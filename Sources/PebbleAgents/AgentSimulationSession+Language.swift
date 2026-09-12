extension AgentSimulationSession {
    public var languageEnabled: Bool {
        languageState?.enabled == true
    }

    public mutating func setLanguageEnabled(
        _ enabled: Bool,
        configuration: AgentLanguageConfiguration = .live,
        pack: AgentLanguagePack = .frenchReference
    ) throws {
        if !enabled, writingState != nil {
            throw AgentWritingError.unavailable("language dependency")
        }
        if !enabled, longDistanceCommunicationState != nil {
            throw AgentSessionError.longDistanceCommunication(
                .languageRequired
            )
        }
        guard causalLedger.isEnabled else {
            throw AgentSessionError.language(.causalLedgerRequired)
        }
        guard knowledgeGraphState != nil else {
            throw AgentSessionError.language(.knowledgeRequired)
        }
        if !enabled, oralTransmissionState != nil {
            throw AgentSessionError.oral(.languageRequired)
        }
        if languageState?.enabled == enabled {
            if let state = languageState,
               state.configuration != configuration || state.pack != pack {
                throw AgentSessionError.language(
                    .invalidState("configuration cannot change after initialization")
                )
            }
            return
        }
        var candidate = self
        try candidate.prevalidateCausalAppend(count: 1)
        var state = candidate.languageState
            ?? AgentLanguageGraphState(configuration: configuration, pack: pack)
        guard state.configuration == configuration, state.pack == pack else {
            throw AgentSessionError.language(
                .invalidState("configuration cannot change after initialization")
            )
        }
        state.enabled = enabled
        _ = try candidate.requiredLanguageEvent(
            kind: .languageInitialized,
            actorID: nil,
            subjectID: nil,
            causes: [],
            recordID: state.pack.packID.rawValue,
            propositionID: nil,
            status: enabled ? "enabled" : "disabled",
            reason: "explicit feature transition",
            summary: "language \(enabled ? "enabled" : "disabled") pack=\(state.pack.packID.rawValue)"
        )
        candidate.languageState = state
        try candidate.validateLanguageStateIfInitialized()
        self = candidate
    }

    public func languageSnapshot() -> AgentLanguageSnapshot {
        guard let state = languageState else {
            return AgentLanguageSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                pack: nil,
                lexicalAssociations: [],
                communications: [],
                priorSeedReceipts: [],
                exposureReceipts: [],
                lexicalInnovations: [],
                provenanceBoundary: nil,
                evictedCommunicationCount: 0,
                evictedInnovationCount: 0,
                retiredLexicalAssociationCount: 0,
                digest: AgentLanguageDigest.make("language:none")
            )
        }
        let associations = state.lexicalAssociations.sorted {
            $0.associationID < $1.associationID
        }
        let communications = state.communications.sorted {
            if $0.communicatedAtTick != $1.communicatedAtTick {
                return $0.communicatedAtTick < $1.communicatedAtTick
            }
            return $0.communicationID < $1.communicationID
        }
        let priorSeedReceipts = state.priorSeedReceipts.sorted {
            $0.seedID < $1.seedID
        }
        let exposureReceipts = state.exposureReceipts.sorted {
            $0.communicationID < $1.communicationID
        }
        let lexicalInnovations = state.lexicalEvolution?.innovations.sorted {
            $0.innovationID < $1.innovationID
        } ?? []
        var canonical = [
            "enabled=\(state.enabled ? 1 : 0)",
            "pack=\(state.pack.packID.rawValue)|\(state.pack.languageTag)|\(state.pack.version)",
            state.pack.entries.map {
                "pack|\($0.senseID.rawValue)|\($0.form)"
            }.joined(separator: ";"),
            associations.map { associationCanonicalText($0) }
                .joined(separator: ";"),
            communications.map { communicationCanonicalText($0) }
                .joined(separator: ";"),
            priorSeedReceipts.map { priorSeedReceiptCanonicalText($0) }
                .joined(separator: ";"),
            exposureReceipts.map { exposureReceiptCanonicalText($0) }
                .joined(separator: ";"),
            "provenanceBoundary=" + (state.provenanceBoundary.map {
                "\($0.eventID.rawValue):\($0.digest)"
            } ?? "none"),
            "evicted=\(state.evictedCommunicationCount)",
            "retired=\(state.retiredLexicalAssociationCount)",
            "next=\(state.nextCommunicationOrdinal)",
        ]
        if let evolution = state.lexicalEvolution {
            canonical.append(
                lexicalInnovations.map { innovationCanonicalText($0) }
                    .joined(separator: ";")
            )
            canonical.append(
                "evictedInnovations=\(evolution.evictedInnovationCount)"
            )
        }
        return AgentLanguageSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            pack: state.pack,
            lexicalAssociations: associations,
            communications: communications,
            priorSeedReceipts: priorSeedReceipts,
            exposureReceipts: exposureReceipts,
            lexicalInnovations: lexicalInnovations,
            provenanceBoundary: state.provenanceBoundary,
            evictedCommunicationCount: state.evictedCommunicationCount,
            evictedInnovationCount:
                state.lexicalEvolution?.evictedInnovationCount ?? 0,
            retiredLexicalAssociationCount:
                state.retiredLexicalAssociationCount,
            digest: AgentLanguageDigest.make(canonical.joined(separator: "|"))
        )
    }

    public func languageSummary() -> AgentLanguageSummary {
        let snapshot = languageSnapshot()
        return AgentLanguageSummary(
            enabled: snapshot.enabled,
            lexicalAssociationCount: snapshot.lexicalAssociations.count,
            knownAssociationCount: snapshot.lexicalAssociations.filter {
                $0.competence == .known
            }.count,
            acquiringAssociationCount: snapshot.lexicalAssociations.filter {
                $0.competence == .acquiring
            }.count,
            communicationCount: snapshot.communications.count,
            lexicalInnovationCount: snapshot.lexicalInnovations.count,
            evictedCommunicationCount: snapshot.evictedCommunicationCount,
            evictedInnovationCount: snapshot.evictedInnovationCount,
            retiredLexicalAssociationCount:
                snapshot.retiredLexicalAssociationCount,
            digest: snapshot.digest
        )
    }

    public mutating func seedLanguagePrior(
        for agentID: AgentID,
        senseIDs: [AgentLanguageSenseID]
    ) throws {
        guard var state = languageState, state.enabled else {
            throw AgentSessionError.language(.disabled)
        }
        guard statesById[agentID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(agentID.rawValue))
        }
        let orderedSenseIDs = Array(Set(senseIDs)).sorted()
        let entries = try orderedSenseIDs.map { senseID in
            guard let entry = state.pack.entry(for: senseID) else {
                throw AgentSessionError.language(
                    .missingLexicalKnowledge(senseID.rawValue)
                )
            }
            return entry
        }
        let newEntries = entries.filter { entry in
            !state.lexicalAssociations.contains {
                $0.associationID == languageAssociationID(
                    ownerID: agentID,
                    packID: state.pack.packID,
                    senseID: entry.senseID,
                    form: entry.form
                )
            }
        }
        guard !newEntries.isEmpty else { return }
        try ensureLanguageAssociationCapacity(
            adding: newEntries.count,
            for: agentID,
            state: state
        )
        var candidate = self
        try candidate.prevalidateCausalAppend(count: 1)
        let grantedAssociationIDs = newEntries.map {
            languageAssociationID(
                ownerID: agentID,
                packID: state.pack.packID,
                senseID: $0.senseID,
                form: $0.form
            )
        }.sorted()
        let seedDigest = languagePriorSeedDigest(
            ownerID: agentID,
            packID: state.pack.packID,
            grantedAssociationIDs: grantedAssociationIDs,
            seededAtTick: candidate.tick
        )
        let seedID = "language-seed-" + seedDigest
        let event = try candidate.requiredLanguageEvent(
            kind: .languagePriorSeeded,
            actorID: agentID,
            subjectID: agentID,
            causes: [],
            recordID: seedID,
            propositionID: nil,
            status: "seededPrior",
            reason: seedDigest,
            summary: "language prior seeded agent=\(agentID.rawValue) senses=\(newEntries.count)"
        )
        state.priorSeedReceipts.append(AgentLanguagePriorSeedReceipt(
            seedID: seedID,
            ownerID: agentID,
            packID: state.pack.packID,
            grantedAssociationIDs: grantedAssociationIDs,
            seededAtTick: candidate.tick,
            seedEventID: event.eventID,
            digest: seedDigest
        ))
        for entry in newEntries {
            state.lexicalAssociations.append(AgentLanguageLexicalAssociation(
                associationID: languageAssociationID(
                    ownerID: agentID,
                    packID: state.pack.packID,
                    senseID: entry.senseID,
                    form: entry.form
                ),
                ownerID: agentID,
                packID: state.pack.packID,
                senseID: entry.senseID,
                form: entry.form,
                source: .seededPrior,
                competence: .known,
                exposureCount: 0,
                firstAcquiredAtTick: candidate.tick,
                lastExposedAtTick: candidate.tick,
                lastEventID: event.eventID,
                priorSeedID: seedID,
                innovationID: nil,
                learningCommunicationIDs: [],
                lastExposureCommunicationID: nil
            ))
        }
        candidate.languageState = state
        try candidate.commitLanguageProvenanceBoundary(
            causes: [event.eventID]
        )
        try candidate.validateLanguageStateIfInitialized()
        self = candidate
    }

    /// Produces a bounded individual lexical innovation from two retained,
    /// faithful CIV-43 uses of the pack form with distinct local recipients.
    /// The caller selects only the person and semantic sense; product logic
    /// selects the causal supports and the resulting form.
    @discardableResult
    public mutating func innovateLanguageLexicalForm(
        for agentID: AgentID,
        senseID: AgentLanguageSenseID
    ) throws -> AgentLanguageLexicalInnovation {
        try innovateLanguageLexicalForm(
            for: agentID,
            senseID: senseID,
            recordedEffect: nil
        )
    }

    @discardableResult
    mutating func innovateLanguageLexicalForm(
        for agentID: AgentID,
        senseID: AgentLanguageSenseID,
        recordedEffect: AgentLanguageLexicalInnovationAcceptedEffect?
    ) throws -> AgentLanguageLexicalInnovation {
        guard var state = languageState, state.enabled else {
            throw AgentSessionError.language(.disabled)
        }
        guard statesById[agentID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(agentID.rawValue))
        }
        guard let packEntry = state.pack.entry(for: senseID) else {
            throw AgentSessionError.language(
                .missingLexicalKnowledge(senseID.rawValue)
            )
        }
        if let existing = state.lexicalEvolution?.innovations.first(where: {
            $0.innovatorID == agentID && $0.senseID == senseID
        }) {
            let accepted = AgentLanguageLexicalInnovationAcceptedEffect(
                evolvedForm: existing.evolvedForm,
                decisionDigest: existing.decisionDigest
            )
            guard recordedEffect == nil || recordedEffect == accepted else {
                throw AgentSessionError.language(
                    .replayEffectMismatch(existing.innovationID.rawValue)
                )
            }
            return existing
        }
        guard let source = state.lexicalAssociations.first(where: {
            $0.ownerID == agentID
                && $0.packID == state.pack.packID
                && $0.senseID == senseID
                && $0.form == packEntry.form
                && $0.innovationID == nil
                && $0.competence == .known
        }) else {
            throw AgentSessionError.language(
                .missingLexicalKnowledge(senseID.rawValue)
            )
        }
        guard let oral = oralTransmissionState, oral.enabled else {
            throw AgentSessionError.language(
                .insufficientLocalUsage(senseID.rawValue)
            )
        }
        let communicationsByID = Dictionary(uniqueKeysWithValues:
            state.communications.map { ($0.communicationID, $0) }
        )
        let eligible = oral.transmissions.compactMap {
            transmission -> (AgentOralTransmission, AgentLanguageCommunication)? in
            guard transmission.speakerID == agentID,
                  transmission.outcome == .faithful,
                  let communication = communicationsByID[
                    transmission.languageCommunicationID
                  ],
                  communication.speakerID == agentID,
                  communication.lexicalUses.contains(where: {
                    $0.senseID == senseID
                        && $0.form == packEntry.form
                        && $0.innovationID == nil
                  }) else { return nil }
            return (transmission, communication)
        }.sorted {
            if $0.0.receiptEventID.sequence
                != $1.0.receiptEventID.sequence {
                return $0.0.receiptEventID.sequence
                    < $1.0.receiptEventID.sequence
            }
            return $0.0.transmissionID < $1.0.transmissionID
        }
        guard eligible.count >= 2 else {
            throw AgentSessionError.language(
                .insufficientLocalUsage(senseID.rawValue)
            )
        }
        let supports = Array(eligible.suffix(2))
        guard Set(supports.map { $0.0.recipientID }).count == 2 else {
            throw AgentSessionError.language(
                .insufficientLocalUsage("distinct local recipients")
            )
        }
        let supportReceipts = supports.map { pair in
            let transmission = pair.0
            let communication = pair.1
            let lexicalUse = communication.lexicalUses.first {
                $0.senseID == senseID
                    && $0.form == packEntry.form
                    && $0.innovationID == nil
            }!
            return AgentLanguageLexicalInnovationSupport(
                transmissionID: transmission.transmissionID,
                speakerID: transmission.speakerID,
                recipientID: transmission.recipientID,
                languageCommunicationID: communication.communicationID,
                languageCommunicationEventID:
                    communication.communicationEventID,
                oralReceiptEventID: transmission.receiptEventID,
                outcome: transmission.outcome,
                locality: transmission.locality,
                transmittedAtTick: transmission.transmittedAtTick,
                semanticContentDigest: communication.semanticContent.digest,
                lexicalUse: lexicalUse,
                languageProvenanceDigest: communication.provenanceDigest,
                oralProvenanceDigest: transmission.provenanceDigest
            )
        }
        let canonicalEffect = languageInnovationAcceptedEffect(
            agentID: agentID,
            senseID: senseID,
            sourceAssociationID: source.associationID,
            sourceForm: source.form,
            supports: supportReceipts,
            atTick: tick
        )
        guard recordedEffect == nil || recordedEffect == canonicalEffect else {
            throw AgentSessionError.language(
                .replayEffectMismatch(senseID.rawValue)
            )
        }
        guard !state.pack.entries.contains(where: {
            $0.form == canonicalEffect.evolvedForm
        }), !(state.lexicalEvolution?.innovations.contains(where: {
            $0.evolvedForm == canonicalEffect.evolvedForm
                && $0.senseID != senseID
        }) ?? false) else {
            throw AgentSessionError.language(
                .invalidState("lexical form rebinding")
            )
        }
        try ensureLanguageAssociationCapacity(
            adding: 1,
            for: agentID,
            state: state
        )
        guard (state.lexicalEvolution?.innovations.count ?? 0)
                < state.configuration.maximumLexicalAssociations else {
            throw AgentSessionError.language(
                .capacityReached("lexical innovations")
            )
        }

        var candidate = self
        try candidate.prevalidateCausalAppend(count: 2)
        let innovationID = AgentLanguageLexicalInnovationID(
            rawValue: "language-innovation-"
                + canonicalEffect.decisionDigest
        )!
        let event = try candidate.requiredLanguageEvent(
            kind: .languageLexicalInnovated,
            actorID: agentID,
            subjectID: agentID,
            causes: supportReceipts.map(\.oralReceiptEventID).sorted(),
            recordID: innovationID.rawValue,
            propositionID: nil,
            status: canonicalEffect.evolvedForm,
            reason: canonicalEffect.decisionDigest,
            summary: "lexical innovation agent=\(agentID.rawValue) sense=\(senseID.rawValue)"
        )
        let innovation = AgentLanguageLexicalInnovation(
            innovationID: innovationID,
            innovatorID: agentID,
            packID: state.pack.packID,
            senseID: senseID,
            sourceAssociationID: source.associationID,
            sourceForm: source.form,
            evolvedForm: canonicalEffect.evolvedForm,
            supports: supportReceipts,
            innovatedAtTick: candidate.tick,
            innovationEventID: event.eventID,
            decisionDigest: canonicalEffect.decisionDigest
        )
        var evolution = state.lexicalEvolution
            ?? AgentLanguageLexicalEvolutionState()
        evolution.innovations.append(innovation)
        state.lexicalEvolution = evolution
        state.lexicalAssociations.append(AgentLanguageLexicalAssociation(
            associationID: languageAssociationID(
                ownerID: agentID,
                packID: state.pack.packID,
                senseID: senseID,
                form: canonicalEffect.evolvedForm
            ),
            ownerID: agentID,
            packID: state.pack.packID,
            senseID: senseID,
            form: canonicalEffect.evolvedForm,
            source: .innovation,
            competence: .known,
            exposureCount: 0,
            firstAcquiredAtTick: candidate.tick,
            lastExposedAtTick: candidate.tick,
            lastEventID: event.eventID,
            priorSeedID: nil,
            innovationID: innovationID,
            learningCommunicationIDs: [],
            lastExposureCommunicationID: nil
        ))
        candidate.languageState = state
        try candidate.commitLanguageProvenanceBoundary(causes: [event.eventID])
        try candidate.validateLanguageStateIfInitialized()
        self = candidate
        return innovation
    }

    public func realizeLanguageSemanticContent(
        for agentID: AgentID,
        propositionID: AgentKnowledgePropositionID
    ) throws -> AgentLanguageRealization {
        guard let state = languageState, state.enabled else {
            throw AgentSessionError.language(.disabled)
        }
        guard statesById[agentID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(agentID.rawValue))
        }
        let (belief, _, content) = try languageBeliefAndSemanticContent(
            ownerID: agentID,
            propositionID: propositionID
        )
        _ = belief
        let lexicalUses = try languageLexicalUses(
            for: agentID,
            content: content,
            state: state
        )
        return AgentLanguageRealization(
            semanticContent: content,
            rendering: .deterministic(
                text: languageDeterministicText(
                    content: content,
                    lexicalUses: lexicalUses
                )
            ),
            lexicalUses: lexicalUses
        )
    }

    @discardableResult
    public mutating func communicateLanguageSemanticContent(
        speakerID: AgentID,
        recipientID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode
    ) throws -> AgentLanguageCommunication {
        try communicateLanguageSemanticContent(
            speakerID: speakerID,
            recipientID: recipientID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            localOralAuthority: nil
        )
    }

    /// CIV-43 alone opens this route after validating live local social
    /// authority. A direct CIV-42 caller may realize an evolved form, but may
    /// not teach it to a remote recipient without an authorized carrier.
    mutating func communicateLanguageSemanticContentForLocalOral(
        speakerID: AgentID,
        recipientID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode,
        locality: AgentOralLocalityEvidence
    ) throws -> AgentLanguageCommunication {
        try communicateLanguageSemanticContent(
            speakerID: speakerID,
            recipientID: recipientID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            localOralAuthority: locality
        )
    }

    private mutating func communicateLanguageSemanticContent(
        speakerID: AgentID,
        recipientID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode,
        localOralAuthority: AgentOralLocalityEvidence?
    ) throws -> AgentLanguageCommunication {
        guard var state = languageState, state.enabled else {
            throw AgentSessionError.language(.disabled)
        }
        guard statesById[speakerID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(speakerID.rawValue))
        }
        guard statesById[recipientID.rawValue] != nil else {
            throw AgentSessionError.language(.unknownAgent(recipientID.rawValue))
        }
        guard speakerID != recipientID else {
            throw AgentSessionError.language(
                .invalidState("speaker and recipient must be distinct")
            )
        }
        if let locality = localOralAuthority {
            guard socialEnabled,
                  locality.observedAtTick == tick,
                  locality.speakerPosition
                    == statesById[speakerID.rawValue]?.position,
                  locality.recipientPosition
                    == statesById[recipientID.rawValue]?.position,
                  locality.authorizedRadius
                    == configuration.socialConfiguration.communicationRadius,
                  locality.distance == manhattanDistance(
                    locality.speakerPosition,
                    locality.recipientPosition
                  ),
                  locality.distance <= locality.authorizedRadius,
                  canUseDirectSocialCommunicationAuthority(
                    speakerID: speakerID,
                    recipientID: recipientID
                  ) else {
                throw AgentSessionError.language(
                    .invalidState("invalid local oral authority")
                )
            }
        }
        let (sourceBelief, sourceProposition, content) =
            try languageBeliefAndSemanticContent(
            ownerID: speakerID,
            propositionID: propositionID
        )
        let lexicalUses: [AgentLanguageLexicalUse]
        let surface: AgentLanguageSurfaceRealization
        switch renderingMode {
        case .noRendering:
            lexicalUses = []
            surface = .noRendering
        case .deterministicCompositional:
            lexicalUses = try languageLexicalUses(
                for: speakerID,
                content: content,
                state: state
            )
            surface = .deterministic(text: languageDeterministicText(
                content: content,
                lexicalUses: lexicalUses
            ))
        }
        let carriesEvolvedForm = lexicalUses.contains {
            $0.innovationID != nil
        }
        guard !carriesEvolvedForm || localOralAuthority != nil else {
            throw AgentSessionError.language(
                .invalidState(
                    "evolved lexical exposure requires local oral authority"
                )
            )
        }

        let prospectiveNewAssociations = lexicalUses.filter { lexicalUse in
            !state.lexicalAssociations.contains {
                $0.associationID == languageAssociationID(
                    ownerID: recipientID,
                    packID: state.pack.packID,
                    senseID: lexicalUse.senseID,
                    form: lexicalUse.form
                )
            }
        }.count
        try ensureLanguageAssociationCapacity(
            adding: prospectiveNewAssociations,
            for: recipientID,
            state: state
        )
        guard state.nextCommunicationOrdinal < UInt64.max else {
            throw AgentSessionError.language(
                .capacityReached("communication ordinal")
            )
        }
        let pendingEvictionCount = max(
            0,
            state.communications.count
                - state.configuration.maximumCommunicationRecords + 1
        )
        guard state.evictedCommunicationCount
                <= Int.max - pendingEvictionCount else {
            throw AgentSessionError.language(
                .capacityReached("evicted communication count")
            )
        }

        var candidate = self
        try candidate.prevalidateCausalAppend(count: 1)
        let historicalAuthority = try candidate
            .retainKnowledgeHistoricalBeliefAuthority(
                belief: sourceBelief,
                proposition: sourceProposition
            )
        guard let historicalBoundary = candidate.knowledgeGraphState?
            .historicalBeliefAuthorityBoundary else {
            throw AgentSessionError.language(
                .invalidState("missing CIV-41 historical authority boundary")
            )
        }
        let semanticAuthority = AgentLanguageSemanticAuthorityReference(
            authorityID: historicalAuthority.authorityID
        )
        state = candidate.languageState ?? state
        if state.communications.count >= state.configuration.maximumCommunicationRecords {
            let oralCommunicationIDs = Set(
                candidate.oralTransmissionState?.transmissions.map(
                    \.languageCommunicationID
                ) ?? []
            )
            let removable = state.communications.filter {
                !oralCommunicationIDs.contains($0.communicationID)
            }.sorted {
                if $0.communicatedAtTick != $1.communicatedAtTick {
                    return $0.communicatedAtTick < $1.communicatedAtTick
                }
                return $0.communicationID < $1.communicationID
            }
            guard removable.count >= pendingEvictionCount else {
                throw AgentSessionError.language(
                    .capacityReached("oral-pinned communication records")
                )
            }
            let evicted = removable.prefix(pendingEvictionCount)
            let evictedIDs = Set(evicted.map(\.communicationID))
            state.communications.removeAll {
                evictedIDs.contains($0.communicationID)
            }
            state.evictedCommunicationCount += evictedIDs.count
        }
        let communicationID = AgentLanguageCommunicationID(
            rawValue: "language-communication-\(state.nextCommunicationOrdinal)"
        )!
        let orderedLexicalUses = lexicalUses.sorted { $0.role < $1.role }
        let exposedAssociationIDs = orderedLexicalUses.map {
            languageAssociationID(
                ownerID: recipientID,
                packID: state.pack.packID,
                senseID: $0.senseID,
                form: $0.form
            )
        }.sorted()
        let provenanceDigest = languageExposureDigest(
            communicationID: communicationID,
            speakerID: speakerID,
            recipientID: recipientID,
            sourceBeliefID: sourceBelief.beliefID,
            sourceBeliefRevisionEventID: sourceBelief.lastRevisionEventID,
            sourcePropositionID: propositionID,
            semanticAuthorityID: semanticAuthority.authorityID,
            semanticContentDigest: content.digest,
            lexicalUses: orderedLexicalUses,
            exposedAssociationIDs: exposedAssociationIDs,
            communicatedAtTick: candidate.tick
        )
        let event = try candidate.requiredLanguageEvent(
            kind: .languageSemanticCommunicated,
            actorID: speakerID,
            subjectID: recipientID,
            causes: [historicalBoundary.eventID],
            recordID: communicationID.rawValue,
            propositionID: propositionID,
            status: renderingMode.rawValue,
            reason: provenanceDigest,
            summary: "semantic communication speaker=\(speakerID.rawValue) recipient=\(recipientID.rawValue) rendering=\(renderingMode.rawValue)"
        )
        var newlyLearnedSenseIDs: [AgentLanguageSenseID] = []
        if !orderedLexicalUses.isEmpty {
            state.exposureReceipts.append(AgentLanguageExposureReceipt(
                communicationID: communicationID,
                speakerID: speakerID,
                recipientID: recipientID,
                sourceBeliefID: sourceBelief.beliefID,
                sourceBeliefRevisionEventID:
                    sourceBelief.lastRevisionEventID,
                sourcePropositionID: propositionID,
                semanticAuthorityID: semanticAuthority.authorityID,
                semanticContentDigest: content.digest,
                lexicalUses: orderedLexicalUses,
                exposedAssociationIDs: exposedAssociationIDs,
                communicatedAtTick: candidate.tick,
                communicationEventID: event.eventID,
                digest: provenanceDigest,
                localOralAuthority: nil
            ))
        }
        for lexicalUse in orderedLexicalUses {
            let associationID = languageAssociationID(
                ownerID: recipientID,
                packID: state.pack.packID,
                senseID: lexicalUse.senseID,
                form: lexicalUse.form
            )
            if let index = state.lexicalAssociations.firstIndex(where: {
                $0.associationID == associationID
            }) {
                guard state.lexicalAssociations[index].innovationID
                        == lexicalUse.innovationID else {
                    throw AgentSessionError.language(
                        .invalidState("lexical authority substitution")
                    )
                }
                let wasKnown = state.lexicalAssociations[index].competence
                    == .known
                if state.lexicalAssociations[index].exposureCount
                    < state.configuration.exposuresRequiredForLearning {
                    state.lexicalAssociations[index].exposureCount += 1
                    if state.lexicalAssociations[index].source == .exposure {
                        state.lexicalAssociations[index]
                            .learningCommunicationIDs.append(communicationID)
                    }
                }
                state.lexicalAssociations[index].lastExposedAtTick = candidate.tick
                state.lexicalAssociations[index].lastEventID = event.eventID
                state.lexicalAssociations[index]
                    .lastExposureCommunicationID = communicationID
                if state.lexicalAssociations[index].exposureCount
                    >= state.configuration.exposuresRequiredForLearning {
                    state.lexicalAssociations[index].competence = .known
                }
                if !wasKnown,
                   state.lexicalAssociations[index].competence == .known {
                    newlyLearnedSenseIDs.append(lexicalUse.senseID)
                }
            } else {
                let competence: AgentLanguageLexicalCompetence =
                    state.configuration.exposuresRequiredForLearning == 1
                        ? .known : .acquiring
                state.lexicalAssociations.append(
                    AgentLanguageLexicalAssociation(
                        associationID: associationID,
                        ownerID: recipientID,
                        packID: state.pack.packID,
                        senseID: lexicalUse.senseID,
                        form: lexicalUse.form,
                        source: .exposure,
                        competence: competence,
                        exposureCount: 1,
                        firstAcquiredAtTick: candidate.tick,
                        lastExposedAtTick: candidate.tick,
                        lastEventID: event.eventID,
                        priorSeedID: nil,
                        innovationID: lexicalUse.innovationID,
                        learningCommunicationIDs: [communicationID],
                        lastExposureCommunicationID: communicationID
                    )
                )
                if competence == .known {
                    newlyLearnedSenseIDs.append(lexicalUse.senseID)
                }
            }
        }
        let communication = AgentLanguageCommunication(
            communicationID: communicationID,
            speakerID: speakerID,
            recipientID: recipientID,
            sourceBeliefID: sourceBelief.beliefID,
            sourceBeliefRevisionEventID: sourceBelief.lastRevisionEventID,
            semanticAuthority: semanticAuthority,
            semanticContent: content,
            rendering: surface,
            lexicalUses: orderedLexicalUses,
            exposedAssociationIDs: exposedAssociationIDs.sorted(),
            newlyLearnedSenseIDs: newlyLearnedSenseIDs.sorted(),
            communicatedAtTick: candidate.tick,
            communicationEventID: event.eventID,
            provenanceDigest: provenanceDigest
        )
        state.communications.append(communication)
        state.nextCommunicationOrdinal += 1
        compactLanguageProvenanceReceipts(&state)
        candidate.languageState = state
        try candidate.commitLanguageProvenanceBoundary(
            causes: [event.eventID]
        )
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateLanguageStateIfInitialized(
            pendingLocalOralCommunicationID:
                carriesEvolvedForm ? communicationID : nil
        )
        self = candidate
        return communication
    }

    /// CIV-43 calls this only after publishing the exact local oral row. The
    /// bounded receipt keeps current evolved competence verifiable after the
    /// full carrier row is later compacted; it owns no belief authority.
    mutating func retainLanguageLocalOralAuthority(
        for transmission: AgentOralTransmission
    ) throws {
        guard var state = languageState,
              let index = state.exposureReceipts.firstIndex(where: {
                  $0.communicationID == transmission.languageCommunicationID
              }), state.exposureReceipts[index].lexicalUses.contains(where: {
                  $0.innovationID != nil
              }) else {
            return
        }
        let receipt = state.exposureReceipts[index]
        let authority = AgentLanguageLocalOralAuthorityReceipt(
            transmissionID: transmission.transmissionID,
            oralReceiptEventID: transmission.receiptEventID,
            receivedPropositionID:
                transmission.interpretedSemanticContent.sourcePropositionID,
            interpretedSemanticContentDigest:
                transmission.interpretedSemanticContent.digest,
            outcome: transmission.outcome,
            decisionDigest: transmission.decisionDigest,
            contentAttachment: transmission.contentAttachment,
            locality: transmission.locality,
            transmittedAtTick: transmission.transmittedAtTick,
            oralProvenanceDigest: transmission.provenanceDigest
        )
        guard receipt.localOralAuthority == nil
                || receipt.localOralAuthority == authority else {
            throw AgentSessionError.language(
                .invalidState("substituted local oral authority")
            )
        }
        state.exposureReceipts[index] = AgentLanguageExposureReceipt(
            communicationID: receipt.communicationID,
            speakerID: receipt.speakerID,
            recipientID: receipt.recipientID,
            sourceBeliefID: receipt.sourceBeliefID,
            sourceBeliefRevisionEventID:
                receipt.sourceBeliefRevisionEventID,
            sourcePropositionID: receipt.sourcePropositionID,
            semanticAuthorityID: receipt.semanticAuthorityID,
            semanticContentDigest: receipt.semanticContentDigest,
            lexicalUses: receipt.lexicalUses,
            exposedAssociationIDs: receipt.exposedAssociationIDs,
            communicatedAtTick: receipt.communicatedAtTick,
            communicationEventID: receipt.communicationEventID,
            digest: receipt.digest,
            localOralAuthority: authority
        )
        languageState = state
        try commitLanguageProvenanceBoundary(
            causes: [transmission.receiptEventID]
        )
    }

    /// Mortality remains the sole lifecycle owner. CIV-42 only retires the
    /// departed person's current lexical competence inside that transaction;
    /// bounded communication history remains immutable historical evidence.
    mutating func terminateLanguageForFinalizedDeath(
        agentID: AgentID,
        deathEventID: AgentCausalEventID
    ) throws {
        guard var state = languageState else { return }
        let before = state.lexicalAssociations.count
        state.lexicalAssociations.removeAll { $0.ownerID == agentID }
        compactLanguageProvenanceReceipts(&state)
        let retired = before - state.lexicalAssociations.count
        if state.retiredLexicalAssociationCount <= Int.max - retired {
            state.retiredLexicalAssociationCount += retired
        } else {
            state.retiredLexicalAssociationCount = Int.max
        }
        languageState = state
        try commitLanguageProvenanceBoundary(causes: [deathEventID])
    }

    func languageBeliefAndSemanticContent(
        ownerID: AgentID,
        propositionID: AgentKnowledgePropositionID
    ) throws -> (
        AgentKnowledgeBelief,
        AgentKnowledgeProposition,
        AgentLanguageSemanticContent
    ) {
        guard let knowledge = knowledgeGraphState else {
            throw AgentSessionError.language(.knowledgeRequired)
        }
        guard let proposition = knowledge.propositions.first(where: {
            $0.propositionID == propositionID
        }) else {
            throw AgentSessionError.language(
                .unknownProposition(propositionID.rawValue)
            )
        }
        guard let belief = knowledge.beliefs.first(where: {
            $0.ownerID == ownerID
                && $0.propositionID == propositionID
                && $0.stance == .accepted
        }) else {
            throw AgentSessionError.language(
                .missingBeliefAuthority(ownerID.rawValue)
            )
        }
        return (
            belief,
            proposition,
            try languageSemanticContent(for: proposition)
        )
    }

    func languageSemanticContent(
        for proposition: AgentKnowledgeProposition
    ) throws -> AgentLanguageSemanticContent {
        guard proposition.subject.kind == .worldCell,
              proposition.predicate.rawValue == "world.resource.presence" else {
            throw AgentSessionError.language(
                .unsupportedSemantics(proposition.propositionID.rawValue)
            )
        }
        let valueSenseID: AgentLanguageSenseID
        switch proposition.value {
        case let .resource(kind, _):
            valueSenseID = AgentLanguageSenseID(
                rawValue: "value.resource.\(kind.rawValue)"
            )!
        case .absent:
            valueSenseID = AgentLanguageSenseID(rawValue: "value.absent")!
        default:
            throw AgentSessionError.language(
                .unsupportedSemantics(proposition.propositionID.rawValue)
            )
        }
        return AgentLanguageSemanticContent(
            sourcePropositionID: proposition.propositionID,
            referent: proposition.subject,
            senses: [
                AgentLanguageSenseUse(
                    role: .referentKind,
                    senseID: AgentLanguageSenseID(
                        rawValue: "referent.worldCell"
                    )!
                ),
                AgentLanguageSenseUse(
                    role: .predicate,
                    senseID: AgentLanguageSenseID(
                        rawValue: "predicate.world.resource.presence"
                    )!
                ),
                AgentLanguageSenseUse(
                    role: .value,
                    senseID: valueSenseID
                ),
            ]
        )
    }

    func languageLexicalUses(
        for agentID: AgentID,
        content: AgentLanguageSemanticContent,
        state: AgentLanguageGraphState
    ) throws -> [AgentLanguageLexicalUse] {
        try content.senses.map { senseUse in
            let candidates = state.lexicalAssociations.filter {
                $0.ownerID == agentID
                    && $0.packID == state.pack.packID
                    && $0.senseID == senseUse.senseID
                    && $0.competence == .known
            }.sorted {
                if $0.lastEventID.sequence != $1.lastEventID.sequence {
                    return $0.lastEventID.sequence > $1.lastEventID.sequence
                }
                if $0.exposureCount != $1.exposureCount {
                    return $0.exposureCount > $1.exposureCount
                }
                if $0.firstAcquiredAtTick != $1.firstAcquiredAtTick {
                    return $0.firstAcquiredAtTick < $1.firstAcquiredAtTick
                }
                if $0.form != $1.form { return $0.form < $1.form }
                return $0.associationID < $1.associationID
            }
            guard let association = candidates.first else {
                throw AgentSessionError.language(
                    .missingLexicalKnowledge(senseUse.senseID.rawValue)
                )
            }
            return AgentLanguageLexicalUse(
                role: senseUse.role,
                senseID: senseUse.senseID,
                form: association.form,
                innovationID: association.innovationID
            )
        }.sorted { $0.role < $1.role }
    }

    func languageDeterministicText(
        content: AgentLanguageSemanticContent,
        lexicalUses: [AgentLanguageLexicalUse]
    ) -> String {
        let byRole = Dictionary(uniqueKeysWithValues: lexicalUses.map {
            ($0.role, $0.form)
        })
        let referentSurface = content.referent.key.hasPrefix("cell:")
            ? String(content.referent.key.dropFirst("cell:".count))
            : content.referent.key
        return "\(byRole[.value] ?? "") \(byRole[.predicate] ?? "") "
            + "\(byRole[.referentKind] ?? "") \(referentSurface)"
    }

    private func languageInnovationAcceptedEffect(
        agentID: AgentID,
        senseID: AgentLanguageSenseID,
        sourceAssociationID: AgentLanguageAssociationID,
        sourceForm: String,
        supports: [AgentLanguageLexicalInnovationSupport],
        atTick: Int
    ) -> AgentLanguageLexicalInnovationAcceptedEffect {
        let supportText = supports.map { support in
            let locality = support.locality
            return [
                support.transmissionID.rawValue,
                support.speakerID.rawValue,
                support.recipientID.rawValue,
                support.oralReceiptEventID.rawValue,
                support.outcome.rawValue,
                support.oralProvenanceDigest,
                support.languageCommunicationID.rawValue,
                support.languageCommunicationEventID.rawValue,
                support.languageProvenanceDigest,
                support.semanticContentDigest,
                lexicalUseCanonicalText(support.lexicalUse),
                "\(locality.speakerPosition.x),\(locality.speakerPosition.y),\(locality.speakerPosition.z)",
                "\(locality.recipientPosition.x),\(locality.recipientPosition.y),\(locality.recipientPosition.z)",
                String(locality.distance),
                String(locality.authorizedRadius),
                String(locality.observedAtTick),
            ].joined(separator: ":")
        }.joined(separator: ";")
        let causalInput = [
            "language-lexical-innovation-selector-v1",
            simulationID.rawValue,
            String(configuration.seed),
            String(atTick),
            agentID.rawValue,
            languageState?.pack.packID.rawValue ?? "missing-pack",
            senseID.rawValue,
            sourceAssociationID.rawValue,
            sourceForm,
            supportText,
        ].joined(separator: "|")
        let selectorDigest = AgentLanguageDigest.make(causalInput)
        let selectors = selectorDigest.utf8.map(Int.init)
        let onsets = ["b", "d", "f", "g", "k", "l", "m", "n", "p", "r", "s", "t", "v", "z"]
        let vowels = ["a", "e", "i", "o", "u"]
        let codas = ["", "l", "m", "n", "r", "s", "t"]
        let syllable: (Int) -> String = { offset in
            onsets[selectors[offset] % onsets.count]
                + vowels[selectors[offset + 1] % vowels.count]
                + codas[selectors[offset + 2] % codas.count]
        }
        let senseBinding = String(
            AgentLanguageDigest.make(senseID.rawValue).prefix(8)
        )
        let evolvedForm = syllable(0) + syllable(3) + "-" + senseBinding
        let decisionDigest = AgentLanguageDigest.make(
            causalInput + "|evolved=\(evolvedForm)"
        )
        return AgentLanguageLexicalInnovationAcceptedEffect(
            evolvedForm: evolvedForm,
            decisionDigest: decisionDigest
        )
    }

    func languageAssociationID(
        ownerID: AgentID,
        packID: AgentLanguagePackID,
        senseID: AgentLanguageSenseID,
        form: String
    ) -> AgentLanguageAssociationID {
        AgentLanguageAssociationID(
            rawValue: "language-association-" + AgentLanguageDigest.make(
                "\(ownerID.rawValue)|\(packID.rawValue)|"
                    + "\(senseID.rawValue)|\(form)"
            )
        )!
    }

    func languageLexicalAuthorityIsValid(
        senseID: AgentLanguageSenseID,
        form: String,
        innovationID: AgentLanguageLexicalInnovationID?,
        state: AgentLanguageGraphState
    ) -> Bool {
        if let innovationID {
            guard let innovation = state.lexicalEvolution?.innovations.first(
                where: { $0.innovationID == innovationID }
            ) else { return false }
            return innovation.packID == state.pack.packID
                && innovation.senseID == senseID
                && innovation.evolvedForm == form
        }
        return state.pack.entry(for: senseID)?.form == form
    }

    private func compactLanguageProvenanceReceipts(
        _ state: inout AgentLanguageGraphState
    ) {
        let retainedSeedIDs = Set(
            state.lexicalAssociations.compactMap(\.priorSeedID)
        )
        state.priorSeedReceipts.removeAll {
            !retainedSeedIDs.contains($0.seedID)
        }
        var retainedCommunicationIDs = Set(
            state.lexicalAssociations.flatMap(\.learningCommunicationIDs)
        )
        retainedCommunicationIDs.formUnion(
            state.lexicalAssociations.compactMap(
                \.lastExposureCommunicationID
            )
        )
        if state.lexicalEvolution != nil {
            retainedCommunicationIDs.formUnion(
                state.communications.filter { communication in
                    communication.lexicalUses.contains {
                        $0.innovationID != nil
                    }
                }.map(\.communicationID)
            )
        }
        state.exposureReceipts.removeAll {
            !retainedCommunicationIDs.contains($0.communicationID)
        }
        guard var evolution = state.lexicalEvolution else { return }
        var retainedInnovationIDs = Set(
            state.lexicalAssociations.compactMap(\.innovationID)
        )
        retainedInnovationIDs.formUnion(
            state.communications.flatMap(\.lexicalUses)
                .compactMap(\.innovationID)
        )
        retainedInnovationIDs.formUnion(
            writingState?.artifacts.flatMap {
                $0.plan.realization.lexicalUses
            }.compactMap(\.innovationID) ?? []
        )
        let removed = evolution.innovations.filter {
            !retainedInnovationIDs.contains($0.innovationID)
        }.count
        evolution.innovations.removeAll {
            !retainedInnovationIDs.contains($0.innovationID)
        }
        if evolution.evictedInnovationCount <= Int.max - removed {
            evolution.evictedInnovationCount += removed
        } else {
            evolution.evictedInnovationCount = Int.max
        }
        state.lexicalEvolution = evolution
    }

    mutating func commitLanguageProvenanceBoundary(
        causes: [AgentCausalEventID]
    ) throws {
        guard var state = languageState else { return }
        let proofCount = state.communications.count
            + state.priorSeedReceipts.count
            + state.exposureReceipts.count
            + (state.lexicalEvolution == nil ? 0 : 1)
        guard proofCount > 0 else {
            state.provenanceBoundary = nil
            languageState = state
            return
        }
        let digest = languageProvenanceBoundaryDigest(state)
        var boundaryCauses = causes
        if let previous = state.provenanceBoundary?.eventID {
            boundaryCauses.append(previous)
        }
        let event = try requiredLanguageEvent(
            kind: .languageInitialized,
            actorID: nil,
            subjectID: nil,
            causes: Array(Set(boundaryCauses)).sorted(),
            recordID: state.pack.packID.rawValue,
            propositionID: nil,
            status: "provenanceBoundary",
            reason: digest,
            summary: "language provenance retention boundary"
        )
        state = languageState ?? state
        state.provenanceBoundary = AgentLanguageProvenanceBoundary(
            eventID: event.eventID,
            digest: digest
        )
        languageState = state
    }

    private func ensureLanguageAssociationCapacity(
        adding count: Int,
        for agentID: AgentID,
        state: AgentLanguageGraphState
    ) throws {
        guard state.lexicalAssociations.count + count
                <= state.configuration.maximumLexicalAssociations else {
            throw AgentSessionError.language(
                .capacityReached("lexical associations")
            )
        }
        let current = state.lexicalAssociations.filter {
            $0.ownerID == agentID
        }.count
        guard current + count
                <= state.configuration.maximumLexicalAssociationsPerAgent else {
            throw AgentSessionError.language(
                .capacityReached("lexical associations for \(agentID.rawValue)")
            )
        }
    }

    mutating func requiredLanguageEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        recordID: String,
        propositionID: AgentKnowledgePropositionID?,
        status: String,
        reason: String,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .languageTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes.sorted(),
            payload: .language(
                recordID: recordID,
                propositionID: propositionID?.rawValue,
                status: status,
                reason: reason
            ),
            summary: summary
        ) else {
            throw AgentSessionError.language(.causalLedgerRequired)
        }
        return event
    }

    func validateLanguageStateIfInitialized(
        pendingLocalOralCommunicationID:
            AgentLanguageCommunicationID? = nil
    ) throws {
        guard let state = languageState else { return }
        guard let knowledge = knowledgeGraphState else {
            throw AgentSessionError.language(.knowledgeRequired)
        }
        do {
            _ = try AgentLanguageConfiguration(
                maximumLexicalAssociations:
                    state.configuration.maximumLexicalAssociations,
                maximumLexicalAssociationsPerAgent:
                    state.configuration.maximumLexicalAssociationsPerAgent,
                maximumCommunicationRecords:
                    state.configuration.maximumCommunicationRecords,
                exposuresRequiredForLearning:
                    state.configuration.exposuresRequiredForLearning
            )
            let canonicalPack = try AgentLanguagePack(
                packID: state.pack.packID,
                languageTag: state.pack.languageTag,
                version: state.pack.version,
                provenance: state.pack.provenance,
                license: state.pack.license,
                entries: state.pack.entries
            )
            guard canonicalPack == state.pack else {
                throw AgentLanguageError.invalidPack(
                    state.pack.packID.rawValue
                )
            }
        } catch {
            throw AgentSessionError.language(.invalidState("configuration"))
        }
        guard state.lexicalAssociations.count
                <= state.configuration.maximumLexicalAssociations,
              state.communications.count
                <= state.configuration.maximumCommunicationRecords,
              state.priorSeedReceipts.count
                <= state.lexicalAssociations.count,
              state.exposureReceipts.count <= state.lexicalAssociations.count
                * (state.configuration.exposuresRequiredForLearning + 1)
                + (state.lexicalEvolution == nil
                    ? 0 : state.communications.count),
              state.evictedCommunicationCount >= 0,
              state.retiredLexicalAssociationCount >= 0,
              (state.lexicalEvolution?.evictedInnovationCount ?? 0) >= 0,
              (state.lexicalEvolution?.innovations.count ?? 0)
                <= state.configuration.maximumLexicalAssociations,
              state.nextCommunicationOrdinal > 0,
              Set(state.lexicalAssociations.map(\.associationID)).count
                == state.lexicalAssociations.count,
              Set(state.communications.map(\.communicationID)).count
                == state.communications.count,
              Set(state.priorSeedReceipts.map(\.seedID)).count
                == state.priorSeedReceipts.count,
              Set(state.exposureReceipts.map(\.communicationID)).count
                == state.exposureReceipts.count,
              Set(state.lexicalEvolution?.innovations.map(\.innovationID)
                    ?? []).count
                == (state.lexicalEvolution?.innovations.count ?? 0) else {
            throw AgentSessionError.language(.invalidState("global bound or identity"))
        }
        let activeAgentIDs = Set(statesById.values.map(\.agentID))
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        func retainedEvent(_ eventID: AgentCausalEventID) throws -> AgentCausalEvent? {
            guard eventID.simulationID == simulationID,
                  eventID.sequence.rawValue <= causalLedger.latestSequence else {
                throw AgentSessionError.language(
                    .invalidState("cross-simulation provenance")
                )
            }
            if let event = retainedEvents[eventID] { return event }
            guard causalLedger.droppedEventCount > 0,
                  eventID.sequence.rawValue <= causalLedger.droppedEventCount else {
                throw AgentSessionError.language(
                    .invalidState("missing causal provenance")
                )
            }
            return nil
        }

        let innovations = state.lexicalEvolution?.innovations ?? []
        let innovationsByID = Dictionary(uniqueKeysWithValues:
            innovations.map { ($0.innovationID, $0) }
        )
        let communicationsByID = Dictionary(uniqueKeysWithValues:
            state.communications.map { ($0.communicationID, $0) }
        )
        let oralTransmissionsByID = Dictionary(uniqueKeysWithValues:
            (oralTransmissionState?.transmissions ?? []).map {
                ($0.transmissionID, $0)
            }
        )
        func lexicalAuthorityIsValid(
            senseID: AgentLanguageSenseID,
            form: String,
            innovationID: AgentLanguageLexicalInnovationID?
        ) -> Bool {
            if let innovationID {
                guard let innovation = innovationsByID[innovationID] else {
                    return false
                }
                return innovation.packID == state.pack.packID
                    && innovation.senseID == senseID
                    && innovation.evolvedForm == form
            }
            return state.pack.entry(for: senseID)?.form == form
        }

        for innovation in innovations {
            let canonicalEffect = innovation.supports.count == 2
                ? languageInnovationAcceptedEffect(
                    agentID: innovation.innovatorID,
                    senseID: innovation.senseID,
                    sourceAssociationID: innovation.sourceAssociationID,
                    sourceForm: innovation.sourceForm,
                    supports: innovation.supports,
                    atTick: innovation.innovatedAtTick
                ) : nil
            let distinctSupportRecipients = Set(innovation.supports.map {
                $0.recipientID
            })
            let supportOrderIsCausal = zip(
                innovation.supports,
                innovation.supports.dropFirst()
            ).allSatisfy {
                $0.0.oralReceiptEventID.sequence
                    < $0.1.oralReceiptEventID.sequence
            }
            let supportsAreStructurallyValid = innovation.supports
                .allSatisfy { support in
                    let locality = support.locality
                    return support.speakerID == innovation.innovatorID
                        && support.outcome == .faithful
                        && support.transmittedAtTick
                        <= innovation.innovatedAtTick
                        && support.languageCommunicationEventID.sequence
                        < support.oralReceiptEventID.sequence
                        && support.oralReceiptEventID.sequence
                        < innovation.innovationEventID.sequence
                        && support.languageCommunicationEventID.simulationID
                            == simulationID
                        && support.oralReceiptEventID.simulationID
                            == simulationID
                        && support.lexicalUse.senseID
                            == innovation.senseID
                        && support.lexicalUse.form == innovation.sourceForm
                        && support.lexicalUse.innovationID == nil
                        && locality.observedAtTick
                            == support.transmittedAtTick
                        && locality.distance == manhattanDistance(
                            locality.speakerPosition,
                            locality.recipientPosition
                        )
                        && locality.authorizedRadius
                            == configuration.socialConfiguration
                                .communicationRadius
                        && locality.distance <= locality.authorizedRadius
                }
            guard innovation.packID == state.pack.packID,
                  state.pack.entry(for: innovation.senseID)?.form
                    == innovation.sourceForm,
                  innovation.sourceAssociationID == languageAssociationID(
                    ownerID: innovation.innovatorID,
                    packID: innovation.packID,
                    senseID: innovation.senseID,
                    form: innovation.sourceForm
                  ),
                  innovation.supports.count == 2,
                  distinctSupportRecipients.count == 2,
                  Set(innovation.supportingTransmissionIDs).count == 2,
                  supportOrderIsCausal,
                  supportsAreStructurallyValid,
                  canonicalEffect?.evolvedForm == innovation.evolvedForm,
                  canonicalEffect?.decisionDigest
                    == innovation.decisionDigest,
                  innovation.innovationID.rawValue
                    == "language-innovation-" + innovation.decisionDigest,
                  !state.pack.entries.contains(where: {
                    $0.form == innovation.evolvedForm
                  }),
                  isValidLanguageText(
                    innovation.evolvedForm, maximum: 64
                  ),
                  innovation.innovatedAtTick >= 0,
                  innovation.innovatedAtTick <= tick else {
                throw AgentSessionError.language(
                    .invalidState("lexical innovation authority")
                )
            }
            for support in innovation.supports {
                if let transmission = oralTransmissionsByID[
                    support.transmissionID
                ] {
                    guard transmission.speakerID == support.speakerID,
                          transmission.recipientID == support.recipientID,
                          transmission.languageCommunicationID
                            == support.languageCommunicationID,
                          transmission.languageCommunicationEventID
                            == support.languageCommunicationEventID,
                          transmission.receiptEventID
                            == support.oralReceiptEventID,
                          transmission.outcome == support.outcome,
                          transmission.locality == support.locality,
                          transmission.transmittedAtTick
                            == support.transmittedAtTick,
                          transmission.transmittedSemanticContent.digest
                            == support.semanticContentDigest,
                          transmission.provenanceDigest
                            == support.oralProvenanceDigest else {
                        throw AgentSessionError.language(
                            .invalidState("retained innovation oral support")
                        )
                    }
                } else {
                    guard (oralTransmissionState?.evictedTransmissionCount
                            ?? 0) > 0 else {
                        throw AgentSessionError.language(
                            .invalidState("missing innovation oral support")
                        )
                    }
                }
                if let communication = communicationsByID[
                    support.languageCommunicationID
                ] {
                    guard communication.speakerID == support.speakerID,
                          communication.recipientID == support.recipientID,
                          communication.communicationEventID
                            == support.languageCommunicationEventID,
                          communication.semanticContent.digest
                            == support.semanticContentDigest,
                          communication.lexicalUses.contains(
                            support.lexicalUse
                          ),
                          communication.provenanceDigest
                            == support.languageProvenanceDigest else {
                        throw AgentSessionError.language(
                            .invalidState(
                                "retained innovation language support"
                            )
                        )
                    }
                } else {
                    guard state.evictedCommunicationCount > 0 else {
                        throw AgentSessionError.language(
                            .invalidState(
                                "missing innovation language support"
                            )
                        )
                    }
                }
                if let event = try retainedEvent(
                    support.languageCommunicationEventID
                ) {
                    guard event.kind == .languageSemanticCommunicated,
                          event.origin == .languageTransition,
                          event.actorID == support.speakerID,
                          event.subjectID == support.recipientID,
                          case let .language(
                            recordID, _, _, reason
                          ) = event.payload,
                          recordID
                            == support.languageCommunicationID.rawValue,
                          reason == support.languageProvenanceDigest else {
                        throw AgentSessionError.language(
                            .invalidState("innovation support event")
                        )
                    }
                }
            }
            if let event = try retainedEvent(innovation.innovationEventID) {
                let expectedCauses = innovation.supports.map(
                    \.oralReceiptEventID
                ).sorted()
                guard event.kind == .languageLexicalInnovated,
                      event.origin == .languageTransition,
                      event.actorID == innovation.innovatorID,
                      event.subjectID == innovation.innovatorID,
                      event.causes == expectedCauses,
                      case let .language(
                        recordID, propositionID, status, reason
                      ) = event.payload,
                      recordID == innovation.innovationID.rawValue,
                      propositionID == nil,
                      status == innovation.evolvedForm,
                      reason == innovation.decisionDigest else {
                    throw AgentSessionError.language(
                        .invalidState("lexical innovation event")
                    )
                }
            }
        }
        let formGroups = Dictionary(grouping: innovations, by: \.evolvedForm)
        let ownerSenseGroups = Dictionary(grouping: innovations, by: {
            "\($0.innovatorID.rawValue)|\($0.senseID.rawValue)"
        })
        guard formGroups.allSatisfy({ _, records in
                  Set(records.map(\.senseID)).count == 1
              }),
              ownerSenseGroups.allSatisfy({ _, records in
                  records.count == 1
              }) else {
            throw AgentSessionError.language(
                .invalidState("lexical innovation uniqueness")
            )
        }

        let historicalAuthorityByID = Dictionary(uniqueKeysWithValues:
            (knowledge.historicalBeliefAuthorities ?? []).map {
                ($0.authorityID, $0)
            }
        )
        func validateProvenanceBoundary() throws {
            let proofCount = state.communications.count
                + state.priorSeedReceipts.count
                + state.exposureReceipts.count
                + (state.lexicalEvolution == nil ? 0 : 1)
            if proofCount == 0 {
                guard state.provenanceBoundary == nil else {
                    throw AgentSessionError.language(
                        .invalidState("empty language provenance boundary")
                    )
                }
            } else {
                guard let boundary = state.provenanceBoundary,
                      boundary.digest
                        == languageProvenanceBoundaryDigest(state),
                      let event = retainedEvents[boundary.eventID],
                      event.kind == .languageInitialized,
                      event.origin == .languageTransition,
                      event.actorID == nil,
                      event.subjectID == nil,
                      case let .language(
                        recordID, propositionID, status, reason
                      ) = event.payload,
                      recordID == state.pack.packID.rawValue,
                      propositionID == nil,
                      status == "provenanceBoundary",
                      reason == boundary.digest else {
                    throw AgentSessionError.language(
                        .invalidState("language provenance boundary")
                    )
                }
            }
        }

        let seedReceiptsByID = Dictionary(uniqueKeysWithValues:
            state.priorSeedReceipts.map { ($0.seedID, $0) }
        )
        for receipt in state.priorSeedReceipts {
            let expectedDigest = languagePriorSeedDigest(
                ownerID: receipt.ownerID,
                packID: receipt.packID,
                grantedAssociationIDs: receipt.grantedAssociationIDs,
                seededAtTick: receipt.seededAtTick
            )
            guard activeAgentIDs.contains(receipt.ownerID),
                  receipt.packID == state.pack.packID,
                  !receipt.grantedAssociationIDs.isEmpty,
                  receipt.grantedAssociationIDs
                    == Array(Set(receipt.grantedAssociationIDs)).sorted(),
                  receipt.seededAtTick >= 0,
                  receipt.seededAtTick <= tick,
                  receipt.seedEventID.simulationID == simulationID,
                  receipt.digest == expectedDigest,
                  receipt.seedID == "language-seed-" + expectedDigest else {
                throw AgentSessionError.language(
                    .invalidState("prior seed receipt")
                )
            }
            if let event = try retainedEvent(receipt.seedEventID) {
                guard event.kind == .languagePriorSeeded,
                      event.origin == .languageTransition,
                      event.actorID == receipt.ownerID,
                      event.subjectID == receipt.ownerID,
                      event.causes.isEmpty,
                      case let .language(
                        recordID, propositionID, status, reason
                      ) = event.payload,
                      recordID == receipt.seedID,
                      propositionID == nil,
                      status == "seededPrior",
                      reason == receipt.digest else {
                    throw AgentSessionError.language(
                        .invalidState("prior seed event")
                    )
                }
            }
        }

        let exposureReceiptsByID = Dictionary(uniqueKeysWithValues:
            state.exposureReceipts.map { ($0.communicationID, $0) }
        )
        for receipt in state.exposureReceipts {
            let expectedAssociationIDs = receipt.lexicalUses.map {
                languageAssociationID(
                    ownerID: receipt.recipientID,
                    packID: state.pack.packID,
                    senseID: $0.senseID,
                    form: $0.form
                )
            }.sorted()
            let expectedDigest = languageExposureDigest(
                communicationID: receipt.communicationID,
                speakerID: receipt.speakerID,
                recipientID: receipt.recipientID,
                sourceBeliefID: receipt.sourceBeliefID,
                sourceBeliefRevisionEventID:
                    receipt.sourceBeliefRevisionEventID,
                sourcePropositionID: receipt.sourcePropositionID,
                semanticAuthorityID: receipt.semanticAuthorityID,
                semanticContentDigest: receipt.semanticContentDigest,
                lexicalUses: receipt.lexicalUses,
                exposedAssociationIDs: receipt.exposedAssociationIDs,
                communicatedAtTick: receipt.communicatedAtTick
            )
            guard receipt.speakerID != receipt.recipientID,
                  let historicalAuthority = historicalAuthorityByID[
                    receipt.semanticAuthorityID
                  ],
                  historicalAuthority.beliefID == receipt.sourceBeliefID,
                  historicalAuthority.ownerID == receipt.speakerID,
                  historicalAuthority.sourceBeliefRevisionEventID
                    == receipt.sourceBeliefRevisionEventID,
                  historicalAuthority.proposition.propositionID
                    == receipt.sourcePropositionID,
                  historicalAuthority.beliefUpdatedAtTick
                    <= receipt.communicatedAtTick,
                  !receipt.lexicalUses.isEmpty,
                  receipt.lexicalUses
                    == receipt.lexicalUses.sorted(by: { $0.role < $1.role }),
                  Set(receipt.lexicalUses.map(\.role)).count
                    == receipt.lexicalUses.count,
                  receipt.lexicalUses.allSatisfy({ lexicalUse in
                      lexicalAuthorityIsValid(
                        senseID: lexicalUse.senseID,
                        form: lexicalUse.form,
                        innovationID: lexicalUse.innovationID
                      )
                  }),
                  receipt.exposedAssociationIDs == expectedAssociationIDs,
                  receipt.communicatedAtTick >= 0,
                  receipt.communicatedAtTick <= tick,
                  receipt.communicationEventID.simulationID == simulationID,
                  receipt.digest == expectedDigest else {
                throw AgentSessionError.language(
                    .invalidState("exposure receipt")
                )
            }
            let carriesEvolvedForm = receipt.lexicalUses.contains {
                $0.innovationID != nil
            }
            if carriesEvolvedForm,
               pendingLocalOralCommunicationID
                == receipt.communicationID {
                guard receipt.localOralAuthority == nil else {
                    throw AgentSessionError.language(
                        .invalidState("premature local oral authority")
                    )
                }
            } else if carriesEvolvedForm {
                guard let oralAuthority = receipt.localOralAuthority,
                      oralAuthority.oralReceiptEventID.simulationID
                        == simulationID,
                      oralAuthority.oralReceiptEventID.sequence
                        > receipt.communicationEventID.sequence,
                      oralAuthority.transmittedAtTick
                        == receipt.communicatedAtTick,
                      oralAuthority.locality.observedAtTick
                        == receipt.communicatedAtTick,
                      oralAuthority.locality.distance == manhattanDistance(
                        oralAuthority.locality.speakerPosition,
                        oralAuthority.locality.recipientPosition
                      ),
                      oralAuthority.locality.authorizedRadius
                        == configuration.socialConfiguration
                            .communicationRadius,
                      oralAuthority.locality.distance
                        <= oralAuthority.locality.authorizedRadius,
                      oralAuthority.contentAttachment.map(
                        oralContentAttachmentIsValid
                      ) ?? true else {
                    throw AgentSessionError.language(
                        .invalidState("local oral exposure authority")
                    )
                }
                if let transmission = oralTransmissionsByID[
                    oralAuthority.transmissionID
                ] {
                    guard transmission.speakerID == receipt.speakerID,
                          transmission.recipientID == receipt.recipientID,
                          transmission.languageCommunicationID
                            == receipt.communicationID,
                          transmission.languageCommunicationEventID
                            == receipt.communicationEventID,
                          transmission.receiptEventID
                            == oralAuthority.oralReceiptEventID,
                          transmission.interpretedSemanticContent
                            .sourcePropositionID
                            == oralAuthority.receivedPropositionID,
                          transmission.interpretedSemanticContent.digest
                            == oralAuthority
                                .interpretedSemanticContentDigest,
                          transmission.outcome == oralAuthority.outcome,
                          transmission.decisionDigest
                            == oralAuthority.decisionDigest,
                          transmission.contentAttachment
                            == oralAuthority.contentAttachment,
                          transmission.locality == oralAuthority.locality,
                          transmission.transmittedAtTick
                            == oralAuthority.transmittedAtTick,
                          transmission.provenanceDigest
                            == oralAuthority.oralProvenanceDigest else {
                        throw AgentSessionError.language(
                            .invalidState("retained local oral authority")
                        )
                    }
                } else {
                    guard (oralTransmissionState?.evictedTransmissionCount
                            ?? 0) > 0 else {
                        throw AgentSessionError.language(
                            .invalidState("missing local oral authority")
                        )
                    }
                }
                if let event = try retainedEvent(
                    oralAuthority.oralReceiptEventID
                ) {
                    guard event.kind == .oralTransmissionAccepted,
                          event.origin == .oralTransition,
                          event.actorID == receipt.speakerID,
                          event.subjectID == receipt.recipientID,
                          event.causes == [receipt.communicationEventID],
                          case let .oral(
                            transmissionID, sourceID, receivedID,
                            status, reason
                          ) = event.payload,
                          transmissionID
                            == oralAuthority.transmissionID.rawValue,
                          sourceID == receipt.sourcePropositionID.rawValue,
                          receivedID
                            == oralAuthority.receivedPropositionID.rawValue,
                          status == oralAuthority.outcome.rawValue,
                          reason == oralReceiptReason(
                            decisionDigest: oralAuthority.decisionDigest,
                            contentAttachment:
                                oralAuthority.contentAttachment
                          ) else {
                        throw AgentSessionError.language(
                            .invalidState("local oral receipt event")
                        )
                    }
                }
            } else if receipt.localOralAuthority != nil {
                throw AgentSessionError.language(
                    .invalidState("unexpected local oral authority")
                )
            }
            if let communication = communicationsByID[
                receipt.communicationID
            ] {
                guard communication.speakerID == receipt.speakerID,
                      communication.recipientID == receipt.recipientID,
                      communication.sourceBeliefID
                        == receipt.sourceBeliefID,
                      communication.sourceBeliefRevisionEventID
                        == receipt.sourceBeliefRevisionEventID,
                      communication.semanticContent.sourcePropositionID
                        == receipt.sourcePropositionID,
                      communication.semanticAuthority.authorityID
                        == receipt.semanticAuthorityID,
                      communication.semanticContent.digest
                        == receipt.semanticContentDigest,
                      communication.lexicalUses == receipt.lexicalUses,
                      communication.exposedAssociationIDs
                        == receipt.exposedAssociationIDs,
                      communication.communicatedAtTick
                        == receipt.communicatedAtTick,
                      communication.communicationEventID
                        == receipt.communicationEventID,
                      communication.provenanceDigest == receipt.digest else {
                    throw AgentSessionError.language(
                        .invalidState("retained exposure mismatch")
                    )
                }
            }
            if let event = try retainedEvent(receipt.communicationEventID) {
                guard event.kind == .languageSemanticCommunicated,
                      event.origin == .languageTransition,
                      event.actorID == receipt.speakerID,
                      event.subjectID == receipt.recipientID,
                      event.causes.count == 1,
                      event.causes[0].simulationID == simulationID,
                      event.causes[0].sequence
                        < receipt.communicationEventID.sequence,
                      case let .language(
                        recordID, propositionID, status, reason
                      ) = event.payload,
                      recordID == receipt.communicationID.rawValue,
                      propositionID == receipt.sourcePropositionID.rawValue,
                      status == AgentLanguageRenderingMode
                        .deterministicCompositional.rawValue,
                      reason == receipt.digest else {
                    throw AgentSessionError.language(
                        .invalidState("exposure event")
                    )
                }
            }
        }

        func exposureProves(
            _ receipt: AgentLanguageExposureReceipt,
            association: AgentLanguageLexicalAssociation
        ) -> Bool {
            receipt.recipientID == association.ownerID
                && receipt.exposedAssociationIDs.contains(
                    association.associationID
                )
                && receipt.lexicalUses.contains {
                    $0.senseID == association.senseID
                        && $0.form == association.form
                        && $0.innovationID == association.innovationID
                }
        }

        for association in state.lexicalAssociations {
            guard activeAgentIDs.contains(association.ownerID),
                  association.packID == state.pack.packID,
                  lexicalAuthorityIsValid(
                    senseID: association.senseID,
                    form: association.form,
                    innovationID: association.innovationID
                  ),
                  isValidLanguageText(association.form, maximum: 64),
                  association.exposureCount >= 0,
                  association.exposureCount
                    <= state.configuration.exposuresRequiredForLearning,
                  association.firstAcquiredAtTick >= 0,
                  association.firstAcquiredAtTick
                    <= association.lastExposedAtTick,
                  association.lastExposedAtTick <= tick,
                  association.associationID == languageAssociationID(
                    ownerID: association.ownerID,
                    packID: association.packID,
                    senseID: association.senseID,
                    form: association.form
                  ),
                  Set(association.learningCommunicationIDs).count
                    == association.learningCommunicationIDs.count else {
                throw AgentSessionError.language(
                    .invalidState("lexical association")
                )
            }
            let learningReceipts = association.learningCommunicationIDs
                .compactMap { exposureReceiptsByID[$0] }
            let learningOrderIsCausal = zip(
                learningReceipts,
                learningReceipts.dropFirst()
            ).allSatisfy { pair in
                pair.0.communicationEventID.sequence
                    < pair.1.communicationEventID.sequence
            }
            guard learningReceipts.count
                    == association.learningCommunicationIDs.count,
                  learningReceipts.allSatisfy({
                      exposureProves($0, association: association)
                  }),
                  learningOrderIsCausal else {
                throw AgentSessionError.language(
                    .invalidState("lexical acquisition history")
                )
            }
            switch association.source {
            case .seededPrior:
                guard let seedID = association.priorSeedID,
                      let receipt = seedReceiptsByID[seedID],
                      receipt.ownerID == association.ownerID,
                      receipt.grantedAssociationIDs.contains(
                        association.associationID
                      ),
                      association.competence == .known,
                      association.innovationID == nil,
                      association.learningCommunicationIDs.isEmpty,
                      association.firstAcquiredAtTick
                        == receipt.seededAtTick else {
                    throw AgentSessionError.language(
                        .invalidState("seeded lexical acquisition")
                    )
                }
                if let lastID = association.lastExposureCommunicationID {
                    guard let last = exposureReceiptsByID[lastID],
                          exposureProves(last, association: association),
                          association.lastExposedAtTick
                            == last.communicatedAtTick,
                          association.lastEventID
                            == last.communicationEventID else {
                        throw AgentSessionError.language(
                            .invalidState("seeded lexical last exposure")
                        )
                    }
                } else {
                    guard association.lastExposedAtTick
                            == receipt.seededAtTick,
                          association.lastEventID == receipt.seedEventID else {
                        throw AgentSessionError.language(
                            .invalidState("seeded lexical origin")
                        )
                    }
                }
            case .exposure:
                let expectedCompetence: AgentLanguageLexicalCompetence =
                    association.exposureCount
                        >= state.configuration.exposuresRequiredForLearning
                            ? .known : .acquiring
                guard association.priorSeedID == nil,
                      association.exposureCount > 0,
                      association.exposureCount
                        == association.learningCommunicationIDs.count,
                      association.competence == expectedCompetence,
                      let firstLearning = learningReceipts.first,
                      association.firstAcquiredAtTick
                        == firstLearning.communicatedAtTick,
                      let lastID = association.lastExposureCommunicationID,
                      let last = exposureReceiptsByID[lastID],
                      let lastLearning = learningReceipts.last,
                      exposureProves(last, association: association),
                      association.lastExposedAtTick
                        == last.communicatedAtTick,
                      association.lastEventID
                        == last.communicationEventID,
                      lastLearning.communicationEventID.sequence
                        <= last.communicationEventID.sequence else {
                    throw AgentSessionError.language(
                        .invalidState("exposure lexical acquisition")
                    )
                }
            case .innovation:
                guard association.priorSeedID == nil,
                      let innovationID = association.innovationID,
                      let innovation = innovationsByID[innovationID],
                      innovation.innovatorID == association.ownerID,
                      innovation.packID == association.packID,
                      innovation.senseID == association.senseID,
                      innovation.evolvedForm == association.form,
                      association.competence == .known,
                      association.exposureCount == 0,
                      association.learningCommunicationIDs.isEmpty,
                      association.lastExposureCommunicationID == nil,
                      association.firstAcquiredAtTick
                        == innovation.innovatedAtTick,
                      association.lastExposedAtTick
                        == innovation.innovatedAtTick,
                      association.lastEventID
                        == innovation.innovationEventID else {
                    throw AgentSessionError.language(
                        .invalidState("innovated lexical acquisition")
                    )
                }
            }
        }

        for receipt in state.priorSeedReceipts {
            let exactGrantSet = state.lexicalAssociations.filter {
                $0.priorSeedID == receipt.seedID
            }.map(\.associationID).sorted()
            guard exactGrantSet == receipt.grantedAssociationIDs else {
                throw AgentSessionError.language(
                    .invalidState("seed grant reachability")
                )
            }
        }
        var referencedExposureIDs = Set(
            state.lexicalAssociations.flatMap(\.learningCommunicationIDs)
        )
        referencedExposureIDs.formUnion(
            state.lexicalAssociations.compactMap(
                \.lastExposureCommunicationID
            )
        )
        if state.lexicalEvolution != nil {
            referencedExposureIDs.formUnion(
                state.communications.filter { communication in
                    communication.lexicalUses.contains {
                        $0.innovationID != nil
                    }
                }.map(\.communicationID)
            )
        }
        guard referencedExposureIDs
                == Set(state.exposureReceipts.map(\.communicationID)) else {
            throw AgentSessionError.language(
                .invalidState("exposure receipt reachability")
            )
        }
        for ownerID in Set(state.lexicalAssociations.map(\.ownerID)) {
            guard state.lexicalAssociations.filter({
                $0.ownerID == ownerID
            }).count <= state.configuration.maximumLexicalAssociationsPerAgent else {
                throw AgentSessionError.language(
                    .invalidState("per-agent bound \(ownerID.rawValue)")
                )
            }
        }

        for communication in state.communications {
            guard let historicalAuthority = historicalAuthorityByID[
                communication.semanticAuthority.authorityID
            ] else {
                throw AgentSessionError.language(
                    .invalidState("missing CIV-41 historical authority")
                )
            }
            let rebuiltContent = AgentLanguageSemanticContent(
                sourcePropositionID:
                    communication.semanticContent.sourcePropositionID,
                referent: communication.semanticContent.referent,
                senses: communication.semanticContent.senses
            )
            let expectedSemanticContent = try languageSemanticContent(
                for: historicalAuthority.proposition
            )
            let expectedProvenanceDigest = languageExposureDigest(
                communicationID: communication.communicationID,
                speakerID: communication.speakerID,
                recipientID: communication.recipientID,
                sourceBeliefID: communication.sourceBeliefID,
                sourceBeliefRevisionEventID:
                    communication.sourceBeliefRevisionEventID,
                sourcePropositionID:
                    communication.semanticContent.sourcePropositionID,
                semanticAuthorityID:
                    communication.semanticAuthority.authorityID,
                semanticContentDigest: communication.semanticContent.digest,
                lexicalUses: communication.lexicalUses,
                exposedAssociationIDs:
                    communication.exposedAssociationIDs,
                communicatedAtTick: communication.communicatedAtTick
            )
            guard rebuiltContent == communication.semanticContent,
                  expectedSemanticContent == communication.semanticContent,
                  historicalAuthority.beliefID
                    == communication.sourceBeliefID,
                  historicalAuthority.ownerID == communication.speakerID,
                  historicalAuthority.sourceBeliefRevisionEventID
                    == communication.sourceBeliefRevisionEventID,
                  historicalAuthority.proposition.propositionID
                    == communication.semanticContent.sourcePropositionID,
                  historicalAuthority.beliefUpdatedAtTick
                    <= communication.communicatedAtTick,
                  communication.speakerID != communication.recipientID,
                  AgentID(rawValue: communication.speakerID.rawValue) != nil,
                  AgentID(rawValue: communication.recipientID.rawValue) != nil,
                  communication.communicatedAtTick >= 0,
                  communication.communicatedAtTick <= tick,
                  Set(communication.semanticContent.senses.map(\.role)).count
                    == communication.semanticContent.senses.count,
                  communication.semanticContent.senses.count == 3,
                  communication.exposedAssociationIDs
                    == communication.exposedAssociationIDs.sorted(),
                  communication.newlyLearnedSenseIDs
                    == communication.newlyLearnedSenseIDs.sorted(),
                  Set(communication.newlyLearnedSenseIDs).count
                    == communication.newlyLearnedSenseIDs.count,
                  Set(communication.newlyLearnedSenseIDs).isSubset(
                    of: Set(communication.lexicalUses.map(\.senseID))
                  ),
                  communication.provenanceDigest
                    == expectedProvenanceDigest else {
                throw AgentSessionError.language(
                    .invalidState("semantic authority mismatch")
                )
            }
            switch communication.rendering {
            case .noRendering:
                guard communication.lexicalUses.isEmpty,
                      communication.exposedAssociationIDs.isEmpty,
                      communication.newlyLearnedSenseIDs.isEmpty else {
                    throw AgentSessionError.language(
                        .invalidState("NO_RENDERING exposure")
                    )
                }
            case let .deterministic(text):
                let orderedUses = communication.lexicalUses.sorted {
                    $0.role < $1.role
                }
                let expectedExposedAssociationIDs = orderedUses.map {
                    languageAssociationID(
                        ownerID: communication.recipientID,
                        packID: state.pack.packID,
                        senseID: $0.senseID,
                        form: $0.form
                    )
                }.sorted()
                guard communication.lexicalUses == orderedUses,
                      orderedUses.map(\.role)
                        == communication.semanticContent.senses.map(\.role),
                      orderedUses.map(\.senseID)
                        == communication.semanticContent.senses.map(\.senseID),
                      orderedUses.allSatisfy({
                          isValidLanguageText($0.form, maximum: 64)
                            && lexicalAuthorityIsValid(
                                senseID: $0.senseID,
                                form: $0.form,
                                innovationID: $0.innovationID
                            )
                      }),
                      communication.exposedAssociationIDs
                        == expectedExposedAssociationIDs,
                      isValidLanguageText(text, maximum: 256),
                      text == languageDeterministicText(
                        content: communication.semanticContent,
                        lexicalUses: orderedUses
                      ) else {
                    throw AgentSessionError.language(
                        .invalidState("deterministic rendering")
                    )
                }
            }
            if communication.lexicalUses.contains(where: {
                $0.innovationID != nil
            }) {
                let oralRecord = oralTransmissionState?.transmissions.first {
                    $0.languageCommunicationID
                        == communication.communicationID
                }
                let retainedAuthority = exposureReceiptsByID[
                    communication.communicationID
                ]?.localOralAuthority
                guard pendingLocalOralCommunicationID
                        == communication.communicationID
                        || retainedAuthority != nil
                        || (oralRecord?.speakerID == communication.speakerID
                            && oralRecord?.recipientID
                                == communication.recipientID
                            && oralRecord?.languageCommunicationEventID
                                == communication.communicationEventID) else {
                    throw AgentSessionError.language(
                        .invalidState(
                            "evolved exposure lacks local oral carrier"
                        )
                    )
                }
            }
            if let event = try retainedEvent(communication.communicationEventID) {
                guard event.kind == .languageSemanticCommunicated,
                      event.origin == .languageTransition,
                      event.actorID == communication.speakerID,
                      event.subjectID == communication.recipientID,
                      event.causes.count == 1,
                      event.causes[0].simulationID == simulationID,
                      event.causes[0].sequence
                        < communication.communicationEventID.sequence,
                      case let .language(
                        recordID, propositionID, status, reason
                      ) = event.payload,
                      recordID == communication.communicationID.rawValue,
                      propositionID == communication.semanticContent
                        .sourcePropositionID.rawValue,
                      status == (communication.rendering == .noRendering
                        ? AgentLanguageRenderingMode.noRendering.rawValue
                        : AgentLanguageRenderingMode
                            .deterministicCompositional.rawValue),
                      reason == communication.provenanceDigest else {
                    throw AgentSessionError.language(
                        .invalidState("communication event")
                    )
                }
            }
        }
        if let pendingLocalOralCommunicationID {
            guard state.communications.contains(where: {
                $0.communicationID == pendingLocalOralCommunicationID
                    && $0.lexicalUses.contains(where: {
                        $0.innovationID != nil
                    })
            }) else {
                throw AgentSessionError.language(
                    .invalidState("invalid pending local oral exposure")
                )
            }
        }
        var referencedInnovationIDs = Set(
            state.lexicalAssociations.compactMap(\.innovationID)
        )
        referencedInnovationIDs.formUnion(
            state.communications.flatMap(\.lexicalUses)
                .compactMap(\.innovationID)
        )
        referencedInnovationIDs.formUnion(
            writingState?.artifacts.flatMap {
                $0.plan.realization.lexicalUses
            }.compactMap(\.innovationID) ?? []
        )
        guard referencedInnovationIDs == Set(innovationsByID.keys) else {
            throw AgentSessionError.language(
                .invalidState("lexical innovation reachability")
            )
        }
        try validateProvenanceBoundary()
    }
}

private func communicationCanonicalText(
    _ communication: AgentLanguageCommunication
) -> String {
    let rendering: String
    switch communication.rendering {
    case .noRendering:
        rendering = "NO_RENDERING"
    case let .deterministic(text):
        rendering = "deterministic:\(text)"
    }
    return "communication|\(communication.communicationID.rawValue)|"
        + "\(communication.speakerID.rawValue)|\(communication.recipientID.rawValue)|"
        + "\(communication.sourceBeliefID.rawValue)|"
        + "\(communication.sourceBeliefRevisionEventID.rawValue)|"
        + "\(communication.semanticAuthority.authorityID.rawValue)|"
        + "\(communication.semanticContent.digest)|\(rendering)|"
        + communication.lexicalUses.map(lexicalUseCanonicalText)
            .joined(separator: ",")
        + "|" + communication.exposedAssociationIDs.map(\.rawValue)
            .joined(separator: ",")
        + "|" + communication.newlyLearnedSenseIDs.map(\.rawValue)
            .joined(separator: ",")
        + "|\(communication.communicatedAtTick)|"
        + communication.communicationEventID.rawValue
        + "|\(communication.provenanceDigest)"
}

private func associationCanonicalText(
    _ association: AgentLanguageLexicalAssociation
) -> String {
    var fields = [
        "association",
        association.associationID.rawValue,
        association.ownerID.rawValue,
        association.packID.rawValue,
        association.senseID.rawValue,
        association.form,
        association.source.rawValue,
        association.competence.rawValue,
        String(association.exposureCount),
        String(association.firstAcquiredAtTick),
        String(association.lastExposedAtTick),
        association.lastEventID.rawValue,
        association.priorSeedID ?? "none",
        association.learningCommunicationIDs.map(\.rawValue)
            .joined(separator: ","),
        association.lastExposureCommunicationID?.rawValue ?? "none",
    ]
    if let innovationID = association.innovationID {
        fields.append(innovationID.rawValue)
    }
    return fields.joined(separator: "|")
}

private func lexicalUseCanonicalText(
    _ use: AgentLanguageLexicalUse
) -> String {
    let base = "\(use.role.rawValue):\(use.senseID.rawValue):\(use.form)"
    return use.innovationID.map { base + ":" + $0.rawValue } ?? base
}

private func innovationCanonicalText(
    _ innovation: AgentLanguageLexicalInnovation
) -> String {
    [
        "innovation",
        innovation.innovationID.rawValue,
        innovation.innovatorID.rawValue,
        innovation.packID.rawValue,
        innovation.senseID.rawValue,
        innovation.sourceAssociationID.rawValue,
        innovation.sourceForm,
        innovation.evolvedForm,
        innovation.supports.map(innovationSupportCanonicalText)
            .joined(separator: ";"),
        String(innovation.innovatedAtTick),
        innovation.innovationEventID.rawValue,
        innovation.decisionDigest,
    ].joined(separator: "|")
}

private func innovationSupportCanonicalText(
    _ support: AgentLanguageLexicalInnovationSupport
) -> String {
    let locality = support.locality
    return [
        "support",
        support.transmissionID.rawValue,
        support.speakerID.rawValue,
        support.recipientID.rawValue,
        support.languageCommunicationID.rawValue,
        support.languageCommunicationEventID.rawValue,
        support.oralReceiptEventID.rawValue,
        support.outcome.rawValue,
        "\(locality.speakerPosition.x),\(locality.speakerPosition.y),\(locality.speakerPosition.z)",
        "\(locality.recipientPosition.x),\(locality.recipientPosition.y),\(locality.recipientPosition.z)",
        String(locality.distance),
        String(locality.authorizedRadius),
        String(locality.observedAtTick),
        String(support.transmittedAtTick),
        support.semanticContentDigest,
        lexicalUseCanonicalText(support.lexicalUse),
        support.languageProvenanceDigest,
        support.oralProvenanceDigest,
    ].joined(separator: ":")
}

private func languagePriorSeedDigest(
    ownerID: AgentID,
    packID: AgentLanguagePackID,
    grantedAssociationIDs: [AgentLanguageAssociationID],
    seededAtTick: Int
) -> String {
    AgentLanguageDigest.make([
        "prior-seed",
        ownerID.rawValue,
        packID.rawValue,
        grantedAssociationIDs.map(\.rawValue).joined(separator: ","),
        String(seededAtTick),
    ].joined(separator: "|"))
}

private func languageExposureDigest(
    communicationID: AgentLanguageCommunicationID,
    speakerID: AgentID,
    recipientID: AgentID,
    sourceBeliefID: AgentKnowledgeBeliefID,
    sourceBeliefRevisionEventID: AgentCausalEventID,
    sourcePropositionID: AgentKnowledgePropositionID,
    semanticAuthorityID: AgentKnowledgeHistoricalBeliefAuthorityID,
    semanticContentDigest: String,
    lexicalUses: [AgentLanguageLexicalUse],
    exposedAssociationIDs: [AgentLanguageAssociationID],
    communicatedAtTick: Int
) -> String {
    AgentLanguageDigest.make([
        "linguistic-exposure",
        communicationID.rawValue,
        speakerID.rawValue,
        recipientID.rawValue,
        sourceBeliefID.rawValue,
        sourceBeliefRevisionEventID.rawValue,
        sourcePropositionID.rawValue,
        semanticAuthorityID.rawValue,
        semanticContentDigest,
        lexicalUses.map(lexicalUseCanonicalText).joined(separator: ","),
        exposedAssociationIDs.map(\.rawValue).joined(separator: ","),
        String(communicatedAtTick),
    ].joined(separator: "|"))
}

private func priorSeedReceiptCanonicalText(
    _ receipt: AgentLanguagePriorSeedReceipt
) -> String {
    [
        "seed-receipt",
        receipt.seedID,
        receipt.ownerID.rawValue,
        receipt.packID.rawValue,
        receipt.grantedAssociationIDs.map(\.rawValue).joined(separator: ","),
        String(receipt.seededAtTick),
        receipt.seedEventID.rawValue,
        receipt.digest,
    ].joined(separator: "|")
}

private func exposureReceiptCanonicalText(
    _ receipt: AgentLanguageExposureReceipt
) -> String {
    var fields = [
        "exposure-receipt",
        receipt.communicationID.rawValue,
        receipt.speakerID.rawValue,
        receipt.recipientID.rawValue,
        receipt.sourceBeliefID.rawValue,
        receipt.sourceBeliefRevisionEventID.rawValue,
        receipt.sourcePropositionID.rawValue,
        receipt.semanticAuthorityID.rawValue,
        receipt.semanticContentDigest,
        receipt.lexicalUses.map(lexicalUseCanonicalText)
            .joined(separator: ","),
        receipt.exposedAssociationIDs.map(\.rawValue).joined(separator: ","),
        String(receipt.communicatedAtTick),
        receipt.communicationEventID.rawValue,
        receipt.digest,
    ]
    if let authority = receipt.localOralAuthority {
        fields.append(localOralAuthorityCanonicalText(authority))
    }
    return fields.joined(separator: "|")
}

private func localOralAuthorityCanonicalText(
    _ authority: AgentLanguageLocalOralAuthorityReceipt
) -> String {
    let locality = authority.locality
    return [
        "local-oral-authority",
        authority.transmissionID.rawValue,
        authority.oralReceiptEventID.rawValue,
        authority.receivedPropositionID.rawValue,
        authority.interpretedSemanticContentDigest,
        authority.outcome.rawValue,
        authority.decisionDigest,
        authority.contentAttachment?.canonicalText ?? "none",
        "\(locality.speakerPosition.x),\(locality.speakerPosition.y),\(locality.speakerPosition.z)",
        "\(locality.recipientPosition.x),\(locality.recipientPosition.y),\(locality.recipientPosition.z)",
        String(locality.distance),
        String(locality.authorizedRadius),
        String(locality.observedAtTick),
        String(authority.transmittedAtTick),
        authority.oralProvenanceDigest,
    ].joined(separator: ":")
}

func languageProvenanceBoundaryDigest(
    _ state: AgentLanguageGraphState
) -> String {
    let communications = state.communications.sorted {
        $0.communicationID < $1.communicationID
    }.map(communicationCanonicalText).joined(separator: ";")
    let seeds = state.priorSeedReceipts.sorted {
        $0.seedID < $1.seedID
    }.map(priorSeedReceiptCanonicalText).joined(separator: ";")
    let exposures = state.exposureReceipts.sorted {
        $0.communicationID < $1.communicationID
    }.map(exposureReceiptCanonicalText).joined(separator: ";")
    let legacy = "language-provenance-boundary-v1|communications=\(communications)"
        + "|seeds=\(seeds)|exposures=\(exposures)"
    guard let evolution = state.lexicalEvolution else {
        return AgentLanguageDigest.make(legacy)
    }
    let innovations = evolution.innovations.sorted {
        $0.innovationID < $1.innovationID
    }.map(innovationCanonicalText).joined(separator: ";")
    return AgentLanguageDigest.make(
        "language-provenance-boundary-v2|communications=\(communications)"
            + "|seeds=\(seeds)|exposures=\(exposures)"
            + "|innovations=\(innovations)"
            + "|evictedInnovations=\(evolution.evictedInnovationCount)"
    )
}
