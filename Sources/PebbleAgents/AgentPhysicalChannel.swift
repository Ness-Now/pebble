public enum AgentPhysicalChannelConfigurationError: Error, Equatable {
    case invalidRadius(Int)
    case invalidLifetime(Int)
    case invalidCapacity(Int)
    case invalidOcclusionSamples(Int)
    case invalidThresholds(ambiguous: Int, exact: Int)
}

public struct AgentPhysicalChannelConfiguration: Codable, Equatable {
    public static let live = try! AgentPhysicalChannelConfiguration()

    public let soundRadius: Int
    public let gestureRadius: Int
    public let signalLifetimeTicks: Int
    public let maximumPendingSignals: Int
    public let maximumRetainedPerceptions: Int
    public let maximumOcclusionSamples: Int
    public let exactThreshold: Int
    public let ambiguousThreshold: Int

    public init(
        soundRadius: Int = 12,
        gestureRadius: Int = 8,
        signalLifetimeTicks: Int = 3,
        maximumPendingSignals: Int = 32,
        maximumRetainedPerceptions: Int = 64,
        maximumOcclusionSamples: Int = 24,
        exactThreshold: Int = 70,
        ambiguousThreshold: Int = 40
    ) throws {
        guard soundRadius >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidRadius(soundRadius)
        }
        guard gestureRadius >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidRadius(gestureRadius)
        }
        guard signalLifetimeTicks >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidLifetime(signalLifetimeTicks)
        }
        guard maximumPendingSignals >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidCapacity(maximumPendingSignals)
        }
        guard maximumRetainedPerceptions >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidCapacity(maximumRetainedPerceptions)
        }
        guard maximumOcclusionSamples >= 1 else {
            throw AgentPhysicalChannelConfigurationError.invalidOcclusionSamples(maximumOcclusionSamples)
        }
        guard (0...100).contains(ambiguousThreshold),
              (0...100).contains(exactThreshold),
              ambiguousThreshold < exactThreshold else {
            throw AgentPhysicalChannelConfigurationError.invalidThresholds(
                ambiguous: ambiguousThreshold,
                exact: exactThreshold
            )
        }
        self.soundRadius = soundRadius
        self.gestureRadius = gestureRadius
        self.signalLifetimeTicks = signalLifetimeTicks
        self.maximumPendingSignals = maximumPendingSignals
        self.maximumRetainedPerceptions = maximumRetainedPerceptions
        self.maximumOcclusionSamples = maximumOcclusionSamples
        self.exactThreshold = exactThreshold
        self.ambiguousThreshold = ambiguousThreshold
    }

    /// V1 uses Manhattan distance and a fixed opaque-cell penalty. Greater
    /// distance or occlusion can never improve clarity; no random input exists.
    public func soundClarity(distanceManhattan: Int, opaqueOcclusionCount: Int) -> Int {
        guard distanceManhattan >= 0, distanceManhattan <= soundRadius,
              opaqueOcclusionCount >= 0 else { return 0 }
        return max(0, min(100, 100 - distanceManhattan * 5 - opaqueOcclusionCount * 20))
    }

    /// A pointing gesture is visible only inside its radius with direct LOS.
    public func gestureClarity(distanceManhattan: Int, lineOfSight: Bool) -> Int {
        guard lineOfSight, distanceManhattan >= 0,
              distanceManhattan <= gestureRadius else { return 0 }
        return max(0, min(100, 100 - distanceManhattan * 5))
    }

    public func classify(
        soundClarity: Int,
        gestureClarity: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        isIntendedRecipient: Bool
    ) -> AgentPhysicalPerceptionOutcome {
        guard chunksReady else { return .inconclusive }
        if isIntendedRecipient,
           lineOfSight,
           soundClarity >= exactThreshold,
           gestureClarity >= exactThreshold {
            return .exact
        }
        if soundClarity >= ambiguousThreshold,
           gestureClarity >= ambiguousThreshold {
            return .ambiguous
        }
        return .missed
    }
}

private func physicalIdentifierIsValid(_ rawValue: String) -> Bool {
    (1...512).contains(rawValue.utf8.count)
        && rawValue.utf8.allSatisfy { (33...126).contains($0) }
}

public struct AgentPhysicalSignalID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard physicalIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentPhysicalSignalModality: String, Codable, CaseIterable, Sendable {
    case attentionSound
    case pointingGesture
}

public enum AgentPhysicalSignalStatus: String, Codable, Sendable {
    case pending
    case decoded
    case ambiguous
    case missed
    case expired
    case cancelled
}

public enum AgentPhysicalPerceptionOutcome: String, Codable, CaseIterable, Sendable {
    case exact
    case ambiguous
    case missed
    case inconclusive
}

public struct AgentPhysicalSignal: Codable, Equatable {
    public let signalID: AgentPhysicalSignalID
    public let senderID: AgentID
    public let intendedRecipientID: AgentID
    public let factID: AgentSocialFactID
    public let directObservationEventID: AgentCausalEventID
    public let sourcePosition: AgentPosition
    public let pointedPosition: AgentPosition
    public let resource: AgentResourceKind
    public let expectedBlockFingerprint: Int
    public let emittedAtTick: Int
    public let expiresAtTick: Int
    public let emittedEventID: AgentCausalEventID
    public let modalities: [AgentPhysicalSignalModality]
    public internal(set) var status: AgentPhysicalSignalStatus
}

/// Raw, deterministic evidence supplied by a physical adapter. The kernel
/// derives the outcome and never trusts the adapter to create social meaning.
public struct AgentPhysicalSignalObservation: Codable, Equatable {
    public let signalID: AgentPhysicalSignalID
    public let observerID: AgentID
    public let distanceManhattan: Int
    public let soundClarity: Int
    public let gestureClarity: Int
    public let opaqueOcclusionCount: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let observedAtTick: Int

    public init(
        signalID: AgentPhysicalSignalID,
        observerID: AgentID,
        distanceManhattan: Int,
        soundClarity: Int,
        gestureClarity: Int,
        opaqueOcclusionCount: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        observedAtTick: Int
    ) {
        self.signalID = signalID
        self.observerID = observerID
        self.distanceManhattan = distanceManhattan
        self.soundClarity = soundClarity
        self.gestureClarity = gestureClarity
        self.opaqueOcclusionCount = opaqueOcclusionCount
        self.lineOfSight = lineOfSight
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
    }
}

public struct AgentPhysicalPerception: Codable, Equatable {
    public let signalID: AgentPhysicalSignalID
    public let observerID: AgentID
    public let isIntendedRecipient: Bool
    public let distanceManhattan: Int
    public let soundClarity: Int
    public let gestureClarity: Int
    public let opaqueOcclusionCount: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let outcome: AgentPhysicalPerceptionOutcome
    public let observedAtTick: Int
    public let perceivedEventID: AgentCausalEventID
    public let decodedEventID: AgentCausalEventID?
}

public struct AgentPhysicalPresentationRequest: Codable, Equatable {
    public let signalID: AgentPhysicalSignalID
    public let senderID: AgentID
    public let sourcePosition: AgentPosition
    public let pointedPosition: AgentPosition
    public let emittedAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var presentedAtTick: Int?
}

public struct AgentPhysicalEvictionCounts: Codable, Equatable {
    public internal(set) var signals: Int
    public internal(set) var perceptions: Int
    public internal(set) var presentations: Int

    public init(signals: Int = 0, perceptions: Int = 0, presentations: Int = 0) {
        self.signals = signals
        self.perceptions = perceptions
        self.presentations = presentations
    }
}

public struct AgentPhysicalChannelSnapshot: Codable, Equatable {
    public let enabled: Bool
    public let tick: Int
    public let configuration: AgentPhysicalChannelConfiguration
    public let signals: [AgentPhysicalSignal]
    public let perceptions: [AgentPhysicalPerception]
    public let presentations: [AgentPhysicalPresentationRequest]
    public let evictionCounts: AgentPhysicalEvictionCounts
    public let physicalCausalEventCount: Int
    public let decodedMessageCount: Int
    public let digest: String
}

public struct AgentPhysicalChannelSummary: Codable, Equatable {
    public let enabled: Bool
    public let pendingSignalCount: Int
    public let retainedSignalCount: Int
    public let retainedPerceptionCount: Int
    public let exactCount: Int
    public let ambiguousCount: Int
    public let missedCount: Int
    public let inconclusiveCount: Int
    public let expiredCount: Int
    public let decodedMessageCount: Int
    public let physicalCausalEventCount: Int
    public let evictionCounts: AgentPhysicalEvictionCounts
    public let digest: String
}

public enum AgentPhysicalChannelError: Error, Equatable {
    case causalLedgerRequired
    case socialRequired
    case channelDisabled
    case unknownSignal(String)
    case unknownObserver(String)
    case invalidObservation(String)
    case duplicateObservation(String)
}
