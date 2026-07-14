public enum AgentSocialConfigurationError: Error, Equatable {
    case invalidCommunicationRadius(Int)
    case invalidTrustThreshold(Int)
    case invalidTrustDelta(Int)
    case invalidTrustBounds(Int, Int)
    case invalidLifetime(Int)
    case invalidCapacity(Int)
    case invalidShareCooldown(Int)
}

public struct AgentSocialConfiguration: Codable, Equatable {
    public static let live = try! AgentSocialConfiguration()

    public let communicationRadius: Int
    public let minimumTrustToVerify: Int
    public let confirmedTrustDelta: Int
    public let contradictedTrustDelta: Int
    public let minimumTrust: Int
    public let maximumTrust: Int
    public let claimLifetimeTicks: Int
    public let messageLifetimeTicks: Int
    public let maximumFactsPerAgent: Int
    public let maximumBeliefsPerAgent: Int
    public let maximumTrustRelations: Int
    public let maximumRetainedMessages: Int
    public let shareCooldownTicks: Int

    public init(
        communicationRadius: Int = 8,
        minimumTrustToVerify: Int = -20,
        confirmedTrustDelta: Int = 10,
        contradictedTrustDelta: Int = -15,
        minimumTrust: Int = -100,
        maximumTrust: Int = 100,
        claimLifetimeTicks: Int = 12,
        messageLifetimeTicks: Int = 8,
        maximumFactsPerAgent: Int = 8,
        maximumBeliefsPerAgent: Int = 8,
        maximumTrustRelations: Int = 32,
        maximumRetainedMessages: Int = 32,
        shareCooldownTicks: Int = 8
    ) throws {
        guard (1...AgentResourcePerception.maximumDistance).contains(communicationRadius) else {
            throw AgentSocialConfigurationError.invalidCommunicationRadius(communicationRadius)
        }
        guard minimumTrust < maximumTrust else {
            throw AgentSocialConfigurationError.invalidTrustBounds(minimumTrust, maximumTrust)
        }
        guard (minimumTrust...maximumTrust).contains(minimumTrustToVerify) else {
            throw AgentSocialConfigurationError.invalidTrustThreshold(minimumTrustToVerify)
        }
        guard confirmedTrustDelta > 0, contradictedTrustDelta < 0 else {
            throw AgentSocialConfigurationError.invalidTrustDelta(
                confirmedTrustDelta == 0 ? contradictedTrustDelta : confirmedTrustDelta
            )
        }
        guard claimLifetimeTicks >= 1, messageLifetimeTicks >= 1 else {
            throw AgentSocialConfigurationError.invalidLifetime(
                min(claimLifetimeTicks, messageLifetimeTicks)
            )
        }
        let capacities = [
            maximumFactsPerAgent, maximumBeliefsPerAgent,
            maximumTrustRelations, maximumRetainedMessages,
        ]
        guard capacities.allSatisfy({ $0 >= 1 }) else {
            throw AgentSocialConfigurationError.invalidCapacity(capacities.min() ?? 0)
        }
        guard shareCooldownTicks >= 1 else {
            throw AgentSocialConfigurationError.invalidShareCooldown(shareCooldownTicks)
        }
        self.communicationRadius = communicationRadius
        self.minimumTrustToVerify = minimumTrustToVerify
        self.confirmedTrustDelta = confirmedTrustDelta
        self.contradictedTrustDelta = contradictedTrustDelta
        self.minimumTrust = minimumTrust
        self.maximumTrust = maximumTrust
        self.claimLifetimeTicks = claimLifetimeTicks
        self.messageLifetimeTicks = messageLifetimeTicks
        self.maximumFactsPerAgent = maximumFactsPerAgent
        self.maximumBeliefsPerAgent = maximumBeliefsPerAgent
        self.maximumTrustRelations = maximumTrustRelations
        self.maximumRetainedMessages = maximumRetainedMessages
        self.shareCooldownTicks = shareCooldownTicks
    }
}

public enum AgentSocialError: Error, Equatable {
    case causalLedgerRequired
    case socialDisabled
    case invalidIdentifier(String)
    case unknownFact(String)
    case unknownBelief(String)
    case invalidVerification(String)
    case forwardingProhibited(String)
}

private protocol AgentSocialIdentifier {
    var rawValue: String { get }
    init?(rawValue: String)
}

private func isValidSocialIdentifier(_ value: String) -> Bool {
    (1...512).contains(value.utf8.count) && value.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentSocialFactID: RawRepresentable, Codable, Hashable, Comparable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidSocialIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentSocialMessageID: RawRepresentable, Codable, Hashable, Comparable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidSocialIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentSocialBeliefID: RawRepresentable, Codable, Hashable, Comparable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidSocialIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentTrustRelationID: RawRepresentable, Codable, Hashable, Comparable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard isValidSocialIdentifier(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentSocialFact: Codable, Equatable {
    public let factID: AgentSocialFactID
    public let observerID: AgentID
    public let resource: AgentResourceKind
    public let position: AgentPosition
    public let source: AgentResourceObservationSource
    public let stableKey: String
    public let expectedBlockFingerprint: Int
    public let observedAtTick: Int
    public let expiresAtTick: Int
    public let directObservationEventID: AgentCausalEventID

    init(
        factID: AgentSocialFactID,
        observerID: AgentID,
        resource: AgentResourceKind,
        position: AgentPosition,
        stableKey: String,
        expectedBlockFingerprint: Int,
        observedAtTick: Int,
        expiresAtTick: Int,
        directObservationEventID: AgentCausalEventID
    ) {
        self.factID = factID
        self.observerID = observerID
        self.resource = resource
        self.position = position
        source = .naturalWorld
        self.stableKey = stableKey
        self.expectedBlockFingerprint = expectedBlockFingerprint
        self.observedAtTick = observedAtTick
        self.expiresAtTick = expiresAtTick
        self.directObservationEventID = directObservationEventID
    }

    public func isExpired(at tick: Int) -> Bool { tick > expiresAtTick }
}

public enum AgentSocialMessageStatus: String, Codable, Equatable {
    case received
    case expired
    case ignored
}

public struct AgentSocialMessage: Codable, Equatable {
    public let messageID: AgentSocialMessageID
    public let senderID: AgentID
    public let recipientID: AgentID
    public let fact: AgentSocialFact
    public let sentAtTick: Int
    public let receivedAtTick: Int
    public let expiresAtTick: Int
    public let sentEventID: AgentCausalEventID
    public let receivedEventID: AgentCausalEventID
    public internal(set) var status: AgentSocialMessageStatus
}

public enum AgentSocialBeliefStatus: String, Codable, Equatable, CaseIterable {
    case unverified
    case confirmed
    case contradicted
    case expired
    case ignored
}

public struct AgentSocialBelief: Codable, Equatable {
    public let beliefID: AgentSocialBeliefID
    public let ownerID: AgentID
    public let senderID: AgentID
    public let fact: AgentSocialFact
    public let messageID: AgentSocialMessageID
    public let directProvenanceEventID: AgentCausalEventID
    public let receivedEventID: AgentCausalEventID
    public let receivedAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var status: AgentSocialBeliefStatus
    public internal(set) var verifiedAtTick: Int?
    public internal(set) var verificationEventID: AgentCausalEventID?
    public internal(set) var reason: String
}

public struct AgentTrustRelation: Codable, Equatable {
    public let relationID: AgentTrustRelationID
    public let sourceID: AgentID
    public let targetID: AgentID
    public internal(set) var score: Int
    public internal(set) var confirmationCount: Int
    public internal(set) var contradictionCount: Int
    public internal(set) var lastChangedAtTick: Int
    public internal(set) var lastChangeEventID: AgentCausalEventID?
}

public enum AgentSocialVerificationResult: String, Codable, Equatable {
    case confirmed
    case contradicted
    case inconclusive
}

public struct AgentSocialVerificationRequest: Codable, Equatable {
    public let beliefID: AgentSocialBeliefID
    public let verifierID: AgentID
    public let senderID: AgentID
    public let resource: AgentResourceKind
    public let position: AgentPosition
    public let expectedBlockFingerprint: Int
}

public struct AgentSocialVerificationObservation: Codable, Equatable {
    public let beliefID: AgentSocialBeliefID
    public let verifierID: AgentID
    public let position: AgentPosition
    public let chunkReady: Bool
    public let observedBlockFingerprint: Int?
    public let observedResource: AgentResourceKind?

    public init(
        beliefID: AgentSocialBeliefID,
        verifierID: AgentID,
        position: AgentPosition,
        chunkReady: Bool,
        observedBlockFingerprint: Int? = nil,
        observedResource: AgentResourceKind? = nil
    ) {
        self.beliefID = beliefID
        self.verifierID = verifierID
        self.position = position
        self.chunkReady = chunkReady
        self.observedBlockFingerprint = observedBlockFingerprint
        self.observedResource = observedResource
    }
}

public struct AgentSocialEvictionCounts: Codable, Equatable {
    public internal(set) var facts = 0
    public internal(set) var messages = 0
    public internal(set) var beliefs = 0
    public internal(set) var trustRelations = 0
    public init() {}
}

public struct AgentSocialSnapshot: Codable, Equatable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentSocialConfiguration
    public let facts: [AgentSocialFact]
    public let messages: [AgentSocialMessage]
    public let beliefs: [AgentSocialBelief]
    public let trustRelations: [AgentTrustRelation]
    public let activeVerifications: [AgentSocialVerificationRequest]
    public let evictionCounts: AgentSocialEvictionCounts
    public let socialCausalEventCount: Int
    public let digest: String
}

public struct AgentSocialSummary: Codable, Equatable {
    public let enabled: Bool
    public let retainedMessageCount: Int
    public let unverifiedBeliefCount: Int
    public let confirmedBeliefCount: Int
    public let contradictedBeliefCount: Int
    public let expiredBeliefCount: Int
    public let ignoredBeliefCount: Int
    public let activeVerificationCount: Int
    public let trustEdgeCount: Int
    public let socialCausalEventCount: Int
    public let evictionCounts: AgentSocialEvictionCounts
    public let digest: String
}

public struct AgentTrustSnapshot: Codable, Equatable {
    public let relations: [AgentTrustRelation]
    public let digest: String
}

enum AgentSocialDigest {
    static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
