public enum AgentCooperationConfigurationError: Error, Equatable {
    case invalidCapacity(Int)
    case invalidQuantity(Int)
    case invalidLifetime(Int)
    case invalidCooldown(Int)
    case invalidTrustThreshold(Int)
    case invalidReliabilityDelta(Int)
    case invalidReliabilityBounds(Int, Int)
}

public struct AgentCooperationConfiguration: Codable, Equatable {
    public static let live = try! AgentCooperationConfiguration()

    public let maximumTasks: Int
    public let maximumOffers: Int
    public let maximumRelations: Int
    public let maximumTaskQuantity: Int
    public let offerLifetimeTicks: Int
    public let acceptedTaskLifetimeTicks: Int
    public let offerCooldownTicks: Int
    public let minimumTrustToAccept: Int
    public let completionReliabilityDelta: Int
    public let failureReliabilityDelta: Int
    public let minimumReliability: Int
    public let maximumReliability: Int

    public init(
        maximumTasks: Int = 16,
        maximumOffers: Int = 16,
        maximumRelations: Int = 32,
        maximumTaskQuantity: Int = 3,
        offerLifetimeTicks: Int = 6,
        acceptedTaskLifetimeTicks: Int = 64,
        offerCooldownTicks: Int = 8,
        minimumTrustToAccept: Int = 0,
        completionReliabilityDelta: Int = 10,
        failureReliabilityDelta: Int = -10,
        minimumReliability: Int = -100,
        maximumReliability: Int = 100
    ) throws {
        guard [maximumTasks, maximumOffers, maximumRelations].allSatisfy({ $0 >= 1 }) else {
            throw AgentCooperationConfigurationError.invalidCapacity(
                min(maximumTasks, maximumOffers, maximumRelations)
            )
        }
        guard (1...3).contains(maximumTaskQuantity) else {
            throw AgentCooperationConfigurationError.invalidQuantity(maximumTaskQuantity)
        }
        guard offerLifetimeTicks >= 1, acceptedTaskLifetimeTicks >= 1 else {
            throw AgentCooperationConfigurationError.invalidLifetime(
                min(offerLifetimeTicks, acceptedTaskLifetimeTicks)
            )
        }
        guard offerCooldownTicks >= 1 else {
            throw AgentCooperationConfigurationError.invalidCooldown(offerCooldownTicks)
        }
        guard minimumReliability < maximumReliability else {
            throw AgentCooperationConfigurationError.invalidReliabilityBounds(
                minimumReliability, maximumReliability
            )
        }
        guard (minimumReliability...maximumReliability).contains(minimumTrustToAccept) else {
            throw AgentCooperationConfigurationError.invalidTrustThreshold(minimumTrustToAccept)
        }
        guard completionReliabilityDelta > 0, failureReliabilityDelta < 0 else {
            throw AgentCooperationConfigurationError.invalidReliabilityDelta(
                completionReliabilityDelta == 0
                    ? failureReliabilityDelta
                    : completionReliabilityDelta
            )
        }
        self.maximumTasks = maximumTasks
        self.maximumOffers = maximumOffers
        self.maximumRelations = maximumRelations
        self.maximumTaskQuantity = maximumTaskQuantity
        self.offerLifetimeTicks = offerLifetimeTicks
        self.acceptedTaskLifetimeTicks = acceptedTaskLifetimeTicks
        self.offerCooldownTicks = offerCooldownTicks
        self.minimumTrustToAccept = minimumTrustToAccept
        self.completionReliabilityDelta = completionReliabilityDelta
        self.failureReliabilityDelta = failureReliabilityDelta
        self.minimumReliability = minimumReliability
        self.maximumReliability = maximumReliability
    }
}

private func cooperationIdentifierIsValid(_ value: String) -> Bool {
    (1...512).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentSharedTaskID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard cooperationIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentCooperationRelationID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard cooperationIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentSharedTaskKind: String, Codable, CaseIterable, Sendable {
    case deliverConstructionMaterial
}

public enum AgentSharedTaskStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case signaled
    case offered
    case accepted
    case active
    case completed
    case declined
    case expired
    case cancelled
    case failed
    case superseded

    public var isTerminal: Bool {
        switch self {
        case .completed, .declined, .expired, .cancelled, .failed, .superseded:
            return true
        case .draft, .signaled, .offered, .accepted, .active:
            return false
        }
    }

    public var reservesDemand: Bool {
        switch self {
        case .draft, .signaled, .offered, .accepted, .active:
            return true
        case .completed, .declined, .expired, .cancelled, .failed, .superseded:
            return false
        }
    }
}

public struct AgentCooperationOfferEnvelope: Codable, Equatable {
    public let taskID: AgentSharedTaskID
    public let signalID: AgentPhysicalSignalID
    public let issuerID: AgentID
    public let intendedHelperID: AgentID
    public let projectID: String
    public let resource: AgentResourceKind
    public let quantity: Int
    public let sourceFactID: AgentSocialFactID
}

public struct AgentSharedTaskOffer: Codable, Equatable {
    public let taskID: AgentSharedTaskID
    public let signalID: AgentPhysicalSignalID
    public let issuerID: AgentID
    public let helperID: AgentID
    public let offeredAtTick: Int
    public let expiresAtTick: Int
    public let exactPerceptionEventID: AgentCausalEventID
}

public struct AgentSharedTask: Codable, Equatable {
    public let taskID: AgentSharedTaskID
    public let kind: AgentSharedTaskKind
    public let projectID: String
    public let issuerID: AgentID
    public let helperID: AgentID
    public let resource: AgentResourceKind
    public let requestedQuantity: Int
    public internal(set) var contributedQuantity: Int
    public let createdAtTick: Int
    public let offerExpiresAtTick: Int
    public internal(set) var acceptedAtTick: Int?
    public internal(set) var startedAtTick: Int?
    public internal(set) var completedAtTick: Int?
    public internal(set) var status: AgentSharedTaskStatus
    public let sourceDemandDigest: String
    public let sourceConstructionEventID: AgentCausalEventID?
    public let sourceFactID: AgentSocialFactID
    public let sourceFactEventID: AgentCausalEventID
    public internal(set) var physicalSignalID: AgentPhysicalSignalID?
    public internal(set) var offerPerceptionEventID: AgentCausalEventID?
    public internal(set) var acceptanceEventID: AgentCausalEventID?
    public internal(set) var latestProgressEventID: AgentCausalEventID?
    public internal(set) var terminalEventID: AgentCausalEventID?
    public internal(set) var reason: String

    public var remainingQuantity: Int {
        max(0, requestedQuantity - contributedQuantity)
    }
}

public struct AgentCooperationRelation: Codable, Equatable {
    public let relationID: AgentCooperationRelationID
    public let issuerID: AgentID
    public let helperID: AgentID
    public internal(set) var reliabilityScore: Int
    public internal(set) var completedTaskCount: Int
    public internal(set) var failedAcceptedTaskCount: Int
    public internal(set) var lastOutcome: AgentSharedTaskStatus
    public internal(set) var lastChangedAtTick: Int
    public internal(set) var lastChangeEventID: AgentCausalEventID
}

public struct AgentCooperationEvictionCounts: Codable, Equatable {
    public internal(set) var tasks: Int
    public internal(set) var offers: Int
    public internal(set) var relations: Int

    public init(tasks: Int = 0, offers: Int = 0, relations: Int = 0) {
        self.tasks = tasks
        self.offers = offers
        self.relations = relations
    }
}

public struct AgentCooperationSnapshot: Codable, Equatable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentCooperationConfiguration
    public let tasks: [AgentSharedTask]
    public let offers: [AgentSharedTaskOffer]
    public let relations: [AgentCooperationRelation]
    public let committedMaterials: [AgentResourceAmount]
    public let contributedMaterials: [AgentResourceAmount]
    public let evictionCounts: AgentCooperationEvictionCounts
    public let cooperationCausalEventCount: Int
    public let digest: String
}

public struct AgentCooperationSummary: Codable, Equatable {
    public let enabled: Bool
    public let taskCount: Int
    public let offeredCount: Int
    public let acceptedCount: Int
    public let activeCount: Int
    public let completedCount: Int
    public let declinedCount: Int
    public let expiredCount: Int
    public let cancelledCount: Int
    public let failedCount: Int
    public let supersededCount: Int
    public let committedMaterials: [AgentResourceAmount]
    public let contributedMaterials: [AgentResourceAmount]
    public let relationCount: Int
    public let cooperationCausalEventCount: Int
    public let evictionCounts: AgentCooperationEvictionCounts
    public let digest: String
}

public enum AgentCooperationError: Error, Equatable {
    case causalLedgerRequired
    case socialRequired
    case physicalRequired
    case constructionProjectRequired
    case cooperationDisabled
    case invalidTask(String)
    case invalidHelper(String)
    case invalidOffer(String)
    case invalidTransition(String)
    case taskCapacityReached
}
