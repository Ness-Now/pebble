extension AgentSimulationSession {
    public var oralTransmissionEnabled: Bool {
        oralTransmissionState?.enabled == true
    }

    public mutating func setOralTransmissionEnabled(
        _ enabled: Bool,
        configuration: AgentOralConfiguration = .live
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.oral(.causalLedgerRequired)
        }
        guard socialEnabled else {
            throw AgentSessionError.oral(.socialRequired)
        }
        guard knowledgeGraphEnabled else {
            throw AgentSessionError.oral(.knowledgeRequired)
        }
        guard languageState?.enabled == true else {
            throw AgentSessionError.oral(.languageRequired)
        }
        if enabled {
            guard let languageCapacity = languageState?.configuration
                .maximumCommunicationRecords,
                  configuration.maximumTransmissionRecords
                    < languageCapacity else {
                throw AgentSessionError.oral(.invalidState(
                    "oral history requires one CIV-42 communication headroom slot"
                ))
            }
        }
        if oralTransmissionState?.enabled == enabled {
            if enabled,
               oralTransmissionState?.configuration != configuration {
                throw AgentSessionError.oral(.invalidState(
                    "configuration cannot change while enabled"
                ))
            }
            return
        }
        var candidate = self
        try candidate.prevalidateCausalAppend(count: 1)
        var state = candidate.oralTransmissionState
            ?? AgentOralTransmissionState(configuration: configuration)
        guard state.configuration == configuration else {
            throw AgentSessionError.oral(.invalidState(
                "configuration cannot change after initialization"
            ))
        }
        state.enabled = enabled
        let event = try candidate.requiredOralEvent(
            kind: .oralTransmissionInitialized,
            actorID: nil,
            subjectID: nil,
            causes: [],
            transmissionID: "oral-transmission",
            sourcePropositionID: nil,
            receivedPropositionID: nil,
            status: enabled ? "enabled" : "disabled",
            reason: "explicit feature transition",
            summary: "oral transmission \(enabled ? "enabled" : "disabled")"
        )
        candidate.oralTransmissionState = state
        _ = event
        try candidate.validateOralTransmissionStateIfInitialized()
        self = candidate
    }

    public func oralTransmissionSnapshot() -> AgentOralSnapshot {
        guard let state = oralTransmissionState else {
            return AgentOralSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                transmissions: [],
                evictedTransmissionCount: 0,
                provenanceBoundary: nil,
                digest: AgentOralDigest.make("oral:none")
            )
        }
        let transmissions = state.transmissions.sorted {
            if $0.transmittedAtTick != $1.transmittedAtTick {
                return $0.transmittedAtTick < $1.transmittedAtTick
            }
            return $0.transmissionID < $1.transmissionID
        }
        let digest = AgentOralDigest.make([
            "oral-snapshot-v1",
            state.enabled ? "1" : "0",
            String(state.configuration.maximumTransmissionRecords),
            String(state.configuration.maximumFaithfulDistance),
            transmissions.map(oralTransmissionCanonicalText)
                .joined(separator: ";"),
            String(state.evictedTransmissionCount),
            String(state.nextTransmissionOrdinal),
            state.provenanceBoundary.map {
                "\($0.eventID.rawValue):\($0.digest)"
            } ?? "none",
        ].joined(separator: "|"))
        return AgentOralSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            transmissions: transmissions,
            evictedTransmissionCount: state.evictedTransmissionCount,
            provenanceBoundary: state.provenanceBoundary,
            digest: digest
        )
    }

    public func oralTransmissionSummary() -> AgentOralSummary {
        let snapshot = oralTransmissionSnapshot()
        return AgentOralSummary(
            enabled: snapshot.enabled,
            transmissionCount: snapshot.transmissions.count,
            faithfulCount: snapshot.transmissions.filter {
                $0.outcome == .faithful
            }.count,
            distortedCount: snapshot.transmissions.filter {
                $0.outcome == .distanceDistorted
            }.count,
            evictedTransmissionCount: snapshot.evictedTransmissionCount,
            digest: snapshot.digest
        )
    }

    /// The caller selects only speaker, recipient, source proposition, and
    /// CIV-42 rendering. It cannot inject the received proposition.
    @discardableResult
    public mutating func transmitOralClaim(
        speakerID: AgentID,
        recipientID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode
    ) throws -> AgentOralTransmission {
        try transmitOralClaim(
            speakerID: speakerID,
            recipientID: recipientID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            recordedEffect: nil
        )
    }

    @discardableResult
    mutating func transmitOralClaim(
        speakerID: AgentID,
        recipientID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode,
        recordedEffect: AgentOralAcceptedEffect?
    ) throws -> AgentOralTransmission {
        guard let oral = oralTransmissionState, oral.enabled else {
            throw AgentSessionError.oral(.disabled)
        }
        guard socialEnabled else {
            throw AgentSessionError.oral(.socialRequired)
        }
        guard knowledgeGraphEnabled else {
            throw AgentSessionError.oral(.knowledgeRequired)
        }
        guard languageState?.enabled == true else {
            throw AgentSessionError.oral(.languageRequired)
        }
        guard let speaker = statesById[speakerID.rawValue] else {
            throw AgentSessionError.oral(.unknownAgent(speakerID.rawValue))
        }
        guard let recipient = statesById[recipientID.rawValue] else {
            throw AgentSessionError.oral(.unknownAgent(recipientID.rawValue))
        }
        guard speakerID != recipientID else {
            throw AgentSessionError.oral(.invalidParticipant(
                "speaker and recipient must be distinct"
            ))
        }
        guard !isMigratingAgent(speakerID.rawValue),
              !isMigratingAgent(recipientID.rawValue) else {
            throw AgentSessionError.oral(.migratingParticipant(
                "\(speakerID.rawValue)>\(recipientID.rawValue)"
            ))
        }
        let distance = manhattanDistance(
            speaker.position, recipient.position
        )
        let radius = configuration.socialConfiguration.communicationRadius
        guard distance <= radius else {
            throw AgentSessionError.oral(.nonLocal(
                distance: distance, radius: radius
            ))
        }
        guard canUseDirectSocialCommunicationAuthority(
            speakerID: speakerID,
            recipientID: recipientID
        ) else {
            throw AgentSessionError.oral(.localAuthorityRefused(
                "\(speakerID.rawValue)>\(recipientID.rawValue)"
            ))
        }
        let (_, sourceProposition, sourceSemanticContent) =
            try languageBeliefAndSemanticContent(
                ownerID: speakerID,
                propositionID: propositionID
            )
        let locality = AgentOralLocalityEvidence(
            speakerPosition: speaker.position,
            recipientPosition: recipient.position,
            distance: distance,
            authorizedRadius: radius,
            observedAtTick: tick
        )
        let canonicalEffect = try oralAcceptedEffect(
            speakerID: speakerID,
            recipientID: recipientID,
            sourceProposition: sourceProposition,
            sourceSemanticContent: sourceSemanticContent,
            locality: locality,
            configuration: oral.configuration
        )
        if let recordedEffect, recordedEffect != canonicalEffect {
            throw AgentSessionError.oral(.replayEffectMismatch(
                propositionID.rawValue
            ))
        }
        let acceptedEffect = recordedEffect ?? canonicalEffect

        var candidate = self
        let communication = try candidate.communicateLanguageSemanticContent(
            speakerID: speakerID,
            recipientID: recipientID,
            propositionID: propositionID,
            renderingMode: renderingMode
        )
        guard communication.semanticContent == sourceSemanticContent else {
            throw AgentSessionError.oral(.invalidState(
                "CIV-42 transmitted semantic mismatch"
            ))
        }
        guard var state = candidate.oralTransmissionState,
              state.nextTransmissionOrdinal < UInt64.max else {
            throw AgentSessionError.oral(.capacityReached(
                "transmission ordinal"
            ))
        }
        let transmissionID = AgentOralTransmissionID(
            rawValue: "oral-transmission-\(state.nextTransmissionOrdinal)"
        )!
        let receiptEvent = try candidate.requiredOralEvent(
            kind: .oralTransmissionAccepted,
            actorID: speakerID,
            subjectID: recipientID,
            causes: [communication.communicationEventID],
            transmissionID: transmissionID.rawValue,
            sourcePropositionID: propositionID,
            receivedPropositionID:
                acceptedEffect.interpretedProposition.propositionID,
            status: acceptedEffect.outcome.rawValue,
            reason: acceptedEffect.decisionDigest,
            summary: "oral claim \(speakerID.rawValue)>\(recipientID.rawValue) \(acceptedEffect.outcome.rawValue)"
        )
        let acquisition = try candidate.recordKnowledgeOralSourceClaim(
            transmissionID: transmissionID,
            communication: communication,
            interpretedProposition: acceptedEffect.interpretedProposition,
            receiptEventID: receiptEvent.eventID
        )
        let provenanceDigest = oralTransmissionDigest(
            transmissionID: transmissionID,
            communication: communication,
            interpretedSemanticContent:
                acceptedEffect.interpretedSemanticContent,
            outcome: acceptedEffect.outcome,
            decisionDigest: acceptedEffect.decisionDigest,
            locality: locality,
            receiptEventID: receiptEvent.eventID,
            acquisition: acquisition,
            transmittedAtTick: candidate.tick
        )
        let transmission = AgentOralTransmission(
            transmissionID: transmissionID,
            speakerID: speakerID,
            recipientID: recipientID,
            sourceBeliefID: communication.sourceBeliefID,
            sourceBeliefRevisionEventID:
                communication.sourceBeliefRevisionEventID,
            sourceAuthorityID:
                communication.semanticAuthority.authorityID,
            languageCommunicationID: communication.communicationID,
            languageCommunicationEventID:
                communication.communicationEventID,
            transmittedSemanticContent: communication.semanticContent,
            interpretedSemanticContent:
                acceptedEffect.interpretedSemanticContent,
            outcome: acceptedEffect.outcome,
            decisionDigest: acceptedEffect.decisionDigest,
            locality: locality,
            receiptEventID: receiptEvent.eventID,
            recipientClaimID: acquisition.claimID,
            recipientClaimEventID: acquisition.claimEventID,
            recipientUnderstandingID: acquisition.understandingID,
            recipientBeliefID: acquisition.beliefID,
            recipientBeliefRevisionEventID:
                acquisition.beliefRevisionEventID,
            transmittedAtTick: candidate.tick,
            provenanceDigest: provenanceDigest
        )
        state = candidate.oralTransmissionState ?? state
        state.transmissions.append(transmission)
        state.nextTransmissionOrdinal += 1
        candidate.oralTransmissionState = state
        try candidate.compactOralStateAfterTransmission()
        try candidate.commitOralProvenanceBoundary(causes: [
            receiptEvent.eventID,
            acquisition.claimEventID,
            acquisition.beliefRevisionEventID,
        ])
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateLanguageStateIfInitialized()
        try candidate.validateOralTransmissionStateIfInitialized()
        self = candidate
        return transmission
    }

    private func oralAcceptedEffect(
        speakerID: AgentID,
        recipientID: AgentID,
        sourceProposition: AgentKnowledgeProposition,
        sourceSemanticContent: AgentLanguageSemanticContent,
        locality: AgentOralLocalityEvidence,
        configuration: AgentOralConfiguration
    ) throws -> AgentOralAcceptedEffect {
        enum SupportedValue: String, CaseIterable {
            case absent
            case wood
            case stone
        }
        let sourceValue: SupportedValue
        switch sourceProposition.value {
        case .absent:
            sourceValue = .absent
        case let .resource(kind, _) where kind == .wood:
            sourceValue = .wood
        case let .resource(kind, _) where kind == .stone:
            sourceValue = .stone
        default:
            throw AgentSessionError.oral(.unsupportedSemantics(
                sourceProposition.propositionID.rawValue
            ))
        }
        let outcome: AgentOralTransmissionOutcome
        let interpretedProposition: AgentKnowledgeProposition
        if locality.distance <= configuration.maximumFaithfulDistance {
            outcome = .faithful
            interpretedProposition = sourceProposition
        } else {
            outcome = .distanceDistorted
            let alternatives = SupportedValue.allCases.filter {
                $0 != sourceValue
            }
            let selectorInput = [
                "oral-distance-distortion-selector-v1",
                simulationID.rawValue,
                String(self.configuration.seed),
                String(locality.observedAtTick),
                speakerID.rawValue,
                recipientID.rawValue,
                sourceProposition.propositionID.rawValue,
                sourceSemanticContent.digest,
                String(locality.distance),
                String(locality.authorizedRadius),
                String(configuration.maximumFaithfulDistance),
            ].joined(separator: "|")
            let selected = alternatives[
                AgentOralDigest.selector(
                    selectorInput, modulo: alternatives.count
                )
            ]
            let value: AgentKnowledgeValue
            switch selected {
            case .absent: value = .absent
            case .wood: value = .resource(kind: .wood, fingerprint: nil)
            case .stone: value = .resource(kind: .stone, fingerprint: nil)
            }
            interpretedProposition = AgentKnowledgeProposition(
                subject: sourceProposition.subject,
                predicate: sourceProposition.predicate,
                value: value
            )
        }
        let interpretedSemanticContent = try languageSemanticContent(
            for: interpretedProposition
        )
        guard outcome == .faithful
                || interpretedSemanticContent.digest
                    != sourceSemanticContent.digest else {
            throw AgentSessionError.oral(.invalidState(
                "distortion must change semantic content"
            ))
        }
        let decisionDigest = AgentOralDigest.make([
            "oral-accepted-effect-v1",
            simulationID.rawValue,
            String(self.configuration.seed),
            String(locality.observedAtTick),
            speakerID.rawValue,
            recipientID.rawValue,
            sourceProposition.propositionID.rawValue,
            sourceSemanticContent.digest,
            interpretedProposition.propositionID.rawValue,
            interpretedSemanticContent.digest,
            outcome.rawValue,
            String(locality.distance),
            String(locality.authorizedRadius),
            String(configuration.maximumFaithfulDistance),
        ].joined(separator: "|"))
        return AgentOralAcceptedEffect(
            interpretedProposition: interpretedProposition,
            interpretedSemanticContent: interpretedSemanticContent,
            outcome: outcome,
            decisionDigest: decisionDigest
        )
    }

    private mutating func compactOralStateAfterTransmission() throws {
        guard var oral = oralTransmissionState,
              oral.transmissions.count
                > oral.configuration.maximumTransmissionRecords else {
            return
        }
        let excess = oral.transmissions.count
            - oral.configuration.maximumTransmissionRecords
        let currentUnderstandingIDs = Set(
            knowledgeGraphState?.beliefs.map(\.basisUnderstandingID) ?? []
        )
        let currentClaimIDs: Set<AgentKnowledgeClaimID> = Set(
            (knowledgeGraphState?.understandings.compactMap { understanding
                -> AgentKnowledgeClaimID? in
                guard currentUnderstandingIDs.contains(
                    understanding.understandingID
                ), case let .sourceClaim(claimID) = understanding.basis else {
                    return nil
                }
                return claimID
            }) ?? []
        )
        var pinnedTransmissionIDs = Set(
            knowledgeGraphState?.claims.compactMap { claim in
                currentClaimIDs.contains(claim.claimID)
                    ? claim.oralTransmissionID : nil
            } ?? []
        )
        for departed in knowledgeGraphState?.departedBeliefs ?? [] {
            if case let .oralSourceClaim(
                _, _, _, _, transmissionID, _, _, _
            ) = departed.basis {
                pinnedTransmissionIDs.insert(transmissionID)
            }
        }
        let removable = oral.transmissions.filter {
            !pinnedTransmissionIDs.contains($0.transmissionID)
        }.sorted {
            if $0.transmittedAtTick != $1.transmittedAtTick {
                return $0.transmittedAtTick < $1.transmittedAtTick
            }
            return $0.transmissionID < $1.transmissionID
        }
        guard removable.count >= excess,
              oral.evictedTransmissionCount <= Int.max - excess else {
            throw AgentSessionError.oral(.capacityReached(
                "oral transmission records are epistemically pinned"
            ))
        }
        let evicted: [AgentOralTransmission] = Array(
            removable.prefix(excess)
        )
        let evictedIDs: Set<AgentOralTransmissionID> = Set(
            evicted.map(\.transmissionID)
        )
        oral.transmissions.removeAll {
            evictedIDs.contains($0.transmissionID)
        }
        oral.evictedTransmissionCount += excess
        oralTransmissionState = oral
        for record in evicted {
            try retireKnowledgeOralClaim(record.recipientClaimID)
        }
    }

    private mutating func retireKnowledgeOralClaim(
        _ claimID: AgentKnowledgeClaimID
    ) throws {
        guard var knowledge = knowledgeGraphState,
              let claim = knowledge.claims.first(where: {
                  $0.claimID == claimID
              }) else { return }
        guard claim.oralTransmissionID != nil else {
            throw AgentSessionError.oral(.invalidState(
                "attempted to compact non-oral claim"
            ))
        }
        let currentUnderstandingIDs = Set(
            knowledge.beliefs.map(\.basisUnderstandingID)
        )
        let removableUnderstandingIDs: Set<AgentKnowledgeUnderstandingID> =
            Set(knowledge.understandings.compactMap { understanding
                -> AgentKnowledgeUnderstandingID? in
                guard case let .sourceClaim(basisClaimID) =
                        understanding.basis,
                      basisClaimID == claimID,
                      !currentUnderstandingIDs.contains(
                        understanding.understandingID
                      ) else { return nil }
                return understanding.understandingID
            })
        guard !knowledge.understandings.contains(where: {
            if case let .sourceClaim(basisClaimID) = $0.basis {
                return basisClaimID == claimID
                    && currentUnderstandingIDs.contains($0.understandingID)
            }
            return false
        }) else {
            throw AgentSessionError.oral(.capacityReached(
                "current oral understanding"
            ))
        }
        let removedRevisionCount = knowledge.revisions.filter {
            removableUnderstandingIDs.contains($0.triggerUnderstandingID)
        }.count
        knowledge.revisions.removeAll {
            removableUnderstandingIDs.contains($0.triggerUnderstandingID)
        }
        knowledge.understandings.removeAll {
            removableUnderstandingIDs.contains($0.understandingID)
        }
        knowledge.claims.removeAll { $0.claimID == claimID }
        knowledge.evictionCounts.claims += 1
        knowledge.evictionCounts.understandings +=
            removableUnderstandingIDs.count
        knowledge.evictionCounts.revisions += removedRevisionCount
        knowledgeGraphState = knowledge
    }

    struct KnowledgeOralAcquisition {
        let claimID: AgentKnowledgeClaimID
        let claimEventID: AgentCausalEventID
        let understandingID: AgentKnowledgeUnderstandingID
        let beliefID: AgentKnowledgeBeliefID
        let beliefRevisionEventID: AgentCausalEventID
    }

    private mutating func recordKnowledgeOralSourceClaim(
        transmissionID: AgentOralTransmissionID,
        communication: AgentLanguageCommunication,
        interpretedProposition: AgentKnowledgeProposition,
        receiptEventID: AgentCausalEventID
    ) throws -> KnowledgeOralAcquisition {
        guard var knowledge = knowledgeGraphState, knowledge.enabled else {
            throw AgentSessionError.oral(.knowledgeRequired)
        }
        guard statesById[communication.speakerID.rawValue] != nil,
              statesById[communication.recipientID.rawValue] != nil else {
            throw AgentSessionError.oral(.unknownAgent(
                communication.recipientID.rawValue
            ))
        }
        guard let authority = (knowledge.historicalBeliefAuthorities ?? [])
            .first(where: {
                $0.authorityID
                    == communication.semanticAuthority.authorityID
            }),
              authority.ownerID == communication.speakerID,
              authority.beliefID == communication.sourceBeliefID,
              authority.sourceBeliefRevisionEventID
                == communication.sourceBeliefRevisionEventID,
              authority.proposition.propositionID
                == communication.semanticContent.sourcePropositionID else {
            throw AgentSessionError.oral(.missingAuthority(
                communication.semanticAuthority.authorityID.rawValue
            ))
        }
        insertKnowledgeProposition(interpretedProposition, into: &knowledge)
        let claimID = AgentKnowledgeClaimID(
            rawValue: "claim-" + AgentKnowledgeDigest.make(
                "oral|\(communication.recipientID.rawValue)|"
                    + transmissionID.rawValue
            )
        )!
        guard !knowledge.claims.contains(where: {
            $0.claimID == claimID
        }) else {
            throw AgentSessionError.oral(.invalidState(
                "duplicate oral claim"
            ))
        }
        let claimEvent = try requiredKnowledgeEvent(
            kind: .knowledgeClaimReceived,
            actorID: communication.speakerID,
            subjectID: communication.recipientID,
            causes: [receiptEventID],
            recordID: claimID.rawValue,
            propositionID: interpretedProposition.propositionID,
            status: "attributedOralSourceClaim",
            reason: transmissionID.rawValue,
            summary: "oral knowledge claim \(communication.speakerID.rawValue)>\(communication.recipientID.rawValue)"
        )
        knowledge.claims.append(AgentKnowledgeSourceClaim(
            claimID: claimID,
            propositionID: interpretedProposition.propositionID,
            sourceAgentID: communication.speakerID,
            recipientID: communication.recipientID,
            sourceEvidenceID: nil,
            socialMessageID: nil,
            sourceBeliefAuthorityID:
                communication.semanticAuthority.authorityID,
            languageCommunicationID: communication.communicationID,
            oralTransmissionID: transmissionID,
            sentEventID: communication.communicationEventID,
            receivedEventID: receiptEventID,
            acquisitionEventID: claimEvent.eventID,
            receivedAtTick: tick
        ))
        let understanding = try formKnowledgeUnderstanding(
            ownerID: communication.recipientID,
            proposition: interpretedProposition,
            basis: .sourceClaim(claimID),
            interpretation: .acceptedAsAsserted,
            cause: claimEvent.eventID,
            state: &knowledge
        )
        try reviseKnowledgeBelief(
            ownerID: communication.recipientID,
            proposition: interpretedProposition,
            stance: .accepted,
            understanding: understanding,
            state: &knowledge
        )
        // CIV-43 rows pin their CIV-41 claim and understanding until the oral
        // record itself is compacted.
        try compactKnowledgeState(&knowledge)
        guard let belief = knowledge.beliefs.first(where: {
            $0.ownerID == communication.recipientID
                && $0.questionKey == interpretedProposition.questionKey
        }), belief.propositionID == interpretedProposition.propositionID,
              belief.basisUnderstandingID == understanding.understandingID
        else {
            throw AgentSessionError.oral(.invalidState(
                "recipient belief publication"
            ))
        }
        knowledgeGraphState = knowledge
        return KnowledgeOralAcquisition(
            claimID: claimID,
            claimEventID: claimEvent.eventID,
            understandingID: understanding.understandingID,
            beliefID: belief.beliefID,
            beliefRevisionEventID: belief.lastRevisionEventID
        )
    }

    mutating func commitOralProvenanceBoundary(
        causes: [AgentCausalEventID]
    ) throws {
        guard var state = oralTransmissionState else { return }
        guard !state.transmissions.isEmpty else {
            state.provenanceBoundary = nil
            oralTransmissionState = state
            return
        }
        let digest = oralProvenanceBoundaryDigest(state)
        var boundaryCauses = causes
        if let previous = state.provenanceBoundary?.eventID {
            boundaryCauses.append(previous)
        }
        let event = try requiredOralEvent(
            kind: .oralProvenanceBoundary,
            actorID: nil,
            subjectID: nil,
            causes: Array(Set(boundaryCauses)).sorted(),
            transmissionID: "oral-provenance",
            sourcePropositionID: nil,
            receivedPropositionID: nil,
            status: "provenanceBoundary",
            reason: digest,
            summary: "oral provenance retention boundary"
        )
        state = oralTransmissionState ?? state
        state.provenanceBoundary = AgentOralProvenanceBoundary(
            eventID: event.eventID,
            digest: digest
        )
        oralTransmissionState = state
    }

    func validateOralTransmissionStateIfInitialized() throws {
        guard let state = oralTransmissionState else { return }
        guard socialEnabled else {
            throw AgentSessionError.oral(.socialRequired)
        }
        guard let knowledge = knowledgeGraphState, knowledge.enabled else {
            throw AgentSessionError.oral(.knowledgeRequired)
        }
        guard let language = languageState, language.enabled else {
            throw AgentSessionError.oral(.languageRequired)
        }
        guard state.configuration.maximumTransmissionRecords
                < language.configuration.maximumCommunicationRecords else {
            throw AgentSessionError.oral(.invalidState(
                "oral/CIV-42 retention headroom"
            ))
        }
        do {
            _ = try AgentOralConfiguration(
                maximumTransmissionRecords:
                    state.configuration.maximumTransmissionRecords,
                maximumFaithfulDistance:
                    state.configuration.maximumFaithfulDistance
            )
        } catch {
            throw AgentSessionError.oral(.invalidState("configuration"))
        }
        guard state.transmissions.count
                <= state.configuration.maximumTransmissionRecords,
              state.evictedTransmissionCount >= 0,
              state.nextTransmissionOrdinal > 0,
              Set(state.transmissions.map(\.transmissionID)).count
                == state.transmissions.count else {
            throw AgentSessionError.oral(.invalidState(
                "global bound or identity"
            ))
        }
        try validateOralProvenanceBoundaryIfInitialized()
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        func retainedEvent(
            _ eventID: AgentCausalEventID
        ) throws -> AgentCausalEvent? {
            guard eventID.simulationID == simulationID,
                  eventID.sequence.rawValue <= causalLedger.latestSequence
            else {
                throw AgentSessionError.oral(.invalidState(
                    "cross-simulation provenance"
                ))
            }
            if let event = retainedEvents[eventID] { return event }
            guard causalLedger.droppedEventCount > 0,
                  eventID.sequence.rawValue <= causalLedger.droppedEventCount
            else {
                throw AgentSessionError.oral(.invalidState(
                    "missing causal provenance"
                ))
            }
            return nil
        }
        let authorities = Dictionary(uniqueKeysWithValues:
            (knowledge.historicalBeliefAuthorities ?? []).map {
                ($0.authorityID, $0)
            }
        )
        let communications = Dictionary(uniqueKeysWithValues:
            language.communications.map { ($0.communicationID, $0) }
        )
        let claims = Dictionary(uniqueKeysWithValues:
            knowledge.claims.map { ($0.claimID, $0) }
        )
        let understandings = Dictionary(uniqueKeysWithValues:
            knowledge.understandings.map { ($0.understandingID, $0) }
        )
        let departedBeliefs = knowledge.departedBeliefs ?? []
        let propositions = Dictionary(uniqueKeysWithValues:
            knowledge.propositions.map { ($0.propositionID, $0) }
        )
        for record in state.transmissions {
            guard record.speakerID != record.recipientID,
                  record.transmittedAtTick >= 0,
                  record.transmittedAtTick <= tick,
                  record.locality.observedAtTick
                    == record.transmittedAtTick,
                  record.locality.distance == manhattanDistance(
                    record.locality.speakerPosition,
                    record.locality.recipientPosition
                  ),
                  record.locality.authorizedRadius
                    == configuration.socialConfiguration.communicationRadius,
                  record.locality.distance
                    <= record.locality.authorizedRadius,
                  let authority = authorities[record.sourceAuthorityID],
                  authority.ownerID == record.speakerID,
                  authority.beliefID == record.sourceBeliefID,
                  authority.sourceBeliefRevisionEventID
                    == record.sourceBeliefRevisionEventID,
                  let communication = communications[
                    record.languageCommunicationID
                  ],
                  communication.speakerID == record.speakerID,
                  communication.recipientID == record.recipientID,
                  communication.sourceBeliefID == record.sourceBeliefID,
                  communication.sourceBeliefRevisionEventID
                    == record.sourceBeliefRevisionEventID,
                  communication.semanticAuthority.authorityID
                    == record.sourceAuthorityID,
                  communication.communicationEventID
                    == record.languageCommunicationEventID,
                  communication.semanticContent
                    == record.transmittedSemanticContent,
                  let interpretedProposition = propositions[
                    record.interpretedSemanticContent.sourcePropositionID
                  ],
                  try languageSemanticContent(for: interpretedProposition)
                    == record.interpretedSemanticContent,
                  record.languageCommunicationEventID.sequence
                    < record.receiptEventID.sequence,
                  record.receiptEventID.sequence
                    < record.recipientClaimEventID.sequence else {
                throw AgentSessionError.oral(.invalidState(
                    "oral cross-domain provenance"
                ))
            }
            let activeAcquisitionMatches: Bool = {
                guard let claim = claims[record.recipientClaimID],
                      claim.sourceAgentID == record.speakerID,
                      claim.recipientID == record.recipientID,
                      claim.propositionID
                        == interpretedProposition.propositionID,
                      claim.sourceEvidenceID == nil,
                      claim.socialMessageID == nil,
                      claim.sourceBeliefAuthorityID
                        == record.sourceAuthorityID,
                      claim.languageCommunicationID
                        == record.languageCommunicationID,
                      claim.oralTransmissionID == record.transmissionID,
                      claim.sentEventID
                        == record.languageCommunicationEventID,
                      claim.receivedEventID == record.receiptEventID,
                      claim.acquisitionEventID
                        == record.recipientClaimEventID,
                      let understanding = understandings[
                        record.recipientUnderstandingID
                      ],
                      understanding.ownerID == record.recipientID,
                      understanding.propositionID
                        == interpretedProposition.propositionID,
                      understanding.basis
                        == .sourceClaim(record.recipientClaimID),
                      record.recipientClaimEventID.sequence
                        < understanding.formedEventID.sequence,
                      understanding.formedEventID.sequence
                        < record.recipientBeliefRevisionEventID.sequence else {
                    return false
                }
                return true
            }()
            let departedAcquisitionMatches = departedBeliefs.contains {
                departed in
                guard departed.ownerID == record.recipientID,
                      departed.beliefID == record.recipientBeliefID,
                      departed.proposition == interpretedProposition,
                      departed.basisUnderstandingID
                        == record.recipientUnderstandingID,
                      record.recipientClaimEventID.sequence
                        < departed.understandingFormedEventID.sequence,
                      departed.understandingFormedEventID.sequence
                        < record.recipientBeliefRevisionEventID.sequence,
                      departed.lastRevisionEventID
                        == record.recipientBeliefRevisionEventID,
                      case let .oralSourceClaim(
                        claimID, sourceAgentID, sourceAuthorityID,
                        communicationID, transmissionID, sentEventID,
                        receivedEventID, acquisitionEventID
                      ) = departed.basis else {
                    return false
                }
                return claimID == record.recipientClaimID
                    && sourceAgentID == record.speakerID
                    && sourceAuthorityID == record.sourceAuthorityID
                    && communicationID == record.languageCommunicationID
                    && transmissionID == record.transmissionID
                    && sentEventID == record.languageCommunicationEventID
                    && receivedEventID == record.receiptEventID
                    && acquisitionEventID == record.recipientClaimEventID
            }
            guard activeAcquisitionMatches || departedAcquisitionMatches else {
                throw AgentSessionError.oral(.invalidState(
                    "oral cross-domain provenance"
                ))
            }
            let expectedEffect = try oralAcceptedEffect(
                speakerID: record.speakerID,
                recipientID: record.recipientID,
                sourceProposition: authority.proposition,
                sourceSemanticContent: record.transmittedSemanticContent,
                locality: record.locality,
                configuration: state.configuration
            )
            guard expectedEffect.interpretedSemanticContent
                    == record.interpretedSemanticContent,
                  expectedEffect.outcome == record.outcome,
                  expectedEffect.decisionDigest == record.decisionDigest else {
                throw AgentSessionError.oral(.invalidState(
                    "accepted distortion effect"
                ))
            }
            let acquisition = KnowledgeOralAcquisition(
                claimID: record.recipientClaimID,
                claimEventID: record.recipientClaimEventID,
                understandingID: record.recipientUnderstandingID,
                beliefID: record.recipientBeliefID,
                beliefRevisionEventID:
                    record.recipientBeliefRevisionEventID
            )
            guard record.provenanceDigest == oralTransmissionDigest(
                transmissionID: record.transmissionID,
                communication: communication,
                interpretedSemanticContent:
                    record.interpretedSemanticContent,
                outcome: record.outcome,
                decisionDigest: record.decisionDigest,
                locality: record.locality,
                receiptEventID: record.receiptEventID,
                acquisition: acquisition,
                transmittedAtTick: record.transmittedAtTick
            ) else {
                throw AgentSessionError.oral(.invalidState(
                    "oral provenance digest"
                ))
            }
            if let event = try retainedEvent(record.receiptEventID) {
                guard event.kind == .oralTransmissionAccepted,
                      event.origin == .oralTransition,
                      event.actorID == record.speakerID,
                      event.subjectID == record.recipientID,
                      event.causes == [record.languageCommunicationEventID],
                      case let .oral(
                        transmissionID, sourceID, receivedID, status, reason
                      ) = event.payload,
                      transmissionID == record.transmissionID.rawValue,
                      sourceID == record.transmittedSemanticContent
                        .sourcePropositionID.rawValue,
                      receivedID == record.interpretedSemanticContent
                        .sourcePropositionID.rawValue,
                      status == record.outcome.rawValue,
                      reason == record.decisionDigest else {
                    throw AgentSessionError.oral(.invalidState(
                        "oral receipt event"
                    ))
                }
            }
            if let event = try retainedEvent(
                record.recipientBeliefRevisionEventID
            ) {
                guard event.kind == .knowledgeBeliefRevised,
                      event.origin == .knowledgeTransition,
                      event.actorID == record.recipientID,
                      event.subjectID == record.recipientID,
                      case let .knowledge(
                        recordID, propositionID, status, _
                      ) = event.payload,
                      recordID == record.recipientBeliefID.rawValue,
                      propositionID == record.interpretedSemanticContent
                        .sourcePropositionID.rawValue,
                      status == AgentKnowledgeBeliefStance.accepted.rawValue
                else {
                    throw AgentSessionError.oral(.invalidState(
                        "recipient belief revision event"
                    ))
                }
            }
        }
    }

    /// Authenticate the independent exact-retained set before validating
    /// cross-domain links. Otherwise a forged oral set and matching dependent
    /// rows could fail only inside a mutually edited domain.
    func validateOralProvenanceBoundaryIfInitialized() throws {
        guard let state = oralTransmissionState else { return }
        if state.transmissions.isEmpty {
            guard state.provenanceBoundary == nil else {
                throw AgentSessionError.oral(.invalidState(
                    "empty oral provenance boundary"
                ))
            }
            return
        }
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        guard let boundary = state.provenanceBoundary,
              boundary.digest == oralProvenanceBoundaryDigest(state),
              let event = retainedEvents[boundary.eventID],
              event.kind == .oralProvenanceBoundary,
              event.origin == .oralTransition,
              event.actorID == nil,
              event.subjectID == nil,
              case let .oral(
                transmissionID, sourceID, receivedID, status, reason
              ) = event.payload,
              transmissionID == "oral-provenance",
              sourceID == nil,
              receivedID == nil,
              status == "provenanceBoundary",
              reason == boundary.digest else {
            throw AgentSessionError.oral(.invalidState(
                "oral provenance boundary"
            ))
        }
    }

    private mutating func requiredOralEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        transmissionID: String,
        sourcePropositionID: AgentKnowledgePropositionID?,
        receivedPropositionID: AgentKnowledgePropositionID?,
        status: String,
        reason: String,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .oralTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes.sorted(),
            payload: .oral(
                transmissionID: transmissionID,
                sourcePropositionID: sourcePropositionID?.rawValue,
                receivedPropositionID: receivedPropositionID?.rawValue,
                status: status,
                reason: reason
            ),
            summary: summary
        ) else {
            throw AgentSessionError.oral(.causalLedgerRequired)
        }
        return event
    }
}

func oralTransmissionCanonicalText(
    _ record: AgentOralTransmission
) -> String {
    [
        record.transmissionID.rawValue,
        record.speakerID.rawValue,
        record.recipientID.rawValue,
        record.sourceBeliefID.rawValue,
        record.sourceBeliefRevisionEventID.rawValue,
        record.sourceAuthorityID.rawValue,
        record.languageCommunicationID.rawValue,
        record.languageCommunicationEventID.rawValue,
        record.transmittedSemanticContent.digest,
        record.interpretedSemanticContent.digest,
        record.outcome.rawValue,
        record.decisionDigest,
        "\(record.locality.speakerPosition.x),\(record.locality.speakerPosition.y),\(record.locality.speakerPosition.z)",
        "\(record.locality.recipientPosition.x),\(record.locality.recipientPosition.y),\(record.locality.recipientPosition.z)",
        String(record.locality.distance),
        String(record.locality.authorizedRadius),
        String(record.locality.observedAtTick),
        record.receiptEventID.rawValue,
        record.recipientClaimID.rawValue,
        record.recipientClaimEventID.rawValue,
        record.recipientUnderstandingID.rawValue,
        record.recipientBeliefID.rawValue,
        record.recipientBeliefRevisionEventID.rawValue,
        String(record.transmittedAtTick),
        record.provenanceDigest,
    ].joined(separator: "|")
}

func oralTransmissionDigest(
    transmissionID: AgentOralTransmissionID,
    communication: AgentLanguageCommunication,
    interpretedSemanticContent: AgentLanguageSemanticContent,
    outcome: AgentOralTransmissionOutcome,
    decisionDigest: String,
    locality: AgentOralLocalityEvidence,
    receiptEventID: AgentCausalEventID,
    acquisition: AgentSimulationSession.KnowledgeOralAcquisition,
    transmittedAtTick: Int
) -> String {
    AgentOralDigest.make([
        "oral-transmission-provenance-v1",
        transmissionID.rawValue,
        communication.speakerID.rawValue,
        communication.recipientID.rawValue,
        communication.sourceBeliefID.rawValue,
        communication.sourceBeliefRevisionEventID.rawValue,
        communication.semanticAuthority.authorityID.rawValue,
        communication.communicationID.rawValue,
        communication.communicationEventID.rawValue,
        communication.semanticContent.digest,
        interpretedSemanticContent.digest,
        outcome.rawValue,
        decisionDigest,
        "\(locality.speakerPosition.x),\(locality.speakerPosition.y),\(locality.speakerPosition.z)",
        "\(locality.recipientPosition.x),\(locality.recipientPosition.y),\(locality.recipientPosition.z)",
        String(locality.distance),
        String(locality.authorizedRadius),
        String(locality.observedAtTick),
        receiptEventID.rawValue,
        acquisition.claimID.rawValue,
        acquisition.claimEventID.rawValue,
        acquisition.understandingID.rawValue,
        acquisition.beliefID.rawValue,
        acquisition.beliefRevisionEventID.rawValue,
        String(transmittedAtTick),
    ].joined(separator: "|"))
}

func oralProvenanceBoundaryDigest(
    _ state: AgentOralTransmissionState
) -> String {
    AgentOralDigest.make(
        "oral-provenance-boundary-v1|"
            + state.transmissions.sorted {
                $0.transmissionID < $1.transmissionID
            }.map(oralTransmissionCanonicalText).joined(separator: ";")
            + "|evicted=\(state.evictedTransmissionCount)"
    )
}
