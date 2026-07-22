private struct AgentLethalMortalityCandidate {
    let agentID: AgentID
    let healthBefore: Int
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
                maximumExitFrames: configuration.maximumExitFrames
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
        guard state.totalDeathCount == 0, state.unrecoveredAtDeath.isEmpty else {
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
            "config=\(mortality.configuration.maximumDeathsPerTick),\(mortality.configuration.maximumRetainedDeathRecords),\(mortality.configuration.maximumFinalMemoryEntries),\(mortality.configuration.maximumCancelledCommitmentIDsPerDeath),\(mortality.configuration.maximumExitFrames)",
            "total=\(mortality.totalDeathCount)",
            "processed=\(mortality.processedDeathIDs.sorted().map(\.rawValue).joined(separator: ","))",
            "terminal=\(mortality.unrecoveredAtDeath.amounts.map { "\($0.resource.rawValue):\($0.quantity)" }.joined(separator: ","))",
            "starvation=\(mortality.terminalStarvationDamageTotal)",
            records.map { "\($0.deathTick):\($0.agentID.rawValue):\($0.deathID.rawValue):\($0.finalStateDigest)" }.joined(separator: ";"),
            exits.map { "\($0.tick):\($0.agentID.rawValue):\($0.populationBefore)>\($0.populationAfter)" }.joined(separator: ";"),
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

    mutating func applyMortalitySurvivalBoundary(
        at mortalityTick: Int
    ) throws -> [String: AgentMemoryEntry] {
        guard let mortality = mortalityState else { return [:] }
        var candidate = self
        var survivalMemories: [String: AgentMemoryEntry] = [:]
        var lethal: [AgentLethalMortalityCandidate] = []
        for id in candidate.sortedIds {
            guard var state = candidate.statesById[id] else { continue }
            let healthBefore = state.health
            let memory = candidate.applySurvivalTick(to: &state, tick: mortalityTick)
            state.ticksAlive += 1
            if let memory {
                candidate.appendMemory(memory, to: &state.memory)
                survivalMemories[id] = memory
            }
            candidate.statesById[id] = state
            if healthBefore > 0, state.health == 0 {
                lethal.append(AgentLethalMortalityCandidate(
                    agentID: state.agentID,
                    healthBefore: healthBefore
                ))
            }
        }
        lethal.sort { $0.agentID < $1.agentID }
        guard lethal.count <= mortality.configuration.maximumDeathsPerTick else {
            throw AgentSessionError.mortality(.deathsPerTickExceeded(lethal.count))
        }
        if !lethal.isEmpty {
            try candidate.finalizeMortalityTransitions(lethal, at: mortalityTick)
            for entry in lethal { survivalMemories.removeValue(forKey: entry.agentID.rawValue) }
        }
        self = candidate
        return survivalMemories
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
                  state.needs.hunger >= configuration.survivalConfiguration.criticalHungerThreshold,
                  registry.members.contains(where: { $0.agentID == item.agentID }) else {
                throw AgentSessionError.mortality(.invalidLethalTransition(item.agentID.rawValue))
            }
            let ordinal = mortality.totalDeathCount + offset + 1
            let digest = AgentMortalityDigest.make(
                "\(simulationID.rawValue)|\(item.agentID.rawValue)|\(mortalityTick)|"
                    + "\(AgentMortalityCause.starvation.rawValue)|\(ordinal)"
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
                  state.needs.hunger >= configuration.survivalConfiguration.criticalHungerThreshold,
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

            let lethalEvent = try requiredMortalityEvent(
                kind: .lethalHealthDepletion,
                actorID: item.agentID,
                subjectID: item.agentID,
                causes: [mortality.lastMortalityEventID],
                payload: mortalityDeathPayload(
                    deathID: deathID,
                    state: state,
                    member: member,
                    healthBefore: item.healthBefore,
                    populationBefore: populationBefore,
                    populationAfter: populationBefore,
                    carriedQuantity: carriedTotal,
                    cancelledCommitments: 0,
                    reason: "starvation depleted health"
                ),
                summary: "lethal starvation agent=\(item.agentID.rawValue) death=\(deathID.rawValue)"
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
                cause: .starvation,
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
                lethalDamageEventID: lethalEvent.eventID,
                deathEventID: deathEvent.eventID,
                populationExitEventID: exitEvent.eventID,
                resourcesRetiredEventID: resourcesEvent.eventID,
                commitmentsResolvedEventID: commitmentsEvent.eventID,
                cancelledCommitmentIDs: cancelledIDs,
                cleanupCounts: cleanup
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
            cause: AgentMortalityCause.starvation.rawValue,
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
        case .mortalityInitialized, .lethalHealthDepletion, .agentDeathFinalized,
             .populationMemberExited, .mortalityResourcesRetired,
             .mortalityCommitmentsResolved, .mortalityStateCleared:
            return true
        default:
            return false
        }
    }
}
