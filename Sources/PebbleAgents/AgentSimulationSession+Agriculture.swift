extension AgentSimulationSession {
    /// Reconciles durable agriculture action rows with receipts loaded from
    /// Pebble's independent World-side persistence.
    public func validateIndependentAgriculturalActionReceipts(
        _ evidence: [AgentAgriculturalPhysicalReceiptEvidence],
        worldID: String,
        storageIdentity: String,
        dimension: Int
    ) throws {
        let receiptIDs = evidence.map(\.receiptID)
        guard receiptIDs.count == Set(receiptIDs).count else {
            throw AgentSessionError.agriculture(
                .invalidState("duplicate independent agriculture receipt")
            )
        }
        let required = agricultureState?.retainedActions ?? []
        guard Set(receiptIDs) == Set(required.map(\.outcome.actionID)) else {
            throw AgentSessionError.agriculture(
                .invalidState("independent agriculture receipt set")
            )
        }
        let byID = Dictionary(uniqueKeysWithValues: evidence.map {
            ($0.receiptID, $0)
        })
        for record in required {
            guard let receipt = byID[record.outcome.actionID],
                  receipt.version
                    == AgentAgriculturalPhysicalReceiptEvidence.currentVersion,
                  receipt.hasValidDigest,
                  receipt.operationID == receipt.receiptID.rawValue,
                  receipt.worldID == worldID,
                  receipt.storageIdentity == storageIdentity,
                  receipt.dimension == dimension,
                  receipt.simulationID == simulationID,
                  receipt.outcome == record.outcome else {
                throw AgentSessionError.agriculture(
                    .invalidState(
                        "independent agriculture receipt mismatch "
                            + record.outcome.actionID.rawValue
                    )
                )
            }
        }
    }

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

    /// Derives the renewable-subsistence milestone from already authoritative
    /// agriculture and physical-food receipts. No milestone state is mutated.
    public func renewableSubsistenceEvidence() -> [AgentRenewableSubsistenceEvidence] {
        guard let agricultureState,
              let food = physicalFoodSurvivalState else { return [] }
        return agricultureState.plots.compactMap { plot in
            guard plot.cycleOrdinal == 2,
                  let renewal = plot.renewalEvidence else { return nil }
            let source = renewal.sourceHarvestActionIDs.compactMap { actionID in
                agricultureState.retainedActions.first {
                    $0.outcome.actionID == actionID
                }
            }.sorted { $0.outcome.actionID < $1.outcome.actionID }
            guard source.count == plot.cells.count,
                  let firstHarvestSequence = source.map({
                      $0.agricultureEventID.sequence.rawValue
                  }).max() else { return nil }
            let renewalSequence = renewal.renewalEventID.sequence.rawValue
            let firstPlants = renewal.sourcePlantActionIDs.compactMap { actionID in
                agricultureState.retainedActions.first {
                    $0.outcome.actionID == actionID
                }
            }.sorted { $0.outcome.actionID < $1.outcome.actionID }
            let consumptions = food.completedOutcomes.filter {
                $0.agentID == plot.plannerID
                    && $0.canonicalMaterialName == plot.crop.produceItemKey
                    && $0.consumptionSequence.rawValue > firstHarvestSequence
                    && $0.consumptionSequence.rawValue < renewalSequence
            }.sorted { $0.consumptionSequence < $1.consumptionSequence }
            let secondPlants = agricultureState.retainedActions.filter {
                $0.outcome.plotID == plot.plotID
                    && $0.outcome.kind == .plant
                    && $0.agricultureEventID.sequence.rawValue > renewalSequence
            }.sorted { $0.outcome.actionID < $1.outcome.actionID }
            let secondHarvests = agricultureState.retainedActions.filter {
                $0.outcome.plotID == plot.plotID
                    && $0.outcome.kind == .harvest
                    && $0.agricultureEventID.sequence.rawValue > renewalSequence
            }.sorted { $0.outcome.actionID < $1.outcome.actionID }
            let secondInput = secondPlants.reduce(0) { total, record in
                total + record.outcome.materialDeltas.filter {
                    $0.direction == .consumed
                        && $0.itemKey == plot.crop.plantingItemKey
                }.reduce(0) { $0 + $1.quantity }
            }
            let secondOutput = secondHarvests.reduce(0) { total, record in
                total + record.outcome.materialDeltas.filter {
                    $0.direction == .acquired
                        && $0.itemKey == plot.crop.produceItemKey
                }.reduce(0) { $0 + $1.quantity }
            }
            let consumption = consumptions.count == 1 ? consumptions[0] : nil
            let sourceFunded = renewal.sourceOutputQuantity
                >= renewal.reproductiveInputQuantity + (consumption?.quantityConsumed ?? 0)
            let secondEstablished = secondPlants.count == plot.cells.count
                && secondInput == renewal.reproductiveInputQuantity
            let secondCompleted = secondEstablished
                && secondHarvests.count == plot.cells.count && secondOutput > 0
            let status: AgentRenewableSubsistenceStatus
            let blockReason: String?
            if consumption == nil {
                status = .blocked
                blockReason = consumptions.isEmpty
                    ? "verified physical food consumption missing"
                    : "ambiguous physical food consumption"
            } else if !sourceFunded {
                status = .blocked
                blockReason = "first output cannot fund consumption and renewal"
            } else if !secondEstablished {
                status = .blocked
                blockReason = "second physical planting incomplete"
            } else if secondCompleted {
                status = .renewableCycleCompleted
                blockReason = nil
            } else {
                status = .secondCycleEstablished
                blockReason = nil
            }
            let firstPlantIDs = firstPlants.map(\.outcome.actionID)
            let secondPlantIDs = secondPlants.map(\.outcome.actionID)
            let secondHarvestIDs = secondHarvests.map(\.outcome.actionID)
            let digest = AgentAgricultureDigest.make(
                "\(plot.plotID.rawValue)|\(plot.crop.rawValue)|cycle=2|"
                    + firstPlantIDs.map(\.rawValue).joined(separator: ",") + "|"
                    + renewal.sourceHarvestActionIDs.map(\.rawValue).joined(separator: ",")
                    + "|first=\(renewal.sourceOutputQuantity)|"
                    + "consumption=\(consumption?.consumptionID ?? "none")|"
                    + "reserved=\(renewal.reproductiveInputQuantity)|"
                    + secondPlantIDs.map(\.rawValue).joined(separator: ",")
                    + "|secondInput=\(secondInput)|"
                    + secondHarvestIDs.map(\.rawValue).joined(separator: ",")
                    + "|secondOutput=\(secondOutput)|status=\(status.rawValue)"
            )
            return AgentRenewableSubsistenceEvidence(
                plotID: plot.plotID,
                crop: plot.crop,
                cycleOrdinal: plot.cycleOrdinal,
                firstPlantActionIDs: firstPlantIDs,
                firstHarvestActionIDs: renewal.sourceHarvestActionIDs,
                firstOutputQuantity: renewal.sourceOutputQuantity,
                consumptionID: consumption?.consumptionID,
                consumedQuantity: consumption?.quantityConsumed ?? 0,
                hungerBefore: consumption?.hungerBefore,
                hungerAfter: consumption?.hungerAfter,
                reservedOutputQuantity: renewal.reproductiveInputQuantity,
                secondPlantActionIDs: secondPlantIDs,
                secondInputQuantity: secondInput,
                secondHarvestActionIDs: secondHarvestIDs,
                secondOutputQuantity: secondOutput,
                status: status,
                blockReason: blockReason,
                digest: digest
            )
        }.sorted { $0.plotID < $1.plotID }
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
        try requireStageCapability(.harvest, for: plannerID)
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
            sourceObservationEventID: sourceObservationEventID,
            sourceObservationReceiptID:
                observationRecord.physicalObservationReceiptID,
            plannedCivilDate: date,
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
                && permitsStageCapability(.harvest, for: $0)
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
              statesById[actorID.rawValue]?.health ?? 0 > 0,
              permitsStageCapability(.harvest, for: actorID) else { return nil }
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
                        actorID: actorID, kind: kind, position: cell.position,
                        crop: plot.crop
                    )
                }
            }
            if plot.cells.allSatisfy({ $0.phase == .harvested }) {
                return AgentAgriculturalIntent(
                    plotID: plot.plotID, cellIndex: nil, actorID: actorID,
                    kind: .store, position: plot.cells[0].position,
                    crop: plot.crop
                )
            }
        }
        return nil
    }

    /// Reopens a completed plot only from a fresh local observation proving
    /// that every retained cell is still real, crop-supporting farmland.
    /// Physical seed/tool custody remains a Pebble-side precondition.
    @discardableResult
    public mutating func renewAgriculturalPlot(
        plotID: AgentAgriculturalPlotID,
        plannerID: AgentID,
        sourceObservationEventID: AgentCausalEventID
    ) throws -> AgentAgriculturalPlot {
        var candidate = self
        let plot = try candidate.renewAgriculturalPlotInPlace(
            plotID: plotID,
            plannerID: plannerID,
            sourceObservationEventID: sourceObservationEventID
        )
        try candidate.validateAgricultureStateIfEnabled()
        self = candidate
        return plot
    }

    private mutating func renewAgriculturalPlotInPlace(
        plotID: AgentAgriculturalPlotID,
        plannerID: AgentID,
        sourceObservationEventID: AgentCausalEventID
    ) throws -> AgentAgriculturalPlot {
        guard var state = agricultureState else {
            throw AgentSessionError.agriculture(.disabled)
        }
        try requireStageCapability(.harvest, for: plannerID)
        guard let plotIndex = state.plots.firstIndex(where: {
            $0.plotID == plotID
        }), state.plots[plotIndex].plannerID == plannerID,
              state.plots[plotIndex].phase == .cycleCompleted,
              state.plots[plotIndex].cells.allSatisfy({
                  $0.phase == .harvested
              }),
              let observationRecord = ecologicalObservations(
                  for: plannerID
              ).first(where: {
                  $0.causalEventID == sourceObservationEventID
                      && $0.observation.isFresh(atSimulationTick: tick)
              }) else {
            throw AgentSessionError.agriculture(
                .invalidAction("completed plot or fresh renewal observation")
            )
        }
        let soils = observationRecord.observation.soils
        guard state.plots[plotIndex].cells.allSatisfy({ cell in
            soils.contains {
                $0.position == cell.position
                    && $0.alreadyFarmland && $0.supportsCrop
            }
        }) else {
            throw AgentSessionError.agriculture(
                .invalidAction("renewal requires observed physical farmland")
            )
        }
        let sourceCycleOrdinal = state.plots[plotIndex].cycleOrdinal
        let sourceHarvestRecords = try state.plots[plotIndex].cells.map { cell in
            guard let eventID = cell.lastWorkEventID,
                  let record = state.retainedActions.first(where: {
                      $0.agricultureEventID == eventID
                  }),
                  record.outcome.plotID == plotID,
                  record.outcome.cellIndex == cell.index,
                  record.outcome.kind == .harvest else {
                throw AgentSessionError.agriculture(
                    .invalidAction("retained source harvest evidence")
                )
            }
            return record
        }.sorted { $0.outcome.actionID < $1.outcome.actionID }
        let sourceHarvestActionIDs = sourceHarvestRecords.map(\.outcome.actionID)
        guard sourceHarvestActionIDs.count == Set(sourceHarvestActionIDs).count else {
            throw AgentSessionError.agriculture(
                .invalidAction("unique source harvest evidence")
            )
        }
        let sourcePlantRecords = try sourceHarvestRecords.map { harvest in
            guard let cellIndex = harvest.outcome.cellIndex,
                  let record = state.retainedActions.last(where: {
                      $0.outcome.plotID == plotID
                          && $0.outcome.cellIndex == cellIndex
                          && $0.outcome.kind == .plant
                          && $0.agricultureEventID.sequence
                              < harvest.agricultureEventID.sequence
                  }) else {
                throw AgentSessionError.agriculture(
                    .invalidAction("retained source planting evidence")
                )
            }
            return record
        }.sorted { $0.outcome.actionID < $1.outcome.actionID }
        let sourcePlantActionIDs = sourcePlantRecords.map(\.outcome.actionID)
        guard sourcePlantActionIDs.count == Set(sourcePlantActionIDs).count else {
            throw AgentSessionError.agriculture(
                .invalidAction("unique source planting evidence")
            )
        }
        let sourceOutputQuantity = sourceHarvestRecords.reduce(0) { total, record in
            total + record.outcome.materialDeltas.filter {
                $0.direction == .acquired
                    && $0.itemKey == state.plots[plotIndex].crop.plantingItemKey
            }.reduce(0) { $0 + $1.quantity }
        }
        let reproductiveInputQuantity = state.plots[plotIndex].cells.count
        guard sourceOutputQuantity >= reproductiveInputQuantity else {
            throw AgentSessionError.agriculture(
                .invalidAction("source harvest cannot fund renewal")
            )
        }
        try prevalidateCausalAppend(count: 1)
        let digest = AgentAgricultureDigest.make(
            "\(state.rollingDigest)|renew|\(plotID.rawValue)|"
                + sourceObservationEventID.rawValue + "|cycle=\(sourceCycleOrdinal)|"
                + sourcePlantActionIDs.map(\.rawValue).joined(separator: ",") + "|"
                + sourceHarvestActionIDs.map(\.rawValue).joined(separator: ",")
                + "|output=\(sourceOutputQuantity)|input=\(reproductiveInputQuantity)"
        )
        let renewalCauses = Array(Set(
            [state.plots[plotIndex].lastAgricultureEventID, sourceObservationEventID]
                + sourceHarvestRecords.map(\.agricultureEventID)
        )).sorted().prefix(AgentCausalEvent.maximumCauseCount)
        let event = try requiredAgricultureEvent(
            kind: .agriculturalPlotPlanned,
            actorID: plannerID,
            causes: Array(renewalCauses),
            payload: agriculturePayload(
                plotID: plotID,
                status: "renewed",
                physicalFingerprint: 0,
                quantity: state.plots[plotIndex].cells.count,
                digest: digest
            ),
            summary: "agricultural plot renewed from observed farmland id="
                + plotID.rawValue
        )
        for index in state.plots[plotIndex].cells.indices {
            state.plots[plotIndex].cells[index].phase = .prepared
            state.plots[plotIndex].cells[index].lastWorkEventID = event.eventID
        }
        state.plots[plotIndex].phase = .planting
        state.plots[plotIndex].plantedCivilDate = nil
        state.plots[plotIndex].harvestedCivilDate = nil
        state.plots[plotIndex].lastAgricultureEventID = event.eventID
        state.plots[plotIndex].cycleOrdinal = sourceCycleOrdinal + 1
        state.plots[plotIndex].renewalEvidence = AgentAgriculturalRenewalEvidence(
            sourceCycleOrdinal: sourceCycleOrdinal,
            sourcePlantActionIDs: sourcePlantActionIDs,
            sourceHarvestActionIDs: sourceHarvestActionIDs,
            sourceOutputQuantity: sourceOutputQuantity,
            reproductiveInputQuantity: reproductiveInputQuantity,
            reservedAtTick: tick,
            sourceObservationReceiptID:
                observationRecord.physicalObservationReceiptID,
            renewalEventID: event.eventID
        )
        state.reservations.removeAll { $0.plotID == plotID }
        state.lastAgricultureEventID = event.eventID
        state.rollingDigest = digest
        agricultureState = state
        return state.plots[plotIndex]
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
        try requireStageCapability(.harvest, for: outcome.actorID)
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
            state, activeAgents: Array(statesById.values),
            population: populationRegistry, mortality: mortalityState,
            ecologicalObservations: ecologicalObservationState,
            clock: clock,
            causalLatestSequence: causalLedger.latestSequence,
            causalDroppedEventCount: causalLedger.droppedEventCount,
            causalEvents: causalLedger.events
        )
    }

    static func validateAgricultureState(
        _ state: AgentAgricultureState,
        activeAgents: [AgentSessionAgentState],
        population: AgentPopulationRegistry?,
        mortality: AgentMortalityState?,
        ecologicalObservations: AgentEcologicalObservationState?,
        clock: AgentSimulationClock,
        causalLatestSequence: UInt64,
        causalDroppedEventCount _: UInt64,
        causalEvents: [AgentCausalEvent]
    ) throws {
        let retained = Dictionary(
            uniqueKeysWithValues: causalEvents.map { ($0.eventID, $0) }
        )
        let retentionBoundary: AgentCausalEvent? = {
            guard let event = retained[state.initializedEventID],
                  event.kind == .agricultureInitialized,
                  event.origin == .agricultureTransition,
                  event.actorID == nil,
                  event.subjectID == nil,
                  event.operationID == nil,
                  event.causes.isEmpty,
                  case let .agriculture(
                      plotID, cellIndex, actionID, status,
                      physicalFingerprint, itemKey, quantity, digest
                  ) = event.payload,
                  plotID == nil,
                  cellIndex == nil,
                  actionID == nil,
                  physicalFingerprint == 0,
                  itemKey == nil,
                  quantity == state.plots.count,
                  status == "retentionBoundary",
                  digest == agricultureCausalRetentionDigest(
                      state,
                      population: population,
                      mortality: mortality
                  ) else {
                return nil
            }
            return event
        }()
        let agents = Set(activeAgents.map(\.agentID))
        let populationByAgent = Dictionary(
            uniqueKeysWithValues: (population?.members ?? []).map {
                ($0.agentID, $0)
            }
        )
        let deathByAgent = Dictionary(
            uniqueKeysWithValues: (mortality?.records ?? []).map {
                ($0.agentID, $0)
            }
        )
        let compactedDeathIDs = Set(
            (mortality?.compactedDeathSummaries ?? []).map(\.agentID)
        )
        func registrationEventIsValid(
            _ eventID: AgentCausalEventID,
            agentID: AgentID,
            noLaterThan tick: Int
        ) -> Bool {
            guard let event = retained[eventID],
                  event.simulationTick.rawValue <= tick else {
                return false
            }
            switch (event.kind, event.origin, event.payload) {
            case let (
                .populationMemberRegistered,
                .populationTransition,
                .population(_, memberID, _, _, _, _, _)
            ):
                return event.actorID == agentID
                    && event.subjectID == agentID
                    && memberID == agentID.rawValue
            case let (
                .populationMemberBorn,
                .lifecycleTransition,
                .birth(_, _, newbornID, _, _, _, _, _)
            ):
                return event.subjectID == agentID
                    && newbornID == agentID.rawValue
            default:
                return false
            }
        }
        func deathEventIsValid(_ death: AgentMortalityRecord) -> Bool {
            guard let event = retained[death.deathEventID],
                  event.kind == .agentDeathFinalized,
                  event.origin == .mortalityTransition,
                  event.actorID == death.agentID,
                  event.subjectID == death.agentID,
                  event.simulationTick.rawValue == death.deathTick,
                  case let .mortalityDeath(
                      deathID, agentID, _, tick, _, _, _, _, _, _, _, _, _, _
                  ) = event.payload else {
                return false
            }
            return deathID == death.deathID.rawValue
                && agentID == death.agentID.rawValue
                && tick == death.deathTick
        }
        func ecologicalObservationEventIsValid(
            _ eventID: AgentCausalEventID,
            observerID: AgentID?,
            physicalReceiptID: AgentPhysicalObservationReceiptID? = nil
        ) -> Bool {
            guard let event = retained[eventID],
                  event.kind == .ecologicalObservationRecorded,
                  event.origin == .ecologicalObservationTransition,
                  observerID.map({ event.actorID == $0 }) ?? true,
                  observerID.map({ event.subjectID == $0 }) ?? true,
                  case let .ecologicalObservation(
                      payloadObserverID, _, _, payloadReceiptID,
                      _, _, _, status, digest
                  ) = event.payload else {
                return false
            }
            return observerID.map({ payloadObserverID == $0.rawValue }) ?? true
                && event.operationID?.rawValue == payloadReceiptID
                && (physicalReceiptID.map {
                    $0.rawValue == payloadReceiptID
                } ?? true)
                && status == "recorded"
                && digest.count == 16
        }
        func agricultureEventIsValid(
            _ eventID: AgentCausalEventID,
            plotID: AgentAgriculturalPlotID? = nil,
            cellIndex: Int? = nil
        ) -> Bool {
            guard let event = retained[eventID],
                  event.origin == .agricultureTransition,
                  case let .agriculture(
                      payloadPlotID, payloadCellIndex, _, _, _, _, _, digest
                  ) = event.payload,
                  digest.count == 16 else {
                return false
            }
            if let plotID, payloadPlotID != plotID.rawValue { return false }
            if let cellIndex, payloadCellIndex != cellIndex { return false }
            return true
        }
        func agricultureWorkEventIsValid(
            _ eventID: AgentCausalEventID,
            plotID: AgentAgriculturalPlotID,
            cellIndex: Int
        ) -> Bool {
            guard let event = retained[eventID],
                  event.origin == .agricultureTransition,
                  case let .agriculture(
                      payloadPlotID, payloadCellIndex, _, status, _, _, _, digest
                  ) = event.payload,
                  payloadPlotID == plotID.rawValue,
                  digest.count == 16 else {
                return false
            }
            return payloadCellIndex == cellIndex
                || (event.kind == .agriculturalPlotPlanned
                    && payloadCellIndex == nil
                    && status == "renewed")
        }
        func historicallyValidActor(
            _ agentID: AgentID,
            at simulationTick: Int,
            referenceEventID: AgentCausalEventID,
            lastHistoricalEventID: AgentCausalEventID? = nil
        ) -> Bool {
            let coveredByBoundary = retentionBoundary.map {
                referenceEventID.sequence < $0.sequence
            } == true
            guard simulationTick >= 0,
                  simulationTick <= clock.tick.rawValue,
                  referenceEventID.simulationID == clock.simulationID,
                  retained[referenceEventID] != nil || coveredByBoundary else {
                return false
            }
            if agents.contains(agentID) {
                let registrationIsExact = populationByAgent[agentID].map {
                    registrationEventIsValid(
                        $0.registrationEventID,
                        agentID: agentID,
                        noLaterThan: simulationTick
                    )
                } == true
                let registrationIsBound = populationByAgent[agentID].map {
                    member in
                    retentionBoundary.map { boundary in
                        member.registrationEventID.sequence < boundary.sequence
                    } == true
                } == true
                guard let member = populationByAgent[agentID],
                      member.registeredTick <= simulationTick,
                      member.registrationEventID.sequence
                        < referenceEventID.sequence,
                      registrationIsExact || registrationIsBound,
                      deathByAgent[agentID] == nil,
                      !compactedDeathIDs.contains(agentID) else {
                    return false
                }
                return true
            }
            guard let death = deathByAgent[agentID],
                  death.registrationEventID.sequence
                    < referenceEventID.sequence,
                  (lastHistoricalEventID ?? referenceEventID).sequence
                    < death.deathEventID.sequence,
                  simulationTick <= death.deathTick,
                  registrationEventIsValid(
                      death.registrationEventID,
                      agentID: agentID,
                      noLaterThan: simulationTick
                  ) || retentionBoundary.map({
                      death.registrationEventID.sequence < $0.sequence
                  }) == true,
                  deathEventIsValid(death) else {
                return false
            }
            return true
        }
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
            guard historicallyValidActor(
                    plot.plannerID,
                    at: plot.plannedCivilDate.simulationTick,
                    referenceEventID: plot.sourceObservationEventID,
                    lastHistoricalEventID: plot.lastAgricultureEventID
                  ),
                  (state.configuration.minimumCellsPerPlot...state.configuration.maximumCellsPerPlot)
                    .contains(plot.cells.count),
                  plot.cells.map(\.index) == Array(plot.cells.indices),
                  Set(plot.cells.map(\.position)).count == plot.cells.count,
                  plot.sourceObservationEventID.simulationID == clock.simulationID,
                  plot.lastAgricultureEventID.simulationID == clock.simulationID,
                  ecologicalObservationEventIsValid(
                      plot.sourceObservationEventID,
                      observerID: plot.plannerID,
                      physicalReceiptID:
                        plot.sourceObservationReceiptID
                  ) || retentionBoundary.map({
                      plot.sourceObservationEventID.sequence < $0.sequence
                  }) == true,
                  (agricultureEventIsValid(
                      plot.lastAgricultureEventID,
                      plotID: plot.plotID
                  ) || retentionBoundary?.eventID
                      == plot.lastAgricultureEventID),
                  plot.cells.allSatisfy({ cell in
                      cell.lastWorkEventID.map {
                          agricultureWorkEventIsValid(
                              $0,
                              plotID: plot.plotID,
                              cellIndex: cell.index
                          ) || retentionBoundary?.eventID == $0
                      } ?? true
                  }),
                  plot.cycleOrdinal >= 1 else {
                throw AgentAgricultureError.invalidState("plot identity")
            }
            if plot.cycleOrdinal == 1 {
                guard plot.renewalEvidence == nil else {
                    throw AgentAgricultureError.invalidState("unexpected renewal evidence")
                }
            } else {
                guard let evidence = plot.renewalEvidence,
                      evidence.sourceCycleOrdinal == plot.cycleOrdinal - 1,
                      evidence.reproductiveInputQuantity == plot.cells.count,
                      evidence.sourceOutputQuantity >= evidence.reproductiveInputQuantity,
                      evidence.reservedAtTick >= 0,
                      evidence.reservedAtTick <= clock.tick.rawValue,
                      evidence.sourceObservationReceiptID != nil,
                      evidence.renewalEventID.simulationID == clock.simulationID,
                      evidence.sourcePlantActionIDs
                        == evidence.sourcePlantActionIDs.sorted(),
                      Set(evidence.sourcePlantActionIDs).count
                        == evidence.sourcePlantActionIDs.count,
                      evidence.sourcePlantActionIDs.count == plot.cells.count,
                      evidence.sourceHarvestActionIDs
                        == evidence.sourceHarvestActionIDs.sorted(),
                      Set(evidence.sourceHarvestActionIDs).count
                        == evidence.sourceHarvestActionIDs.count,
                      evidence.sourceHarvestActionIDs.count == plot.cells.count else {
                    throw AgentAgricultureError.invalidState("renewal evidence")
                }
                let sourceRecords = evidence.sourceHarvestActionIDs.compactMap { actionID in
                    state.retainedActions.first { $0.outcome.actionID == actionID }
                }
                let sourcePlants = evidence.sourcePlantActionIDs.compactMap { actionID in
                    state.retainedActions.first { $0.outcome.actionID == actionID }
                }
                guard sourceRecords.count == evidence.sourceHarvestActionIDs.count,
                      sourcePlants.count == evidence.sourcePlantActionIDs.count,
                      Set(sourceRecords.compactMap(\.outcome.cellIndex)).count
                        == plot.cells.count,
                      Set(sourcePlants.compactMap(\.outcome.cellIndex)).count
                        == plot.cells.count,
                      sourcePlants.allSatisfy({ record in
                          record.outcome.plotID == plot.plotID
                              && record.outcome.kind == .plant
                              && record.outcome.materialDeltas
                                  == [AgentAgriculturalMaterialDelta(
                                      itemKey: plot.crop.plantingItemKey,
                                      quantity: 1,
                                      direction: .consumed
                                  )]
                      }),
                      sourceRecords.allSatisfy({ record in
                          record.outcome.plotID == plot.plotID
                              && record.outcome.kind == .harvest
                              && record.outcome.cellIndex.map(plot.cells.indices.contains) == true
                      }),
                      sourceRecords.reduce(0, { total, record in
                          total + record.outcome.materialDeltas.filter {
                              $0.direction == .acquired
                                  && $0.itemKey == plot.crop.plantingItemKey
                          }.reduce(0) { $0 + $1.quantity }
                      }) == evidence.sourceOutputQuantity,
                      sourceRecords.allSatisfy({ harvest in
                          guard let cell = harvest.outcome.cellIndex,
                                let plant = sourcePlants.first(where: {
                                    $0.outcome.cellIndex == cell
                                }),
                                plant.agricultureEventID.sequence
                                    < harvest.agricultureEventID.sequence else {
                              return false
                          }
                          return !state.retainedActions.contains(where: {
                              $0.outcome.plotID == plot.plotID
                                  && $0.outcome.cellIndex == cell
                                  && $0.outcome.kind == .plant
                                  && $0.agricultureEventID.sequence
                                      > plant.agricultureEventID.sequence
                                  && $0.agricultureEventID.sequence
                                      < harvest.agricultureEventID.sequence
                          })
                      }) else {
                    throw AgentAgricultureError.invalidState("source harvest evidence")
                }
            }
            for cell in plot.cells where cell.phase == .planted {
                guard let workEventID = cell.lastWorkEventID,
                      let workEvent = retained[workEventID],
                      workEvent.kind == .agriculturalCropPlanted,
                      workEvent.origin == .agricultureTransition,
                      let plantRecord = state.retainedActions.first(where: {
                          $0.agricultureEventID == workEventID
                              && $0.outcome.kind == .plant
                              && $0.outcome.plotID == plot.plotID
                              && $0.outcome.cellIndex == cell.index
                              && $0.outcome.position == cell.position
                      }),
                      workEvent.operationID?.rawValue
                        == plantRecord.outcome.actionID.rawValue,
                      (plot.cycleOrdinal == 1
                          || plot.renewalEvidence.map {
                              $0.renewalEventID.sequence < workEvent.sequence
                          } == true) else {
                    throw AgentAgricultureError.invalidState(
                        "current-cycle planting boundary"
                    )
                }
            }
        }
        let reservationKeys = state.reservations.map {
            "\($0.plotID.rawValue):\($0.cellIndex)"
        }
        guard state.reservations == state.reservations.sorted(by: agricultureReservationSort),
              Set(reservationKeys).count == reservationKeys.count,
              state.reservations.allSatisfy({ reservation in
                  let historicalPlanner = state.plots.first(where: {
                      $0.plotID == reservation.plotID
                          && $0.plannerID == reservation.agentID
                  })
                  let actorIsValid = agents.contains(reservation.agentID)
                      || historicalPlanner.map {
                          historicallyValidActor(
                              reservation.agentID,
                              at: reservation.reservedAtTick,
                              referenceEventID: $0.sourceObservationEventID,
                              lastHistoricalEventID: $0.lastAgricultureEventID
                          )
                      } == true
                  return actorIsValid
                      && reservation.reservedAtTick <= clock.tick.rawValue
                      && reservation.expiresAtTick >= reservation.reservedAtTick
                      && state.plots.first(where: { $0.plotID == reservation.plotID })
                        .map { $0.cells.indices.contains(reservation.cellIndex) } == true
              }) else {
            throw AgentAgricultureError.invalidState("reservations")
        }
        guard state.initializedEventID.simulationID == clock.simulationID,
              state.lastAgricultureEventID.simulationID == clock.simulationID,
              state.lastAgricultureEventID.sequence.rawValue <= causalLatestSequence,
              (retentionBoundary != nil || (
                  retained[state.initializedEventID]?.kind == .agricultureInitialized
                      && retained[state.initializedEventID]?.origin
                          == .agricultureTransition
                      && agricultureEventIsValid(state.initializedEventID)
              )),
              (agricultureEventIsValid(state.lastAgricultureEventID)
                  || retentionBoundary?.eventID
                      == state.lastAgricultureEventID),
              state.retainedActions.allSatisfy({
                  agricultureEventIsValid(
                      $0.agricultureEventID,
                      plotID: $0.outcome.plotID,
                      cellIndex: $0.outcome.cellIndex
                  )
                      && ($0.skillPracticeEventID.map { retained[$0] != nil } ?? true)
              }),
              state.managedSurplusRecords.allSatisfy({
                  agricultureEventIsValid($0.agricultureEventID, plotID: $0.plotID)
              }) else {
            throw AgentAgricultureError.invalidState("causal references")
        }
        guard state.retainedActions.allSatisfy({ record in
            historicallyValidActor(
                record.outcome.actorID,
                at: record.outcome.civilDate.simulationTick,
                referenceEventID: record.agricultureEventID
            )
        }) else {
            throw AgentAgricultureError.invalidState("historical action actor")
        }
        for record in state.retainedActions {
            let outcome = record.outcome
            let expectedKind: AgentCausalEventKind
            switch outcome.kind {
            case .till: expectedKind = .agriculturalCellPrepared
            case .plant: expectedKind = .agriculturalCropPlanted
            case .maturityObserved: expectedKind = .agriculturalCropMatured
            case .harvest: expectedKind = .agriculturalCropHarvested
            case .store: expectedKind = .agriculturalSurplusStored
            case .reconcile: expectedKind = .agriculturalCellReconciled
            }
            guard let event = retained[record.agricultureEventID],
                  event.kind == expectedKind,
                  event.origin == .agricultureTransition,
                  event.actorID == outcome.actorID,
                  event.operationID?.rawValue == outcome.actionID.rawValue,
                  event.simulationTick.rawValue == outcome.civilDate.simulationTick,
                  case let .agriculture(
                      plotID, cellIndex, actionID, status,
                      physicalFingerprint, itemKey, quantity, digest
                  ) = event.payload,
                  plotID == outcome.plotID.rawValue,
                  cellIndex == outcome.cellIndex,
                  actionID == outcome.actionID.rawValue,
                  status == "succeeded",
                  physicalFingerprint == outcome.afterFingerprint,
                  itemKey == outcome.materialDeltas.first?.itemKey,
                  quantity == outcome.materialDeltas.reduce(0, { $0 + $1.quantity }),
                  digest == record.digest,
                  event.causes.allSatisfy({ retained[$0] != nil }) else {
                throw AgentAgricultureError.invalidState("action causal event")
            }
            if let skillEventID = record.skillPracticeEventID {
                guard let skillEvent = retained[skillEventID],
                      skillEvent.kind == .skillPracticeCredited,
                      skillEvent.origin == .skillTransition,
                      skillEvent.actorID == outcome.actorID,
                      skillEvent.causes.contains(record.agricultureEventID) else {
                    throw AgentAgricultureError.invalidState("skill causal event")
                }
            }
            if let sourceObservationEventID = outcome.sourceObservationEventID {
                guard ecologicalObservationEventIsValid(
                    sourceObservationEventID,
                    observerID: outcome.kind == .maturityObserved
                        ? nil : outcome.actorID
                ) else {
                    throw AgentAgricultureError.invalidState("action observation event")
                }
            }
            if outcome.kind == .maturityObserved,
               let cellIndex = outcome.cellIndex {
                let plot = state.plots.first {
                    $0.plotID == outcome.plotID
                }
                let currentPlant = state.retainedActions.last(where: {
                    $0.outcome.kind == .plant
                        && $0.outcome.plotID == outcome.plotID
                        && $0.outcome.cellIndex == cellIndex
                        && $0.agricultureEventID.sequence
                            < record.agricultureEventID.sequence
                })
                guard let plot,
                      plot.cells.indices.contains(cellIndex),
                      let currentPlant,
                      let sourceObservationEventID = outcome
                        .sourceObservationEventID,
                      currentPlant.agricultureEventID.sequence
                        < sourceObservationEventID.sequence,
                      plot.cycleOrdinal == 1
                        || plot.renewalEvidence.map({ renewal in
                            record.agricultureEventID.sequence
                              < renewal.renewalEventID.sequence
                                || renewal.renewalEventID.sequence
                                  < currentPlant.agricultureEventID.sequence
                        }) == true else {
                    throw AgentAgricultureError.invalidState(
                        "current-cycle maturity boundary"
                    )
                }
                if let observation = ecologicalObservations?.observations
                    .first(where: {
                        $0.causalEventID == sourceObservationEventID
                    }) {
                    let cell = plot.cells[cellIndex]
                    let cropPosition = AgentPosition(
                        x: cell.position.x,
                        y: cell.position.y + 1,
                        z: cell.position.z
                    )
                    let exactCrops = observation.observation.crops.filter {
                        $0.position == cropPosition
                    }
                    let foundationReceiptID: AgentPhysicalObservationReceiptID?
                    if let renewal = plot.renewalEvidence,
                       renewal.renewalEventID.sequence
                        < currentPlant.agricultureEventID.sequence {
                        foundationReceiptID = renewal.sourceObservationReceiptID
                    } else {
                        foundationReceiptID = plot.sourceObservationReceiptID
                    }
                    let minimumPhysicalTick = foundationReceiptID.flatMap {
                        receiptID in
                        ecologicalObservations?.observations.first(where: {
                            $0.physicalObservationReceiptID == receiptID
                        })?.observation.physicalWorldTick
                    }
                    let physicalTickIsCompatible = minimumPhysicalTick.map({
                        observation.observation.physicalWorldTick >= $0
                    }) ?? true
                    guard outcome.position == cell.position,
                          exactCrops.count == 1,
                          let crop = exactCrops.first,
                          crop.cropKey == plot.crop.rawValue,
                          crop.mature,
                          crop.growthStage == crop.maximumGrowthStage,
                          physicalTickIsCompatible else {
                        throw AgentAgricultureError.invalidState(
                            "maturity observation content"
                        )
                    }
                }
            }
        }
        for surplus in state.managedSurplusRecords {
            guard let event = retained[surplus.agricultureEventID],
                  event.kind == .agriculturalSurplusStored,
                  event.origin == .agricultureTransition,
                  event.simulationTick.rawValue == surplus.recordedTick,
                  case let .agriculture(
                      plotID, cellIndex, _, status, _, _, quantity, _
                  ) = event.payload,
                  plotID == surplus.plotID.rawValue,
                  cellIndex == nil,
                  status == "succeeded",
                  quantity >= max(
                      surplus.seedReserveQuantity,
                      surplus.physicalSurplusQuantity
                  ) else {
                throw AgentAgricultureError.invalidState("surplus causal event")
            }
        }
        for plot in state.plots where plot.cycleOrdinal > 1 {
            guard let evidence = plot.renewalEvidence,
                  retained[evidence.renewalEventID] != nil else {
                throw AgentAgricultureError.invalidState("renewal causal reference")
            }
            guard let event = retained[evidence.renewalEventID],
                  event.kind == .agriculturalPlotPlanned,
                  event.origin == .agricultureTransition,
                  event.actorID == plot.plannerID,
                  case let .agriculture(
                      plotID, cellIndex, actionID, status, _, _, quantity, _
                  ) = event.payload,
                  plotID == plot.plotID.rawValue,
                  cellIndex == nil,
                  actionID == nil,
                  status == "renewed",
                  quantity == plot.cells.count,
                  event.causes.allSatisfy({ retained[$0] != nil }) else {
                throw AgentAgricultureError.invalidState("renewal causal event")
            }
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
            let cell = plot.cells[outcome.cellIndex!]
            let observationRecord = ecologicalObservationState?.observations
                .first { $0.causalEventID == outcome.sourceObservationEventID }
            let cropPosition = AgentPosition(
                x: cell.position.x,
                y: cell.position.y + 1,
                z: cell.position.z
            )
            let exactCrops = observationRecord?.observation.crops.filter {
                $0.position == cropPosition
            } ?? []
            let foundationReceiptID = plot.cycleOrdinal > 1
                ? plot.renewalEvidence?.sourceObservationReceiptID
                : plot.sourceObservationReceiptID
            let minimumPhysicalTick = foundationReceiptID.flatMap { receiptID in
                ecologicalObservationState?.observations.first {
                    $0.physicalObservationReceiptID == receiptID
                }?.observation.physicalWorldTick
            }
            let physicalTickIsCompatible = observationRecord.map { record in
                minimumPhysicalTick.map {
                    record.observation.physicalWorldTick >= $0
                } ?? true
            } ?? false
            guard cell.phase == .planted,
                  outcome.beforeFingerprint == outcome.afterFingerprint,
                  outcome.materialDeltas.isEmpty, outcome.sourceObservationEventID != nil,
                  outcome.position == cell.position,
                  observationRecord != nil,
                  exactCrops.count == 1,
                  exactCrops[0].cropKey == plot.crop.rawValue,
                  exactCrops[0].mature,
                  exactCrops[0].growthStage == exactCrops[0].maximumGrowthStage,
                  physicalTickIsCompatible,
                  let plantingEventID = cell.lastWorkEventID,
                  let plantingRecord = state.retainedActions.first(where: {
                      $0.agricultureEventID == plantingEventID
                          && $0.outcome.kind == .plant
                          && $0.outcome.plotID == plot.plotID
                          && $0.outcome.cellIndex == outcome.cellIndex
                  }),
                  plantingRecord.outcome.position == cell.position,
                  let observationEvent = causalLedger.events.first(where: {
                      $0.eventID == outcome.sourceObservationEventID
                          && $0.kind == .ecologicalObservationRecorded
                  }),
                  observationEvent.sequence > plantingEventID.sequence,
                  (plot.cycleOrdinal == 1
                      || plot.renewalEvidence.map {
                          $0.sourceCycleOrdinal == plot.cycleOrdinal - 1
                              && $0.renewalEventID.sequence
                                < plantingEventID.sequence
                      } == true) else {
                throw AgentSessionError.agriculture(.invalidAction("maturity evidence"))
            }
            return (.agriculturalCropMatured, false)
        case .harvest:
            let produceQuantity = outcome.materialDeltas.filter {
                $0.direction == .acquired && $0.itemKey == plot.crop.produceItemKey
            }.reduce(0) { $0 + $1.quantity }
            let reproductiveQuantity = outcome.materialDeltas.filter {
                $0.direction == .acquired && $0.itemKey == plot.crop.plantingItemKey
            }.reduce(0) { $0 + $1.quantity }
            guard plot.cells[outcome.cellIndex!].phase == .mature,
                  outcome.beforeFingerprint != outcome.afterFingerprint,
                  !outcome.materialDeltas.isEmpty,
                  outcome.materialDeltas.allSatisfy({ $0.direction == .acquired }),
                  produceQuantity > 0, reproductiveQuantity > 0,
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
        let cycles = state.plots.map { plot in
            let renewal = plot.renewalEvidence.map {
                "\($0.sourceCycleOrdinal):"
                    + $0.sourcePlantActionIDs.map(\.rawValue).joined(separator: ",") + ":"
                    + $0.sourceHarvestActionIDs.map(\.rawValue).joined(separator: ",")
                    + ":\($0.sourceOutputQuantity):\($0.reproductiveInputQuantity):"
                    + "\($0.reservedAtTick):"
                    + "\($0.sourceObservationReceiptID?.rawValue ?? "none"):"
                    + $0.renewalEventID.rawValue
            } ?? "initial"
            return "\(plot.plotID.rawValue):\(plot.cycleOrdinal):\(renewal)"
        }.joined(separator: ";")
        return AgentAgricultureDigest.make(
            "\(state.rollingDigest)|plots=\(state.plots.count)|actions=\(state.totalActionCount)|"
                + "cycles=\(state.completedCycleCount)|last=\(state.lastAgricultureEventID.rawValue)|"
                + cycles
        )
    }

    private mutating func evictAgricultureHistoryIfNeeded(
        _ state: inout AgentAgricultureState
    ) {
        if state.retainedActions.count > state.configuration.maximumRetainedActions {
            let pinned = Set(state.plots.compactMap(\.renewalEvidence)
                .flatMap { $0.sourcePlantActionIDs + $0.sourceHarvestActionIDs })
            while state.retainedActions.count > state.configuration.maximumRetainedActions,
                  let index = state.retainedActions.firstIndex(where: {
                      !pinned.contains($0.outcome.actionID)
                  }) {
                state.retainedActions.remove(at: index)
                state.evictionCounts.actionRecords += 1
            }
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

/// Canonical, bounded projection of immutable plot foundations. The retained
/// causal boundary binds these fields after their original planning and
/// observation events leave the FIFO suffix. Mutable action, receipt, renewal,
/// and surplus history is intentionally excluded because those rows continue
/// to require their own exact retained events.
func agricultureCausalRetentionDigest(
    _ state: AgentAgricultureState,
    population: AgentPopulationRegistry?,
    mortality: AgentMortalityState?
) -> String {
    let configuration = state.configuration
    let configurationRow = [
        configuration.maximumPlots,
        configuration.maximumCellsPerPlot,
        configuration.minimumCellsPerPlot,
        configuration.maximumReservations,
        configuration.reservationLifetimeTicks,
        configuration.maximumRetainedActions,
        configuration.maximumRetainedSurplusRecords,
        configuration.maximumProcessedActionIDs,
    ].map(String.init).joined(separator: ",")
    let plots = state.plots.sorted { $0.plotID < $1.plotID }.map { plot in
        let date = plot.plannedCivilDate
        let registration = population?.members.first {
            $0.agentID == plot.plannerID
        }?.registrationEventID.rawValue ?? mortality?.records.first {
            $0.agentID == plot.plannerID
        }?.registrationEventID.rawValue ?? "missing-registration"
        let cells = plot.cells.map {
            "\($0.index):\($0.position.x),\($0.position.y),\($0.position.z)"
        }.joined(separator: ";")
        return [
            plot.plotID.rawValue,
            plot.plannerID.rawValue,
            registration,
            plot.crop.rawValue,
            plot.designatedStorageLocationID,
            plot.sourceObservationEventID.rawValue,
            plot.sourceObservationReceiptID?.rawValue ?? "none",
            "\(date.day):\(date.season.rawValue):\(date.year):\(date.dayOfYear):"
                + "\(date.absoluteDay):\(date.simulationTick)",
            cells,
        ].joined(separator: "|")
    }.joined(separator: "||")
    return AgentAgricultureDigest.make(
        "agricultureCausalRetentionV1|configuration=\(configurationRow)|plots=\(plots)"
    )
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
