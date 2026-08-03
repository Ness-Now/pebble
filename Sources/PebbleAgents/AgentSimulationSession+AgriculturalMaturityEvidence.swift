import Foundation

extension AgentSimulationSession {
    /// Selects the newest exact-cell observation only after proving the
    /// current planting boundary. Independent World-side receipts remain a
    /// Pebble adapter precondition and are not copied into this aggregate.
    public func currentCycleCropObservation(
        plot expectedPlot: AgentAgriculturalPlot,
        cell expectedCell: AgentAgriculturalCell,
        cropPosition: AgentPosition,
        minimumPhysicalWorldTick: Int
    ) throws -> AgentCurrentCycleCropObservationResult {
        guard minimumPhysicalWorldTick >= 0,
              let state = agricultureState,
              let plot = state.plots.first(where: {
                  $0.plotID == expectedPlot.plotID
              }),
              plot == expectedPlot,
              plot.cells.indices.contains(expectedCell.index),
              plot.cells[expectedCell.index] == expectedCell,
              expectedCell.phase == .planted,
              cropPosition == AgentPosition(
                  x: expectedCell.position.x,
                  y: expectedCell.position.y + 1,
                  z: expectedCell.position.z
              ) else {
            throw AgentSessionError.agriculture(
                .invalidAction("current-cycle crop identity")
            )
        }

        let causalEvents = Dictionary(
            uniqueKeysWithValues: causalLedger.events.map {
                ($0.eventID, $0)
            }
        )
        guard let plantingEventID = expectedCell.lastWorkEventID,
              let currentPlantAction = state.retainedActions.first(where: {
                  $0.agricultureEventID == plantingEventID
              }),
              currentPlantAction.outcome.kind == .plant,
              currentPlantAction.outcome.plotID == plot.plotID,
              currentPlantAction.outcome.cellIndex == expectedCell.index,
              currentPlantAction.outcome.position == expectedCell.position,
              currentPlantAction.outcome.materialDeltas
                == [AgentAgriculturalMaterialDelta(
                    itemKey: plot.crop.plantingItemKey,
                    quantity: 1,
                    direction: .consumed
                )],
              let plantingEvent = causalEvents[plantingEventID],
              plantingEvent.kind == .agriculturalCropPlanted,
              plantingEvent.origin == .agricultureTransition,
              plantingEvent.actorID == currentPlantAction.outcome.actorID,
              plantingEvent.operationID?.rawValue
                == currentPlantAction.outcome.actionID.rawValue,
              plantingEvent.simulationTick.rawValue
                == currentPlantAction.outcome.civilDate.simulationTick else {
            return AgentCurrentCycleCropObservationResult(
                classification: .invalidCurrentEvidence
            )
        }
        if plot.cycleOrdinal > 1 {
            guard let renewal = plot.renewalEvidence,
                  renewal.sourceCycleOrdinal == plot.cycleOrdinal - 1,
                  renewal.renewalEventID.sequence < plantingEvent.sequence else {
                return AgentCurrentCycleCropObservationResult(
                    classification: .invalidCurrentEvidence
                )
            }
        }

        struct Candidate {
            let actorID: AgentID
            let record: AgentEcologicalObservationRecord
            let crop: AgentCropObservation
        }
        var candidates: [Candidate] = []
        for actorID in snapshot().agents.compactMap({
            AgentID(rawValue: $0.id)
        }).sorted() {
            guard let record = ecologicalObservations(for: actorID).first(where: {
                $0.observation.crops.contains(where: {
                    $0.position == cropPosition
                })
            }) else {
                continue
            }
            let exactCellCrops = record.observation.crops.filter {
                $0.position == cropPosition
            }
            guard record.causalEventID.sequence > plantingEvent.sequence else {
                // This actor has no post-plant evidence for the current cycle.
                continue
            }
            guard exactCellCrops.count == 1,
                  let crop = exactCellCrops.first,
                  crop.cropKey == plot.crop.rawValue,
                  record.observation.physicalWorldTick
                    >= minimumPhysicalWorldTick,
                  let receiptID = record.physicalObservationReceiptID,
                  let event = causalEvents[record.causalEventID],
                  event.kind == .ecologicalObservationRecorded,
                  event.origin == .ecologicalObservationTransition,
                  event.actorID == actorID,
                  event.subjectID == actorID,
                  event.operationID?.rawValue == receiptID.rawValue,
                  event.simulationTick.rawValue
                    == record.observation.observedAtSimulationTick,
                  event.sequence == record.causalEventID.sequence,
                  case let .ecologicalObservation(
                      observerID, _, dimensionKey, physicalReceiptID,
                      _, _, _, status, digest
                  ) = event.payload,
                  observerID == actorID.rawValue,
                  dimensionKey == record.observation.dimensionKey,
                  physicalReceiptID == receiptID.rawValue,
                  status == "recorded",
                  digest == record.observation.digest else {
                return AgentCurrentCycleCropObservationResult(
                    classification: .invalidCurrentEvidence
                )
            }
            candidates.append(Candidate(
                actorID: actorID,
                record: record,
                crop: crop
            ))
        }
        guard !candidates.isEmpty else {
            return AgentCurrentCycleCropObservationResult(
                classification: .noEligibleObservation
            )
        }
        candidates.sort {
            if $0.record.observation.physicalWorldTick
                != $1.record.observation.physicalWorldTick {
                return $0.record.observation.physicalWorldTick
                    > $1.record.observation.physicalWorldTick
            }
            if $0.record.observation.observedAtSimulationTick
                != $1.record.observation.observedAtSimulationTick {
                return $0.record.observation.observedAtSimulationTick
                    > $1.record.observation.observedAtSimulationTick
            }
            if $0.record.causalEventID.sequence
                != $1.record.causalEventID.sequence {
                return $0.record.causalEventID.sequence
                    > $1.record.causalEventID.sequence
            }
            if $0.record.sequence != $1.record.sequence {
                return $0.record.sequence > $1.record.sequence
            }
            return $0.actorID < $1.actorID
        }
        let selected = candidates[0]
        let samePhysicalBoundary = candidates.filter {
            $0.record.observation.physicalWorldTick
                == selected.record.observation.physicalWorldTick
                && $0.record.observation.observedAtSimulationTick
                    == selected.record.observation.observedAtSimulationTick
        }
        guard samePhysicalBoundary.allSatisfy({ $0.crop == selected.crop }) else {
            return AgentCurrentCycleCropObservationResult(
                classification: .conflictingCurrentEvidence
            )
        }
        let evidence = AgentCurrentCycleCropObservationEvidence(
            record: selected.record,
            crop: selected.crop,
            currentPlantAction: currentPlantAction
        )
        return AgentCurrentCycleCropObservationResult(
            classification: selected.crop.mature
                ? .currentCycleMature : .currentCycleNonMature,
            evidence: evidence
        )
    }
}
