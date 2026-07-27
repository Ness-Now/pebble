public enum AgentProductiveSourceError: Error, Equatable, CustomStringConvertible {
    case disabled
    case invalidConfiguration(String)
    case invalidObservation(String)
    case duplicateSource(String)
    case unknownSource(String)
    case staleMaterial(String)
    case sourceUnavailable(String)

    public var description: String {
        switch self {
        case .disabled:
            return "productive source lifecycle disabled"
        case let .invalidConfiguration(reason):
            return "invalid productive source configuration: \(reason)"
        case let .invalidObservation(reason):
            return "invalid productive source observation: \(reason)"
        case let .duplicateSource(key):
            return "duplicate productive source \(key)"
        case let .unknownSource(key):
            return "unknown productive source \(key)"
        case let .staleMaterial(key):
            return "stale productive source material \(key)"
        case let .sourceUnavailable(key):
            return "productive source unavailable \(key)"
        }
    }
}

public struct AgentProductiveSourceConfiguration: Codable, Equatable, Sendable {
    public let maximumSources: Int
    public let maximumTransitions: Int
    public let maximumObservationAgeTicks: Int

    public init(
        maximumSources: Int = 128,
        maximumTransitions: Int = 512,
        maximumObservationAgeTicks: Int = 8
    ) throws {
        guard (1...1024).contains(maximumSources) else {
            throw AgentProductiveSourceError.invalidConfiguration("sources")
        }
        guard (1...4096).contains(maximumTransitions) else {
            throw AgentProductiveSourceError.invalidConfiguration("transitions")
        }
        guard (1...256).contains(maximumObservationAgeTicks) else {
            throw AgentProductiveSourceError.invalidConfiguration("observation age")
        }
        self.maximumSources = maximumSources
        self.maximumTransitions = maximumTransitions
        self.maximumObservationAgeTicks = maximumObservationAgeTicks
    }

    public static let live = try! AgentProductiveSourceConfiguration()
}

public enum AgentProductiveSourceDisposition: String, Codable, CaseIterable, Sendable {
    case viable
    case temporarilyUnavailable
    case depleted
    case withdrawn
}

public enum AgentProductiveSourceViability: String, Codable, CaseIterable, Sendable {
    case observed
    case viable
    case temporarilyUnavailable
    case depleted
    case withdrawn
    case renewed

    public var eligible: Bool {
        self == .viable || self == .renewed
    }
}

/// Pure bounded evidence published by Pebble after a local physical scan.
/// Event and runtime IDs are provenance only and never define renewal.
public struct AgentProductiveSourceObservation: Codable, Equatable, Sendable {
    public let sourceKey: String
    public let domain: AgentAutonomousActivityDomain
    public let materialFingerprint: String
    public let observedAtTick: Int
    public let observerID: AgentID
    public let physicalPosition: AgentPosition?
    public let disposition: AgentProductiveSourceDisposition
    public let observationReference: String
    public let temporarilyUnavailableReason: String?
    public let withdrawalReason: String?
    public let renewalReason: String?

    public init(
        sourceKey: String,
        domain: AgentAutonomousActivityDomain,
        materialFingerprint: String,
        observedAtTick: Int,
        observerID: AgentID,
        physicalPosition: AgentPosition?,
        disposition: AgentProductiveSourceDisposition,
        observationReference: String,
        temporarilyUnavailableReason: String? = nil,
        withdrawalReason: String? = nil,
        renewalReason: String? = nil
    ) {
        self.sourceKey = String(sourceKey.prefix(160))
        self.domain = domain
        self.materialFingerprint = String(materialFingerprint.prefix(160))
        self.observedAtTick = observedAtTick
        self.observerID = observerID
        self.physicalPosition = physicalPosition
        self.disposition = disposition
        self.observationReference = String(observationReference.prefix(160))
        self.temporarilyUnavailableReason = temporarilyUnavailableReason.map {
            String($0.prefix(160))
        }
        self.withdrawalReason = withdrawalReason.map {
            String($0.prefix(160))
        }
        self.renewalReason = renewalReason.map { String($0.prefix(160)) }
    }
}

public struct AgentProductiveSource: Codable, Equatable, Sendable {
    public let sourceKey: String
    public let domain: AgentAutonomousActivityDomain
    public internal(set) var materialFingerprint: String
    public internal(set) var lastObservedTick: Int
    public internal(set) var viability: AgentProductiveSourceViability
    public internal(set) var temporarilyUnavailableReason: String?
    public internal(set) var withdrawalReason: String?
    public internal(set) var renewalReason: String?
    public internal(set) var lastPhysicalSuccessTick: Int?
    public internal(set) var physicalPosition: AgentPosition?
    public internal(set) var observerID: AgentID
    public internal(set) var observationReference: String
    public let firstObservedTick: Int
    public internal(set) var observationCount: Int
    public internal(set) var renewalCount: Int
    public internal(set) var lastPhysicalReceiptID: String?
}

public struct AgentProductiveSourceTransition: Codable, Equatable, Sendable {
    public let sourceKey: String
    public let domain: AgentAutonomousActivityDomain
    public let from: AgentProductiveSourceViability?
    public let to: AgentProductiveSourceViability
    public let tick: Int
    public let materialFingerprint: String
    public let reason: String
}

public struct AgentProductiveSourceCounters: Codable, Equatable, Sendable {
    public internal(set) var observationCount = 0
    public internal(set) var viableCount = 0
    public internal(set) var temporarilyUnavailableCount = 0
    public internal(set) var depletedCount = 0
    public internal(set) var renewedCount = 0
    public internal(set) var withdrawnCount = 0
    public internal(set) var physicalSuccessCount = 0

    public init() {}
}

public struct AgentProductiveSourceState: Codable, Equatable, Sendable {
    public let configuration: AgentProductiveSourceConfiguration
    public internal(set) var sources: [AgentProductiveSource]
    public internal(set) var transitions: [AgentProductiveSourceTransition]
    public internal(set) var counters: AgentProductiveSourceCounters
    public internal(set) var evictionCount: Int

    public init(configuration: AgentProductiveSourceConfiguration) {
        self.configuration = configuration
        sources = []
        transitions = []
        counters = AgentProductiveSourceCounters()
        evictionCount = 0
    }
}

public struct AgentProductiveSourceSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentProductiveSourceConfiguration?
    public let sources: [AgentProductiveSource]
    public let transitions: [AgentProductiveSourceTransition]
    public let counters: AgentProductiveSourceCounters
    public let evictionCount: Int
}

extension AgentSimulationSession {
    public var productiveSourceLifecycleEnabled: Bool {
        autonomousActivityState?.productiveSourceState != nil
    }

    public func productiveSourceSnapshot() -> AgentProductiveSourceSnapshot {
        guard let state = autonomousActivityState?.productiveSourceState else {
            return AgentProductiveSourceSnapshot(
                enabled: false,
                configuration: nil,
                sources: [],
                transitions: [],
                counters: AgentProductiveSourceCounters(),
                evictionCount: 0
            )
        }
        return AgentProductiveSourceSnapshot(
            enabled: true,
            configuration: state.configuration,
            sources: state.sources.sorted(by: productiveSourceSort),
            transitions: state.transitions,
            counters: state.counters,
            evictionCount: state.evictionCount
        )
    }

    public func productiveSource(
        for sourceKey: String
    ) -> AgentProductiveSource? {
        autonomousActivityState?.productiveSourceState?.sources.first {
            $0.sourceKey == sourceKey
        }
    }

    public func viableProductiveSources(
        domain: AgentAutonomousActivityDomain
    ) -> [AgentProductiveSource] {
        (autonomousActivityState?.productiveSourceState?.sources ?? [])
            .filter { $0.domain == domain && $0.viability.eligible }
            .sorted(by: productiveSourceSort)
    }

    public mutating func setProductiveSourceLifecycleEnabled(
        _ enabled: Bool,
        configuration: AgentProductiveSourceConfiguration = .live
    ) throws {
        guard var autonomy = autonomousActivityState else {
            throw AgentProductiveSourceError.disabled
        }
        if enabled {
            if autonomy.productiveSourceState == nil {
                autonomy.productiveSourceState = AgentProductiveSourceState(
                    configuration: configuration
                )
                autonomousActivityState = autonomy
            }
            return
        }
        autonomy.productiveSourceState = nil
        autonomousActivityState = autonomy
    }

    @discardableResult
    public mutating func recordProductiveSourceObservations(
        _ observations: [AgentProductiveSourceObservation]
    ) throws -> [AgentProductiveSourceTransition] {
        guard var autonomy = autonomousActivityState,
              var state = autonomy.productiveSourceState else {
            throw AgentProductiveSourceError.disabled
        }
        guard Set(observations.map(\.sourceKey)).count == observations.count else {
            throw AgentProductiveSourceError.duplicateSource(
                observations.first?.sourceKey ?? "unknown"
            )
        }
        let transitionStart = state.transitions.count
        for observation in observations.sorted(by: productiveObservationSort) {
            try validateProductiveSourceObservation(observation)
            state.counters.observationCount += 1
            if let index = state.sources.firstIndex(where: {
                $0.sourceKey == observation.sourceKey
            }) {
                try reconcileProductiveSource(
                    observation, at: index, state: &state
                )
            } else {
                appendNewProductiveSource(observation, state: &state)
            }
        }
        evictProductiveSourceState(&state)
        autonomy.productiveSourceState = state
        autonomousActivityState = autonomy
        let retainedStart = max(0, transitionStart - max(
            0, transitionStart + observations.count * 2
                - state.configuration.maximumTransitions
        ))
        return Array(state.transitions.dropFirst(min(
            retainedStart, state.transitions.count
        )))
    }

    @discardableResult
    public mutating func recordProductiveSourceSuccess(
        sourceKey: String,
        expectedMaterialFingerprint: String,
        physicalReceiptID: String
    ) throws -> AgentProductiveSource {
        guard var autonomy = autonomousActivityState,
              var state = autonomy.productiveSourceState else {
            throw AgentProductiveSourceError.disabled
        }
        guard let index = state.sources.firstIndex(where: {
            $0.sourceKey == sourceKey
        }) else {
            throw AgentProductiveSourceError.unknownSource(sourceKey)
        }
        guard state.sources[index].materialFingerprint
                == expectedMaterialFingerprint else {
            throw AgentProductiveSourceError.staleMaterial(sourceKey)
        }
        guard state.sources[index].viability.eligible else {
            throw AgentProductiveSourceError.sourceUnavailable(sourceKey)
        }
        state.sources[index].lastPhysicalSuccessTick = tick
        state.sources[index].lastPhysicalReceiptID = String(
            physicalReceiptID.prefix(160)
        )
        state.counters.physicalSuccessCount += 1
        let result = state.sources[index]
        autonomy.productiveSourceState = state
        autonomousActivityState = autonomy
        return result
    }

    @discardableResult
    public mutating func reviewProductiveSources(
    ) throws -> [AgentProductiveSourceTransition] {
        guard var autonomy = autonomousActivityState,
              var state = autonomy.productiveSourceState else {
            throw AgentProductiveSourceError.disabled
        }
        let transitionStart = state.transitions.count
        for index in state.sources.indices {
            guard state.sources[index].viability != .withdrawn,
                  tick - state.sources[index].lastObservedTick
                    > state.configuration.maximumObservationAgeTicks else {
                continue
            }
            let previous = state.sources[index].viability
            state.sources[index].viability = .withdrawn
            state.sources[index].temporarilyUnavailableReason = nil
            state.sources[index].withdrawalReason = "local observation stale"
            state.sources[index].renewalReason = nil
            appendProductiveSourceTransition(
                source: state.sources[index],
                from: previous,
                to: .withdrawn,
                reason: "local observation stale",
                state: &state
            )
        }
        evictProductiveSourceState(&state)
        autonomy.productiveSourceState = state
        autonomousActivityState = autonomy
        return Array(state.transitions.dropFirst(min(
            transitionStart, state.transitions.count
        )))
    }

    private func validateProductiveSourceObservation(
        _ observation: AgentProductiveSourceObservation
    ) throws {
        guard !observation.sourceKey.isEmpty,
              !observation.materialFingerprint.isEmpty,
              !observation.observationReference.isEmpty,
              observation.observedAtTick >= 0,
              observation.observedAtTick <= tick + 1,
              statesById[observation.observerID.rawValue] != nil else {
            throw AgentProductiveSourceError.invalidObservation(
                observation.sourceKey
            )
        }
        if observation.disposition == .temporarilyUnavailable,
           observation.temporarilyUnavailableReason == nil {
            throw AgentProductiveSourceError.invalidObservation(
                "temporary reason missing"
            )
        }
        if observation.disposition == .depleted
            || observation.disposition == .withdrawn,
           observation.withdrawalReason == nil {
            throw AgentProductiveSourceError.invalidObservation(
                "withdrawal reason missing"
            )
        }
    }

    private mutating func appendNewProductiveSource(
        _ observation: AgentProductiveSourceObservation,
        state: inout AgentProductiveSourceState
    ) {
        let viability = productiveViability(for: observation.disposition)
        let source = AgentProductiveSource(
            sourceKey: observation.sourceKey,
            domain: observation.domain,
            materialFingerprint: observation.materialFingerprint,
            lastObservedTick: observation.observedAtTick,
            viability: viability,
            temporarilyUnavailableReason:
                observation.temporarilyUnavailableReason,
            withdrawalReason: observation.withdrawalReason,
            renewalReason: nil,
            lastPhysicalSuccessTick: nil,
            physicalPosition: observation.physicalPosition,
            observerID: observation.observerID,
            observationReference: observation.observationReference,
            firstObservedTick: observation.observedAtTick,
            observationCount: 1,
            renewalCount: 0,
            lastPhysicalReceiptID: nil
        )
        state.sources.append(source)
        appendProductiveSourceTransition(
            source: source,
            from: nil,
            to: .observed,
            reason: "fresh local physical observation",
            state: &state
        )
        appendProductiveSourceTransition(
            source: source,
            from: .observed,
            to: viability,
            reason: transitionReason(for: observation, renewed: false),
            state: &state
        )
    }

    private mutating func reconcileProductiveSource(
        _ observation: AgentProductiveSourceObservation,
        at index: Int,
        state: inout AgentProductiveSourceState
    ) throws {
        var source = state.sources[index]
        guard source.domain == observation.domain else {
            throw AgentProductiveSourceError.invalidObservation(
                "domain changed for \(observation.sourceKey)"
            )
        }
        let previous = source.viability
        let materialChanged =
            source.materialFingerprint != observation.materialFingerprint
        var next = productiveViability(for: observation.disposition)
        if observation.disposition == .viable {
            let restoring = previous == .temporarilyUnavailable
                || previous == .depleted || previous == .withdrawn
            if restoring || materialChanged {
                guard observation.renewalReason != nil else {
                    throw AgentProductiveSourceError.invalidObservation(
                        "renewal fact missing for \(observation.sourceKey)"
                    )
                }
                next = .renewed
                source.renewalCount += 1
                state.counters.renewedCount += 1
            } else if previous == .renewed {
                next = .viable
            }
        }
        source.materialFingerprint = observation.materialFingerprint
        source.lastObservedTick = observation.observedAtTick
        source.viability = next
        source.temporarilyUnavailableReason =
            observation.temporarilyUnavailableReason
        source.withdrawalReason = observation.withdrawalReason
        source.renewalReason = next == .renewed
            ? observation.renewalReason : nil
        source.physicalPosition = observation.physicalPosition
        source.observerID = observation.observerID
        source.observationReference = observation.observationReference
        source.observationCount += 1
        state.sources[index] = source
        if previous != next || materialChanged {
            appendProductiveSourceTransition(
                source: source,
                from: previous,
                to: next,
                reason: transitionReason(
                    for: observation, renewed: next == .renewed
                ),
                state: &state
            )
        }
    }

    private func productiveViability(
        for disposition: AgentProductiveSourceDisposition
    ) -> AgentProductiveSourceViability {
        switch disposition {
        case .viable: return .viable
        case .temporarilyUnavailable: return .temporarilyUnavailable
        case .depleted: return .depleted
        case .withdrawn: return .withdrawn
        }
    }

    private func transitionReason(
        for observation: AgentProductiveSourceObservation,
        renewed: Bool
    ) -> String {
        if renewed, let reason = observation.renewalReason { return reason }
        return observation.temporarilyUnavailableReason
            ?? observation.withdrawalReason
            ?? "physical source viable"
    }

    private mutating func appendProductiveSourceTransition(
        source: AgentProductiveSource,
        from: AgentProductiveSourceViability?,
        to: AgentProductiveSourceViability,
        reason: String,
        state: inout AgentProductiveSourceState
    ) {
        state.transitions.append(AgentProductiveSourceTransition(
            sourceKey: source.sourceKey,
            domain: source.domain,
            from: from,
            to: to,
            tick: source.lastObservedTick,
            materialFingerprint: source.materialFingerprint,
            reason: String(reason.prefix(160))
        ))
        switch to {
        case .observed: break
        case .viable: state.counters.viableCount += 1
        case .temporarilyUnavailable:
            state.counters.temporarilyUnavailableCount += 1
        case .depleted: state.counters.depletedCount += 1
        case .renewed: break
        case .withdrawn: state.counters.withdrawnCount += 1
        }
    }

    private mutating func evictProductiveSourceState(
        _ state: inout AgentProductiveSourceState
    ) {
        state.sources.sort(by: productiveSourceEvictionSort)
        if state.sources.count > state.configuration.maximumSources {
            let count = state.sources.count - state.configuration.maximumSources
            state.sources.removeFirst(count)
            state.evictionCount += count
        }
        state.sources.sort(by: productiveSourceSort)
        if state.transitions.count > state.configuration.maximumTransitions {
            let count = state.transitions.count
                - state.configuration.maximumTransitions
            state.transitions.removeFirst(count)
            state.evictionCount += count
        }
    }

    private func productiveObservationSort(
        _ lhs: AgentProductiveSourceObservation,
        _ rhs: AgentProductiveSourceObservation
    ) -> Bool {
        if lhs.domain != rhs.domain {
            return lhs.domain.rawValue < rhs.domain.rawValue
        }
        return lhs.sourceKey < rhs.sourceKey
    }

    private func productiveSourceSort(
        _ lhs: AgentProductiveSource,
        _ rhs: AgentProductiveSource
    ) -> Bool {
        if lhs.domain != rhs.domain {
            return lhs.domain.rawValue < rhs.domain.rawValue
        }
        return lhs.sourceKey < rhs.sourceKey
    }

    private func productiveSourceEvictionSort(
        _ lhs: AgentProductiveSource,
        _ rhs: AgentProductiveSource
    ) -> Bool {
        if lhs.lastObservedTick != rhs.lastObservedTick {
            return lhs.lastObservedTick < rhs.lastObservedTick
        }
        return productiveSourceSort(lhs, rhs)
    }
}
