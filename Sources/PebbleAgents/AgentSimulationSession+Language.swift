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
        let seedID = "language-seed-" + AgentLanguageDigest.make(
            "\(agentID.rawValue)|\(state.pack.packID.rawValue)|"
                + newEntries.map { $0.senseID.rawValue }.joined(separator: ",")
        )
        let event = try candidate.requiredLanguageEvent(
            kind: .languagePriorSeeded,
            actorID: agentID,
            subjectID: agentID,
            causes: [],
            recordID: seedID,
            propositionID: nil,
            status: "seededPrior",
            reason: state.pack.packID.rawValue,
            summary: "language prior seeded agent=\(agentID.rawValue) senses=\(newEntries.count)"
        )
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
                lastEventID: event.eventID
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
        let (belief, content) = try languageBeliefAndSemanticContent(
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
        let (sourceBelief, content) = try languageBeliefAndSemanticContent(
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
        let event = try candidate.requiredLanguageEvent(
            kind: .languageSemanticCommunicated,
            actorID: speakerID,
            subjectID: recipientID,
            causes: [sourceBelief.lastRevisionEventID],
            recordID: communicationID.rawValue,
            propositionID: propositionID,
            status: renderingMode.rawValue,
            reason: content.digest,
            summary: "semantic communication speaker=\(speakerID.rawValue) recipient=\(recipientID.rawValue) rendering=\(renderingMode.rawValue)"
        )
        var exposedAssociationIDs: [AgentLanguageAssociationID] = []
        var newlyLearnedSenseIDs: [AgentLanguageSenseID] = []
        for lexicalUse in lexicalUses {
            let associationID = languageAssociationID(
                ownerID: recipientID,
                packID: state.pack.packID,
                senseID: lexicalUse.senseID,
                form: lexicalUse.form
            )
            exposedAssociationIDs.append(associationID)
            if let index = state.lexicalAssociations.firstIndex(where: {
                $0.associationID == associationID
            }) {
                let wasKnown = state.lexicalAssociations[index].competence
                    == .known
                if state.lexicalAssociations[index].exposureCount
                    < state.configuration.exposuresRequiredForLearning {
                    state.lexicalAssociations[index].exposureCount += 1
                }
                state.lexicalAssociations[index].lastExposedAtTick = candidate.tick
                state.lexicalAssociations[index].lastEventID = event.eventID
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
                        lastEventID: event.eventID
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
            semanticContent: content,
            rendering: surface,
            lexicalUses: lexicalUses.sorted { $0.role < $1.role },
            exposedAssociationIDs: exposedAssociationIDs.sorted(),
            newlyLearnedSenseIDs: newlyLearnedSenseIDs.sorted(),
            communicatedAtTick: candidate.tick,
            communicationEventID: event.eventID
        )
        state.communications.append(communication)
        state.nextCommunicationOrdinal += 1
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
    ) throws -> (AgentKnowledgeBelief, AgentLanguageSemanticContent) {
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
        return (belief, try languageSemanticContent(for: proposition))
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
        guard knowledgeGraphState != nil else {
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
              state.evictedCommunicationCount >= 0,
              state.retiredLexicalAssociationCount >= 0,
              state.nextCommunicationOrdinal > 0,
              Set(state.lexicalAssociations.map(\.associationID)).count
                == state.lexicalAssociations.count,
              Set(state.communications.map(\.communicationID)).count
                == state.communications.count else {
            throw AgentSessionError.language(.invalidState("global bound or identity"))
        }
        let activeAgentIDs = Set(statesById.values.map(\.agentID))
        guard state.lexicalAssociations.allSatisfy({ association in
            activeAgentIDs.contains(association.ownerID)
                && association.packID == state.pack.packID
                && isValidLanguageText(association.form, maximum: 64)
                && association.exposureCount >= 0
                && association.exposureCount
                    <= state.configuration.exposuresRequiredForLearning
                && association.firstAcquiredAtTick >= 0
                && association.firstAcquiredAtTick
                    <= association.lastExposedAtTick
                && association.lastExposedAtTick <= tick
                && association.associationID == languageAssociationID(
                    ownerID: association.ownerID,
                    packID: association.packID,
                    senseID: association.senseID,
                    form: association.form
                )
                && (association.source == .seededPrior
                    ? association.competence == .known
                    : association.exposureCount > 0
                        && association.competence
                            == (association.exposureCount
                                >= state.configuration.exposuresRequiredForLearning
                                    ? .known : .acquiring))
        }) else {
            throw AgentSessionError.language(
                .invalidState("lexical association")
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
        for association in state.lexicalAssociations {
            if let event = try retainedEvent(association.lastEventID) {
                guard event.origin == .languageTransition,
                      event.kind == .languagePriorSeeded
                        || event.kind == .languageSemanticCommunicated,
                      event.actorID == association.ownerID
                        || event.subjectID == association.ownerID else {
                    throw AgentSessionError.language(
                        .invalidState("association event")
                    )
                }
            }
        }
        for communication in state.communications {
            let rebuiltContent = AgentLanguageSemanticContent(
                sourcePropositionID:
                    communication.semanticContent.sourcePropositionID,
                referent: communication.semanticContent.referent,
                senses: communication.semanticContent.senses
            )
            guard rebuiltContent == communication.semanticContent,
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
                  ) else {
                throw AgentSessionError.language(
                    .invalidState("semantic communication")
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
                      reason == communication.semanticContent.digest else {
                    throw AgentSessionError.language(
                        .invalidState("communication event")
                    )
                }
            }
            if let event = try retainedEvent(
                communication.sourceBeliefRevisionEventID
            ) {
                guard event.kind == .knowledgeBeliefRevised,
                      event.origin == .knowledgeTransition,
                      event.actorID == communication.speakerID,
                      case let .knowledge(
                        recordID, propositionID, _, _
                      ) = event.payload,
                      recordID == communication.sourceBeliefID.rawValue,
                      propositionID == communication.semanticContent
                        .sourcePropositionID.rawValue else {
                    throw AgentSessionError.language(
                        .invalidState("CIV-41 source authority")
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
    ]
    return fields.joined(separator: "|")
}
