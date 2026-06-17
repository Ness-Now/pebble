import Foundation
import PebbleCore

let options = parseArguments(CommandLine.arguments)
validateScenario(options.scenario)

let world = World(dim: .overworld, seed: options.seed)
let scenarioResult = prepareScenario(options, world: world)
var labAgents = scenarioResult.agents

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

func encodeNearbyAgentEvents(_ agent: LabAgent, tick: Int) throws -> String {
    var lines = ""
    for nearbyAgent in agent.nearbyAgents {
        lines += try encodeEventLine(RunEvent(
            type: "agent_observed_nearby_agent",
            tick: tick,
            event: "agent_observed_nearby_agent",
            scenario: options.scenario,
            agentId: agent.id,
            otherAgentId: nearbyAgent.id,
            dx: nearbyAgent.dx,
            dy: nearbyAgent.dy,
            dz: nearbyAgent.dz,
            distanceManhattan: nearbyAgent.distanceManhattan
        ))
    }
    return lines
}

func encodeGoalChangeEvent(_ change: LabGoalChange, agent: LabAgent, tick: Int) throws -> String {
    try encodeEventLine(RunEvent(
        type: "agent_goal_changed",
        tick: tick,
        scenario: options.scenario,
        agentId: agent.id,
        reason: change.goal.reason,
        fromGoal: change.from.rawValue,
        toGoal: change.to.rawValue,
        urgency: change.goal.urgency
    ))
}

func encodeSpawnAndInitialObservation(agent: inout LabAgent, allAgents: [LabAgent]) throws -> String {
    var lines = ""
    let memoryStart = agent.memory.count
    agent.remember(
        tick: 0,
        type: "spawned",
        summary: "\(agent.id) spawned at (\(agent.position.x),\(agent.position.y),\(agent.position.z))",
        importance: 1.0
    )
    agent.observe(world: world, tick: 0)
    agent.observeNearbyAgents(allAgents)
    let goalChange = agent.selectGoal(tick: 0)
    lines += try encodeEventLine(RunEvent(
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
        lines += try encodeEventLine(RunEvent(
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
    lines += try encodeNearbyAgentEvents(agent, tick: 0)
    if let goalChange {
        lines += try encodeGoalChangeEvent(goalChange, agent: agent, tick: 0)
    }
    for entry in agent.memory.dropFirst(memoryStart) {
        lines += try encodeMemoryEvent(entry, agent: agent, scenario: options.scenario)
    }
    return lines
}

func tickAndEncodeAgent(_ agent: inout LabAgent, allAgents: [LabAgent]) throws -> String {
    var lines = ""
    let memoryStart = agent.memory.count
    agent.tick()
    agent.observe(world: world, tick: ticksCompleted)
    agent.observeNearbyAgents(allAgents)
    let goalChange = agent.selectGoal(tick: ticksCompleted)
    agent.decideAction(tick: ticksCompleted)
    agent.applyLastActionEffect(tick: ticksCompleted)
    lines += try encodeEventLine(RunEvent(
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
        lines += try encodeEventLine(RunEvent(
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
    lines += try encodeNearbyAgentEvents(agent, tick: ticksCompleted)
    if let goalChange {
        lines += try encodeGoalChangeEvent(goalChange, agent: agent, tick: ticksCompleted)
    }
    if let action = agent.lastAction {
        lines += try encodeEventLine(RunEvent(
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
    if let effect = agent.lastActionEffect {
        lines += try encodeEventLine(RunEvent(
            type: "agent_action_effect_applied",
            tick: ticksCompleted,
            scenario: options.scenario,
            agentId: agent.id,
            action: effect.action,
            effect: effect.effect,
            hungerBefore: effect.hungerBefore,
            hungerAfter: effect.hungerAfter,
            fatigueBefore: effect.fatigueBefore,
            fatigueAfter: effect.fatigueAfter,
            curiosityBefore: effect.curiosityBefore,
            curiosityAfter: effect.curiosityAfter,
            safetyBefore: effect.safetyBefore,
            safetyAfter: effect.safetyAfter,
            stateBefore: effect.stateBefore,
            stateAfter: effect.stateAfter
        ))
    }
    for entry in agent.memory.dropFirst(memoryStart) {
        lines += try encodeMemoryEvent(entry, agent: agent, scenario: options.scenario)
    }
    return lines
}

func sumAgents(_ value: (LabAgent) -> Int) -> Int? {
    guard !labAgents.isEmpty else { return nil }
    return labAgents.reduce(0) { $0 + value($1) }
}

func countAgents(_ include: (LabAgent) -> Bool) -> Int? {
    guard !labAgents.isEmpty else { return nil }
    return labAgents.filter(include).count
}

func goalsByKind() -> [String: Int]? {
    guard !labAgents.isEmpty else { return nil }
    return labAgents.reduce(into: [:]) { counts, agent in
        counts[agent.currentGoal.kind.rawValue, default: 0] += 1
    }
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
        let allAgents = labAgents
        for index in labAgents.indices {
            eventsNDJSON += try encodeSpawnAndInitialObservation(
                agent: &labAgents[index],
                allAgents: allAgents
            )
        }
    } catch {
        fail("failed to encode run_started event: \(error)")
    }
}

for _ in 0..<options.ticks {
    world.tick()
    ticksCompleted += 1

    if !labAgents.isEmpty {
        let allAgents = labAgents
        for index in labAgents.indices {
            if options.outPath != nil {
                do {
                    eventsNDJSON += try tickAndEncodeAgent(&labAgents[index], allAgents: allAgents)
                } catch {
                    fail("failed to encode agent_tick event: \(error)")
                }
            } else {
                labAgents[index].tick()
                labAgents[index].observe(world: world, tick: ticksCompleted)
                labAgents[index].observeNearbyAgents(allAgents)
                _ = labAgents[index].selectGoal(tick: ticksCompleted)
                labAgents[index].decideAction(tick: ticksCompleted)
                labAgents[index].applyLastActionEffect(tick: ticksCompleted)
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
        let primaryAgent = labAgents.first
        let agentCount = labAgents.isEmpty ? nil : labAgents.count
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
                agentCount: agentCount,
                agentsSpawned: agentCount,
                agentTicks: sumAgents { $0.ticksAlive },
                agentObservations: sumAgents { $0.observationCount },
                agentCurrentChunkReady: primaryAgent?.observation?.chunkReady,
                agentSurfaceY: primaryAgent?.observation?.surfaceY,
                agentHeight: primaryAgent?.observation?.height,
                agentActions: sumAgents { $0.actionCount },
                agentLastAction: primaryAgent?.lastAction?.name,
                agentMemoryEntries: sumAgents { $0.memory.count },
                agentLastMemoryType: primaryAgent?.memory.last?.type,
                agentActionEffects: sumAgents { $0.actionEffectCount },
                agentLastActionEffect: primaryAgent?.lastActionEffect?.effect,
                nearbyAgentObservations: sumAgents { $0.nearbyObservationCount },
                agentsWithNearbyAgents: countAgents { !$0.nearbyAgents.isEmpty },
                agentGoalSelections: sumAgents { $0.goalSelectionCount },
                agentGoalChanges: sumAgents { $0.goalChangeCount },
                goalsByKind: goalsByKind()
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
        if !labAgents.isEmpty, options.scenario == "agent_smoke" {
            try writeJSON(
                AgentSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    agents: labAgents
                ),
                to: outURL.appendingPathComponent("agent_snapshot.json")
            )
            eventsNDJSON += try encodeEventLine(RunEvent(
                type: "agent_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                path: "agent_snapshot.json",
                agents: labAgents.count
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
