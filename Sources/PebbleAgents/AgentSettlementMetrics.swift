public enum AgentSettlementMetricsError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case populationRequired
    case causalLedgerRequired
    case alreadyEnabled
    case disabled
    case invalidPulseBoundary(expected: Int, actual: Int)
    case macroSequenceOverflow
    case invalidFrame(String)
    case invalidBaseline(String)
    case fixedPointOverflow

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid settlement metrics configuration: \(reason)"
        case .populationRequired:
            return "settlement metrics require the population registry"
        case .causalLedgerRequired:
            return "settlement metrics require the causal ledger"
        case .alreadyEnabled:
            return "settlement metrics already enabled"
        case .disabled:
            return "settlement metrics disabled"
        case let .invalidPulseBoundary(expected, actual):
            return "invalid settlement pulse boundary: expected \(expected), actual \(actual)"
        case .macroSequenceOverflow:
            return "settlement macro sequence overflow"
        case let .invalidFrame(reason):
            return "invalid settlement metric frame: \(reason)"
        case let .invalidBaseline(reason):
            return "invalid settlement metric baseline: \(reason)"
        case .fixedPointOverflow:
            return "settlement fixed-point conversion overflow"
        }
    }
}

public struct AgentSettlementMetricsConfiguration: Codable, Equatable, Sendable {
    public let macroIntervalTicks: Int
    public let maximumMetricFrames: Int
    public let maximumAgentClassifications: Int
    public let maximumCausalEventsPerWindow: Int
    public let fixedPointScale: Int64

    public init(
        macroIntervalTicks: Int = 4,
        maximumMetricFrames: Int = 16,
        maximumAgentClassifications: Int = 8,
        maximumCausalEventsPerWindow: Int = 4096,
        fixedPointScale: Int64 = 1_000_000
    ) throws {
        guard (2...32).contains(macroIntervalTicks) else {
            throw AgentSettlementMetricsError.invalidConfiguration("macro interval")
        }
        guard (1...64).contains(maximumMetricFrames) else {
            throw AgentSettlementMetricsError.invalidConfiguration("frame history")
        }
        guard (8...64).contains(maximumAgentClassifications) else {
            throw AgentSettlementMetricsError.invalidConfiguration("agent classifications")
        }
        guard (1...4096).contains(maximumCausalEventsPerWindow) else {
            throw AgentSettlementMetricsError.invalidConfiguration("causal window")
        }
        guard fixedPointScale == 1_000_000 else {
            throw AgentSettlementMetricsError.invalidConfiguration("fixed-point scale")
        }
        self.macroIntervalTicks = macroIntervalTicks
        self.maximumMetricFrames = maximumMetricFrames
        self.maximumAgentClassifications = maximumAgentClassifications
        self.maximumCausalEventsPerWindow = maximumCausalEventsPerWindow
        self.fixedPointScale = fixedPointScale
    }

    public static let live = try! AgentSettlementMetricsConfiguration()
}

public struct AgentMetricFixedPoint: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    public init(value: Double, scale: Int64 = 1_000_000) throws {
        let scaled = value * Double(scale)
        let rounded = scaled.rounded(.toNearestOrAwayFromZero)
        guard scaled.isFinite,
              rounded >= Double(Int64.min),
              rounded < Double(Int64.max) else {
            throw AgentSettlementMetricsError.fixedPointOverflow
        }
        rawValue = Int64(rounded)
    }

    public static func < (lhs: AgentMetricFixedPoint, rhs: AgentMetricFixedPoint) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentMetricFixedPointDistribution: Codable, Equatable, Sendable {
    public let count: Int
    public let minimum: AgentMetricFixedPoint
    public let maximum: AgentMetricFixedPoint
    public let sum: AgentMetricFixedPoint
    public let mean: AgentMetricFixedPoint

    public init(values: [AgentMetricFixedPoint]) throws {
        guard let minimum = values.min(), let maximum = values.max(), !values.isEmpty else {
            throw AgentSettlementMetricsError.invalidFrame("empty fixed-point distribution")
        }
        var total: Int64 = 0
        for value in values {
            let (next, overflow) = total.addingReportingOverflow(value.rawValue)
            guard !overflow else { throw AgentSettlementMetricsError.fixedPointOverflow }
            total = next
        }
        count = values.count
        self.minimum = minimum
        self.maximum = maximum
        sum = AgentMetricFixedPoint(rawValue: total)
        mean = AgentMetricFixedPoint(rawValue: total / Int64(values.count))
    }
}

public struct AgentSettlementMacroSequence:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: UInt64

    public init?(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static func < (
        lhs: AgentSettlementMacroSequence,
        rhs: AgentSettlementMacroSequence
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static let zero = AgentSettlementMacroSequence(rawValue: 0)!
}

public struct AgentSettlementMetricFrameID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...128).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95 || $0 == 47
              }) else { return nil }
        self.rawValue = rawValue
    }

    public init(
        settlementID: AgentSettlementID,
        macroSequence: AgentSettlementMacroSequence,
        endTick: Int
    ) {
        let digits = String(macroSequence.rawValue)
        let padded = String(repeating: "0", count: max(0, 8 - digits.count)) + digits
        rawValue = "\(settlementID.rawValue)/frame-\(padded)-t\(endTick)"
    }

    public static func < (
        lhs: AgentSettlementMetricFrameID,
        rhs: AgentSettlementMetricFrameID
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentSettlementCondition: String, Codable, CaseIterable, Sendable {
    case stable
    case active
    case transitioning
    case strained
    case incomplete
}

public enum AgentSettlementActivityTier: String, Codable, CaseIterable, Sendable {
    case microUrgent
    case microMigrating
    case microEngaged
    case macroObservedStable
}

public struct AgentSettlementAgentClassification: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let tier: AgentSettlementActivityTier
    public let reason: String

    public init(
        agentID: AgentID,
        tier: AgentSettlementActivityTier,
        reason: String
    ) {
        self.agentID = agentID
        self.tier = tier
        self.reason = String(reason.prefix(64))
    }
}

public struct AgentSettlementMetricBaseline: Codable, Equatable, Sendable {
    public let tick: Int
    public let causalSequence: UInt64
    public let movementCount: Int
    public let distanceMoved: Int
    public let harvestedUnits: Int
    public let consumedUnits: Int
    public let settledMaterialUnits: Int

    public init(
        tick: Int,
        causalSequence: UInt64,
        movementCount: Int,
        distanceMoved: Int,
        harvestedUnits: Int,
        consumedUnits: Int,
        settledMaterialUnits: Int
    ) {
        self.tick = tick
        self.causalSequence = causalSequence
        self.movementCount = movementCount
        self.distanceMoved = distanceMoved
        self.harvestedUnits = harvestedUnits
        self.consumedUnits = consumedUnits
        self.settledMaterialUnits = settledMaterialUnits
    }
}

public struct AgentSettlementPopulationMetrics: Codable, Equatable, Sendable {
    public let capacity: Int
    public let members: Int
    public let founders: Int
    public let residents: Int
    public let migrants: Int
    public let admissionDelta: Int
    public let arrivalDelta: Int
}

public struct AgentSettlementActivityMetrics: Codable, Equatable, Sendable {
    public let urgentCount: Int
    public let migratingCount: Int
    public let engagedCount: Int
    public let stableCount: Int
    public let classifications: [AgentSettlementAgentClassification]
}

public struct AgentSettlementWelfareMetrics: Codable, Equatable, Sendable {
    public let hunger: AgentMetricFixedPointDistribution
    public let fatigue: AgentMetricFixedPointDistribution
    public let curiosity: AgentMetricFixedPointDistribution
    public let safety: AgentMetricFixedPointDistribution
    public let minimumHealth: Int
    public let meanHealth: Int
    public let maximumFear: Int
    public let hungryCount: Int
    public let criticalHungerCount: Int
    public let fatiguedCount: Int
}

public struct AgentSettlementSpatialMetrics: Codable, Equatable, Sendable {
    public let agentsAtHome: Int
    public let agentsAwayFromHome: Int
    public let totalDistanceFromHome: Int
    public let maximumDistanceFromHome: Int
    public let totalDistanceFromAnchor: Int
    public let maximumDistanceFromAnchor: Int
    public let distinctOccupiedPositions: Int
}

public struct AgentSettlementMaterialMetrics: Codable, Equatable {
    public let campStock: [AgentResourceAmount]
    public let carried: [AgentResourceAmount]
    public let harvested: [AgentResourceAmount]
    public let consumed: [AgentResourceAmount]
    public let constructionEscrow: [AgentResourceAmount]
    public let constructed: [AgentResourceAmount]
    public let conservationBalanced: Bool
}

public struct AgentSettlementThroughputMetrics: Codable, Equatable, Sendable {
    public let movementDelta: Int
    public let distanceDelta: Int
    public let successfulInteractionDelta: Int
    public let harvestedUnitDelta: Int
    public let deliveryDelta: Int
    public let deliveredUnitDelta: Int
    public let consumptionDelta: Int
    public let constructionPlacementDelta: Int
    public let constructionCompletionDelta: Int

    public var materialActivityDelta: Int {
        successfulInteractionDelta + deliveryDelta + consumptionDelta
            + constructionPlacementDelta + constructionCompletionDelta
    }
}

public struct AgentSettlementSocialMetrics: Codable, Equatable, Sendable {
    public let factsRetained: Int
    public let messagesRetained: Int
    public let beliefsRetained: Int
    public let trustEdges: Int
    public let eventDelta: Int
}

public struct AgentSettlementPhysicalMetrics: Codable, Equatable, Sendable {
    public let signalsRetained: Int
    public let exactCount: Int
    public let ambiguousCount: Int
    public let missedCount: Int
    public let inconclusiveCount: Int
    public let eventDelta: Int
}

public struct AgentSettlementCooperationMetrics: Codable, Equatable, Sendable {
    public let activeTasks: Int
    public let completedTasks: Int
    public let reliabilityEdges: Int
    public let eventDelta: Int
}

public struct AgentSettlementMetricFrame: Codable, Equatable {
    public let frameID: AgentSettlementMetricFrameID
    public let settlementID: AgentSettlementID
    public let macroSequence: AgentSettlementMacroSequence
    public let fromTickExclusive: Int
    public let toTickInclusive: Int
    public let causalSequenceStartExclusive: UInt64
    public let causalSequenceEndInclusive: UInt64
    public let causalCoverageComplete: Bool
    public let population: AgentSettlementPopulationMetrics
    public let activity: AgentSettlementActivityMetrics
    public let welfare: AgentSettlementWelfareMetrics
    public let spatial: AgentSettlementSpatialMetrics
    public let material: AgentSettlementMaterialMetrics
    public let throughput: AgentSettlementThroughputMetrics
    public let social: AgentSettlementSocialMetrics
    public let physical: AgentSettlementPhysicalMetrics
    public let cooperation: AgentSettlementCooperationMetrics
    public let populationEventDelta: Int
    public let condition: AgentSettlementCondition
    public let reasonCode: String
    public let digest: String

    public init(
        frameID: AgentSettlementMetricFrameID,
        settlementID: AgentSettlementID,
        macroSequence: AgentSettlementMacroSequence,
        fromTickExclusive: Int,
        toTickInclusive: Int,
        causalSequenceStartExclusive: UInt64,
        causalSequenceEndInclusive: UInt64,
        causalCoverageComplete: Bool,
        population: AgentSettlementPopulationMetrics,
        activity: AgentSettlementActivityMetrics,
        welfare: AgentSettlementWelfareMetrics,
        spatial: AgentSettlementSpatialMetrics,
        material: AgentSettlementMaterialMetrics,
        throughput: AgentSettlementThroughputMetrics,
        social: AgentSettlementSocialMetrics,
        physical: AgentSettlementPhysicalMetrics,
        cooperation: AgentSettlementCooperationMetrics,
        populationEventDelta: Int,
        condition: AgentSettlementCondition,
        reasonCode: String
    ) {
        self.frameID = frameID
        self.settlementID = settlementID
        self.macroSequence = macroSequence
        self.fromTickExclusive = fromTickExclusive
        self.toTickInclusive = toTickInclusive
        self.causalSequenceStartExclusive = causalSequenceStartExclusive
        self.causalSequenceEndInclusive = causalSequenceEndInclusive
        self.causalCoverageComplete = causalCoverageComplete
        self.population = population
        self.activity = activity
        self.welfare = welfare
        self.spatial = spatial
        self.material = material
        self.throughput = throughput
        self.social = social
        self.physical = physical
        self.cooperation = cooperation
        self.populationEventDelta = populationEventDelta
        self.condition = condition
        self.reasonCode = String(reasonCode.prefix(64))
        digest = AgentSettlementMetricsDigest.make(
            "\(frameID.rawValue)|\(macroSequence.rawValue)|\(fromTickExclusive)|"
                + "\(toTickInclusive)|\(causalSequenceStartExclusive)|"
                + "\(causalSequenceEndInclusive)|\(causalCoverageComplete ? 1 : 0)|"
                + "\(population.members)|\(population.residents)|\(population.migrants)|"
                + "\(activity.urgentCount)|\(activity.migratingCount)|"
                + "\(activity.engagedCount)|\(activity.stableCount)|"
                + activity.classifications.map {
                    "\($0.agentID.rawValue):\($0.tier.rawValue):\($0.reason)"
                }.joined(separator: ",")
                + "|\(throughput.movementDelta)|\(throughput.distanceDelta)|"
                + "\(throughput.materialActivityDelta)|\(social.eventDelta)|"
                + "\(physical.eventDelta)|\(cooperation.eventDelta)|"
                + "\(populationEventDelta)|\(condition.rawValue)|\(self.reasonCode)"
        )
    }
}

public struct AgentSettlementMetricsEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var frames: Int

    public init(frames: Int = 0) {
        self.frames = frames
    }
}

public struct AgentSettlementMetricsState: Codable, Equatable {
    public let configuration: AgentSettlementMetricsConfiguration
    public let settlementID: AgentSettlementID
    public internal(set) var macroSequence: AgentSettlementMacroSequence
    public internal(set) var lastPulseTick: Int
    public internal(set) var nextPulseTick: Int
    public internal(set) var baseline: AgentSettlementMetricBaseline
    public internal(set) var frames: [AgentSettlementMetricFrame]
    public internal(set) var evictionCounts: AgentSettlementMetricsEvictionCounts
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastSettlementEventID: AgentCausalEventID
}

public struct AgentSettlementMetricsSnapshot: Codable, Equatable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentSettlementMetricsConfiguration?
    public let settlementID: AgentSettlementID?
    public let macroSequence: AgentSettlementMacroSequence
    public let lastPulseTick: Int?
    public let nextPulseTick: Int?
    public let frames: [AgentSettlementMetricFrame]
    public let evictionCounts: AgentSettlementMetricsEvictionCounts
    public let digest: String
}

public struct AgentSettlementMetricsSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let settlementID: AgentSettlementID?
    public let microTick: Int
    public let macroIntervalTicks: Int?
    public let macroSequence: UInt64
    public let lastPulseTick: Int?
    public let nextPulseTick: Int?
    public let retainedFrameCount: Int
    public let evictedFrameCount: Int
    public let condition: AgentSettlementCondition?
    public let population: Int
    public let capacity: Int
    public let urgent: Int
    public let migrating: Int
    public let engaged: Int
    public let stable: Int
    public let movementDelta: Int
    public let materialActivityDelta: Int
    public let socialActivityDelta: Int
    public let cooperationActivityDelta: Int
    public let causalCoverageComplete: Bool?
    public let digest: String
}

public struct AgentSettlementAgentMetricsSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let settlementID: AgentSettlementID?
    public let macroSequence: AgentSettlementMacroSequence
    public let classification: AgentSettlementAgentClassification?
}

public enum AgentSettlementMetricsDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
