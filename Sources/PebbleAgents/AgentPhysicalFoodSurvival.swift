public enum AgentFoodAuthorityMode: String, Codable, Equatable, Sendable {
    case legacyAbstract
    case physicalItems
}

public enum AgentPhysicalFoodConsumptionStatus: String, Codable, Equatable, Sendable {
    case succeeded
}

public struct AgentPhysicalFoodConsumptionIntent: Codable, Equatable, Sendable {
    public let consumptionID: String
    public let consumptionSequence: AgentCausalSequence
    public let agentID: AgentID
    public let tick: Int

    public init(
        consumptionID: String,
        consumptionSequence: AgentCausalSequence,
        agentID: AgentID,
        tick: Int
    ) {
        self.consumptionID = consumptionID
        self.consumptionSequence = consumptionSequence
        self.agentID = agentID
        self.tick = tick
    }

    public static func canonicalConsumptionID(
        simulationID: AgentSimulationID,
        agentID: AgentID,
        sequence: AgentCausalSequence
    ) -> String {
        "physical-food:\(simulationID.rawValue):\(agentID.rawValue):\(sequence.rawValue)"
    }
}

/// Stable durable provenance for the kind of physical custody that Pebble
/// validated. Runtime entity IDs and custody endpoint identities never cross
/// this boundary.
public enum AgentPhysicalFoodSourceKind: String, Codable, Equatable, Sendable {
    case agentCarriedInventory
}

/// A pure Civilization DTO published only after Pebble has resolved Core food
/// metadata and proven one exact physical custody debit. Core hunger points use
/// the canonical Player scale (0...20); agents model hunger as a normalized
/// deficit, so `normalizedHungerReduction = min(1, coreHungerPoints / 20)`.
public struct AgentValidatedPhysicalFoodConsumptionOutcome: Codable, Equatable, Sendable {
    public let consumptionID: String
    public let consumptionSequence: AgentCausalSequence
    public let agentID: AgentID
    public let tick: Int
    public let canonicalMaterialName: String
    public let quantityConsumed: Int
    public let coreHungerPoints: Int
    public let coreSaturation: Double
    public let normalizedHungerReduction: Double
    public let status: AgentPhysicalFoodConsumptionStatus
    public let physicalReceiptID: String
    public let sourceKind: AgentPhysicalFoodSourceKind
    public let sourceSlot: Int
    public let hungerBefore: Double
    public let hungerAfter: Double

    public init(
        consumptionID: String,
        consumptionSequence: AgentCausalSequence,
        agentID: AgentID,
        tick: Int,
        canonicalMaterialName: String,
        quantityConsumed: Int,
        coreHungerPoints: Int,
        coreSaturation: Double,
        normalizedHungerReduction: Double,
        status: AgentPhysicalFoodConsumptionStatus,
        physicalReceiptID: String,
        sourceKind: AgentPhysicalFoodSourceKind,
        sourceSlot: Int,
        hungerBefore: Double,
        hungerAfter: Double
    ) {
        self.consumptionID = consumptionID
        self.consumptionSequence = consumptionSequence
        self.agentID = agentID
        self.tick = tick
        self.canonicalMaterialName = canonicalMaterialName
        self.quantityConsumed = quantityConsumed
        self.coreHungerPoints = coreHungerPoints
        self.coreSaturation = coreSaturation
        self.normalizedHungerReduction = normalizedHungerReduction
        self.status = status
        self.physicalReceiptID = physicalReceiptID
        self.sourceKind = sourceKind
        self.sourceSlot = sourceSlot
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
    }
}

public struct AgentPhysicalFoodSurvivalState: Codable, Equatable, Sendable {
    public static let maximumRetainedConsumptionIDs = 64
    public static let maximumRetainedOutcomes = 64

    public internal(set) var authorityMode: AgentFoodAuthorityMode
    public internal(set) var recentConsumptionIDs: [String]
    public internal(set) var completedOutcomes: [AgentValidatedPhysicalFoodConsumptionOutcome]
    public internal(set) var latestAcceptedConsumptionSequence: AgentCausalSequence?
    public internal(set) var totalConsumedQuantity: UInt64
    public internal(set) var droppedConsumptionIDCount: UInt64
    public internal(set) var droppedOutcomeCount: UInt64

    public init(
        authorityMode: AgentFoodAuthorityMode = .physicalItems,
        recentConsumptionIDs: [String] = [],
        completedOutcomes: [AgentValidatedPhysicalFoodConsumptionOutcome] = [],
        latestAcceptedConsumptionSequence: AgentCausalSequence? = nil,
        totalConsumedQuantity: UInt64 = 0,
        droppedConsumptionIDCount: UInt64 = 0,
        droppedOutcomeCount: UInt64 = 0
    ) {
        self.authorityMode = authorityMode
        self.recentConsumptionIDs = recentConsumptionIDs
        self.completedOutcomes = completedOutcomes
        self.latestAcceptedConsumptionSequence = latestAcceptedConsumptionSequence
        self.totalConsumedQuantity = totalConsumedQuantity
        self.droppedConsumptionIDCount = droppedConsumptionIDCount
        self.droppedOutcomeCount = droppedOutcomeCount
    }
}

public enum AgentPhysicalFoodSurvivalError: Error, Equatable {
    case survivalRequired
    case disabled
    case causalLedgerRequired
    case legacyAbstractAuthorityDisabled
    case invalidIntent(String)
    case duplicateConsumption(String)
    case noHungerNeed(AgentID)
    case invalidOutcome(String)
    case invalidState(String)
}
