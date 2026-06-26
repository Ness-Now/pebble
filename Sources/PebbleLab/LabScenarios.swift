import Foundation
import PebbleCore

struct ScenarioResult {
    var chunksTouched: Int?
    var chunkRadius: Int?
    var originChunkReady: Bool?
    var centerHeight: Int?
    var centerSurfaceY: Int?
    var nonAirBlocks: Int?
    var expectedChunks: Int?
    var readyChunks: Int?
    var nonAirBlocksTotal: Int?
    var adoptedChunks: [AdoptedChunk] = []
    var agents: [LabAgent] = []
    var physicalBridge = LabAgentPhysicalBridge()
    var coreEntityBridge = LabCoreEntityBridge()
}

struct AdoptedChunk {
    let x: Int
    let z: Int
    let chunksTouched: Int
    let originChunkReady: Bool
    let ready: Bool
    let centerHeight: Int
    let centerSurfaceY: Int
    let nonAirBlocks: Int
}

let supportedScenarios = ["empty", "chunk_smoke", "agent_smoke", "agents_basic", "seek_safety_smoke", "long_run_smoke", "regression_smoke", "physical_placeholder_smoke", "physical_sync_smoke", "core_entity_smoke", "physical_behavior_smoke", "physical_behavior_multi_smoke", "physical_movement_denied_smoke", "physical_movement_find_occupable_smoke", "physical_movement_approved_single_step_smoke", "physical_movement_single_step_hardening_smoke", "route_following_fixture_smoke", "world_observation_smoke", "world_observation_multi_smoke", "terrain_scan_smoke", "terrain_scan_edge_smoke", "terrain_column_scan_smoke", "terrain_column_scan_edge_smoke", "terrain_pathfinding_column_smoke", "terrain_pathfinding_column_edge_smoke", "terrain_pathfinding_column_positive_smoke", "terrain_path_live_movement_smoke", "terrain_path_movement_fixture_smoke", "terrain_collision_fixture_smoke", "terrain_collision_live_readonly_smoke", "terrain_semantics_fixture_smoke", "terrain_traversability_fixture_smoke", "terrain_pathfinding_fixture_smoke"]

func validateScenario(_ scenario: String) {
    guard supportedScenarios.contains(scenario) else {
        fail("unsupported scenario: \(scenario). Currently supported: \(supportedScenarios.joined(separator: ", "))")
    }
}

func prepareScenario(_ options: Options, world: World) -> ScenarioResult {
    let scenario = options.scenario

    switch scenario {
    case "terrain_semantics_fixture_smoke", "terrain_traversability_fixture_smoke", "terrain_pathfinding_fixture_smoke", "terrain_pathfinding_column_positive_smoke", "terrain_path_live_movement_smoke", "terrain_path_movement_fixture_smoke", "terrain_collision_fixture_smoke", "route_following_fixture_smoke":
        return ScenarioResult()
    case "chunk_smoke", "agent_smoke", "agents_basic", "seek_safety_smoke", "long_run_smoke", "regression_smoke", "physical_placeholder_smoke", "physical_sync_smoke", "core_entity_smoke", "physical_behavior_smoke", "physical_behavior_multi_smoke", "physical_movement_denied_smoke", "physical_movement_find_occupable_smoke", "physical_movement_approved_single_step_smoke", "physical_movement_single_step_hardening_smoke", "world_observation_smoke", "world_observation_multi_smoke", "terrain_scan_smoke", "terrain_scan_edge_smoke", "terrain_column_scan_smoke", "terrain_column_scan_edge_smoke", "terrain_pathfinding_column_smoke", "terrain_pathfinding_column_edge_smoke", "terrain_collision_live_readonly_smoke":
        registerAllBlocks()
        registerAllBiomes()

        let chunkRadius = (scenario == "agent_smoke" || scenario == "agents_basic" || scenario == "seek_safety_smoke" || scenario == "long_run_smoke" || scenario == "regression_smoke" || scenario == "physical_placeholder_smoke" || scenario == "physical_sync_smoke" || scenario == "core_entity_smoke" || scenario == "physical_behavior_smoke" || scenario == "physical_behavior_multi_smoke" || scenario == "physical_movement_denied_smoke" || scenario == "physical_movement_find_occupable_smoke" || scenario == "physical_movement_approved_single_step_smoke" || scenario == "physical_movement_single_step_hardening_smoke" || scenario == "world_observation_smoke" || scenario == "world_observation_multi_smoke" || scenario == "terrain_collision_live_readonly_smoke" || isTerrainColumnScanScenario(scenario) || isTerrainScanScenario(scenario)) && !options.chunkRadiusProvided ? 1 : options.chunkRadius
        var adoptedChunks: [AdoptedChunk] = []
        var nonAirBlocksTotal = 0

        for cz in -chunkRadius...chunkRadius {
            for cx in -chunkRadius...chunkRadius {
                let generated = generateChunk(.overworld, world.seed, cx, cz)
                let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)

                chunk.blocks = generated.blocks
                chunk.biomes = generated.biomes
                chunk.buildHeightmap()
                chunk.scanSpecials()

                world.setChunk(chunk)
                world.light.initChunkLight(chunk)

                let nonAirBlocks = chunk.blocks.reduce(0) { count, cell in
                    count + (cell == 0 ? 0 : 1)
                }
                nonAirBlocksTotal += nonAirBlocks
                let centerX = cx * 16 + 8
                let centerZ = cz * 16 + 8
                adoptedChunks.append(AdoptedChunk(
                    x: cx,
                    z: cz,
                    chunksTouched: world.chunks.count,
                    originChunkReady: world.isChunkReady(0, 0),
                    ready: world.isChunkReady(cx, cz),
                    centerHeight: world.heightAt(centerX, centerZ),
                    centerSurfaceY: world.surfaceY(centerX, centerZ),
                    nonAirBlocks: nonAirBlocks
                ))
            }
        }

        let expectedChunks = (chunkRadius * 2 + 1) * (chunkRadius * 2 + 1)
        var readyChunks = 0
        for cz in -chunkRadius...chunkRadius {
            for cx in -chunkRadius...chunkRadius where world.isChunkReady(cx, cz) {
                readyChunks += 1
            }
        }

        var result = ScenarioResult(
            chunksTouched: world.chunks.count,
            chunkRadius: chunkRadius,
            originChunkReady: world.isChunkReady(0, 0),
            centerHeight: world.heightAt(8, 8),
            centerSurfaceY: world.surfaceY(8, 8),
            nonAirBlocks: world.getChunk(0, 0)?.blocks.reduce(0) { count, cell in
                count + (cell == 0 ? 0 : 1)
            },
            expectedChunks: expectedChunks,
            readyChunks: readyChunks,
            nonAirBlocksTotal: nonAirBlocksTotal,
            adoptedChunks: adoptedChunks
        )
        if scenario == "agent_smoke" {
            var agent0 = makeLabAgent(id: "agent_0", x: 8, z: 8, world: world)
            var agent1 = makeLabAgent(id: "agent_1", x: 12, z: 8, world: world)
            agent0.inventory.add("food", count: 1)
            agent1.inventory.add("wood", count: 2)
            result.agents = [
                agent0,
                agent1
            ]
        } else if scenario == "agents_basic" {
            result.agents = makeBasicAgents(count: options.agents, seed: options.seed, world: world)
        } else if scenario == "seek_safety_smoke" {
            var agent = makeLabAgent(id: "agent_0", x: 13, z: 8, world: world)
            agent.homePosition = LabAgentPosition(x: 8, y: spawnYAt(x: 8, z: 8, world: world), z: 8)
            agent.fear = 90
            agent.needs.curiosity = 0.1
            result.agents = [agent]
        } else if scenario == "long_run_smoke" {
            let agentCount = options.agentsProvided ? options.agents : 10
            result.agents = makeBasicAgents(count: agentCount, seed: options.seed, world: world)
        } else if scenario == "regression_smoke" {
            let agentCount = options.agentsProvided ? options.agents : 4
            result.agents = makeBasicAgents(count: agentCount, seed: options.seed, world: world)
        } else if scenario == "physical_placeholder_smoke" {
            var agent = makeLabAgent(id: "agent_0", x: 8, z: 8, world: world)
            agent.needs.curiosity = 0.1
            result.agents = [agent]
            _ = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
        } else if scenario == "physical_sync_smoke" {
            var agent = makeLabAgent(id: "agent_0", x: 8, z: 8, world: world)
            agent.needs.curiosity = 0.9
            result.agents = [agent]
            _ = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
        } else if scenario == "core_entity_smoke" || scenario == "physical_behavior_smoke" {
            var agent = makeLabAgent(id: "agent_0", x: 8, z: 8, world: world)
            agent.needs.curiosity = 0.9
            result.agents = [agent]
            let handle = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
            _ = result.coreEntityBridge.spawnCoreEntity(
                for: agent,
                physicalId: handle.physicalId,
                world: world
            )
        } else if scenario == "physical_behavior_multi_smoke" {
            result.agents = [
                makeLabAgent(id: "agent_0", x: 8, z: 8, world: world),
                makeLabAgent(id: "agent_1", x: 12, z: 8, world: world),
                makeLabAgent(id: "agent_2", x: 8, z: 12, world: world)
            ]
            for index in result.agents.indices {
                result.agents[index].needs.curiosity = 0.9
            }
            for agent in result.agents {
                let handle = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
                _ = result.coreEntityBridge.spawnCoreEntity(
                    for: agent,
                    physicalId: handle.physicalId,
                    world: world
                )
            }
        } else if scenario == "world_observation_smoke" || isTerrainColumnScanScenario(scenario) || isTerrainScanScenario(scenario) {
            let terrainContract = terrainScanScenarioContract(for: scenario)
            let columnContract = terrainColumnScanScenarioContract(for: scenario)
            var agent = makeLabAgent(
                id: "agent_0",
                x: columnContract?.agentX ?? terrainContract?.agentX ?? 8,
                z: columnContract?.agentZ ?? terrainContract?.agentZ ?? 8,
                world: world
            )
            agent.needs.curiosity = 0.1
            result.agents = [agent]
            let handle = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
            _ = result.coreEntityBridge.spawnCoreEntity(
                for: agent,
                physicalId: handle.physicalId,
                world: world
            )
        } else if scenario == "world_observation_multi_smoke" {
            result.agents = [
                makeLabAgent(id: "agent_0", x: 8, z: 8, world: world),
                makeLabAgent(id: "agent_1", x: 12, z: 8, world: world),
                makeLabAgent(id: "agent_2", x: 8, z: 12, world: world)
            ]
            for index in result.agents.indices {
                result.agents[index].needs.curiosity = 0.1
            }
            for agent in result.agents {
                let handle = result.physicalBridge.spawnPlaceholder(for: agent, tick: 0)
                _ = result.coreEntityBridge.spawnCoreEntity(
                    for: agent,
                    physicalId: handle.physicalId,
                    world: world
                )
            }
        }
        return result
    default:
        return ScenarioResult()
    }
}

func makeBasicAgents(count: Int, seed: UInt32, world: World) -> [LabAgent] {
    let columns = max(1, Int(ceil(Double(count).squareRoot())))
    let rows = max(1, Int(ceil(Double(count) / Double(columns))))
    let spacing = 4
    let centerX = 8
    let centerZ = 8
    let xOffset = ((columns - 1) * spacing) / 2
    let zOffset = ((rows - 1) * spacing) / 2
    let seedOffset = Int(seed % UInt32(count))

    return (0..<count).map { index in
        let placedIndex = (index + seedOffset) % count
        let column = placedIndex % columns
        let row = placedIndex / columns
        let x = centerX + column * spacing - xOffset
        let z = centerZ + row * spacing - zOffset
        var agent = makeLabAgent(id: "agent_\(index)", x: x, z: z, world: world)

        if index % 3 == 0 {
            agent.needs.curiosity = 0.9
        }

        if index == 0 {
            agent.inventory.add("food", count: 1)
        } else if index == 1 {
            agent.inventory.add("wood", count: 2)
        }

        return agent
    }
}

func makeLabAgent(id: String, x: Int, z: Int, world: World) -> LabAgent {
    let spawnY = spawnYAt(x: x, z: z, world: world)
    return LabAgent(id: id, x: x, y: spawnY, z: z)
}

func spawnYAt(x: Int, z: Int, world: World) -> Int {
    var spawnY = world.heightAt(x, z) + 1
    while world.getBlock(x, spawnY, z) != 0 && spawnY < world.info.minY + world.info.height {
        spawnY += 1
    }
    return spawnY
}

func makeWorldSnapshot(
    options: Options,
    world: World,
    result: ScenarioResult,
    ticksCompleted: Int
) -> WorldSnapshot? {
    guard (options.scenario == "chunk_smoke" || options.scenario == "agent_smoke" || options.scenario == "agents_basic" || options.scenario == "seek_safety_smoke" || options.scenario == "long_run_smoke" || options.scenario == "regression_smoke" || options.scenario == "physical_placeholder_smoke" || options.scenario == "physical_sync_smoke" || options.scenario == "core_entity_smoke" || options.scenario == "physical_behavior_smoke" || options.scenario == "physical_behavior_multi_smoke" || options.scenario == "world_observation_smoke" || options.scenario == "world_observation_multi_smoke" || isTerrainScanScenario(options.scenario)),
          let chunkRadius = result.chunkRadius,
          let expectedChunks = result.expectedChunks,
          let readyChunks = result.readyChunks,
          let originChunkReady = result.originChunkReady,
          let centerHeight = result.centerHeight,
          let centerSurfaceY = result.centerSurfaceY
    else { return nil }

    let chunks = result.adoptedChunks
        .sorted {
            if $0.x != $1.x { return $0.x < $1.x }
            return $0.z < $1.z
        }
        .map {
            SnapshotChunk(
                cx: $0.x,
                cz: $0.z,
                ready: $0.ready,
                centerHeight: $0.centerHeight,
                centerSurfaceY: $0.centerSurfaceY,
                nonAirBlocks: $0.nonAirBlocks
            )
        }

    return WorldSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        worldTime: world.time,
        chunkRadius: chunkRadius,
        expectedChunks: expectedChunks,
        readyChunks: readyChunks,
        originChunkReady: originChunkReady,
        center: SnapshotCenter(x: 8, z: 8, height: centerHeight, surfaceY: centerSurfaceY),
        chunks: chunks
    )
}
