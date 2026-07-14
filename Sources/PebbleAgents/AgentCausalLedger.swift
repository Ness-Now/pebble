public enum AgentCausalLedgerPolicy: Equatable, Sendable {
    case disabled
    case bounded(maxEvents: Int)
}

public enum AgentCausalLedgerError: Error, Equatable {
    case invalidBound(Int)
    case sequenceOverflow
    case payloadMismatch(AgentCausalEventKind)
    case tooManyCauses(Int)
    case duplicateCause(AgentCausalEventID)
    case crossSimulationCause(AgentCausalEventID)
    case nonPriorCause(AgentCausalEventID)
}

public struct AgentCausalSequence: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: UInt64

    public init?(rawValue: UInt64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }

    public static func < (lhs: AgentCausalSequence, rhs: AgentCausalSequence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentCausalEventID: Codable, Hashable, Comparable, Sendable {
    public let simulationID: AgentSimulationID
    public let sequence: AgentCausalSequence

    public init(simulationID: AgentSimulationID, sequence: AgentCausalSequence) {
        self.simulationID = simulationID
        self.sequence = sequence
    }

    public var rawValue: String {
        let digits = String(sequence.rawValue)
        let padded = String(repeating: "0", count: max(0, 20 - digits.count)) + digits
        return "\(simulationID.rawValue)/event-\(padded)"
    }

    public static func < (lhs: AgentCausalEventID, rhs: AgentCausalEventID) -> Bool {
        if lhs.simulationID != rhs.simulationID { return lhs.simulationID < rhs.simulationID }
        return lhs.sequence < rhs.sequence
    }
}

public enum AgentCausalEventKind: String, Codable, CaseIterable, Sendable {
    case sessionLifecycle
    case featureToggle
    case perception
    case goalTransition
    case actionSelected
    case tickCompleted
    case movement
    case interaction
    case delivery
    case consumption
    case constructionFunding
    case constructionPlacement
    case constructionCompletion
    case constructionClear
    case resourceFactGrounded
    case socialMessageSent
    case socialMessageReceived
    case socialBeliefChanged
    case socialVerification
    case trustChanged
    case socialStateCleared
}

public enum AgentCausalOrigin: String, Codable, Sendable {
    case session
    case externalObservation
    case cognitiveTransition
    case worldOutcome
    case controllerCommand
    case lifecycle
    case socialTransition
}

public enum AgentCausalPayload: Codable, Equatable, Sendable {
    case lifecycle(status: String, agentCount: Int)
    case feature(name: String, enabled: Bool)
    case perception(worldObserved: Bool, resourceObservationCount: Int, memoriesAdded: Int)
    case cognitive(goal: String, action: String, goalChanged: Bool)
    case movement(status: String, from: AgentPosition, to: AgentPosition)
    case operation(status: String, detail: String)
    case resourceFact(
        factID: String,
        observerID: String,
        resource: AgentResourceKind,
        position: AgentPosition,
        fingerprint: Int
    )
    case socialMessage(messageID: String, factID: String, status: String)
    case socialBelief(beliefID: String, messageID: String, status: String, reason: String)
    case socialVerification(
        beliefID: String,
        expectedFingerprint: Int,
        observedFingerprint: Int?,
        result: String
    )
    case trust(relationID: String, before: Int, delta: Int, after: Int)
    case socialClear(facts: Int, messages: Int, beliefs: Int, trustRelations: Int)

    var canonicalText: String {
        switch self {
        case let .lifecycle(status, agentCount):
            return "lifecycle|\(status)|\(agentCount)"
        case let .feature(name, enabled):
            return "feature|\(name)|\(enabled ? 1 : 0)"
        case let .perception(worldObserved, resourceObservationCount, memoriesAdded):
            return "perception|\(worldObserved ? 1 : 0)|\(resourceObservationCount)|\(memoriesAdded)"
        case let .cognitive(goal, action, goalChanged):
            return "cognitive|\(goal)|\(action)|\(goalChanged ? 1 : 0)"
        case let .movement(status, from, to):
            return "movement|\(status)|\(from.x),\(from.y),\(from.z)|\(to.x),\(to.y),\(to.z)"
        case let .operation(status, detail):
            return "operation|\(status)|\(detail)"
        case let .resourceFact(factID, observerID, resource, position, fingerprint):
            return "resourceFact|\(factID)|\(observerID)|\(resource.rawValue)|\(position.x),\(position.y),\(position.z)|\(fingerprint)"
        case let .socialMessage(messageID, factID, status):
            return "socialMessage|\(messageID)|\(factID)|\(status)"
        case let .socialBelief(beliefID, messageID, status, reason):
            return "socialBelief|\(beliefID)|\(messageID)|\(status)|\(reason)"
        case let .socialVerification(
            beliefID, expectedFingerprint, observedFingerprint, result
        ):
            return "socialVerification|\(beliefID)|\(expectedFingerprint)|\(observedFingerprint.map(String.init) ?? "none")|\(result)"
        case let .trust(relationID, before, delta, after):
            return "trust|\(relationID)|\(before)|\(delta)|\(after)"
        case let .socialClear(facts, messages, beliefs, trustRelations):
            return "socialClear|\(facts)|\(messages)|\(beliefs)|\(trustRelations)"
        }
    }
}

public struct AgentCausalEvent: Codable, Equatable, Sendable {
    public static let maximumCauseCount = 8
    public let schemaVersion: Int
    public let eventID: AgentCausalEventID
    public let simulationID: AgentSimulationID
    public let sequence: AgentCausalSequence
    public let simulationTick: AgentSimulationTick
    public let instant: AgentSimulationInstant
    public let kind: AgentCausalEventKind
    public let origin: AgentCausalOrigin
    public let actorID: AgentID?
    public let subjectID: AgentID?
    public let operationID: AgentOperationID?
    public let causes: [AgentCausalEventID]
    public let payload: AgentCausalPayload
    public let summary: String
    public let digest: String

    init(
        id: AgentCausalEventID,
        instant: AgentSimulationInstant,
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID?,
        subjectID: AgentID?,
        operationID: AgentOperationID?,
        causes: [AgentCausalEventID],
        payload: AgentCausalPayload,
        summary: String
    ) throws {
        try Self.validate(payload: payload, for: kind)
        try Self.validate(causes: causes, for: id)
        schemaVersion = 1
        eventID = id
        simulationID = instant.simulationID
        sequence = id.sequence
        simulationTick = instant.tick
        self.instant = instant
        self.kind = kind
        self.origin = origin
        self.actorID = actorID
        self.subjectID = subjectID
        self.operationID = operationID
        self.causes = causes
        self.payload = payload
        self.summary = String(summary.prefix(160))
        digest = Self.digest(
            "\(id.rawValue)|\(instant.tick.rawValue)|\(kind.rawValue)|\(origin.rawValue)|"
                + "\(actorID?.rawValue ?? "-")|\(subjectID?.rawValue ?? "-")|"
                + "\(operationID?.rawValue ?? "-")|"
                + causes.map(\.rawValue).joined(separator: ",")
                + "|\(payload.canonicalText)|\(self.summary)"
        )
    }

    public static func validate(
        payload: AgentCausalPayload,
        for kind: AgentCausalEventKind
    ) throws {
        let matches: Bool
        switch (kind, payload) {
        case (.sessionLifecycle, .lifecycle), (.tickCompleted, .lifecycle),
             (.featureToggle, .feature), (.perception, .perception),
             (.goalTransition, .cognitive), (.actionSelected, .cognitive),
             (.movement, .movement), (.interaction, .operation),
             (.delivery, .operation), (.consumption, .operation),
             (.constructionFunding, .operation), (.constructionPlacement, .operation),
             (.constructionCompletion, .operation), (.constructionClear, .operation),
             (.resourceFactGrounded, .resourceFact),
             (.socialMessageSent, .socialMessage),
             (.socialMessageReceived, .socialMessage),
             (.socialBeliefChanged, .socialBelief),
             (.socialVerification, .socialVerification),
             (.trustChanged, .trust),
             (.socialStateCleared, .socialClear):
            matches = true
        default:
            matches = false
        }
        guard matches else { throw AgentCausalLedgerError.payloadMismatch(kind) }
    }

    public static func validate(
        causes: [AgentCausalEventID],
        for eventID: AgentCausalEventID
    ) throws {
        guard causes.count <= maximumCauseCount else {
            throw AgentCausalLedgerError.tooManyCauses(causes.count)
        }
        var prior: AgentCausalEventID?
        for cause in causes {
            guard cause.simulationID == eventID.simulationID else {
                throw AgentCausalLedgerError.crossSimulationCause(cause)
            }
            guard cause.sequence < eventID.sequence else {
                throw AgentCausalLedgerError.nonPriorCause(cause)
            }
            if prior == cause { throw AgentCausalLedgerError.duplicateCause(cause) }
            prior = cause
        }
        guard causes == causes.sorted() else {
            throw AgentCausalLedgerError.nonPriorCause(causes[0])
        }
    }

    static func digest(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: 16 - digits.count) + digits
    }
}

public struct AgentCausalLedgerSummary: Codable, Equatable, Sendable {
    public let simulationID: AgentSimulationID
    public let currentTick: AgentSimulationTick
    public let latestSequence: UInt64
    public let nextSequence: UInt64?
    public let retainedEventCount: Int
    public let droppedEventCount: UInt64
    public let firstRetainedEventID: AgentCausalEventID?
    public let lastRetainedEventID: AgentCausalEventID?
    public let retainedCauseCoverageComplete: Bool
    public let digest: String
}

public struct AgentCausalLedgerSnapshot: Codable, Equatable, Sendable {
    public let summary: AgentCausalLedgerSummary
    public let events: [AgentCausalEvent]
}

struct AgentCausalLedger {
    let policy: AgentCausalLedgerPolicy
    private(set) var events: [AgentCausalEvent] = []
    private(set) var latestSequence: UInt64 = 0
    private(set) var droppedEventCount: UInt64 = 0
    private(set) var rollingDigest = AgentCausalEvent.digest("")

    var isEnabled: Bool {
        if case .bounded = policy { return true }
        return false
    }

    init(policy: AgentCausalLedgerPolicy) throws {
        if case let .bounded(maxEvents) = policy, maxEvents <= 0 {
            throw AgentCausalLedgerError.invalidBound(maxEvents)
        }
        self.policy = policy
    }

    func prevalidateAppend(count: Int) throws {
        guard case .bounded = policy else { return }
        guard count >= 0, UInt64(count) <= UInt64.max - latestSequence else {
            throw AgentCausalLedgerError.sequenceOverflow
        }
    }

    mutating func append(
        instant: AgentSimulationInstant,
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent? {
        guard case let .bounded(maxEvents) = policy else { return nil }
        guard latestSequence < UInt64.max else { throw AgentCausalLedgerError.sequenceOverflow }
        let sequence = AgentCausalSequence(rawValue: latestSequence + 1)!
        let event = try AgentCausalEvent(
            id: AgentCausalEventID(simulationID: instant.simulationID, sequence: sequence),
            instant: instant,
            kind: kind,
            origin: origin,
            actorID: actorID,
            subjectID: subjectID,
            operationID: operationID,
            causes: causes,
            payload: payload,
            summary: summary
        )
        latestSequence = sequence.rawValue
        rollingDigest = AgentCausalEvent.digest("\(rollingDigest)|\(event.digest)")
        events.append(event)
        if events.count > maxEvents {
            let removed = events.count - maxEvents
            events.removeFirst(removed)
            droppedEventCount += UInt64(removed)
        }
        return event
    }

    func snapshot(instant: AgentSimulationInstant, tail limit: Int? = nil) -> AgentCausalLedgerSnapshot {
        let selected = limit.map { Array(events.suffix(max(0, $0))) } ?? events
        return AgentCausalLedgerSnapshot(
            summary: AgentCausalLedgerSummary(
                simulationID: instant.simulationID,
                currentTick: instant.tick,
                latestSequence: latestSequence,
                nextSequence: latestSequence == UInt64.max ? nil : latestSequence + 1,
                retainedEventCount: events.count,
                droppedEventCount: droppedEventCount,
                firstRetainedEventID: events.first?.eventID,
                lastRetainedEventID: events.last?.eventID,
                retainedCauseCoverageComplete: droppedEventCount == 0,
                digest: rollingDigest
            ),
            events: selected
        )
    }
}
