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
        if !enabled, oralTransmissionState != nil {
            throw AgentSessionError.oral(.knowledgeRequired)
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
                beliefs: [], revisions: [], departedBeliefs: [],
                departedBeliefEvictionCount: 0,
                historicalBeliefAuthorities: [],
                historicalBeliefAuthorityBoundary: nil,
                historicalBeliefAuthorityEvictionCount: 0,
                disagreements: [],
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
        let departedBeliefs = (state.departedBeliefs ?? []).sorted {
            if $0.departedAtTick != $1.departedAtTick {
                return $0.departedAtTick < $1.departedAtTick
            }
            if $0.deathID != $1.deathID { return $0.deathID < $1.deathID }
            return $0.beliefID < $1.beliefID
        }
        let historicalAuthorities =
            (state.historicalBeliefAuthorities ?? []).sorted {
                $0.authorityID < $1.authorityID
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
        var canonicalRows = [
            "enabled=\(state.enabled ? 1 : 0)",
            propositions.map {
                "p|\($0.propositionID.rawValue)|\($0.questionKey)|\($0.value.canonicalText)"
            }.joined(separator: ";"),
            evidence.map {
                "e|\($0.evidenceID.rawValue)|\($0.observerID.rawValue)|\($0.propositionID.rawValue)|\($0.authority.rawValue)|\($0.authorityEventID.rawValue)|\($0.acquisitionEventID.rawValue)"
            }.joined(separator: ";"),
            claims.map {
                "c|\($0.claimID.rawValue)|\($0.sourceAgentID.rawValue)|\($0.recipientID.rawValue)|\($0.propositionID.rawValue)|\($0.sourceEvidenceID?.rawValue ?? "none")|\($0.socialMessageID?.rawValue ?? "none")|\($0.sourceBeliefAuthorityID?.rawValue ?? "none")|\($0.languageCommunicationID?.rawValue ?? "none")|\($0.oralTransmissionID?.rawValue ?? "none")|\($0.receivedEventID.rawValue)"
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
            departedBeliefs.map {
                "d|\($0.beliefID.rawValue)|\($0.ownerID.rawValue)|\($0.deathID.rawValue)|\($0.proposition.propositionID.rawValue)|\($0.stance.rawValue)|\($0.basisUnderstandingID.rawValue)|\($0.interpretation.rawValue)|\($0.basis.canonicalText)|\($0.revisionCount)|\($0.lastRevisionEventID.rawValue)|\($0.departedAtTick)|\($0.deathEventID.rawValue)"
            }.joined(separator: ";"),
            "departedEvicted=\(state.departedBeliefEvictionCount ?? 0)",
            "evicted=\(state.evictionCounts.propositions),\(state.evictionCounts.evidence),\(state.evictionCounts.claims),\(state.evictionCounts.understandings),\(state.evictionCounts.revisions)",
        ]
        if state.historicalBeliefAuthorities != nil {
            canonicalRows.append(historicalAuthorities.map {
                historicalBeliefAuthorityCanonicalText($0)
            }.joined(separator: ";"))
            canonicalRows.append(
                "historicalAuthorityBoundary="
                    + (state.historicalBeliefAuthorityBoundary.map {
                        "\($0.eventID.rawValue):\($0.digest)"
                    } ?? "none")
            )
            canonicalRows.append(
                "historicalAuthorityEvicted="
                    + String(
                        state.historicalBeliefAuthorityEvictionCount ?? 0
                    )
            )
        }
        let canonical = canonicalRows.joined(separator: "|")
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
            departedBeliefs: departedBeliefs,
            departedBeliefEvictionCount:
                state.departedBeliefEvictionCount ?? 0,
            historicalBeliefAuthorities: historicalAuthorities,
            historicalBeliefAuthorityBoundary:
                state.historicalBeliefAuthorityBoundary,
            historicalBeliefAuthorityEvictionCount:
                state.historicalBeliefAuthorityEvictionCount ?? 0,
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
            departedBeliefCount: snapshot.departedBeliefs.count,
            departedBeliefEvictionCount:
                snapshot.departedBeliefEvictionCount,
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
            sourceBeliefAuthorityID: nil,
            languageCommunicationID: nil,
            oralTransmissionID: nil,
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

    func insertKnowledgeProposition(
        _ proposition: AgentKnowledgeProposition,
        into state: inout AgentKnowledgeGraphState
    ) {
        guard !state.propositions.contains(where: {
            $0.propositionID == proposition.propositionID
        }) else { return }
        state.propositions.append(proposition)
    }

    mutating func formKnowledgeUnderstanding(
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

    mutating func reviseKnowledgeBelief(
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

    /// CIV-41 issues and owns the bounded historical epistemic authority used
    /// by other domains. The caller receives only the stable authority ID.
    mutating func retainKnowledgeHistoricalBeliefAuthority(
        belief: AgentKnowledgeBelief,
        proposition: AgentKnowledgeProposition
    ) throws -> AgentKnowledgeHistoricalBeliefAuthority {
        guard var state = knowledgeGraphState else {
            throw AgentSessionError.knowledge(.disabled)
        }
        guard belief.ownerID == statesById[belief.ownerID.rawValue]?.agentID,
              belief.propositionID == proposition.propositionID,
              belief.stance == .accepted,
              state.beliefs.contains(where: { $0 == belief }),
              state.propositions.contains(where: { $0 == proposition }) else {
            throw AgentSessionError.knowledge(
                .invalidState("historical authority source")
            )
        }
        let digest = knowledgeHistoricalBeliefAuthorityDigest(
            beliefID: belief.beliefID,
            ownerID: belief.ownerID,
            proposition: proposition,
            stance: belief.stance,
            basisUnderstandingID: belief.basisUnderstandingID,
            beliefFormedAtTick: belief.formedAtTick,
            beliefUpdatedAtTick: belief.updatedAtTick,
            beliefRevisionCount: belief.revisionCount,
            sourceBeliefRevisionEventID: belief.lastRevisionEventID
        )
        let authorityID = AgentKnowledgeHistoricalBeliefAuthorityID(
            rawValue: "historical-belief-authority-" + digest
        )!
        if let existing = (state.historicalBeliefAuthorities ?? []).first(
            where: { $0.authorityID == authorityID }
        ) {
            return existing
        }
        let authority = AgentKnowledgeHistoricalBeliefAuthority(
            authorityID: authorityID,
            beliefID: belief.beliefID,
            ownerID: belief.ownerID,
            proposition: proposition,
            stance: belief.stance,
            basisUnderstandingID: belief.basisUnderstandingID,
            beliefFormedAtTick: belief.formedAtTick,
            beliefUpdatedAtTick: belief.updatedAtTick,
            beliefRevisionCount: belief.revisionCount,
            sourceBeliefRevisionEventID: belief.lastRevisionEventID,
            digest: digest
        )
        var authorities = state.historicalBeliefAuthorities ?? []
        authorities.append(authority)
        var pinned = referencedKnowledgeHistoricalAuthorityIDs()
        pinned.insert(authorityID)
        let excess = max(
            0, authorities.count - state.configuration.maximumRevisions
        )
        if excess > 0 {
            let removable = authorities.indices.filter {
                !pinned.contains(authorities[$0].authorityID)
            }.sorted {
                let lhs = authorities[$0]
                let rhs = authorities[$1]
                if lhs.beliefUpdatedAtTick != rhs.beliefUpdatedAtTick {
                    return lhs.beliefUpdatedAtTick < rhs.beliefUpdatedAtTick
                }
                return lhs.authorityID < rhs.authorityID
            }
            guard removable.count >= excess else {
                throw AgentSessionError.knowledge(
                    .capacityReached("historical belief authorities")
                )
            }
            for index in removable.prefix(excess).sorted(by: >) {
                authorities.remove(at: index)
            }
        }
        state.historicalBeliefAuthorities = authorities
        state.historicalBeliefAuthorityEvictionCount =
            (state.historicalBeliefAuthorityEvictionCount ?? 0) + excess
        knowledgeGraphState = state
        try commitKnowledgeHistoricalAuthorityBoundary(
            causes: [belief.lastRevisionEventID]
        )
        return authority
    }

    func referencedKnowledgeHistoricalAuthorityIDs()
        -> Set<AgentKnowledgeHistoricalBeliefAuthorityID> {
        var result = Set((languageState?.communications ?? []).map {
            $0.semanticAuthority.authorityID
        })
        result.formUnion(
            (languageState?.exposureReceipts ?? []).map(\.semanticAuthorityID)
        )
        result.formUnion(
            knowledgeGraphState?.claims.compactMap(
                \.sourceBeliefAuthorityID
            ) ?? []
        )
        result.formUnion(
            oralTransmissionState?.transmissions.map(\.sourceAuthorityID) ?? []
        )
        for departed in knowledgeGraphState?.departedBeliefs ?? [] {
            if case let .oralSourceClaim(
                _, _, authorityID, _, _, _, _, _
            ) = departed.basis {
                result.insert(authorityID)
            }
        }
        return result
    }

    mutating func commitKnowledgeHistoricalAuthorityBoundary(
        causes: [AgentCausalEventID]
    ) throws {
        guard var state = knowledgeGraphState,
              state.historicalBeliefAuthorities != nil else { return }
        let authorities = state.historicalBeliefAuthorities ?? []
        guard !authorities.isEmpty else {
            state.historicalBeliefAuthorityBoundary = nil
            knowledgeGraphState = state
            return
        }
        let digest = knowledgeHistoricalAuthorityBoundaryDigest(authorities)
        var boundaryCauses = causes
        if let previous = state.historicalBeliefAuthorityBoundary?.eventID {
            boundaryCauses.append(previous)
        }
        let event = try requiredKnowledgeEvent(
            kind: .knowledgeGraphInitialized,
            actorID: nil,
            subjectID: nil,
            causes: Array(Set(boundaryCauses)).sorted(),
            recordID: "historical-belief-authorities",
            propositionID: nil,
            status: "retentionBoundary",
            reason: digest,
            summary: "knowledge historical belief authority boundary"
        )
        state = knowledgeGraphState ?? state
        state.historicalBeliefAuthorityBoundary =
            AgentKnowledgeHistoricalAuthorityBoundary(
                eventID: event.eventID,
                digest: digest
            )
        knowledgeGraphState = state
    }

    /// Composes CIV-41 with the existing mortality authority. The death event
    /// is the terminal causal boundary; CIV-41 neither detects nor finalizes
    /// death itself.
    mutating func terminateKnowledgeForFinalizedDeath(
        agentID: AgentID,
        deathID: AgentDeathID,
        deathEventID: AgentCausalEventID,
        at deathTick: Int
    ) throws {
        guard var state = knowledgeGraphState else { return }
        let propositionsByID = Dictionary(uniqueKeysWithValues:
            state.propositions.map { ($0.propositionID, $0) }
        )
        let understandingsByID = Dictionary(uniqueKeysWithValues:
            state.understandings.map { ($0.understandingID, $0) }
        )
        let evidenceByID = Dictionary(uniqueKeysWithValues:
            state.evidence.map { ($0.evidenceID, $0) }
        )
        let claimsByID = Dictionary(uniqueKeysWithValues:
            state.claims.map { ($0.claimID, $0) }
        )
        let currentBeliefs = state.beliefs.filter {
            $0.ownerID == agentID
        }.sorted { $0.beliefID < $1.beliefID }
        var departed = state.departedBeliefs ?? []
        for belief in currentBeliefs {
            guard let proposition = propositionsByID[belief.propositionID],
                  let understanding = understandingsByID[
                      belief.basisUnderstandingID
                  ], understanding.ownerID == agentID else {
                throw AgentSessionError.knowledge(.invalidState(
                    "terminal belief provenance \(belief.beliefID.rawValue)"
                ))
            }
            let historicalBasis: AgentKnowledgeDepartedBeliefBasis
            switch understanding.basis {
            case let .evidence(evidenceID):
                guard let evidence = evidenceByID[evidenceID],
                      evidence.observerID == agentID else {
                    throw AgentSessionError.knowledge(.invalidState(
                        "terminal direct evidence \(belief.beliefID.rawValue)"
                    ))
                }
                historicalBasis = .evidence(
                    evidenceID: evidence.evidenceID,
                    authority: evidence.authority,
                    authorityEventID: evidence.authorityEventID,
                    acquisitionEventID: evidence.acquisitionEventID
                )
            case let .sourceClaim(claimID):
                guard let claim = claimsByID[claimID],
                      claim.recipientID == agentID else {
                    throw AgentSessionError.knowledge(.invalidState(
                        "terminal source claim \(belief.beliefID.rawValue)"
                    ))
                }
                if let sourceEvidenceID = claim.sourceEvidenceID,
                   let socialMessageID = claim.socialMessageID,
                   let sourceEvidence = evidenceByID[sourceEvidenceID] {
                    historicalBasis = .sourceClaim(
                        claimID: claim.claimID,
                        sourceAgentID: claim.sourceAgentID,
                        sourceEvidenceID: sourceEvidenceID,
                        sourceEvidenceAuthority: sourceEvidence.authority,
                        sourceEvidenceAuthorityEventID:
                            sourceEvidence.authorityEventID,
                        sourceEvidenceAcquisitionEventID:
                            sourceEvidence.acquisitionEventID,
                        socialMessageID: socialMessageID,
                        sentEventID: claim.sentEventID,
                        receivedEventID: claim.receivedEventID,
                        acquisitionEventID: claim.acquisitionEventID
                    )
                } else if let sourceBeliefAuthorityID =
                            claim.sourceBeliefAuthorityID,
                          let languageCommunicationID =
                            claim.languageCommunicationID,
                          let oralTransmissionID = claim.oralTransmissionID {
                    historicalBasis = .oralSourceClaim(
                        claimID: claim.claimID,
                        sourceAgentID: claim.sourceAgentID,
                        sourceBeliefAuthorityID: sourceBeliefAuthorityID,
                        languageCommunicationID: languageCommunicationID,
                        oralTransmissionID: oralTransmissionID,
                        sentEventID: claim.sentEventID,
                        receivedEventID: claim.receivedEventID,
                        acquisitionEventID: claim.acquisitionEventID
                    )
                } else {
                    throw AgentSessionError.knowledge(.invalidState(
                        "terminal source claim route \(belief.beliefID.rawValue)"
                    ))
                }
            }
            guard !departed.contains(where: {
                $0.beliefID == belief.beliefID && $0.deathID == deathID
            }) else {
                throw AgentSessionError.knowledge(.invalidState(
                    "duplicate terminal belief \(belief.beliefID.rawValue)"
                ))
            }
            departed.append(AgentKnowledgeDepartedBelief(
                beliefID: belief.beliefID,
                ownerID: agentID,
                deathID: deathID,
                proposition: proposition,
                stance: belief.stance,
                basisUnderstandingID: belief.basisUnderstandingID,
                interpretation: understanding.interpretation,
                understandingFormedEventID: understanding.formedEventID,
                basis: historicalBasis,
                formedAtTick: belief.formedAtTick,
                updatedAtTick: belief.updatedAtTick,
                revisionCount: belief.revisionCount,
                lastRevisionEventID: belief.lastRevisionEventID,
                departedAtTick: deathTick,
                deathEventID: deathEventID
            ))
        }

        state.beliefs.removeAll { $0.ownerID == agentID }
        state.revisions.removeAll { $0.ownerID == agentID }
        state.understandings.removeAll { $0.ownerID == agentID }
        state.claims.removeAll { $0.recipientID == agentID }

        // A dead source's evidence remains only when a living understanding or
        // attributed claim still requires it. Its observer identity and
        // authority never change.
        var retainedEvidenceIDs = Set(state.claims.compactMap(\.sourceEvidenceID))
        retainedEvidenceIDs.formUnion(state.understandings.compactMap {
            if case let .evidence(id) = $0.basis { return id }
            return nil
        })
        let activeAgentIDs = Set(statesById.values.map(\.agentID))
        state.evidence.removeAll {
            !activeAgentIDs.contains($0.observerID)
                && !retainedEvidenceIDs.contains($0.evidenceID)
        }

        departed.sort {
            if $0.departedAtTick != $1.departedAtTick {
                return $0.departedAtTick < $1.departedAtTick
            }
            if $0.deathID != $1.deathID { return $0.deathID < $1.deathID }
            return $0.beliefID < $1.beliefID
        }
        let historicalExcess = max(
            0, departed.count - state.configuration.maximumDepartedBeliefs
        )
        let evictedDepartedBeliefs: [AgentKnowledgeDepartedBelief]
        if historicalExcess > 0 {
            evictedDepartedBeliefs = Array(departed.prefix(historicalExcess))
            departed.removeFirst(historicalExcess)
            state.departedBeliefEvictionCount =
                (state.departedBeliefEvictionCount ?? 0) + historicalExcess
        } else {
            evictedDepartedBeliefs = []
        }
        state.departedBeliefs = departed
        knowledgeGraphState = state
        try reconcileOralHistoryAfterDepartedBeliefEviction(
            evictedDepartedBeliefs,
            causeEventID: deathEventID
        )
        state = knowledgeGraphState ?? state
        try compactKnowledgeState(&state)
        try validateKnowledgeGraphState(state)
        knowledgeGraphState = state
    }

    mutating func requiredKnowledgeEvent(
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

    mutating func compactKnowledgeState(
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

        var currentUnderstandingIDs = Set(state.beliefs.map(\.basisUnderstandingID))
        currentUnderstandingIDs.formUnion(
            oralTransmissionState?.transmissions.map(
                \.recipientUnderstandingID
            ) ?? []
        )
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
        }).union(
            oralTransmissionState?.transmissions.map(\.recipientClaimID) ?? []
        )
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
        retainedEvidenceIDs.formUnion(state.claims.compactMap(\.sourceEvidenceID))
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
              unique((state.departedBeliefs ?? []).map(\.beliefID)),
              unique((state.historicalBeliefAuthorities ?? []).map(
                  \.authorityID
              )),
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
        let historicalAuthorities = state.historicalBeliefAuthorities ?? []
        let historicalAuthorityByID = Dictionary(uniqueKeysWithValues:
            historicalAuthorities.map { ($0.authorityID, $0) }
        )
        guard referencedKnowledgeHistoricalAuthorityIDs().isSubset(
                of: Set(historicalAuthorityByID.keys)
              ),
              historicalAuthorities.count <= configuration.maximumRevisions,
              (state.historicalBeliefAuthorityEvictionCount ?? 0) >= 0 else {
            throw AgentSessionError.knowledge(
                .invalidState("historical authority bound or reference")
            )
        }
        if historicalAuthorities.isEmpty {
            guard state.historicalBeliefAuthorityBoundary == nil else {
                throw AgentSessionError.knowledge(
                    .invalidState("empty historical authority boundary")
                )
            }
        } else {
            guard let boundary = state.historicalBeliefAuthorityBoundary,
                  boundary.digest
                    == knowledgeHistoricalAuthorityBoundaryDigest(
                        historicalAuthorities
                    ),
                  let event = retainedEventByID[boundary.eventID],
                  event.kind == .knowledgeGraphInitialized,
                  event.origin == .knowledgeTransition,
                  event.actorID == nil,
                  event.subjectID == nil,
                  case let .knowledge(
                    recordID, propositionID, status, reason
                  ) = event.payload,
                  recordID == "historical-belief-authorities",
                  propositionID == nil,
                  status == "retentionBoundary",
                  reason == boundary.digest else {
                throw AgentSessionError.knowledge(
                    .invalidState("historical authority boundary")
                )
            }
        }
        for authority in historicalAuthorities {
            let canonicalProposition = AgentKnowledgeProposition(
                subject: authority.proposition.subject,
                predicate: authority.proposition.predicate,
                value: authority.proposition.value
            )
            let canonicalBeliefID = AgentKnowledgeBeliefID(
                rawValue: "belief-" + AgentKnowledgeDigest.make(
                    "\(authority.ownerID.rawValue)|"
                        + authority.proposition.questionKey
                )
            )!
            let expectedDigest = knowledgeHistoricalBeliefAuthorityDigest(
                beliefID: authority.beliefID,
                ownerID: authority.ownerID,
                proposition: authority.proposition,
                stance: authority.stance,
                basisUnderstandingID: authority.basisUnderstandingID,
                beliefFormedAtTick: authority.beliefFormedAtTick,
                beliefUpdatedAtTick: authority.beliefUpdatedAtTick,
                beliefRevisionCount: authority.beliefRevisionCount,
                sourceBeliefRevisionEventID:
                    authority.sourceBeliefRevisionEventID
            )
            let expectedID = AgentKnowledgeHistoricalBeliefAuthorityID(
                rawValue: "historical-belief-authority-" + expectedDigest
            )!
            guard canonicalProposition == authority.proposition,
                  canonicalBeliefID == authority.beliefID,
                  expectedID == authority.authorityID,
                  expectedDigest == authority.digest,
                  authority.stance == .accepted,
                  authority.beliefFormedAtTick >= 0,
                  authority.beliefFormedAtTick
                    <= authority.beliefUpdatedAtTick,
                  authority.beliefUpdatedAtTick <= tick,
                  authority.beliefRevisionCount >= 1,
                  authority.sourceBeliefRevisionEventID.simulationID
                    == simulationID,
                  authority.sourceBeliefRevisionEventID.sequence.rawValue
                    <= causalLedger.latestSequence else {
                throw AgentSessionError.knowledge(
                    .invalidState("historical belief authority")
                )
            }
            if let exactEvent = retainedEventByID[
                authority.sourceBeliefRevisionEventID
            ] {
                guard exactEvent.kind == .knowledgeBeliefRevised,
                      exactEvent.origin == .knowledgeTransition,
                      exactEvent.actorID == authority.ownerID,
                      exactEvent.subjectID == authority.ownerID,
                      case let .knowledge(
                        recordID, propositionID, status, _
                      ) = exactEvent.payload,
                      recordID == authority.beliefID.rawValue,
                      propositionID
                        == authority.proposition.propositionID.rawValue,
                      status == authority.stance.rawValue else {
                    throw AgentSessionError.knowledge(
                        .invalidState("historical authority revision event")
                    )
                }
            }
            if let retainedProposition = propositionByID[
                authority.proposition.propositionID
            ], retainedProposition != authority.proposition {
                throw AgentSessionError.knowledge(
                    .invalidState("historical authority proposition")
                )
            }
            if let revision = state.revisions.first(where: {
                $0.revisionEventID
                    == authority.sourceBeliefRevisionEventID
            }) {
                guard revision.beliefID == authority.beliefID,
                      revision.ownerID == authority.ownerID,
                      revision.questionKey
                        == authority.proposition.questionKey,
                      revision.propositionID
                        == authority.proposition.propositionID,
                      revision.stance == authority.stance,
                      revision.triggerUnderstandingID
                        == authority.basisUnderstandingID,
                      revision.revisedAtTick
                        == authority.beliefUpdatedAtTick else {
                    throw AgentSessionError.knowledge(
                        .invalidState("historical authority revision")
                    )
                }
            }
            if let current = state.beliefs.first(where: {
                $0.beliefID == authority.beliefID
            }) {
                guard current.ownerID == authority.ownerID,
                      current.questionKey
                        == authority.proposition.questionKey,
                      current.formedAtTick
                        == authority.beliefFormedAtTick,
                      current.revisionCount
                        >= authority.beliefRevisionCount,
                      current.lastRevisionEventID.sequence
                        >= authority.sourceBeliefRevisionEventID.sequence else {
                    throw AgentSessionError.knowledge(
                        .invalidState("historical authority current belief")
                    )
                }
                if current.lastRevisionEventID
                    == authority.sourceBeliefRevisionEventID {
                    guard current.propositionID
                            == authority.proposition.propositionID,
                          current.stance == authority.stance,
                          current.basisUnderstandingID
                            == authority.basisUnderstandingID,
                          current.updatedAtTick
                            == authority.beliefUpdatedAtTick,
                          current.revisionCount
                            == authority.beliefRevisionCount else {
                        throw AgentSessionError.knowledge(
                            .invalidState("historical authority exact belief")
                        )
                    }
                }
            } else if let departed = (state.departedBeliefs ?? []).first(
                where: { $0.beliefID == authority.beliefID }
            ) {
                guard departed.ownerID == authority.ownerID,
                      departed.proposition.questionKey
                        == authority.proposition.questionKey,
                      departed.formedAtTick
                        == authority.beliefFormedAtTick,
                      departed.revisionCount
                        >= authority.beliefRevisionCount,
                      departed.lastRevisionEventID.sequence
                        >= authority.sourceBeliefRevisionEventID.sequence else {
                    throw AgentSessionError.knowledge(
                        .invalidState("historical authority departed belief")
                    )
                }
            }
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
        func retainedEvidenceAuthorityMatches(
            _ eventID: AgentCausalEventID,
            authority: AgentKnowledgeEvidenceAuthority,
            observerID: AgentID
        ) throws -> Bool {
            guard let event = try retainedCausalEvent(eventID) else {
                return true
            }
            switch authority {
            case .validatedWorldObservation:
                return event.kind == .resourceFactGrounded
                    && event.actorID == observerID
            case .validatedSocialVerification:
                return event.kind == .socialVerification
                    && event.actorID == observerID
            case .canonicalCivilizationState:
                return event.origin != .knowledgeTransition
            }
        }
        let departedEventIDs = (state.departedBeliefs ?? []).flatMap { record in
            let basis: [AgentCausalEventID]
            switch record.basis {
            case let .evidence(_, _, authorityEventID, acquisitionEventID):
                basis = [authorityEventID, acquisitionEventID]
            case let .sourceClaim(
                _, _, _, _, sourceAuthorityEventID,
                sourceAcquisitionEventID, _, sentEventID,
                receivedEventID, acquisitionEventID
            ):
                basis = [
                    sourceAuthorityEventID, sourceAcquisitionEventID,
                    sentEventID, receivedEventID, acquisitionEventID,
                ]
            case let .oralSourceClaim(
                _, _, _, _, _, sentEventID, receivedEventID,
                acquisitionEventID
            ):
                basis = [sentEventID, receivedEventID, acquisitionEventID]
            }
            return basis + [
                record.understandingFormedEventID,
                record.lastRevisionEventID,
                record.deathEventID,
            ]
        }
        let allEventIDs = state.evidence.flatMap {
            [$0.authorityEventID, $0.acquisitionEventID]
        } + state.claims.flatMap {
            [$0.sentEventID, $0.receivedEventID, $0.acquisitionEventID]
        } + state.understandings.map(\.formedEventID)
            + state.beliefs.map(\.lastRevisionEventID)
            + state.revisions.map(\.revisionEventID)
            + departedEventIDs
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
            return try retainedEvidenceAuthorityMatches(
                record.authorityEventID,
                authority: record.authority,
                observerID: record.observerID
            )
        }), try state.claims.allSatisfy({ record throws -> Bool in
            guard propositionByID[record.propositionID] != nil,
                  record.receivedAtTick >= 0, record.receivedAtTick <= tick,
                  record.sentEventID.sequence < record.receivedEventID.sequence,
                  record.receivedEventID.sequence
                    < record.acquisitionEventID.sequence else { return false }
            if let sourceEvidenceID = record.sourceEvidenceID,
               let socialMessageID = record.socialMessageID {
                guard record.sourceBeliefAuthorityID == nil,
                      record.languageCommunicationID == nil,
                      record.oralTransmissionID == nil,
                      let sourceEvidence = evidenceByID[sourceEvidenceID],
                      sourceEvidence.propositionID == record.propositionID,
                      sourceEvidence.observerID == record.sourceAgentID,
                      sourceEvidence.acquisitionEventID.sequence
                        < record.sentEventID.sequence else { return false }
                let socialEvents: [(
                    AgentCausalEventID, AgentCausalEventKind, String
                )] = [
                    (record.sentEventID, .socialMessageSent, "sent"),
                    (record.receivedEventID, .socialMessageReceived, "received"),
                ]
                for (eventID, kind, status) in socialEvents {
                    if let event = try retainedCausalEvent(eventID) {
                        guard event.kind == kind,
                              event.actorID == record.sourceAgentID,
                              event.subjectID == record.recipientID,
                              case let .socialMessage(
                                messageID, _, eventStatus
                              ) = event.payload,
                              messageID == socialMessageID.rawValue,
                              eventStatus == status else { return false }
                    }
                }
            } else if let sourceAuthorityID =
                        record.sourceBeliefAuthorityID,
                      let communicationID = record.languageCommunicationID,
                      let transmissionID = record.oralTransmissionID {
                guard record.socialMessageID == nil,
                      let authority = (state.historicalBeliefAuthorities ?? [])
                        .first(where: { $0.authorityID == sourceAuthorityID }),
                      authority.ownerID == record.sourceAgentID,
                      let communication = languageState?.communications.first(
                        where: { $0.communicationID == communicationID }
                      ),
                      communication.speakerID == record.sourceAgentID,
                      communication.recipientID == record.recipientID,
                      communication.semanticAuthority.authorityID
                        == sourceAuthorityID,
                      communication.communicationEventID == record.sentEventID,
                      let transmission = oralTransmissionState?.transmissions
                        .first(where: {
                            $0.transmissionID == transmissionID
                        }),
                      transmission.recipientClaimID == record.claimID,
                      transmission.speakerID == record.sourceAgentID,
                      transmission.recipientID == record.recipientID,
                      transmission.sourceAuthorityID == sourceAuthorityID,
                      transmission.languageCommunicationID == communicationID,
                      transmission.receiptEventID == record.receivedEventID,
                      transmission.interpretedSemanticContent
                        .sourcePropositionID == record.propositionID else {
                    return false
                }
                if let event = try retainedCausalEvent(
                    record.receivedEventID
                ) {
                    guard event.kind == .oralTransmissionAccepted,
                          event.origin == .oralTransition,
                          event.actorID == record.sourceAgentID,
                          event.subjectID == record.recipientID,
                          case let .oral(
                            eventTransmissionID, _, reachedID, _, _
                          ) = event.payload,
                          eventTransmissionID == transmissionID.rawValue,
                          reachedID == record.propositionID.rawValue else {
                        return false
                    }
                }
            } else {
                return false
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
        }), try (state.departedBeliefs ?? []).allSatisfy({
            record throws -> Bool in
            guard AgentKnowledgeProposition(
                subject: record.proposition.subject,
                predicate: record.proposition.predicate,
                value: record.proposition.value
            ) == record.proposition,
            statesById[record.ownerID.rawValue] == nil,
            record.proposition.questionKey
                == "\(record.proposition.subject.canonicalText)|"
                    + record.proposition.predicate.rawValue,
            record.formedAtTick >= 0,
            record.formedAtTick <= record.updatedAtTick,
            record.updatedAtTick <= record.departedAtTick,
            record.departedAtTick <= tick,
            record.revisionCount >= 1,
            record.understandingFormedEventID.sequence
                < record.lastRevisionEventID.sequence,
            record.lastRevisionEventID.sequence < record.deathEventID.sequence
            else { return false }
            switch record.basis {
            case let .evidence(
                evidenceID, authority, authorityEventID, acquisitionEventID
            ):
                guard authorityEventID.sequence < acquisitionEventID.sequence,
                      acquisitionEventID.sequence
                        < record.understandingFormedEventID.sequence else {
                    return false
                }
                guard try retainedEvidenceAuthorityMatches(
                    authorityEventID,
                    authority: authority,
                    observerID: record.ownerID
                ) else { return false }
                if let acquisition = try retainedCausalEvent(
                    acquisitionEventID
                ) {
                    guard acquisition.kind == .knowledgeEvidenceAcquired,
                          acquisition.origin == .knowledgeTransition,
                          acquisition.actorID == record.ownerID,
                          acquisition.subjectID == record.ownerID,
                          case let .knowledge(
                            recordID, propositionID, status, _
                          ) = acquisition.payload,
                          recordID == evidenceID.rawValue,
                          propositionID
                            == record.proposition.propositionID.rawValue,
                          status == authority.rawValue else { return false }
                }
            case let .sourceClaim(
                claimID, sourceAgentID, sourceEvidenceID,
                sourceEvidenceAuthority, sourceAuthorityEventID,
                sourceAcquisitionEventID, socialMessageID,
                sentEventID, receivedEventID, acquisitionEventID
            ):
                guard sourceAgentID != record.ownerID,
                      sourceAuthorityEventID.sequence
                        < sourceAcquisitionEventID.sequence,
                      sourceAcquisitionEventID.sequence < sentEventID.sequence,
                      sentEventID.sequence < receivedEventID.sequence,
                      receivedEventID.sequence < acquisitionEventID.sequence,
                      acquisitionEventID.sequence
                        < record.understandingFormedEventID.sequence else {
                    return false
                }
                if let sourceAcquisition = try retainedCausalEvent(
                    sourceAcquisitionEventID
                ) {
                    guard sourceAcquisition.kind == .knowledgeEvidenceAcquired,
                          sourceAcquisition.origin == .knowledgeTransition,
                          sourceAcquisition.actorID == sourceAgentID,
                          sourceAcquisition.subjectID == sourceAgentID,
                          case let .knowledge(
                            recordID, propositionID, status, _
                          ) = sourceAcquisition.payload,
                          recordID == sourceEvidenceID.rawValue,
                          propositionID
                            == record.proposition.propositionID.rawValue,
                          status == sourceEvidenceAuthority.rawValue else {
                        return false
                    }
                }
                guard try retainedEvidenceAuthorityMatches(
                    sourceAuthorityEventID,
                    authority: sourceEvidenceAuthority,
                    observerID: sourceAgentID
                ) else { return false }
                let socialEvents: [(
                    AgentCausalEventID, AgentCausalEventKind, String
                )] = [
                    (sentEventID, .socialMessageSent, "sent"),
                    (receivedEventID, .socialMessageReceived, "received"),
                ]
                for (eventID, kind, status) in socialEvents {
                    if let event = try retainedCausalEvent(eventID) {
                        guard event.kind == kind,
                              event.actorID == sourceAgentID,
                              event.subjectID == record.ownerID,
                              case let .socialMessage(
                                messageID, _, eventStatus
                              ) = event.payload,
                              messageID == socialMessageID.rawValue,
                              eventStatus == status else { return false }
                    }
                }
                if let acquisition = try retainedCausalEvent(
                    acquisitionEventID
                ) {
                    guard acquisition.kind == .knowledgeClaimReceived,
                          acquisition.origin == .knowledgeTransition,
                          acquisition.actorID == sourceAgentID,
                          acquisition.subjectID == record.ownerID,
                          case let .knowledge(
                            recordID, propositionID, _, _
                          ) = acquisition.payload,
                          recordID == claimID.rawValue,
                          propositionID
                            == record.proposition.propositionID.rawValue else {
                        return false
                    }
                }
            case let .oralSourceClaim(
                claimID, sourceAgentID, sourceBeliefAuthorityID,
                languageCommunicationID, oralTransmissionID, sentEventID,
                receivedEventID, acquisitionEventID
            ):
                guard sourceAgentID != record.ownerID,
                      sentEventID.sequence < receivedEventID.sequence,
                      receivedEventID.sequence < acquisitionEventID.sequence,
                      acquisitionEventID.sequence
                        < record.understandingFormedEventID.sequence,
                      let authority = (state.historicalBeliefAuthorities ?? [])
                        .first(where: {
                            $0.authorityID == sourceBeliefAuthorityID
                        }),
                      authority.ownerID == sourceAgentID,
                      let communication = languageState?.communications.first(
                        where: {
                            $0.communicationID == languageCommunicationID
                        }),
                      communication.speakerID == sourceAgentID,
                      communication.recipientID == record.ownerID,
                      communication.communicationEventID == sentEventID,
                      communication.semanticAuthority.authorityID
                        == sourceBeliefAuthorityID,
                      let transmission = oralTransmissionState?.transmissions
                        .first(where: {
                            $0.transmissionID == oralTransmissionID
                        }),
                      transmission.recipientClaimID == claimID,
                      transmission.receiptEventID == receivedEventID,
                      transmission.interpretedSemanticContent
                        .sourcePropositionID
                            == record.proposition.propositionID else {
                    return false
                }
                if let acquisition = try retainedCausalEvent(
                    acquisitionEventID
                ) {
                    guard acquisition.kind == .knowledgeClaimReceived,
                          acquisition.origin == .knowledgeTransition,
                          acquisition.actorID == sourceAgentID,
                          acquisition.subjectID == record.ownerID,
                          case let .knowledge(
                            eventRecordID, propositionID, _, _
                          ) = acquisition.payload,
                          eventRecordID == claimID.rawValue,
                          propositionID
                            == record.proposition.propositionID.rawValue else {
                        return false
                    }
                }
            }
            if let understandingEvent = try retainedCausalEvent(
                record.understandingFormedEventID
            ) {
                guard understandingEvent.kind == .knowledgeUnderstandingFormed,
                      understandingEvent.origin == .knowledgeTransition,
                      understandingEvent.actorID == record.ownerID,
                      understandingEvent.subjectID == record.ownerID,
                      case let .knowledge(
                        recordID, propositionID, status, _
                      ) = understandingEvent.payload,
                      recordID == record.basisUnderstandingID.rawValue,
                      propositionID == record.proposition.propositionID.rawValue,
                      status == record.interpretation.rawValue else {
                    return false
                }
            }
            if let revisionEvent = try retainedCausalEvent(
                record.lastRevisionEventID
            ) {
                guard revisionEvent.kind == .knowledgeBeliefRevised,
                      revisionEvent.origin == .knowledgeTransition,
                      revisionEvent.actorID == record.ownerID,
                      revisionEvent.subjectID == record.ownerID,
                      case let .knowledge(
                        recordID, propositionID, status, _
                      ) = revisionEvent.payload,
                      recordID == record.beliefID.rawValue,
                      propositionID == record.proposition.propositionID.rawValue,
                      status == record.stance.rawValue else { return false }
            }
            guard let deathEvent = try retainedCausalEvent(record.deathEventID)
            else { return true }
            guard deathEvent.kind == .agentDeathFinalized,
                  deathEvent.origin == .mortalityTransition,
                  deathEvent.actorID == record.ownerID,
                  deathEvent.subjectID == record.ownerID,
                  case let .mortalityDeath(
                    deathID, agentID, _, deathTick, _, _, _, _, _, _, _, _, _, _
                  ) = deathEvent.payload else { return false }
            return deathID == record.deathID.rawValue
                && agentID == record.ownerID.rawValue
                && deathTick == record.departedAtTick
        }) else {
            throw AgentSessionError.knowledge(.invalidState("graph relationship"))
        }
        guard state.propositions.count <= configuration.maximumPropositions,
              state.evidence.count <= configuration.maximumEvidence,
              state.claims.count <= configuration.maximumClaims,
              state.understandings.count <= configuration.maximumUnderstandings,
              state.beliefs.count <= configuration.maximumBeliefs,
              state.revisions.count <= configuration.maximumRevisions,
              (state.departedBeliefs ?? []).count
                <= configuration.maximumDepartedBeliefs,
              (state.departedBeliefEvictionCount ?? 0) >= 0,
              [
                  state.evictionCounts.propositions,
                  state.evictionCounts.evidence,
                  state.evictionCounts.claims,
                  state.evictionCounts.understandings,
                  state.evictionCounts.revisions,
              ].allSatisfy({ $0 >= 0 }) else {
            throw AgentSessionError.knowledge(.invalidState("global bound"))
        }
        let activeAgentIDs = Set(statesById.values.map(\.agentID))
        let departedBeliefIDs = Set(
            (state.departedBeliefs ?? []).map(\.beliefID)
        )
        guard departedBeliefIDs.isDisjoint(with: state.beliefs.map(\.beliefID)),
        state.claims.allSatisfy({
            activeAgentIDs.contains($0.recipientID)
        }), state.understandings.allSatisfy({
            activeAgentIDs.contains($0.ownerID)
        }), state.beliefs.allSatisfy({
            activeAgentIDs.contains($0.ownerID)
        }), state.revisions.allSatisfy({
            activeAgentIDs.contains($0.ownerID)
        }) else {
            throw AgentSessionError.knowledge(
                .invalidState("current cognition requires active owner")
            )
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

func historicalBeliefAuthorityCanonicalText(
    _ authority: AgentKnowledgeHistoricalBeliefAuthority
) -> String {
    [
        "historical-belief-authority",
        authority.authorityID.rawValue,
        authority.beliefID.rawValue,
        authority.ownerID.rawValue,
        authority.proposition.propositionID.rawValue,
        authority.proposition.subject.canonicalText,
        authority.proposition.predicate.rawValue,
        authority.proposition.value.canonicalText,
        authority.stance.rawValue,
        authority.basisUnderstandingID.rawValue,
        String(authority.beliefFormedAtTick),
        String(authority.beliefUpdatedAtTick),
        String(authority.beliefRevisionCount),
        authority.sourceBeliefRevisionEventID.rawValue,
        authority.digest,
    ].joined(separator: "|")
}

func knowledgeHistoricalBeliefAuthorityDigest(
    beliefID: AgentKnowledgeBeliefID,
    ownerID: AgentID,
    proposition: AgentKnowledgeProposition,
    stance: AgentKnowledgeBeliefStance,
    basisUnderstandingID: AgentKnowledgeUnderstandingID,
    beliefFormedAtTick: Int,
    beliefUpdatedAtTick: Int,
    beliefRevisionCount: Int,
    sourceBeliefRevisionEventID: AgentCausalEventID
) -> String {
    AgentKnowledgeDigest.make([
        "historical-belief-authority-v1",
        beliefID.rawValue,
        ownerID.rawValue,
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

func knowledgeHistoricalAuthorityBoundaryDigest(
    _ authorities: [AgentKnowledgeHistoricalBeliefAuthority]
) -> String {
    AgentKnowledgeDigest.make(
        "historical-belief-authority-boundary-v1|"
            + authorities.sorted { $0.authorityID < $1.authorityID }.map {
                historicalBeliefAuthorityCanonicalText($0)
            }.joined(separator: ";")
    )
}
