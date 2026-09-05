import CryptoKit
import Foundation

public enum AgentLongDistanceCommunicationConfigurationError: Error, Equatable {
    case invalidTransportCapacity(Int)
    case invalidJourneyStepCapacity(Int)
    case invalidTransportDistance(Int)
    case invalidTotalProgressCapacity(Int)
}

/// CIV-44 owns only causal transport provenance. CIV-41 remains the belief
/// authority, CIV-42 remains the semantic/language authority, and CIV-43 owns
/// both person-to-person oral handoffs.
public struct AgentLongDistanceCommunicationConfiguration:
    Codable, Equatable, Sendable {
    public static let live = try! AgentLongDistanceCommunicationConfiguration()

    public let maximumRetainedTransports: Int
    public let maximumJourneySteps: Int
    public let maximumTransportDistance: Int

    public init(
        maximumRetainedTransports: Int = 64,
        maximumJourneySteps: Int = 128,
        maximumTransportDistance: Int = 64
    ) throws {
        guard (1...512).contains(maximumRetainedTransports) else {
            throw AgentLongDistanceCommunicationConfigurationError
                .invalidTransportCapacity(maximumRetainedTransports)
        }
        guard (1...512).contains(maximumJourneySteps) else {
            throw AgentLongDistanceCommunicationConfigurationError
                .invalidJourneyStepCapacity(maximumJourneySteps)
        }
        guard (2...AgentResourcePerception.maximumDistance * 8).contains(
            maximumTransportDistance
        ) else {
            throw AgentLongDistanceCommunicationConfigurationError
                .invalidTransportDistance(maximumTransportDistance)
        }
        guard maximumRetainedTransports * maximumJourneySteps <= 8_192 else {
            throw AgentLongDistanceCommunicationConfigurationError
                .invalidTotalProgressCapacity(
                    maximumRetainedTransports * maximumJourneySteps
                )
        }
        self.maximumRetainedTransports = maximumRetainedTransports
        self.maximumJourneySteps = maximumJourneySteps
        self.maximumTransportDistance = maximumTransportDistance
    }
}

public enum AgentLongDistanceCommunicationError: Error, Equatable {
    case causalLedgerRequired
    case socialRequired
    case knowledgeRequired
    case languageRequired
    case oralRequired
    case autonomousActivityRequired
    case disabled
    case unknownAgent(String)
    case invalidParticipant(String)
    case migratingParticipant(String)
    case localPickupRefused(String)
    case destinationNotRemote(distance: Int, radius: Int)
    case destinationTooFar(distance: Int, maximum: Int)
    case carrierBusy(String)
    case transportNotFound(String)
    case transportNotArrived(String)
    case destinationConditionRefused(String)
    case carrierBeliefChanged(String)
    case capacityReached(String)
    case invalidState(String)
}

private func isValidLongDistanceCommunicationIdentifier(
    _ value: String
) -> Bool {
    (1...192).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentCommunicationTransportID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String

    public init?(rawValue: String) {
        guard isValidLongDistanceCommunicationIdentifier(rawValue) else {
            return nil
        }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentCommunicationTransportStatus:
    String, Codable, CaseIterable, Sendable {
    case inTransit
    case arrived
    case delivered
    case failed

    public var isTerminal: Bool { self == .delivered || self == .failed }
}

public enum AgentCommunicationTransportFailure:
    String, Codable, CaseIterable, Sendable {
    case journeyStepLimit
    case carrierDied
    case destinationDied
}

/// One accepted movement publication by the existing movement authority.
/// `movementEventID` proves the physical/coarse position publication;
/// `progressEventID` links that fact into the CIV-44 transport chain.
public struct AgentCommunicationTransportProgress:
    Codable, Equatable, Sendable {
    public let stepOrdinal: Int
    public let fromPosition: AgentPosition
    public let toPosition: AgentPosition
    public let movementEventID: AgentCausalEventID
    public let progressEventID: AgentCausalEventID
    public let progressedAtTick: Int
}

public struct AgentCommunicationTransport:
    Codable, Equatable, Sendable {
    public let transportID: AgentCommunicationTransportID
    public let authorID: AgentID
    public let carrierID: AgentID
    public let destinationID: AgentID
    public let sourceAuthorityID:
        AgentKnowledgeHistoricalBeliefAuthorityID
    public let pickupTransmissionID: AgentOralTransmissionID
    public let pickupReceiptEventID: AgentCausalEventID
    /// Immutable commitments to the authoritative, retained CIV-43 pickup.
    /// CIV-44 deliberately does not duplicate CIV-42 semantic objects.
    public let originSemanticContentDigest: String
    public let carriedSemanticContentDigest: String
    public let carriedPropositionID: AgentKnowledgePropositionID
    /// CIV-41 belief identity and exact revision accepted by the CIV-43
    /// pickup. Later same-content reaffirmations may advance the live belief
    /// revision, but can never change these pickup facts.
    public let carrierBeliefID: AgentKnowledgeBeliefID
    public let carrierBeliefRevisionEventID: AgentCausalEventID
    public let dispatchPosition: AgentPosition
    public let destinationPositionAtDispatch: AgentPosition
    public let initialDistance: Int
    public let startedAtTick: Int
    public let dispatchEventID: AgentCausalEventID
    public internal(set) var progress: [AgentCommunicationTransportProgress]
    public internal(set) var status: AgentCommunicationTransportStatus
    public internal(set) var arrivalPosition: AgentPosition?
    public internal(set) var destinationPositionAtArrival: AgentPosition?
    public internal(set) var arrivedAtTick: Int?
    public internal(set) var arrivalEventID: AgentCausalEventID?
    public internal(set) var deliveryTransmissionID: AgentOralTransmissionID?
    public internal(set) var destinationBeliefID: AgentKnowledgeBeliefID?
    public internal(set) var destinationBeliefRevisionEventID:
        AgentCausalEventID?
    public internal(set) var deliveredAtTick: Int?
    public internal(set) var deliveryEventID: AgentCausalEventID?
    public internal(set) var failure: AgentCommunicationTransportFailure?
    public internal(set) var failedAtTick: Int?
    public internal(set) var failureEventID: AgentCausalEventID?
    public internal(set) var provenanceDigest: String
}

/// One retained event independently commits the exact bounded transport set.
/// A dropped causal prefix is never sufficient authority by itself.
public struct AgentCommunicationTransportProvenanceBoundary:
    Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let digest: String
}

public struct AgentLongDistanceCommunicationState:
    Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let configuration: AgentLongDistanceCommunicationConfiguration
    public internal(set) var transports: [AgentCommunicationTransport]
    public internal(set) var evictedTransportCount: Int
    public internal(set) var totalStartedCount: Int
    public internal(set) var totalDeliveredCount: Int
    public internal(set) var totalFailedCount: Int
    public internal(set) var nextTransportOrdinal: UInt64
    public internal(set) var provenanceBoundary:
        AgentCommunicationTransportProvenanceBoundary?

    init(configuration: AgentLongDistanceCommunicationConfiguration) {
        enabled = true
        self.configuration = configuration
        transports = []
        evictedTransportCount = 0
        totalStartedCount = 0
        totalDeliveredCount = 0
        totalFailedCount = 0
        nextTransportOrdinal = 1
        provenanceBoundary = nil
    }
}

public struct AgentLongDistanceCommunicationSnapshot:
    Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentLongDistanceCommunicationConfiguration?
    public let transports: [AgentCommunicationTransport]
    public let evictedTransportCount: Int
    public let totalStartedCount: Int
    public let totalDeliveredCount: Int
    public let totalFailedCount: Int
    public let provenanceBoundary:
        AgentCommunicationTransportProvenanceBoundary?
    public let digest: String
}

public struct AgentLongDistanceCommunicationSummary:
    Codable, Equatable, Sendable {
    public let enabled: Bool
    public let retainedTransportCount: Int
    public let inTransitCount: Int
    public let arrivedCount: Int
    public let deliveredCount: Int
    public let failedCount: Int
    public let evictedTransportCount: Int
    public let acceptedMovementStepCount: Int
    public let digest: String
}

enum AgentLongDistanceCommunicationDigest {
    static func make(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}
