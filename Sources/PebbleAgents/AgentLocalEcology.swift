public enum AgentLocalEcologyError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case settlementMismatch
    case alreadyEnabled
    case disabled
    case noValidHabitat
    case tooManyHabitatObservations(Int)
    case duplicateHabitat
    case invalidHabitat(String)
    case unknownPatch(String)
    case invalidForage(String)
    case forageLimitReached
    case invalidPressureFrame
    case ecologyConservationFailed

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid local ecology configuration: \(reason)"
        case .causalLedgerRequired: return "local ecology requires the causal ledger"
        case .populationRequired: return "local ecology requires the population registry"
        case .settlementMismatch: return "local ecology settlement mismatch"
        case .alreadyEnabled: return "local ecology already enabled"
        case .disabled: return "local ecology disabled"
        case .noValidHabitat: return "no valid local ecology habitat"
        case let .tooManyHabitatObservations(count): return "too many habitat observations: \(count)"
        case .duplicateHabitat: return "duplicate local ecology habitat"
        case let .invalidHabitat(reason): return "invalid local ecology habitat: \(reason)"
        case let .unknownPatch(id): return "unknown local ecology patch: \(id)"
        case let .invalidForage(id): return "invalid local ecology forage: \(id)"
        case .forageLimitReached: return "local ecology forage history limit reached"
        case .invalidPressureFrame: return "invalid subsistence pressure frame"
        case .ecologyConservationFailed: return "local ecology conservation failed"
        }
    }
}

public struct AgentLocalEcologyConfiguration: Codable, Equatable, Sendable {
    public let maximumPatches: Int
    public let maximumHabitatCandidates: Int
    public let observationRadius: Int
    public let patchCapacity: Int
    public let initialYield: Int
    public let regenerationIntervalTicks: Int
    public let regenerationQuantity: Int
    public let maximumForageIntentsPerTick: Int
    public let maximumForageHistory: Int
    public let maximumPressureFrames: Int
    public let maximumHabitatReadsPerScan: Int

    public init(
        maximumPatches: Int = 4,
        maximumHabitatCandidates: Int = 16,
        observationRadius: Int = 8,
        patchCapacity: Int = 1,
        initialYield: Int = 1,
        regenerationIntervalTicks: Int = 8,
        regenerationQuantity: Int = 1,
        maximumForageIntentsPerTick: Int = 8,
        maximumForageHistory: Int = 64,
        maximumPressureFrames: Int = 32,
        maximumHabitatReadsPerScan: Int = 256
    ) throws {
        guard (1...8).contains(maximumPatches) else {
            throw AgentLocalEcologyError.invalidConfiguration("patches")
        }
        guard (1...32).contains(maximumHabitatCandidates) else {
            throw AgentLocalEcologyError.invalidConfiguration("habitat candidates")
        }
        guard (1...8).contains(observationRadius) else {
            throw AgentLocalEcologyError.invalidConfiguration("observation radius")
        }
        guard (1...4).contains(patchCapacity) else {
            throw AgentLocalEcologyError.invalidConfiguration("patch capacity")
        }
        guard (0...patchCapacity).contains(initialYield) else {
            throw AgentLocalEcologyError.invalidConfiguration("initial yield")
        }
        guard (2...64).contains(regenerationIntervalTicks) else {
            throw AgentLocalEcologyError.invalidConfiguration("regeneration interval")
        }
        guard (1...patchCapacity).contains(regenerationQuantity) else {
            throw AgentLocalEcologyError.invalidConfiguration("regeneration quantity")
        }
        guard (1...8).contains(maximumForageIntentsPerTick) else {
            throw AgentLocalEcologyError.invalidConfiguration("forage intents")
        }
        guard (1...128).contains(maximumForageHistory) else {
            throw AgentLocalEcologyError.invalidConfiguration("forage history")
        }
        guard (1...64).contains(maximumPressureFrames) else {
            throw AgentLocalEcologyError.invalidConfiguration("pressure frames")
        }
        guard (1...256).contains(maximumHabitatReadsPerScan) else {
            throw AgentLocalEcologyError.invalidConfiguration("World reads")
        }
        self.maximumPatches = maximumPatches
        self.maximumHabitatCandidates = maximumHabitatCandidates
        self.observationRadius = observationRadius
        self.patchCapacity = patchCapacity
        self.initialYield = initialYield
        self.regenerationIntervalTicks = regenerationIntervalTicks
        self.regenerationQuantity = regenerationQuantity
        self.maximumForageIntentsPerTick = maximumForageIntentsPerTick
        self.maximumForageHistory = maximumForageHistory
        self.maximumPressureFrames = maximumPressureFrames
        self.maximumHabitatReadsPerScan = maximumHabitatReadsPerScan
    }

    public static let live = try! AgentLocalEcologyConfiguration()
}

public struct AgentEcologyPatchID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.hasPrefix("patch-"), rawValue.utf8.count == 22,
              rawValue.dropFirst(6).allSatisfy({ $0.isHexDigit }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    public static func make(
        settlementID: AgentSettlementID,
        habitatPosition: AgentPosition,
        foragePosition: AgentPosition,
        habitatFingerprint: Int
    ) -> Self {
        let text = "\(settlementID.rawValue)|\(habitatPosition.x),\(habitatPosition.y),\(habitatPosition.z)|"
            + "\(foragePosition.x),\(foragePosition.y),\(foragePosition.z)|\(habitatFingerprint)"
        return AgentEcologyPatchID(rawValue: "patch-\(AgentLocalEcologyDigest.make(text))")!
    }
}

public enum AgentEcologyPatchStatus: String, Codable, CaseIterable, Sendable {
    case available
    case depleted
    case invalidated
}

public struct AgentEcologyHabitatObservation: Codable, Equatable, Sendable {
    public let worldTick: Int
    public let candidateIndex: Int
    public let settlementID: AgentSettlementID
    public let habitatPosition: AgentPosition
    public let foragePosition: AgentPosition
    public let habitatFingerprint: Int
    public let distanceFromSettlement: Int
    public let directionIndex: Int
    public let habitatChunkReady: Bool
    public let forageChunkReady: Bool
    public let habitatValid: Bool
    public let forageAccessible: Bool
    public let worldReadCount: Int

    public init(
        worldTick: Int,
        candidateIndex: Int,
        settlementID: AgentSettlementID = .main,
        habitatPosition: AgentPosition,
        foragePosition: AgentPosition,
        habitatFingerprint: Int,
        distanceFromSettlement: Int,
        directionIndex: Int,
        habitatChunkReady: Bool = true,
        forageChunkReady: Bool = true,
        habitatValid: Bool = true,
        forageAccessible: Bool = true,
        worldReadCount: Int = 1
    ) {
        self.worldTick = worldTick
        self.candidateIndex = candidateIndex
        self.settlementID = settlementID
        self.habitatPosition = habitatPosition
        self.foragePosition = foragePosition
        self.habitatFingerprint = habitatFingerprint
        self.distanceFromSettlement = distanceFromSettlement
        self.directionIndex = directionIndex
        self.habitatChunkReady = habitatChunkReady
        self.forageChunkReady = forageChunkReady
        self.habitatValid = habitatValid
        self.forageAccessible = forageAccessible
        self.worldReadCount = worldReadCount
    }

    public var patchID: AgentEcologyPatchID {
        .make(
            settlementID: settlementID,
            habitatPosition: habitatPosition,
            foragePosition: foragePosition,
            habitatFingerprint: habitatFingerprint
        )
    }

    public var isUsable: Bool {
        habitatChunkReady && forageChunkReady && habitatValid && forageAccessible
    }

    public static func sortsBefore(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.distanceFromSettlement != rhs.distanceFromSettlement {
            return lhs.distanceFromSettlement < rhs.distanceFromSettlement
        }
        if lhs.directionIndex != rhs.directionIndex { return lhs.directionIndex < rhs.directionIndex }
        if lhs.habitatPosition.x != rhs.habitatPosition.x {
            return lhs.habitatPosition.x < rhs.habitatPosition.x
        }
        if lhs.habitatPosition.z != rhs.habitatPosition.z {
            return lhs.habitatPosition.z < rhs.habitatPosition.z
        }
        if lhs.habitatPosition.y != rhs.habitatPosition.y {
            return lhs.habitatPosition.y < rhs.habitatPosition.y
        }
        if lhs.habitatFingerprint != rhs.habitatFingerprint {
            return lhs.habitatFingerprint < rhs.habitatFingerprint
        }
        return lhs.candidateIndex < rhs.candidateIndex
    }
}

public struct AgentEcologyPatch: Codable, Equatable, Sendable {
    public let patchID: AgentEcologyPatchID
    public let settlementID: AgentSettlementID
    public let habitatPosition: AgentPosition
    public let foragePosition: AgentPosition
    public let habitatFingerprint: Int
    public let capacity: Int
    public internal(set) var currentYield: Int
    public let initialYield: Int
    public internal(set) var regeneratedTotal: Int
    public internal(set) var harvestedTotal: Int
    public internal(set) var status: AgentEcologyPatchStatus
    public let registeredTick: Int
    public internal(set) var lastRegenerationTick: Int
    public internal(set) var lastForageTick: Int?
    public let registrationEventID: AgentCausalEventID
    public internal(set) var lastEcologyEventID: AgentCausalEventID

    public var regenerating: Bool { status != .invalidated && currentYield < capacity }
}

public enum AgentForageStatus: String, Codable, CaseIterable, Sendable {
    case succeeded
    case depleted
    case staleObservation
    case notAdjacent
    case inventoryFull
    case habitatInvalid
    case blocked
}

public struct AgentForageIntent: Codable, Equatable, Sendable {
    public let forageID: String
    public let patchID: AgentEcologyPatchID
    public let agentID: AgentID
    public let tick: Int
    public let target: AgentPosition
    public let observedAtTick: Int
    public let expectedHabitatFingerprint: Int

    public init(
        forageID: String,
        patchID: AgentEcologyPatchID,
        agentID: AgentID,
        tick: Int,
        target: AgentPosition,
        observedAtTick: Int,
        expectedHabitatFingerprint: Int
    ) {
        self.forageID = forageID
        self.patchID = patchID
        self.agentID = agentID
        self.tick = tick
        self.target = target
        self.observedAtTick = observedAtTick
        self.expectedHabitatFingerprint = expectedHabitatFingerprint
    }
}

public struct AgentForageOutcome: Codable, Equatable, Sendable {
    public let forageID: String
    public let patchID: AgentEcologyPatchID
    public let agentID: AgentID
    public let tick: Int
    public let status: AgentForageStatus
    public let yieldBefore: Int
    public let yieldAfter: Int
    public let inventoryBefore: Int
    public let inventoryAfter: Int
    public let reason: String
}

public enum AgentSubsistencePressureLevel: String, Codable, CaseIterable, Sendable {
    case abundant
    case adequate
    case scarce
    case critical
    case recovering
}

public struct AgentSubsistencePressureInput: Codable, Equatable, Sendable {
    public let population: Int
    public let hungry: Int
    public let critical: Int
    public let starvationDamageDelta: Int
    public let availableYield: Int
    public let carriedFood: Int
    public let stockedFood: Int
    public let regeneratedDelta: Int
    public let consumedDelta: Int

    public init(
        population: Int,
        hungry: Int,
        critical: Int,
        starvationDamageDelta: Int,
        availableYield: Int,
        carriedFood: Int,
        stockedFood: Int,
        regeneratedDelta: Int,
        consumedDelta: Int
    ) {
        self.population = population
        self.hungry = hungry
        self.critical = critical
        self.starvationDamageDelta = starvationDamageDelta
        self.availableYield = availableYield
        self.carriedFood = carriedFood
        self.stockedFood = stockedFood
        self.regeneratedDelta = regeneratedDelta
        self.consumedDelta = consumedDelta
    }

    public var accessibleFood: Int { availableYield + carriedFood + stockedFood }
}

public enum AgentSubsistencePressureClassifier {
    public static func classify(
        _ input: AgentSubsistencePressureInput,
        previous: AgentSubsistencePressureLevel?
    ) -> AgentSubsistencePressureLevel {
        if input.starvationDamageDelta > 0 || (input.critical > 0 && input.accessibleFood == 0) {
            return .critical
        }
        if input.hungry > input.accessibleFood { return .scarce }
        if let previous, previous == .scarce || previous == .critical,
           input.regeneratedDelta > 0 || input.consumedDelta > 0 {
            return .recovering
        }
        if input.hungry > 0 || input.accessibleFood == 0 { return .adequate }
        return .abundant
    }
}

public struct AgentSubsistencePressureFrame: Codable, Equatable, Sendable {
    public let sequence: UInt64
    public let tick: Int
    public let previousLevel: AgentSubsistencePressureLevel?
    public let level: AgentSubsistencePressureLevel
    public let input: AgentSubsistencePressureInput
    public let causalEventID: AgentCausalEventID
}

public struct AgentEcologyEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var forageHistory: Int
    public internal(set) var pressureFrames: Int

    public init(forageHistory: Int = 0, pressureFrames: Int = 0) {
        self.forageHistory = max(0, forageHistory)
        self.pressureFrames = max(0, pressureFrames)
    }
}

public struct AgentLocalEcologyState: Codable, Equatable, Sendable {
    public let configuration: AgentLocalEcologyConfiguration
    public let settlementID: AgentSettlementID
    public internal(set) var patches: [AgentEcologyPatch]
    public internal(set) var processedForageIDs: [String]
    public internal(set) var forageHistory: [AgentForageOutcome]
    public internal(set) var pressureFrames: [AgentSubsistencePressureFrame]
    public internal(set) var pressureSequence: UInt64
    public internal(set) var baselineRegenerated: Int
    public internal(set) var baselineConsumed: Int
    public internal(set) var baselineStarvationDamage: Int
    public internal(set) var evictionCounts: AgentEcologyEvictionCounts
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastEcologyEventID: AgentCausalEventID

    public var currentPressure: AgentSubsistencePressureLevel? { pressureFrames.last?.level }
}

public struct AgentEcologyConservationSnapshot: Codable, Equatable, Sendable {
    public let initialYieldTotal: Int
    public let regeneratedTotal: Int
    public let currentPatchYieldTotal: Int
    public let harvestedFromEcologyTotal: Int
    public let balanced: Bool
}

public struct AgentLocalEcologySnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let settlementID: AgentSettlementID?
    public let configuration: AgentLocalEcologyConfiguration?
    public let patches: [AgentEcologyPatch]
    public let forageHistory: [AgentForageOutcome]
    public let pressureFrames: [AgentSubsistencePressureFrame]
    public let conservation: AgentEcologyConservationSnapshot
    public let ecologyCausalEventCount: Int
    public let evictionCounts: AgentEcologyEvictionCounts
    public let digest: String
}

public struct AgentLocalEcologySummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let patchCount: Int
    public let availablePatchCount: Int
    public let depletedPatchCount: Int
    public let invalidatedPatchCount: Int
    public let currentYield: Int
    public let capacity: Int
    public let regenerated: Int
    public let harvested: Int
    public let pressure: AgentSubsistencePressureLevel?
    public let hungry: Int
    public let critical: Int
    public let starvationDamage: Int
    public let ecologyEventCount: Int
    public let conservationBalanced: Bool
    public let digest: String
}

public enum AgentLocalEcologyDigest {
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
