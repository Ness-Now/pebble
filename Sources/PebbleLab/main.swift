import Foundation
import PebbleCore

let options = parseArguments(CommandLine.arguments)
validateScenario(options.scenario)

let world = World(dim: .overworld, seed: options.seed)
let scenarioResult = prepareScenario(options, world: world)
var labAgent = scenarioResult.agent

var ticksCompleted = 0
var eventsNDJSON = ""

func encodeMemoryEvent(_ entry: LabMemoryEntry, agent: LabAgent, scenario: String) throws -> String {
    try encodeEventLine(RunEvent(
        type: "agent_memory_recorded",
        tick: entry.tick,
        scenario: scenario,
        agentId: agent.id,
        memoryType: entry.type,
        importance: entry.importance,
        summary: entry.summary
    ))
}

if options.outPath != nil {
    do {
        eventsNDJSON += try encodeEventLine(RunEvent(
            type: "run_started",
            tick: 0,
            scenario: options.scenario,
            seed: options.seed,
            ticksRequested: options.ticks,
            worldTime: nil,
            success: nil,
            chunksTouched: nil,
            chunkRadius: nil
        ))
        for adopted in scenarioResult.adoptedChunks {
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "chunk_smoke_chunk_adopted",
                tick: 0,
                scenario: options.scenario,
                seed: nil,
                ticksRequested: nil,
                worldTime: nil,
                success: nil,
                chunksTouched: adopted.chunksTouched,
                chunkRadius: scenarioResult.chunkRadius,
                chunkX: adopted.x,
                chunkZ: adopted.z,
                originChunkReady: adopted.x == 0 && adopted.z == 0 ? adopted.originChunkReady : nil,
                centerHeight: nil,
                centerSurfaceY: nil,
                nonAirBlocks: adopted.nonAirBlocks
            ))
        }
        if options.scenario == "chunk_smoke" {
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "chunk_smoke_area_ready",
                tick: 0,
                scenario: options.scenario,
                seed: nil,
                ticksRequested: nil,
                worldTime: nil,
                success: nil,
                chunksTouched: scenarioResult.chunksTouched,
                chunkRadius: scenarioResult.chunkRadius,
                chunkX: nil,
                chunkZ: nil,
                originChunkReady: scenarioResult.originChunkReady,
                centerHeight: scenarioResult.centerHeight,
                centerSurfaceY: scenarioResult.centerSurfaceY,
                nonAirBlocks: nil,
                expectedChunks: scenarioResult.expectedChunks,
                readyChunks: scenarioResult.readyChunks,
                nonAirBlocksTotal: scenarioResult.nonAirBlocksTotal
            ))
        }
        if var agent = labAgent {
            let memoryStart = agent.memory.count
            agent.remember(
                tick: 0,
                type: "spawned",
                summary: "\(agent.id) spawned at (\(agent.position.x),\(agent.position.y),\(agent.position.z))",
                importance: 1.0
            )
            agent.observe(world: world, tick: 0)
            labAgent = agent
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "agent_spawned",
                tick: 0,
                scenario: options.scenario,
                agentId: agent.id,
                agentType: agent.type,
                x: agent.position.x,
                y: agent.position.y,
                z: agent.position.z,
                state: agent.state
            ))
            if let observation = agent.observation {
                eventsNDJSON += try encodeEventLine(RunEvent(
                    type: "agent_observed",
                    tick: 0,
                    scenario: options.scenario,
                    chunkX: observation.chunkX,
                    chunkZ: observation.chunkZ,
                    agentId: agent.id,
                    x: observation.x,
                    y: observation.y,
                    z: observation.z,
                    chunkReady: observation.chunkReady,
                    surfaceY: observation.surfaceY,
                    height: observation.height,
                    blockBelow: observation.blockBelow,
                    blockAtFeet: observation.blockAtFeet
                ))
            }
            for entry in agent.memory.dropFirst(memoryStart) {
                eventsNDJSON += try encodeMemoryEvent(entry, agent: agent, scenario: options.scenario)
            }
        }
    } catch {
        fail("failed to encode run_started event: \(error)")
    }
}

for _ in 0..<options.ticks {
    world.tick()
    ticksCompleted += 1

    if var agent = labAgent {
        let memoryStart = agent.memory.count
        agent.tick()
        agent.observe(world: world, tick: ticksCompleted)
        agent.decideAction(tick: ticksCompleted)
        labAgent = agent
        if options.outPath != nil {
            do {
                eventsNDJSON += try encodeEventLine(RunEvent(
                    type: "agent_tick",
                    tick: ticksCompleted,
                    scenario: options.scenario,
                    agentId: agent.id,
                    state: agent.state,
                    hunger: agent.needs.hunger,
                    fatigue: agent.needs.fatigue,
                    curiosity: agent.needs.curiosity,
                    safety: agent.needs.safety
                ))
                if let observation = agent.observation {
                    eventsNDJSON += try encodeEventLine(RunEvent(
                        type: "agent_observed",
                        tick: ticksCompleted,
                        scenario: options.scenario,
                        chunkX: observation.chunkX,
                        chunkZ: observation.chunkZ,
                        agentId: agent.id,
                        x: observation.x,
                        y: observation.y,
                        z: observation.z,
                        chunkReady: observation.chunkReady,
                        surfaceY: observation.surfaceY,
                        height: observation.height,
                        blockBelow: observation.blockBelow,
                        blockAtFeet: observation.blockAtFeet
                    ))
                }
                if let action = agent.lastAction {
                    eventsNDJSON += try encodeEventLine(RunEvent(
                        type: "agent_action_chosen",
                        tick: ticksCompleted,
                        scenario: options.scenario,
                        agentId: agent.id,
                        state: agent.state,
                        hunger: agent.needs.hunger,
                        fatigue: agent.needs.fatigue,
                        curiosity: agent.needs.curiosity,
                        safety: agent.needs.safety,
                        action: action.name,
                        reason: action.reason
                    ))
                }
                for entry in agent.memory.dropFirst(memoryStart) {
                    eventsNDJSON += try encodeMemoryEvent(entry, agent: agent, scenario: options.scenario)
                }
            } catch {
                fail("failed to encode agent_tick event: \(error)")
            }
        }
    }

    if options.outPath != nil {
        do {
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "world_tick",
                tick: ticksCompleted,
                scenario: nil,
                seed: nil,
                ticksRequested: nil,
                worldTime: world.time,
                success: nil,
                chunksTouched: nil,
                chunkRadius: nil
            ))
        } catch {
            fail("failed to encode world_tick event: \(error)")
        }
    }
}

if options.outPath != nil {
    do {
        eventsNDJSON += try encodeEventLine(RunEvent(
            type: "run_finished",
            tick: ticksCompleted,
            scenario: nil,
            seed: nil,
            ticksRequested: nil,
            worldTime: world.time,
            success: true,
            chunksTouched: nil,
            chunkRadius: nil
        ))
    } catch {
        fail("failed to encode run_finished event: \(error)")
    }
}

if let outPath = options.outPath {
    let outURL = URL(fileURLWithPath: outPath, isDirectory: true)

    do {
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        try writeJSON(
            RunConfig(
                scenario: options.scenario,
                seed: options.seed,
                ticks: options.ticks,
                outPath: outPath
            ),
            to: outURL.appendingPathComponent("config.json")
        )
        try writeJSON(
            RunMetrics(
                scenario: options.scenario,
                seed: options.seed,
                ticksRequested: options.ticks,
                ticksCompleted: ticksCompleted,
                worldTime: world.time,
                success: true,
                chunksTouched: scenarioResult.chunksTouched,
                chunkRadius: scenarioResult.chunkRadius,
                originChunkReady: scenarioResult.originChunkReady,
                centerHeight: scenarioResult.centerHeight,
                centerSurfaceY: scenarioResult.centerSurfaceY,
                nonAirBlocks: scenarioResult.nonAirBlocks,
                expectedChunks: scenarioResult.expectedChunks,
                readyChunks: scenarioResult.readyChunks,
                nonAirBlocksTotal: scenarioResult.nonAirBlocksTotal,
                agentCount: labAgent == nil ? nil : 1,
                agentsSpawned: labAgent == nil ? nil : 1,
                agentTicks: labAgent?.ticksAlive,
                agentObservations: labAgent?.observationCount,
                agentCurrentChunkReady: labAgent?.observation?.chunkReady,
                agentSurfaceY: labAgent?.observation?.surfaceY,
                agentHeight: labAgent?.observation?.height,
                agentActions: labAgent?.actionCount,
                agentLastAction: labAgent?.lastAction?.name,
                agentMemoryEntries: labAgent?.memory.count,
                agentLastMemoryType: labAgent?.memory.last?.type
            ),
            to: outURL.appendingPathComponent("metrics.json")
        )
        if let snapshot = makeWorldSnapshot(
            options: options,
            world: world,
            result: scenarioResult,
            ticksCompleted: ticksCompleted
        ) {
            try writeJSON(snapshot, to: outURL.appendingPathComponent("world_snapshot.json"))
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "world_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                chunks: snapshot.chunks.count,
                path: "world_snapshot.json"
            ))
        }
        if let agent = labAgent, options.scenario == "agent_smoke" {
            try writeJSON(
                AgentSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    agents: [agent]
                ),
                to: outURL.appendingPathComponent("agent_snapshot.json")
            )
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "agent_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                path: "agent_snapshot.json",
                agents: 1
            ))
        }
        try eventsNDJSON.write(
            to: outURL.appendingPathComponent("events.ndjson"),
            atomically: true,
            encoding: .utf8
        )
    } catch {
        fail("failed to write run outputs to \(outPath): \(error)")
    }
}

print("PebbleLab headless scenario=\(options.scenario) dim=\(world.dim.rawValue) seed=\(world.seed) ticks=\(world.time)")
