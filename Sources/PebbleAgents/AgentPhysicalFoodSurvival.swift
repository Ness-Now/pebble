public enum AgentFoodAuthorityMode: String, Codable, Equatable, Sendable {
    case legacyAbstract
    case physicalItems
}

public enum AgentPhysicalFoodConsumptionStatus: String, Codable, Equatable, Sendable {
    case succeeded
}

public struct AgentPhysicalFoodConsumptionIntent: Codable, Equatable, Sendable {
    public let consumptionID: String
    public let agentID: AgentID
    public let tick: Int

    public init(consumptionID: String, agentID: AgentID, tick: Int) {
        self.consumptionID = consumptionID
        self.agentID = agentID
        self.tick = tick
    }
}

/// A pure Civilization DTO published only after Pebble has resolved Core food
/// metadata and proven one exact physical custody debit. Core hunger points use
/// the canonical Player scale (0...20); agents model hunger as a normalized
/// deficit, so `normalizedHungerReduction = min(1, coreHungerPoints / 20)`.
public struct AgentValidatedPhysicalFoodConsumptionOutcome: Codable, Equatable, Sendable {
    public let consumptionID: String
    public let agentID: AgentID
    public let tick: Int
    public let canonicalMaterialName: String
    public let quantityConsumed: Int
    public let coreHungerPoints: Int
    public let coreSaturation: Double
    public let normalizedHungerReduction: Double
    public let status: AgentPhysicalFoodConsumptionStatus
    public let physicalReceiptID: String
    public let sourceLocationID: String
    public let sourceSlot: Int
    public let hungerBefore: Double
    public let hungerAfter: Double

    public init(
        consumptionID: String,
        agentID: AgentID,
        tick: Int,
        canonicalMaterialName: String,
        quantityConsumed: Int,
        coreHungerPoints: Int,
        coreSaturation: Double,
        normalizedHungerReduction: Double,
        status: AgentPhysicalFoodConsumptionStatus,
        physicalReceiptID: String,
        sourceLocationID: String,
        sourceSlot: Int,
        hungerBefore: Double,
        hungerAfter: Double
    ) {
        self.consumptionID = consumptionID
        self.agentID = agentID
        self.tick = tick
        self.canonicalMaterialName = canonicalMaterialName
        self.quantityConsumed = quantityConsumed
        self.coreHungerPoints = coreHungerPoints
        self.coreSaturation = coreSaturation
        self.normalizedHungerReduction = normalizedHungerReduction
        self.status = status
        self.physicalReceiptID = physicalReceiptID
        self.sourceLocationID = sourceLocationID
        self.sourceSlot = sourceSlot
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
    }
}

public struct AgentPhysicalFoodSurvivalState: Codable, Equatable, Sendable {
    public static let maximumProcessedConsumptionIDs = 4096
    public static let maximumRetainedOutcomes = 64

    public internal(set) var authorityMode: AgentFoodAuthorityMode
    public internal(set) var processedConsumptionIDs: [String]
    public internal(set) var completedOutcomes: [AgentValidatedPhysicalFoodConsumptionOutcome]
    public internal(set) var totalConsumedQuantity: Int
    public internal(set) var droppedOutcomeCount: Int

    public init(
        authorityMode: AgentFoodAuthorityMode = .physicalItems,
        processedConsumptionIDs: [String] = [],
        completedOutcomes: [AgentValidatedPhysicalFoodConsumptionOutcome] = [],
        totalConsumedQuantity: Int = 0,
        droppedOutcomeCount: Int = 0
    ) {
        self.authorityMode = authorityMode
        self.processedConsumptionIDs = processedConsumptionIDs
        self.completedOutcomes = completedOutcomes
        self.totalConsumedQuantity = totalConsumedQuantity
        self.droppedOutcomeCount = droppedOutcomeCount
    }
}

public enum AgentPhysicalFoodSurvivalError: Error, Equatable {
    case survivalRequired
    case disabled
    case legacyAbstractAuthorityDisabled
    case invalidIntent(String)
    case duplicateConsumption(String)
    case consumptionLimitReached
    case noHungerNeed(AgentID)
    case invalidOutcome(String)
    case invalidState(String)
}
