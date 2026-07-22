extension AgentSimulationSession {
    public var livestockEnabled: Bool { livestockState != nil }

    public func livestockSnapshot() -> AgentLivestockSnapshot {
        guard let state = livestockState else {
            return AgentLivestockSnapshot(
                enabled: false, herds: [], managedAnimals: [], activeTasks: [],
                reservations: [], retainedTaskRecords: [], breedingDecisions: [],
                productRecords: [], lossRecords: [], capital: livestockCapital(nil),
                evictionCounts: AgentLivestockEvictionCounts(),
                digest: AgentLivestockDigest.make("disabled")
            )
        }
        return AgentLivestockSnapshot(
            enabled: true, herds: state.herds, managedAnimals: state.managedAnimals,
            activeTasks: state.activeTasks, reservations: activeLivestockReservations(state),
            retainedTaskRecords: state.retainedTaskRecords,
            breedingDecisions: state.breedingDecisions, productRecords: state.productRecords,
            lossRecords: state.lossRecords, capital: livestockCapital(state),
            evictionCounts: state.evictionCounts, digest: livestockDigest(state)
        )
    }

    public func livestockCapitalSnapshot() -> AgentLivestockCapitalSnapshot {
        livestockCapital(livestockState)
    }

    public func livestockFeedPressure(
        compatibleFeedQuantity: Int,
        reservedPlantingQuantity: Int
    ) -> AgentLivestockFeedPressureSnapshot {
        let living = livestockState?.managedAnimals.filter(\.status.resolvedLiving).count ?? 0
        let eligible = max(0, compatibleFeedQuantity - reservedPlantingQuantity)
        let consumed = livestockState?.retainedTaskRecords.reduce(0) {
            $0 + ($1.outcome.kind == .feed && $1.outcome.status.successful
                ? $1.outcome.consumedQuantity : 0)
        } ?? 0
        let level: AgentLivestockFeedPressureSnapshot.Level
        if living == 0 || eligible >= living * 2 { level = .low }
        else if eligible >= living { level = .medium }
        else { level = .high }
        return AgentLivestockFeedPressureSnapshot(
            managedLivingCount: living, compatibleFeedQuantity: max(0, compatibleFeedQuantity),
            reservedPlantingQuantity: max(0, reservedPlantingQuantity),
            eligibleFeedQuantity: eligible, recentFeedConsumption: consumed, level: level
        )
    }

    public mutating func setLivestockEnabled(
        _ enabled: Bool,
        configuration: AgentLivestockConfiguration = .live
    ) throws {
        if enabled {
            guard livestockState == nil else { throw AgentSessionError.livestock(.alreadyEnabled) }
            guard causalLedger.policy != .disabled else { throw AgentSessionError.livestock(.causalLedgerRequired) }
            guard populationRegistry != nil else { throw AgentSessionError.livestock(.populationRequired) }
            guard lifecycleState != nil else { throw AgentSessionError.livestock(.lifecycleRequired) }
            guard skillState != nil else { throw AgentSessionError.livestock(.skillsRequired) }
            guard ecologicalObservationState != nil else { throw AgentSessionError.livestock(.ecologicalObservationRequired) }
            var candidate = self
            try candidate.prevalidateCausalAppend(count: 1)
            let digest = AgentLivestockDigest.make("empty")
            let event = try candidate.requiredLivestockEvent(
                kind: .livestockInitialized,
                payload: candidate.livestockPayload(status: "initialized", digest: digest),
                summary: "livestock initialized without retroactive animals"
            )
            candidate.livestockState = AgentLivestockState(
                configuration: configuration, herds: [], managedAnimals: [], activeTasks: [],
                reservations: [], retainedTaskRecords: [], breedingDecisions: [],
                productRecords: [], lossRecords: [], processedActionIDs: [],
                totalActionCount: 0, totalOffspringCount: 0,
                evictionCounts: AgentLivestockEvictionCounts(), rollingDigest: digest,
                initializedEventID: event.eventID, lastLivestockEventID: event.eventID,
                transitionTick: candidate.tick, actionsAtTick: 0
            )
            try candidate.validateLivestockStateIfEnabled()
            self = candidate
        } else if livestockState != nil {
            throw AgentSessionError.livestock(.unsafeDisable)
        }
    }

    public mutating func applyLivestockOperation(_ operation: AgentLivestockOperation) throws {
        var candidate = self
        try candidate.applyLivestockOperationInPlace(operation)
        try candidate.validateLivestockStateIfEnabled()
        self = candidate
    }

    private mutating func applyLivestockOperationInPlace(
        _ operation: AgentLivestockOperation
    ) throws {
        switch operation {
        case let .establishHerd(herdID, speciesKey, area, responsible):
            try establishLivestockHerd(herdID, speciesKey: speciesKey, area: area, responsible: responsible)
        case let .admitObservedAnimal(recordID, herdID, actorID, speciesKey, position, stage, source, feed):
            try admitLivestockAnimal(recordID, herdID: herdID, actorID: actorID,
                speciesKey: speciesKey, position: position, stage: stage, source: source,
                compatibleFeedAvailable: feed)
        case let .queueTask(request): try queueLivestockTask(request)
        case let .recordOutcome(outcome): try recordLivestockOutcome(outcome)
        case let .recordBreedingDecision(actionID, herdID, actorID, parents, feed, reserved):
            try decideLivestockBreeding(actionID, herdID: herdID, actorID: actorID,
                parents: parents, compatibleFeed: feed, reservedPlanting: reserved)
        case let .reconcile(resolutions): try reconcileLivestock(resolutions)
        }
    }

    private mutating func establishLivestockHerd(
        _ herdID: AgentLivestockHerdID,
        speciesKey: String,
        area: AgentLivestockManagementArea,
        responsible: [AgentID]
    ) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        guard state.herds.count < state.configuration.maximumHerds else { throw AgentSessionError.livestock(.capacityReached("herds")) }
        guard !state.herds.contains(where: { $0.herdID == herdID }) else { throw AgentSessionError.livestock(.conflict("herd identity")) }
        guard validLivestockSpecies(speciesKey), area.minimum.x <= area.maximum.x,
              area.minimum.y <= area.maximum.y, area.minimum.z <= area.maximum.z,
              area.maximum.x - area.minimum.x <= 128, area.maximum.y - area.minimum.y <= 32,
              area.maximum.z - area.minimum.z <= 128 else { throw AgentSessionError.livestock(.invalidHerd("species or bounded area")) }
        let actors = Array(Set(responsible)).sorted()
        guard !actors.isEmpty, actors.count <= 8 else { throw AgentSessionError.livestock(.invalidHerd("responsible agents")) }
        for actor in actors { try requireLivestockActor(actor) }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentLivestockDigest.make("\(state.rollingDigest)|herd|\(herdID.rawValue)|\(speciesKey)|\(tick)")
        let event = try requiredLivestockEvent(
            kind: .livestockGroupEstablished, actorID: actors.first,
            operationID: AgentOperationID(rawValue: "livestock-herd:\(herdID.rawValue)"),
            causes: [state.lastLivestockEventID],
            payload: livestockPayload(herdID: herdID, status: "established", digest: digest),
            summary: "livestock group established herd=\(herdID.rawValue) species=\(speciesKey)"
        )
        state.herds.append(AgentManagedHerd(
            herdID: herdID, speciesKey: speciesKey, managementArea: area,
            responsibleAgentIDs: actors, managedAnimalRecordIDs: [], establishedAtTick: tick,
            establishedEventID: event.eventID
        ))
        state.herds.sort { $0.herdID < $1.herdID }
        state.lastLivestockEventID = event.eventID
        state.rollingDigest = digest
        livestockState = state
    }

    private mutating func admitLivestockAnimal(
        _ recordID: AgentManagedAnimalRecordID,
        herdID: AgentLivestockHerdID,
        actorID: AgentID,
        speciesKey: String,
        position: AgentPosition,
        stage: AgentAnimalLifeStage,
        source: AgentCausalEventID,
        compatibleFeedAvailable: Bool
    ) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        try requireLivestockActor(actorID)
        guard let herdIndex = state.herds.firstIndex(where: { $0.herdID == herdID }) else { throw AgentSessionError.livestock(.unknownHerd(herdID)) }
        guard herdIndex >= 0, state.herds[herdIndex].speciesKey == speciesKey,
              !state.managedAnimals.contains(where: { $0.recordID == recordID }),
              !state.managedAnimals.contains(where: {
                  $0.status.resolvedLiving && $0.speciesKey == speciesKey
                      && $0.lastKnownPosition == position
              }),
              state.herds[herdIndex].managedAnimalRecordIDs.count < state.configuration.maximumManagedAnimalsPerHerd,
              compatibleFeedAvailable else { throw AgentSessionError.livestock(.invalidAnimal("identity, capacity, or feed proof")) }
        guard let observation = ecologicalObservations(for: actorID).first(where: {
            $0.causalEventID == source && $0.observation.isFresh(atSimulationTick: tick)
        }), observation.observation.animals.contains(where: {
            $0.speciesKey == speciesKey && $0.position == position && $0.lifeStage == stage && $0.count > 0
        }) else { throw AgentSessionError.livestock(.invalidAnimal("fresh physical observation")) }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentLivestockDigest.make("\(state.rollingDigest)|admit|\(recordID.rawValue)|\(source.rawValue)")
        let event = try requiredLivestockEvent(
            kind: .managedAnimalAdded, actorID: actorID,
            operationID: AgentOperationID(rawValue: "livestock-admit:\(recordID.rawValue)"),
            causes: [source],
            payload: livestockPayload(herdID: herdID, animalID: recordID, status: "managed", quantity: 1, digest: digest),
            summary: "observed animal admitted record=\(recordID.rawValue)"
        )
        state.managedAnimals.append(AgentManagedAnimalRecord(
            recordID: recordID, herdID: herdID, speciesKey: speciesKey,
            sourceObservationEventID: source, joinedAtTick: tick,
            status: state.herds[herdIndex].managementArea.contains(position) ? .managed : .outsideManagementArea,
            lastKnownPosition: position, lastObservedLifeStage: stage,
            breedingReady: false, productReady: false, lastResolvedAtTick: tick,
            lastReconciliationReason: "admitted from fresh observation", admittedEventID: event.eventID
        ))
        state.managedAnimals.sort { $0.recordID < $1.recordID }
        state.herds[herdIndex].managedAnimalRecordIDs.append(recordID)
        state.herds[herdIndex].managedAnimalRecordIDs.sort()
        state.lastLivestockEventID = event.eventID
        state.rollingDigest = digest
        livestockState = state
    }

    private mutating func queueLivestockTask(_ request: AgentLivestockTaskRequest) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        try requireLivestockActor(request.responsibleAgentID)
        guard activeCareEngagement(for: request.responsibleAgentID) == nil else { throw AgentSessionError.livestock(.humanCarePriority(request.responsibleAgentID)) }
        state.reservations.removeAll { $0.expiresAtTick < tick }
        guard state.activeTasks.count < state.configuration.maximumActiveTasks,
              state.reservations.count < state.configuration.maximumReservations else { throw AgentSessionError.livestock(.capacityReached("tasks or reservations")) }
        guard !state.activeTasks.contains(where: { $0.taskID == request.taskID }),
              state.herds.contains(where: { $0.herdID == request.herdID }),
              let animal = state.managedAnimals.first(where: { $0.recordID == request.primaryAnimalRecordID }),
              animal.herdID == request.herdID, animal.status.resolvedLiving else { throw AgentSessionError.livestock(.invalidTask("identity or unresolved animal")) }
        if let secondary = request.secondaryAnimalRecordID {
            guard secondary != request.primaryAnimalRecordID,
                  state.managedAnimals.contains(where: { $0.recordID == secondary && $0.herdID == request.herdID && $0.status.resolvedLiving }) else { throw AgentSessionError.livestock(.invalidTask("secondary animal")) }
        }
        let key = "\(request.herdID.rawValue):\(request.primaryAnimalRecordID.rawValue):\(request.kind.rawValue)"
        guard !state.reservations.contains(where: { $0.reservationKey == key }) else { throw AgentSessionError.livestock(.conflict("animal task reservation")) }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentLivestockDigest.make("\(state.rollingDigest)|task|\(request.taskID.rawValue)|\(tick)")
        let event = try requiredLivestockEvent(
            kind: .livestockTaskCompleted, actorID: request.responsibleAgentID,
            operationID: AgentOperationID(rawValue: "livestock-task:\(request.taskID.rawValue)"),
            causes: [state.lastLivestockEventID],
            payload: livestockPayload(herdID: request.herdID, animalID: request.primaryAnimalRecordID,
                taskID: request.taskID, status: "reserved", digest: digest),
            summary: "livestock task reserved id=\(request.taskID.rawValue) kind=\(request.kind.rawValue)"
        )
        let expires = tick + state.configuration.reservationLifetimeTicks
        state.activeTasks.append(AgentLivestockTask(
            taskID: request.taskID, herdID: request.herdID, kind: request.kind,
            primaryAnimalRecordID: request.primaryAnimalRecordID,
            secondaryAnimalRecordID: request.secondaryAnimalRecordID,
            responsibleAgentID: request.responsibleAgentID, targetPosition: request.targetPosition,
            createdAtTick: tick, expiresAtTick: expires, status: .reserved,
            createdEventID: event.eventID, terminalEventID: nil
        ))
        state.activeTasks.sort { $0.taskID < $1.taskID }
        state.reservations.append(AgentLivestockReservation(
            reservationKey: key, taskID: request.taskID,
            responsibleAgentID: request.responsibleAgentID, reservedAtTick: tick,
            expiresAtTick: expires
        ))
        state.reservations.sort { $0.reservationKey < $1.reservationKey }
        state.lastLivestockEventID = event.eventID
        state.rollingDigest = digest
        livestockState = state
    }

    private mutating func decideLivestockBreeding(
        _ actionID: AgentLivestockActionID,
        herdID: AgentLivestockHerdID,
        actorID: AgentID,
        parents: [AgentManagedAnimalRecordID],
        compatibleFeed: Int,
        reservedPlanting: Int
    ) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        try prepareLivestockAction(actionID, state: &state)
        try requireLivestockActor(actorID)
        guard compatibleFeed >= 0, reservedPlanting >= 0, reservedPlanting <= compatibleFeed,
              parents.count == 2, Set(parents).count == 2,
              let herd = state.herds.first(where: { $0.herdID == herdID }) else { throw AgentSessionError.livestock(.invalidOutcome("breeding inputs")) }
        let parentRecords = parents.compactMap { id in state.managedAnimals.first { $0.recordID == id } }
        guard parentRecords.count == 2, parentRecords.allSatisfy({ $0.herdID == herdID && $0.status.resolvedLiving && $0.lastObservedLifeStage == .adult }) else { throw AgentSessionError.livestock(.invalidOutcome("resolved adult parents")) }
        let eligible = compatibleFeed - reservedPlanting
        let status: AgentLivestockBreedingDecisionStatus
        if activeCareEngagement(for: actorID) != nil { status = .deferredHumanCare }
        else if herd.managedAnimalRecordIDs.count >= state.configuration.maximumManagedAnimalsPerHerd { status = .deferredCapacity }
        else if eligible < 2 { status = .deferredFeedShortage }
        else { status = .approved }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentLivestockDigest.make("\(state.rollingDigest)|breed-decision|\(actionID.rawValue)|\(status.rawValue)|\(eligible)")
        let event = try requiredLivestockEvent(
            kind: .livestockTaskCompleted, actorID: actorID,
            operationID: AgentOperationID(rawValue: actionID.rawValue),
            causes: [state.lastLivestockEventID],
            payload: livestockPayload(herdID: herdID, animalID: parents.first,
                actionID: actionID, status: status.rawValue, quantity: eligible, digest: digest),
            summary: "livestock breeding decision herd=\(herdID.rawValue) status=\(status.rawValue)"
        )
        state.breedingDecisions.append(AgentLivestockBreedingDecision(
            actionID: actionID, herdID: herdID, actorID: actorID,
            parentRecordIDs: parents.sorted(), compatibleFeedQuantity: compatibleFeed,
            reservedPlantingQuantity: reservedPlanting, eligibleFeedQuantity: eligible,
            status: status, decidedAtTick: tick, causalEventID: event.eventID
        ))
        finishLivestockAction(actionID, digest: digest, eventID: event.eventID, state: &state)
        evictLivestockHistory(&state)
        livestockState = state
    }

    private mutating func recordLivestockOutcome(_ outcome: AgentLivestockValidatedOutcome) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        try prepareLivestockAction(outcome.actionID, state: &state)
        guard outcome.completedAtTick == tick, outcome.actorID == state.activeTasks.first(where: { $0.taskID == outcome.taskID })?.responsibleAgentID,
              let taskIndex = state.activeTasks.firstIndex(where: { $0.taskID == outcome.taskID }),
              state.activeTasks[taskIndex].primaryAnimalRecordID == outcome.primaryAnimalRecordID,
              state.activeTasks[taskIndex].secondaryAnimalRecordID == outcome.secondaryAnimalRecordID else { throw AgentSessionError.livestock(.invalidOutcome("task attribution")) }
        try requireLivestockActor(outcome.actorID)
        guard activeCareEngagement(for: outcome.actorID) == nil else { throw AgentSessionError.livestock(.humanCarePriority(outcome.actorID)) }
        try validateLivestockOutcomeEvidence(outcome, task: state.activeTasks[taskIndex], state: state)
        let eventKind: AgentCausalEventKind
        switch outcome.kind {
        case .feed: eventKind = .animalFed
        case .breedingObserved: eventKind = .animalBreedingObserved
        case .collectProduct: eventKind = .animalProductAcquired
        case .herdMove, .slaughter: eventKind = .livestockTaskCompleted
        }
        let grantsPractice = outcome.status.successful && [.feed, .herdMove, .collectProduct].contains(outcome.kind)
        try prevalidateCausalAppend(count: grantsPractice && skillState != nil ? 2 : 1)
        let digest = AgentLivestockDigest.make("\(state.rollingDigest)|outcome|\(outcome.actionID.rawValue)|\(outcome.status.rawValue)|\(outcome.attribution)")
        let event = try requiredLivestockEvent(
            kind: eventKind, actorID: outcome.actorID,
            operationID: AgentOperationID(rawValue: outcome.actionID.rawValue),
            causes: [state.activeTasks[taskIndex].createdEventID],
            payload: livestockPayload(herdID: state.activeTasks[taskIndex].herdID,
                animalID: outcome.primaryAnimalRecordID, taskID: outcome.taskID,
                actionID: outcome.actionID, status: outcome.status.rawValue,
                quantity: outcome.kind == .feed ? outcome.consumedQuantity : outcome.acquiredQuantity,
                digest: digest),
            summary: "livestock physical outcome action=\(outcome.actionID.rawValue) status=\(outcome.status.rawValue)"
        )
        var practiceEventID: AgentCausalEventID?
        if grantsPractice {
            practiceEventID = try creditPracticeAfterMaterialSuccess(
                agentID: outcome.actorID, domain: .husbandry,
                sourceSuccessEventID: event.eventID
            )
        }
        if outcome.status.successful, outcome.kind == .herdMove, let position = outcome.finalPosition,
           let animalIndex = state.managedAnimals.firstIndex(where: { $0.recordID == outcome.primaryAnimalRecordID }),
           let herd = state.herds.first(where: { $0.herdID == state.managedAnimals[animalIndex].herdID }) {
            state.managedAnimals[animalIndex].lastKnownPosition = position
            state.managedAnimals[animalIndex].status = herd.managementArea.contains(position) ? .managed : .outsideManagementArea
            state.managedAnimals[animalIndex].lastResolvedAtTick = tick
        }
        if outcome.status.successful, outcome.kind == .breedingObserved, let child = outcome.offspring,
           let herdIndex = state.herds.firstIndex(where: { $0.herdID == state.activeTasks[taskIndex].herdID }) {
            state.managedAnimals.append(AgentManagedAnimalRecord(
                recordID: child.recordID, herdID: state.herds[herdIndex].herdID,
                speciesKey: child.speciesKey, sourceObservationEventID: event.eventID,
                joinedAtTick: tick, status: state.herds[herdIndex].managementArea.contains(child.position) ? .managed : .outsideManagementArea,
                lastKnownPosition: child.position, lastObservedLifeStage: child.lifeStage,
                breedingReady: false, productReady: false, lastResolvedAtTick: tick,
                lastReconciliationReason: "Core birth observed", admittedEventID: event.eventID
            ))
            state.managedAnimals.sort { $0.recordID < $1.recordID }
            state.herds[herdIndex].managedAnimalRecordIDs.append(child.recordID)
            state.herds[herdIndex].managedAnimalRecordIDs.sort()
            state.totalOffspringCount += 1
        }
        if outcome.status.successful, outcome.kind == .collectProduct {
            state.productRecords.append(AgentAnimalProductRecord(
                recordID: outcome.primaryAnimalRecordID, actionID: outcome.actionID,
                products: outcome.acquiredItems, acquiredAtTick: tick,
                causalEventID: event.eventID
            ))
        }
        state.retainedTaskRecords.append(AgentLivestockOutcomeRecord(
            outcome: outcome, livestockEventID: event.eventID,
            skillPracticeEventID: practiceEventID, digest: digest
        ))
        state.activeTasks.remove(at: taskIndex)
        state.reservations.removeAll { $0.taskID == outcome.taskID }
        finishLivestockAction(outcome.actionID, digest: digest, eventID: event.eventID, state: &state)
        evictLivestockHistory(&state)
        livestockState = state
    }

    private mutating func reconcileLivestock(_ resolutions: [AgentManagedAnimalResolution]) throws {
        guard var state = livestockState else { throw AgentSessionError.livestock(.disabled) }
        guard resolutions.count == state.managedAnimals.filter({ $0.status != .released }).count,
              Set(resolutions.map(\.recordID)).count == resolutions.count else { throw AgentSessionError.livestock(.invalidOutcome("complete unique reconciliation")) }
        let lossCount = resolutions.filter { [.missing, .dead].contains($0.kind) }.filter { resolution in
            !state.lossRecords.contains(where: { $0.recordID == resolution.recordID })
        }.count
        try prevalidateCausalAppend(count: lossCount)
        for resolution in resolutions.sorted(by: { $0.recordID < $1.recordID }) {
            guard resolution.observedAtTick == tick,
                  let index = state.managedAnimals.firstIndex(where: { $0.recordID == resolution.recordID }),
                  state.managedAnimals[index].speciesKey == resolution.speciesKey else { throw AgentSessionError.livestock(.invalidOutcome("resolution identity")) }
            switch resolution.kind {
            case .resolvedLiving:
                guard let position = resolution.position, let stage = resolution.lifeStage,
                      let herd = state.herds.first(where: { $0.herdID == state.managedAnimals[index].herdID }) else { throw AgentSessionError.livestock(.invalidOutcome("resolved physical state")) }
                state.managedAnimals[index].lastKnownPosition = position
                state.managedAnimals[index].lastObservedLifeStage = stage
                state.managedAnimals[index].breedingReady = resolution.breedingReady
                state.managedAnimals[index].productReady = resolution.productReady
                state.managedAnimals[index].status = herd.managementArea.contains(position) ? .managed : .outsideManagementArea
                state.managedAnimals[index].lastResolvedAtTick = tick
                state.managedAnimals[index].lastReconciliationReason = resolution.reason
            case .ambiguous:
                state.managedAnimals[index].status = .unresolved
                state.managedAnimals[index].lastReconciliationReason = resolution.reason
            case .missing, .dead:
                let kind: AgentLivestockLossKind = resolution.kind == .dead ? .dead : .missing
                state.managedAnimals[index].status = resolution.kind == .dead ? .dead : .missing
                state.managedAnimals[index].lastReconciliationReason = resolution.reason
                guard !state.lossRecords.contains(where: { $0.recordID == resolution.recordID }) else { continue }
                let digest = AgentLivestockDigest.make("\(state.rollingDigest)|loss|\(resolution.recordID.rawValue)|\(kind.rawValue)|\(tick)")
                let event = try requiredLivestockEvent(
                    kind: .managedAnimalLost,
                    causes: [state.managedAnimals[index].admittedEventID],
                    payload: livestockPayload(herdID: state.managedAnimals[index].herdID,
                        animalID: resolution.recordID, status: kind.rawValue, quantity: 1,
                        digest: digest),
                    summary: "managed animal lost record=\(resolution.recordID.rawValue) kind=\(kind.rawValue)"
                )
                state.lossRecords.append(AgentAnimalLossRecord(
                    recordID: resolution.recordID, herdID: state.managedAnimals[index].herdID,
                    kind: kind, reason: resolution.reason, recordedAtTick: tick,
                    causalEventID: event.eventID
                ))
                let blocked = state.activeTasks.filter {
                    $0.primaryAnimalRecordID == resolution.recordID || $0.secondaryAnimalRecordID == resolution.recordID
                }.map(\.taskID)
                state.activeTasks.removeAll { blocked.contains($0.taskID) }
                state.reservations.removeAll { blocked.contains($0.taskID) }
                state.lastLivestockEventID = event.eventID
                state.rollingDigest = digest
            }
        }
        evictLivestockHistory(&state)
        livestockState = state
    }

    private func requireLivestockActor(_ actorID: AgentID) throws {
        guard statesById[actorID.rawValue]?.health ?? 0 > 0 else { throw AgentSessionError.livestock(.unknownAgent(actorID)) }
        guard lifecycleState?.members.first(where: { $0.agentID == actorID })?.currentStage == .mature else { throw AgentSessionError.livestock(.incapableAgent(actorID)) }
    }

    private mutating func prepareLivestockAction(
        _ actionID: AgentLivestockActionID,
        state: inout AgentLivestockState
    ) throws {
        guard !state.processedActionIDs.contains(actionID) else { throw AgentSessionError.livestock(.duplicateAction(actionID)) }
        if state.transitionTick != tick { state.transitionTick = tick; state.actionsAtTick = 0 }
        guard state.actionsAtTick < state.configuration.maximumActionsPerTick else { throw AgentSessionError.livestock(.actionsPerTickReached) }
    }

    private func validateLivestockOutcomeEvidence(
        _ outcome: AgentLivestockValidatedOutcome,
        task: AgentLivestockTask,
        state: AgentLivestockState
    ) throws {
        let expected: AgentLivestockActionKind
        switch task.kind {
        case .feed: expected = .feed
        case .herdMove, .recoverMissing: expected = .herdMove
        case .breed: expected = .breedingObserved
        case .collectProduct: expected = .collectProduct
        case .slaughter: expected = .slaughter
        case .observe: throw AgentSessionError.livestock(.invalidOutcome("observation is reconciliation, not mutation"))
        }
        guard outcome.kind == expected, outcome.attribution.count > 0 && outcome.attribution.count <= 160,
              outcome.physicalCausalIDs.count <= state.configuration.maximumPhysicalCausalIDsPerOutcome,
              Set(outcome.physicalCausalIDs).count == outcome.physicalCausalIDs.count,
              outcome.physicalCausalIDs.allSatisfy({ $0 > 0 }),
              (outcome.consumedItems + outcome.acquiredItems).allSatisfy({ $0.count > 0 && !$0.identity.itemKey.isEmpty }) else { throw AgentSessionError.livestock(.invalidOutcome("physical evidence")) }
        guard outcome.status.successful else { return }
        switch outcome.kind {
        case .feed:
            guard outcome.consumedQuantity == 1, outcome.consumedItems.count == 1,
                  outcome.acquiredItems.isEmpty, outcome.offspring == nil else { throw AgentSessionError.livestock(.invalidOutcome("feed conservation")) }
        case .herdMove:
            guard outcome.finalPosition != nil, outcome.consumedItems.isEmpty,
                  outcome.acquiredItems.isEmpty, outcome.offspring == nil else { throw AgentSessionError.livestock(.invalidOutcome("herd evidence")) }
        case .breedingObserved:
            guard let child = outcome.offspring, child.lifeStage == .juvenile,
                  child.speciesKey == state.managedAnimals.first(where: { $0.recordID == task.primaryAnimalRecordID })?.speciesKey,
                  !state.managedAnimals.contains(where: { $0.recordID == child.recordID }),
                  outcome.consumedItems.isEmpty, outcome.acquiredItems.isEmpty else { throw AgentSessionError.livestock(.invalidOutcome("Core offspring observation")) }
            guard let herd = state.herds.first(where: { $0.herdID == task.herdID }), herd.managedAnimalRecordIDs.count < state.configuration.maximumManagedAnimalsPerHerd else { throw AgentSessionError.livestock(.capacityReached("offspring")) }
        case .collectProduct:
            guard outcome.acquiredQuantity > 0, outcome.consumedItems.isEmpty,
                  !(outcome.custodyFingerprint ?? "").isEmpty,
                  !outcome.physicalCausalIDs.isEmpty else { throw AgentSessionError.livestock(.invalidOutcome("product custody")) }
        case .slaughter:
            guard outcome.acquiredQuantity > 0, !outcome.physicalCausalIDs.isEmpty else { throw AgentSessionError.livestock(.invalidOutcome("slaughter conservation")) }
        }
    }

    private func activeLivestockReservations(_ state: AgentLivestockState) -> [AgentLivestockReservation] {
        state.reservations.filter { $0.expiresAtTick >= tick }.sorted { $0.reservationKey < $1.reservationKey }
    }

    private func livestockCapital(_ state: AgentLivestockState?) -> AgentLivestockCapitalSnapshot {
        let records = state?.managedAnimals ?? []
        let outcomes = state?.retainedTaskRecords ?? []
        return AgentLivestockCapitalSnapshot(
            historicalManagedRecordCount: records.count,
            resolvedLivingCount: records.filter(\.status.resolvedLiving).count,
            adultCount: records.filter { $0.status.resolvedLiving && $0.lastObservedLifeStage == .adult }.count,
            youngCount: records.filter { $0.status.resolvedLiving && $0.lastObservedLifeStage == .juvenile }.count,
            breedingReadyCount: records.filter { $0.status.resolvedLiving && $0.breedingReady }.count,
            productReadyCount: records.filter { $0.status.resolvedLiving && $0.productReady }.count,
            unresolvedCount: records.filter { $0.status == .unresolved }.count,
            missingCount: records.filter { $0.status == .missing }.count,
            deadCount: records.filter { $0.status == .dead }.count,
            releasedCount: records.filter { $0.status == .released }.count,
            recentBirths: outcomes.filter { $0.outcome.status.successful && $0.outcome.kind == .breedingObserved }.count,
            recentLosses: state?.lossRecords.count ?? 0,
            recentPhysicalOutputs: state?.productRecords.reduce(0) { $0 + $1.products.reduce(0) { $0 + $1.count } } ?? 0,
            feedInputsObserved: outcomes.reduce(0) { $0 + ($1.outcome.kind == .feed ? $1.outcome.consumedQuantity : 0) }
        )
    }

    private mutating func finishLivestockAction(
        _ actionID: AgentLivestockActionID,
        digest: String,
        eventID: AgentCausalEventID,
        state: inout AgentLivestockState
    ) {
        state.processedActionIDs.append(actionID)
        state.totalActionCount += 1
        state.actionsAtTick += 1
        state.lastLivestockEventID = eventID
        state.rollingDigest = digest
    }

    private func livestockDigest(_ state: AgentLivestockState) -> String {
        AgentLivestockDigest.make([
            state.rollingDigest, String(state.totalActionCount), String(state.totalOffspringCount),
            state.herds.map { "\($0.herdID.rawValue):\($0.managedAnimalRecordIDs.count)" }.joined(separator: ","),
            state.managedAnimals.map { "\($0.recordID.rawValue):\($0.status.rawValue)" }.joined(separator: ",")
        ].joined(separator: "|"))
    }

    private mutating func evictLivestockHistory(_ state: inout AgentLivestockState) {
        func trim<T>(_ values: inout [T], to maximum: Int, count: inout Int) {
            if values.count > maximum { let excess = values.count - maximum; values.removeFirst(excess); count += excess }
        }
        trim(&state.retainedTaskRecords, to: state.configuration.maximumRetainedTaskRecords, count: &state.evictionCounts.taskRecords)
        trim(&state.breedingDecisions, to: state.configuration.maximumRetainedBreedingDecisions, count: &state.evictionCounts.breedingDecisions)
        trim(&state.productRecords, to: state.configuration.maximumRetainedProductRecords, count: &state.evictionCounts.productRecords)
        trim(&state.lossRecords, to: state.configuration.maximumRetainedLossRecords, count: &state.evictionCounts.lossRecords)
        trim(&state.processedActionIDs, to: state.configuration.maximumProcessedActionIDs, count: &state.evictionCounts.processedActionIDs)
    }

    func validateLivestockStateIfEnabled() throws {
        guard let state = livestockState else { return }
        guard state.herds.count <= state.configuration.maximumHerds,
              state.activeTasks.count <= state.configuration.maximumActiveTasks,
              state.reservations.count <= state.configuration.maximumReservations,
              state.herds.map(\.herdID) == state.herds.map(\.herdID).sorted(),
              Set(state.herds.map(\.herdID)).count == state.herds.count,
              state.managedAnimals.map(\.recordID) == state.managedAnimals.map(\.recordID).sorted(),
              Set(state.managedAnimals.map(\.recordID)).count == state.managedAnimals.count,
              Set(state.activeTasks.map(\.taskID)).count == state.activeTasks.count,
              Set(state.reservations.map(\.reservationKey)).count == state.reservations.count,
              state.processedActionIDs.count == Set(state.processedActionIDs).count,
              state.totalActionCount >= state.processedActionIDs.count,
              state.totalOffspringCount >= 0,
              state.initializedEventID.simulationID == simulationID,
              state.lastLivestockEventID.simulationID == simulationID,
              state.lastLivestockEventID.sequence.rawValue <= causalLedger.latestSequence else { throw AgentSessionError.livestock(.invalidState("bounds, ordering, or causal identity")) }
        let animalIDs = Set(state.managedAnimals.map(\.recordID))
        let agentIDs = Set(statesById.values.map(\.agentID))
        for herd in state.herds {
            guard herd.managedAnimalRecordIDs.count <= state.configuration.maximumManagedAnimalsPerHerd,
                  Set(herd.managedAnimalRecordIDs).count == herd.managedAnimalRecordIDs.count,
                  herd.managedAnimalRecordIDs.allSatisfy(animalIDs.contains),
                  herd.responsibleAgentIDs.allSatisfy(agentIDs.contains),
                  state.managedAnimals.filter({ $0.herdID == herd.herdID }).map(\.recordID).sorted() == herd.managedAnimalRecordIDs else { throw AgentSessionError.livestock(.invalidState("herd membership")) }
        }
        guard state.activeTasks.allSatisfy({ task in
            animalIDs.contains(task.primaryAnimalRecordID) && agentIDs.contains(task.responsibleAgentID)
                && state.herds.contains(where: { $0.herdID == task.herdID })
                && task.createdAtTick <= tick && task.expiresAtTick >= task.createdAtTick
        }), state.reservations.allSatisfy({ reservation in
            state.activeTasks.contains(where: { $0.taskID == reservation.taskID })
                && agentIDs.contains(reservation.responsibleAgentID)
        }) else { throw AgentSessionError.livestock(.invalidState("tasks or reservations")) }
    }

    @discardableResult
    private mutating func requiredLivestockEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind, origin: .livestockTransition, actorID: actorID,
            operationID: operationID, causes: causes.sorted(), payload: payload,
            summary: summary
        ) else { throw AgentSessionError.livestock(.causalLedgerRequired) }
        return event
    }

    private func livestockPayload(
        herdID: AgentLivestockHerdID? = nil,
        animalID: AgentManagedAnimalRecordID? = nil,
        taskID: AgentLivestockTaskID? = nil,
        actionID: AgentLivestockActionID? = nil,
        status: String,
        quantity: Int = 0,
        digest: String
    ) -> AgentCausalPayload {
        .livestock(herdID: herdID?.rawValue, animalRecordID: animalID?.rawValue,
            taskID: taskID?.rawValue, actionID: actionID?.rawValue,
            status: status, quantity: quantity, digest: digest)
    }
}

private func validLivestockSpecies(_ key: String) -> Bool {
    (1...160).contains(key.count) && key.utf8.allSatisfy { (33...126).contains($0) }
}
