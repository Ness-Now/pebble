public struct AgentSettlementID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...64).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                      || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentSettlementID, rhs: AgentSettlementID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static let main = AgentSettlementID(rawValue: "settlement-main")!
}

public struct AgentPopulationOrdinal: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: Int

    public init?(rawValue: Int) {
        guard rawValue >= 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentPopulationOrdinal, rhs: AgentPopulationOrdinal) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentMigrationID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                      || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentMigrationID, rhs: AgentMigrationID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentMigrationOrigin: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue == "outside-north" else { return nil }
        self.rawValue = rawValue
    }

    public static let outsideNorth = AgentMigrationOrigin(rawValue: "outside-north")!
}

public enum AgentPopulationMembershipStatus: String, Codable, CaseIterable, Sendable {
    case founderResident
    case migrating
    case resident
}

public enum AgentMigrationStatus: String, Codable, CaseIterable, Sendable {
    case proposed
    case admitted
    case inTransit
    case arrived
    case rejected
    case cancelled
    case failed
}

public enum AgentMigrationFailure: String, Codable, CaseIterable, Error, Sendable {
    case populationFull
    case migrationAlreadyActive
    case noValidEntry
    case entryChunkUnavailable
    case entryOccupied
    case receptionUnavailable
    case routeUnavailable
    case invalidWorldObservation
    case duplicateAdmission
    case deadlineExceeded
    case memberMissing
    case settlementMissing
    case routeIrrecoverable
    case memberDied
}

public enum AgentPopulationError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case invalidFounder(String)
    case admission(AgentMigrationFailure)
    case invalidMigration(String)
    case capacityReached
    case ordinalOverflow

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid population configuration: \(reason)"
        case .causalLedgerRequired: return "population requires the causal ledger"
        case .alreadyEnabled: return "population registry already enabled"
        case .disabled: return "population registry disabled"
        case .unsafeDisable: return "population disable refused while durable population state exists"
        case let .invalidFounder(id): return "invalid founder \(id)"
        case let .admission(reason): return "migration admission refused: \(reason.rawValue)"
        case let .invalidMigration(id): return "invalid migration \(id)"
        case .capacityReached: return "population capacity reached"
        case .ordinalOverflow: return "population ordinal overflow"
        }
    }
}

public struct AgentPopulationConfiguration: Codable, Equatable, Sendable {
    public let maximumActivePopulation: Int
    public let maximumMigrationRecords: Int
    public let maximumConcurrentMigrations: Int
    public let maximumMigrationDistance: Int
    public let maximumEntryCandidates: Int
    public let maximumRouteLength: Int
    public let maximumMigrationTicks: Int
    public let maximumMigrationReplans: Int
    public let arrivalDistance: Int

    public init(
        maximumActivePopulation: Int = 8,
        maximumMigrationRecords: Int = 16,
        maximumConcurrentMigrations: Int = 1,
        maximumMigrationDistance: Int = 24,
        maximumEntryCandidates: Int = 16,
        maximumRouteLength: Int = 32,
        maximumMigrationTicks: Int = 64,
        maximumMigrationReplans: Int = 3,
        arrivalDistance: Int = 0
    ) throws {
        guard (3...512).contains(maximumActivePopulation) else {
            throw AgentPopulationError.invalidConfiguration("active population")
        }
        guard (1...64).contains(maximumMigrationRecords) else {
            throw AgentPopulationError.invalidConfiguration("migration records")
        }
        guard maximumConcurrentMigrations == 1 else {
            throw AgentPopulationError.invalidConfiguration("concurrent migrations")
        }
        guard (1...64).contains(maximumMigrationDistance),
              (1...16).contains(maximumEntryCandidates),
              (1...32).contains(maximumRouteLength),
              (1...256).contains(maximumMigrationTicks),
              (0...3).contains(maximumMigrationReplans),
              arrivalDistance == 0 else {
            throw AgentPopulationError.invalidConfiguration("migration bounds")
        }
        self.maximumActivePopulation = maximumActivePopulation
        self.maximumMigrationRecords = maximumMigrationRecords
        self.maximumConcurrentMigrations = maximumConcurrentMigrations
        self.maximumMigrationDistance = maximumMigrationDistance
        self.maximumEntryCandidates = maximumEntryCandidates
        self.maximumRouteLength = maximumRouteLength
        self.maximumMigrationTicks = maximumMigrationTicks
        self.maximumMigrationReplans = maximumMigrationReplans
        self.arrivalDistance = arrivalDistance
    }

    public static let live = try! AgentPopulationConfiguration()
}

public struct AgentPopulationSettlement: Codable, Equatable, Sendable {
    public let settlementID: AgentSettlementID
    public let anchor: AgentPosition
    public let receptionPosition: AgentPosition
    public let capacity: Int
    public internal(set) var residentIDs: [AgentID]
    public internal(set) var inTransitIDs: [AgentID]

    public init(
        settlementID: AgentSettlementID = .main,
        anchor: AgentPosition,
        receptionPosition: AgentPosition,
        capacity: Int,
        residentIDs: [AgentID],
        inTransitIDs: [AgentID]
    ) {
        self.settlementID = settlementID
        self.anchor = anchor
        self.receptionPosition = receptionPosition
        self.capacity = capacity
        self.residentIDs = residentIDs.sorted()
        self.inTransitIDs = inTransitIDs.sorted()
    }
}

public struct AgentPopulationMemberRecord: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let ordinal: AgentPopulationOrdinal
    public internal(set) var settlementID: AgentSettlementID
    public internal(set) var status: AgentPopulationMembershipStatus
    public let founder: Bool
    public let registeredTick: Int
    public internal(set) var arrivalTick: Int?
    public let migrationID: AgentMigrationID?
    public let entryPosition: AgentPosition?
    public let receptionPosition: AgentPosition
    public let registrationEventID: AgentCausalEventID
    public internal(set) var arrivalEventID: AgentCausalEventID?

    public init(
        agentID: AgentID,
        ordinal: AgentPopulationOrdinal,
        settlementID: AgentSettlementID,
        status: AgentPopulationMembershipStatus,
        founder: Bool,
        registeredTick: Int,
        arrivalTick: Int?,
        migrationID: AgentMigrationID?,
        entryPosition: AgentPosition?,
        receptionPosition: AgentPosition,
        registrationEventID: AgentCausalEventID,
        arrivalEventID: AgentCausalEventID?
    ) {
        self.agentID = agentID
        self.ordinal = ordinal
        self.settlementID = settlementID
        self.status = status
        self.founder = founder
        self.registeredTick = registeredTick
        self.arrivalTick = arrivalTick
        self.migrationID = migrationID
        self.entryPosition = entryPosition
        self.receptionPosition = receptionPosition
        self.registrationEventID = registrationEventID
        self.arrivalEventID = arrivalEventID
    }
}

public struct AgentMigrationAdmissionIntent: Codable, Equatable, Sendable {
    public let origin: AgentMigrationOrigin
    public let destinationSettlementID: AgentSettlementID

    public init(
        origin: AgentMigrationOrigin = .outsideNorth,
        destinationSettlementID: AgentSettlementID = .main
    ) {
        self.origin = origin
        self.destinationSettlementID = destinationSettlementID
    }
}

public struct AgentMigrationWorldObservation: Codable, Equatable, Sendable {
    public let worldTick: Int
    public let candidateIndex: Int
    public let entryPosition: AgentPosition
    public let receptionPosition: AgentPosition
    public let route: [AgentPosition]
    public let entryChunkReady: Bool
    public let entrySafe: Bool
    public let entryUnoccupied: Bool
    public let receptionChunkReady: Bool
    public let receptionSafe: Bool
    public let receptionUnoccupied: Bool

    public init(
        worldTick: Int,
        candidateIndex: Int,
        entryPosition: AgentPosition,
        receptionPosition: AgentPosition,
        route: [AgentPosition],
        entryChunkReady: Bool = true,
        entrySafe: Bool = true,
        entryUnoccupied: Bool = true,
        receptionChunkReady: Bool = true,
        receptionSafe: Bool = true,
        receptionUnoccupied: Bool = true
    ) {
        self.worldTick = worldTick
        self.candidateIndex = candidateIndex
        self.entryPosition = entryPosition
        self.receptionPosition = receptionPosition
        self.route = route
        self.entryChunkReady = entryChunkReady
        self.entrySafe = entrySafe
        self.entryUnoccupied = entryUnoccupied
        self.receptionChunkReady = receptionChunkReady
        self.receptionSafe = receptionSafe
        self.receptionUnoccupied = receptionUnoccupied
    }
}

public struct AgentMigrationRecord: Codable, Equatable, Sendable {
    public let migrationID: AgentMigrationID
    public let migrantID: AgentID
    public let ordinal: AgentPopulationOrdinal
    public let origin: AgentMigrationOrigin
    public let destinationSettlementID: AgentSettlementID
    public let entryPosition: AgentPosition
    public let receptionPosition: AgentPosition
    public let route: [AgentPosition]
    public internal(set) var routeCursor: Int
    public let admittedTick: Int
    public let startedTick: Int
    public internal(set) var arrivedTick: Int?
    public let deadlineTick: Int
    public internal(set) var status: AgentMigrationStatus
    public internal(set) var failure: AgentMigrationFailure?
    public let proposedEventID: AgentCausalEventID
    public let admittedEventID: AgentCausalEventID
    public let startedEventID: AgentCausalEventID
    public internal(set) var arrivedEventID: AgentCausalEventID?
    public internal(set) var lastMovementEventID: AgentCausalEventID?
    public internal(set) var replanCount: Int

    public init(
        migrationID: AgentMigrationID,
        migrantID: AgentID,
        ordinal: AgentPopulationOrdinal,
        origin: AgentMigrationOrigin,
        destinationSettlementID: AgentSettlementID,
        entryPosition: AgentPosition,
        receptionPosition: AgentPosition,
        route: [AgentPosition],
        routeCursor: Int,
        admittedTick: Int,
        startedTick: Int,
        arrivedTick: Int?,
        deadlineTick: Int,
        status: AgentMigrationStatus,
        failure: AgentMigrationFailure?,
        proposedEventID: AgentCausalEventID,
        admittedEventID: AgentCausalEventID,
        startedEventID: AgentCausalEventID,
        arrivedEventID: AgentCausalEventID?,
        lastMovementEventID: AgentCausalEventID?,
        replanCount: Int
    ) {
        self.migrationID = migrationID
        self.migrantID = migrantID
        self.ordinal = ordinal
        self.origin = origin
        self.destinationSettlementID = destinationSettlementID
        self.entryPosition = entryPosition
        self.receptionPosition = receptionPosition
        self.route = route
        self.routeCursor = routeCursor
        self.admittedTick = admittedTick
        self.startedTick = startedTick
        self.arrivedTick = arrivedTick
        self.deadlineTick = deadlineTick
        self.status = status
        self.failure = failure
        self.proposedEventID = proposedEventID
        self.admittedEventID = admittedEventID
        self.startedEventID = startedEventID
        self.arrivedEventID = arrivedEventID
        self.lastMovementEventID = lastMovementEventID
        self.replanCount = replanCount
    }
}

public struct AgentPopulationEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var terminalMigrations: Int
    public internal(set) var diagnostics: Int

    public init(terminalMigrations: Int = 0, diagnostics: Int = 0) {
        self.terminalMigrations = terminalMigrations
        self.diagnostics = diagnostics
    }
}

public struct AgentPopulationRegistry: Codable, Equatable, Sendable {
    public let configuration: AgentPopulationConfiguration
    public internal(set) var settlement: AgentPopulationSettlement
    /// CIV-39 settlements other than the legacy/main settlement. The main
    /// settlement remains stored exactly once in `settlement`; this array is
    /// not a second projection of it. Optional storage preserves byte and
    /// decode compatibility for pre-CIV-39 checkpoints.
    public internal(set) var additionalSettlements: [AgentPopulationSettlement]?
    public internal(set) var members: [AgentPopulationMemberRecord]
    public internal(set) var migrations: [AgentMigrationRecord]
    /// CIV-39 execution-fidelity and inter-settlement transition authority.
    /// Agent state itself remains exclusively in AgentSimulationSession.
    public internal(set) var scaleState: AgentPopulationScaleState?
    public internal(set) var nextPopulationOrdinal: AgentPopulationOrdinal
    public internal(set) var evictionCounts: AgentPopulationEvictionCounts
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastPopulationEventID: AgentCausalEventID

    public init(
        configuration: AgentPopulationConfiguration,
        settlement: AgentPopulationSettlement,
        additionalSettlements: [AgentPopulationSettlement]? = nil,
        members: [AgentPopulationMemberRecord],
        migrations: [AgentMigrationRecord],
        scaleState: AgentPopulationScaleState? = nil,
        nextPopulationOrdinal: AgentPopulationOrdinal,
        evictionCounts: AgentPopulationEvictionCounts,
        initializedEventID: AgentCausalEventID,
        lastPopulationEventID: AgentCausalEventID
    ) {
        self.configuration = configuration
        self.settlement = settlement
        self.additionalSettlements = additionalSettlements?.sorted {
            $0.settlementID < $1.settlementID
        }
        self.members = members.sorted { $0.agentID < $1.agentID }
        self.migrations = migrations.sorted { $0.migrationID < $1.migrationID }
        self.scaleState = scaleState
        self.nextPopulationOrdinal = nextPopulationOrdinal
        self.evictionCounts = evictionCounts
        self.initializedEventID = initializedEventID
        self.lastPopulationEventID = lastPopulationEventID
    }
}

public struct AgentPopulationSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let settlement: AgentPopulationSettlement?
    public let additionalSettlements: [AgentPopulationSettlement]
    public let members: [AgentPopulationMemberRecord]
    public let migrations: [AgentMigrationRecord]
    public let nextPopulationOrdinal: Int?
    public let evictionCounts: AgentPopulationEvictionCounts
    public let populationCausalEventCount: Int
    public let digest: String

    public init(
        enabled: Bool,
        settlement: AgentPopulationSettlement?,
        additionalSettlements: [AgentPopulationSettlement] = [],
        members: [AgentPopulationMemberRecord],
        migrations: [AgentMigrationRecord],
        nextPopulationOrdinal: Int?,
        evictionCounts: AgentPopulationEvictionCounts,
        populationCausalEventCount: Int,
        digest: String
    ) {
        self.enabled = enabled
        self.settlement = settlement
        self.additionalSettlements = additionalSettlements.sorted {
            $0.settlementID < $1.settlementID
        }
        self.members = members
        self.migrations = migrations
        self.nextPopulationOrdinal = nextPopulationOrdinal
        self.evictionCounts = evictionCounts
        self.populationCausalEventCount = populationCausalEventCount
        self.digest = digest
    }

    public var settlements: [AgentPopulationSettlement] {
        ([settlement].compactMap { $0 } + additionalSettlements).sorted {
            $0.settlementID < $1.settlementID
        }
    }
}

public struct AgentPopulationSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let settlementID: AgentSettlementID?
    public let capacity: Int
    public let memberCount: Int
    public let founderCount: Int
    public let residentCount: Int
    public let migratingCount: Int
    public let nextPopulationOrdinal: Int?
    public let activeMigrationCount: Int
    public let arrivedMigrationCount: Int
    public let rejectedMigrationCount: Int
    public let failedMigrationCount: Int
    public let populationCausalEventCount: Int
    public let evictionCounts: AgentPopulationEvictionCounts
    public let digest: String
}

public struct AgentMigrationSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let migrations: [AgentMigrationRecord]
    public let activeMigrationID: AgentMigrationID?
    public let digest: String

    public init(
        enabled: Bool,
        migrations: [AgentMigrationRecord],
        activeMigrationID: AgentMigrationID?,
        digest: String
    ) {
        self.enabled = enabled
        self.migrations = migrations
        self.activeMigrationID = activeMigrationID
        self.digest = digest
    }
}

public enum AgentPopulationDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: 16 - digits.count) + digits
    }
}

extension AgentPopulationRegistry {
    public var settlements: [AgentPopulationSettlement] {
        ([settlement] + (additionalSettlements ?? [])).sorted {
            $0.settlementID < $1.settlementID
        }
    }

    func settlement(withID id: AgentSettlementID) -> AgentPopulationSettlement? {
        if settlement.settlementID == id { return settlement }
        return additionalSettlements?.first { $0.settlementID == id }
    }

    mutating func updateSettlement(
        withID id: AgentSettlementID,
        _ update: (inout AgentPopulationSettlement) -> Void
    ) -> Bool {
        if settlement.settlementID == id {
            update(&settlement)
            return true
        }
        guard let index = additionalSettlements?.firstIndex(where: {
            $0.settlementID == id
        }) else { return false }
        update(&additionalSettlements![index])
        additionalSettlements!.sort { $0.settlementID < $1.settlementID }
        return true
    }

    /// The single current-resident capacity rule used by both candidate
    /// publication and durable-state validation. In-transit inhabitants remain
    /// governed by their migration authority; settlement capacity bounds the
    /// current resident projection exactly as persisted by schema 35.
    func hasResidentCapacity(
        forProposedAdmissions admissionSettlementIDs: [AgentSettlementID] = []
    ) -> Bool {
        let currentSettlements = settlements
        let knownSettlementIDs = Set(currentSettlements.map(\.settlementID))
        guard admissionSettlementIDs.allSatisfy(knownSettlementIDs.contains)
        else { return false }
        return currentSettlements.allSatisfy { settlement in
            guard settlement.residentIDs.count <= settlement.capacity else {
                return false
            }
            let proposedCount = admissionSettlementIDs.reduce(into: 0) {
                count, settlementID in
                if settlementID == settlement.settlementID { count += 1 }
            }
            return proposedCount
                <= settlement.capacity - settlement.residentIDs.count
        }
    }

    /// Counts current residents plus every durable incoming claim that can
    /// still become current residence. Both legacy external migration and
    /// CIV-39 settlement migration persist their active authority in schema
    /// 35, so this value is reconstructible and needs no second occupancy
    /// counter. Terminal history deliberately contributes no current claim.
    func hasCommittedResidentCapacity(
        forProposedAdmissions admissionSettlementIDs: [AgentSettlementID] = []
    ) -> Bool {
        let legacyClaims = migrations.compactMap { migration in
            migration.status == .admitted || migration.status == .inTransit
                ? migration.destinationSettlementID : nil
        }
        let scaledClaims = scaleState?.settlementMigrations.compactMap {
            migration in
            migration.status == .inTransit
                ? migration.destinationSettlementID : nil
        } ?? []
        return hasResidentCapacity(
            forProposedAdmissions:
                legacyClaims + scaledClaims + admissionSettlementIDs
        )
    }

    mutating func removeMemberFromEverySettlement(_ agentID: AgentID) {
        _ = updateSettlement(withID: settlement.settlementID) {
            $0.residentIDs.removeAll { $0 == agentID }
            $0.inTransitIDs.removeAll { $0 == agentID }
        }
        for id in (additionalSettlements ?? []).map(\.settlementID) {
            _ = updateSettlement(withID: id) {
                $0.residentIDs.removeAll { $0 == agentID }
                $0.inTransitIDs.removeAll { $0 == agentID }
            }
        }
    }
}
