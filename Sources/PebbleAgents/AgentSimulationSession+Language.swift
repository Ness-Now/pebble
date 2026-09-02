extension AgentSimulationSession {
    public var languageEnabled: Bool {
        languageState?.enabled == true
    }

    public mutating func setLanguageEnabled(
        _ enabled: Bool,
        configuration: AgentLanguageConfiguration = .live,
        pack: AgentLanguagePack = .frenchReference
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.language(.causalLedgerRequired)
        }
        guard knowledgeGraphState != nil else {
            throw AgentSessionError.language(.knowledgeRequired)
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
                evictedCommunicationCount: 0,
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
        let canonical = [
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
            "evicted=\(state.evictedCommunicationCount)",
            "retired=\(state.retiredLexicalAssociationCount)",
            "next=\(state.nextCommunicationOrdinal)",
        ].joined(separator: "|")
        return AgentLanguageSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            pack: state.pack,
            lexicalAssociations: associations,
            communications: communications,
            priorSeedReceipts: priorSeedReceipts,
            exposureReceipts: exposureReceipts,
            evictedCommunicationCount: state.evictedCommunicationCount,
            retiredLexicalAssociationCount:
                state.retiredLexicalAssociationCount,
            digest: AgentLanguageDigest.make(canonical)
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
            evictedCommunicationCount: snapshot.evictedCommunicationCount,
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
                learningCommunicationIDs: [],
                lastExposureCommunicationID: nil
            ))
        }
        candidate.languageState = state
        try candidate.validateLanguageStateIfInitialized()
        self = candidate
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
        let (sourceBelief, sourceProposition, content) =
            try languageBeliefAndSemanticContent(
            ownerID: speakerID,
            propositionID: propositionID
        )
        let semanticAuthority = languageSemanticAuthorityReceipt(
            belief: sourceBelief,
            proposition: sourceProposition
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
        if state.communications.count >= state.configuration.maximumCommunicationRecords {
            let evicted = state.communications.sorted {
                if $0.communicatedAtTick != $1.communicatedAtTick {
                    return $0.communicatedAtTick < $1.communicatedAtTick
                }
                return $0.communicationID < $1.communicationID
            }.prefix(pendingEvictionCount)
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
            semanticAuthorityDigest: semanticAuthority.digest,
            semanticContentDigest: content.digest,
            lexicalUses: orderedLexicalUses,
            exposedAssociationIDs: exposedAssociationIDs,
            communicatedAtTick: candidate.tick
        )
        let event = try candidate.requiredLanguageEvent(
            kind: .languageSemanticCommunicated,
            actorID: speakerID,
            subjectID: recipientID,
            causes: [sourceBelief.lastRevisionEventID],
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
                semanticAuthorityDigest: semanticAuthority.digest,
                semanticContentDigest: content.digest,
                lexicalUses: orderedLexicalUses,
                exposedAssociationIDs: exposedAssociationIDs,
                communicatedAtTick: candidate.tick,
                communicationEventID: event.eventID,
                digest: provenanceDigest
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
        try candidate.validateLanguageStateIfInitialized()
        self = candidate
        return communication
    }

    /// Mortality remains the sole lifecycle owner. CIV-42 only retires the
    /// departed person's current lexical competence inside that transaction;
    /// bounded communication history remains immutable historical evidence.
    mutating func terminateLanguageForFinalizedDeath(agentID: AgentID) {
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
    }

    private func languageBeliefAndSemanticContent(
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

    private func languageSemanticContent(
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

    private func languageLexicalUses(
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
                form: association.form
            )
        }.sorted { $0.role < $1.role }
    }

    private func languageDeterministicText(
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

    private func languageAssociationID(
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

    private func languageSemanticAuthorityReceipt(
        belief: AgentKnowledgeBelief,
        proposition: AgentKnowledgeProposition
    ) -> AgentLanguageSemanticAuthorityReceipt {
        AgentLanguageSemanticAuthorityReceipt(
            sourceBeliefID: belief.beliefID,
            sourceOwnerID: belief.ownerID,
            proposition: proposition,
            stance: belief.stance,
            basisUnderstandingID: belief.basisUnderstandingID,
            beliefFormedAtTick: belief.formedAtTick,
            beliefUpdatedAtTick: belief.updatedAtTick,
            beliefRevisionCount: belief.revisionCount,
            sourceBeliefRevisionEventID: belief.lastRevisionEventID,
            digest: languageSemanticAuthorityDigest(
                sourceBeliefID: belief.beliefID,
                sourceOwnerID: belief.ownerID,
                proposition: proposition,
                stance: belief.stance,
                basisUnderstandingID: belief.basisUnderstandingID,
                beliefFormedAtTick: belief.formedAtTick,
                beliefUpdatedAtTick: belief.updatedAtTick,
                beliefRevisionCount: belief.revisionCount,
                sourceBeliefRevisionEventID: belief.lastRevisionEventID
            )
        )
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
        state.exposureReceipts.removeAll {
            !retainedCommunicationIDs.contains($0.communicationID)
        }
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

    private mutating func requiredLanguageEvent(
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

    func validateLanguageStateIfInitialized() throws {
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
                * (state.configuration.exposuresRequiredForLearning + 1),
              state.evictedCommunicationCount >= 0,
              state.retiredLexicalAssociationCount >= 0,
              state.nextCommunicationOrdinal > 0,
              Set(state.lexicalAssociations.map(\.associationID)).count
                == state.lexicalAssociations.count,
              Set(state.communications.map(\.communicationID)).count
                == state.communications.count,
              Set(state.priorSeedReceipts.map(\.seedID)).count
                == state.priorSeedReceipts.count,
              Set(state.exposureReceipts.map(\.communicationID)).count
                == state.exposureReceipts.count else {
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

        func validateSemanticAuthority(
            _ receipt: AgentLanguageSemanticAuthorityReceipt,
            communicatedAtTick: Int
        ) throws {
            let canonicalProposition = AgentKnowledgeProposition(
                subject: receipt.proposition.subject,
                predicate: receipt.proposition.predicate,
                value: receipt.proposition.value
            )
            let canonicalBeliefID = AgentKnowledgeBeliefID(
                rawValue: "belief-" + AgentKnowledgeDigest.make(
                    "\(receipt.sourceOwnerID.rawValue)|"
                        + receipt.proposition.questionKey
                )
            )!
            let expectedDigest = languageSemanticAuthorityDigest(
                sourceBeliefID: receipt.sourceBeliefID,
                sourceOwnerID: receipt.sourceOwnerID,
                proposition: receipt.proposition,
                stance: receipt.stance,
                basisUnderstandingID: receipt.basisUnderstandingID,
                beliefFormedAtTick: receipt.beliefFormedAtTick,
                beliefUpdatedAtTick: receipt.beliefUpdatedAtTick,
                beliefRevisionCount: receipt.beliefRevisionCount,
                sourceBeliefRevisionEventID:
                    receipt.sourceBeliefRevisionEventID
            )
            guard canonicalProposition == receipt.proposition,
                  canonicalBeliefID == receipt.sourceBeliefID,
                  receipt.stance == .accepted,
                  receipt.beliefFormedAtTick >= 0,
                  receipt.beliefFormedAtTick
                    <= receipt.beliefUpdatedAtTick,
                  receipt.beliefUpdatedAtTick <= communicatedAtTick,
                  receipt.beliefRevisionCount >= 1,
                  receipt.sourceBeliefRevisionEventID.simulationID
                    == simulationID,
                  receipt.digest == expectedDigest else {
                throw AgentSessionError.language(
                    .invalidState("CIV-41 semantic authority receipt")
                )
            }
            if let retainedProposition = knowledge.propositions.first(where: {
                $0.propositionID == receipt.proposition.propositionID
            }), retainedProposition != receipt.proposition {
                throw AgentSessionError.language(
                    .invalidState("CIV-41 proposition mismatch")
                )
            }
            if let revision = knowledge.revisions.first(where: {
                $0.revisionEventID == receipt.sourceBeliefRevisionEventID
            }) {
                guard revision.beliefID == receipt.sourceBeliefID,
                      revision.ownerID == receipt.sourceOwnerID,
                      revision.questionKey == receipt.proposition.questionKey,
                      revision.propositionID
                        == receipt.proposition.propositionID,
                      revision.stance == receipt.stance,
                      revision.triggerUnderstandingID
                        == receipt.basisUnderstandingID,
                      revision.revisedAtTick
                        == receipt.beliefUpdatedAtTick else {
                    throw AgentSessionError.language(
                        .invalidState("CIV-41 retained revision mismatch")
                    )
                }
            }
            if let currentBelief = knowledge.beliefs.first(where: {
                $0.beliefID == receipt.sourceBeliefID
            }) {
                guard currentBelief.ownerID == receipt.sourceOwnerID,
                      currentBelief.questionKey
                        == receipt.proposition.questionKey,
                      currentBelief.formedAtTick
                        == receipt.beliefFormedAtTick,
                      currentBelief.revisionCount
                        >= receipt.beliefRevisionCount,
                      currentBelief.lastRevisionEventID.sequence
                        >= receipt.sourceBeliefRevisionEventID.sequence else {
                    throw AgentSessionError.language(
                        .invalidState("CIV-41 retained belief mismatch")
                    )
                }
                if currentBelief.lastRevisionEventID
                    == receipt.sourceBeliefRevisionEventID {
                    guard currentBelief.propositionID
                            == receipt.proposition.propositionID,
                          currentBelief.stance == receipt.stance,
                          currentBelief.basisUnderstandingID
                            == receipt.basisUnderstandingID,
                          currentBelief.updatedAtTick
                            == receipt.beliefUpdatedAtTick,
                          currentBelief.revisionCount
                            == receipt.beliefRevisionCount else {
                        throw AgentSessionError.language(
                            .invalidState("CIV-41 exact belief mismatch")
                        )
                    }
                }
            } else if let departed = (knowledge.departedBeliefs ?? []).first(
                where: { $0.beliefID == receipt.sourceBeliefID }
            ) {
                guard departed.ownerID == receipt.sourceOwnerID,
                      departed.proposition.questionKey
                        == receipt.proposition.questionKey,
                      departed.formedAtTick == receipt.beliefFormedAtTick,
                      departed.revisionCount >= receipt.beliefRevisionCount,
                      departed.lastRevisionEventID.sequence
                        >= receipt.sourceBeliefRevisionEventID.sequence else {
                    throw AgentSessionError.language(
                        .invalidState("CIV-41 departed belief mismatch")
                    )
                }
                if departed.lastRevisionEventID
                    == receipt.sourceBeliefRevisionEventID {
                    guard departed.proposition == receipt.proposition,
                          departed.stance == receipt.stance,
                          departed.basisUnderstandingID
                            == receipt.basisUnderstandingID,
                          departed.updatedAtTick
                            == receipt.beliefUpdatedAtTick,
                          departed.revisionCount
                            == receipt.beliefRevisionCount else {
                        throw AgentSessionError.language(
                            .invalidState("CIV-41 exact departed belief mismatch")
                        )
                    }
                }
            } else if activeAgentIDs.contains(receipt.sourceOwnerID) {
                throw AgentSessionError.language(
                    .invalidState("missing retained CIV-41 belief")
                )
            }
            if let event = try retainedEvent(
                receipt.sourceBeliefRevisionEventID
            ) {
                guard event.kind == .knowledgeBeliefRevised,
                      event.origin == .knowledgeTransition,
                      event.actorID == receipt.sourceOwnerID,
                      event.subjectID == receipt.sourceOwnerID,
                      case let .knowledge(
                        recordID, propositionID, status, _
                      ) = event.payload,
                      recordID == receipt.sourceBeliefID.rawValue,
                      propositionID
                        == receipt.proposition.propositionID.rawValue,
                      status == AgentKnowledgeBeliefStance.accepted.rawValue
                else {
                    throw AgentSessionError.language(
                        .invalidState("CIV-41 source authority event")
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
        let communicationsByID = Dictionary(uniqueKeysWithValues:
            state.communications.map { ($0.communicationID, $0) }
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
                semanticAuthorityDigest: receipt.semanticAuthorityDigest,
                semanticContentDigest: receipt.semanticContentDigest,
                lexicalUses: receipt.lexicalUses,
                exposedAssociationIDs: receipt.exposedAssociationIDs,
                communicatedAtTick: receipt.communicatedAtTick
            )
            guard receipt.speakerID != receipt.recipientID,
                  !receipt.lexicalUses.isEmpty,
                  receipt.lexicalUses
                    == receipt.lexicalUses.sorted(by: { $0.role < $1.role }),
                  Set(receipt.lexicalUses.map(\.role)).count
                    == receipt.lexicalUses.count,
                  receipt.lexicalUses.allSatisfy({ lexicalUse in
                      state.pack.entry(for: lexicalUse.senseID)?.form
                        == lexicalUse.form
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
                      communication.semanticAuthority.digest
                        == receipt.semanticAuthorityDigest,
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
                      event.causes
                        == [receipt.sourceBeliefRevisionEventID],
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
                }
        }

        for association in state.lexicalAssociations {
            guard activeAgentIDs.contains(association.ownerID),
                  association.packID == state.pack.packID,
                  state.pack.entry(for: association.senseID)?.form
                    == association.form,
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
            let rebuiltContent = AgentLanguageSemanticContent(
                sourcePropositionID:
                    communication.semanticContent.sourcePropositionID,
                referent: communication.semanticContent.referent,
                senses: communication.semanticContent.senses
            )
            let expectedSemanticContent = try languageSemanticContent(
                for: communication.semanticAuthority.proposition
            )
            try validateSemanticAuthority(
                communication.semanticAuthority,
                communicatedAtTick: communication.communicatedAtTick
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
                semanticAuthorityDigest:
                    communication.semanticAuthority.digest,
                semanticContentDigest: communication.semanticContent.digest,
                lexicalUses: communication.lexicalUses,
                exposedAssociationIDs:
                    communication.exposedAssociationIDs,
                communicatedAtTick: communication.communicatedAtTick
            )
            guard rebuiltContent == communication.semanticContent,
                  expectedSemanticContent == communication.semanticContent,
                  communication.semanticAuthority.sourceBeliefID
                    == communication.sourceBeliefID,
                  communication.semanticAuthority.sourceOwnerID
                    == communication.speakerID,
                  communication.semanticAuthority.sourceBeliefRevisionEventID
                    == communication.sourceBeliefRevisionEventID,
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
                            && state.pack.entry(for: $0.senseID)?.form
                                == $0.form
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
            if let event = try retainedEvent(communication.communicationEventID) {
                guard event.kind == .languageSemanticCommunicated,
                      event.origin == .languageTransition,
                      event.actorID == communication.speakerID,
                      event.subjectID == communication.recipientID,
                      event.causes
                        == [communication.sourceBeliefRevisionEventID],
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
        + "\(communication.semanticAuthority.digest)|"
        + "\(communication.semanticContent.digest)|\(rendering)|"
        + communication.lexicalUses.map {
            "\($0.role.rawValue):\($0.senseID.rawValue):\($0.form)"
        }.joined(separator: ",")
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
    let fields = [
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
    return fields.joined(separator: "|")
}

private func languageSemanticAuthorityDigest(
    sourceBeliefID: AgentKnowledgeBeliefID,
    sourceOwnerID: AgentID,
    proposition: AgentKnowledgeProposition,
    stance: AgentKnowledgeBeliefStance,
    basisUnderstandingID: AgentKnowledgeUnderstandingID,
    beliefFormedAtTick: Int,
    beliefUpdatedAtTick: Int,
    beliefRevisionCount: Int,
    sourceBeliefRevisionEventID: AgentCausalEventID
) -> String {
    AgentLanguageDigest.make([
        "semantic-authority",
        sourceBeliefID.rawValue,
        sourceOwnerID.rawValue,
        proposition.propositionID.rawValue,
        proposition.subject.canonicalText,
        proposition.predicate.rawValue,
        proposition.value.canonicalText,
        stance.rawValue,
        basisUnderstandingID.rawValue,
        String(beliefFormedAtTick),
        String(beliefUpdatedAtTick),
        String(beliefRevisionCount),
        sourceBeliefRevisionEventID.rawValue,
    ].joined(separator: "|"))
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
    semanticAuthorityDigest: String,
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
        semanticAuthorityDigest,
        semanticContentDigest,
        lexicalUses.map {
            "\($0.role.rawValue):\($0.senseID.rawValue):\($0.form)"
        }.joined(separator: ","),
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
    [
        "exposure-receipt",
        receipt.communicationID.rawValue,
        receipt.speakerID.rawValue,
        receipt.recipientID.rawValue,
        receipt.sourceBeliefID.rawValue,
        receipt.sourceBeliefRevisionEventID.rawValue,
        receipt.sourcePropositionID.rawValue,
        receipt.semanticAuthorityDigest,
        receipt.semanticContentDigest,
        receipt.lexicalUses.map {
            "\($0.role.rawValue):\($0.senseID.rawValue):\($0.form)"
        }.joined(separator: ","),
        receipt.exposedAssociationIDs.map(\.rawValue).joined(separator: ","),
        String(receipt.communicatedAtTick),
        receipt.communicationEventID.rawValue,
        receipt.digest,
    ].joined(separator: "|")
}
