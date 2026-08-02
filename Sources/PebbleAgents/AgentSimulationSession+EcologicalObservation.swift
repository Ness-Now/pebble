extension AgentSimulationSession {
    public var ecologicalObservationEnabled: Bool { ecologicalObservationState != nil }

    public func civilDate() -> AgentCivilDate? {
        ecologicalObservationState?.configuration.calendar.date(atSimulationTick: tick)
    }

    public func ecologicalObservationSnapshot() -> AgentEcologicalObservationSnapshot {
        guard let state = ecologicalObservationState else {
            return AgentEcologicalObservationSnapshot(
                enabled: false, configuration: nil, civilDate: nil,
                observations: [], freshCount: 0, staleCount: 0,
                totalObservationCount: 0, scanCount: 0, worldReadCount: 0,
                cacheHitCount: 0, cacheMissCount: 0,
                evictionCounts: AgentEcologicalObservationEvictionCounts(),
                digest: AgentEcologicalObservationDigest.make("disabled")
            )
        }
        let records = state.observations.sorted { $0.sequence < $1.sequence }
        let fresh = records.filter { $0.observation.isFresh(atSimulationTick: tick) }.count
        let canonical = [
            "enabled=1",
            "calendar=\(state.configuration.calendar.ticksPerCivilDay),\(state.configuration.calendar.daysPerSeason),\(state.configuration.calendar.seasonsPerYear),\(state.configuration.calendar.epochSimulationTick),\(state.configuration.calendar.epochYear)",
            "bounds=\(state.configuration.radius),\(state.configuration.verticalRadius),\(state.configuration.maximumCellsPerScan),\(state.configuration.maximumChunksPerScan),\(state.configuration.maximumEntitiesPerScan),\(state.configuration.maximumResultsPerScan),\(state.configuration.maximumWorldReadsPerScan),\(state.configuration.maximumScansPerSimulationTick)",
            "retention=\(state.configuration.maximumRetainedObservations),\(state.configuration.maximumRetainedObservationsPerAgent)",
            "freshness=\(state.configuration.dynamicFreshnessTicks),\(state.configuration.waterSoilFreshnessTicks),\(state.configuration.biomeFreshnessTicks)",
            records.map { "r|\($0.sequence)|\($0.observation.digest)|\($0.causalEventID.rawValue)" }.joined(separator: ";"),
            "totals=\(state.totalObservationCount),\(state.evictionCounts.observations)",
            "events=\(state.initializedEventID.rawValue),\(state.lastObservationEventID.rawValue)",
        ].joined(separator: "|")
        return AgentEcologicalObservationSnapshot(
            enabled: true,
            configuration: state.configuration,
            civilDate: state.configuration.calendar.date(atSimulationTick: tick),
            observations: records,
            freshCount: fresh,
            staleCount: records.count - fresh,
            totalObservationCount: state.totalObservationCount,
            scanCount: records.count,
            worldReadCount: records.reduce(0) { $0 + $1.observation.diagnostics.worldReads },
            cacheHitCount: records.reduce(0) { $0 + $1.observation.diagnostics.cacheHits },
            cacheMissCount: records.reduce(0) { $0 + $1.observation.diagnostics.cacheMisses },
            evictionCounts: state.evictionCounts,
            digest: AgentEcologicalObservationDigest.make(canonical)
        )
    }

    public func ecologicalObservations(
        for observerID: AgentID,
        freshOnly: Bool = true
    ) -> [AgentEcologicalObservationRecord] {
        guard statesById[observerID.rawValue] != nil,
              populationRegistry?.members.contains(where: {
                  $0.agentID == observerID
              }) == true else {
            return []
        }
        return ecologicalObservationState?.observations.filter {
            $0.observation.observerID == observerID
                && (!freshOnly || $0.observation.isFresh(atSimulationTick: tick))
        }.sorted { $0.sequence > $1.sequence } ?? []
    }

    /// Returns only validation classifications derived from the active
    /// population or retained mortality authority. It never grants current
    /// agency to a historical observer.
    public func historicalEcologicalObservationValidations() throws
        -> [AgentHistoricalEcologicalObservationValidation] {
        guard let state = ecologicalObservationState else { return [] }
        return try validateEcologicalObservationState(
            state,
            activeAgents: Array(statesById.values),
            population: populationRegistry,
            mortality: mortalityState,
            agriculture: agricultureState,
            clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    public func nearestObservedWater(for observerID: AgentID) -> [AgentWaterAffordance] {
        guard let latest = ecologicalObservations(for: observerID).first?.observation else { return [] }
        return latest.water.sorted {
            let ld = ecologicalDistance(latest.origin, $0.position)
            let rd = ecologicalDistance(latest.origin, $1.position)
            if ld != rd { return ld < rd }
            return AgentEcologicalObservation.waterSort($0, $1)
        }
    }

    public func observedTillableSoils(for observerID: AgentID) -> [AgentSoilAffordance] {
        ecologicalObservations(for: observerID).first?.observation.soils.filter(\.tillable) ?? []
    }

    public func observedCrops(for observerID: AgentID) -> [AgentCropObservation] {
        ecologicalObservations(for: observerID).first?.observation.crops ?? []
    }

    public func observedAnimals(for observerID: AgentID) -> [AgentAnimalObservation] {
        ecologicalObservations(for: observerID).first?.observation.animals ?? []
    }

    public func observedFishingCandidates(for observerID: AgentID) -> [AgentFishingAffordance] {
        ecologicalObservations(for: observerID).first?.observation.fishing.filter(\.candidate) ?? []
    }

    public mutating func setEcologicalObservationEnabled(
        _ enabled: Bool,
        configuration observationConfiguration: AgentEcologicalObservationConfiguration = .live
    ) throws {
        if enabled {
            guard ecologicalObservationState == nil else {
                throw AgentSessionError.ecologicalObservation(.alreadyEnabled)
            }
            guard causalLedger.policy != .disabled else {
                throw AgentSessionError.ecologicalObservation(.causalLedgerRequired)
            }
            guard populationRegistry != nil else {
                throw AgentSessionError.ecologicalObservation(.populationRequired)
            }
            var candidate = self
            try candidate.prevalidateCausalAppend(count: 1)
            let event = try candidate.requiredEcologicalObservationEvent(
                kind: .ecologicalObservationInitialized,
                payload: .ecologicalObservation(
                    observerID: nil, worldContextKey: nil, dimensionKey: nil,
                    resultCount: 0, worldReads: 0, truncated: false,
                    status: "initialized", digest: AgentEcologicalObservationDigest.make("empty")
                ),
                summary: "ecological observation initialized without retroactive observations"
            )
            candidate.ecologicalObservationState = AgentEcologicalObservationState(
                configuration: observationConfiguration,
                observations: [], totalObservationCount: 0,
                evictionCounts: AgentEcologicalObservationEvictionCounts(),
                initializedEventID: event.eventID,
                lastObservationEventID: event.eventID,
                transitionTick: tick, observationsAtTick: 0
            )
            try candidate.validateEcologicalObservationStateIfEnabled()
            self = candidate
        } else if ecologicalObservationState != nil {
            throw AgentSessionError.ecologicalObservation(.unsafeDisable)
        }
    }

    @discardableResult
    public mutating func recordEcologicalObservation(
        _ observation: AgentEcologicalObservation
    ) throws -> AgentEcologicalObservationRecord {
        var candidate = self
        let record = try candidate.recordEcologicalObservationInPlace(observation)
        try candidate.validateEcologicalObservationStateIfEnabled()
        self = candidate
        return record
    }

    private mutating func recordEcologicalObservationInPlace(
        _ observation: AgentEcologicalObservation
    ) throws -> AgentEcologicalObservationRecord {
        guard var state = ecologicalObservationState else {
            throw AgentSessionError.ecologicalObservation(.disabled)
        }
        guard statesById[observation.observerID.rawValue] != nil,
              populationRegistry?.members.contains(where: {
                  $0.agentID == observation.observerID
              }) == true else {
            throw AgentSessionError.ecologicalObservation(.unknownObserver(observation.observerID))
        }
        guard observation.observedAtSimulationTick == tick,
              observation.civilDate == state.configuration.calendar.date(atSimulationTick: tick),
              observation.physicalWorldTick >= 0,
              observation.physicalTime.worldTick == observation.physicalWorldTick,
              observation.expiresAtSimulationTick >= tick,
              observation.expiresAtSimulationTick - tick
                <= state.configuration.dynamicFreshnessTicks,
              ecologicalContextKeyIsValid(observation.worldContextKey),
              ecologicalContextKeyIsValid(observation.dimensionKey),
              observation.hasValidDigest() else {
            throw AgentSessionError.ecologicalObservation(.invalidObservation("identity, clock, context, or digest"))
        }
        let diagnostics = observation.diagnostics
        let resultCount = observation.water.count + observation.soils.count
            + observation.crops.count + observation.plants.count
            + observation.animals.count + observation.fishing.count
            + (observation.biome == nil ? 0 : 1) + 2
        guard diagnostics.radius <= state.configuration.radius,
              diagnostics.cellsConsidered <= state.configuration.maximumCellsPerScan,
              diagnostics.worldReads <= state.configuration.maximumWorldReadsPerScan,
              diagnostics.chunksTouched <= state.configuration.maximumChunksPerScan,
              diagnostics.entitiesConsidered <= state.configuration.maximumEntitiesPerScan,
              diagnostics.resultsEmitted == resultCount,
              resultCount <= state.configuration.maximumResultsPerScan else {
            throw AgentSessionError.ecologicalObservation(.invalidObservation("scan budget"))
        }
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.observationsAtTick = 0
        }
        guard state.observationsAtTick < state.configuration.maximumScansPerSimulationTick else {
            throw AgentSessionError.ecologicalObservation(.scansPerTickReached)
        }
        guard state.totalObservationCount < UInt64.max else {
            throw AgentSessionError.ecologicalObservation(.sequenceOverflow)
        }
        try prevalidateCausalAppend(count: 1)
        try prepareDurableEvidenceForCausalAppend(count: 1)
        guard let preparedState = ecologicalObservationState else {
            throw AgentSessionError.ecologicalObservation(.disabled)
        }
        state = preparedState
        if state.transitionTick != tick {
            state.transitionTick = tick
            state.observationsAtTick = 0
        }
        let sequence = state.totalObservationCount + 1
        let event = try requiredEcologicalObservationEvent(
            kind: .ecologicalObservationRecorded,
            actorID: observation.observerID,
            subjectID: observation.observerID,
            causes: [state.lastObservationEventID],
            payload: .ecologicalObservation(
                observerID: observation.observerID.rawValue,
                worldContextKey: observation.worldContextKey,
                dimensionKey: observation.dimensionKey,
                resultCount: resultCount,
                worldReads: diagnostics.worldReads,
                truncated: diagnostics.completion != .complete,
                status: "recorded", digest: observation.digest
            ),
            summary: "ecological observation recorded observer=\(observation.observerID.rawValue) results=\(resultCount)"
        )
        let record = AgentEcologicalObservationRecord(
            sequence: sequence, observation: observation, causalEventID: event.eventID
        )
        state.observations.append(record)
        state.totalObservationCount = sequence
        state.lastObservationEventID = event.eventID
        state.observationsAtTick += 1
        evictEcologicalObservationsIfNeeded(&state)
        ecologicalObservationState = state
        return record
    }

    func validateEcologicalObservationStateIfEnabled() throws {
        guard let state = ecologicalObservationState else { return }
        _ = try validateEcologicalObservationState(
            state,
            activeAgents: Array(statesById.values),
            population: populationRegistry,
            mortality: mortalityState,
            agriculture: agricultureState,
            clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    private func ecologicalContextKeyIsValid(_ value: String) -> Bool {
        (1...160).contains(value.utf8.count)
            && value.utf8.allSatisfy { (33...126).contains($0) }
    }

    private mutating func evictEcologicalObservationsIfNeeded(
        _ state: inout AgentEcologicalObservationState
    ) {
        let grouped = Dictionary(grouping: state.observations.indices, by: {
            state.observations[$0].observation.observerID
        })
        var remove = Set<Int>()
        for indices in grouped.values {
            let excess = indices.count - state.configuration.maximumRetainedObservationsPerAgent
            if excess > 0 { remove.formUnion(indices.prefix(excess)) }
        }
        if state.observations.count - remove.count > state.configuration.maximumRetainedObservations {
            let remaining = state.observations.indices.filter { !remove.contains($0) }
            let excess = remaining.count - state.configuration.maximumRetainedObservations
            if excess > 0 { remove.formUnion(remaining.prefix(excess)) }
        }
        if !remove.isEmpty {
            state.observations = state.observations.enumerated().compactMap {
                remove.contains($0.offset) ? nil : $0.element
            }
            state.evictionCounts.observations += remove.count
        }
    }

    /// Evicts retained personal observations before the full death authority
    /// that proves their historical observer is compacted. The caller owns the
    /// enclosing candidate transaction; no partial state is published.
    mutating func evictEcologicalObservationsForCompactedDeaths(
        _ records: [AgentMortalityRecord]
    ) throws {
        guard var state = ecologicalObservationState, !records.isEmpty else {
            return
        }
        let agentIDs = Set(records.map(\.agentID))
        let removed = state.observations.reduce(into: 0) { count, record in
            if agentIDs.contains(record.observation.observerID) { count += 1 }
        }
        guard removed <= Int.max - state.evictionCounts.observations else {
            throw AgentSessionError.ecologicalObservation(
                .invalidState("mortality compaction eviction overflow")
            )
        }
        state.observations.removeAll {
            agentIDs.contains($0.observation.observerID)
        }
        state.evictionCounts.observations += removed
        ecologicalObservationState = state
    }

    private func ecologicalDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private mutating func requiredEcologicalObservationEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind, origin: .ecologicalObservationTransition,
            actorID: actorID, subjectID: subjectID, causes: causes,
            payload: payload, summary: summary
        ) else {
            throw AgentSessionError.ecologicalObservation(.causalLedgerRequired)
        }
        return event
    }
}

private enum HistoricalEcologicalObserverFailure: String {
    case historicalEvidenceUnavailable
    case registeredAfterObservation
    case diedBeforeObservation
    case causalBindingInvalid
    case unknownObserver
}

/// Canonical validation used both while publishing a candidate session and
/// while validating checkpoint durable state. A historical-person row alone
/// is deliberately insufficient: schema 29 requires either an active member
/// or the full retained death record with registration/death ordering.
func validateEcologicalObservationState(
    _ state: AgentEcologicalObservationState,
    activeAgents: [AgentSessionAgentState],
    population: AgentPopulationRegistry?,
    mortality: AgentMortalityState?,
    agriculture: AgentAgricultureState?,
    clock: AgentSimulationClock,
    causalLatestSequence: UInt64,
    causalDroppedEventCount _: UInt64,
    causalEvents: [AgentCausalEvent]
) throws -> [AgentHistoricalEcologicalObservationValidation] {
    func invalid(_ reason: String) -> AgentSessionError {
        .ecologicalObservation(.invalidState(reason))
    }
    var eventsByID: [AgentCausalEventID: AgentCausalEvent] = [:]
    for event in causalEvents {
        guard eventsByID.updateValue(event, forKey: event.eventID) == nil else {
            throw invalid("duplicate causal event")
        }
    }
    func registrationBindingIsValid(
        observerID: AgentID,
        registrationEventID: AgentCausalEventID,
        registeredTick: Int?,
        observationTick: Int,
        observationEventID: AgentCausalEventID
    ) -> Bool {
        guard registrationEventID.simulationID == clock.simulationID,
              registrationEventID.sequence.rawValue
                < observationEventID.sequence.rawValue else {
            return false
        }
        guard let event = eventsByID[registrationEventID] else { return false }
        guard event.simulationTick.rawValue <= observationTick,
              registeredTick == nil
                || event.simulationTick.rawValue == registeredTick else {
            return false
        }
        switch (event.kind, event.origin, event.payload) {
        case let (
            .populationMemberRegistered,
            .populationTransition,
            .population(
                _, memberID, _, _, _, _, _
            )
        ):
            return event.actorID == observerID
                && event.subjectID == observerID
                && memberID == observerID.rawValue
        case let (
            .populationMemberBorn,
            .lifecycleTransition,
            .birth(_, _, newbornID, _, _, _, _, _)
        ):
            return event.subjectID == observerID
                && newbornID == observerID.rawValue
        default:
            return false
        }
    }
    func deathBindingIsValid(
        _ death: AgentMortalityRecord,
        observationEventID: AgentCausalEventID
    ) -> Bool {
        guard death.deathEventID.simulationID == clock.simulationID,
              observationEventID.sequence.rawValue
                < death.deathEventID.sequence.rawValue else {
            return false
        }
        guard let event = eventsByID[death.deathEventID] else { return false }
        guard event.kind == .agentDeathFinalized,
              event.origin == .mortalityTransition,
              event.actorID == death.agentID,
              event.subjectID == death.agentID,
              event.simulationTick.rawValue == death.deathTick else {
            return false
        }
        guard case let .mortalityDeath(
            deathID, agentID, _, tick, _, _, _, _, _, _, _, _, _, _
        ) = event.payload else {
            return false
        }
        return deathID == death.deathID.rawValue
            && agentID == death.agentID.rawValue
            && tick == death.deathTick
    }
    guard let population else {
        throw invalid("population authority unavailable")
    }
    guard state.evictionCounts.observations >= 0,
          state.observations.count
            <= state.configuration.maximumRetainedObservations,
          state.totalObservationCount
            == UInt64(state.observations.count)
                + UInt64(state.evictionCounts.observations),
          state.observations.map(\.sequence)
            == state.observations.map(\.sequence).sorted(),
          Set(state.observations.map(\.sequence)).count
            == state.observations.count,
          state.observations.allSatisfy({
              $0.sequence > 0 && $0.sequence <= state.totalObservationCount
          }),
          state.transitionTick >= 0,
          state.transitionTick <= clock.tick.rawValue,
          state.observationsAtTick >= 0,
          state.observationsAtTick
            <= state.configuration.maximumScansPerSimulationTick else {
        throw invalid("bounds or ordering")
    }
    let counts = Dictionary(
        grouping: state.observations,
        by: { $0.observation.observerID }
    )
    guard counts.values.allSatisfy({
        $0.count <= state.configuration.maximumRetainedObservationsPerAgent
    }) else {
        throw invalid("per-agent retention")
    }

    func isAgricultureRetentionBoundary(_ event: AgentCausalEvent) -> Bool {
        guard let agriculture,
              event.eventID == agriculture.initializedEventID,
              event.kind == .agricultureInitialized,
              event.origin == .agricultureTransition,
              event.actorID == nil,
              event.subjectID == nil,
              event.operationID == nil,
              event.causes.isEmpty,
              case let .agriculture(
                  plotID, cellIndex, actionID, status,
                  physicalFingerprint, itemKey, quantity, digest
              ) = event.payload else {
            return false
        }
        return plotID == nil && cellIndex == nil && actionID == nil
            && status == "retentionBoundary" && physicalFingerprint == 0
            && itemKey == nil && quantity == agriculture.plots.count
            && digest == agricultureCausalRetentionDigest(
                agriculture,
                population: population,
                mortality: mortality
            )
    }
    func isEcologicalInitialization(_ event: AgentCausalEvent) -> Bool {
        guard event.kind == .ecologicalObservationInitialized,
              event.origin == .ecologicalObservationTransition,
              event.actorID == nil,
              event.subjectID == nil,
              event.operationID == nil,
              event.causes.isEmpty,
              case let .ecologicalObservation(
                  observer, world, dimension, results, reads, truncated,
                  status, digest
              ) = event.payload else {
            return false
        }
        return observer == nil && world == nil && dimension == nil
            && results >= 0 && reads == 0 && !truncated
            && ["initialized", "retentionBoundary"].contains(status)
            && digest.utf8.count == 16
    }
    guard state.initializedEventID.simulationID == clock.simulationID,
          state.lastObservationEventID.simulationID == clock.simulationID,
          state.initializedEventID.sequence.rawValue <= causalLatestSequence,
          state.lastObservationEventID.sequence.rawValue <= causalLatestSequence,
          let initializedEvent = eventsByID[state.initializedEventID],
          let lastEvent = eventsByID[state.lastObservationEventID],
          isEcologicalInitialization(initializedEvent)
            || isAgricultureRetentionBoundary(initializedEvent),
          (lastEvent.origin == .ecologicalObservationTransition
              && [.ecologicalObservationInitialized, .ecologicalObservationRecorded]
                .contains(lastEvent.kind))
            || isAgricultureRetentionBoundary(lastEvent) else {
        throw invalid("causal reference")
    }
    var activeByID: [AgentID: AgentSessionAgentState] = [:]
    for active in activeAgents {
        guard activeByID.updateValue(active, forKey: active.agentID) == nil else {
            throw invalid("duplicate active observer authority")
        }
    }
    var membersByID: [AgentID: AgentPopulationMemberRecord] = [:]
    for member in population.members {
        guard membersByID.updateValue(member, forKey: member.agentID) == nil else {
            throw invalid("duplicate population observer authority")
        }
    }
    let deathRecords = mortality?.records ?? []
    var deathsByID: [AgentID: AgentMortalityRecord] = [:]
    for death in deathRecords {
        guard deathsByID.updateValue(death, forKey: death.agentID) == nil else {
            throw invalid("duplicate retained death observer authority")
        }
    }
    let summaries = mortality?.compactedDeathSummaries ?? []
    let summaryIDs = Set(summaries.map(\.agentID))
    guard summaryIDs.count == summaries.count,
          Set(deathsByID.keys).isDisjoint(with: summaryIDs) else {
        throw invalid("duplicate historical authority")
    }

    var validations: [AgentHistoricalEcologicalObservationValidation] = []
    validations.reserveCapacity(state.observations.count)
    for record in state.observations {
        let observation = record.observation
        guard observation.observedAtSimulationTick >= 0,
              observation.observedAtSimulationTick <= clock.tick.rawValue,
              observation.civilDate == state.configuration.calendar.date(
                  atSimulationTick: observation.observedAtSimulationTick
              ),
              observation.physicalWorldTick >= 0,
              observation.physicalTime.worldTick
                == observation.physicalWorldTick,
              observation.expiresAtSimulationTick
                >= observation.observedAtSimulationTick,
              observation.expiresAtSimulationTick
                    - observation.observedAtSimulationTick
                <= state.configuration.dynamicFreshnessTicks,
              observation.hasValidDigest(),
              ecologicalObservationContextKeyIsValid(
                  observation.worldContextKey
              ),
              ecologicalObservationContextKeyIsValid(
                  observation.dimensionKey
              ),
              record.causalEventID.simulationID == clock.simulationID,
              record.causalEventID.sequence.rawValue <= causalLatestSequence,
              eventsByID[record.causalEventID] != nil else {
            throw invalid(
                "\(HistoricalEcologicalObserverFailure.causalBindingInvalid.rawValue) "
                    + "sequence=\(record.sequence)"
            )
        }

        let diagnostics = observation.diagnostics
        let resultCount = ecologicalObservationResultCount(observation)
        guard diagnostics.radius <= state.configuration.radius,
              diagnostics.cellsConsidered
                <= state.configuration.maximumCellsPerScan,
              diagnostics.worldReads
                <= state.configuration.maximumWorldReadsPerScan,
              diagnostics.chunksTouched
                <= state.configuration.maximumChunksPerScan,
              diagnostics.entitiesConsidered
                <= state.configuration.maximumEntitiesPerScan,
              diagnostics.resultsEmitted == resultCount,
              resultCount <= state.configuration.maximumResultsPerScan else {
            throw invalid("scan budget sequence=\(record.sequence)")
        }

        let event = eventsByID[record.causalEventID]!
        guard event.kind == .ecologicalObservationRecorded,
              event.origin == .ecologicalObservationTransition,
              event.actorID == observation.observerID,
              event.subjectID == observation.observerID,
              event.operationID == nil,
              event.simulationTick.rawValue
                == observation.observedAtSimulationTick,
              event.causes.count == 1,
              event.causes[0].simulationID == clock.simulationID,
              event.causes[0].sequence.rawValue
                < event.eventID.sequence.rawValue,
              let cause = eventsByID[event.causes[0]],
              (cause.origin == .ecologicalObservationTransition
                  && [.ecologicalObservationInitialized, .ecologicalObservationRecorded]
                    .contains(cause.kind))
                || isAgricultureRetentionBoundary(cause),
              event.payload == .ecologicalObservation(
                  observerID: observation.observerID.rawValue,
                  worldContextKey: observation.worldContextKey,
                  dimensionKey: observation.dimensionKey,
                  resultCount: resultCount,
                  worldReads: diagnostics.worldReads,
                  truncated: diagnostics.completion != .complete,
                  status: "recorded",
                  digest: observation.digest
              ) else {
            throw invalid(
                "\(HistoricalEcologicalObserverFailure.causalBindingInvalid.rawValue) "
                    + "sequence=\(record.sequence)"
            )
        }

        let observerID = observation.observerID
        let classification: AgentHistoricalEcologicalObserverClassification
        if let active = activeByID[observerID],
           let member = membersByID[observerID] {
            guard active.agentID == member.agentID,
                  deathsByID[observerID] == nil,
                  !summaryIDs.contains(observerID),
                  member.registeredTick
                    <= observation.observedAtSimulationTick,
                  registrationBindingIsValid(
                      observerID: observerID,
                      registrationEventID: member.registrationEventID,
                      registeredTick: member.registeredTick,
                      observationTick:
                        observation.observedAtSimulationTick,
                      observationEventID: record.causalEventID
                  ) else {
                throw invalid(
                    "\(HistoricalEcologicalObserverFailure.registeredAfterObservation.rawValue) "
                        + "observer=\(observerID.rawValue)"
                )
            }
            classification = .activeAtObservation
        } else if activeByID[observerID] != nil
                    || membersByID[observerID] != nil {
            throw invalid(
                "\(HistoricalEcologicalObserverFailure.unknownObserver.rawValue) "
                    + "observer=\(observerID.rawValue)"
            )
        } else if let death = deathsByID[observerID] {
            guard !summaryIDs.contains(observerID),
                  registrationBindingIsValid(
                      observerID: observerID,
                      registrationEventID: death.registrationEventID,
                      registeredTick: nil,
                      observationTick:
                        observation.observedAtSimulationTick,
                      observationEventID: record.causalEventID
                  ) else {
                throw invalid(
                    "\(HistoricalEcologicalObserverFailure.registeredAfterObservation.rawValue) "
                        + "observer=\(observerID.rawValue)"
                )
            }
            guard record.causalEventID.sequence.rawValue
                    < death.deathEventID.sequence.rawValue,
                  observation.observedAtSimulationTick <= death.deathTick,
                  deathBindingIsValid(
                      death,
                      observationEventID: record.causalEventID
                  ) else {
                throw invalid(
                    "\(HistoricalEcologicalObserverFailure.diedBeforeObservation.rawValue) "
                        + "observer=\(observerID.rawValue)"
                )
            }
            classification = .deceasedAfterObservationRetained
        } else if summaryIDs.contains(observerID) {
            throw invalid(
                "\(HistoricalEcologicalObserverFailure.historicalEvidenceUnavailable.rawValue) "
                    + "observer=\(observerID.rawValue)"
            )
        } else {
            throw invalid(
                "\(HistoricalEcologicalObserverFailure.unknownObserver.rawValue) "
                    + "observer=\(observerID.rawValue)"
            )
        }
        validations.append(AgentHistoricalEcologicalObservationValidation(
            sequence: record.sequence,
            observerID: observerID,
            classification: classification
        ))
    }
    return validations
}

private func ecologicalObservationContextKeyIsValid(_ value: String) -> Bool {
    (1...160).contains(value.utf8.count)
        && value.utf8.allSatisfy { (33...126).contains($0) }
}

private func ecologicalObservationResultCount(
    _ observation: AgentEcologicalObservation
) -> Int {
    observation.water.count + observation.soils.count
        + observation.crops.count + observation.plants.count
        + observation.animals.count + observation.fishing.count
        + (observation.biome == nil ? 0 : 1) + 2
}
