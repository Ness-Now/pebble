extension AgentSimulationSession {
    public var agricultureEnabled: Bool { agricultureState != nil }

    public func agricultureSnapshot() -> AgentAgricultureSnapshot {
        guard let state = agricultureState else {
            return AgentAgricultureSnapshot(
                enabled: false, configuration: nil, plots: [], reservations: [],
                retainedActions: [], managedSurplusRecords: [], totalActionCount: 0,
                completedCycleCount: 0, evictionCounts: AgentAgricultureEvictionCounts(),
                digest: AgentAgricultureDigest.make("disabled")
            )
        }
        return AgentAgricultureSnapshot(
            enabled: true, configuration: state.configuration,
            plots: state.plots, reservations: activeAgriculturalReservations(state),
            retainedActions: state.retainedActions,
            managedSurplusRecords: state.managedSurplusRecords,
            totalActionCount: state.totalActionCount,
            completedCycleCount: state.completedCycleCount,
            evictionCounts: state.evictionCounts,
            digest: agricultureDigest(state)
        )
    }

    public mutating func setAgricultureEnabled(
        _ enabled: Bool,
        configuration: AgentAgricultureConfiguration = .live
    ) throws {
        if enabled {
            guard agricultureState == nil else {
                throw AgentSessionError.agriculture(.alreadyEnabled)
            }
            guard causalLedger.policy != .disabled else {
                throw AgentSessionError.agriculture(.causalLedgerRequired)
            }
            guard populationRegistry != nil else {
                throw AgentSessionError.agriculture(.populationRequired)
            }
            guard lifecycleState != nil else {
                throw AgentSessionError.agriculture(.lifecycleRequired)
            }
            guard skillState != nil else {
                throw AgentSessionError.agriculture(.skillsRequired)
            }
            guard ecologicalObservationState != nil else {
                throw AgentSessionError.agriculture(.ecologicalObservationRequired)
            }
            var candidate = self
            try candidate.prevalidateCausalAppend(count: 1)
            let digest = AgentAgricultureDigest.make("empty")
            let event = try candidate.requiredAgricultureEvent(
                kind: .agricultureInitialized,
                payload: candidate.agriculturePayload(status: "initialized", digest: digest),
                summary: "agriculture initialized without retroactive plots"
            )
            candidate.agricultureState = AgentAgricultureState(
                configuration: configuration, plots: [], reservations: [],
                retainedActions: [], managedSurplusRecords: [], processedActionIDs: [],
                totalActionCount: 0, completedCycleCount: 0,
                evictionCounts: AgentAgricultureEvictionCounts(), rollingDigest: digest,
                initializedEventID: event.eventID, lastAgricultureEventID: event.eventID
            )
            try candidate.validateAgricultureStateIfEnabled()
            self = candidate
        } else if agricultureState != nil {
            throw AgentSessionError.agriculture(.unsafeDisable)
        }
    }

    @discardableResult
    public mutating func planAgriculturalPlot(
        plannerID: AgentID,
        positions: [AgentPosition],
        crop: AgentAgriculturalCrop = .wheat,
        sourceObservationEventID: AgentCausalEventID,
        designatedStorageLocationID: String
    ) throws -> AgentAgriculturalPlotID {
        var candidate = self
        let id = try candidate.planAgriculturalPlotInPlace(
            plannerID: plannerID, positions: positions, crop: crop,
            sourceObservationEventID: sourceObservationEventID,
            designatedStorageLocationID: designatedStorageLocationID
        )
        try candidate.validateAgricultureStateIfEnabled()
        self = candidate
        return id
    }

    private mutating func planAgriculturalPlotInPlace(
        plannerID: AgentID,
        positions: [AgentPosition],
        crop: AgentAgriculturalCrop,
        sourceObservationEventID: AgentCausalEventID,
        designatedStorageLocationID: String
    ) throws -> AgentAgriculturalPlotID {
        guard var state = agricultureState else {
            throw AgentSessionError.agriculture(.disabled)
        }
        guard statesById[plannerID.rawValue]?.health ?? 0 > 0 else {
            throw AgentSessionError.agriculture(.unknownAgent(plannerID))
        }
        guard state.plots.count < state.configuration.maximumPlots else {
            throw AgentSessionError.agriculture(.plotCapacityReached)
        }
        guard (state.configuration.minimumCellsPerPlot...state.configuration.maximumCellsPerPlot)
                .contains(positions.count), Set(positions).count == positions.count else {
            throw AgentSessionError.agriculture(.invalidPlot("cell bounds or duplicates"))
        }
        guard (1...160).contains(designatedStorageLocationID.count),
              designatedStorageLocationID.utf8.allSatisfy({ (33...126).contains($0) }) else {
            throw AgentSessionError.agriculture(.invalidPlot("storage location"))
        }
        guard let observationRecord = ecologicalObservations(for: plannerID).first,
              observationRecord.causalEventID == sourceObservationEventID,
              observationRecord.observation.isFresh(atSimulationTick: tick) else {
            throw AgentSessionError.agriculture(.invalidPlot("fresh source observation"))
        }
        let soils = observationRecord.observation.soils
        guard positions.allSatisfy({ position in
            soils.contains { $0.position == position && ($0.tillable || $0.alreadyFarmland) }
        }) else {
            throw AgentSessionError.agriculture(.invalidPlot("unobserved or untillable cell"))
        }
        let water = observationRecord.observation.water
        guard positions.allSatisfy({ position in
            water.contains { source in
                abs(source.position.x - position.x) <= 4
                    && abs(source.position.z - position.z) <= 4
                    && (0...1).contains(source.position.y - position.y)
            }
        }), let date = civilDate() else {
            throw AgentSessionError.agriculture(.invalidPlot("water or calendar unavailable"))
        }
        let canonicalPositions = positions.sorted(by: agriculturePositionSort)
        let idDigest = AgentAgricultureDigest.make(
            "\(simulationID.rawValue)|\(plannerID.rawValue)|\(crop.rawValue)|"
                + canonicalPositions.map { "\($0.x),\($0.y),\($0.z)" }.joined(separator: ";")
                + "|\(sourceObservationEventID.rawValue)"
        )
        let plotID = AgentAgriculturalPlotID(rawValue: "plot-\(idDigest)")!
        guard !state.plots.contains(where: { $0.plotID == plotID }) else {
            throw AgentSessionError.agriculture(.invalidPlot("duplicate identity"))
        }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentAgricultureDigest.make("\(state.rollingDigest)|plan|\(plotID.rawValue)")
        let event = try requiredAgricultureEvent(
            kind: .agriculturalPlotPlanned, actorID: plannerID,
            causes: [sourceObservationEventID],
            payload: agriculturePayload(
                plotID: plotID, status: "planned", physicalFingerprint: 0,
                quantity: canonicalPositions.count, digest: digest
            ),
            summary: "agricultural plot planned id=\(plotID.rawValue) cells=\(canonicalPositions.count)"
        )
        let cells = canonicalPositions.enumerated().map {
            AgentAgriculturalCell(
                index: $0.offset, position: $0.element, phase: .planned,
                lastObservedFingerprint: 0,
                lastWorkEventID: nil
            )
        }
        state.plots.append(AgentAgriculturalPlot(
            plotID: plotID, plannerID: plannerID, crop: crop, cells: cells,
            designatedStorageLocationID: designatedStorageLocationID,
            sourceObservationEventID: sourceObservationEventID, plannedCivilDate: date,
            phase: .planned, plantedCivilDate: nil, harvestedCivilDate: nil,
            lastAgricultureEventID: event.eventID
        ))
        state.plots.sort { $0.plotID < $1.plotID }
        state.lastAgricultureEventID = event.eventID
        state.rollingDigest = digest
        agricultureState = state
        return plotID
    }

    @discardableResult
    public mutating func reserveAgriculturalCell(
        plotID: AgentAgriculturalPlotID,
        cellIndex: Int,
        contenders: [AgentID]
    ) throws -> AgentAgriculturalWorkReservation {
        guard var state = agricultureState else {
            throw AgentSessionError.agriculture(.disabled)
        }
        state.reservations.removeAll { $0.expiresAtTick < tick }
        guard let plot = state.plots.first(where: { $0.plotID == plotID }) else {
            throw AgentSessionError.agriculture(.unknownPlot(plotID))
        }
        guard plot.cells.indices.contains(cellIndex) else {
            throw AgentSessionError.agriculture(.invalidCell(cellIndex))
        }
        if let existing = state.reservations.first(where: {
            $0.plotID == plotID && $0.cellIndex == cellIndex
        }) {
            agricultureState = state
            return existing
        }
        let eligible = Array(Set(contenders)).sorted().filter {
            statesById[$0.rawValue]?.health ?? 0 > 0
        }
        guard let winner = eligible.first else {
            throw AgentSessionError.agriculture(.invalidReservation("no eligible contender"))
        }
        guard state.reservations.count < state.configuration.maximumReservations else {
            throw AgentSessionError.agriculture(.reservationCapacityReached)
        }
        let reservation = AgentAgriculturalWorkReservation(
            plotID: plotID, cellIndex: cellIndex, agentID: winner,
            reservedAtTick: tick,
            expiresAtTick: tick + state.configuration.reservationLifetimeTicks
        )
        state.reservations.append(reservation)
        state.reservations.sort(by: agricultureReservationSort)
        agricultureState = state
        return reservation
    }

    public func nextAgriculturalIntent(for actorID: AgentID) -> AgentAgriculturalIntent? {
        guard let state = agricultureState,
              statesById[actorID.rawValue]?.health ?? 0 > 0 else { return nil }
        for plot in state.plots where plot.phase != .cycleCompleted
            && plot.phase != .cancelled && plot.phase != .blocked {
            for cell in plot.cells {
                let reserved = activeAgriculturalReservations(state).first {
                    $0.plotID == plot.plotID && $0.cellIndex == cell.index
                }
                guard reserved == nil || reserved?.agentID == actorID else { continue }
                let kind: AgentAgriculturalActionKind?
                switch cell.phase {
                case .planned: kind = .till
                case .prepared: kind = .plant
                case .planted: kind = nil
                case .mature: kind = .harvest
                case .harvested, .blocked: kind = nil
                }
                if let kind {
                    return AgentAgriculturalIntent(
                        plotID: plot.plotID, cellIndex: cell.index,
                        actorID: actorID, kind: kind, position: cell.position
                    )
                }
            }
            if plot.cells.allSatisfy({ $0.phase == .harvested }) {
                return AgentAgriculturalIntent(
                    plotID: plot.plotID, cellIndex: nil, actorID: actorID,
                    kind: .store, position: plot.cells[0].position
                )
            }
        }
        return nil
    }

    @discardableResult
    public mutating func recordAgriculturalActionSuccess(
        _ outcome: AgentAgriculturalActionOutcome
    ) throws -> AgentAgriculturalActionRecord {
        var candidate = self
        let record = try candidate.recordAgriculturalActionSuccessInPlace(outcome)
        try candidate.validateAgricultureStateIfEnabled()
        try candidate.validateSkillStateIfEnabled()
        self = candidate
        return record
    }

    private mutating func recordAgriculturalActionSuccessInPlace(
        _ outcome: AgentAgriculturalActionOutcome
    ) throws -> AgentAgriculturalActionRecord {
        guard var state = agricultureState else {
            throw AgentSessionError.agriculture(.disabled)
        }
        guard !state.processedActionIDs.contains(outcome.actionID) else {
            throw AgentSessionError.agriculture(.duplicateAction(outcome.actionID))
        }
        guard statesById[outcome.actorID.rawValue]?.health ?? 0 > 0 else {
            throw AgentSessionError.agriculture(.unknownAgent(outcome.actorID))
        }
        guard let plotIndex = state.plots.firstIndex(where: { $0.plotID == outcome.plotID }) else {
            throw AgentSessionError.agriculture(.unknownPlot(outcome.plotID))
        }
        guard outcome.civilDate == civilDate(), state.totalActionCount < Int.max,
              state.processedActionIDs.count
                < state.configuration.maximumProcessedActionIDs else {
            throw AgentSessionError.agriculture(.invalidAction("calendar or counter"))
        }
        let actionKind = try validateAgriculturalOutcome(
            outcome, plot: state.plots[plotIndex], state: state
        )
        let causes = agriculturalCauses(outcome, plot: state.plots[plotIndex])
        try prevalidateCausalAppend(count: actionKind.grantsPractice ? 2 : 1)
        let nextDigest = AgentAgricultureDigest.make(
            "\(state.rollingDigest)|\(outcome.actionID.rawValue)|\(outcome.kind.rawValue)|"
                + "\(outcome.beforeFingerprint)>\(outcome.afterFingerprint)|"
                + outcome.materialDeltas.map {
                    "\($0.direction.rawValue):\($0.itemKey):\($0.quantity)"
                }.joined(separator: ",")
        )
        let event = try requiredAgricultureEvent(
            kind: actionKind.eventKind, actorID: outcome.actorID,
            operationID: AgentOperationID(rawValue: outcome.actionID.rawValue),
            causes: causes,
            payload: agriculturePayload(
                plotID: outcome.plotID, cellIndex: outcome.cellIndex,
                actionID: outcome.actionID, status: "succeeded",
                physicalFingerprint: outcome.afterFingerprint,
                itemKey: outcome.materialDeltas.first?.itemKey,
                quantity: outcome.materialDeltas.reduce(0) { $0 + $1.quantity },
                digest: nextDigest
            ),
            summary: "agricultural \(outcome.kind.rawValue) succeeded plot=\(outcome.plotID.rawValue)"
        )
        var skillEventID: AgentCausalEventID?
        if actionKind.grantsPractice {
            skillEventID = try creditPracticeAfterMaterialSuccess(
                agentID: outcome.actorID, domain: .cultivation,
                sourceSuccessEventID: event.eventID
            )
        }
        applyAgriculturalOutcome(
            outcome, eventID: event.eventID, plot: &state.plots[plotIndex]
        )
        let record = AgentAgriculturalActionRecord(
            outcome: outcome, agricultureEventID: event.eventID,
            skillPracticeEventID: skillEventID, digest: nextDigest
        )
        state.retainedActions.append(record)
        state.processedActionIDs.append(outcome.actionID)
        state.totalActionCount += 1
        state.lastAgricultureEventID = event.eventID
        state.rollingDigest = nextDigest
        if outcome.kind == .store {
            let plot = state.plots[plotIndex]
            state.managedSurplusRecords.append(AgentManagedSurplusRecord(
                plotID: plot.plotID,
                storageLocationID: outcome.storageLocationID!,
                cropItemKey: plot.crop.produceItemKey,
                plantingItemKey: plot.crop.plantingItemKey,
                seedReserveTarget: plot.cells.count,
                seedReserveQuantity: outcome.seedReserveQuantity,
                physicalSurplusQuantity: outcome.physicalSurplusQuantity,
                custodyFingerprint: outcome.custodyFingerprint!,
                recordedTick: tick, agricultureEventID: event.eventID
            ))
            state.completedCycleCount += 1
        }
        evictAgricultureHistoryIfNeeded(&state)
        agricultureState = state
        return record
    }

    func validateAgricultureStateIfEnabled() throws {
        guard let state = agricultureState else { return }
        try Self.validateAgricultureState(
            state, agents: Set(statesById.values.map(\.agentID)), clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    static func validateAgricultureState(
        _ state: AgentAgricultureState,
        agents: Set<AgentID>,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        _ = try AgentAgricultureConfiguration(
            maximumPlots: state.configuration.maximumPlots,
            maximumCellsPerPlot: state.configuration.maximumCellsPerPlot,
            minimumCellsPerPlot: state.configuration.minimumCellsPerPlot,
            maximumReservations: state.configuration.maximumReservations,
            reservationLifetimeTicks: state.configuration.reservationLifetimeTicks,
            maximumRetainedActions: state.configuration.maximumRetainedActions,
            maximumRetainedSurplusRecords: state.configuration.maximumRetainedSurplusRecords,
            maximumProcessedActionIDs: state.configuration.maximumProcessedActionIDs
        )
        guard state.plots.count <= state.configuration.maximumPlots,
              state.reservations.count <= state.configuration.maximumReservations,
              state.retainedActions.count <= state.configuration.maximumRetainedActions,
              state.managedSurplusRecords.count
                <= state.configuration.maximumRetainedSurplusRecords,
              state.processedActionIDs.count
                <= state.configuration.maximumProcessedActionIDs,
              state.totalActionCount >= state.retainedActions.count,
              state.completedCycleCount >= state.managedSurplusRecords.count,
              state.evictionCounts.actionRecords >= 0,
              state.evictionCounts.surplusRecords >= 0,
              state.processedActionIDs.count == Set(state.processedActionIDs).count,
              state.processedActionIDs.count == state.totalActionCount else {
            throw AgentAgricultureError.invalidState("bounds or totals")
        }
        let plotIDs = state.plots.map(\.plotID)
        guard plotIDs == plotIDs.sorted(), Set(plotIDs).count == plotIDs.count else {
            throw AgentAgricultureError.invalidState("plot ordering")
        }
        for plot in state.plots {
            guard agents.contains(plot.plannerID),
                  (state.configuration.minimumCellsPerPlot...state.configuration.maximumCellsPerPlot)
                    .contains(plot.cells.count),
                  plot.cells.map(\.index) == Array(plot.cells.indices),
                  Set(plot.cells.map(\.position)).count == plot.cells.count,
                  plot.sourceObservationEventID.simulationID == clock.simulationID,
                  plot.lastAgricultureEventID.simulationID == clock.simulationID else {
                throw AgentAgricultureError.invalidState("plot identity")
            }
        }
        let reservationKeys = state.reservations.map {
            "\($0.plotID.rawValue):\($0.cellIndex)"
        }
        guard state.reservations == state.reservations.sorted(by: agricultureReservationSort),
              Set(reservationKeys).count == reservationKeys.count,
              state.reservations.allSatisfy({ reservation in
                  agents.contains(reservation.agentID)
                      && reservation.reservedAtTick <= clock.tick.rawValue
                      && reservation.expiresAtTick >= reservation.reservedAtTick
                      && state.plots.first(where: { $0.plotID == reservation.plotID })
                        .map { $0.cells.indices.contains(reservation.cellIndex) } == true
              }) else {
            throw AgentAgricultureError.invalidState("reservations")
        }
        let retained = Dictionary(uniqueKeysWithValues: causalEvents.map { ($0.eventID, $0) })
        func eventExists(_ id: AgentCausalEventID) -> Bool {
            retained[id] != nil || id.sequence.rawValue <= causalDroppedEventCount
        }
        guard state.initializedEventID.simulationID == clock.simulationID,
              state.lastAgricultureEventID.simulationID == clock.simulationID,
              state.lastAgricultureEventID.sequence.rawValue <= causalLatestSequence,
              eventExists(state.initializedEventID), eventExists(state.lastAgricultureEventID),
              state.retainedActions.allSatisfy({
                  eventExists($0.agricultureEventID)
                      && ($0.skillPracticeEventID.map(eventExists) ?? true)
              }),
              state.managedSurplusRecords.allSatisfy({ eventExists($0.agricultureEventID) }) else {
            throw AgentAgricultureError.invalidState("causal references")
        }
    }

    private func validateAgriculturalOutcome(
        _ outcome: AgentAgriculturalActionOutcome,
        plot: AgentAgriculturalPlot,
        state: AgentAgricultureState
    ) throws -> (eventKind: AgentCausalEventKind, grantsPractice: Bool) {
        guard outcome.sourceItemEntityIDs.count == Set(outcome.sourceItemEntityIDs).count,
              outcome.sourceItemEntityIDs.allSatisfy({ $0 > 0 }),
              outcome.materialDeltas.allSatisfy({
                  !$0.itemKey.isEmpty && $0.itemKey.count <= 160 && $0.quantity > 0
              }) else {
            throw AgentSessionError.agriculture(.invalidAction("physical evidence"))
        }
        if outcome.kind != .store {
            guard let index = outcome.cellIndex, plot.cells.indices.contains(index),
                  plot.cells[index].position == outcome.position else {
                throw AgentSessionError.agriculture(.invalidAction("cell identity"))
            }
            if let reservation = activeAgriculturalReservations(state).first(where: {
                $0.plotID == plot.plotID && $0.cellIndex == index
            }), reservation.agentID != outcome.actorID {
                throw AgentSessionError.agriculture(.invalidAction("reservation owner"))
            }
        }
        switch outcome.kind {
        case .till:
            guard plot.cells[outcome.cellIndex!].phase == .planned,
                  outcome.beforeFingerprint != outcome.afterFingerprint,
                  outcome.materialDeltas.isEmpty, outcome.sourceItemEntityIDs.isEmpty else {
                throw AgentSessionError.agriculture(.invalidAction("till evidence"))
            }
            return (.agriculturalCellPrepared, true)
        case .plant:
            guard plot.cells[outcome.cellIndex!].phase == .prepared,
                  outcome.beforeFingerprint != outcome.afterFingerprint,
                  outcome.materialDeltas == [AgentAgriculturalMaterialDelta(
                    itemKey: plot.crop.plantingItemKey, quantity: 1, direction: .consumed
                  )], outcome.sourceItemEntityIDs.isEmpty,
                  outcome.custodyFingerprint != nil else {
                throw AgentSessionError.agriculture(.invalidAction("plant evidence"))
            }
            return (.agriculturalCropPlanted, true)
        case .maturityObserved:
            guard plot.cells[outcome.cellIndex!].phase == .planted,
                  outcome.beforeFingerprint == outcome.afterFingerprint,
                  outcome.materialDeltas.isEmpty, outcome.sourceObservationEventID != nil,
                  causalLedger.events.contains(where: {
                      $0.eventID == outcome.sourceObservationEventID
                          && $0.kind == .ecologicalObservationRecorded
                  }) else {
                throw AgentSessionError.agriculture(.invalidAction("maturity evidence"))
            }
            return (.agriculturalCropMatured, false)
        case .harvest:
            guard plot.cells[outcome.cellIndex!].phase == .mature,
                  outcome.beforeFingerprint != outcome.afterFingerprint,
                  !outcome.materialDeltas.isEmpty,
                  outcome.materialDeltas.allSatisfy({ $0.direction == .acquired }),
                  !outcome.sourceItemEntityIDs.isEmpty,
                  outcome.custodyFingerprint != nil else {
                throw AgentSessionError.agriculture(.invalidAction("harvest evidence"))
            }
            return (.agriculturalCropHarvested, true)
        case .store:
            guard outcome.cellIndex == nil,
                  plot.cells.allSatisfy({ $0.phase == .harvested }),
                  outcome.storageLocationID == plot.designatedStorageLocationID,
                  outcome.custodyFingerprint?.isEmpty == false,
                  outcome.seedReserveQuantity >= 0,
                  outcome.physicalSurplusQuantity >= 0,
                  outcome.materialDeltas.contains(where: {
                      $0.direction == .stored && $0.itemKey == plot.crop.produceItemKey
                          && $0.quantity >= outcome.physicalSurplusQuantity
                  }),
                  outcome.materialDeltas.filter({
                      $0.direction == .stored && $0.itemKey == plot.crop.plantingItemKey
                  }).reduce(0, { $0 + $1.quantity }) >= outcome.seedReserveQuantity else {
                throw AgentSessionError.agriculture(.invalidAction("storage evidence"))
            }
            return (.agriculturalSurplusStored, false)
        case .reconcile:
            guard plot.cells[outcome.cellIndex!].phase != .harvested,
                  outcome.materialDeltas.isEmpty else {
                throw AgentSessionError.agriculture(.invalidAction("reconciliation evidence"))
            }
            return (.agriculturalCellReconciled, false)
        }
    }

    private func agriculturalCauses(
        _ outcome: AgentAgriculturalActionOutcome,
        plot: AgentAgriculturalPlot
    ) -> [AgentCausalEventID] {
        var causes = [plot.lastAgricultureEventID]
        if let observation = outcome.sourceObservationEventID,
           observation != plot.lastAgricultureEventID {
            causes.append(observation)
        }
        return Array(Set(causes)).sorted()
    }

    private func applyAgriculturalOutcome(
        _ outcome: AgentAgriculturalActionOutcome,
        eventID: AgentCausalEventID,
        plot: inout AgentAgriculturalPlot
    ) {
        if let index = outcome.cellIndex {
            plot.cells[index].lastObservedFingerprint = outcome.afterFingerprint
            plot.cells[index].lastWorkEventID = eventID
            switch outcome.kind {
            case .till: plot.cells[index].phase = .prepared
            case .plant:
                plot.cells[index].phase = .planted
                if plot.plantedCivilDate == nil { plot.plantedCivilDate = outcome.civilDate }
            case .maturityObserved: plot.cells[index].phase = .mature
            case .harvest:
                plot.cells[index].phase = .harvested
                plot.harvestedCivilDate = outcome.civilDate
            case .reconcile: plot.cells[index].phase = .blocked
            case .store: break
            }
        }
        plot.lastAgricultureEventID = eventID
        if outcome.kind == .store {
            plot.phase = .cycleCompleted
        } else if plot.cells.contains(where: { $0.phase == .blocked }) {
            plot.phase = .blocked
        } else if plot.cells.allSatisfy({ $0.phase == .harvested }) {
            plot.phase = .storing
        } else if plot.cells.contains(where: { $0.phase == .mature }) {
            plot.phase = .harvestReady
        } else if plot.cells.allSatisfy({ $0.phase == .planted }) {
            plot.phase = .growing
        } else if plot.cells.contains(where: { $0.phase == .prepared }) {
            plot.phase = .planting
        } else {
            plot.phase = .preparing
        }
    }

    private func activeAgriculturalReservations(
        _ state: AgentAgricultureState
    ) -> [AgentAgriculturalWorkReservation] {
        state.reservations.filter { $0.expiresAtTick >= tick }
            .sorted(by: agricultureReservationSort)
    }

    private func agricultureDigest(_ state: AgentAgricultureState) -> String {
        AgentAgricultureDigest.make(
            "\(state.rollingDigest)|plots=\(state.plots.count)|actions=\(state.totalActionCount)|"
                + "cycles=\(state.completedCycleCount)|last=\(state.lastAgricultureEventID.rawValue)"
        )
    }

    private mutating func evictAgricultureHistoryIfNeeded(
        _ state: inout AgentAgricultureState
    ) {
        if state.retainedActions.count > state.configuration.maximumRetainedActions {
            let excess = state.retainedActions.count - state.configuration.maximumRetainedActions
            state.retainedActions.removeFirst(excess)
            state.evictionCounts.actionRecords += excess
        }
        if state.managedSurplusRecords.count
            > state.configuration.maximumRetainedSurplusRecords {
            let excess = state.managedSurplusRecords.count
                - state.configuration.maximumRetainedSurplusRecords
            state.managedSurplusRecords.removeFirst(excess)
            state.evictionCounts.surplusRecords += excess
        }
    }

    private mutating func requiredAgricultureEvent(
        kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        operationID: AgentOperationID? = nil,
        causes: [AgentCausalEventID] = [],
        payload: AgentCausalPayload,
        summary: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind, origin: .agricultureTransition, actorID: actorID,
            operationID: operationID, causes: causes,
            payload: payload, summary: summary
        ) else { throw AgentSessionError.agriculture(.causalLedgerRequired) }
        return event
    }

    private func agriculturePayload(
        plotID: AgentAgriculturalPlotID? = nil,
        cellIndex: Int? = nil,
        actionID: AgentAgriculturalActionID? = nil,
        status: String,
        physicalFingerprint: Int = 0,
        itemKey: String? = nil,
        quantity: Int = 0,
        digest: String
    ) -> AgentCausalPayload {
        .agriculture(
            plotID: plotID?.rawValue, cellIndex: cellIndex,
            actionID: actionID?.rawValue, status: status,
            physicalFingerprint: physicalFingerprint,
            itemKey: itemKey, quantity: quantity, digest: digest
        )
    }
}

private func agriculturePositionSort(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Bool {
    if lhs.x != rhs.x { return lhs.x < rhs.x }
    if lhs.y != rhs.y { return lhs.y < rhs.y }
    return lhs.z < rhs.z
}

private func agricultureReservationSort(
    _ lhs: AgentAgriculturalWorkReservation,
    _ rhs: AgentAgriculturalWorkReservation
) -> Bool {
    if lhs.plotID != rhs.plotID { return lhs.plotID < rhs.plotID }
    if lhs.cellIndex != rhs.cellIndex { return lhs.cellIndex < rhs.cellIndex }
    return lhs.agentID < rhs.agentID
}
