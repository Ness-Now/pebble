public enum AgentPhysiologicalTimeError: Error, Equatable, Sendable {
    case invalidConfiguration(String)
    case invalidWorldTick(Int)
    case worldTickMovedBackward(previous: Int, current: Int)
    case elapsedWorldTickLimitExceeded(Int)
    case pendingBoundaryLimitExceeded(Int)
    case invalidState(String)
    case arithmeticOverflow
}

/// Explicit World-time calibration for passive biology.
///
/// The V1 values are product calibration, not an architectural constant. The
/// unit and boundary remain durable so later calibration does not require a
/// change of time authority.
public struct AgentPhysiologicalTimeConfiguration:
    Codable, Equatable, Sendable
{
    public static let normalizedNeedScale: Int64 = 1_000_000

    public let worldTicksPerDay: Int
    public let boundaryWorldTicks: Int
    public let hungerMillionthsPerWorldDay: Int64
    public let fatigueMillionthsPerWorldDay: Int64
    public let restRecoveryMillionthsPerBoundary: Int64
    public let maximumElapsedWorldTicksPerInput: Int
    public let maximumPendingBoundaries: Int

    public init(
        worldTicksPerDay: Int,
        boundaryWorldTicks: Int,
        hungerMillionthsPerWorldDay: Int64,
        fatigueMillionthsPerWorldDay: Int64,
        restRecoveryMillionthsPerBoundary: Int64,
        maximumElapsedWorldTicksPerInput: Int = 9_600,
        maximumPendingBoundaries: Int = 8
    ) throws {
        guard worldTicksPerDay > 0,
              boundaryWorldTicks > 0,
              boundaryWorldTicks <= worldTicksPerDay,
              hungerMillionthsPerWorldDay > 0,
              fatigueMillionthsPerWorldDay > 0,
              restRecoveryMillionthsPerBoundary > 0,
              restRecoveryMillionthsPerBoundary
                <= Self.normalizedNeedScale,
              maximumElapsedWorldTicksPerInput > 0,
              maximumPendingBoundaries > 0 else {
            throw AgentPhysiologicalTimeError.invalidConfiguration("bounds")
        }
        self.worldTicksPerDay = worldTicksPerDay
        self.boundaryWorldTicks = boundaryWorldTicks
        self.hungerMillionthsPerWorldDay = hungerMillionthsPerWorldDay
        self.fatigueMillionthsPerWorldDay = fatigueMillionthsPerWorldDay
        self.restRecoveryMillionthsPerBoundary =
            restRecoveryMillionthsPerBoundary
        self.maximumElapsedWorldTicksPerInput =
            maximumElapsedWorldTicksPerInput
        self.maximumPendingBoundaries = maximumPendingBoundaries
    }

    /// PRODUCT CALIBRATION V1: 1.0 hunger and 1.2 fatigue per 24,000
    /// authoritative World ticks, published at 1/20-day boundaries.
    public static let live = try! AgentPhysiologicalTimeConfiguration(
        worldTicksPerDay: 24_000,
        boundaryWorldTicks: 1_200,
        hungerMillionthsPerWorldDay: 1_000_000,
        fatigueMillionthsPerWorldDay: 1_200_000,
        restRecoveryMillionthsPerBoundary: 1_000_000
    )

    /// Existing focused configurations expressed their passive deltas per
    /// survival tick. Preserve those numerical fixtures by interpreting one
    /// such delta at an explicit V1 physiological boundary, never at a
    /// cognitive boundary.
    static func v1Compatible(
        with survival: AgentSurvivalConfiguration
    ) -> AgentPhysiologicalTimeConfiguration {
        let boundariesPerDay = Double(
            live.worldTicksPerDay / live.boundaryWorldTicks
        )
        return try! AgentPhysiologicalTimeConfiguration(
            worldTicksPerDay: live.worldTicksPerDay,
            boundaryWorldTicks: live.boundaryWorldTicks,
            hungerMillionthsPerWorldDay: Int64((
                survival.hungerPerTick * boundariesPerDay
                    * Double(normalizedNeedScale)
            ).rounded()),
            fatigueMillionthsPerWorldDay: Int64((
                survival.fatiguePerTick * boundariesPerDay
                    * Double(normalizedNeedScale)
            ).rounded()),
            restRecoveryMillionthsPerBoundary: Int64((
                survival.restRecoveryPerTick
                    * Double(normalizedNeedScale)
            ).rounded()),
            maximumElapsedWorldTicksPerInput:
                live.maximumElapsedWorldTicksPerInput,
            maximumPendingBoundaries: live.maximumPendingBoundaries
        )
    }
}

public struct AgentPhysiologicalBoundaryDelta: Equatable, Sendable {
    public let boundaryOrdinal: Int
    public let hungerMillionths: Int64
    public let fatigueMillionths: Int64
    public let restRecoveryMillionths: Int64
}

public struct AgentPhysiologicalTimeState: Codable, Equatable, Sendable {
    public let configuration: AgentPhysiologicalTimeConfiguration
    public internal(set) var lastReconciledWorldTick: Int?
    public internal(set) var totalElapsedWorldTicks: Int
    public internal(set) var remainderWorldTicks: Int
    public internal(set) var appliedBoundaryCount: Int
    public internal(set) var pendingBoundaryCount: Int

    public init(
        configuration: AgentPhysiologicalTimeConfiguration,
        lastReconciledWorldTick: Int? = nil,
        totalElapsedWorldTicks: Int = 0,
        remainderWorldTicks: Int = 0,
        appliedBoundaryCount: Int = 0,
        pendingBoundaryCount: Int = 0
    ) {
        self.configuration = configuration
        self.lastReconciledWorldTick = lastReconciledWorldTick
        self.totalElapsedWorldTicks = totalElapsedWorldTicks
        self.remainderWorldTicks = remainderWorldTicks
        self.appliedBoundaryCount = appliedBoundaryCount
        self.pendingBoundaryCount = pendingBoundaryCount
    }

    func validated() throws -> AgentPhysiologicalTimeState {
        _ = try AgentPhysiologicalTimeConfiguration(
            worldTicksPerDay: configuration.worldTicksPerDay,
            boundaryWorldTicks: configuration.boundaryWorldTicks,
            hungerMillionthsPerWorldDay:
                configuration.hungerMillionthsPerWorldDay,
            fatigueMillionthsPerWorldDay:
                configuration.fatigueMillionthsPerWorldDay,
            restRecoveryMillionthsPerBoundary:
                configuration.restRecoveryMillionthsPerBoundary,
            maximumElapsedWorldTicksPerInput:
                configuration.maximumElapsedWorldTicksPerInput,
            maximumPendingBoundaries:
                configuration.maximumPendingBoundaries
        )
        guard lastReconciledWorldTick.map({ $0 >= 0 }) ?? true,
              totalElapsedWorldTicks >= 0,
              remainderWorldTicks >= 0,
              remainderWorldTicks < configuration.boundaryWorldTicks,
              appliedBoundaryCount >= 0,
              pendingBoundaryCount >= 0,
              pendingBoundaryCount <= configuration.maximumPendingBoundaries
        else {
            throw AgentPhysiologicalTimeError.invalidState("bounds")
        }
        let (boundaryCount, overflow) = appliedBoundaryCount
            .addingReportingOverflow(pendingBoundaryCount)
        guard !overflow else {
            throw AgentPhysiologicalTimeError.arithmeticOverflow
        }
        let (boundaryTicks, multiplyOverflow) = boundaryCount
            .multipliedReportingOverflow(by: configuration.boundaryWorldTicks)
        let (expectedElapsed, addOverflow) = boundaryTicks
            .addingReportingOverflow(remainderWorldTicks)
        guard !multiplyOverflow, !addOverflow,
              expectedElapsed == totalElapsedWorldTicks else {
            throw AgentPhysiologicalTimeError.invalidState("elapsed")
        }
        return self
    }
}

extension AgentSimulationSession {
    public func physiologicalTimeSnapshot() -> AgentPhysiologicalTimeState {
        physiologicalTimeState
    }

    /// Establishes or deliberately rebases the World cursor without granting
    /// elapsed biology. Used at start, restore, and the explicit `/lab pause`
    /// exclusion boundary.
    public mutating func rebasePhysiologicalTime(
        toWorldTick worldTick: Int
    ) throws {
        guard worldTick >= 0 else {
            throw AgentPhysiologicalTimeError.invalidWorldTick(worldTick)
        }
        if let prior = physiologicalTimeState.lastReconciledWorldTick,
           worldTick < prior {
            throw AgentPhysiologicalTimeError.worldTickMovedBackward(
                previous: prior, current: worldTick
            )
        }
        migrateLegacyPhysiologicalAgeIfNeeded()
        physiologicalTimeState.lastReconciledWorldTick = worldTick
        legacyTemporalSchemaVersionOverride = nil
    }

    @_spi(Testing)
    public mutating func useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: Int
    ) throws {
        guard schemaVersion < AgentCheckpointSchema.temporalPhysiologyVersion,
              AgentCheckpointSchema.supports(schemaVersion),
              physiologicalTimeState.totalElapsedWorldTicks == 0,
              physiologicalTimeState.lastReconciledWorldTick == nil else {
            throw AgentPhysiologicalTimeError.invalidState(
                "legacy replay fixture"
            )
        }
        legacyTemporalSchemaVersionOverride = schemaVersion
    }

    /// Accepts monotonic authoritative World progression. This performs only
    /// constant bounded arithmetic; per-agent biological transitions remain
    /// session-owned and are published by the next cognitive boundary.
    public mutating func advancePhysiologicalTime(
        toWorldTick worldTick: Int
    ) throws {
        guard worldTick >= 0 else {
            throw AgentPhysiologicalTimeError.invalidWorldTick(worldTick)
        }
        guard let prior = physiologicalTimeState.lastReconciledWorldTick else {
            try rebasePhysiologicalTime(toWorldTick: worldTick)
            return
        }
        guard worldTick >= prior else {
            throw AgentPhysiologicalTimeError.worldTickMovedBackward(
                previous: prior, current: worldTick
            )
        }
        let elapsed = worldTick - prior
        guard elapsed <= physiologicalTimeState.configuration
            .maximumElapsedWorldTicksPerInput else {
            throw AgentPhysiologicalTimeError
                .elapsedWorldTickLimitExceeded(elapsed)
        }
        guard elapsed > 0 else { return }
        var candidate = physiologicalTimeState
        let (combinedRemainder, remainderOverflow) = candidate
            .remainderWorldTicks.addingReportingOverflow(elapsed)
        let (totalElapsed, totalOverflow) = candidate
            .totalElapsedWorldTicks.addingReportingOverflow(elapsed)
        guard !remainderOverflow, !totalOverflow else {
            throw AgentPhysiologicalTimeError.arithmeticOverflow
        }
        let due = combinedRemainder / candidate.configuration.boundaryWorldTicks
        let (pending, pendingOverflow) = candidate.pendingBoundaryCount
            .addingReportingOverflow(due)
        guard !pendingOverflow,
              pending <= candidate.configuration.maximumPendingBoundaries else {
            throw AgentPhysiologicalTimeError
                .pendingBoundaryLimitExceeded(pending)
        }
        candidate.lastReconciledWorldTick = worldTick
        candidate.totalElapsedWorldTicks = totalElapsed
        candidate.remainderWorldTicks = combinedRemainder
            % candidate.configuration.boundaryWorldTicks
        candidate.pendingBoundaryCount = pending
        _ = try candidate.validated()
        migrateLegacyPhysiologicalAgeIfNeeded()
        physiologicalTimeState = candidate
        legacyTemporalSchemaVersionOverride = nil
    }

    mutating func takeNextPhysiologicalBoundary() throws
        -> AgentPhysiologicalBoundaryDelta?
    {
        guard physiologicalTimeState.pendingBoundaryCount > 0 else {
            return nil
        }
        var candidate = physiologicalTimeState
        let nextOrdinal = candidate.appliedBoundaryCount + 1
        let currentOrdinal = candidate.appliedBoundaryCount
        func cumulative(
            rate: Int64, ordinal: Int
        ) throws -> Int64 {
            let (first, firstOverflow) = rate.multipliedReportingOverflow(
                by: Int64(candidate.configuration.boundaryWorldTicks)
            )
            let (second, secondOverflow) = first.multipliedReportingOverflow(
                by: Int64(ordinal)
            )
            guard !firstOverflow, !secondOverflow else {
                throw AgentPhysiologicalTimeError.arithmeticOverflow
            }
            return second / Int64(candidate.configuration.worldTicksPerDay)
        }
        let hunger = try cumulative(
            rate: candidate.configuration.hungerMillionthsPerWorldDay,
            ordinal: nextOrdinal
        ) - cumulative(
            rate: candidate.configuration.hungerMillionthsPerWorldDay,
            ordinal: currentOrdinal
        )
        let fatigue = try cumulative(
            rate: candidate.configuration.fatigueMillionthsPerWorldDay,
            ordinal: nextOrdinal
        ) - cumulative(
            rate: candidate.configuration.fatigueMillionthsPerWorldDay,
            ordinal: currentOrdinal
        )
        candidate.appliedBoundaryCount = nextOrdinal
        candidate.pendingBoundaryCount -= 1
        _ = try candidate.validated()
        physiologicalTimeState = candidate
        return AgentPhysiologicalBoundaryDelta(
            boundaryOrdinal: nextOrdinal,
            hungerMillionths: hunger,
            fatigueMillionths: fatigue,
            restRecoveryMillionths:
                candidate.configuration.restRecoveryMillionthsPerBoundary
        )
    }

    mutating func applyDuePhysiologicalBoundaries(
        at eventTick: Int,
        causalRetentionFault: AgentCausalRetentionFaultPoint? = nil
    ) throws -> [String: AgentMemoryEntry] {
        var latestMemories: [String: AgentMemoryEntry] = [:]
        while let boundary = try takeNextPhysiologicalBoundary() {
            if mortalityState != nil {
                let memories = try applyMortalitySurvivalBoundary(
                    at: eventTick,
                    boundary: boundary,
                    causalRetentionFault: causalRetentionFault
                )
                for (agentID, memory) in memories {
                    latestMemories[agentID] = memory
                }
                if mortalityState?.pendingTransitions.isEmpty == false {
                    break
                }
            } else if survivalEnabled {
                for id in sortedIds {
                    guard var state = statesById[id] else { continue }
                    let restingAtHome = state.position == state.homePosition
                        && state.currentGoal.kind == .rest
                        && state.lastAction?.name == "rest"
                    let memory = applySurvivalTick(
                        to: &state,
                        tick: eventTick,
                        boundary: boundary,
                        restingAtHome: restingAtHome
                    )
                    if let memory {
                        appendMemory(memory, to: &state.memory)
                        latestMemories[id] = memory
                    }
                    statesById[id] = state
                }
            }
        }
        return latestMemories
    }

    func physiologicalAge(for agentID: AgentID) throws -> Int {
        guard let member = lifecycleState?.members.first(where: {
            $0.agentID == agentID
        }) else {
            throw AgentSessionError.lifecycle(.invalidMember(agentID.rawValue))
        }
        // A genuinely historical checkpoint/replay fixture must retain the
        // lifecycle age contract from its schema: elapsed cognitive/session
        // ticks. New v44 sessions never enter this path and use only the
        // World-derived boundary age below.
        if legacyTemporalSchemaVersionOverride != nil {
            return try member.age(at: tick)
        }
        if member.physiologicalRegisteredBoundary != nil,
           member.physiologicalInitialAge != nil {
            return try member.physiologicalAge(
                atBoundary: physiologicalTimeState.appliedBoundaryCount
            )
        }
        if let profile = homeostasisState?.profiles.first(where: {
            $0.agentID == agentID
        }) {
            return profile.ageTicks
        }
        return try member.age(at: tick)
    }

    mutating func migrateLegacyPhysiologicalAgeIfNeeded() {
        guard var lifecycle = lifecycleState else { return }
        var changed = false
        for index in lifecycle.members.indices
        where lifecycle.members[index].physiologicalRegisteredBoundary == nil
            || lifecycle.members[index].physiologicalInitialAge == nil {
            let member = lifecycle.members[index]
            let age = homeostasisState?.profiles.first(where: {
                $0.agentID == member.agentID
            })?.ageTicks ?? ((try? member.age(at: tick))
                ?? member.initialAgeTicks)
            lifecycle.members[index].physiologicalRegisteredBoundary =
                physiologicalTimeState.appliedBoundaryCount
            lifecycle.members[index].physiologicalInitialAge = age
            changed = true
        }
        if changed { lifecycleState = lifecycle }
    }
}
