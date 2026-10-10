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

/// Prospective local custody evidence. Absence retains historical cognition.
/// Pebble supplies this from its existing food-consumption policy, never from
/// checkpoint item bytes, abstract stocks or acquisition totals.
public struct AgentPhysicalFoodCustodyObservation: Codable, Equatable {
    public let version: Int
    public let worldTick: Int
    public let hasEligibleFood: Bool

    public init(worldTick: Int, hasEligibleFood: Bool) {
        version = 1
        self.worldTick = worldTick
        self.hasEligibleFood = hasEligibleFood
    }

    private enum CodingKeys: String, CodingKey { case version, worldTick, hasEligibleFood }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        worldTick = try c.decode(Int.self, forKey: .worldTick)
        hasEligibleFood = try c.decode(Bool.self, forKey: .hasEligibleFood)
        guard version == 1, worldTick >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: c,
                debugDescription: "invalid physical food custody observation")
        }
    }
}

/// Session-owned bounded memory carried by the existing local observation
/// contract, like care proposal memory. It is not a route or food opportunity.
/// No global checkpoint/replay capability or historical nil semantics change.
public struct AgentHungerDiscoveryProgress: Codable, Equatable {
    public static let maximumAttempts = 24
    public static let burstAttempts = 8
    public static let cooldownTicks = 8
    public static let maximumFailures = 4

    public internal(set) var version = 1
    public internal(set) var startedAtTick: Int
    public internal(set) var attempts = 0
    public internal(set) var attemptsInBurst = 0
    public internal(set) var failures = 0
    public internal(set) var cooldownUntilTick: Int?
    public internal(set) var lastAttemptTick: Int?
    public internal(set) var lastEvaluatedOutcomeTick: Int?
    public internal(set) var refusedContexts: [String] = []

    init(startedAtTick: Int) { self.startedAtTick = startedAtTick }

    var exhausted: Bool {
        attempts >= Self.maximumAttempts || failures >= Self.maximumFailures
    }

    private enum CodingKeys: String, CodingKey {
        case version, startedAtTick, attempts, attemptsInBurst, failures
        case cooldownUntilTick, lastAttemptTick, lastEvaluatedOutcomeTick, refusedContexts
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        startedAtTick = try c.decode(Int.self, forKey: .startedAtTick)
        attempts = try c.decode(Int.self, forKey: .attempts)
        attemptsInBurst = try c.decode(Int.self, forKey: .attemptsInBurst)
        failures = try c.decode(Int.self, forKey: .failures)
        cooldownUntilTick = try c.decodeIfPresent(Int.self, forKey: .cooldownUntilTick)
        lastAttemptTick = try c.decodeIfPresent(Int.self, forKey: .lastAttemptTick)
        lastEvaluatedOutcomeTick = try c.decodeIfPresent(Int.self, forKey: .lastEvaluatedOutcomeTick)
        refusedContexts = try c.decode([String].self, forKey: .refusedContexts)
        guard version == 1, startedAtTick >= 0,
              (0...Self.maximumAttempts).contains(attempts),
              (0...Self.burstAttempts).contains(attemptsInBurst),
              attemptsInBurst <= attempts,
              (0...Self.maximumFailures).contains(failures),
              cooldownUntilTick.map({ $0 >= startedAtTick }) ?? true,
              lastAttemptTick.map({ $0 >= startedAtTick }) ?? true,
              lastEvaluatedOutcomeTick.map({ $0 >= startedAtTick && $0 <= (lastAttemptTick ?? -1) }) ?? true,
              (attempts == 0) == (lastAttemptTick == nil),
              refusedContexts.count <= Self.maximumFailures,
              refusedContexts.count <= failures,
              Set(refusedContexts).count == refusedContexts.count,
              refusedContexts.allSatisfy({ $0.count == 16 && $0.allSatisfy(\.isHexDigit) }) else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: c,
                debugDescription: "invalid bounded hunger discovery memory")
        }
    }
}
