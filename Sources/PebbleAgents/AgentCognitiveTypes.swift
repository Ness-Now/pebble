public struct AgentNeeds: Codable {
    public var hunger: Double
    public var fatigue: Double
    public var curiosity: Double
    public var safety: Double

    public init(hunger: Double, fatigue: Double, curiosity: Double, safety: Double) {
        self.hunger = hunger
        self.fatigue = fatigue
        self.curiosity = curiosity
        self.safety = safety
    }
}

public struct AgentPeerSnapshot {
    public let id: String
    public let position: AgentPosition

    public init(id: String, position: AgentPosition) {
        self.id = id
        self.position = position
    }
}

public struct AgentNearbyObservation: Codable, Equatable {
    public let id: String
    public let dx: Int
    public let dy: Int
    public let dz: Int
    public let distanceManhattan: Int

    public init(id: String, dx: Int, dy: Int, dz: Int, distanceManhattan: Int) {
        self.id = id
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.distanceManhattan = distanceManhattan
    }
}

public struct AgentGoalChange {
    public let from: AgentGoalKind
    public let to: AgentGoalKind
    public let goal: AgentGoal

    public init(from: AgentGoalKind, to: AgentGoalKind, goal: AgentGoal) {
        self.from = from
        self.to = to
        self.goal = goal
    }
}

public struct AgentActionEffect: Codable, Equatable, Sendable {
    public let action: String
    public let effect: String
    public let tick: Int

    public let hungerBefore: Double
    public let hungerAfter: Double
    public let fatigueBefore: Double
    public let fatigueAfter: Double
    public let curiosityBefore: Double
    public let curiosityAfter: Double
    public let safetyBefore: Double
    public let safetyAfter: Double

    public let fearBefore: Int
    public let fearAfter: Int

    public let stateBefore: String
    public let stateAfter: String

    public init(
        action: String,
        effect: String,
        tick: Int,
        hungerBefore: Double,
        hungerAfter: Double,
        fatigueBefore: Double,
        fatigueAfter: Double,
        curiosityBefore: Double,
        curiosityAfter: Double,
        safetyBefore: Double,
        safetyAfter: Double,
        fearBefore: Int,
        fearAfter: Int,
        stateBefore: String,
        stateAfter: String
    ) {
        self.action = action
        self.effect = effect
        self.tick = tick
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
    }
}

public struct AgentMemoryEntry: Codable, Equatable, Sendable {
    public let tick: Int
    public let type: String
    public let summary: String
    public let importance: Double

    public init(tick: Int, type: String, summary: String, importance: Double) {
        self.tick = tick
        self.type = type
        self.summary = summary
        self.importance = importance
    }
}

public struct AgentTickTransitionResult {
    public let needs: AgentNeeds
    public let state: String

    public init(needs: AgentNeeds, state: String) {
        self.needs = needs
        self.state = state
    }
}

public struct AgentGoalSelectionInput {
    public let tick: Int
    public let health: Int
    public let fear: Int
    public let needs: AgentNeeds
    public let hasNearbyAgents: Bool
    public let hasCollectibleAdjacentResource: Bool
    public let hasInventoryCapacity: Bool
    public let hasCommittedResourceTask: Bool
    public let shouldDeliverResources: Bool
    public let shouldBuildShelter: Bool
    public let hasConstructionTask: Bool
    public let canShareInformation: Bool
    public let canVerifySocialInformation: Bool
    public let hasActiveCooperationTask: Bool
    public let shouldConsiderCooperationOffer: Bool
    public let canAcceptCooperationOffer: Bool
    public let isMigrating: Bool
    public let currentGoalKind: AgentGoalKind
    public let survivalEnabled: Bool
    public let hungryThreshold: Double
    public let criticalHungerThreshold: Double
    public let hungerRecoveryThreshold: Double
    public let fatigueThreshold: Double
    public let fatigueRecoveryThreshold: Double

    public init(
        tick: Int,
        health: Int,
        fear: Int,
        needs: AgentNeeds,
        hasNearbyAgents: Bool,
        hasCollectibleAdjacentResource: Bool = false,
        hasInventoryCapacity: Bool = false,
        hasCommittedResourceTask: Bool = false,
        shouldDeliverResources: Bool = false,
        shouldBuildShelter: Bool = false,
        hasConstructionTask: Bool = false,
        canShareInformation: Bool = false,
        canVerifySocialInformation: Bool = false,
        hasActiveCooperationTask: Bool = false,
        shouldConsiderCooperationOffer: Bool = false,
        canAcceptCooperationOffer: Bool = false,
        isMigrating: Bool = false,
        currentGoalKind: AgentGoalKind,
        survivalEnabled: Bool = false,
        hungryThreshold: Double = AgentSurvivalConfiguration.live.hungryThreshold,
        criticalHungerThreshold: Double = AgentSurvivalConfiguration.live.criticalHungerThreshold,
        hungerRecoveryThreshold: Double = AgentSurvivalConfiguration.live.hungerRecoveryThreshold,
        fatigueThreshold: Double = AgentSurvivalConfiguration.live.fatigueThreshold,
        fatigueRecoveryThreshold: Double = AgentSurvivalConfiguration.live.fatigueRecoveryThreshold
    ) {
        self.tick = tick
        self.health = health
        self.fear = fear
        self.needs = needs
        self.hasNearbyAgents = hasNearbyAgents
        self.hasCollectibleAdjacentResource = hasCollectibleAdjacentResource
        self.hasInventoryCapacity = hasInventoryCapacity
        self.hasCommittedResourceTask = hasCommittedResourceTask
        self.shouldDeliverResources = shouldDeliverResources
        self.shouldBuildShelter = shouldBuildShelter
        self.hasConstructionTask = hasConstructionTask
        self.canShareInformation = canShareInformation
        self.canVerifySocialInformation = canVerifySocialInformation
        self.hasActiveCooperationTask = hasActiveCooperationTask
        self.shouldConsiderCooperationOffer = shouldConsiderCooperationOffer
        self.canAcceptCooperationOffer = canAcceptCooperationOffer
        self.isMigrating = isMigrating
        self.currentGoalKind = currentGoalKind
        self.survivalEnabled = survivalEnabled
        self.hungryThreshold = hungryThreshold
        self.criticalHungerThreshold = criticalHungerThreshold
        self.hungerRecoveryThreshold = hungerRecoveryThreshold
        self.fatigueThreshold = fatigueThreshold
        self.fatigueRecoveryThreshold = fatigueRecoveryThreshold
    }
}

public struct AgentActionEffectInput {
    public let action: AgentAction
    public let goalKind: AgentGoalKind
    public let distanceFromHome: Int
    public let needs: AgentNeeds
    public let fear: Int
    public let state: String
    public let tick: Int
    public let survivalEnabled: Bool
    public let restRecoveryPerTick: Double

    public init(
        action: AgentAction,
        goalKind: AgentGoalKind,
        distanceFromHome: Int,
        needs: AgentNeeds,
        fear: Int,
        state: String,
        tick: Int,
        survivalEnabled: Bool = false,
        restRecoveryPerTick: Double = AgentSurvivalConfiguration.live.restRecoveryPerTick
    ) {
        self.action = action
        self.goalKind = goalKind
        self.distanceFromHome = distanceFromHome
        self.needs = needs
        self.fear = fear
        self.state = state
        self.tick = tick
        self.survivalEnabled = survivalEnabled
        self.restRecoveryPerTick = restRecoveryPerTick
    }
}

public struct AgentActionEffectResult {
    public let needs: AgentNeeds
    public let fear: Int
    public let state: String
    public let actionEffect: AgentActionEffect

    public init(needs: AgentNeeds, fear: Int, state: String, actionEffect: AgentActionEffect) {
        self.needs = needs
        self.fear = fear
        self.state = state
        self.actionEffect = actionEffect
    }
}
