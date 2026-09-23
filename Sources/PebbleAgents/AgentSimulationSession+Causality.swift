@_spi(Testing)
public enum AgentCausalRetentionFaultPoint: String, CaseIterable, Sendable {
    case afterMortalityStateBeforeMembershipAuthorityRefresh
    case afterMortalityMembershipValidationBeforePublication
    case beforePopulationMembershipAuthorityPublication
    case afterPopulationMembershipAuthorityCausalAppend
    case afterPopulationMembershipAuthorityPublication
    case afterMembershipEcologicalDependencyCalculation
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
        let originalPopulation = populationRegistry
        let originalEcology = ecologicalObservationState
        let originalAgriculture = agricultureState
        let originalKnowledge = knowledgeGraphState
        let originalLanguage = languageState
        let originalWriting = writingState
        let originalArchive = archiveState
        let originalCulture = distributedCultureState
        let originalOral = oralTransmissionState
        let originalLongDistanceCommunication =
            longDistanceCommunicationState
        do {
            var attempts = 0
            let attemptLimit = causalLedger.events.count + count + 4
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
                // Remove rows that require evidence which is about to leave
                // while that evidence is still exact. Membership refresh then
                // precedes every other boundary append, so another boundary
                // cannot compact the active-membership authority first.
                try evictEcologicalRowsDependingOn(
                    leaving,
                    testFault: testFault
                )
                if try appendPopulationMembershipAuthorityBoundaryIfNeeded(
                    beforeEvicting: leaving,
                    testFault: testFault
                ) {
                    continue
                }
                if try appendKnowledgeHistoricalAuthorityBoundaryIfNeeded(
                    beforeEvicting: leaving
                ) {
                    continue
                }
                if try appendLanguageProvenanceBoundaryIfNeeded(
                    beforeEvicting: leaving
                ) {
                    continue
                }
                if try appendOralProvenanceBoundaryIfNeeded(
                    beforeEvicting: leaving
                ) {
                    continue
                }
                if try appendLongDistanceCommunicationProvenanceBoundaryIfNeeded(
                    beforeEvicting: leaving
                ) {
                    continue
                }
                if try appendWritingBoundaryIfNeeded(beforeEvicting: leaving) {
                    continue
                }
                if try appendArchiveBoundaryIfNeeded(beforeEvicting: leaving) {
                    continue
                }
                if try appendCultureBoundaryIfNeeded(beforeEvicting: leaving) {
                    continue
                }
                if try appendAgricultureRetentionBoundaryIfNeeded(
                    beforeEvicting: leaving,
                    testFault: testFault
                ) {
                    continue
                }
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
            populationRegistry = originalPopulation
            ecologicalObservationState = originalEcology
            agricultureState = originalAgriculture
            knowledgeGraphState = originalKnowledge
            languageState = originalLanguage
            writingState = originalWriting
            archiveState = originalArchive
            distributedCultureState = originalCulture
            oralTransmissionState = originalOral
            longDistanceCommunicationState =
                originalLongDistanceCommunication
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
        let originalPopulation = populationRegistry
        let originalEcology = ecologicalObservationState
        let originalAgriculture = agricultureState
        let originalKnowledge = knowledgeGraphState
        let originalLanguage = languageState
        let originalWriting = writingState
        let originalArchive = archiveState
        let originalCulture = distributedCultureState
        let originalOral = oralTransmissionState
        let originalLongDistanceCommunication =
            longDistanceCommunicationState
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
            populationRegistry = originalPopulation
            ecologicalObservationState = originalEcology
            agricultureState = originalAgriculture
            knowledgeGraphState = originalKnowledge
            languageState = originalLanguage
            writingState = originalWriting
            archiveState = originalArchive
            distributedCultureState = originalCulture
            oralTransmissionState = originalOral
            longDistanceCommunicationState =
                originalLongDistanceCommunication
            throw error
        }
    }

    func populationMembershipAuthorityRows(
        _ registry: AgentPopulationRegistry
    ) -> [AgentPopulationMembershipAuthorityMember] {
        Self.populationMembershipAuthorityRows(registry)
    }

    func populationMembershipAuthorityDigest(
        _ members: [AgentPopulationMembershipAuthorityMember]
    ) -> String {
        Self.populationMembershipAuthorityDigest(
            members, simulationID: simulationID
        )
    }

    func populationMembershipAuthorityEventIsValid(
        _ event: AgentCausalEvent,
        expectedMembers: [AgentPopulationMembershipAuthorityMember]? = nil
    ) -> Bool {
        guard event.kind == .populationMembershipAuthorityRetained,
              event.origin == .populationTransition,
              event.actorID == nil,
              event.subjectID == nil,
              event.operationID == nil,
              case let .populationMembershipAuthority(members, digest) =
                event.payload,
              !members.isEmpty,
              members == members.sorted(by: { lhs, rhs in
                  if lhs.ordinal != rhs.ordinal {
                      return lhs.ordinal < rhs.ordinal
                  }
                  return lhs.agentID < rhs.agentID
              }),
              Set(members.map(\.agentID)).count == members.count,
              Set(members.map(\.ordinal)).count == members.count,
              members.allSatisfy({
                  $0.registrationEventID.simulationID == simulationID
                      && $0.registeredTick >= 0
                      && $0.registeredTick <= event.simulationTick.rawValue
              }),
              digest == populationMembershipAuthorityDigest(members),
              expectedMembers.map({ $0 == members }) ?? true else {
            return false
        }
        return true
    }

    /// Refreshes one bounded projection event, never the immutable original
    /// registration identities. This is schema-44-only; schemas 1...43 retain
    /// their exact historical causal contract.
    private mutating func appendPopulationMembershipAuthorityBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent],
        testFault: AgentCausalRetentionFaultPoint?
    ) throws -> Bool {
        guard legacyTemporalSchemaVersionOverride == nil,
              let registry = populationRegistry,
              !registry.members.isEmpty,
              !leaving.isEmpty else { return false }
        let leavingIDs = Set(leaving.map(\.eventID))
        let needsInitialAuthority =
            registry.currentMembershipAuthorityEventID == nil
                && registry.members.contains {
                    leavingIDs.contains($0.registrationEventID)
                }
        let currentAuthorityLeaves =
            registry.currentMembershipAuthorityEventID.map {
                leavingIDs.contains($0)
            } ?? false
        guard needsInitialAuthority || currentAuthorityLeaves else {
            return false
        }
        try appendPopulationMembershipAuthorityBoundary(
            membershipCauseEventID: registry.lastPopulationEventID,
            testFault: testFault
        )
        return true
    }

    private mutating func appendPopulationMembershipAuthorityBoundary(
        membershipCauseEventID: AgentCausalEventID?,
        testFault: AgentCausalRetentionFaultPoint?
    ) throws {
        guard var registry = populationRegistry else {
            throw AgentSessionError.population(.disabled)
        }
        let members = populationMembershipAuthorityRows(registry)
        guard !members.isEmpty,
              members.count <= registry.configuration.maximumActivePopulation
        else {
            throw AgentSessionError.population(
                .invalidMembershipAuthority("projection")
            )
        }
        let retainedIDs = Set(causalLedger.events.map(\.eventID))
        let priorAuthority = registry.currentMembershipAuthorityEventID
        let causes = Array(Set([
            priorAuthority,
            membershipCauseEventID,
            priorAuthority == nil ? registry.initializedEventID : nil,
        ].compactMap { $0 }).filter {
            retainedIDs.contains($0)
        }).sorted()
        try injectCausalRetentionFault(
            testFault,
            at: .beforePopulationMembershipAuthorityPublication
        )
        let digest = populationMembershipAuthorityDigest(members)
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .populationMembershipAuthorityRetained,
            origin: .populationTransition,
            actorID: nil,
            subjectID: nil,
            operationID: nil,
            causes: Array(causes.prefix(AgentCausalEvent.maximumCauseCount)),
            payload: .populationMembershipAuthority(
                members: members,
                digest: digest
            ),
            summary: "active population membership retention boundary members=\(members.count)",
            afterEventAppended: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterPopulationMembershipAuthorityCausalAppend
                )
            },
            afterCompaction: {
                try Self.injectCausalRetentionFault(
                    testFault,
                    at: .afterCausalCompaction
                )
            }
        ), populationMembershipAuthorityEventIsValid(
            event,
            expectedMembers: members
        ) else {
            throw AgentSessionError.population(
                .invalidMembershipAuthority("event")
            )
        }
        registry.currentMembershipAuthorityEventID = event.eventID
        registry.lastPopulationEventID = event.eventID
        populationRegistry = registry
        try injectCausalRetentionFault(
            testFault,
            at: .afterPopulationMembershipAuthorityPublication
        )
    }

    /// Membership additions/removals change the projection. If a retained
    /// authority already exists because original registrations have compacted,
    /// replace it immediately through the ordinary causal ledger.
    mutating func refreshPopulationMembershipAuthorityAfterMembershipChange(
        causedBy eventID: AgentCausalEventID,
        testFault: AgentCausalRetentionFaultPoint? = nil
    ) throws {
        guard legacyTemporalSchemaVersionOverride == nil,
              let currentID = populationRegistry?
                .currentMembershipAuthorityEventID else { return }
        let originalLedger = causalLedger
        let originalPopulation = populationRegistry
        let originalEcology = ecologicalObservationState
        do {
            if let current = causalLedger.events.first(where: {
                $0.eventID == currentID
            }) {
                // Active survivors must move to the refreshed projection, so
                // their older observations cannot continue to depend on this
                // authority. Departed observers are different: mortality has
                // captured this exact authority in their terminal record and
                // it remains the causal proof for observations made before
                // death. The ordinary retention coordinator will evict those
                // rows before this authority itself later leaves the ledger.
                let departedObserverIDs = Set(
                    mortalityState?.records.map(\.agentID) ?? []
                ).union(
                    mortalityState?.compactedDeathSummaries?.map(\.agentID)
                        ?? []
                )
                try evictEcologicalRowsDependingOn(
                    [current],
                    preservingObservers: departedObserverIDs,
                    testFault: testFault
                )
            }
            if let registry = populationRegistry,
               populationMembershipAuthorityRows(registry).isEmpty {
                // The registry remains the membership authority. With no
                // active members there is no active projection to publish;
                // mortality records retain the predecessor event needed by
                // pre-death historical evidence.
                populationRegistry?.currentMembershipAuthorityEventID = nil
                return
            }
            try prepareDurableEvidenceForCausalAppend(count: 1)
            if let refreshedID = populationRegistry?
                .currentMembershipAuthorityEventID,
               let refreshed = causalLedger.events.first(where: {
                   $0.eventID == refreshedID
               }),
               let registry = populationRegistry,
               populationMembershipAuthorityEventIsValid(
                   refreshed,
                   expectedMembers: populationMembershipAuthorityRows(registry)
               ) {
                return
            }
            try appendPopulationMembershipAuthorityBoundary(
                membershipCauseEventID: eventID,
                testFault: testFault
            )
        } catch {
            causalLedger = originalLedger
            populationRegistry = originalPopulation
            ecologicalObservationState = originalEcology
            throw error
        }
    }

    private mutating func appendWritingBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard let state = writingState, let boundary = state.boundary,
              leaving.contains(where: { $0.eventID == boundary.eventID }) else { return false }
        let digest = writingBoundaryDigest(state)
        guard let event = try causalLedger.append(
            instant: simulationInstant, kind: .writingProvenanceBoundary,
            origin: .writingTransition, actorID: nil, subjectID: nil,
            causes: [boundary.eventID],
            payload: .writing(recordID: "writing", detail: digest),
            summary: "writing provenance retention boundary"
        ) else { throw AgentWritingError.unavailable("causal writing retention") }
        writingState!.boundary = AgentWritingBoundary(eventID: event.eventID, digest: digest)
        return true
    }

    private mutating func appendArchiveBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard let state = archiveState, let boundary = state.boundary,
              leaving.contains(where: { $0.eventID == boundary.eventID }) else {
            return false
        }
        let digest = archiveBoundaryDigest(state)
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .archiveProvenanceBoundary,
            origin: .archiveTransition,
            actorID: nil,
            subjectID: nil,
            causes: [boundary.eventID],
            payload: .archive(recordID: "archive", detail: digest),
            summary: "archive provenance retention boundary"
        ) else {
            throw AgentArchiveError.unavailable("causal archive retention")
        }
        archiveState!.boundary = AgentArchiveBoundary(
            eventID: event.eventID,
            digest: digest
        )
        return true
    }

    private mutating func appendCultureBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard let state = distributedCultureState,
              let boundary = state.boundary,
              leaving.contains(where: { $0.eventID == boundary.eventID }) else {
            return false
        }
        let digest = cultureBoundaryDigest(state)
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .cultureProvenanceBoundary,
            origin: .cultureTransition,
            actorID: nil,
            subjectID: nil,
            causes: [boundary.eventID],
            payload: .culture(
                recordID: "distributed-culture",
                practiceID: nil,
                status: "provenanceBoundary",
                detail: digest
            ),
            summary: "distributed culture provenance retention boundary"
        ) else {
            throw AgentSessionError.culture(.causalLedgerRequired)
        }
        distributedCultureState!.boundary = AgentCultureBoundary(
            eventID: event.eventID,
            digest: digest
        )
        return true
    }

    /// CIV-41's bounded historical authority set always has one exact retained
    /// causal commitment. Refresh it while the previous commitment is still
    /// exact, before FIFO compaction removes that event.
    private mutating func appendKnowledgeHistoricalAuthorityBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard var state = knowledgeGraphState,
              let authorities = state.historicalBeliefAuthorities,
              !authorities.isEmpty,
              !leaving.isEmpty else { return false }
        let leavingIDs = Set(leaving.map(\.eventID))
        let boundaryIsLeaving = state.historicalBeliefAuthorityBoundary.map {
            leavingIDs.contains($0.eventID)
        } ?? false
        let uncommittedSourceIsLeaving =
            state.historicalBeliefAuthorityBoundary == nil
                && authorities.contains {
                    leavingIDs.contains($0.sourceBeliefRevisionEventID)
                }
        guard boundaryIsLeaving || uncommittedSourceIsLeaving else {
            return false
        }
        let digest = knowledgeHistoricalAuthorityBoundaryDigest(authorities)
        let causes = state.historicalBeliefAuthorityBoundary.map {
            [$0.eventID]
        } ?? authorities.compactMap {
            leavingIDs.contains($0.sourceBeliefRevisionEventID)
                ? $0.sourceBeliefRevisionEventID : nil
        }
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .knowledgeGraphInitialized,
            origin: .knowledgeTransition,
            actorID: nil,
            subjectID: nil,
            causes: Array(Set(causes)).sorted(),
            payload: .knowledge(
                recordID: "historical-belief-authorities",
                propositionID: nil,
                status: "retentionBoundary",
                reason: digest
            ),
            summary: "knowledge historical belief authority boundary"
        ) else {
            throw AgentSessionError.knowledge(.causalLedgerRequired)
        }
        state.historicalBeliefAuthorityBoundary =
            AgentKnowledgeHistoricalAuthorityBoundary(
                eventID: event.eventID,
                digest: digest
            )
        knowledgeGraphState = state
        try validateKnowledgeGraphStateIfEnabled()
        return true
    }

    /// CIV-42's current communications and acquisition receipts are committed
    /// as one exact bounded proof set. A dropped-prefix ID alone is never
    /// accepted; the current row must remain covered by this retained event.
    private mutating func appendLanguageProvenanceBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard var state = languageState, !leaving.isEmpty else { return false }
        let proofCount = state.communications.count
            + state.priorSeedReceipts.count
            + state.exposureReceipts.count
        guard proofCount > 0 else { return false }
        let leavingIDs = Set(leaving.map(\.eventID))
        let boundaryIsLeaving = state.provenanceBoundary.map {
            leavingIDs.contains($0.eventID)
        } ?? false
        let uncommittedProofIsLeaving = state.provenanceBoundary == nil
            && (state.communications.contains {
                leavingIDs.contains($0.communicationEventID)
            } || state.priorSeedReceipts.contains {
                leavingIDs.contains($0.seedEventID)
            } || state.exposureReceipts.contains {
                leavingIDs.contains($0.communicationEventID)
            })
        guard boundaryIsLeaving || uncommittedProofIsLeaving else {
            return false
        }
        let digest = languageProvenanceBoundaryDigest(state)
        let causes: [AgentCausalEventID]
        if let previous = state.provenanceBoundary?.eventID {
            causes = [previous]
        } else {
            causes = Array(Set(
                state.communications.map(\.communicationEventID)
                    + state.priorSeedReceipts.map(\.seedEventID)
                    + state.exposureReceipts.map(\.communicationEventID)
            ).intersection(leavingIDs)).sorted()
        }
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .languageInitialized,
            origin: .languageTransition,
            actorID: nil,
            subjectID: nil,
            causes: causes,
            payload: .language(
                recordID: state.pack.packID.rawValue,
                propositionID: nil,
                status: "provenanceBoundary",
                reason: digest
            ),
            summary: "language provenance retention boundary"
        ) else {
            throw AgentSessionError.language(.causalLedgerRequired)
        }
        state.provenanceBoundary = AgentLanguageProvenanceBoundary(
            eventID: event.eventID,
            digest: digest
        )
        languageState = state
        try validateLanguageStateIfInitialized()
        return true
    }

    /// CIV-43 applies the same exact-retained-boundary doctrine as CIV-42.
    /// The bounded current oral-hop set is recommitted before either its
    /// previous commitment or an uncommitted receipt leaves the FIFO suffix.
    private mutating func appendOralProvenanceBoundaryIfNeeded(
        beforeEvicting leaving: [AgentCausalEvent]
    ) throws -> Bool {
        guard var state = oralTransmissionState,
              !leaving.isEmpty else { return false }
        let hasOralHistory = !state.transmissions.isEmpty
            || state.evictedTransmissionCount > 0
            || state.provenanceBoundary != nil
        guard hasOralHistory else { return false }
        let leavingIDs = Set(leaving.map(\.eventID))
        let boundaryIsLeaving = state.provenanceBoundary.map {
            leavingIDs.contains($0.eventID)
        } ?? false
        let uncommittedReceiptIsLeaving = state.provenanceBoundary == nil
            && state.transmissions.contains {
                leavingIDs.contains($0.receiptEventID)
            }
        guard boundaryIsLeaving || uncommittedReceiptIsLeaving else {
            return false
        }
        let digest = oralProvenanceBoundaryDigest(state)
        let causes: [AgentCausalEventID]
        if let previous = state.provenanceBoundary?.eventID {
            causes = [previous]
        } else {
            causes = Array(Set(state.transmissions.map(\.receiptEventID))
                .intersection(leavingIDs)).sorted()
        }
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .oralProvenanceBoundary,
            origin: .oralTransition,
            actorID: nil,
            subjectID: nil,
            causes: causes,
            payload: .oral(
                transmissionID: "oral-provenance",
                sourcePropositionID: nil,
                receivedPropositionID: nil,
                status: "provenanceBoundary",
                reason: digest
            ),
            summary: "oral provenance retention boundary"
        ) else {
            throw AgentSessionError.oral(.causalLedgerRequired)
        }
        state.provenanceBoundary = AgentOralProvenanceBoundary(
            eventID: event.eventID,
            digest: digest
        )
        oralTransmissionState = state
        try validateOralTransmissionStateIfInitialized()
        return true
    }

    /// CIV-44 authenticates its exact bounded transport set before FIFO
    /// compaction can remove either a current boundary or uncommitted causal
    /// transport evidence.
    private mutating func
        appendLongDistanceCommunicationProvenanceBoundaryIfNeeded(
            beforeEvicting leaving: [AgentCausalEvent]
        ) throws -> Bool {
        guard var state = longDistanceCommunicationState,
              !leaving.isEmpty else { return false }
        let hasHistory = state.totalStartedCount > 0
            || state.evictedTransportCount > 0
            || state.provenanceBoundary != nil
        guard hasHistory else { return false }
        let leavingIDs = Set(leaving.map(\.eventID))
        let boundaryIsLeaving = state.provenanceBoundary.map {
            leavingIDs.contains($0.eventID)
        } ?? false
        let evidenceIDs = state.transports.flatMap { record in
            [record.dispatchEventID]
                + record.progress.flatMap {
                    [$0.movementEventID, $0.progressEventID]
                }
                + [
                    record.arrivalEventID,
                    record.deliveryEventID,
                    record.failureEventID,
                ].compactMap { $0 }
        }
        let uncommittedEvidenceIsLeaving =
            state.provenanceBoundary == nil
                && !Set(evidenceIDs).isDisjoint(with: leavingIDs)
        guard boundaryIsLeaving || uncommittedEvidenceIsLeaving else {
            return false
        }
        let digest =
            longDistanceCommunicationProvenanceBoundaryDigest(state)
        let causes: [AgentCausalEventID]
        if let previous = state.provenanceBoundary?.eventID {
            causes = [previous]
        } else {
            causes = Array(Set(evidenceIDs).intersection(leavingIDs))
                .sorted()
        }
        guard let event = try causalLedger.append(
            instant: simulationInstant,
            kind: .communicationTransportProvenanceBoundary,
            origin: .communicationTransportTransition,
            actorID: nil,
            subjectID: nil,
            causes: Array(causes.prefix(4)),
            payload: .communicationTransport(
                transportID: "communication-transport-provenance",
                authorID: nil,
                carrierID: nil,
                destinationID: nil,
                status: "provenanceBoundary",
                detail: digest
            ),
            summary: "communication transport provenance retention boundary"
        ) else {
            throw AgentSessionError.longDistanceCommunication(
                .causalLedgerRequired
            )
        }
        state.provenanceBoundary =
            AgentCommunicationTransportProvenanceBoundary(
                eventID: event.eventID,
                digest: digest
            )
        longDistanceCommunicationState = state
        try validateLongDistanceCommunicationStateIfInitialized()
        return true
    }

    private mutating func evictEcologicalRowsDependingOn(
        _ leaving: [AgentCausalEvent],
        preservingObservers: Set<AgentID> = [],
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
            if preservingObservers.contains(record.observation.observerID) {
                retained.append(record)
                continue
            }
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
                let current = populationRegistry?
                    .currentMembershipAuthorityEventID
                required.insert(
                    current.map {
                        $0.sequence < record.causalEventID.sequence
                            ? $0 : member.registrationEventID
                    } ?? member.registrationEventID
                )
            } else if let death = deathsByID[observerID],
                      !activeIDs.contains(observerID),
                      populationByID[observerID] == nil {
                required.insert(death.membershipAuthorityEventID.map {
                    $0.sequence < record.causalEventID.sequence
                        ? $0 : death.registrationEventID
                } ?? death.registrationEventID)
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
        try injectCausalRetentionFault(
            testFault,
            at: .afterMembershipEcologicalDependencyCalculation
        )
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
        try evictEcologicalRowsDependingOn(leaving, testFault: testFault)
        if try appendPopulationMembershipAuthorityBoundaryIfNeeded(
            beforeEvicting: leaving,
            testFault: testFault
        ) {
            try appendEcologicalRetentionBoundary(testFault: testFault)
            return
        }
        if try appendAgricultureRetentionBoundaryIfNeeded(
            beforeEvicting: leaving,
            testFault: testFault
        ) {
            try appendEcologicalRetentionBoundary(testFault: testFault)
            return
        }
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

    static func injectCausalRetentionFault(
        _ requested: AgentCausalRetentionFaultPoint?,
        at point: AgentCausalRetentionFaultPoint,
        when condition: Bool = true
    ) throws {
        guard condition, requested == point else { return }
        throw AgentSessionError.ecologicalObservation(
            .invalidState("injected causal retention fault \(point.rawValue)")
        )
    }

    func injectCausalRetentionFault(
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
                return [
                    populationRegistry?.currentMembershipAuthorityEventID
                        ?? member.registrationEventID,
                ]
            }
            if let death = mortalityState?.records.first(where: {
                $0.agentID == agentID
            }) {
                return [
                    death.membershipAuthorityEventID
                        ?? death.registrationEventID,
                    death.deathEventID,
                ]
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
