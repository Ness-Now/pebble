public enum AgentMemoryPolicy: Equatable {
    case legacyUnbounded
    case bounded(maxEntries: Int)
}

public enum AgentSessionError: Error, Equatable {
    case invalidNearbyRadius(Int)
    case invalidResourceObservationRadius(Int)
    case invalidRecentMemorySnapshotLimit(Int)
    case invalidMemoryBound(Int)
    case invalidInitialTick(Int)
    case duplicateAgentId(String)
    case duplicatePerceptionInput(String)
    case unknownAgentId(String)
    case worldObservationPositionMismatch(String)
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
    case inventoryFull(String)
    case invalidInteractionOutcome(String)
}

public struct AgentSessionConfiguration {
    public let seed: UInt32
    public let nearbyRadius: Int
    public let resourceObservationRadius: Int
    public let recentMemorySnapshotLimit: Int
    public let memoryPolicy: AgentMemoryPolicy
    public let feedbackLoopConfiguration: AgentFeedbackLoopConfiguration

    public init(
        seed: UInt32,
        nearbyRadius: Int = 8,
        resourceObservationRadius: Int = 1,
        recentMemorySnapshotLimit: Int = 10,
        memoryPolicy: AgentMemoryPolicy,
        feedbackLoopConfiguration: AgentFeedbackLoopConfiguration = .live
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
        self.seed = seed
        self.nearbyRadius = nearbyRadius
        self.resourceObservationRadius = resourceObservationRadius
        self.recentMemorySnapshotLimit = recentMemorySnapshotLimit
        self.memoryPolicy = memoryPolicy
        self.feedbackLoopConfiguration = feedbackLoopConfiguration
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
        lastInteractionOutcome: AgentInteractionOutcome? = nil
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
    }
}

public struct AgentPerceptionInput {
    public let agentId: String
    public let observationCountIncrement: Int
    public let externalMemoryEntries: [AgentMemoryEntry]
    public let worldObservation: AgentWorldObservation?
    public let resourceObservations: [AgentResourceObservation]

    public init(
        agentId: String,
        observationCountIncrement: Int = 0,
        externalMemoryEntries: [AgentMemoryEntry] = [],
        worldObservation: AgentWorldObservation? = nil,
        resourceObservations: [AgentResourceObservation] = []
    ) {
        self.agentId = agentId
        self.observationCountIncrement = observationCountIncrement
        self.externalMemoryEntries = externalMemoryEntries
        self.worldObservation = worldObservation
        self.resourceObservations = resourceObservations
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
    public let configuration: AgentSessionConfiguration
    public private(set) var tick: Int
    private var statesById: [String: AgentSessionAgentState]
    private var processedInteractionIds: Set<String>

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
    }

    public func snapshot() -> AgentSessionSnapshot {
        let agents = sortedIds.compactMap { id in
            statesById[id].map {
                AgentSnapshot(
                    state: $0,
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit
                )
            }
        }
        return AgentSessionSnapshot(seed: configuration.seed, tick: tick, agents: agents)
    }

    public func state(for agentId: String) throws -> AgentSessionAgentState {
        guard let state = statesById[agentId] else {
            throw AgentSessionError.unknownAgentId(agentId)
        }
        return state
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
            guard outcome.inventoryDelta.resource == outcome.resource,
                  outcome.inventoryDelta.quantity == 1,
                  state.resourceInventory.add(outcome.resource, quantity: 1) else {
                throw AgentSessionError.invalidInteractionOutcome(outcome.interactionId)
            }
            memory = AgentMemoryEntry(
                tick: tick,
                type: "resource_harvested",
                summary: "\(outcome.agentId) harvested 1 \(outcome.resource.rawValue)",
                importance: 0.40
            )
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
            perceptionsById[perception.agentId] = perception
        }

        let nextTick = tick + 1
        let ids = sortedIds
        let peers = ids.compactMap { id in
            statesById[id].map { AgentPeerSnapshot(id: id, position: $0.position) }
        }
        var results: [AgentSessionAgentTickResult] = []

        for id in ids {
            guard var state = statesById[id] else { continue }
            let perception = perceptionsById[id]
            var memoriesAdded = perception?.externalMemoryEntries ?? []
            state.lastResourceObservations = resourceObservationsById[id] ?? []
            state.activeResourceTarget = AgentResourceTargeting.select(
                current: state.activeResourceTarget,
                observations: state.lastResourceObservations,
                inventory: state.resourceInventory,
                tick: nextTick
            )

            let tickTransition = AgentCognitiveTransitions.advanceTick(needs: state.needs)
            state.needs = tickTransition.needs
            state.state = tickTransition.state
            state.ticksAlive += 1

            appendMemories(memoriesAdded, to: &state.memory)
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
                currentGoalKind: state.currentGoal.kind
            ))
            if let goalChange {
                state.currentGoal = goalChange.goal
                state.goalChangeCount += 1
            }

            let baseAction = AgentActionDecider.decide(AgentActionDecisionInput(
                agentId: id,
                tick: nextTick,
                goalKind: state.currentGoal.kind,
                position: state.position,
                homePosition: state.homePosition,
                resourceObservations: state.lastResourceObservations,
                activeResourceTarget: state.activeResourceTarget
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
                tick: nextTick
            ))
            state.needs = effectResult.needs
            state.fear = effectResult.fear
            state.state = effectResult.state
            state.lastActionEffect = effectResult.actionEffect
            state.actionEffectCount += 1
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
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit
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
                      action.name == "move_abstract",
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
                if state.currentGoal.kind == .seekSafety, outcome.distanceReducedTowardHome > 0 {
                    state.returnHomeMoveCount += 1
                    state.totalDistanceReducedTowardHome += outcome.distanceReducedTowardHome
                }
                if let entry = AgentFeedbackLoop.movementMemoryEntry(outcome: outcome) {
                    appendMemory(entry, to: &state.memory)
                    state.feedbackMemoryWriteCount += 1
                }
            case .blocked:
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

    private var sortedIds: [String] {
        statesById.keys.sorted()
    }

    private func distanceFromHome(_ state: AgentSessionAgentState) -> Int {
        abs(state.position.x - state.homePosition.x)
            + abs(state.position.y - state.homePosition.y)
            + abs(state.position.z - state.homePosition.z)
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
