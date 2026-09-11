import CryptoKit
import Foundation

public enum AgentCultureError: Error, Equatable {
    case invalidConfiguration(String)
    case invalidPractice(String)
    case invalidOperationID(String)
    case causalLedgerRequired
    case populationRequired
    case socialRequired
    case disabled
    case unknownAgent(AgentID)
    case unknownPractice(AgentCulturePracticeID)
    case unknownCarrier(String)
    case invalidCarrier(String)
    case nonLocal(AgentID, AgentID)
    case notAdopted(AgentID, AgentCulturePracticeID)
    case duplicateCarrier(AgentCulturePracticeID)
    case capacityReached(String)
    case conflictingRetry(String)
    case invalidState(String)
}

/// Structural bounds for sparse, per-individual cultural state. These bounds
/// cap retained rows, not a dense agents-by-practices matrix.
public struct AgentCultureConfiguration: Codable, Equatable, Sendable {
    public static let live = try! Self()

    public let maximumIndividuals: Int
    public let maximumPracticesPerIndividual: Int
    public let maximumHistoryPerIndividual: Int
    public let maximumOperationReceipts: Int
    public let maximumParticipantsPerUse: Int
    public let maximumWitnessesPerUse: Int
    public let adoptionExposureThreshold: Int
    public let inactivityTicksBeforeDecline: Int

    public init(
        maximumIndividuals: Int = 512,
        maximumPracticesPerIndividual: Int = 32,
        maximumHistoryPerIndividual: Int = 128,
        maximumOperationReceipts: Int = 4_096,
        maximumParticipantsPerUse: Int = 8,
        maximumWitnessesPerUse: Int = 16,
        adoptionExposureThreshold: Int = 2,
        inactivityTicksBeforeDecline: Int = 64
    ) throws {
        guard (1...512).contains(maximumIndividuals) else {
            throw AgentCultureError.invalidConfiguration("individuals")
        }
        guard (1...64).contains(maximumPracticesPerIndividual),
              maximumIndividuals * maximumPracticesPerIndividual <= 32_768 else {
            throw AgentCultureError.invalidConfiguration("individual practices")
        }
        guard (1...512).contains(maximumHistoryPerIndividual),
              maximumIndividuals * maximumHistoryPerIndividual <= 131_072 else {
            throw AgentCultureError.invalidConfiguration("individual history")
        }
        guard (1...65_536).contains(maximumOperationReceipts) else {
            throw AgentCultureError.invalidConfiguration("operation receipts")
        }
        guard (1...AgentCausalEvent.maximumCauseCount).contains(
            maximumParticipantsPerUse
        ), (0...64).contains(maximumWitnessesPerUse) else {
            throw AgentCultureError.invalidConfiguration("use participants")
        }
        guard (1...16).contains(adoptionExposureThreshold),
              (1...1_000_000).contains(inactivityTicksBeforeDecline) else {
            throw AgentCultureError.invalidConfiguration("decision thresholds")
        }
        self.maximumIndividuals = maximumIndividuals
        self.maximumPracticesPerIndividual = maximumPracticesPerIndividual
        self.maximumHistoryPerIndividual = maximumHistoryPerIndividual
        self.maximumOperationReceipts = maximumOperationReceipts
        self.maximumParticipantsPerUse = maximumParticipantsPerUse
        self.maximumWitnessesPerUse = maximumWitnessesPerUse
        self.adoptionExposureThreshold = adoptionExposureThreshold
        self.inactivityTicksBeforeDecline = inactivityTicksBeforeDecline
    }

    func validate() throws {
        _ = try Self(
            maximumIndividuals: maximumIndividuals,
            maximumPracticesPerIndividual: maximumPracticesPerIndividual,
            maximumHistoryPerIndividual: maximumHistoryPerIndividual,
            maximumOperationReceipts: maximumOperationReceipts,
            maximumParticipantsPerUse: maximumParticipantsPerUse,
            maximumWitnessesPerUse: maximumWitnessesPerUse,
            adoptionExposureThreshold: adoptionExposureThreshold,
            inactivityTicksBeforeDecline: inactivityTicksBeforeDecline
        )
    }
}

public struct AgentCulturePracticeID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard cultureIdentifierIsValid(rawValue, maximum: 96) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentCultureNormContext: String, Codable, CaseIterable, Sendable {
    case scarcityAid
    case reciprocalWork
}

public enum AgentCultureNormAction: String, Codable, CaseIterable, Sendable {
    case offerBeforePrivateUse
    case reciprocateAfterAid
}

public struct AgentCultureNormPattern: Codable, Equatable, Sendable {
    public let context: AgentCultureNormContext
    public let expectedAction: AgentCultureNormAction

    public init(
        context: AgentCultureNormContext,
        expectedAction: AgentCultureNormAction
    ) {
        self.context = context
        self.expectedAction = expectedAction
    }
}

public enum AgentCultureRitualContext: String, Codable, CaseIterable, Sendable {
    case departure
    case remembrance
    case harvestReturn
}

public enum AgentCultureRitualStep: String, Codable, CaseIterable, Sendable {
    case assemble
    case shareFood
    case speakNames
    case exchangeToken
    case disperse
}

public struct AgentCultureRitualPattern: Codable, Equatable, Sendable {
    public let context: AgentCultureRitualContext
    public let orderedSteps: [AgentCultureRitualStep]
    public let minimumParticipants: Int

    public init(
        context: AgentCultureRitualContext,
        orderedSteps: [AgentCultureRitualStep],
        minimumParticipants: Int = 2
    ) throws {
        guard (2...8).contains(orderedSteps.count),
              (1...8).contains(minimumParticipants),
              minimumParticipants <= orderedSteps.count,
              !zip(orderedSteps, orderedSteps.dropFirst()).contains(where: ==)
        else {
            throw AgentCultureError.invalidPractice("ritual pattern")
        }
        self.context = context
        self.orderedSteps = orderedSteps
        self.minimumParticipants = minimumParticipants
    }

    func validate() throws {
        _ = try Self(
            context: context,
            orderedSteps: orderedSteps,
            minimumParticipants: minimumParticipants
        )
    }
}

/// V1 models an expectation or an ordered communal practice. It deliberately
/// does not model law, recognized rights, religion, belief, or organization.
public enum AgentCulturePracticeForm: Codable, Equatable, Sendable {
    case norm(AgentCultureNormPattern)
    case ritual(AgentCultureRitualPattern)

    var competitionKey: String {
        switch self {
        case let .norm(pattern):
            return "norm|" + pattern.context.rawValue
        case let .ritual(pattern):
            return "ritual|" + pattern.context.rawValue
        }
    }

    var canonicalText: String {
        switch self {
        case let .norm(pattern):
            return "norm|\(pattern.context.rawValue)|\(pattern.expectedAction.rawValue)"
        case let .ritual(pattern):
            return "ritual|\(pattern.context.rawValue)|"
                + pattern.orderedSteps.map(\.rawValue).joined(separator: ",")
                + "|\(pattern.minimumParticipants)"
        }
    }

    func validate() throws {
        if case let .ritual(pattern) = self { try pattern.validate() }
    }
}

/// Immutable identity and lineage are copied into each participating
/// individual's sparse record. There is no global practice registry.
public struct AgentCulturePractice: Codable, Equatable, Sendable {
    public let practiceID: AgentCulturePracticeID
    public let rootPracticeID: AgentCulturePracticeID
    public let parentPracticeID: AgentCulturePracticeID?
    public let generation: Int
    public let form: AgentCulturePracticeForm
    public let originatorID: AgentID
    public let originOperationID: String
}

public enum AgentCultureStanceStatus: String, Codable, CaseIterable, Sendable {
    case exposed
    case adopted
    case rejected
    case ceased
}

public struct AgentCultureStance: Codable, Equatable, Sendable {
    public let practice: AgentCulturePractice
    public internal(set) var status: AgentCultureStanceStatus
    public internal(set) var exposureCount: Int
    public internal(set) var useCount: Int
    public internal(set) var lastExposureTick: Int?
    public internal(set) var lastUseTick: Int?
    public internal(set) var adoptedAtTick: Int?
    public internal(set) var adoptedEventID: AgentCausalEventID?
    public internal(set) var lastTransitionEventID: AgentCausalEventID
}

public enum AgentCultureCarrierReference: Codable, Equatable, Sendable {
    case oral(AgentOralTransmissionID)
    case writingReading(String)
    case archiveRetrieval(String)

    var canonicalText: String {
        switch self {
        case let .oral(id): return "oral|" + id.rawValue
        case let .writingReading(id): return "writing|" + id
        case let .archiveRetrieval(id): return "archive|" + id
        }
    }
}

public enum AgentCultureRecordKind: String, Codable, CaseIterable, Sendable {
    case originated
    case variationCreated
    case exposed
    case considered
    case used
    case continuityReviewed
}

public enum AgentCultureDecisionOutcome: String, Codable, CaseIterable, Sendable {
    case considered
    case adopted
    case rejected
    case continued
    case ceasedUnused
    case ceasedSuperseded
}

/// One record describes one accepted causal transition. A use record is
/// present in the sparse histories of its participants and witnesses so no
/// settlement-level row becomes the owner of their cultural state.
public struct AgentCultureRecord: Codable, Equatable, Sendable {
    public let operationID: String
    public let requestDigest: String
    public let kind: AgentCultureRecordKind
    public let practice: AgentCulturePractice
    public let actorID: AgentID
    public let sourceAgentID: AgentID?
    public let carrier: AgentCultureCarrierReference?
    public let participantIDs: [AgentID]
    public let witnessIDs: [AgentID]
    public let outcome: AgentCultureDecisionOutcome?
    public let competingPracticeID: AgentCulturePracticeID?
    public let tick: Int
    public let eventID: AgentCausalEventID
}

public struct AgentCultureIndividualState: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var stances: [AgentCultureStance]
    public internal(set) var history: [AgentCultureRecord]
}

/// This is an idempotence index only. It cannot answer who holds, uses, or
/// rejects a practice and therefore is not cultural truth.
public struct AgentCultureOperationReceipt: Codable, Equatable, Sendable {
    public let operationID: String
    public let requestDigest: String
    public let eventID: AgentCausalEventID
    public let recordHolderID: AgentID
}

public struct AgentCultureBoundary: Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let digest: String
}

public struct AgentDistributedCultureState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let configuration: AgentCultureConfiguration
    public internal(set) var individuals: [AgentCultureIndividualState]
    public internal(set) var operationReceipts: [AgentCultureOperationReceipt]
    public internal(set) var boundary: AgentCultureBoundary?

    init(configuration: AgentCultureConfiguration) {
        enabled = true
        self.configuration = configuration
        individuals = []
        operationReceipts = []
        boundary = nil
    }
}

public struct AgentCultureSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentCultureConfiguration?
    public let individuals: [AgentCultureIndividualState]
    public let operationReceiptCount: Int
    public let boundary: AgentCultureBoundary?
    public let digest: String
}

public enum AgentCultureProjectionScope: Equatable, Sendable {
    case settlement(AgentSettlementID)
    case household(AgentHouseholdID)
    case house(AgentHouseID)
    case individuals([AgentID])
}

public struct AgentCulturePrevalenceEntry: Equatable, Sendable {
    public let practice: AgentCulturePractice
    public let exposedCount: Int
    public let adoptedCount: Int
    public let rejectedCount: Int
    public let ceasedCount: Int
    public let totalUseCount: Int
}

public struct AgentCultureProjectionMetrics: Equatable, Sendable {
    public let memberCount: Int
    public let culturalIndividualsVisited: Int
    public let stanceRowsVisited: Int
    public let maximumStanceRowsVisited: Int
    public let historicalRowsVisited: Int
}

/// A read-only calculation. It is never Codable session state and no cultural
/// transition accepts it as input.
public struct AgentCulturePrevalenceProjection: Equatable, Sendable {
    public let scope: AgentCultureProjectionScope
    public let memberIDs: [AgentID]
    public let entries: [AgentCulturePrevalenceEntry]
    public let metrics: AgentCultureProjectionMetrics
}

enum AgentCultureDigest {
    static func make(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}

func cultureIdentifierIsValid(_ value: String, maximum: Int) -> Bool {
    !value.isEmpty && value.utf8.prefix(maximum + 1).count <= maximum
        && value.utf8.allSatisfy { byte in
            (65...90).contains(byte) || (97...122).contains(byte)
                || (48...57).contains(byte) || "-_.:/".utf8.contains(byte)
        }
}

func cultureBoundaryDigest(_ state: AgentDistributedCultureState) -> String {
    var committed = state
    committed.boundary = nil
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return AgentCultureDigest.make(String(decoding: try! encoder.encode(committed), as: UTF8.self))
}
