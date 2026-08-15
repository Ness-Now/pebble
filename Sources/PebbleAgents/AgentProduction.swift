public enum AgentProductionError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration
    case causalLedgerRequired
    case disabled
    case unsafeDisable
    case unknownAgent(AgentID)
    case invalidNeed(String)
    case invalidOpportunity(String)
    case staleOpportunity(String)
    case invalidOutcome(String)
    case duplicateOperation(String)
    case capacityReached(String)
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidConfiguration: return "invalid production configuration"
        case .causalLedgerRequired: return "production requires causal ledger"
        case .disabled: return "production disabled"
        case .unsafeDisable: return "production disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown production agent \(id.rawValue)"
        case let .invalidNeed(id): return "invalid production need \(id)"
        case let .invalidOpportunity(id): return "invalid production opportunity \(id)"
        case let .staleOpportunity(id): return "stale production opportunity \(id)"
        case let .invalidOutcome(id): return "invalid production outcome \(id)"
        case let .duplicateOperation(id): return "duplicate production operation \(id)"
        case let .capacityReached(kind): return "production capacity reached \(kind)"
        case let .invalidState(reason): return "invalid production state \(reason)"
        }
    }
}

public struct AgentProductionNeedID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentProductionOpportunityID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({
                  $0.isASCII && ($0.isLetter || $0.isNumber || "-_:.".contains($0))
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentProductionNeedReason: String, Codable, CaseIterable, Sendable {
    case missingUsefulTool
    case physicalFoodNeed
    case materialWork
}

public enum AgentProductionNeedStatus: String, Codable, CaseIterable, Sendable {
    case active
    case fulfilled
    case cancelled
}

public struct AgentProductionConfiguration: Codable, Equatable, Sendable {
    public let maximumNeeds: Int
    public let maximumOpportunities: Int
    public let maximumRecords: Int
    public let maximumUseRecords: Int
    public let maximumProcessedOperations: Int
    public let opportunityLifetimeTicks: Int

    public init(
        maximumNeeds: Int = 64,
        maximumOpportunities: Int = 64,
        maximumRecords: Int = 256,
        maximumUseRecords: Int = 256,
        maximumProcessedOperations: Int = 512,
        opportunityLifetimeTicks: Int = 2
    ) throws {
        guard (1...512).contains(maximumNeeds),
              (1...512).contains(maximumOpportunities),
              (1...4096).contains(maximumRecords),
              (1...4096).contains(maximumUseRecords),
              (1...4096).contains(maximumProcessedOperations),
              (1...32).contains(opportunityLifetimeTicks) else {
            throw AgentProductionError.invalidConfiguration
        }
        self.maximumNeeds = maximumNeeds
        self.maximumOpportunities = maximumOpportunities
        self.maximumRecords = maximumRecords
        self.maximumUseRecords = maximumUseRecords
        self.maximumProcessedOperations = maximumProcessedOperations
        self.opportunityLifetimeTicks = opportunityLifetimeTicks
    }

    public static let live = try! AgentProductionConfiguration()
}

public struct AgentProductionNeed: Codable, Equatable, Sendable {
    public let needID: AgentProductionNeedID
    public let actorID: AgentID
    public let reason: AgentProductionNeedReason
    public let desiredOutputItemKey: String
    public let quantity: Int
    public let priority: Int
    public let createdAtTick: Int
    public internal(set) var status: AgentProductionNeedStatus
    public internal(set) var causalEventID: AgentCausalEventID
    public internal(set) var fulfilledByOperationID: String?

    public init(
        needID: AgentProductionNeedID,
        actorID: AgentID,
        reason: AgentProductionNeedReason,
        desiredOutputItemKey: String,
        quantity: Int = 1,
        priority: Int = 70,
        createdAtTick: Int,
        status: AgentProductionNeedStatus = .active,
        causalEventID: AgentCausalEventID,
        fulfilledByOperationID: String? = nil
    ) {
        self.needID = needID
        self.actorID = actorID
        self.reason = reason
        self.desiredOutputItemKey = String(desiredOutputItemKey.prefix(80))
        self.quantity = quantity
        self.priority = max(0, min(100, priority))
        self.createdAtTick = createdAtTick
        self.status = status
        self.causalEventID = causalEventID
        self.fulfilledByOperationID = fulfilledByOperationID
    }
}

/// Current, bounded physical opportunity supplied by Pebble. It contains only
/// observations and grants no authority to mutate a holder or workstation.
public struct AgentProductionOpportunityObservation: Codable, Equatable, Sendable {
    public let opportunityID: AgentProductionOpportunityID
    public let needID: AgentProductionNeedID
    public let actorID: AgentID
    public let recipeID: String
    public let workshopPosition: AgentPosition
    public let workshopBlockKey: String
    public let sourceLocationID: String
    public let sourceCustodyFingerprint: String
    public let planFingerprint: String
    public let inputs: [AgentMaterialStackSnapshot]
    public let output: AgentMaterialStackSnapshot
    public let observedAtTick: Int
    public let expiresAtTick: Int

    public init(
        opportunityID: AgentProductionOpportunityID,
        needID: AgentProductionNeedID,
        actorID: AgentID,
        recipeID: String,
        workshopPosition: AgentPosition,
        workshopBlockKey: String,
        sourceLocationID: String,
        sourceCustodyFingerprint: String,
        planFingerprint: String,
        inputs: [AgentMaterialStackSnapshot],
        output: AgentMaterialStackSnapshot,
        observedAtTick: Int,
        expiresAtTick: Int
    ) {
        self.opportunityID = opportunityID
        self.needID = needID
        self.actorID = actorID
        self.recipeID = String(recipeID.prefix(320))
        self.workshopPosition = workshopPosition
        self.workshopBlockKey = String(workshopBlockKey.prefix(80))
        self.sourceLocationID = String(sourceLocationID.prefix(256))
        self.sourceCustodyFingerprint = String(sourceCustodyFingerprint.prefix(16_384))
        self.planFingerprint = String(planFingerprint.prefix(80))
        self.inputs = inputs
        self.output = output
        self.observedAtTick = observedAtTick
        self.expiresAtTick = expiresAtTick
    }
}

public struct AgentProductionOpportunity: Codable, Equatable, Sendable {
    public let observation: AgentProductionOpportunityObservation
    public let causalEventID: AgentCausalEventID

    public init(
        observation: AgentProductionOpportunityObservation,
        causalEventID: AgentCausalEventID
    ) {
        self.observation = observation
        self.causalEventID = causalEventID
    }

    public var opportunityID: AgentProductionOpportunityID { observation.opportunityID }
    public var needID: AgentProductionNeedID { observation.needID }
    public var actorID: AgentID { observation.actorID }
    public var recipeID: String { observation.recipeID }
    public var workshopPosition: AgentPosition { observation.workshopPosition }
    public var workshopBlockKey: String { observation.workshopBlockKey }
    public var sourceLocationID: String { observation.sourceLocationID }
    public var sourceCustodyFingerprint: String {
        observation.sourceCustodyFingerprint
    }
    public var planFingerprint: String { observation.planFingerprint }
    public var inputs: [AgentMaterialStackSnapshot] { observation.inputs }
    public var output: AgentMaterialStackSnapshot { observation.output }
    public var observedAtTick: Int { observation.observedAtTick }
    public var expiresAtTick: Int { observation.expiresAtTick }
}

/// Verified physical result offered by Pebble before Civilization publication.
public struct AgentVerifiedProductionOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let opportunityID: AgentProductionOpportunityID
    public let actorID: AgentID
    public let recipeID: String
    public let workshopPosition: AgentPosition
    public let workshopBlockKey: String
    public let sourceLocationID: String
    public let sourceCustodyFingerprintBefore: String
    public let sourceCustodyFingerprintAfter: String
    public let planFingerprint: String
    public let inputsConsumed: [AgentMaterialStackSnapshot]
    public let outputProduced: AgentMaterialStackSnapshot
    public let physicalReceiptID: String
    public let completedAtTick: Int

    public init(
        operationID: String,
        opportunityID: AgentProductionOpportunityID,
        actorID: AgentID,
        recipeID: String,
        workshopPosition: AgentPosition,
        workshopBlockKey: String,
        sourceLocationID: String,
        sourceCustodyFingerprintBefore: String,
        sourceCustodyFingerprintAfter: String,
        planFingerprint: String,
        inputsConsumed: [AgentMaterialStackSnapshot],
        outputProduced: AgentMaterialStackSnapshot,
        physicalReceiptID: String,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.opportunityID = opportunityID
        self.actorID = actorID
        self.recipeID = recipeID
        self.workshopPosition = workshopPosition
        self.workshopBlockKey = workshopBlockKey
        self.sourceLocationID = sourceLocationID
        self.sourceCustodyFingerprintBefore = sourceCustodyFingerprintBefore
        self.sourceCustodyFingerprintAfter = sourceCustodyFingerprintAfter
        self.planFingerprint = planFingerprint
        self.inputsConsumed = inputsConsumed
        self.outputProduced = outputProduced
        self.physicalReceiptID = physicalReceiptID
        self.completedAtTick = completedAtTick
    }
}

public struct AgentProductionRecord: Codable, Equatable, Sendable {
    public let operationID: String
    public let needID: AgentProductionNeedID
    public let actorID: AgentID
    public let reason: AgentProductionNeedReason
    public let recipeID: String
    public let workshopPosition: AgentPosition
    public let workshopBlockKey: String
    public let sourceLocationID: String
    public let sourceCustodyFingerprintBefore: String?
    public let sourceCustodyFingerprintAfter: String?
    public let inputsConsumed: [AgentMaterialStackSnapshot]
    public let outputProduced: AgentMaterialStackSnapshot
    public let physicalReceiptID: String
    public let completedAtTick: Int
    public let causalEventID: AgentCausalEventID
}

public struct AgentProducedGoodUseOutcome: Codable, Equatable, Sendable {
    public let operationID: String
    public let productionOperationID: String
    public let actorID: AgentID
    public let physicalReceiptID: String
    public let identityBefore: AgentMaterialStackSnapshot
    public let identityAfter: AgentMaterialStackSnapshot
    public let physicalEffect: String
    public let completedAtTick: Int

    public init(
        operationID: String,
        productionOperationID: String,
        actorID: AgentID,
        physicalReceiptID: String,
        identityBefore: AgentMaterialStackSnapshot,
        identityAfter: AgentMaterialStackSnapshot,
        physicalEffect: String,
        completedAtTick: Int
    ) {
        self.operationID = operationID
        self.productionOperationID = productionOperationID
        self.actorID = actorID
        self.physicalReceiptID = physicalReceiptID
        self.identityBefore = identityBefore
        self.identityAfter = identityAfter
        self.physicalEffect = String(physicalEffect.prefix(160))
        self.completedAtTick = completedAtTick
    }
}

public struct AgentProducedGoodUseRecord: Codable, Equatable, Sendable {
    public let outcome: AgentProducedGoodUseOutcome
    public let causalEventID: AgentCausalEventID
}

public struct AgentProductionState: Codable, Equatable, Sendable {
    public let configuration: AgentProductionConfiguration
    public internal(set) var needs: [AgentProductionNeed]
    public internal(set) var opportunities: [AgentProductionOpportunity]
    public internal(set) var records: [AgentProductionRecord]
    public internal(set) var useRecords: [AgentProducedGoodUseRecord]
    public internal(set) var processedOperationIDs: [String]
    public internal(set) var totalProductionCount: Int
    public internal(set) var totalUseCount: Int
    public internal(set) var evictionCount: Int
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastProductionEventID: AgentCausalEventID
}

public struct AgentProductionSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentProductionConfiguration?
    public let needs: [AgentProductionNeed]
    public let opportunities: [AgentProductionOpportunity]
    public let records: [AgentProductionRecord]
    public let useRecords: [AgentProducedGoodUseRecord]
    public let totalProductionCount: Int
    public let totalUseCount: Int
    public let evictionCount: Int
}

public enum AgentProductionDigest {
    public static func make(_ text: String) -> String {
        AgentAutonomousActivityDigest.make(text)
    }
}
