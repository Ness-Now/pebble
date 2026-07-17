public enum AgentSurvivalConfigurationError: Error, Equatable {
    case invalidRate(String, Double)
    case invalidThresholds
    case invalidStarvationGraceTicks(Int)
    case invalidStarvationDamage(Int)
}

public struct AgentSurvivalConfiguration: Codable, Equatable {
    public let hungerPerTick: Double
    public let fatiguePerTick: Double
    public let hungryThreshold: Double
    public let criticalHungerThreshold: Double
    public let hungerRecoveryThreshold: Double
    public let fatigueThreshold: Double
    public let fatigueRecoveryThreshold: Double
    public let foodNutrition: Double
    public let restRecoveryPerTick: Double
    public let starvationGraceTicks: Int
    public let starvationDamagePerTick: Int

    public init(
        hungerPerTick: Double,
        fatiguePerTick: Double,
        hungryThreshold: Double,
        criticalHungerThreshold: Double,
        hungerRecoveryThreshold: Double,
        fatigueThreshold: Double,
        fatigueRecoveryThreshold: Double,
        foodNutrition: Double,
        restRecoveryPerTick: Double,
        starvationGraceTicks: Int,
        starvationDamagePerTick: Int
    ) throws {
        let rates = [
            ("hungerPerTick", hungerPerTick),
            ("fatiguePerTick", fatiguePerTick),
            ("foodNutrition", foodNutrition),
            ("restRecoveryPerTick", restRecoveryPerTick),
        ]
        for (name, value) in rates where !value.isFinite || value <= 0 || value > 1 {
            throw AgentSurvivalConfigurationError.invalidRate(name, value)
        }
        let thresholds = [
            hungryThreshold,
            criticalHungerThreshold,
            hungerRecoveryThreshold,
            fatigueThreshold,
            fatigueRecoveryThreshold,
        ]
        guard thresholds.allSatisfy({ $0.isFinite && (0...1).contains($0) }),
              hungerRecoveryThreshold < hungryThreshold,
              hungryThreshold < criticalHungerThreshold,
              fatigueRecoveryThreshold < fatigueThreshold else {
            throw AgentSurvivalConfigurationError.invalidThresholds
        }
        guard starvationGraceTicks >= 0 else {
            throw AgentSurvivalConfigurationError.invalidStarvationGraceTicks(starvationGraceTicks)
        }
        guard (1...100).contains(starvationDamagePerTick) else {
            throw AgentSurvivalConfigurationError.invalidStarvationDamage(starvationDamagePerTick)
        }
        self.hungerPerTick = hungerPerTick
        self.fatiguePerTick = fatiguePerTick
        self.hungryThreshold = hungryThreshold
        self.criticalHungerThreshold = criticalHungerThreshold
        self.hungerRecoveryThreshold = hungerRecoveryThreshold
        self.fatigueThreshold = fatigueThreshold
        self.fatigueRecoveryThreshold = fatigueRecoveryThreshold
        self.foodNutrition = foodNutrition
        self.restRecoveryPerTick = restRecoveryPerTick
        self.starvationGraceTicks = starvationGraceTicks
        self.starvationDamagePerTick = starvationDamagePerTick
    }

    public static let live: AgentSurvivalConfiguration = {
        try! AgentSurvivalConfiguration(
            hungerPerTick: 0.05,
            fatiguePerTick: 0.06,
            hungryThreshold: 0.40,
            criticalHungerThreshold: 0.80,
            hungerRecoveryThreshold: 0.15,
            fatigueThreshold: 0.65,
            fatigueRecoveryThreshold: 0.20,
            foodNutrition: 1.0,
            restRecoveryPerTick: 1.0,
            starvationGraceTicks: 2,
            starvationDamagePerTick: 10
        )
    }()
}

public enum AgentSurvivalStatus: String, Codable, Equatable {
    case stable
    case hungry
    case starving
    case exhausted
    case recovering
}

public enum AgentSurvivalMemoryType: String, Codable, Equatable {
    case foodConsumed = "food_consumed"
    case consumptionBlocked = "consumption_blocked"
    case starvationDamage = "starvation_damage"
}

public enum AgentConsumptionStatus: String, Codable, Equatable, Sendable {
    case succeeded
    case blocked
    case foodUnavailable
}

public struct AgentConsumptionIntent: Equatable {
    public let consumptionId: String
    public let agentId: String
    public let tick: Int
    public let resource: AgentResourceKind
    public let quantity: Int

    public init(
        consumptionId: String,
        agentId: String,
        tick: Int,
        resource: AgentResourceKind = .foodRaw,
        quantity: Int = 1
    ) {
        self.consumptionId = consumptionId
        self.agentId = agentId
        self.tick = tick
        self.resource = resource
        self.quantity = quantity
    }
}

public struct AgentConsumptionOutcome: Codable, Equatable {
    public let consumptionId: String
    public let agentId: String
    public let tick: Int
    public let resource: AgentResourceKind
    public let quantity: Int
    public let status: AgentConsumptionStatus
    public let hungerBefore: Double
    public let hungerAfter: Double
    public let reason: String

    public init(
        consumptionId: String,
        agentId: String,
        tick: Int,
        resource: AgentResourceKind,
        quantity: Int,
        status: AgentConsumptionStatus,
        hungerBefore: Double,
        hungerAfter: Double,
        reason: String
    ) {
        self.consumptionId = consumptionId
        self.agentId = agentId
        self.tick = tick
        self.resource = resource
        self.quantity = quantity
        self.status = status
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
        self.reason = reason
    }
}

public struct AgentSurvivalProgress: Codable, Equatable {
    public static let maximumEventCount = 4096
    public internal(set) var status: AgentSurvivalStatus
    public internal(set) var consecutiveCriticalHungerTicks: Int
    public internal(set) var foodConsumedCount: Int
    public internal(set) var restTicks: Int
    public internal(set) var starvationDamageTaken: Int
    public internal(set) var lastConsumptionOutcome: AgentConsumptionOutcome?
    public internal(set) var lastMemoryType: AgentSurvivalMemoryType?

    public init(
        status: AgentSurvivalStatus = .stable,
        consecutiveCriticalHungerTicks: Int = 0,
        foodConsumedCount: Int = 0,
        restTicks: Int = 0,
        starvationDamageTaken: Int = 0,
        lastConsumptionOutcome: AgentConsumptionOutcome? = nil,
        lastMemoryType: AgentSurvivalMemoryType? = nil
    ) {
        self.status = status
        self.consecutiveCriticalHungerTicks = max(0, consecutiveCriticalHungerTicks)
        self.foodConsumedCount = min(Self.maximumEventCount, max(0, foodConsumedCount))
        self.restTicks = min(Self.maximumEventCount, max(0, restTicks))
        self.starvationDamageTaken = min(100, max(0, starvationDamageTaken))
        self.lastConsumptionOutcome = lastConsumptionOutcome
        self.lastMemoryType = lastMemoryType
    }
}
