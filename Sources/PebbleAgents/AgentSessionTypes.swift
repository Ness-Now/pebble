public enum AgentMemoryPolicy: Codable, Equatable {
    case legacyUnbounded
    case bounded(maxEntries: Int)
}

public enum AgentSessionError: Error, Equatable {
    case invalidNearbyRadius(Int)
    case invalidResourceObservationRadius(Int)
    case invalidRecentMemorySnapshotLimit(Int)
    case invalidMemoryBound(Int)
    case invalidNavigationMaxReplans(Int)
    case invalidNavigationReplanCooldown(Int)
    case invalidReservationLifetime(Int)
    case invalidDeliveryQuota(Int)
    case invalidCampStockCapacity(Int)
    case invalidInitialTick(Int)
    case simulationTickOverflow
    case duplicateAgentId(String)
    case duplicatePerceptionInput(String)
    case unknownAgentId(String)
    case worldObservationPositionMismatch(String)
    case invalidNavigationObservation(String)
    case movementOutcomeCountMismatch(expected: Int, actual: Int)
    case duplicateMovementOutcome(String)
    case missingMovementOutcome(String)
    case movementTickMismatch(String)
    case movementFromPositionMismatch(String)
    case movementGoalMismatch(String)
    case duplicateMovementDestination
    case occupiedMovementDestination(String)
    case inconsistentMovementDelta(String)
    case invalidCardinalMovement(String)
    case invalidVerticalMovement(String)
    case invalidStationaryMovement(String)
    case movementActionMismatch(String)
    case movementDirectionMismatch(String)
    case movementHomeMetricsMismatch(String)
    case invalidInteractionQuantity(String)
    case interactionTickMismatch(String)
    case duplicateInteraction(String)
    case duplicateResourceCredit(String)
    case inventoryFull(String)
    case invalidInteractionOutcome(String)
    case invalidNaturalResourceIdentity(String)
    case deliveryTickMismatch(String)
    case duplicateDelivery(String)
    case deliveryAwayFromHome(String)
    case emptyDelivery(String)
    case campStockFull(String)
    case invalidDeliveryOutcome(String)
    case invalidConsumptionQuantity(String)
    case invalidConsumptionResource(String)
    case consumptionTickMismatch(String)
    case duplicateConsumption(String)
    case invalidConsumptionOutcome(String)
    case survivalDisabled(String)
    case consumptionLimitReached
    case constructionProjectAlreadyExists
    case constructionProjectMissing
    case constructionBuilderMismatch(String)
    case constructionDisabled
    case constructionFundingTickMismatch(String)
    case duplicateConstructionFunding(String)
    case invalidConstructionFunding(String)
    case constructionPlacementTickMismatch(String)
    case duplicateConstructionPlacement(String)
    case invalidConstructionPlacement(String)
    case constructionCompletionInvalid(String)
    case constructionClearInvalid(String)
    case constructionEventLimitReached
    case social(AgentSocialError)
    case physical(AgentPhysicalChannelError)
    case cooperation(AgentCooperationError)
}

public struct AgentSessionConfiguration: Codable {
    public let seed: UInt32
    public let nearbyRadius: Int
    public let resourceObservationRadius: Int
    public let recentMemorySnapshotLimit: Int
    public let memoryPolicy: AgentMemoryPolicy
    public let feedbackLoopConfiguration: AgentFeedbackLoopConfiguration
    public let navigationMaxReplans: Int
    public let navigationReplanCooldownTicks: Int
    public let reservationLifetimeTicks: Int
    public let deliveryQuota: Int
    public let campStockCapacity: Int
    public let survivalConfiguration: AgentSurvivalConfiguration
    public let socialConfiguration: AgentSocialConfiguration
    public let physicalChannelConfiguration: AgentPhysicalChannelConfiguration
    public let cooperationConfiguration: AgentCooperationConfiguration

    public init(
        seed: UInt32,
        nearbyRadius: Int = 8,
        resourceObservationRadius: Int = 1,
        recentMemorySnapshotLimit: Int = 10,
        memoryPolicy: AgentMemoryPolicy,
        feedbackLoopConfiguration: AgentFeedbackLoopConfiguration = .live,
        navigationMaxReplans: Int = 3,
        navigationReplanCooldownTicks: Int = 1,
        reservationLifetimeTicks: Int = 4,
        deliveryQuota: Int = 2,
        campStockCapacity: Int = 64,
        survivalConfiguration: AgentSurvivalConfiguration = .live,
        socialConfiguration: AgentSocialConfiguration = .live,
        physicalChannelConfiguration: AgentPhysicalChannelConfiguration = .live,
        cooperationConfiguration: AgentCooperationConfiguration = .live
    ) throws {
        guard nearbyRadius >= 0 else {
            throw AgentSessionError.invalidNearbyRadius(nearbyRadius)
        }
        guard (1...AgentResourcePerception.maximumDistance).contains(resourceObservationRadius) else {
            throw AgentSessionError.invalidResourceObservationRadius(resourceObservationRadius)
        }
        guard recentMemorySnapshotLimit >= 0 else {
            throw AgentSessionError.invalidRecentMemorySnapshotLimit(recentMemorySnapshotLimit)
        }
        if case let .bounded(maxEntries) = memoryPolicy, maxEntries <= 0 {
            throw AgentSessionError.invalidMemoryBound(maxEntries)
        }
        guard navigationMaxReplans >= 0 else {
            throw AgentSessionError.invalidNavigationMaxReplans(navigationMaxReplans)
        }
        guard navigationReplanCooldownTicks >= 1 else {
            throw AgentSessionError.invalidNavigationReplanCooldown(navigationReplanCooldownTicks)
        }
        guard reservationLifetimeTicks >= 1 else {
            throw AgentSessionError.invalidReservationLifetime(reservationLifetimeTicks)
        }
        guard deliveryQuota >= 1 else {
            throw AgentSessionError.invalidDeliveryQuota(deliveryQuota)
        }
        guard campStockCapacity >= deliveryQuota else {
            throw AgentSessionError.invalidCampStockCapacity(campStockCapacity)
        }
        self.seed = seed
        self.nearbyRadius = nearbyRadius
        self.resourceObservationRadius = resourceObservationRadius
        self.recentMemorySnapshotLimit = recentMemorySnapshotLimit
        self.memoryPolicy = memoryPolicy
        self.feedbackLoopConfiguration = feedbackLoopConfiguration
        self.navigationMaxReplans = navigationMaxReplans
        self.navigationReplanCooldownTicks = navigationReplanCooldownTicks
        self.reservationLifetimeTicks = reservationLifetimeTicks
        self.deliveryQuota = deliveryQuota
        self.campStockCapacity = campStockCapacity
        self.survivalConfiguration = survivalConfiguration
        self.socialConfiguration = socialConfiguration
        self.physicalChannelConfiguration = physicalChannelConfiguration
        self.cooperationConfiguration = cooperationConfiguration
    }
}

public struct AgentSessionAgentState: Codable {
    public internal(set) var agentID: AgentID
    public var id: String { agentID.rawValue }
    public internal(set) var state: String
    public internal(set) var position: AgentPosition
    public internal(set) var needs: AgentNeeds
    public internal(set) var health: Int
    public internal(set) var fear: Int
    public internal(set) var homePosition: AgentPosition
    public internal(set) var nearbyAgents: [AgentNearbyObservation]
    public internal(set) var currentGoal: AgentGoal
    public internal(set) var lastAction: AgentAction?
    public internal(set) var lastActionEffect: AgentActionEffect?
    public internal(set) var memory: [AgentMemoryEntry]
    public internal(set) var tickCreated: Int
    public internal(set) var ticksAlive: Int
    public internal(set) var observationCount: Int
    public internal(set) var nearbyObservationCount: Int
    public internal(set) var goalSelectionCount: Int
    public internal(set) var goalChangeCount: Int
    public internal(set) var actionCount: Int
    public internal(set) var actionEffectCount: Int
    public internal(set) var movementCount: Int
    public internal(set) var totalManhattanDistanceMoved: Int
    public internal(set) var returnHomeMoveCount: Int
    public internal(set) var totalDistanceReducedTowardHome: Int
    public internal(set) var lastWorldObservation: AgentWorldObservation?
    public internal(set) var lastWorldPerceptionEffect: AgentWorldPerceptionEffect?
    public internal(set) var lastMovementOutcome: AgentMovementOutcome?
    public internal(set) var lastFeedbackDecisionTrace: AgentFeedbackDecisionTrace?
    public internal(set) var feedbackMemoryWriteCount: Int
    public internal(set) var feedbackMemoryDeduplicatedCount: Int
    public internal(set) var memoryRetrievalCount: Int
    public internal(set) var memoryInfluencedDecisionCount: Int
    public internal(set) var lastResourceObservations: [AgentResourceObservation]
    public internal(set) var activeResourceTarget: AgentResourceTarget?
    public internal(set) var resourceInventory: AgentResourceInventory
    public internal(set) var lastInteractionOutcome: AgentInteractionOutcome?
    public internal(set) var navigationProgress: AgentNavigationProgress
    public internal(set) var lastDeliveryOutcome: AgentDeliveryOutcome?
    public internal(set) var survivalProgress: AgentSurvivalProgress?

    public init(
        id: String,
        state: String,
        position: AgentPosition,
        needs: AgentNeeds,
        health: Int,
        fear: Int,
        homePosition: AgentPosition,
        nearbyAgents: [AgentNearbyObservation],
        currentGoal: AgentGoal,
        lastAction: AgentAction?,
        lastActionEffect: AgentActionEffect?,
        memory: [AgentMemoryEntry],
        tickCreated: Int,
        ticksAlive: Int,
        observationCount: Int,
        nearbyObservationCount: Int,
        goalSelectionCount: Int,
        goalChangeCount: Int,
        actionCount: Int,
        actionEffectCount: Int,
        movementCount: Int,
        totalManhattanDistanceMoved: Int,
        returnHomeMoveCount: Int,
        totalDistanceReducedTowardHome: Int,
        lastWorldObservation: AgentWorldObservation? = nil,
        lastWorldPerceptionEffect: AgentWorldPerceptionEffect? = nil,
        lastMovementOutcome: AgentMovementOutcome? = nil,
        lastFeedbackDecisionTrace: AgentFeedbackDecisionTrace? = nil,
        feedbackMemoryWriteCount: Int = 0,
        feedbackMemoryDeduplicatedCount: Int = 0,
        memoryRetrievalCount: Int = 0,
        memoryInfluencedDecisionCount: Int = 0,
        lastResourceObservations: [AgentResourceObservation] = [],
        activeResourceTarget: AgentResourceTarget? = nil,
        resourceInventory: AgentResourceInventory = AgentResourceInventory(),
        lastInteractionOutcome: AgentInteractionOutcome? = nil,
        navigationProgress: AgentNavigationProgress = AgentNavigationProgress(),
        lastDeliveryOutcome: AgentDeliveryOutcome? = nil,
        survivalProgress: AgentSurvivalProgress? = nil
    ) {
        guard let agentID = AgentID(rawValue: id) else {
            preconditionFailure("invalid AgentID: \(id)")
        }
        self.agentID = agentID
        self.state = state
        self.position = position
        self.needs = needs
        self.health = health
        self.fear = fear
        self.homePosition = homePosition
        self.nearbyAgents = nearbyAgents
        self.currentGoal = currentGoal
        self.lastAction = lastAction
        self.lastActionEffect = lastActionEffect
        self.memory = memory
        self.tickCreated = tickCreated
        self.ticksAlive = ticksAlive
        self.observationCount = observationCount
        self.nearbyObservationCount = nearbyObservationCount
        self.goalSelectionCount = goalSelectionCount
        self.goalChangeCount = goalChangeCount
        self.actionCount = actionCount
        self.actionEffectCount = actionEffectCount
        self.movementCount = movementCount
        self.totalManhattanDistanceMoved = totalManhattanDistanceMoved
        self.returnHomeMoveCount = returnHomeMoveCount
        self.totalDistanceReducedTowardHome = totalDistanceReducedTowardHome
        self.lastWorldObservation = lastWorldObservation
        self.lastWorldPerceptionEffect = lastWorldPerceptionEffect
        self.lastMovementOutcome = lastMovementOutcome
        self.lastFeedbackDecisionTrace = lastFeedbackDecisionTrace
        self.feedbackMemoryWriteCount = feedbackMemoryWriteCount
        self.feedbackMemoryDeduplicatedCount = feedbackMemoryDeduplicatedCount
        self.memoryRetrievalCount = memoryRetrievalCount
        self.memoryInfluencedDecisionCount = memoryInfluencedDecisionCount
        self.lastResourceObservations = lastResourceObservations
        self.activeResourceTarget = activeResourceTarget
        self.resourceInventory = resourceInventory
        self.lastInteractionOutcome = lastInteractionOutcome
        self.navigationProgress = navigationProgress
        self.lastDeliveryOutcome = lastDeliveryOutcome
        self.survivalProgress = survivalProgress
    }

    public init(
        agentID: AgentID,
        state: String,
        position: AgentPosition,
        needs: AgentNeeds,
        health: Int,
        fear: Int,
        homePosition: AgentPosition,
        nearbyAgents: [AgentNearbyObservation],
        currentGoal: AgentGoal,
        lastAction: AgentAction?,
        lastActionEffect: AgentActionEffect?,
        memory: [AgentMemoryEntry],
        tickCreated: Int,
        ticksAlive: Int,
        observationCount: Int,
        nearbyObservationCount: Int,
        goalSelectionCount: Int,
        goalChangeCount: Int,
        actionCount: Int,
        actionEffectCount: Int,
        movementCount: Int,
        totalManhattanDistanceMoved: Int,
        returnHomeMoveCount: Int,
        totalDistanceReducedTowardHome: Int,
        lastWorldObservation: AgentWorldObservation? = nil,
        lastWorldPerceptionEffect: AgentWorldPerceptionEffect? = nil,
        lastMovementOutcome: AgentMovementOutcome? = nil,
        lastFeedbackDecisionTrace: AgentFeedbackDecisionTrace? = nil,
        feedbackMemoryWriteCount: Int = 0,
        feedbackMemoryDeduplicatedCount: Int = 0,
        memoryRetrievalCount: Int = 0,
        memoryInfluencedDecisionCount: Int = 0,
        lastResourceObservations: [AgentResourceObservation] = [],
        activeResourceTarget: AgentResourceTarget? = nil,
        resourceInventory: AgentResourceInventory = AgentResourceInventory(),
        lastInteractionOutcome: AgentInteractionOutcome? = nil,
        navigationProgress: AgentNavigationProgress = AgentNavigationProgress(),
        lastDeliveryOutcome: AgentDeliveryOutcome? = nil,
        survivalProgress: AgentSurvivalProgress? = nil
    ) {
        self.init(
            id: agentID.rawValue, state: state, position: position, needs: needs,
            health: health, fear: fear, homePosition: homePosition, nearbyAgents: nearbyAgents,
            currentGoal: currentGoal, lastAction: lastAction, lastActionEffect: lastActionEffect,
            memory: memory, tickCreated: tickCreated, ticksAlive: ticksAlive,
            observationCount: observationCount, nearbyObservationCount: nearbyObservationCount,
            goalSelectionCount: goalSelectionCount, goalChangeCount: goalChangeCount,
            actionCount: actionCount, actionEffectCount: actionEffectCount,
            movementCount: movementCount, totalManhattanDistanceMoved: totalManhattanDistanceMoved,
            returnHomeMoveCount: returnHomeMoveCount,
            totalDistanceReducedTowardHome: totalDistanceReducedTowardHome,
            lastWorldObservation: lastWorldObservation,
            lastWorldPerceptionEffect: lastWorldPerceptionEffect,
            lastMovementOutcome: lastMovementOutcome,
            lastFeedbackDecisionTrace: lastFeedbackDecisionTrace,
            feedbackMemoryWriteCount: feedbackMemoryWriteCount,
            feedbackMemoryDeduplicatedCount: feedbackMemoryDeduplicatedCount,
            memoryRetrievalCount: memoryRetrievalCount,
            memoryInfluencedDecisionCount: memoryInfluencedDecisionCount,
            lastResourceObservations: lastResourceObservations,
            activeResourceTarget: activeResourceTarget, resourceInventory: resourceInventory,
            lastInteractionOutcome: lastInteractionOutcome, navigationProgress: navigationProgress,
            lastDeliveryOutcome: lastDeliveryOutcome, survivalProgress: survivalProgress
        )
    }
}

public struct AgentPerceptionInput: Codable {
    public let agentId: String
    public let observationCountIncrement: Int
    public let externalMemoryEntries: [AgentMemoryEntry]
    public let worldObservation: AgentWorldObservation?
    public let resourceObservations: [AgentResourceObservation]
    public let socialResourceObservations: [AgentResourceObservation]
    public let navigationObservation: AgentNavigationObservation?

    public init(
        agentId: String,
        observationCountIncrement: Int = 0,
        externalMemoryEntries: [AgentMemoryEntry] = [],
        worldObservation: AgentWorldObservation? = nil,
        resourceObservations: [AgentResourceObservation] = [],
        socialResourceObservations: [AgentResourceObservation] = [],
        navigationObservation: AgentNavigationObservation? = nil
    ) {
        self.agentId = agentId
        self.observationCountIncrement = observationCountIncrement
        self.externalMemoryEntries = externalMemoryEntries
        self.worldObservation = worldObservation
        self.resourceObservations = resourceObservations
        self.socialResourceObservations = socialResourceObservations
        self.navigationObservation = navigationObservation
    }
}

public struct AgentExternalUpdate: Codable {
    public let agentId: String
    public let position: AgentPosition?
    public let memoryEntries: [AgentMemoryEntry]
    public let movementCount: Int?
    public let totalManhattanDistanceMoved: Int?
    public let returnHomeMoveCount: Int?
    public let totalDistanceReducedTowardHome: Int?

    public init(
        agentId: String,
        position: AgentPosition? = nil,
        memoryEntries: [AgentMemoryEntry] = [],
        movementCount: Int? = nil,
        totalManhattanDistanceMoved: Int? = nil,
        returnHomeMoveCount: Int? = nil,
        totalDistanceReducedTowardHome: Int? = nil
    ) {
        self.agentId = agentId
        self.position = position
        self.memoryEntries = memoryEntries
        self.movementCount = movementCount
        self.totalManhattanDistanceMoved = totalManhattanDistanceMoved
        self.returnHomeMoveCount = returnHomeMoveCount
        self.totalDistanceReducedTowardHome = totalDistanceReducedTowardHome
    }
}

public struct AgentSessionAgentTickResult {
    public let agentId: String
    public let goalChange: AgentGoalChange?
    public let action: AgentAction
    public let actionEffect: AgentActionEffect
    public let memoriesAdded: [AgentMemoryEntry]
    public let worldPerceptionEffect: AgentWorldPerceptionEffect?
    public let snapshot: AgentSnapshot

    init(
        agentId: String,
        goalChange: AgentGoalChange?,
        action: AgentAction,
        actionEffect: AgentActionEffect,
        memoriesAdded: [AgentMemoryEntry],
        worldPerceptionEffect: AgentWorldPerceptionEffect?,
        snapshot: AgentSnapshot
    ) {
        self.agentId = agentId
        self.goalChange = goalChange
        self.action = action
        self.actionEffect = actionEffect
        self.memoriesAdded = memoriesAdded
        self.worldPerceptionEffect = worldPerceptionEffect
        self.snapshot = snapshot
    }
}

public struct AgentSessionTickResult {
    public let tick: Int
    public let agents: [AgentSessionAgentTickResult]

    init(tick: Int, agents: [AgentSessionAgentTickResult]) {
        self.tick = tick
        self.agents = agents
    }
}
