struct AgentSocialShareIntent {
    let senderID: AgentID
    let recipientID: AgentID
    let factID: AgentSocialFactID
}

struct AgentSocialTickPlan {
    var shareIntentsByAgentId: [String: AgentSocialShareIntent]
    var verificationBeliefsByAgentId: [String: AgentSocialBeliefID]
    var expiredBeliefIDs: [AgentSocialBeliefID]

    static let disabled = AgentSocialTickPlan(
        shareIntentsByAgentId: [:],
        verificationBeliefsByAgentId: [:],
        expiredBeliefIDs: []
    )
}

extension AgentSimulationSession {
    public mutating func setSocialEnabled(_ enabled: Bool) throws {
        if enabled, !causalLedger.isEnabled {
            throw AgentSessionError.social(.causalLedgerRequired)
        }
        if !enabled, oralTransmissionState != nil {
            throw AgentSessionError.oral(.socialRequired)
        }
        guard socialEnabled != enabled else { return }
        let physicalWasEnabled = physicalEnabled
        if !enabled, cooperationEnabled {
            try disableCooperationState(reason: "social channel disabled")
            recordFeatureToggle(name: "cooperation", enabled: false)
        }
        socialEnabled = enabled
        if !enabled {
            disablePhysicalChannelState()
            activeSocialVerificationByAgentId.removeAll()
            for id in sortedIds {
                guard var state = statesById[id] else { continue }
                if state.currentGoal.kind == .shareInformation
                    || state.currentGoal.kind == .verifySocialInformation {
                    state.currentGoal = AgentGoal(
                        kind: .idle,
                        reason: "social disabled",
                        startedAtTick: tick,
                        urgency: 0
                    )
                }
                if state.navigationProgress.route?.purpose == .socialVerification {
                    state.navigationProgress = AgentNavigationProgress(
                        lastInvalidation: .targetMissing
                    )
                }
                statesById[id] = state
            }
        }
        if physicalWasEnabled && !enabled {
            recordFeatureToggle(name: "physical", enabled: false)
        }
        recordFeatureToggle(name: "social", enabled: enabled)
    }

    public mutating func clearSocialState() throws {
        try prevalidateCausalAppend(count: 1)
        let counts = (
            facts: socialFacts.count,
            messages: socialMessages.count,
            beliefs: socialBeliefs.count,
            trust: socialTrustRelations.count
        )
        socialFacts.removeAll()
        socialMessages.removeAll()
        socialBeliefs.removeAll()
        socialTrustRelations.removeAll()
        activeSocialVerificationByAgentId.removeAll()
        lastSocialShareTickByAgentId.removeAll()
        socialEvictionCounts = AgentSocialEvictionCounts()
        for id in sortedIds {
            guard var state = statesById[id] else { continue }
            if state.currentGoal.kind == .shareInformation
                || state.currentGoal.kind == .verifySocialInformation {
                state.currentGoal = AgentGoal(
                    kind: .idle,
                    reason: "social state cleared",
                    startedAtTick: tick,
                    urgency: 0
                )
            }
            if state.navigationProgress.route?.purpose == .socialVerification {
                state.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetMissing)
            }
            statesById[id] = state
        }
        try recordCausalEvent(
            kind: .socialStateCleared,
            origin: .controllerCommand,
            payload: .socialClear(
                facts: counts.facts,
                messages: counts.messages,
                beliefs: counts.beliefs,
                trustRelations: counts.trust
            ),
            summary: "social state cleared"
        )
    }

    public func socialSnapshot() -> AgentSocialSnapshot {
        let facts = socialFacts.sorted { $0.factID < $1.factID }
        let messages = socialMessages.sorted { $0.messageID < $1.messageID }
        let beliefs = socialBeliefs.sorted { $0.beliefID < $1.beliefID }
        let trust = socialTrustRelations.sorted { $0.relationID < $1.relationID }
        let active = activeSocialVerificationByAgentId.keys.sorted().compactMap {
            socialVerificationRequest(for: $0)
        }
        let socialEventCount = causalLedger.events.filter { $0.kind.isSocial }.count
        let canonical = [
            "enabled=\(socialEnabled ? 1 : 0)",
            facts.map {
                "f|\($0.factID.rawValue)|\($0.observerID.rawValue)|\($0.stableKey)|\($0.observedAtTick)|\($0.expiresAtTick)|\($0.directObservationEventID.rawValue)"
            }.joined(separator: ";"),
            messages.map {
                "m|\($0.messageID.rawValue)|\($0.senderID.rawValue)|\($0.recipientID.rawValue)|\($0.fact.factID.rawValue)|\($0.sentAtTick)|\($0.status.rawValue)"
            }.joined(separator: ";"),
            beliefs.map {
                "b|\($0.beliefID.rawValue)|\($0.ownerID.rawValue)|\($0.senderID.rawValue)|\($0.status.rawValue)|\($0.reason)|\($0.verificationEventID?.rawValue ?? "none")"
            }.joined(separator: ";"),
            trust.map {
                "t|\($0.relationID.rawValue)|\($0.score)|\($0.confirmationCount)|\($0.contradictionCount)|\($0.lastChangedAtTick)"
            }.joined(separator: ";"),
            active.map { "a|\($0.verifierID.rawValue)|\($0.beliefID.rawValue)" }.joined(separator: ";"),
            "evicted=\(socialEvictionCounts.facts),\(socialEvictionCounts.messages),\(socialEvictionCounts.beliefs),\(socialEvictionCounts.trustRelations)",
            "events=\(socialEventCount)",
        ].joined(separator: "|")
        return AgentSocialSnapshot(
            enabled: socialEnabled,
            tick: tick,
            configuration: configuration.socialConfiguration,
            facts: facts,
            messages: messages,
            beliefs: beliefs,
            trustRelations: trust,
            activeVerifications: active,
            evictionCounts: socialEvictionCounts,
            socialCausalEventCount: socialEventCount,
            digest: AgentSocialDigest.make(canonical)
        )
    }

    public func socialSummary() -> AgentSocialSummary {
        let snapshot = socialSnapshot()
        func count(_ status: AgentSocialBeliefStatus) -> Int {
            snapshot.beliefs.filter { $0.status == status }.count
        }
        return AgentSocialSummary(
            enabled: snapshot.enabled,
            retainedMessageCount: snapshot.messages.count,
            unverifiedBeliefCount: count(.unverified),
            confirmedBeliefCount: count(.confirmed),
            contradictedBeliefCount: count(.contradicted),
            expiredBeliefCount: count(.expired),
            ignoredBeliefCount: count(.ignored),
            activeVerificationCount: snapshot.activeVerifications.count,
            trustEdgeCount: snapshot.trustRelations.count,
            socialCausalEventCount: snapshot.socialCausalEventCount,
            evictionCounts: snapshot.evictionCounts,
            digest: snapshot.digest
        )
    }

    public func trustSnapshot() -> AgentTrustSnapshot {
        let relations = socialTrustRelations.sorted { $0.relationID < $1.relationID }
        let canonical = relations.map {
            "\($0.relationID.rawValue)|\($0.score)|\($0.confirmationCount)|\($0.contradictionCount)|\($0.lastChangedAtTick)"
        }.joined(separator: ";")
        return AgentTrustSnapshot(
            relations: relations,
            digest: AgentSocialDigest.make(canonical)
        )
    }

    public func socialVerificationRequest(for agentId: String) -> AgentSocialVerificationRequest? {
        guard let beliefID = activeSocialVerificationByAgentId[agentId],
              let belief = socialBeliefs.first(where: { $0.beliefID == beliefID }),
              belief.status == .unverified else { return nil }
        return AgentSocialVerificationRequest(
            beliefID: belief.beliefID,
            verifierID: belief.ownerID,
            senderID: belief.senderID,
            resource: belief.fact.resource,
            position: belief.fact.position,
            expectedBlockFingerprint: belief.fact.expectedBlockFingerprint
        )
    }

    public func pendingSocialVerificationRequest(for agentId: String) -> AgentSocialVerificationRequest? {
        if let active = socialVerificationRequest(for: agentId) { return active }
        guard socialEnabled, !isMigratingAgent(agentId),
              let state = statesById[agentId] else { return nil }
        let belief = socialBeliefs.filter {
            $0.ownerID.rawValue == agentId && $0.status == .unverified
                && tick + 1 <= $0.expiresAtTick
                && trustScore(sourceAgentId: agentId, targetAgentId: $0.senderID.rawValue)
                    >= configuration.socialConfiguration.minimumTrustToVerify
        }.sorted { lhs, rhs in
            if lhs.expiresAtTick != rhs.expiresAtTick { return lhs.expiresAtTick < rhs.expiresAtTick }
            let lhsTrust = trustScore(sourceAgentId: agentId, targetAgentId: lhs.senderID.rawValue)
            let rhsTrust = trustScore(sourceAgentId: agentId, targetAgentId: rhs.senderID.rawValue)
            if lhsTrust != rhsTrust { return lhsTrust > rhsTrust }
            let lhsDistance = manhattanDistance(state.position, lhs.fact.position)
            let rhsDistance = manhattanDistance(state.position, rhs.fact.position)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            return lhs.messageID < rhs.messageID
        }.first
        guard let belief else { return nil }
        return AgentSocialVerificationRequest(
            beliefID: belief.beliefID,
            verifierID: belief.ownerID,
            senderID: belief.senderID,
            resource: belief.fact.resource,
            position: belief.fact.position,
            expectedBlockFingerprint: belief.fact.expectedBlockFingerprint
        )
    }

    public func trustScore(sourceAgentId: String, targetAgentId: String) -> Int {
        socialTrustRelations.first {
            $0.sourceID.rawValue == sourceAgentId && $0.targetID.rawValue == targetAgentId
        }?.score ?? 0
    }

    public mutating func attemptToForwardSocialBelief(
        beliefID: AgentSocialBeliefID,
        by agentId: String,
        to recipientId: String
    ) throws {
        guard let belief = socialBeliefs.first(where: { $0.beliefID == beliefID }),
              belief.ownerID.rawValue == agentId else {
            throw AgentSessionError.social(.unknownBelief(beliefID.rawValue))
        }
        throw AgentSessionError.social(
            .forwardingProhibited("\(agentId)->\(recipientId):\(beliefID.rawValue)")
        )
    }

    mutating func prepareSocialTick(at socialTick: Int) -> AgentSocialTickPlan {
        guard socialEnabled else { return .disabled }
        var expired: [AgentSocialBeliefID] = []
        for index in socialBeliefs.indices.sorted(by: {
            socialBeliefs[$0].beliefID < socialBeliefs[$1].beliefID
        }) where socialBeliefs[index].status == .unverified
            && socialTick > socialBeliefs[index].expiresAtTick {
            socialBeliefs[index].status = .expired
            socialBeliefs[index].reason = "belief lifetime elapsed without direct verification"
            socialBeliefs[index].verifiedAtTick = nil
            socialBeliefs[index].verificationEventID = nil
            expired.append(socialBeliefs[index].beliefID)
        }
        for index in socialMessages.indices where socialTick > socialMessages[index].expiresAtTick {
            if socialMessages[index].status == .received {
                socialMessages[index].status = .expired
            }
        }
        activeSocialVerificationByAgentId = activeSocialVerificationByAgentId.filter { _, beliefID in
            socialBeliefs.first { $0.beliefID == beliefID }?.status == .unverified
        }

        var verification: [String: AgentSocialBeliefID] = [:]
        for id in sortedIds where !isMigratingAgent(id) {
            if let active = activeSocialVerificationByAgentId[id],
               socialBeliefs.first(where: { $0.beliefID == active })?.status == .unverified {
                verification[id] = active
                continue
            }
            let candidates = socialBeliefs.filter {
                $0.ownerID.rawValue == id && $0.status == .unverified
                    && socialTick <= $0.expiresAtTick
                    && trustScore(sourceAgentId: id, targetAgentId: $0.senderID.rawValue)
                        >= configuration.socialConfiguration.minimumTrustToVerify
            }.sorted { lhs, rhs in
                if lhs.expiresAtTick != rhs.expiresAtTick {
                    return lhs.expiresAtTick < rhs.expiresAtTick
                }
                let lhsTrust = trustScore(
                    sourceAgentId: id, targetAgentId: lhs.senderID.rawValue
                )
                let rhsTrust = trustScore(
                    sourceAgentId: id, targetAgentId: rhs.senderID.rawValue
                )
                if lhsTrust != rhsTrust { return lhsTrust > rhsTrust }
                guard let state = statesById[id] else { return lhs.beliefID < rhs.beliefID }
                let lhsDistance = manhattanDistance(state.position, lhs.fact.position)
                let rhsDistance = manhattanDistance(state.position, rhs.fact.position)
                if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
                return lhs.messageID < rhs.messageID
            }
            verification[id] = candidates.first?.beliefID
        }

        var shares: [String: AgentSocialShareIntent] = [:]
        for senderId in sortedIds where !isMigratingAgent(senderId) {
            guard let sender = statesById[senderId],
                  lastSocialShareTickByAgentId[senderId].map({
                      socialTick - $0 >= configuration.socialConfiguration.shareCooldownTicks
                  }) != false else { continue }
            let facts = socialFacts.filter {
                $0.observerID.rawValue == senderId && !$0.isExpired(at: socialTick)
            }.sorted {
                if $0.expiresAtTick != $1.expiresAtTick { return $0.expiresAtTick < $1.expiresAtTick }
                return $0.factID < $1.factID
            }
            for fact in facts {
                let recipients = sortedIds.compactMap { recipientId -> (AgentID, Int)? in
                    guard recipientId != senderId,
                          !isMigratingAgent(recipientId),
                          let recipient = statesById[recipientId],
                          !isSociallyUrgent(recipient),
                          !hasMaterialTransaction(recipient),
                          trustScore(sourceAgentId: recipientId, targetAgentId: senderId)
                            >= configuration.socialConfiguration.minimumTrustToVerify else {
                        return nil
                    }
                    let distance = manhattanDistance(sender.position, recipient.position)
                    guard distance <= configuration.socialConfiguration.communicationRadius,
                          !socialMessages.contains(where: {
                              $0.senderID.rawValue == senderId
                                && $0.recipientID.rawValue == recipientId
                                && $0.fact.factID == fact.factID
                                && $0.fact.directObservationEventID == fact.directObservationEventID
                          }),
                          !socialBeliefs.contains(where: {
                              $0.ownerID.rawValue == recipientId
                                && $0.senderID.rawValue == senderId
                                && $0.fact.factID == fact.factID
                                && $0.status == .unverified
                          }),
                          let recipientID = AgentID(rawValue: recipientId) else { return nil }
                    guard !hasPendingPhysicalSignal(
                        senderID: fact.observerID,
                        recipientID: recipientID,
                        factID: fact.factID
                    ) else { return nil }
                    return (recipientID, distance)
                }.sorted {
                    if $0.1 != $1.1 { return $0.1 < $1.1 }
                    return $0.0 < $1.0
                }
                if let recipient = recipients.first?.0 {
                    shares[senderId] = AgentSocialShareIntent(
                        senderID: fact.observerID,
                        recipientID: recipient,
                        factID: fact.factID
                    )
                    break
                }
            }
        }
        return AgentSocialTickPlan(
            shareIntentsByAgentId: shares,
            verificationBeliefsByAgentId: verification,
            expiredBeliefIDs: expired.sorted()
        )
    }

    mutating func activateSocialVerification(
        agentId: String,
        candidate: AgentSocialBeliefID?,
        selectedGoal: AgentGoalKind
    ) {
        guard socialEnabled, !isMigratingAgent(agentId),
              selectedGoal == .verifySocialInformation, let candidate else { return }
        activeSocialVerificationByAgentId[agentId] = candidate
    }

    func socialVerificationRequest(
        candidate: AgentSocialBeliefID?,
        for agentId: String
    ) -> AgentSocialVerificationRequest? {
        let selected = activeSocialVerificationByAgentId[agentId] ?? candidate
        guard let selected,
              let belief = socialBeliefs.first(where: { $0.beliefID == selected }),
              belief.ownerID.rawValue == agentId,
              belief.status == .unverified else { return nil }
        return AgentSocialVerificationRequest(
            beliefID: belief.beliefID,
            verifierID: belief.ownerID,
            senderID: belief.senderID,
            resource: belief.fact.resource,
            position: belief.fact.position,
            expectedBlockFingerprint: belief.fact.expectedBlockFingerprint
        )
    }

    mutating func recordGroundedSocialFacts(
        observerID: AgentID,
        observations: [AgentResourceObservation],
        perceptionEventID: AgentCausalEventID,
        at factTick: Int
    ) throws {
        guard socialEnabled, !isMigratingAgent(observerID.rawValue) else { return }
        for observation in observations.sorted(by: AgentResourcePerception.sortsBefore) {
            guard observation.source == .naturalWorld,
                  observation.resource == .wood || observation.resource == .stone,
                  let fingerprint = observation.expectedBlockFingerprint else { continue }
            let identity = observation.identity
            guard !socialFacts.contains(where: {
                $0.observerID == observerID && $0.stableKey == identity.stableKey
                    && !$0.isExpired(at: factTick)
            }) else { continue }
            let rawID = "fact-" + AgentSocialDigest.make(
                "\(observerID.rawValue)|\(factTick)|\(identity.stableKey)|\(perceptionEventID.rawValue)"
            )
            let factID = AgentSocialFactID(rawValue: rawID)!
            let event = try requiredSocialEvent(
                kind: .resourceFactGrounded,
                actorID: observerID,
                subjectID: observerID,
                causes: [perceptionEventID],
                payload: .resourceFact(
                    factID: factID.rawValue,
                    observerID: observerID.rawValue,
                    resource: observation.resource,
                    position: observation.target,
                    fingerprint: fingerprint
                ),
                summary: "direct natural fact actor=\(observerID.rawValue) resource=\(observation.resource.rawValue)"
            )
            let fact = AgentSocialFact(
                factID: factID,
                observerID: observerID,
                resource: observation.resource,
                position: observation.target,
                stableKey: identity.stableKey,
                expectedBlockFingerprint: fingerprint,
                observedAtTick: factTick,
                expiresAtTick: factTick + configuration.socialConfiguration.claimLifetimeTicks,
                directObservationEventID: event.eventID
            )
            socialFacts.append(fact)
            try recordKnowledgeDirectResourceObservation(
                observerID: observerID,
                position: observation.target,
                resource: observation.resource,
                fingerprint: fingerprint,
                authority: .validatedWorldObservation,
                authorityEventID: event.eventID
            )
            enforceFactBound(for: observerID)
        }
    }

    mutating func applySocialTickPlan(
        _ plan: AgentSocialTickPlan,
        results: [AgentSessionAgentTickResult]
    ) throws {
        guard socialEnabled else { return }
        for beliefID in plan.expiredBeliefIDs.sorted() {
            guard let belief = socialBeliefs.first(where: { $0.beliefID == beliefID }) else { continue }
            _ = try requiredSocialEvent(
                kind: .socialBeliefChanged,
                actorID: belief.ownerID,
                subjectID: belief.senderID,
                causes: [belief.receivedEventID],
                payload: .socialBelief(
                    beliefID: belief.beliefID.rawValue,
                    messageID: belief.messageID.rawValue,
                    status: AgentSocialBeliefStatus.expired.rawValue,
                    reason: "lifetimeElapsed"
                ),
                summary: "social belief expired owner=\(belief.ownerID.rawValue)"
            )
        }
        let resultByID = Dictionary(uniqueKeysWithValues: results.map { ($0.agentId, $0) })
        for senderId in plan.shareIntentsByAgentId.keys.sorted() {
            guard let intent = plan.shareIntentsByAgentId[senderId],
                  resultByID[senderId]?.action.name == "share_information" else { continue }
            if physicalEnabled {
                try emitPhysicalSignal(intent)
            } else {
                _ = try deliverSocialMessage(intent)
            }
        }
    }

    public mutating func applySocialVerification(
        _ observation: AgentSocialVerificationObservation
    ) throws -> AgentSocialVerificationResult {
        var candidate = self
        let result = try candidate.applySocialVerificationInPlace(observation)
        self = candidate
        return result
    }

    private mutating func applySocialVerificationInPlace(
        _ observation: AgentSocialVerificationObservation
    ) throws -> AgentSocialVerificationResult {
        guard socialEnabled else { throw AgentSessionError.social(.socialDisabled) }
        guard let index = socialBeliefs.firstIndex(where: {
            $0.beliefID == observation.beliefID
        }), socialBeliefs[index].ownerID == observation.verifierID,
        socialBeliefs[index].status == .unverified,
        activeSocialVerificationByAgentId[observation.verifierID.rawValue] == observation.beliefID,
        observation.position == socialBeliefs[index].fact.position,
        let state = statesById[observation.verifierID.rawValue],
        state.lastAction?.name == "verify_information",
        state.lastAction?.target == observation.position,
        manhattanDistance(state.position, observation.position) <= 1 else {
            throw AgentSessionError.social(.invalidVerification(observation.beliefID.rawValue))
        }
        try prevalidateCausalAppend(
            count: observation.chunkReady ? (knowledgeGraphEnabled ? 6 : 3) : 1
        )
        let belief = socialBeliefs[index]
        let result: AgentSocialVerificationResult
        if !observation.chunkReady {
            result = .inconclusive
        } else if observation.observedBlockFingerprint == belief.fact.expectedBlockFingerprint,
                  observation.observedResource == belief.fact.resource {
            result = .confirmed
        } else {
            result = .contradicted
        }
        let causes = [
            belief.receivedEventID,
            lastDecisionEventByAgentID[observation.verifierID],
        ].compactMap { $0 }.sorted()
        let verificationEvent = try requiredSocialEvent(
            kind: .socialVerification,
            actorID: observation.verifierID,
            subjectID: belief.senderID,
            causes: Array(Set(causes)).sorted(),
            payload: .socialVerification(
                beliefID: belief.beliefID.rawValue,
                expectedFingerprint: belief.fact.expectedBlockFingerprint,
                observedFingerprint: observation.observedBlockFingerprint,
                result: result.rawValue
            ),
            summary: "social verification \(result.rawValue) verifier=\(observation.verifierID.rawValue)"
        )
        guard result != .inconclusive else { return result }

        socialBeliefs[index].status = result == .confirmed ? .confirmed : .contradicted
        socialBeliefs[index].verifiedAtTick = tick
        socialBeliefs[index].verificationEventID = verificationEvent.eventID
        socialBeliefs[index].reason = result == .confirmed
            ? "direct World fingerprint matched"
            : "direct World fingerprint or resource differed"
        _ = try requiredSocialEvent(
            kind: .socialBeliefChanged,
            actorID: observation.verifierID,
            subjectID: belief.senderID,
            causes: [verificationEvent.eventID],
            payload: .socialBelief(
                beliefID: belief.beliefID.rawValue,
                messageID: belief.messageID.rawValue,
                status: socialBeliefs[index].status.rawValue,
                reason: result.rawValue
            ),
            summary: "social belief \(result.rawValue) owner=\(observation.verifierID.rawValue)"
        )
        let requestedDelta = result == .confirmed
            ? configuration.socialConfiguration.confirmedTrustDelta
            : configuration.socialConfiguration.contradictedTrustDelta
        try applyTrustChange(
            sourceID: observation.verifierID,
            targetID: belief.senderID,
            requestedDelta: requestedDelta,
            result: result,
            verificationEventID: verificationEvent.eventID
        )
        try recordKnowledgeDirectResourceObservation(
            observerID: observation.verifierID,
            position: observation.position,
            resource: observation.observedResource,
            fingerprint: observation.observedBlockFingerprint,
            authority: .validatedSocialVerification,
            authorityEventID: verificationEvent.eventID,
            interpretation: result == .contradicted
                ? .revisedByContradictoryObservation
                : .directlyObserved
        )
        activeSocialVerificationByAgentId.removeValue(forKey: observation.verifierID.rawValue)
        return result
    }

    func canDeliverSocialMessage(_ intent: AgentSocialShareIntent) -> Bool {
        guard let fact = socialFacts.first(where: { $0.factID == intent.factID }),
              !isMigratingAgent(intent.senderID.rawValue),
              !isMigratingAgent(intent.recipientID.rawValue),
              fact.observerID == intent.senderID,
              !fact.isExpired(at: tick),
              let sender = statesById[intent.senderID.rawValue],
              let recipient = statesById[intent.recipientID.rawValue],
              manhattanDistance(sender.position, recipient.position)
                <= configuration.socialConfiguration.communicationRadius,
              !isSociallyUrgent(recipient),
              !hasMaterialTransaction(recipient),
              trustScore(
                sourceAgentId: intent.recipientID.rawValue,
                targetAgentId: intent.senderID.rawValue
              ) >= configuration.socialConfiguration.minimumTrustToVerify,
              !socialMessages.contains(where: {
                  $0.senderID == intent.senderID && $0.recipientID == intent.recipientID
                    && $0.fact.factID == intent.factID
                    && $0.fact.directObservationEventID == fact.directObservationEventID
              }) else { return false }
        return true
    }

    /// Shared, actor-neutral direct/social locality authority. Domain-specific
    /// communication may compose this reachability decision without acquiring
    /// the fact-specific delivery and trust-state mutation owned by CIV-03.
    func canUseDirectSocialCommunicationAuthority(
        speakerID: AgentID,
        recipientID: AgentID
    ) -> Bool {
        guard socialEnabled,
              speakerID != recipientID,
              !isMigratingAgent(speakerID.rawValue),
              !isMigratingAgent(recipientID.rawValue),
              let speaker = statesById[speakerID.rawValue],
              let recipient = statesById[recipientID.rawValue],
              !isSociallyUrgent(recipient),
              !hasMaterialTransaction(recipient),
              trustScore(
                sourceAgentId: recipientID.rawValue,
                targetAgentId: speakerID.rawValue
              ) >= configuration.socialConfiguration.minimumTrustToVerify,
              manhattanDistance(speaker.position, recipient.position)
                <= configuration.socialConfiguration.communicationRadius else {
            return false
        }
        return true
    }

    @discardableResult
    mutating func deliverSocialMessage(
        _ intent: AgentSocialShareIntent,
        physicalCause: AgentCausalEventID? = nil
    ) throws -> Bool {
        guard canDeliverSocialMessage(intent),
              let fact = socialFacts.first(where: { $0.factID == intent.factID }) else {
            return false
        }
        let messageID = AgentSocialMessageID(rawValue: "message-" + AgentSocialDigest.make(
            "\(intent.senderID.rawValue)|\(intent.recipientID.rawValue)|\(fact.factID.rawValue)|\(tick)"
        ))!
        let beliefID = AgentSocialBeliefID(rawValue: "belief-" + AgentSocialDigest.make(
            "\(intent.recipientID.rawValue)|\(messageID.rawValue)"
        ))!
        let directCauses = [
            fact.directObservationEventID,
            lastDecisionEventByAgentID[intent.senderID],
        ].compactMap { $0 }
        let sendCauses = physicalCause.map { [$0] } ?? directCauses
        let sent = try requiredSocialEvent(
            kind: .socialMessageSent,
            actorID: intent.senderID,
            subjectID: intent.recipientID,
            causes: Array(Set(sendCauses)).sorted(),
            payload: .socialMessage(
                messageID: messageID.rawValue,
                factID: fact.factID.rawValue,
                status: "sent"
            ),
            summary: "directed social message sent \(intent.senderID.rawValue)>\(intent.recipientID.rawValue)"
        )
        let received = try requiredSocialEvent(
            kind: .socialMessageReceived,
            actorID: intent.senderID,
            subjectID: intent.recipientID,
            causes: [sent.eventID],
            payload: .socialMessage(
                messageID: messageID.rawValue,
                factID: fact.factID.rawValue,
                status: "received"
            ),
            summary: "directed social message received recipient=\(intent.recipientID.rawValue)"
        )
        _ = try requiredSocialEvent(
            kind: .socialBeliefChanged,
            actorID: intent.recipientID,
            subjectID: intent.senderID,
            causes: [received.eventID],
            payload: .socialBelief(
                beliefID: beliefID.rawValue,
                messageID: messageID.rawValue,
                status: AgentSocialBeliefStatus.unverified.rawValue,
                reason: "directMessageReceived"
            ),
            summary: "unverified social belief formed owner=\(intent.recipientID.rawValue)"
        )
        let expiry = min(
            fact.expiresAtTick,
            tick + configuration.socialConfiguration.messageLifetimeTicks
        )
        let message = AgentSocialMessage(
            messageID: messageID,
            senderID: intent.senderID,
            recipientID: intent.recipientID,
            fact: fact,
            sentAtTick: tick,
            receivedAtTick: tick,
            expiresAtTick: expiry,
            sentEventID: sent.eventID,
            receivedEventID: received.eventID,
            status: .received
        )
        socialMessages.append(message)
        socialBeliefs.append(AgentSocialBelief(
            beliefID: beliefID,
            ownerID: intent.recipientID,
            senderID: intent.senderID,
            fact: fact,
            messageID: messageID,
            directProvenanceEventID: fact.directObservationEventID,
            receivedEventID: received.eventID,
            receivedAtTick: tick,
            expiresAtTick: expiry,
            status: .unverified,
            verifiedAtTick: nil,
            verificationEventID: nil,
            reason: "structured directed message received; World not yet checked"
        ))
        lastSocialShareTickByAgentId[intent.senderID.rawValue] = tick
        enforceMessageBound()
        enforceBeliefBound(for: intent.recipientID)
        try recordKnowledgeSourceClaim(message: message)
        return true
    }

    private mutating func applyTrustChange(
        sourceID: AgentID,
        targetID: AgentID,
        requestedDelta: Int,
        result: AgentSocialVerificationResult,
        verificationEventID: AgentCausalEventID
    ) throws {
        let relationID = AgentTrustRelationID(
            rawValue: "trust-\(sourceID.rawValue)-to-\(targetID.rawValue)"
        )!
        let existingIndex = socialTrustRelations.firstIndex { $0.relationID == relationID }
        let before = existingIndex.map { socialTrustRelations[$0].score } ?? 0
        let after = min(
            configuration.socialConfiguration.maximumTrust,
            max(configuration.socialConfiguration.minimumTrust, before + requestedDelta)
        )
        let actualDelta = after - before
        let event = try requiredSocialEvent(
            kind: .trustChanged,
            actorID: sourceID,
            subjectID: targetID,
            causes: [verificationEventID],
            payload: .trust(
                relationID: relationID.rawValue,
                before: before,
                delta: actualDelta,
                after: after
            ),
            summary: "directed trust \(sourceID.rawValue)>\(targetID.rawValue) \(before)>\(after)"
        )
        if let existingIndex {
            socialTrustRelations[existingIndex].score = after
            socialTrustRelations[existingIndex].confirmationCount += result == .confirmed ? 1 : 0
            socialTrustRelations[existingIndex].contradictionCount += result == .contradicted ? 1 : 0
            socialTrustRelations[existingIndex].lastChangedAtTick = tick
            socialTrustRelations[existingIndex].lastChangeEventID = event.eventID
        } else {
            socialTrustRelations.append(AgentTrustRelation(
                relationID: relationID,
                sourceID: sourceID,
                targetID: targetID,
                score: after,
                confirmationCount: result == .confirmed ? 1 : 0,
                contradictionCount: result == .contradicted ? 1 : 0,
                lastChangedAtTick: tick,
                lastChangeEventID: event.eventID
            ))
            enforceTrustBound()
        }
    }

    private mutating func requiredSocialEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .socialTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else { throw AgentSessionError.social(.causalLedgerRequired) }
        return event
    }

    func isSociallyUrgent(_ state: AgentSessionAgentState) -> Bool {
        if state.health <= 25 || state.fear >= 70 || state.needs.safety < 0.5 { return true }
        if survivalEnabled {
            if state.needs.hunger >= configuration.survivalConfiguration.hungryThreshold
                || state.needs.fatigue >= configuration.survivalConfiguration.fatigueThreshold {
                return true
            }
        }
        return false
    }

    func hasMaterialTransaction(_ state: AgentSessionAgentState) -> Bool {
        switch state.currentGoal.kind {
        case .satisfyHunger, .seekSafety, .rest, .deliverResources, .buildShelter,
             .migrateToSettlement:
            return true
        case .collectResource:
            return reservation(for: state)?.agentId == state.id
        default:
            return false
        }
    }

    private mutating func enforceFactBound(for observerID: AgentID) {
        let indices = socialFacts.indices.filter {
            socialFacts[$0].observerID == observerID
        }.sorted {
            let lhs = socialFacts[$0]
            let rhs = socialFacts[$1]
            if lhs.observedAtTick != rhs.observedAtTick { return lhs.observedAtTick < rhs.observedAtTick }
            return lhs.factID < rhs.factID
        }
        let excess = indices.count - configuration.socialConfiguration.maximumFactsPerAgent
        guard excess > 0 else { return }
        for index in indices.prefix(excess).sorted(by: >) { socialFacts.remove(at: index) }
        socialEvictionCounts.facts += excess
    }

    private mutating func enforceMessageBound() {
        let excess = socialMessages.count - configuration.socialConfiguration.maximumRetainedMessages
        guard excess > 0 else { return }
        socialMessages.sort {
            if $0.receivedAtTick != $1.receivedAtTick { return $0.receivedAtTick < $1.receivedAtTick }
            return $0.messageID < $1.messageID
        }
        socialMessages.removeFirst(excess)
        socialEvictionCounts.messages += excess
    }

    private mutating func enforceBeliefBound(for ownerID: AgentID) {
        let indices = socialBeliefs.indices.filter {
            socialBeliefs[$0].ownerID == ownerID
        }.sorted {
            let lhs = socialBeliefs[$0]
            let rhs = socialBeliefs[$1]
            if lhs.receivedAtTick != rhs.receivedAtTick { return lhs.receivedAtTick < rhs.receivedAtTick }
            return lhs.beliefID < rhs.beliefID
        }
        let excess = indices.count - configuration.socialConfiguration.maximumBeliefsPerAgent
        guard excess > 0 else { return }
        for index in indices.prefix(excess).sorted(by: >) {
            activeSocialVerificationByAgentId.removeValue(
                forKey: socialBeliefs[index].ownerID.rawValue
            )
            socialBeliefs.remove(at: index)
        }
        socialEvictionCounts.beliefs += excess
    }

    private mutating func enforceTrustBound() {
        let excess = socialTrustRelations.count
            - configuration.socialConfiguration.maximumTrustRelations
        guard excess > 0 else { return }
        socialTrustRelations.sort {
            if $0.lastChangedAtTick != $1.lastChangedAtTick {
                return $0.lastChangedAtTick < $1.lastChangedAtTick
            }
            return $0.relationID < $1.relationID
        }
        socialTrustRelations.removeFirst(excess)
        socialEvictionCounts.trustRelations += excess
    }
}

private extension AgentCausalEventKind {
    var isSocial: Bool {
        switch self {
        case .resourceFactGrounded, .socialMessageSent, .socialMessageReceived,
             .socialBeliefChanged, .socialVerification, .trustChanged, .socialStateCleared:
            return true
        default:
            return false
        }
    }
}
