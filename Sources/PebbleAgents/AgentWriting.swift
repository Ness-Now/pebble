import CryptoKit
import Foundation

public enum AgentWritingError: Error, Equatable {
    case invalidState(String)
    case capacityReached(String)
    case unavailable(String)
}

/// V1 retains inscriptions and accepted readings. Admission refuses at capacity;
/// ordinary communication, terminal-belief and causal FIFO eviction cannot erase
/// material content. There is no archive, catalogue or global retrieval service.
public struct AgentWritingConfiguration: Codable, Equatable, Sendable {
    public static let live = try! Self()
    public let maximumArtifacts: Int
    public let maximumReadings: Int
    public let maximumLiteracyRecords: Int
    public init(maximumArtifacts: Int = 256, maximumReadings: Int = 512,
                maximumLiteracyRecords: Int = 512) throws {
        guard (1...4096).contains(maximumArtifacts),
              (1...4096).contains(maximumReadings),
              (1...4096).contains(maximumLiteracyRecords) else {
            throw AgentWritingError.invalidState("writing capacities")
        }
        self.maximumArtifacts = maximumArtifacts
        self.maximumReadings = maximumReadings
        self.maximumLiteracyRecords = maximumLiteracyRecords
    }
}

/// A fresh local observation from Pebble, or the exact recorded observation on
/// historical replay. This is an adapter input, never a cognitive World lookup.
public struct AgentWritingPhysicalReceipt: Codable, Equatable, Sendable {
    public let worldID: String
    public let dimension: String
    public let cell: AgentPosition
    public let blockKey: String
    public let artifactID: String
    public let materialID: Int
    public let contentDigest: String
    public let lines: [String]
    public let actorID: AgentID
    public let actorPosition: AgentPosition
    public let observedAtTick: Int
    public init(worldID: String, dimension: String, cell: AgentPosition,
                blockKey: String, artifactID: String, materialID: Int, contentDigest: String,
                lines: [String], actorID: AgentID, actorPosition: AgentPosition,
                observedAtTick: Int) {
        self.worldID = worldID; self.dimension = dimension; self.cell = cell
        self.blockKey = blockKey; self.artifactID = artifactID
        self.materialID = materialID
        self.contentDigest = contentDigest; self.lines = lines
        self.actorID = actorID; self.actorPosition = actorPosition
        self.observedAtTick = observedAtTick
    }
}

/// Prepared without mutation. Its accepted CIV-42 realization is replay input;
/// neither restore nor replay asks a provider to generate historical content.
public enum AgentWritingAssertion: Codable, Equatable, Sendable {
    case beliefReport
    /// An explicit choice to assert a supported alternative to an actually
    /// held source belief. This creates neither a private belief nor evidence.
    case deliberateCounterAssertion(AgentKnowledgeValue)
}

public struct AgentWritingPlan: Codable, Equatable, Sendable {
    public let artifactID: String
    public let materialID: Int
    public let ordinal: UInt64
    public let worldID: String
    public let dimension: String
    public let cell: AgentPosition
    public let authorID: AgentID
    public let sourceBeliefID: AgentKnowledgeBeliefID
    public let sourcePropositionID: AgentKnowledgePropositionID
    public let assertion: AgentWritingAssertion
    public let assertedProposition: AgentKnowledgeProposition
    public let sourceRevisionEventID: AgentCausalEventID
    public let realization: AgentLanguageRealization
    public let lines: [String]
    public let preparedAtTick: Int
    public var contentDigest: String { writingDigest(self) }
}

public struct AgentWrittenArtifact: Codable, Equatable, Sendable {
    public let plan: AgentWritingPlan
    public let sourceAuthorityID: AgentKnowledgeHistoricalBeliefAuthorityID
    public let literacy: AgentLanguageLiteracyReceipt
    public let physicalReceipt: AgentWritingPhysicalReceipt
    public let inscriptionEventID: AgentCausalEventID
    public var artifactID: String { plan.artifactID }
}

public struct AgentWritingReading: Codable, Equatable, Sendable {
    public let readingID: String
    public let artifactID: String
    public let readerID: AgentID
    public let literacy: AgentLanguageLiteracyReceipt
    public let physicalReceipt: AgentWritingPhysicalReceipt
    public let accessEventID: AgentCausalEventID
    public let readingEventID: AgentCausalEventID
    public let claimID: AgentKnowledgeClaimID
    public let claimEventID: AgentCausalEventID
    /// CIV-41 owns this historical acquisition even after current cognition,
    /// terminal beliefs or their event bodies have compacted.
    public let recipientAuthorityID: AgentKnowledgeHistoricalBeliefAuthorityID
}

public struct AgentWritingBoundary: Codable, Equatable, Sendable {
    public let eventID: AgentCausalEventID
    public let digest: String
}

public struct AgentWritingState: Codable, Equatable, Sendable {
    public internal(set) var enabled: Bool
    public let worldID: String
    public let configuration: AgentWritingConfiguration
    public internal(set) var literacyRecords: [AgentWritingLiteracyRecord]
    /// Historical accepted inscriptions; presence is never inferred from these rows.
    public internal(set) var artifacts: [AgentWrittenArtifact]
    public internal(set) var readings: [AgentWritingReading]
    public internal(set) var boundary: AgentWritingBoundary?
    public internal(set) var nextArtifactOrdinal: UInt64
    public internal(set) var nextReadingOrdinal: UInt64

    init(worldID: String, configuration: AgentWritingConfiguration) {
        enabled = true; self.worldID = worldID; self.configuration = configuration
        literacyRecords = []
        artifacts = []; readings = []; boundary = nil
        nextArtifactOrdinal = 1; nextReadingOrdinal = 1
    }
}

func writingDigest<T: Encodable>(_ value: T) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    // All callers pass closed Codable value types with finite scalar fields.
    let data = try! encoder.encode(value)
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

func writingBoundaryDigest(_ state: AgentWritingState) -> String {
    var committed = state
    committed.boundary = nil
    return writingDigest(committed)
}
