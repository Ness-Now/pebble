import Foundation

public enum AgentLivestockError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case skillsRequired
    case ecologicalObservationRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case incapableAgent(AgentID)
    case humanCarePriority(AgentID)
    case invalidHerd(String)
    case unknownHerd(AgentLivestockHerdID)
    case invalidAnimal(String)
    case unknownAnimal(AgentManagedAnimalRecordID)
    case invalidTask(String)
    case unknownTask(AgentLivestockTaskID)
    case conflict(String)
    case capacityReached(String)
    case duplicateAction(AgentLivestockActionID)
    case actionsPerTickReached
    case invalidOutcome(String)
    case invalidInitiationContext(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(value): return "invalid livestock configuration: \(value)"
        case .causalLedgerRequired: return "livestock requires the causal ledger"
        case .populationRequired: return "livestock requires population"
        case .lifecycleRequired: return "livestock requires lifecycle"
        case .skillsRequired: return "livestock requires skills"
        case .ecologicalObservationRequired: return "livestock requires ecological observation"
        case .alreadyEnabled: return "livestock already enabled"
        case .disabled: return "livestock disabled"
        case .unsafeDisable: return "livestock disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown livestock agent \(id.rawValue)"
        case let .incapableAgent(id): return "livestock capability refused for \(id.rawValue)"
        case let .humanCarePriority(id): return "human dependent care preempts livestock for \(id.rawValue)"
        case let .invalidHerd(value): return "invalid livestock herd: \(value)"
        case let .unknownHerd(id): return "unknown livestock herd \(id.rawValue)"
        case let .invalidAnimal(value): return "invalid managed animal: \(value)"
        case let .unknownAnimal(id): return "unknown managed animal \(id.rawValue)"
        case let .invalidTask(value): return "invalid livestock task: \(value)"
        case let .unknownTask(id): return "unknown livestock task \(id.rawValue)"
        case let .conflict(value): return "livestock conflict: \(value)"
        case let .capacityReached(value): return "livestock capacity reached: \(value)"
        case let .duplicateAction(id): return "duplicate livestock action \(id.rawValue)"
        case .actionsPerTickReached: return "livestock actions per tick reached"
        case let .invalidOutcome(value): return "invalid livestock outcome: \(value)"
        case let .invalidInitiationContext(value): return "invalid livestock initiation context: \(value)"
        case let .invalidState(value): return "invalid livestock state: \(value)"
        }
    }
}

public struct AgentLivestockConfiguration: Codable, Equatable, Sendable {
    public let maximumHerds: Int
    public let maximumManagedAnimalsPerHerd: Int
    public let maximumActiveTasks: Int
    public let maximumReservations: Int
    public let reservationLifetimeTicks: Int
    public let maximumRetainedTaskRecords: Int
    public let maximumRetainedBreedingDecisions: Int
    public let maximumRetainedProductRecords: Int
    public let maximumRetainedLossRecords: Int
    public let maximumProcessedActionIDs: Int
    public let maximumActionsPerTick: Int
    public let maximumPhysicalCausalIDsPerOutcome: Int

    public init(
        maximumHerds: Int = 4,
        maximumManagedAnimalsPerHerd: Int = 16,
        maximumActiveTasks: Int = 24,
        maximumReservations: Int = 24,
        reservationLifetimeTicks: Int = 8,
        maximumRetainedTaskRecords: Int = 128,
        maximumRetainedBreedingDecisions: Int = 64,
        maximumRetainedProductRecords: Int = 64,
        maximumRetainedLossRecords: Int = 64,
        maximumProcessedActionIDs: Int = 1024,
        maximumActionsPerTick: Int = 8,
        maximumPhysicalCausalIDsPerOutcome: Int = 64
    ) throws {
        guard (1...16).contains(maximumHerds) else { throw AgentLivestockError.invalidConfiguration("herds") }
        guard (1...64).contains(maximumManagedAnimalsPerHerd) else { throw AgentLivestockError.invalidConfiguration("animals per herd") }
        guard (1...128).contains(maximumActiveTasks) else { throw AgentLivestockError.invalidConfiguration("active tasks") }
        guard (1...128).contains(maximumReservations) else { throw AgentLivestockError.invalidConfiguration("reservations") }
        guard (1...64).contains(reservationLifetimeTicks) else { throw AgentLivestockError.invalidConfiguration("reservation lifetime") }
        guard (1...1024).contains(maximumRetainedTaskRecords) else { throw AgentLivestockError.invalidConfiguration("task history") }
        guard (1...512).contains(maximumRetainedBreedingDecisions) else { throw AgentLivestockError.invalidConfiguration("breeding decisions") }
        guard (1...512).contains(maximumRetainedProductRecords) else { throw AgentLivestockError.invalidConfiguration("product history") }
        guard (1...512).contains(maximumRetainedLossRecords) else { throw AgentLivestockError.invalidConfiguration("loss history") }
        guard (maximumRetainedTaskRecords...16_384).contains(maximumProcessedActionIDs) else { throw AgentLivestockError.invalidConfiguration("processed actions") }
        guard (1...128).contains(maximumActionsPerTick) else { throw AgentLivestockError.invalidConfiguration("actions per tick") }
        guard (1...128).contains(maximumPhysicalCausalIDsPerOutcome) else { throw AgentLivestockError.invalidConfiguration("physical causal IDs") }
        self.maximumHerds = maximumHerds
        self.maximumManagedAnimalsPerHerd = maximumManagedAnimalsPerHerd
        self.maximumActiveTasks = maximumActiveTasks
        self.maximumReservations = maximumReservations
        self.reservationLifetimeTicks = reservationLifetimeTicks
        self.maximumRetainedTaskRecords = maximumRetainedTaskRecords
        self.maximumRetainedBreedingDecisions = maximumRetainedBreedingDecisions
        self.maximumRetainedProductRecords = maximumRetainedProductRecords
        self.maximumRetainedLossRecords = maximumRetainedLossRecords
        self.maximumProcessedActionIDs = maximumProcessedActionIDs
        self.maximumActionsPerTick = maximumActionsPerTick
        self.maximumPhysicalCausalIDsPerOutcome = maximumPhysicalCausalIDsPerOutcome
    }

    public static let live = try! AgentLivestockConfiguration()
}

private func validLivestockID(_ rawValue: String) -> Bool {
    (1...160).contains(rawValue.count)
        && rawValue.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0)) }
}

public struct AgentLivestockHerdID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) { guard validLivestockID(rawValue) else { return nil }; self.rawValue = rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentManagedAnimalRecordID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) { guard validLivestockID(rawValue) else { return nil }; self.rawValue = rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentLivestockTaskID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) { guard validLivestockID(rawValue) else { return nil }; self.rawValue = rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentLivestockActionID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) { guard validLivestockID(rawValue) else { return nil }; self.rawValue = rawValue }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentLivestockManagementArea: Codable, Equatable, Sendable {
    public let minimum: AgentPosition
    public let maximum: AgentPosition

    public init(minimum: AgentPosition, maximum: AgentPosition) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public func contains(_ position: AgentPosition) -> Bool {
        (minimum.x...maximum.x).contains(position.x)
            && (minimum.y...maximum.y).contains(position.y)
            && (minimum.z...maximum.z).contains(position.z)
    }
}

public enum AgentManagedAnimalStatus: String, Codable, CaseIterable, Sendable {
    case managed
    case outsideManagementArea
    case missing
    case unresolved
    case dead
    case released

    public var resolvedLiving: Bool { self == .managed || self == .outsideManagementArea }
}

public enum AgentManagedAnimalResolutionKind: String, Codable, CaseIterable, Sendable {
    case resolvedLiving
    case missing
    case ambiguous
    case dead
}

public struct AgentManagedAnimalRecord: Codable, Equatable, Sendable {
    public let recordID: AgentManagedAnimalRecordID
    public let herdID: AgentLivestockHerdID
    public let speciesKey: String
    public let sourceObservationEventID: AgentCausalEventID
    public let joinedAtTick: Int
    public internal(set) var status: AgentManagedAnimalStatus
    public internal(set) var lastKnownPosition: AgentPosition
    public internal(set) var lastObservedLifeStage: AgentAnimalLifeStage
    public internal(set) var breedingReady: Bool
    public internal(set) var productReady: Bool
    public internal(set) var lastResolvedAtTick: Int?
    public internal(set) var lastReconciliationReason: String
    public let admittedEventID: AgentCausalEventID
}

public struct AgentManagedHerd: Codable, Equatable, Sendable {
    public let herdID: AgentLivestockHerdID
    public let speciesKey: String
    public let managementArea: AgentLivestockManagementArea
    public internal(set) var responsibleAgentIDs: [AgentID]
    public internal(set) var managedAnimalRecordIDs: [AgentManagedAnimalRecordID]
    public let establishedAtTick: Int
    public let establishedEventID: AgentCausalEventID
}

public enum AgentLivestockTaskKind: String, Codable, CaseIterable, Sendable {
    case observe
    case feed
    case herdMove
    case breed
    case collectProduct
    case recoverMissing
    case slaughter

    public var followsManagedAnimalPosition: Bool {
        switch self {
        case .observe, .feed, .breed, .collectProduct, .slaughter:
            return true
        case .herdMove, .recoverMissing:
            return false
        }
    }
}

public enum AgentLivestockTaskStatus: String, Codable, CaseIterable, Sendable {
    case queued
    case reserved
    case completed
    case failed
    case interrupted
    case expired

    public var terminal: Bool { ![.queued, .reserved].contains(self) }
}

public struct AgentLivestockTask: Codable, Equatable, Sendable {
    public let taskID: AgentLivestockTaskID
    public let herdID: AgentLivestockHerdID
    public let kind: AgentLivestockTaskKind
    public let primaryAnimalRecordID: AgentManagedAnimalRecordID
    public let secondaryAnimalRecordID: AgentManagedAnimalRecordID?
    public let responsibleAgentID: AgentID
    public let targetPosition: AgentPosition
    public let createdAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var status: AgentLivestockTaskStatus
    public let createdEventID: AgentCausalEventID
    public internal(set) var terminalEventID: AgentCausalEventID?
}

public struct AgentLivestockTaskRequest: Codable, Equatable, Sendable {
    public let taskID: AgentLivestockTaskID
    public let herdID: AgentLivestockHerdID
    public let kind: AgentLivestockTaskKind
    public let primaryAnimalRecordID: AgentManagedAnimalRecordID
    public let secondaryAnimalRecordID: AgentManagedAnimalRecordID?
    public let responsibleAgentID: AgentID
    public let targetPosition: AgentPosition

    public init(
        taskID: AgentLivestockTaskID,
        herdID: AgentLivestockHerdID,
        kind: AgentLivestockTaskKind,
        primaryAnimalRecordID: AgentManagedAnimalRecordID,
        secondaryAnimalRecordID: AgentManagedAnimalRecordID? = nil,
        responsibleAgentID: AgentID,
        targetPosition: AgentPosition
    ) {
        self.taskID = taskID
        self.herdID = herdID
        self.kind = kind
        self.primaryAnimalRecordID = primaryAnimalRecordID
        self.secondaryAnimalRecordID = secondaryAnimalRecordID
        self.responsibleAgentID = responsibleAgentID
        self.targetPosition = targetPosition
    }
}

public struct AgentLivestockReservation: Codable, Equatable, Sendable {
    public let reservationKey: String
    public let taskID: AgentLivestockTaskID
    public let responsibleAgentID: AgentID
    public let reservedAtTick: Int
    public let expiresAtTick: Int
}

public enum AgentLivestockOutcomeStatus: String, Codable, CaseIterable, Sendable {
    case succeeded
    case failed
    case interrupted
    case reconciled

    public var successful: Bool { self == .succeeded }
}

public enum AgentLivestockActionKind: String, Codable, CaseIterable, Sendable {
    case feed
    case herdMove
    case breedingObserved
    case collectProduct
    case slaughter
}

public struct AgentLivestockOffspringSnapshot: Codable, Equatable, Sendable {
    public let recordID: AgentManagedAnimalRecordID
    public let speciesKey: String
    public let position: AgentPosition
    public let lifeStage: AgentAnimalLifeStage

    public init(recordID: AgentManagedAnimalRecordID, speciesKey: String, position: AgentPosition, lifeStage: AgentAnimalLifeStage) {
        self.recordID = recordID
        self.speciesKey = speciesKey
        self.position = position
        self.lifeStage = lifeStage
    }
}

public struct AgentLivestockValidatedOutcome: Codable, Equatable, Sendable {
    public let actionID: AgentLivestockActionID
    public let taskID: AgentLivestockTaskID
    public let actorID: AgentID
    public let kind: AgentLivestockActionKind
    public let status: AgentLivestockOutcomeStatus
    public let primaryAnimalRecordID: AgentManagedAnimalRecordID
    public let secondaryAnimalRecordID: AgentManagedAnimalRecordID?
    public let physicalCausalIDs: [Int]
    public let consumedItems: [AgentMaterialStackSnapshot]
    public let acquiredItems: [AgentMaterialStackSnapshot]
    public let offspring: AgentLivestockOffspringSnapshot?
    public let finalPosition: AgentPosition?
    public let custodyFingerprint: String?
    public let attribution: String
    public let completedAtTick: Int

    public init(
        actionID: AgentLivestockActionID,
        taskID: AgentLivestockTaskID,
        actorID: AgentID,
        kind: AgentLivestockActionKind,
        status: AgentLivestockOutcomeStatus,
        primaryAnimalRecordID: AgentManagedAnimalRecordID,
        secondaryAnimalRecordID: AgentManagedAnimalRecordID? = nil,
        physicalCausalIDs: [Int] = [],
        consumedItems: [AgentMaterialStackSnapshot] = [],
        acquiredItems: [AgentMaterialStackSnapshot] = [],
        offspring: AgentLivestockOffspringSnapshot? = nil,
        finalPosition: AgentPosition? = nil,
        custodyFingerprint: String? = nil,
        attribution: String,
        completedAtTick: Int
    ) {
        self.actionID = actionID
        self.taskID = taskID
        self.actorID = actorID
        self.kind = kind
        self.status = status
        self.primaryAnimalRecordID = primaryAnimalRecordID
        self.secondaryAnimalRecordID = secondaryAnimalRecordID
        self.physicalCausalIDs = physicalCausalIDs.sorted()
        self.consumedItems = consumedItems.sorted(by: AgentLivestockValidatedOutcome.materialSort)
        self.acquiredItems = acquiredItems.sorted(by: AgentLivestockValidatedOutcome.materialSort)
        self.offspring = offspring
        self.finalPosition = finalPosition
        self.custodyFingerprint = custodyFingerprint
        self.attribution = attribution
        self.completedAtTick = completedAtTick
    }

    public var consumedQuantity: Int { consumedItems.reduce(0) { $0 + $1.count } }
    public var acquiredQuantity: Int { acquiredItems.reduce(0) { $0 + $1.count } }

    private static func materialSort(_ lhs: AgentMaterialStackSnapshot, _ rhs: AgentMaterialStackSnapshot) -> Bool {
        if lhs.identity.itemKey != rhs.identity.itemKey { return lhs.identity.itemKey < rhs.identity.itemKey }
        if lhs.identity.damage != rhs.identity.damage { return lhs.identity.damage < rhs.identity.damage }
        return lhs.count < rhs.count
    }
}

public struct AgentLivestockOutcomeRecord: Codable, Equatable, Sendable {
    public let outcome: AgentLivestockValidatedOutcome
    public let livestockEventID: AgentCausalEventID
    public let skillPracticeEventID: AgentCausalEventID?
    public let digest: String
}

public enum AgentLivestockBreedingDecisionStatus: String, Codable, CaseIterable, Sendable {
    case approved
    case deferredFeedShortage
    case deferredCapacity
    case deferredHumanCare
}

public struct AgentLivestockBreedingDecision: Codable, Equatable, Sendable {
    public let actionID: AgentLivestockActionID
    public let herdID: AgentLivestockHerdID
    public let actorID: AgentID
    public let parentRecordIDs: [AgentManagedAnimalRecordID]
    public let compatibleFeedQuantity: Int
    public let reservedPlantingQuantity: Int
    public let eligibleFeedQuantity: Int
    public let status: AgentLivestockBreedingDecisionStatus
    public let decidedAtTick: Int
    public let causalEventID: AgentCausalEventID
}

public enum AgentLivestockLossKind: String, Codable, CaseIterable, Sendable {
    case missing
    case dead
}

public struct AgentAnimalLossRecord: Codable, Equatable, Sendable {
    public let recordID: AgentManagedAnimalRecordID
    public let herdID: AgentLivestockHerdID
    public let kind: AgentLivestockLossKind
    public let reason: String
    public let recordedAtTick: Int
    public let causalEventID: AgentCausalEventID
}

public struct AgentAnimalProductRecord: Codable, Equatable, Sendable {
    public let recordID: AgentManagedAnimalRecordID
    public let actionID: AgentLivestockActionID
    public let products: [AgentMaterialStackSnapshot]
    public let acquiredAtTick: Int
    public let causalEventID: AgentCausalEventID
}

public struct AgentManagedAnimalResolution: Codable, Equatable, Sendable {
    public let recordID: AgentManagedAnimalRecordID
    public let kind: AgentManagedAnimalResolutionKind
    public let speciesKey: String
    public let position: AgentPosition?
    public let lifeStage: AgentAnimalLifeStage?
    public let breedingReady: Bool
    public let productReady: Bool
    public let reason: String
    public let observedAtTick: Int

    public init(recordID: AgentManagedAnimalRecordID, kind: AgentManagedAnimalResolutionKind, speciesKey: String, position: AgentPosition? = nil, lifeStage: AgentAnimalLifeStage? = nil, breedingReady: Bool = false, productReady: Bool = false, reason: String, observedAtTick: Int) {
        self.recordID = recordID
        self.kind = kind
        self.speciesKey = speciesKey
        self.position = position
        self.lifeStage = lifeStage
        self.breedingReady = breedingReady
        self.productReady = productReady
        self.reason = reason
        self.observedAtTick = observedAtTick
    }
}

public struct AgentLivestockFeedPressureSnapshot: Codable, Equatable, Sendable {
    public enum Level: String, Codable, CaseIterable, Sendable { case low, medium, high }
    public let managedLivingCount: Int
    public let compatibleFeedQuantity: Int
    public let reservedPlantingQuantity: Int
    public let eligibleFeedQuantity: Int
    public let recentFeedConsumption: Int
    public let level: Level
}

public struct AgentLivestockCapitalSnapshot: Codable, Equatable, Sendable {
    public let historicalManagedRecordCount: Int
    public let resolvedLivingCount: Int
    public let adultCount: Int
    public let youngCount: Int
    public let breedingReadyCount: Int
    public let productReadyCount: Int
    public let unresolvedCount: Int
    public let missingCount: Int
    public let deadCount: Int
    public let releasedCount: Int
    public let recentBirths: Int
    public let recentLosses: Int
    public let recentPhysicalOutputs: Int
    public let feedInputsObserved: Int
}

public struct AgentLivestockEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var taskRecords = 0
    public internal(set) var breedingDecisions = 0
    public internal(set) var productRecords = 0
    public internal(set) var lossRecords = 0
    public internal(set) var processedActionIDs = 0
    public init() {}
}

public struct AgentLivestockState: Codable, Equatable, Sendable {
    public let configuration: AgentLivestockConfiguration
    public internal(set) var herds: [AgentManagedHerd]
    public internal(set) var managedAnimals: [AgentManagedAnimalRecord]
    public internal(set) var activeTasks: [AgentLivestockTask]
    public internal(set) var reservations: [AgentLivestockReservation]
    public internal(set) var retainedTaskRecords: [AgentLivestockOutcomeRecord]
    public internal(set) var breedingDecisions: [AgentLivestockBreedingDecision]
    public internal(set) var productRecords: [AgentAnimalProductRecord]
    public internal(set) var lossRecords: [AgentAnimalLossRecord]
    public internal(set) var processedActionIDs: [AgentLivestockActionID]
    public internal(set) var totalActionCount: Int
    public internal(set) var totalOffspringCount: Int
    public internal(set) var evictionCounts: AgentLivestockEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastLivestockEventID: AgentCausalEventID
    public internal(set) var transitionTick: Int
    public internal(set) var actionsAtTick: Int
}

public struct AgentLivestockSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let herds: [AgentManagedHerd]
    public let managedAnimals: [AgentManagedAnimalRecord]
    public let activeTasks: [AgentLivestockTask]
    public let reservations: [AgentLivestockReservation]
    public let retainedTaskRecords: [AgentLivestockOutcomeRecord]
    public let breedingDecisions: [AgentLivestockBreedingDecision]
    public let productRecords: [AgentAnimalProductRecord]
    public let lossRecords: [AgentAnimalLossRecord]
    public let capital: AgentLivestockCapitalSnapshot
    public let evictionCounts: AgentLivestockEvictionCounts
    public let digest: String
}

public enum AgentLivestockOperation: Codable, Equatable, Sendable {
    case establishHerd(
        herdID: AgentLivestockHerdID, speciesKey: String,
        managementArea: AgentLivestockManagementArea, responsibleAgentIDs: [AgentID]
    )
    case admitObservedAnimal(
        recordID: AgentManagedAnimalRecordID, herdID: AgentLivestockHerdID,
        actorID: AgentID, speciesKey: String, position: AgentPosition,
        lifeStage: AgentAnimalLifeStage, sourceObservationEventID: AgentCausalEventID,
        compatibleFeedAvailable: Bool
    )
    case queueTask(AgentLivestockTaskRequest)
    case recordOutcome(AgentLivestockValidatedOutcome)
    case recordBreedingDecision(
        actionID: AgentLivestockActionID, herdID: AgentLivestockHerdID,
        actorID: AgentID, parentRecordIDs: [AgentManagedAnimalRecordID],
        compatibleFeedQuantity: Int, reservedPlantingQuantity: Int
    )
    case reconcile([AgentManagedAnimalResolution])

    public var operationIDText: String {
        switch self {
        case let .establishHerd(herdID, _, _, _): return "livestock-herd:\(herdID.rawValue)"
        case let .admitObservedAnimal(recordID, _, _, _, _, _, _, _): return "livestock-admit:\(recordID.rawValue)"
        case let .queueTask(task): return "livestock-task:\(task.taskID.rawValue)"
        case let .recordOutcome(outcome): return outcome.actionID.rawValue
        case let .recordBreedingDecision(actionID, _, _, _, _, _): return actionID.rawValue
        case let .reconcile(values): return "livestock-reconcile:" + values.map(\.recordID.rawValue).sorted().joined(separator: ",")
        }
    }
}

public enum AgentLivestockDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 { value ^= UInt64(byte); value &*= 1_099_511_628_211 }
        let digits = String(value, radix: 16)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
