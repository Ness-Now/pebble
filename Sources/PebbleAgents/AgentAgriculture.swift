import Foundation

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
        minimumCellsPerPlot: Int = 1,
        maximumReservations: Int = 16,
        reservationLifetimeTicks: Int = 4,
        maximumRetainedActions: Int = 128,
        maximumRetainedSurplusRecords: Int = 32,
        maximumProcessedActionIDs: Int = 4096
    ) throws {
        guard (1...32).contains(maximumPlots) else {
            throw AgentAgricultureError.invalidConfiguration("plots")
        }
        guard (1...16).contains(maximumCellsPerPlot),
              (1...maximumCellsPerPlot).contains(minimumCellsPerPlot) else {
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
    case carrots

    public var plantingItemKey: String {
        switch self {
        case .wheat: return "wheat_seeds"
        case .carrots: return "carrot"
        }
    }

    public var produceItemKey: String {
        switch self {
        case .wheat: return "wheat"
        case .carrots: return "carrot"
        }
    }
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

public struct AgentAgriculturalRenewalEvidence: Codable, Equatable, Sendable {
    public let sourceCycleOrdinal: Int
    public let sourcePlantActionIDs: [AgentAgriculturalActionID]
    public let sourceHarvestActionIDs: [AgentAgriculturalActionID]
    public let sourceOutputQuantity: Int
    public let reproductiveInputQuantity: Int
    public let reservedAtTick: Int
    public let sourceObservationReceiptID: AgentPhysicalObservationReceiptID?
    public let renewalEventID: AgentCausalEventID

    public init(
        sourceCycleOrdinal: Int,
        sourcePlantActionIDs: [AgentAgriculturalActionID],
        sourceHarvestActionIDs: [AgentAgriculturalActionID],
        sourceOutputQuantity: Int,
        reproductiveInputQuantity: Int,
        reservedAtTick: Int,
        sourceObservationReceiptID: AgentPhysicalObservationReceiptID? = nil,
        renewalEventID: AgentCausalEventID
    ) {
        self.sourceCycleOrdinal = sourceCycleOrdinal
        self.sourcePlantActionIDs = sourcePlantActionIDs.sorted()
        self.sourceHarvestActionIDs = sourceHarvestActionIDs.sorted()
        self.sourceOutputQuantity = sourceOutputQuantity
        self.reproductiveInputQuantity = reproductiveInputQuantity
        self.reservedAtTick = reservedAtTick
        self.sourceObservationReceiptID = sourceObservationReceiptID
        self.renewalEventID = renewalEventID
    }
}

public struct AgentAgriculturalPlot: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let plannerID: AgentID
    public let crop: AgentAgriculturalCrop
    public internal(set) var cells: [AgentAgriculturalCell]
    public let designatedStorageLocationID: String
    public let sourceObservationEventID: AgentCausalEventID
    public let sourceObservationReceiptID: AgentPhysicalObservationReceiptID?
    public let plannedCivilDate: AgentCivilDate
    public internal(set) var phase: AgentAgriculturalPlotPhase
    public internal(set) var plantedCivilDate: AgentCivilDate?
    public internal(set) var harvestedCivilDate: AgentCivilDate?
    public internal(set) var lastAgricultureEventID: AgentCausalEventID
    public internal(set) var cycleOrdinal: Int
    public internal(set) var renewalEvidence: AgentAgriculturalRenewalEvidence?

    init(
        plotID: AgentAgriculturalPlotID,
        plannerID: AgentID,
        crop: AgentAgriculturalCrop,
        cells: [AgentAgriculturalCell],
        designatedStorageLocationID: String,
        sourceObservationEventID: AgentCausalEventID,
        sourceObservationReceiptID: AgentPhysicalObservationReceiptID?,
        plannedCivilDate: AgentCivilDate,
        phase: AgentAgriculturalPlotPhase,
        plantedCivilDate: AgentCivilDate?,
        harvestedCivilDate: AgentCivilDate?,
        lastAgricultureEventID: AgentCausalEventID,
        cycleOrdinal: Int = 1,
        renewalEvidence: AgentAgriculturalRenewalEvidence? = nil
    ) {
        self.plotID = plotID
        self.plannerID = plannerID
        self.crop = crop
        self.cells = cells
        self.designatedStorageLocationID = designatedStorageLocationID
        self.sourceObservationEventID = sourceObservationEventID
        self.sourceObservationReceiptID = sourceObservationReceiptID
        self.plannedCivilDate = plannedCivilDate
        self.phase = phase
        self.plantedCivilDate = plantedCivilDate
        self.harvestedCivilDate = harvestedCivilDate
        self.lastAgricultureEventID = lastAgricultureEventID
        self.cycleOrdinal = cycleOrdinal
        self.renewalEvidence = renewalEvidence
    }

    private enum CodingKeys: String, CodingKey {
        case plotID, plannerID, crop, cells, designatedStorageLocationID
        case sourceObservationEventID, sourceObservationReceiptID
        case plannedCivilDate, phase
        case plantedCivilDate, harvestedCivilDate, lastAgricultureEventID
        case cycleOrdinal, renewalEvidence
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        plotID = try values.decode(AgentAgriculturalPlotID.self, forKey: .plotID)
        plannerID = try values.decode(AgentID.self, forKey: .plannerID)
        crop = try values.decode(AgentAgriculturalCrop.self, forKey: .crop)
        cells = try values.decode([AgentAgriculturalCell].self, forKey: .cells)
        designatedStorageLocationID = try values.decode(
            String.self, forKey: .designatedStorageLocationID
        )
        sourceObservationEventID = try values.decode(
            AgentCausalEventID.self, forKey: .sourceObservationEventID
        )
        sourceObservationReceiptID = try values.decodeIfPresent(
            AgentPhysicalObservationReceiptID.self,
            forKey: .sourceObservationReceiptID
        )
        plannedCivilDate = try values.decode(AgentCivilDate.self, forKey: .plannedCivilDate)
        phase = try values.decode(AgentAgriculturalPlotPhase.self, forKey: .phase)
        plantedCivilDate = try values.decodeIfPresent(
            AgentCivilDate.self, forKey: .plantedCivilDate
        )
        harvestedCivilDate = try values.decodeIfPresent(
            AgentCivilDate.self, forKey: .harvestedCivilDate
        )
        lastAgricultureEventID = try values.decode(
            AgentCausalEventID.self, forKey: .lastAgricultureEventID
        )
        cycleOrdinal = try values.decodeIfPresent(Int.self, forKey: .cycleOrdinal) ?? 1
        renewalEvidence = try values.decodeIfPresent(
            AgentAgriculturalRenewalEvidence.self, forKey: .renewalEvidence
        )
    }
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

/// Read-only projection of Pebble's independent World-side agriculture
/// receipt. The receipt bytes themselves remain in World persistence and are
/// not serialized into the Civilization checkpoint.
public struct AgentAgriculturalPhysicalReceiptEvidence: Codable, Equatable,
    Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let receiptID: AgentAgriculturalActionID
    public let operationID: String
    public let worldID: String
    public let storageIdentity: String
    public let dimension: Int
    public let simulationID: AgentSimulationID
    public let outcome: AgentAgriculturalActionOutcome
    public let receiptDigest: AgentCheckpointDigest

    public init(
        version: Int = currentVersion,
        receiptID: AgentAgriculturalActionID,
        operationID: String,
        worldID: String,
        storageIdentity: String,
        dimension: Int,
        simulationID: AgentSimulationID,
        outcome: AgentAgriculturalActionOutcome,
        receiptDigest: AgentCheckpointDigest? = nil
    ) {
        self.version = version
        self.receiptID = receiptID
        self.operationID = operationID
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.dimension = dimension
        self.simulationID = simulationID
        self.outcome = outcome
        self.receiptDigest = receiptDigest ?? Self.makeDigest(
            version: version,
            receiptID: receiptID,
            operationID: operationID,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID,
            outcome: outcome
        )
    }

    public var hasValidDigest: Bool {
        receiptDigest == Self.makeDigest(
            version: version,
            receiptID: receiptID,
            operationID: operationID,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID,
            outcome: outcome
        )
    }

    private static func makeDigest(
        version: Int,
        receiptID: AgentAgriculturalActionID,
        operationID: String,
        worldID: String,
        storageIdentity: String,
        dimension: Int,
        simulationID: AgentSimulationID,
        outcome: AgentAgriculturalActionOutcome
    ) -> AgentCheckpointDigest {
        let outcomeBytes = try! AgentCheckpointCodec.encode(outcome)
        let canonical = [
            "pebble-agriculture-physical-receipt-v1",
            String(version), receiptID.rawValue, operationID, worldID,
            storageIdentity, String(dimension), simulationID.rawValue,
            AgentCheckpointDigest.sha256(outcomeBytes).rawValue,
        ].joined(separator: "|")
        return AgentCheckpointDigest.sha256(Data(canonical.utf8))
    }
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
    public internal(set) var initializedEventID: AgentCausalEventID
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

public enum AgentRenewableSubsistenceStatus: String, Codable, Equatable, Sendable {
    case blocked
    case secondCycleEstablished
    case renewableCycleCompleted
}

/// Read-only milestone evidence derived from retained physical receipts. It
/// owns no material, crop stage, need, or success transition of its own.
public struct AgentRenewableSubsistenceEvidence: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let crop: AgentAgriculturalCrop
    public let cycleOrdinal: Int
    public let firstPlantActionIDs: [AgentAgriculturalActionID]
    public let firstHarvestActionIDs: [AgentAgriculturalActionID]
    public let firstOutputQuantity: Int
    public let consumptionID: String?
    public let consumedQuantity: Int
    public let hungerBefore: Double?
    public let hungerAfter: Double?
    public let reservedOutputQuantity: Int
    public let secondPlantActionIDs: [AgentAgriculturalActionID]
    public let secondInputQuantity: Int
    public let secondHarvestActionIDs: [AgentAgriculturalActionID]
    public let secondOutputQuantity: Int
    public let status: AgentRenewableSubsistenceStatus
    public let blockReason: String?
    public let digest: String

    public init(
        plotID: AgentAgriculturalPlotID,
        crop: AgentAgriculturalCrop,
        cycleOrdinal: Int,
        firstPlantActionIDs: [AgentAgriculturalActionID],
        firstHarvestActionIDs: [AgentAgriculturalActionID],
        firstOutputQuantity: Int,
        consumptionID: String?,
        consumedQuantity: Int,
        hungerBefore: Double?,
        hungerAfter: Double?,
        reservedOutputQuantity: Int,
        secondPlantActionIDs: [AgentAgriculturalActionID],
        secondInputQuantity: Int,
        secondHarvestActionIDs: [AgentAgriculturalActionID],
        secondOutputQuantity: Int,
        status: AgentRenewableSubsistenceStatus,
        blockReason: String?,
        digest: String
    ) {
        self.plotID = plotID
        self.crop = crop
        self.cycleOrdinal = cycleOrdinal
        self.firstPlantActionIDs = firstPlantActionIDs.sorted()
        self.firstHarvestActionIDs = firstHarvestActionIDs.sorted()
        self.firstOutputQuantity = firstOutputQuantity
        self.consumptionID = consumptionID
        self.consumedQuantity = consumedQuantity
        self.hungerBefore = hungerBefore
        self.hungerAfter = hungerAfter
        self.reservedOutputQuantity = reservedOutputQuantity
        self.secondPlantActionIDs = secondPlantActionIDs.sorted()
        self.secondInputQuantity = secondInputQuantity
        self.secondHarvestActionIDs = secondHarvestActionIDs.sorted()
        self.secondOutputQuantity = secondOutputQuantity
        self.status = status
        self.blockReason = blockReason
        self.digest = digest
    }
}

public struct AgentAgriculturalIntent: Codable, Equatable, Sendable {
    public let plotID: AgentAgriculturalPlotID
    public let cellIndex: Int?
    public let actorID: AgentID
    public let kind: AgentAgriculturalActionKind
    public let position: AgentPosition
    public let crop: AgentAgriculturalCrop

    public init(
        plotID: AgentAgriculturalPlotID,
        cellIndex: Int?,
        actorID: AgentID,
        kind: AgentAgriculturalActionKind,
        position: AgentPosition,
        crop: AgentAgriculturalCrop = .wheat
    ) {
        self.plotID = plotID
        self.cellIndex = cellIndex
        self.actorID = actorID
        self.kind = kind
        self.position = position
        self.crop = crop
    }

    private enum CodingKeys: String, CodingKey {
        case plotID, cellIndex, actorID, kind, position, crop
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        plotID = try values.decode(AgentAgriculturalPlotID.self, forKey: .plotID)
        cellIndex = try values.decodeIfPresent(Int.self, forKey: .cellIndex)
        actorID = try values.decode(AgentID.self, forKey: .actorID)
        kind = try values.decode(AgentAgriculturalActionKind.self, forKey: .kind)
        position = try values.decode(AgentPosition.self, forKey: .position)
        crop = try values.decodeIfPresent(
            AgentAgriculturalCrop.self, forKey: .crop
        ) ?? .wheat
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
