extension AgentSimulationSession {
    public mutating func setPhysicalEnabled(_ enabled: Bool) throws {
        if enabled, !causalLedger.isEnabled {
            throw AgentSessionError.physical(.causalLedgerRequired)
        }
        if enabled, !socialEnabled {
            throw AgentSessionError.physical(.socialRequired)
        }
        guard physicalEnabled != enabled else { return }
        if !enabled, cooperationEnabled {
            try disableCooperationState(reason: "physical channel disabled")
            recordFeatureToggle(name: "cooperation", enabled: false)
        }
        physicalEnabled = enabled
        if !enabled { disablePhysicalChannelState() }
        recordFeatureToggle(name: "physical", enabled: enabled)
    }

    public mutating func clearPhysicalState() throws {
        try prevalidateCausalAppend(count: 1)
        let counts = (
            signals: physicalSignals.count,
            perceptions: physicalPerceptions.count,
            presentations: physicalPresentationRequests.count
        )
        physicalSignals.removeAll()
        physicalPerceptions.removeAll()
        physicalPresentationRequests.removeAll()
        physicalEvictionCounts = AgentPhysicalEvictionCounts()
        _ = try recordCausalEvent(
            kind: .physicalStateCleared,
            origin: .controllerCommand,
            payload: .physicalClear(
                signals: counts.signals,
                perceptions: counts.perceptions,
                presentations: counts.presentations
            ),
            summary: "physical channel state cleared"
        )
    }

    public func physicalChannelSnapshot() -> AgentPhysicalChannelSnapshot {
        let signals = physicalSignals.sorted {
            if $0.emittedAtTick != $1.emittedAtTick { return $0.emittedAtTick < $1.emittedAtTick }
            return $0.signalID < $1.signalID
        }
        let perceptions = physicalPerceptions.sorted {
            if $0.observedAtTick != $1.observedAtTick { return $0.observedAtTick < $1.observedAtTick }
            if $0.signalID != $1.signalID { return $0.signalID < $1.signalID }
            return $0.observerID < $1.observerID
        }
        let presentations = physicalPresentationRequests.sorted {
            if $0.emittedAtTick != $1.emittedAtTick { return $0.emittedAtTick < $1.emittedAtTick }
            return $0.signalID < $1.signalID
        }
        let eventCount = causalLedger.events.filter { $0.kind.isPhysical }.count
        let canonical = [
            "enabled=\(physicalEnabled ? 1 : 0)",
            signals.map {
                "s|\($0.signalID.rawValue)|\($0.senderID.rawValue)|\($0.intendedRecipientID.rawValue)|\($0.factID.rawValue)|\($0.emittedAtTick)|\($0.expiresAtTick)|\($0.status.rawValue)|\($0.emittedEventID.rawValue)"
            }.joined(separator: ";"),
            perceptions.map {
                "p|\($0.signalID.rawValue)|\($0.observerID.rawValue)|\($0.isIntendedRecipient ? 1 : 0)|\($0.distanceManhattan)|\($0.soundClarity)|\($0.gestureClarity)|\($0.opaqueOcclusionCount)|\($0.lineOfSight ? 1 : 0)|\($0.chunksReady ? 1 : 0)|\($0.outcome.rawValue)|\($0.observedAtTick)|\($0.perceivedEventID.rawValue)|\($0.decodedEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            presentations.map {
                "r|\($0.signalID.rawValue)|\($0.emittedAtTick)|\($0.expiresAtTick)|\($0.presentedAtTick.map(String.init) ?? "none")"
            }.joined(separator: ";"),
            "evicted=\(physicalEvictionCounts.signals),\(physicalEvictionCounts.perceptions),\(physicalEvictionCounts.presentations)",
            "events=\(eventCount)",
        ].joined(separator: "|")
        return AgentPhysicalChannelSnapshot(
            enabled: physicalEnabled,
            tick: tick,
            configuration: configuration.physicalChannelConfiguration,
            signals: signals,
            perceptions: perceptions,
            presentations: presentations,
            evictionCounts: physicalEvictionCounts,
            physicalCausalEventCount: eventCount,
            decodedMessageCount: signals.filter { $0.status == .decoded }.count,
            digest: AgentSocialDigest.make(canonical)
        )
    }

    public func physicalChannelSummary() -> AgentPhysicalChannelSummary {
        let snapshot = physicalChannelSnapshot()
        func count(_ outcome: AgentPhysicalPerceptionOutcome) -> Int {
            snapshot.perceptions.filter { $0.outcome == outcome }.count
        }
        return AgentPhysicalChannelSummary(
            enabled: snapshot.enabled,
            pendingSignalCount: snapshot.signals.filter { $0.status == .pending }.count,
            retainedSignalCount: snapshot.signals.count,
            retainedPerceptionCount: snapshot.perceptions.count,
            exactCount: count(.exact),
            ambiguousCount: count(.ambiguous),
            missedCount: count(.missed),
            inconclusiveCount: count(.inconclusive),
            expiredCount: snapshot.signals.filter { $0.status == .expired }.count,
            decodedMessageCount: snapshot.decodedMessageCount,
            physicalCausalEventCount: snapshot.physicalCausalEventCount,
            evictionCounts: snapshot.evictionCounts,
            digest: snapshot.digest
        )
    }

    public mutating func claimPhysicalPresentationRequests() -> [AgentPhysicalPresentationRequest] {
        guard physicalEnabled else { return [] }
        var claimed: [AgentPhysicalPresentationRequest] = []
        for index in physicalPresentationRequests.indices
        where physicalPresentationRequests[index].presentedAtTick == nil {
            physicalPresentationRequests[index].presentedAtTick = tick
            claimed.append(physicalPresentationRequests[index])
        }
        return claimed.sorted { $0.signalID < $1.signalID }
    }

    func hasPendingPhysicalSignal(
        senderID: AgentID,
        recipientID _: AgentID,
        factID: AgentSocialFactID
    ) -> Bool {
        physicalEnabled && physicalSignals.contains {
            $0.status == .pending && $0.senderID == senderID
                && $0.factID == factID
        }
    }

    mutating func emitPhysicalSignal(_ intent: AgentSocialShareIntent) throws {
        guard physicalEnabled, canDeliverSocialMessage(intent),
              let fact = socialFacts.first(where: { $0.factID == intent.factID }),
              let sender = statesById[intent.senderID.rawValue],
              !hasPendingPhysicalSignal(
                  senderID: intent.senderID,
                  recipientID: intent.recipientID,
                  factID: intent.factID
              ) else { return }
        let signalID = AgentPhysicalSignalID(rawValue: "signal-" + AgentSocialDigest.make(
            "\(simulationID.rawValue)|\(tick)|\(intent.senderID.rawValue)|\(intent.recipientID.rawValue)|\(intent.factID.rawValue)"
        ))!
        guard !physicalSignals.contains(where: { $0.signalID == signalID }) else { return }
        let task = cooperationEnabled ? sharedTasks.first {
            $0.status == .draft
                && $0.issuerID == intent.senderID
                && $0.helperID == intent.recipientID
                && $0.sourceFactID == intent.factID
        } : nil
        let cooperationOffer = task.map {
            AgentCooperationOfferEnvelope(
                taskID: $0.taskID,
                signalID: signalID,
                issuerID: $0.issuerID,
                intendedHelperID: $0.helperID,
                projectID: $0.projectID,
                resource: $0.resource,
                quantity: $0.requestedQuantity,
                sourceFactID: $0.sourceFactID
            )
        }
        let causes = [
            fact.directObservationEventID,
            lastDecisionEventByAgentID[intent.senderID],
        ].compactMap { $0 }.sorted()
        let event = try requiredPhysicalEvent(
            kind: .physicalSignalEmitted,
            actorID: intent.senderID,
            subjectID: intent.recipientID,
            causes: Array(Set(causes)).sorted(),
            payload: .physicalSignal(
                signalID: signalID.rawValue,
                senderID: intent.senderID.rawValue,
                recipientID: intent.recipientID.rawValue,
                factID: fact.factID.rawValue,
                source: sender.position,
                pointed: fact.position,
                modalities: AgentPhysicalSignalModality.allCases.map(\.rawValue).joined(separator: ",")
            ),
            summary: "physical signal emitted \(intent.senderID.rawValue)>\(intent.recipientID.rawValue)"
        )
        let expiry = tick + configuration.physicalChannelConfiguration.signalLifetimeTicks
        physicalSignals.append(AgentPhysicalSignal(
            signalID: signalID,
            senderID: intent.senderID,
            intendedRecipientID: intent.recipientID,
            factID: fact.factID,
            directObservationEventID: fact.directObservationEventID,
            sourcePosition: sender.position,
            pointedPosition: fact.position,
            resource: fact.resource,
            expectedBlockFingerprint: fact.expectedBlockFingerprint,
            emittedAtTick: tick,
            expiresAtTick: expiry,
            emittedEventID: event.eventID,
            modalities: [.attentionSound, .pointingGesture],
            cooperationOffer: cooperationOffer,
            status: .pending
        ))
        physicalPresentationRequests.append(AgentPhysicalPresentationRequest(
            signalID: signalID,
            senderID: intent.senderID,
            sourcePosition: sender.position,
            pointedPosition: fact.position,
            emittedAtTick: tick,
            expiresAtTick: expiry,
            presentedAtTick: nil
        ))
        lastSocialShareTickByAgentId[intent.senderID.rawValue] = tick
        if let cooperationOffer {
            try markSharedTaskSignaled(
                envelope: cooperationOffer,
                emittedEventID: event.eventID
            )
        }
        enforcePhysicalBounds()
    }

    mutating func applyPhysicalObservations(
        _ observations: [AgentPhysicalSignalObservation]
    ) throws {
        guard physicalEnabled else {
            if !observations.isEmpty { throw AgentSessionError.physical(.channelDisabled) }
            return
        }
        var keys = Set<String>()
        for observation in observations.sorted(by: physicalObservationSort) {
            let key = "\(observation.signalID.rawValue)|\(observation.observerID.rawValue)"
            guard keys.insert(key).inserted else {
                throw AgentSessionError.physical(.duplicateObservation(key))
            }
            guard let signalIndex = physicalSignals.firstIndex(where: {
                $0.signalID == observation.signalID
            }) else {
                throw AgentSessionError.physical(.unknownSignal(observation.signalID.rawValue))
            }
            guard statesById[observation.observerID.rawValue] != nil else {
                throw AgentSessionError.physical(.unknownObserver(observation.observerID.rawValue))
            }
            let signal = physicalSignals[signalIndex]
            if signal.status != .pending { continue }
            if physicalPerceptions.contains(where: {
                $0.signalID == observation.signalID && $0.observerID == observation.observerID
                    && $0.outcome != .inconclusive
            }) { continue }
            guard observation.observedAtTick == tick,
                  observation.observedAtTick > signal.emittedAtTick,
                  observation.observedAtTick <= signal.expiresAtTick,
                  observation.distanceManhattan >= 0,
                  (0...100).contains(observation.soundClarity),
                  (0...100).contains(observation.gestureClarity),
                  observation.opaqueOcclusionCount >= 0 else {
                throw AgentSessionError.physical(.invalidObservation(key))
            }
            let intended = observation.observerID == signal.intendedRecipientID
            var outcome = configuration.physicalChannelConfiguration.classify(
                soundClarity: observation.soundClarity,
                gestureClarity: observation.gestureClarity,
                lineOfSight: observation.lineOfSight,
                chunksReady: observation.chunksReady,
                isIntendedRecipient: intended
            )
            let intent = AgentSocialShareIntent(
                senderID: signal.senderID,
                recipientID: signal.intendedRecipientID,
                factID: signal.factID
            )
            if outcome == .exact, !canDeliverSocialMessage(intent) { outcome = .missed }
            let perceived = try requiredPhysicalEvent(
                kind: .physicalSignalPerceived,
                actorID: observation.observerID,
                subjectID: signal.senderID,
                causes: [signal.emittedEventID],
                payload: .physicalPerception(
                    signalID: signal.signalID.rawValue,
                    observerID: observation.observerID.rawValue,
                    intended: intended,
                    soundClarity: observation.soundClarity,
                    gestureClarity: observation.gestureClarity,
                    occlusions: observation.opaqueOcclusionCount,
                    lineOfSight: observation.lineOfSight,
                    outcome: outcome.rawValue
                ),
                summary: "physical perception \(outcome.rawValue) observer=\(observation.observerID.rawValue)"
            )
            var decodedEventID: AgentCausalEventID?
            if outcome == .exact {
                let decoded = try requiredPhysicalEvent(
                    kind: .physicalSignalDecoded,
                    actorID: observation.observerID,
                    subjectID: signal.senderID,
                    causes: [signal.directObservationEventID, perceived.eventID].sorted(),
                    payload: .physicalPerception(
                        signalID: signal.signalID.rawValue,
                        observerID: observation.observerID.rawValue,
                        intended: true,
                        soundClarity: observation.soundClarity,
                        gestureClarity: observation.gestureClarity,
                        occlusions: observation.opaqueOcclusionCount,
                        lineOfSight: observation.lineOfSight,
                        outcome: outcome.rawValue
                    ),
                    summary: "physical signal decoded recipient=\(observation.observerID.rawValue)"
                )
                decodedEventID = decoded.eventID
                guard try deliverSocialMessage(intent, physicalCause: decoded.eventID) else {
                    throw AgentSessionError.physical(.invalidObservation(key))
                }
                if let offer = signal.cooperationOffer {
                    try markSharedTaskOffered(
                        envelope: offer,
                        perceptionEventID: decoded.eventID
                    )
                }
                physicalSignals[signalIndex].status = .decoded
            } else if intended && outcome == .ambiguous {
                physicalSignals[signalIndex].status = .ambiguous
            } else if intended && outcome == .missed {
                physicalSignals[signalIndex].status = .missed
            }
            physicalPerceptions.append(AgentPhysicalPerception(
                signalID: observation.signalID,
                observerID: observation.observerID,
                isIntendedRecipient: intended,
                distanceManhattan: observation.distanceManhattan,
                soundClarity: observation.soundClarity,
                gestureClarity: observation.gestureClarity,
                opaqueOcclusionCount: observation.opaqueOcclusionCount,
                lineOfSight: observation.lineOfSight,
                chunksReady: observation.chunksReady,
                outcome: outcome,
                observedAtTick: observation.observedAtTick,
                perceivedEventID: perceived.eventID,
                decodedEventID: decodedEventID
            ))
            enforcePhysicalBounds()
        }
        try expirePhysicalSignals()
    }

    mutating func disablePhysicalChannelState() {
        physicalEnabled = false
        for index in physicalSignals.indices where physicalSignals[index].status == .pending {
            physicalSignals[index].status = .cancelled
        }
        physicalPresentationRequests.removeAll()
    }

    private mutating func expirePhysicalSignals() throws {
        for index in physicalSignals.indices.sorted(by: {
            physicalSignals[$0].signalID < physicalSignals[$1].signalID
        }) where physicalSignals[index].status == .pending
            && tick > physicalSignals[index].expiresAtTick {
            let signal = physicalSignals[index]
            _ = try requiredPhysicalEvent(
                kind: .physicalSignalExpired,
                actorID: signal.senderID,
                subjectID: signal.intendedRecipientID,
                causes: [signal.emittedEventID],
                payload: .physicalSignal(
                    signalID: signal.signalID.rawValue,
                    senderID: signal.senderID.rawValue,
                    recipientID: signal.intendedRecipientID.rawValue,
                    factID: signal.factID.rawValue,
                    source: signal.sourcePosition,
                    pointed: signal.pointedPosition,
                    modalities: signal.modalities.map(\.rawValue).joined(separator: ",")
                ),
                summary: "physical signal expired \(signal.signalID.rawValue)"
            )
            physicalSignals[index].status = .expired
        }
    }

    private mutating func requiredPhysicalEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .physicalTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else { throw AgentSessionError.physical(.causalLedgerRequired) }
        return event
    }

    private func physicalObservationSort(
        _ lhs: AgentPhysicalSignalObservation,
        _ rhs: AgentPhysicalSignalObservation
    ) -> Bool {
        if lhs.signalID != rhs.signalID { return lhs.signalID < rhs.signalID }
        return lhs.observerID < rhs.observerID
    }

    private mutating func enforcePhysicalBounds() {
        let config = configuration.physicalChannelConfiguration
        if physicalSignals.count > config.maximumPendingSignals {
            physicalSignals.sort {
                if $0.emittedAtTick != $1.emittedAtTick { return $0.emittedAtTick < $1.emittedAtTick }
                return $0.signalID < $1.signalID
            }
            let excess = physicalSignals.count - config.maximumPendingSignals
            let removed = Set(physicalSignals.prefix(excess).map(\.signalID))
            physicalSignals.removeFirst(excess)
            physicalPresentationRequests.removeAll { removed.contains($0.signalID) }
            physicalEvictionCounts.signals += excess
        }
        if physicalPerceptions.count > config.maximumRetainedPerceptions {
            physicalPerceptions.sort {
                if $0.observedAtTick != $1.observedAtTick { return $0.observedAtTick < $1.observedAtTick }
                if $0.signalID != $1.signalID { return $0.signalID < $1.signalID }
                return $0.observerID < $1.observerID
            }
            let excess = physicalPerceptions.count - config.maximumRetainedPerceptions
            physicalPerceptions.removeFirst(excess)
            physicalEvictionCounts.perceptions += excess
        }
        if physicalPresentationRequests.count > config.maximumPendingSignals {
            physicalPresentationRequests.sort {
                if $0.emittedAtTick != $1.emittedAtTick { return $0.emittedAtTick < $1.emittedAtTick }
                return $0.signalID < $1.signalID
            }
            let excess = physicalPresentationRequests.count - config.maximumPendingSignals
            physicalPresentationRequests.removeFirst(excess)
            physicalEvictionCounts.presentations += excess
        }
    }
}

private extension AgentCausalEventKind {
    var isPhysical: Bool {
        switch self {
        case .physicalSignalEmitted, .physicalSignalPerceived, .physicalSignalDecoded,
             .physicalSignalExpired, .physicalStateCleared:
            return true
        default:
            return false
        }
    }
}
