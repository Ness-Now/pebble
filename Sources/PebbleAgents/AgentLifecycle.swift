public struct AgentReproductionPlanID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                      || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentBirthID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                      || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentLifeStage: String, Codable, CaseIterable, Sendable {
    case newborn
    case juvenile
    case mature
}

public enum AgentLifecycleOrigin: String, Codable, CaseIterable, Sendable {
    case bootstrapResident
    case importedMigrant
    case localBirth
}

public enum AgentReproductionPlanStatus: String, Codable, CaseIterable, Sendable {
    case planned
    case completed
    case cancelled
    case failed

    public var isTerminal: Bool { self != .planned }
}

public enum AgentReproductionPlanReason: String, Codable, CaseIterable, Sendable {
    case completed
    case reproductionDisabled
    case parentUnavailable
    case parentDied
    case parentMigrating
    case parentImmature
    case kinshipInvalid
    case parentIneligible
    case populationFull
    case subsistenceInsufficient
    case birthSiteUnavailable
    case invalidObservation
    case staleObservation
}

public enum AgentLifecycleError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case settlementRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case reproductionDisabled
    case invalidMember(String)
    case invalidPlan(String)
    case invalidObservation(String)
    case staleObservation(String)
    case populationFull
    case ordinalOverflow
    case ageOverflow(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid lifecycle configuration: \(reason)"
        case .causalLedgerRequired: return "lifecycle requires the causal ledger"
        case .populationRequired: return "lifecycle requires the population registry"
        case .settlementRequired: return "lifecycle requires a valid settlement"
        case .alreadyEnabled: return "lifecycle already enabled"
        case .disabled: return "lifecycle disabled"
        case .unsafeDisable: return "lifecycle disable refused while durable state exists"
        case .reproductionDisabled: return "reproduction disabled"
        case let .invalidMember(id): return "invalid lifecycle member \(id)"
        case let .invalidPlan(id): return "invalid reproduction plan \(id)"
        case let .invalidObservation(id): return "invalid birth site observation \(id)"
        case let .staleObservation(id): return "stale birth site observation \(id)"
        case .populationFull: return "population capacity reached"
        case .ordinalOverflow: return "population ordinal overflow"
        case let .ageOverflow(id): return "demographic age overflow for \(id)"
        }
    }
}

public struct AgentLifecycleConfiguration: Codable, Equatable, Sendable {
    public let newbornDurationTicks: Int
    public let maturityAgeTicks: Int
    public let reproductionEvaluationIntervalTicks: Int
    public let reproductionPlanDelayTicks: Int
    public let reproductionCooldownTicks: Int
    public let maximumConcurrentPlans: Int
    public let maximumBirthsPerTick: Int
    public let maximumRetainedBirthRecords: Int
    public let maximumRetainedPlanRecords: Int
    public let maximumParentBirthCount: Int
    public let maximumBirthSiteCandidates: Int
    public let birthSiteRadius: Int
    public let maximumBirthSiteWorldReads: Int
    public let maximumLifecycleFrames: Int

    public init(
        newbornDurationTicks: Int = 2,
        maturityAgeTicks: Int = 8,
        reproductionEvaluationIntervalTicks: Int = 2,
        reproductionPlanDelayTicks: Int = 2,
        reproductionCooldownTicks: Int = 16,
        maximumConcurrentPlans: Int = 1,
        maximumBirthsPerTick: Int = 1,
        maximumRetainedBirthRecords: Int = 32,
        maximumRetainedPlanRecords: Int = 32,
        maximumParentBirthCount: Int = 16,
        maximumBirthSiteCandidates: Int = 16,
        birthSiteRadius: Int = 4,
        maximumBirthSiteWorldReads: Int = 128,
        maximumLifecycleFrames: Int = 64
    ) throws {
        guard (1...8).contains(newbornDurationTicks),
              (newbornDurationTicks + 1...64).contains(maturityAgeTicks),
              (1...16).contains(reproductionEvaluationIntervalTicks),
              (1...16).contains(reproductionPlanDelayTicks),
              (1...128).contains(reproductionCooldownTicks),
              maximumConcurrentPlans == 1,
              maximumBirthsPerTick == 1,
              (1...64).contains(maximumRetainedBirthRecords),
              (1...64).contains(maximumRetainedPlanRecords),
              (1...64).contains(maximumParentBirthCount),
              (1...16).contains(maximumBirthSiteCandidates),
              (1...8).contains(birthSiteRadius),
              (1...256).contains(maximumBirthSiteWorldReads),
              (1...128).contains(maximumLifecycleFrames) else {
            throw AgentLifecycleError.invalidConfiguration("bounds")
        }
        self.newbornDurationTicks = newbornDurationTicks
        self.maturityAgeTicks = maturityAgeTicks
        self.reproductionEvaluationIntervalTicks = reproductionEvaluationIntervalTicks
        self.reproductionPlanDelayTicks = reproductionPlanDelayTicks
        self.reproductionCooldownTicks = reproductionCooldownTicks
        self.maximumConcurrentPlans = maximumConcurrentPlans
        self.maximumBirthsPerTick = maximumBirthsPerTick
        self.maximumRetainedBirthRecords = maximumRetainedBirthRecords
        self.maximumRetainedPlanRecords = maximumRetainedPlanRecords
        self.maximumParentBirthCount = maximumParentBirthCount
        self.maximumBirthSiteCandidates = maximumBirthSiteCandidates
        self.birthSiteRadius = birthSiteRadius
        self.maximumBirthSiteWorldReads = maximumBirthSiteWorldReads
        self.maximumLifecycleFrames = maximumLifecycleFrames
    }

    public static let live = try! AgentLifecycleConfiguration()
}

public struct AgentLifecycleMember: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let ordinal: AgentPopulationOrdinal
    public let settlementID: AgentSettlementID
    public let origin: AgentLifecycleOrigin
    public let lifecycleRegisteredTick: Int
    public let initialAgeTicks: Int
    public internal(set) var currentStage: AgentLifeStage
    public internal(set) var lastStageTransitionTick: Int?
    public let progenitorIDs: [AgentID]
    public let birthID: AgentBirthID?
    public internal(set) var lastCompletedBirthTick: Int?
    public internal(set) var completedBirthCount: Int
    public let registrationEventID: AgentCausalEventID
    public internal(set) var lastLifecycleEventID: AgentCausalEventID

    public func age(at tick: Int) throws -> Int {
        let elapsed = tick - lifecycleRegisteredTick
        guard elapsed >= 0 else { throw AgentLifecycleError.invalidMember(agentID.rawValue) }
        let (age, overflow) = initialAgeTicks.addingReportingOverflow(elapsed)
        guard !overflow else { throw AgentLifecycleError.ageOverflow(agentID.rawValue) }
        return age
    }
}

public struct AgentReproductionPlan: Codable, Equatable, Sendable {
    public let planID: AgentReproductionPlanID
    public let settlementID: AgentSettlementID
    public let progenitorIDs: [AgentID]
    public let createdTick: Int
    public let dueTick: Int
    public let populationAtPlanning: Int
    public let pressureAtPlanning: AgentSubsistencePressureLevel
    public internal(set) var resolvedTick: Int?
    public internal(set) var status: AgentReproductionPlanStatus
    public internal(set) var reason: AgentReproductionPlanReason?
    public let createdEventID: AgentCausalEventID
    public internal(set) var terminalEventID: AgentCausalEventID?
}

public struct AgentReproductionSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let eligibleMatureResidentIDs: [AgentID]
    public let eligiblePairs: [[AgentID]]
    public let activePlans: [AgentReproductionPlan]
    public let populationCount: Int
    public let populationCapacity: Int
    public let pressure: AgentSubsistencePressureLevel?
    public let accessibleFood: Int
    public let lastCancellationReason: AgentReproductionPlanReason?
    public let digest: String
}

public struct AgentBirthSiteObservation: Codable, Equatable, Sendable {
    public let planID: AgentReproductionPlanID
    public let observedTick: Int
    public let settlementID: AgentSettlementID
    public let floorPosition: AgentPosition
    public let position: AgentPosition
    public let candidateIndex: Int
    public let worldFingerprint: Int
    public let chunkReady: Bool
    public let floorSolid: Bool
    public let feetFree: Bool
    public let headFree: Bool
    public let unoccupied: Bool
    public let candidatesConsidered: Int
    public let worldReads: Int
    public let distanceFromReception: Int
    public let scanDiagnostics: String

    public init(
        planID: AgentReproductionPlanID,
        observedTick: Int,
        settlementID: AgentSettlementID = AgentSettlementID(rawValue: "settlement-main")!,
        floorPosition: AgentPosition? = nil,
        position: AgentPosition,
        candidateIndex: Int,
        worldFingerprint: Int,
        chunkReady: Bool = true,
        floorSolid: Bool = true,
        feetFree: Bool = true,
        headFree: Bool = true,
        unoccupied: Bool = true,
        candidatesConsidered: Int = 1,
        worldReads: Int = 3,
        distanceFromReception: Int = 0,
        scanDiagnostics: String = "headless_authoritative_observation"
    ) {
        self.planID = planID
        self.observedTick = observedTick
        self.settlementID = settlementID
        self.floorPosition = floorPosition ?? AgentPosition(
            x: position.x, y: position.y - 1, z: position.z
        )
        self.position = position
        self.candidateIndex = candidateIndex
        self.worldFingerprint = worldFingerprint
        self.chunkReady = chunkReady
        self.floorSolid = floorSolid
        self.feetFree = feetFree
        self.headFree = headFree
        self.unoccupied = unoccupied
        self.candidatesConsidered = candidatesConsidered
        self.worldReads = worldReads
        self.distanceFromReception = max(0, distanceFromReception)
        self.scanDiagnostics = String(scanDiagnostics.prefix(256))
    }

    public var isValid: Bool {
        chunkReady && floorSolid && feetFree && headFree && unoccupied
    }
}

public struct AgentBirthRecord: Codable, Equatable, Sendable {
    public let birthID: AgentBirthID
    public let planID: AgentReproductionPlanID
    public let newbornID: AgentID
    public let ordinal: AgentPopulationOrdinal
    public let settlementID: AgentSettlementID
    public let progenitorIDs: [AgentID]
    public let birthTick: Int
    public let position: AgentPosition
    public let worldFingerprint: Int
    public let siteValidatedEventID: AgentCausalEventID
    public let populationBornEventID: AgentCausalEventID
    public let finalizedEventID: AgentCausalEventID
}

public struct AgentLifecycleFrame: Codable, Equatable, Sendable {
    public let tick: Int
    public let newbornCount: Int
    public let juvenileCount: Int
    public let matureCount: Int
    public let activePlanCount: Int
    public let birthDelta: Int
    public let maturityDelta: Int
    public let totalBirthCount: Int
}

public struct AgentLifecycleEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var births: Int
    public internal(set) var plans: Int
    public internal(set) var frames: Int

    public init(births: Int = 0, plans: Int = 0, frames: Int = 0) {
        self.births = max(0, births)
        self.plans = max(0, plans)
        self.frames = max(0, frames)
    }
}

public struct AgentLifecycleState: Codable, Equatable, Sendable {
    public let configuration: AgentLifecycleConfiguration
    public let settlementID: AgentSettlementID
    public internal(set) var reproductionEnabled: Bool
    public internal(set) var members: [AgentLifecycleMember]
    public internal(set) var plans: [AgentReproductionPlan]
    public internal(set) var births: [AgentBirthRecord]
    public internal(set) var frames: [AgentLifecycleFrame]
    public internal(set) var totalBirthCount: Int
    public internal(set) var rollingDigest: String
    public internal(set) var evictionCounts: AgentLifecycleEvictionCounts
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastLifecycleEventID: AgentCausalEventID
}

public struct AgentLifecycleSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let reproductionEnabled: Bool
    public let members: [AgentLifecycleMember]
    public let plans: [AgentReproductionPlan]
    public let births: [AgentBirthRecord]
    public let frames: [AgentLifecycleFrame]
    public let totalBirthCount: Int
    public let evictionCounts: AgentLifecycleEvictionCounts
    public let digest: String
}

public struct AgentLifecycleSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let reproductionEnabled: Bool
    public let newbornCount: Int
    public let juvenileCount: Int
    public let matureCount: Int
    public let activePlanCount: Int
    public let retainedBirthCount: Int
    public let totalBirthCount: Int
    public let latestBirthID: AgentBirthID?
    public let latestNewbornID: AgentID?
    public let digest: String
}

public enum AgentLifecycleDigest {
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
