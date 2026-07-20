import PebbleAgents
import PebbleCore

struct PebbleAgentAgricultureProofFixture {
    struct OriginalCell {
        let position: PhysicalBlockPosition
        let cell: Int
    }

    struct OriginalSkyLight {
        let position: PhysicalBlockPosition
        let value: Int
    }

    let originalCells: [OriginalCell]
    let originalSkyLight: [OriginalSkyLight]
    let originalActorItems: [ItemStack?]
    let originalActorPosition: (x: Double, y: Double, z: Double)
    let originalActorOrientation: (yaw: Double, pitch: Double)
    let entityIDsBefore: [Int]
    let actorID: String
    let productiveCells: [AgentPosition]
    let displayCells: [AgentPosition]
    let water: PhysicalBlockPosition
    let containerPosition: PhysicalBlockPosition
    let negativeTillCell: AgentPosition
    let negativePlantCell: AgentPosition
    let negativeHarvestCell: AgentPosition
    let container: BlockEntityData
}

private enum PebbleAgentAgricultureProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func handleAgriculture(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab agriculture <on|status|proof>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = agricultureGateDependencies()
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "PebbleAgents agriculture refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard candidate.populationEnabled, candidate.lifecycleEnabled,
              candidate.skillsEnabled, candidate.ecologicalObservationEnabled else {
            return failure(
                "Agriculture requires population, lifecycle, skills, and ecological observation."
            )
        }
        do {
            switch command {
            case "on":
                if !candidate.agricultureEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setAgricultureEnabled(true, configuration: .live),
                        session: &candidate, recorder: &recorder
                    ) == nil {
                        try candidate.setAgricultureEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceAgricultureState(candidate, reason: "activated")
                return agricultureStatus(candidate, world: world)
            case "status":
                traceAgricultureState(candidate, reason: "status")
                return agricultureStatus(candidate, world: world)
            case "proof":
                return handleAgricultureProof(world: world, player: player)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents agriculture command failed: \(error)")
        }
    }

    /// Product decision seam: a fresh CIV-21 observation plus real tool,
    /// planting input, and storage can create a bounded plan and expose the
    /// next work intent. It does not execute farming or mutate the World.
    @discardableResult
    func prepareLiveAgriculturalPlanIfEligible(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> Bool {
        guard agricultureFeatureEnabled, session.agricultureEnabled,
              session.agricultureSnapshot().plots.isEmpty else { return false }
        for snapshot in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
            guard let actorID = AgentID(rawValue: snapshot.id),
                  let observationRecord = session.ecologicalObservations(for: actorID).first,
                  observationRecord.observation.isFresh(atSimulationTick: session.tick),
                  let probe = probesByAgentId[snapshot.id], probe.world === world, !probe.dead else {
                trace("agriculture autonomy candidate=\(snapshot.id) refused=observation_or_embodiment")
                continue
            }
            let embodiment = PebbleAgentEmbodiment(probe: probe)
            let hasHoe = embodiment.carriedItems.compactMap { $0 }.contains {
                $0.count > 0 && itemDef($0.id).tool?.type == "hoe"
            }
            let hasSeeds = materialCustodyGateway.placementBinding(
                actor: embodiment, requiredBlockID: Int(B.wheat)
            ) != nil
            let storage = nearestLiveAgricultureContainer(
                world: world, origin: embodiment.position, radius: 8
            )
            let observation = observationRecord.observation
            let maximum = session.agricultureSnapshot().configuration?.maximumCellsPerPlot ?? 4
            let minimum = session.agricultureSnapshot().configuration?.minimumCellsPerPlot ?? 2
            let positions = observation.soils.filter { soil in
                guard soil.tillable else { return false }
                let physical = world.getBlock(
                    soil.position.x, soil.position.y, soil.position.z
                ) >> 4
                guard physical == Int(B.dirt) || physical == Int(B.grass_block)
                        || physical == Int(B.dirt_path) else { return false }
                return observation.water.contains { water in
                    abs(water.position.x - soil.position.x) <= 4
                        && abs(water.position.z - soil.position.z) <= 4
                        && (0...1).contains(water.position.y - soil.position.y)
                }
            }.map(\.position).sorted(by: agricultureLivePositionSort)
            let bounded = Array(positions.prefix(maximum))
            guard hasHoe, hasSeeds, let storage, bounded.count >= minimum else {
                trace(
                    "agriculture autonomy candidate=\(actorID.rawValue) refused=materials_or_site "
                        + "hoe=\(hasHoe ? 1 : 0) seeds=\(hasSeeds ? 1 : 0) "
                        + "storage=\(storage == nil ? 0 : 1) observedSoils=\(observation.soils.count) "
                        + "observedWater=\(observation.water.count) eligible=\(positions.count) "
                        + "completion=\(observation.diagnostics.completion.rawValue) "
                        + "cells=\(observation.diagnostics.cellsConsidered) "
                        + "chunks=\(observation.diagnostics.chunksTouched)"
                )
                continue
            }
            let operation = AgentReplayOperation.planAgriculturalPlot(
                plannerID: actorID, positions: bounded, crop: .wheat,
                sourceObservationEventID: observationRecord.causalEventID,
                designatedStorageLocationID: "container:\(storage.x),\(storage.y),\(storage.z)"
            )
            if try applyRecordedOperationIfActive(
                operation, session: &session, recorder: &recorder
            ) == nil {
                _ = try session.planAgriculturalPlot(
                    plannerID: actorID, positions: bounded, crop: .wheat,
                    sourceObservationEventID: observationRecord.causalEventID,
                    designatedStorageLocationID: "container:\(storage.x),\(storage.y),\(storage.z)"
                )
            }
            let intent = session.nextAgriculturalIntent(for: actorID)
            trace(
                "agriculture autonomy observer=\(actorID.rawValue) observation=fresh "
                    + "soil=real water=real tool=real seeds=real storage=real "
                    + "plot=planned cells=\(bounded.count) next=\(intent?.kind.rawValue ?? "none") "
                    + "worldMutation=none materialMutation=none"
            )
            return true
        }
        return false
    }

    private func agricultureGateDependencies() -> [(String, Bool)] {
        [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_MOVE=1", movementFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_INTERACT=1", interactionFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_MATERIAL=1", materialFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            (
                "PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1",
                ecologicalObservationFeatureEnabled
            ),
            ("PEBBLELAB_APP_AGENTS_AGRICULTURE=1", agricultureFeatureEnabled),
        ]
    }

    private func nearestLiveAgricultureContainer(
        world: World,
        origin: AgentPosition,
        radius: Int
    ) -> BlockEntityData? {
        var candidates: [BlockEntityData] = []
        for y in (origin.y - 2)...(origin.y + 2) {
            for z in (origin.z - radius)...(origin.z + radius) {
                for x in (origin.x - radius)...(origin.x + radius) {
                    guard world.isChunkReady(x >> 4, z >> 4),
                          let value = world.getBlockEntity(x, y, z),
                          value.type == "container", value.items != nil else { continue }
                    candidates.append(value)
                }
            }
        }
        return candidates.sorted {
            let lhs = abs($0.x - origin.x) + abs($0.y - origin.y) + abs($0.z - origin.z)
            let rhs = abs($1.x - origin.x) + abs($1.y - origin.y) + abs($1.z - origin.z)
            if lhs != rhs { return lhs < rhs }
            if $0.x != $1.x { return $0.x < $1.x }
            if $0.y != $1.y { return $0.y < $1.y }
            return $0.z < $1.z
        }.first
    }

    private func agricultureStatus(
        _ session: AgentSimulationSession,
        world: World
    ) -> PebbleAgentCommandResult {
        let snapshot = session.agricultureSnapshot()
        let live: String
        if let record = snapshot.managedSurplusRecords.last,
           let coordinates = agricultureContainerCoordinates(record.storageLocationID),
           let container = world.getBlockEntity(coordinates.x, coordinates.y, coordinates.z),
           let quantities = try? agricultureExecutor.liveSurplus(
                container: container, world: world,
                materialGateway: materialCustodyGateway
           ) {
            live = "liveSeeds=\(quantities.seeds) liveWheat=\(quantities.wheat)"
        } else {
            live = "liveSeeds=unavailable liveWheat=unavailable"
        }
        return success(
            "Agriculture gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 13 : 12) plots=\(snapshot.plots.count) "
                + "actions=\(snapshot.totalActionCount) cycles=\(snapshot.completedCycleCount) "
                + "reservations=\(snapshot.reservations.count) "
                + "historicalSurplus=\(snapshot.managedSurplusRecords.count) \(live) "
                + "digest=\(snapshot.digest)."
        )
    }

    private func traceAgricultureState(
        _ session: AgentSimulationSession,
        reason: String
    ) {
        let snapshot = session.agricultureSnapshot()
        trace(
            "agriculture state tick=\(session.tick) reason=\(reason) "
                + "enabled=\(snapshot.enabled ? 1 : 0) schema=\(snapshot.enabled ? 13 : 12) "
                + "plots=\(snapshot.plots.count) actions=\(snapshot.totalActionCount) "
                + "cycles=\(snapshot.completedCycleCount) reservations=\(snapshot.reservations.count) "
                + "surplusRecords=\(snapshot.managedSurplusRecords.count) "
                + "digest=\(snapshot.digest) worldMutation=none materialMutation=none"
        )
    }

    private func agricultureContainerCoordinates(
        _ locationID: String
    ) -> (x: Int, y: Int, z: Int)? {
        guard locationID.hasPrefix("container:") else { return nil }
        let values = locationID.dropFirst("container:".count).split(separator: ",")
        guard values.count == 3, let x = Int(values[0]), let y = Int(values[1]),
              let z = Int(values[2]) else { return nil }
        return (x, y, z)
    }

    private func handleAgricultureProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let proofGates = agricultureGateDependencies() + [
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = proofGates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Agriculture proof refused; missing gates: " + missing.joined(separator: ", ")
            )
        }
        guard replayRecorder == nil else {
            return failure("Agriculture proof requires replay recording to be inactive.")
        }
        guard var candidate = session, activeWorld === world,
              candidate.agricultureEnabled,
              candidate.agricultureSnapshot().plots.isEmpty else {
            return failure("Agriculture proof requires fresh active agriculture state.")
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled,
              !economyAutoEnabled else {
            return failure(
                "Agriculture proof requires pause, movement off, and auto modes off."
            )
        }
        let actorID = AgentID(rawValue: "agent_0")!
        guard let probe = probesByAgentId[actorID.rawValue], probe.world === world,
              !probe.dead, probe.carriedItems.allSatisfy({ $0 == nil }) else {
            return failure("Agriculture proof requires empty live agent_0 custody.")
        }
        guard cleanupAgricultureProofFixture(world: world),
              let fixture = prepareAgricultureProofFixture(
                world: world, actorID: actorID.rawValue, probe: probe
              ) else {
            return failure("Agriculture proof could not prepare a bounded loaded fixture.")
        }
        agricultureProofFixture = fixture
        do {
            let embodiment = PebbleAgentEmbodiment(probe: probe)
            let sessionBefore = candidate.snapshot()
            let campBefore = sessionBefore.campStock
            let resourcesBefore = sessionBefore.agents.map { ($0.id, $0.resourceInventory) }
            let cultivationBefore = candidate.practiceUnits(
                agentID: actorID, domain: .cultivation
            )
            let entityIDsBefore = world.entities.map(\.id).sorted()
            var recorder: AgentReplayRecorder?

            // Negative preconditions: neither a missing hoe nor an incompatible
            // planting item can fall through to a direct World mutation.
            probe.carriedItems[1] = ItemStack(iid("carrot"), 1)
            ecologicalObservationSensor.invalidate(world: world)
            _ = try recordLiveEcologicalObservation(
                world: world, observerID: actorID,
                session: &candidate, recorder: &recorder
            )
            probe.carriedItems[1] = ItemStack(iid("wheat_seeds"), 4)
            probe.carriedItems[0] = ItemStack(iid("iron_hoe"), 1)
            guard try prepareLiveAgriculturalPlanIfEligible(
                world: world, session: &candidate, recorder: &recorder
            ), let plot = candidate.agricultureSnapshot().plots.first,
                  plot.cells.map(\.position) == fixture.productiveCells.sorted(
                    by: agricultureLivePositionSort
                  ) else {
                throw PebbleAgentAgricultureProofError.failed("autonomous site selection")
            }
            let plotID = plot.plotID
            let missingToolIntent = AgentAgriculturalIntent(
                plotID: plotID, cellIndex: 0, actorID: actorID,
                kind: .till, position: plot.cells[0].position
            )
            probe.carriedItems[0] = nil
            let missingToolBefore = world.getBlock(
                missingToolIntent.position.x,
                missingToolIntent.position.y,
                missingToolIntent.position.z
            )
            var missingToolRefused = false
            do {
                _ = try agricultureExecutor.till(
                    world: world, actor: embodiment, intent: missingToolIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: [],
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("missing-tool"),
                    publishAndVerify: { _ in
                        throw ControllerError.agricultureBoundary("unexpected publication")
                    }
                )
            } catch PebbleAgentAgricultureExecutor.ExecutionError.missingHoe {
                missingToolRefused = true
            }
            try requireAgricultureProof(
                missingToolRefused && world.getBlock(
                    missingToolIntent.position.x,
                    missingToolIntent.position.y,
                    missingToolIntent.position.z
                ) == missingToolBefore,
                "missing tool refusal"
            )
            probe.carriedItems[0] = ItemStack(iid("iron_hoe"), 1)

            let wrongSeedIntent = AgentAgriculturalIntent(
                plotID: plotID, cellIndex: 0, actorID: actorID,
                kind: .plant, position: plot.cells[0].position
            )
            probe.carriedItems[1] = ItemStack(iid("carrot"), 1)
            var wrongSeedRefused = false
            do {
                _ = try agricultureExecutor.plant(
                    world: world, actor: embodiment, intent: wrongSeedIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: [],
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("wrong-seed"),
                    publishAndVerify: { _ in
                        throw ControllerError.agricultureBoundary("unexpected publication")
                    }
                )
            } catch PebbleAgentAgricultureExecutor.ExecutionError.missingSeeds {
                wrongSeedRefused = true
            }
            try requireAgricultureProof(wrongSeedRefused, "wrong seed refusal")
            probe.carriedItems[1] = ItemStack(iid("wheat_seeds"), 5)

            let negativeTill = fixture.negativeTillCell
            try navigateAgricultureActor(
                world: world, embodiment: embodiment,
                destination: AgentPosition(
                    x: negativeTill.x + 1, y: negativeTill.y + 1, z: negativeTill.z
                )
            )
            let tillTarget = PhysicalBlockPosition(
                x: negativeTill.x, y: negativeTill.y, z: negativeTill.z
            )
            let tillBinding = try requireAgricultureValue(
                materialCustodyGateway.toolBinding(actor: embodiment, slot: 0, world: world),
                "hoe binding"
            )
            let staleTillRequest = PebbleAgentBlockTillingRequest(
                actorID: actorID.rawValue, target: tillTarget,
                expectedCell: Int(cell(B.dirt)), heldItem: tillBinding.heldItem
            )
            _ = world.setBlock(
                tillTarget.x, tillTarget.y, tillTarget.z, Int(cell(B.stone)), SET_SILENT
            )
            let staleTill = physicalActionGateway.tillBlock(
                world: world, actor: embodiment, request: staleTillRequest,
                toolState: tillBinding.toolState, occupiedPositions: []
            )
            _ = world.setBlock(
                tillTarget.x, tillTarget.y, tillTarget.z, Int(cell(B.dirt)), SET_SILENT
            )
            let hoeBeforeLateTill = probe.carriedItems[0]?.copy()
            let lateTill = physicalActionGateway.tillBlock(
                world: world, actor: embodiment,
                request: PebbleAgentBlockTillingRequest(
                    actorID: actorID.rawValue, target: tillTarget,
                    expectedCell: Int(cell(B.dirt)), heldItem: tillBinding.heldItem
                ),
                toolState: tillBinding.toolState, occupiedPositions: [],
                verifyAfterMutation: { false }
            )
            try requireAgricultureProof(
                staleTill.status == .staleTarget
                    && lateTill.status == .verificationFailure
                    && world.getBlock(tillTarget.x, tillTarget.y, tillTarget.z)
                        == Int(cell(B.dirt))
                    && probe.carriedItems[0] == hoeBeforeLateTill,
                "stale and late till rollback"
            )

            let negativePlant = fixture.negativePlantCell
            let plantWork = AgentPosition(
                x: negativePlant.x + 1, y: negativePlant.y + 1, z: negativePlant.z
            )
            try navigateAgricultureActor(
                world: world, embodiment: embodiment, destination: plantWork
            )
            _ = world.setBlock(
                negativePlant.x, negativePlant.y, negativePlant.z,
                Int(cell(B.farmland, 7)), SET_SILENT
            )
            let negativePlantIntent = AgentAgriculturalIntent(
                plotID: plotID, cellIndex: 0, actorID: actorID, kind: .plant,
                position: negativePlant
            )
            let seedCountBeforeLatePlant = agricultureItemCount(
                "wheat_seeds", in: probe.carriedItems
            )
            var latePlantRejected = false
            do {
                _ = try agricultureExecutor.plant(
                    world: world, actor: embodiment, intent: negativePlantIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: [],
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("late-plant"),
                    publishAndVerify: { _ in
                        throw ControllerError.agricultureBoundary("injected late plant")
                    }
                )
            } catch ControllerError.agricultureBoundary {
                latePlantRejected = true
            }
            let negativeCrop = PhysicalBlockPosition(
                x: negativePlant.x, y: negativePlant.y + 1, z: negativePlant.z
            )
            let placement = try requireAgricultureValue(
                materialCustodyGateway.placementBinding(
                    actor: embodiment, requiredBlockID: Int(B.wheat)
                ),
                "planting binding"
            )
            let staleHit = RaycastHit(
                x: negativePlant.x, y: negativePlant.y, z: negativePlant.z,
                face: 1, cell: Int(cell(B.farmland, 7)), t: 0,
                px: Double(negativePlant.x) + 0.5,
                py: Double(negativePlant.y) + 0.5,
                pz: Double(negativePlant.z) + 0.5
            )
            _ = world.setBlock(
                negativeCrop.x, negativeCrop.y, negativeCrop.z,
                Int(cell(B.stone)), SET_SILENT
            )
            let stalePlant = physicalActionGateway.placeBlock(
                world: world, actor: embodiment,
                request: PebbleAgentBlockPlacementRequest(
                    actorID: actorID.rawValue, hit: staleHit, target: negativeCrop,
                    expectedCell: 0, blockID: Int(B.wheat),
                    heldItem: placement.heldItem,
                    orientation: BlockPlacementOrientation(yaw: embodiment.yaw, pitch: embodiment.pitch)
                ),
                custody: placement.custody, occupiedPositions: []
            )
            _ = world.setBlock(
                negativeCrop.x, negativeCrop.y, negativeCrop.z, 0, SET_SILENT
            )
            try requireAgricultureProof(
                latePlantRejected && stalePlant.status == .staleTarget
                    && agricultureItemCount("wheat_seeds", in: probe.carriedItems)
                        == seedCountBeforeLatePlant
                    && world.getBlock(negativeCrop.x, negativeCrop.y, negativeCrop.z) == 0,
                "late and stale plant rollback"
            )
            probe.carriedItems[1] = ItemStack(iid("wheat_seeds"), 4)

            let negativeHarvest = fixture.negativeHarvestCell
            try navigateAgricultureActor(
                world: world, embodiment: embodiment,
                destination: AgentPosition(
                    x: negativeHarvest.x + 1,
                    y: negativeHarvest.y + 1,
                    z: negativeHarvest.z
                )
            )
            _ = world.setBlock(
                negativeHarvest.x, negativeHarvest.y, negativeHarvest.z,
                Int(cell(B.farmland, 7)), SET_SILENT
            )
            _ = world.setBlock(
                negativeHarvest.x, negativeHarvest.y + 1, negativeHarvest.z,
                Int(cell(B.wheat, 7)), SET_SILENT
            )
            let negativeHarvestIntent = AgentAgriculturalIntent(
                plotID: plotID, cellIndex: 0, actorID: actorID, kind: .harvest,
                position: negativeHarvest
            )
            let inventoryBeforeLateHarvest = copyItemInventory(probe.carriedItems)
            var lateHarvestRejected = false
            do {
                _ = try agricultureExecutor.harvest(
                    world: world, actor: embodiment, intent: negativeHarvestIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: [],
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("late-harvest"),
                    publishAndVerify: { _ in
                        throw ControllerError.agricultureBoundary("injected late harvest")
                    }
                )
            } catch ControllerError.agricultureBoundary {
                lateHarvestRejected = true
            }
            let harvestTarget = PhysicalBlockPosition(
                x: negativeHarvest.x, y: negativeHarvest.y + 1, z: negativeHarvest.z
            )
            let staleHarvestRequest = PebbleAgentBlockBreakRequest(
                actorID: actorID.rawValue, target: harvestTarget,
                expectedCell: Int(cell(B.wheat, 7)), heldItem: nil, isCreative: false
            )
            _ = world.setBlock(
                harvestTarget.x, harvestTarget.y, harvestTarget.z,
                Int(cell(B.wheat, 6)), SET_SILENT
            )
            let staleHarvest = physicalActionGateway.breakBlock(
                world: world, actor: embodiment, request: staleHarvestRequest,
                occupiedPositions: [], acquireDrops: { _ in true }
            )
            _ = world.setBlock(
                harvestTarget.x, harvestTarget.y, harvestTarget.z,
                Int(cell(B.wheat, 7)), SET_SILENT
            )
            let beforeFullCustody = copyItemInventory(probe.carriedItems)
            probe.carriedItems = Array(
                repeating: ItemStack(iid("stone"), 64),
                count: LabCoreAgentEntity.carriedItemSlotCount
            )
            let fullCustodyHarvest = physicalActionGateway.breakBlock(
                world: world, actor: embodiment,
                request: PebbleAgentBlockBreakRequest(
                    actorID: actorID.rawValue, target: harvestTarget,
                    expectedCell: Int(cell(B.wheat, 7)), heldItem: nil, isCreative: false
                ),
                occupiedPositions: [],
                acquireDrops: { ids in
                    guard let source = PebbleAgentItemEntityCustodyEndpoint(
                        spawnedItemEntityIDs: ids, world: world
                    ), let fingerprint = try? self.materialCustodyGateway.fingerprint(
                        .liveAgent(embodiment, in: world)
                    ) else { return false }
                    return self.materialCustodyGateway.acquireItemEntities(
                        PebbleAgentItemEntityAcquisitionRequest(
                            transactionID: "agriculture-full-custody",
                            spawnedItemEntityIDs: ids,
                            expectedDestinationFingerprint: fingerprint
                        ),
                        from: source, to: .liveAgent(embodiment, in: world)
                    ).succeeded
                }
            )
            probe.carriedItems = beforeFullCustody
            try requireAgricultureProof(
                lateHarvestRejected && staleHarvest.status == .staleTarget
                    && fullCustodyHarvest.status == .verificationFailure
                    && world.getBlock(harvestTarget.x, harvestTarget.y, harvestTarget.z)
                        == Int(cell(B.wheat, 7))
                    && probe.carriedItems == inventoryBeforeLateHarvest
                    && world.entities.map(\.id).sorted() == entityIDsBefore,
                "late stale and full-custody harvest rollback"
            )
            _ = world.setBlock(
                harvestTarget.x, harvestTarget.y, harvestTarget.z, 0, SET_SILENT
            )

            // Full four-cell product cycle.
            var duplicateRefused = false
            for cell in plot.cells.sorted(by: { $0.index < $1.index }) {
                let reservation = try candidate.reserveAgriculturalCell(
                    plotID: plotID, cellIndex: cell.index,
                    contenders: cell.index == 0
                        ? [AgentID(rawValue: "agent_1")!, actorID] : [actorID]
                )
                try requireAgricultureProof(
                    reservation.agentID == actorID, "deterministic reservation"
                )
                try navigateAgricultureActor(
                    world: world, embodiment: embodiment,
                    destination: agricultureWorkPosition(for: cell.position)
                )
                let tillIntent = try requireAgricultureValue(
                    candidate.nextAgriculturalIntent(for: actorID), "till intent"
                )
                let tilled = try agricultureExecutor.till(
                    world: world, actor: embodiment, intent: tillIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: agricultureOccupiedPositions(),
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("till-\(cell.index)"),
                    publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
                )
                if cell.index == 0 {
                    let digestBeforeDuplicate = candidate.agricultureSnapshot().digest
                    do {
                        _ = try candidate.recordAgriculturalActionSuccess(tilled.action.outcome)
                    } catch AgentSessionError.agriculture(.duplicateAction) {
                        duplicateRefused = candidate.agricultureSnapshot().digest
                            == digestBeforeDuplicate
                    }
                }
                let plantIntent = try requireAgricultureValue(
                    candidate.nextAgriculturalIntent(for: actorID), "plant intent"
                )
                _ = try agricultureExecutor.plant(
                    world: world, actor: embodiment, intent: plantIntent,
                    civilDate: candidate.civilDate()!, occupiedPositions: agricultureOccupiedPositions(),
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("plant-\(cell.index)"),
                    publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
                )
            }
            let immatureWait = candidate.nextAgriculturalIntent(for: actorID) == nil
            let practiceAfterPlant = candidate.practiceUnits(
                agentID: actorID, domain: .cultivation
            )
            var growthCalls = 0
            for position in fixture.productiveCells {
                randomTickHandlers[Int(B.farmland)]?(
                    world, position.x, position.y, position.z,
                    world.getBlock(position.x, position.y, position.z)
                )
                while world.getBlock(position.x, position.y + 1, position.z) & 7 < 7,
                      growthCalls < 4_096 {
                    randomTickHandlers[Int(B.wheat)]?(
                        world, position.x, position.y + 1, position.z,
                        world.getBlock(position.x, position.y + 1, position.z)
                    )
                    growthCalls += 1
                }
            }
            try requireAgricultureProof(
                fixture.productiveCells.allSatisfy {
                    world.getBlock($0.x, $0.y, $0.z) >> 4 == Int(B.farmland)
                        && world.getBlock($0.x, $0.y, $0.z) & 7 == 7
                        && world.getBlock($0.x, $0.y + 1, $0.z)
                            == Int(cell(B.wheat, 7))
                },
                "canonical random-tick growth"
            )
            let practiceAfterGrowth = candidate.practiceUnits(
                agentID: actorID, domain: .cultivation
            )
            ecologicalObservationSensor.invalidate(world: world)
            _ = try recordLiveEcologicalObservation(
                world: world, observerID: actorID,
                session: &candidate, recorder: &recorder
            )
            let maturityRecord = try requireAgricultureValue(
                candidate.ecologicalObservations(for: actorID).first,
                "maturity observation"
            )
            for cell in plot.cells.sorted(by: { $0.index < $1.index }) {
                let crop = try requireAgricultureValue(
                    maturityRecord.observation.crops.first {
                        $0.position == AgentPosition(
                            x: cell.position.x,
                            y: cell.position.y + 1,
                            z: cell.position.z
                        ) && $0.mature
                    },
                    "observed mature crop"
                )
                _ = try agricultureExecutor.observeMaturity(
                    world: world,
                    intent: AgentAgriculturalIntent(
                        plotID: plotID, cellIndex: cell.index, actorID: actorID,
                        kind: .maturityObserved, position: cell.position
                    ),
                    observationEventID: maturityRecord.causalEventID,
                    observedCrop: crop, civilDate: candidate.civilDate()!,
                    actionID: agricultureActionID("mature-\(cell.index)"),
                    publish: { try candidate.recordAgriculturalActionSuccess($0) }
                )
            }
            resetGameRng(46)
            for cell in plot.cells.sorted(by: { $0.index < $1.index }) {
                try navigateAgricultureActor(
                    world: world, embodiment: embodiment,
                    destination: agricultureWorkPosition(for: cell.position)
                )
                let intent = try requireAgricultureValue(
                    candidate.nextAgriculturalIntent(for: actorID), "harvest intent"
                )
                _ = try agricultureExecutor.harvest(
                    world: world, actor: embodiment, intent: intent,
                    civilDate: candidate.civilDate()!, occupiedPositions: agricultureOccupiedPositions(),
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("harvest-\(cell.index)"),
                    publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
                )
            }

            // Real capacity and late-failure checks precede the successful
            // atomic batch deposit into the same physical container.
            let sourceEndpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                embodiment, in: world
            )
            let containerEndpoint = PebbleAgentMaterialCustodyEndpoint.container(
                fixture.container, in: world
            )
            let oneAgriculturalStack = try requireAgricultureValue(
                materialCustodyGateway.inspect(sourceEndpoint).slots.compactMap { $0 }.first {
                    $0.identity.itemKey == "wheat_seeds"
                }.map {
                    AgentMaterialStackSnapshot(identity: $0.identity, count: 1)
                },
                "harvested seed"
            )
            fixture.container.items = Array(
                repeating: ItemStack(iid("stone"), 64), count: 27
            )
            let fullSourceBefore = try materialCustodyGateway.fingerprint(sourceEndpoint)
            let fullDestinationBefore = try materialCustodyGateway.fingerprint(containerEndpoint)
            let fullStorage = materialCustodyGateway.transferBatch(
                PebbleAgentMaterialBatchTransactionRequest(
                    transactionID: "agriculture-storage-full",
                    materials: [oneAgriculturalStack],
                    expectedSourceFingerprint: fullSourceBefore,
                    expectedDestinationFingerprint: fullDestinationBefore
                ),
                from: sourceEndpoint, to: containerEndpoint
            )
            fixture.container.items = Array(repeating: nil, count: 27)
            let lateSourceBefore = try materialCustodyGateway.fingerprint(sourceEndpoint)
            let lateDestinationBefore = try materialCustodyGateway.fingerprint(containerEndpoint)
            let lateStorage = materialCustodyGateway.transferBatch(
                PebbleAgentMaterialBatchTransactionRequest(
                    transactionID: "agriculture-storage-late",
                    materials: [oneAgriculturalStack],
                    expectedSourceFingerprint: lateSourceBefore,
                    expectedDestinationFingerprint: lateDestinationBefore
                ),
                from: sourceEndpoint, to: containerEndpoint,
                verifyAfterMutation: { false }
            )
            let lateSourceAfter = try materialCustodyGateway.fingerprint(sourceEndpoint)
            let lateDestinationAfter = try materialCustodyGateway.fingerprint(containerEndpoint)
            try requireAgricultureProof(
                fullStorage.status == .destinationFull
                    && lateStorage.status == .verificationFailure
                    && lateSourceAfter == lateSourceBefore
                    && lateDestinationAfter == lateDestinationBefore,
                "storage capacity and late rollback"
            )
            try navigateAgricultureActor(
                world: world, embodiment: embodiment,
                destination: AgentPosition(
                    x: fixture.containerPosition.x - 1,
                    y: fixture.containerPosition.y,
                    z: fixture.containerPosition.z
                )
            )
            let storeIntent = try requireAgricultureValue(
                candidate.nextAgriculturalIntent(for: actorID), "storage intent"
            )
            _ = try agricultureExecutor.storeHarvest(
                world: world, actor: embodiment, intent: storeIntent,
                container: fixture.container, civilDate: candidate.civilDate()!,
                seedReserveTarget: fixture.productiveCells.count,
                materialGateway: materialCustodyGateway,
                actionID: agricultureActionID("store"),
                publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
            )
            let stored = try agricultureExecutor.liveSurplus(
                container: fixture.container, world: world,
                materialGateway: materialCustodyGateway
            )
            try requireAgricultureProof(
                stored.seeds >= fixture.productiveCells.count
                    && stored.wheat == fixture.productiveCells.count,
                "physical seed reserve and wheat surplus"
            )

            // Consume part of the physical reserve through the custody gateway
            // for a second real plot, leaving planted/mature crops visible.
            let storedSnapshot = try materialCustodyGateway.inspect(containerEndpoint)
            let storedSeeds = try requireAgricultureValue(
                storedSnapshot.slots.compactMap { $0 }.first {
                    $0.identity.itemKey == "wheat_seeds"
                },
                "stored seed reserve"
            )
            let withdrawal = materialCustodyGateway.transfer(
                PebbleAgentMaterialTransactionRequest(
                    transactionID: "agriculture-reserve-replant",
                    material: AgentMaterialStackSnapshot(
                        identity: storedSeeds.identity,
                        count: fixture.displayCells.count
                    ),
                    expectedSourceFingerprint: try materialCustodyGateway.fingerprint(
                        containerEndpoint
                    ),
                    expectedDestinationFingerprint: try materialCustodyGateway.fingerprint(
                        sourceEndpoint
                    )
                ),
                from: containerEndpoint, to: sourceEndpoint
            )
            try requireAgricultureProof(withdrawal.succeeded, "physical reserve withdrawal")
            let afterWithdrawal = try agricultureExecutor.liveSurplus(
                container: fixture.container, world: world,
                materialGateway: materialCustodyGateway
            )
            ecologicalObservationSensor.invalidate(world: world)
            _ = try recordLiveEcologicalObservation(
                world: world, observerID: actorID,
                session: &candidate, recorder: &recorder
            )
            let displayObservation = try requireAgricultureValue(
                candidate.ecologicalObservations(for: actorID).first,
                "display plot observation"
            )
            let displayPlotID = try candidate.planAgriculturalPlot(
                plannerID: actorID,
                positions: fixture.displayCells,
                sourceObservationEventID: displayObservation.causalEventID,
                designatedStorageLocationID: "container:\(fixture.containerPosition.x),"
                    + "\(fixture.containerPosition.y),\(fixture.containerPosition.z)"
            )
            let displayPlot = try requireAgricultureValue(
                candidate.agricultureSnapshot().plots.first { $0.plotID == displayPlotID },
                "display plot"
            )
            for cell in displayPlot.cells.sorted(by: { $0.index < $1.index }) {
                _ = try candidate.reserveAgriculturalCell(
                    plotID: displayPlotID, cellIndex: cell.index, contenders: [actorID]
                )
                try navigateAgricultureActor(
                    world: world, embodiment: embodiment,
                    destination: AgentPosition(
                        x: cell.position.x - 1,
                        y: cell.position.y + 1,
                        z: cell.position.z
                    )
                )
                _ = try agricultureExecutor.till(
                    world: world, actor: embodiment,
                    intent: try requireAgricultureValue(
                        candidate.nextAgriculturalIntent(for: actorID), "display till"
                    ),
                    civilDate: candidate.civilDate()!, occupiedPositions: agricultureOccupiedPositions(),
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("display-till-\(cell.index)"),
                    publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
                )
                _ = try agricultureExecutor.plant(
                    world: world, actor: embodiment,
                    intent: try requireAgricultureValue(
                        candidate.nextAgriculturalIntent(for: actorID), "display plant"
                    ),
                    civilDate: candidate.civilDate()!, occupiedPositions: agricultureOccupiedPositions(),
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    actionID: agricultureActionID("display-plant-\(cell.index)"),
                    publishAndVerify: { try candidate.recordAgriculturalActionSuccess($0) }
                )
            }
            for (offset, position) in fixture.displayCells.enumerated() {
                randomTickHandlers[Int(B.farmland)]?(
                    world, position.x, position.y, position.z,
                    world.getBlock(position.x, position.y, position.z)
                )
                let targetStage = offset == 1 ? 3 : offset == 2 ? 7 : 0
                var localCalls = 0
                while world.getBlock(position.x, position.y + 1, position.z) & 7
                        < targetStage,
                      localCalls < 512 {
                    randomTickHandlers[Int(B.wheat)]?(
                        world, position.x, position.y + 1, position.z,
                        world.getBlock(position.x, position.y + 1, position.z)
                    )
                    localCalls += 1
                    growthCalls += 1
                }
            }
            let tampered = fixture.displayCells[0]
            let tamperedBefore = world.getBlock(tampered.x, tampered.y + 1, tampered.z)
            _ = world.setBlock(tampered.x, tampered.y + 1, tampered.z, 0, SET_SILENT)
            ecologicalObservationSensor.invalidate(world: world)
            _ = try recordLiveEcologicalObservation(
                world: world, observerID: actorID,
                session: &candidate, recorder: &recorder
            )
            let tamperObservation = try requireAgricultureValue(
                candidate.ecologicalObservations(for: actorID).first,
                "tamper observation"
            )
            _ = try candidate.recordAgriculturalActionSuccess(
                AgentAgriculturalActionOutcome(
                    actionID: agricultureActionID("external-tamper"),
                    kind: .reconcile, actorID: actorID, plotID: displayPlotID,
                    cellIndex: 0, position: tampered,
                    beforeFingerprint: tamperedBefore, afterFingerprint: 0,
                    sourceObservationEventID: tamperObservation.causalEventID,
                    civilDate: candidate.civilDate()!
                )
            )
            let current = try agricultureExecutor.liveSurplus(
                container: fixture.container, world: world,
                materialGateway: materialCustodyGateway
            )
            let resourcesAfter = candidate.snapshot().agents.map {
                ($0.id, $0.resourceInventory)
            }
            let cultivationAfter = candidate.practiceUnits(
                agentID: actorID, domain: .cultivation
            )
            let visibleCrops = fixture.displayCells.filter {
                world.getBlock($0.x, $0.y + 1, $0.z) >> 4 == Int(B.wheat)
            }.count
            try requireAgricultureProof(
                duplicateRefused && immatureWait
                    && practiceAfterGrowth == practiceAfterPlant
                    && cultivationAfter - cultivationBefore == 18
                    && candidate.snapshot().campStock == campBefore
                    && resourcesAfter.elementsEqual(resourcesBefore, by: {
                        $0.0 == $1.0 && $0.1 == $1.1
                    })
                    && afterWithdrawal.seeds == stored.seeds - fixture.displayCells.count
                    && current.seeds == afterWithdrawal.seeds
                    && current.wheat == stored.wheat
                    && visibleCrops == 2
                    && candidate.agricultureSnapshot().completedCycleCount == 1,
                "final agriculture invariants"
            )
            session = candidate
            replayRecorder = recorder
            trace(
                "agriculture proof actor=agent_0 authority=PebbleCore crop=wheat "
                    + "observation=CIV21 site=real soil=real water=real plan=4cells "
                    + "navigation=findPath+Entity.move reach=physical hoe=iron_hoe "
                    + "till=canonical plant=registry seedsConsumed=4 growth=randomTicks "
                    + "growthCalls=\(growthCalls) stage=0>7 hydration=water mature=CIV21 "
                    + "harvest=canonical drops=exact custody=real wheat=\(stored.wheat) "
                    + "seedReserve=\(stored.seeds) container=real "
                    + "liveSeedsAfterReplant=\(current.seeds) liveWheat=\(current.wheat) "
                    + "surplus=physical historicalRecord=nonspendable externalRemoval=reflected "
                    + "multiAgentWinner=agent_0 duplicate=refused immature=wait "
                    + "staleTill=refused stalePlant=refused staleHarvest=refused "
                    + "lateTill=rollback latePlant=rollback lateHarvest=rollback "
                    + "fullCustody=rollback fullStorage=rollback tamper=reconciled "
                    + "practice=18 waitingPractice=0 observationPractice=0 "
                    + "campStockDelta=0 resourceInventoryDelta=0 civilSeasonGrowthEffect=0 "
                    + "displayCrops=2 fixture=retainedForCapture cleanup=deferred "
                    + "schema=13 cycle=complete digest=\(candidate.agricultureSnapshot().digest)"
            )
            traceAgricultureState(candidate, reason: "proof")
            return success(
                "Agriculture proof passed: real four-cell wheat cycle, physical reserve, "
                    + "container surplus, and two visible crops retained for capture."
            )
        } catch {
            let cleanup = cleanupAgricultureProofFixture(world: world)
            return failure(
                "Agriculture proof failed: \(error); cleanup=\(cleanup ? "exact" : "failed")."
            )
        }
    }

    private func prepareAgricultureProofFixture(
        world: World,
        actorID: String,
        probe: LabCoreAgentEntity
    ) -> PebbleAgentAgricultureProofFixture? {
        let origin = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        let soilY = origin.y - 1
        let productive = (-4 ... -1).map {
            AgentPosition(x: origin.x, y: soilY, z: origin.z + $0)
        }.sorted(by: agricultureLivePositionSort)
        let display = (-1 ... 1).map {
            AgentPosition(x: origin.x + 3, y: soilY, z: origin.z + $0)
        }.sorted(by: agricultureLivePositionSort)
        let water = PhysicalBlockPosition(
            x: origin.x + 1, y: soilY, z: origin.z - 2
        )
        let containerPosition = PhysicalBlockPosition(
            x: origin.x + 3, y: origin.y, z: origin.z - 2
        )
        let negativeTill = AgentPosition(x: origin.x - 1, y: soilY, z: origin.z - 2)
        let negativePlant = AgentPosition(x: origin.x - 1, y: soilY, z: origin.z - 3)
        let negativeHarvest = AgentPosition(x: origin.x - 1, y: soilY, z: origin.z - 4)
        var originals: [PebbleAgentAgricultureProofFixture.OriginalCell] = []
        for x in (origin.x - 4)...(origin.x + 4) {
            for z in (origin.z - 4)...(origin.z + 4) {
                for y in (soilY - 1)...(origin.y + 1) {
                    guard world.isChunkReady(x >> 4, z >> 4),
                          world.getBlockEntity(x, y, z) == nil else { return nil }
                    originals.append(.init(
                        position: PhysicalBlockPosition(x: x, y: y, z: z),
                        cell: world.getBlock(x, y, z)
                    ))
                }
            }
        }
        let cropPositions = productive + display
        let sky = cropPositions.compactMap { position
            -> PebbleAgentAgricultureProofFixture.OriginalSkyLight? in
            guard let chunk = world.getChunkAt(position.x, position.z) else { return nil }
            return .init(
                position: PhysicalBlockPosition(
                    x: position.x, y: position.y + 1, z: position.z
                ),
                value: chunk.getSky(
                    posMod(position.x, CHUNK_W), position.y + 1,
                    posMod(position.z, CHUNK_W)
                )
            )
        }
        guard sky.count == cropPositions.count else { return nil }
        for original in originals {
            let position = original.position
            let prepared: Int
            if position.y == soilY - 1 || position.y == soilY {
                prepared = Int(cell(B.stone))
            } else {
                prepared = 0
            }
            _ = world.setBlock(position.x, position.y, position.z, prepared, SET_SILENT)
        }
        for position in productive + display {
            _ = world.setBlock(position.x, position.y, position.z, Int(cell(B.dirt)), SET_SILENT)
        }
        _ = world.setBlock(water.x, water.y, water.z, Int(cell(B.water, 0)), SET_SILENT)
        _ = world.setBlock(
            containerPosition.x, containerPosition.y, containerPosition.z,
            Int(cell(B.chest)), SET_SILENT
        )
        let container = makeContainerBE(
            containerPosition.x, containerPosition.y, containerPosition.z, 27
        )
        world.setBlockEntity(container)
        for position in cropPositions {
            world.getChunkAt(position.x, position.z)?.setSky(
                posMod(position.x, CHUNK_W), position.y + 1,
                posMod(position.z, CHUNK_W), 15
            )
        }
        guard world.getBlockEntity(
            containerPosition.x, containerPosition.y, containerPosition.z
        ) === container else { return nil }
        return PebbleAgentAgricultureProofFixture(
            originalCells: originals,
            originalSkyLight: sky,
            originalActorItems: copyItemInventory(probe.carriedItems),
            originalActorPosition: (probe.x, probe.y, probe.z),
            originalActorOrientation: (probe.yaw, probe.pitch),
            entityIDsBefore: world.entities.map(\.id).sorted(),
            actorID: actorID,
            productiveCells: productive,
            displayCells: display,
            water: water,
            containerPosition: containerPosition,
            negativeTillCell: negativeTill,
            negativePlantCell: negativePlant,
            negativeHarvestCell: negativeHarvest,
            container: container
        )
    }

    func cleanupAgricultureProofFixture(world: World) -> Bool {
        guard let fixture = agricultureProofFixture else { return true }
        fixture.container.items = Array(repeating: nil, count: 27)
        for entity in world.entities where !fixture.entityIDsBefore.contains(entity.id) {
            world.removeEntity(entity)
        }
        for original in fixture.originalCells.reversed() {
            _ = world.setBlock(
                original.position.x, original.position.y, original.position.z,
                original.cell, SET_SILENT
            )
        }
        for original in fixture.originalSkyLight {
            world.getChunkAt(original.position.x, original.position.z)?.setSky(
                posMod(original.position.x, CHUNK_W), original.position.y,
                posMod(original.position.z, CHUNK_W), original.value
            )
        }
        if let actor = probesByAgentId[fixture.actorID], actor.world === world, !actor.dead {
            actor.carriedItems = copyItemInventory(fixture.originalActorItems)
            actor.setPos(
                fixture.originalActorPosition.x,
                fixture.originalActorPosition.y,
                fixture.originalActorPosition.z
            )
            actor.yaw = fixture.originalActorOrientation.yaw
            actor.pitch = fixture.originalActorOrientation.pitch
            actor.prevX = actor.x
            actor.prevY = actor.y
            actor.prevZ = actor.z
        }
        let restored = fixture.originalCells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.cell
                && world.getBlockEntity($0.position.x, $0.position.y, $0.position.z) == nil
        } && world.entities.map(\.id).sorted() == fixture.entityIDsBefore
            && probesByAgentId[fixture.actorID]?.carriedItems == fixture.originalActorItems
        if restored { agricultureProofFixture = nil }
        return restored
    }

    private func navigateAgricultureActor(
        world: World,
        embodiment: PebbleAgentEmbodiment,
        destination: AgentPosition
    ) throws {
        let occupied = Set(probesByAgentId.values.filter {
            $0 !== embodiment.probe && !$0.dead && $0.world === world
        }.map {
            AgentPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        })
        for _ in 0..<32 {
            if embodiment.position == destination { return }
            guard let path = findPath(
                world, embodiment.x, embodiment.y, embodiment.z,
                Double(destination.x) + 0.5, Double(destination.y),
                Double(destination.z) + 0.5, 600, true
            ), let node = path.first else {
                throw PebbleAgentAgricultureProofError.failed("Core navigation unavailable")
            }
            let next = AgentPosition(x: node.x, y: node.y, z: node.z)
            guard !occupied.contains(next) else {
                throw PebbleAgentAgricultureProofError.failed("dynamic obstacle")
            }
            let before = embodiment.position
            embodiment.probe.yaw = detAtan2(
                -(Double(next.x) + 0.5 - embodiment.x),
                Double(next.z) + 0.5 - embodiment.z
            )
            embodiment.probe.move(
                Double(next.x) + 0.5 - embodiment.x,
                Double(next.y) - embodiment.y,
                Double(next.z) + 0.5 - embodiment.z
            )
            guard embodiment.position == next, embodiment.position != before else {
                throw PebbleAgentAgricultureProofError.failed("Core movement collision")
            }
        }
        throw PebbleAgentAgricultureProofError.failed("navigation bound")
    }

    private func agricultureWorkPosition(for soil: AgentPosition) -> AgentPosition {
        AgentPosition(x: soil.x - 1, y: soil.y + 1, z: soil.z)
    }

    private func agricultureOccupiedPositions() -> [PhysicalBlockPosition] {
        probesByAgentId.values.filter { !$0.dead }.map {
            PhysicalBlockPosition(
                x: Int($0.x.rounded(.down)),
                y: Int($0.y.rounded(.down)),
                z: Int($0.z.rounded(.down))
            )
        }
    }

    private func agricultureActionID(_ suffix: String) -> AgentAgriculturalActionID {
        AgentAgriculturalActionID(rawValue: "agriculture-live:\(suffix)")!
    }

    private func agricultureItemCount(_ key: String, in slots: [ItemStack?]) -> Int {
        slots.compactMap { $0 }.filter { itemDef($0.id).name == key }
            .reduce(0) { $0 + $1.count }
    }

    private func requireAgricultureProof(
        _ condition: @autoclosure () throws -> Bool,
        _ label: String
    ) throws {
        guard try condition() else { throw PebbleAgentAgricultureProofError.failed(label) }
    }

    private func requireAgricultureValue<T>(_ value: T?, _ label: String) throws -> T {
        guard let value else { throw PebbleAgentAgricultureProofError.failed(label) }
        return value
    }
}

private func agricultureLivePositionSort(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Bool {
    if lhs.x != rhs.x { return lhs.x < rhs.x }
    if lhs.y != rhs.y { return lhs.y < rhs.y }
    return lhs.z < rhs.z
}
