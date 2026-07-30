public enum AgentDependentCareError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case kinshipRequired
    case householdsRequired
    case survivalRequired
    case alreadyEnabled
    case unsafeDisable
    case unknownDependent(AgentID)
    case unknownCaregiver(AgentID)
    case ineligibleCaregiver(AgentID)
    case invalidHousehold(AgentHouseholdID)
    case duplicateAssignment(AgentID)
    case assignmentCapacityReached
    case dependentCapacityReached
    case caregiverCapacityReached(AgentID)
    case needCapacityReached
    case duplicateNeed(AgentID, AgentCareNeedKind)
    case invalidNeed(String)
    case invalidEngagement(String)
    case outcomeCapacityReached
    case transitionCapacityReached
    case interactionTooFar
    case materialDebitRequired
    case capabilityDenied(AgentID, AgentStageCapability)
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid dependent care configuration: \(reason)"
        case .causalLedgerRequired: return "dependent care requires the causal ledger"
        case .populationRequired: return "dependent care requires population"
        case .lifecycleRequired: return "dependent care requires lifecycle"
        case .kinshipRequired: return "dependent care requires kinship"
        case .householdsRequired: return "dependent care requires households"
        case .survivalRequired: return "dependent care requires survival"
        case .alreadyEnabled: return "dependent care already enabled"
        case .unsafeDisable: return "dependent care disable refused while durable state exists"
        case let .unknownDependent(id): return "unknown dependent \(id.rawValue)"
        case let .unknownCaregiver(id): return "unknown caregiver \(id.rawValue)"
        case let .ineligibleCaregiver(id): return "ineligible caregiver \(id.rawValue)"
        case let .invalidHousehold(id): return "invalid care household \(id.rawValue)"
        case let .duplicateAssignment(id): return "duplicate open care assignment for \(id.rawValue)"
        case .assignmentCapacityReached: return "care assignment capacity reached"
        case .dependentCapacityReached: return "dependent capacity reached"
        case let .caregiverCapacityReached(id): return "caregiver capacity reached for \(id.rawValue)"
        case .needCapacityReached: return "active care need capacity reached"
        case let .duplicateNeed(id, kind): return "duplicate \(kind.rawValue) need for \(id.rawValue)"
        case let .invalidNeed(id): return "invalid care need \(id)"
        case let .invalidEngagement(id): return "invalid care engagement \(id)"
        case .outcomeCapacityReached: return "care outcome capacity reached"
        case .transitionCapacityReached: return "care transition capacity reached"
        case .interactionTooFar: return "care interaction distance exceeded"
        case .materialDebitRequired: return "care nourishment requires one material food debit"
        case let .capabilityDenied(id, capability):
            return "\(capability.rawValue) is denied for \(id.rawValue) at the current life stage"
        case let .invalidCausalReference(id): return "invalid care causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid dependent care state: \(reason)"
        }
    }
}

public struct AgentDependentCareConfiguration: Codable, Equatable, Sendable {
    public let maximumDependents: Int
    public let maximumAssignments: Int
    public let maximumActiveNeeds: Int
    public let maximumActiveEngagements: Int
    public let maximumRetainedOutcomes: Int
    public let maximumDependentsPerCaregiver: Int
    public let maximumCareTransitionsPerTick: Int
    public let nourishmentHungerThreshold: Double
    public let careInteractionDistance: Int
    public let supervisionIntervalTicks: Int

    public init(
        maximumDependents: Int = 64,
        maximumAssignments: Int = 256,
        maximumActiveNeeds: Int = 128,
        maximumActiveEngagements: Int = 128,
        maximumRetainedOutcomes: Int = 512,
        maximumDependentsPerCaregiver: Int = 4,
        maximumCareTransitionsPerTick: Int = 32,
        nourishmentHungerThreshold: Double = 0.20,
        careInteractionDistance: Int = 1,
        supervisionIntervalTicks: Int = 4
    ) throws {
        guard (1...512).contains(maximumDependents) else {
            throw AgentDependentCareError.invalidConfiguration("dependents")
        }
        guard (1...4096).contains(maximumAssignments) else {
            throw AgentDependentCareError.invalidConfiguration("assignments")
        }
        guard (1...4096).contains(maximumActiveNeeds) else {
            throw AgentDependentCareError.invalidConfiguration("active needs")
        }
        guard (1...4096).contains(maximumActiveEngagements) else {
            throw AgentDependentCareError.invalidConfiguration("active engagements")
        }
        guard (1...8192).contains(maximumRetainedOutcomes) else {
            throw AgentDependentCareError.invalidConfiguration("retained outcomes")
        }
        guard (1...32).contains(maximumDependentsPerCaregiver) else {
            throw AgentDependentCareError.invalidConfiguration("dependents per caregiver")
        }
        guard (1...512).contains(maximumCareTransitionsPerTick) else {
            throw AgentDependentCareError.invalidConfiguration("transitions per tick")
        }
        guard nourishmentHungerThreshold.isFinite,
              (0...1).contains(nourishmentHungerThreshold) else {
            throw AgentDependentCareError.invalidConfiguration("nourishment threshold")
        }
        guard (1...8).contains(careInteractionDistance) else {
            throw AgentDependentCareError.invalidConfiguration("interaction distance")
        }
        guard (1...128).contains(supervisionIntervalTicks) else {
            throw AgentDependentCareError.invalidConfiguration("supervision interval")
        }
        self.maximumDependents = maximumDependents
        self.maximumAssignments = maximumAssignments
        self.maximumActiveNeeds = maximumActiveNeeds
        self.maximumActiveEngagements = maximumActiveEngagements
        self.maximumRetainedOutcomes = maximumRetainedOutcomes
        self.maximumDependentsPerCaregiver = maximumDependentsPerCaregiver
        self.maximumCareTransitionsPerTick = maximumCareTransitionsPerTick
        self.nourishmentHungerThreshold = nourishmentHungerThreshold
        self.careInteractionDistance = careInteractionDistance
        self.supervisionIntervalTicks = supervisionIntervalTicks
    }

    public static let live = try! AgentDependentCareConfiguration()
}

public enum AgentCareAssignmentStatus: String, Codable, CaseIterable, Sendable {
    case active
    case ended
}

public enum AgentCareAssignmentEndReason: String, Codable, CaseIterable, Sendable {
    case caregiverDied
    case dependentDied
    case householdSeparated
    case dependentMatured
    case reassigned
}

public struct AgentCareAssignment: Codable, Equatable, Sendable {
    public let dependentID: AgentID
    public let caregiverID: AgentID
    public let householdID: AgentHouseholdID
    public let startedTick: Int
    public let startedEventID: AgentCausalEventID
    public internal(set) var endedTick: Int?
    public internal(set) var endedEventID: AgentCausalEventID?
    public internal(set) var endedReason: AgentCareAssignmentEndReason?
    public internal(set) var status: AgentCareAssignmentStatus
}

public struct AgentCareNeedID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.hasPrefix("care-need-"), rawValue.utf8.count <= 96,
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentCareNeedKind: String, Codable, CaseIterable, Sendable {
    case nourishment
    case supervision
    case returnHome
}

public enum AgentCareNeedStatus: String, Codable, CaseIterable, Sendable {
    case active
    case resolved
    case unmet
    case closed
}

public enum AgentCareNeedTerminalReason: String, Codable, CaseIterable, Sendable {
    case provided
    case supervised
    case returnedHome
    case foodUnavailable
    case noCaregiver
    case dependentDied
    case dependentMatured
}

public struct AgentCareNeed: Codable, Equatable, Sendable {
    public let needID: AgentCareNeedID
    public let dependentID: AgentID
    public let kind: AgentCareNeedKind
    public let severity: Int
    public let raisedTick: Int
    public let raisedEventID: AgentCausalEventID
    public internal(set) var status: AgentCareNeedStatus
    public internal(set) var assignedCaregiverID: AgentID?
    public internal(set) var resolvedTick: Int?
    public internal(set) var terminalReason: AgentCareNeedTerminalReason?
    public internal(set) var terminalEventID: AgentCausalEventID?
}

public struct AgentCareEngagementID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.hasPrefix("care-engagement-"), rawValue.utf8.count <= 96,
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentCareEngagementKind: String, Codable, CaseIterable, Sendable {
    case approachDependent
    case provideFood
    case supervise
    case assistReturnHome
}

public struct AgentCareEngagement: Codable, Equatable, Sendable {
    public let engagementID: AgentCareEngagementID
    public let needID: AgentCareNeedID
    public let dependentID: AgentID
    public let caregiverID: AgentID
    public let kind: AgentCareEngagementKind
    public let startedTick: Int
    public let startedEventID: AgentCausalEventID
}

public enum AgentCareFoodSource: String, Codable, CaseIterable, Sendable {
    case caregiverInventory
    case physicalCaregiverInventory
    case campStock
    case none
}

public struct AgentPhysicalDependentFoodIntent: Codable, Equatable, Sendable {
    public let provisionID: String
    public let provisionSequence: AgentCausalSequence
    public let needID: AgentCareNeedID
    public let caregiverID: AgentID
    public let dependentID: AgentID
    public let tick: Int

    public init(
        provisionID: String, provisionSequence: AgentCausalSequence,
        needID: AgentCareNeedID, caregiverID: AgentID, dependentID: AgentID, tick: Int
    ) {
        self.provisionID = provisionID
        self.provisionSequence = provisionSequence
        self.needID = needID
        self.caregiverID = caregiverID
        self.dependentID = dependentID
        self.tick = tick
    }
}

public struct AgentValidatedPhysicalDependentFoodOutcome: Codable, Equatable, Sendable {
    public let intent: AgentPhysicalDependentFoodIntent
    public let canonicalMaterialName: String
    public let quantityConsumed: Int
    public let coreHungerPoints: Int
    public let coreSaturation: Double
    public let sourceSlot: Int
    public let physicalReceiptID: String
    public let hungerBefore: Double
    public let hungerAfter: Double

    public init(
        intent: AgentPhysicalDependentFoodIntent, canonicalMaterialName: String,
        quantityConsumed: Int, coreHungerPoints: Int, coreSaturation: Double,
        sourceSlot: Int, physicalReceiptID: String,
        hungerBefore: Double, hungerAfter: Double
    ) {
        self.intent = intent
        self.canonicalMaterialName = canonicalMaterialName
        self.quantityConsumed = quantityConsumed
        self.coreHungerPoints = coreHungerPoints
        self.coreSaturation = coreSaturation
        self.sourceSlot = sourceSlot
        self.physicalReceiptID = physicalReceiptID
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
    }
}

public struct AgentCareProvisionIntent: Codable, Equatable, Sendable {
    public let provisionID: String
    public let needID: AgentCareNeedID
    public let caregiverID: AgentID
    public let dependentID: AgentID
    public let tick: Int

    public init(
        provisionID: String,
        needID: AgentCareNeedID,
        caregiverID: AgentID,
        dependentID: AgentID,
        tick: Int
    ) {
        self.provisionID = provisionID
        self.needID = needID
        self.caregiverID = caregiverID
        self.dependentID = dependentID
        self.tick = tick
    }
}

public struct AgentCareProvisionResult: Codable, Equatable, Sendable {
    public let provisionID: String
    public let needID: AgentCareNeedID
    public let caregiverID: AgentID
    public let dependentID: AgentID
    public let tick: Int
    public let succeeded: Bool
    public let foodSource: AgentCareFoodSource
    public let foodBefore: Int
    public let foodAfter: Int
    public let consumedByDependent: Int
    public let hungerBefore: Double
    public let hungerAfter: Double
    public let reason: String
}

public struct AgentCareOutcome: Codable, Equatable, Sendable {
    public let needID: AgentCareNeedID
    public let dependentID: AgentID
    public let caregiverID: AgentID?
    public let kind: AgentCareNeedKind
    public let status: AgentCareNeedStatus
    public let terminalReason: AgentCareNeedTerminalReason
    public let tick: Int
    public let foodSource: AgentCareFoodSource
    public let materialQuantity: Int
    public let hungerBefore: Double?
    public let hungerAfter: Double?
    public let terminalEventID: AgentCausalEventID
}

public struct AgentCareEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var outcomes: Int

    public init(outcomes: Int = 0) { self.outcomes = max(0, outcomes) }
}

public struct AgentDependentCareState: Codable, Equatable, Sendable {
    public let configuration: AgentDependentCareConfiguration
    public internal(set) var assignments: [AgentCareAssignment]
    public internal(set) var activeNeeds: [AgentCareNeed]
    public internal(set) var activeEngagements: [AgentCareEngagement]
    public internal(set) var terminalOutcomes: [AgentCareOutcome]
    public internal(set) var totalAssignmentCount: Int
    public internal(set) var totalNeedCount: Int
    public internal(set) var totalEngagementCount: Int
    public internal(set) var totalOutcomeCount: Int
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
    public internal(set) var evictionCounts: AgentCareEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastCareEventID: AgentCausalEventID
    /// CIV-31 extends the single Dependent Care authority. Keeping the V2
    /// state optional preserves historical schema 9...22 decoding without
    /// creating a parallel childhood engine.
    public internal(set) var childhoodV2: AgentChildhoodState? = nil
}

public enum AgentStageCapability: String, Codable, CaseIterable, Sendable {
    case perceive
    case autonomousCognition
    case autonomousAction
    case autonomousMovement
    case idle
    case returnHome
    case approachCaregiver
    case selfConsumeCarriedFood
    case harvest
    case deliver
    case build
    case cooperateAsWorker
    case reproduce
    case voluntaryMigration
}

public struct AgentStageCapabilityPolicy: Codable, Equatable, Sendable {
    public let stage: AgentLifeStage
    public let allowed: [AgentStageCapability]

    public func permits(_ capability: AgentStageCapability) -> Bool {
        allowed.contains(capability)
    }

    public static func policy(for stage: AgentLifeStage) -> Self {
        switch stage {
        case .newborn:
            return Self(stage: stage, allowed: [.perceive])
        case .juvenile:
            return Self(stage: stage, allowed: [
                .perceive, .autonomousCognition, .autonomousAction, .autonomousMovement,
                .idle, .returnHome, .approachCaregiver, .selfConsumeCarriedFood,
            ])
        case .mature:
            return Self(stage: stage, allowed: AgentStageCapability.allCases)
        }
    }
}

public struct AgentDependentCareSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentDependentCareConfiguration?
    public let assignments: [AgentCareAssignment]
    public let activeNeeds: [AgentCareNeed]
    public let activeEngagements: [AgentCareEngagement]
    public let terminalOutcomes: [AgentCareOutcome]
    public let atRiskDependentIDs: [AgentID]
    public let totalAssignmentCount: Int
    public let totalNeedCount: Int
    public let totalEngagementCount: Int
    public let totalOutcomeCount: Int
    public let evictionCounts: AgentCareEvictionCounts
    public let digest: String
}

public enum AgentDependentCareDigest {
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
