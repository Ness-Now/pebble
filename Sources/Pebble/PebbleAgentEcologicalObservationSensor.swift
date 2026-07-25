import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentEcologicalObservationSensorSnapshot: Equatable {
    let scans: Int
    let cacheHits: Int
    let cacheMisses: Int
    let worldReads: Int
    let chunksUnavailable: Int
    let invalidations: Int
}

/// Read-only, bounded projection of already-loaded PebbleCore World truth.
/// Runtime registry and entity identifiers never cross this adapter boundary.
final class PebbleAgentEcologicalObservationSensor {
    private struct CacheKey: Hashable {
        let worldIdentity: ObjectIdentifier
        let origin: AgentPosition
        let radius: Int
        let verticalRadius: Int
        let worldContextKey: String
        let dimensionKey: String
        let cells: Int
        let chunks: Int
        let entities: Int
        let results: Int
        let reads: Int
    }

    private struct CacheEntry {
        let key: CacheKey
        let physicalWorldTick: Int
        let observation: AgentEcologicalObservation
        let animalEntityIDs: [Int]
    }

    /// Ephemeral, live-only bridge from one exact observation result index to
    /// the PebbleCore entity that produced it. The binding is intentionally
    /// absent from `AgentEcologicalObservation` and every durable checkpoint.
    private struct AnimalBindingEntry {
        let worldIdentity: ObjectIdentifier
        let origin: AgentPosition
        let radius: Int
        let observation: AgentEcologicalObservation
        let entityIDs: [Int]
    }

    private static let maximumCacheEntries = 64
    private static let maximumAnimalBindingEntries = 128
    private static let cropStages: [String: Int] = [
        "wheat": 7, "carrots": 7, "potatoes": 7, "beetroots": 3,
        "torchflower_crop": 1, "pitcher_crop": 4,
        "pumpkin_stem": 7, "melon_stem": 7,
        "attached_pumpkin_stem": 7, "attached_melon_stem": 7,
    ]
    private static let tillableSoils = Set(["grass_block", "dirt", "dirt_path"])
    private static let plantNames = Set([
        "oak_sapling", "spruce_sapling", "birch_sapling", "jungle_sapling",
        "acacia_sapling", "dark_oak_sapling", "mangrove_propagule",
        "cherry_sapling", "azalea", "flowering_azalea", "bamboo_sapling",
        "bamboo", "cactus", "sugar_cane", "kelp", "kelp_plant",
        "seagrass", "tall_seagrass", "sweet_berry_bush", "cocoa",
        "nether_wart", "chorus_flower", "chorus_plant", "short_grass",
        "tall_grass", "fern", "large_fern", "vine", "cave_vines",
        "cave_vines_plant", "small_dripleaf", "big_dripleaf",
        "big_dripleaf_stem", "moss_block", "moss_carpet", "lily_pad",
        "dandelion", "poppy", "blue_orchid", "allium", "azure_bluet",
        "red_tulip", "orange_tulip", "white_tulip", "pink_tulip",
        "oxeye_daisy", "cornflower", "lily_of_the_valley", "sunflower",
        "lilac", "rose_bush", "peony", "torchflower", "pitcher_plant",
    ])

    private var cache: [CacheEntry] = []
    private var animalBindings: [AnimalBindingEntry] = []
    private(set) var scans = 0
    private(set) var cacheHits = 0
    private(set) var cacheMisses = 0
    private(set) var worldReads = 0
    private(set) var chunksUnavailable = 0
    private(set) var invalidations = 0

    var snapshot: PebbleAgentEcologicalObservationSensorSnapshot {
        PebbleAgentEcologicalObservationSensorSnapshot(
            scans: scans, cacheHits: cacheHits, cacheMisses: cacheMisses,
            worldReads: worldReads, chunksUnavailable: chunksUnavailable,
            invalidations: invalidations
        )
    }

    func invalidateAll() {
        if !cache.isEmpty || !animalBindings.isEmpty { invalidations += 1 }
        cache.removeAll(keepingCapacity: true)
        animalBindings.removeAll(keepingCapacity: true)
    }

    func invalidate(world: World) {
        let identity = ObjectIdentifier(world)
        let previousCacheCount = cache.count
        let previousBindingCount = animalBindings.count
        cache.removeAll { $0.key.worldIdentity == identity }
        animalBindings.removeAll { $0.worldIdentity == identity }
        if cache.count != previousCacheCount
            || animalBindings.count != previousBindingCount {
            invalidations += 1
        }
    }

    func invalidate(world: World, origin: AgentPosition, radius: Int) {
        let identity = ObjectIdentifier(world)
        let previousCacheCount = cache.count
        let previousBindingCount = animalBindings.count
        cache.removeAll {
            $0.key.worldIdentity == identity && $0.key.origin == origin
                && $0.key.radius == radius
        }
        animalBindings.removeAll {
            $0.worldIdentity == identity && $0.origin == origin && $0.radius == radius
        }
        if cache.count != previousCacheCount
            || animalBindings.count != previousBindingCount {
            invalidations += 1
        }
    }

    func scan(
        world: World,
        observerID: AgentID,
        origin: AgentPosition,
        worldContextKey: String,
        dimensionKey: String,
        simulationTick: Int,
        civilDate: AgentCivilDate,
        configuration: AgentEcologicalObservationConfiguration
    ) -> AgentEcologicalObservation {
        scans += 1
        let key = CacheKey(
            worldIdentity: ObjectIdentifier(world), origin: origin,
            radius: configuration.radius,
            verticalRadius: configuration.verticalRadius,
            worldContextKey: worldContextKey, dimensionKey: dimensionKey,
            cells: configuration.maximumCellsPerScan,
            chunks: configuration.maximumChunksPerScan,
            entities: configuration.maximumEntitiesPerScan,
            results: configuration.maximumResultsPerScan,
            reads: configuration.maximumWorldReadsPerScan
        )
        if let cached = cache.last(where: {
            $0.key == key && $0.physicalWorldTick == world.time
        }) {
            cacheHits += 1
            let observation = rebound(
                cached.observation, observerID: observerID,
                simulationTick: simulationTick, civilDate: civilDate,
                configuration: configuration
            )
            registerAnimalBindings(
                world: world, observation: observation, radius: configuration.radius,
                entityIDs: cached.animalEntityIDs
            )
            return observation
        }
        cacheMisses += 1
        let result = scanUncached(
            world: world, observerID: observerID, origin: origin,
            worldContextKey: worldContextKey, dimensionKey: dimensionKey,
            simulationTick: simulationTick, civilDate: civilDate,
            configuration: configuration
        )
        cache.append(CacheEntry(
            key: key, physicalWorldTick: world.time, observation: result.observation,
            animalEntityIDs: result.animalEntityIDs
        ))
        if cache.count > Self.maximumCacheEntries {
            cache.removeFirst(cache.count - Self.maximumCacheEntries)
        }
        registerAnimalBindings(
            world: world, observation: result.observation, radius: configuration.radius,
            entityIDs: result.animalEntityIDs
        )
        worldReads += result.observation.diagnostics.worldReads
        chunksUnavailable += result.observation.diagnostics.chunksUnavailable
        return result.observation
    }

    /// Resolves one exact live observation index without making Core identity
    /// part of the durable cognitive observation. A stale World tick, removed
    /// entity, changed species/position, or changed life stage invalidates the
    /// lookup rather than falling back to an ambiguous proximity search.
    func animalEntityID(
        world: World,
        observation: AgentEcologicalObservation,
        animalIndex: Int
    ) -> Int? {
        guard world.time == observation.physicalWorldTick,
              observation.animals.indices.contains(animalIndex),
              let binding = animalBindings.last(where: {
                  $0.worldIdentity == ObjectIdentifier(world)
                      && $0.observation == observation
              }),
              binding.entityIDs.indices.contains(animalIndex) else {
            return nil
        }
        let entityID = binding.entityIDs[animalIndex]
        guard let animal = world.entityById[entityID] as? Animal,
              animal.world === world, world.entityById[entityID] === animal,
              !animal.dead, animal.deathTime <= 0 else {
            return nil
        }
        let expected = observation.animals[animalIndex]
        let position = AgentPosition(
            x: Int(animal.x.rounded(.down)),
            y: Int(animal.y.rounded(.down)),
            z: Int(animal.z.rounded(.down))
        )
        let lifeStage: AgentAnimalLifeStage = animal.baby ? .juvenile : .adult
        guard expected.count == 1, animal.type == expected.speciesKey,
              position == expected.position, lifeStage == expected.lifeStage else {
            return nil
        }
        return entityID
    }

    private func registerAnimalBindings(
        world: World,
        observation: AgentEcologicalObservation,
        radius: Int,
        entityIDs: [Int]
    ) {
        guard entityIDs.count == observation.animals.count else { return }
        animalBindings.removeAll {
            $0.worldIdentity == ObjectIdentifier(world) && $0.observation == observation
        }
        animalBindings.append(AnimalBindingEntry(
            worldIdentity: ObjectIdentifier(world), origin: observation.origin,
            radius: radius, observation: observation, entityIDs: entityIDs
        ))
        if animalBindings.count > Self.maximumAnimalBindingEntries {
            animalBindings.removeFirst(
                animalBindings.count - Self.maximumAnimalBindingEntries
            )
        }
    }

    private func rebound(
        _ cached: AgentEcologicalObservation,
        observerID: AgentID,
        simulationTick: Int,
        civilDate: AgentCivilDate,
        configuration: AgentEcologicalObservationConfiguration
    ) -> AgentEcologicalObservation {
        let old = cached.diagnostics
        let diagnostics = AgentEcologicalScanDiagnostics(
            radius: old.radius, cellsConsidered: 0, worldReads: 0,
            chunksTouched: old.chunksTouched,
            chunksUnavailable: old.chunksUnavailable,
            entitiesConsidered: 0, resultsEmitted: old.resultsEmitted,
            cacheHits: 1, cacheMisses: 0, completion: old.completion
        )
        return AgentEcologicalObservation(
            observerID: observerID, origin: cached.origin,
            worldContextKey: cached.worldContextKey, dimensionKey: cached.dimensionKey,
            observedAtSimulationTick: simulationTick,
            physicalWorldTick: cached.physicalWorldTick, civilDate: civilDate,
            biome: cached.biome, water: cached.water, soils: cached.soils,
            crops: cached.crops, plants: cached.plants, animals: cached.animals,
            fishing: cached.fishing, weather: cached.weather,
            physicalTime: cached.physicalTime, diagnostics: diagnostics,
            expiresAtSimulationTick: simulationTick + configuration.dynamicFreshnessTicks
        )
    }

    private func scanUncached(
        world: World,
        observerID: AgentID,
        origin: AgentPosition,
        worldContextKey: String,
        dimensionKey: String,
        simulationTick: Int,
        civilDate: AgentCivilDate,
        configuration: AgentEcologicalObservationConfiguration
    ) -> (observation: AgentEcologicalObservation, animalEntityIDs: [Int]) {
        var reads = 0
        var cells = 0
        var unavailable = 0
        var touched = Set<String>()
        var budgetExceeded = false
        var water: [AgentWaterAffordance] = []
        var soils: [AgentSoilAffordance] = []
        var crops: [AgentCropObservation] = []
        var plants: [AgentPlantObservation] = []
        var fishing: [AgentFishingAffordance] = []
        var emitted = 2 // weather and physical time are always present
        let reserve = configuration.maximumResultsPerScan

        let positions = candidatePositions(origin: origin, configuration: configuration)
        for position in positions {
            guard cells < configuration.maximumCellsPerScan,
                  reads < configuration.maximumWorldReadsPerScan else {
                budgetExceeded = true
                break
            }
            cells += 1
            let chunkX = floorDiv(position.x, CHUNK_W)
            let chunkZ = floorDiv(position.z, CHUNK_W)
            let chunkKey = "\(chunkX),\(chunkZ)"
            if !touched.contains(chunkKey), touched.count >= configuration.maximumChunksPerScan {
                budgetExceeded = true
                break
            }
            touched.insert(chunkKey)
            guard world.isChunkReady(chunkX, chunkZ) else {
                unavailable += 1
                continue
            }
            let cell = world.getBlock(position.x, position.y, position.z)
            reads += 1
            let id = cell >> 4
            guard id >= 0, id < blockDefs.count else { continue }
            let definition = blockDefs[id]
            let name = definition.name
            let meta = cell & 15

            if (id == Int(B.water) || isWaterlogged(UInt16(truncatingIfNeeded: cell))),
               emitted + 2 <= reserve {
                let source = id == Int(B.water) && (meta & 7) == 0
                water.append(AgentWaterAffordance(
                    fluidKey: "water", position: position, sourceBlock: source
                ))
                fishing.append(AgentFishingAffordance(
                    position: position, waterKey: "water", candidate: true
                ))
                emitted += 2
            }

            if (Self.tillableSoils.contains(name) || name == "farmland"), emitted < reserve {
                let farmland = name == "farmland"
                soils.append(AgentSoilAffordance(
                    blockKey: name, position: position,
                    tillable: Self.tillableSoils.contains(name),
                    alreadyFarmland: farmland,
                    hydrated: farmland ? meta > 0 : nil,
                    supportsCrop: true
                ))
                emitted += 1
            }

            if let maximumStage = Self.cropStages[name], emitted < reserve {
                let stage = min(meta & 7, maximumStage)
                var supportKey: String?
                if reads < configuration.maximumWorldReadsPerScan,
                   world.isChunkReady(chunkX, chunkZ) {
                    let support = world.getBlock(position.x, position.y - 1, position.z)
                    reads += 1
                    let supportID = support >> 4
                    if supportID >= 0, supportID < blockDefs.count {
                        supportKey = blockDefs[supportID].name
                    }
                } else {
                    budgetExceeded = true
                }
                crops.append(AgentCropObservation(
                    cropKey: name, position: position, growthStage: stage,
                    maximumGrowthStage: maximumStage, mature: stage >= maximumStage,
                    supportBlockKey: supportKey
                ))
                emitted += 1
            } else if Self.plantNames.contains(name), emitted < reserve {
                plants.append(AgentPlantObservation(
                    plantKey: name, position: position,
                    renewability: definition.randomTicks ? .conditional : .unknown
                ))
                emitted += 1
            }
        }

        var biome: AgentBiomeObservation?
        let originChunkX = floorDiv(origin.x, CHUNK_W)
        let originChunkZ = floorDiv(origin.z, CHUNK_W)
        if world.isChunkReady(originChunkX, originChunkZ), emitted < reserve {
            let index = world.biomeAt(origin.x, origin.y, origin.z)
            let key = index >= 0 && index < BIOMES.count
                ? (BIOMES[index]?.name ?? "unknown") : "unknown"
            biome = AgentBiomeObservation(biomeKey: key, position: origin)
            emitted += 1
        }

        let nearby = world.getEntitiesNear(
            Double(origin.x) + 0.5, Double(origin.y) + 0.5,
            Double(origin.z) + 0.5, Double(configuration.radius)
        ) { $0 is Animal }
        let entities = nearby.compactMap { $0 as? Animal }.sorted(by: { lhs, rhs in
            if lhs.type != rhs.type { return lhs.type < rhs.type }
            if lhs.x != rhs.x { return lhs.x < rhs.x }
            if lhs.y != rhs.y { return lhs.y < rhs.y }
            if lhs.z != rhs.z { return lhs.z < rhs.z }
            return lhs.id < rhs.id
        }).prefix(configuration.maximumEntitiesPerScan)
        var animalPairs: [(observation: AgentAnimalObservation, entityID: Int)] = []
        for entity in entities where emitted < reserve {
            let animal = entity
            animalPairs.append((
                observation: AgentAnimalObservation(
                    speciesKey: animal.type,
                    position: AgentPosition(
                        x: Int(floor(animal.x)), y: Int(floor(animal.y)),
                        z: Int(floor(animal.z))
                    ),
                    count: 1, lifeStage: animal.baby ? .juvenile : .adult,
                    breedableAffordanceObservable: false
                ),
                entityID: animal.id
            ))
            emitted += 1
        }
        // `AgentEcologicalObservation` canonicalizes animals by position before
        // species. Keep the transient IDs in that exact order as well; sorting
        // entities by their registry presentation order would silently break
        // the index-to-Core-identity sidecar for mixed species.
        animalPairs.sort { lhs, rhs in
            if AgentEcologicalObservation.animalSort(
                lhs.observation,
                rhs.observation
            ) {
                return true
            }
            if AgentEcologicalObservation.animalSort(
                rhs.observation,
                lhs.observation
            ) {
                return false
            }
            return lhs.entityID < rhs.entityID
        }
        let animals = animalPairs.map(\.observation)
        let animalEntityIDs = animalPairs.map(\.entityID)

        let weatherKind: AgentWeatherKind = world.thundering
            ? .thunder : (world.raining ? .rain : .clear)
        let timeOfDay = physicalTimeOfDay(world.dayTime)
        let completion: AgentEcologicalScanCompletion = budgetExceeded
            ? .scanBudgetExceeded : (unavailable > 0 ? .chunkUnavailable : .complete)
        let diagnostics = AgentEcologicalScanDiagnostics(
            radius: configuration.radius, cellsConsidered: cells,
            worldReads: reads, chunksTouched: touched.count,
            chunksUnavailable: unavailable,
            entitiesConsidered: entities.count, resultsEmitted: emitted,
            cacheHits: 0, cacheMisses: 1, completion: completion
        )
        let observation = AgentEcologicalObservation(
            observerID: observerID, origin: origin,
            worldContextKey: worldContextKey, dimensionKey: dimensionKey,
            observedAtSimulationTick: simulationTick,
            physicalWorldTick: world.time, civilDate: civilDate,
            biome: biome, water: water, soils: soils, crops: crops,
            plants: plants, animals: animals, fishing: fishing,
            weather: AgentWeatherObservation(
                kind: weatherKind, raining: world.raining,
                thundering: world.thundering
            ),
            physicalTime: AgentPhysicalWorldTimeObservation(
                worldTick: world.time, dayTime: world.dayTime,
                timeOfDay: timeOfDay,
                daylightCycleEnabled: world.rule("doDaylightCycle")
            ),
            diagnostics: diagnostics,
            expiresAtSimulationTick: simulationTick + configuration.dynamicFreshnessTicks
        )
        return (observation, animalEntityIDs)
    }

    private func candidatePositions(
        origin: AgentPosition,
        configuration: AgentEcologicalObservationConfiguration
    ) -> [AgentPosition] {
        var positions: [AgentPosition] = []
        for y in (origin.y - configuration.verticalRadius)...(origin.y + configuration.verticalRadius) {
            for z in (origin.z - configuration.radius)...(origin.z + configuration.radius) {
                for x in (origin.x - configuration.radius)...(origin.x + configuration.radius) {
                    let horizontal = abs(x - origin.x) + abs(z - origin.z)
                    guard horizontal <= configuration.radius else { continue }
                    positions.append(AgentPosition(x: x, y: y, z: z))
                }
            }
        }
        return positions.sorted {
            let lhsDistance = abs($0.x - origin.x) + abs($0.y - origin.y)
                + abs($0.z - origin.z)
            let rhsDistance = abs($1.x - origin.x) + abs($1.y - origin.y)
                + abs($1.z - origin.z)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            return AgentEcologicalObservation.positionSort($0, $1)
        }
    }

    private func physicalTimeOfDay(_ raw: Int) -> AgentPhysicalTimeOfDay {
        let value = ((raw % DAY_LENGTH) + DAY_LENGTH) % DAY_LENGTH
        switch value {
        case 0..<1_000: return .dawn
        case 1_000..<12_000: return .day
        case 12_000..<13_000: return .dusk
        default: return .night
        }
    }
}
