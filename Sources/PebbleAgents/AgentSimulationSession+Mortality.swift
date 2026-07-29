private struct AgentLethalMortalityCandidate {
    let agentID: AgentID
    let healthBefore: Int
    let cause: AgentMortalityCause
    let terminalPhysiologyEventID: AgentCausalEventID?
    let pendingMaterialExitEventID: AgentCausalEventID?
    let materialExitEventIDs: [AgentCausalEventID]
}

extension AgentSimulationSession {
    public var mortalityEnabled: Bool { mortalityState != nil }

    public mutating func setMortalityEnabled(
        _ enabled: Bool,
        configuration: AgentMortalityConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.setMortalityEnabledInPlace(enabled, configuration: configuration)
        self = candidate
    }

    private mutating func setMortalityEnabledInPlace(
        _ enabled: Bool,
        configuration: AgentMortalityConfiguration
    ) throws {
        if enabled {
            guard mortalityState == nil else {
                throw AgentSessionError.mortality(.alreadyEnabled)
            }
            guard causalLedger.isEnabled else {
                throw AgentSessionError.mortality(.causalLedgerRequired)
            }
            guard survivalEnabled else {
                throw AgentSessionError.mortality(.survivalRequired)
            }
            guard let registry = populationRegistry else {
                throw AgentSessionError.mortality(.populationRequired)
            }
            guard registry.settlement.settlementID == .main,
                  Set(registry.members.map(\.agentID))
                    == Set(statesById.values.map(\.agentID)) else {
                throw AgentSessionError.mortality(.invalidSettlement)
            }
            if let invalid = statesById.values.sorted(by: { $0.agentID < $1.agentID })
                .first(where: { $0.health <= 0 }) {
                throw AgentSessionError.mortality(.nonLivingAgent(invalid.id))
            }
            _ = try AgentMortalityConfiguration(
                maximumDeathsPerTick: configuration.maximumDeathsPerTick,
                maximumRetainedDeathRecords: configuration.maximumRetainedDeathRecords,
                maximumFinalMemoryEntries: configuration.maximumFinalMemoryEntries,
                maximumCancelledCommitmentIDsPerDeath:
                    configuration.maximumCancelledCommitmentIDsPerDeath,
                maximumExitFrames: configuration.maximumExitFrames,
                maximumMaterialExitsPerDeath:
                    configuration.maximumMaterialExitsPerDeath
            )
            try prevalidateCausalAppend(count: 1)
            guard let event = try recordCausalEvent(
                kind: .mortalityInitialized,
                origin: .mortalityTransition,
                payload: .mortalityDeath(
                    deathID: "none",
                    agentID: "none",
                    cause: AgentMortalityCause.starvation.rawValue,
                    tick: tick,
                    healthBefore: 0,
                    healthAfter: 0,
                    hunger: 0,
                    populationBefore: registry.members.count,
                    populationAfter: registry.members.count,
                    membershipStatus: "none",
                    position: registry.settlement.anchor,
                    carriedQuantity: 0,
                    cancelledCommitments: 0,
                    reason: "initialized"
                ),
                summary: "mortality initialized population=\(registry.members.count)"
            ) else {
                throw AgentSessionError.mortality(.causalLedgerRequired)
            }
            mortalityState = AgentMortalityState(
                configuration: configuration,
                records: [],
                totalDeathCount: 0,
                processedDeathIDs: [],
                unrecoveredAtDeath: AgentCampStock(capacity: 4096),
                terminalStarvationDamageTotal: 0,
                exitFrames: [],
                pendingTransitions: [],
                evictionCounts: AgentMortalityEvictionCounts(),
                rollingDigest: AgentMortalityDigest.make(""),
                initializedEventID: event.eventID,
                lastMortalityEventID: event.eventID
            )
            return
        }

        guard let state = mortalityState else {
            throw AgentSessionError.mortality(.disabled)
        }
        guard state.totalDeathCount == 0, state.unrecoveredAtDeath.isEmpty,
              state.pendingTransitions.isEmpty else {
            throw AgentSessionError.mortality(.unsafeDisable)
        }
        mortalityState = nil
    }

    public mutating func clearMortalityDiagnostics() throws {
        var candidate = self
        guard var mortality = candidate.mortalityState else {
            throw AgentSessionError.mortality(.disabled)
        }
        let removed = mortality.exitFrames.count
        try candidate.prevalidateCausalAppend(count: 1)
        guard let event = try candidate.recordCausalEvent(
            kind: .mortalityStateCleared,
            origin: .mortalityTransition,
            causes: [mortality.lastMortalityEventID],
            payload: .mortalityClear(exitFrames: removed),
            summary: "mortality diagnostics cleared exitFrames=\(removed)"
        ) else {
            throw AgentSessionError.mortality(.causalLedgerRequired)
        }
        mortality.exitFrames.removeAll()
        mortality.lastMortalityEventID = event.eventID
        candidate.mortalityState = mortality
        self = candidate
    }

    public func mortalitySnapshot() -> AgentMortalitySnapshot {
        guard let mortality = mortalityState else {
            return AgentMortalitySnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                records: [],
                totalDeathCount: 0,
                processedDeathIDs: [],
                unrecoveredAtDeath: [],
                terminalStarvationDamageTotal: 0,
                exitFrames: [],
                pendingTransitions: [],
                evictionCounts: AgentMortalityEvictionCounts(),
                rollingDigest: AgentMortalityDigest.make(""),
                lastMortalityEventID: nil,
                digest: AgentMortalityDigest.make("disabled|\(tick)")
            )
        }
        let records = mortality.records.sorted(by: mortalityRecordSort)
        let exits = mortality.exitFrames.sorted {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            if $0.agentID != $1.agentID { return $0.agentID < $1.agentID }
            return $0.deathID < $1.deathID
        }
        let canonical = [
            "config=\(mortality.configuration.maximumDeathsPerTick),\(mortality.configuration.maximumRetainedDeathRecords),\(mortality.configuration.maximumFinalMemoryEntries),\(mortality.configuration.maximumCancelledCommitmentIDsPerDeath),\(mortality.configuration.maximumExitFrames),\(mortality.configuration.maximumMaterialExitsPerDeath)",
            "total=\(mortality.totalDeathCount)",
            "processed=\(mortality.processedDeathIDs.sorted().map(\.rawValue).joined(separator: ","))",
            "terminal=\(mortality.unrecoveredAtDeath.amounts.map { "\($0.resource.rawValue):\($0.quantity)" }.joined(separator: ","))",
            "starvation=\(mortality.terminalStarvationDamageTotal)",
            records.map { "\($0.deathTick):\($0.agentID.rawValue):\($0.deathID.rawValue):\($0.finalStateDigest)" }.joined(separator: ";"),
            exits.map { "\($0.tick):\($0.agentID.rawValue):\($0.populationBefore)>\($0.populationAfter)" }.joined(separator: ";"),
            mortality.pendingTransitions.sorted {
                $0.agentID < $1.agentID
            }.map {
                "\($0.detectedAtTick):\($0.agentID.rawValue):"
                    + "\($0.requiredMaterialAssetIDs.map(\.rawValue).joined(separator: ",")):"
                    + "\($0.resolvedMaterialAssetIDs.map(\.rawValue).joined(separator: ","))"
            }.joined(separator: ";"),
            "evicted=\(mortality.evictionCounts.deathRecords),\(mortality.evictionCounts.exitFrames)",
            "rolling=\(mortality.rollingDigest)",
            "last=\(mortality.lastMortalityEventID.rawValue)",
        ].joined(separator: "|")
        return AgentMortalitySnapshot(
            enabled: true,
            tick: tick,
            configuration: mortality.configuration,
            records: records,
            totalDeathCount: mortality.totalDeathCount,
            processedDeathIDs: mortality.processedDeathIDs.sorted(),
            unrecoveredAtDeath: mortality.unrecoveredAtDeath.amounts,
            terminalStarvationDamageTotal: mortality.terminalStarvationDamageTotal,
            exitFrames: exits,
            pendingTransitions: mortality.pendingTransitions.sorted {
                $0.agentID < $1.agentID
            },
            evictionCounts: mortality.evictionCounts,
            rollingDigest: mortality.rollingDigest,
            lastMortalityEventID: mortality.lastMortalityEventID,
            digest: AgentMortalityDigest.make(canonical)
        )
    }

    public func mortalitySummary() -> AgentMortalitySummary {
        let snapshot = mortalitySnapshot()
        let latest = snapshot.records.last
        return AgentMortalitySummary(
            enabled: snapshot.enabled,
            activeAgentCount: statesById.count,
            totalDeathCount: snapshot.totalDeathCount,
            retainedDeathCount: snapshot.records.count,
            evictedDeathCount: snapshot.evictionCounts.deathRecords,
            pendingDeathCount: snapshot.pendingTransitions.count,
            latestDeathID: latest?.deathID,
            latestAgentID: latest?.agentID,
            latestCause: latest?.cause,
            latestDeathTick: latest?.deathTick,
            unrecoveredTotal: snapshot.unrecoveredAtDeath.reduce(0) { $0 + $1.quantity },
            mortalityEventCount: causalLedger.events.filter { $0.kind.isMortality }.count,
            digest: snapshot.digest
        )
    }

    public func populationExitSnapshot() -> [AgentPopulationExitFrame] {
        mortalitySnapshot().exitFrames
    }

    public func pendingMortalityTransitions() -> [AgentPendingMortalityTransition] {
        mortalityState?.pendingTransitions.sorted {
            $0.agentID < $1.agentID
        } ?? []
    }

    mutating func applyMortalitySurvivalBoundary(
        at mortalityTick: Int
    ) throws -> [String: AgentMemoryEntry] {
        guard let mortality = mortalityState else { return [:] }
        var candidate = self
        var survivalMemories: [String: AgentMemoryEntry] = [:]
        var healthBeforeByID: [AgentID: Int] = [:]
        for id in candidate.sortedIds {
            guard var state = candidate.statesById[id] else { continue }
            healthBeforeByID[state.agentID] = state.health
            let memory = candidate.applySurvivalTick(
                to: &state,
                tick: mortalityTick,
                appliesLegacyStarvationDamage: candidate.homeostasisState == nil
            )
            state.ticksAlive += 1
            if let memory {
                candidate.appendMemory(memory, to: &state.memory)
                survivalMemories[id] = memory
            }
            candidate.statesById[id] = state
        }
        try candidate.applyHomeostasisBoundary(at: mortalityTick)
        var lethal: [AgentLethalMortalityCandidate] = []
        for agentID in healthBeforeByID.keys.sorted() {
            guard let healthBefore = healthBeforeByID[agentID],
                  let state = candidate.statesById[agentID.rawValue],
                  healthBefore > 0, state.health == 0 else { continue }
            let terminalPhysiologyEventID = try candidate
                .terminalHomeostasisEventID(for: agentID, at: mortalityTick)
            lethal.append(AgentLethalMortalityCandidate(
                agentID: agentID,
                healthBefore: healthBefore,
                cause: candidate.homeostasisMortalityCause(for: agentID),
                terminalPhysiologyEventID: terminalPhysiologyEventID,
                pendingMaterialExitEventID: nil,
                materialExitEventIDs: []
            ))
        }
        lethal.sort { $0.agentID < $1.agentID }
        guard lethal.count <= mortality.configuration.maximumDeathsPerTick else {
            throw AgentSessionError.mortality(.deathsPerTickExceeded(lethal.count))
        }
        if !lethal.isEmpty {
            let staged = try candidate.stageMaterialExitMortalityTransitions(
                lethal, at: mortalityTick
            )
            let immediateIDs = Set(staged.map(\.agentID))
            let immediate = lethal.filter { !immediateIDs.contains($0.agentID) }
            if !immediate.isEmpty {
                try candidate.finalizeMortalityTransitions(immediate, at: mortalityTick)
            }
            for entry in lethal {
                survivalMemories.removeValue(forKey: entry.agentID.rawValue)
            }
        }
        self = candidate
        return survivalMemories
    }

    private mutating func stageMaterialExitMortalityTransitions(
        _ lethal: [AgentLethalMortalityCandidate],
        at mortalityTick: Int
    ) throws -> [AgentPendingMortalityTransition] {
        guard var mortality = mortalityState else {
            throw AgentSessionError.mortality(.disabled)
        }
        var pending: [AgentPendingMortalityTransition] = []
        for item in lethal {
            let assetIDs = materialRightsState?.records.compactMap { record in
                record.lastVerifiedHolder.holder == .agent(item.agentID)
                    ? record.asset.assetID : nil
            }.sorted() ?? []
            guard assetIDs.count <= mortality.configuration
                .maximumMaterialExitsPerDeath else {
                throw AgentSessionError.mortality(
                    .materialExitLimitExceeded(assetIDs.count)
                )
            }
            guard !assetIDs.isEmpty else { continue }
            guard !mortality.pendingTransitions.contains(where: {
                $0.agentID == item.agentID
            }) else {
                throw AgentSessionError.mortality(
                    .pendingMaterialExit(item.agentID.rawValue)
                )
            }
            try prevalidateCausalAppend(count: 1)
            let causes = Array(Set([
                item.terminalPhysiologyEventID,
                mortality.lastMortalityEventID,
            ].compactMap { $0 })).sorted()
            let event = try requiredMortalityEvent(
                kind: .mortalityMaterialExitPending,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: causes,
                payload: .operation(
                    status: "pending",
                    detail: "assets=\(assetIDs.map(\.rawValue).joined(separator: ","))"
                ),
                summary: "mortality material exit pending agent="
                    + "\(item.agentID.rawValue) assets=\(assetIDs.count)"
            )
            let transition = AgentPendingMortalityTransition(
                agentID: item.agentID,
                healthBeforeLethalDamage: item.healthBefore,
                cause: item.cause,
                detectedAtTick: mortalityTick,
                terminalPhysiologyEventID: item.terminalPhysiologyEventID,
                pendingEventID: event.eventID,
                requiredMaterialAssetIDs: assetIDs,
                resolvedMaterialAssetIDs: [],
                materialExitEventIDs: []
            )
            mortality.pendingTransitions.append(transition)
            mortality.pendingTransitions.sort { $0.agentID < $1.agentID }
            mortality.lastMortalityEventID = event.eventID
            pending.append(transition)
        }
        mortalityState = mortality
        return pending
    }

    @discardableResult
    public mutating func finalizePendingMortality(
        for agentID: AgentID
    ) throws -> AgentMortalityRecord {
        var candidate = self
        let record = try candidate.finalizePendingMortalityInPlace(for: agentID)
        self = candidate
        return record
    }

    private mutating func finalizePendingMortalityInPlace(
        for agentID: AgentID
    ) throws -> AgentMortalityRecord {
        guard var mortality = mortalityState,
              let index = mortality.pendingTransitions.firstIndex(where: {
                  $0.agentID == agentID
              }) else {
            throw AgentSessionError.mortality(.pendingMaterialExit(agentID.rawValue))
        }
        let pending = mortality.pendingTransitions[index]
        guard pending.unresolvedMaterialAssetIDs.isEmpty,
              pending.requiredMaterialAssetIDs
                == pending.resolvedMaterialAssetIDs.sorted(),
              !pending.materialExitEventIDs.isEmpty else {
            throw AgentSessionError.mortality(.pendingMaterialExit(agentID.rawValue))
        }
        mortality.pendingTransitions.remove(at: index)
        mortalityState = mortality
        try finalizeMortalityTransitions([
            AgentLethalMortalityCandidate(
                agentID: pending.agentID,
                healthBefore: pending.healthBeforeLethalDamage,
                cause: pending.cause,
                terminalPhysiologyEventID: pending.terminalPhysiologyEventID,
                pendingMaterialExitEventID: pending.pendingEventID,
                materialExitEventIDs: pending.materialExitEventIDs
            ),
        ], at: pending.detectedAtTick)
        guard let record = mortalityState?.records.last(where: {
            $0.agentID == agentID && $0.deathTick == pending.detectedAtTick
        }) else {
            throw AgentSessionError.mortality(.invalidState(
                "pending death finalization missing record \(agentID.rawValue)"
            ))
        }
        return record
    }

    private mutating func finalizeMortalityTransitions(
        _ lethal: [AgentLethalMortalityCandidate],
        at mortalityTick: Int
    ) throws {
        guard var mortality = mortalityState, var registry = populationRegistry else {
            throw AgentSessionError.mortality(.disabled)
        }
        let householdEventCount = try householdDeathEventCount(
            agentIDs: lethal.map(\.agentID), at: mortalityTick
        )
        let terminalWorkEventCount = lethal.reduce(0) { count, candidate in
            count + activeWorkCommitments(for: candidate.agentID).count
        }
        try prevalidateCausalAppend(
            count: lethal.count * (lifecycleState == nil ? 7 : 9)
                + householdEventCount
                + (dependentCareState?.configuration.maximumCareTransitionsPerTick ?? 0)
                + terminalWorkEventCount
        )
        let preDeathIDs = Set(statesById.values.map(\.agentID))
        guard lethal.map(\.agentID) == lethal.map(\.agentID).sorted(),
              Set(lethal.map(\.agentID)).count == lethal.count else {
            throw AgentSessionError.mortality(.invalidState("lethal order"))
        }
        var prevalidatedDeathIDs: [AgentID: AgentDeathID] = [:]
        var terminalPreview = mortality.unrecoveredAtDeath
        for (offset, item) in lethal.enumerated() {
            guard let state = statesById[item.agentID.rawValue], state.health == 0,
                  item.healthBefore > 0,
                  validLethalPhysiology(state: state, candidate: item),
                  registry.members.contains(where: { $0.agentID == item.agentID }) else {
                throw AgentSessionError.mortality(.invalidLethalTransition(item.agentID.rawValue))
            }
            let ordinal = mortality.totalDeathCount + offset + 1
            let digest = AgentMortalityDigest.make(
                "\(simulationID.rawValue)|\(item.agentID.rawValue)|\(mortalityTick)|"
                    + "\(item.cause.rawValue)|\(ordinal)"
            )
            let deathID = AgentDeathID(
                rawValue: "death-\(item.agentID.rawValue)-t\(mortalityTick)-\(digest)"
            )!
            guard !mortality.processedDeathIDs.contains(deathID),
                  !mortality.records.contains(where: { $0.agentID == item.agentID }),
                  prevalidatedDeathIDs[item.agentID] == nil else {
                throw AgentSessionError.mortality(.duplicateDeath(deathID.rawValue))
            }
            guard state.resourceInventory.isEmpty
                    || terminalPreview.add(state.resourceInventory.amounts) else {
                throw AgentSessionError.mortality(.terminalResourceOverflow)
            }
            prevalidatedDeathIDs[item.agentID] = deathID
        }
        for item in lethal {
            guard let state = statesById[item.agentID.rawValue], state.health == 0,
                  item.healthBefore > 0,
                  validLethalPhysiology(state: state, candidate: item),
                  let memberIndex = registry.members.firstIndex(where: {
                      $0.agentID == item.agentID
                  }) else {
                throw AgentSessionError.mortality(.invalidLethalTransition(item.agentID.rawValue))
            }
            let member = registry.members[memberIndex]
            let deathID = prevalidatedDeathIDs[item.agentID]!
            guard !mortality.processedDeathIDs.contains(deathID),
                  !mortality.records.contains(where: { $0.agentID == item.agentID }) else {
                throw AgentSessionError.mortality(.duplicateDeath(deathID.rawValue))
            }
            let populationBefore = registry.members.count
            let carried = state.resourceInventory.amounts
            let carriedTotal = carried.reduce(0) { $0 + $1.quantity }
            let terminalBefore = mortality.unrecoveredAtDeath.totalCount
            guard carried.isEmpty || mortality.unrecoveredAtDeath.add(carried) else {
                throw AgentSessionError.mortality(.terminalResourceOverflow)
            }

            let continuityEventID = item.pendingMaterialExitEventID
                ?? mortality.lastMortalityEventID
            let lethalCauses = Array(Set([
                item.terminalPhysiologyEventID,
                item.pendingMaterialExitEventID,
                item.materialExitEventIDs.last,
                continuityEventID,
            ].compactMap { $0 })).sorted()
            if homeostasisState != nil {
                guard let terminal = item.terminalPhysiologyEventID,
                      lethalCauses.contains(terminal) else {
                    throw AgentSessionError.mortality(.invalidLethalTransition(
                        item.agentID.rawValue
                    ))
                }
            }
            let lethalEvent = try requiredMortalityEvent(
                kind: .lethalHealthDepletion,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: lethalCauses,
                payload: mortalityDeathPayload(
                    deathID: deathID,
                    state: state,
                    member: member,
                    cause: item.cause,
                    healthBefore: item.healthBefore,
                    populationBefore: populationBefore,
                    populationAfter: populationBefore,
                    carriedQuantity: carriedTotal,
                    cancelledCommitments: 0,
                    reason: "\(item.cause.rawValue) depleted health"
                ),
                summary: "lethal \(item.cause.rawValue) agent=\(item.agentID.rawValue) death=\(deathID.rawValue)"
            )

            let reservationCount = reservationsByTarget.values.filter {
                $0.agentId == item.agentID.rawValue
            }.count
            reservationsByTarget = reservationsByTarget.filter {
                $0.value.agentId != item.agentID.rawValue
            }
            failedNaturalResourceTargetKeysByAgentId.removeValue(forKey: item.agentID.rawValue)
            let socialCount = activeSocialVerificationByAgentId.removeValue(
                forKey: item.agentID.rawValue
            ) == nil ? 0 : 1
            lastSocialShareTickByAgentId.removeValue(forKey: item.agentID.rawValue)

            var signalCount = 0
            for index in physicalSignals.indices where physicalSignals[index].status == .pending
                && (physicalSignals[index].senderID == item.agentID
                    || physicalSignals[index].intendedRecipientID == item.agentID) {
                physicalSignals[index].status = .cancelled
                signalCount += 1
            }
            let presentationCount = physicalPresentationRequests.filter {
                $0.senderID == item.agentID && $0.presentedAtTick == nil
            }.count
            physicalPresentationRequests.removeAll {
                $0.senderID == item.agentID && $0.presentedAtTick == nil
            }

            let taskIndices = sharedTasks.indices.filter {
                !sharedTasks[$0].status.isTerminal
                    && (sharedTasks[$0].issuerID == item.agentID
                        || sharedTasks[$0].helperID == item.agentID)
            }
            let taskIDs = taskIndices.map { sharedTasks[$0].taskID.rawValue }
            for index in taskIndices {
                sharedTasks[index].status = .cancelled
                sharedTasks[index].reason = "participantDied"
            }
            let offerIDs = sharedTaskOffers.filter {
                $0.issuerID == item.agentID || $0.helperID == item.agentID
            }.map { $0.signalID.rawValue }
            sharedTaskOffers.removeAll {
                $0.issuerID == item.agentID || $0.helperID == item.agentID
            }
            lastCooperationOfferTickByIssuerID.removeValue(forKey: item.agentID.rawValue)

            var constructionBlocked = false
            if var project = constructionProject, project.builderAgentId == item.agentID.rawValue,
               project.status != .completed {
                project.recordFailure(.builderDied)
                constructionProject = project
                constructionBlocked = true
            }

            let pointerCount = [
                lastPerceptionEventByAgentID.removeValue(forKey: item.agentID),
                lastDecisionEventByAgentID.removeValue(forKey: item.agentID),
                lastOutcomeEventByAgentID.removeValue(forKey: item.agentID),
            ].compactMap { $0 }.count

            let reservationIDs = reservationCount > 0
                ? ["reservation:\(item.agentID.rawValue)"] : []
            var cancelledIDs = reservationIDs + taskIDs + offerIDs
            cancelledIDs = Array(cancelledIDs.sorted().prefix(
                mortality.configuration.maximumCancelledCommitmentIDsPerDeath
            ))

            let resourcesEvent = try requiredMortalityEvent(
                kind: .mortalityResourcesRetired,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: [lethalEvent.eventID],
                payload: .mortalityResources(
                    deathID: deathID.rawValue,
                    amounts: carried,
                    terminalBefore: terminalBefore,
                    terminalAfter: mortality.unrecoveredAtDeath.totalCount,
                    conservationExact: true
                ),
                summary: "mortality resources retired death=\(deathID.rawValue) quantity=\(carriedTotal)"
            )
            let commitmentsEvent = try requiredMortalityEvent(
                kind: .mortalityCommitmentsResolved,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: [lethalEvent.eventID],
                payload: .mortalityCommitments(
                    deathID: deathID.rawValue,
                    reservations: reservationCount,
                    socialVerifications: socialCount,
                    signals: signalCount + presentationCount,
                    tasksAndOffers: taskIndices.count + offerIDs.count,
                    constructionBlocked: constructionBlocked,
                    reason: "participantDied"
                ),
                summary: "mortality commitments resolved death=\(deathID.rawValue)"
            )
            for index in taskIndices { sharedTasks[index].terminalEventID = commitmentsEvent.eventID }

            var migrationFailureEvent: AgentCausalEvent?
            if let migrationIndex = registry.migrations.firstIndex(where: {
                $0.migrantID == item.agentID && !$0.status.isTerminal
            }) {
                let migration = registry.migrations[migrationIndex]
                migrationFailureEvent = try requiredMortalityEvent(
                    kind: .migrationFailed,
                    actorID: item.agentID,
                    subjectID: item.agentID,
                    causes: [migration.startedEventID, commitmentsEvent.eventID].sorted(),
                    payload: .migration(
                        migrationID: migration.migrationID.rawValue,
                        migrantID: migration.migrantID.rawValue,
                        origin: migration.origin.rawValue,
                        destination: migration.destinationSettlementID.rawValue,
                        entry: migration.entryPosition,
                        reception: migration.receptionPosition,
                        status: AgentMigrationStatus.failed.rawValue,
                        reason: AgentMigrationFailure.memberDied.rawValue,
                        routeLength: migration.route.count
                    ),
                    summary: "migration failed member died id=\(migration.migrationID.rawValue)"
                )
                registry.migrations[migrationIndex].status = .failed
                registry.migrations[migrationIndex].failure = .memberDied
            }

            // Capture the terminal activity boundary after lethal survival and
            // before the authoritative active-state removal below.
            let terminalActivity = AgentTerminalActivitySnapshot(state: state)
            if let activity = activeAutonomousActivity(for: item.agentID) {
                _ = try recordAutonomousActivityOutcome(
                    AgentAutonomousActivityOutcome(
                        activityID: activity.activityID,
                        actorID: item.agentID,
                        lifecycle: .interrupted,
                        completedAtTick: mortalityTick,
                        sourceEventID: lethalEvent.eventID,
                        reason: "participant died"
                    )
                )
            }
            let terminalHomeostasis = homeostasisProfile(for: item.agentID)
            let terminalAge = try? lifecycleState?.members.first {
                $0.agentID == item.agentID
            }?.age(at: mortalityTick)
            let terminalStage = lifecycleState?.members.first {
                $0.agentID == item.agentID
            }?.currentStage
            try endWorkCommitmentsForTerminalAgent(item.agentID)
            let careEventID = try applyDependentCareDeath(
                agentID: item.agentID,
                lethalAgentIDs: Set(lethal.map(\.agentID)),
                causeEventID: lethalEvent.eventID,
                at: mortalityTick
            )
            try applyLifecycleDeath(
                agentID: item.agentID,
                causeEventID: lethalEvent.eventID,
                at: mortalityTick
            )
            let householdEventID = try closeHouseholdMembershipForDeath(
                agentID: item.agentID,
                causeEventID: commitmentsEvent.eventID,
                at: mortalityTick
            )
            registry.members.remove(at: memberIndex)
            registry.settlement.residentIDs.removeAll { $0 == item.agentID }
            registry.settlement.inTransitIDs.removeAll { $0 == item.agentID }
            statesById[item.agentID.rawValue] = nil
            let populationAfter = registry.members.count

            let exitEvent = try requiredMortalityEvent(
                kind: .populationMemberExited,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: [
                    lethalEvent.eventID,
                    resourcesEvent.eventID,
                    commitmentsEvent.eventID,
                    migrationFailureEvent?.eventID,
                    careEventID,
                    householdEventID,
                ].compactMap { $0 }.sorted(),
                payload: mortalityDeathPayload(
                    deathID: deathID,
                    state: state,
                    member: member,
                    cause: item.cause,
                    healthBefore: item.healthBefore,
                    populationBefore: populationBefore,
                    populationAfter: populationAfter,
                    carriedQuantity: carriedTotal,
                    cancelledCommitments: cancelledIDs.count,
                    reason: "active population exit"
                ),
                summary: "population member exited agent=\(item.agentID.rawValue) \(populationBefore)>\(populationAfter)"
            )
            registry.lastPopulationEventID = exitEvent.eventID
            let deathEvent = try requiredMortalityEvent(
                kind: .agentDeathFinalized,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: [exitEvent.eventID],
                payload: mortalityDeathPayload(
                    deathID: deathID,
                    state: state,
                    member: member,
                    cause: item.cause,
                    healthBefore: item.healthBefore,
                    populationBefore: populationBefore,
                    populationAfter: populationAfter,
                    carriedQuantity: carriedTotal,
                    cancelledCommitments: cancelledIDs.count,
                    reason: "death finalized"
                ),
                summary: "agent death finalized agent=\(item.agentID.rawValue) death=\(deathID.rawValue)"
            )

            let cleanup = AgentMortalityCleanupCounts(
                reservations: reservationCount,
                socialVerifications: socialCount,
                physicalSignals: signalCount,
                physicalPresentations: presentationCount,
                cooperationTasks: taskIndices.count,
                cooperationOffers: offerIDs.count,
                constructionProjects: constructionBlocked ? 1 : 0,
                activePointers: pointerCount
            )
            let finalDigest = AgentMortalityDigest.make(
                "\(item.agentID.rawValue)|\(mortalityTick)|\(state.position.x),\(state.position.y),\(state.position.z)|"
                    + "\(state.health)|\(state.needs.hunger)|\(state.needs.fatigue)|\(state.fear)|"
                    + "\(state.ticksAlive)|\(state.currentGoal.kind.rawValue)|"
                    + "\(state.lastAction?.name ?? "none")|\(carried.map { "\($0.resource.rawValue):\($0.quantity)" }.joined(separator: ","))|"
                    + terminalActivity.canonicalText
            )
            let memoryLimit = mortality.configuration.maximumFinalMemoryEntries
            let finalMemory = memoryLimit == 0 ? [] : Array(state.memory.suffix(memoryLimit))
            let record = AgentMortalityRecord(
                deathID: deathID,
                agentID: item.agentID,
                populationOrdinal: member.ordinal,
                founder: member.founder,
                settlementID: member.settlementID,
                membershipStatus: member.status,
                migrationID: member.migrationID,
                cause: item.cause,
                deathTick: mortalityTick,
                finalPosition: state.position,
                finalHome: state.homePosition,
                healthBeforeLethalDamage: item.healthBefore,
                finalHealth: state.health,
                finalHunger: state.needs.hunger,
                finalFatigue: state.needs.fatigue,
                finalFear: state.fear,
                starvationDamageTotal: state.survivalProgress?.starvationDamageTaken ?? 0,
                ticksAlive: state.ticksAlive,
                lastGoal: state.currentGoal.kind,
                lastAction: state.lastAction,
                terminalActivity: terminalActivity,
                carriedInventory: carried,
                finalMemory: finalMemory,
                finalStateDigest: finalDigest,
                registrationEventID: member.registrationEventID,
                arrivalEventID: member.arrivalEventID,
                terminalPhysiologyEventID: item.terminalPhysiologyEventID,
                pendingMaterialExitEventID: item.pendingMaterialExitEventID,
                materialExitEventIDs: item.materialExitEventIDs,
                lethalDamageEventID: lethalEvent.eventID,
                deathEventID: deathEvent.eventID,
                populationExitEventID: exitEvent.eventID,
                resourcesRetiredEventID: resourcesEvent.eventID,
                commitmentsResolvedEventID: commitmentsEvent.eventID,
                cancelledCommitmentIDs: cancelledIDs,
                cleanupCounts: cleanup,
                finalVitalStatus: .dead,
                finalHomeostasis: terminalHomeostasis,
                demographicAgeTicks: terminalAge ?? nil,
                lifeStage: terminalStage
            )
            mortality.records.append(record)
            mortality.records.sort(by: mortalityRecordSort)
            mortality.totalDeathCount += 1
            mortality.terminalStarvationDamageTotal += record.starvationDamageTotal
            mortality.rollingDigest = AgentMortalityDigest.make(
                "\(mortality.rollingDigest)|\(deathID.rawValue)|\(finalDigest)"
            )
            mortality.exitFrames.append(AgentPopulationExitFrame(
                deathID: deathID,
                agentID: item.agentID,
                tick: mortalityTick,
                populationBefore: populationBefore,
                populationAfter: populationAfter,
                residentCountAfter: registry.settlement.residentIDs.count,
                migrantCountAfter: registry.settlement.inTransitIDs.count,
                carriedRetired: carriedTotal,
                populationExitEventID: exitEvent.eventID
            ))
            mortality.lastMortalityEventID = deathEvent.eventID
            try removeHomeostasisProfileAfterDeath(item.agentID)
            if mortality.records.count > mortality.configuration.maximumRetainedDeathRecords {
                let removed = mortality.records.count
                    - mortality.configuration.maximumRetainedDeathRecords
                mortality.records.removeFirst(removed)
                mortality.evictionCounts.deathRecords += removed
            }
            mortality.processedDeathIDs = mortality.records.map(\.deathID).sorted()
            if mortality.exitFrames.count > mortality.configuration.maximumExitFrames {
                let removed = mortality.exitFrames.count - mortality.configuration.maximumExitFrames
                mortality.exitFrames.removeFirst(removed)
                mortality.evictionCounts.exitFrames += removed
            }
        }
        let deadIDs = Set(lethal.map(\.agentID))
        let deadRawIDs = Set(deadIDs.map(\.rawValue))
        let remaining = Set(statesById.values.map(\.agentID))
        let activePhysicalReference = physicalSignals.contains {
            $0.status == .pending
                && (deadIDs.contains($0.senderID) || deadIDs.contains($0.intendedRecipientID))
        } || physicalPresentationRequests.contains {
            $0.presentedAtTick == nil && deadIDs.contains($0.senderID)
        }
        let activeCooperationReference = sharedTasks.contains {
            !$0.status.isTerminal
                && (deadIDs.contains($0.issuerID) || deadIDs.contains($0.helperID))
        } || sharedTaskOffers.contains {
            deadIDs.contains($0.issuerID) || deadIDs.contains($0.helperID)
        }
        let invalidDeadBuilder = constructionProject.map { project in
            guard deadRawIDs.contains(project.builderAgentId) else { return false }
            return project.status != .blocked || project.lastFailure != .builderDied
        } ?? false
        guard remaining == preDeathIDs.subtracting(lethal.map(\.agentID)),
              Set(registry.members.map(\.agentID)) == remaining,
              registry.settlement.residentIDs.allSatisfy({ !deadIDs.contains($0) }),
              registry.settlement.inTransitIDs.allSatisfy({ !deadIDs.contains($0) }),
              reservationsByTarget.values.allSatisfy({ !deadRawIDs.contains($0.agentId) }),
              failedNaturalResourceTargetKeysByAgentId.keys.allSatisfy({ !deadRawIDs.contains($0) }),
              activeSocialVerificationByAgentId.keys.allSatisfy({ !deadRawIDs.contains($0) }),
              lastSocialShareTickByAgentId.keys.allSatisfy({ !deadRawIDs.contains($0) }),
              lastCooperationOfferTickByIssuerID.keys.allSatisfy({ !deadRawIDs.contains($0) }),
              lastPerceptionEventByAgentID.keys.allSatisfy({ !deadIDs.contains($0) }),
              lastDecisionEventByAgentID.keys.allSatisfy({ !deadIDs.contains($0) }),
              lastOutcomeEventByAgentID.keys.allSatisfy({ !deadIDs.contains($0) }),
              !activePhysicalReference,
              !activeCooperationReference,
              !invalidDeadBuilder,
              homeostasisState == nil
                || Set(homeostasisState?.profiles.map(\.agentID) ?? []) == remaining,
              conservationSnapshotWith(mortality: mortality).balanced else {
            throw AgentSessionError.mortality(.invalidState("post-transition invariants"))
        }
        populationRegistry = registry
        mortalityState = mortality
        try validateHouseholdCrossDomainIfEnabled()
        try validateDependentCareCrossDomainIfEnabled()
    }

    private func conservationSnapshotWith(
        mortality: AgentMortalityState
    ) -> AgentResourceConservationSnapshot {
        let carried = AgentResourceKind.allCases.map { resource in
            AgentResourceAmount(
                resource: resource,
                quantity: statesById.values.reduce(0) {
                    $0 + $1.resourceInventory.count(of: resource)
                }
            )
        }
        return AgentResourceConservationSnapshot(
            harvested: harvestedResourceTotals.amounts,
            carried: carried,
            campStock: campStock.amounts,
            consumed: consumedResourceTotals.amounts,
            constructionEscrow: constructionProject?.materialEscrow.amounts ?? [],
            constructed: constructionProject?.placedMaterialTotals.amounts ?? [],
            unrecoveredAtDeath: mortality.unrecoveredAtDeath.amounts
        )
    }

    private func mortalityDeathPayload(
        deathID: AgentDeathID,
        state: AgentSessionAgentState,
        member: AgentPopulationMemberRecord,
        cause: AgentMortalityCause,
        healthBefore: Int,
        populationBefore: Int,
        populationAfter: Int,
        carriedQuantity: Int,
        cancelledCommitments: Int,
        reason: String
    ) -> AgentCausalPayload {
        .mortalityDeath(
            deathID: deathID.rawValue,
            agentID: state.id,
            cause: cause.rawValue,
            tick: tick,
            healthBefore: healthBefore,
            healthAfter: state.health,
            hunger: state.needs.hunger,
            populationBefore: populationBefore,
            populationAfter: populationAfter,
            membershipStatus: member.status.rawValue,
            position: state.position,
            carriedQuantity: carriedQuantity,
            cancelledCommitments: cancelledCommitments,
            reason: reason
        )
    }

    private func validLethalPhysiology(
        state: AgentSessionAgentState,
        candidate: AgentLethalMortalityCandidate
    ) -> Bool {
        if homeostasisState != nil {
            return homeostasisProfile(for: candidate.agentID)?.vitalStatus == .dead
                && candidate.cause != .starvation
                && candidate.terminalPhysiologyEventID != nil
        }
        return state.needs.hunger
            >= configuration.survivalConfiguration.criticalHungerThreshold
            && candidate.cause == .starvation
    }

    private func terminalHomeostasisEventID(
        for agentID: AgentID,
        at mortalityTick: Int
    ) throws -> AgentCausalEventID? {
        guard homeostasisState != nil else { return nil }
        guard let profile = homeostasisProfile(for: agentID),
              profile.vitalStatus == .dead,
              profile.condition == .dead,
              profile.lastUpdatedTick == mortalityTick,
              let event = causalLedger.events.first(where: {
                  $0.eventID == profile.lastEventID
              }),
              event.kind == .homeostasisChanged,
              event.origin == .homeostasisTransition,
              event.actorID == agentID,
              event.subjectID == agentID,
              event.simulationTick.rawValue == mortalityTick else {
            throw AgentSessionError.mortality(.invalidLethalTransition(
                agentID.rawValue
            ))
        }
        return event.eventID
    }

    private func homeostasisMortalityCause(
        for agentID: AgentID
    ) -> AgentMortalityCause {
        guard let profile = homeostasisProfile(for: agentID) else {
            return .starvation
        }
        let factors = Set(profile.activeFactors.filter(\.harmful).map(\.code))
        if factors.contains(.compoundedDeprivation)
            || (factors.contains(.hunger) && factors.contains(.fatigue)) {
            return .compoundedHomeostaticFailure
        }
        if factors.contains(.fatigue) { return .exhaustion }
        return .deprivation
    }

    private mutating func requiredMortalityEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        subjectID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .mortalityTransition,
            actorID: actorID,
            subjectID: subjectID,
            causes: causes,
            payload: payload,
            summary: summary
        ) else { throw AgentSessionError.mortality(.causalLedgerRequired) }
        return event
    }

    private func mortalityRecordSort(
        _ lhs: AgentMortalityRecord,
        _ rhs: AgentMortalityRecord
    ) -> Bool {
        if lhs.deathTick != rhs.deathTick { return lhs.deathTick < rhs.deathTick }
        if lhs.agentID != rhs.agentID { return lhs.agentID < rhs.agentID }
        return lhs.deathID < rhs.deathID
    }
}

extension AgentCausalEventKind {
    var isMortality: Bool {
        switch self {
        case .mortalityInitialized, .mortalityMaterialExitPending,
             .lethalHealthDepletion, .agentDeathFinalized,
             .populationMemberExited, .mortalityResourcesRetired,
             .mortalityCommitmentsResolved, .mortalityStateCleared:
            return true
        default:
            return false
        }
    }
}
