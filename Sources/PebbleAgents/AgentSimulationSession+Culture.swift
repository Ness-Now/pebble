import Foundation

extension AgentSimulationSession {
    public var distributedCultureEnabled: Bool {
        distributedCultureState?.enabled == true
    }

    public mutating func setDistributedCultureEnabled(
        _ enabled: Bool,
        configuration: AgentCultureConfiguration = .live
    ) throws {
        if distributedCultureState?.enabled == enabled {
            if enabled, distributedCultureState?.configuration != configuration {
                throw AgentSessionError.culture(
                    .invalidState("configuration cannot change after initialization")
                )
            }
            return
        }
        if enabled {
            guard causalLedger.isEnabled else {
                throw AgentSessionError.culture(.causalLedgerRequired)
            }
            guard populationRegistry != nil else {
                throw AgentSessionError.culture(.populationRequired)
            }
            guard socialEnabled else {
                throw AgentSessionError.culture(.socialRequired)
            }
        } else if distributedCultureState == nil {
            return
        }
        let retainedConfiguration = distributedCultureState?.configuration
            ?? configuration
        try retainedConfiguration.validate()
        var candidate = self
        let event = try candidate.requiredCultureEvent(
            kind: .cultureInitialized,
            actorID: nil,
            subjectID: nil,
            causes: [],
            practiceID: nil,
            recordID: "distributed-culture",
            status: enabled ? "enabled" : "disabled",
            detail: AgentCultureDigest.make(
                "feature|\(enabled)|\(retainedConfiguration)"
            ),
            summary: "distributed culture \(enabled ? "enabled" : "disabled")"
        )
        var state = candidate.distributedCultureState
            ?? AgentDistributedCultureState(configuration: retainedConfiguration)
        guard state.configuration == retainedConfiguration else {
            throw AgentSessionError.culture(
                .invalidState("configuration cannot change after initialization")
            )
        }
        state.enabled = enabled
        candidate.distributedCultureState = state
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
    }

    public func distributedCultureSnapshot() -> AgentCultureSnapshot {
        guard let state = distributedCultureState else {
            return AgentCultureSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                individuals: [],
                operationReceiptCount: 0,
                boundary: nil,
                digest: AgentCultureDigest.make("distributed-culture:none")
            )
        }
        return AgentCultureSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            individuals: state.individuals,
            operationReceiptCount: state.operationReceipts.count,
            boundary: state.boundary,
            digest: cultureBoundaryDigest(state)
        )
    }

    /// An origin is an individual innovation. It creates one adopted stance
    /// for the originator only; no group or settlement is synchronized.
    @discardableResult
    public mutating func originateCulturalPractice(
        operationID: String,
        originatorID: AgentID,
        form: AgentCulturePracticeForm
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        try form.validate()
        let requestDigest = AgentCultureDigest.make([
            "culture-origin-v1", simulationID.rawValue, operationID,
            originatorID.rawValue, form.canonicalText,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        try requireCultureAgent(originatorID)
        guard distributedCultureState?.enabled == true else {
            throw AgentSessionError.culture(.disabled)
        }
        var candidate = self
        try candidate.prevalidateCultureRows(
            affectedAgentIDs: [originatorID],
            newPracticeFor: [originatorID]
        )
        let practiceID = candidate.culturePracticeID(
            operationID: operationID,
            originatorID: originatorID,
            form: form,
            parentID: nil
        )
        let practice = AgentCulturePractice(
            practiceID: practiceID,
            rootPracticeID: practiceID,
            parentPracticeID: nil,
            generation: 0,
            form: form,
            originatorID: originatorID,
            originOperationID: operationID
        )
        let event = try candidate.requiredCultureEvent(
            kind: .culturePracticeOriginated,
            actorID: originatorID,
            subjectID: originatorID,
            causes: [],
            practiceID: practiceID,
            recordID: operationID,
            status: AgentCultureDecisionOutcome.adopted.rawValue,
            detail: requestDigest,
            summary: "cultural practice originated actor=\(originatorID.rawValue)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .originated,
            practice: practice,
            actorID: originatorID,
            sourceAgentID: nil,
            carrier: nil,
            carrierEventID: nil,
            carrierContentDigest: nil,
            participantIDs: [],
            witnessIDs: [],
            outcome: .adopted,
            competingPracticeID: nil,
            causes: event.causes,
            tick: candidate.tick,
            eventID: event.eventID
        )
        candidate.insertCultureRecord(record, for: [originatorID])
        candidate.setCultureStance(
            AgentCultureStance(
                practice: practice,
                status: .adopted,
                exposureCount: 0,
                useCount: 0,
                lastExposureTick: nil,
                lastUseTick: nil,
                adoptedAtTick: candidate.tick,
                adoptedEventID: event.eventID,
                lastTransitionEventID: event.eventID
            ),
            for: originatorID
        )
        candidate.insertCultureReceipt(for: record)
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
        return record
    }

    /// A variation is created only from the actor's own adopted parent. The
    /// parent record is retained unchanged and the new form must remain in the
    /// same narrow competition context.
    @discardableResult
    public mutating func createCulturalVariation(
        operationID: String,
        creatorID: AgentID,
        parentPracticeID: AgentCulturePracticeID,
        form: AgentCulturePracticeForm
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        try form.validate()
        let requestDigest = AgentCultureDigest.make([
            "culture-variation-v1", simulationID.rawValue, operationID,
            creatorID.rawValue, parentPracticeID.rawValue, form.canonicalText,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        try requireCultureAgent(creatorID)
        guard let parent = cultureStance(
            for: creatorID, practiceID: parentPracticeID
        ), parent.status == .adopted else {
            throw AgentSessionError.culture(
                .notAdopted(creatorID, parentPracticeID)
            )
        }
        guard form != parent.practice.form,
              form.competitionKey == parent.practice.form.competitionKey,
              parent.practice.generation < Int.max else {
            throw AgentSessionError.culture(.invalidPractice("variation lineage"))
        }
        var candidate = self
        try candidate.prevalidateCultureRows(
            affectedAgentIDs: [creatorID],
            newPracticeFor: [creatorID]
        )
        let practiceID = candidate.culturePracticeID(
            operationID: operationID,
            originatorID: creatorID,
            form: form,
            parentID: parentPracticeID
        )
        let practice = AgentCulturePractice(
            practiceID: practiceID,
            rootPracticeID: parent.practice.rootPracticeID,
            parentPracticeID: parentPracticeID,
            generation: parent.practice.generation + 1,
            form: form,
            originatorID: creatorID,
            originOperationID: operationID
        )
        let event = try candidate.requiredCultureEvent(
            kind: .cultureVariationCreated,
            actorID: creatorID,
            subjectID: creatorID,
            causes: [parent.lastTransitionEventID],
            practiceID: practiceID,
            recordID: operationID,
            status: AgentCultureDecisionOutcome.adopted.rawValue,
            detail: requestDigest,
            summary: "cultural variation created actor=\(creatorID.rawValue)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .variationCreated,
            practice: practice,
            actorID: creatorID,
            sourceAgentID: creatorID,
            carrier: nil,
            carrierEventID: nil,
            carrierContentDigest: nil,
            participantIDs: [],
            witnessIDs: [],
            outcome: .adopted,
            competingPracticeID: parentPracticeID,
            causes: event.causes,
            tick: candidate.tick,
            eventID: event.eventID
        )
        candidate.insertCultureRecord(record, for: [creatorID])
        candidate.setCultureStance(
            AgentCultureStance(
                practice: practice,
                status: .adopted,
                exposureCount: 0,
                useCount: 0,
                lastExposureTick: nil,
                lastUseTick: nil,
                adoptedAtTick: candidate.tick,
                adoptedEventID: event.eventID,
                lastTransitionEventID: event.eventID
            ),
            for: creatorID
        )
        candidate.insertCultureReceipt(for: record)
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
        return record
    }

    /// Creates an oral carrier whose immutable attachment commits the exact
    /// cultural descriptor, then admits the exposure in the same aggregate
    /// transaction. The accompanying CIV-41 proposition remains separate
    /// epistemic content; the attachment is not a belief or semantic sense.
    @discardableResult
    public mutating func transmitCulturalPracticeOrally(
        operationID: String,
        sourceAgentID: AgentID,
        targetID: AgentID,
        practiceID: AgentCulturePracticeID,
        accompanyingPropositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode
    ) throws -> AgentCultureRecord {
        try transmitCulturalPracticeOrally(
            operationID: operationID,
            sourceAgentID: sourceAgentID,
            targetID: targetID,
            practiceID: practiceID,
            accompanyingPropositionID: accompanyingPropositionID,
            renderingMode: renderingMode,
            recordedEffect: nil
        ).record
    }

    mutating func transmitCulturalPracticeOrally(
        operationID: String,
        sourceAgentID: AgentID,
        targetID: AgentID,
        practiceID: AgentCulturePracticeID,
        accompanyingPropositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode,
        recordedEffect: AgentOralAcceptedEffect?
    ) throws -> (record: AgentCultureRecord, transmission: AgentOralTransmission?) {
        try requireCultureOperationID(operationID)
        guard let sourceStance = cultureStance(
            for: sourceAgentID, practiceID: practiceID
        ) else {
            throw AgentSessionError.culture(.unknownPractice(practiceID))
        }
        let contentDigest = culturePracticeContentDigest(sourceStance.practice)
        let requestDigest = AgentCultureDigest.make([
            "culture-oral-exposure-v2", simulationID.rawValue, operationID,
            sourceAgentID.rawValue, targetID.rawValue, practiceID.rawValue,
            accompanyingPropositionID.rawValue, renderingMode.rawValue,
            contentDigest,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) {
            let transmission: AgentOralTransmission?
            if case let .oral(transmissionID) = existing.carrier {
                transmission = oralTransmissionState?.transmissions.first {
                    $0.transmissionID == transmissionID
                }
            } else {
                throw AgentSessionError.culture(.invalidState(
                    "oral culture retry carrier"
                ))
            }
            return (existing, transmission)
        }
        guard distributedCultureState?.enabled == true else {
            throw AgentSessionError.culture(.disabled)
        }
        try requireCultureAgent(sourceAgentID)
        try requireCultureAgent(targetID)
        guard sourceAgentID != targetID,
              sourceStance.status == .adopted else {
            throw AgentSessionError.culture(.notAdopted(
                sourceAgentID, practiceID
            ))
        }
        try prevalidateCultureRows(
            affectedAgentIDs: [targetID],
            newPracticeFor: cultureStance(
                for: targetID, practiceID: practiceID
            ) == nil ? [targetID] : []
        )

        let attachment = AgentOralContentAttachment(
            namespace: cultureOralContentNamespace,
            contentID: practiceID.rawValue,
            contentDigest: contentDigest
        )
        var candidate = self
        let transmission = try candidate.transmitOralClaim(
            speakerID: sourceAgentID,
            recipientID: targetID,
            propositionID: accompanyingPropositionID,
            renderingMode: renderingMode,
            recordedEffect: recordedEffect,
            contentAttachment: attachment
        )
        let carrier: AgentCultureCarrierReference = .oral(
            transmission.transmissionID
        )
        let evidence = try candidate.cultureCarrierEvidence(
            carrier,
            targetID: targetID,
            sourceAgentID: sourceAgentID,
            sourceStance: sourceStance
        )
        let record = try candidate.admitCulturalExposure(
            operationID: operationID,
            requestDigest: requestDigest,
            targetID: targetID,
            sourceAgentID: sourceAgentID,
            sourceStance: sourceStance,
            carrier: carrier,
            carrierEvidence: evidence
        )
        self = candidate
        return (record, transmission)
    }

    /// Admits only a carrier that already contains an exact cultural-content
    /// commitment. Plain oral claims and the current CIV-45/46 carriers fail
    /// closed because their records do not contain that commitment.
    @discardableResult
    public mutating func recordCulturalExposure(
        operationID: String,
        targetID: AgentID,
        sourceAgentID: AgentID,
        practiceID: AgentCulturePracticeID,
        carrier: AgentCultureCarrierReference
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        try validateCultureCarrierInput(carrier)
        let requestDigest = AgentCultureDigest.make([
            "culture-exposure-v1", simulationID.rawValue, operationID,
            targetID.rawValue, sourceAgentID.rawValue, practiceID.rawValue,
            carrier.canonicalText,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        try requireCultureAgent(targetID)
        try requireCultureAgent(sourceAgentID)
        guard targetID != sourceAgentID,
              let sourceStance = cultureStance(
                  for: sourceAgentID, practiceID: practiceID
              ) else {
            throw AgentSessionError.culture(.unknownPractice(practiceID))
        }
        let carrierEvidence = try cultureCarrierEvidence(
            carrier,
            targetID: targetID,
            sourceAgentID: sourceAgentID,
            sourceStance: sourceStance
        )
        var candidate = self
        let record = try candidate.admitCulturalExposure(
            operationID: operationID,
            requestDigest: requestDigest,
            targetID: targetID,
            sourceAgentID: sourceAgentID,
            sourceStance: sourceStance,
            carrier: carrier,
            carrierEvidence: carrierEvidence
        )
        self = candidate
        return record
    }

    /// Adoption and rejection are deterministic consequences of the target's
    /// own exposure and competing-use history. The caller cannot select the
    /// result.
    @discardableResult
    public mutating func considerCulturalPractice(
        operationID: String,
        agentID: AgentID,
        practiceID: AgentCulturePracticeID
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        let requestDigest = AgentCultureDigest.make([
            "culture-consider-v1", simulationID.rawValue, operationID,
            agentID.rawValue, practiceID.rawValue,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        guard let state = distributedCultureState, state.enabled else {
            throw AgentSessionError.culture(.disabled)
        }
        try requireCultureAgent(agentID)
        guard let stance = cultureStance(for: agentID, practiceID: practiceID),
              stance.exposureCount > 0 else {
            throw AgentSessionError.culture(.unknownPractice(practiceID))
        }
        let competitor = strongestCultureCompetitor(
            for: agentID,
            excluding: practiceID,
            competitionKey: stance.practice.form.competitionKey
        )
        let required = state.configuration.adoptionExposureThreshold
            + (competitor?.useCount ?? 0)
        let outcome: AgentCultureDecisionOutcome
        if stance.status == .adopted {
            outcome = .considered
        } else if stance.exposureCount >= required {
            outcome = .adopted
        } else if competitor != nil {
            outcome = .rejected
        } else {
            outcome = .considered
        }
        var candidate = self
        try candidate.prevalidateCultureRows(
            affectedAgentIDs: [agentID], newPracticeFor: []
        )
        let causes = [stance.lastTransitionEventID,
                      competitor?.lastTransitionEventID].compactMap { $0 }.sorted()
        let event = try candidate.requiredCultureEvent(
            kind: .culturePracticeConsidered,
            actorID: agentID,
            subjectID: agentID,
            causes: causes,
            practiceID: practiceID,
            recordID: operationID,
            status: outcome.rawValue,
            detail: requestDigest,
            summary: "cultural practice considered actor=\(agentID.rawValue) result=\(outcome.rawValue)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .considered,
            practice: stance.practice,
            actorID: agentID,
            sourceAgentID: nil,
            carrier: nil,
            carrierEventID: nil,
            carrierContentDigest: nil,
            participantIDs: [],
            witnessIDs: [],
            outcome: outcome,
            competingPracticeID: competitor?.practice.practiceID,
            causes: event.causes,
            tick: candidate.tick,
            eventID: event.eventID
        )
        candidate.insertCultureRecord(record, for: [agentID])
        var updated = candidate.cultureStance(for: agentID, practiceID: practiceID)!
        if outcome == .adopted {
            updated.status = .adopted
            updated.adoptedAtTick = candidate.tick
            updated.adoptedEventID = event.eventID
        } else if outcome == .rejected {
            updated.status = .rejected
        }
        updated.lastTransitionEventID = event.eventID
        candidate.setCultureStance(updated, for: agentID)
        candidate.insertCultureReceipt(for: record)
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
        return record
    }

    /// An enactment requires adopted participants, current settlement/locality
    /// authority, and a structured norm or ritual. Witnesses are exposed but
    /// never automatically adopt.
    @discardableResult
    public mutating func enactCulturalPractice(
        operationID: String,
        practitionerID: AgentID,
        practiceID: AgentCulturePracticeID,
        coParticipantIDs: [AgentID] = [],
        witnessIDs: [AgentID] = []
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        guard let state = distributedCultureState, state.enabled else {
            throw AgentSessionError.culture(.disabled)
        }
        // Public array bounds precede Set construction, sorting, joining and
        // hashing. The practitioner consumes one participant slot.
        guard coParticipantIDs.count
                < state.configuration.maximumParticipantsPerUse,
              witnessIDs.count
                <= state.configuration.maximumWitnessesPerUse else {
            throw AgentSessionError.culture(.invalidState(
                "use participant input bound"
            ))
        }
        let participants = Array(Set([practitionerID] + coParticipantIDs)).sorted()
        let witnesses = Array(Set(witnessIDs)).sorted()
        let requestDigest = AgentCultureDigest.make([
            "culture-use-v1", simulationID.rawValue, operationID,
            practitionerID.rawValue, practiceID.rawValue,
            participants.map(\.rawValue).joined(separator: ","),
            witnesses.map(\.rawValue).joined(separator: ","),
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        guard participants.count == coParticipantIDs.count + 1,
              witnesses.count == witnessIDs.count,
              Set(participants).isDisjoint(with: Set(witnesses)),
              participants.count <= state.configuration.maximumParticipantsPerUse,
              witnesses.count <= state.configuration.maximumWitnessesPerUse else {
            throw AgentSessionError.culture(.invalidState("use participants"))
        }
        for id in participants + witnesses { try requireCultureAgent(id) }
        guard let primary = cultureStance(
            for: practitionerID, practiceID: practiceID
        ), primary.status == .adopted else {
            throw AgentSessionError.culture(.notAdopted(practitionerID, practiceID))
        }
        for id in participants {
            guard let stance = cultureStance(for: id, practiceID: practiceID),
                  stance.status == .adopted,
                  stance.practice == primary.practice else {
                throw AgentSessionError.culture(.notAdopted(id, practiceID))
            }
        }
        if case let .ritual(pattern) = primary.practice.form,
           participants.count < pattern.minimumParticipants {
            throw AgentSessionError.culture(.invalidPractice("ritual quorum"))
        }
        for id in participants where id != practitionerID {
            guard cultureAgentsShareLocalAuthority(practitionerID, id) else {
                throw AgentSessionError.culture(.nonLocal(practitionerID, id))
            }
        }
        for id in witnesses {
            guard cultureAgentsShareLocalAuthority(practitionerID, id) else {
                throw AgentSessionError.culture(.nonLocal(practitionerID, id))
            }
        }
        var candidate = self
        let affected = participants + witnesses
        let newPracticeFor = witnesses.filter {
            candidate.cultureStance(for: $0, practiceID: practiceID) == nil
        }
        try candidate.prevalidateCultureRows(
            affectedAgentIDs: affected,
            newPracticeFor: newPracticeFor
        )
        let causes = participants.compactMap {
            candidate.cultureStance(for: $0, practiceID: practiceID)?
                .adoptedEventID
        }.sorted()
        let event = try candidate.requiredCultureEvent(
            kind: .culturePracticeUsed,
            actorID: practitionerID,
            subjectID: witnesses.first,
            causes: causes,
            practiceID: practiceID,
            recordID: operationID,
            status: "used",
            detail: requestDigest,
            summary: "cultural practice used actor=\(practitionerID.rawValue) participants=\(participants.count) witnesses=\(witnesses.count)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .used,
            practice: primary.practice,
            actorID: practitionerID,
            sourceAgentID: practitionerID,
            carrier: nil,
            carrierEventID: nil,
            carrierContentDigest: nil,
            participantIDs: participants,
            witnessIDs: witnesses,
            outcome: nil,
            competingPracticeID: nil,
            causes: event.causes,
            tick: candidate.tick,
            eventID: event.eventID
        )
        candidate.insertCultureRecord(record, for: affected)
        for id in participants {
            var stance = candidate.cultureStance(for: id, practiceID: practiceID)!
            stance.useCount += 1
            stance.lastUseTick = candidate.tick
            stance.lastTransitionEventID = event.eventID
            candidate.setCultureStance(stance, for: id)
        }
        for id in witnesses {
            candidate.applyCultureExposure(
                practice: primary.practice,
                to: id,
                eventID: event.eventID
            )
        }
        candidate.insertCultureReceipt(for: record)
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
        return record
    }

    /// Continuity is reviewed from the individual's own use history. A more
    /// used competing variant or bounded inactivity can end current use while
    /// leaving the complete prior record intact.
    @discardableResult
    public mutating func reviewCulturalContinuity(
        operationID: String,
        agentID: AgentID,
        practiceID: AgentCulturePracticeID
    ) throws -> AgentCultureRecord {
        try requireCultureOperationID(operationID)
        let requestDigest = AgentCultureDigest.make([
            "culture-continuity-v1", simulationID.rawValue, operationID,
            agentID.rawValue, practiceID.rawValue,
        ].joined(separator: "|"))
        if let existing = try existingCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest
        ) { return existing }
        guard let state = distributedCultureState, state.enabled else {
            throw AgentSessionError.culture(.disabled)
        }
        guard let stance = cultureStance(for: agentID, practiceID: practiceID),
              stance.status == .adopted else {
            throw AgentSessionError.culture(.notAdopted(agentID, practiceID))
        }
        let competitor = strongestCultureCompetitor(
            for: agentID,
            excluding: practiceID,
            competitionKey: stance.practice.form.competitionKey
        )
        let competitorIsStronger = competitor.map {
            $0.useCount > stance.useCount
                || ($0.useCount == stance.useCount
                    && ($0.lastUseTick ?? -1) > (stance.lastUseTick ?? -1))
        } ?? false
        let referenceTick = stance.lastUseTick ?? stance.adoptedAtTick ?? tick
        let inactive = tick - referenceTick
            >= state.configuration.inactivityTicksBeforeDecline
        let outcome: AgentCultureDecisionOutcome = competitorIsStronger
            ? .ceasedSuperseded : (inactive ? .ceasedUnused : .continued)
        var candidate = self
        try candidate.prevalidateCultureRows(
            affectedAgentIDs: [agentID], newPracticeFor: []
        )
        let event = try candidate.requiredCultureEvent(
            kind: .cultureContinuityReviewed,
            actorID: agentID,
            subjectID: agentID,
            causes: [stance.lastTransitionEventID,
                     competitorIsStronger ? competitor?.lastTransitionEventID : nil]
                .compactMap { $0 }.sorted(),
            practiceID: practiceID,
            recordID: operationID,
            status: outcome.rawValue,
            detail: requestDigest,
            summary: "cultural continuity actor=\(agentID.rawValue) result=\(outcome.rawValue)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .continuityReviewed,
            practice: stance.practice,
            actorID: agentID,
            sourceAgentID: nil,
            carrier: nil,
            carrierEventID: nil,
            carrierContentDigest: nil,
            participantIDs: [],
            witnessIDs: [],
            outcome: outcome,
            competingPracticeID: competitorIsStronger
                ? competitor?.practice.practiceID : nil,
            causes: event.causes,
            tick: candidate.tick,
            eventID: event.eventID
        )
        candidate.insertCultureRecord(record, for: [agentID])
        var updated = candidate.cultureStance(for: agentID, practiceID: practiceID)!
        if outcome == .ceasedSuperseded || outcome == .ceasedUnused {
            updated.status = .ceased
        }
        updated.lastTransitionEventID = event.eventID
        candidate.setCultureStance(updated, for: agentID)
        candidate.insertCultureReceipt(for: record)
        try candidate.commitCultureBoundary(causes: [event.eventID])
        try candidate.validateDistributedCultureStateIfInitialized()
        self = candidate
        return record
    }

    public func culturalPrevalence(
        in scope: AgentCultureProjectionScope
    ) throws -> AgentCulturePrevalenceProjection {
        let memberIDs = try cultureProjectionMemberIDs(scope)
        let selected = Set(memberIDs)
        let individuals = distributedCultureState?.individuals.filter {
            selected.contains($0.agentID)
        } ?? []
        var rows: [AgentCulturePracticeID: AgentCulturePrevalenceEntry] = [:]
        var visited = 0
        for individual in individuals {
            for stance in individual.stances {
                visited += 1
                let old = rows[stance.practice.practiceID]
                rows[stance.practice.practiceID] = AgentCulturePrevalenceEntry(
                    practice: stance.practice,
                    exposedCount: (old?.exposedCount ?? 0)
                        + (stance.status == .exposed ? 1 : 0),
                    adoptedCount: (old?.adoptedCount ?? 0)
                        + (stance.status == .adopted ? 1 : 0),
                    rejectedCount: (old?.rejectedCount ?? 0)
                        + (stance.status == .rejected ? 1 : 0),
                    ceasedCount: (old?.ceasedCount ?? 0)
                        + (stance.status == .ceased ? 1 : 0),
                    totalUseCount: (old?.totalUseCount ?? 0) + stance.useCount
                )
            }
        }
        let perIndividual = distributedCultureState?.configuration
            .maximumPracticesPerIndividual ?? 0
        return AgentCulturePrevalenceProjection(
            scope: scope,
            memberIDs: memberIDs,
            entries: rows.values.sorted {
                $0.practice.practiceID < $1.practice.practiceID
            },
            metrics: AgentCultureProjectionMetrics(
                memberCount: memberIDs.count,
                culturalIndividualsVisited: individuals.count,
                stanceRowsVisited: visited,
                maximumStanceRowsVisited: memberIDs.count * perIndividual,
                historicalRowsVisited: 0
            )
        )
    }
}

/// Rebuilds only the cryptographic/causal attestations around an intentionally
/// mutated schema-42 durable state. This test-only seam lets hostile-checkpoint
/// tests prove the semantic validator, instead of stopping at the first stale
/// boundary digest. It does not relax restore and is unavailable to ordinary
/// callers.
@_spi(Testing)
public func reattestCultureDurableStateForTesting(
    _ bytes: Data
) throws -> Data {
    var root = try JSONSerialization.jsonObject(with: bytes) as! [String: Any]
    var cultureObject = root["distributedCultureState"] as! [String: Any]
    let cultureBytes = try JSONSerialization.data(
        withJSONObject: cultureObject,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let culture = try AgentCheckpointCodec.decode(
        AgentDistributedCultureState.self,
        from: cultureBytes
    )
    guard let boundary = culture.boundary,
          var boundaryObject = cultureObject["boundary"] as? [String: Any]
    else {
        throw AgentSessionError.culture(.invalidState(
            "testing culture boundary"
        ))
    }
    let boundaryDigest = cultureBoundaryDigest(culture)
    boundaryObject["digest"] = boundaryDigest
    cultureObject["boundary"] = boundaryObject
    root["distributedCultureState"] = cultureObject

    let ledgerBytes = try JSONSerialization.data(
        withJSONObject: root["causalLedger"]!,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let ledger = try AgentCheckpointCodec.decode(
        AgentCausalLedgerDurableState.self,
        from: ledgerBytes
    )
    guard ledger.droppedEventCount == 0 else {
        throw AgentSessionError.culture(.invalidState(
            "testing reattestation requires complete causal retention"
        ))
    }
    let events = try ledger.events.map { event -> AgentCausalEvent in
        let payload: AgentCausalPayload
        if event.eventID == boundary.eventID {
            guard case let .culture(
                recordID, practiceID, status, _
            ) = event.payload else {
                throw AgentSessionError.culture(.invalidState(
                    "testing culture boundary event"
                ))
            }
            payload = .culture(
                recordID: recordID,
                practiceID: practiceID,
                status: status,
                detail: boundaryDigest
            )
        } else {
            payload = event.payload
        }
        return try AgentCausalEvent(
            id: event.eventID,
            instant: event.instant,
            kind: event.kind,
            origin: event.origin,
            actorID: event.actorID,
            subjectID: event.subjectID,
            operationID: event.operationID,
            causes: event.causes,
            payload: payload,
            summary: event.summary
        )
    }
    let rollingDigest = events.reduce(AgentCausalEvent.digest("")) {
        AgentCausalEvent.digest("\($0)|\($1.digest)")
    }
    let reattestedLedger = AgentCausalLedgerDurableState(
        policy: ledger.policy,
        events: events,
        latestSequence: ledger.latestSequence,
        droppedEventCount: ledger.droppedEventCount,
        rollingDigest: rollingDigest
    )
    root["causalLedger"] = try JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(reattestedLedger)
    )
    return try JSONSerialization.data(
        withJSONObject: root,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
}

extension AgentSimulationSession {
    private struct CultureCarrierEvidence {
        let carrierEventID: AgentCausalEventID
        let sourceStatusEventID: AgentCausalEventID
        let contentDigest: String
    }

    private mutating func admitCulturalExposure(
        operationID: String,
        requestDigest: String,
        targetID: AgentID,
        sourceAgentID: AgentID,
        sourceStance: AgentCultureStance,
        carrier: AgentCultureCarrierReference,
        carrierEvidence: CultureCarrierEvidence
    ) throws -> AgentCultureRecord {
        let practiceID = sourceStance.practice.practiceID
        if let target = cultureIndividual(for: targetID),
           target.history.contains(where: {
               $0.kind == .exposed && $0.practice.practiceID == practiceID
                   && $0.carrier == carrier
           }) {
            throw AgentSessionError.culture(.duplicateCarrier(practiceID))
        }
        try prevalidateCultureRows(
            affectedAgentIDs: [targetID],
            newPracticeFor: cultureStance(
                for: targetID, practiceID: practiceID
            ) == nil ? [targetID] : []
        )
        let causes = [
            carrierEvidence.carrierEventID,
            carrierEvidence.sourceStatusEventID,
        ].sorted()
        let event = try requiredCultureEvent(
            kind: .culturePracticeExposed,
            actorID: sourceAgentID,
            subjectID: targetID,
            causes: causes,
            practiceID: practiceID,
            recordID: operationID,
            status: "exposed",
            detail: requestDigest,
            summary: "cultural exposure \(sourceAgentID.rawValue)>\(targetID.rawValue)"
        )
        let record = AgentCultureRecord(
            operationID: operationID,
            requestDigest: requestDigest,
            kind: .exposed,
            practice: sourceStance.practice,
            actorID: targetID,
            sourceAgentID: sourceAgentID,
            carrier: carrier,
            carrierEventID: carrierEvidence.carrierEventID,
            carrierContentDigest: carrierEvidence.contentDigest,
            participantIDs: [],
            witnessIDs: [],
            outcome: nil,
            competingPracticeID: nil,
            causes: event.causes,
            tick: tick,
            eventID: event.eventID
        )
        insertCultureRecord(record, for: [targetID])
        applyCultureExposure(
            practice: sourceStance.practice,
            to: targetID,
            eventID: event.eventID
        )
        insertCultureReceipt(for: record)
        try commitCultureBoundary(causes: [event.eventID])
        try validateDistributedCultureStateIfInitialized()
        return record
    }

    private func cultureCarrierEvidence(
        _ carrier: AgentCultureCarrierReference,
        targetID: AgentID,
        sourceAgentID: AgentID,
        sourceStance: AgentCultureStance
    ) throws -> CultureCarrierEvidence {
        let authoritySequence: AgentCausalSequence
        let carrierEventID: AgentCausalEventID
        let contentDigest: String
        switch carrier {
        case let .oral(id):
            guard let transmission = oralTransmissionState?.transmissions.first(where: {
                $0.transmissionID == id
            }) else {
                throw AgentSessionError.culture(.unknownCarrier(carrier.canonicalText))
            }
            guard transmission.speakerID == sourceAgentID,
                  transmission.recipientID == targetID,
                  let attachment = transmission.contentAttachment,
                  attachment.namespace == cultureOralContentNamespace,
                  attachment.contentID
                    == sourceStance.practice.practiceID.rawValue,
                  attachment.contentDigest
                    == culturePracticeContentDigest(sourceStance.practice)
            else {
                throw AgentSessionError.culture(.invalidCarrier(carrier.canonicalText))
            }
            authoritySequence = transmission.receiptEventID.sequence
            carrierEventID = transmission.receiptEventID
            contentDigest = attachment.contentDigest
        case let .writingReading(readingID):
            guard let reading = writingState?.readings.first(where: {
                $0.readingID == readingID
            }), let artifact = writingState?.artifacts.first(where: {
                $0.artifactID == reading.artifactID
            }) else {
                throw AgentSessionError.culture(.unknownCarrier(carrier.canonicalText))
            }
            guard reading.readerID == targetID,
                  artifact.plan.authorID == sourceAgentID else {
                throw AgentSessionError.culture(.invalidCarrier(carrier.canonicalText))
            }
            throw AgentSessionError.culture(.invalidCarrier(
                "writing carrier has no cultural-content commitment"
            ))
        case let .archiveRetrieval(operationID):
            guard let retrieval = archiveState?.retrievals.first(where: {
                $0.operationID == operationID
            }), let artifact = writingState?.artifacts.first(where: {
                $0.artifactID == retrieval.artifactID
            }) else {
                throw AgentSessionError.culture(.unknownCarrier(carrier.canonicalText))
            }
            guard retrieval.readerID == targetID,
                  artifact.plan.authorID == sourceAgentID else {
                throw AgentSessionError.culture(.invalidCarrier(carrier.canonicalText))
            }
            throw AgentSessionError.culture(.invalidCarrier(
                "archive carrier has no cultural-content commitment"
            ))
        }
        guard let historical = cultureHistoricalStatus(
            for: sourceAgentID,
            practiceID: sourceStance.practice.practiceID,
            through: authoritySequence
        ), historical.status == .adopted else {
            throw AgentSessionError.culture(
                .notAdopted(sourceAgentID, sourceStance.practice.practiceID)
            )
        }
        return CultureCarrierEvidence(
            carrierEventID: carrierEventID,
            sourceStatusEventID: historical.eventID,
            contentDigest: contentDigest
        )
    }

    private func cultureHistoricalStatus(
        for agentID: AgentID,
        practiceID: AgentCulturePracticeID,
        through sequence: AgentCausalSequence
    ) -> (status: AgentCultureStanceStatus, eventID: AgentCausalEventID)? {
        guard let individual = cultureIndividual(for: agentID) else { return nil }
        var status: AgentCultureStanceStatus?
        var eventID: AgentCausalEventID?
        for record in individual.history where
            record.practice.practiceID == practiceID
                && record.eventID.sequence <= sequence {
            switch record.kind {
            case .originated, .variationCreated:
                status = .adopted
                eventID = record.eventID
            case .exposed:
                if status == nil { status = .exposed; eventID = record.eventID }
            case .considered:
                if record.outcome == .adopted {
                    status = .adopted; eventID = record.eventID
                } else if record.outcome == .rejected {
                    status = .rejected; eventID = record.eventID
                }
            case .continuityReviewed:
                if record.outcome == .ceasedUnused
                    || record.outcome == .ceasedSuperseded {
                    status = .ceased; eventID = record.eventID
                }
            case .used:
                break
            }
        }
        guard let status, let eventID else { return nil }
        return (status, eventID)
    }

    private func cultureIndividual(
        for agentID: AgentID
    ) -> AgentCultureIndividualState? {
        distributedCultureState?.individuals.first { $0.agentID == agentID }
    }

    private func cultureStance(
        for agentID: AgentID,
        practiceID: AgentCulturePracticeID
    ) -> AgentCultureStance? {
        cultureIndividual(for: agentID)?.stances.first {
            $0.practice.practiceID == practiceID
        }
    }

    private mutating func setCultureStance(
        _ stance: AgentCultureStance,
        for agentID: AgentID
    ) {
        let individualIndex = distributedCultureState!.individuals.firstIndex {
            $0.agentID == agentID
        }!
        if let stanceIndex = distributedCultureState!.individuals[individualIndex]
            .stances.firstIndex(where: {
                $0.practice.practiceID == stance.practice.practiceID
            }) {
            distributedCultureState!.individuals[individualIndex]
                .stances[stanceIndex] = stance
        } else {
            distributedCultureState!.individuals[individualIndex]
                .stances.append(stance)
        }
        distributedCultureState!.individuals[individualIndex].stances.sort {
            $0.practice.practiceID < $1.practice.practiceID
        }
    }

    private mutating func insertCultureRecord(
        _ record: AgentCultureRecord,
        for agentIDs: [AgentID]
    ) {
        for agentID in Array(Set(agentIDs)).sorted() {
            if distributedCultureState!.individuals.firstIndex(where: {
                $0.agentID == agentID
            }) == nil {
                distributedCultureState!.individuals.append(
                    AgentCultureIndividualState(
                        agentID: agentID, stances: [], history: []
                    )
                )
                distributedCultureState!.individuals.sort { $0.agentID < $1.agentID }
            }
            let index = distributedCultureState!.individuals.firstIndex {
                $0.agentID == agentID
            }!
            distributedCultureState!.individuals[index].history.append(record)
            distributedCultureState!.individuals[index].history.sort {
                $0.eventID < $1.eventID
            }
        }
    }

    private mutating func insertCultureReceipt(for record: AgentCultureRecord) {
        distributedCultureState!.operationReceipts.append(
            AgentCultureOperationReceipt(
                operationID: record.operationID,
                requestDigest: record.requestDigest,
                eventID: record.eventID,
                recordHolderID: record.actorID
            )
        )
        distributedCultureState!.operationReceipts.sort {
            $0.operationID < $1.operationID
        }
    }

    private mutating func applyCultureExposure(
        practice: AgentCulturePractice,
        to agentID: AgentID,
        eventID: AgentCausalEventID
    ) {
        var stance = cultureStance(for: agentID, practiceID: practice.practiceID)
            ?? AgentCultureStance(
                practice: practice,
                status: .exposed,
                exposureCount: 0,
                useCount: 0,
                lastExposureTick: nil,
                lastUseTick: nil,
                adoptedAtTick: nil,
                adoptedEventID: nil,
                lastTransitionEventID: eventID
            )
        stance.exposureCount += 1
        stance.lastExposureTick = tick
        stance.lastTransitionEventID = eventID
        setCultureStance(stance, for: agentID)
    }

    private func strongestCultureCompetitor(
        for agentID: AgentID,
        excluding practiceID: AgentCulturePracticeID,
        competitionKey: String
    ) -> AgentCultureStance? {
        cultureIndividual(for: agentID)?.stances.filter {
            $0.practice.practiceID != practiceID
                && $0.practice.form.competitionKey == competitionKey
                && $0.status == .adopted
        }.sorted {
            if $0.useCount != $1.useCount { return $0.useCount > $1.useCount }
            if ($0.lastUseTick ?? -1) != ($1.lastUseTick ?? -1) {
                return ($0.lastUseTick ?? -1) > ($1.lastUseTick ?? -1)
            }
            return $0.practice.practiceID < $1.practice.practiceID
        }.first
    }

    private func cultureAgentsShareLocalAuthority(
        _ first: AgentID,
        _ second: AgentID
    ) -> Bool {
        guard let registry = populationRegistry,
              let firstMember = registry.members.first(where: {
                  $0.agentID == first
              }), let secondMember = registry.members.first(where: {
                  $0.agentID == second
              }), firstMember.settlementID == secondMember.settlementID else {
            return false
        }
        return canUseDirectSocialCommunicationAuthority(
            speakerID: first, recipientID: second
        )
    }

    private func cultureProjectionMemberIDs(
        _ scope: AgentCultureProjectionScope
    ) throws -> [AgentID] {
        switch scope {
        case let .settlement(id):
            guard let settlement = populationRegistry?.settlement(withID: id) else {
                throw AgentSessionError.culture(.invalidState("projection settlement"))
            }
            return settlement.residentIDs.sorted()
        case let .household(id):
            guard let household = householdState,
                  household.households.contains(where: { $0.householdID == id }) else {
                throw AgentSessionError.culture(.invalidState("projection household"))
            }
            return household.membershipPeriods.filter {
                $0.householdID == id && $0.leftTick == nil
            }.map(\.agentID).sorted()
        case let .house(id):
            guard let family = familyState,
                  family.houses.contains(where: { $0.houseID == id }) else {
                throw AgentSessionError.culture(.invalidState("projection house"))
            }
            return family.houseMembershipPeriods.filter {
                $0.houseID == id && $0.leftTick == nil
            }.map(\.agentID).sorted()
        case let .individuals(ids):
            let maximum = distributedCultureState?.configuration
                .maximumIndividuals ?? AgentCultureConfiguration.live
                .maximumIndividuals
            // Refuse an oversized public input before sorting, Set
            // construction or per-identity authority lookup.
            guard ids.count <= maximum else {
                throw AgentSessionError.culture(.invalidState(
                    "projection individual input bound"
                ))
            }
            let sorted = ids.sorted()
            guard
                  Set(sorted).count == sorted.count else {
                throw AgentSessionError.culture(.invalidState("projection individuals"))
            }
            for id in sorted { try requireCultureAgent(id) }
            return sorted
        }
    }

    private func culturePracticeID(
        operationID: String,
        originatorID: AgentID,
        form: AgentCulturePracticeForm,
        parentID: AgentCulturePracticeID?
    ) -> AgentCulturePracticeID {
        AgentCulturePracticeID(
            rawValue: "practice-" + AgentCultureDigest.make([
                "culture-practice-id-v1", simulationID.rawValue, operationID,
                originatorID.rawValue, form.canonicalText,
                parentID?.rawValue ?? "root",
            ].joined(separator: "|"))
        )!
    }

    private func requireCultureOperationID(_ operationID: String) throws {
        guard cultureIdentifierIsValid(operationID, maximum: 128) else {
            throw AgentSessionError.culture(.invalidOperationID(operationID))
        }
    }

    private func validateCultureCarrierInput(
        _ carrier: AgentCultureCarrierReference
    ) throws {
        switch carrier {
        case .oral:
            return
        case let .writingReading(identifier),
             let .archiveRetrieval(identifier):
            guard cultureIdentifierIsValid(identifier, maximum: 192) else {
                throw AgentSessionError.culture(.invalidCarrier(
                    "carrier identifier"
                ))
            }
        }
    }

    private func requireCultureAgent(_ agentID: AgentID) throws {
        guard statesById[agentID.rawValue] != nil,
              populationRegistry?.members.contains(where: {
                  $0.agentID == agentID
                      && $0.status != .migrating
              }) == true else {
            throw AgentSessionError.culture(.unknownAgent(agentID))
        }
    }

    private func existingCultureRecord(
        operationID: String,
        requestDigest: String
    ) throws -> AgentCultureRecord? {
        guard let state = distributedCultureState,
              let receipt = state.operationReceipts.first(where: {
                  $0.operationID == operationID
              }) else { return nil }
        guard receipt.requestDigest == requestDigest else {
            throw AgentSessionError.culture(.conflictingRetry(operationID))
        }
        guard let holder = state.individuals.first(where: {
                  $0.agentID == receipt.recordHolderID
              }), let record = holder.history.first(where: {
                  $0.operationID == operationID
              }), record.eventID == receipt.eventID else {
            throw AgentSessionError.culture(.invalidState("operation receipt"))
        }
        return record
    }

    private mutating func prevalidateCultureRows(
        affectedAgentIDs: [AgentID],
        newPracticeFor: [AgentID]
    ) throws {
        guard let state = distributedCultureState, state.enabled else {
            throw AgentSessionError.culture(.disabled)
        }
        guard affectedAgentIDs.count
                <= state.configuration.maximumParticipantsPerUse
                    + state.configuration.maximumWitnessesPerUse,
              newPracticeFor.count
                <= state.configuration.maximumIndividuals else {
            throw AgentSessionError.culture(.capacityReached(
                "culture row input bound"
            ))
        }
        let affected = Array(Set(affectedAgentIDs)).sorted()
        let newIndividuals = affected.filter { cultureIndividual(for: $0) == nil }
        guard state.individuals.count + newIndividuals.count
                <= state.configuration.maximumIndividuals,
              state.operationReceipts.count
                < state.configuration.maximumOperationReceipts else {
            throw AgentSessionError.culture(.capacityReached("individuals or operations"))
        }
        for agentID in affected {
            let individual = cultureIndividual(for: agentID)
            guard (individual?.history.count ?? 0)
                    < state.configuration.maximumHistoryPerIndividual else {
                throw AgentSessionError.culture(.capacityReached("individual history"))
            }
        }
        for agentID in Set(newPracticeFor) {
            guard (cultureIndividual(for: agentID)?.stances.count ?? 0)
                    < state.configuration.maximumPracticesPerIndividual else {
                throw AgentSessionError.culture(.capacityReached("individual practices"))
            }
        }
    }

    @discardableResult
    private mutating func requiredCultureEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        practiceID: AgentCulturePracticeID?,
        recordID: String,
        status: String,
        detail: String,
        summary: String
    ) throws -> AgentCausalEvent {
        guard causes.count <= AgentCausalEvent.maximumCauseCount else {
            throw AgentSessionError.culture(.invalidState(
                "culture causal input bound"
            ))
        }
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .cultureTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: Array(Set(causes)).sorted(),
            payload: .culture(
                recordID: recordID,
                practiceID: practiceID?.rawValue,
                status: status,
                detail: detail
            ),
            summary: summary
        ) else {
            throw AgentSessionError.culture(.causalLedgerRequired)
        }
        return event
    }

    mutating func commitCultureBoundary(
        causes: [AgentCausalEventID]
    ) throws {
        guard var state = distributedCultureState else { return }
        let digest = cultureBoundaryDigest(state)
        let causal = Array(Set(causes + (state.boundary.map { [$0.eventID] } ?? [])))
            .sorted()
        let event = try requiredCultureEvent(
            kind: .cultureProvenanceBoundary,
            actorID: nil,
            subjectID: nil,
            causes: Array(causal.suffix(AgentCausalEvent.maximumCauseCount)),
            practiceID: nil,
            recordID: "distributed-culture",
            status: "provenanceBoundary",
            detail: digest,
            summary: "distributed culture provenance boundary"
        )
        state = distributedCultureState ?? state
        state.boundary = AgentCultureBoundary(
            eventID: event.eventID, digest: digest
        )
        distributedCultureState = state
    }

    private func prevalidateCultureEncodedInputBounds(
        _ state: AgentDistributedCultureState
    ) throws {
        try state.configuration.validate()
        guard state.individuals.count <= state.configuration.maximumIndividuals,
              state.operationReceipts.count
                <= state.configuration.maximumOperationReceipts,
              state.boundary.map({ cultureDigestIsValid($0.digest) }) ?? false
        else {
            throw AgentSessionError.culture(.invalidState(
                "encoded culture input bound"
            ))
        }
        for individual in state.individuals {
            guard individual.stances.count
                    <= state.configuration.maximumPracticesPerIndividual,
                  individual.history.count
                    <= state.configuration.maximumHistoryPerIndividual else {
                throw AgentSessionError.culture(.invalidState(
                    "encoded individual input bound"
                ))
            }
            for stance in individual.stances {
                try validateCulturePractice(stance.practice)
            }
            for record in individual.history {
                guard cultureIdentifierIsValid(
                        record.operationID, maximum: 128
                      ),
                      cultureDigestIsValid(record.requestDigest),
                      record.participantIDs.count
                        <= state.configuration.maximumParticipantsPerUse,
                      record.witnessIDs.count
                        <= state.configuration.maximumWitnessesPerUse,
                      record.causes.count <= AgentCausalEvent.maximumCauseCount,
                      record.carrierContentDigest.map(cultureDigestIsValid)
                        ?? true else {
                    throw AgentSessionError.culture(.invalidState(
                        "encoded history input bound"
                    ))
                }
                try validateCulturePractice(record.practice)
                if let carrier = record.carrier {
                    try validateCultureCarrierInput(carrier)
                }
            }
        }
        for receipt in state.operationReceipts {
            guard cultureIdentifierIsValid(
                    receipt.operationID, maximum: 128
                  ), cultureDigestIsValid(receipt.requestDigest) else {
                throw AgentSessionError.culture(.invalidState(
                    "encoded receipt input bound"
                ))
            }
        }
    }

    func validateCultureBoundary() throws {
        guard let state = distributedCultureState else { return }
        // Check every caller-controlled collection and string before encoding
        // the complete state for its boundary digest.
        try prevalidateCultureEncodedInputBounds(state)
        guard let boundary = state.boundary,
              boundary.digest == cultureBoundaryDigest(state),
              let event = causalLedger.events.first(where: {
                  $0.eventID == boundary.eventID
              }), event.kind == .cultureProvenanceBoundary,
              event.origin == .cultureTransition,
              case let .culture(recordID, practiceID, status, detail) = event.payload,
              recordID == "distributed-culture", practiceID == nil,
              status == "provenanceBoundary", detail == boundary.digest else {
            throw AgentSessionError.culture(.invalidState("provenance boundary"))
        }
    }

    func validateDistributedCultureStateIfInitialized() throws {
        guard let state = distributedCultureState else { return }
        try state.configuration.validate()
        try validateCultureBoundary()
        guard populationRegistry != nil,
              state.individuals.count <= state.configuration.maximumIndividuals,
              state.operationReceipts.count
                <= state.configuration.maximumOperationReceipts,
              state.individuals == state.individuals.sorted(by: {
                  $0.agentID < $1.agentID
              }), Set(state.individuals.map(\.agentID)).count
                == state.individuals.count,
              state.operationReceipts == state.operationReceipts.sorted(by: {
                  $0.operationID < $1.operationID
              }), Set(state.operationReceipts.map(\.operationID)).count
                == state.operationReceipts.count else {
            throw AgentSessionError.culture(.invalidState("bounds or ordering"))
        }
        var practices: [AgentCulturePracticeID: AgentCulturePractice] = [:]
        var records: [String: AgentCultureRecord] = [:]
        var holders: [String: Set<AgentID>] = [:]
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        let activeOrHistoricallyDepartedAgentIDs = Set(
            statesById.values.map(\.agentID)
        ).union(mortalityState?.records.map(\.agentID) ?? [])
            .union(mortalityState?.compactedDeathSummaries?.map(\.agentID) ?? [])
        for individual in state.individuals {
            // Mortality owns removal from the active population. Culture keeps
            // the bounded individual row as historical evidence; accepting a
            // mortality-owned departed identity does not make it active or
            // include it in a settlement prevalence projection.
            guard activeOrHistoricallyDepartedAgentIDs.contains(individual.agentID),
                  individual.stances.count
                    <= state.configuration.maximumPracticesPerIndividual,
                  individual.history.count
                    <= state.configuration.maximumHistoryPerIndividual,
                  individual.stances == individual.stances.sorted(by: {
                      $0.practice.practiceID < $1.practice.practiceID
                  }), Set(individual.stances.map { $0.practice.practiceID }).count
                    == individual.stances.count,
                  individual.history == individual.history.sorted(by: {
                      $0.eventID < $1.eventID
                  }) else {
                throw AgentSessionError.culture(.invalidState("individual state"))
            }
            for stance in individual.stances {
                try validateCulturePractice(stance.practice)
                guard stance.exposureCount >= 0, stance.useCount >= 0,
                      stance.lastTransitionEventID.simulationID == simulationID,
                      stance.lastTransitionEventID.sequence.rawValue
                        <= causalLedger.latestSequence,
                      (stance.status == .adopted || stance.status == .ceased)
                        == (stance.adoptedEventID != nil),
                      (stance.adoptedEventID == nil)
                        == (stance.adoptedAtTick == nil),
                      stance.lastExposureTick.map({ $0 <= tick }) ?? true,
                      stance.lastUseTick.map({ $0 <= tick }) ?? true,
                      stance.adoptedAtTick.map({ $0 <= tick }) ?? true else {
                    throw AgentSessionError.culture(.invalidState("stance"))
                }
                if let existing = practices[stance.practice.practiceID],
                   existing != stance.practice {
                    throw AgentSessionError.culture(.invalidState("practice identity"))
                }
                practices[stance.practice.practiceID] = stance.practice
            }
            for record in individual.history {
                try validateCulturePractice(record.practice)
                guard cultureIdentifierIsValid(record.operationID, maximum: 128),
                      cultureDigestIsValid(record.requestDigest),
                      record.tick >= 0, record.tick <= tick,
                      record.eventID.simulationID == simulationID,
                      record.eventID.sequence.rawValue <= causalLedger.latestSequence else {
                    throw AgentSessionError.culture(.invalidState("history record"))
                }
                try validateCultureRecordShape(record)
                try validateCultureRecordCausalEvent(
                    record, retainedEvents: retainedEvents
                )
                try validateCultureCarrierProvenance(
                    record, retainedEvents: retainedEvents
                )
                if let existing = records[record.operationID], existing != record {
                    throw AgentSessionError.culture(.invalidState("operation collision"))
                }
                records[record.operationID] = record
                holders[record.operationID, default: []].insert(individual.agentID)
                if let existing = practices[record.practice.practiceID],
                   existing != record.practice {
                    throw AgentSessionError.culture(.invalidState("practice record"))
                }
                practices[record.practice.practiceID] = record.practice
            }
            try validateCultureIndividualDerivedState(individual)
        }
        try validateCultureCausalSemantics(
            records.values.sorted { $0.eventID < $1.eventID }
        )
        guard records.count == state.operationReceipts.count else {
            throw AgentSessionError.culture(.invalidState("operation count"))
        }
        for receipt in state.operationReceipts {
            guard let record = records[receipt.operationID],
                  receipt.requestDigest == record.requestDigest,
                  receipt.eventID == record.eventID,
                  holders[receipt.operationID]?.contains(receipt.recordHolderID)
                    == true else {
                throw AgentSessionError.culture(.invalidState("operation receipt"))
            }
            let expectedHolders: Set<AgentID>
            switch record.kind {
            case .used:
                expectedHolders = Set(record.participantIDs + record.witnessIDs)
            default:
                expectedHolders = [record.actorID]
            }
            guard holders[record.operationID] == expectedHolders else {
                throw AgentSessionError.culture(.invalidState("distributed record holders"))
            }
        }
        for practice in practices.values {
            if let parentID = practice.parentPracticeID {
                guard let parent = practices[parentID],
                      practice.generation == parent.generation + 1,
                      practice.rootPracticeID == parent.rootPracticeID,
                      practice.form.competitionKey
                        == parent.form.competitionKey,
                      practice.form != parent.form else {
                    throw AgentSessionError.culture(.invalidState("variation lineage"))
                }
            }
        }
    }

    private struct CultureHistoricalCursor {
        var stance: AgentCultureStance
        var statusEventID: AgentCausalEventID
    }

    /// Replays each unique distributed record once, in causal order. This is
    /// validation only: it proves that retained record causes are the exact
    /// individual histories the live transition would have selected, even if
    /// a hostile checkpoint consistently alters both a record and its ledger
    /// event. Work is bounded by retained operation receipts and sparse
    /// per-individual practice rows; there is no agents-by-practices scan.
    private func validateCultureCausalSemantics(
        _ records: [AgentCultureRecord]
    ) throws {
        guard let configuration = distributedCultureState?.configuration,
              records.count <= configuration.maximumOperationReceipts else {
            throw AgentSessionError.culture(.invalidState(
                "culture causal validation bound"
            ))
        }
        var cursors: [AgentID: [AgentCulturePracticeID: CultureHistoricalCursor]]
            = [:]

        func strongestCompetitor(
            for agentID: AgentID,
            excluding practiceID: AgentCulturePracticeID,
            competitionKey: String
        ) -> CultureHistoricalCursor? {
            cursors[agentID]?.values.filter {
                $0.stance.practice.practiceID != practiceID
                    && $0.stance.practice.form.competitionKey == competitionKey
                    && $0.stance.status == .adopted
            }.sorted {
                if $0.stance.useCount != $1.stance.useCount {
                    return $0.stance.useCount > $1.stance.useCount
                }
                if ($0.stance.lastUseTick ?? -1)
                    != ($1.stance.lastUseTick ?? -1) {
                    return ($0.stance.lastUseTick ?? -1)
                        > ($1.stance.lastUseTick ?? -1)
                }
                return $0.stance.practice.practiceID
                    < $1.stance.practice.practiceID
            }.first
        }

        func publish(
            _ cursor: CultureHistoricalCursor,
            for agentID: AgentID
        ) {
            cursors[agentID, default: [:]][
                cursor.stance.practice.practiceID
            ] = cursor
        }

        for record in records {
            let practiceID = record.practice.practiceID
            switch record.kind {
            case .originated:
                guard cursors[record.actorID]?[practiceID] == nil,
                      record.causes.isEmpty else {
                    throw AgentSessionError.culture(.invalidState(
                        "origin causal history"
                    ))
                }
                publish(CultureHistoricalCursor(
                    stance: AgentCultureStance(
                        practice: record.practice,
                        status: .adopted,
                        exposureCount: 0,
                        useCount: 0,
                        lastExposureTick: nil,
                        lastUseTick: nil,
                        adoptedAtTick: record.tick,
                        adoptedEventID: record.eventID,
                        lastTransitionEventID: record.eventID
                    ),
                    statusEventID: record.eventID
                ), for: record.actorID)

            case .variationCreated:
                guard let parentID = record.practice.parentPracticeID,
                      let parent = cursors[record.actorID]?[parentID],
                      parent.stance.status == .adopted,
                      record.causes == [parent.stance.lastTransitionEventID],
                      cursors[record.actorID]?[practiceID] == nil else {
                    throw AgentSessionError.culture(.invalidState(
                        "variation causal history"
                    ))
                }
                publish(CultureHistoricalCursor(
                    stance: AgentCultureStance(
                        practice: record.practice,
                        status: .adopted,
                        exposureCount: 0,
                        useCount: 0,
                        lastExposureTick: nil,
                        lastUseTick: nil,
                        adoptedAtTick: record.tick,
                        adoptedEventID: record.eventID,
                        lastTransitionEventID: record.eventID
                    ),
                    statusEventID: record.eventID
                ), for: record.actorID)

            case .exposed:
                guard let sourceAgentID = record.sourceAgentID,
                      let source = cursors[sourceAgentID]?[practiceID],
                      source.stance.status == .adopted,
                      let carrierEventID = record.carrierEventID,
                      record.causes
                        == [carrierEventID, source.statusEventID].sorted()
                else {
                    throw AgentSessionError.culture(.invalidState(
                        "exposure causal history"
                    ))
                }
                var target = cursors[record.actorID]?[practiceID]
                    ?? CultureHistoricalCursor(
                        stance: AgentCultureStance(
                            practice: record.practice,
                            status: .exposed,
                            exposureCount: 0,
                            useCount: 0,
                            lastExposureTick: nil,
                            lastUseTick: nil,
                            adoptedAtTick: nil,
                            adoptedEventID: nil,
                            lastTransitionEventID: record.eventID
                        ),
                        statusEventID: record.eventID
                    )
                target.stance.exposureCount += 1
                target.stance.lastExposureTick = record.tick
                target.stance.lastTransitionEventID = record.eventID
                if target.stance.status == .exposed {
                    target.statusEventID = record.eventID
                }
                publish(target, for: record.actorID)

            case .considered:
                guard var target = cursors[record.actorID]?[practiceID] else {
                    throw AgentSessionError.culture(.invalidState(
                        "consideration causal history"
                    ))
                }
                let competitor = strongestCompetitor(
                    for: record.actorID,
                    excluding: practiceID,
                    competitionKey: target.stance.practice.form.competitionKey
                )
                let required = configuration.adoptionExposureThreshold
                    + (competitor?.stance.useCount ?? 0)
                let expectedOutcome: AgentCultureDecisionOutcome
                if target.stance.status == .adopted {
                    expectedOutcome = .considered
                } else if target.stance.exposureCount >= required {
                    expectedOutcome = .adopted
                } else if competitor != nil {
                    expectedOutcome = .rejected
                } else {
                    expectedOutcome = .considered
                }
                let expectedCauses = [
                    target.stance.lastTransitionEventID,
                    competitor?.stance.lastTransitionEventID,
                ].compactMap { $0 }.sorted()
                guard record.outcome == expectedOutcome,
                      record.competingPracticeID
                        == competitor?.stance.practice.practiceID,
                      record.causes == expectedCauses else {
                    throw AgentSessionError.culture(.invalidState(
                        "consideration causal decision"
                    ))
                }
                if expectedOutcome == .adopted {
                    target.stance.status = .adopted
                    target.stance.adoptedAtTick = record.tick
                    target.stance.adoptedEventID = record.eventID
                    target.statusEventID = record.eventID
                } else if expectedOutcome == .rejected {
                    target.stance.status = .rejected
                    target.statusEventID = record.eventID
                }
                target.stance.lastTransitionEventID = record.eventID
                publish(target, for: record.actorID)

            case .used:
                var participants: [AgentID: CultureHistoricalCursor] = [:]
                for participantID in record.participantIDs {
                    guard let participant = cursors[participantID]?[practiceID],
                          participant.stance.status == .adopted,
                          participant.stance.practice == record.practice,
                          participant.stance.adoptedEventID != nil else {
                        throw AgentSessionError.culture(.invalidState(
                            "use participant causal history"
                        ))
                    }
                    participants[participantID] = participant
                }
                guard record.causes == participants.values.compactMap({
                    $0.stance.adoptedEventID
                }).sorted() else {
                    throw AgentSessionError.culture(.invalidState(
                        "use causal links"
                    ))
                }
                for participantID in record.participantIDs {
                    var participant = participants[participantID]!
                    participant.stance.useCount += 1
                    participant.stance.lastUseTick = record.tick
                    participant.stance.lastTransitionEventID = record.eventID
                    publish(participant, for: participantID)
                }
                for witnessID in record.witnessIDs {
                    var witness = cursors[witnessID]?[practiceID]
                        ?? CultureHistoricalCursor(
                            stance: AgentCultureStance(
                                practice: record.practice,
                                status: .exposed,
                                exposureCount: 0,
                                useCount: 0,
                                lastExposureTick: nil,
                                lastUseTick: nil,
                                adoptedAtTick: nil,
                                adoptedEventID: nil,
                                lastTransitionEventID: record.eventID
                            ),
                            statusEventID: record.eventID
                        )
                    witness.stance.exposureCount += 1
                    witness.stance.lastExposureTick = record.tick
                    witness.stance.lastTransitionEventID = record.eventID
                    if witness.stance.status == .exposed {
                        witness.statusEventID = record.eventID
                    }
                    publish(witness, for: witnessID)
                }

            case .continuityReviewed:
                guard var target = cursors[record.actorID]?[practiceID],
                      target.stance.status == .adopted else {
                    throw AgentSessionError.culture(.invalidState(
                        "continuity causal history"
                    ))
                }
                let competitor = strongestCompetitor(
                    for: record.actorID,
                    excluding: practiceID,
                    competitionKey: target.stance.practice.form.competitionKey
                )
                let competitorIsStronger = competitor.map {
                    $0.stance.useCount > target.stance.useCount
                        || ($0.stance.useCount == target.stance.useCount
                            && ($0.stance.lastUseTick ?? -1)
                                > (target.stance.lastUseTick ?? -1))
                } ?? false
                let referenceTick = target.stance.lastUseTick
                    ?? target.stance.adoptedAtTick ?? record.tick
                let inactive = record.tick - referenceTick
                    >= configuration.inactivityTicksBeforeDecline
                let expectedOutcome: AgentCultureDecisionOutcome =
                    competitorIsStronger ? .ceasedSuperseded
                        : (inactive ? .ceasedUnused : .continued)
                let expectedCauses = [
                    target.stance.lastTransitionEventID,
                    competitorIsStronger
                        ? competitor?.stance.lastTransitionEventID : nil,
                ].compactMap { $0 }.sorted()
                guard record.outcome == expectedOutcome,
                      record.competingPracticeID
                        == (competitorIsStronger
                            ? competitor?.stance.practice.practiceID : nil),
                      record.causes == expectedCauses else {
                    throw AgentSessionError.culture(.invalidState(
                        "continuity causal decision"
                    ))
                }
                if expectedOutcome == .ceasedSuperseded
                    || expectedOutcome == .ceasedUnused {
                    target.stance.status = .ceased
                    target.statusEventID = record.eventID
                }
                target.stance.lastTransitionEventID = record.eventID
                publish(target, for: record.actorID)
            }
        }

        for individual in distributedCultureState?.individuals ?? [] {
            guard cursors[individual.agentID]?.values.map(\.stance).sorted(by: {
                $0.practice.practiceID < $1.practice.practiceID
            }) == individual.stances else {
                throw AgentSessionError.culture(.invalidState(
                    "causal replayed cultural stance"
                ))
            }
        }
    }

    private func validateCultureRecordShape(
        _ record: AgentCultureRecord
    ) throws {
        guard record.causes == record.causes.sorted(),
              Set(record.causes).count == record.causes.count,
              record.causes.allSatisfy({
                  $0.simulationID == simulationID
                      && $0.sequence < record.eventID.sequence
              }),
              record.participantIDs == record.participantIDs.sorted(),
              Set(record.participantIDs).count
                == record.participantIDs.count,
              record.witnessIDs == record.witnessIDs.sorted(),
              Set(record.witnessIDs).count == record.witnessIDs.count,
              Set(record.participantIDs).isDisjoint(
                with: Set(record.witnessIDs)
              ) else {
            throw AgentSessionError.culture(.invalidState("record shape"))
        }
        switch record.kind {
        case .originated:
            guard record.practice.originatorID == record.actorID,
                  record.practice.originOperationID == record.operationID,
                  record.practice.parentPracticeID == nil,
                  record.sourceAgentID == nil,
                  record.carrier == nil,
                  record.carrierEventID == nil,
                  record.carrierContentDigest == nil,
                  record.participantIDs.isEmpty,
                  record.witnessIDs.isEmpty,
                  record.outcome == .adopted,
                  record.competingPracticeID == nil,
                  record.causes.isEmpty else {
                throw AgentSessionError.culture(.invalidState(
                    "origin record"
                ))
            }
        case .variationCreated:
            guard record.practice.originatorID == record.actorID,
                  record.practice.originOperationID == record.operationID,
                  record.practice.parentPracticeID
                    == record.competingPracticeID,
                  record.sourceAgentID == record.actorID,
                  record.carrier == nil,
                  record.carrierEventID == nil,
                  record.carrierContentDigest == nil,
                  record.participantIDs.isEmpty,
                  record.witnessIDs.isEmpty,
                  record.outcome == .adopted,
                  record.causes.count == 1 else {
                throw AgentSessionError.culture(.invalidState(
                    "variation record"
                ))
            }
        case .exposed:
            guard let sourceAgentID = record.sourceAgentID,
                  sourceAgentID != record.actorID,
                  case .oral? = record.carrier,
                  let carrierEventID = record.carrierEventID,
                  record.causes.contains(carrierEventID),
                  record.carrierContentDigest
                    == culturePracticeContentDigest(record.practice),
                  record.participantIDs.isEmpty,
                  record.witnessIDs.isEmpty,
                  record.outcome == nil,
                  record.competingPracticeID == nil,
                  record.causes.count == 2 else {
                throw AgentSessionError.culture(.invalidState(
                    "exposure record"
                ))
            }
        case .considered:
            guard record.sourceAgentID == nil,
                  record.carrier == nil,
                  record.carrierEventID == nil,
                  record.carrierContentDigest == nil,
                  record.participantIDs.isEmpty,
                  record.witnessIDs.isEmpty,
                  record.outcome == .considered
                    || record.outcome == .adopted
                    || record.outcome == .rejected,
                  record.causes.count
                    == (record.competingPracticeID == nil ? 1 : 2),
                  record.outcome != .rejected
                    || record.competingPracticeID != nil else {
                throw AgentSessionError.culture(.invalidState(
                    "consideration record"
                ))
            }
        case .used:
            guard record.sourceAgentID == record.actorID,
                  record.carrier == nil,
                  record.carrierEventID == nil,
                  record.carrierContentDigest == nil,
                  record.participantIDs.contains(record.actorID),
                  record.outcome == nil,
                  record.competingPracticeID == nil,
                  record.causes.count == record.participantIDs.count else {
                throw AgentSessionError.culture(.invalidState("use record"))
            }
        case .continuityReviewed:
            guard record.sourceAgentID == nil,
                  record.carrier == nil,
                  record.carrierEventID == nil,
                  record.carrierContentDigest == nil,
                  record.participantIDs.isEmpty,
                  record.witnessIDs.isEmpty,
                  record.outcome == .continued
                    || record.outcome == .ceasedUnused
                    || record.outcome == .ceasedSuperseded,
                  (record.outcome == .ceasedSuperseded)
                    == (record.competingPracticeID != nil),
                  record.causes.count
                    == (record.competingPracticeID == nil ? 1 : 2) else {
                throw AgentSessionError.culture(.invalidState(
                    "continuity record"
                ))
            }
        }
    }

    private func validateCultureRecordCausalEvent(
        _ record: AgentCultureRecord,
        retainedEvents: [AgentCausalEventID: AgentCausalEvent]
    ) throws {
        guard let event = retainedEvents[record.eventID] else {
            guard causalLedger.droppedEventCount > 0,
                  let firstRetained = causalLedger.events.first?.eventID,
                  record.eventID < firstRetained,
                  let boundary = distributedCultureState?.boundary,
                  record.eventID < boundary.eventID else {
                throw AgentSessionError.culture(.invalidState(
                    "missing culture causal event"
                ))
            }
            return
        }
        let expectedKind: AgentCausalEventKind
        let expectedActor: AgentID?
        let expectedSubject: AgentID?
        let expectedStatus: String
        switch record.kind {
        case .originated:
            expectedKind = .culturePracticeOriginated
            expectedActor = record.actorID
            expectedSubject = record.actorID
            expectedStatus = AgentCultureDecisionOutcome.adopted.rawValue
        case .variationCreated:
            expectedKind = .cultureVariationCreated
            expectedActor = record.actorID
            expectedSubject = record.actorID
            expectedStatus = AgentCultureDecisionOutcome.adopted.rawValue
        case .exposed:
            expectedKind = .culturePracticeExposed
            expectedActor = record.sourceAgentID
            expectedSubject = record.actorID
            expectedStatus = "exposed"
        case .considered:
            expectedKind = .culturePracticeConsidered
            expectedActor = record.actorID
            expectedSubject = record.actorID
            expectedStatus = record.outcome!.rawValue
        case .used:
            expectedKind = .culturePracticeUsed
            expectedActor = record.actorID
            expectedSubject = record.witnessIDs.first
            expectedStatus = "used"
        case .continuityReviewed:
            expectedKind = .cultureContinuityReviewed
            expectedActor = record.actorID
            expectedSubject = record.actorID
            expectedStatus = record.outcome!.rawValue
        }
        guard event.kind == expectedKind,
              event.origin == .cultureTransition,
              event.actorID == expectedActor,
              event.subjectID == expectedSubject,
              event.operationID == nil,
              event.causes == record.causes,
              event.simulationTick.rawValue == record.tick,
              case let .culture(
                recordID, practiceID, status, detail
              ) = event.payload,
              recordID == record.operationID,
              practiceID == record.practice.practiceID.rawValue,
              status == expectedStatus,
              detail == record.requestDigest else {
            throw AgentSessionError.culture(.invalidState(
                "culture causal event mismatch"
            ))
        }
    }

    private func validateCultureCarrierProvenance(
        _ record: AgentCultureRecord,
        retainedEvents: [AgentCausalEventID: AgentCausalEvent]
    ) throws {
        guard record.kind == .exposed else { return }
        guard let sourceAgentID = record.sourceAgentID,
              let carrierEventID = record.carrierEventID,
              let contentDigest = record.carrierContentDigest,
              case let .oral(transmissionID)? = record.carrier,
              let oralState = oralTransmissionState else {
            throw AgentSessionError.culture(.invalidState(
                "culture carrier provenance"
            ))
        }
        guard let historical = cultureHistoricalStatus(
                for: sourceAgentID,
                practiceID: record.practice.practiceID,
                through: carrierEventID.sequence
              ), historical.status == .adopted,
              record.causes == [carrierEventID, historical.eventID].sorted()
        else {
            throw AgentSessionError.culture(.invalidState(
                "culture source causal status"
            ))
        }
        if let transmission = oralState.transmissions.first(where: {
            $0.transmissionID == transmissionID
        }) {
            guard transmission.speakerID == sourceAgentID,
                  transmission.recipientID == record.actorID,
                  transmission.receiptEventID == carrierEventID,
                  let attachment = transmission.contentAttachment,
                  attachment.namespace == cultureOralContentNamespace,
                  attachment.contentID
                    == record.practice.practiceID.rawValue,
                  attachment.contentDigest == contentDigest else {
                throw AgentSessionError.culture(.invalidState(
                    "culture carrier content"
                ))
            }
        } else {
            guard oralState.evictedTransmissionCount > 0 else {
                throw AgentSessionError.culture(.invalidState(
                    "missing culture carrier"
                ))
            }
        }
        if let carrierEvent = retainedEvents[carrierEventID] {
            guard carrierEvent.kind == .oralTransmissionAccepted,
                  carrierEvent.origin == .oralTransition,
                  carrierEvent.actorID == sourceAgentID,
                  carrierEvent.subjectID == record.actorID,
                  case let .oral(
                    retainedID, _, _, _, reason
                  ) = carrierEvent.payload,
                  retainedID == transmissionID.rawValue,
                  reason == contentDigest else {
                throw AgentSessionError.culture(.invalidState(
                    "culture carrier causal event"
                ))
            }
        } else {
            guard causalLedger.droppedEventCount > 0,
                  let firstRetained = causalLedger.events.first?.eventID,
                  carrierEventID < firstRetained else {
                throw AgentSessionError.culture(.invalidState(
                    "missing carrier causal event"
                ))
            }
        }
    }

    private func validateCulturePractice(
        _ practice: AgentCulturePractice
    ) throws {
        try practice.form.validate()
        guard cultureIdentifierIsValid(
                practice.practiceID.rawValue, maximum: 96
              ),
              cultureIdentifierIsValid(
                practice.rootPracticeID.rawValue, maximum: 96
              ),
              (practice.parentPracticeID.map {
                cultureIdentifierIsValid($0.rawValue, maximum: 96)
              } ?? true),
              cultureIdentifierIsValid(practice.originOperationID, maximum: 128),
              practice.generation >= 0,
              (practice.generation == 0) == (practice.parentPracticeID == nil),
              (practice.parentPracticeID == nil
                ? practice.rootPracticeID == practice.practiceID : true),
              practice.practiceID == culturePracticeID(
                  operationID: practice.originOperationID,
                  originatorID: practice.originatorID,
                  form: practice.form,
                  parentID: practice.parentPracticeID
              ) else {
            throw AgentSessionError.culture(.invalidState("practice descriptor"))
        }
    }

    private func validateCultureIndividualDerivedState(
        _ individual: AgentCultureIndividualState
    ) throws {
        var derived: [AgentCulturePracticeID: AgentCultureStance] = [:]
        for record in individual.history {
            let id = record.practice.practiceID
            switch record.kind {
            case .originated, .variationCreated:
                guard record.actorID == individual.agentID,
                      derived[id] == nil,
                      record.outcome == .adopted else {
                    throw AgentSessionError.culture(.invalidState("origin history"))
                }
                derived[id] = AgentCultureStance(
                    practice: record.practice, status: .adopted,
                    exposureCount: 0, useCount: 0,
                    lastExposureTick: nil, lastUseTick: nil,
                    adoptedAtTick: record.tick,
                    adoptedEventID: record.eventID,
                    lastTransitionEventID: record.eventID
                )
            case .exposed:
                guard record.actorID == individual.agentID,
                      record.sourceAgentID != nil, record.carrier != nil,
                      record.participantIDs.isEmpty, record.witnessIDs.isEmpty else {
                    throw AgentSessionError.culture(.invalidState("exposure history"))
                }
                var stance = derived[id] ?? AgentCultureStance(
                    practice: record.practice, status: .exposed,
                    exposureCount: 0, useCount: 0,
                    lastExposureTick: nil, lastUseTick: nil,
                    adoptedAtTick: nil, adoptedEventID: nil,
                    lastTransitionEventID: record.eventID
                )
                stance.exposureCount += 1
                stance.lastExposureTick = record.tick
                stance.lastTransitionEventID = record.eventID
                derived[id] = stance
            case .considered:
                guard record.actorID == individual.agentID,
                      var stance = derived[id], let outcome = record.outcome else {
                    throw AgentSessionError.culture(.invalidState("decision history"))
                }
                if outcome == .adopted {
                    stance.status = .adopted
                    stance.adoptedAtTick = record.tick
                    stance.adoptedEventID = record.eventID
                } else if outcome == .rejected {
                    stance.status = .rejected
                } else if outcome != .considered {
                    throw AgentSessionError.culture(.invalidState("decision outcome"))
                }
                stance.lastTransitionEventID = record.eventID
                derived[id] = stance
            case .used:
                let isParticipant = record.participantIDs.contains(individual.agentID)
                let isWitness = record.witnessIDs.contains(individual.agentID)
                guard isParticipant != isWitness else {
                    throw AgentSessionError.culture(.invalidState("use history"))
                }
                if isParticipant {
                    guard var stance = derived[id], stance.status == .adopted else {
                        throw AgentSessionError.culture(.invalidState("use adoption"))
                    }
                    stance.useCount += 1
                    stance.lastUseTick = record.tick
                    stance.lastTransitionEventID = record.eventID
                    derived[id] = stance
                } else {
                    var stance = derived[id] ?? AgentCultureStance(
                        practice: record.practice, status: .exposed,
                        exposureCount: 0, useCount: 0,
                        lastExposureTick: nil, lastUseTick: nil,
                        adoptedAtTick: nil, adoptedEventID: nil,
                        lastTransitionEventID: record.eventID
                    )
                    stance.exposureCount += 1
                    stance.lastExposureTick = record.tick
                    stance.lastTransitionEventID = record.eventID
                    derived[id] = stance
                }
            case .continuityReviewed:
                guard record.actorID == individual.agentID,
                      var stance = derived[id], let outcome = record.outcome else {
                    throw AgentSessionError.culture(.invalidState("continuity history"))
                }
                if outcome == .ceasedUnused || outcome == .ceasedSuperseded {
                    stance.status = .ceased
                } else if outcome != .continued {
                    throw AgentSessionError.culture(.invalidState("continuity outcome"))
                }
                stance.lastTransitionEventID = record.eventID
                derived[id] = stance
            }
        }
        let expected = derived.values.sorted {
            $0.practice.practiceID < $1.practice.practiceID
        }
        guard expected == individual.stances else {
            throw AgentSessionError.culture(.invalidState("derived individual stance"))
        }
    }
}
