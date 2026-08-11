extension AgentSimulationSession {
    public var persistenceReconciliationEnabled: Bool {
        persistenceReconciliationState != nil
    }

    public func persistenceReconciliationSnapshot()
        -> AgentPersistenceReconciliationSnapshot {
        AgentPersistenceReconciliationSnapshot(state: persistenceReconciliationState)
    }

    public mutating func setPersistenceReconciliationEnabled(
        _ enabled: Bool,
        configuration: AgentPersistenceReconciliationConfiguration = .live
    ) throws {
        if enabled {
            guard causalLedger.isEnabled else {
                throw AgentSessionError.persistenceReconciliation(.causalLedgerRequired)
            }
            guard persistenceReconciliationState == nil else { return }
            try prevalidateCausalAppend(count: 1)
            persistenceReconciliationState = AgentPersistenceReconciliationState(
                configuration: configuration
            )
            _ = try recordCausalEvent(
                kind: .persistenceReconciliation,
                origin: .persistenceReconciliation,
                payload: .operation(status: "enabled", detail: "bounded World reconciliation V1"),
                summary: "persistence reconciliation enabled"
            )
            return
        }
        guard persistenceReconciliationState != nil else { return }
        persistenceReconciliationState = nil
        recordFeatureToggle(name: "persistenceReconciliation", enabled: false)
    }

    @discardableResult
    public mutating func applyPersistenceReconciliation(
        _ request: AgentPersistenceReconciliationRequest
    ) throws -> AgentPersistenceReconciliationReport {
        var candidate = self
        let report = try candidate.applyPersistenceReconciliationInPlace(request)
        self = candidate
        return report
    }

    private mutating func applyPersistenceReconciliationInPlace(
        _ request: AgentPersistenceReconciliationRequest
    ) throws -> AgentPersistenceReconciliationReport {
        guard var state = persistenceReconciliationState else {
            throw AgentSessionError.persistenceReconciliation(.disabled)
        }
        guard validReconciliationText(request.runID, maximum: 256),
              request.observedWorldTick >= 0 else {
            throw AgentSessionError.persistenceReconciliation(
                .invalidRequest(request.runID)
            )
        }
        if state.processedRunIDs.contains(request.runID) {
            guard let run = state.recentRuns.last(where: { $0.runID == request.runID }) else {
                throw AgentSessionError.persistenceReconciliation(
                    .invalidState("processed run has no retained report")
                )
            }
            return AgentPersistenceReconciliationReport(status: .duplicate, run: run)
        }
        try validateReconciliationEnvelope(request)

        let expectations = request.binding.assets
        let rightsRecords = materialRightsState?.records
            .sorted { $0.asset.assetID < $1.asset.assetID } ?? []
        guard expectations.count <= state.configuration.maximumAssetReferences,
              request.assetObservations.count == expectations.count,
              Set(expectations.map(\.asset.assetID)).count == expectations.count,
              expectations.map(\.asset) == rightsRecords.map(\.asset),
              expectations.map(\.savedObservation)
                == rightsRecords.map(\.lastVerifiedHolder),
              request.assetObservations.map(\.assetID)
                == expectations.map(\.asset.assetID) else {
            throw AgentSessionError.persistenceReconciliation(.assetReferenceMismatch)
        }
        guard request.assetObservations.allSatisfy({
            $0.observations.count <= state.configuration.maximumObservationsPerAsset
        }) else {
            throw AgentSessionError.persistenceReconciliation(
                .invalidRequest("physical observation bound")
            )
        }

        let activeActivities = autonomousActivityState?.activeActivities
            .sorted(by: activitySort) ?? []
        guard request.activityResolutions.count
                <= state.configuration.maximumActivityResolutions,
              request.activityResolutions.map(\.activityID)
                == activeActivities.map(\.activityID),
              zip(request.activityResolutions, activeActivities).allSatisfy({
                  $0.actorID == $1.candidate.actorID
              }) else {
            throw AgentSessionError.persistenceReconciliation(
                .activityResolutionMismatch(
                    activeActivities.map(\.activityID).joined(separator: ",")
                )
            )
        }
        guard request.activityResolutions.allSatisfy({
            !$0.reason.isEmpty && $0.reason.utf8.count <= 240
        }) else {
            throw AgentSessionError.persistenceReconciliation(
                .invalidRequest("activity reason")
            )
        }

        var classified: [(
            expectation: AgentPersistenceAssetExpectation,
            outcome: AgentPersistenceReconciliationOutcome,
            observation: AgentMaterialHolderObservation?,
            reason: String
        )] = []
        for (expectation, set) in zip(expectations, request.assetObservations) {
            let item = try classifyReconciliation(
                expectation: expectation,
                observations: set.observations
            )
            guard item.outcome.isPublishable else {
                switch item.outcome {
                case .ambiguous:
                    throw AgentSessionError.persistenceReconciliation(
                        .ambiguousAsset(expectation.asset.assetID)
                    )
                case .duplicatedOrConflicting:
                    throw AgentSessionError.persistenceReconciliation(
                        .duplicatedOrConflictingAsset(expectation.asset.assetID)
                    )
                default:
                    throw AgentSessionError.persistenceReconciliation(
                        .invalidObservation(expectation.asset.assetID)
                    )
                }
            }
            classified.append((expectation, item.outcome, item.observation, item.reason))
        }

        let causalBefore = causalLedger.latestSequence
        try prevalidateCausalAppend(
            count: classified.count + request.activityResolutions.count + 1
        )
        var assetResults: [AgentPersistenceAssetReconciliationResult] = []
        var rights = materialRightsState
        for item in classified {
            if item.outcome == .changedButReconcilable,
               let observation = item.observation,
               let index = rights?.records.firstIndex(where: {
                   $0.asset.assetID == item.expectation.asset.assetID
               }) {
                // A matched current observation proves the durable physical
                // projection without rewriting its historical receipt. The
                // current observation remains authoritative in the run
                // result; only a genuinely changed physical fact replaces
                // the durable Material Rights projection.
                rights?.records[index].lastVerifiedHolder = observation
            }
            let detail = [
                "asset=\(item.expectation.asset.assetID.rawValue)",
                "outcome=\(item.outcome.rawValue)",
                "saved=\(item.expectation.savedObservation.holder.stableText)",
                "restored=\(item.observation?.holder.stableText ?? "none")",
            ].joined(separator: " ")
            let event = try recordCausalEvent(
                kind: .persistenceReconciliation,
                origin: .persistenceReconciliation,
                operationID: AgentOperationID(
                    rawValue: "\(request.runID):\(item.expectation.asset.assetID.rawValue)"
                ),
                payload: .operation(
                    status: item.outcome.rawValue,
                    detail: String(detail.prefix(160))
                ),
                summary: "physical asset reconciled \(item.expectation.asset.assetID.rawValue)"
            )
            assetResults.append(AgentPersistenceAssetReconciliationResult(
                assetID: item.expectation.asset.assetID,
                outcome: item.outcome,
                savedHolder: item.expectation.savedObservation.holder,
                restoredHolder: item.observation?.holder,
                observation: item.observation,
                reason: item.reason,
                eventID: event?.eventID
            ))
        }
        materialRightsState = rights

        var activityResults: [AgentPersistenceActivityReconciliationResult] = []
        for resolution in request.activityResolutions {
            if !resolution.policy.keepsActivityActive {
                try interruptAutonomousActivityForPersistence(resolution)
            }
            let event = try recordCausalEvent(
                kind: .persistenceReconciliation,
                origin: .persistenceReconciliation,
                actorID: resolution.actorID,
                operationID: AgentOperationID(
                    rawValue: "\(request.runID):\(resolution.activityID)"
                ),
                payload: .operation(
                    status: resolution.policy.rawValue,
                    detail: String(resolution.reason.prefix(160))
                ),
                summary: "interrupted activity \(resolution.policy.rawValue)"
            )
            activityResults.append(AgentPersistenceActivityReconciliationResult(
                activityID: resolution.activityID,
                actorID: resolution.actorID,
                policy: resolution.policy,
                reason: resolution.reason,
                eventID: event?.eventID
            ))
        }
        _ = try recordCausalEvent(
            kind: .persistenceReconciliation,
            origin: .persistenceReconciliation,
            operationID: AgentOperationID(rawValue: request.runID),
            payload: .operation(
                status: "completed",
                detail: "assets=\(assetResults.count) activities=\(activityResults.count) duplicates=0"
            ),
            summary: "World/civilization reconciliation completed"
        )
        try validateMaterialRightsStateIfEnabled()

        let run = AgentPersistenceReconciliationRun(
            runID: request.runID,
            checkpointID: request.binding.checkpointID,
            world: request.restoredWorld,
            checkpointTick: request.binding.checkpointTick.rawValue,
            observedWorldTick: request.observedWorldTick,
            causalSequenceBefore: causalBefore,
            causalSequenceAfter: causalLedger.latestSequence,
            assetResults: assetResults,
            activityResults: activityResults,
            duplicationCount: 0
        )
        state.latestResults = assetResults
        state.recentRuns.append(run)
        state.processedRunIDs.append(request.runID)
        retainReconciliationBounds(&state)
        persistenceReconciliationState = state
        try validatePersistenceReconciliationStateIfEnabled()
        return AgentPersistenceReconciliationReport(status: .applied, run: run)
    }

    private func validateReconciliationEnvelope(
        _ request: AgentPersistenceReconciliationRequest
    ) throws {
        let binding = request.binding
        guard binding.world == request.restoredWorld else {
            throw AgentSessionError.persistenceReconciliation(
                .worldMismatch("identity, storage, seed, or dimension")
            )
        }
        guard binding.simulationID == simulationID else {
            throw AgentSessionError.persistenceReconciliation(
                .checkpointMismatch("simulation identity")
            )
        }
        guard binding.checkpointTick.rawValue == tick else {
            throw AgentSessionError.persistenceReconciliation(
                .checkpointMismatch("simulation tick")
            )
        }
        guard binding.causalSequence == causalLedger.latestSequence else {
            throw AgentSessionError.persistenceReconciliation(
                .checkpointMismatch("causal sequence")
            )
        }
        guard !binding.world.worldID.isEmpty,
              !binding.world.storageIdentity.isEmpty else {
            throw AgentSessionError.persistenceReconciliation(
                .worldMismatch("empty identity")
            )
        }
    }

    private func classifyReconciliation(
        expectation: AgentPersistenceAssetExpectation,
        observations: [AgentMaterialHolderObservation]
    ) throws -> (
        outcome: AgentPersistenceReconciliationOutcome,
        observation: AgentMaterialHolderObservation?,
        reason: String
    ) {
        guard expectation.candidateHolders.count > 0,
              expectation.candidateHolders.count <= 32,
              expectation.candidateHolders.contains(
                  expectation.savedObservation.holder
              ) else {
            return (.invalid, nil, "invalid bounded holder expectation")
        }
        guard observations.allSatisfy({ observation in
            expectation.candidateHolders.contains(observation.holder)
                && observation.quantity == expectation.asset.quantity
                && observation.quantity > 0
                && observation.materialIdentity.itemKey
                    == expectation.asset.materialIdentity.itemKey
                && observation.observedAtTick == tick
                && !observation.custodyFingerprint.isEmpty
                && observation.custodyFingerprint.utf8.count <= 8192
                && !observation.physicalReceiptID.isEmpty
                && observation.physicalReceiptID.utf8.count <= 256
        }) else {
            return (.invalid, nil, "observation violates asset or holder contract")
        }
        if observations.isEmpty {
            return (.missing, nil, "physical asset absent from all bounded candidate holders")
        }
        if observations.count > 1 {
            let holders = Set(observations.map(\.holder))
            return holders.count > 1
                ? (.duplicatedOrConflicting, nil, "compatible asset observed at multiple holders")
                : (.ambiguous, nil, "multiple compatible observations at one holder")
        }
        let observed = observations[0]
        let saved = expectation.savedObservation
        let physicallyEqual = observed.holder == saved.holder
            && observed.materialIdentity == saved.materialIdentity
            && observed.quantity == saved.quantity
            && observed.custodyFingerprint == saved.custodyFingerprint
        if physicallyEqual {
            return (.matched, observed, "restored physical fact matches saved projection")
        }
        return (
            .changedButReconcilable,
            observed,
            "restored physical truth replaced the saved holder projection"
        )
    }

    private mutating func interruptAutonomousActivityForPersistence(
        _ resolution: AgentPersistenceActivityResolution
    ) throws {
        guard var autonomy = autonomousActivityState,
              let index = autonomy.activeActivities.firstIndex(where: {
                  $0.activityID == resolution.activityID
                    && $0.candidate.actorID == resolution.actorID
              }) else {
            throw AgentSessionError.persistenceReconciliation(
                .activityResolutionMismatch(resolution.activityID)
            )
        }
        var activity = autonomy.activeActivities.remove(at: index)
        activity.lifecycle = .interrupted
        activity.updatedAtTick = tick
        autonomy.recentRecords.append(AgentAutonomousActivityRecord(
            activity: activity,
            outcome: AgentAutonomousActivityOutcome(
                activityID: activity.activityID,
                actorID: resolution.actorID,
                lifecycle: .interrupted,
                completedAtTick: tick,
                reason: "restart \(resolution.policy.rawValue): \(resolution.reason)"
            )
        ))
        if autonomy.recentRecords.count > autonomy.configuration.maximumRetainedRecords {
            let remove = autonomy.recentRecords.count
                - autonomy.configuration.maximumRetainedRecords
            autonomy.recentRecords.removeFirst(remove)
            autonomy.evictionCount += remove
        }
        autonomousActivityState = autonomy
    }

    private func validReconciliationText(_ text: String, maximum: Int) -> Bool {
        !text.isEmpty && text.utf8.count <= maximum && !text.contains("\n")
    }

    private func retainReconciliationBounds(
        _ state: inout AgentPersistenceReconciliationState
    ) {
        if state.latestResults.count > state.configuration.maximumRetainedResults {
            let remove = state.latestResults.count
                - state.configuration.maximumRetainedResults
            state.latestResults.removeFirst(remove)
            state.droppedResultCount += UInt64(remove)
        }
        if state.recentRuns.count > state.configuration.maximumRetainedRuns {
            let remove = state.recentRuns.count - state.configuration.maximumRetainedRuns
            state.recentRuns.removeFirst(remove)
            state.droppedRunCount += UInt64(remove)
        }
        if state.processedRunIDs.count > state.configuration.maximumProcessedRunIDs {
            let remove = state.processedRunIDs.count
                - state.configuration.maximumProcessedRunIDs
            state.processedRunIDs.removeFirst(remove)
            state.droppedRunIDCount += UInt64(remove)
        }
    }

    func validatePersistenceReconciliationStateIfEnabled() throws {
        guard let state = persistenceReconciliationState else { return }
        let configuration = state.configuration
        guard state.latestResults.count <= configuration.maximumRetainedResults,
              state.recentRuns.count <= configuration.maximumRetainedRuns,
              state.processedRunIDs.count <= configuration.maximumProcessedRunIDs,
              state.processedRunIDs.count == Set(state.processedRunIDs).count,
              state.latestResults.map(\.assetID).count
                == Set(state.latestResults.map(\.assetID)).count,
              state.latestResults.allSatisfy({ $0.outcome.isPublishable }),
              state.recentRuns.allSatisfy({
                  $0.duplicationCount == 0
                    && $0.causalSequenceBefore <= $0.causalSequenceAfter
                    && $0.causalSequenceAfter <= causalLedger.latestSequence
                    && $0.assetResults.allSatisfy { $0.outcome.isPublishable }
              }),
              state.processedRunIDs.allSatisfy({ runID in
                  state.recentRuns.contains(where: { $0.runID == runID })
              }) else {
            throw AgentSessionError.persistenceReconciliation(
                .invalidState("bounds, identity, or causal sequence")
            )
        }
        if let rights = materialRightsState {
            let rightsIDs = Set(rights.records.map(\.asset.assetID))
            guard state.latestResults.allSatisfy({
                rightsIDs.contains($0.assetID)
            }) else {
                throw AgentSessionError.persistenceReconciliation(
                    .invalidState("result references unknown rights asset")
                )
            }
        } else if !state.latestResults.isEmpty {
            throw AgentSessionError.persistenceReconciliation(
                .invalidState("physical results without material rights")
            )
        }
    }
}
