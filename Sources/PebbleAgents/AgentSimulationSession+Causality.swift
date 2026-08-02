@_spi(Testing)
public enum AgentCausalRetentionFaultPoint: String, CaseIterable, Sendable {
    case afterFirstEcologicalRowEviction
    case afterEcologicalEvictionCounterUpdate
    case afterEcologicalValidation
    case afterCausalAppend
    case afterCausalCompaction
}

extension AgentSimulationSession {
    func prevalidateCausalAppend(count: Int) throws {
        try causalLedger.prevalidateAppend(count: count)
    }

    /// Coordinates bounded causal retention with durable product evidence.
    /// Every append path passes here through `recordCausalEvent`, including
    /// subsystem-specific required-event helpers.
    mutating func prepareDurableEvidenceForCausalAppend(
        count: Int,
        testFault: AgentCausalRetentionFaultPoint? = nil
    ) throws {
        guard count > 0, causalLedger.isEnabled else { return }
        let originalLedger = causalLedger
        let originalEcology = ecologicalObservationState
        let originalAgriculture = agricultureState
        do {
            var attempts = 0
            let attemptLimit = causalLedger.events.count + count + 2
            while true {
                attempts += 1
                guard attempts <= attemptLimit else {
                    throw AgentSessionError.ecologicalObservation(
                        .invalidState("causal retention boundary convergence")
                    )
                }
                let leaving = try causalLedger.eventsEvictedByAppending(
                    count: count
                )
                if try appendAgricultureRetentionBoundaryIfNeeded(
                    beforeEvicting: leaving,
                    testFault: testFault
                ) {
                    continue
                }
                try evictEcologicalRowsDependingOn(
                    leaving,
                    testFault: testFault
                )
                guard let ecology = ecologicalObservationState,
                      leaving.contains(where: {
                          $0.eventID == ecology.initializedEventID
                              || $0.eventID == ecology.lastObservationEventID
                      }) else {
                    break
                }
                try appendEcologicalRetentionBoundary(testFault: testFault)
            }
            try validateRetainedEcologicalCausalEvidence()
            try injectCausalRetentionFault(
                testFault,
                at: .afterEcologicalValidation
            )
        } catch {
            causalLedger = originalLedger
            ecologicalObservationState = originalEcology
            agricultureState = originalAgriculture
            throw error
        }
    }

    @discardableResult
    mutating func recordCausalEvent(
        kind: AgentCausalEventKind,
        origin: AgentCausalOrigin,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String,
        instant: AgentSimulationInstant? = nil,
        testFault: AgentCausalRetentionFaultPoint? = nil
    ) throws -> AgentCausalEvent? {
        let originalLedger = causalLedger
        let originalEcology = ecologicalObservationState
        let originalAgriculture = agricultureState
        do {
            try prepareDurableEvidenceForCausalAppend(
                count: 1,
                testFault: testFault
            )
            return try causalLedger.append(
                instant: instant ?? simulationInstant,
                kind: kind,
                origin: origin,
                actorID: actorID,
                subjectID: subjectID,
                operationID: operationID,
                causes: causes,
                payload: payload,
                summary: summary,
                afterEventAppended: {
                    try Self.injectCausalRetentionFault(
                        testFault,
                        at: .afterCausalAppend
                    )
                },
                afterCompaction: {
                    try Self.injectCausalRetentionFault(
                        testFault,
                        at: .afterCausalCompaction
                    )
                }
            )
        } catch {
            causalLedger = originalLedger
            ecologicalObservationState = originalEcology
            agricultureState = originalAgriculture
            throw error
        }
    }

    private mutating func evictEcologicalRowsDependingOn(
        _ leaving: [AgentCausalEvent],
        testFault: AgentCausalRetentionFaultPoint? = nil
    ) throws {
        guard var state = ecologicalObservationState, !leaving.isEmpty else {
            return
        }
        let leavingIDs = Set(leaving.map(\.eventID))
        let eventsByID = Dictionary(
            uniqueKeysWithValues: causalLedger.events.map {
                ($0.eventID, $0)
            }
        )
        let activeIDs = Set(statesById.values.map(\.agentID))
        let populationByID = Dictionary(
            uniqueKeysWithValues: (populationRegistry?.members ?? []).map {
                ($0.agentID, $0)
            }
        )
        let deathsByID = Dictionary(
            uniqueKeysWithValues: (mortalityState?.records ?? []).map {
                ($0.agentID, $0)
            }
        )
        var removed = 0
        var retained: [AgentEcologicalObservationRecord] = []
        retained.reserveCapacity(state.observations.count)
        for record in state.observations {
            var required = Set<AgentCausalEventID>()
            required.insert(record.causalEventID)
            guard let event = eventsByID[record.causalEventID] else {
                retained.append(record)
                continue
            }
            required.formUnion(event.causes)
            let observerID = record.observation.observerID
            if activeIDs.contains(observerID),
               let member = populationByID[observerID],
               deathsByID[observerID] == nil {
                required.insert(member.registrationEventID)
            } else if let death = deathsByID[observerID],
                      !activeIDs.contains(observerID),
                      populationByID[observerID] == nil {
                required.insert(death.registrationEventID)
                required.insert(death.deathEventID)
            }
            if !required.isDisjoint(with: leavingIDs) {
                removed += 1
                try injectCausalRetentionFault(
                    testFault,
                    at: .afterFirstEcologicalRowEviction,
                    when: removed == 1
                )
            } else {
                retained.append(record)
            }
        }
        guard removed <= Int.max - state.evictionCounts.observations else {
            throw AgentSessionError.ecologicalObservation(
                .invalidState("causal retention eviction overflow")
            )
        }
        state.observations = retained
        state.evictionCounts.observations += removed
        ecologicalObservationState = state
        try injectCausalRetentionFault(
            testFault,
            at: .afterEcologicalEvictionCounterUpdate,
            when: removed > 0
        )
    }

    private mutating func appendEcologicalRetentionBoundary(
        testFault: AgentCausalRetentionFaultPoint? = nil
    ) throws {
        guard var state = ecologicalObservationState else { return }
        let leaving = try causalLedger.eventsEvictedByAppending(count: 1)
        if try appendAgricultureRetentionBoundaryIfNeeded(
            beforeEvicting: leaving,
            testFault: testFault
        ) {
            try appendEcologicalRetentionBoundary(testFault: testFault)
            return
        }
        try evictEcologicalRowsDependingOn(leaving, testFault: testFault)
        state = ecologicalObservationState ?? state
        let retained = state.observations.map {
            "\($0.sequence):\($0.causalEventID.rawValue):\($0.observation.digest)"
        }.joined(separator: ";")
        let digest = AgentEcologicalObservationDigest.make(
            "causalRetentionBoundary|tick=\(tick)|total=\(state.totalObservationCount)"
                + "|evicted=\(state.evictionCounts.observations)|retained=\(retained)"
        )
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .ecologicalObservationInitialized,
            origin: .ecologicalObservationTransition,
            actorID: nil,
            subjectID: nil,
            operationID: nil,
            causes: [],
            payload: .ecologicalObservation(
                observerID: nil,
                worldContextKey: nil,
                dimensionKey: nil,
                physicalReceiptID: nil,
                resultCount: state.observations.count,
                worldReads: 0,
                truncated: false,
                status: "retentionBoundary",
                digest: digest
            ),
            summary: "ecological observation causal retention boundary retained=\(state.observations.count)",
            afterEventAppended: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterCausalAppend
                )
            },
            afterCompaction: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterCausalCompaction
                )
            }
        ) else {
            throw AgentSessionError.ecologicalObservation(
                .causalLedgerRequired
            )
        }
        state.initializedEventID = event.eventID
        state.lastObservationEventID = event.eventID
        ecologicalObservationState = state
        try validateRetainedEcologicalCausalEvidence()
    }

    private static func injectCausalRetentionFault(
        _ requested: AgentCausalRetentionFaultPoint?,
        at point: AgentCausalRetentionFaultPoint,
        when condition: Bool = true
    ) throws {
        guard condition, requested == point else { return }
        throw AgentSessionError.ecologicalObservation(
            .invalidState("injected causal retention fault \(point.rawValue)")
        )
    }

    private func injectCausalRetentionFault(
        _ requested: AgentCausalRetentionFaultPoint?,
        at point: AgentCausalRetentionFaultPoint,
        when condition: Bool = true
    ) throws {
        try Self.injectCausalRetentionFault(
            requested,
            at: point,
            when: condition
        )
    }

    @_spi(Testing)
    public mutating func appendCausalRetentionTestEvent(
        failingAt fault: AgentCausalRetentionFaultPoint? = nil
    ) throws {
        try recordCausalEvent(
            kind: .sessionLifecycle,
            origin: .lifecycle,
            payload: .lifecycle(
                status: "causal-retention-test",
                agentCount: statesById.count
            ),
            summary: "causal retention test event",
            testFault: fault
        )
    }

    /// This check is deliberately limited to the causal-retention contract.
    /// A multi-domain candidate may be between population removal and death
    /// publication while recording its mortality events; the complete
    /// historical-observer validation runs at the owning transaction boundary.
    private func validateRetainedEcologicalCausalEvidence() throws {
        guard let state = ecologicalObservationState else { return }
        let retained = Dictionary(
            uniqueKeysWithValues: causalLedger.events.map { ($0.eventID, $0) }
        )
        guard retained[state.initializedEventID] != nil,
              retained[state.lastObservationEventID] != nil,
              state.observations.allSatisfy({ record in
                  guard let event = retained[record.causalEventID] else {
                      return false
                  }
                  return event.causes.allSatisfy { retained[$0] != nil }
              }) else {
            throw AgentSessionError.ecologicalObservation(
                .invalidState("retained causal evidence unavailable")
            )
        }
    }

    /// Long-lived plot foundations remain operational rather than becoming an
    /// unbounded pin on the FIFO causal suffix. Before their exact source
    /// events leave, this boundary records a canonical digest of every
    /// immutable plot foundation and moves the mutable authority pointers to
    /// the new retained event. Historical action and receipt rows are not
    /// summarized here: their exact events remain mandatory and capacity is
    /// refused atomically if one would leave.
    private mutating func appendAgricultureRetentionBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent],
        testFault: AgentCausalRetentionFaultPoint?
    ) throws -> Bool {
        guard var agriculture = agricultureState, !leaving.isEmpty else {
            return false
        }
        let leavingIDs = Set(leaving.map(\.eventID))
        var exactHistorical: Set<AgentCausalEventID> = []
        var refreshable: Set<AgentCausalEventID> = [
            agriculture.initializedEventID, agriculture.lastAgricultureEventID,
        ]
        func authorityIDs(for agentID: AgentID) -> [AgentCausalEventID] {
            if let member = populationRegistry?.members.first(where: {
                $0.agentID == agentID
            }) {
                return [member.registrationEventID]
            }
            if let death = mortalityState?.records.first(where: {
                $0.agentID == agentID
            }) {
                return [death.registrationEventID, death.deathEventID]
            }
            return []
        }
        for plot in agriculture.plots {
            refreshable.insert(plot.sourceObservationEventID)
            refreshable.insert(plot.lastAgricultureEventID)
            refreshable.formUnion(plot.cells.compactMap(\.lastWorkEventID))
            if let renewal = plot.renewalEvidence {
                exactHistorical.insert(renewal.renewalEventID)
            }
            refreshable.formUnion(authorityIDs(for: plot.plannerID))
        }
        for record in agriculture.retainedActions {
            exactHistorical.insert(record.agricultureEventID)
            if let skill = record.skillPracticeEventID {
                exactHistorical.insert(skill)
            }
            if let observation = record.outcome.sourceObservationEventID {
                exactHistorical.insert(observation)
            }
            exactHistorical.formUnion(authorityIDs(for: record.outcome.actorID))
        }
        for surplus in agriculture.managedSurplusRecords {
            exactHistorical.insert(surplus.agricultureEventID)
        }
        let eventsByID = Dictionary(
            uniqueKeysWithValues: causalLedger.events.map {
                ($0.eventID, $0)
            }
        )
        for eventID in Array(exactHistorical) {
            guard let event = eventsByID[eventID] else {
                throw AgentSessionError.agriculture(
                    .invalidState("retained agriculture causal event unavailable")
                )
            }
            exactHistorical.formUnion(event.causes)
        }
        guard exactHistorical.isDisjoint(with: leavingIDs) else {
            throw AgentSessionError.agriculture(
                .invalidState("retained agriculture causal evidence capacity")
            )
        }
        guard !refreshable.isDisjoint(with: leavingIDs) else { return false }

        try evictEcologicalRowsDependingOn(leaving, testFault: testFault)
        guard causalLedger.latestSequence < UInt64.max,
              let sequence = AgentCausalSequence(
                  rawValue: causalLedger.latestSequence + 1
              ) else {
            throw AgentSessionError.agriculture(.invalidState("causal sequence"))
        }
        let eventID = AgentCausalEventID(
            simulationID: simulationID,
            sequence: sequence
        )
        agriculture.initializedEventID = eventID
        agriculture.lastAgricultureEventID = eventID
        for plotIndex in agriculture.plots.indices {
            if leavingIDs.contains(
                agriculture.plots[plotIndex].lastAgricultureEventID
            ) && !exactHistorical.contains(
                agriculture.plots[plotIndex].lastAgricultureEventID
            ) {
                agriculture.plots[plotIndex].lastAgricultureEventID = eventID
            }
            for cellIndex in agriculture.plots[plotIndex].cells.indices {
                if let workEvent = agriculture.plots[plotIndex]
                    .cells[cellIndex].lastWorkEventID,
                   leavingIDs.contains(workEvent),
                   !exactHistorical.contains(workEvent) {
                    agriculture.plots[plotIndex].cells[cellIndex]
                        .lastWorkEventID = eventID
                }
            }
        }
        let digest = agricultureCausalRetentionDigest(
            agriculture,
            population: populationRegistry,
            mortality: mortalityState
        )
        guard var ecology = ecologicalObservationState else {
            throw AgentSessionError.agriculture(.ecologicalObservationRequired)
        }
        ecology.initializedEventID = eventID
        ecology.lastObservationEventID = eventID
        ecologicalObservationState = ecology
        agricultureState = agriculture
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .agricultureInitialized,
            origin: .agricultureTransition,
            payload: .agriculture(
                plotID: nil,
                cellIndex: nil,
                actionID: nil,
                status: "retentionBoundary",
                physicalFingerprint: 0,
                itemKey: nil,
                quantity: agriculture.plots.count,
                digest: digest
            ),
            summary: "durable agriculture causal retention boundary",
            afterEventAppended: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterCausalAppend
                )
            },
            afterCompaction: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterCausalCompaction
                )
            }
        ), event.eventID == eventID else {
            throw AgentSessionError.agriculture(.causalLedgerRequired)
        }
        try validateRetainedEcologicalCausalEvidence()
        try validateAgricultureStateIfEnabled()
        return true
    }

    mutating func recordFeatureToggle(name: String, enabled: Bool) {
        try! recordCausalEvent(
            kind: .featureToggle,
            origin: .session,
            payload: .feature(name: name, enabled: enabled),
            summary: "\(name) \(enabled ? "enabled" : "disabled")"
        )
    }

    @discardableResult
    mutating func recordAcceptedOperation(
        kind: AgentCausalEventKind,
        agentId: String,
        operationId: String,
        status: String,
        detail: String,
        origin: AgentCausalOrigin = .worldOutcome,
        extraCauses: [AgentCausalEventID] = []
    ) -> AgentCausalEventID? {
        guard let agentID = AgentID(rawValue: agentId) else { return nil }
        let cause: AgentCausalEventID?
        switch kind {
        case .constructionPlacement, .constructionCompletion, .constructionClear:
            cause = lastConstructionEventID
        case .constructionFunding:
            cause = lastOutcomeEventByAgentID[agentID] ?? lastDecisionEventByAgentID[agentID]
        case .interaction, .delivery, .consumption, .physicalFoodConsumed:
            cause = lastOutcomeEventByAgentID[agentID] ?? lastDecisionEventByAgentID[agentID]
        default:
            cause = lastDecisionEventByAgentID[agentID]
        }
        let causes = Array(Set(extraCauses + (cause.map { [$0] } ?? []))).sorted()
        let event = try! recordCausalEvent(
            kind: kind,
            origin: origin,
            actorID: agentID,
            operationID: AgentOperationID(rawValue: operationId),
            causes: Array(causes.prefix(AgentCausalEvent.maximumCauseCount)),
            payload: .operation(status: String(status.prefix(64)), detail: String(detail.prefix(160))),
            summary: "\(kind.rawValue) \(status) actor=\(agentId)"
        )
        guard let eventID = event?.eventID else { return nil }
        lastOutcomeEventByAgentID[agentID] = eventID
        if kind == .constructionFunding || kind == .constructionPlacement
            || kind == .constructionCompletion || kind == .constructionClear {
            lastConstructionEventID = eventID
        }
        return eventID
    }
}
