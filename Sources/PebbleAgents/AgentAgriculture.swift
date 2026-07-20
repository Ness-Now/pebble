public enum AgentAgricultureError: Error, Equatable, CustomStringConvertible {
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
    case invalidPlot(String)
    case plotCapacityReached
    case unknownPlot(AgentAgriculturalPlotID)
    case invalidCell(Int)
    case invalidReservation(String)
    case reservationCapacityReached
    case invalidAction(String)
    case duplicateAction(AgentAgriculturalActionID)
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid agriculture configuration: \(reason)"
        case .causalLedgerRequired: return "agriculture requires the causal ledger"
        case .populationRequired: return "agriculture requires population"
        case .lifecycleRequired: return "agriculture requires lifecycle"
        case .skillsRequired: return "agriculture requires skills"
        case .ecologicalObservationRequired: return "agriculture requires ecological observation"
        case .alreadyEnabled: return "agriculture already enabled"
        case .disabled: return "agriculture disabled"
        case .unsafeDisable: return "agriculture disable refused while durable state exists"
        case let .unknownAgent(id): return "unknown agricultural agent \(id.rawValue)"
        case let .invalidPlot(reason): return "invalid agricultural plot: \(reason)"
        case .plotCapacityReached: return "agricultural plot capacity reached"
        case let .unknownPlot(id): return "unknown agricultural plot \(id.rawValue)"
        case let .invalidCell(index): return "invalid agricultural cell \(index)"
        case let .invalidReservation(reason): return "invalid agricultural reservation: \(reason)"
        case .reservationCapacityReached: return "agricultural reservation capacity reached"
        case let .invalidAction(reason): return "invalid agricultural action: \(reason)"
        case let .duplicateAction(id): return "duplicate agricultural action \(id.rawValue)"
        case let .invalidCausalReference(id): return "invalid agricultural causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid agriculture state: \(reason)"
        }
    }
}

public struct AgentAgricultureConfiguration: Codable, Equatable, Sendable {
    public let maximumPlots: Int
    public let maximumCellsPerPlot: Int
    public let minimumCellsPerPlot: Int
    public let maximumReservations: Int
    public let reservationLifetimeTicks: Int
    public let maximumRetainedActions: Int
    public let maximumRetainedSurplusRecords: Int
    public let maximumProcessedActionIDs: Int

    public init(
        maximumPlots: Int = 4,
        maximumCellsPerPlot: Int = 4,
        minimumCellsPerPlot: Int = 2,
        maximumReservations: Int = 16,
        reservationLifetimeTicks: Int = 4,
        maximumRetainedActions: Int = 128,
        maximumRetainedSurplusRecords: Int = 32,
        maximumProcessedActionIDs: Int = 4096
    ) throws {
        guard (1...32).contains(maximumPlots) else {
            throw AgentAgricultureError.invalidConfiguration("plots")
        }
        guard (2...16).contains(maximumCellsPerPlot),
              (2...maximumCellsPerPlot).contains(minimumCellsPerPlot) else {
            throw AgentAgricultureError.invalidConfiguration("cells per plot")
        }
        guard (1...256).contains(maximumReservations) else {
            throw AgentAgricultureError.invalidConfiguration("reservations")
        }
        guard (1...64).contains(reservationLifetimeTicks) else {
            throw AgentAgricultureError.invalidConfiguration("reservation lifetime")
        }
        guard (1...2048).contains(maximumRetainedActions) else {
            throw AgentAgricultureError.invalidConfiguration("retained actions")
        }
        guard (1...512).contains(maximumRetainedSurplusRecords) else {
            throw AgentAgricultureError.invalidConfiguration("surplus records")
        }
        guard (1...16_384).contains(maximumProcessedActionIDs),
              maximumProcessedActionIDs >= maximumRetainedActions else {
            throw AgentAgricultureError.invalidConfiguration("processed action IDs")
        }
        self.maximumPlots = maximumPlots
        self.maximumCellsPerPlot = maximumCellsPerPlot
        self.minimumCellsPerPlot = minimumCellsPerPlot
        self.maximumReservations = maximumReservations
        self.reservationLifetimeTicks = reservationLifetimeTicks
        self.maximumRetainedActions = maximumRetainedActions
        self.maximumRetainedSurplusRecords = maximumRetainedSurplusRecords
        self.maximumProcessedActionIDs = maximumProcessedActionIDs
    }

    public static let live = try! AgentAgricultureConfiguration()
}

public struct AgentAgriculturalPlotID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentAgriculturalActionID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...160).contains(rawValue.count),
              rawValue.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "-_.:".contains($0)) }) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentAgriculturalCrop: String, Codable, CaseIterable, Sendable {
    case wheat

    public var plantingItemKey: String { "wheat_seeds" }
    public var produceItemKey: String { "wheat" }
}

public enum AgentAgriculturalPlotPhase: String, Codable, CaseIterable, Sendable {
    case planned
    case preparing
    case planting
    case growing
    case harvestReady
    case harvesting
    case storing
    case cycleCompleted
    case blocked
    case cancelled
}

public enum AgentAgriculturalCellPhase: String, Codable, CaseIterable, Sendable {
    case planned
    case prepared
    case planted
    case mature
    case harvested
    case blocked
}

public enum AgentAgriculturalActionKind: String, Codable, CaseIterable, Sendable {
    case till
    case plant
    case maturityObserved
    case harvest
    case store
    case reconcile
}

public enum AgentAgriculturalMaterialDirection: String, Codable, CaseIterable, Sendable {
    case consumed
    case acquired
    case stored
}

public struct AgentAgriculturalMaterialDelta: Codable, Equatable, Sendable {
    public let itemKey: String
    public let quantity: Int
    public let direction: AgentAgriculturalMaterialDirection

    public init(itemKey: String, quantity: Int, direction: AgentAgriculturalMaterialDirection) {
        self.itemKey = itemKey
        self.quantity = quantity
        self.direction = direction
    }
}

public struct AgentAgriculturalCell: Codable, Equatable, Sendable {
    public let index: Int
    public let position: AgentPosition
    public internal(set) var phase: AgentAgriculturalCellPhase
    public internal(set) var lastObservedFingerprint: Int
    public internal(set) var lastWorkEventID: AgentCausalEventID?
}

public struct AgentAgriculturalPlot: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let plannerID: AgentID
    public let crop: AgentAgriculturalCrop
    public internal(set) var cells: [AgentAgriculturalCell]
    public let designatedStorageLocationID: String
    public let sourceObservationEventID: AgentCausalEventID
    public let plannedCivilDate: AgentCivilDate
    public internal(set) var phase: AgentAgriculturalPlotPhase
    public internal(set) var plantedCivilDate: AgentCivilDate?
    public internal(set) var harvestedCivilDate: AgentCivilDate?
    public internal(set) var lastAgricultureEventID: AgentCausalEventID
}

public struct AgentAgriculturalWorkReservation: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let cellIndex: Int
    public let agentID: AgentID
    public let reservedAtTick: Int
    public let expiresAtTick: Int
}

/// A verified outcome crossing the Pebble physical boundary. It describes
/// evidence and history only; it is not an inventory or a crop simulation.
public struct AgentAgriculturalActionOutcome: Codable, Equatable, Sendable {
    public let actionID: AgentAgriculturalActionID
    public let kind: AgentAgriculturalActionKind
    public let actorID: AgentID
    public let plotID: AgentAgriculturalPlotID
    public let cellIndex: Int?
    public let position: AgentPosition
    public let beforeFingerprint: Int
    public let afterFingerprint: Int
    public let materialDeltas: [AgentAgriculturalMaterialDelta]
    public let sourceItemEntityIDs: [Int]
    public let custodyFingerprint: String?
    public let storageLocationID: String?
    public let seedReserveQuantity: Int
    public let physicalSurplusQuantity: Int
    public let sourceObservationEventID: AgentCausalEventID?
    public let civilDate: AgentCivilDate

    public init(
        actionID: AgentAgriculturalActionID,
        kind: AgentAgriculturalActionKind,
        actorID: AgentID,
        plotID: AgentAgriculturalPlotID,
        cellIndex: Int?,
        position: AgentPosition,
        beforeFingerprint: Int,
        afterFingerprint: Int,
        materialDeltas: [AgentAgriculturalMaterialDelta] = [],
        sourceItemEntityIDs: [Int] = [],
        custodyFingerprint: String? = nil,
        storageLocationID: String? = nil,
        seedReserveQuantity: Int = 0,
        physicalSurplusQuantity: Int = 0,
        sourceObservationEventID: AgentCausalEventID? = nil,
        civilDate: AgentCivilDate
    ) {
        self.actionID = actionID
        self.kind = kind
        self.actorID = actorID
        self.plotID = plotID
        self.cellIndex = cellIndex
        self.position = position
        self.beforeFingerprint = beforeFingerprint
        self.afterFingerprint = afterFingerprint
        self.materialDeltas = materialDeltas
        self.sourceItemEntityIDs = sourceItemEntityIDs
        self.custodyFingerprint = custodyFingerprint
        self.storageLocationID = storageLocationID
        self.seedReserveQuantity = seedReserveQuantity
        self.physicalSurplusQuantity = physicalSurplusQuantity
        self.sourceObservationEventID = sourceObservationEventID
        self.civilDate = civilDate
    }
}

public struct AgentAgriculturalActionRecord: Codable, Equatable, Sendable {
    public let outcome: AgentAgriculturalActionOutcome
    public let agricultureEventID: AgentCausalEventID
    public let skillPracticeEventID: AgentCausalEventID?
    public let digest: String
}

/// Historical, non-spendable evidence derived from a real designated
/// container. Live queries must inspect that container again.
public struct AgentManagedSurplusRecord: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let storageLocationID: String
    public let cropItemKey: String
    public let plantingItemKey: String
    public let seedReserveTarget: Int
    public let seedReserveQuantity: Int
    public let physicalSurplusQuantity: Int
    public let custodyFingerprint: String
    public let recordedTick: Int
    public let agricultureEventID: AgentCausalEventID
}

public struct AgentAgricultureEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var actionRecords: Int
    public internal(set) var surplusRecords: Int

    public init(actionRecords: Int = 0, surplusRecords: Int = 0) {
        self.actionRecords = actionRecords
        self.surplusRecords = surplusRecords
    }
}

public struct AgentAgricultureState: Codable, Equatable, Sendable {
    public let configuration: AgentAgricultureConfiguration
    public internal(set) var plots: [AgentAgriculturalPlot]
    public internal(set) var reservations: [AgentAgriculturalWorkReservation]
    public internal(set) var retainedActions: [AgentAgriculturalActionRecord]
    public internal(set) var managedSurplusRecords: [AgentManagedSurplusRecord]
    public internal(set) var processedActionIDs: [AgentAgriculturalActionID]
    public internal(set) var totalActionCount: Int
    public internal(set) var completedCycleCount: Int
    public internal(set) var evictionCounts: AgentAgricultureEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastAgricultureEventID: AgentCausalEventID
}

public struct AgentAgricultureSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentAgricultureConfiguration?
    public let plots: [AgentAgriculturalPlot]
    public let reservations: [AgentAgriculturalWorkReservation]
    public let retainedActions: [AgentAgriculturalActionRecord]
    public let managedSurplusRecords: [AgentManagedSurplusRecord]
    public let totalActionCount: Int
    public let completedCycleCount: Int
    public let evictionCounts: AgentAgricultureEvictionCounts
    public let digest: String
}

public struct AgentAgriculturalIntent: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let cellIndex: Int?
    public let actorID: AgentID
    public let kind: AgentAgriculturalActionKind
    public let position: AgentPosition

    public init(
        plotID: AgentAgriculturalPlotID,
        cellIndex: Int?,
        actorID: AgentID,
        kind: AgentAgriculturalActionKind,
        position: AgentPosition
    ) {
        self.plotID = plotID
        self.cellIndex = cellIndex
        self.actorID = actorID
        self.kind = kind
        self.position = position
    }
}

public enum AgentAgricultureDigest {
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
