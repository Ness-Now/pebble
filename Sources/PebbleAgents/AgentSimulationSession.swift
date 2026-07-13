public enum AgentMemoryPolicy: Equatable {
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
}

public struct AgentSessionConfiguration {
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
        survivalConfiguration: AgentSurvivalConfiguration = .live
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
    }
}

public struct AgentSessionAgentState {
    public internal(set) var id: String
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
        self.id = id
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
}

public struct AgentPerceptionInput {
    public let agentId: String
    public let observationCountIncrement: Int
    public let externalMemoryEntries: [AgentMemoryEntry]
    public let worldObservation: AgentWorldObservation?
    public let resourceObservations: [AgentResourceObservation]
    public let navigationObservation: AgentNavigationObservation?

    public init(
        agentId: String,
        observationCountIncrement: Int = 0,
        externalMemoryEntries: [AgentMemoryEntry] = [],
        worldObservation: AgentWorldObservation? = nil,
        resourceObservations: [AgentResourceObservation] = [],
        navigationObservation: AgentNavigationObservation? = nil
    ) {
        self.agentId = agentId
        self.observationCountIncrement = observationCountIncrement
        self.externalMemoryEntries = externalMemoryEntries
        self.worldObservation = worldObservation
        self.resourceObservations = resourceObservations
        self.navigationObservation = navigationObservation
    }
}

public struct AgentExternalUpdate {
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

public struct AgentSimulationSession {
    public static let maximumConsumptionCount = AgentSurvivalProgress.maximumEventCount
    public let configuration: AgentSessionConfiguration
    public private(set) var tick: Int
    private var statesById: [String: AgentSessionAgentState]
    private var processedInteractionIds: Set<String>
    private var creditedResourceKeys: Set<String>
    private var reservationsByTarget: [String: AgentResourceReservation]
    public private(set) var economyEnabled: Bool
    public private(set) var campStock: AgentCampStock
    private var harvestedResourceTotals: AgentCampStock
    private var processedDeliveryIds: Set<String>
    public private(set) var survivalEnabled: Bool
    private var consumedResourceTotals: AgentCampStock
    private var processedConsumptionIds: Set<String>

    public init(
        configuration: AgentSessionConfiguration,
        agents: [AgentSessionAgentState],
        initialTick: Int = 0
    ) throws {
        guard initialTick >= 0 else {
            throw AgentSessionError.invalidInitialTick(initialTick)
        }
        var states: [String: AgentSessionAgentState] = [:]
        for var agent in agents {
            guard states[agent.id] == nil else {
                throw AgentSessionError.duplicateAgentId(agent.id)
            }
            applyMemoryPolicy(configuration.memoryPolicy, to: &agent.memory)
            states[agent.id] = agent
        }
        self.configuration = configuration
        tick = initialTick
        statesById = states
        processedInteractionIds = []
        creditedResourceKeys = []
        reservationsByTarget = [:]
        economyEnabled = false
        campStock = AgentCampStock(capacity: configuration.campStockCapacity)
        harvestedResourceTotals = AgentCampStock(capacity: 4096)
        processedDeliveryIds = []
        survivalEnabled = false
        consumedResourceTotals = AgentCampStock(capacity: 4096)
        processedConsumptionIds = []
    }

    public func snapshot() -> AgentSessionSnapshot {
        let agents = sortedIds.compactMap { id in
            statesById[id].map {
                AgentSnapshot(
                    state: $0,
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit,
                    resourceReservation: reservation(for: $0),
                    survivalEnabled: survivalEnabled
                )
            }
        }
        return AgentSessionSnapshot(
            seed: configuration.seed,
            tick: tick,
            agents: agents,
            resourceReservations: reservationsByTarget.values.sorted(by: reservationSort),
            economyEnabled: economyEnabled,
            deliveryQuota: configuration.deliveryQuota,
            campStock: campStock,
            conservation: conservationSnapshot(),
            survivalEnabled: survivalEnabled,
            survivalConfiguration: configuration.survivalConfiguration
        )
    }

    public func state(for agentId: String) throws -> AgentSessionAgentState {
        guard let state = statesById[agentId] else {
            throw AgentSessionError.unknownAgentId(agentId)
        }
        return state
    }

    public mutating func setEconomyEnabled(_ enabled: Bool) {
        economyEnabled = enabled
        guard !enabled else { return }
        reservationsByTarget.removeAll()
        for id in sortedIds {
            guard var state = statesById[id] else { continue }
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress()
            if state.currentGoal.kind == .deliverResources {
                state.currentGoal = AgentGoal(
                    kind: .idle,
                    reason: "economy disabled",
                    startedAtTick: tick,
                    urgency: 0
                )
            }
            statesById[id] = state
        }
    }

    public mutating func setSurvivalEnabled(_ enabled: Bool) {
        survivalEnabled = enabled
        for id in sortedIds {
            guard var state = statesById[id] else { continue }
            if enabled {
                if state.survivalProgress == nil {
                    state.survivalProgress = AgentSurvivalProgress()
                }
            } else {
                if state.currentGoal.kind == .satisfyHunger {
                    releaseReservation(for: state)
                    state.activeResourceTarget = nil
                    state.navigationProgress = AgentNavigationProgress()
                } else if state.currentGoal.kind == .rest,
                          state.navigationProgress.route?.purpose == .homeRest {
                    state.navigationProgress = AgentNavigationProgress()
                }
                if state.currentGoal.kind == .satisfyHunger || state.currentGoal.kind == .rest {
                    state.currentGoal = AgentGoal(
                        kind: .idle,
                        reason: "survival disabled",
                        startedAtTick: tick,
                        urgency: 0
                    )
                }
                state.survivalProgress = nil
            }
            statesById[id] = state
        }
    }

    public func conservationSnapshot() -> AgentResourceConservationSnapshot {
        let carried = AgentResourceKind.allCases.map { resource in
            AgentResourceAmount(
                resource: resource,
                quantity: statesById.values.reduce(0) {
                    $0 + $1.resourceInventory.count(of: resource)
                }
            )
        }
        return AgentResourceConservationSnapshot(
            harvested: harvestedResourceTotals.amounts,
            carried: carried,
            campStock: campStock.amounts,
            consumed: consumedResourceTotals.amounts
        )
    }

    public func prevalidateConsumption(_ intent: AgentConsumptionIntent) throws {
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard survivalEnabled else {
            throw AgentSessionError.survivalDisabled(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.consumptionTickMismatch(intent.consumptionId)
        }
        guard !processedConsumptionIds.contains(intent.consumptionId) else {
            throw AgentSessionError.duplicateConsumption(intent.consumptionId)
        }
        guard processedConsumptionIds.count < Self.maximumConsumptionCount else {
            throw AgentSessionError.consumptionLimitReached
        }
        guard intent.resource == .foodRaw else {
            throw AgentSessionError.invalidConsumptionResource(intent.consumptionId)
        }
        guard intent.quantity == 1 else {
            throw AgentSessionError.invalidConsumptionQuantity(intent.consumptionId)
        }
        guard state.survivalProgress != nil else {
            throw AgentSessionError.survivalDisabled(intent.agentId)
        }
    }

    @discardableResult
    public mutating func consumeFood(_ intent: AgentConsumptionIntent) throws -> AgentConsumptionOutcome {
        try prevalidateConsumption(intent)
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        let hasFood = state.resourceInventory.count(of: .foodRaw) >= intent.quantity
        let hungerAfter = hasFood
            ? max(0, state.needs.hunger - configuration.survivalConfiguration.foodNutrition)
            : state.needs.hunger
        let outcome = AgentConsumptionOutcome(
            consumptionId: intent.consumptionId,
            agentId: intent.agentId,
            tick: tick,
            resource: intent.resource,
            quantity: intent.quantity,
            status: hasFood ? .succeeded : .foodUnavailable,
            hungerBefore: state.needs.hunger,
            hungerAfter: hungerAfter,
            reason: hasFood
                ? "one carried foodRaw consumed atomically"
                : "no carried foodRaw available"
        )
        try applyConsumptionOutcome(outcome)
        return outcome
    }

    public mutating func applyConsumptionOutcome(_ outcome: AgentConsumptionOutcome) throws {
        var candidate = self
        try candidate.applyConsumptionOutcomeInPlace(outcome)
        self = candidate
    }

    private mutating func applyConsumptionOutcomeInPlace(
        _ outcome: AgentConsumptionOutcome
    ) throws {
        guard var state = statesById[outcome.agentId],
              var progress = state.survivalProgress else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard survivalEnabled else {
            throw AgentSessionError.survivalDisabled(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.consumptionTickMismatch(outcome.consumptionId)
        }
        guard !processedConsumptionIds.contains(outcome.consumptionId) else {
            throw AgentSessionError.duplicateConsumption(outcome.consumptionId)
        }
        guard processedConsumptionIds.count < Self.maximumConsumptionCount else {
            throw AgentSessionError.consumptionLimitReached
        }
        guard outcome.resource == .foodRaw else {
            throw AgentSessionError.invalidConsumptionResource(outcome.consumptionId)
        }
        guard outcome.quantity == 1 else {
            throw AgentSessionError.invalidConsumptionQuantity(outcome.consumptionId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            let expectedHunger = max(
                0,
                state.needs.hunger - configuration.survivalConfiguration.foodNutrition
            )
            var inventory = state.resourceInventory
            var consumed = consumedResourceTotals
            guard outcome.hungerBefore == state.needs.hunger,
                  outcome.hungerAfter == expectedHunger,
                  inventory.remove(.foodRaw, quantity: 1),
                  consumed.add(.foodRaw, quantity: 1) else {
                throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
            }
            state.resourceInventory = inventory
            state.needs.hunger = expectedHunger
            consumedResourceTotals = consumed
            progress.consecutiveCriticalHungerTicks = 0
            progress.foodConsumedCount = min(
                AgentSurvivalProgress.maximumEventCount,
                progress.foodConsumedCount + 1
            )
            progress.status = expectedHunger <= configuration.survivalConfiguration.hungerRecoveryThreshold
                ? .stable
                : .hungry
            memory = AgentMemoryEntry(
                tick: tick,
                type: "food_consumed",
                summary: "\(outcome.agentId) consumed 1 foodRaw",
                importance: 0.50
            )
        case .blocked, .foodUnavailable:
            guard outcome.hungerBefore == state.needs.hunger,
                  outcome.hungerAfter == state.needs.hunger else {
                throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "consumption_blocked",
                summary: "\(outcome.agentId) consumption blocked: \(outcome.reason)",
                importance: 0.30
            )
        }
        progress.lastConsumptionOutcome = outcome
        progress.lastMemoryType = AgentSurvivalMemoryType(rawValue: memory.type)
        state.survivalProgress = progress
        appendMemory(memory, to: &state.memory)
        statesById[outcome.agentId] = state
        processedConsumptionIds.insert(outcome.consumptionId)
        guard conservationSnapshot().balanced else {
            throw AgentSessionError.invalidConsumptionOutcome(outcome.consumptionId)
        }
    }

    public func prevalidateDelivery(_ intent: AgentDeliveryIntent) throws {
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.deliveryTickMismatch(intent.deliveryId)
        }
        guard !processedDeliveryIds.contains(intent.deliveryId) else {
            throw AgentSessionError.duplicateDelivery(intent.deliveryId)
        }
        guard intent.position == state.position, state.position == state.homePosition else {
            throw AgentSessionError.deliveryAwayFromHome(intent.agentId)
        }
        guard !state.resourceInventory.isEmpty else {
            throw AgentSessionError.emptyDelivery(intent.agentId)
        }
    }

    @discardableResult
    public mutating func deliverResources(_ intent: AgentDeliveryIntent) throws -> AgentDeliveryOutcome {
        try prevalidateDelivery(intent)
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        let transferred = state.resourceInventory.amounts
        let outcome = AgentDeliveryOutcome(
            deliveryId: intent.deliveryId,
            agentId: intent.agentId,
            tick: tick,
            status: campStock.canAdd(transferred) ? .succeeded : .campStockFull,
            transferred: campStock.canAdd(transferred) ? transferred : [],
            reason: campStock.canAdd(transferred)
                ? "inventory delivered atomically to camp stock"
                : "camp stock capacity reached"
        )
        try applyDeliveryOutcome(outcome)
        return outcome
    }

    public mutating func applyDeliveryOutcome(_ outcome: AgentDeliveryOutcome) throws {
        var candidate = self
        try candidate.applyDeliveryOutcomeInPlace(outcome)
        self = candidate
    }

    private mutating func applyDeliveryOutcomeInPlace(_ outcome: AgentDeliveryOutcome) throws {
        guard var state = statesById[outcome.agentId] else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.deliveryTickMismatch(outcome.deliveryId)
        }
        guard !processedDeliveryIds.contains(outcome.deliveryId) else {
            throw AgentSessionError.duplicateDelivery(outcome.deliveryId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            let expected = state.resourceInventory.amounts
            guard state.position == state.homePosition,
                  !expected.isEmpty,
                  outcome.transferred == expected,
                  campStock.canAdd(expected) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            guard state.resourceInventory.removeAll(expected), campStock.add(expected) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "resource_delivered",
                summary: "\(outcome.agentId) delivered \(expected.reduce(0) { $0 + $1.quantity }) resources",
                importance: 0.45
            )
            state.navigationProgress = AgentNavigationProgress(lastInvalidation: .delivered)
        case .blocked:
            guard outcome.transferred.isEmpty else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "delivery_blocked",
                summary: "\(outcome.agentId) delivery blocked: \(outcome.reason)",
                importance: 0.25
            )
        case .campStockFull:
            guard outcome.transferred.isEmpty, !campStock.canAdd(state.resourceInventory.amounts) else {
                throw AgentSessionError.invalidDeliveryOutcome(outcome.deliveryId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "camp_stock_full",
                summary: "\(outcome.agentId) camp stock full",
                importance: 0.30
            )
        }
        appendMemory(memory, to: &state.memory)
        state.lastDeliveryOutcome = outcome
        statesById[outcome.agentId] = state
        processedDeliveryIds.insert(outcome.deliveryId)
    }

    public func prevalidateInteraction(_ intent: AgentInteractionIntent) throws {
        guard let state = statesById[intent.agentId] else {
            throw AgentSessionError.unknownAgentId(intent.agentId)
        }
        guard intent.tick == tick else {
            throw AgentSessionError.interactionTickMismatch(intent.interactionId)
        }
        guard intent.quantity == 1 else {
            throw AgentSessionError.invalidInteractionQuantity(intent.interactionId)
        }
        guard !processedInteractionIds.contains(intent.interactionId) else {
            throw AgentSessionError.duplicateInteraction(intent.interactionId)
        }
        guard state.resourceInventory.canAdd(intent.resource, quantity: intent.quantity) else {
            throw AgentSessionError.inventoryFull(intent.agentId)
        }
    }

    public mutating func applyInteractionOutcome(_ outcome: AgentInteractionOutcome) throws {
        guard var state = statesById[outcome.agentId] else {
            throw AgentSessionError.unknownAgentId(outcome.agentId)
        }
        guard outcome.tick == tick else {
            throw AgentSessionError.interactionTickMismatch(outcome.interactionId)
        }
        guard !processedInteractionIds.contains(outcome.interactionId) else {
            throw AgentSessionError.duplicateInteraction(outcome.interactionId)
        }

        let memory: AgentMemoryEntry
        switch outcome.status {
        case .succeeded:
            let creditKey = reservationKey(target: outcome.target, resource: outcome.resource)
            guard !creditedResourceKeys.contains(creditKey) else {
                throw AgentSessionError.duplicateResourceCredit(creditKey)
            }
            var nextInventory = state.resourceInventory
            var nextHarvestedTotals = harvestedResourceTotals
            guard outcome.inventoryDelta.resource == outcome.resource,
                  outcome.inventoryDelta.quantity == 1,
                  nextInventory.add(outcome.resource, quantity: 1),
                  nextHarvestedTotals.add(outcome.resource, quantity: 1) else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            state.resourceInventory = nextInventory
            harvestedResourceTotals = nextHarvestedTotals
            memory = AgentMemoryEntry(
                tick: tick,
                type: "resource_harvested",
                summary: "\(outcome.agentId) harvested 1 \(outcome.resource.rawValue)",
                importance: 0.40
            )
            reservationsByTarget.removeValue(forKey: reservationKey(
                target: outcome.target,
                resource: outcome.resource
            ))
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress(
                lastInvalidation: .harvested
            )
            creditedResourceKeys.insert(creditKey)
        case .blocked:
            guard outcome.inventoryDelta.quantity == 0 else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "interaction_blocked",
                summary: "\(outcome.agentId) interaction blocked: \(outcome.reason)",
                importance: 0.25
            )
        case .inventoryFull:
            guard outcome.inventoryDelta.quantity == 0,
                  !state.resourceInventory.canAdd(outcome.resource) else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "inventory_full",
                summary: "\(outcome.agentId) inventory full for \(outcome.resource.rawValue)",
                importance: 0.30
            )
        }

        appendMemory(memory, to: &state.memory)
        state.lastInteractionOutcome = outcome
        statesById[outcome.agentId] = state
        processedInteractionIds.insert(outcome.interactionId)
    }

    public mutating func advanceTick(
        perceptions: [AgentPerceptionInput] = []
    ) throws -> AgentSessionTickResult {
        var perceptionsById: [String: AgentPerceptionInput] = [:]
        var resourceObservationsById: [String: [AgentResourceObservation]] = [:]
        for perception in perceptions {
            guard statesById[perception.agentId] != nil else {
                throw AgentSessionError.unknownAgentId(perception.agentId)
            }
            guard perceptionsById[perception.agentId] == nil else {
                throw AgentSessionError.duplicatePerceptionInput(perception.agentId)
            }
            if let observation = perception.worldObservation,
               observation.position != statesById[perception.agentId]?.position {
                throw AgentSessionError.worldObservationPositionMismatch(perception.agentId)
            }
            if let position = statesById[perception.agentId]?.position {
                resourceObservationsById[perception.agentId] = try AgentResourcePerception.normalize(
                    observerPosition: position,
                    observations: perception.resourceObservations,
                    maximumDistance: configuration.resourceObservationRadius
                )
            }
            if let navigation = perception.navigationObservation {
                guard navigation.origin == statesById[perception.agentId]?.position,
                      (1...AgentNavigationObservation.maximumRadius).contains(navigation.radius),
                      navigation.cells.count <= AgentNavigationObservation.maximumCellCount else {
                    throw AgentSessionError.invalidNavigationObservation(perception.agentId)
                }
            }
            perceptionsById[perception.agentId] = perception
        }

        let nextTick = tick + 1
        let ids = sortedIds
        reservationsByTarget = reservationsByTarget.filter { !$0.value.isExpired(at: nextTick) }
        for id in ids {
            guard var state = statesById[id] else { continue }
            let previousTarget = state.activeResourceTarget
            state.lastResourceObservations = resourceObservationsById[id] ?? []
            if shouldSatisfyHunger(state, projectedToNextTick: true) {
                let foodObservations = state.lastResourceObservations.filter {
                    $0.resource == .foodRaw
                }
                state.activeResourceTarget = state.resourceInventory.count(of: .foodRaw) > 0
                    ? nil
                    : AgentResourceTargeting.select(
                        current: previousTarget?.resource == .foodRaw ? previousTarget : nil,
                        observations: foodObservations,
                        inventory: state.resourceInventory,
                        tick: nextTick
                    )
            } else if shouldRest(state, projectedToNextTick: true) {
                state.activeResourceTarget = nil
            } else if shouldDeliverResources(state) {
                state.activeResourceTarget = nil
            } else if survivalEnabled && !economyEnabled {
                state.activeResourceTarget = nil
            } else {
                state.activeResourceTarget = AgentResourceTargeting.select(
                    current: previousTarget,
                    observations: state.lastResourceObservations,
                    inventory: state.resourceInventory,
                    tick: nextTick
                )
            }
            if let previousTarget,
               state.activeResourceTarget?.target != previousTarget.target
                    || state.activeResourceTarget?.resource != previousTarget.resource {
                state.navigationProgress = AgentNavigationProgress(
                    replanCount: 0,
                    lastInvalidation: state.activeResourceTarget == nil ? .targetGone : .targetChanged
                )
            }
            statesById[id] = state
        }
        reconcileReservations(at: nextTick)
        let peers = ids.compactMap { id in
            statesById[id].map { AgentPeerSnapshot(id: id, position: $0.position) }
        }
        var results: [AgentSessionAgentTickResult] = []

        for id in ids {
            guard var state = statesById[id] else { continue }
            let perception = perceptionsById[id]
            var memoriesAdded = perception?.externalMemoryEntries ?? []

            let survivalMemory: AgentMemoryEntry?
            if survivalEnabled {
                survivalMemory = applySurvivalTick(to: &state, tick: nextTick)
            } else {
                let tickTransition = AgentCognitiveTransitions.advanceTick(needs: state.needs)
                state.needs = tickTransition.needs
                state.state = tickTransition.state
                survivalMemory = nil
            }
            state.ticksAlive += 1

            appendMemories(memoriesAdded, to: &state.memory)
            if let survivalMemory {
                appendMemory(survivalMemory, to: &state.memory)
                memoriesAdded.append(survivalMemory)
            }
            var worldPerceptionEffect: AgentWorldPerceptionEffect?
            if let observation = perception?.worldObservation {
                let effect = AgentWorldPerceptionInterpreter.interpret(
                    agentId: id,
                    tick: nextTick,
                    observation: observation,
                    needs: state.needs,
                    fear: state.fear
                )
                state.lastWorldObservation = observation
                state.lastWorldPerceptionEffect = effect
                state.needs.safety = effect.safetyAfter
                state.needs.curiosity = effect.curiosityAfter
                state.fear = effect.fearAfter
                state.observationCount += 1
                let worldMemory = AgentMemoryEntry(
                    tick: nextTick,
                    type: "world_observed",
                    summary: effect.memorySummary,
                    importance: effect.memoryImportance
                )
                appendMemory(worldMemory, to: &state.memory)
                memoriesAdded.append(worldMemory)
                worldPerceptionEffect = effect
            }
            state.observationCount += perception?.observationCountIncrement ?? 0

            state.nearbyAgents = AgentCognitiveTransitions.observeNearbyAgents(
                observerId: id,
                observerPosition: state.position,
                peers: peers,
                radius: configuration.nearbyRadius
            )
            state.nearbyObservationCount += state.nearbyAgents.count

            state.goalSelectionCount += 1
            let goalChange = AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
                tick: nextTick,
                health: state.health,
                fear: state.fear,
                needs: state.needs,
                hasNearbyAgents: !state.nearbyAgents.isEmpty,
                hasCollectibleAdjacentResource: state.activeResourceTarget != nil,
                hasInventoryCapacity: state.activeResourceTarget.map {
                    state.resourceInventory.canAdd($0.resource)
                } ?? false,
                hasCommittedResourceTask: (state.currentGoal.kind == .collectResource
                    || state.currentGoal.kind == .satisfyHunger)
                    && reservation(for: state)?.agentId == id,
                shouldDeliverResources: shouldDeliverResources(state),
                currentGoalKind: state.currentGoal.kind,
                survivalEnabled: survivalEnabled,
                hungryThreshold: configuration.survivalConfiguration.hungryThreshold,
                criticalHungerThreshold: configuration.survivalConfiguration.criticalHungerThreshold,
                hungerRecoveryThreshold: configuration.survivalConfiguration.hungerRecoveryThreshold,
                fatigueThreshold: configuration.survivalConfiguration.fatigueThreshold,
                fatigueRecoveryThreshold: configuration.survivalConfiguration.fatigueRecoveryThreshold
            ))
            if let goalChange {
                state.currentGoal = goalChange.goal
                state.goalChangeCount += 1
            }

            updateNavigation(
                state: &state,
                observation: perception?.navigationObservation,
                tick: nextTick
            )

            let baseAction = AgentActionDecider.decide(AgentActionDecisionInput(
                agentId: id,
                tick: nextTick,
                goalKind: state.currentGoal.kind,
                position: state.position,
                homePosition: state.homePosition,
                resourceObservations: state.lastResourceObservations,
                activeResourceTarget: state.activeResourceTarget,
                navigationProgress: state.navigationProgress,
                resourceReservation: reservation(for: state),
                survivalEnabled: survivalEnabled,
                hasFoodRaw: state.resourceInventory.count(of: .foodRaw) > 0
            ))
            let retrievedMemories = AgentFeedbackLoop.retrieveMovementMemories(
                memory: state.memory,
                currentTick: nextTick,
                lastMovementOutcome: state.lastMovementOutcome,
                configuration: configuration.feedbackLoopConfiguration
            )
            if !retrievedMemories.isEmpty {
                state.memoryRetrievalCount += 1
            }
            let decisionTrace = AgentFeedbackLoop.adjustAction(
                agentId: id,
                tick: nextTick,
                position: state.position,
                homePosition: state.homePosition,
                goal: state.currentGoal,
                baseAction: baseAction,
                worldObservation: state.lastWorldObservation,
                occupiedPositions: peers.map(\.position),
                lastMovementOutcome: state.lastMovementOutcome,
                retrievedMemories: retrievedMemories,
                configuration: configuration.feedbackLoopConfiguration
            )
            let action = decisionTrace.finalAction
            state.lastFeedbackDecisionTrace = decisionTrace
            if decisionTrace.actionChanged && !decisionTrace.memoryRecordsUsed.isEmpty {
                state.memoryInfluencedDecisionCount += 1
            }
            state.lastAction = action
            state.actionCount += 1
            let actionMemory = AgentMemoryEntry(
                tick: nextTick,
                type: "action_chosen",
                summary: "\(id) chose \(action.name) because \(action.reason)",
                importance: 0.2
            )
            appendMemory(actionMemory, to: &state.memory)
            memoriesAdded.append(actionMemory)

            let effectResult = AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
                action: action,
                goalKind: state.currentGoal.kind,
                distanceFromHome: distanceFromHome(state),
                needs: state.needs,
                fear: state.fear,
                state: state.state,
                tick: nextTick,
                survivalEnabled: survivalEnabled,
                restRecoveryPerTick: configuration.survivalConfiguration.restRecoveryPerTick
            ))
            state.needs = effectResult.needs
            state.fear = effectResult.fear
            state.state = effectResult.state
            state.lastActionEffect = effectResult.actionEffect
            state.actionEffectCount += 1
            if survivalEnabled {
                updateSurvivalProgress(for: &state, action: action)
            }
            let effectMemory = AgentMemoryEntry(
                tick: nextTick,
                type: "action_effect_applied",
                summary: "\(id) applied \(action.name) effect",
                importance: 0.15
            )
            appendMemory(effectMemory, to: &state.memory)
            memoriesAdded.append(effectMemory)

            statesById[id] = state
            results.append(AgentSessionAgentTickResult(
                agentId: id,
                goalChange: goalChange,
                action: action,
                actionEffect: effectResult.actionEffect,
                memoriesAdded: memoriesAdded,
                worldPerceptionEffect: worldPerceptionEffect,
                snapshot: AgentSnapshot(
                    state: state,
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit,
                    resourceReservation: reservation(for: state),
                    survivalEnabled: survivalEnabled
                )
            ))
        }

        tick = nextTick
        return AgentSessionTickResult(tick: tick, agents: results)
    }

    public mutating func applyExternalUpdate(_ update: AgentExternalUpdate) throws {
        guard var state = statesById[update.agentId] else {
            throw AgentSessionError.unknownAgentId(update.agentId)
        }
        if let position = update.position {
            state.position = position
        }
        appendMemories(update.memoryEntries, to: &state.memory)
        if let movementCount = update.movementCount {
            state.movementCount = movementCount
        }
        if let total = update.totalManhattanDistanceMoved {
            state.totalManhattanDistanceMoved = total
        }
        if let count = update.returnHomeMoveCount {
            state.returnHomeMoveCount = count
        }
        if let total = update.totalDistanceReducedTowardHome {
            state.totalDistanceReducedTowardHome = total
        }
        statesById[update.agentId] = state
    }

    public mutating func applyMovementOutcomes(_ outcomes: [AgentMovementOutcome]) throws {
        let ids = sortedIds
        guard outcomes.count == ids.count else {
            throw AgentSessionError.movementOutcomeCountMismatch(expected: ids.count, actual: outcomes.count)
        }
        var byId: [String: AgentMovementOutcome] = [:]
        for outcome in outcomes {
            guard statesById[outcome.agentId] != nil else {
                throw AgentSessionError.unknownAgentId(outcome.agentId)
            }
            guard byId[outcome.agentId] == nil else {
                throw AgentSessionError.duplicateMovementOutcome(outcome.agentId)
            }
            byId[outcome.agentId] = outcome
        }
        for id in ids where byId[id] == nil {
            throw AgentSessionError.missingMovementOutcome(id)
        }

        let initialPositions = statesById.mapValues(\.position)
        var destinationKeys = [String]()
        for id in ids {
            guard let state = statesById[id], let outcome = byId[id] else { continue }
            guard outcome.tick == tick else { throw AgentSessionError.movementTickMismatch(id) }
            guard outcome.fromPosition == state.position else {
                throw AgentSessionError.movementFromPositionMismatch(id)
            }
            guard outcome.goalKind == state.currentGoal.kind else {
                throw AgentSessionError.movementGoalMismatch(id)
            }
            let dx = outcome.toPosition.x - outcome.fromPosition.x
            let dy = outcome.toPosition.y - outcome.fromPosition.y
            let dz = outcome.toPosition.z - outcome.fromPosition.z
            switch outcome.status {
            case .moved:
                guard dx == outcome.appliedDX, dy == outcome.appliedDY, dz == outcome.appliedDZ else {
                    throw AgentSessionError.inconsistentMovementDelta(id)
                }
                guard abs(dx) + abs(dz) == 1 else {
                    throw AgentSessionError.invalidCardinalMovement(id)
                }
                guard (-1...1).contains(dy) else {
                    throw AgentSessionError.invalidVerticalMovement(id)
                }
                guard let action = state.lastAction,
                      action.name == "move_abstract"
                        || action.name == "approach_resource"
                        || action.name == "return_home",
                      outcome.requestedDX == (action.dx ?? 0),
                      outcome.requestedDY == (action.dy ?? 0),
                      outcome.requestedDZ == (action.dz ?? 0),
                      outcome.actionReason == action.reason,
                      outcome.appliedDX == outcome.requestedDX,
                      outcome.appliedDZ == outcome.requestedDZ else {
                    throw AgentSessionError.movementActionMismatch(id)
                }
                guard outcome.requestedDirection?.dx == outcome.appliedDX,
                      outcome.requestedDirection?.dz == outcome.appliedDZ else {
                    throw AgentSessionError.movementDirectionMismatch(id)
                }
                let destinationKey = positionKey(outcome.toPosition)
                guard !destinationKeys.contains(destinationKey) else {
                    throw AgentSessionError.duplicateMovementDestination
                }
                destinationKeys.append(destinationKey)
                if initialPositions.contains(where: { otherId, position in
                    otherId != id && position == outcome.toPosition
                }) {
                    throw AgentSessionError.occupiedMovementDestination(id)
                }
            case .blocked, .notRequested:
                guard outcome.toPosition == outcome.fromPosition,
                      outcome.appliedDX == 0,
                      outcome.appliedDY == 0,
                      outcome.appliedDZ == 0 else {
                    throw AgentSessionError.invalidStationaryMovement(id)
                }
            }
            let distanceBefore = manhattanDistance(outcome.fromPosition, state.homePosition)
            let distanceAfter = manhattanDistance(outcome.toPosition, state.homePosition)
            guard outcome.distanceFromHomeBefore == distanceBefore,
                  outcome.distanceFromHomeAfter == distanceAfter,
                  outcome.distanceReducedTowardHome == max(0, distanceBefore - distanceAfter) else {
                throw AgentSessionError.movementHomeMetricsMismatch(id)
            }
        }

        var updated = statesById
        for id in ids {
            guard var state = updated[id], let outcome = byId[id] else { continue }
            state.lastMovementOutcome = outcome
            switch outcome.status {
            case .moved:
                state.position = outcome.toPosition
                state.movementCount += 1
                state.totalManhattanDistanceMoved += abs(outcome.appliedDX) + abs(outcome.appliedDZ)
                if (state.currentGoal.kind == .seekSafety
                        || state.currentGoal.kind == .deliverResources
                        || (survivalEnabled && state.currentGoal.kind == .rest)),
                   outcome.distanceReducedTowardHome > 0 {
                    state.returnHomeMoveCount += 1
                    state.totalDistanceReducedTowardHome += outcome.distanceReducedTowardHome
                }
                if state.lastAction?.name == "approach_resource"
                    || state.lastAction?.name == "return_home" {
                    guard let route = state.navigationProgress.route,
                          state.navigationProgress.status == .active,
                          state.navigationProgress.nextStep == outcome.toPosition else {
                        throw AgentSessionError.movementActionMismatch(id)
                    }
                    let nextIndex = state.navigationProgress.routeIndex + 1
                    let arrived = nextIndex == route.positions.count - 1
                    state.navigationProgress = AgentNavigationProgress(
                        status: arrived ? .arrived : .active,
                        route: route,
                        routeIndex: nextIndex,
                        replanCount: state.navigationProgress.replanCount,
                        consecutiveBlockedMoves: 0,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation,
                        lastFailure: nil
                    )
                }
                if let entry = AgentFeedbackLoop.movementMemoryEntry(outcome: outcome) {
                    appendMemory(entry, to: &state.memory)
                    state.feedbackMemoryWriteCount += 1
                }
            case .blocked:
                if state.lastAction?.name == "approach_resource"
                    || state.lastAction?.name == "return_home" {
                    state.navigationProgress = AgentNavigationProgress(
                        status: state.navigationProgress.status,
                        route: state.navigationProgress.route,
                        routeIndex: state.navigationProgress.routeIndex,
                        replanCount: state.navigationProgress.replanCount,
                        consecutiveBlockedMoves: state.navigationProgress.consecutiveBlockedMoves + 1,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation,
                        lastFailure: .movementBlocked
                    )
                }
                if let entry = AgentFeedbackLoop.movementMemoryEntry(outcome: outcome) {
                    if AgentFeedbackLoop.isDuplicateBlockedMemory(
                        candidate: entry,
                        memory: state.memory,
                        currentTick: tick,
                        configuration: configuration.feedbackLoopConfiguration
                    ) {
                        state.feedbackMemoryDeduplicatedCount += 1
                    } else {
                        appendMemory(entry, to: &state.memory)
                        state.feedbackMemoryWriteCount += 1
                    }
                }
            case .notRequested:
                break
            }
            updated[id] = state
        }
        statesById = updated
    }

    private mutating func reconcileReservations(at reservationTick: Int) {
        var candidateIdsByTarget: [String: [String]] = [:]
        for id in sortedIds {
            guard let target = statesById[id]?.activeResourceTarget else { continue }
            candidateIdsByTarget[reservationKey(target: target.target, resource: target.resource), default: []]
                .append(id)
        }

        var updated: [String: AgentResourceReservation] = [:]
        for key in candidateIdsByTarget.keys.sorted() {
            guard let ids = candidateIdsByTarget[key]?.sorted(),
                  let firstId = ids.first,
                  let target = statesById[firstId]?.activeResourceTarget else { continue }
            let prior = reservationsByTarget[key]
            let owner = prior.flatMap { ids.contains($0.agentId) ? $0.agentId : nil } ?? firstId
            updated[key] = AgentResourceReservation(
                agentId: owner,
                target: target.target,
                resource: target.resource,
                acquiredAtTick: prior?.agentId == owner ? prior!.acquiredAtTick : reservationTick,
                expiresAtTick: reservationTick + configuration.reservationLifetimeTicks
            )
            for id in ids where id != owner {
                guard var state = statesById[id] else { continue }
                state.navigationProgress = AgentNavigationProgress(
                    status: .failed,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .reservationConflict,
                    lastFailure: .reservationConflict
                )
                statesById[id] = state
            }
        }
        reservationsByTarget = updated
    }

    private mutating func updateNavigation(
        state: inout AgentSessionAgentState,
        observation: AgentNavigationObservation?,
        tick navigationTick: Int
    ) {
        let purpose: AgentNavigationPurpose
        let targetPosition: AgentPosition
        let targetResource: AgentResourceKind?
        let goalMode: AgentNavigationGoalMode
        switch state.currentGoal.kind {
        case .collectResource, .satisfyHunger:
            guard let target = state.activeResourceTarget else {
                if state.navigationProgress.status != .idle || state.navigationProgress.route != nil {
                    state.navigationProgress = AgentNavigationProgress(
                        lastInvalidation: state.navigationProgress.lastInvalidation ?? .targetMissing
                    )
                }
                return
            }
            if state.currentGoal.kind == .satisfyHunger, target.resource != .foodRaw {
                releaseReservation(for: state)
                state.activeResourceTarget = nil
                state.navigationProgress = AgentNavigationProgress(
                    lastInvalidation: .targetChanged,
                    lastFailure: .targetChanged
                )
                return
            }
            purpose = .resource
            targetPosition = target.target
            targetResource = target.resource
            goalMode = .cardinalAdjacent
            if target.distanceManhattan <= 1 {
                if let route = state.navigationProgress.route {
                    state.navigationProgress = AgentNavigationProgress(
                        status: .arrived,
                        route: route,
                        routeIndex: min(state.navigationProgress.routeIndex, route.positions.count - 1),
                        replanCount: state.navigationProgress.replanCount,
                        consecutiveBlockedMoves: 0,
                        lastPlanTick: state.navigationProgress.lastPlanTick,
                        lastInvalidation: state.navigationProgress.lastInvalidation
                    )
                }
                return
            }
            guard let reservation = reservation(for: state), reservation.agentId == state.id else {
                state.navigationProgress = AgentNavigationProgress(
                    status: .failed,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .reservationLost,
                    lastFailure: .reservationLost
                )
                return
            }
        case .deliverResources:
            guard economyEnabled, !state.resourceInventory.isEmpty else {
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            releaseReservation(for: state)
            purpose = .homeDelivery
            targetPosition = state.homePosition
            targetResource = nil
            goalMode = .exact
            if state.position == state.homePosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        case .rest:
            guard survivalEnabled else {
                releaseReservation(for: state)
                state.navigationProgress = AgentNavigationProgress()
                return
            }
            releaseReservation(for: state)
            purpose = .homeRest
            targetPosition = state.homePosition
            targetResource = nil
            goalMode = .exact
            if state.position == state.homePosition {
                state.navigationProgress = AgentNavigationProgress(
                    status: .arrived,
                    route: state.navigationProgress.route,
                    routeIndex: state.navigationProgress.route.map {
                        max(0, $0.positions.count - 1)
                    } ?? 0,
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation
                )
                return
            }
        default:
            releaseReservation(for: state)
            if state.navigationProgress.route != nil {
                state.navigationProgress = AgentNavigationProgress(lastInvalidation: .reservationLost)
            }
            return
        }
        guard let observation else {
            if state.navigationProgress.route != nil {
                state.navigationProgress = AgentNavigationProgress(
                    replanCount: state.navigationProgress.replanCount,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: .perceptionMissing,
                    lastFailure: .perceptionMissing
                )
            }
            return
        }
        guard observation.target == targetPosition else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: .targetChanged,
                lastFailure: .targetChanged
            )
            return
        }
        if let worldTick = state.lastWorldObservation?.worldTick,
           observation.worldTick != worldTick {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: .perceptionStale,
                lastFailure: .perceptionStale
            )
            return
        }

        var invalidation = state.navigationProgress.lastInvalidation
        var shouldPlan = state.navigationProgress.route == nil
        if let route = state.navigationProgress.route {
            let routeMatches = route.purpose == purpose
                && route.target == targetPosition
                && route.resource == targetResource
                && route.positions.indices.contains(state.navigationProgress.routeIndex)
                && route.positions[state.navigationProgress.routeIndex] == state.position
            if !routeMatches {
                shouldPlan = true
                invalidation = .targetChanged
            } else if state.navigationProgress.consecutiveBlockedMoves > 0 {
                shouldPlan = true
                invalidation = .movementBlocked
            } else if let next = state.navigationProgress.nextStep,
                      !observation.cells.contains(where: {
                          $0.position == next && $0.status == .traversable
                      }) {
                shouldPlan = true
                invalidation = .nextStepInvalid
            } else {
                state.navigationProgress = AgentNavigationProgress(
                    status: state.navigationProgress.status,
                    route: route,
                    routeIndex: state.navigationProgress.routeIndex,
                    replanCount: state.navigationProgress.replanCount,
                    consecutiveBlockedMoves: state.navigationProgress.consecutiveBlockedMoves,
                    lastPlanTick: state.navigationProgress.lastPlanTick,
                    lastInvalidation: state.navigationProgress.lastInvalidation,
                    lastFailure: nil
                )
                return
            }
        }
        guard shouldPlan else { return }
        if let lastPlanTick = state.navigationProgress.lastPlanTick,
           navigationTick - lastPlanTick < configuration.navigationReplanCooldownTicks {
            return
        }
        let isReplan = state.navigationProgress.lastPlanTick != nil
        let nextReplanCount = state.navigationProgress.replanCount + (isReplan ? 1 : 0)
        guard nextReplanCount <= configuration.navigationMaxReplans else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: state.navigationProgress.replanCount,
                lastPlanTick: state.navigationProgress.lastPlanTick,
                lastInvalidation: invalidation,
                lastFailure: .replanLimitReached
            )
            if purpose == .resource { releaseReservation(for: state) }
            return
        }

        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: state.position,
            target: targetPosition,
            goalMode: goalMode,
            cells: observation.cells,
            radius: observation.radius,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
        guard plan.found else {
            state.navigationProgress = AgentNavigationProgress(
                status: .failed,
                replanCount: nextReplanCount,
                lastPlanTick: navigationTick,
                lastInvalidation: invalidation,
                lastFailure: plan.failure ?? .noRoute
            )
            return
        }
        let route = AgentNavigationRoute(
            purpose: purpose,
            target: targetPosition,
            resource: targetResource,
            positions: plan.positions,
            plannedAtTick: navigationTick,
            visitedNodeCount: plan.visitedNodeCount
        )
        state.navigationProgress = AgentNavigationProgress(
            status: route.positions.count == 1 ? .arrived : .active,
            route: route,
            routeIndex: 0,
            replanCount: nextReplanCount,
            consecutiveBlockedMoves: 0,
            lastPlanTick: navigationTick,
            lastInvalidation: invalidation,
            lastFailure: nil
        )
    }

    private func reservation(for state: AgentSessionAgentState) -> AgentResourceReservation? {
        guard let target = state.activeResourceTarget else { return nil }
        return reservationsByTarget[reservationKey(target: target.target, resource: target.resource)]
            .flatMap { $0.agentId == state.id ? $0 : nil }
    }

    private mutating func releaseReservation(for state: AgentSessionAgentState) {
        guard let target = state.activeResourceTarget else { return }
        let key = reservationKey(target: target.target, resource: target.resource)
        if reservationsByTarget[key]?.agentId == state.id {
            reservationsByTarget.removeValue(forKey: key)
        }
    }

    private func reservationKey(target: AgentPosition, resource: AgentResourceKind) -> String {
        "\(resource.rawValue):\(target.x),\(target.y),\(target.z)"
    }

    private func reservationSort(
        _ lhs: AgentResourceReservation,
        _ rhs: AgentResourceReservation
    ) -> Bool {
        let lhsKey = reservationKey(target: lhs.target, resource: lhs.resource)
        let rhsKey = reservationKey(target: rhs.target, resource: rhs.resource)
        if lhsKey != rhsKey { return lhsKey < rhsKey }
        return lhs.agentId < rhs.agentId
    }

    private var sortedIds: [String] {
        statesById.keys.sorted()
    }

    private func distanceFromHome(_ state: AgentSessionAgentState) -> Int {
        abs(state.position.x - state.homePosition.x)
            + abs(state.position.y - state.homePosition.y)
            + abs(state.position.z - state.homePosition.z)
    }

    private func shouldDeliverResources(_ state: AgentSessionAgentState) -> Bool {
        economyEnabled
            && !state.resourceInventory.isEmpty
            && (state.currentGoal.kind == .deliverResources
                || state.resourceInventory.totalCount >= configuration.deliveryQuota
                || state.resourceInventory.isFull)
    }

    private func shouldSatisfyHunger(
        _ state: AgentSessionAgentState,
        projectedToNextTick: Bool = false
    ) -> Bool {
        guard survivalEnabled else { return false }
        let added = projectedToNextTick ? configuration.survivalConfiguration.hungerPerTick : 0
        let hunger = min(1, max(0, state.needs.hunger + added))
        if state.currentGoal.kind == .satisfyHunger {
            return hunger > configuration.survivalConfiguration.hungerRecoveryThreshold
        }
        return hunger >= configuration.survivalConfiguration.hungryThreshold
    }

    private func shouldRest(
        _ state: AgentSessionAgentState,
        projectedToNextTick: Bool = false
    ) -> Bool {
        guard survivalEnabled else { return false }
        let added = projectedToNextTick ? configuration.survivalConfiguration.fatiguePerTick : 0
        let fatigue = min(1, max(0, state.needs.fatigue + added))
        if state.currentGoal.kind == .rest {
            return fatigue > configuration.survivalConfiguration.fatigueRecoveryThreshold
        }
        return fatigue >= configuration.survivalConfiguration.fatigueThreshold
    }

    private func applySurvivalTick(
        to state: inout AgentSessionAgentState,
        tick survivalTick: Int
    ) -> AgentMemoryEntry? {
        let survival = configuration.survivalConfiguration
        state.needs.hunger = min(1, max(0, state.needs.hunger + survival.hungerPerTick))
        state.needs.fatigue = min(1, max(0, state.needs.fatigue + survival.fatiguePerTick))
        state.needs.curiosity = min(1, max(0, state.needs.curiosity))
        state.needs.safety = min(1, max(0, state.needs.safety))
        state.health = min(100, max(0, state.health))
        state.state = "idle"
        var progress = state.survivalProgress ?? AgentSurvivalProgress()
        var memory: AgentMemoryEntry?
        if state.needs.hunger >= survival.criticalHungerThreshold {
            progress.consecutiveCriticalHungerTicks = min(
                survival.starvationGraceTicks + 1,
                progress.consecutiveCriticalHungerTicks + 1
            )
            if progress.consecutiveCriticalHungerTicks > survival.starvationGraceTicks,
               state.health > 0 {
                let damage = min(state.health, survival.starvationDamagePerTick)
                state.health -= damage
                progress.starvationDamageTaken = min(
                    100,
                    progress.starvationDamageTaken + damage
                )
                memory = AgentMemoryEntry(
                    tick: survivalTick,
                    type: "starvation_damage",
                    summary: "\(state.id) took \(damage) starvation damage",
                    importance: 0.70
                )
                progress.lastMemoryType = .starvationDamage
            }
        } else {
            progress.consecutiveCriticalHungerTicks = 0
        }
        progress.status = state.needs.hunger >= survival.criticalHungerThreshold
            ? .starving
            : state.needs.hunger >= survival.hungryThreshold
                ? .hungry
                : state.needs.fatigue >= survival.fatigueThreshold
                    ? .exhausted
                    : .stable
        state.survivalProgress = progress
        return memory
    }

    private func updateSurvivalProgress(
        for state: inout AgentSessionAgentState,
        action: AgentAction
    ) {
        guard var progress = state.survivalProgress else { return }
        let survival = configuration.survivalConfiguration
        if action.name == "rest", state.position == state.homePosition {
            progress.restTicks = min(
                AgentSurvivalProgress.maximumEventCount,
                progress.restTicks + 1
            )
            progress.status = state.needs.fatigue <= survival.fatigueRecoveryThreshold
                ? .stable
                : .recovering
        } else if state.currentGoal.kind == .rest {
            progress.status = .exhausted
        } else if state.needs.hunger >= survival.criticalHungerThreshold {
            progress.status = .starving
        } else if state.currentGoal.kind == .satisfyHunger {
            progress.status = .hungry
        } else if state.needs.fatigue >= survival.fatigueThreshold {
            progress.status = .exhausted
        } else {
            progress.status = .stable
        }
        state.survivalProgress = progress
    }

    private func positionKey(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    private func positionText(_ position: AgentPosition) -> String {
        "(\(position.x),\(position.y),\(position.z))"
    }

    private func manhattanDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private func appendMemory(
        _ entry: AgentMemoryEntry,
        to memory: inout [AgentMemoryEntry]
    ) {
        AgentCognitiveTransitions.appendLegacyUnboundedMemory(entry, to: &memory)
        applyMemoryPolicy(configuration.memoryPolicy, to: &memory)
    }

    private func appendMemories(
        _ entries: [AgentMemoryEntry],
        to memory: inout [AgentMemoryEntry]
    ) {
        for entry in entries {
            appendMemory(entry, to: &memory)
        }
    }
}

private func applyMemoryPolicy(_ policy: AgentMemoryPolicy, to memory: inout [AgentMemoryEntry]) {
    guard case let .bounded(maxEntries) = policy, memory.count > maxEntries else { return }
    memory = Array(memory.suffix(maxEntries))
}
