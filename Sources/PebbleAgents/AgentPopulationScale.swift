public enum AgentSimulationFidelity: String, Codable, CaseIterable, Sendable {
    case live = "LIVE"
    case near = "NEAR"
    case dormant = "DORMANT"
}

public enum AgentFidelityTransitionCause: String, Codable, CaseIterable, Sendable {
    case initialPolicy
    case scheduledRotation
    case activeMigration
    case migrationCompleted
}

public struct AgentPopulationScaleConfiguration: Codable, Equatable, Sendable {
    public let maximumSettlements: Int
    public let maximumLiveAgents: Int
    public let maximumNearAgents: Int
    public let nearMaintenanceCadence: Int
    public let dormantMaintenanceCadence: Int
    public let rotationIntervalTicks: Int
    public let maximumFidelityTransitionHistory: Int
    public let maximumSettlementMigrationHistory: Int
    public let maximumConcurrentSettlementMigrations: Int
    public let maximumSettlementMigrationRouteLength: Int

    public init(
        maximumSettlements: Int = 4,
        maximumLiveAgents: Int = 4,
        maximumNearAgents: Int = 12,
        nearMaintenanceCadence: Int = 4,
        dormantMaintenanceCadence: Int = 16,
        rotationIntervalTicks: Int = 8,
        maximumFidelityTransitionHistory: Int = 128,
        maximumSettlementMigrationHistory: Int = 64,
        maximumConcurrentSettlementMigrations: Int = 1,
        maximumSettlementMigrationRouteLength: Int = 32
    ) throws {
        guard (2...8).contains(maximumSettlements),
              (1...128).contains(maximumLiveAgents),
              (1...256).contains(maximumNearAgents),
              (1...64).contains(nearMaintenanceCadence),
              (nearMaintenanceCadence...256).contains(dormantMaintenanceCadence),
              (1...256).contains(rotationIntervalTicks),
              (1...1024).contains(maximumFidelityTransitionHistory),
              (1...512).contains(maximumSettlementMigrationHistory),
              maximumConcurrentSettlementMigrations == 1,
              (1...64).contains(maximumSettlementMigrationRouteLength) else {
            throw AgentPopulationError.invalidConfiguration("population scale")
        }
        self.maximumSettlements = maximumSettlements
        self.maximumLiveAgents = maximumLiveAgents
        self.maximumNearAgents = maximumNearAgents
        self.nearMaintenanceCadence = nearMaintenanceCadence
        self.dormantMaintenanceCadence = dormantMaintenanceCadence
        self.rotationIntervalTicks = rotationIntervalTicks
        self.maximumFidelityTransitionHistory = maximumFidelityTransitionHistory
        self.maximumSettlementMigrationHistory = maximumSettlementMigrationHistory
        self.maximumConcurrentSettlementMigrations = maximumConcurrentSettlementMigrations
        self.maximumSettlementMigrationRouteLength = maximumSettlementMigrationRouteLength
    }

    public static let live = try! AgentPopulationScaleConfiguration()
}

public struct AgentScaledResidentAdmission: Codable {
    public let state: AgentSessionAgentState
    public let settlementID: AgentSettlementID

    public init(state: AgentSessionAgentState, settlementID: AgentSettlementID) {
        self.state = state
        self.settlementID = settlementID
    }
}

public struct AgentFidelityRecord: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var fidelity: AgentSimulationFidelity
    public internal(set) var enteredTick: Int
    public internal(set) var transitionCount: Int
    public internal(set) var lastTransitionEventID: AgentCausalEventID
}

public struct AgentFidelityTransitionRecord: Codable, Equatable, Sendable {
    public let ordinal: UInt64
    public let agentID: AgentID
    public let from: AgentSimulationFidelity?
    public let to: AgentSimulationFidelity
    public let tick: Int
    public let cause: AgentFidelityTransitionCause
    public let eventID: AgentCausalEventID
}

public enum AgentSettlementMigrationStatus: String, Codable, CaseIterable, Sendable {
    case inTransit
    case arrived
    case failed

    var isTerminal: Bool { self != .inTransit }
}

public enum AgentSettlementMigrationFailure: String, Codable, CaseIterable,
    Sendable
{
    case memberDied
}

public struct AgentSettlementMigrationID: RawRepresentable, Codable, Hashable,
    Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard (1...96).contains(rawValue.utf8.count),
              rawValue.utf8.allSatisfy({
                  (65...90).contains($0) || (97...122).contains($0)
                      || (48...57).contains($0) || $0 == 45 || $0 == 95
              }) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (
        lhs: AgentSettlementMigrationID,
        rhs: AgentSettlementMigrationID
    ) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentSettlementMigrationRecord: Codable, Equatable, Sendable {
    public let migrationID: AgentSettlementMigrationID
    public let agentID: AgentID
    public let originSettlementID: AgentSettlementID
    public let destinationSettlementID: AgentSettlementID
    public let route: [AgentPosition]
    public internal(set) var routeCursor: Int
    public let startedTick: Int
    public internal(set) var arrivedTick: Int?
    public internal(set) var status: AgentSettlementMigrationStatus
    public let startedEventID: AgentCausalEventID
    public internal(set) var arrivedEventID: AgentCausalEventID?
    public internal(set) var lastMovementEventID: AgentCausalEventID?
    public internal(set) var failure: AgentSettlementMigrationFailure? = nil
    public internal(set) var failedTick: Int? = nil
    public internal(set) var failureEventID: AgentCausalEventID? = nil
}

public struct AgentFidelityWorkCounters: Codable, Equatable, Sendable {
    public internal(set) var liveCognitionExecutions: UInt64 = 0
    public internal(set) var nearMaintenanceExecutions: UInt64 = 0
    public internal(set) var dormantMaintenanceExecutions: UInt64 = 0
    public internal(set) var skippedFullCognitionExecutions: UInt64 = 0
}

public struct AgentPopulationScaleState: Codable, Equatable, Sendable {
    public let configuration: AgentPopulationScaleConfiguration
    public internal(set) var fidelityRecords: [AgentFidelityRecord]
    public internal(set) var fidelityTransitions: [AgentFidelityTransitionRecord]
    public internal(set) var settlementMigrations: [AgentSettlementMigrationRecord]
    public internal(set) var rotationOffset: Int
    public internal(set) var nextFidelityTransitionOrdinal: UInt64
    public internal(set) var nextSettlementMigrationOrdinal: UInt64
    public internal(set) var evictedFidelityTransitionCount: UInt64
    public internal(set) var evictedSettlementMigrationCount: UInt64
    public internal(set) var workCounters: AgentFidelityWorkCounters
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastScaleEventID: AgentCausalEventID
}

public struct AgentPopulationScaleSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let settlements: [AgentPopulationSettlement]
    public let fidelityRecords: [AgentFidelityRecord]
    public let fidelityTransitions: [AgentFidelityTransitionRecord]
    public let settlementMigrations: [AgentSettlementMigrationRecord]
    public let workCounters: AgentFidelityWorkCounters
    public let evictedFidelityTransitionCount: UInt64
    public let evictedSettlementMigrationCount: UInt64
    public let digest: String

    public var liveCount: Int {
        fidelityRecords.filter { $0.fidelity == .live }.count
    }
    public var nearCount: Int {
        fidelityRecords.filter { $0.fidelity == .near }.count
    }
    public var dormantCount: Int {
        fidelityRecords.filter { $0.fidelity == .dormant }.count
    }
}
