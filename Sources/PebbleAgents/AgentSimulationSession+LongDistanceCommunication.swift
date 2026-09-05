extension AgentSimulationSession {
    public var longDistanceCommunicationEnabled: Bool {
        longDistanceCommunicationState?.enabled == true
    }

    public mutating func setLongDistanceCommunicationEnabled(
        _ enabled: Bool,
        configuration: AgentLongDistanceCommunicationConfiguration = .live
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.longDistanceCommunication(
                .causalLedgerRequired
            )
        }
        guard socialEnabled else {
            throw AgentSessionError.longDistanceCommunication(.socialRequired)
        }
        guard knowledgeGraphEnabled else {
            throw AgentSessionError.longDistanceCommunication(.knowledgeRequired)
        }
        guard languageState?.enabled == true else {
            throw AgentSessionError.longDistanceCommunication(.languageRequired)
        }
        guard oralTransmissionEnabled else {
            throw AgentSessionError.longDistanceCommunication(.oralRequired)
        }
        guard autonomousActivityEnabled else {
            throw AgentSessionError.longDistanceCommunication(
                .autonomousActivityRequired
            )
        }
        if longDistanceCommunicationState?.enabled == enabled {
            if enabled,
               longDistanceCommunicationState?.configuration
                != configuration {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState(
                        "configuration cannot change while enabled"
                    )
                )
            }
            return
        }
        if !enabled,
           longDistanceCommunicationState?.transports.contains(where: {
               !$0.status.isTerminal
           }) == true {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("active transports must end first")
            )
        }

        var candidate = self
        var state = candidate.longDistanceCommunicationState
            ?? AgentLongDistanceCommunicationState(configuration: configuration)
        guard state.configuration == configuration else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState(
                    "configuration cannot change after initialization"
                )
            )
        }
        state.enabled = enabled
        let event = try candidate.requiredCommunicationTransportEvent(
            kind: .communicationTransportInitialized,
            actorID: nil,
            subjectID: nil,
            causes: [],
            transportID: "communication-transport",
            authorID: nil,
            carrierID: nil,
            destinationID: nil,
            status: enabled ? "enabled" : "disabled",
            detail: "explicit feature transition",
            summary:
                "long-distance communication "
                + (enabled ? "enabled" : "disabled")
        )
        candidate.longDistanceCommunicationState = state
        _ = event
        try candidate.validateLongDistanceCommunicationStateIfInitialized()
        self = candidate
    }

    public func longDistanceCommunicationSnapshot()
        -> AgentLongDistanceCommunicationSnapshot {
        guard let state = longDistanceCommunicationState else {
            return AgentLongDistanceCommunicationSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                transports: [],
                evictedTransportCount: 0,
                totalStartedCount: 0,
                totalDeliveredCount: 0,
                totalFailedCount: 0,
                provenanceBoundary: nil,
                digest: AgentLongDistanceCommunicationDigest.make(
                    "communication-transport:none"
                )
            )
        }
        let transports = state.transports.sorted(
            by: communicationTransportSort
        )
        let digest = AgentLongDistanceCommunicationDigest.make([
            "communication-transport-snapshot-v1",
            state.enabled ? "1" : "0",
            String(state.configuration.maximumRetainedTransports),
            String(state.configuration.maximumJourneySteps),
            String(state.configuration.maximumTransportDistance),
            transports.map(communicationTransportCanonicalText)
                .joined(separator: ";"),
            String(state.evictedTransportCount),
            String(state.totalStartedCount),
            String(state.totalDeliveredCount),
            String(state.totalFailedCount),
            String(state.nextTransportOrdinal),
            state.provenanceBoundary.map {
                "\($0.eventID.rawValue):\($0.digest)"
            } ?? "none",
        ].joined(separator: "|"))
        return AgentLongDistanceCommunicationSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            transports: transports,
            evictedTransportCount: state.evictedTransportCount,
            totalStartedCount: state.totalStartedCount,
            totalDeliveredCount: state.totalDeliveredCount,
            totalFailedCount: state.totalFailedCount,
            provenanceBoundary: state.provenanceBoundary,
            digest: digest
        )
    }

    public func longDistanceCommunicationSummary()
        -> AgentLongDistanceCommunicationSummary {
        let snapshot = longDistanceCommunicationSnapshot()
        return AgentLongDistanceCommunicationSummary(
            enabled: snapshot.enabled,
            retainedTransportCount: snapshot.transports.count,
            inTransitCount: snapshot.transports.filter {
                $0.status == .inTransit
            }.count,
            arrivedCount: snapshot.transports.filter {
                $0.status == .arrived
            }.count,
            deliveredCount: snapshot.totalDeliveredCount,
            failedCount: snapshot.totalFailedCount,
            evictedTransportCount: snapshot.evictedTransportCount,
            acceptedMovementStepCount: snapshot.transports.reduce(0) {
                $0 + $1.progress.count
            },
            digest: snapshot.digest
        )
    }

    /// Begins a transport by composing an ordinary, local CIV-43 pickup.
    /// The destination receives no semantic or epistemic effect here.
    @discardableResult
    public mutating func beginLongDistanceCommunication(
        authorID: AgentID,
        carrierID: AgentID,
        destinationID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode
    ) throws -> AgentCommunicationTransport {
        try beginLongDistanceCommunication(
            authorID: authorID,
            carrierID: carrierID,
            destinationID: destinationID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            recordedPickupEffect: nil
        )
    }

    @discardableResult
    mutating func beginLongDistanceCommunication(
        authorID: AgentID,
        carrierID: AgentID,
        destinationID: AgentID,
        propositionID: AgentKnowledgePropositionID,
        renderingMode: AgentLanguageRenderingMode,
        recordedPickupEffect: AgentOralAcceptedEffect?
    ) throws -> AgentCommunicationTransport {
        guard let transportState = longDistanceCommunicationState,
              transportState.enabled else {
            throw AgentSessionError.longDistanceCommunication(.disabled)
        }
        guard autonomousActivityEnabled else {
            throw AgentSessionError.longDistanceCommunication(
                .autonomousActivityRequired
            )
        }
        guard authorID != carrierID, authorID != destinationID,
              carrierID != destinationID else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidParticipant(
                    "\(authorID.rawValue)>\(carrierID.rawValue)>"
                        + destinationID.rawValue
                )
            )
        }
        guard let author = statesById[authorID.rawValue] else {
            throw AgentSessionError.longDistanceCommunication(
                .unknownAgent(authorID.rawValue)
            )
        }
        guard let carrier = statesById[carrierID.rawValue] else {
            throw AgentSessionError.longDistanceCommunication(
                .unknownAgent(carrierID.rawValue)
            )
        }
        guard let destination = statesById[destinationID.rawValue] else {
            throw AgentSessionError.longDistanceCommunication(
                .unknownAgent(destinationID.rawValue)
            )
        }
        guard !isMigratingAgent(authorID.rawValue),
              !isMigratingAgent(carrierID.rawValue),
              !isMigratingAgent(destinationID.rawValue) else {
            throw AgentSessionError.longDistanceCommunication(
                .migratingParticipant(
                    "\(authorID.rawValue)>\(carrierID.rawValue)>"
                        + destinationID.rawValue
                )
            )
        }
        let radius = configuration.socialConfiguration.communicationRadius
        let pickupDistance = manhattanDistance(
            author.position, carrier.position
        )
        guard pickupDistance <= radius,
              canUseDirectSocialCommunicationAuthority(
                  speakerID: authorID,
                  recipientID: carrierID
              ) else {
            throw AgentSessionError.longDistanceCommunication(
                .localPickupRefused(
                    "\(authorID.rawValue)>\(carrierID.rawValue)"
                )
            )
        }
        let authorDestinationDistance = manhattanDistance(
            author.position, destination.position
        )
        let carrierDestinationDistance = manhattanDistance(
            carrier.position, destination.position
        )
        guard authorDestinationDistance > radius,
              carrierDestinationDistance > radius else {
            throw AgentSessionError.longDistanceCommunication(
                .destinationNotRemote(
                    distance: min(
                        authorDestinationDistance,
                        carrierDestinationDistance
                    ),
                    radius: radius
                )
            )
        }
        guard carrierDestinationDistance
                <= transportState.configuration.maximumTransportDistance else {
            throw AgentSessionError.longDistanceCommunication(
                .destinationTooFar(
                    distance: carrierDestinationDistance,
                    maximum:
                        transportState.configuration.maximumTransportDistance
                )
            )
        }
        guard !transportState.transports.contains(where: {
            $0.carrierID == carrierID && !$0.status.isTerminal
        }) else {
            throw AgentSessionError.longDistanceCommunication(
                .carrierBusy(carrierID.rawValue)
            )
        }

        var candidate = self
        try candidate.compactLongDistanceCommunicationForAdmission()
        guard var state = candidate.longDistanceCommunicationState,
              state.nextTransportOrdinal < UInt64.max,
              state.totalStartedCount < Int.max else {
            throw AgentSessionError.longDistanceCommunication(
                .capacityReached("transport ordinal")
            )
        }
        let pickup = try candidate.transmitOralClaim(
            speakerID: authorID,
            recipientID: carrierID,
            propositionID: propositionID,
            renderingMode: renderingMode,
            recordedEffect: recordedPickupEffect
        )
        guard let carrierBelief = candidate.knowledgeGraphState?.beliefs
            .first(where: {
                $0.ownerID == carrierID
                    && $0.beliefID == pickup.recipientBeliefID
                    && $0.lastRevisionEventID
                        == pickup.recipientBeliefRevisionEventID
                    && $0.propositionID
                        == pickup.interpretedSemanticContent
                            .sourcePropositionID
            }) else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("pickup did not publish carrier belief")
            )
        }
        let transportID = AgentCommunicationTransportID(
            rawValue:
                "communication-transport-\(state.nextTransportOrdinal)"
        )!
        let dispatchEvent =
            try candidate.requiredCommunicationTransportEvent(
                kind: .communicationTransportDispatched,
                actorID: authorID,
                subjectID: carrierID,
                causes: [
                    pickup.receiptEventID,
                    pickup.recipientBeliefRevisionEventID,
                ],
                transportID: transportID.rawValue,
                authorID: authorID,
                carrierID: carrierID,
                destinationID: destinationID,
                status: AgentCommunicationTransportStatus.inTransit.rawValue,
                detail: pickup.interpretedSemanticContent.digest,
                summary:
                    "communication transport dispatched author="
                    + "\(authorID.rawValue) carrier=\(carrierID.rawValue) "
                    + "destination=\(destinationID.rawValue)"
            )
        var record = AgentCommunicationTransport(
            transportID: transportID,
            authorID: authorID,
            carrierID: carrierID,
            destinationID: destinationID,
            sourceAuthorityID: pickup.sourceAuthorityID,
            pickupTransmissionID: pickup.transmissionID,
            pickupReceiptEventID: pickup.receiptEventID,
            originSemanticContentDigest:
                pickup.transmittedSemanticContent.digest,
            carriedSemanticContentDigest:
                pickup.interpretedSemanticContent.digest,
            carriedPropositionID:
                pickup.interpretedSemanticContent.sourcePropositionID,
            carrierBeliefID: carrierBelief.beliefID,
            carrierBeliefRevisionEventID:
                carrierBelief.lastRevisionEventID,
            dispatchPosition: carrier.position,
            destinationPositionAtDispatch: destination.position,
            initialDistance: carrierDestinationDistance,
            startedAtTick: candidate.tick,
            dispatchEventID: dispatchEvent.eventID,
            progress: [],
            status: .inTransit,
            arrivalPosition: nil,
            destinationPositionAtArrival: nil,
            arrivedAtTick: nil,
            arrivalEventID: nil,
            deliveryTransmissionID: nil,
            destinationBeliefID: nil,
            destinationBeliefRevisionEventID: nil,
            deliveredAtTick: nil,
            deliveryEventID: nil,
            failure: nil,
            failedAtTick: nil,
            failureEventID: nil,
            provenanceDigest: ""
        )
        record.provenanceDigest =
            communicationTransportRecordDigest(record)
        state = candidate.longDistanceCommunicationState ?? state
        state.transports.append(record)
        state.transports.sort(by: candidate.communicationTransportSort)
        state.totalStartedCount += 1
        state.nextTransportOrdinal += 1
        candidate.longDistanceCommunicationState = state
        try candidate.commitLongDistanceCommunicationProvenanceBoundary(
            causes: [dispatchEvent.eventID]
        )
        try candidate.validateLongDistanceCommunicationStateIfInitialized()
        self = candidate
        return record
    }

    /// Produces pure cognition candidates for the existing generic
    /// civilization-activity navigation path. This creates no movement and
    /// changes no residence or settlement membership.
    public func longDistanceCommunicationActivityCandidates()
        -> [AgentAutonomousActivityCandidate] {
        guard let state = longDistanceCommunicationState, state.enabled else {
            return []
        }
        return state.transports.filter {
            $0.status == .inTransit
        }.sorted(by: communicationTransportSort).compactMap { transport in
            guard let carrier = statesById[transport.carrierID.rawValue],
                  let destination = statesById[
                      transport.destinationID.rawValue
                  ] else { return nil }
            return AgentAutonomousActivityCandidate(
                candidateID:
                    "communication:\(transport.transportID.rawValue)",
                actorID: transport.carrierID,
                domain: .communication,
                actionKey: "deliver_semantic_transport",
                stableReference: transport.transportID.rawValue,
                target: destination.position,
                logicalTargetKey: transport.transportID.rawValue,
                physicalTarget: destination.position,
                approachPosition: destination.position,
                materialFingerprint:
                    transport.carriedSemanticContentDigest,
                source: .responsibility,
                priorityBand: 15,
                urgency: 90,
                continuity: activeAutonomousActivity(
                    for: transport.carrierID
                )?.candidate.stableReference
                    == transport.transportID.rawValue,
                distance: manhattanDistance(
                    carrier.position, destination.position
                ),
                observedAtTick: tick
            )
        }
    }

    /// Completes transport only after accepted movement has published a local
    /// arrival. The final consequence is an ordinary CIV-43 handoff.
    @discardableResult
    public mutating func deliverLongDistanceCommunication(
        transportID: AgentCommunicationTransportID,
        renderingMode: AgentLanguageRenderingMode
    ) throws -> AgentCommunicationTransport {
        try deliverLongDistanceCommunication(
            transportID: transportID,
            renderingMode: renderingMode,
            recordedDeliveryEffect: nil
        )
    }

    @discardableResult
    mutating func deliverLongDistanceCommunication(
        transportID: AgentCommunicationTransportID,
        renderingMode: AgentLanguageRenderingMode,
        recordedDeliveryEffect: AgentOralAcceptedEffect?
    ) throws -> AgentCommunicationTransport {
        guard let state = longDistanceCommunicationState, state.enabled else {
            throw AgentSessionError.longDistanceCommunication(.disabled)
        }
        guard let record = state.transports.first(where: {
            $0.transportID == transportID
        }) else {
            throw AgentSessionError.longDistanceCommunication(
                .transportNotFound(transportID.rawValue)
            )
        }
        guard record.status == .arrived,
              let arrivalEventID = record.arrivalEventID else {
            throw AgentSessionError.longDistanceCommunication(
                .transportNotArrived(transportID.rawValue)
            )
        }
        guard let carrier = statesById[record.carrierID.rawValue],
              let destination = statesById[
                  record.destinationID.rawValue
              ] else {
            throw AgentSessionError.longDistanceCommunication(
                .destinationConditionRefused(transportID.rawValue)
            )
        }
        guard manhattanDistance(carrier.position, destination.position) <= 1
        else {
            throw AgentSessionError.longDistanceCommunication(
                .destinationConditionRefused(transportID.rawValue)
            )
        }
        guard let belief = knowledgeGraphState?.beliefs.first(where: {
            $0.ownerID == record.carrierID
                && $0.beliefID == record.carrierBeliefID
                && $0.propositionID == record.carriedPropositionID
        }) else {
            throw AgentSessionError.longDistanceCommunication(
                .carrierBeliefChanged(transportID.rawValue)
            )
        }

        var candidate = self
        let delivery = try candidate.transmitOralClaim(
            speakerID: record.carrierID,
            recipientID: record.destinationID,
            propositionID: belief.propositionID,
            renderingMode: renderingMode,
            recordedEffect: recordedDeliveryEffect
        )
        guard delivery.sourceBeliefID == record.carrierBeliefID,
              delivery.transmittedSemanticContent.digest
                == record.carriedSemanticContentDigest,
              delivery.transmittedSemanticContent.sourcePropositionID
                == record.carriedPropositionID else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("delivery bypassed carried semantic authority")
            )
        }
        let event = try candidate.requiredCommunicationTransportEvent(
            kind: .communicationTransportDelivered,
            actorID: record.carrierID,
            subjectID: record.destinationID,
            causes: [
                arrivalEventID,
                delivery.receiptEventID,
                delivery.recipientBeliefRevisionEventID,
            ],
            transportID: transportID.rawValue,
            authorID: record.authorID,
            carrierID: record.carrierID,
            destinationID: record.destinationID,
            status: AgentCommunicationTransportStatus.delivered.rawValue,
            detail: delivery.interpretedSemanticContent.digest,
            summary:
                "communication transport delivered carrier="
                + "\(record.carrierID.rawValue) destination="
                + record.destinationID.rawValue
        )
        guard var candidateState = candidate.longDistanceCommunicationState,
              let index = candidateState.transports.firstIndex(where: {
                  $0.transportID == transportID
              }) else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("transport disappeared during delivery")
            )
        }
        candidateState.transports[index].status = .delivered
        candidateState.transports[index].deliveryTransmissionID =
            delivery.transmissionID
        candidateState.transports[index].destinationBeliefID =
            delivery.recipientBeliefID
        candidateState.transports[index]
            .destinationBeliefRevisionEventID =
                delivery.recipientBeliefRevisionEventID
        candidateState.transports[index].deliveredAtTick = candidate.tick
        candidateState.transports[index].deliveryEventID = event.eventID
        candidateState.transports[index].provenanceDigest =
            communicationTransportRecordDigest(
                candidateState.transports[index]
            )
        guard candidateState.totalDeliveredCount < Int.max else {
            throw AgentSessionError.longDistanceCommunication(
                .capacityReached("delivered counter")
            )
        }
        candidateState.totalDeliveredCount += 1
        candidate.longDistanceCommunicationState = candidateState
        try candidate.commitLongDistanceCommunicationProvenanceBoundary(
            causes: [event.eventID]
        )
        if let activity = candidate.activeAutonomousActivity(
            for: record.carrierID
        ), activity.candidate.domain == .communication,
           activity.candidate.stableReference == transportID.rawValue {
            _ = try candidate.recordAutonomousActivityOutcome(
                AgentAutonomousActivityOutcome(
                    activityID: activity.activityID,
                    actorID: record.carrierID,
                    lifecycle: .completed,
                    completedAtTick: candidate.tick,
                    physicalReceiptID: event.eventID.rawValue,
                    sourceEventID: event.eventID,
                    reason: "CIV-44 causal delivery complete"
                )
            )
        }
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateLanguageStateIfInitialized()
        try candidate.validateOralTransmissionStateIfInitialized()
        try candidate.validateLongDistanceCommunicationStateIfInitialized()
        let delivered = candidate.longDistanceCommunicationState!
            .transports.first { $0.transportID == transportID }!
        self = candidate
        return delivered
    }

    /// Called only after the existing movement authority has accepted and
    /// published outcomes. Carrier movement advances the bounded journey;
    /// accepted movement by either participant may satisfy local arrival.
    /// Stationary or rejected outcomes create neither progress nor arrival.
    mutating func updateLongDistanceCommunicationAfterMovementEvents(
        outcomes: [AgentMovementOutcome]
    ) throws {
        guard var state = longDistanceCommunicationState, state.enabled else {
            return
        }
        var outcomesByAgent: [String: AgentMovementOutcome] = [:]
        for outcome in outcomes where outcomesByAgent[outcome.agentId] == nil {
            outcomesByAgent[outcome.agentId] = outcome
        }
        var boundaryCauses: [AgentCausalEventID] = []
        let activeIDs = state.transports.filter {
            $0.status == .inTransit
        }.map(\.transportID).sorted()
        for transportID in activeIDs {
            guard let index = state.transports.firstIndex(where: {
                $0.transportID == transportID
            }) else { continue }
            let current = state.transports[index]
            let carrierOutcome = outcomesByAgent[
                current.carrierID.rawValue
            ]
            let destinationOutcome = outcomesByAgent[
                current.destinationID.rawValue
            ]
            let carrierMoved = carrierOutcome?.status == .moved
            let destinationMoved = destinationOutcome?.status == .moved
            guard carrierMoved || destinationMoved else { continue }
            let carrierMovementEventID = carrierMoved
                ? lastOutcomeEventByAgentID[current.carrierID] : nil
            let destinationMovementEventID = destinationMoved
                ? lastOutcomeEventByAgentID[current.destinationID] : nil
            guard !carrierMoved || carrierMovementEventID != nil,
                  !destinationMoved || destinationMovementEventID != nil else {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState("accepted participant movement provenance")
                )
            }

            var arrivalPredecessor = current.progress.last?.progressEventID
                ?? current.dispatchEventID
            if carrierMoved,
               current.progress.count
                    >= state.configuration.maximumJourneySteps {
                let failureEvent =
                    try requiredCommunicationTransportEvent(
                        kind: .communicationTransportFailed,
                        actorID: current.carrierID,
                        subjectID: current.destinationID,
                        causes: [
                            arrivalPredecessor,
                            carrierMovementEventID!,
                        ],
                        transportID: transportID.rawValue,
                        authorID: current.authorID,
                        carrierID: current.carrierID,
                        destinationID: current.destinationID,
                        status:
                            AgentCommunicationTransportStatus.failed
                                .rawValue,
                        detail:
                            AgentCommunicationTransportFailure
                                .journeyStepLimit.rawValue,
                        summary:
                            "communication transport failed step bound "
                            + transportID.rawValue
                    )
                state = longDistanceCommunicationState ?? state
                guard let refreshed = state.transports.firstIndex(where: {
                    $0.transportID == transportID
                }) else { continue }
                state.transports[refreshed].status = .failed
                state.transports[refreshed].failure = .journeyStepLimit
                state.transports[refreshed].failedAtTick = tick
                state.transports[refreshed].failureEventID =
                    failureEvent.eventID
                state.transports[refreshed].provenanceDigest =
                    communicationTransportRecordDigest(
                        state.transports[refreshed]
                    )
                state.totalFailedCount += 1
                longDistanceCommunicationState = state
                boundaryCauses.append(failureEvent.eventID)
                continue
            }
            if let outcome = carrierOutcome, carrierMoved {
                let progressEvent = try requiredCommunicationTransportEvent(
                    kind: .communicationTransportProgressed,
                    actorID: current.carrierID,
                    subjectID: current.destinationID,
                    causes: [
                        arrivalPredecessor,
                        carrierMovementEventID!,
                    ],
                    transportID: transportID.rawValue,
                    authorID: current.authorID,
                    carrierID: current.carrierID,
                    destinationID: current.destinationID,
                    status:
                        AgentCommunicationTransportStatus.inTransit.rawValue,
                    detail:
                        "\(outcome.fromPosition.x),\(outcome.fromPosition.y),"
                        + "\(outcome.fromPosition.z)>"
                        + "\(outcome.toPosition.x),\(outcome.toPosition.y),"
                        + "\(outcome.toPosition.z)",
                    summary:
                        "communication transport progressed carrier="
                        + current.carrierID.rawValue
                )
                state = longDistanceCommunicationState ?? state
                guard let refreshed = state.transports.firstIndex(where: {
                    $0.transportID == transportID
                }) else { continue }
                state.transports[refreshed].progress.append(
                    AgentCommunicationTransportProgress(
                        stepOrdinal:
                            state.transports[refreshed].progress.count + 1,
                        fromPosition: outcome.fromPosition,
                        toPosition: outcome.toPosition,
                        movementEventID: carrierMovementEventID!,
                        progressEventID: progressEvent.eventID,
                        progressedAtTick: tick
                    )
                )
                // Publish the accepted carrier step before a possible arrival
                // event so retention can inspect the new transport evidence.
                longDistanceCommunicationState = state
                boundaryCauses.append(progressEvent.eventID)
                arrivalPredecessor = progressEvent.eventID
            }

            state = longDistanceCommunicationState ?? state
            guard let arrivalIndex = state.transports.firstIndex(where: {
                $0.transportID == transportID
            }), state.transports[arrivalIndex].status == .inTransit,
                  let carrier = statesById[current.carrierID.rawValue],
                  let destination = statesById[
                      current.destinationID.rawValue
                  ] else { continue }
            if manhattanDistance(
                carrier.position, destination.position
            ) <= 1 {
                var arrivalCauses = [arrivalPredecessor]
                if let destinationMovementEventID {
                    arrivalCauses.append(destinationMovementEventID)
                }
                let arrivalEvent =
                    try requiredCommunicationTransportEvent(
                        kind: .communicationTransportArrived,
                        actorID: current.carrierID,
                        subjectID: current.destinationID,
                        causes: arrivalCauses,
                        transportID: transportID.rawValue,
                        authorID: current.authorID,
                        carrierID: current.carrierID,
                        destinationID: current.destinationID,
                        status:
                            AgentCommunicationTransportStatus.arrived
                                .rawValue,
                        detail:
                            "\(carrier.position.x),"
                            + "\(carrier.position.y),"
                            + "\(carrier.position.z)",
                        summary:
                            "communication transport arrived participants="
                            + "\(current.carrierID.rawValue)>"
                            + current.destinationID.rawValue
                    )
                state = longDistanceCommunicationState ?? state
                guard let refreshedArrivalIndex = state.transports
                    .firstIndex(where: {
                        $0.transportID == transportID
                    }) else { continue }
                state.transports[refreshedArrivalIndex].status = .arrived
                state.transports[refreshedArrivalIndex].arrivalPosition =
                    carrier.position
                state.transports[refreshedArrivalIndex]
                    .destinationPositionAtArrival = destination.position
                state.transports[refreshedArrivalIndex].arrivedAtTick = tick
                state.transports[refreshedArrivalIndex].arrivalEventID =
                    arrivalEvent.eventID
                boundaryCauses.append(arrivalEvent.eventID)
            }
            guard let digestIndex = state.transports.firstIndex(where: {
                $0.transportID == transportID
            }) else { continue }
            state.transports[digestIndex].provenanceDigest =
                communicationTransportRecordDigest(
                    state.transports[digestIndex]
                )
            longDistanceCommunicationState = state
        }
        if !boundaryCauses.isEmpty {
            try commitLongDistanceCommunicationProvenanceBoundary(
                causes: Array(boundaryCauses.suffix(4))
            )
        }
        try validateLongDistanceCommunicationStateIfInitialized()
    }

    /// Mortality is the lifecycle authority. A carrier or destination death
    /// closes, rather than resurrects or silently delivers, every active
    /// transport that depends on that participant.
    mutating func terminateLongDistanceCommunicationForDeath(
        agentID: AgentID,
        deathCauseEventID: AgentCausalEventID
    ) throws -> [AgentCausalEventID] {
        guard var state = longDistanceCommunicationState else { return [] }
        let affected = state.transports.indices.filter {
            !state.transports[$0].status.isTerminal
                && (state.transports[$0].carrierID == agentID
                    || state.transports[$0].destinationID == agentID)
        }
        var causes: [AgentCausalEventID] = []
        for index in affected {
            let record = state.transports[index]
            let failure: AgentCommunicationTransportFailure =
                record.carrierID == agentID
                    ? .carrierDied : .destinationDied
            let event = try requiredCommunicationTransportEvent(
                kind: .communicationTransportFailed,
                actorID: record.carrierID,
                subjectID: record.destinationID,
                causes: [
                    record.arrivalEventID
                        ?? record.progress.last?.progressEventID
                        ?? record.dispatchEventID,
                    deathCauseEventID,
                ],
                transportID: record.transportID.rawValue,
                authorID: record.authorID,
                carrierID: record.carrierID,
                destinationID: record.destinationID,
                status: AgentCommunicationTransportStatus.failed.rawValue,
                detail: failure.rawValue,
                summary:
                    "communication transport failed participant death "
                    + record.transportID.rawValue
            )
            state = longDistanceCommunicationState ?? state
            guard let refreshed = state.transports.firstIndex(where: {
                $0.transportID == record.transportID
            }) else { continue }
            state.transports[refreshed].status = .failed
            state.transports[refreshed].failure = failure
            state.transports[refreshed].failedAtTick = tick
            state.transports[refreshed].failureEventID = event.eventID
            state.transports[refreshed].provenanceDigest =
                communicationTransportRecordDigest(
                    state.transports[refreshed]
                )
            state.totalFailedCount += 1
            longDistanceCommunicationState = state
            causes.append(event.eventID)
        }
        if !causes.isEmpty {
            try commitLongDistanceCommunicationProvenanceBoundary(
                causes: causes
            )
        }
        return causes
    }

    func retainedLongDistanceCommunicationOralTransmissionIDs()
        -> Set<AgentOralTransmissionID> {
        Set((longDistanceCommunicationState?.transports ?? []).flatMap {
            [$0.pickupTransmissionID]
                + ($0.deliveryTransmissionID.map { [$0] } ?? [])
        })
    }

    /// CIV-41 may legitimately evict terminal belief authority, after which
    /// CIV-43 must remove the exclusively dependent oral hop. Before that hop
    /// disappears, retire only terminal CIV-44 records that reference it and
    /// commit the resulting bounded set. Active transports remain protected
    /// by current CIV-41 acquisition authority and are never compacted here.
    mutating func reconcileLongDistanceCommunicationBeforeOralHistoryEviction(
        transmissionIDs: Set<AgentOralTransmissionID>,
        causeEventID: AgentCausalEventID
    ) throws {
        guard var state = longDistanceCommunicationState,
              !transmissionIDs.isEmpty else { return }
        let dependent = state.transports.filter { record in
            transmissionIDs.contains(record.pickupTransmissionID)
                || record.deliveryTransmissionID.map {
                    transmissionIDs.contains($0)
                } == true
        }.sorted(by: communicationTransportSort)
        guard !dependent.isEmpty else { return }
        guard dependent.allSatisfy({ $0.status.isTerminal }) else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState(
                    "active transport lost current oral authority"
                )
            )
        }
        guard state.evictedTransportCount
                <= Int.max - dependent.count else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("terminal reconciliation eviction counter")
            )
        }
        let dependentIDs = Set(dependent.map(\.transportID))
        state.transports.removeAll {
            dependentIDs.contains($0.transportID)
        }
        state.evictedTransportCount += dependent.count
        longDistanceCommunicationState = state
        try commitLongDistanceCommunicationProvenanceBoundary(
            causes: [causeEventID]
        )
        try validateLongDistanceCommunicationStateIfInitialized()
    }

    func hasActiveLongDistanceCommunicationParticipant(
        _ agentID: AgentID
    ) -> Bool {
        longDistanceCommunicationState?.transports.contains {
            !$0.status.isTerminal
                && ($0.carrierID == agentID
                    || $0.destinationID == agentID)
        } == true
    }

    func longDistanceCommunicationMovementEventCapacity(
        for outcomes: [AgentMovementOutcome]
    ) -> Int {
        guard let state = longDistanceCommunicationState, state.enabled else {
            return 0
        }
        var outcomesByAgent: [String: AgentMovementOutcome] = [:]
        for outcome in outcomes where outcomesByAgent[outcome.agentId] == nil {
            outcomesByAgent[outcome.agentId] = outcome
        }
        var eventCount = 0
        var willCommitBoundary = false
        for record in state.transports where record.status == .inTransit {
            let carrierMoved = outcomesByAgent[record.carrierID.rawValue]?
                .status == .moved
            let destinationMoved = outcomesByAgent[
                record.destinationID.rawValue
            ]?.status == .moved
            guard carrierMoved || destinationMoved else { continue }
            if carrierMoved {
                willCommitBoundary = true
                eventCount += 1 // failed-at-bound, or accepted progress
                if record.progress.count
                    >= state.configuration.maximumJourneySteps {
                    continue
                }
            }
            guard let carrier = statesById[record.carrierID.rawValue],
                  let destination = statesById[
                      record.destinationID.rawValue
                  ], manhattanDistance(
                    carrierMoved
                        ? outcomesByAgent[record.carrierID.rawValue]!
                            .toPosition
                        : carrier.position,
                    destinationMoved
                        ? outcomesByAgent[record.destinationID.rawValue]!
                            .toPosition
                        : destination.position
                  ) <= 1 else { continue }
            if !willCommitBoundary { willCommitBoundary = true }
            eventCount += 1 // arrival from accepted participant movement
        }
        return eventCount + (willCommitBoundary ? 1 : 0)
    }

    private mutating func compactLongDistanceCommunicationForAdmission()
        throws {
        guard var state = longDistanceCommunicationState,
              state.transports.count
                >= state.configuration.maximumRetainedTransports else {
            return
        }
        let excess = state.transports.count
            - state.configuration.maximumRetainedTransports + 1
        let removable = state.transports.filter {
            $0.status.isTerminal
        }.sorted(by: communicationTransportSort)
        guard removable.count >= excess,
              state.evictedTransportCount <= Int.max - excess else {
            throw AgentSessionError.longDistanceCommunication(
                .capacityReached("active transport records")
            )
        }
        let IDs = Set(removable.prefix(excess).map(\.transportID))
        state.transports.removeAll { IDs.contains($0.transportID) }
        state.evictedTransportCount += excess
        longDistanceCommunicationState = state
    }

    mutating func commitLongDistanceCommunicationProvenanceBoundary(
        causes: [AgentCausalEventID]
    ) throws {
        guard var state = longDistanceCommunicationState else { return }
        let hasHistory = state.totalStartedCount > 0
            || state.evictedTransportCount > 0
            || state.provenanceBoundary != nil
        guard hasHistory else { return }
        let digest = longDistanceCommunicationProvenanceBoundaryDigest(state)
        var boundaryCauses = causes
        if let previous = state.provenanceBoundary?.eventID {
            boundaryCauses.append(previous)
        }
        let event = try requiredCommunicationTransportEvent(
            kind: .communicationTransportProvenanceBoundary,
            actorID: nil,
            subjectID: nil,
            causes: Array(
                Array(Set(boundaryCauses)).sorted().suffix(4)
            ),
            transportID: "communication-transport-provenance",
            authorID: nil,
            carrierID: nil,
            destinationID: nil,
            status: "provenanceBoundary",
            detail: digest,
            summary: "communication transport provenance retention boundary"
        )
        state = longDistanceCommunicationState ?? state
        state.provenanceBoundary =
            AgentCommunicationTransportProvenanceBoundary(
                eventID: event.eventID,
                digest: digest
            )
        longDistanceCommunicationState = state
    }

    func validateLongDistanceCommunicationStateIfInitialized() throws {
        guard let state = longDistanceCommunicationState else { return }
        guard socialEnabled else {
            throw AgentSessionError.longDistanceCommunication(.socialRequired)
        }
        guard knowledgeGraphEnabled else {
            throw AgentSessionError.longDistanceCommunication(.knowledgeRequired)
        }
        guard languageState?.enabled == true else {
            throw AgentSessionError.longDistanceCommunication(.languageRequired)
        }
        guard oralTransmissionEnabled else {
            throw AgentSessionError.longDistanceCommunication(.oralRequired)
        }
        guard autonomousActivityEnabled else {
            throw AgentSessionError.longDistanceCommunication(
                .autonomousActivityRequired
            )
        }
        do {
            _ = try AgentLongDistanceCommunicationConfiguration(
                maximumRetainedTransports:
                    state.configuration.maximumRetainedTransports,
                maximumJourneySteps:
                    state.configuration.maximumJourneySteps,
                maximumTransportDistance:
                    state.configuration.maximumTransportDistance
            )
        } catch {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("configuration")
            )
        }
        let activeTransports = state.transports.filter {
            !$0.status.isTerminal
        }
        guard state.transports.count
                <= state.configuration.maximumRetainedTransports,
              state.evictedTransportCount >= 0,
              state.totalStartedCount >= 0,
              state.totalDeliveredCount >= 0,
              state.totalFailedCount >= 0,
              state.totalDeliveredCount + state.totalFailedCount
                <= state.totalStartedCount,
              state.totalStartedCount
                == state.evictedTransportCount + state.transports.count,
              state.nextTransportOrdinal
                == UInt64(state.totalStartedCount) + 1,
              Set(state.transports.map(\.transportID)).count
                == state.transports.count,
              Set(activeTransports.map(\.carrierID)).count
                == activeTransports.count else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("global bound, counter, or identity")
            )
        }
        try validateLongDistanceCommunicationProvenanceBoundaryIfInitialized()
        let oralByID = Dictionary(uniqueKeysWithValues:
            (oralTransmissionState?.transmissions ?? []).map {
                ($0.transmissionID, $0)
            }
        )
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        func retainedEvent(
            _ eventID: AgentCausalEventID
        ) throws -> AgentCausalEvent? {
            guard eventID.simulationID == simulationID,
                  eventID.sequence.rawValue <= causalLedger.latestSequence else {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState("cross-simulation provenance")
                )
            }
            if let event = retainedEvents[eventID] { return event }
            guard causalLedger.droppedEventCount > 0,
                  eventID.sequence.rawValue
                    <= causalLedger.droppedEventCount else {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState("missing causal provenance")
                )
            }
            return nil
        }
        let radius = configuration.socialConfiguration.communicationRadius
        for record in state.transports {
            guard record.authorID != record.carrierID,
                  record.authorID != record.destinationID,
                  record.carrierID != record.destinationID,
                  record.initialDistance > radius,
                  record.initialDistance
                    == manhattanDistance(
                        record.dispatchPosition,
                        record.destinationPositionAtDispatch
                    ),
                  record.initialDistance
                    <= state.configuration.maximumTransportDistance,
                  record.startedAtTick >= 0,
                  record.startedAtTick <= tick,
                  record.progress.count
                    <= state.configuration.maximumJourneySteps,
                  record.provenanceDigest
                    == communicationTransportRecordDigest(record),
                  let pickup = oralByID[record.pickupTransmissionID],
                  pickup.speakerID == record.authorID,
                  pickup.recipientID == record.carrierID,
                  pickup.sourceAuthorityID == record.sourceAuthorityID,
                  pickup.receiptEventID == record.pickupReceiptEventID,
                  pickup.transmittedSemanticContent.digest
                    == record.originSemanticContentDigest,
                  pickup.interpretedSemanticContent.digest
                    == record.carriedSemanticContentDigest,
                  pickup.interpretedSemanticContent.sourcePropositionID
                    == record.carriedPropositionID,
                  pickup.recipientBeliefID == record.carrierBeliefID,
                  pickup.recipientBeliefRevisionEventID
                    == record.carrierBeliefRevisionEventID,
                  pickup.receiptEventID.sequence
                    < record.dispatchEventID.sequence else {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState("transport pickup provenance")
                )
            }
            var previousPosition = record.dispatchPosition
            var previousEvent = record.dispatchEventID
            for (offset, progress) in record.progress.enumerated() {
                guard progress.stepOrdinal == offset + 1,
                      progress.fromPosition == previousPosition,
                      progress.progressedAtTick >= record.startedAtTick,
                      progress.progressedAtTick <= tick,
                      progress.movementEventID.sequence
                        < progress.progressEventID.sequence,
                      previousEvent.sequence
                        < progress.progressEventID.sequence else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("transport movement chain")
                    )
                }
                if let movement = try retainedEvent(
                    progress.movementEventID
                ) {
                    guard movement.kind == .movement,
                          movement.origin == .worldOutcome,
                          movement.actorID == record.carrierID,
                          case let .movement(status, from, to) =
                            movement.payload,
                          status == AgentMovementStatus.moved.rawValue,
                          from == progress.fromPosition,
                          to == progress.toPosition else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("accepted movement provenance")
                        )
                    }
                }
                if let event = try retainedEvent(progress.progressEventID) {
                    guard event.kind
                            == .communicationTransportProgressed,
                          event.origin
                            == .communicationTransportTransition,
                          event.actorID == record.carrierID,
                          event.subjectID == record.destinationID,
                          case let .communicationTransport(
                              transportID, authorID, carrierID,
                              destinationID, status, _
                          ) = event.payload,
                          transportID == record.transportID.rawValue,
                          authorID == record.authorID.rawValue,
                          carrierID == record.carrierID.rawValue,
                          destinationID == record.destinationID.rawValue,
                          status == AgentCommunicationTransportStatus
                            .inTransit.rawValue,
                          event.causes.contains(progress.movementEventID)
                            && event.causes.contains(previousEvent) else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("transport progress event")
                        )
                    }
                }
                previousPosition = progress.toPosition
                previousEvent = progress.progressEventID
            }
            let activeParticipants = record.status == .inTransit
                || record.status == .arrived
            if activeParticipants {
                guard statesById[record.carrierID.rawValue] != nil,
                      statesById[record.destinationID.rawValue] != nil,
                      !isMigratingAgent(record.carrierID.rawValue),
                      !isMigratingAgent(record.destinationID.rawValue) else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState(
                            "active participant unavailable or migrating"
                        )
                    )
                }
            }
            switch record.status {
            case .inTransit:
                guard record.arrivalPosition == nil,
                      record.destinationPositionAtArrival == nil,
                      record.arrivedAtTick == nil,
                      record.arrivalEventID == nil,
                      record.deliveryTransmissionID == nil,
                      record.destinationBeliefID == nil,
                      record.destinationBeliefRevisionEventID == nil,
                      record.deliveredAtTick == nil,
                      record.deliveryEventID == nil,
                      record.failure == nil,
                      record.failedAtTick == nil,
                      record.failureEventID == nil else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("in-transit terminal fields")
                    )
                }
            case .arrived, .delivered:
                guard let arrivalPosition = record.arrivalPosition,
                      let destinationPosition =
                        record.destinationPositionAtArrival,
                      let arrivalTick = record.arrivedAtTick,
                      let arrivalEventID = record.arrivalEventID,
                      (record.progress.last?.toPosition
                        ?? record.dispatchPosition) == arrivalPosition,
                      manhattanDistance(
                          arrivalPosition, destinationPosition
                      ) <= 1,
                      arrivalTick >= record.startedAtTick,
                      arrivalEventID.sequence > previousEvent.sequence else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("arrival provenance")
                    )
                }
                if let event = try retainedEvent(arrivalEventID) {
                    guard event.kind == .communicationTransportArrived,
                          event.origin
                            == .communicationTransportTransition,
                          event.actorID == record.carrierID,
                          event.subjectID == record.destinationID,
                          case let .communicationTransport(
                              transportID, authorID, carrierID,
                              destinationID, status, _
                          ) = event.payload,
                          transportID == record.transportID.rawValue,
                          authorID == record.authorID.rawValue,
                          carrierID == record.carrierID.rawValue,
                          destinationID == record.destinationID.rawValue,
                          status == AgentCommunicationTransportStatus
                            .arrived.rawValue,
                          event.simulationTick.rawValue == arrivalTick,
                          event.causes.contains(previousEvent),
                          event.causes.count <= 2 else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("arrival event")
                        )
                    }
                    let destinationMovementCauses = event.causes.filter {
                        $0 != previousEvent
                    }
                    guard destinationMovementCauses.count <= 1,
                          !record.progress.isEmpty
                            || destinationMovementCauses.count == 1 else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("arrival movement authority")
                        )
                    }
                    if let movementEventID =
                        destinationMovementCauses.first,
                       let movement = try retainedEvent(movementEventID) {
                        guard movement.kind == .movement,
                              movement.origin == .worldOutcome,
                              movement.actorID == record.destinationID,
                              movement.simulationTick.rawValue == arrivalTick,
                              case let .movement(status, _, to) =
                                movement.payload,
                              status == AgentMovementStatus.moved.rawValue,
                              to == destinationPosition else {
                            throw AgentSessionError.longDistanceCommunication(
                                .invalidState(
                                    "destination arrival movement"
                                )
                            )
                        }
                    }
                }
                if record.status == .arrived {
                    guard record.deliveryTransmissionID == nil,
                          record.destinationBeliefID == nil,
                          record.destinationBeliefRevisionEventID == nil,
                          record.deliveredAtTick == nil,
                          record.deliveryEventID == nil,
                          record.failure == nil,
                          record.failedAtTick == nil,
                          record.failureEventID == nil else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("arrived terminal fields")
                        )
                    }
                }
            case .failed:
                guard let failure = record.failure,
                      let failedAtTick = record.failedAtTick,
                      let failureEventID = record.failureEventID,
                      failedAtTick >= record.startedAtTick,
                      failedAtTick <= tick,
                      record.deliveryTransmissionID == nil,
                      record.destinationBeliefID == nil,
                      record.destinationBeliefRevisionEventID == nil,
                      record.deliveredAtTick == nil,
                      record.deliveryEventID == nil else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("failure provenance")
                    )
                }
                if let event = try retainedEvent(failureEventID) {
                    guard event.kind == .communicationTransportFailed,
                          event.origin
                            == .communicationTransportTransition,
                          event.actorID == record.carrierID,
                          event.subjectID == record.destinationID,
                          case let .communicationTransport(
                              transportID, authorID, carrierID,
                              destinationID, status, detail
                          ) = event.payload,
                          transportID == record.transportID.rawValue,
                          authorID == record.authorID.rawValue,
                          carrierID == record.carrierID.rawValue,
                          destinationID == record.destinationID.rawValue,
                          status == AgentCommunicationTransportStatus
                            .failed.rawValue,
                          detail == failure.rawValue,
                          event.causes.contains(
                              record.arrivalEventID ?? previousEvent
                          ) else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("failure event")
                        )
                    }
                }
            }
            if record.status == .delivered {
                guard let transmissionID = record.deliveryTransmissionID,
                      let delivery = oralByID[transmissionID],
                      delivery.speakerID == record.carrierID,
                      delivery.recipientID == record.destinationID,
                      delivery.sourceBeliefID == record.carrierBeliefID,
                      delivery.sourceBeliefRevisionEventID.sequence
                        >= record.carrierBeliefRevisionEventID.sequence,
                      delivery.transmittedSemanticContent.digest
                        == record.carriedSemanticContentDigest,
                      delivery.transmittedSemanticContent
                        .sourcePropositionID
                        == record.carriedPropositionID,
                      delivery.recipientBeliefID
                        == record.destinationBeliefID,
                      delivery.recipientBeliefRevisionEventID
                        == record.destinationBeliefRevisionEventID,
                      let deliveryEventID = record.deliveryEventID,
                      let arrivalEventID = record.arrivalEventID,
                      deliveryEventID.sequence
                        > delivery.receiptEventID.sequence,
                      deliveryEventID.sequence > arrivalEventID.sequence,
                      let deliveredAtTick = record.deliveredAtTick,
                      deliveredAtTick >= (record.arrivedAtTick ?? 0),
                      deliveredAtTick <= tick,
                      record.failureEventID == nil else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("delivery provenance")
                    )
                }
                if let event = try retainedEvent(deliveryEventID) {
                    guard event.kind == .communicationTransportDelivered,
                          event.origin
                            == .communicationTransportTransition,
                          event.actorID == record.carrierID,
                          event.subjectID == record.destinationID,
                          case let .communicationTransport(
                              eventTransportID, authorID, carrierID,
                              destinationID, status, detail
                          ) = event.payload,
                          eventTransportID == record.transportID.rawValue,
                          authorID == record.authorID.rawValue,
                          carrierID == record.carrierID.rawValue,
                          destinationID == record.destinationID.rawValue,
                          status == AgentCommunicationTransportStatus
                            .delivered.rawValue,
                          detail
                            == delivery.interpretedSemanticContent.digest,
                          event.causes.contains(arrivalEventID),
                          event.causes.contains(delivery.receiptEventID),
                          event.causes.contains(
                              delivery.recipientBeliefRevisionEventID
                          ) else {
                        throw AgentSessionError.longDistanceCommunication(
                            .invalidState("delivery event")
                        )
                    }
                }
            }
            if let event = try retainedEvent(record.dispatchEventID) {
                guard event.kind == .communicationTransportDispatched,
                      event.origin == .communicationTransportTransition,
                      event.actorID == record.authorID,
                      event.subjectID == record.carrierID,
                      case let .communicationTransport(
                          transportID, authorID, carrierID,
                          destinationID, status, detail
                      ) = event.payload,
                      transportID == record.transportID.rawValue,
                      authorID == record.authorID.rawValue,
                      carrierID == record.carrierID.rawValue,
                      destinationID == record.destinationID.rawValue,
                      status == AgentCommunicationTransportStatus
                        .inTransit.rawValue,
                      detail == record.carriedSemanticContentDigest,
                      event.causes.contains(record.pickupReceiptEventID)
                else {
                    throw AgentSessionError.longDistanceCommunication(
                        .invalidState("dispatch event")
                    )
                }
            }
        }
    }

    func validateLongDistanceCommunicationProvenanceBoundaryIfInitialized()
        throws {
        guard let state = longDistanceCommunicationState else { return }
        let retainedBoundaryEvents = causalLedger.events.filter {
            $0.kind == .communicationTransportProvenanceBoundary
        }
        let hasHistory = state.totalStartedCount > 0
            || state.evictedTransportCount > 0
        if !hasHistory {
            guard state.provenanceBoundary == nil,
                  retainedBoundaryEvents.isEmpty else {
                throw AgentSessionError.longDistanceCommunication(
                    .invalidState("unused transport provenance boundary")
                )
            }
            return
        }
        let retainedEvents = Dictionary(uniqueKeysWithValues:
            causalLedger.events.map { ($0.eventID, $0) }
        )
        guard let boundary = state.provenanceBoundary,
              boundary.digest
                == longDistanceCommunicationProvenanceBoundaryDigest(state),
              let event = retainedEvents[boundary.eventID],
              event.kind == .communicationTransportProvenanceBoundary,
              event.origin == .communicationTransportTransition,
              event.actorID == nil,
              event.subjectID == nil,
              case let .communicationTransport(
                  transportID, authorID, carrierID, destinationID,
                  status, detail
              ) = event.payload,
              transportID == "communication-transport-provenance",
              authorID == nil,
              carrierID == nil,
              destinationID == nil,
              status == "provenanceBoundary",
              detail == boundary.digest,
              retainedBoundaryEvents.map(\.eventID).max()
                == boundary.eventID else {
            throw AgentSessionError.longDistanceCommunication(
                .invalidState("transport provenance boundary")
            )
        }
    }

    private mutating func requiredCommunicationTransportEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        subjectID: AgentID?,
        causes: [AgentCausalEventID],
        transportID: String,
        authorID: AgentID?,
        carrierID: AgentID?,
        destinationID: AgentID?,
        status: String,
        detail: String,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .communicationTransportTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: Array(Set(causes)).sorted(),
            payload: .communicationTransport(
                transportID: transportID,
                authorID: authorID?.rawValue,
                carrierID: carrierID?.rawValue,
                destinationID: destinationID?.rawValue,
                status: status,
                detail: detail
            ),
            summary: summary
        ) else {
            throw AgentSessionError.longDistanceCommunication(
                .causalLedgerRequired
            )
        }
        return event
    }

    func communicationTransportSort(
        _ lhs: AgentCommunicationTransport,
        _ rhs: AgentCommunicationTransport
    ) -> Bool {
        if lhs.startedAtTick != rhs.startedAtTick {
            return lhs.startedAtTick < rhs.startedAtTick
        }
        return lhs.transportID < rhs.transportID
    }
}

func communicationTransportCanonicalText(
    _ record: AgentCommunicationTransport
) -> String {
    [
        communicationTransportRecordCanonicalText(record),
        record.provenanceDigest,
    ].joined(separator: "|")
}

func communicationTransportRecordCanonicalText(
    _ record: AgentCommunicationTransport
) -> String {
    let progress = record.progress.map {
        "\($0.stepOrdinal):"
            + "\($0.fromPosition.x),\($0.fromPosition.y),"
            + "\($0.fromPosition.z)>\($0.toPosition.x),"
            + "\($0.toPosition.y),\($0.toPosition.z):"
            + "\($0.movementEventID.rawValue):"
            + "\($0.progressEventID.rawValue):"
            + String($0.progressedAtTick)
    }.joined(separator: ",")
    func position(_ value: AgentPosition?) -> String {
        value.map { "\($0.x),\($0.y),\($0.z)" } ?? "none"
    }
    return [
        record.transportID.rawValue,
        record.authorID.rawValue,
        record.carrierID.rawValue,
        record.destinationID.rawValue,
        record.sourceAuthorityID.rawValue,
        record.pickupTransmissionID.rawValue,
        record.pickupReceiptEventID.rawValue,
        record.originSemanticContentDigest,
        record.carriedSemanticContentDigest,
        record.carriedPropositionID.rawValue,
        record.carrierBeliefID.rawValue,
        record.carrierBeliefRevisionEventID.rawValue,
        position(record.dispatchPosition),
        position(record.destinationPositionAtDispatch),
        String(record.initialDistance),
        String(record.startedAtTick),
        record.dispatchEventID.rawValue,
        progress,
        record.status.rawValue,
        position(record.arrivalPosition),
        position(record.destinationPositionAtArrival),
        record.arrivedAtTick.map(String.init) ?? "none",
        record.arrivalEventID?.rawValue ?? "none",
        record.deliveryTransmissionID?.rawValue ?? "none",
        record.destinationBeliefID?.rawValue ?? "none",
        record.destinationBeliefRevisionEventID?.rawValue ?? "none",
        record.deliveredAtTick.map(String.init) ?? "none",
        record.deliveryEventID?.rawValue ?? "none",
        record.failure?.rawValue ?? "none",
        record.failedAtTick.map(String.init) ?? "none",
        record.failureEventID?.rawValue ?? "none",
    ].joined(separator: "|")
}

func communicationTransportRecordDigest(
    _ record: AgentCommunicationTransport
) -> String {
    AgentLongDistanceCommunicationDigest.make(
        "communication-transport-record-v1|"
            + communicationTransportRecordCanonicalText(record)
    )
}

func longDistanceCommunicationProvenanceBoundaryDigest(
    _ state: AgentLongDistanceCommunicationState
) -> String {
    AgentLongDistanceCommunicationDigest.make(
        "communication-transport-provenance-boundary-v1|"
            + state.transports.sorted {
                if $0.startedAtTick != $1.startedAtTick {
                    return $0.startedAtTick < $1.startedAtTick
                }
                return $0.transportID < $1.transportID
            }.map(communicationTransportCanonicalText)
                .joined(separator: ";")
            + "|evicted=\(state.evictedTransportCount)"
            + "|started=\(state.totalStartedCount)"
            + "|delivered=\(state.totalDeliveredCount)"
            + "|failed=\(state.totalFailedCount)"
    )
}
