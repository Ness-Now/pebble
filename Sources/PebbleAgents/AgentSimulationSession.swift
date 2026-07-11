public enum AgentMemoryPolicy: Equatable {
    case legacyUnbounded
    case bounded(maxEntries: Int)
}

public enum AgentSessionError: Error, Equatable {
    case invalidNearbyRadius(Int)
    case invalidRecentMemorySnapshotLimit(Int)
    case invalidMemoryBound(Int)
    case invalidInitialTick(Int)
    case duplicateAgentId(String)
    case duplicatePerceptionInput(String)
    case unknownAgentId(String)
    case worldObservationPositionMismatch(String)
}

public struct AgentSessionConfiguration {
    public let seed: UInt32
    public let nearbyRadius: Int
    public let recentMemorySnapshotLimit: Int
    public let memoryPolicy: AgentMemoryPolicy

    public init(
        seed: UInt32,
        nearbyRadius: Int = 8,
        recentMemorySnapshotLimit: Int = 10,
        memoryPolicy: AgentMemoryPolicy
    ) throws {
        guard nearbyRadius >= 0 else {
            throw AgentSessionError.invalidNearbyRadius(nearbyRadius)
        }
        guard recentMemorySnapshotLimit >= 0 else {
            throw AgentSessionError.invalidRecentMemorySnapshotLimit(recentMemorySnapshotLimit)
        }
        if case let .bounded(maxEntries) = memoryPolicy, maxEntries <= 0 {
            throw AgentSessionError.invalidMemoryBound(maxEntries)
        }
        self.seed = seed
        self.nearbyRadius = nearbyRadius
        self.recentMemorySnapshotLimit = recentMemorySnapshotLimit
        self.memoryPolicy = memoryPolicy
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
        lastWorldPerceptionEffect: AgentWorldPerceptionEffect? = nil
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
    }
}

public struct AgentPerceptionInput {
    public let agentId: String
    public let observationCountIncrement: Int
    public let externalMemoryEntries: [AgentMemoryEntry]
    public let worldObservation: AgentWorldObservation?

    public init(
        agentId: String,
        observationCountIncrement: Int = 0,
        externalMemoryEntries: [AgentMemoryEntry] = [],
        worldObservation: AgentWorldObservation? = nil
    ) {
        self.agentId = agentId
        self.observationCountIncrement = observationCountIncrement
        self.externalMemoryEntries = externalMemoryEntries
        self.worldObservation = worldObservation
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

    public mutating func advanceTick(
        perceptions: [AgentPerceptionInput] = []
    ) throws -> AgentSessionTickResult {
        var perceptionsById: [String: AgentPerceptionInput] = [:]
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
                currentGoalKind: state.currentGoal.kind
            ))
            if let goalChange {
                state.currentGoal = goalChange.goal
                state.goalChangeCount += 1
            }

            let action = AgentActionDecider.decide(AgentActionDecisionInput(
                agentId: id,
                tick: nextTick,
                goalKind: state.currentGoal.kind,
                position: state.position,
                homePosition: state.homePosition
            ))
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

    private var sortedIds: [String] {
        statesById.keys.sorted()
    }

    private func distanceFromHome(_ state: AgentSessionAgentState) -> Int {
        abs(state.position.x - state.homePosition.x)
            + abs(state.position.y - state.homePosition.y)
            + abs(state.position.z - state.homePosition.z)
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
