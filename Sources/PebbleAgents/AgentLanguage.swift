import CryptoKit
import Foundation

public enum AgentLanguageConfigurationError: Error, Equatable {
    case invalidCapacity(String, Int)
}

public struct AgentLanguageConfiguration: Codable, Equatable, Sendable {
    public static let live = try! AgentLanguageConfiguration()

    public let maximumLexicalAssociations: Int
    public let maximumLexicalAssociationsPerAgent: Int
    public let maximumCommunicationRecords: Int
    public let exposuresRequiredForLearning: Int

    public init(
        maximumLexicalAssociations: Int = 4_096,
        maximumLexicalAssociationsPerAgent: Int = 32,
        maximumCommunicationRecords: Int = 4_096,
        exposuresRequiredForLearning: Int = 2
    ) throws {
        let global = [
            ("lexicalAssociations", maximumLexicalAssociations),
            ("communicationRecords", maximumCommunicationRecords),
        ]
        for (name, value) in global where !(1...65_536).contains(value) {
            throw AgentLanguageConfigurationError.invalidCapacity(name, value)
        }
        guard (1...256).contains(maximumLexicalAssociationsPerAgent) else {
            throw AgentLanguageConfigurationError.invalidCapacity(
                "lexicalAssociationsPerAgent",
                maximumLexicalAssociationsPerAgent
            )
        }
        guard (1...32).contains(exposuresRequiredForLearning) else {
            throw AgentLanguageConfigurationError.invalidCapacity(
                "exposuresRequiredForLearning",
                exposuresRequiredForLearning
            )
        }
        self.maximumLexicalAssociations = maximumLexicalAssociations
        self.maximumLexicalAssociationsPerAgent =
            maximumLexicalAssociationsPerAgent
        self.maximumCommunicationRecords = maximumCommunicationRecords
        self.exposuresRequiredForLearning = exposuresRequiredForLearning
    }
}

public enum AgentLanguageError: Error, Equatable {
    case causalLedgerRequired
    case knowledgeRequired
    case disabled
    case unknownAgent(String)
    case unknownProposition(String)
    case missingBeliefAuthority(String)
    case unsupportedSemantics(String)
    case invalidIdentifier(String)
    case invalidPack(String)
    case missingLexicalKnowledge(String)
    case capacityReached(String)
    case invalidState(String)
}

private func isValidLanguageIdentifier(
    _ value: String,
    maximum: Int = 192
) -> Bool {
    (1...maximum).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

func isValidLanguageText(_ value: String, maximum: Int) -> Bool {
    (1...maximum).contains(value.utf8.count)
        && value.unicodeScalars.allSatisfy {
            $0.value >= 0x20 && $0.value != 0x7f
        }
}

public struct AgentLanguagePackID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidLanguageIdentifier(rawValue, maximum: 96) else {
            return nil
        }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentLanguageSenseID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidLanguageIdentifier(rawValue, maximum: 128) else {
            return nil
        }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentLanguageAssociationID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidLanguageIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentLanguageCommunicationID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidLanguageIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentLanguageLexicalEntry:
    Codable, Equatable, Hashable, Sendable {
    public let senseID: AgentLanguageSenseID
    public let form: String

    public init(senseID: AgentLanguageSenseID, form: String) throws {
        guard isValidLanguageText(form, maximum: 64) else {
            throw AgentLanguageError.invalidPack("invalid lexical form")
        }
        self.senseID = senseID
        self.form = form
    }
}

/// Replaceable linguistic seed/prior data. A pack supplies lexical forms; it
/// is not an agent belief, a World fact, or gameplay authority.
public struct AgentLanguagePack: Codable, Equatable, Sendable {
    public static let frenchReference = try! AgentLanguagePack(
        packID: AgentLanguagePackID(rawValue: "pebble.fr.reference.v1")!,
        languageTag: "fr",
        version: "1",
        provenance: "Pebble CIV-42 project-authored reference seed",
        license: "Repository project license; no external dataset",
        entries: [
            try! AgentLanguageLexicalEntry(
                senseID: AgentLanguageSenseID(rawValue: "referent.worldCell")!,
                form: "cellule"
            ),
            try! AgentLanguageLexicalEntry(
                senseID: AgentLanguageSenseID(
                    rawValue: "predicate.world.resource.presence"
                )!,
                form: "est présent à"
            ),
            try! AgentLanguageLexicalEntry(
                senseID: AgentLanguageSenseID(rawValue: "value.resource.wood")!,
                form: "bois"
            ),
            try! AgentLanguageLexicalEntry(
                senseID: AgentLanguageSenseID(rawValue: "value.resource.stone")!,
                form: "pierre"
            ),
            try! AgentLanguageLexicalEntry(
                senseID: AgentLanguageSenseID(rawValue: "value.absent")!,
                form: "aucune ressource"
            ),
        ]
    )

    /// A valid pack with no lexical prior. It demonstrates that semantic
    /// communication and NO_RENDERING do not depend on French data.
    public static let semanticOnly = try! AgentLanguagePack(
        packID: AgentLanguagePackID(rawValue: "pebble.semantic-only.v1")!,
        languageTag: "und",
        version: "1",
        provenance: "Pebble CIV-42 language-independent semantic path",
        license: "Repository project license; no external dataset",
        entries: []
    )

    public let packID: AgentLanguagePackID
    public let languageTag: String
    public let version: String
    public let provenance: String
    public let license: String
    public let entries: [AgentLanguageLexicalEntry]

    public init(
        packID: AgentLanguagePackID,
        languageTag: String,
        version: String,
        provenance: String,
        license: String,
        entries: [AgentLanguageLexicalEntry]
    ) throws {
        guard isValidLanguageIdentifier(languageTag, maximum: 32),
              isValidLanguageIdentifier(version, maximum: 32),
              isValidLanguageText(provenance, maximum: 256),
              isValidLanguageText(license, maximum: 256),
              entries.count <= 256,
              Set(entries.map(\.senseID)).count == entries.count else {
            throw AgentLanguageError.invalidPack(packID.rawValue)
        }
        self.packID = packID
        self.languageTag = languageTag
        self.version = version
        self.provenance = provenance
        self.license = license
        self.entries = entries.sorted { $0.senseID < $1.senseID }
    }

    func entry(for senseID: AgentLanguageSenseID) -> AgentLanguageLexicalEntry? {
        entries.first { $0.senseID == senseID }
    }
}

public enum AgentLanguageSenseRole:
    String, Codable, CaseIterable, Comparable, Sendable {
    case referentKind
    case predicate
    case value

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let order: [Self] = [.referentKind, .predicate, .value]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

public struct AgentLanguageSenseUse:
    Codable, Equatable, Hashable, Sendable {
    public let role: AgentLanguageSenseRole
    public let senseID: AgentLanguageSenseID
}

/// Language-independent semantic content for the bounded CIV-42 proposition
/// adapter. It references CIV-41's authoritative proposition identity and
/// carries only language senses plus a referent, never a belief or truth row.
public struct AgentLanguageSemanticContent:
    Codable, Equatable, Hashable, Sendable {
    public let sourcePropositionID: AgentKnowledgePropositionID
    public let referent: AgentKnowledgeEntity
    public let senses: [AgentLanguageSenseUse]
    public let digest: String

    init(
        sourcePropositionID: AgentKnowledgePropositionID,
        referent: AgentKnowledgeEntity,
        senses: [AgentLanguageSenseUse]
    ) {
        self.sourcePropositionID = sourcePropositionID
        self.referent = referent
        self.senses = senses.sorted { $0.role < $1.role }
        digest = AgentLanguageDigest.make(
            "\(sourcePropositionID.rawValue)|\(referent.canonicalText)|"
                + self.senses.map {
                    "\($0.role.rawValue):\($0.senseID.rawValue)"
                }.joined(separator: ",")
        )
    }
}

public enum AgentLanguageRenderingMode: String, Codable, Sendable {
    case noRendering
    case deterministicCompositional
}

public enum AgentLanguageSurfaceRealization:
    Codable, Equatable, Sendable {
    case noRendering
    case deterministic(text: String)

    public var text: String? {
        if case let .deterministic(text) = self { return text }
        return nil
    }
}

public struct AgentLanguageLexicalUse:
    Codable, Equatable, Hashable, Sendable {
    public let role: AgentLanguageSenseRole
    public let senseID: AgentLanguageSenseID
    public let form: String
}

public enum AgentLanguageLexicalAssociationSource:
    String, Codable, Sendable {
    case seededPrior
    case exposure
}

public enum AgentLanguageLexicalCompetence:
    String, Codable, Sendable {
    case acquiring
    case known
}

public struct AgentLanguageLexicalAssociation:
    Codable, Equatable, Sendable {
    public let associationID: AgentLanguageAssociationID
    public let ownerID: AgentID
    public let packID: AgentLanguagePackID
    public let senseID: AgentLanguageSenseID
    public let form: String
    public let source: AgentLanguageLexicalAssociationSource
    public internal(set) var competence: AgentLanguageLexicalCompetence
    public internal(set) var exposureCount: Int
    public let firstAcquiredAtTick: Int
    public internal(set) var lastExposedAtTick: Int
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentLanguageCommunication:
    Codable, Equatable, Sendable {
    public let communicationID: AgentLanguageCommunicationID
    public let speakerID: AgentID
    public let recipientID: AgentID
    public let sourceBeliefID: AgentKnowledgeBeliefID
    public let sourceBeliefRevisionEventID: AgentCausalEventID
    public let semanticContent: AgentLanguageSemanticContent
    public let rendering: AgentLanguageSurfaceRealization
    public let lexicalUses: [AgentLanguageLexicalUse]
    public let exposedAssociationIDs: [AgentLanguageAssociationID]
    public let newlyLearnedSenseIDs: [AgentLanguageSenseID]
    public let communicatedAtTick: Int
    public let communicationEventID: AgentCausalEventID
}

public struct AgentLanguageRealization: Codable, Equatable, Sendable {
    public let semanticContent: AgentLanguageSemanticContent
    public let rendering: AgentLanguageSurfaceRealization
    public let lexicalUses: [AgentLanguageLexicalUse]
}

public struct AgentLanguageGraphState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let configuration: AgentLanguageConfiguration
    public let pack: AgentLanguagePack
    public internal(set) var lexicalAssociations:
        [AgentLanguageLexicalAssociation]
    public internal(set) var communications: [AgentLanguageCommunication]
    public internal(set) var evictedCommunicationCount: Int
    public internal(set) var retiredLexicalAssociationCount: Int
    public internal(set) var nextCommunicationOrdinal: UInt64

    init(
        configuration: AgentLanguageConfiguration,
        pack: AgentLanguagePack
    ) {
        enabled = true
        self.configuration = configuration
        self.pack = pack
        lexicalAssociations = []
        communications = []
        evictedCommunicationCount = 0
        retiredLexicalAssociationCount = 0
        nextCommunicationOrdinal = 1
    }
}

public struct AgentLanguageSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentLanguageConfiguration?
    public let pack: AgentLanguagePack?
    public let lexicalAssociations: [AgentLanguageLexicalAssociation]
    public let communications: [AgentLanguageCommunication]
    public let evictedCommunicationCount: Int
    public let retiredLexicalAssociationCount: Int
    public let digest: String
}

public struct AgentLanguageSummary: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let lexicalAssociationCount: Int
    public let knownAssociationCount: Int
    public let acquiringAssociationCount: Int
    public let communicationCount: Int
    public let evictedCommunicationCount: Int
    public let retiredLexicalAssociationCount: Int
    public let digest: String
}

enum AgentLanguageDigest {
    static func make(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}
