import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentEcologicalObservationProofFixture {
    struct Cell {
        let position: AgentPosition
        let original: Int
    }

    let cells: [Cell]
    let cow: Cow
    let sheep: Sheep
    let entityIDsBefore: [Int]
    let raining: Bool
    let thundering: Bool
    let rainLevel: Double
    let thunderLevel: Double
    let weatherTimer: Int
}

private struct PebbleEcologicalWorldEvidence: Equatable {
    let cells: [Int]
    let entityIDs: [Int]
    let worldTick: Int
    let dayTime: Int
    let raining: Bool
    let thundering: Bool
    let rainLevel: Double
    let thunderLevel: Double
    let chunkCount: Int
}

extension PebbleAgentController {
    func handleEcologicalObservationProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let gates = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            (
                "PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1",
                ecologicalObservationFeatureEnabled
            ),
            (
                "PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
                environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"
            ),
        ]
        let missing = gates.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Ecological observation proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session, activeWorld === world,
              candidate.populationEnabled,
              candidate.ecologicalObservationEnabled else {
            return failure(
                "Ecological observation proof requires population and ecological observation."
            )
        }
        guard isPaused, !movementEnabled, !autoInteractionEnabled,
              !economyAutoEnabled else {
            return failure(
                "Ecological observation proof requires pause, movement off, and auto modes off."
            )
        }
        let observerID = AgentID(rawValue: "agent_0")!
        let otherID = AgentID(rawValue: "agent_1")!
        guard let probe = probesByAgentId[observerID.rawValue],
              probe.world === world, !probe.dead else {
            return failure("Ecological observation proof requires agent_0 embodiment.")
        }
        let origin = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        guard cleanupEcologicalObservationProofFixture(world: world) else {
            return failure("Ecological observation proof prior cleanup failed.")
        }
        guard let fixture = prepareEcologicalObservationProofFixture(
            world: world, origin: origin
        ) else {
            return failure(
                "Ecological observation proof requires a loaded local fixture region."
            )
        }
        ecologicalObservationProofFixture = fixture
        var receiptTransaction =
            PebbleWorldEcologicalObservationReceiptTransaction()
        var receiptTransactionCommitted = false
        defer {
            if !receiptTransactionCommitted {
                try? rollbackWorldEcologicalObservationReceipts(
                    receiptTransaction
                )
            }
        }
        do {
            let materialBefore = candidate.snapshot().agents.map {
                ($0.id, $0.resourceInventory)
            }
            let campBefore = candidate.campStock
            let coarseBefore = candidate.localEcologySnapshot()
            let configuration = candidate.ecologicalObservationSnapshot().configuration!
            let civilDate = candidate.civilDate()!
            var recorder = replayRecorder

            ecologicalObservationSensor.invalidate(world: world, origin: origin, radius: configuration.radius)
            let beforeFirst = ecologicalWorldEvidence(world, fixture: fixture)
            let first = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            let afterFirst = ecologicalWorldEvidence(world, fixture: fixture)
            guard beforeFirst == afterFirst else {
                throw ControllerError.ecologicalObservationBoundary("first scan mutated World")
            }
            try recordScannedEcologicalObservation(
                first,
                world: world,
                session: &candidate,
                recorder: &recorder,
                receiptTransaction: &receiptTransaction
            )

            let beforeCached = ecologicalWorldEvidence(world, fixture: fixture)
            let cached = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            let afterCached = ecologicalWorldEvidence(world, fixture: fixture)
            guard beforeCached == afterCached,
                  cached.diagnostics.cacheHits == 1,
                  cached.diagnostics.worldReads == 0,
                  cached.digest != first.digest else {
                throw ControllerError.ecologicalObservationBoundary("cache proof mismatch")
            }
            guard let firstCowIndex = first.animals.firstIndex(where: {
                $0.speciesKey == "cow"
            }), let firstSheepIndex = first.animals.firstIndex(where: {
                $0.speciesKey == "sheep"
            }), let cachedCowIndex = cached.animals.firstIndex(where: {
                $0.speciesKey == "cow"
            }), let cachedSheepIndex = cached.animals.firstIndex(where: {
                $0.speciesKey == "sheep"
            }), ecologicalObservationSensor.animalEntityID(
                world: world, observation: first, animalIndex: firstCowIndex
            ) == fixture.cow.id,
                  ecologicalObservationSensor.animalEntityID(
                      world: world, observation: first,
                      animalIndex: firstSheepIndex
                  ) == fixture.sheep.id,
                  ecologicalObservationSensor.animalEntityID(
                      world: world, observation: cached, animalIndex: cachedCowIndex
                  ) == fixture.cow.id,
                  ecologicalObservationSensor.animalEntityID(
                      world: world, observation: cached,
                      animalIndex: cachedSheepIndex
                  ) == fixture.sheep.id,
                  firstSheepIndex < firstCowIndex,
                  cachedSheepIndex < cachedCowIndex else {
                throw ControllerError.ecologicalObservationBoundary(
                    "mixed-species animal sidecar order was not exact across cache hit"
                )
            }
            let cowPositionBeforeBindingNegatives = (
                fixture.cow.x, fixture.cow.y, fixture.cow.z
            )
            fixture.cow.setPos(
                fixture.cow.x + 1, fixture.cow.y, fixture.cow.z
            )
            guard ecologicalObservationSensor.animalEntityID(
                world: world, observation: cached, animalIndex: cachedCowIndex
            ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "animal sidecar accepted changed physical position"
                )
            }
            fixture.cow.setPos(
                cowPositionBeforeBindingNegatives.0,
                cowPositionBeforeBindingNegatives.1,
                cowPositionBeforeBindingNegatives.2
            )
            fixture.cow.baby = true
            guard ecologicalObservationSensor.animalEntityID(
                world: world, observation: cached, animalIndex: cachedCowIndex
            ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "animal sidecar accepted changed life stage"
                )
            }
            fixture.cow.baby = false
            fixture.cow.dead = true
            guard ecologicalObservationSensor.animalEntityID(
                world: world, observation: cached, animalIndex: cachedCowIndex
            ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "animal sidecar accepted dead physical identity"
                )
            }
            fixture.cow.dead = false
            let worldTickBeforeBindingNegative = world.time
            world.time = world.time == Int.max ? world.time - 1 : world.time + 1
            guard ecologicalObservationSensor.animalEntityID(
                world: world, observation: cached, animalIndex: cachedCowIndex
            ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "animal sidecar accepted stale physical World tick"
                )
            }
            world.time = worldTickBeforeBindingNegative

            let cropPosition = AgentPosition(x: origin.x + 2, y: origin.y, z: origin.z)
            world.setBlock(
                cropPosition.x, cropPosition.y, cropPosition.z,
                Int(cell(bid("wheat"), 7)), SET_NO_NEIGHBORS
            )
            world.raining = true
            world.thundering = false
            world.rainLevel = 1
            world.thunderLevel = 0
            ecologicalObservationSensor.invalidate(
                world: world, origin: origin, radius: configuration.radius
            )
            guard ecologicalObservationSensor.animalEntityID(
                world: world, observation: cached, animalIndex: cachedCowIndex
            ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "animal sidecar survived explicit invalidation"
                )
            }
            let beforeChanged = ecologicalWorldEvidence(world, fixture: fixture)
            let changed = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            let afterChanged = ecologicalWorldEvidence(world, fixture: fixture)
            guard beforeChanged == afterChanged,
                  changed.weather.kind == .rain,
                  changed.crops.contains(where: {
                      $0.cropKey == "wheat" && $0.position == cropPosition
                          && $0.growthStage == 7 && $0.mature
                  }),
                  changed.digest != first.digest else {
                throw ControllerError.ecologicalObservationBoundary(
                    "real World change was not observed"
                )
            }
            try recordScannedEcologicalObservation(
                changed,
                world: world,
                session: &candidate,
                recorder: &recorder,
                receiptTransaction: &receiptTransaction
            )

            let worldReceiptStore = try worldEcologicalObservationReceiptStore()
            let retainedReceiptIDs = candidate.ecologicalObservationSnapshot()
                .observations.compactMap(\.physicalObservationReceiptID).sorted()
            guard retainedReceiptIDs.count == 2,
                  try worldReceiptStore.evidence(for: retainedReceiptIDs).count
                    == 2 else {
                throw ControllerError.ecologicalObservationBoundary(
                    "independent World-side receipt set mismatch"
                )
            }

            // A late publication failure discards the candidate row/event and
            // removes the separately persisted receipt byte-for-byte.
            let rollbackBaseBytes = try candidate.durableStateBytes()
            var rollbackCandidate = candidate
            var rollbackRecorder = recorder
            var rollbackReceiptTransaction =
                PebbleWorldEcologicalObservationReceiptTransaction()
            try recordScannedEcologicalObservation(
                changed,
                world: world,
                session: &rollbackCandidate,
                recorder: &rollbackRecorder,
                receiptTransaction: &rollbackReceiptTransaction
            )
            guard let rollbackReceiptID = rollbackCandidate
                .ecologicalObservationSnapshot().observations.last?
                .physicalObservationReceiptID else {
                throw ControllerError.ecologicalObservationBoundary(
                    "rollback receipt identity unavailable"
                )
            }
            try rollbackWorldEcologicalObservationReceipts(
                rollbackReceiptTransaction
            )
            guard worldReceiptStore.database.getWorldReceipt(
                    worldID: worldReceiptStore.worldID,
                    kind: PebbleEcologicalObservationReceipt.kind,
                    receiptID: rollbackReceiptID.rawValue
                  ) == nil,
                  try candidate.durableStateBytes() == rollbackBaseBytes else {
                throw ControllerError.ecologicalObservationBoundary(
                    "late receipt/row rollback mismatch"
                )
            }

            let existingReceipt = try worldReceiptStore.receipt(
                retainedReceiptIDs[0]
            )
            var duplicateReceiptRefused = false
            do {
                try worldReceiptStore.insert(existingReceipt)
            } catch PebbleWorldEcologicalObservationReceiptError
                    .duplicateReceipt {
                duplicateReceiptRefused = true
            }
            let receiptCount = worldReceiptStore.database.listWorldReceipts(
                worldID: worldReceiptStore.worldID,
                kind: PebbleEcologicalObservationReceipt.kind
            ).count
            let capacityStore = try PebbleWorldEcologicalObservationReceiptStore(
                database: worldReceiptStore.database,
                worldID: worldReceiptStore.worldID,
                storageIdentity: worldReceiptStore.storageIdentity,
                maximumReceipts: receiptCount
            )
            let capacityReceipt = capacityStore.makeReceipt(
                observation: changed,
                simulationID: candidate.simulationID,
                dimension: world.dim.rawValue,
                ordinal: UInt64.max - 1
            )
            var capacityRefused = false
            do {
                try capacityStore.insert(capacityReceipt)
            } catch PebbleWorldEcologicalObservationReceiptError
                    .capacityReached {
                capacityRefused = true
            }
            guard duplicateReceiptRefused, capacityRefused,
                  capacityStore.database.getWorldReceipt(
                    worldID: capacityStore.worldID,
                    kind: PebbleEcologicalObservationReceipt.kind,
                    receiptID: capacityReceipt.receiptID.rawValue
                  ) == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "World-side receipt duplicate/capacity boundary mismatch"
                )
            }

            guard first.biome != nil,
                  first.water.contains(where: { $0.fluidKey == "water" }),
                  first.soils.contains(where: { $0.blockKey == "dirt" && $0.tillable }),
                  first.crops.contains(where: {
                      $0.cropKey == "wheat" && $0.growthStage == 3
                  }),
                  first.plants.contains(where: { $0.plantKey == "oak_sapling" }),
                  first.animals.contains(where: { $0.speciesKey == "cow" }),
                  first.fishing.contains(where: { $0.waterKey == "water" && $0.candidate }),
                  first.physicalTime.worldTick == world.time,
                  first.civilDate == changed.civilDate else {
                throw ControllerError.ecologicalObservationBoundary(
                    "normalized real World categories incomplete"
                )
            }

            let dryOrigin = AgentPosition(
                x: origin.x + 1, y: origin.y + 1, z: origin.z - 1
            )
            let contrastConfiguration = try AgentEcologicalObservationConfiguration(
                radius: 1, verticalRadius: 0, maximumCellsPerScan: 1,
                maximumChunksPerScan: 1, maximumWorldReadsPerScan: 8
            )
            ecologicalObservationSensor.invalidate(
                world: world, origin: dryOrigin, radius: contrastConfiguration.radius
            )
            let dry = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: dryOrigin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: contrastConfiguration
            )
            guard dry.water.isEmpty, dry.fishing.isEmpty, dry.soils.isEmpty else {
                throw ControllerError.ecologicalObservationBoundary(
                    "dry non-tillable contrast produced a false affordance"
                )
            }

            world.removeEntity(fixture.cow)
            ecologicalObservationSensor.invalidate(
                world: world, origin: origin, radius: configuration.radius
            )
            let withoutFixtureCow = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            world.addEntity(fixture.cow)
            ecologicalObservationSensor.invalidate(
                world: world, origin: origin, radius: configuration.radius
            )
            let fixtureCowPosition = AgentPosition(
                x: Int(floor(fixture.cow.x)), y: Int(floor(fixture.cow.y)),
                z: Int(floor(fixture.cow.z))
            )
            guard !withoutFixtureCow.animals.contains(where: {
                $0.speciesKey == "cow" && $0.position == fixtureCowPosition
            }) else {
                throw ControllerError.ecologicalObservationBoundary(
                    "removed fixture animal remained observable"
                )
            }

            guard let biomePair = ecologicalBiomeNormalizationProof(
                referenceWorld: world, observerID: observerID,
                simulationTick: candidate.tick, civilDate: civilDate
            ), biomePair.0 != biomePair.1 else {
                throw ControllerError.ecologicalObservationBoundary(
                    "distinct real biome identities were not normalized distinctly"
                )
            }

            let chunksBeforeFarScan = world.chunks.count
            let farOrigin = ecologicalUnloadedOrigin(world: world)
            let far = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: farOrigin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            guard world.chunks.count == chunksBeforeFarScan,
                  far.diagnostics.completion == .chunkUnavailable,
                  far.biome == nil, far.water.isEmpty, far.crops.isEmpty else {
                throw ControllerError.ecologicalObservationBoundary(
                    "unloaded chunk was forced or reported as absence"
                )
            }

            let replacement = World(dim: world.dim, seed: world.seed)
            replacement.time = world.time
            replacement.dayTime = world.dayTime
            let sensorBeforeReplacement = ecologicalObservationSensor.snapshot
            let replacementObservation = ecologicalObservationSensor.scan(
                world: replacement, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: configuration
            )
            let sensorAfterReplacement = ecologicalObservationSensor.snapshot
            guard sensorAfterReplacement.cacheMisses
                    == sensorBeforeReplacement.cacheMisses + 1,
                  replacementObservation.diagnostics.cacheMisses == 1,
                  replacementObservation.biome == nil else {
                throw ControllerError.ecologicalObservationBoundary(
                    "World replacement reused stale cache"
                )
            }

            let tinyConfiguration = try AgentEcologicalObservationConfiguration(
                maximumCellsPerScan: 1
            )
            ecologicalObservationSensor.invalidate(
                world: world, origin: origin, radius: tinyConfiguration.radius
            )
            let truncated = ecologicalObservationSensor.scan(
                world: world, observerID: observerID, origin: origin,
                worldContextKey: ecologicalObservationWorldContextKey(world),
                dimensionKey: ecologicalObservationDimensionKey(world.dim),
                simulationTick: candidate.tick, civilDate: civilDate,
                configuration: tinyConfiguration
            )
            guard truncated.diagnostics.cellsConsidered == 1,
                  truncated.diagnostics.completion == .scanBudgetExceeded else {
                throw ControllerError.ecologicalObservationBoundary(
                    "scan budget truncation was not explicit"
                )
            }

            let missingID = AgentID(rawValue: "agent_2")!
            let missingBytes = try candidate.durableStateBytes()
            guard let missingProbe = probesByAgentId.removeValue(
                forKey: missingID.rawValue
            ) else {
                throw ControllerError.ecologicalObservationBoundary(
                    "missing-embodiment fixture unavailable"
                )
            }
            var missingCandidate = candidate
            var missingRecorder: AgentReplayRecorder?
            let missingRefused: Bool
            do {
                _ = try recordLiveEcologicalObservation(
                    world: world, observerID: missingID,
                    session: &missingCandidate, recorder: &missingRecorder,
                    receiptTransaction: &receiptTransaction
                )
                missingRefused = false
            } catch ControllerError.ecologicalObservationBoundary {
                missingRefused = true
            }
            probesByAgentId[missingID.rawValue] = missingProbe
            guard missingRefused,
                  try missingCandidate.durableStateBytes() == missingBytes else {
                throw ControllerError.ecologicalObservationBoundary(
                    "missing embodiment was not refused atomically"
                )
            }

            ecologicalObservationSensor.invalidate(
                world: world, origin: origin, radius: configuration.radius
            )
            let benchmarkBefore = ecologicalObservationSensor.snapshot
            for _ in 0..<32 {
                _ = ecologicalObservationSensor.scan(
                    world: world, observerID: observerID, origin: origin,
                    worldContextKey: ecologicalObservationWorldContextKey(world),
                    dimensionKey: ecologicalObservationDimensionKey(world.dim),
                    simulationTick: candidate.tick, civilDate: civilDate,
                    configuration: configuration
                )
            }
            let benchmarkAfter = ecologicalObservationSensor.snapshot
            let benchmarkHits = benchmarkAfter.cacheHits - benchmarkBefore.cacheHits
            let benchmarkMisses = benchmarkAfter.cacheMisses - benchmarkBefore.cacheMisses
            let benchmarkReads = benchmarkAfter.worldReads - benchmarkBefore.worldReads
            guard benchmarkHits == 31, benchmarkMisses == 1,
                  benchmarkReads <= configuration.maximumWorldReadsPerScan else {
                throw ControllerError.ecologicalObservationBoundary(
                    "32-agent scan benchmark exceeded bounded cache budget"
                )
            }

            let materialAfter = candidate.snapshot().agents.map {
                ($0.id, $0.resourceInventory)
            }
            guard materialBefore.elementsEqual(materialAfter, by: {
                $0.0 == $1.0 && $0.1 == $1.1
            }),
                  campBefore == candidate.campStock,
                  coarseBefore == candidate.localEcologySnapshot(),
                  candidate.ecologicalObservations(for: otherID).isEmpty,
                  candidate.ecologicalObservations(for: observerID).count == 2 else {
                throw ControllerError.ecologicalObservationBoundary(
                    "observation mutated material/coarse truth or leaked between agents"
                )
            }

            try validateWorldEcologicalObservationReceipts(
                for: candidate, dimension: world.dim.rawValue
            )
            let checkpoint = try candidate.makeCheckpoint()
            let restored = try AgentSimulationSession.restoring(checkpoint)
            try validateWorldEcologicalObservationReceipts(
                for: restored, dimension: world.dim.rawValue
            )
            guard checkpoint.schemaVersion
                    == AgentCheckpointSchema
                        .independentEcologicalReceiptVersion,
                  try restored.durableStateBytes() == candidate.durableStateBytes() else {
                throw ControllerError.ecologicalObservationBoundary(
                    "v30 checkpoint restart mismatch"
                )
            }

            session = candidate
            replayRecorder = recorder
            receiptTransaction.commit()
            receiptTransactionCommitted = true
            focusedAgentId = observerID.rawValue
            positionEcologicalObservationProofCamera(player: player, origin: origin)
            let digest = AgentEcologicalObservationDigest.make(
                [first.digest, changed.digest, candidate.ecologicalObservationSnapshot().digest]
                    .joined(separator: "|")
            )
            trace(
                "ecological observation proof observer=agent_0 authority=PebbleCore "
                    + "biome=real water=real soil=real crop=3>7 plant=real animal=cow "
                    + "fishing=candidate weather=clear>rain physicalTime=real "
                    + "civilDate=1-spring-1 clock=sessionTick independentWorldClock=1 "
                    + "biomePair=different waterContrast=present>absent "
                    + "soilContrast=tillable>invalid animalContrast=present>absent "
                    + "fishingContrast=candidate>absent "
                    + "perAgent=exact agent_1=none stableKeys=canonical noRuntimeIDs=1 "
                    + "chunkForce=none unavailable=unknown WorldReplacement=cacheMiss "
                    + "budgetExceeded=explicit missingEmbodiment=refused "
                    + "cache32=1miss+31hits reads=\(benchmarkReads) "
                    + "cellsMax=\(configuration.maximumCellsPerScan) "
                    + "worldReadsMax=\(configuration.maximumWorldReadsPerScan) "
                    + "entitiesMax=\(configuration.maximumEntitiesPerScan) "
                    + "resultsMax=\(configuration.maximumResultsPerScan) "
                    + "scanWorldMutation=none fixtureMutation=controlled "
                    + "materialMutation=none coarseEcologyMutation=none "
                    + "schema=30 restart=exact physicalReceiptCount=2 "
                    + "physicalReceiptIDs=\(retainedReceiptIDs.map(\.rawValue).joined(separator: ",")) "
                    + "receiptRollback=exact receiptCapacity=refused "
                    + "fixture=retainedForCapture cleanup=deferred "
                    + "digest=\(digest)"
            )
            return success(
                "Ecological observation proof passed: real local World categories, "
                    + "civil calendar, cache invalidation, and schema 30 restart are exact."
            )
        } catch {
            let cleanup = cleanupEcologicalObservationProofFixture(world: world)
            ecologicalObservationSensor.invalidate(world: world)
            return failure(
                "Ecological observation proof failed: \(error); cleanup="
                    + (cleanup ? "exact" : "failed")
            )
        }
    }

    func prepareEcologicalObservationProofFixture(
        world: World,
        origin: AgentPosition
    ) -> PebbleAgentEcologicalObservationProofFixture? {
        let featurePositions = [
            AgentPosition(x: origin.x + 1, y: origin.y - 1, z: origin.z),
            AgentPosition(x: origin.x + 2, y: origin.y - 1, z: origin.z),
            AgentPosition(x: origin.x + 2, y: origin.y, z: origin.z),
            AgentPosition(x: origin.x + 1, y: origin.y, z: origin.z + 1),
            AgentPosition(x: origin.x + 2, y: origin.y - 1, z: origin.z + 1),
            AgentPosition(x: origin.x + 2, y: origin.y, z: origin.z + 1),
        ]
        let featureSet = Set(featurePositions)
        let viewPositions = (origin.z - 4...origin.z - 1).flatMap { z in
            (origin.y...origin.y + 2).flatMap { y in
                (origin.x + 1...origin.x + 3).map { x in
                    AgentPosition(x: x, y: y, z: z)
                }
            }
        }.filter { !featureSet.contains($0) }
        let positions = featurePositions + viewPositions
        guard positions.allSatisfy({ world.isChunkReady($0.x >> 4, $0.z >> 4) }) else {
            return nil
        }
        let cells = positions.map {
            PebbleAgentEcologicalObservationProofFixture.Cell(
                position: $0, original: world.getBlock($0.x, $0.y, $0.z)
            )
        }
        let featureReplacements = [
            Int(cell(bid("dirt"))), Int(cell(bid("farmland"), 7)),
            Int(cell(bid("wheat"), 3)), Int(cell(B.water, 0)),
            Int(cell(bid("dirt"))), Int(cell(bid("oak_sapling"))),
        ]
        let replacements = featureReplacements
            + Array(repeating: Int(cell(B.air)), count: viewPositions.count)
        for (position, value) in zip(positions, replacements) {
            world.setBlock(position.x, position.y, position.z, value, SET_NO_NEIGHBORS)
        }
        let entityIDs = world.entities.map(\.id).sorted()
        let cow = Cow(world: world)
        cow.setPos(Double(origin.x) + 3.5, Double(origin.y), Double(origin.z) + 0.5)
        cow.persistent = false
        world.addEntity(cow)
        let sheep = Sheep(world: world)
        sheep.setPos(
            Double(origin.x) + 1.5,
            Double(origin.y),
            Double(origin.z) + 0.5
        )
        sheep.persistent = false
        world.addEntity(sheep)
        return PebbleAgentEcologicalObservationProofFixture(
            cells: cells, cow: cow, sheep: sheep, entityIDsBefore: entityIDs,
            raining: world.raining, thundering: world.thundering,
            rainLevel: world.rainLevel, thunderLevel: world.thunderLevel,
            weatherTimer: world.weatherTimer
        )
    }

    @discardableResult
    func cleanupEcologicalObservationProofFixture(world: World) -> Bool {
        guard let fixture = ecologicalObservationProofFixture else { return true }
        for entry in fixture.cells {
            world.setBlock(
                entry.position.x, entry.position.y, entry.position.z,
                entry.original, SET_SILENT
            )
        }
        if world.entities.contains(where: { $0 === fixture.cow }) {
            world.removeEntity(fixture.cow)
        }
        if world.entities.contains(where: { $0 === fixture.sheep }) {
            world.removeEntity(fixture.sheep)
        }
        world.raining = fixture.raining
        world.thundering = fixture.thundering
        world.rainLevel = fixture.rainLevel
        world.thunderLevel = fixture.thunderLevel
        world.weatherTimer = fixture.weatherTimer
        let cowAbsent = !world.entities.contains(where: { $0 === fixture.cow })
            && world.entityById[fixture.cow.id] == nil
        let sheepAbsent = !world.entities.contains(where: { $0 === fixture.sheep })
            && world.entityById[fixture.sheep.id] == nil
        let restored = fixture.cells.allSatisfy {
            world.getBlock($0.position.x, $0.position.y, $0.position.z) == $0.original
        } && cowAbsent && sheepAbsent
            && world.raining == fixture.raining
            && world.thundering == fixture.thundering
            && world.rainLevel == fixture.rainLevel
            && world.thunderLevel == fixture.thunderLevel
        if !restored {
            let cells = fixture.cells.map {
                "\($0.position.x),\($0.position.y),\($0.position.z):"
                    + "\(world.getBlock($0.position.x, $0.position.y, $0.position.z))"
                    + "/\($0.original)"
            }.joined(separator: ";")
            trace(
                "ecological observation cleanup mismatch cells=\(cells) "
                    + "cowAbsent=\(cowAbsent ? 1 : 0) "
                    + "sheepAbsent=\(sheepAbsent ? 1 : 0) "
                    + "weather=\(world.raining ? 1 : 0):\(world.thundering ? 1 : 0):"
                    + "\(world.rainLevel):\(world.thunderLevel)"
            )
        }
        if restored { ecologicalObservationProofFixture = nil }
        return restored
    }

    private func ecologicalWorldEvidence(
        _ world: World,
        fixture: PebbleAgentEcologicalObservationProofFixture
    ) -> PebbleEcologicalWorldEvidence {
        PebbleEcologicalWorldEvidence(
            cells: fixture.cells.map {
                world.getBlock($0.position.x, $0.position.y, $0.position.z)
            },
            entityIDs: world.entities.map(\.id).sorted(),
            worldTick: world.time, dayTime: world.dayTime,
            raining: world.raining, thundering: world.thundering,
            rainLevel: world.rainLevel, thunderLevel: world.thunderLevel,
            chunkCount: world.chunks.count
        )
    }

    private func ecologicalUnloadedOrigin(world: World) -> AgentPosition {
        for chunk in 10_000..<20_000 where !world.isChunkReady(chunk, chunk) {
            return AgentPosition(x: chunk * CHUNK_W, y: 64, z: chunk * CHUNK_W)
        }
        return AgentPosition(x: 320_000, y: 64, z: 320_000)
    }

    private func ecologicalBiomeNormalizationProof(
        referenceWorld: World,
        observerID: AgentID,
        simulationTick: Int,
        civilDate: AgentCivilDate
    ) -> (String, String)? {
        let definitions = BIOMES.enumerated().compactMap { index, definition in
            definition.map { (index, $0.name) }
        }
        guard let first = definitions.first,
              let second = definitions.first(where: { $0.1 != first.1 }) else {
            return nil
        }
        let fixtureWorld = World(dim: referenceWorld.dim, seed: referenceWorld.seed)
        fixtureWorld.time = referenceWorld.time
        fixtureWorld.dayTime = referenceWorld.dayTime
        let configuration = try! AgentEcologicalObservationConfiguration(
            radius: 1, verticalRadius: 0, maximumCellsPerScan: 5,
            maximumChunksPerScan: 1, maximumWorldReadsPerScan: 8
        )
        var keys: [String] = []
        for (slot, definition) in [first, second].enumerated() {
            let chunk = Chunk(
                cx: slot, cz: 0, minY: fixtureWorld.info.minY,
                height: fixtureWorld.info.height
            )
            for qy in 0..<((chunk.height + 3) / 4) {
                for qz in 0..<4 {
                    for qx in 0..<4 {
                        chunk.setBiome(qx, qy, qz, definition.0)
                    }
                }
            }
            chunk.status = .generated
            fixtureWorld.setChunk(chunk)
            let sampleOrigin = AgentPosition(
                x: slot * CHUNK_W + 8, y: fixtureWorld.info.minY + 8, z: 8
            )
            let observation = ecologicalObservationSensor.scan(
                world: fixtureWorld, observerID: observerID, origin: sampleOrigin,
                worldContextKey: "ecological-biome-fixture",
                dimensionKey: ecologicalObservationDimensionKey(fixtureWorld.dim),
                simulationTick: simulationTick, civilDate: civilDate,
                configuration: configuration
            )
            guard let key = observation.biome?.biomeKey,
                  key == definition.1 else {
                ecologicalObservationSensor.invalidate(world: fixtureWorld)
                return nil
            }
            keys.append(key)
        }
        ecologicalObservationSensor.invalidate(world: fixtureWorld)
        guard keys.count == 2 else { return nil }
        return (keys[0], keys[1])
    }

    private func positionEcologicalObservationProofCamera(
        player: Player,
        origin: AgentPosition
    ) {
        player.setPos(
            Double(origin.x) + 2.5,
            Double(origin.y) + 2,
            Double(origin.z) - 5
        )
        player.vx = 0
        player.vy = 0
        player.vz = 0
        player.flying = true
        player.yaw = 0
        player.pitch = 0.48
    }
}
