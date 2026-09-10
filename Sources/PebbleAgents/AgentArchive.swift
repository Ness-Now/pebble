import Foundation

public enum AgentArchiveError: Error, Equatable {
    case invalidState(String)
    case capacityReached(String)
    case unavailable(String)
}

/// CIV-46 retains bounded catalogue history only. The material inscription
/// remains CIV-45/Core authority and all epistemic effects remain CIV-41-owned.
public struct AgentArchiveConfiguration: Codable, Equatable, Sendable {
    public static let live = try! Self()

    public let maximumCollections: Int
    public let maximumManuscripts: Int
    public let maximumRetrievals: Int
    public let maximumSearchResults: Int

    public init(
        maximumCollections: Int = 64,
        maximumManuscripts: Int = 512,
        maximumRetrievals: Int = 512,
        maximumSearchResults: Int = 64
    ) throws {
        guard (1...1024).contains(maximumCollections),
              (1...4096).contains(maximumManuscripts),
              (1...4096).contains(maximumRetrievals),
              (1...256).contains(maximumSearchResults),
              maximumSearchResults <= maximumManuscripts else {
            throw AgentArchiveError.invalidState("archive capacities")
        }
        self.maximumCollections = maximumCollections
        self.maximumManuscripts = maximumManuscripts
        self.maximumRetrievals = maximumRetrievals
        self.maximumSearchResults = maximumSearchResults
    }
}

public struct AgentArchiveCollectionID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard archiveIdentifierIsValid(rawValue, maximum: 96) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentArchiveManuscriptID:
    RawRepresentable, Codable, Hashable, Comparable, Sendable
{
    public let rawValue: String

    public init?(rawValue: String) {
        guard archiveIdentifierIsValid(rawValue, maximum: 96) else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// These are bounded catalogue scopes, not CIV-47 institutions or culture.
public enum AgentArchiveCollectionKind: String, Codable, CaseIterable, Sendable {
    case manuscriptRegister
    case archive
    case library
}

/// A relationship never replaces either immutable CIV-45 artifact. It only
/// appends a causal continuity statement between two separately identified
/// material inscriptions.
public enum AgentArchiveRelationship: Codable, Equatable, Sendable {
    case source
    case facsimile(parent: AgentArchiveManuscriptID)
    case revision(parent: AgentArchiveManuscriptID)

    public var parentID: AgentArchiveManuscriptID? {
        switch self {
        case .source: return nil
        case let .facsimile(parent), let .revision(parent): return parent
        }
    }

    var indexKey: String {
        switch self {
        case .source: return "source"
        case .facsimile: return "facsimile"
        case .revision: return "revision"
        }
    }
}

/// Historical proof that an adapter observed one exact CIV-45 material carrier
/// while Core authority was held. It deliberately omits lines and semantic
/// content, so it cannot recreate or authorize a lost inscription.
public struct AgentArchiveMaterialWitness: Codable, Equatable, Sendable {
    public let worldID: String
    public let dimension: String
    public let cell: AgentPosition
    public let artifactID: String
    public let materialID: Int
    public let contentDigest: String
    public let observerID: AgentID
    public let observedAtTick: Int

    init(_ receipt: AgentWritingPhysicalReceipt) {
        worldID = receipt.worldID
        dimension = receipt.dimension
        cell = receipt.cell
        artifactID = receipt.artifactID
        materialID = receipt.materialID
        contentDigest = receipt.contentDigest
        observerID = receipt.actorID
        observedAtTick = receipt.observedAtTick
    }
}

public struct AgentArchiveCollection: Codable, Equatable, Sendable {
    public let collectionID: AgentArchiveCollectionID
    public let operationID: String
    public let kind: AgentArchiveCollectionKind
    /// The collection's material access mark is an ordinary CIV-45 artifact.
    /// Losing it removes agent search access but does not erase history.
    public let catalogueArtifactID: String
    public let curatorID: AgentID
    public let materialWitness: AgentArchiveMaterialWitness
    public let createdAtTick: Int
    public let creationEventID: AgentCausalEventID
}

public struct AgentArchiveManuscript: Codable, Equatable, Sendable {
    public let manuscriptID: AgentArchiveManuscriptID
    public let operationID: String
    public let collectionID: AgentArchiveCollectionID
    public let artifactID: String
    public let relationship: AgentArchiveRelationship
    public let rootArtifactID: String
    public let generation: Int
    public let cataloguerID: AgentID
    public let materialWitness: AgentArchiveMaterialWitness
    public let registeredAtTick: Int
    public let registrationEventID: AgentCausalEventID
}

public struct AgentArchiveRetrieval: Codable, Equatable, Sendable {
    public let operationID: String
    public let manuscriptID: AgentArchiveManuscriptID
    public let collectionID: AgentArchiveCollectionID
    public let artifactID: String
    public let readerID: AgentID
    public let indexRevision: UInt64
    public let indexSourceDigest: String
    public let writingReadingID: String
    public let retrievedAtTick: Int
    public let retrievalEventID: AgentCausalEventID
}

public struct AgentArchiveBoundary: Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let digest: String
}

public struct AgentArchiveState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let worldID: String
    public let configuration: AgentArchiveConfiguration
    public internal(set) var collections: [AgentArchiveCollection]
    public internal(set) var manuscripts: [AgentArchiveManuscript]
    public internal(set) var retrievals: [AgentArchiveRetrieval]
    /// A derived commitment used only to reject stale indexes in O(1).
    /// Restore validation recomputes it from collections and manuscripts.
    public internal(set) var indexRevision: UInt64
    public internal(set) var indexSourceDigest: String
    public internal(set) var boundary: AgentArchiveBoundary?

    init(worldID: String, configuration: AgentArchiveConfiguration) {
        enabled = true
        self.worldID = worldID
        self.configuration = configuration
        collections = []
        manuscripts = []
        retrievals = []
        indexRevision = 1
        indexSourceDigest = ""
        boundary = nil
        indexSourceDigest = archiveIndexSourceDigest(self)
    }
}

public enum AgentArchiveSearchQuery: Equatable, Sendable {
    case collection(AgentArchiveCollectionID)
    case artifact(String)
    case lineageRoot(String)
    case author(AgentID)
    case proposition(AgentKnowledgePropositionID)
    case question(String)
    case relationship(String)

    var key: String {
        switch self {
        case let .collection(id): return "collection|" + id.rawValue
        case let .artifact(id): return "artifact|" + id
        case let .lineageRoot(id): return "lineage|" + id
        case let .author(id): return "author|" + id.rawValue
        case let .proposition(id): return "proposition|" + id.rawValue
        case let .question(key): return "question|" + key
        case let .relationship(value): return "relationship|" + value
        }
    }

    /// Validates caller-controlled query text with a fixed-prefix scan before
    /// constructing or hashing the posting key.
    var boundedKey: String? {
        let value: String
        switch self {
        case let .collection(id): value = id.rawValue
        case let .artifact(id), let .lineageRoot(id): value = id
        case let .author(id): value = id.rawValue
        case let .proposition(id): value = id.rawValue
        case let .question(question): value = question
        case let .relationship(relationship): value = relationship
        }
        guard !value.isEmpty,
              value.utf8.prefix(513).count <= 512 else {
            return nil
        }
        let postingKey = key
        guard postingKey.utf8.count <= 512 else { return nil }
        return postingKey
    }
}

public struct AgentArchiveSelection: Codable, Equatable, Sendable {
    public let manuscriptID: AgentArchiveManuscriptID
    public let collectionID: AgentArchiveCollectionID
    public let artifactID: String
    public let indexRevision: UInt64
    public let indexSourceDigest: String

    init(entry: AgentArchiveIndexEntry, index: AgentArchiveIndex) {
        manuscriptID = entry.manuscriptID
        collectionID = entry.collectionID
        artifactID = entry.artifactID
        indexRevision = index.sourceRevision
        indexSourceDigest = index.sourceDigest
    }
}

/// Discovery metadata only. It contains no lines, proposition value, belief,
/// understanding, evidence, or authority capable of restoring lost content.
public struct AgentArchiveIndexEntry: Equatable, Sendable {
    public let manuscriptID: AgentArchiveManuscriptID
    public let collectionID: AgentArchiveCollectionID
    public let artifactID: String
    public let materialID: Int
    public let rootArtifactID: String
    public let generation: Int
    public let relationship: String
    public let authorID: AgentID
    public let dimension: String
    public let cell: AgentPosition
    public let registeredAtTick: Int
}

public struct AgentArchiveIndexMetrics: Equatable, Sendable {
    public let writingArtifactsVisited: Int
    public let collectionsVisited: Int
    public let manuscriptsVisited: Int
    public let postingsEmitted: Int
    public let maximumPossiblePostings: Int
}

public struct AgentArchiveIndex: Equatable, Sendable {
    public let sourceRevision: UInt64
    public let sourceDigest: String
    public let metrics: AgentArchiveIndexMetrics
    let postings: [String: [AgentArchiveIndexEntry]]

    init(
        sourceRevision: UInt64,
        sourceDigest: String,
        metrics: AgentArchiveIndexMetrics,
        postings: [String: [AgentArchiveIndexEntry]]
    ) {
        self.sourceRevision = sourceRevision
        self.sourceDigest = sourceDigest
        self.metrics = metrics
        self.postings = postings
    }
}

public struct AgentArchiveSearchMetrics: Equatable, Sendable {
    public let globalRecordsScanned: Int
    public let postingEntriesVisited: Int
    public let maximumPostingEntriesVisited: Int
}

public struct AgentArchiveSearchHit: Equatable, Sendable {
    public let entry: AgentArchiveIndexEntry
    public let selection: AgentArchiveSelection
}

public struct AgentArchiveSearchResult: Equatable, Sendable {
    public let query: AgentArchiveSearchQuery
    public let hits: [AgentArchiveSearchHit]
    public let totalMatches: Int
    public let truncated: Bool
    public let metrics: AgentArchiveSearchMetrics
}

public struct AgentArchiveRetrievalResult: Equatable, Sendable {
    public let archiveRecord: AgentArchiveRetrieval
    public let writingReading: AgentWritingReading

    public init(
        archiveRecord: AgentArchiveRetrieval,
        writingReading: AgentWritingReading
    ) {
        self.archiveRecord = archiveRecord
        self.writingReading = writingReading
    }
}

public struct AgentArchiveSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentArchiveConfiguration?
    public let collections: [AgentArchiveCollection]
    public let manuscripts: [AgentArchiveManuscript]
    public let retrievals: [AgentArchiveRetrieval]
    public let indexRevision: UInt64
    public let indexSourceDigest: String
    public let boundary: AgentArchiveBoundary?
    public let digest: String
}

private struct AgentArchiveIndexSource: Codable {
    let worldID: String
    let configuration: AgentArchiveConfiguration
    let collections: [AgentArchiveCollection]
    let manuscripts: [AgentArchiveManuscript]
}

func archiveIndexSourceDigest(_ state: AgentArchiveState) -> String {
    writingDigest(AgentArchiveIndexSource(
        worldID: state.worldID,
        configuration: state.configuration,
        collections: state.collections,
        manuscripts: state.manuscripts
    ))
}

func archiveBoundaryDigest(_ state: AgentArchiveState) -> String {
    var committed = state
    committed.boundary = nil
    return writingDigest(committed)
}

func archiveIdentifierIsValid(_ value: String, maximum: Int) -> Bool {
    !value.isEmpty && value.utf8.prefix(maximum + 1).count <= maximum
        && value.allSatisfy { character in
            character.isASCII && (character.isLetter || character.isNumber
                || "-_.:/|".contains(character))
        }
}
