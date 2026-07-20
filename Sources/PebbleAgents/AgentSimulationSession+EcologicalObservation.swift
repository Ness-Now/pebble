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
        ecologicalObservationState?.observations.filter {
            $0.observation.observerID == observerID
                && (!freshOnly || $0.observation.isFresh(atSimulationTick: tick))
        }.sorted { $0.sequence > $1.sequence } ?? []
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
        guard state.totalObservationCount >= UInt64(state.observations.count),
              state.observations.count <= state.configuration.maximumRetainedObservations,
              state.observations.map(\.sequence) == state.observations.map(\.sequence).sorted(),
              Set(state.observations.map(\.sequence)).count == state.observations.count,
              state.observations.allSatisfy({ $0.observation.hasValidDigest() }),
              state.transitionTick <= tick,
              state.observationsAtTick >= 0,
              state.observationsAtTick <= state.configuration.maximumScansPerSimulationTick else {
            throw AgentSessionError.ecologicalObservation(.invalidState("bounds or ordering"))
        }
        let counts = Dictionary(grouping: state.observations, by: { $0.observation.observerID })
        guard counts.values.allSatisfy({
            $0.count <= state.configuration.maximumRetainedObservationsPerAgent
        }) else {
            throw AgentSessionError.ecologicalObservation(.invalidState("per-agent retention"))
        }
        let eventIDs = Set(causalLedger.events.map(\.eventID))
        guard ecologicalCausalReferenceExists(state.initializedEventID, retained: eventIDs),
              ecologicalCausalReferenceExists(state.lastObservationEventID, retained: eventIDs),
              state.observations.allSatisfy({
                  ecologicalCausalReferenceExists($0.causalEventID, retained: eventIDs)
              }) else {
            throw AgentSessionError.ecologicalObservation(.invalidState("causal reference"))
        }
    }

    private func ecologicalCausalReferenceExists(
        _ eventID: AgentCausalEventID,
        retained: Set<AgentCausalEventID>
    ) -> Bool {
        retained.contains(eventID)
            || eventID.sequence.rawValue <= causalLedger.droppedEventCount
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
