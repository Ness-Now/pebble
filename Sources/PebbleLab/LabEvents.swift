import Foundation

struct RunEvent: Encodable {
    let type: String
    let event: String?
    let tick: Int
    let scenario: String?
    let seed: UInt32?
    let ticksRequested: Int?
    let requestedTicks: Int?
    let executedTicks: Int?
    let requestedTicksTotal: Int?
    let executedTicksTotal: Int?
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
    let policyMode: String?
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
    let approved: Int?
    let denied: Int?
    let displacementRefused: Int?
    let completed: Int?
    let stopped: Int?
    let attemptedEdges: Int?
    let completedEdges: Int?
    let displacementsApplied: Int?
    let deniedEdges: Int?
    let routeLength: Int?
    let stoppedAtIndex: Int?
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
    let cases: Int?
    let tickCount: Int?
    let agentCount: Int?
    let agentsObserved: Int?
    let intentCount: Int?
    let resolutions: Int?
    let feedback: Int?
    let feedbackObserved: Int?
    let feedbackAccepted: Int?
    let feedbackIgnored: Int?
    let invalidFeedback: Int?
    let contextsProduced: Int?
    let feedbackObservedTotal: Int?
    let feedbackAcceptedTotal: Int?
    let feedbackIgnoredTotal: Int?
    let invalidFeedbackTotal: Int?
    let contextsProducedTotal: Int?
    let duplicateFeedbackTotal: Int?
    let maxFeedbackExceededTotal: Int?
    let tickMismatchFeedbackTotal: Int?
    let movedTotal: Int?
    let approvedForMovementTotal: Int?
    let blockedByCollisionTotal: Int?
    let blockedByAgentConflictTotal: Int?
    let blockedBySourceMismatchTotal: Int?
    let blockedByDivergenceTotal: Int?
    let blockedByStaleIntentTotal: Int?
    let blockedByInvalidEdgeTotal: Int?
    let blockedByMaxAgentsTotal: Int?
    let contexts: Int?
    let proposals: Int?
    let baselineProposals: Int?
    let feedbackAwareProposals: Int?
    let acceptedIntents: Int?
    let rejectedProposals: Int?
    let noIntent: Int?
    let invalidContext: Int?
    let duplicateAgentContexts: Int?
    let duplicateProposals: Int?
    let invalidOneEdgeProposals: Int?
    let staleProposals: Int?
    let wrongSourceProposals: Int?
    let maxProposalsExceeded: Int?
    let tickAgents: Int?
    let tickIntents: Int?
    let tickResolutions: Int?
    let tickFeedback: Int?
    let tickApproved: Int?
    let tickDenied: Int?
    let sameDestinationConflicts: Int?
    let occupiedDestinationConflicts: Int?
    let swapConflicts: Int?
    let sourceMismatch: Int?
    let staleIntent: Int?
    let missingAgent: Int?
    let invalidEdges: Int?
    let duplicateIntent: Int?
    let cycleConflicts: Int?
    let chainDependencies: Int?
    let movingAwayDestination: Int?
    let verticalInvalidEdges: Int?
    let zeroLengthEdges: Int?
    let allDeniedCases: Int?
    let emptyIntentCases: Int?
    let maxAgentsExceeded: Int?
    let moved: Int?
    let approvedForMovement: Int?
    let blockedByCollision: Int?
    let blockedByAgentConflict: Int?
    let blockedByMaxAgents: Int?
    let duplicateFeedback: Int?
    let intentContexts: Int?
    let contextsWithFeedback: Int?
    let contextsWithoutFeedback: Int?
    let behaviorChangedByFeedback: Bool?
    let behaviorChangedCount: Int?
    let feedbackUsedForDecision: Bool?
    let feedbackReactions: Int?
    let noFeedbackBaselineKept: Int?
    let movedBaselineKept: Int?
    let approvedForMovementBaselineKept: Int?
    let blockedByCollisionNoIntent: Int?
    let blockedByAgentConflictNoIntent: Int?
    let blockedBySourceMismatchNoIntent: Int?
    let blockedByDivergenceNoIntent: Int?
    let blockedByStaleIntentNoIntent: Int?
    let blockedByInvalidEdgeNoIntent: Int?
    let blockedByMaxAgentsNoIntent: Int?
    let intentContextsTotal: Int?
    let contextsTotal: Int?
    let contextsWithFeedbackTotal: Int?
    let contextsWithoutFeedbackTotal: Int?
    let feedbackConsumedTotal: Int?
    let feedbackCarriedToNextTickTotal: Int?
    let proposalsTotal: Int?
    let baselineProposalsTotal: Int?
    let feedbackAwareProposalsTotal: Int?
    let acceptedIntentsTotal: Int?
    let rejectedProposalsTotal: Int?
    let noIntentTotal: Int?
    let noIntentFromBlockedFeedbackTotal: Int?
    let invalidOneEdgeProposalsTotal: Int?
    let feedbackReactionsTotal: Int?
    let behaviorChangedCountTotal: Int?
    let noFeedbackBaselineKeptTotal: Int?
    let movedBaselineKeptTotal: Int?
    let approvedForMovementBaselineKeptTotal: Int?
    let blockedByCollisionNoIntentTotal: Int?
    let blockedByAgentConflictNoIntentTotal: Int?
    let blockedBySourceMismatchNoIntentTotal: Int?
    let blockedByDivergenceNoIntentTotal: Int?
    let blockedByStaleIntentNoIntentTotal: Int?
    let blockedByInvalidEdgeNoIntentTotal: Int?
    let blockedByMaxAgentsNoIntentTotal: Int?
    let baselineMovementIntentInputs: Int?
    let feedbackAwareMovementIntentInputs: Int?
    let agentsTotal: Int?
    let movementIntentInputsTotal: Int?
    let movementIntentReduction: Int?
    let noIntentFilteredOut: Int?
    let feedbackAwareAcceptedIntents: Int?
    let feedbackAwareRejectedProposals: Int?
    let feedbackAwareNoIntent: Int?
    let tickDeniedSameDestinationConflict: Int?
    let tickDeniedConflictTotal: Int?
    let tickDeniedCollisionTotal: Int?
    let tickFeedbackEmitted: Int?
    let tickApprovedTotal: Int?
    let tickDeniedTotal: Int?
    let feedbackEmittedTotal: Int?
    let policyReadCollision: Bool?
    let policyWorldUsed: Bool?
    let tickWorldReadOnlyUsed: Bool?
    let worldMutated: Bool?
    let approvedAgentsMoved: Int?
    let approvedApplicationsTotal: Int?
    let deniedAgentsPreserved: Int?
    let deniedPreservedTotal: Int?
    let noIntentAgentsPreserved: Int?
    let noIntentPreservedTotal: Int?
    let feedbackCandidatesTotal: Int?
    let feedbackDedupedTotal: Int?
    let missingFeedbackAllowedTotal: Int?
    let staleFeedbackIgnoredTotal: Int?
    let futureFeedbackIgnoredTotal: Int?
    let sameTickFeedbackIgnoredTotal: Int?
    let crossAgentLeakAttemptsTotal: Int?
    let unknownAgentFeedbackIgnoredTotal: Int?
    let malformedFeedbackIgnoredTotal: Int?
    let sameTickFeedbackConsumedTotal: Int?
    let crossAgentFeedbackLeaksTotal: Int?
    let futureFeedbackConsumedTotal: Int?
    let repeatabilityChecks: Int?
    let repeatabilityFailures: Int?
    let abstractPositionsChanged: Int?
    let physicalPositionsChanged: Int?
    let abstractPhysicalDivergenceBefore: Int?
    let abstractPhysicalDivergenceAfter: Int?
    let routeFollowingUsed: Bool?
    let movedFeedback: Int?
    let approvedForMovementFeedback: Int?
    let blockedByCollisionFeedback: Int?
    let blockedByAgentConflictFeedback: Int?
    let blockedBySourceMismatchFeedback: Int?
    let blockedByDivergenceFeedback: Int?
    let blockedByStaleIntentFeedback: Int?
    let blockedByInvalidEdgeFeedback: Int?
    let blockedByMaxAgentsFeedback: Int?
    let occupableDestinations: Int?
    let nonOccupableDestinations: Int?
    let collisionDenied: Int?
    let divergenceDenied: Int?
    let staleCollision: Int?
    let partialApprovalCases: Int?
    let divergenceBeforeMax: Int?
    let divergenceAfterMax: Int?
    let productionAcceptedSameDestination: Bool?
    let tickResolvedSameDestination: Bool?
    let deniedPositionsPreserved: Bool?
    let approvedPositionsMoved: Bool?
    let intentProduced: Bool?
    let productionReadCollision: Bool?
    let tickReadCollision: Bool?
    let worldUsed: Bool?
    let liveCollisionRead: Bool?
    let physicalMovementApplied: Bool?
    let routeFollowingApplied: Bool?
    let occupableFound: Bool?
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
    let collisionRead: Bool?
    let movementApplied: Bool?
    let feedbackConsumed: Bool?
    let memoryUpdated: Bool?
    let goalChanged: Bool?
    let avoidancePerformed: Bool?
    let reservationRuntimeUsed: Bool?
    let mutationPerformed: Bool?
    let occupable: Int?
    let blocked: Int?
    let unsupported: Int?
    let verticalSpaceOccupied: Int?
    let liquidUnsupported: Int?
    let outOfBounds: Int?
    let notLoaded: Int?
    let notReady: Int?
    let status: String?
    let samples: Int?
    let loadedSamples: Int?
    let readySamples: Int?
    let physicalPlaceholderDisplaced: Bool?
    let coreEntityDisplaced: Bool?
    let movementPerformed: Bool?
    let pathfindingPerformed: Bool?
    let collisionStatus: String?
    let displacementApplied: Bool?
    let routeFollowingPerformed: Bool?
    let pathfindingInsideFollower: Bool?
    let replanningPerformed: Bool?
    let physicsPerformed: Bool?
    let divergenceBefore: Int?
    let divergenceAfter: Int?

    init(
        type: String,
        tick: Int,
        event: String? = nil,
        scenario: String? = nil,
        seed: UInt32? = nil,
        ticksRequested: Int? = nil,
        requestedTicks: Int? = nil,
        executedTicks: Int? = nil,
        requestedTicksTotal: Int? = nil,
        executedTicksTotal: Int? = nil,
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
        policyMode: String? = nil,
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
        approved: Int? = nil,
        denied: Int? = nil,
        displacementRefused: Int? = nil,
        completed: Int? = nil,
        stopped: Int? = nil,
        attemptedEdges: Int? = nil,
        completedEdges: Int? = nil,
        displacementsApplied: Int? = nil,
        deniedEdges: Int? = nil,
        routeLength: Int? = nil,
        stoppedAtIndex: Int? = nil,
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
        cases: Int? = nil,
        tickCount: Int? = nil,
        agentCount: Int? = nil,
        agentsObserved: Int? = nil,
        intentCount: Int? = nil,
        resolutions: Int? = nil,
        feedback: Int? = nil,
        feedbackObserved: Int? = nil,
        feedbackAccepted: Int? = nil,
        feedbackIgnored: Int? = nil,
        invalidFeedback: Int? = nil,
        contextsProduced: Int? = nil,
        feedbackObservedTotal: Int? = nil,
        feedbackAcceptedTotal: Int? = nil,
        feedbackIgnoredTotal: Int? = nil,
        invalidFeedbackTotal: Int? = nil,
        contextsProducedTotal: Int? = nil,
        duplicateFeedbackTotal: Int? = nil,
        maxFeedbackExceededTotal: Int? = nil,
        tickMismatchFeedbackTotal: Int? = nil,
        movedTotal: Int? = nil,
        approvedForMovementTotal: Int? = nil,
        blockedByCollisionTotal: Int? = nil,
        blockedByAgentConflictTotal: Int? = nil,
        blockedBySourceMismatchTotal: Int? = nil,
        blockedByDivergenceTotal: Int? = nil,
        blockedByStaleIntentTotal: Int? = nil,
        blockedByInvalidEdgeTotal: Int? = nil,
        blockedByMaxAgentsTotal: Int? = nil,
        contexts: Int? = nil,
        proposals: Int? = nil,
        baselineProposals: Int? = nil,
        feedbackAwareProposals: Int? = nil,
        acceptedIntents: Int? = nil,
        rejectedProposals: Int? = nil,
        noIntent: Int? = nil,
        invalidContext: Int? = nil,
        duplicateAgentContexts: Int? = nil,
        duplicateProposals: Int? = nil,
        invalidOneEdgeProposals: Int? = nil,
        staleProposals: Int? = nil,
        wrongSourceProposals: Int? = nil,
        maxProposalsExceeded: Int? = nil,
        tickAgents: Int? = nil,
        tickIntents: Int? = nil,
        tickResolutions: Int? = nil,
        tickFeedback: Int? = nil,
        tickApproved: Int? = nil,
        tickDenied: Int? = nil,
        sameDestinationConflicts: Int? = nil,
        occupiedDestinationConflicts: Int? = nil,
        swapConflicts: Int? = nil,
        sourceMismatch: Int? = nil,
        staleIntent: Int? = nil,
        missingAgent: Int? = nil,
        invalidEdges: Int? = nil,
        duplicateIntent: Int? = nil,
        cycleConflicts: Int? = nil,
        chainDependencies: Int? = nil,
        movingAwayDestination: Int? = nil,
        verticalInvalidEdges: Int? = nil,
        zeroLengthEdges: Int? = nil,
        allDeniedCases: Int? = nil,
        emptyIntentCases: Int? = nil,
        maxAgentsExceeded: Int? = nil,
        moved: Int? = nil,
        approvedForMovement: Int? = nil,
        blockedByCollision: Int? = nil,
        blockedByAgentConflict: Int? = nil,
        blockedByMaxAgents: Int? = nil,
        duplicateFeedback: Int? = nil,
        intentContexts: Int? = nil,
        contextsWithFeedback: Int? = nil,
        contextsWithoutFeedback: Int? = nil,
        behaviorChangedByFeedback: Bool? = nil,
        behaviorChangedCount: Int? = nil,
        feedbackUsedForDecision: Bool? = nil,
        feedbackReactions: Int? = nil,
        noFeedbackBaselineKept: Int? = nil,
        movedBaselineKept: Int? = nil,
        approvedForMovementBaselineKept: Int? = nil,
        blockedByCollisionNoIntent: Int? = nil,
        blockedByAgentConflictNoIntent: Int? = nil,
        blockedBySourceMismatchNoIntent: Int? = nil,
        blockedByDivergenceNoIntent: Int? = nil,
        blockedByStaleIntentNoIntent: Int? = nil,
        blockedByInvalidEdgeNoIntent: Int? = nil,
        blockedByMaxAgentsNoIntent: Int? = nil,
        intentContextsTotal: Int? = nil,
        contextsTotal: Int? = nil,
        contextsWithFeedbackTotal: Int? = nil,
        contextsWithoutFeedbackTotal: Int? = nil,
        feedbackConsumedTotal: Int? = nil,
        feedbackCarriedToNextTickTotal: Int? = nil,
        proposalsTotal: Int? = nil,
        baselineProposalsTotal: Int? = nil,
        feedbackAwareProposalsTotal: Int? = nil,
        acceptedIntentsTotal: Int? = nil,
        rejectedProposalsTotal: Int? = nil,
        noIntentTotal: Int? = nil,
        noIntentFromBlockedFeedbackTotal: Int? = nil,
        invalidOneEdgeProposalsTotal: Int? = nil,
        feedbackReactionsTotal: Int? = nil,
        behaviorChangedCountTotal: Int? = nil,
        noFeedbackBaselineKeptTotal: Int? = nil,
        movedBaselineKeptTotal: Int? = nil,
        approvedForMovementBaselineKeptTotal: Int? = nil,
        blockedByCollisionNoIntentTotal: Int? = nil,
        blockedByAgentConflictNoIntentTotal: Int? = nil,
        blockedBySourceMismatchNoIntentTotal: Int? = nil,
        blockedByDivergenceNoIntentTotal: Int? = nil,
        blockedByStaleIntentNoIntentTotal: Int? = nil,
        blockedByInvalidEdgeNoIntentTotal: Int? = nil,
        blockedByMaxAgentsNoIntentTotal: Int? = nil,
        baselineMovementIntentInputs: Int? = nil,
        feedbackAwareMovementIntentInputs: Int? = nil,
        agentsTotal: Int? = nil,
        movementIntentInputsTotal: Int? = nil,
        movementIntentReduction: Int? = nil,
        noIntentFilteredOut: Int? = nil,
        feedbackAwareAcceptedIntents: Int? = nil,
        feedbackAwareRejectedProposals: Int? = nil,
        feedbackAwareNoIntent: Int? = nil,
        tickDeniedSameDestinationConflict: Int? = nil,
        tickDeniedConflictTotal: Int? = nil,
        tickDeniedCollisionTotal: Int? = nil,
        tickFeedbackEmitted: Int? = nil,
        tickApprovedTotal: Int? = nil,
        tickDeniedTotal: Int? = nil,
        feedbackEmittedTotal: Int? = nil,
        policyReadCollision: Bool? = nil,
        policyWorldUsed: Bool? = nil,
        tickWorldReadOnlyUsed: Bool? = nil,
        worldMutated: Bool? = nil,
        approvedAgentsMoved: Int? = nil,
        approvedApplicationsTotal: Int? = nil,
        deniedAgentsPreserved: Int? = nil,
        deniedPreservedTotal: Int? = nil,
        noIntentAgentsPreserved: Int? = nil,
        noIntentPreservedTotal: Int? = nil,
        feedbackCandidatesTotal: Int? = nil,
        feedbackDedupedTotal: Int? = nil,
        missingFeedbackAllowedTotal: Int? = nil,
        staleFeedbackIgnoredTotal: Int? = nil,
        futureFeedbackIgnoredTotal: Int? = nil,
        sameTickFeedbackIgnoredTotal: Int? = nil,
        crossAgentLeakAttemptsTotal: Int? = nil,
        unknownAgentFeedbackIgnoredTotal: Int? = nil,
        malformedFeedbackIgnoredTotal: Int? = nil,
        sameTickFeedbackConsumedTotal: Int? = nil,
        crossAgentFeedbackLeaksTotal: Int? = nil,
        futureFeedbackConsumedTotal: Int? = nil,
        repeatabilityChecks: Int? = nil,
        repeatabilityFailures: Int? = nil,
        abstractPositionsChanged: Int? = nil,
        physicalPositionsChanged: Int? = nil,
        abstractPhysicalDivergenceBefore: Int? = nil,
        abstractPhysicalDivergenceAfter: Int? = nil,
        routeFollowingUsed: Bool? = nil,
        movedFeedback: Int? = nil,
        approvedForMovementFeedback: Int? = nil,
        blockedByCollisionFeedback: Int? = nil,
        blockedByAgentConflictFeedback: Int? = nil,
        blockedBySourceMismatchFeedback: Int? = nil,
        blockedByDivergenceFeedback: Int? = nil,
        blockedByStaleIntentFeedback: Int? = nil,
        blockedByInvalidEdgeFeedback: Int? = nil,
        blockedByMaxAgentsFeedback: Int? = nil,
        occupableDestinations: Int? = nil,
        nonOccupableDestinations: Int? = nil,
        collisionDenied: Int? = nil,
        divergenceDenied: Int? = nil,
        staleCollision: Int? = nil,
        partialApprovalCases: Int? = nil,
        divergenceBeforeMax: Int? = nil,
        divergenceAfterMax: Int? = nil,
        productionAcceptedSameDestination: Bool? = nil,
        tickResolvedSameDestination: Bool? = nil,
        deniedPositionsPreserved: Bool? = nil,
        approvedPositionsMoved: Bool? = nil,
        intentProduced: Bool? = nil,
        productionReadCollision: Bool? = nil,
        tickReadCollision: Bool? = nil,
        worldUsed: Bool? = nil,
        liveCollisionRead: Bool? = nil,
        physicalMovementApplied: Bool? = nil,
        routeFollowingApplied: Bool? = nil,
        occupableFound: Bool? = nil,
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
        collisionRead: Bool? = nil,
        movementApplied: Bool? = nil,
        feedbackConsumed: Bool? = nil,
        memoryUpdated: Bool? = nil,
        goalChanged: Bool? = nil,
        avoidancePerformed: Bool? = nil,
        reservationRuntimeUsed: Bool? = nil,
        mutationPerformed: Bool? = nil,
        occupable: Int? = nil,
        blocked: Int? = nil,
        unsupported: Int? = nil,
        verticalSpaceOccupied: Int? = nil,
        liquidUnsupported: Int? = nil,
        outOfBounds: Int? = nil,
        notLoaded: Int? = nil,
        notReady: Int? = nil,
        status: String? = nil,
        samples: Int? = nil,
        loadedSamples: Int? = nil,
        readySamples: Int? = nil,
        physicalPlaceholderDisplaced: Bool? = nil,
        coreEntityDisplaced: Bool? = nil,
        movementPerformed: Bool? = nil,
        pathfindingPerformed: Bool? = nil,
        collisionStatus: String? = nil,
        displacementApplied: Bool? = nil,
        routeFollowingPerformed: Bool? = nil,
        pathfindingInsideFollower: Bool? = nil,
        replanningPerformed: Bool? = nil,
        physicsPerformed: Bool? = nil,
        divergenceBefore: Int? = nil,
        divergenceAfter: Int? = nil
    ) {
        self.type = type
        self.event = event
        self.tick = tick
        self.scenario = scenario
        self.seed = seed
        self.ticksRequested = ticksRequested
        self.requestedTicks = requestedTicks
        self.executedTicks = executedTicks
        self.requestedTicksTotal = requestedTicksTotal
        self.executedTicksTotal = executedTicksTotal
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
        self.policyMode = policyMode
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
        self.approved = approved
        self.denied = denied
        self.displacementRefused = displacementRefused
        self.completed = completed
        self.stopped = stopped
        self.attemptedEdges = attemptedEdges
        self.completedEdges = completedEdges
        self.displacementsApplied = displacementsApplied
        self.deniedEdges = deniedEdges
        self.routeLength = routeLength
        self.stoppedAtIndex = stoppedAtIndex
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
        self.cases = cases
        self.tickCount = tickCount
        self.agentCount = agentCount
        self.agentsObserved = agentsObserved
        self.intentCount = intentCount
        self.resolutions = resolutions
        self.feedback = feedback
        self.feedbackObserved = feedbackObserved
        self.feedbackAccepted = feedbackAccepted
        self.feedbackIgnored = feedbackIgnored
        self.invalidFeedback = invalidFeedback
        self.contextsProduced = contextsProduced
        self.feedbackObservedTotal = feedbackObservedTotal
        self.feedbackAcceptedTotal = feedbackAcceptedTotal
        self.feedbackIgnoredTotal = feedbackIgnoredTotal
        self.invalidFeedbackTotal = invalidFeedbackTotal
        self.contextsProducedTotal = contextsProducedTotal
        self.duplicateFeedbackTotal = duplicateFeedbackTotal
        self.maxFeedbackExceededTotal = maxFeedbackExceededTotal
        self.tickMismatchFeedbackTotal = tickMismatchFeedbackTotal
        self.movedTotal = movedTotal
        self.approvedForMovementTotal = approvedForMovementTotal
        self.blockedByCollisionTotal = blockedByCollisionTotal
        self.blockedByAgentConflictTotal = blockedByAgentConflictTotal
        self.blockedBySourceMismatchTotal = blockedBySourceMismatchTotal
        self.blockedByDivergenceTotal = blockedByDivergenceTotal
        self.blockedByStaleIntentTotal = blockedByStaleIntentTotal
        self.blockedByInvalidEdgeTotal = blockedByInvalidEdgeTotal
        self.blockedByMaxAgentsTotal = blockedByMaxAgentsTotal
        self.contexts = contexts
        self.proposals = proposals
        self.baselineProposals = baselineProposals
        self.feedbackAwareProposals = feedbackAwareProposals
        self.acceptedIntents = acceptedIntents
        self.rejectedProposals = rejectedProposals
        self.noIntent = noIntent
        self.invalidContext = invalidContext
        self.duplicateAgentContexts = duplicateAgentContexts
        self.duplicateProposals = duplicateProposals
        self.invalidOneEdgeProposals = invalidOneEdgeProposals
        self.staleProposals = staleProposals
        self.wrongSourceProposals = wrongSourceProposals
        self.maxProposalsExceeded = maxProposalsExceeded
        self.tickAgents = tickAgents
        self.tickIntents = tickIntents
        self.tickResolutions = tickResolutions
        self.tickFeedback = tickFeedback
        self.tickApproved = tickApproved
        self.tickDenied = tickDenied
        self.sameDestinationConflicts = sameDestinationConflicts
        self.occupiedDestinationConflicts = occupiedDestinationConflicts
        self.swapConflicts = swapConflicts
        self.sourceMismatch = sourceMismatch
        self.staleIntent = staleIntent
        self.missingAgent = missingAgent
        self.invalidEdges = invalidEdges
        self.duplicateIntent = duplicateIntent
        self.cycleConflicts = cycleConflicts
        self.chainDependencies = chainDependencies
        self.movingAwayDestination = movingAwayDestination
        self.verticalInvalidEdges = verticalInvalidEdges
        self.zeroLengthEdges = zeroLengthEdges
        self.allDeniedCases = allDeniedCases
        self.emptyIntentCases = emptyIntentCases
        self.maxAgentsExceeded = maxAgentsExceeded
        self.moved = moved
        self.approvedForMovement = approvedForMovement
        self.blockedByCollision = blockedByCollision
        self.blockedByAgentConflict = blockedByAgentConflict
        self.blockedByMaxAgents = blockedByMaxAgents
        self.duplicateFeedback = duplicateFeedback
        self.intentContexts = intentContexts
        self.contextsWithFeedback = contextsWithFeedback
        self.contextsWithoutFeedback = contextsWithoutFeedback
        self.behaviorChangedByFeedback = behaviorChangedByFeedback
        self.behaviorChangedCount = behaviorChangedCount
        self.feedbackUsedForDecision = feedbackUsedForDecision
        self.feedbackReactions = feedbackReactions
        self.noFeedbackBaselineKept = noFeedbackBaselineKept
        self.movedBaselineKept = movedBaselineKept
        self.approvedForMovementBaselineKept = approvedForMovementBaselineKept
        self.blockedByCollisionNoIntent = blockedByCollisionNoIntent
        self.blockedByAgentConflictNoIntent = blockedByAgentConflictNoIntent
        self.blockedBySourceMismatchNoIntent = blockedBySourceMismatchNoIntent
        self.blockedByDivergenceNoIntent = blockedByDivergenceNoIntent
        self.blockedByStaleIntentNoIntent = blockedByStaleIntentNoIntent
        self.blockedByInvalidEdgeNoIntent = blockedByInvalidEdgeNoIntent
        self.blockedByMaxAgentsNoIntent = blockedByMaxAgentsNoIntent
        self.intentContextsTotal = intentContextsTotal
        self.contextsTotal = contextsTotal
        self.contextsWithFeedbackTotal = contextsWithFeedbackTotal
        self.contextsWithoutFeedbackTotal = contextsWithoutFeedbackTotal
        self.feedbackConsumedTotal = feedbackConsumedTotal
        self.feedbackCarriedToNextTickTotal = feedbackCarriedToNextTickTotal
        self.proposalsTotal = proposalsTotal
        self.baselineProposalsTotal = baselineProposalsTotal
        self.feedbackAwareProposalsTotal = feedbackAwareProposalsTotal
        self.acceptedIntentsTotal = acceptedIntentsTotal
        self.rejectedProposalsTotal = rejectedProposalsTotal
        self.noIntentTotal = noIntentTotal
        self.noIntentFromBlockedFeedbackTotal = noIntentFromBlockedFeedbackTotal
        self.invalidOneEdgeProposalsTotal = invalidOneEdgeProposalsTotal
        self.feedbackReactionsTotal = feedbackReactionsTotal
        self.behaviorChangedCountTotal = behaviorChangedCountTotal
        self.noFeedbackBaselineKeptTotal = noFeedbackBaselineKeptTotal
        self.movedBaselineKeptTotal = movedBaselineKeptTotal
        self.approvedForMovementBaselineKeptTotal = approvedForMovementBaselineKeptTotal
        self.blockedByCollisionNoIntentTotal = blockedByCollisionNoIntentTotal
        self.blockedByAgentConflictNoIntentTotal = blockedByAgentConflictNoIntentTotal
        self.blockedBySourceMismatchNoIntentTotal = blockedBySourceMismatchNoIntentTotal
        self.blockedByDivergenceNoIntentTotal = blockedByDivergenceNoIntentTotal
        self.blockedByStaleIntentNoIntentTotal = blockedByStaleIntentNoIntentTotal
        self.blockedByInvalidEdgeNoIntentTotal = blockedByInvalidEdgeNoIntentTotal
        self.blockedByMaxAgentsNoIntentTotal = blockedByMaxAgentsNoIntentTotal
        self.baselineMovementIntentInputs = baselineMovementIntentInputs
        self.feedbackAwareMovementIntentInputs = feedbackAwareMovementIntentInputs
        self.agentsTotal = agentsTotal
        self.movementIntentInputsTotal = movementIntentInputsTotal
        self.movementIntentReduction = movementIntentReduction
        self.noIntentFilteredOut = noIntentFilteredOut
        self.feedbackAwareAcceptedIntents = feedbackAwareAcceptedIntents
        self.feedbackAwareRejectedProposals = feedbackAwareRejectedProposals
        self.feedbackAwareNoIntent = feedbackAwareNoIntent
        self.tickDeniedSameDestinationConflict = tickDeniedSameDestinationConflict
        self.tickDeniedConflictTotal = tickDeniedConflictTotal
        self.tickDeniedCollisionTotal = tickDeniedCollisionTotal
        self.tickFeedbackEmitted = tickFeedbackEmitted
        self.tickApprovedTotal = tickApprovedTotal
        self.tickDeniedTotal = tickDeniedTotal
        self.feedbackEmittedTotal = feedbackEmittedTotal
        self.policyReadCollision = policyReadCollision
        self.policyWorldUsed = policyWorldUsed
        self.tickWorldReadOnlyUsed = tickWorldReadOnlyUsed
        self.worldMutated = worldMutated
        self.approvedAgentsMoved = approvedAgentsMoved
        self.approvedApplicationsTotal = approvedApplicationsTotal
        self.deniedAgentsPreserved = deniedAgentsPreserved
        self.deniedPreservedTotal = deniedPreservedTotal
        self.noIntentAgentsPreserved = noIntentAgentsPreserved
        self.noIntentPreservedTotal = noIntentPreservedTotal
        self.feedbackCandidatesTotal = feedbackCandidatesTotal
        self.feedbackDedupedTotal = feedbackDedupedTotal
        self.missingFeedbackAllowedTotal = missingFeedbackAllowedTotal
        self.staleFeedbackIgnoredTotal = staleFeedbackIgnoredTotal
        self.futureFeedbackIgnoredTotal = futureFeedbackIgnoredTotal
        self.sameTickFeedbackIgnoredTotal = sameTickFeedbackIgnoredTotal
        self.crossAgentLeakAttemptsTotal = crossAgentLeakAttemptsTotal
        self.unknownAgentFeedbackIgnoredTotal = unknownAgentFeedbackIgnoredTotal
        self.malformedFeedbackIgnoredTotal = malformedFeedbackIgnoredTotal
        self.sameTickFeedbackConsumedTotal = sameTickFeedbackConsumedTotal
        self.crossAgentFeedbackLeaksTotal = crossAgentFeedbackLeaksTotal
        self.futureFeedbackConsumedTotal = futureFeedbackConsumedTotal
        self.repeatabilityChecks = repeatabilityChecks
        self.repeatabilityFailures = repeatabilityFailures
        self.abstractPositionsChanged = abstractPositionsChanged
        self.physicalPositionsChanged = physicalPositionsChanged
        self.abstractPhysicalDivergenceBefore = abstractPhysicalDivergenceBefore
        self.abstractPhysicalDivergenceAfter = abstractPhysicalDivergenceAfter
        self.routeFollowingUsed = routeFollowingUsed
        self.movedFeedback = movedFeedback
        self.approvedForMovementFeedback = approvedForMovementFeedback
        self.blockedByCollisionFeedback = blockedByCollisionFeedback
        self.blockedByAgentConflictFeedback = blockedByAgentConflictFeedback
        self.blockedBySourceMismatchFeedback = blockedBySourceMismatchFeedback
        self.blockedByDivergenceFeedback = blockedByDivergenceFeedback
        self.blockedByStaleIntentFeedback = blockedByStaleIntentFeedback
        self.blockedByInvalidEdgeFeedback = blockedByInvalidEdgeFeedback
        self.blockedByMaxAgentsFeedback = blockedByMaxAgentsFeedback
        self.occupableDestinations = occupableDestinations
        self.nonOccupableDestinations = nonOccupableDestinations
        self.collisionDenied = collisionDenied
        self.divergenceDenied = divergenceDenied
        self.staleCollision = staleCollision
        self.partialApprovalCases = partialApprovalCases
        self.divergenceBeforeMax = divergenceBeforeMax
        self.divergenceAfterMax = divergenceAfterMax
        self.productionAcceptedSameDestination = productionAcceptedSameDestination
        self.tickResolvedSameDestination = tickResolvedSameDestination
        self.deniedPositionsPreserved = deniedPositionsPreserved
        self.approvedPositionsMoved = approvedPositionsMoved
        self.intentProduced = intentProduced
        self.productionReadCollision = productionReadCollision
        self.tickReadCollision = tickReadCollision
        self.worldUsed = worldUsed
        self.liveCollisionRead = liveCollisionRead
        self.physicalMovementApplied = physicalMovementApplied
        self.routeFollowingApplied = routeFollowingApplied
        self.occupableFound = occupableFound
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
        self.collisionRead = collisionRead
        self.movementApplied = movementApplied
        self.feedbackConsumed = feedbackConsumed
        self.memoryUpdated = memoryUpdated
        self.goalChanged = goalChanged
        self.avoidancePerformed = avoidancePerformed
        self.reservationRuntimeUsed = reservationRuntimeUsed
        self.mutationPerformed = mutationPerformed
        self.occupable = occupable
        self.blocked = blocked
        self.unsupported = unsupported
        self.verticalSpaceOccupied = verticalSpaceOccupied
        self.liquidUnsupported = liquidUnsupported
        self.outOfBounds = outOfBounds
        self.notLoaded = notLoaded
        self.notReady = notReady
        self.status = status
        self.samples = samples
        self.loadedSamples = loadedSamples
        self.readySamples = readySamples
        self.physicalPlaceholderDisplaced = physicalPlaceholderDisplaced
        self.coreEntityDisplaced = coreEntityDisplaced
        self.movementPerformed = movementPerformed
        self.pathfindingPerformed = pathfindingPerformed
        self.collisionStatus = collisionStatus
        self.displacementApplied = displacementApplied
        self.routeFollowingPerformed = routeFollowingPerformed
        self.pathfindingInsideFollower = pathfindingInsideFollower
        self.replanningPerformed = replanningPerformed
        self.physicsPerformed = physicsPerformed
        self.divergenceBefore = divergenceBefore
        self.divergenceAfter = divergenceAfter
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
