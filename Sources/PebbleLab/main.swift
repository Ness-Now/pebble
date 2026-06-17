import Foundation
import PebbleCore

let options = parseArguments(CommandLine.arguments)
validateScenario(options.scenario)

let world = World(dim: .overworld, seed: options.seed)
let scenarioResult = prepareScenario(options, world: world)
var labAgents = scenarioResult.agents
var physicalBridge = scenarioResult.physicalBridge
var coreEntityBridge = scenarioResult.coreEntityBridge

var ticksCompleted = 0
var eventsNDJSON = ""
var eventsWritten = 0
var eventsSuppressed = 0
var worldTickEventsWritten = 0
var worldTickEventsSuppressed = 0
var nearbyAgentEventsWritten = 0
var nearbyAgentEventsSuppressed = 0
var physicalSyncEvents = 0
var physicalSyncDistance = 0
var physicalSyncedAgentIds = Set<String>()
var coreEntitySyncEvents = 0
var coreEntitySyncDistance = 0
var coreEntitySyncedAgentIds = Set<String>()

func shouldWriteFrequentEvent(tick: Int) -> Bool {
    options.eventRate == 1 || tick % options.eventRate == 0
}

func appendEvent(_ event: RunEvent) throws {
    eventsNDJSON += try encodeEventLine(event)
    eventsWritten += 1
}

func appendEventLines(_ lines: String) {
    guard !lines.isEmpty else { return }
    eventsWritten += lines.split(separator: "\n", omittingEmptySubsequences: true).count
    eventsNDJSON += lines
}

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
        guard shouldWriteFrequentEvent(tick: tick) else {
            nearbyAgentEventsSuppressed += 1
            eventsSuppressed += 1
            continue
        }

        nearbyAgentEventsWritten += 1
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

func encodeHomeAssignedEvent(_ agent: LabAgent, tick: Int) throws -> String {
    try encodeEventLine(RunEvent(
        type: "agent_home_assigned",
        tick: tick,
        scenario: options.scenario,
        agentId: agent.id,
        reason: "spawn position assigned as home",
        homeX: agent.homePosition.x,
        homeY: agent.homePosition.y,
        homeZ: agent.homePosition.z
    ))
}

func encodeInventoryAssignedEvents(_ agent: LabAgent, tick: Int) throws -> String {
    var lines = ""
    for item in agent.inventory.items.keys.sorted() {
        let count = agent.inventory.count(item)
        lines += try encodeEventLine(RunEvent(
            type: "agent_inventory_assigned",
            tick: tick,
            scenario: options.scenario,
            agentId: agent.id,
            reason: "initial scenario inventory",
            item: item,
            delta: count,
            count: count
        ))
    }
    return lines
}

func encodeFearChangedEvent(_ agent: LabAgent, effect: LabAgentActionEffect, tick: Int) throws -> String {
    try encodeEventLine(RunEvent(
        type: "agent_fear_changed",
        tick: tick,
        scenario: options.scenario,
        agentId: agent.id,
        reason: effect.effect,
        fromValue: effect.fearBefore,
        toValue: effect.fearAfter
    ))
}

func encodeMovementEvent(_ movement: LabAgentMovement, agent: LabAgent) throws -> String {
    try encodeEventLine(RunEvent(
        type: "agent_moved_abstract",
        tick: movement.tick,
        scenario: options.scenario,
        agentId: agent.id,
        fromX: movement.fromX,
        fromY: movement.fromY,
        fromZ: movement.fromZ,
        toX: movement.toX,
        toY: movement.toY,
        toZ: movement.toZ,
        reason: movement.reason,
        dx: movement.dx,
        dy: movement.dy,
        dz: movement.dz,
        distanceManhattan: movement.distanceManhattan,
        goal: movement.goal,
        homeX: movement.homeX,
        homeY: movement.homeY,
        homeZ: movement.homeZ,
        distanceFromHomeBefore: movement.distanceFromHomeBefore,
        distanceFromHomeAfter: movement.distanceFromHomeAfter,
        distanceReducedTowardHome: movement.distanceReducedTowardHome
    ))
}

func makePhysicalSpawnEvent(_ handle: LabPhysicalAgentHandle) -> RunEvent {
    RunEvent(
        type: "lab_physical_agent_spawned",
        tick: handle.spawnedAtTick,
        scenario: options.scenario,
        agentId: handle.agentId,
        x: handle.position.x,
        y: handle.position.y,
        z: handle.position.z,
        physicalId: handle.physicalId,
        kind: handle.kind
    )
}

func makePhysicalSyncEvent(_ sync: LabPhysicalAgentSync) -> RunEvent {
    RunEvent(
        type: "lab_physical_agent_synced",
        tick: sync.tick,
        scenario: options.scenario,
        agentId: sync.agentId,
        x: sync.abstractPosition.x,
        y: sync.abstractPosition.y,
        z: sync.abstractPosition.z,
        fromX: sync.fromPosition.x,
        fromY: sync.fromPosition.y,
        fromZ: sync.fromPosition.z,
        toX: sync.toPosition.x,
        toY: sync.toPosition.y,
        toZ: sync.toPosition.z,
        distanceManhattan: sync.distanceManhattan,
        physicalId: sync.physicalId
    )
}

func makeCoreEntitySpawnEvent(_ entity: LabCoreAgentEntity) -> RunEvent {
    RunEvent(
        type: "lab_core_entity_spawned",
        tick: 0,
        scenario: options.scenario,
        agentId: entity.labAgentId,
        x: Int(entity.x.rounded()),
        y: Int(entity.y.rounded()),
        z: Int(entity.z.rounded()),
        physicalId: entity.physicalId,
        coreEntityId: entity.id,
        kind: entity.type
    )
}

func makeCoreEntitySyncEvent(_ sync: LabCoreAgentSync) -> RunEvent {
    RunEvent(
        type: "lab_core_entity_synced",
        tick: sync.tick,
        scenario: options.scenario,
        agentId: sync.agentId,
        x: sync.abstractPosition.x,
        y: sync.abstractPosition.y,
        z: sync.abstractPosition.z,
        fromX: sync.fromPosition.x,
        fromY: sync.fromPosition.y,
        fromZ: sync.fromPosition.z,
        toX: sync.toPosition.x,
        toY: sync.toPosition.y,
        toZ: sync.toPosition.z,
        distanceManhattan: sync.distanceManhattan,
        physicalId: sync.physicalId,
        coreEntityId: sync.coreEntityId
    )
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
    lines += try encodeHomeAssignedEvent(agent, tick: 0)
    lines += try encodeInventoryAssignedEvents(agent, tick: 0)
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
    let movement = agent.applyAbstractMovement(tick: ticksCompleted)
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
            fearBefore: effect.fearBefore,
            fearAfter: effect.fearAfter,
            stateBefore: effect.stateBefore,
            stateAfter: effect.stateAfter
        ))
        if effect.fearBefore != effect.fearAfter {
            lines += try encodeFearChangedEvent(agent, effect: effect, tick: ticksCompleted)
        }
    }
    if let movement {
        lines += try encodeMovementEvent(movement, agent: agent)
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

func averageAgents(_ value: (LabAgent) -> Int) -> Double? {
    guard !labAgents.isEmpty else { return nil }
    let total = labAgents.reduce(0) { $0 + value($1) }
    return Double(total) / Double(labAgents.count)
}

func minAgentValue(_ value: (LabAgent) -> Int) -> Int? {
    labAgents.map(value).min()
}

func maxAgentValue(_ value: (LabAgent) -> Int) -> Int? {
    labAgents.map(value).max()
}

func goalsByKind() -> [String: Int]? {
    guard !labAgents.isEmpty else { return nil }
    return labAgents.reduce(into: [:]) { counts, agent in
        counts[agent.currentGoal.kind.rawValue, default: 0] += 1
    }
}

func inventoryItemsByKind() -> [String: Int]? {
    guard !labAgents.isEmpty else { return nil }
    return labAgents.reduce(into: [:]) { counts, agent in
        for (item, count) in agent.inventory.items {
            counts[item, default: 0] += count
        }
    }
}

func makeRegressionReport(metrics: RunMetrics, expectedAgents: Int) -> RegressionReport {
    let expectedAgentTicks = expectedAgents * ticksCompleted
    let checks = [
        RegressionCheck(
            name: "ticks_completed",
            passed: metrics.ticksCompleted == metrics.ticksRequested,
            expected: "\(metrics.ticksRequested)",
            actual: "\(metrics.ticksCompleted)"
        ),
        RegressionCheck(
            name: "run_success",
            passed: metrics.success,
            expected: "true",
            actual: "\(metrics.success)"
        ),
        RegressionCheck(
            name: "agents_spawned",
            passed: metrics.agentCount == expectedAgents,
            expected: "\(expectedAgents)",
            actual: "\(metrics.agentCount ?? 0)"
        ),
        RegressionCheck(
            name: "agents_alive",
            passed: metrics.agentsAlive == expectedAgents,
            expected: "\(expectedAgents)",
            actual: "\(metrics.agentsAlive ?? 0)"
        ),
        RegressionCheck(
            name: "agent_ticks_recorded",
            passed: metrics.agentTicks == expectedAgentTicks,
            expected: "\(expectedAgentTicks)",
            actual: "\(metrics.agentTicks ?? 0)"
        ),
        RegressionCheck(
            name: "chunks_ready",
            passed: metrics.readyChunks == metrics.expectedChunks,
            expected: "\(metrics.expectedChunks ?? 0)",
            actual: "\(metrics.readyChunks ?? 0)"
        ),
        RegressionCheck(
            name: "events_written",
            passed: (metrics.eventsWritten ?? 0) > 0,
            expected: "> 0",
            actual: "\(metrics.eventsWritten ?? 0)"
        )
    ]
    let checksFailed = checks.filter { !$0.passed }.count

    return RegressionReport(
        scenario: metrics.scenario,
        seed: metrics.seed,
        success: checksFailed == 0,
        summary: RegressionSummary(
            ticksRequested: metrics.ticksRequested,
            ticksCompleted: metrics.ticksCompleted,
            expectedAgents: expectedAgents,
            actualAgents: metrics.agentCount ?? 0,
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed
        ),
        checks: checks,
        keyMetrics: RegressionKeyMetrics(
            worldTime: metrics.worldTime,
            agentTicks: metrics.agentTicks,
            agentsAlive: metrics.agentsAlive,
            agentMoves: metrics.agentMoves,
            nearbyAgentObservations: metrics.nearbyAgentObservations,
            agentGoalChanges: metrics.agentGoalChanges,
            eventsWritten: metrics.eventsWritten,
            eventsSuppressed: metrics.eventsSuppressed
        ),
        notes: [
            "Regression smoke is compact and in-process; it does not spawn other PebbleLab commands.",
            "Checks summarize this deterministic run and do not replace pebsmoke goldens."
        ]
    )
}

if options.outPath != nil {
    do {
        try appendEvent(RunEvent(
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
            try appendEvent(RunEvent(
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
            try appendEvent(RunEvent(
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
            appendEventLines(try encodeSpawnAndInitialObservation(
                agent: &labAgents[index],
                allAgents: allAgents
            ))
        }
        for handle in physicalBridge.handles {
            try appendEvent(makePhysicalSpawnEvent(handle))
        }
        for entity in coreEntityBridge.entities {
            try appendEvent(makeCoreEntitySpawnEvent(entity))
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
                    appendEventLines(try tickAndEncodeAgent(&labAgents[index], allAgents: allAgents))
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
                _ = labAgents[index].applyAbstractMovement(tick: ticksCompleted)
            }
        }
    }

    physicalBridge.tick()
    let syncs = physicalBridge.sync(with: labAgents, tick: ticksCompleted)
    if !syncs.isEmpty {
        physicalSyncEvents += syncs.count
        physicalSyncDistance += syncs.reduce(0) { $0 + $1.distanceManhattan }
        for sync in syncs {
            physicalSyncedAgentIds.insert(sync.agentId)
        }

        if options.outPath != nil {
            do {
                for sync in syncs {
                    try appendEvent(makePhysicalSyncEvent(sync))
                }
            } catch {
                fail("failed to encode physical sync event: \(error)")
            }
        }
    }

    coreEntityBridge.tick()
    let coreSyncs = coreEntityBridge.sync(with: labAgents, tick: ticksCompleted)
    if !coreSyncs.isEmpty {
        coreEntitySyncEvents += coreSyncs.count
        coreEntitySyncDistance += coreSyncs.reduce(0) { $0 + $1.distanceManhattan }
        for sync in coreSyncs {
            coreEntitySyncedAgentIds.insert(sync.agentId)
        }

        if options.outPath != nil {
            do {
                for sync in coreSyncs {
                    try appendEvent(makeCoreEntitySyncEvent(sync))
                }
            } catch {
                fail("failed to encode core entity sync event: \(error)")
            }
        }
    }

    if options.outPath != nil {
        do {
            if options.logWorldTicks && shouldWriteFrequentEvent(tick: ticksCompleted) {
                try appendEvent(RunEvent(
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
                worldTickEventsWritten += 1
            } else {
                worldTickEventsSuppressed += 1
                eventsSuppressed += 1
            }
        } catch {
            fail("failed to encode world_tick event: \(error)")
        }
    }
}

func makeSuccessCriteria() -> RunSuccessCriteria {
    RunSuccessCriteria(
        ticksCompleted: ticksCompleted == options.ticks,
        agentsSpawned: labAgents.count == scenarioResult.agents.count,
        agentTicksRecorded: labAgents.isEmpty || (sumAgents { $0.ticksAlive } ?? 0) > 0
    )
}

let successCriteria = makeSuccessCriteria()
let coreEntityInvariantReport = options.scenario == "core_entity_smoke"
    ? coreEntityBridge.invariantReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        agents: labAgents,
        physicalBridge: physicalBridge,
        world: world
    )
    : nil
let runSuccess = successCriteria.ticksCompleted
    && successCriteria.agentsSpawned
    && successCriteria.agentTicksRecorded
    && (coreEntityInvariantReport?.success ?? true)

if options.outPath != nil {
    do {
        try appendEvent(RunEvent(
            type: "run_finished",
            tick: ticksCompleted,
            scenario: nil,
            seed: nil,
            ticksRequested: nil,
            worldTime: world.time,
            success: runSuccess,
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
                eventRate: options.eventRate,
                logWorldTicks: options.logWorldTicks,
                outPath: outPath
            ),
            to: outURL.appendingPathComponent("config.json")
        )
        if let snapshot = makeWorldSnapshot(
            options: options,
            world: world,
            result: scenarioResult,
            ticksCompleted: ticksCompleted
        ) {
            try writeJSON(snapshot, to: outURL.appendingPathComponent("world_snapshot.json"))
            try appendEvent(RunEvent(
                type: "world_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                chunks: snapshot.chunks.count,
                path: "world_snapshot.json"
            ))
        }
        if !labAgents.isEmpty, options.scenario == "agent_smoke" || options.scenario == "agents_basic" || options.scenario == "seek_safety_smoke" || options.scenario == "long_run_smoke" || options.scenario == "regression_smoke" || options.scenario == "physical_placeholder_smoke" || options.scenario == "physical_sync_smoke" || options.scenario == "core_entity_smoke" {
            try writeJSON(
                AgentSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    agents: labAgents
                ),
                to: outURL.appendingPathComponent("agent_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "agent_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                path: "agent_snapshot.json",
                agents: labAgents.count
            ))
        }
        if options.scenario == "physical_placeholder_smoke" || options.scenario == "physical_sync_smoke" || options.scenario == "core_entity_smoke" {
            try writeJSON(
                PhysicalSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    physicalAgents: physicalBridge.snapshotLinks(for: labAgents)
                ),
                to: outURL.appendingPathComponent("physical_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "physical_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                path: "physical_snapshot.json",
                agents: physicalBridge.count
            ))
        }
        if options.scenario == "core_entity_smoke" {
            try writeJSON(
                CoreEntitySnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    coreEntities: coreEntityBridge.snapshotLinks(for: labAgents)
                ),
                to: outURL.appendingPathComponent("core_entity_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "core_entity_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                path: "core_entity_snapshot.json",
                agents: coreEntityBridge.count
            ))
            if let coreEntityInvariantReport {
                try writeJSON(
                    coreEntityInvariantReport,
                    to: outURL.appendingPathComponent("core_entity_invariant_report.json")
                )
                try appendEvent(RunEvent(
                    type: "core_entity_invariant_report_written",
                    tick: ticksCompleted,
                    scenario: options.scenario,
                    success: coreEntityInvariantReport.success,
                    path: "core_entity_invariant_report.json"
                ))
            }
        }
        let metrics = RunMetrics(
            scenario: options.scenario,
            seed: options.seed,
            ticksRequested: options.ticks,
            ticksCompleted: ticksCompleted,
            worldTime: world.time,
            success: runSuccess,
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
            goalsByKind: goalsByKind(),
            agentsAlive: countAgents { $0.isAlive },
            averageHealth: averageAgents { $0.health },
            averageFear: averageAgents { $0.fear },
            agentsWithHome: countAgents { _ in true },
            minHealth: minAgentValue { $0.health },
            maxFear: maxAgentValue { $0.fear },
            agentsWithInventory: countAgents { !$0.inventory.isEmpty },
            totalInventoryItems: sumAgents { $0.inventory.totalItemCount },
            inventoryItemsByKind: inventoryItemsByKind(),
            agentMoves: sumAgents { $0.movementCount },
            agentsMoved: countAgents { $0.movementCount > 0 },
            totalManhattanDistanceMoved: sumAgents { $0.totalManhattanDistanceMoved },
            maxDistanceFromHome: maxAgentValue { $0.distanceFromHome },
            averageDistanceFromHome: averageAgents { $0.distanceFromHome },
            agentReturnHomeMoves: sumAgents { $0.returnHomeMoveCount },
            agentsMovedTowardHome: countAgents { $0.returnHomeMoveCount > 0 },
            totalDistanceReducedTowardHome: sumAgents { $0.totalDistanceReducedTowardHome },
            agentsAtHome: countAgents { $0.distanceFromHome == 0 },
            agentsNearHome: countAgents { $0.distanceFromHome <= 1 },
            eventsWritten: eventsWritten,
            eventsSuppressed: eventsSuppressed,
            eventRate: options.eventRate,
            worldTickEventsWritten: worldTickEventsWritten,
            worldTickEventsSuppressed: worldTickEventsSuppressed,
            nearbyAgentEventsWritten: nearbyAgentEventsWritten,
            nearbyAgentEventsSuppressed: nearbyAgentEventsSuppressed,
            physicalAgentsSpawned: physicalBridge.count == 0 ? nil : physicalBridge.count,
            physicalAgentsTicked: physicalBridge.count == 0 ? nil : physicalBridge.tickCount,
            agentsWithPhysicalPlaceholder: physicalBridge.count == 0 ? nil : physicalBridge.snapshotLinks(for: labAgents).count,
            physicalBridgeLinks: physicalBridge.count == 0 ? nil : physicalBridge.linkCount,
            physicalAgentsSynced: physicalBridge.count == 0 ? nil : physicalSyncedAgentIds.count,
            physicalSyncEvents: physicalBridge.count == 0 ? nil : physicalSyncEvents,
            physicalSyncDistance: physicalBridge.count == 0 ? nil : physicalSyncDistance,
            abstractPhysicalDivergence: physicalBridge.count == 0 ? nil : physicalBridge.totalDivergence(from: labAgents),
            maxAbstractPhysicalDivergence: physicalBridge.count == 0 ? nil : physicalBridge.maxDivergence(from: labAgents),
            coreEntitiesSpawned: coreEntityBridge.count == 0 ? nil : coreEntityBridge.count,
            coreEntitiesTicked: coreEntityBridge.count == 0 ? nil : coreEntityBridge.tickCount,
            coreEntityLinks: coreEntityBridge.count == 0 ? nil : coreEntityBridge.linkCount,
            coreEntitiesSynced: coreEntityBridge.count == 0 ? nil : coreEntitySyncedAgentIds.count,
            coreEntitySyncEvents: coreEntityBridge.count == 0 ? nil : coreEntitySyncEvents,
            coreEntitySyncDistance: coreEntityBridge.count == 0 ? nil : coreEntitySyncDistance,
            abstractCoreEntityDivergence: coreEntityBridge.count == 0 ? nil : coreEntityBridge.totalDivergence(from: labAgents),
            maxAbstractCoreEntityDivergence: coreEntityBridge.count == 0 ? nil : coreEntityBridge.maxDivergence(from: labAgents),
            worldEntitiesCount: coreEntityBridge.count == 0 ? nil : world.entities.count,
            successCriteria: successCriteria
        )
        try writeJSON(metrics, to: outURL.appendingPathComponent("metrics.json"))
        if options.scenario == "regression_smoke" {
            try writeJSON(
                makeRegressionReport(metrics: metrics, expectedAgents: labAgents.count),
                to: outURL.appendingPathComponent("regression_report.json")
            )
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
