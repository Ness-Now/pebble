import PebbleAgents
import PebbleCore

private enum PebbleRenewableSubsistenceProofError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case let .failed(reason): return reason
        }
    }
}

extension PebbleAgentController {
    func handleRenewableSubsistence(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab renewable-subsistence <setup|plant-first|harvest-first|consume-replant|status|verify-maturity-mismatch|mature-second|harvest-second>"
            + " (Evaluation 11 gated: reserve-to-agent1|return-agent1-reserve|transfer-to-g1|final-reserve-to-g1|feed-g0)"
        guard arguments.count == 1, let command = arguments.first?.lowercased(),
              let publishedSession = session, activeWorld === world else {
            return failure(usage)
        }
        let gates = agricultureGateDependencies() + [
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = gates.filter { !$0.1 }.map { $0.0 }
        guard missing.isEmpty else {
            return failure(
                "Renewable subsistence proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard publishedSession.agricultureEnabled,
              publishedSession.physicalFoodSurvivalEnabled,
              publishedSession.lifecycleEnabled, publishedSession.skillsEnabled,
              publishedSession.ecologicalObservationEnabled, isPaused, !movementEnabled,
              replayRecorder == nil else {
            return failure(
                "Renewable subsistence requires paused agriculture, physical food, lifecycle, skills, and ecological observation."
            )
        }
        if command == "status" {
            traceRenewableSubsistenceStatus(
                world: world, session: publishedSession
            )
            return success("Renewable subsistence status traced.")
        }
        guard candidatePhysicalHardFailure == nil else {
            return failure(
                "Renewable subsistence refused after candidate physical hard failure."
            )
        }
        guard activeCandidatePhysicalTransaction == nil else {
            return failure("Renewable subsistence nested candidate refused.")
        }
        if command == "mature-second" {
            do {
                try matureSecondRenewableCrop(
                    world: world, session: publishedSession
                )
                return success("Renewable subsistence mature-second passed.")
            } catch {
                return failure(
                    "Renewable subsistence mature-second failed: \(error)"
                )
            }
        }

        var externalGrowthStartTick = world.time
        var externalGrowthTicks = 0
        if command == "harvest-first" || command == "harvest-second" {
            do {
                let (_, _, _, cell) = try renewableContext(
                    world: world, session: publishedSession
                )
                externalGrowthStartTick = world.time
                let cropCell = world.getBlock(
                    cell.position.x, cell.position.y + 1, cell.position.z
                )
                if cell.phase == .planted,
                   cropCell != Int(PebbleCore.cell(B.carrots, 7)) {
                    externalGrowthTicks = try advanceRenewableCropByWorldTicks(
                        world: world, position: cell.position
                    )
                }
            } catch {
                return failure(
                    "Renewable subsistence \(command) external World progression failed: \(error)"
                )
            }
        }

        let transaction = PebbleCandidatePhysicalTransaction(
            transactionID: "renewable:\(publishedSession.simulationID.rawValue):"
                + "\(command):world:\(world.time)",
            operation: "renewable-subsistence \(command)",
            physicalWorldTick: world.time,
            injectedCompensationFailurePrefix: environment[
                "PEBBLELAB_DISPOSABLE_CANDIDATE_COMPENSATION_FAULT"
            ] == "movement-collision" ? "agriculture-navigation" : nil
        )
        activeCandidatePhysicalTransaction = transaction
        physicalActionGateway.candidatePhysicalTransaction = transaction
        materialCustodyGateway.candidatePhysicalTransaction = transaction
        defer {
            if physicalActionGateway.candidatePhysicalTransaction === transaction {
                physicalActionGateway.candidatePhysicalTransaction = nil
            }
            if materialCustodyGateway.candidatePhysicalTransaction === transaction {
                materialCustodyGateway.candidatePhysicalTransaction = nil
            }
            if activeCandidatePhysicalTransaction === transaction {
                activeCandidatePhysicalTransaction = nil
            }
        }
        var candidate = publishedSession
        let publishedRecorder = replayRecorder
        var candidateRecorder = replayRecorder
        var receiptTransaction =
            PebbleWorldEcologicalObservationReceiptTransaction()
        activeCandidateReceiptTransaction = receiptTransaction
        defer {
            if activeCandidateReceiptTransaction === receiptTransaction {
                activeCandidateReceiptTransaction = nil
            }
        }
        do {
            switch command {
            case "setup":
                try setupRenewableSubsistence(
                    world: world, session: &candidate,
                    recorder: &candidateRecorder,
                    receiptTransaction: &receiptTransaction
                )
            case "plant-first":
                try plantFirstRenewableCycle(world: world, session: &candidate)
            case "harvest-first":
                try harvestRenewableCycle(
                    ordinal: 1, world: world, session: &candidate,
                    recorder: &candidateRecorder,
                    receiptTransaction: &receiptTransaction,
                    growthStartTick: externalGrowthStartTick,
                    growthTicks: externalGrowthTicks
                )
            case "consume-replant":
                try consumeAndReplantRenewableOutput(
                    world: world, session: &candidate,
                    recorder: &candidateRecorder,
                    receiptTransaction: &receiptTransaction
                )
            case "verify-maturity-mismatch":
                try verifyRenewableMaturityMismatch(
                    world: world, session: &candidate
                )
            case "harvest-second":
                try harvestRenewableCycle(
                    ordinal: 2, world: world, session: &candidate,
                    recorder: &candidateRecorder,
                    receiptTransaction: &receiptTransaction,
                    growthStartTick: externalGrowthStartTick,
                    growthTicks: externalGrowthTicks
                )
            case "evaluation11-reserve-to-agent1":
                try transferEvaluation11RenewableReserve(
                    quantity: 1, targetID: AgentID(rawValue: "agent_1")!,
                    role: "independent-G0-reserve", world: world,
                    session: candidate
                )
            case "evaluation11-return-agent1-reserve":
                try returnEvaluation11RenewableReserve(
                    sourceID: AgentID(rawValue: "agent_1")!,
                    world: world, session: candidate
                )
            case "evaluation11-transfer-to-g1":
                try transferEvaluation11RenewableReserve(
                    quantity: 2, targetID: AgentID(rawValue: "agent_3")!,
                    role: "mature-G1-care-reserve", world: world,
                    session: candidate, requireMatureG1: true
                )
            case "evaluation11-final-reserve-to-g1":
                try transferEvaluation11RenewableReserve(
                    quantity: 1, targetID: AgentID(rawValue: "agent_3")!,
                    role: "post-succession-obligation-reserve", world: world,
                    session: candidate, requireMatureG1: true
                )
            case "evaluation11-feed-g0":
                try feedEvaluation11G0FromRenewableOutput(
                    world: world, session: &candidate,
                    recorder: &candidateRecorder
                )
            default:
                return failure(usage)
            }
            if candidate.ecologicalObservationEnabled {
                try validateWorldEcologicalObservationReceipts(
                    for: candidate, dimension: world.dim.rawValue
                )
            }
            if environment[
                "PEBBLELAB_DISPOSABLE_CANDIDATE_PHYSICAL_FAULT"
            ] == "renewable-after-final-validation",
               !candidateRenewableLateFailureProofInjected,
               command.hasPrefix("harvest-") {
                candidateRenewableLateFailureProofInjected = true
                trace(
                    "candidate physical fault seam operation=renewable-subsistence "
                        + "command=\(command) point=after-final-validation "
                        + "mutations=\(transaction.registeredCompensationIDs.joined(separator: ",")) "
                        + "growthStartTick=\(externalGrowthStartTick) "
                        + "growthTicks=\(externalGrowthTicks) physicalWorldTick=\(world.time) "
                        + "publishedSessionTick=\(publishedSession.tick)"
                )
                throw PebbleRenewableSubsistenceProofError.failed(
                    "injected renewable failure after final validation"
                )
            }
            receiptTransaction.commit()
            session = candidate
            replayRecorder = candidateRecorder
            transaction.commit()
            return success("Renewable subsistence \(command) passed.")
        } catch {
            let receiptIDs = receiptTransaction.stagedReceiptIDs.sorted()
            let registeredCompensations = transaction.registeredCompensationIDs
            var receiptFailure: String?
            do {
                try rollbackWorldEcologicalObservationReceipts(
                    receiptTransaction
                )
            } catch {
                receiptFailure = String(describing: error)
            }
            let rollback = transaction.rollback()
            activeCandidatePhysicalTransaction = nil
            replayRecorder = publishedRecorder
            if receiptFailure != nil || rollback.failure != nil {
                let hardFailure = makeCandidatePhysicalHardFailure(
                    transaction: transaction,
                    rollback: rollback,
                    receiptFailure: receiptFailure,
                    receiptIDs: receiptIDs,
                    session: publishedSession,
                    world: world
                )
                candidatePhysicalHardFailure = hardFailure
                isPaused = true
                lastError = "candidate physical hard failure: \(hardFailure)"
                runtimeErrorCount += 1
                trace("CANDIDATE_PHYSICAL_HARD_FAILURE \(hardFailure)")
            } else {
                let cropState: String
                if let (_, _, _, cell) = try? renewableContext(
                    world: world, session: publishedSession
                ) {
                    cropState = String(
                        world.getBlock(
                            cell.position.x, cell.position.y + 1,
                            cell.position.z
                        )
                    )
                } else {
                    cropState = "unavailable"
                }
                trace(
                    "CANDIDATE_PHYSICAL_ROLLBACK operation=renewable-subsistence "
                        + "command=\(command) transaction=\(transaction.transactionID) "
                        + "error=\(error) registered=\(registeredCompensations.joined(separator: ",")) "
                        + "completed=\(rollback.completed.joined(separator: ",")) "
                        + "receipts=\(receiptIDs.joined(separator: ",")) receiptsRetained=0 "
                        + "publishedSession=unchanged publishedSessionTick=\(self.session?.tick ?? -1) "
                        + "publishedRecorder=unchanged growthStartTick=\(externalGrowthStartTick) "
                        + "growthTicks=\(externalGrowthTicks) physicalWorldTick=\(world.time) "
                        + "cropCell=\(cropState)"
                )
            }
            return failure("Renewable subsistence \(command) failed: \(error)")
        }
    }

    private func setupRenewableSubsistence(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        let actorID = try renewableActorID()
        guard session.agricultureSnapshot().plots.isEmpty,
              session.physicalFoodSurvivalSnapshot()?.completedOutcomes.isEmpty == true,
              let probe = probesByAgentId[actorID.rawValue], probe.world === world,
              !probe.dead, probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "setup requires fresh agriculture, food history, and empty actor custody"
            )
        }
        let origin = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        let soil = AgentPosition(x: origin.x, y: origin.y - 1, z: origin.z - 3)
        let water = PhysicalBlockPosition(x: soil.x, y: soil.y, z: soil.z - 3)
        let work = agricultureWorkPosition(for: soil)
        let containerPosition = PhysicalBlockPosition(
            x: work.x - 1, y: work.y, z: work.z
        )
        var fixturePositions = [
            PhysicalBlockPosition(x: soil.x, y: soil.y, z: soil.z),
            PhysicalBlockPosition(x: soil.x, y: soil.y + 1, z: soil.z),
            PhysicalBlockPosition(x: work.x, y: work.y - 1, z: work.z),
            PhysicalBlockPosition(x: work.x, y: work.y, z: work.z),
            PhysicalBlockPosition(x: work.x, y: work.y + 1, z: work.z),
            water, containerPosition,
        ]
        for x in work.x...origin.x {
            for z in work.z...origin.z {
                for y in (origin.y - 1)...(origin.y + 1) {
                    fixturePositions.append(
                        PhysicalBlockPosition(x: x, y: y, z: z)
                    )
                }
            }
        }
        for position in fixturePositions {
            guard world.isChunkReady(position.x >> 4, position.z >> 4),
                  world.getBlockEntity(position.x, position.y, position.z) == nil else {
                throw PebbleRenewableSubsistenceProofError.failed(
                    "initial fixture cell unavailable"
                )
            }
        }
        let originalFixtureCells = fixturePositions.map {
            ($0, world.getBlock($0.x, $0.y, $0.z))
        }
        let originalSky = world.getSkyLight(soil.x, soil.y + 1, soil.z)
        let originalInventory = copyItemInventory(probe.carriedItems)
        let fixtureReservation = try activeCandidatePhysicalTransaction?.reserve(
            compensationPrefix: "renewable-proof-fixture:\(actorID.rawValue)"
        )
        for x in work.x...origin.x {
            for z in work.z...origin.z {
                _ = world.setBlock(x, origin.y - 1, z, Int(cell(B.stone)), SET_SILENT)
                _ = world.setBlock(x, origin.y, z, 0, SET_SILENT)
                _ = world.setBlock(x, origin.y + 1, z, 0, SET_SILENT)
            }
        }
        _ = world.setBlock(soil.x, soil.y, soil.z, Int(cell(B.dirt)), SET_SILENT)
        _ = world.setBlock(soil.x, soil.y + 1, soil.z, 0, SET_SILENT)
        _ = world.setBlock(work.x, work.y - 1, work.z, Int(cell(B.stone)), SET_SILENT)
        _ = world.setBlock(work.x, work.y, work.z, 0, SET_SILENT)
        _ = world.setBlock(work.x, work.y + 1, work.z, 0, SET_SILENT)
        _ = world.setBlock(water.x, water.y, water.z, Int(cell(B.water)), SET_SILENT)
        _ = world.setBlock(
            containerPosition.x, containerPosition.y, containerPosition.z,
            Int(cell(B.chest)), SET_SILENT
        )
        let container = makeContainerBE(
            containerPosition.x, containerPosition.y, containerPosition.z, 27
        )
        world.setBlockEntity(container)
        world.getChunkAt(soil.x, soil.z)?.setSky(
            posMod(soil.x, CHUNK_W), soil.y + 1, posMod(soil.z, CHUNK_W), 15
        )
        probe.carriedItems[0] = ItemStack(iid("iron_hoe"), 1)
        probe.carriedItems[1] = ItemStack(iid("carrot"), 1)
        let expectedFixtureCells = fixturePositions.map {
            ($0, world.getBlock($0.x, $0.y, $0.z))
        }
        let expectedInventory = copyItemInventory(probe.carriedItems)
        func restoreFixture() -> Bool {
            if world.getBlockEntity(
                containerPosition.x, containerPosition.y,
                containerPosition.z
            ) === container {
                _ = world.setBlock(
                    containerPosition.x, containerPosition.y,
                    containerPosition.z, 0, SET_SILENT
                )
            }
            for (position, original) in originalFixtureCells.reversed() {
                _ = world.setBlock(
                    position.x, position.y, position.z,
                    original, SET_SILENT
                )
            }
            world.getChunkAt(soil.x, soil.z)?.setSky(
                posMod(soil.x, CHUNK_W), soil.y + 1,
                posMod(soil.z, CHUNK_W), originalSky
            )
            probe.carriedItems = copyItemInventory(originalInventory)
            return originalFixtureCells.allSatisfy { position, original in
                world.getBlock(position.x, position.y, position.z) == original
            } && world.getBlockEntity(
                containerPosition.x, containerPosition.y,
                containerPosition.z
            ) == nil
                && world.getSkyLight(soil.x, soil.y + 1, soil.z) == originalSky
                && probe.carriedItems == originalInventory
        }
        if let transaction = activeCandidatePhysicalTransaction,
           let fixtureReservation {
            let compensation = PebbleCandidatePhysicalCompensation(
                reservation: fixtureReservation,
                mutation: "renewable disposable proof fixture installation",
                agentID: actorID.rawValue,
                probeID: probe.physicalId,
                expectedBefore: "cells=\(originalFixtureCells.count) "
                    + "sky=\(originalSky) inventory=empty",
                observedState: {
                    let cellsConform = expectedFixtureCells.allSatisfy {
                        position, expected in
                        world.getBlock(position.x, position.y, position.z) == expected
                    }
                    return "cellsConform=\(cellsConform ? 1 : 0) "
                        + "inventory=\(probe.carriedItems)"
                },
                compensate: {
                    guard expectedFixtureCells.allSatisfy({ position, expected in
                        world.getBlock(position.x, position.y, position.z) == expected
                    }), world.getBlockEntity(
                        containerPosition.x, containerPosition.y,
                        containerPosition.z
                    ) === container,
                    probe.carriedItems == expectedInventory else {
                        return false
                    }
                    return restoreFixture()
                }
            )
            try transaction.registerOrCompensate(compensation)
        }
        try navigateAgricultureActor(
            world: world, embodiment: PebbleAgentEmbodiment(probe: probe),
            destination: work
        )
        try synchronizeRenewableCandidatePosition(
            session: &session, actorID: actorID,
            embodiment: PebbleAgentEmbodiment(probe: probe)
        )
        ecologicalObservationSensor.invalidate(world: world)
        _ = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &session,
            recorder: &recorder, receiptTransaction: &receiptTransaction
        )
        guard let observation = session.ecologicalObservations(for: actorID).first,
              observation.observation.soils.contains(where: {
                  $0.position == soil && $0.tillable
              }),
              observation.observation.water.contains(where: {
                  $0.position == AgentPosition(x: water.x, y: water.y, z: water.z)
              }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "initial physical site was not observed"
            )
        }
        _ = try session.planAgriculturalPlot(
            plannerID: actorID, positions: [soil], crop: .carrots,
            sourceObservationEventID: observation.causalEventID,
            designatedStorageLocationID:
                "container:\(containerPosition.x),\(containerPosition.y),\(containerPosition.z)"
        )
        guard let plot = session.agricultureSnapshot().plots.first,
              session.agricultureSnapshot().plots.count == 1,
              plot.crop == .carrots, plot.cells.count == 1,
              plot.cells[0].position == soil,
              plot.designatedStorageLocationID
                == "container:\(containerPosition.x),\(containerPosition.y),\(containerPosition.z)",
              agricultureItemCount("carrot", in: probe.carriedItems) == 1 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "one-cell carrot plan was not selected from the real fixture"
            )
        }
        trace(
            "renewable initialization world=\(ecologicalObservationWorldContextKey(world)) "
                + "simulation=\(session.simulationID.rawValue) agent=\(actorID.rawValue) "
                + "resource=carrot initialAsset=carrot initialQuantity=1 "
                + "soil=\(soil.x),\(soil.y),\(soil.z) water=\(water.x),\(water.y),\(water.z) "
                + "container=\(containerPosition.x),\(containerPosition.y),\(containerPosition.z) "
                + "terrain=existingWorld fixtureCells=26 cropPreexisting=0 foodReserve=0 "
                + "actorStart=\(origin.x),\(origin.y),\(origin.z) "
                + "actorWork=\(work.x),\(work.y),\(work.z) navigation=Core "
                + "tool=iron_hoe:1 tick=\(session.tick) worldTick=\(world.time)"
        )
        trace(
            "renewable INITIALIZATION CLOSED tick=\(session.tick) "
                + "externalInjectionsAfterBoundary=0 directWorldBlockMutationsAfterBoundary=0"
        )
    }

    private func plantFirstRenewableCycle(
        world: World,
        session: inout AgentSimulationSession
    ) throws {
        let (actorID, probe, plot, cell) = try renewableContext(
            world: world, session: session
        )
        guard plot.cycleOrdinal == 1, cell.phase == .planned,
              agricultureItemCount("carrot", in: probe.carriedItems) == 1 else {
            throw PebbleRenewableSubsistenceProofError.failed("first planting precondition")
        }
        _ = try session.reserveAgriculturalCell(
            plotID: plot.plotID, cellIndex: cell.index, contenders: [actorID]
        )
        let embodiment = PebbleAgentEmbodiment(probe: probe)
        guard let tillIntent = session.nextAgriculturalIntent(for: actorID),
              tillIntent.kind == .till else {
            throw PebbleRenewableSubsistenceProofError.failed("first till intent")
        }
        let tillID = agricultureActionID("renewable-cycle1-till")
        _ = try agricultureExecutor.till(
            world: world, actor: embodiment, intent: tillIntent,
            civilDate: try renewableCivilDate(session),
            occupiedPositions: agricultureOccupiedPositions(),
            materialGateway: materialCustodyGateway,
            physicalGateway: physicalActionGateway, actionID: tillID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        guard let plantIntent = session.nextAgriculturalIntent(for: actorID),
              plantIntent.kind == .plant, plantIntent.crop == .carrots else {
            throw PebbleRenewableSubsistenceProofError.failed("first plant intent")
        }
        let plantID = agricultureActionID("renewable-cycle1-plant")
        _ = try agricultureExecutor.plant(
            world: world, actor: embodiment, intent: plantIntent,
            civilDate: try renewableCivilDate(session),
            occupiedPositions: agricultureOccupiedPositions(),
            materialGateway: materialCustodyGateway,
            physicalGateway: physicalActionGateway, actionID: plantID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        let cropCell = world.getBlock(cell.position.x, cell.position.y + 1, cell.position.z)
        guard cropCell == Int(PebbleCore.cell(B.carrots, 0)),
              agricultureItemCount("carrot", in: probe.carriedItems) == 0 else {
            throw PebbleRenewableSubsistenceProofError.failed("first physical debit")
        }
        trace(
            "renewable first operation operationID=\(plantID.rawValue) tillID=\(tillID.rawValue) "
                + "input=carrot:1 debit=1 freeInitialStock=0 site=\(cell.position.x),"
                + "\(cell.position.y + 1),\(cell.position.z) stage=0 crop=carrots "
                + "externalInjections=0 directWorldBlockMutations=0"
        )
    }

    private func harvestRenewableCycle(
        ordinal: Int,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction,
        growthStartTick: Int,
        growthTicks: Int
    ) throws {
        let (actorID, probe, plot, cell) = try renewableContext(
            world: world, session: session
        )
        guard plot.cycleOrdinal == ordinal,
              cell.phase == .planted || cell.phase == .mature,
              agricultureItemCount("carrot", in: probe.carriedItems) == 0 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "cycle \(ordinal) growth precondition"
            )
        }
        let embodiment = PebbleAgentEmbodiment(probe: probe)
        try navigateAgricultureActor(
            world: world, embodiment: embodiment,
            destination: agricultureWorkPosition(for: cell.position)
        )
        try synchronizeRenewableCandidatePosition(
            session: &session, actorID: actorID, embodiment: embodiment
        )
        let maturityID: AgentAgriculturalActionID
        let maturityObservation: AgentEcologicalObservationRecord
        if cell.phase == .planted {
            ecologicalObservationSensor.invalidate(world: world)
            _ = try recordLiveEcologicalObservation(
                world: world, observerID: actorID,
                session: &session, recorder: &recorder,
                receiptTransaction: &receiptTransaction
            )
            guard let observation = session.ecologicalObservations(
                    for: actorID
                  ).first,
                  let crop = observation.observation.crops.first(where: {
                      $0.cropKey == AgentAgriculturalCrop.carrots.rawValue
                          && $0.position == AgentPosition(
                              x: cell.position.x,
                              y: cell.position.y + 1,
                              z: cell.position.z
                          ) && $0.mature
                  }) else {
                throw PebbleRenewableSubsistenceProofError.failed(
                    "cycle \(ordinal) maturity observation"
                )
            }
            maturityObservation = observation
            maturityID = agricultureActionID(
                "renewable-cycle\(ordinal)-maturity"
            )
            _ = try agricultureExecutor.observeMaturity(
                world: world,
                intent: AgentAgriculturalIntent(
                    plotID: plot.plotID, cellIndex: cell.index,
                    actorID: actorID, kind: .maturityObserved,
                    position: cell.position, crop: .carrots
                ),
                observationEventID: observation.causalEventID,
                observedCrop: crop,
                civilDate: try renewableCivilDate(session),
                actionID: maturityID,
                publish: {
                    try publishVerifiedAgriculturalAction(
                        $0, world: world, session: &session
                    )
                }
            )
        } else {
            guard let maturity = session.agricultureSnapshot()
                    .retainedActions.last(where: {
                        $0.outcome.plotID == plot.plotID
                            && $0.outcome.cellIndex == cell.index
                            && $0.outcome.kind == .maturityObserved
                    }),
                  let source = maturity.outcome.sourceObservationEventID,
                  let observation = session.ecologicalObservationSnapshot()
                    .observations.first(where: {
                        $0.causalEventID == source
                    }) else {
                throw PebbleRenewableSubsistenceProofError.failed(
                    "cycle \(ordinal) retained maturity evidence"
                )
            }
            maturityID = maturity.outcome.actionID
            maturityObservation = observation
        }
        guard let harvestIntent = session.nextAgriculturalIntent(for: actorID),
              harvestIntent.kind == .harvest else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "cycle \(ordinal) harvest intent"
            )
        }
        let harvestID = agricultureActionID("renewable-cycle\(ordinal)-harvest")
        let harvested = try agricultureExecutor.harvest(
            world: world, actor: embodiment, intent: harvestIntent,
            civilDate: try renewableCivilDate(session),
            occupiedPositions: agricultureOccupiedPositions(),
            materialGateway: materialCustodyGateway,
            physicalGateway: physicalActionGateway, actionID: harvestID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        let output = harvested.action.outcome.materialDeltas.filter {
            $0.direction == .acquired && $0.itemKey == "carrot"
        }.reduce(0) { $0 + $1.quantity }
        guard output >= 3,
              agricultureItemCount("carrot", in: probe.carriedItems) == output,
              world.getBlock(cell.position.x, cell.position.y + 1, cell.position.z) == 0 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "cycle \(ordinal) physical output"
            )
        }
        if ordinal == 2 {
            try storeSecondHarvest(
                world: world, session: &session, actorID: actorID,
                probe: probe, plot: plot, output: output
            )
            try returnRenewableActorHome(
                world: world, session: &session, actorID: actorID,
                embodiment: embodiment
            )
        }
        trace(
            "renewable cycle harvest cycle=\(ordinal) growthStart=\(growthStartTick) "
                + "authorizedWorldTicks=\(growthTicks) maturityTick=\(world.time) "
                + "maturityID=\(maturityID.rawValue) harvestReceipt=\(harvestID.rawValue) "
                + "maturityObservation=\(maturityObservation.causalEventID.rawValue) "
                + "maturityReceipt="
                + "\(maturityObservation.physicalObservationReceiptID?.rawValue ?? "none") "
                + "output=carrot:\(output) foodOutput=1 reproductiveOutput=\(output - 1) "
                + "siteAfter=air externalInjections=0 directWorldBlockMutations=0"
        )
        if ordinal == 2 {
            guard let evidence = session.renewableSubsistenceEvidence().first,
                  evidence.status == .renewableCycleCompleted,
                  evidence.secondOutputQuantity == output else {
                throw PebbleRenewableSubsistenceProofError.failed(
                    "derived renewable completion"
                )
            }
            traceRenewableSubsistenceStatus(world: world, session: session)
        }
    }

    private func matureSecondRenewableCrop(
        world: World,
        session: AgentSimulationSession
    ) throws {
        let (_, _, plot, cell) = try renewableContext(
            world: world, session: session
        )
        guard plot.cycleOrdinal == 2, cell.phase == .planted else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "cycle 2 physical maturity precondition"
            )
        }
        let start = world.time
        let ticks = try advanceRenewableCropByWorldTicks(
            world: world, position: cell.position
        )
        trace(
            "renewable cycle physical maturity cycle=2 growthStart=\(start) "
                + "authorizedWorldTicks=\(ticks) maturityTick=\(world.time) "
                + "stage=7 sessionMutation=none externalInjections=0 "
                + "directWorldBlockMutations=0"
        )
    }

    private func verifyRenewableMaturityMismatch(
        world: World,
        session: inout AgentSimulationSession
    ) throws {
        let (actorID, _, plot, cell) = try renewableContext(
            world: world, session: session
        )
        let cropPosition = AgentPosition(
            x: cell.position.x, y: cell.position.y + 1, z: cell.position.z
        )
        guard plot.cycleOrdinal == 2, cell.phase == .planted,
              let worldID = persistenceWorldID,
              world.getBlock(
                cropPosition.x, cropPosition.y, cropPosition.z
              ) == Int(PebbleCore.cell(B.carrots, 0)),
              let current = session.ecologicalObservations(for: actorID).first,
              let physicalCrop = current.observation.crops.first(where: {
                  $0.position == cropPosition
                      && $0.cropKey == AgentAgriculturalCrop.carrots.rawValue
              }), !physicalCrop.mature, physicalCrop.growthStage == 0 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "maturity mismatch proof requires current cycle stage-0 evidence"
            )
        }
        let beforeBytes = try session.durableStateBytes()
        let beforeCell = world.getBlock(
            cropPosition.x, cropPosition.y, cropPosition.z
        )
        let receiptStore = try worldAgriculturalActionReceiptStore()
        let beforeReceipts = receiptStore.database.listWorldReceipts(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind
        ).count
        let adversarialCrop = AgentCropObservation(
            cropKey: physicalCrop.cropKey,
            position: physicalCrop.position,
            growthStage: physicalCrop.maximumGrowthStage,
            maximumGrowthStage: physicalCrop.maximumGrowthStage,
            mature: true,
            supportBlockKey: physicalCrop.supportBlockKey
        )
        var publicationCalled = false
        let actionID = AgentAgriculturalActionID.automaticMaturity(
            simulationTick: session.tick,
            plotID: plot.plotID,
            cycleOrdinal: plot.cycleOrdinal,
            cellIndex: cell.index
        )!
        var refused = false
        do {
            _ = try agricultureExecutor.observeMaturity(
                world: world,
                intent: AgentAgriculturalIntent(
                    plotID: plot.plotID, cellIndex: cell.index,
                    actorID: actorID, kind: .maturityObserved,
                    position: cell.position, crop: plot.crop
                ),
                observationEventID: current.causalEventID,
                observedCrop: adversarialCrop,
                civilDate: try renewableCivilDate(session),
                actionID: actionID,
                publish: { outcome in
                    publicationCalled = true
                    return try self.publishVerifiedAgriculturalAction(
                        outcome, world: world, session: &session
                    )
                }
            )
        } catch let error as PebbleAgentAgricultureExecutor.ExecutionError {
            refused = error.description
                == PebbleAgentAgricultureExecutor.ExecutionError
                    .observationMismatch.description
        }
        let afterReceipts = receiptStore.database.listWorldReceipts(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind
        ).count
        guard refused, !publicationCalled,
              try session.durableStateBytes() == beforeBytes,
              world.getBlock(cropPosition.x, cropPosition.y, cropPosition.z)
                == beforeCell,
              afterReceipts == beforeReceipts else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "maturity mismatch did not fail closed exactly"
            )
        }
        trace(
            "renewable maturity mismatch cycle=2 physicalStage=0 "
                + "adversarialEvidence=mature action=\(actionID.rawValue) "
                + "refused=agricultural_maturity_observation_mismatch "
                + "publication=none sessionRollback=exact worldRollback=exact "
                + "WorldReceiptDelta=0 simulationTick=\(session.tick)"
        )
    }

    private func consumeAndReplantRenewableOutput(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        let (actorID, probe, plot, cell) = try renewableContext(
            world: world, session: session
        )
        guard plot.cycleOrdinal == 1, plot.phase == .storing,
              agricultureItemCount("carrot", in: probe.carriedItems) >= 3 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "first output is not ready for consumption"
            )
        }
        let hungerBefore = try session.state(for: actorID).needs.hunger
        guard hungerBefore > 0 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "normal survival tick did not create a hunger need"
            )
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(probe, in: world)
        let intent = try session.nextPhysicalFoodConsumptionIntent(for: actorID)
        guard let plan = try foodConsumptionExecutor.prepare(
            intent, session: session, source: source,
            gateway: materialCustodyGateway
        ), plan.validatedOutcome.canonicalMaterialName == "carrot" else {
            throw PebbleRenewableSubsistenceProofError.failed("carrot food intent")
        }
        let countBefore = agricultureItemCount("carrot", in: probe.carriedItems)
        let consumed = foodConsumptionExecutor.execute(
            plan, session: &session, source: source,
            gateway: materialCustodyGateway
        )
        guard consumed.succeeded, let food = consumed.outcome,
              agricultureItemCount("carrot", in: probe.carriedItems) == countBefore - 1,
              try session.state(for: actorID).needs.hunger == food.hungerAfter,
              food.hungerAfter < food.hungerBefore else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "physical carrot consumption"
            )
        }

        let container = try renewableContainer(world: world, plot: plot)
        let embodiment = PebbleAgentEmbodiment(probe: probe)
        guard let storeIntent = session.nextAgriculturalIntent(for: actorID),
              storeIntent.kind == .store else {
            throw PebbleRenewableSubsistenceProofError.failed("first storage intent")
        }
        let storeID = agricultureActionID("renewable-cycle1-store")
        _ = try agricultureExecutor.storeHarvest(
            world: world, actor: embodiment, intent: storeIntent,
            container: container, civilDate: try renewableCivilDate(session),
            seedReserveTarget: 1, retainedSeedQuantity: 1,
            materialGateway: materialCustodyGateway, actionID: storeID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        guard agricultureItemCount("carrot", in: probe.carriedItems) == 1,
              agricultureItemCount("carrot", in: container.items ?? []) == countBefore - 2,
              session.agricultureSnapshot().completedCycleCount == 1 else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "physical reproductive reservation"
            )
        }

        ecologicalObservationSensor.invalidate(world: world)
        _ = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &session,
            recorder: &recorder, receiptTransaction: &receiptTransaction
        )
        guard let observation = session.ecologicalObservations(for: actorID).first else {
            throw PebbleRenewableSubsistenceProofError.failed("renewal observation")
        }
        _ = try session.renewAgriculturalPlot(
            plotID: plot.plotID, plannerID: actorID,
            sourceObservationEventID: observation.causalEventID
        )
        let renewed = try renewablePlot(session)
        _ = try session.reserveAgriculturalCell(
            plotID: renewed.plotID, cellIndex: cell.index, contenders: [actorID]
        )
        guard let plantIntent = session.nextAgriculturalIntent(for: actorID),
              plantIntent.kind == .plant, plantIntent.crop == .carrots else {
            throw PebbleRenewableSubsistenceProofError.failed("second plant intent")
        }
        let secondPlantID = agricultureActionID("renewable-cycle2-plant")
        _ = try agricultureExecutor.plant(
            world: world, actor: embodiment, intent: plantIntent,
            civilDate: try renewableCivilDate(session),
            occupiedPositions: agricultureOccupiedPositions(),
            materialGateway: materialCustodyGateway,
            physicalGateway: physicalActionGateway, actionID: secondPlantID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        guard agricultureItemCount("carrot", in: probe.carriedItems) == 0,
              world.getBlock(cell.position.x, cell.position.y + 1, cell.position.z)
                == Int(PebbleCore.cell(B.carrots, 0)) else {
            throw PebbleRenewableSubsistenceProofError.failed("second physical debit")
        }
        try transferRenewableHoeToContainer(
            world: world, probe: probe, embodiment: embodiment, container: container
        )
        try returnRenewableActorHome(
            world: world, session: &session, actorID: actorID,
            embodiment: embodiment
        )
        guard probe.carriedItems.allSatisfy({ $0 == nil }),
              agricultureItemCount("iron_hoe", in: container.items ?? []) == 1,
              let evidence = session.renewableSubsistenceEvidence().first,
              evidence.status == .secondCycleEstablished,
              evidence.consumptionID == food.consumptionID,
              evidence.secondPlantActionIDs == [secondPlantID] else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "second-cycle provenance or empty restart probe"
            )
        }
        trace(
            "renewable food and reserve consumptionReceipt=\(food.consumptionID) "
                + "material=carrot debit=1 hunger=\(food.hungerBefore)>\(food.hungerAfter) "
                + "reservedOutput=carrot:1 physicalHolder=agent:agent_0 "
                + "storedSurplus=\(countBefore - 2) storeReceipt=\(storeID.rawValue)"
        )
        trace(
            "renewable second operation operationID=\(secondPlantID.rawValue) "
                + "input=carrot:1 provenance=\(evidence.firstHarvestActionIDs.map(\.rawValue).joined(separator: ",")) "
                + "debit=1 freeReproductiveStock=0 site=\(cell.position.x),"
                + "\(cell.position.y + 1),\(cell.position.z) stage=0 "
                + "checkpointReady=1 probeInventory=empty externalInjections=0 "
                + "probePosition=home directWorldBlockMutations=0"
        )
    }

    private func returnRenewableActorHome(
        world: World,
        session: inout AgentSimulationSession,
        actorID: AgentID,
        embodiment: PebbleAgentEmbodiment
    ) throws {
        let home = try session.state(for: actorID).homePosition
        try navigateAgricultureActor(
            world: world, embodiment: embodiment, destination: home
        )
        try synchronizeRenewableCandidatePosition(
            session: &session, actorID: actorID, embodiment: embodiment
        )
        guard embodiment.position == home else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "probe did not return to checkpoint position"
            )
        }
    }

    private func synchronizeRenewableCandidatePosition(
        session: inout AgentSimulationSession,
        actorID: AgentID,
        embodiment: PebbleAgentEmbodiment
    ) throws {
        try session.applyExternalUpdate(AgentExternalUpdate(
            agentId: actorID.rawValue,
            position: embodiment.position
        ))
        guard try session.state(for: actorID).position == embodiment.position else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "renewable candidate position publication"
            )
        }
    }

    private func storeSecondHarvest(
        world: World,
        session: inout AgentSimulationSession,
        actorID: AgentID,
        probe: LabCoreAgentEntity,
        plot: AgentAgriculturalPlot,
        output: Int
    ) throws {
        let container = try renewableContainer(world: world, plot: plot)
        let embodiment = PebbleAgentEmbodiment(probe: probe)
        guard let intent = session.nextAgriculturalIntent(for: actorID),
              intent.kind == .store else {
            throw PebbleRenewableSubsistenceProofError.failed("second storage intent")
        }
        let storeID = agricultureActionID("renewable-cycle2-store")
        _ = try agricultureExecutor.storeHarvest(
            world: world, actor: embodiment, intent: intent,
            container: container, civilDate: try renewableCivilDate(session),
            seedReserveTarget: 1, retainedSeedQuantity: 1,
            materialGateway: materialCustodyGateway, actionID: storeID,
            publishAndVerify: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
        guard agricultureItemCount("carrot", in: probe.carriedItems) == 1,
              agricultureItemCount("carrot", in: container.items ?? []) >= output else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "second reproductive reserve"
            )
        }
        trace(
            "renewable second reserve storeReceipt=\(storeID.rawValue) "
                + "newPhysicalReserve=carrot:1 holder=agent:agent_0 "
                + "containerCarrots=\(agricultureItemCount("carrot", in: container.items ?? []))"
        )
    }

    private func transferRenewableHoeToContainer(
        world: World,
        probe: LabCoreAgentEntity,
        embodiment: PebbleAgentEmbodiment,
        container: BlockEntityData
    ) throws {
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(embodiment, in: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)
        guard let hoe = try materialCustodyGateway.inspect(source).slots.compactMap({ $0 })
            .first(where: { $0.identity.itemKey == "iron_hoe" }) else {
            throw PebbleRenewableSubsistenceProofError.failed("restart hoe custody")
        }
        let result = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: "renewable-cycle2-restart-hoe",
                material: AgentMaterialStackSnapshot(identity: hoe.identity, count: 1),
                expectedSourceFingerprint: try materialCustodyGateway.fingerprint(source),
                expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(destination)
            ),
            from: source, to: destination
        )
        guard result.succeeded, probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleRenewableSubsistenceProofError.failed("restart hoe transfer")
        }
    }

    private func advanceRenewableCropByWorldTicks(
        world: World,
        position: AgentPosition
    ) throws -> Int {
        let cropY = position.y + 1
        guard world.getBlock(position.x, cropY, position.z) == Int(cell(B.carrots, 0)) else {
            throw PebbleRenewableSubsistenceProofError.failed("crop did not start at stage zero")
        }
        let priorSpeed = world.randomTickSpeed
        let priorDistance = world.simDistance
        let priorCenterX = world.simCenterX
        let priorCenterZ = world.simCenterZ
        world.randomTickSpeed = 4_096
        world.simDistance = 0
        world.simCenterX = floorDiv(position.x, CHUNK_W)
        world.simCenterZ = floorDiv(position.z, CHUNK_W)
        defer {
            world.randomTickSpeed = priorSpeed
            world.simDistance = priorDistance
            world.simCenterX = priorCenterX
            world.simCenterZ = priorCenterZ
        }
        var ticks = 0
        while world.getBlock(position.x, cropY, position.z) & 7 < 7, ticks < 256 {
            world.tick()
            ticks += 1
        }
        guard world.getBlock(position.x, cropY, position.z) == Int(cell(B.carrots, 7)) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "canonical World ticks did not mature the carrot within the bound"
            )
        }
        return ticks
    }

    private func traceRenewableSubsistenceStatus(
        world: World,
        session: AgentSimulationSession
    ) {
        guard let plot = session.agricultureSnapshot().plots.first,
              let cell = plot.cells.first else {
            trace("renewable status unavailable")
            return
        }
        let cropCell = world.getBlock(cell.position.x, cell.position.y + 1, cell.position.z)
        let stage = cropCell >> 4 == Int(B.carrots) ? cropCell & 7 : -1
        let actorCarrots = probesByAgentId[plot.plannerID.rawValue].map {
            agricultureItemCount("carrot", in: $0.carriedItems)
        } ?? -1
        let container = try? renewableContainer(world: world, plot: plot)
        let containerCarrots = container.map {
            agricultureItemCount("carrot", in: $0.items ?? [])
        } ?? -1
        let snapshot = session.agricultureSnapshot()
        let duplicateReceipts = snapshot.retainedActions.count
            - Set(snapshot.retainedActions.map(\.outcome.actionID)).count
        let duplicateSites = plot.cells.count - Set(plot.cells.map(\.position)).count
        let evidence = session.renewableSubsistenceEvidence().first
        trace(
            "renewable status schema=\(session.durableState().schemaVersion) "
                + "observerSchema=\(evidence == nil ? 6 : 7) "
                + "world=\(ecologicalObservationWorldContextKey(world)) "
                + "simulation=\(session.simulationID.rawValue) tick=\(session.tick) "
                + "worldTick=\(world.time) agent=\(plot.plannerID.rawValue) "
                + "plot=\(plot.plotID.rawValue) crop=\(plot.crop.rawValue) "
                + "cycle=\(plot.cycleOrdinal) phase=\(plot.phase.rawValue) stage=\(stage) "
                + "actorCarrots=\(actorCarrots) containerCarrots=\(containerCarrots) "
                + "status=\(evidence?.status.rawValue ?? "blocked") "
                + "firstOutput=\(evidence?.firstOutputQuantity ?? 0) "
                + "consumed=\(evidence?.consumedQuantity ?? 0) "
                + "secondInput=\(evidence?.secondInputQuantity ?? 0) "
                + "secondOutput=\(evidence?.secondOutputQuantity ?? 0) "
                + "duplicateReceipts=\(duplicateReceipts) duplicateSites=\(duplicateSites) "
                + "externalInjections=0 directWorldBlockMutations=0 runtimeErrors=\(runtimeErrorCount)"
        )
    }

    private func renewableContext(
        world: World,
        session: AgentSimulationSession
    ) throws -> (AgentID, LabCoreAgentEntity, AgentAgriculturalPlot, AgentAgriculturalCell) {
        let plot = try renewablePlot(session)
        guard plot.crop == .carrots, plot.cells.count == 1,
              let cell = plot.cells.first,
              let probe = probesByAgentId[plot.plannerID.rawValue],
              probe.world === world, !probe.dead else {
            throw PebbleRenewableSubsistenceProofError.failed("renewable context")
        }
        return (plot.plannerID, probe, plot, cell)
    }

    private func renewablePlot(
        _ session: AgentSimulationSession
    ) throws -> AgentAgriculturalPlot {
        let plots = session.agricultureSnapshot().plots
        guard plots.count == 1, let plot = plots.first else {
            throw PebbleRenewableSubsistenceProofError.failed("single renewable plot")
        }
        return plot
    }

    private func renewableContainer(
        world: World,
        plot: AgentAgriculturalPlot
    ) throws -> BlockEntityData {
        let prefix = "container:"
        guard plot.designatedStorageLocationID.hasPrefix(prefix) else {
            throw PebbleRenewableSubsistenceProofError.failed("container binding")
        }
        let components = plot.designatedStorageLocationID.dropFirst(prefix.count)
            .split(separator: ",")
        guard components.count == 3, let x = Int(components[0]),
              let y = Int(components[1]), let z = Int(components[2]),
              let container = world.getBlockEntity(x, y, z),
              container.type == "container", container.items != nil else {
            throw PebbleRenewableSubsistenceProofError.failed("live container")
        }
        return container
    }

    private func renewableActorID() throws -> AgentID {
        guard let actorID = AgentID(rawValue: "agent_0") else {
            throw PebbleRenewableSubsistenceProofError.failed("actor identity")
        }
        return actorID
    }

    private func renewableCivilDate(
        _ session: AgentSimulationSession
    ) throws -> AgentCivilDate {
        guard let date = session.civilDate() else {
            throw PebbleRenewableSubsistenceProofError.failed("civil date")
        }
        return date
    }

    /// Evaluation-only composition bridge. It redistributes material already
    /// harvested by the published renewable cycle through the normal custody
    /// gateway. It is unavailable without the exact Evaluation 11 gate.
    private func transferEvaluation11RenewableReserve(
        quantity: Int,
        targetID: AgentID,
        role: String,
        world: World,
        session: AgentSimulationSession,
        requireMatureG1: Bool = false
    ) throws {
        guard environment["PEBBLELAB_GATE_D_EVALUATION_11"] == "1",
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              quantity > 0,
              session.renewableSubsistenceEvidence().contains(where: {
                  $0.status == .renewableCycleCompleted
              }),
              let target = probesByAgentId[targetID.rawValue],
              target.world === world, !target.dead,
              target.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 renewable reserve precondition"
            )
        }
        if requireMatureG1 {
            guard session.lifecycleSnapshot().members.contains(where: {
                $0.agentID == targetID && $0.currentStage == .mature
            }), session.kinshipSnapshot().parentageRecords.contains(where: {
                $0.childID == targetID
                    && $0.canonicalParentIDs.map(\.rawValue)
                        == ["agent_0", "agent_1"]
            }) else {
                throw PebbleRenewableSubsistenceProofError.failed(
                    "evaluation11 G1 reserve authority"
                )
            }
        }
        let plot = try renewablePlot(session)
        let container = try renewableContainer(world: world, plot: plot)
        let source = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            target, in: world
        )
        let sourceBefore = try materialCustodyGateway.inspect(source)
        let destinationBefore = try materialCustodyGateway.inspect(destination)
        let matching = sourceBefore.slots.compactMap({ $0 }).filter {
            $0.identity.itemKey == "carrot" && $0.count >= quantity
        }
        guard matching.count == 1, let carrots = matching.first else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 renewable reserve source is not exact"
            )
        }
        let totalBefore = sourceBefore.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
            + destinationBefore.slots.compactMap({ $0 })
                .filter { $0.identity.itemKey == "carrot" }
                .reduce(0) { $0 + $1.count }
        let sourceFingerprint = try materialCustodyGateway.fingerprint(source)
        let destinationFingerprint = try materialCustodyGateway.fingerprint(
            destination
        )
        let transactionID = "gate-d-e11-renewable-reserve:"
            + "\(targetID.rawValue):t\(session.tick)"
        let result = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: transactionID,
                material: AgentMaterialStackSnapshot(
                    identity: carrots.identity, count: quantity
                ),
                expectedSourceFingerprint: sourceFingerprint,
                expectedDestinationFingerprint: destinationFingerprint
            ),
            from: source,
            to: destination
        )
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let destinationAfter = try materialCustodyGateway.inspect(destination)
        let sourceCarrots = sourceAfter.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
        let targetCarrots = destinationAfter.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
        guard result.succeeded, targetCarrots == quantity,
              sourceCarrots + targetCarrots == totalBefore,
              try session.durableStateBytes()
                == self.session?.durableStateBytes() else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 renewable reserve transfer"
            )
        }
        trace(
            "evaluation11 renewable reserve source=cycle2-container "
                + "target=\(targetID.rawValue) role=\(role) material=carrot "
                + "quantity=\(quantity) sourceBeforeFingerprint=\(sourceFingerprint) "
                + "destinationBeforeFingerprint=\(destinationFingerprint) "
                + "sourceAfter=\(sourceCarrots) targetAfter=\(targetCarrots) "
                + "total=\(totalBefore)>\(sourceCarrots + targetCarrots) "
                + "transaction=\(transactionID) syntheticMaterial=0 "
                + "physicalLoss=0 physicalDuplication=0 sessionMutation=none"
        )
    }

    private func returnEvaluation11RenewableReserve(
        sourceID: AgentID,
        world: World,
        session: AgentSimulationSession
    ) throws {
        guard environment["PEBBLELAB_GATE_D_EVALUATION_11"] == "1",
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              let sourceProbe = probesByAgentId[sourceID.rawValue],
              sourceProbe.world === world, !sourceProbe.dead else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 reserve return precondition"
            )
        }
        let plot = try renewablePlot(session)
        let container = try renewableContainer(world: world, plot: plot)
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            sourceProbe, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let sourceBefore = try materialCustodyGateway.inspect(source)
        let destinationBefore = try materialCustodyGateway.inspect(destination)
        let matches = sourceBefore.slots.compactMap({ $0 }).filter {
            $0.identity.itemKey == "carrot" && $0.count == 1
        }
        guard matches.count == 1, let carrot = matches.first else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 returned reserve is not exact"
            )
        }
        let totalBefore = sourceBefore.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
            + destinationBefore.slots.compactMap({ $0 })
                .filter { $0.identity.itemKey == "carrot" }
                .reduce(0) { $0 + $1.count }
        let transactionID = "gate-d-e11-renewable-return:"
            + "\(sourceID.rawValue):t\(session.tick)"
        let result = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: transactionID,
                material: AgentMaterialStackSnapshot(
                    identity: carrot.identity, count: 1
                ),
                expectedSourceFingerprint:
                    try materialCustodyGateway.fingerprint(source),
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination
        )
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let destinationAfter = try materialCustodyGateway.inspect(destination)
        let sourceCarrots = sourceAfter.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
        let destinationCarrots = destinationAfter.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
        guard result.succeeded, sourceCarrots == 0,
              sourceCarrots + destinationCarrots == totalBefore,
              try session.durableStateBytes()
                == self.session?.durableStateBytes() else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 renewable reserve return conservation"
            )
        }
        trace(
            "evaluation11 renewable reserve return source=\(sourceID.rawValue) "
                + "destination=cycle2-container material=carrot quantity=1 "
                + "sourceAfter=\(sourceCarrots) destinationAfter=\(destinationCarrots) "
                + "total=\(totalBefore)>\(sourceCarrots + destinationCarrots) "
                + "transaction=\(transactionID) syntheticMaterial=0 "
                + "physicalLoss=0 physicalDuplication=0 sessionMutation=none"
        )
    }

    /// Evaluation-only bridge from harvested output into the normal physical
    /// food executor. The renewable container remains the material source.
    private func feedEvaluation11G0FromRenewableOutput(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        guard environment["PEBBLELAB_GATE_D_EVALUATION_11"] == "1",
              environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              session.renewableSubsistenceEvidence().contains(where: {
                  $0.status == .renewableCycleCompleted
              }),
              let actorID = AgentID(rawValue: "agent_0"),
              let actor = probesByAgentId[actorID.rawValue],
              actor.world === world, !actor.dead,
              actor.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 feeding precondition"
            )
        }
        let plot = try renewablePlot(session)
        let container = try renewableContainer(world: world, plot: plot)
        let source = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            actor, in: world
        )
        let sourceBefore = try materialCustodyGateway.inspect(source)
        let carrots = sourceBefore.slots.compactMap({ $0 }).filter {
            $0.identity.itemKey == "carrot" && $0.count >= 1
        }
        guard carrots.count == 1, let stack = carrots.first else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 renewable source is not exact"
            )
        }
        let transferID = "gate-d-e11-renewable-g0:t\(session.tick)"
        let transfer = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: transferID,
                material: AgentMaterialStackSnapshot(
                    identity: stack.identity, count: 1
                ),
                expectedSourceFingerprint:
                    try materialCustodyGateway.fingerprint(source),
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination
        )
        guard transfer.succeeded else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 renewable transfer \(transfer.status.rawValue)"
            )
        }
        let stateBefore = try session.state(for: actorID)
        let intent = try session.nextPhysicalFoodConsumptionIntent(for: actorID)
        guard let plan = try foodConsumptionExecutor.prepare(
            intent, session: session, source: destination,
            gateway: materialCustodyGateway
        ), plan.validatedOutcome.canonicalMaterialName == "carrot" else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 carrot plan"
            )
        }
        var recorderCandidate = recorder
        let consumption = foodConsumptionExecutor.execute(
            plan, session: &session, source: destination,
            gateway: materialCustodyGateway,
            publish: { outcome, candidate in
                if var activeRecorder = recorderCandidate {
                    _ = try activeRecorder.apply(
                        .validatedPhysicalFoodConsumption(outcome),
                        to: &candidate
                    )
                    recorderCandidate = activeRecorder
                } else {
                    try candidate.applyValidatedPhysicalFoodConsumption(outcome)
                }
            }
        )
        guard consumption.succeeded, let outcome = consumption.outcome,
              actor.carriedItems.allSatisfy({ $0 == nil }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 carrot consumption "
                    + consumption.status.rawValue
            )
        }
        recorder = recorderCandidate
        let sourceAfter = try materialCustodyGateway.inspect(source)
        let remaining = sourceAfter.slots.compactMap({ $0 })
            .filter { $0.identity.itemKey == "carrot" }
            .reduce(0) { $0 + $1.count }
        let stateAfter = try session.state(for: actorID)
        guard remaining == stack.count - 1,
              stateAfter.needs.hunger == outcome.hungerAfter else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "evaluation11 G0 renewable conservation"
            )
        }
        trace(
            "evaluation11 renewable G0 nourishment actor=agent_0 "
                + "material=carrot source=cycle2-container transfer=1 "
                + "physicalCount=1>0 hunger=\(stateBefore.needs.hunger)>"
                + "\(stateAfter.needs.hunger) remaining=\(remaining) "
                + "receipt=\(outcome.physicalReceiptID) physicalDebit=1 "
                + "deprivation=delayed-not-disabled syntheticMaterial=0 "
                + "physicalLoss=0 physicalDuplication=0 publication=validated"
        )
    }
}
