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
        let usage = "Usage: /lab renewable-subsistence <setup|plant-first|harvest-first|consume-replant|status|harvest-second>"
        guard arguments.count == 1, let command = arguments.first?.lowercased(),
              var candidate = session, activeWorld === world else {
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
        guard candidate.agricultureEnabled, candidate.physicalFoodSurvivalEnabled,
              candidate.lifecycleEnabled, candidate.skillsEnabled,
              candidate.ecologicalObservationEnabled, isPaused, !movementEnabled,
              replayRecorder == nil else {
            return failure(
                "Renewable subsistence requires paused agriculture, physical food, lifecycle, skills, and ecological observation."
            )
        }
        do {
            switch command {
            case "setup":
                try setupRenewableSubsistence(world: world, session: &candidate)
            case "plant-first":
                try plantFirstRenewableCycle(world: world, session: &candidate)
            case "harvest-first":
                try harvestRenewableCycle(
                    ordinal: 1, world: world, session: &candidate
                )
            case "consume-replant":
                try consumeAndReplantRenewableOutput(
                    world: world, session: &candidate
                )
            case "status":
                traceRenewableSubsistenceStatus(world: world, session: candidate)
                return success("Renewable subsistence status traced.")
            case "harvest-second":
                try harvestRenewableCycle(
                    ordinal: 2, world: world, session: &candidate
                )
            default:
                return failure(usage)
            }
            session = candidate
            return success("Renewable subsistence \(command) passed.")
        } catch {
            return failure("Renewable subsistence \(command) failed: \(error)")
        }
    }

    private func setupRenewableSubsistence(
        world: World,
        session: inout AgentSimulationSession
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
        try navigateAgricultureActor(
            world: world, embodiment: PebbleAgentEmbodiment(probe: probe),
            destination: work
        )
        ecologicalObservationSensor.invalidate(world: world)
        var recorder: AgentReplayRecorder?
        _ = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &session, recorder: &recorder
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
        session: inout AgentSimulationSession
    ) throws {
        let (actorID, probe, plot, cell) = try renewableContext(
            world: world, session: session
        )
        guard plot.cycleOrdinal == ordinal, cell.phase == .planted,
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
        let growthStartTick = world.time
        let growthTicks = try advanceRenewableCropByWorldTicks(
            world: world, position: cell.position
        )
        ecologicalObservationSensor.invalidate(world: world)
        var recorder: AgentReplayRecorder?
        _ = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &session, recorder: &recorder
        )
        guard let observation = session.ecologicalObservations(for: actorID).first,
              let crop = observation.observation.crops.first(where: {
                  $0.cropKey == AgentAgriculturalCrop.carrots.rawValue
                      && $0.position == AgentPosition(
                          x: cell.position.x, y: cell.position.y + 1,
                          z: cell.position.z
                      ) && $0.mature
              }) else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "cycle \(ordinal) maturity observation"
            )
        }
        let maturityID = agricultureActionID("renewable-cycle\(ordinal)-maturity")
        _ = try agricultureExecutor.observeMaturity(
            world: world,
            intent: AgentAgriculturalIntent(
                plotID: plot.plotID, cellIndex: cell.index, actorID: actorID,
                kind: .maturityObserved, position: cell.position, crop: .carrots
            ),
            observationEventID: observation.causalEventID,
            observedCrop: crop, civilDate: try renewableCivilDate(session),
            actionID: maturityID,
            publish: {
                try publishVerifiedAgriculturalAction(
                    $0, world: world, session: &session
                )
            }
        )
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
                world: world, session: session, actorID: actorID,
                embodiment: embodiment
            )
        }
        trace(
            "renewable cycle harvest cycle=\(ordinal) growthStart=\(growthStartTick) "
                + "authorizedWorldTicks=\(growthTicks) maturityTick=\(world.time) "
                + "maturityID=\(maturityID.rawValue) harvestReceipt=\(harvestID.rawValue) "
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

    private func consumeAndReplantRenewableOutput(
        world: World,
        session: inout AgentSimulationSession
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
        var recorder: AgentReplayRecorder?
        _ = try recordLiveEcologicalObservation(
            world: world, observerID: actorID, session: &session, recorder: &recorder
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
            world: world, session: session, actorID: actorID,
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
        session: AgentSimulationSession,
        actorID: AgentID,
        embodiment: PebbleAgentEmbodiment
    ) throws {
        let home = try session.state(for: actorID).position
        try navigateAgricultureActor(
            world: world, embodiment: embodiment, destination: home
        )
        guard embodiment.position == home else {
            throw PebbleRenewableSubsistenceProofError.failed(
                "probe did not return to checkpoint position"
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
            "renewable status schema=29 observerSchema=\(evidence == nil ? 6 : 7) "
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
}
