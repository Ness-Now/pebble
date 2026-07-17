extension AgentSimulationSession {
    public var localEcologyEnabled: Bool { localEcologyState != nil }

    public mutating func initializeLocalEcology(
        observations: [AgentEcologyHabitatObservation],
        configuration: AgentLocalEcologyConfiguration = .live
    ) throws {
        var candidate = self
        try candidate.initializeLocalEcologyInPlace(
            observations: observations,
            configuration: configuration
        )
        self = candidate
    }

    mutating func initializeLocalEcologyInPlace(
        observations: [AgentEcologyHabitatObservation],
        configuration: AgentLocalEcologyConfiguration
    ) throws {
        guard causalLedger.isEnabled else {
            throw AgentSessionError.localEcology(.causalLedgerRequired)
        }
        guard let registry = populationRegistry else {
            throw AgentSessionError.localEcology(.populationRequired)
        }
        guard registry.settlement.settlementID == .main else {
            throw AgentSessionError.localEcology(.settlementMismatch)
        }
        guard localEcologyState == nil else {
            throw AgentSessionError.localEcology(.alreadyEnabled)
        }
        guard !observations.isEmpty else {
            throw AgentSessionError.localEcology(.noValidHabitat)
        }
        guard observations.count <= configuration.maximumHabitatCandidates else {
            throw AgentSessionError.localEcology(.tooManyHabitatObservations(observations.count))
        }
        guard observations.reduce(0, { $0 + $1.worldReadCount })
                <= configuration.maximumHabitatReadsPerScan else {
            throw AgentSessionError.localEcology(.invalidHabitat("World read bound"))
        }
        var patchIDs = Set<AgentEcologyPatchID>()
        var habitats = Set<AgentPosition>()
        for observation in observations {
            guard observation.worldTick >= 0,
                  observation.settlementID == registry.settlement.settlementID,
                  observation.isUsable,
                  observation.habitatFingerprint >= 0,
                  observation.worldReadCount > 0,
                  (0..<configuration.maximumHabitatCandidates).contains(observation.candidateIndex),
                  observation.distanceFromSettlement >= 0,
                  observation.distanceFromSettlement
                    == manhattanDistance(registry.settlement.anchor, observation.foragePosition),
                  manhattanDistance(observation.habitatPosition, observation.foragePosition) == 1 else {
                throw AgentSessionError.localEcology(.invalidHabitat("observation contract"))
            }
            guard patchIDs.insert(observation.patchID).inserted,
                  habitats.insert(observation.habitatPosition).inserted else {
                throw AgentSessionError.localEcology(.duplicateHabitat)
            }
        }
        let selected = Array(observations.sorted(by: AgentEcologyHabitatObservation.sortsBefore)
            .prefix(configuration.maximumPatches))
        guard !selected.isEmpty else {
            throw AgentSessionError.localEcology(.noValidHabitat)
        }
        try prevalidateCausalAppend(count: selected.count + 1)
        guard let initialized = try recordCausalEvent(
            kind: .localEcologyInitialized,
            origin: .ecologyTransition,
            payload: .ecologyPatch(
                patchID: nil,
                settlementID: registry.settlement.settlementID.rawValue,
                position: registry.settlement.anchor,
                fingerprint: nil,
                yieldBefore: 0,
                yieldDelta: selected.count * configuration.initialYield,
                yieldAfter: selected.count * configuration.initialYield,
                capacity: selected.count * configuration.patchCapacity,
                status: "initialized",
                reason: "bounded read-only habitats accepted"
            ),
            summary: "local ecology initialized patches=\(selected.count)"
        ) else {
            throw AgentSessionError.localEcology(.causalLedgerRequired)
        }
        var patches: [AgentEcologyPatch] = []
        var latest = initialized.eventID
        for observation in selected {
            guard let event = try recordCausalEvent(
                kind: .ecologyPatchRegistered,
                origin: .ecologyTransition,
                causes: [initialized.eventID],
                payload: .ecologyPatch(
                    patchID: observation.patchID.rawValue,
                    settlementID: observation.settlementID.rawValue,
                    position: observation.habitatPosition,
                    fingerprint: observation.habitatFingerprint,
                    yieldBefore: 0,
                    yieldDelta: configuration.initialYield,
                    yieldAfter: configuration.initialYield,
                    capacity: configuration.patchCapacity,
                    status: configuration.initialYield > 0
                        ? AgentEcologyPatchStatus.available.rawValue
                        : AgentEcologyPatchStatus.depleted.rawValue,
                    reason: "verified World habitat registered"
                ),
                summary: "ecology patch registered id=\(observation.patchID.rawValue)"
            ) else {
                throw AgentSessionError.localEcology(.causalLedgerRequired)
            }
            latest = event.eventID
            patches.append(AgentEcologyPatch(
                patchID: observation.patchID,
                settlementID: observation.settlementID,
                habitatPosition: observation.habitatPosition,
                foragePosition: observation.foragePosition,
                habitatFingerprint: observation.habitatFingerprint,
                capacity: configuration.patchCapacity,
                currentYield: configuration.initialYield,
                initialYield: configuration.initialYield,
                regeneratedTotal: 0,
                harvestedTotal: 0,
                status: configuration.initialYield > 0 ? .available : .depleted,
                registeredTick: tick,
                lastRegenerationTick: tick,
                lastForageTick: nil,
                registrationEventID: event.eventID,
                lastEcologyEventID: event.eventID
            ))
        }
        localEcologyState = AgentLocalEcologyState(
            configuration: configuration,
            settlementID: registry.settlement.settlementID,
            patches: patches.sorted { $0.patchID < $1.patchID },
            processedForageIDs: [],
            forageHistory: [],
            pressureFrames: [],
            pressureSequence: 0,
            baselineRegenerated: 0,
            baselineConsumed: consumedResourceTotals.count(of: .foodRaw),
            baselineStarvationDamage: totalStarvationDamage(),
            evictionCounts: AgentEcologyEvictionCounts(),
            initializedEventID: initialized.eventID,
            lastEcologyEventID: latest
        )
        guard ecologyConservationSnapshot().balanced else {
            throw AgentSessionError.localEcology(.ecologyConservationFailed)
        }
    }

    public mutating func setLocalEcologyEnabled(_ enabled: Bool) throws {
        if enabled {
            guard localEcologyState != nil else {
                throw AgentSessionError.localEcology(.noValidHabitat)
            }
            return
        }
        guard let state = localEcologyState else { return }
        try prevalidateCausalAppend(count: 1)
        _ = try recordCausalEvent(
            kind: .localEcologyStateCleared,
            origin: .ecologyTransition,
            causes: [state.lastEcologyEventID],
            payload: .ecologyClear(
                forageHistory: state.forageHistory.count,
                pressureFrames: state.pressureFrames.count
            ),
            summary: "local ecology disabled"
        )
        reservationsByTarget = reservationsByTarget.filter { $0.value.source != .localEcology }
        for id in sortedIds {
            guard var agent = statesById[id], agent.activeResourceTarget?.source == .localEcology else {
                continue
            }
            agent.activeResourceTarget = nil
            agent.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetGone)
            statesById[id] = agent
        }
        localEcologyState = nil
    }

    public func localEcologyResourceObservations(
        for agentID: AgentID,
        habitatValidations: [AgentEcologyHabitatObservation]
    ) throws -> [AgentResourceObservation] {
        guard let ecology = localEcologyState else { return [] }
        guard let agent = statesById[agentID.rawValue] else {
            throw AgentSessionError.unknownAgentId(agentID.rawValue)
        }
        let validations = Dictionary(uniqueKeysWithValues: habitatValidations.map { ($0.patchID, $0) })
        var observations: [AgentResourceObservation] = []
        for patch in ecology.patches.sorted(by: { $0.patchID < $1.patchID }) {
            guard patch.status == .available, patch.currentYield > 0,
                  let validation = validations[patch.patchID], validation.isUsable,
                  validation.habitatPosition == patch.habitatPosition,
                  validation.foragePosition == patch.foragePosition,
                  validation.habitatFingerprint == patch.habitatFingerprint else { continue }
            let distance = manhattanDistance(agent.position, patch.foragePosition)
            guard (1...ecology.configuration.observationRadius).contains(distance),
                  let direction = AgentResourcePerception.direction(
                    observerPosition: agent.position,
                    target: patch.foragePosition
                  ) else { continue }
            observations.append(AgentResourceObservation(
                resource: .foodRaw,
                target: patch.foragePosition,
                direction: direction,
                distanceManhattan: distance,
                quantityAvailable: patch.currentYield,
                source: .localEcology,
                expectedBlockFingerprint: patch.habitatFingerprint,
                ecologyPatchID: patch.patchID,
                observationTick: tick
            ))
        }
        return try AgentResourcePerception.normalize(
            observerPosition: agent.position,
            observations: Array(observations.prefix(AgentResourcePerception.maximumObservationCount)),
            maximumDistance: ecology.configuration.observationRadius
        )
    }

    @discardableResult
    public mutating func applyForageIntents(
        _ intents: [AgentForageIntent],
        habitatValidations: [AgentEcologyHabitatObservation]
    ) throws -> [AgentForageOutcome] {
        var candidate = self
        let outcomes = try candidate.applyForageIntentsInPlace(
            intents,
            habitatValidations: habitatValidations
        )
        self = candidate
        return outcomes
    }

    mutating func applyForageIntentsInPlace(
        _ intents: [AgentForageIntent],
        habitatValidations: [AgentEcologyHabitatObservation]
    ) throws -> [AgentForageOutcome] {
        guard var ecology = localEcologyState else {
            throw AgentSessionError.localEcology(.disabled)
        }
        guard !intents.isEmpty,
              intents.count <= ecology.configuration.maximumForageIntentsPerTick else {
            throw AgentSessionError.localEcology(.invalidForage("batch"))
        }
        guard ecology.processedForageIDs.count + intents.count
                <= ecology.configuration.maximumForageHistory else {
            throw AgentSessionError.localEcology(.forageLimitReached)
        }
        var forageIDs = Set<String>()
        for intent in intents {
            guard intent.tick == tick,
                  AgentOperationID(rawValue: intent.forageID) != nil,
                  forageIDs.insert(intent.forageID).inserted,
                  !ecology.processedForageIDs.contains(intent.forageID),
                  statesById[intent.agentID.rawValue] != nil else {
                throw AgentSessionError.localEcology(.invalidForage(intent.forageID))
            }
        }
        try prevalidateCausalAppend(count: intents.count * 2)
        let validationByPatch = Dictionary(
            habitatValidations.map { ($0.patchID, $0) },
            uniquingKeysWith: { lhs, _ in lhs }
        )
        let sorted = intents.sorted {
            if $0.patchID != $1.patchID { return $0.patchID < $1.patchID }
            if $0.agentID != $1.agentID { return $0.agentID < $1.agentID }
            return $0.forageID < $1.forageID
        }
        var outcomes: [AgentForageOutcome] = []
        for intent in sorted {
            guard let patchIndex = ecology.patches.firstIndex(where: { $0.patchID == intent.patchID }),
                  var agent = statesById[intent.agentID.rawValue] else {
                throw AgentSessionError.localEcology(.unknownPatch(intent.patchID.rawValue))
            }
            var patch = ecology.patches[patchIndex]
            let validation = validationByPatch[patch.patchID]
            let inventoryBefore = agent.resourceInventory.count(of: .foodRaw)
            let status: AgentForageStatus
            let reason: String
            if agent.health <= 0 {
                status = .blocked
                reason = "agent health does not permit forage"
            } else if patch.status == .invalidated || validation?.isUsable != true
                || validation?.habitatFingerprint != patch.habitatFingerprint {
                status = .habitatInvalid
                reason = "habitat validation failed"
            } else if intent.target != patch.foragePosition
                || intent.expectedHabitatFingerprint != patch.habitatFingerprint
                || intent.observedAtTick < tick - 1 || intent.observedAtTick > tick {
                status = .staleObservation
                reason = "forage observation no longer matches patch"
            } else if !AgentInteractionSandbox.isCardinalAdjacent(
                target: patch.foragePosition,
                actor: agent.position
            ) {
                status = .notAdjacent
                reason = "agent is not cardinal-adjacent to forage position"
            } else if patch.currentYield <= 0 || patch.status == .depleted {
                status = .depleted
                reason = "patch yield depleted"
            } else if !agent.resourceInventory.canAdd(.foodRaw) {
                status = .inventoryFull
                reason = "agent inventory full"
            } else {
                status = .succeeded
                reason = "one bounded foodRaw yield foraged"
            }
            let yieldBefore = patch.currentYield
            if status == .succeeded {
                guard agent.resourceInventory.add(.foodRaw),
                      harvestedResourceTotals.add(.foodRaw) else {
                    throw AgentSessionError.localEcology(.invalidForage(intent.forageID))
                }
                patch.currentYield -= 1
                patch.harvestedTotal += 1
                patch.lastForageTick = tick
                patch.status = patch.currentYield == 0 ? .depleted : .available
                agent.activeResourceTarget = nil
                agent.navigationProgress = AgentNavigationProgress()
                statesById[agent.id] = agent
                reservationsByTarget = reservationsByTarget.filter {
                    $0.value.ecologyPatchID != patch.patchID
                }
            }
            let outcome = AgentForageOutcome(
                forageID: intent.forageID,
                patchID: patch.patchID,
                agentID: intent.agentID,
                tick: tick,
                status: status,
                yieldBefore: yieldBefore,
                yieldAfter: patch.currentYield,
                inventoryBefore: inventoryBefore,
                inventoryAfter: statesById[agent.id]?.resourceInventory.count(of: .foodRaw)
                    ?? inventoryBefore,
                reason: reason
            )
            guard let event = try recordCausalEvent(
                kind: .ecologyForageResolved,
                origin: .ecologyTransition,
                actorID: intent.agentID,
                operationID: AgentOperationID(rawValue: intent.forageID),
                causes: [patch.lastEcologyEventID],
                payload: .ecologyForage(
                    forageID: intent.forageID,
                    patchID: patch.patchID.rawValue,
                    agentID: intent.agentID.rawValue,
                    status: status.rawValue,
                    yieldBefore: yieldBefore,
                    yieldAfter: patch.currentYield,
                    inventoryBefore: inventoryBefore,
                    inventoryAfter: outcome.inventoryAfter
                ),
                summary: "forage \(status.rawValue) patch=\(patch.patchID.rawValue)"
            ) else {
                throw AgentSessionError.localEcology(.causalLedgerRequired)
            }
            patch.lastEcologyEventID = event.eventID
            if status == .succeeded, patch.status == .depleted,
               let depleted = try recordCausalEvent(
                kind: .ecologyPatchDepleted,
                origin: .ecologyTransition,
                actorID: intent.agentID,
                causes: [event.eventID],
                payload: .ecologyPatch(
                    patchID: patch.patchID.rawValue,
                    settlementID: patch.settlementID.rawValue,
                    position: patch.habitatPosition,
                    fingerprint: patch.habitatFingerprint,
                    yieldBefore: yieldBefore,
                    yieldDelta: -1,
                    yieldAfter: patch.currentYield,
                    capacity: patch.capacity,
                    status: patch.status.rawValue,
                    reason: "successful forage exhausted bounded yield"
                ),
                summary: "ecology patch depleted id=\(patch.patchID.rawValue)"
               ) {
                patch.lastEcologyEventID = depleted.eventID
            }
            ecology.patches[patchIndex] = patch
            ecology.lastEcologyEventID = patch.lastEcologyEventID
            ecology.processedForageIDs.append(intent.forageID)
            ecology.forageHistory.append(outcome)
            if ecology.forageHistory.count > ecology.configuration.maximumForageHistory {
                let removed = ecology.forageHistory.count - ecology.configuration.maximumForageHistory
                ecology.forageHistory.removeFirst(removed)
                ecology.evictionCounts.forageHistory += removed
            }
            outcomes.append(outcome)
        }
        ecology.patches.sort { $0.patchID < $1.patchID }
        localEcologyState = ecology
        guard ecologyConservationSnapshot().balanced, conservationSnapshot().balanced else {
            throw AgentSessionError.localEcology(.ecologyConservationFailed)
        }
        return outcomes
    }

    @discardableResult
    public mutating func applyLocalEcologyEndOfTick(
        habitatValidations: [AgentEcologyHabitatObservation]
    ) throws -> AgentSubsistencePressureFrame? {
        var candidate = self
        let frame = try candidate.applyLocalEcologyEndOfTickInPlace(
            habitatValidations: habitatValidations
        )
        self = candidate
        return frame
    }

    mutating func applyLocalEcologyEndOfTickInPlace(
        habitatValidations: [AgentEcologyHabitatObservation]
    ) throws -> AgentSubsistencePressureFrame? {
        guard var ecology = localEcologyState else { return nil }
        let validationByPatch = Dictionary(
            habitatValidations.map { ($0.patchID, $0) },
            uniquingKeysWith: { lhs, _ in lhs }
        )
        try prevalidateCausalAppend(count: ecology.patches.count + 1)
        for index in ecology.patches.indices {
            var patch = ecology.patches[index]
            let validation = validationByPatch[patch.patchID]
            let valid = validation?.isUsable == true
                && validation?.habitatPosition == patch.habitatPosition
                && validation?.foragePosition == patch.foragePosition
                && validation?.habitatFingerprint == patch.habitatFingerprint
            if !valid, patch.status != .invalidated {
                guard let event = try recordCausalEvent(
                    kind: .ecologyPatchInvalidated,
                    origin: .ecologyTransition,
                    causes: [patch.lastEcologyEventID],
                    payload: .ecologyPatch(
                        patchID: patch.patchID.rawValue,
                        settlementID: patch.settlementID.rawValue,
                        position: patch.habitatPosition,
                        fingerprint: patch.habitatFingerprint,
                        yieldBefore: patch.currentYield,
                        yieldDelta: 0,
                        yieldAfter: patch.currentYield,
                        capacity: patch.capacity,
                        status: AgentEcologyPatchStatus.invalidated.rawValue,
                        reason: "World habitat or forage binding changed"
                    ),
                    summary: "ecology patch invalidated id=\(patch.patchID.rawValue)"
                ) else { throw AgentSessionError.localEcology(.causalLedgerRequired) }
                patch.status = .invalidated
                patch.lastEcologyEventID = event.eventID
                reservationsByTarget = reservationsByTarget.filter {
                    $0.value.ecologyPatchID != patch.patchID
                }
                for id in sortedIds where statesById[id]?.activeResourceTarget?.ecologyPatchID == patch.patchID {
                    statesById[id]?.activeResourceTarget = nil
                    statesById[id]?.navigationProgress = AgentNavigationProgress(lastInvalidation: .targetGone)
                }
                ecology.lastEcologyEventID = event.eventID
            } else if valid, patch.status != .invalidated,
                      patch.currentYield < patch.capacity,
                      tick - patch.lastRegenerationTick
                        >= ecology.configuration.regenerationIntervalTicks {
                let before = patch.currentYield
                let quantity = min(
                    ecology.configuration.regenerationQuantity,
                    patch.capacity - patch.currentYield
                )
                patch.currentYield += quantity
                patch.regeneratedTotal += quantity
                patch.lastRegenerationTick = tick
                patch.status = .available
                guard let event = try recordCausalEvent(
                    kind: .ecologyPatchRegenerated,
                    origin: .ecologyTransition,
                    causes: [patch.lastEcologyEventID],
                    payload: .ecologyPatch(
                        patchID: patch.patchID.rawValue,
                        settlementID: patch.settlementID.rawValue,
                        position: patch.habitatPosition,
                        fingerprint: patch.habitatFingerprint,
                        yieldBefore: before,
                        yieldDelta: quantity,
                        yieldAfter: patch.currentYield,
                        capacity: patch.capacity,
                        status: patch.status.rawValue,
                        reason: "simulation tick regeneration interval elapsed"
                    ),
                    summary: "ecology patch regenerated id=\(patch.patchID.rawValue) quantity=\(quantity)"
                ) else { throw AgentSessionError.localEcology(.causalLedgerRequired) }
                patch.lastEcologyEventID = event.eventID
                ecology.lastEcologyEventID = event.eventID
            }
            ecology.patches[index] = patch
        }
        let regenerated = ecology.patches.reduce(0) { $0 + $1.regeneratedTotal }
        let consumed = consumedResourceTotals.count(of: .foodRaw)
        let starvation = totalStarvationDamage()
        let residentIDs = Set(populationRegistry?.settlement.residentIDs.map(\.rawValue) ?? sortedIds)
        let residents = sortedIds.compactMap { residentIDs.contains($0) ? statesById[$0] : nil }
        let survival = configuration.survivalConfiguration
        let input = AgentSubsistencePressureInput(
            population: residents.count,
            hungry: residents.filter { $0.needs.hunger >= survival.hungryThreshold }.count,
            critical: residents.filter { $0.needs.hunger >= survival.criticalHungerThreshold }.count,
            starvationDamageDelta: max(0, starvation - ecology.baselineStarvationDamage),
            availableYield: ecology.patches.filter { $0.status == .available }
                .reduce(0) { $0 + $1.currentYield },
            carriedFood: residents.reduce(0) { $0 + $1.resourceInventory.count(of: .foodRaw) },
            stockedFood: campStock.count(of: .foodRaw),
            regeneratedDelta: max(0, regenerated - ecology.baselineRegenerated),
            consumedDelta: max(0, consumed - ecology.baselineConsumed)
        )
        let previous = ecology.pressureFrames.last?.level
        let level = AgentSubsistencePressureClassifier.classify(input, previous: previous)
        guard ecology.pressureSequence < UInt64.max else {
            throw AgentSessionError.localEcology(.invalidPressureFrame)
        }
        ecology.pressureSequence += 1
        guard let pressureEvent = try recordCausalEvent(
            kind: .subsistencePressureChanged,
            origin: .ecologyTransition,
            causes: [ecology.lastEcologyEventID],
            payload: .subsistencePressure(
                previous: previous?.rawValue,
                current: level.rawValue,
                population: input.population,
                hungry: input.hungry,
                critical: input.critical,
                available: input.availableYield,
                carried: input.carriedFood,
                stocked: input.stockedFood,
                regenerated: input.regeneratedDelta,
                consumed: input.consumedDelta,
                starvationDamage: input.starvationDamageDelta
            ),
            summary: "subsistence pressure \(previous?.rawValue ?? "none")->\(level.rawValue)"
        ) else { throw AgentSessionError.localEcology(.causalLedgerRequired) }
        let frame = AgentSubsistencePressureFrame(
            sequence: ecology.pressureSequence,
            tick: tick,
            previousLevel: previous,
            level: level,
            input: input,
            causalEventID: pressureEvent.eventID
        )
        ecology.pressureFrames.append(frame)
        if ecology.pressureFrames.count > ecology.configuration.maximumPressureFrames {
            let removed = ecology.pressureFrames.count - ecology.configuration.maximumPressureFrames
            ecology.pressureFrames.removeFirst(removed)
            ecology.evictionCounts.pressureFrames += removed
        }
        ecology.baselineRegenerated = regenerated
        ecology.baselineConsumed = consumed
        ecology.baselineStarvationDamage = starvation
        ecology.lastEcologyEventID = pressureEvent.eventID
        localEcologyState = ecology
        guard ecologyConservationSnapshot().balanced else {
            throw AgentSessionError.localEcology(.ecologyConservationFailed)
        }
        return frame
    }

    public mutating func clearLocalEcologyDiagnostics() throws {
        guard var ecology = localEcologyState else {
            throw AgentSessionError.localEcology(.disabled)
        }
        try prevalidateCausalAppend(count: 1)
        let forageCount = ecology.forageHistory.count
        let pressureCount = max(0, ecology.pressureFrames.count - 1)
        ecology.forageHistory.removeAll()
        if let last = ecology.pressureFrames.last { ecology.pressureFrames = [last] }
        guard let event = try recordCausalEvent(
            kind: .localEcologyStateCleared,
            origin: .ecologyTransition,
            causes: [ecology.lastEcologyEventID],
            payload: .ecologyClear(forageHistory: forageCount, pressureFrames: pressureCount),
            summary: "local ecology diagnostics cleared"
        ) else { throw AgentSessionError.localEcology(.causalLedgerRequired) }
        ecology.lastEcologyEventID = event.eventID
        localEcologyState = ecology
    }

    public func ecologyConservationSnapshot() -> AgentEcologyConservationSnapshot {
        let patches = localEcologyState?.patches ?? []
        let initial = patches.reduce(0) { $0 + $1.initialYield }
        let regenerated = patches.reduce(0) { $0 + $1.regeneratedTotal }
        let current = patches.reduce(0) { $0 + $1.currentYield }
        let harvested = patches.reduce(0) { $0 + $1.harvestedTotal }
        return AgentEcologyConservationSnapshot(
            initialYieldTotal: initial,
            regeneratedTotal: regenerated,
            currentPatchYieldTotal: current,
            harvestedFromEcologyTotal: harvested,
            balanced: initial + regenerated == current + harvested
        )
    }

    public func localEcologySnapshot() -> AgentLocalEcologySnapshot {
        guard let ecology = localEcologyState else {
            return AgentLocalEcologySnapshot(
                enabled: false,
                settlementID: nil,
                configuration: nil,
                patches: [],
                forageHistory: [],
                pressureFrames: [],
                conservation: ecologyConservationSnapshot(),
                ecologyCausalEventCount: 0,
                evictionCounts: AgentEcologyEvictionCounts(),
                digest: AgentLocalEcologyDigest.make("disabled")
            )
        }
        let patches = ecology.patches.sorted { $0.patchID < $1.patchID }
        let forage = ecology.forageHistory.sorted {
            if $0.patchID != $1.patchID { return $0.patchID < $1.patchID }
            if $0.agentID != $1.agentID { return $0.agentID < $1.agentID }
            return $0.forageID < $1.forageID
        }
        let frames = ecology.pressureFrames.sorted { $0.sequence < $1.sequence }
        let conservation = ecologyConservationSnapshot()
        let eventCount = causalLedger.events.filter { $0.kind.isLocalEcology }.count
        let canonical = [
            "config=\(ecology.configuration.maximumPatches),\(ecology.configuration.maximumHabitatCandidates),\(ecology.configuration.observationRadius),\(ecology.configuration.patchCapacity),\(ecology.configuration.initialYield),\(ecology.configuration.regenerationIntervalTicks),\(ecology.configuration.regenerationQuantity),\(ecology.configuration.maximumForageIntentsPerTick),\(ecology.configuration.maximumForageHistory),\(ecology.configuration.maximumPressureFrames),\(ecology.configuration.maximumHabitatReadsPerScan)",
            patches.map { patch in
                "p|\(patch.patchID.rawValue)|\(positionText(patch.habitatPosition))|\(positionText(patch.foragePosition))|\(patch.habitatFingerprint)|\(patch.capacity)|\(patch.currentYield)|\(patch.initialYield)|\(patch.regeneratedTotal)|\(patch.harvestedTotal)|\(patch.status.rawValue)|\(patch.registeredTick)|\(patch.lastRegenerationTick)|\(patch.lastForageTick.map(String.init) ?? "none")|\(patch.registrationEventID.rawValue)|\(patch.lastEcologyEventID.rawValue)"
            }.joined(separator: ";"),
            "processed=\(ecology.processedForageIDs.sorted().joined(separator: ","))",
            forage.map { "f|\($0.forageID)|\($0.patchID.rawValue)|\($0.agentID.rawValue)|\($0.tick)|\($0.status.rawValue)|\($0.yieldBefore)|\($0.yieldAfter)|\($0.inventoryBefore)|\($0.inventoryAfter)" }.joined(separator: ";"),
            frames.map { "r|\($0.sequence)|\($0.tick)|\($0.previousLevel?.rawValue ?? "none")|\($0.level.rawValue)|\($0.input.population)|\($0.input.hungry)|\($0.input.critical)|\($0.input.starvationDamageDelta)|\($0.input.availableYield)|\($0.input.carriedFood)|\($0.input.stockedFood)|\($0.input.regeneratedDelta)|\($0.input.consumedDelta)|\($0.causalEventID.rawValue)" }.joined(separator: ";"),
            "baselines=\(ecology.baselineRegenerated),\(ecology.baselineConsumed),\(ecology.baselineStarvationDamage)",
            "evictions=\(ecology.evictionCounts.forageHistory),\(ecology.evictionCounts.pressureFrames)",
            "events=\(eventCount)|last=\(ecology.lastEcologyEventID.rawValue)",
        ].joined(separator: "|")
        return AgentLocalEcologySnapshot(
            enabled: true,
            settlementID: ecology.settlementID,
            configuration: ecology.configuration,
            patches: patches,
            forageHistory: forage,
            pressureFrames: frames,
            conservation: conservation,
            ecologyCausalEventCount: eventCount,
            evictionCounts: ecology.evictionCounts,
            digest: AgentLocalEcologyDigest.make(canonical)
        )
    }

    public func localEcologySummary() -> AgentLocalEcologySummary {
        let snapshot = localEcologySnapshot()
        let survival = configuration.survivalConfiguration
        let residents = populationRegistry?.settlement.residentIDs.compactMap {
            statesById[$0.rawValue]
        } ?? sortedIds.compactMap { statesById[$0] }
        return AgentLocalEcologySummary(
            enabled: snapshot.enabled,
            patchCount: snapshot.patches.count,
            availablePatchCount: snapshot.patches.filter { $0.status == .available }.count,
            depletedPatchCount: snapshot.patches.filter { $0.status == .depleted }.count,
            invalidatedPatchCount: snapshot.patches.filter { $0.status == .invalidated }.count,
            currentYield: snapshot.patches.filter { $0.status != .invalidated }
                .reduce(0) { $0 + $1.currentYield },
            capacity: snapshot.patches.reduce(0) { $0 + $1.capacity },
            regenerated: snapshot.patches.reduce(0) { $0 + $1.regeneratedTotal },
            harvested: snapshot.patches.reduce(0) { $0 + $1.harvestedTotal },
            pressure: snapshot.pressureFrames.last?.level,
            hungry: residents.filter { $0.needs.hunger >= survival.hungryThreshold }.count,
            critical: residents.filter { $0.needs.hunger >= survival.criticalHungerThreshold }.count,
            starvationDamage: residents.reduce(0) {
                $0 + ($1.survivalProgress?.starvationDamageTaken ?? 0)
            },
            ecologyEventCount: snapshot.ecologyCausalEventCount,
            conservationBalanced: snapshot.conservation.balanced,
            digest: snapshot.digest
        )
    }

    public func subsistencePressureSnapshot() -> [AgentSubsistencePressureFrame] {
        localEcologyState?.pressureFrames.sorted { $0.sequence < $1.sequence } ?? []
    }

    func totalStarvationDamage() -> Int {
        statesById.values.reduce(0) { partial, state in
            partial + (state.survivalProgress?.starvationDamageTaken ?? 0)
        }
    }
}

extension AgentCausalEventKind {
    var isLocalEcology: Bool {
        switch self {
        case .localEcologyInitialized, .ecologyPatchRegistered, .ecologyPatchRegenerated,
             .ecologyForageResolved, .ecologyPatchDepleted, .ecologyPatchInvalidated,
             .subsistencePressureChanged, .localEcologyStateCleared:
            return true
        default:
            return false
        }
    }
}
