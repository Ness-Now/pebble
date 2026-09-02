import CryptoKit
import Foundation

public enum AgentOralConfigurationError: Error, Equatable {
    case invalidCapacity(Int)
    case invalidFaithfulDistance(Int)
}

/// CIV-43 owns only the bounded provenance of an oral hop. CIV-41 remains the
/// authority for propositions, understandings, and beliefs; CIV-42 remains
/// the authority for semantic communication and lexical exposure.
public struct AgentOralConfiguration: Codable, Equatable, Sendable {
    public static let live = try! AgentOralConfiguration()

    public let maximumTransmissionRecords: Int
    public let maximumFaithfulDistance: Int

    public init(
        maximumTransmissionRecords: Int = 2_048,
        maximumFaithfulDistance: Int = 1
    ) throws {
        guard (1...65_536).contains(maximumTransmissionRecords) else {
            throw AgentOralConfigurationError.invalidCapacity(
                maximumTransmissionRecords
            )
        }
        guard (0...AgentResourcePerception.maximumDistance).contains(
            maximumFaithfulDistance
        ) else {
            throw AgentOralConfigurationError.invalidFaithfulDistance(
                maximumFaithfulDistance
            )
        }
        self.maximumTransmissionRecords = maximumTransmissionRecords
        self.maximumFaithfulDistance = maximumFaithfulDistance
    }
}

public enum AgentOralError: Error, Equatable {
    case causalLedgerRequired
    case socialRequired
    case knowledgeRequired
    case languageRequired
    case disabled
    case unknownAgent(String)
    case invalidParticipant(String)
    case migratingParticipant(String)
    case localAuthorityRefused(String)
    case nonLocal(distance: Int, radius: Int)
    case unsupportedSemantics(String)
    case missingAuthority(String)
    case capacityReached(String)
    case replayEffectMismatch(String)
    case invalidState(String)
}

private func isValidOralIdentifier(_ value: String) -> Bool {
    (1...192).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentOralTransmissionID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidOralIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum AgentOralTransmissionOutcome:
    String, Codable, CaseIterable, Sendable {
    case faithful
    case distanceDistorted
}

public struct AgentOralLocalityEvidence: Codable, Equatable, Sendable {
    public let speakerPosition: AgentPosition
    public let recipientPosition: AgentPosition
    public let distance: Int
    public let authorizedRadius: Int
    public let observedAtTick: Int
}

/// The accepted semantic result is journaled. Replay verifies its commitment
/// against authoritative hop inputs and applies it without selecting again.
public struct AgentOralAcceptedEffect: Codable, Equatable, Sendable {
    public let interpretedProposition: AgentKnowledgeProposition
    public let interpretedSemanticContent: AgentLanguageSemanticContent
    public let outcome: AgentOralTransmissionOutcome
    public let decisionDigest: String

    public init(
        interpretedProposition: AgentKnowledgeProposition,
        interpretedSemanticContent: AgentLanguageSemanticContent,
        outcome: AgentOralTransmissionOutcome,
        decisionDigest: String
    ) {
        self.interpretedProposition = interpretedProposition
        self.interpretedSemanticContent = interpretedSemanticContent
        self.outcome = outcome
        self.decisionDigest = decisionDigest
    }
}

public struct AgentOralTransmission: Codable, Equatable, Sendable {
    public let transmissionID: AgentOralTransmissionID
    public let speakerID: AgentID
    public let recipientID: AgentID
    public let sourceBeliefID: AgentKnowledgeBeliefID
    public let sourceBeliefRevisionEventID: AgentCausalEventID
    public let sourceAuthorityID: AgentKnowledgeHistoricalBeliefAuthorityID
    public let languageCommunicationID: AgentLanguageCommunicationID
    public let languageCommunicationEventID: AgentCausalEventID
    public let transmittedSemanticContent: AgentLanguageSemanticContent
    public let interpretedSemanticContent: AgentLanguageSemanticContent
    public let outcome: AgentOralTransmissionOutcome
    public let decisionDigest: String
    public let locality: AgentOralLocalityEvidence
    public let receiptEventID: AgentCausalEventID
    public let recipientClaimID: AgentKnowledgeClaimID
    public let recipientClaimEventID: AgentCausalEventID
    public let recipientUnderstandingID: AgentKnowledgeUnderstandingID
    public let recipientBeliefID: AgentKnowledgeBeliefID
    public let recipientBeliefRevisionEventID: AgentCausalEventID
    public let transmittedAtTick: Int
    public let provenanceDigest: String
}

/// One retained event independently commits the exact bounded set. A dropped
/// causal prefix is never accepted as sufficient proof on its own.
public struct AgentOralProvenanceBoundary:
    Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let digest: String
}

public struct AgentOralTransmissionState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let configuration: AgentOralConfiguration
    public internal(set) var transmissions: [AgentOralTransmission]
    public internal(set) var evictedTransmissionCount: Int
    public internal(set) var nextTransmissionOrdinal: UInt64
    public internal(set) var provenanceBoundary: AgentOralProvenanceBoundary?

    init(configuration: AgentOralConfiguration) {
        enabled = true
        self.configuration = configuration
        transmissions = []
        evictedTransmissionCount = 0
        nextTransmissionOrdinal = 1
        provenanceBoundary = nil
    }
}

public struct AgentOralSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentOralConfiguration?
    public let transmissions: [AgentOralTransmission]
    public let evictedTransmissionCount: Int
    public let provenanceBoundary: AgentOralProvenanceBoundary?
    public let digest: String
}

public struct AgentOralSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let transmissionCount: Int
    public let faithfulCount: Int
    public let distortedCount: Int
    public let evictedTransmissionCount: Int
    public let digest: String
}

enum AgentOralDigest {
    static func make(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }

    static func selector(_ text: String, modulo: Int) -> Int {
        precondition(modulo > 0)
        let digest = SHA256.hash(data: Data(text.utf8))
        return Int(Array(digest)[0]) % modulo
    }
}
