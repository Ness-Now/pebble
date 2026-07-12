public struct AgentNeedsSnapshot: Encodable, Equatable {
    public let hunger: Double
    public let fatigue: Double
    public let curiosity: Double
    public let safety: Double

    init(_ needs: AgentNeeds) {
        hunger = needs.hunger
        fatigue = needs.fatigue
        curiosity = needs.curiosity
        safety = needs.safety
    }
}

public struct AgentSnapshot: Encodable, Equatable {
    public let id: String
    public let state: String
    public let position: AgentPosition
    public let needs: AgentNeedsSnapshot
    public let health: Int
    public let isAlive: Bool
    public let fear: Int
    public let homePosition: AgentPosition
    public let distanceFromHome: Int

    public let nearbyAgents: [AgentNearbyObservation]
    public let currentGoal: AgentGoal
    public let lastAction: AgentAction?
    public let lastActionEffect: AgentActionEffect?
    public let lastWorldObservation: AgentWorldObservation?
    public let lastWorldPerceptionEffect: AgentWorldPerceptionEffect?
    public let lastMovementOutcome: AgentMovementOutcome?
    public let lastFeedbackDecisionTrace: AgentFeedbackDecisionTrace?

    public let ticksAlive: Int
    public let observationCount: Int
    public let nearbyObservationCount: Int
    public let goalSelectionCount: Int
    public let goalChangeCount: Int
    public let actionCount: Int
    public let actionEffectCount: Int
    public let movementCount: Int
    public let totalManhattanDistanceMoved: Int
    public let returnHomeMoveCount: Int
    public let totalDistanceReducedTowardHome: Int
    public let feedbackMemoryWriteCount: Int
    public let feedbackMemoryDeduplicatedCount: Int
    public let memoryRetrievalCount: Int
    public let memoryInfluencedDecisionCount: Int

    public let memoryCount: Int
    public let recentMemory: [AgentMemoryEntry]

    init(state: AgentSessionAgentState, recentMemoryLimit: Int) {
        id = state.id
        self.state = state.state
        position = state.position
        needs = AgentNeedsSnapshot(state.needs)
        health = state.health
        isAlive = state.health > 0
        fear = state.fear
        homePosition = state.homePosition
        distanceFromHome = abs(state.position.x - state.homePosition.x)
            + abs(state.position.y - state.homePosition.y)
            + abs(state.position.z - state.homePosition.z)
        nearbyAgents = state.nearbyAgents
        currentGoal = state.currentGoal
        lastAction = state.lastAction
        lastActionEffect = state.lastActionEffect
        lastWorldObservation = state.lastWorldObservation
        lastWorldPerceptionEffect = state.lastWorldPerceptionEffect
        lastMovementOutcome = state.lastMovementOutcome
        lastFeedbackDecisionTrace = state.lastFeedbackDecisionTrace
        ticksAlive = state.ticksAlive
        observationCount = state.observationCount
        nearbyObservationCount = state.nearbyObservationCount
        goalSelectionCount = state.goalSelectionCount
        goalChangeCount = state.goalChangeCount
        actionCount = state.actionCount
        actionEffectCount = state.actionEffectCount
        movementCount = state.movementCount
        totalManhattanDistanceMoved = state.totalManhattanDistanceMoved
        returnHomeMoveCount = state.returnHomeMoveCount
        totalDistanceReducedTowardHome = state.totalDistanceReducedTowardHome
        feedbackMemoryWriteCount = state.feedbackMemoryWriteCount
        feedbackMemoryDeduplicatedCount = state.feedbackMemoryDeduplicatedCount
        memoryRetrievalCount = state.memoryRetrievalCount
        memoryInfluencedDecisionCount = state.memoryInfluencedDecisionCount
        memoryCount = state.memory.count
        recentMemory = Array(state.memory.suffix(recentMemoryLimit))
    }

    public static func == (lhs: AgentSnapshot, rhs: AgentSnapshot) -> Bool {
        lhs.id == rhs.id
            && lhs.state == rhs.state
            && lhs.position == rhs.position
            && lhs.needs == rhs.needs
            && lhs.health == rhs.health
            && lhs.isAlive == rhs.isAlive
            && lhs.fear == rhs.fear
            && lhs.homePosition == rhs.homePosition
            && lhs.distanceFromHome == rhs.distanceFromHome
            && lhs.nearbyAgents == rhs.nearbyAgents
            && lhs.currentGoal == rhs.currentGoal
            && actionsEqual(lhs.lastAction, rhs.lastAction)
            && effectsEqual(lhs.lastActionEffect, rhs.lastActionEffect)
            && lhs.lastWorldObservation == rhs.lastWorldObservation
            && lhs.lastWorldPerceptionEffect == rhs.lastWorldPerceptionEffect
            && lhs.lastMovementOutcome == rhs.lastMovementOutcome
            && lhs.lastFeedbackDecisionTrace == rhs.lastFeedbackDecisionTrace
            && lhs.ticksAlive == rhs.ticksAlive
            && lhs.observationCount == rhs.observationCount
            && lhs.nearbyObservationCount == rhs.nearbyObservationCount
            && lhs.goalSelectionCount == rhs.goalSelectionCount
            && lhs.goalChangeCount == rhs.goalChangeCount
            && lhs.actionCount == rhs.actionCount
            && lhs.actionEffectCount == rhs.actionEffectCount
            && lhs.movementCount == rhs.movementCount
            && lhs.totalManhattanDistanceMoved == rhs.totalManhattanDistanceMoved
            && lhs.returnHomeMoveCount == rhs.returnHomeMoveCount
            && lhs.totalDistanceReducedTowardHome == rhs.totalDistanceReducedTowardHome
            && lhs.feedbackMemoryWriteCount == rhs.feedbackMemoryWriteCount
            && lhs.feedbackMemoryDeduplicatedCount == rhs.feedbackMemoryDeduplicatedCount
            && lhs.memoryRetrievalCount == rhs.memoryRetrievalCount
            && lhs.memoryInfluencedDecisionCount == rhs.memoryInfluencedDecisionCount
            && lhs.memoryCount == rhs.memoryCount
            && memoriesEqual(lhs.recentMemory, rhs.recentMemory)
    }

    private enum CodingKeys: String, CodingKey {
        case id, state, position, needs, health, isAlive, fear, homePosition, distanceFromHome
        case nearbyAgents, currentGoal, lastAction, lastActionEffect
        case lastWorldObservation, lastWorldPerceptionEffect, lastMovementOutcome
        case lastFeedbackDecisionTrace
        case ticksAlive, observationCount, nearbyObservationCount, goalSelectionCount
        case goalChangeCount, actionCount, actionEffectCount, movementCount
        case totalManhattanDistanceMoved, returnHomeMoveCount, totalDistanceReducedTowardHome
        case feedbackMemoryWriteCount, feedbackMemoryDeduplicatedCount
        case memoryRetrievalCount, memoryInfluencedDecisionCount
        case memoryCount, recentMemory
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(state, forKey: .state)
        try container.encode(position, forKey: .position)
        try container.encode(needs, forKey: .needs)
        try container.encode(health, forKey: .health)
        try container.encode(isAlive, forKey: .isAlive)
        try container.encode(fear, forKey: .fear)
        try container.encode(homePosition, forKey: .homePosition)
        try container.encode(distanceFromHome, forKey: .distanceFromHome)
        try container.encode(nearbyAgents, forKey: .nearbyAgents)
        try container.encode(currentGoal, forKey: .currentGoal)
        try container.encodeIfPresent(lastAction, forKey: .lastAction)
        try container.encodeIfPresent(lastActionEffect, forKey: .lastActionEffect)
        try container.encodeIfPresent(lastWorldObservation, forKey: .lastWorldObservation)
        try container.encodeIfPresent(lastWorldPerceptionEffect, forKey: .lastWorldPerceptionEffect)
        try container.encodeIfPresent(lastMovementOutcome, forKey: .lastMovementOutcome)
        if lastMovementOutcome != nil {
            try container.encodeIfPresent(lastFeedbackDecisionTrace, forKey: .lastFeedbackDecisionTrace)
        }
        try container.encode(ticksAlive, forKey: .ticksAlive)
        try container.encode(observationCount, forKey: .observationCount)
        try container.encode(nearbyObservationCount, forKey: .nearbyObservationCount)
        try container.encode(goalSelectionCount, forKey: .goalSelectionCount)
        try container.encode(goalChangeCount, forKey: .goalChangeCount)
        try container.encode(actionCount, forKey: .actionCount)
        try container.encode(actionEffectCount, forKey: .actionEffectCount)
        try container.encode(movementCount, forKey: .movementCount)
        try container.encode(totalManhattanDistanceMoved, forKey: .totalManhattanDistanceMoved)
        try container.encode(returnHomeMoveCount, forKey: .returnHomeMoveCount)
        try container.encode(totalDistanceReducedTowardHome, forKey: .totalDistanceReducedTowardHome)
        if feedbackMemoryWriteCount != 0 {
            try container.encode(feedbackMemoryWriteCount, forKey: .feedbackMemoryWriteCount)
        }
        if feedbackMemoryDeduplicatedCount != 0 {
            try container.encode(feedbackMemoryDeduplicatedCount, forKey: .feedbackMemoryDeduplicatedCount)
        }
        if memoryRetrievalCount != 0 {
            try container.encode(memoryRetrievalCount, forKey: .memoryRetrievalCount)
        }
        if memoryInfluencedDecisionCount != 0 {
            try container.encode(memoryInfluencedDecisionCount, forKey: .memoryInfluencedDecisionCount)
        }
        try container.encode(memoryCount, forKey: .memoryCount)
        try container.encode(recentMemory, forKey: .recentMemory)
    }
}

public struct AgentSessionSnapshot: Encodable, Equatable {
    public let seed: UInt32
    public let tick: Int
    public let agentCount: Int
    public let agents: [AgentSnapshot]

    init(seed: UInt32, tick: Int, agents: [AgentSnapshot]) {
        self.seed = seed
        self.tick = tick
        agentCount = agents.count
        self.agents = agents
    }
}

private func actionsEqual(_ lhs: AgentAction?, _ rhs: AgentAction?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case let (lhs?, rhs?):
        return lhs.name == rhs.name
            && lhs.reason == rhs.reason
            && lhs.tick == rhs.tick
            && lhs.dx == rhs.dx
            && lhs.dy == rhs.dy
            && lhs.dz == rhs.dz
    default:
        return false
    }
}

private func effectsEqual(_ lhs: AgentActionEffect?, _ rhs: AgentActionEffect?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case let (lhs?, rhs?):
        return lhs.action == rhs.action
            && lhs.effect == rhs.effect
            && lhs.tick == rhs.tick
            && lhs.hungerBefore == rhs.hungerBefore
            && lhs.hungerAfter == rhs.hungerAfter
            && lhs.fatigueBefore == rhs.fatigueBefore
            && lhs.fatigueAfter == rhs.fatigueAfter
            && lhs.curiosityBefore == rhs.curiosityBefore
            && lhs.curiosityAfter == rhs.curiosityAfter
            && lhs.safetyBefore == rhs.safetyBefore
            && lhs.safetyAfter == rhs.safetyAfter
            && lhs.fearBefore == rhs.fearBefore
            && lhs.fearAfter == rhs.fearAfter
            && lhs.stateBefore == rhs.stateBefore
            && lhs.stateAfter == rhs.stateAfter
    default:
        return false
    }
}

private func memoriesEqual(_ lhs: [AgentMemoryEntry], _ rhs: [AgentMemoryEntry]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { left, right in
        left.tick == right.tick
            && left.type == right.type
            && left.summary == right.summary
            && left.importance == right.importance
    }
}
