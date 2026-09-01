extension AgentSimulationSession {
    public var knowledgeGraphEnabled: Bool {
        knowledgeGraphState?.enabled == true
    }

    public mutating func setKnowledgeGraphEnabled(
        _ enabled: Bool,
        configuration: AgentKnowledgeConfiguration = .live
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.knowledge(.causalLedgerRequired)
        }
        if enabled, !socialEnabled {
            throw AgentSessionError.knowledge(.socialRequired)
        }
        if knowledgeGraphState?.enabled == enabled {
            if enabled, knowledgeGraphState?.configuration != configuration {
                throw AgentSessionError.knowledge(
                    .invalidState("configuration cannot change while enabled")
                )
            }
            return
        }
        var candidate = self
        try candidate.prevalidateCausalAppend(count: 1)
        var state = candidate.knowledgeGraphState
            ?? AgentKnowledgeGraphState(configuration: configuration)
        if state.configuration != configuration {
            throw AgentSessionError.knowledge(
                .invalidState("configuration cannot change after initialization")
            )
        }
        state.enabled = enabled
        let event = try candidate.requiredKnowledgeEvent(
            kind: .knowledgeGraphInitialized,
            actorID: nil,
            subjectID: nil,
            causes: [],
            recordID: "knowledge-graph",
            propositionID: nil,
            status: enabled ? "enabled" : "disabled",
            reason: "explicit feature transition",
            summary: "knowledge graph \(enabled ? "enabled" : "disabled")"
        )
        candidate.knowledgeGraphState = state
        try candidate.validateKnowledgeGraphStateIfEnabled()
        _ = event
        self = candidate
    }

    public func knowledgeSnapshot() -> AgentKnowledgeSnapshot {
        guard let state = knowledgeGraphState else {
            return AgentKnowledgeSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                propositions: [], evidence: [], claims: [], understandings: [],
                beliefs: [], revisions: [], disagreements: [],
                evictionCounts: AgentKnowledgeEvictionCounts(),
                digest: AgentKnowledgeDigest.make("knowledge:none")
            )
        }
        let propositions = state.propositions.sorted { $0.propositionID < $1.propositionID }
        let evidence = state.evidence.sorted { $0.evidenceID < $1.evidenceID }
        let claims = state.claims.sorted { $0.claimID < $1.claimID }
        let understandings = state.understandings.sorted {
            $0.understandingID < $1.understandingID
        }
        let beliefs = state.beliefs.sorted { $0.beliefID < $1.beliefID }
        let revisions = state.revisions.sorted {
            if $0.revisedAtTick != $1.revisedAtTick {
                return $0.revisedAtTick < $1.revisedAtTick
            }
            return $0.revisionID < $1.revisionID
        }
        let grouped = Dictionary(grouping: beliefs, by: \.questionKey)
        let disagreements: [AgentKnowledgeDisagreement] = grouped.keys.sorted().compactMap { key in
            let rows = (grouped[key] ?? []).sorted { $0.ownerID < $1.ownerID }
            let positions = Set(rows.map {
                "\($0.propositionID.rawValue)|\($0.stance.rawValue)"
            })
            guard rows.count > 1, positions.count > 1 else { return nil }
            return AgentKnowledgeDisagreement(
                questionKey: key,
                beliefIDs: rows.map(\.beliefID),
                ownerIDs: rows.map(\.ownerID),
                propositionIDs: rows.map(\.propositionID),
                stances: rows.map(\.stance)
            )
        }
        let canonical = [
            "enabled=\(state.enabled ? 1 : 0)",
            propositions.map {
                "p|\($0.propositionID.rawValue)|\($0.questionKey)|\($0.value.canonicalText)"
            }.joined(separator: ";"),
            evidence.map {
                "e|\($0.evidenceID.rawValue)|\($0.observerID.rawValue)|\($0.propositionID.rawValue)|\($0.authority.rawValue)|\($0.authorityEventID.rawValue)|\($0.acquisitionEventID.rawValue)"
            }.joined(separator: ";"),
            claims.map {
                "c|\($0.claimID.rawValue)|\($0.sourceAgentID.rawValue)|\($0.recipientID.rawValue)|\($0.propositionID.rawValue)|\($0.sourceEvidenceID.rawValue)|\($0.receivedEventID.rawValue)"
            }.joined(separator: ";"),
            understandings.map {
                "u|\($0.understandingID.rawValue)|\($0.ownerID.rawValue)|\($0.propositionID.rawValue)|\($0.basis.canonicalText)|\($0.interpretation.rawValue)|\($0.formedEventID.rawValue)"
            }.joined(separator: ";"),
            beliefs.map {
                "b|\($0.beliefID.rawValue)|\($0.ownerID.rawValue)|\($0.questionKey)|\($0.propositionID.rawValue)|\($0.stance.rawValue)|\($0.basisUnderstandingID.rawValue)|\($0.revisionCount)|\($0.lastRevisionEventID.rawValue)"
            }.joined(separator: ";"),
            revisions.map {
                "r|\($0.revisionID.rawValue)|\($0.beliefID.rawValue)|\($0.previousPropositionID?.rawValue ?? "none")|\($0.propositionID.rawValue)|\($0.triggerUnderstandingID.rawValue)|\($0.revisionEventID.rawValue)"
            }.joined(separator: ";"),
            "evicted=\(state.evictionCounts.propositions),\(state.evictionCounts.evidence),\(state.evictionCounts.claims),\(state.evictionCounts.understandings),\(state.evictionCounts.revisions)",
        ].joined(separator: "|")
        return AgentKnowledgeSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            propositions: propositions,
            evidence: evidence,
            claims: claims,
            understandings: understandings,
            beliefs: beliefs,
            revisions: revisions,
            disagreements: disagreements,
            evictionCounts: state.evictionCounts,
            digest: AgentKnowledgeDigest.make(canonical)
        )
    }

    public func knowledgeSummary() -> AgentKnowledgeSummary {
        let snapshot = knowledgeSnapshot()
        return AgentKnowledgeSummary(
            enabled: snapshot.enabled,
            propositionCount: snapshot.propositions.count,
            directEvidenceCount: snapshot.evidence.count,
            sourceClaimCount: snapshot.claims.count,
            understandingCount: snapshot.understandings.count,
            currentBeliefCount: snapshot.beliefs.count,
            disagreementCount: snapshot.disagreements.count,
            revisionCount: snapshot.revisions.count,
            evictionCounts: snapshot.evictionCounts,
            digest: snapshot.digest
        )
    }

    mutating func recordKnowledgeDirectResourceObservation(
        observerID: AgentID,
        position: AgentPosition,
        resource: AgentResourceKind?,
        fingerprint: Int?,
        authority: AgentKnowledgeEvidenceAuthority,
        authorityEventID: AgentCausalEventID,
        interpretation: AgentKnowledgeInterpretation = .directlyObserved
    ) throws {
        guard var state = knowledgeGraphState, state.enabled else { return }
        guard statesById[observerID.rawValue] != nil else {
            throw AgentSessionError.knowledge(.unknownAgent(observerID.rawValue))
        }
        let proposition = try knowledgeResourceProposition(
            position: position, resource: resource, fingerprint: fingerprint
        )
        let evidenceID = AgentKnowledgeEvidenceID(
            rawValue: "evidence-" + AgentKnowledgeDigest.make(
                "\(observerID.rawValue)|\(proposition.propositionID.rawValue)|\(authorityEventID.rawValue)"
            )
        )!
        if state.evidence.contains(where: { $0.evidenceID == evidenceID }) { return }
        insertKnowledgeProposition(proposition, into: &state)
        let evidenceEvent = try requiredKnowledgeEvent(
            kind: .knowledgeEvidenceAcquired,
            actorID: observerID,
            subjectID: observerID,
            causes: [authorityEventID],
            recordID: evidenceID.rawValue,
            propositionID: proposition.propositionID,
            status: authority.rawValue,
            reason: "validated direct evidence",
            summary: "knowledge evidence acquired owner=\(observerID.rawValue)"
        )
        state.evidence.append(AgentKnowledgeEvidence(
            evidenceID: evidenceID,
            observerID: observerID,
            propositionID: proposition.propositionID,
            authority: authority,
            authorityEventID: authorityEventID,
            acquisitionEventID: evidenceEvent.eventID,
            acquiredAtTick: tick
        ))
        let basis = AgentKnowledgeUnderstandingBasis.evidence(evidenceID)
        let understanding = try formKnowledgeUnderstanding(
            ownerID: observerID,
            proposition: proposition,
            basis: basis,
            interpretation: interpretation,
            cause: evidenceEvent.eventID,
            state: &state
        )
        try reviseKnowledgeBelief(
            ownerID: observerID,
            proposition: proposition,
            stance: .accepted,
            understanding: understanding,
            state: &state
        )
        try compactKnowledgeState(&state)
        try validateKnowledgeGraphState(state)
        knowledgeGraphState = state
    }

    mutating func recordKnowledgeSourceClaim(
        message: AgentSocialMessage
    ) throws {
        guard var state = knowledgeGraphState, state.enabled else { return }
        guard statesById[message.senderID.rawValue] != nil,
              statesById[message.recipientID.rawValue] != nil else {
            throw AgentSessionError.knowledge(.unknownAgent(message.recipientID.rawValue))
        }
        guard let sourceEvidence = state.evidence.first(where: {
            $0.observerID == message.senderID
                && $0.authorityEventID == message.fact.directObservationEventID
        }), let proposition = state.propositions.first(where: {
            $0.propositionID == sourceEvidence.propositionID
        }) else {
            throw AgentSessionError.knowledge(
                .missingProvenance(message.fact.directObservationEventID.rawValue)
            )
        }
        let claimID = AgentKnowledgeClaimID(
            rawValue: "claim-" + AgentKnowledgeDigest.make(
                "\(message.recipientID.rawValue)|\(message.messageID.rawValue)"
            )
        )!
        if state.claims.contains(where: { $0.claimID == claimID }) { return }
        let claimEvent = try requiredKnowledgeEvent(
            kind: .knowledgeClaimReceived,
            actorID: message.senderID,
            subjectID: message.recipientID,
            causes: [message.receivedEventID],
            recordID: claimID.rawValue,
            propositionID: proposition.propositionID,
            status: "attributedSourceClaim",
            reason: message.messageID.rawValue,
            summary: "knowledge claim received \(message.senderID.rawValue)>\(message.recipientID.rawValue)"
        )
        state.claims.append(AgentKnowledgeSourceClaim(
            claimID: claimID,
            propositionID: proposition.propositionID,
            sourceAgentID: message.senderID,
            recipientID: message.recipientID,
            sourceEvidenceID: sourceEvidence.evidenceID,
            socialMessageID: message.messageID,
            sentEventID: message.sentEventID,
            receivedEventID: message.receivedEventID,
            acquisitionEventID: claimEvent.eventID,
            receivedAtTick: tick
        ))
        let understanding = try formKnowledgeUnderstanding(
            ownerID: message.recipientID,
            proposition: proposition,
            basis: .sourceClaim(claimID),
            interpretation: .acceptedAsAsserted,
            cause: claimEvent.eventID,
            state: &state
        )
        try reviseKnowledgeBelief(
            ownerID: message.recipientID,
            proposition: proposition,
            stance: .accepted,
            understanding: understanding,
            state: &state
        )
        try compactKnowledgeState(&state)
        try validateKnowledgeGraphState(state)
        knowledgeGraphState = state
    }

    private func knowledgeResourceProposition(
        position: AgentPosition,
        resource: AgentResourceKind?,
        fingerprint: Int?
    ) throws -> AgentKnowledgeProposition {
        let subject = try AgentKnowledgeEntity(
            kind: .worldCell,
            key: "cell:\(position.x),\(position.y),\(position.z)"
        )
        let predicate = AgentKnowledgePredicate(rawValue: "world.resource.presence")!
        let value: AgentKnowledgeValue = resource.map {
            .resource(kind: $0, fingerprint: fingerprint)
        } ?? .absent
        return AgentKnowledgeProposition(
            subject: subject, predicate: predicate, value: value
        )
    }

    private func insertKnowledgeProposition(
        _ proposition: AgentKnowledgeProposition,
        into state: inout AgentKnowledgeGraphState
    ) {
        guard !state.propositions.contains(where: {
            $0.propositionID == proposition.propositionID
        }) else { return }
        state.propositions.append(proposition)
    }

    private mutating func formKnowledgeUnderstanding(
        ownerID: AgentID,
        proposition: AgentKnowledgeProposition,
        basis: AgentKnowledgeUnderstandingBasis,
        interpretation: AgentKnowledgeInterpretation,
        cause: AgentCausalEventID,
        state: inout AgentKnowledgeGraphState
    ) throws -> AgentKnowledgeUnderstanding {
        let understandingID = AgentKnowledgeUnderstandingID(
            rawValue: "understanding-" + AgentKnowledgeDigest.make(
                "\(ownerID.rawValue)|\(proposition.propositionID.rawValue)|\(basis.canonicalText)"
            )
        )!
        if let existing = state.understandings.first(where: {
            $0.understandingID == understandingID
        }) { return existing }
        let event = try requiredKnowledgeEvent(
            kind: .knowledgeUnderstandingFormed,
            actorID: ownerID,
            subjectID: ownerID,
            causes: [cause],
            recordID: understandingID.rawValue,
            propositionID: proposition.propositionID,
            status: interpretation.rawValue,
            reason: basis.canonicalText,
            summary: "knowledge understanding formed owner=\(ownerID.rawValue)"
        )
        let understanding = AgentKnowledgeUnderstanding(
            understandingID: understandingID,
            ownerID: ownerID,
            propositionID: proposition.propositionID,
            basis: basis,
            interpretation: interpretation,
            formedAtTick: tick,
            formedEventID: event.eventID
        )
        state.understandings.append(understanding)
        return understanding
    }

    private mutating func reviseKnowledgeBelief(
        ownerID: AgentID,
        proposition: AgentKnowledgeProposition,
        stance: AgentKnowledgeBeliefStance,
        understanding: AgentKnowledgeUnderstanding,
        state: inout AgentKnowledgeGraphState
    ) throws {
        let beliefID = AgentKnowledgeBeliefID(
            rawValue: "belief-" + AgentKnowledgeDigest.make(
                "\(ownerID.rawValue)|\(proposition.questionKey)"
            )
        )!
        let existingIndex = state.beliefs.firstIndex { $0.beliefID == beliefID }
        let previous = existingIndex.map { state.beliefs[$0] }
        if previous?.propositionID == proposition.propositionID,
           previous?.stance == stance,
           previous?.basisUnderstandingID == understanding.understandingID {
            return
        }
        let event = try requiredKnowledgeEvent(
            kind: .knowledgeBeliefRevised,
            actorID: ownerID,
            subjectID: ownerID,
            causes: [understanding.formedEventID],
            recordID: beliefID.rawValue,
            propositionID: proposition.propositionID,
            status: stance.rawValue,
            reason: previous == nil ? "initial stance" : "newer acquired understanding",
            summary: "knowledge belief revised owner=\(ownerID.rawValue)"
        )
        let nextRevisionCount = (previous?.revisionCount ?? 0) + 1
        if let existingIndex {
            state.beliefs[existingIndex].propositionID = proposition.propositionID
            state.beliefs[existingIndex].stance = stance
            state.beliefs[existingIndex].basisUnderstandingID = understanding.understandingID
            state.beliefs[existingIndex].updatedAtTick = tick
            state.beliefs[existingIndex].revisionCount = nextRevisionCount
            state.beliefs[existingIndex].lastRevisionEventID = event.eventID
        } else {
            state.beliefs.append(AgentKnowledgeBelief(
                beliefID: beliefID,
                ownerID: ownerID,
                questionKey: proposition.questionKey,
                propositionID: proposition.propositionID,
                stance: stance,
                basisUnderstandingID: understanding.understandingID,
                formedAtTick: tick,
                updatedAtTick: tick,
                revisionCount: nextRevisionCount,
                lastRevisionEventID: event.eventID
            ))
        }
        state.revisions.append(AgentKnowledgeBeliefRevision(
            revisionID: AgentKnowledgeRevisionID(
                rawValue: "revision-" + AgentKnowledgeDigest.make(
                    "\(beliefID.rawValue)|\(event.eventID.rawValue)"
                )
            )!,
            beliefID: beliefID,
            ownerID: ownerID,
            questionKey: proposition.questionKey,
            previousPropositionID: previous?.propositionID,
            previousStance: previous?.stance,
            propositionID: proposition.propositionID,
            stance: stance,
            triggerUnderstandingID: understanding.understandingID,
            revisedAtTick: tick,
            revisionEventID: event.eventID
        ))
    }

    private mutating func requiredKnowledgeEvent(
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
            origin: .knowledgeTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: .knowledge(
                recordID: recordID,
                propositionID: propositionID?.rawValue,
                status: status,
                reason: reason
            ),
            summary: summary
        ) else {
            throw AgentSessionError.knowledge(.causalLedgerRequired)
        }
        return event
    }

    private mutating func compactKnowledgeState(
        _ state: inout AgentKnowledgeGraphState
    ) throws {
        let configuration = state.configuration
        let revisionIndices = try knowledgeEvictionIndices(
            records: state.revisions,
            maximumGlobal: configuration.maximumRevisions,
            maximumPerAgent: configuration.maximumRevisionsPerAgent,
            owner: \.ownerID,
            pinned: { _ in false },
            sortsBefore: {
                if $0.revisedAtTick != $1.revisedAtTick {
                    return $0.revisedAtTick < $1.revisedAtTick
                }
                return $0.revisionID < $1.revisionID
            },
            label: "revisions"
        )
        removeKnowledgeRecords(
            at: revisionIndices, from: &state.revisions,
            counter: &state.evictionCounts.revisions
        )

        let currentUnderstandingIDs = Set(state.beliefs.map(\.basisUnderstandingID))
        let understandingIndices = try knowledgeEvictionIndices(
            records: state.understandings,
            maximumGlobal: configuration.maximumUnderstandings,
            maximumPerAgent: configuration.maximumUnderstandingsPerAgent,
            owner: \.ownerID,
            pinned: { currentUnderstandingIDs.contains($0.understandingID) },
            sortsBefore: {
                if $0.formedAtTick != $1.formedAtTick {
                    return $0.formedAtTick < $1.formedAtTick
                }
                return $0.understandingID < $1.understandingID
            },
            label: "understandings"
        )
        removeKnowledgeRecords(
            at: understandingIndices, from: &state.understandings,
            counter: &state.evictionCounts.understandings
        )

        let retainedClaimIDs = Set(state.understandings.compactMap {
            if case let .sourceClaim(id) = $0.basis { return id }
            return nil
        })
        let claimIndices = try knowledgeEvictionIndices(
            records: state.claims,
            maximumGlobal: configuration.maximumClaims,
            maximumPerAgent: configuration.maximumClaimsPerAgent,
            owner: \.recipientID,
            pinned: { retainedClaimIDs.contains($0.claimID) },
            sortsBefore: {
                if $0.receivedAtTick != $1.receivedAtTick {
                    return $0.receivedAtTick < $1.receivedAtTick
                }
                return $0.claimID < $1.claimID
            },
            label: "claims"
        )
        removeKnowledgeRecords(
            at: claimIndices, from: &state.claims,
            counter: &state.evictionCounts.claims
        )

        var retainedEvidenceIDs = Set(state.understandings.compactMap {
            if case let .evidence(id) = $0.basis { return id }
            return nil
        })
        retainedEvidenceIDs.formUnion(state.claims.map(\.sourceEvidenceID))
        let activeFactEvents = Set(
            socialFacts.filter { !$0.isExpired(at: tick) }
                .map(\.directObservationEventID)
        )
        retainedEvidenceIDs.formUnion(state.evidence.compactMap {
            activeFactEvents.contains($0.authorityEventID) ? $0.evidenceID : nil
        })
        let evidenceIndices = try knowledgeEvictionIndices(
            records: state.evidence,
            maximumGlobal: configuration.maximumEvidence,
            maximumPerAgent: configuration.maximumEvidencePerAgent,
            owner: \.observerID,
            pinned: { retainedEvidenceIDs.contains($0.evidenceID) },
            sortsBefore: {
                if $0.acquiredAtTick != $1.acquiredAtTick {
                    return $0.acquiredAtTick < $1.acquiredAtTick
                }
                return $0.evidenceID < $1.evidenceID
            },
            label: "evidence"
        )
        removeKnowledgeRecords(
            at: evidenceIndices, from: &state.evidence,
            counter: &state.evictionCounts.evidence
        )

        guard state.beliefs.count <= configuration.maximumBeliefs else {
            throw AgentSessionError.knowledge(.capacityReached("beliefs"))
        }
        for ownerID in Set(state.beliefs.map(\.ownerID)) where
            state.beliefs.filter({ $0.ownerID == ownerID }).count
                > configuration.maximumBeliefsPerAgent {
            throw AgentSessionError.knowledge(
                .capacityReached("beliefs for \(ownerID.rawValue)")
            )
        }

        var retainedPropositionIDs = Set(state.evidence.map(\.propositionID))
        retainedPropositionIDs.formUnion(state.claims.map(\.propositionID))
        retainedPropositionIDs.formUnion(state.understandings.map(\.propositionID))
        retainedPropositionIDs.formUnion(state.beliefs.map(\.propositionID))
        retainedPropositionIDs.formUnion(state.revisions.flatMap {
            [$0.propositionID] + ($0.previousPropositionID.map { [$0] } ?? [])
        })
        if state.propositions.count > configuration.maximumPropositions {
            let removable = state.propositions.indices.filter {
                !retainedPropositionIDs.contains(state.propositions[$0].propositionID)
            }.sorted {
                state.propositions[$0].propositionID
                    < state.propositions[$1].propositionID
            }
            let excess = state.propositions.count - configuration.maximumPropositions
            guard removable.count >= excess else {
                throw AgentSessionError.knowledge(.capacityReached("propositions"))
            }
            removeKnowledgeRecords(
                at: Set(removable.prefix(excess)), from: &state.propositions,
                counter: &state.evictionCounts.propositions
            )
        }
    }

    private func knowledgeEvictionIndices<Record>(
        records: [Record],
        maximumGlobal: Int,
        maximumPerAgent: Int,
        owner: KeyPath<Record, AgentID>,
        pinned: (Record) -> Bool,
        sortsBefore: (Record, Record) -> Bool,
        label: String
    ) throws -> Set<Int> {
        var selected = Set<Int>()
        let owners = Set(records.map { $0[keyPath: owner] }).sorted()
        for ownerID in owners {
            let indices = records.indices.filter {
                records[$0][keyPath: owner] == ownerID
            }.sorted { sortsBefore(records[$0], records[$1]) }
            let excess = max(0, indices.count - maximumPerAgent)
            let removable = indices.filter { !pinned(records[$0]) }
            guard removable.count >= excess else {
                throw AgentSessionError.knowledge(
                    .capacityReached("\(label) for \(ownerID.rawValue)")
                )
            }
            selected.formUnion(removable.prefix(excess))
        }
        let globalExcess = max(0, records.count - selected.count - maximumGlobal)
        let remaining = records.indices.filter {
            !selected.contains($0) && !pinned(records[$0])
        }.sorted { sortsBefore(records[$0], records[$1]) }
        guard remaining.count >= globalExcess else {
            throw AgentSessionError.knowledge(.capacityReached(label))
        }
        selected.formUnion(remaining.prefix(globalExcess))
        return selected
    }

    private func removeKnowledgeRecords<Record>(
        at indices: Set<Int>,
        from records: inout [Record],
        counter: inout Int
    ) {
        for index in indices.sorted(by: >) { records.remove(at: index) }
        counter += indices.count
    }

    func validateKnowledgeGraphStateIfEnabled() throws {
        guard let state = knowledgeGraphState else { return }
        try validateKnowledgeGraphState(state)
    }

    func validateKnowledgeGraphState(
        _ state: AgentKnowledgeGraphState
    ) throws {
        let configuration = state.configuration
        do {
            _ = try AgentKnowledgeConfiguration(
                maximumPropositions: configuration.maximumPropositions,
                maximumEvidence: configuration.maximumEvidence,
                maximumClaims: configuration.maximumClaims,
                maximumUnderstandings: configuration.maximumUnderstandings,
                maximumBeliefs: configuration.maximumBeliefs,
                maximumRevisions: configuration.maximumRevisions,
                maximumEvidencePerAgent: configuration.maximumEvidencePerAgent,
                maximumClaimsPerAgent: configuration.maximumClaimsPerAgent,
                maximumUnderstandingsPerAgent: configuration.maximumUnderstandingsPerAgent,
                maximumBeliefsPerAgent: configuration.maximumBeliefsPerAgent,
                maximumRevisionsPerAgent: configuration.maximumRevisionsPerAgent
            )
        } catch {
            throw AgentSessionError.knowledge(.invalidState("configuration"))
        }
        func unique<T: Hashable>(_ values: [T]) -> Bool {
            Set(values).count == values.count
        }
        guard unique(state.propositions.map(\.propositionID)),
              unique(state.evidence.map(\.evidenceID)),
              unique(state.claims.map(\.claimID)),
              unique(state.understandings.map(\.understandingID)),
              unique(state.beliefs.map(\.beliefID)),
              unique(state.revisions.map(\.revisionID)),
              unique(state.beliefs.map {
                  "\($0.ownerID.rawValue)|\($0.questionKey)"
              }) else {
            throw AgentSessionError.knowledge(.invalidState("duplicate identity"))
        }
        let propositionByID = Dictionary(uniqueKeysWithValues:
            state.propositions.map { ($0.propositionID, $0) }
        )
        let evidenceByID = Dictionary(uniqueKeysWithValues:
            state.evidence.map { ($0.evidenceID, $0) }
        )
        let claimByID = Dictionary(uniqueKeysWithValues:
            state.claims.map { ($0.claimID, $0) }
        )
        let understandingByID = Dictionary(uniqueKeysWithValues:
            state.understandings.map { ($0.understandingID, $0) }
        )
        let retainedEventByID = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        func retainedCausalEvent(
            _ eventID: AgentCausalEventID
        ) throws -> AgentCausalEvent? {
            guard eventID.simulationID == simulationID,
                  eventID.sequence.rawValue <= causalLedger.latestSequence else {
                throw AgentSessionError.knowledge(
                    .invalidState("cross-simulation provenance")
                )
            }
            if let event = retainedEventByID[eventID] { return event }
            guard causalLedger.droppedEventCount > 0,
                  eventID.sequence.rawValue <= causalLedger.droppedEventCount else {
                throw AgentSessionError.knowledge(
                    .invalidState("missing causal provenance")
                )
            }
            return nil
        }
        func retainedKnowledgeEventMatches(
            _ eventID: AgentCausalEventID,
            kind: AgentCausalEventKind,
            ownerID: AgentID,
            recordID: String,
            propositionID: AgentKnowledgePropositionID
        ) throws -> Bool {
            guard let event = try retainedCausalEvent(eventID) else { return true }
            guard event.kind == kind,
                  event.origin == .knowledgeTransition,
                  event.actorID == ownerID,
                  event.subjectID == ownerID,
                  case let .knowledge(payloadRecordID, payloadPropositionID, _, _)
                    = event.payload else { return false }
            return payloadRecordID == recordID
                && payloadPropositionID == propositionID.rawValue
        }
        let allEventIDs = state.evidence.flatMap {
            [$0.authorityEventID, $0.acquisitionEventID]
        } + state.claims.flatMap {
            [$0.sentEventID, $0.receivedEventID, $0.acquisitionEventID]
        } + state.understandings.map(\.formedEventID)
            + state.beliefs.map(\.lastRevisionEventID)
            + state.revisions.map(\.revisionEventID)
        guard allEventIDs.allSatisfy({
            $0.simulationID == simulationID
                && $0.sequence.rawValue <= causalLedger.latestSequence
        }) else {
            throw AgentSessionError.knowledge(.invalidState("cross-simulation provenance"))
        }
        guard state.propositions.allSatisfy({ proposition in
            AgentKnowledgeProposition(
                subject: proposition.subject,
                predicate: proposition.predicate,
                value: proposition.value
            ) == proposition
        }), try state.evidence.allSatisfy({ record throws -> Bool in
            guard propositionByID[record.propositionID] != nil,
                  record.acquiredAtTick >= 0, record.acquiredAtTick <= tick,
                  record.authorityEventID.sequence
                    < record.acquisitionEventID.sequence,
                  try retainedKnowledgeEventMatches(
                    record.acquisitionEventID,
                    kind: .knowledgeEvidenceAcquired,
                    ownerID: record.observerID,
                    recordID: record.evidenceID.rawValue,
                    propositionID: record.propositionID
                  ) else { return false }
            let authorityEvent = try retainedCausalEvent(record.authorityEventID)
            guard let authorityEvent else { return true }
            switch record.authority {
            case .validatedWorldObservation:
                return authorityEvent.kind == .resourceFactGrounded
                    && authorityEvent.actorID == record.observerID
            case .validatedSocialVerification:
                return authorityEvent.kind == .socialVerification
                    && authorityEvent.actorID == record.observerID
            case .canonicalCivilizationState:
                return authorityEvent.origin != .knowledgeTransition
            }
        }), try state.claims.allSatisfy({ record throws -> Bool in
            guard propositionByID[record.propositionID] != nil,
                  let sourceEvidence = evidenceByID[record.sourceEvidenceID],
                  sourceEvidence.propositionID == record.propositionID,
                  sourceEvidence.observerID == record.sourceAgentID,
                  record.receivedAtTick >= 0, record.receivedAtTick <= tick,
                  sourceEvidence.acquisitionEventID.sequence
                    < record.sentEventID.sequence,
                  record.sentEventID.sequence < record.receivedEventID.sequence,
                  record.receivedEventID.sequence
                    < record.acquisitionEventID.sequence else { return false }
            let socialEvents: [(AgentCausalEventID, AgentCausalEventKind, String)] = [
                (record.sentEventID, .socialMessageSent, "sent"),
                (record.receivedEventID, .socialMessageReceived, "received"),
            ]
            for (eventID, kind, status) in socialEvents {
                let event = try retainedCausalEvent(eventID)
                if let event {
                    guard event.kind == kind,
                          event.actorID == record.sourceAgentID,
                          event.subjectID == record.recipientID,
                          case let .socialMessage(messageID, _, eventStatus)
                            = event.payload,
                          messageID == record.socialMessageID.rawValue,
                          eventStatus == status else { return false }
                }
            }
            let acquisition = try retainedCausalEvent(record.acquisitionEventID)
            guard let acquisition else { return true }
            guard acquisition.kind == .knowledgeClaimReceived,
                  acquisition.origin == .knowledgeTransition,
                  acquisition.actorID == record.sourceAgentID,
                  acquisition.subjectID == record.recipientID,
                  case let .knowledge(recordID, propositionID, _, _)
                    = acquisition.payload else { return false }
            return recordID == record.claimID.rawValue
                && propositionID == record.propositionID.rawValue
        }), try state.understandings.allSatisfy({ record throws -> Bool in
            guard propositionByID[record.propositionID] != nil,
                  record.formedAtTick >= 0, record.formedAtTick <= tick else {
                return false
            }
            let basisEventID: AgentCausalEventID
            switch record.basis {
            case let .evidence(id):
                guard let evidence = evidenceByID[id],
                      evidence.propositionID == record.propositionID else {
                    return false
                }
                basisEventID = evidence.acquisitionEventID
            case let .sourceClaim(id):
                guard let claim = claimByID[id],
                      claim.propositionID == record.propositionID else {
                    return false
                }
                basisEventID = claim.acquisitionEventID
            }
            guard basisEventID.sequence < record.formedEventID.sequence else {
                return false
            }
            return try retainedKnowledgeEventMatches(
                record.formedEventID,
                kind: .knowledgeUnderstandingFormed,
                ownerID: record.ownerID,
                recordID: record.understandingID.rawValue,
                propositionID: record.propositionID
            )
        }), try state.beliefs.allSatisfy({ record throws -> Bool in
            guard let proposition = propositionByID[record.propositionID],
                  let understanding = understandingByID[record.basisUnderstandingID]
            else { return false }
            guard proposition.questionKey == record.questionKey
                && understanding.ownerID == record.ownerID
                && understanding.propositionID == record.propositionID
                && record.formedAtTick >= 0
                && record.formedAtTick <= record.updatedAtTick
                && record.updatedAtTick <= tick
                && record.revisionCount >= 1
                && understanding.formedEventID.sequence
                    < record.lastRevisionEventID.sequence else { return false }
            return try retainedKnowledgeEventMatches(
                record.lastRevisionEventID,
                kind: .knowledgeBeliefRevised,
                ownerID: record.ownerID,
                recordID: record.beliefID.rawValue,
                propositionID: record.propositionID
            )
        }), try state.revisions.allSatisfy({ record throws -> Bool in
            guard let belief = state.beliefs.first(where: {
                $0.beliefID == record.beliefID
            }), let understanding = understandingByID[
                record.triggerUnderstandingID
            ] else { return false }
            guard propositionByID[record.propositionID] != nil
                && (record.previousPropositionID.map { previousID in
                    propositionByID[previousID] != nil
                } != false)
                && belief.ownerID == record.ownerID
                && belief.questionKey == record.questionKey
                && understanding.ownerID == record.ownerID
                && understanding.formedEventID.sequence
                    < record.revisionEventID.sequence
                && record.revisedAtTick >= 0
                && record.revisedAtTick <= tick else { return false }
            return try retainedKnowledgeEventMatches(
                record.revisionEventID,
                kind: .knowledgeBeliefRevised,
                ownerID: record.ownerID,
                recordID: record.beliefID.rawValue,
                propositionID: record.propositionID
            )
        }) else {
            throw AgentSessionError.knowledge(.invalidState("graph relationship"))
        }
        guard state.propositions.count <= configuration.maximumPropositions,
              state.evidence.count <= configuration.maximumEvidence,
              state.claims.count <= configuration.maximumClaims,
              state.understandings.count <= configuration.maximumUnderstandings,
              state.beliefs.count <= configuration.maximumBeliefs,
              state.revisions.count <= configuration.maximumRevisions,
              [
                  state.evictionCounts.propositions,
                  state.evictionCounts.evidence,
                  state.evictionCounts.claims,
                  state.evictionCounts.understandings,
                  state.evictionCounts.revisions,
              ].allSatisfy({ $0 >= 0 }) else {
            throw AgentSessionError.knowledge(.invalidState("global bound"))
        }
        let owners = Set(
            state.evidence.map(\.observerID)
                + state.claims.map(\.recipientID)
                + state.understandings.map(\.ownerID)
                + state.beliefs.map(\.ownerID)
                + state.revisions.map(\.ownerID)
        )
        for ownerID in owners {
            guard state.evidence.filter({ $0.observerID == ownerID }).count
                    <= configuration.maximumEvidencePerAgent,
                  state.claims.filter({ $0.recipientID == ownerID }).count
                    <= configuration.maximumClaimsPerAgent,
                  state.understandings.filter({ $0.ownerID == ownerID }).count
                    <= configuration.maximumUnderstandingsPerAgent,
                  state.beliefs.filter({ $0.ownerID == ownerID }).count
                    <= configuration.maximumBeliefsPerAgent,
                  state.revisions.filter({ $0.ownerID == ownerID }).count
                    <= configuration.maximumRevisionsPerAgent else {
                throw AgentSessionError.knowledge(
                    .invalidState("per-agent bound \(ownerID.rawValue)")
                )
            }
        }
    }
}
