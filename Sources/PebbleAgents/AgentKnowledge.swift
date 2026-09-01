import CryptoKit
import Foundation

public enum AgentKnowledgeConfigurationError: Error, Equatable {
    case invalidCapacity(String, Int)
}

public struct AgentKnowledgeConfiguration: Codable, Equatable, Sendable {
    public static let live = try! AgentKnowledgeConfiguration()

    public let maximumPropositions: Int
    public let maximumEvidence: Int
    public let maximumClaims: Int
    public let maximumUnderstandings: Int
    public let maximumBeliefs: Int
    public let maximumRevisions: Int
    public let maximumEvidencePerAgent: Int
    public let maximumClaimsPerAgent: Int
    public let maximumUnderstandingsPerAgent: Int
    public let maximumBeliefsPerAgent: Int
    public let maximumRevisionsPerAgent: Int

    /// Departed beliefs are immutable historical evidence, not current
    /// cognition. Reusing the global current-belief bound keeps the V1 graph
    /// shape compatible while ensuring generational history is finite.
    public var maximumDepartedBeliefs: Int { maximumBeliefs }

    public init(
        maximumPropositions: Int = 4_096,
        maximumEvidence: Int = 4_096,
        maximumClaims: Int = 4_096,
        maximumUnderstandings: Int = 4_096,
        maximumBeliefs: Int = 4_096,
        maximumRevisions: Int = 4_096,
        maximumEvidencePerAgent: Int = 16,
        maximumClaimsPerAgent: Int = 16,
        maximumUnderstandingsPerAgent: Int = 16,
        maximumBeliefsPerAgent: Int = 16,
        maximumRevisionsPerAgent: Int = 32
    ) throws {
        let global = [
            ("propositions", maximumPropositions),
            ("evidence", maximumEvidence),
            ("claims", maximumClaims),
            ("understandings", maximumUnderstandings),
            ("beliefs", maximumBeliefs),
            ("revisions", maximumRevisions),
        ]
        for (name, value) in global where !(1...65_536).contains(value) {
            throw AgentKnowledgeConfigurationError.invalidCapacity(name, value)
        }
        let perAgent = [
            ("evidencePerAgent", maximumEvidencePerAgent),
            ("claimsPerAgent", maximumClaimsPerAgent),
            ("understandingsPerAgent", maximumUnderstandingsPerAgent),
            ("beliefsPerAgent", maximumBeliefsPerAgent),
            ("revisionsPerAgent", maximumRevisionsPerAgent),
        ]
        for (name, value) in perAgent where !(1...256).contains(value) {
            throw AgentKnowledgeConfigurationError.invalidCapacity(name, value)
        }
        self.maximumPropositions = maximumPropositions
        self.maximumEvidence = maximumEvidence
        self.maximumClaims = maximumClaims
        self.maximumUnderstandings = maximumUnderstandings
        self.maximumBeliefs = maximumBeliefs
        self.maximumRevisions = maximumRevisions
        self.maximumEvidencePerAgent = maximumEvidencePerAgent
        self.maximumClaimsPerAgent = maximumClaimsPerAgent
        self.maximumUnderstandingsPerAgent = maximumUnderstandingsPerAgent
        self.maximumBeliefsPerAgent = maximumBeliefsPerAgent
        self.maximumRevisionsPerAgent = maximumRevisionsPerAgent
    }
}

public enum AgentKnowledgeError: Error, Equatable {
    case causalLedgerRequired
    case disabled
    case socialRequired
    case unknownAgent(String)
    case invalidIdentifier(String)
    case missingProvenance(String)
    case capacityReached(String)
    case invalidState(String)
}

private func isValidKnowledgeIdentifier(_ value: String, maximum: Int = 192) -> Bool {
    (1...maximum).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentKnowledgePropositionID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentKnowledgeEvidenceID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentKnowledgeClaimID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentKnowledgeUnderstandingID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentKnowledgeBeliefID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentKnowledgeRevisionID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentKnowledgeEntityKind: String, Codable, CaseIterable, Sendable {
    case agent
    case settlement
    case worldCell
    case material
    case civilizationRecord
}

public struct AgentKnowledgeEntity: Codable, Equatable, Hashable, Sendable {
    public let kind: AgentKnowledgeEntityKind
    public let key: String

    public init(kind: AgentKnowledgeEntityKind, key: String) throws {
        guard isValidKnowledgeIdentifier(key) else {
            throw AgentKnowledgeError.invalidIdentifier(key)
        }
        self.kind = kind
        self.key = key
    }

    var canonicalText: String { "\(kind.rawValue):\(key)" }
}

public struct AgentKnowledgePredicate:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidKnowledgeIdentifier(rawValue, maximum: 96) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentKnowledgeValue: Codable, Equatable, Hashable, Sendable {
    case absent
    case flag(Bool)
    case integer(Int)
    case entity(AgentKnowledgeEntity)
    case position(AgentPosition)
    case resource(kind: AgentResourceKind, fingerprint: Int?)

    var canonicalText: String {
        switch self {
        case .absent:
            return "absent"
        case let .flag(value):
            return "flag:\(value ? 1 : 0)"
        case let .integer(value):
            return "integer:\(value)"
        case let .entity(value):
            return "entity:\(value.canonicalText)"
        case let .position(value):
            return "position:\(value.x),\(value.y),\(value.z)"
        case let .resource(kind, fingerprint):
            return "resource:\(kind.rawValue):\(fingerprint.map(String.init) ?? "unknown")"
        }
    }
}

public struct AgentKnowledgeProposition: Codable, Equatable, Hashable, Sendable {
    public let propositionID: AgentKnowledgePropositionID
    public let subject: AgentKnowledgeEntity
    public let predicate: AgentKnowledgePredicate
    public let value: AgentKnowledgeValue
    public let questionKey: String

    public init(
        subject: AgentKnowledgeEntity,
        predicate: AgentKnowledgePredicate,
        value: AgentKnowledgeValue
    ) {
        self.subject = subject
        self.predicate = predicate
        self.value = value
        questionKey = "\(subject.canonicalText)|\(predicate.rawValue)"
        propositionID = AgentKnowledgePropositionID(
            rawValue: "proposition-" + AgentKnowledgeDigest.make(
                "\(questionKey)|\(value.canonicalText)"
            )
        )!
    }
}

public enum AgentKnowledgeEvidenceAuthority: String, Codable, CaseIterable, Sendable {
    case validatedWorldObservation
    case validatedSocialVerification
    case canonicalCivilizationState
}

public struct AgentKnowledgeEvidence: Codable, Equatable, Sendable {
    public let evidenceID: AgentKnowledgeEvidenceID
    public let observerID: AgentID
    public let propositionID: AgentKnowledgePropositionID
    public let authority: AgentKnowledgeEvidenceAuthority
    public let authorityEventID: AgentCausalEventID
    public let acquisitionEventID: AgentCausalEventID
    public let acquiredAtTick: Int
}

public struct AgentKnowledgeSourceClaim: Codable, Equatable, Sendable {
    public let claimID: AgentKnowledgeClaimID
    public let propositionID: AgentKnowledgePropositionID
    public let sourceAgentID: AgentID
    public let recipientID: AgentID
    public let sourceEvidenceID: AgentKnowledgeEvidenceID
    public let socialMessageID: AgentSocialMessageID
    public let sentEventID: AgentCausalEventID
    public let receivedEventID: AgentCausalEventID
    public let acquisitionEventID: AgentCausalEventID
    public let receivedAtTick: Int
}

public enum AgentKnowledgeUnderstandingBasis: Codable, Equatable, Hashable, Sendable {
    case evidence(AgentKnowledgeEvidenceID)
    case sourceClaim(AgentKnowledgeClaimID)

    var canonicalText: String {
        switch self {
        case let .evidence(id): return "evidence:\(id.rawValue)"
        case let .sourceClaim(id): return "claim:\(id.rawValue)"
        }
    }
}

public enum AgentKnowledgeInterpretation: String, Codable, CaseIterable, Sendable {
    case directlyObserved
    case acceptedAsAsserted
    case revisedByContradictoryObservation
}

public struct AgentKnowledgeUnderstanding: Codable, Equatable, Sendable {
    public let understandingID: AgentKnowledgeUnderstandingID
    public let ownerID: AgentID
    public let propositionID: AgentKnowledgePropositionID
    public let basis: AgentKnowledgeUnderstandingBasis
    public let interpretation: AgentKnowledgeInterpretation
    public let formedAtTick: Int
    public let formedEventID: AgentCausalEventID
}

public enum AgentKnowledgeBeliefStance: String, Codable, CaseIterable, Sendable {
    case accepted
    case rejected
    case uncertain
}

public struct AgentKnowledgeBelief: Codable, Equatable, Sendable {
    public let beliefID: AgentKnowledgeBeliefID
    public let ownerID: AgentID
    public let questionKey: String
    public internal(set) var propositionID: AgentKnowledgePropositionID
    public internal(set) var stance: AgentKnowledgeBeliefStance
    public internal(set) var basisUnderstandingID: AgentKnowledgeUnderstandingID
    public let formedAtTick: Int
    public internal(set) var updatedAtTick: Int
    public internal(set) var revisionCount: Int
    public internal(set) var lastRevisionEventID: AgentCausalEventID
}

public struct AgentKnowledgeBeliefRevision: Codable, Equatable, Sendable {
    public let revisionID: AgentKnowledgeRevisionID
    public let beliefID: AgentKnowledgeBeliefID
    public let ownerID: AgentID
    public let questionKey: String
    public let previousPropositionID: AgentKnowledgePropositionID?
    public let previousStance: AgentKnowledgeBeliefStance?
    public let propositionID: AgentKnowledgePropositionID
    public let stance: AgentKnowledgeBeliefStance
    public let triggerUnderstandingID: AgentKnowledgeUnderstandingID
    public let revisedAtTick: Int
    public let revisionEventID: AgentCausalEventID
}

public enum AgentKnowledgeDepartedBeliefBasis:
    Codable, Equatable, Sendable {
    case evidence(
        evidenceID: AgentKnowledgeEvidenceID,
        authority: AgentKnowledgeEvidenceAuthority,
        authorityEventID: AgentCausalEventID,
        acquisitionEventID: AgentCausalEventID
    )
    case sourceClaim(
        claimID: AgentKnowledgeClaimID,
        sourceAgentID: AgentID,
        sourceEvidenceID: AgentKnowledgeEvidenceID,
        sourceEvidenceAuthority: AgentKnowledgeEvidenceAuthority,
        sourceEvidenceAuthorityEventID: AgentCausalEventID,
        sourceEvidenceAcquisitionEventID: AgentCausalEventID,
        socialMessageID: AgentSocialMessageID,
        sentEventID: AgentCausalEventID,
        receivedEventID: AgentCausalEventID,
        acquisitionEventID: AgentCausalEventID
    )

    var canonicalText: String {
        switch self {
        case let .evidence(evidenceID, authority, authorityEventID, acquisitionEventID):
            return "evidence:\(evidenceID.rawValue):\(authority.rawValue):"
                + "\(authorityEventID.rawValue):\(acquisitionEventID.rawValue)"
        case let .sourceClaim(
            claimID, sourceAgentID, sourceEvidenceID,
            sourceEvidenceAuthority, sourceEvidenceAuthorityEventID,
            sourceEvidenceAcquisitionEventID, socialMessageID,
            sentEventID, receivedEventID, acquisitionEventID
        ):
            return "claim:\(claimID.rawValue):\(sourceAgentID.rawValue):"
                + "\(sourceEvidenceID.rawValue):\(sourceEvidenceAuthority.rawValue):"
                + "\(sourceEvidenceAuthorityEventID.rawValue):"
                + "\(sourceEvidenceAcquisitionEventID.rawValue):"
                + "\(socialMessageID.rawValue):\(sentEventID.rawValue):"
                + "\(receivedEventID.rawValue):\(acquisitionEventID.rawValue)"
        }
    }
}

/// A self-contained, immutable terminal account of one belief at the
/// authoritative mortality boundary. It preserves what the departed owner
/// believed and why without pinning live understandings, claims, or evidence.
public struct AgentKnowledgeDepartedBelief: Codable, Equatable, Sendable {
    public let beliefID: AgentKnowledgeBeliefID
    public let ownerID: AgentID
    public let deathID: AgentDeathID
    public let proposition: AgentKnowledgeProposition
    public let stance: AgentKnowledgeBeliefStance
    public let basisUnderstandingID: AgentKnowledgeUnderstandingID
    public let interpretation: AgentKnowledgeInterpretation
    public let understandingFormedEventID: AgentCausalEventID
    public let basis: AgentKnowledgeDepartedBeliefBasis
    public let formedAtTick: Int
    public let updatedAtTick: Int
    public let revisionCount: Int
    public let lastRevisionEventID: AgentCausalEventID
    public let departedAtTick: Int
    public let deathEventID: AgentCausalEventID
}

public struct AgentKnowledgeEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var propositions = 0
    public internal(set) var evidence = 0
    public internal(set) var claims = 0
    public internal(set) var understandings = 0
    public internal(set) var revisions = 0
    public init() {}
}

public struct AgentKnowledgeGraphState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let configuration: AgentKnowledgeConfiguration
    public internal(set) var propositions: [AgentKnowledgeProposition]
    public internal(set) var evidence: [AgentKnowledgeEvidence]
    public internal(set) var claims: [AgentKnowledgeSourceClaim]
    public internal(set) var understandings: [AgentKnowledgeUnderstanding]
    public internal(set) var beliefs: [AgentKnowledgeBelief]
    public internal(set) var revisions: [AgentKnowledgeBeliefRevision]
    public internal(set) var evictionCounts: AgentKnowledgeEvictionCounts
    /// Optional only for byte-compatible decoding of the reviewed pre-
    /// correction schema-36 candidate. New graphs always initialize it.
    public internal(set) var departedBeliefs: [AgentKnowledgeDepartedBelief]?
    public internal(set) var departedBeliefEvictionCount: Int?

    init(configuration: AgentKnowledgeConfiguration) {
        enabled = true
        self.configuration = configuration
        propositions = []
        evidence = []
        claims = []
        understandings = []
        beliefs = []
        revisions = []
        evictionCounts = AgentKnowledgeEvictionCounts()
        departedBeliefs = []
        departedBeliefEvictionCount = 0
    }
}

public struct AgentKnowledgeDisagreement: Codable, Equatable, Sendable {
    public let questionKey: String
    public let beliefIDs: [AgentKnowledgeBeliefID]
    public let ownerIDs: [AgentID]
    public let propositionIDs: [AgentKnowledgePropositionID]
    public let stances: [AgentKnowledgeBeliefStance]
}

public struct AgentKnowledgeSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentKnowledgeConfiguration?
    public let propositions: [AgentKnowledgeProposition]
    public let evidence: [AgentKnowledgeEvidence]
    public let claims: [AgentKnowledgeSourceClaim]
    public let understandings: [AgentKnowledgeUnderstanding]
    public let beliefs: [AgentKnowledgeBelief]
    public let revisions: [AgentKnowledgeBeliefRevision]
    public let departedBeliefs: [AgentKnowledgeDepartedBelief]
    public let departedBeliefEvictionCount: Int
    public let disagreements: [AgentKnowledgeDisagreement]
    public let evictionCounts: AgentKnowledgeEvictionCounts
    public let digest: String
}

public struct AgentKnowledgeSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let propositionCount: Int
    public let directEvidenceCount: Int
    public let sourceClaimCount: Int
    public let understandingCount: Int
    public let currentBeliefCount: Int
    public let departedBeliefCount: Int
    public let departedBeliefEvictionCount: Int
    public let disagreementCount: Int
    public let revisionCount: Int
    public let evictionCounts: AgentKnowledgeEvictionCounts
    public let digest: String
}

enum AgentKnowledgeDigest {
    static func make(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}
