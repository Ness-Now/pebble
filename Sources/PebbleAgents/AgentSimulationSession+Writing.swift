extension AgentSimulationSession {
    public mutating func setWritingEnabled(
        _ enabled: Bool, worldID: String,
        configuration: AgentWritingConfiguration = .live
    ) throws {
        if !enabled, archiveState != nil {
            throw AgentArchiveError.unavailable("archive dependency")
        }
        guard causalLedger.isEnabled, knowledgeGraphEnabled,
              languageState?.enabled == true,
              isValidLanguageText(worldID, maximum: 128) else {
            throw AgentWritingError.unavailable("writing requires World binding, CIV-41/42 and causality")
        }
        _ = try AgentWritingConfiguration(maximumArtifacts: configuration.maximumArtifacts,
                                          maximumReadings: configuration.maximumReadings,
            maximumLiteracyRecords: configuration.maximumLiteracyRecords)
        if let state = writingState {
            guard state.worldID == worldID, state.configuration == configuration else {
                throw AgentWritingError.invalidState("immutable writing configuration")
            }
            if state.enabled == enabled { return }
        }
        var candidate = self
        var state = writingState ?? AgentWritingState(worldID: worldID, configuration: configuration)
        state.enabled = enabled
        candidate.writingState = state
        let event = try candidate.requiredWritingEvent(.writingInitialized,
            recordID: "writing", detail: enabled ? "enabled" : "disabled")
        try candidate.commitWritingBoundary(causes: [event.eventID])
        try candidate.validateWritingState()
        self = candidate
    }

    public func prepareWriting(
        authorID: AgentID, propositionID: AgentKnowledgePropositionID,
        materialID: Int, dimension: String, cell: AgentPosition,
        assertion: AgentWritingAssertion = .beliefReport
    ) throws -> AgentWritingPlan {
        guard let state = writingState, state.enabled else {
            throw AgentWritingError.unavailable("writing disabled")
        }
        guard state.artifacts.count < state.configuration.maximumArtifacts,
              state.nextArtifactOrdinal < UInt64.max else {
            throw AgentWritingError.capacityReached("artifacts")
        }
        try requireWritingParticipant(authorID, cell: cell)
        guard materialID > 0, materialID < Int.max,
              !state.artifacts.contains(where: { $0.plan.materialID == materialID }) else {
            throw AgentWritingError.invalidState("physical identity already used or invalid")
        }
        guard isValidLanguageText(dimension, maximum: 32) else {
            throw AgentWritingError.invalidState("dimension")
        }
        let (belief, source, _) = try languageBeliefAndSemanticContent(ownerID: authorID,
                                                                       propositionID: propositionID)
        let proposition = try writtenAssertionProposition(source: source, assertion: assertion)
        let content = try languageSemanticContent(for: proposition)
        let uses = try languageLexicalUses(for: authorID, content: content, state: languageState!)
        let realization = AgentLanguageRealization(semanticContent: content,
            rendering: .deterministic(text: languageDeterministicText(content: content, lexicalUses: uses)),
            lexicalUses: uses)
        try requireWritingLiteracy(authorID)
        _ = try writtenLanguageAssociations(ownerID: authorID, realization: realization)
        return AgentWritingPlan(
            artifactID: writingArtifactID(worldID: state.worldID, materialID: materialID),
            materialID: materialID,
            ordinal: state.nextArtifactOrdinal, worldID: state.worldID,
            dimension: dimension, cell: cell, authorID: authorID,
            sourceBeliefID: belief.beliefID, sourcePropositionID: propositionID,
            assertion: assertion, assertedProposition: proposition, sourceRevisionEventID: belief.lastRevisionEventID,
            realization: realization, lines: try writtenSignLines(realization), preparedAtTick: tick
        )
    }

    /// Pebble applies the plan to a real blank sign and verifies it before
    /// calling this publication boundary. A refusal requires physical rollback.
    @discardableResult
    public mutating func acceptWriting(
        _ plan: AgentWritingPlan, receipt: AgentWritingPhysicalReceipt
    ) throws -> AgentWrittenArtifact {
        guard try prepareWriting(authorID: plan.authorID,
            propositionID: plan.sourcePropositionID,
            materialID: plan.materialID,
            dimension: plan.dimension, cell: plan.cell, assertion: plan.assertion) == plan else {
            throw AgentWritingError.invalidState("stale or substituted writing plan")
        }
        try requireWritingReceipt(receipt, plan: plan, actorID: plan.authorID)
        var candidate = self
        let (belief, proposition, _) = try candidate.languageBeliefAndSemanticContent(
            ownerID: plan.authorID, propositionID: plan.sourcePropositionID)
        let authority = try candidate.retainKnowledgeHistoricalBeliefAuthority(
            belief: belief, proposition: proposition)
        let literacy = try candidate.useWrittenLanguage(ownerID: plan.authorID,
            realization: plan.realization, recordID: plan.artifactID,
            cause: plan.sourceRevisionEventID)
        let event = try candidate.requiredWritingEvent(.writingInscribed,
            actorID: plan.authorID, causes: [literacy.useEventID],
            recordID: plan.artifactID, detail: writingDigest(receipt))
        let artifact = AgentWrittenArtifact(plan: plan, sourceAuthorityID: authority.authorityID,
            literacy: literacy, physicalReceipt: receipt, inscriptionEventID: event.eventID)
        candidate.writingState!.artifacts.append(artifact)
        candidate.writingState!.nextArtifactOrdinal += 1
        try candidate.commitWritingBoundary(causes: [event.eventID])
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateWritingState()
        self = candidate
        return artifact
    }

    @discardableResult
    public mutating func readWriting(
        artifactID: String, readerID: AgentID, receipt: AgentWritingPhysicalReceipt
    ) throws -> AgentWritingReading {
        guard let state = writingState, state.enabled,
              let artifact = state.artifacts.first(where: { $0.artifactID == artifactID }) else {
            throw AgentWritingError.unavailable("unknown writing")
        }
        guard state.readings.count < state.configuration.maximumReadings,
              state.nextReadingOrdinal < UInt64.max else {
            throw AgentWritingError.capacityReached("readings")
        }
        // Re-reading in a later tick is causal; retrying this exact boundary is
        // refused before consuming a reading identity or reaffirming a belief.
        guard !state.readings.contains(where: {
            $0.artifactID == artifactID && $0.readerID == readerID
                && $0.physicalReceipt.observedAtTick == tick
        }) else { throw AgentWritingError.unavailable("duplicate reading boundary") }
        guard artifact.plan.authorID != readerID else {
            throw AgentWritingError.unavailable("self reading does not create a source claim")
        }
        try requireWritingReceipt(receipt, plan: artifact.plan, actorID: readerID)
        try requireWritingLiteracy(readerID)
        _ = try writtenLanguageAssociations(ownerID: readerID, realization: artifact.plan.realization)
        var candidate = self
        let readingID = "writing-reading-\(state.nextReadingOrdinal)"
        let access = try candidate.requiredWritingEvent(.writingAccessed, actorID: readerID,
            causes: [artifact.inscriptionEventID], recordID: readingID, detail: writingDigest(receipt))
        let literacy = try candidate.useWrittenLanguage(ownerID: readerID,
            realization: artifact.plan.realization, recordID: readingID, cause: access.eventID)
        let read = try candidate.requiredWritingEvent(.writingRead, actorID: readerID,
            causes: [literacy.useEventID, access.eventID], recordID: readingID, detail: artifactID)
        let acquisition = try candidate.acquireWrittenSourceClaim(artifact: artifact,
            readingID: readingID, readerID: readerID, readingEventID: read.eventID)
        let reading = AgentWritingReading(readingID: readingID, artifactID: artifactID,
            readerID: readerID, literacy: literacy, physicalReceipt: receipt,
            accessEventID: access.eventID, readingEventID: read.eventID,
            claimID: acquisition.claimID, claimEventID: acquisition.claimEventID,
            recipientAuthorityID: acquisition.authorityID)
        candidate.writingState!.readings.append(reading)
        candidate.writingState!.nextReadingOrdinal += 1
        // Historical result stays in CIV-41, not a writing-owned belief copy.
        _ = try candidate.retainKnowledgeHistoricalBeliefAuthority(
            belief: acquisition.belief, proposition: acquisition.proposition)
        try candidate.commitWritingBoundary(causes: [read.eventID, acquisition.claimEventID])
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateLanguageStateIfInitialized()
        try candidate.validateWritingState()
        self = candidate
        return reading
    }

    func writtenAssertionProposition(source: AgentKnowledgeProposition,
        assertion: AgentWritingAssertion) throws -> AgentKnowledgeProposition {
        switch assertion {
        case .beliefReport: return source
        case let .deliberateCounterAssertion(value):
            guard value == .absent || value == .resource(kind: .wood, fingerprint: nil)
                || value == .resource(kind: .stone, fingerprint: nil), value != source.value else {
                throw AgentWritingError.invalidState("unsupported counter assertion")
            }
            return AgentKnowledgeProposition(subject: source.subject, predicate: source.predicate, value: value)
        }
    }

    func writingArtifactID(worldID: String, materialID: Int) -> String {
        "inscription-" + writingDigest([worldID, String(materialID)])
    }

    func writtenSignLines(_ realization: AgentLanguageRealization) throws -> [String] {
        try validateWrittenRealization(realization)
        let uses = realization.lexicalUses
        let key = realization.semanticContent.referent.key
        guard key.hasPrefix("cell:") else { throw AgentWritingError.invalidState("written referent") }
        let lines = [uses[2].form, uses[1].form, uses[0].form, String(key.dropFirst(5))]
        guard lines.allSatisfy({ isValidLanguageText($0, maximum: 64) }) else {
            throw AgentWritingError.invalidState("sign line capacity")
        }
        return lines
    }

    func requireWritingParticipant(_ actorID: AgentID, cell: AgentPosition) throws {
        guard let actor = statesById[actorID.rawValue], !isMigratingAgent(actorID.rawValue),
              writingPositionsAreLocal(actor.position, cell) else {
            throw AgentWritingError.unavailable("inactive, migrating or nonlocal participant")
        }
    }

    func requireWritingReceipt(_ receipt: AgentWritingPhysicalReceipt,
                               plan: AgentWritingPlan, actorID: AgentID) throws {
        try requireWritingParticipant(actorID, cell: plan.cell)
        guard receipt.actorID == actorID,
              receipt.actorPosition == statesById[actorID.rawValue]?.position,
              receipt.observedAtTick == tick,
              writingReceiptMatches(receipt, plan: plan) else {
            throw AgentWritingError.unavailable("stale or incompatible physical receipt")
        }
    }

    func writingReceiptMatches(_ receipt: AgentWritingPhysicalReceipt, plan: AgentWritingPlan) -> Bool {
        receipt.worldID == plan.worldID && receipt.dimension == plan.dimension
            && receipt.cell == plan.cell && receipt.artifactID == plan.artifactID
            && receipt.materialID == plan.materialID
            && receipt.contentDigest == plan.contentDigest && receipt.lines == plan.lines
            && ["oak_sign", "spruce_sign", "birch_sign", "jungle_sign", "acacia_sign",
                "dark_oak_sign", "mangrove_sign", "cherry_sign", "bamboo_sign",
                "crimson_sign", "warped_sign"].contains(receipt.blockKey)
            && writingPositionsAreLocal(receipt.actorPosition, receipt.cell)
    }

    @discardableResult
    mutating func requiredWritingEvent(_ kind: AgentCausalEventKind,
        actorID: AgentID? = nil, causes: [AgentCausalEventID] = [],
        recordID: String, detail: String) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(kind: kind, origin: .writingTransition,
            actorID: actorID, causes: Array(Set(causes)).sorted(),
            payload: .writing(recordID: recordID, detail: detail), summary: "writing \(kind.rawValue)") else {
            throw AgentWritingError.unavailable("causal ledger")
        }
        return event
    }

    mutating func commitWritingBoundary(causes: [AgentCausalEventID]) throws {
        guard let state = writingState else { return }
        let digest = writingBoundaryDigest(state)
        let previous = state.boundary.map { [$0.eventID] } ?? []
        let event = try requiredWritingEvent(.writingProvenanceBoundary,
            causes: Array(Set(causes + previous)).sorted(), recordID: "writing", detail: digest)
        writingState!.boundary = AgentWritingBoundary(eventID: event.eventID, digest: digest)
    }

    func validateWritingBoundary() throws {
        guard let state = writingState else { return }
        guard let boundary = state.boundary,
              boundary.digest == writingBoundaryDigest(state),
              let event = causalLedger.events.last(where: { $0.kind == .writingProvenanceBoundary }),
              event.eventID == boundary.eventID,
              event.origin == .writingTransition, event.actorID == nil,
              event.payload == .writing(recordID: "writing", detail: boundary.digest) else {
            throw AgentWritingError.invalidState("exact latest writing boundary")
        }
    }

    /// A compacted event is usable only under the exact retained writing set
    /// authenticated above; a plausible dropped-prefix ID alone is not proof.
    func validateWritingEvent(_ id: AgentCausalEventID, kind: AgentCausalEventKind,
                              actorID: AgentID?, payload: AgentCausalPayload) throws {
        guard id.simulationID == simulationID, id.sequence.rawValue > 0,
              id.sequence.rawValue <= causalLedger.latestSequence else {
            throw AgentWritingError.invalidState("writing event reference")
        }
        if let event = causalLedger.events.first(where: { $0.eventID == id }) {
            guard event.kind == kind, event.actorID == actorID, event.payload == payload,
                  event.origin == (kind == .languageWrittenFormsUsed ? .languageTransition : .writingTransition) else {
                throw AgentWritingError.invalidState("writing event payload")
            }
        } else if id.sequence.rawValue > causalLedger.droppedEventCount {
            throw AgentWritingError.invalidState("impossible writing event")
        }
    }

    func validateWritingState() throws {
        guard let state = writingState else { return }
        try validateWritingBoundary()
        try validateWritingLiteracy()
        _ = try AgentWritingConfiguration(maximumArtifacts: state.configuration.maximumArtifacts,
                                          maximumReadings: state.configuration.maximumReadings,
            maximumLiteracyRecords: state.configuration.maximumLiteracyRecords)
        guard knowledgeGraphState != nil, languageState != nil,
              isValidLanguageText(state.worldID, maximum: 128),
              state.artifacts.count <= state.configuration.maximumArtifacts,
              state.readings.count <= state.configuration.maximumReadings,
              state.nextArtifactOrdinal == UInt64(state.artifacts.count) + 1,
              state.nextReadingOrdinal == UInt64(state.readings.count) + 1,
              Set(state.artifacts.map(\.artifactID)).count == state.artifacts.count,
              Set(state.artifacts.map { $0.plan.materialID }).count == state.artifacts.count,
              Set(state.readings.map(\.readingID)).count == state.readings.count,
              Set(state.readings.map { writingDigest([$0.artifactID, $0.readerID.rawValue,
                String($0.physicalReceipt.observedAtTick)]) }).count == state.readings.count else {
            throw AgentWritingError.invalidState("writing bounds or duplicate identities")
        }
        for (index, artifact) in state.artifacts.enumerated() {
            let plan = artifact.plan
            guard let authority = knowledgeGraphState?.historicalBeliefAuthorities?.first(where: {
                $0.authorityID == artifact.sourceAuthorityID
            }), plan.worldID == state.worldID, plan.ordinal == UInt64(index) + 1,
                  plan.materialID > 0, plan.materialID < Int.max,
                  plan.artifactID == writingArtifactID(worldID: state.worldID, materialID: plan.materialID),
                  isValidLanguageText(plan.dimension, maximum: 32),
                  AgentID(rawValue: plan.authorID.rawValue) != nil,
                  authority.ownerID == plan.authorID, authority.beliefID == plan.sourceBeliefID,
                  authority.sourceBeliefRevisionEventID == plan.sourceRevisionEventID,
                  authority.stance == .accepted,
                  authority.proposition.propositionID == plan.sourcePropositionID,
                  try writtenAssertionProposition(source: authority.proposition, assertion: plan.assertion) == plan.assertedProposition,
                  try languageSemanticContent(for: plan.assertedProposition) == plan.realization.semanticContent,
                  plan.lines == (try writtenSignLines(plan.realization)),
                  plan.preparedAtTick >= 0, plan.preparedAtTick <= tick,
                  authority.beliefUpdatedAtTick <= plan.preparedAtTick,
                  artifact.physicalReceipt.actorID == plan.authorID,
                  artifact.physicalReceipt.observedAtTick == plan.preparedAtTick,
                  writingReceiptMatches(artifact.physicalReceipt, plan: plan),
                  plan.sourceRevisionEventID.sequence < artifact.literacy.useEventID.sequence,
                  artifact.literacy.useEventID.sequence < artifact.inscriptionEventID.sequence,
                  artifact.inscriptionEventID.sequence < state.boundary!.eventID.sequence else {
                throw AgentWritingError.invalidState("artifact author/content/material authority")
            }
            try validateHistoricalWrittenLanguage(artifact.literacy, ownerID: plan.authorID,
                realization: plan.realization, recordID: artifact.artifactID)
            try validateWritingEvent(artifact.inscriptionEventID, kind: .writingInscribed,
                actorID: plan.authorID, payload: .writing(recordID: artifact.artifactID,
                    detail: writingDigest(artifact.physicalReceipt)))
        }
        for (index, reading) in state.readings.enumerated() {
            guard let artifact = state.artifacts.first(where: { $0.artifactID == reading.artifactID }),
                  let result = knowledgeGraphState?.historicalBeliefAuthorities?.first(where: {
                    $0.authorityID == reading.recipientAuthorityID
                  }), reading.readingID == "writing-reading-\(index + 1)",
                  result.ownerID == reading.readerID, result.stance == .accepted,
                  result.proposition.propositionID == artifact.plan.realization.semanticContent.sourcePropositionID,
                  result.basisUnderstandingID == knowledgeUnderstandingID(ownerID: reading.readerID,
                    propositionID: result.proposition.propositionID, basis: .sourceClaim(reading.claimID)),
                  result.beliefUpdatedAtTick == reading.physicalReceipt.observedAtTick,
                  reading.readerID != artifact.plan.authorID,
                  reading.physicalReceipt.actorID == reading.readerID,
                  reading.physicalReceipt.observedAtTick >= artifact.plan.preparedAtTick,
                  reading.physicalReceipt.observedAtTick <= tick,
                  writingReceiptMatches(reading.physicalReceipt, plan: artifact.plan),
                  reading.claimID == writtenClaimID(reading.readingID, readerID: reading.readerID),
                  artifact.inscriptionEventID.sequence < reading.accessEventID.sequence,
                  reading.accessEventID.sequence < reading.literacy.useEventID.sequence,
                  reading.literacy.useEventID.sequence < reading.readingEventID.sequence,
                  reading.readingEventID.sequence < reading.claimEventID.sequence,
                  reading.claimEventID.sequence < result.sourceBeliefRevisionEventID.sequence,
                  result.sourceBeliefRevisionEventID.sequence < state.boundary!.eventID.sequence else {
                throw AgentWritingError.invalidState("written reading authority")
            }
            try validateHistoricalWrittenLanguage(reading.literacy, ownerID: reading.readerID,
                realization: artifact.plan.realization, recordID: reading.readingID)
            try validateWritingEvent(reading.accessEventID, kind: .writingAccessed,
                actorID: reading.readerID, payload: .writing(recordID: reading.readingID,
                    detail: writingDigest(reading.physicalReceipt)))
            try validateWritingEvent(reading.readingEventID, kind: .writingRead,
                actorID: reading.readerID, payload: .writing(recordID: reading.readingID, detail: reading.artifactID))
        }
    }
}

private func writingPositionsAreLocal(_ actor: AgentPosition, _ cell: AgentPosition) -> Bool {
    // Validate before arithmetic: malformed Int.min/max coordinates cannot trap.
    let values = [actor.x, actor.y, actor.z, cell.x, cell.y, cell.z]
    guard values.allSatisfy({ (-30_000_000...30_000_000).contains($0) }) else { return false }
    return abs(actor.x - cell.x) + abs(actor.y - cell.y) + abs(actor.z - cell.z) <= 2
}
