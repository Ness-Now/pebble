import Foundation
import PebbleCore

let options = parseArguments(CommandLine.arguments)
validateScenario(options.scenario)

let isMultiAgentMovementFixtureScenario = options.scenario
    == "multi_agent_movement_fixture_smoke"
let isMultiAgentMovementFixtureHardeningScenario = options.scenario
    == "multi_agent_movement_fixture_hardening_smoke"
let isMultiAgentLiveCollisionIntentScenario = options.scenario
    == "multi_agent_live_collision_intent_smoke"
let isMultiAgentApprovedPhysicalMovementScenario = options.scenario
    == "multi_agent_approved_physical_movement_smoke"
let isMultiAgentMovementHardeningScenario = options.scenario
    == "multi_agent_movement_hardening_smoke"
let isMultiAgentMovementTickFixtureScenario = options.scenario
    == "multi_agent_movement_tick_fixture_smoke"
let isMultiAgentMovementTickLiveReadonlyScenario = options.scenario
    == "multi_agent_movement_tick_live_readonly_smoke"
let isMultiAgentMovementTickApprovedApplicationScenario = options.scenario
    == "multi_agent_movement_tick_approved_application_smoke"
let isMultiAgentMovementTickHardeningScenario = options.scenario
    == "multi_agent_movement_tick_hardening_smoke"
let isAgentIntentProductionFixtureScenario = options.scenario
    == "agent_intent_production_fixture_smoke"
let isAgentIntentProductionHardeningScenario = options.scenario
    == "agent_intent_production_hardening_smoke"
let isAgentIntentToTickFixtureScenario = options.scenario
    == "agent_intent_to_tick_fixture_smoke"
let isAgentIntentToTickLiveReadonlyScenario = options.scenario
    == "agent_intent_to_tick_live_readonly_smoke"
let isAgentIntentToTickApprovedApplicationScenario = options.scenario
    == "agent_intent_to_tick_approved_application_smoke"
let isAgentFeedbackConsumptionFixtureScenario = options.scenario
    == "agent_feedback_consumption_fixture_smoke"
let isAgentFeedbackConsumptionHardeningScenario = options.scenario
    == "agent_feedback_consumption_hardening_smoke"
let isFeedbackToAgentIntentContextFixtureScenario = options.scenario
    == "feedback_to_agent_intent_context_fixture_smoke"
let isFeedbackToAgentIntentContextHardeningScenario = options.scenario
    == "feedback_to_agent_intent_context_hardening_smoke"
let isFeedbackAwareIntentPolicyFixtureScenario = options.scenario
    == "feedback_aware_intent_policy_fixture_smoke"
let isFeedbackAwareIntentPolicyHardeningScenario = options.scenario
    == "feedback_aware_intent_policy_hardening_smoke"
let isFeedbackAwareIntentToTickFixtureScenario = options.scenario
    == "feedback_aware_intent_to_tick_fixture_smoke"
let isFeedbackAwareIntentToTickLiveReadonlyScenario = options.scenario
    == "feedback_aware_intent_to_tick_live_readonly_smoke"
let isFeedbackAwareIntentToTickApprovedApplicationScenario = options.scenario
    == "feedback_aware_intent_to_tick_approved_application_smoke"
let isMultiTickClosedLoopFixtureScenario = options.scenario
    == "multi_tick_closed_loop_fixture_smoke"
let isMultiTickClosedLoopHardeningScenario = options.scenario
    == "multi_tick_closed_loop_hardening_smoke"
let isMultiTickClosedLoopLiveReadonlyScenario = options.scenario
    == "multi_tick_closed_loop_live_readonly_smoke"
let isMultiTickClosedLoopApprovedApplicationScenario = options.scenario
    == "multi_tick_closed_loop_approved_application_smoke"
let isAlternateLocalHintFixtureScenario = options.scenario
    == "alternate_local_hint_fixture_smoke"
let isAlternateLocalHintHardeningScenario = options.scenario
    == "alternate_local_hint_hardening_smoke"
let world = (isMultiAgentMovementFixtureScenario
    || isMultiAgentMovementFixtureHardeningScenario
    || isMultiAgentMovementTickFixtureScenario
    || isMultiAgentMovementTickLiveReadonlyScenario
    || isMultiAgentMovementTickApprovedApplicationScenario
    || isMultiAgentMovementTickHardeningScenario
    || isAgentIntentProductionFixtureScenario
    || isAgentIntentProductionHardeningScenario
    || isAgentIntentToTickFixtureScenario
    || isAgentIntentToTickLiveReadonlyScenario
    || isAgentIntentToTickApprovedApplicationScenario
    || isAgentFeedbackConsumptionFixtureScenario
    || isAgentFeedbackConsumptionHardeningScenario
    || isFeedbackToAgentIntentContextFixtureScenario
    || isFeedbackToAgentIntentContextHardeningScenario
    || isFeedbackAwareIntentPolicyFixtureScenario
    || isFeedbackAwareIntentPolicyHardeningScenario
    || isFeedbackAwareIntentToTickFixtureScenario
    || isFeedbackAwareIntentToTickLiveReadonlyScenario
    || isFeedbackAwareIntentToTickApprovedApplicationScenario
    || isMultiTickClosedLoopFixtureScenario
    || isMultiTickClosedLoopHardeningScenario
    || isMultiTickClosedLoopLiveReadonlyScenario
    || isMultiTickClosedLoopApprovedApplicationScenario
    || isAlternateLocalHintFixtureScenario
    || isAlternateLocalHintHardeningScenario)
    ? nil
    : World(dim: .overworld, seed: options.seed)
let scenarioResult = world.map { prepareScenario(options, world: $0) } ?? ScenarioResult()
var labAgents = scenarioResult.agents
var physicalBridge = scenarioResult.physicalBridge
var coreEntityBridge = scenarioResult.coreEntityBridge
let isPhysicalBehaviorScenario = options.scenario == "physical_behavior_smoke"
    || options.scenario == "physical_behavior_multi_smoke"
let isWorldObservationSingleScenario = options.scenario == "world_observation_smoke"
let isWorldObservationMultiScenario = options.scenario == "world_observation_multi_smoke"
let isWorldObservationScenario = isWorldObservationSingleScenario || isWorldObservationMultiScenario
let terrainScanContract = terrainScanScenarioContract(for: options.scenario)
let isTerrainScanRun = terrainScanContract != nil
let terrainColumnScanContract = terrainColumnScanScenarioContract(for: options.scenario)
let isTerrainColumnScanRun = terrainColumnScanContract != nil
let isTerrainSemanticsFixtureScenario = options.scenario == "terrain_semantics_fixture_smoke"
let isTerrainTraversabilityFixtureScenario = options.scenario
    == "terrain_traversability_fixture_smoke"
let isTerrainPathfindingFixtureScenario = options.scenario
    == "terrain_pathfinding_fixture_smoke"
let isTerrainPathfindingColumnScenario = options.scenario
    == "terrain_pathfinding_column_smoke"
    || options.scenario == "terrain_pathfinding_column_edge_smoke"
let isTerrainPathfindingPositiveScenario = options.scenario
    == "terrain_pathfinding_column_positive_smoke"
let isTerrainLiveMovementScenario = options.scenario
    == "terrain_path_live_movement_smoke"
let isTerrainMovementFixtureScenario = options.scenario
    == "terrain_path_movement_fixture_smoke"
let isTerrainCollisionFixtureScenario = options.scenario
    == "terrain_collision_fixture_smoke"
let isTerrainCollisionLiveScenario = options.scenario
    == "terrain_collision_live_readonly_smoke"
let isPhysicalMovementDeniedScenario = options.scenario
    == "physical_movement_denied_smoke"
let isPhysicalMovementApprovedScenario = options.scenario
    == "physical_movement_approved_single_step_smoke"
let isPhysicalMovementHardeningScenario = options.scenario
    == "physical_movement_single_step_hardening_smoke"
let isPhysicalMovementOccupableSearchScenario = options.scenario
    == "physical_movement_find_occupable_smoke"
let isRouteFollowingFixtureScenario = options.scenario
    == "route_following_fixture_smoke"
let isRouteFollowingDeniedLiveScenario = options.scenario
    == "route_following_denied_live_smoke"
let isRouteFollowingApprovedTwoStepScenario = options.scenario
    == "route_following_approved_two_step_smoke"
let isRouteFollowingLiveHardeningScenario = options.scenario
    == "route_following_live_hardening_smoke"
let isWorldInteractionScenario = isWorldObservationScenario
    || isTerrainScanRun
    || isTerrainColumnScanRun

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

func requireWorld() -> World {
    guard let world else {
        fail("scenario \(options.scenario) does not create or use World")
    }
    return world
}

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
    agent.observe(world: requireWorld(), tick: 0)
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
    agent.observe(world: requireWorld(), tick: ticksCompleted)
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
        if options.scenario == "physical_behavior_smoke",
           let agent = labAgents.first,
           let handle = physicalBridge.handles.first,
           let entity = coreEntityBridge.entities.first {
            try appendEvent(RunEvent(
                type: "lab_physical_behavior_started",
                tick: 0,
                scenario: options.scenario,
                agentId: agent.id,
                x: agent.position.x,
                y: agent.position.y,
                z: agent.position.z,
                physicalId: handle.physicalId,
                coreEntityId: entity.id
            ))
        } else if options.scenario == "physical_behavior_multi_smoke" {
            try appendEvent(RunEvent(
                type: "lab_physical_behavior_multi_started",
                tick: 0,
                scenario: options.scenario,
                agents: labAgents.count
            ))
        }
    } catch {
        fail("failed to encode run_started event: \(error)")
    }
}

if isMultiAgentMovementTickLiveReadonlyScenario
    || isMultiAgentMovementTickApprovedApplicationScenario
    || isMultiAgentMovementTickHardeningScenario
    || isAgentIntentToTickLiveReadonlyScenario
    || isAgentIntentToTickApprovedApplicationScenario
    || isAgentFeedbackConsumptionFixtureScenario
    || isAgentFeedbackConsumptionHardeningScenario
    || isFeedbackToAgentIntentContextFixtureScenario
    || isFeedbackToAgentIntentContextHardeningScenario
    || isFeedbackAwareIntentPolicyFixtureScenario
    || isFeedbackAwareIntentPolicyHardeningScenario
    || isFeedbackAwareIntentToTickFixtureScenario
    || isFeedbackAwareIntentToTickLiveReadonlyScenario
    || isFeedbackAwareIntentToTickApprovedApplicationScenario
    || isMultiTickClosedLoopFixtureScenario
    || isMultiTickClosedLoopHardeningScenario
    || isMultiTickClosedLoopLiveReadonlyScenario
    || isMultiTickClosedLoopApprovedApplicationScenario {
    ticksCompleted = options.ticks
} else {
    for _ in 0..<options.ticks {
        requireWorld().tick()
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
                    labAgents[index].observe(world: requireWorld(), tick: ticksCompleted)
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
                        worldTime: world?.time ?? 0,
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
}

func makeSuccessCriteria() -> RunSuccessCriteria {
    RunSuccessCriteria(
        ticksCompleted: ticksCompleted == options.ticks,
        agentsSpawned: labAgents.count == scenarioResult.agents.count,
        agentTicksRecorded: labAgents.isEmpty || (sumAgents { $0.ticksAlive } ?? 0) > 0
    )
}

let successCriteria = makeSuccessCriteria()
let terrainSemanticsFixtureReport = isTerrainSemanticsFixtureScenario
    ? makeTerrainSemanticsFixtureReport(scenario: options.scenario, seed: options.seed)
    : nil
let terrainSemanticsFixtureSuccess = terrainSemanticsFixtureReport?.success
let terrainTraversabilityFixtureReport = isTerrainTraversabilityFixtureScenario
    ? makeTerrainTraversabilityFixtureReport(scenario: options.scenario, seed: options.seed)
    : nil
let terrainTraversabilitySummary = terrainTraversabilityFixtureReport.map(
    makeTerrainTraversabilitySummary
)
let terrainTraversabilityInvariantReport = terrainTraversabilityFixtureReport.map(
    makeTerrainTraversabilityInvariantReport
)
let terrainTraversabilitySuccess = isTerrainTraversabilityFixtureScenario
    ? ((terrainTraversabilityFixtureReport?.success ?? false)
        && (terrainTraversabilitySummary?.success ?? false)
        && (terrainTraversabilityInvariantReport?.success ?? false))
    : nil
let terrainPathfindingFixtureReport = isTerrainPathfindingFixtureScenario
    ? makeTerrainPathfindingFixtureReport(scenario: options.scenario, seed: options.seed)
    : nil
let terrainPathfindingInvariantReport = terrainPathfindingFixtureReport.map(
    makeTerrainPathfindingInvariantReport
)
let terrainPathfindingSuccess = isTerrainPathfindingFixtureScenario
    ? ((terrainPathfindingFixtureReport?.success ?? false)
        && (terrainPathfindingInvariantReport?.success ?? false))
    : nil
let terrainMovementFixtureReport = isTerrainMovementFixtureScenario
    ? makeTerrainMovementFixtureReport(scenario: options.scenario, seed: options.seed)
    : nil
let terrainMovementInvariantReport = terrainMovementFixtureReport.map(
    makeTerrainMovementInvariantReport
)
let terrainMovementSuccess = isTerrainMovementFixtureScenario
    ? ((terrainMovementFixtureReport?.success ?? false)
        && (terrainMovementInvariantReport?.success ?? false)
        && terrainMovementFixtureReport?.summary.failed == 0)
    : nil
let terrainCollisionFixtureReport = isTerrainCollisionFixtureScenario
    ? makeTerrainCollisionFixtureReport(scenario: options.scenario, seed: options.seed)
    : nil
let terrainCollisionInvariantReport = terrainCollisionFixtureReport.map(
    makeTerrainCollisionInvariantReport
)
let terrainCollisionSuccess = isTerrainCollisionFixtureScenario
    ? ((terrainCollisionFixtureReport?.success ?? false)
        && (terrainCollisionInvariantReport?.success ?? false)
        && terrainCollisionFixtureReport?.summary.failed == 0)
    : nil
let terrainCollisionLiveSnapshot = isTerrainCollisionLiveScenario
    ? makeTerrainCollisionLiveSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        world: requireWorld()
    )
    : nil
let terrainCollisionLiveInvariantReport = isTerrainCollisionLiveScenario
    ? makeTerrainCollisionLiveInvariantReport(
        snapshot: terrainCollisionLiveSnapshot,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let terrainCollisionLiveSuccess = isTerrainCollisionLiveScenario
    ? ((terrainCollisionLiveSnapshot?.summary.success ?? false)
        && (terrainCollisionLiveInvariantReport?.success ?? false)
        && terrainCollisionLiveSnapshot?.result.reason.isEmpty == false
        && terrainCollisionLiveSnapshot?.summary.movementPerformed == false
        && terrainCollisionLiveSnapshot?.summary.pathfindingPerformed == false
        && terrainCollisionLiveSnapshot?.summary.mutationPerformed == false
        && terrainCollisionLiveSnapshot?.summary.liveAgentDisplaced == false
        && terrainCollisionLiveSnapshot?.summary.physicalPlaceholderDisplaced == false
        && terrainCollisionLiveSnapshot?.summary.coreEntityDisplaced == false)
    : nil
let physicalMovementSnapshot = isPhysicalMovementDeniedScenario
    ? makePhysicalMovementDeniedSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        world: requireWorld()
    )
    : (isPhysicalMovementApprovedScenario
        ? makePhysicalMovementApprovedSingleStepSnapshot(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil)
let isPhysicalMovementIntegrationScenario = isPhysicalMovementDeniedScenario
    || isPhysicalMovementApprovedScenario
let physicalMovementInvariantReport = isPhysicalMovementIntegrationScenario
    ? makePhysicalMovementIntegrationInvariantReport(
        snapshot: physicalMovementSnapshot,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let physicalMovementDeniedSuccess = isPhysicalMovementDeniedScenario
    && (physicalMovementSnapshot?.success ?? false)
    && (physicalMovementInvariantReport?.success ?? false)
    && physicalMovementSnapshot?.displacementApplied == false
    && physicalMovementSnapshot?.status == .collisionDenied
    && physicalMovementSnapshot?.collisionStatus != .occupable
    && physicalMovementSnapshot?.pathfindingPerformed == false
    && physicalMovementSnapshot?.routeFollowingPerformed == false
    && physicalMovementSnapshot?.physicsPerformed == false
    && physicalMovementSnapshot?.mutationPerformed == false
    && physicalMovementSnapshot?.preAbstractPosition == physicalMovementSnapshot?.postAbstractPosition
    && physicalMovementSnapshot?.prePhysicalPosition == physicalMovementSnapshot?.postPhysicalPosition
    && physicalMovementSnapshot?.preCoreEntityPosition == physicalMovementSnapshot?.postCoreEntityPosition
let physicalMovementApprovedSuccess = isPhysicalMovementApprovedScenario
    && (physicalMovementSnapshot?.success ?? false)
    && (physicalMovementInvariantReport?.success ?? false)
    && physicalMovementSnapshot?.status == .approved
    && physicalMovementSnapshot?.displacementApplied == true
    && physicalMovementSnapshot?.collisionStatus == .occupable
    && physicalMovementSnapshot?.divergenceBefore == 0
    && physicalMovementSnapshot?.divergenceAfter == 0
    && physicalMovementSnapshot?.pathfindingPerformed == false
    && physicalMovementSnapshot?.routeFollowingPerformed == false
    && physicalMovementSnapshot?.physicsPerformed == false
    && physicalMovementSnapshot?.mutationPerformed == false
let physicalMovementSuccess = isPhysicalMovementIntegrationScenario
    ? (physicalMovementDeniedSuccess || physicalMovementApprovedSuccess)
    : nil
let physicalMovementOccupableSearchSnapshot = isPhysicalMovementOccupableSearchScenario
    ? makePhysicalMovementOccupableSearchSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        world: requireWorld()
    )
    : nil
let physicalMovementOccupableSearchInvariantReport =
    isPhysicalMovementOccupableSearchScenario
        ? makePhysicalMovementOccupableSearchInvariantReport(
            snapshot: physicalMovementOccupableSearchSnapshot,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let physicalMovementOccupableSearchSuccess = isPhysicalMovementOccupableSearchScenario
    ? ((physicalMovementOccupableSearchSnapshot?.summary.success ?? false)
        && (physicalMovementOccupableSearchInvariantReport?.success ?? false)
        && physicalMovementOccupableSearchSnapshot?.summary.occupableFound == true
        && physicalMovementOccupableSearchSnapshot?.summary.selectedStatus == .occupable
        && physicalMovementOccupableSearchSnapshot?.summary.movementPerformed == false
        && physicalMovementOccupableSearchSnapshot?.summary.agentDisplaced == false
        && physicalMovementOccupableSearchSnapshot?.summary.physicalPlaceholderDisplaced == false
        && physicalMovementOccupableSearchSnapshot?.summary.coreEntityDisplaced == false
        && physicalMovementOccupableSearchSnapshot?.summary.pathfindingPerformed == false
        && physicalMovementOccupableSearchSnapshot?.summary.routeFollowingPerformed == false
        && physicalMovementOccupableSearchSnapshot?.summary.physicsPerformed == false
        && physicalMovementOccupableSearchSnapshot?.summary.mutationPerformed == false)
    : nil
let physicalMovementHardeningReport = isPhysicalMovementHardeningScenario
    ? makePhysicalMovementSingleStepHardeningReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let physicalMovementHardeningInvariantReport = isPhysicalMovementHardeningScenario
    ? makePhysicalMovementHardeningInvariantReport(
        report: physicalMovementHardeningReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let physicalMovementHardeningSuccess = isPhysicalMovementHardeningScenario
    ? ((physicalMovementHardeningReport?.success ?? false)
        && (physicalMovementHardeningInvariantReport?.success ?? false)
        && physicalMovementHardeningReport?.summary.failed == 0
        && physicalMovementHardeningReport?.summary.displacementApplied == 1
        && physicalMovementHardeningReport?.summary.displacementRefused == (physicalMovementHardeningReport?.summary.cases ?? 0) - 1
        && (physicalMovementHardeningReport?.cases.allSatisfy {
            !$0.snapshot.pathfindingPerformed
                && !$0.snapshot.routeFollowingPerformed
                && !$0.snapshot.physicsPerformed
                && !$0.snapshot.mutationPerformed
        } ?? false))
    : nil
let routeFollowingFixtureReport = isRouteFollowingFixtureScenario
    ? makeRouteFollowingFixtureReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let routeFollowingFixtureInvariantReport = isRouteFollowingFixtureScenario
    ? makeRouteFollowingFixtureInvariantReport(
        report: routeFollowingFixtureReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let routeFollowingFixtureSuccess = isRouteFollowingFixtureScenario
    ? ((routeFollowingFixtureReport?.success ?? false)
        && (routeFollowingFixtureInvariantReport?.success ?? false)
        && routeFollowingFixtureReport?.summary.failed == 0
        && (routeFollowingFixtureReport?.summary.completed ?? 0) >= 1
        && (routeFollowingFixtureReport?.summary.stopped ?? 0) >= 1)
    : nil
let multiAgentMovementFixtureReport = isMultiAgentMovementFixtureScenario
    ? makeMultiAgentMovementFixtureReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let multiAgentMovementFixtureInvariantReport = isMultiAgentMovementFixtureScenario
    ? makeMultiAgentMovementFixtureInvariantReport(
        report: multiAgentMovementFixtureReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiAgentMovementFixtureSuccess = isMultiAgentMovementFixtureScenario
    ? ((multiAgentMovementFixtureReport?.success ?? false)
        && (multiAgentMovementFixtureInvariantReport?.success ?? false)
        && multiAgentMovementFixtureReport?.summary.failed == 0
        && (multiAgentMovementFixtureReport?.summary.approvedTotal ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.deniedTotal ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.sameDestinationConflicts ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.occupiedDestinationConflicts ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.swapConflicts ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.sourceMismatch ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.staleIntent ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.missingAgent ?? 0) > 0
        && (multiAgentMovementFixtureReport?.summary.invalidEdges ?? 0) > 0
        && multiAgentMovementFixtureReport?.summary.pathfindingPerformed == false
        && multiAgentMovementFixtureReport?.summary.replanningPerformed == false
        && multiAgentMovementFixtureReport?.summary.goalSelectionPerformed == false
        && multiAgentMovementFixtureReport?.summary.avoidancePerformed == false
        && multiAgentMovementFixtureReport?.summary.reservationTableImplemented == false
        && multiAgentMovementFixtureReport?.summary.physicsPerformed == false
        && multiAgentMovementFixtureReport?.summary.worldUsed == false
        && multiAgentMovementFixtureReport?.summary.mutationPerformed == false)
    : nil
let multiAgentMovementFixtureHardeningReport =
    isMultiAgentMovementFixtureHardeningScenario
        ? makeMultiAgentMovementFixtureHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let multiAgentMovementFixtureHardeningInvariantReport =
    isMultiAgentMovementFixtureHardeningScenario
        ? makeMultiAgentMovementFixtureHardeningInvariantReport(
            report: multiAgentMovementFixtureHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementFixtureHardeningSuccess =
    isMultiAgentMovementFixtureHardeningScenario
        ? ((multiAgentMovementFixtureHardeningReport?.success ?? false)
            && (multiAgentMovementFixtureHardeningInvariantReport?.success ?? false)
            && multiAgentMovementFixtureHardeningReport?.summary.failed == 0
            && (multiAgentMovementFixtureHardeningReport?.summary.duplicateIntent ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.cycleConflicts ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.chainDependencies ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.movingAwayDestination ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.verticalInvalidEdges ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.zeroLengthEdges ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.allDeniedCases ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.emptyIntentCases ?? 0) > 0
            && (multiAgentMovementFixtureHardeningReport?.summary.maxAgentsExceeded ?? 0) > 0
            && multiAgentMovementFixtureHardeningReport?.summary.worldUsed == false
            && multiAgentMovementFixtureHardeningReport?.summary.pathfindingPerformed == false
            && multiAgentMovementFixtureHardeningReport?.summary.replanningPerformed == false
            && multiAgentMovementFixtureHardeningReport?.summary.goalSelectionPerformed == false
            && multiAgentMovementFixtureHardeningReport?.summary.avoidancePerformed == false
            && multiAgentMovementFixtureHardeningReport?.summary.reservationTableImplemented == false
            && multiAgentMovementFixtureHardeningReport?.summary.physicsPerformed == false
            && multiAgentMovementFixtureHardeningReport?.summary.mutationPerformed == false)
        : nil
let multiAgentLiveCollisionIntentReport = isMultiAgentLiveCollisionIntentScenario
    ? makeMultiAgentLiveCollisionIntentReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let multiAgentLiveCollisionIntentInvariantReport =
    isMultiAgentLiveCollisionIntentScenario
        ? makeMultiAgentLiveCollisionIntentInvariantReport(
            report: multiAgentLiveCollisionIntentReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentLiveCollisionIntentSuccess =
    isMultiAgentLiveCollisionIntentScenario
        ? ((multiAgentLiveCollisionIntentReport?.success ?? false)
            && (multiAgentLiveCollisionIntentInvariantReport?.success ?? false)
            && multiAgentLiveCollisionIntentReport?.summary.failed == 0
            && (multiAgentLiveCollisionIntentReport?.summary.occupableDestinations ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.nonOccupableDestinations ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.approvedTotal ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.collisionDenied ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.sameDestinationConflicts ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.sourceMismatch ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.invalidEdges ?? 0) > 0
            && (multiAgentLiveCollisionIntentReport?.summary.staleIntent ?? 0) > 0
            && multiAgentLiveCollisionIntentReport?.summary.worldUsed == true
            && multiAgentLiveCollisionIntentReport?.summary.liveCollisionRead == true
            && multiAgentLiveCollisionIntentReport?.summary.displacementApplied == false
            && multiAgentLiveCollisionIntentReport?.summary.physicalMovementApplied == false
            && multiAgentLiveCollisionIntentReport?.summary.routeFollowingApplied == false
            && multiAgentLiveCollisionIntentReport?.summary.pathfindingPerformed == false
            && multiAgentLiveCollisionIntentReport?.summary.replanningPerformed == false
            && multiAgentLiveCollisionIntentReport?.summary.goalSelectionPerformed == false
            && multiAgentLiveCollisionIntentReport?.summary.avoidancePerformed == false
            && multiAgentLiveCollisionIntentReport?.summary.reservationTableImplemented == false
            && multiAgentLiveCollisionIntentReport?.summary.physicsPerformed == false
            && multiAgentLiveCollisionIntentReport?.summary.mutationPerformed == false)
        : nil
let multiAgentApprovedPhysicalMovementReport =
    isMultiAgentApprovedPhysicalMovementScenario
        ? makeMultiAgentApprovedPhysicalMovementReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let multiAgentApprovedPhysicalMovementInvariantReport =
    isMultiAgentApprovedPhysicalMovementScenario
        ? makeMultiAgentApprovedPhysicalMovementInvariantReport(
            report: multiAgentApprovedPhysicalMovementReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentApprovedPhysicalMovementSuccess =
    isMultiAgentApprovedPhysicalMovementScenario
        ? ((multiAgentApprovedPhysicalMovementReport?.success ?? false)
            && (multiAgentApprovedPhysicalMovementInvariantReport?.success ?? false)
            && multiAgentApprovedPhysicalMovementReport?.summary.failed == 0
            && (multiAgentApprovedPhysicalMovementReport?.summary.agentCountTotal ?? 0) >= 2
            && (multiAgentApprovedPhysicalMovementReport?.summary.intentCountTotal ?? 0) >= 2
            && (multiAgentApprovedPhysicalMovementReport?.summary.occupableDestinations ?? 0) == multiAgentApprovedPhysicalMovementReport?.summary.intentCountTotal
            && multiAgentApprovedPhysicalMovementReport?.summary.nonOccupableDestinations == 0
            && (multiAgentApprovedPhysicalMovementReport?.summary.approvedTotal ?? 0) >= 2
            && multiAgentApprovedPhysicalMovementReport?.summary.deniedTotal == 0
            && multiAgentApprovedPhysicalMovementReport?.summary.displacementsApplied == multiAgentApprovedPhysicalMovementReport?.summary.approvedTotal
            && multiAgentApprovedPhysicalMovementReport?.summary.divergenceBeforeMax == 0
            && multiAgentApprovedPhysicalMovementReport?.summary.divergenceAfterMax == 0
            && multiAgentApprovedPhysicalMovementReport?.summary.worldUsed == true
            && multiAgentApprovedPhysicalMovementReport?.summary.liveCollisionRead == true
            && multiAgentApprovedPhysicalMovementReport?.summary.physicalMovementApplied == true
            && multiAgentApprovedPhysicalMovementReport?.summary.routeFollowingApplied == false
            && multiAgentApprovedPhysicalMovementReport?.summary.pathfindingPerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.replanningPerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.goalSelectionPerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.avoidancePerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.reservationTableImplemented == false
            && multiAgentApprovedPhysicalMovementReport?.summary.physicsPerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.terrainMutationPerformed == false
            && multiAgentApprovedPhysicalMovementReport?.summary.worldMutationPerformed == false)
        : nil
let multiAgentMovementHardeningReport = isMultiAgentMovementHardeningScenario
    ? makeMultiAgentMovementHardeningReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let multiAgentMovementHardeningInvariantReport =
    isMultiAgentMovementHardeningScenario
        ? makeMultiAgentMovementHardeningInvariantReport(
            report: multiAgentMovementHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementHardeningSuccess =
    isMultiAgentMovementHardeningScenario
        ? ((multiAgentMovementHardeningReport?.success ?? false)
            && (multiAgentMovementHardeningInvariantReport?.success ?? false)
            && multiAgentMovementHardeningReport?.summary.failed == 0
            && (multiAgentMovementHardeningReport?.summary.approvedTotal ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.deniedTotal ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.displacementsApplied ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.partialApprovalCases ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.collisionDenied ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.sameDestinationConflicts ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.swapConflicts ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.sourceMismatch ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.staleIntent ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.invalidEdges ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.divergenceDenied ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.staleCollision ?? 0) > 0
            && (multiAgentMovementHardeningReport?.summary.maxAgentsExceeded ?? 0) > 0
            && multiAgentMovementHardeningReport?.summary.worldUsed == true
            && multiAgentMovementHardeningReport?.summary.liveCollisionRead == true
            && multiAgentMovementHardeningReport?.summary.physicalMovementApplied == true
            && multiAgentMovementHardeningReport?.summary.routeFollowingApplied == false
            && multiAgentMovementHardeningReport?.summary.pathfindingPerformed == false
            && multiAgentMovementHardeningReport?.summary.replanningPerformed == false
            && multiAgentMovementHardeningReport?.summary.goalSelectionPerformed == false
            && multiAgentMovementHardeningReport?.summary.avoidancePerformed == false
            && multiAgentMovementHardeningReport?.summary.reservationTableImplemented == false
            && multiAgentMovementHardeningReport?.summary.physicsPerformed == false
            && multiAgentMovementHardeningReport?.summary.terrainMutationPerformed == false
            && multiAgentMovementHardeningReport?.summary.worldMutationPerformed == false)
        : nil
let multiAgentMovementTickFixtureReport = isMultiAgentMovementTickFixtureScenario
    ? makeMultiAgentMovementTickFixtureReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let multiAgentMovementTickFixtureInvariantReport =
    isMultiAgentMovementTickFixtureScenario
        ? makeMultiAgentMovementTickFixtureInvariantReport(
            report: multiAgentMovementTickFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementTickFixtureSuccess =
    isMultiAgentMovementTickFixtureScenario
        ? ((multiAgentMovementTickFixtureReport?.success ?? false)
            && (multiAgentMovementTickFixtureInvariantReport?.success ?? false)
            && multiAgentMovementTickFixtureReport?.summary.agentCount == 4
            && multiAgentMovementTickFixtureReport?.summary.physicalPositionCount == 4
            && multiAgentMovementTickFixtureReport?.summary.intentCount == 4
            && multiAgentMovementTickFixtureReport?.summary.resolutions == 4
            && multiAgentMovementTickFixtureReport?.summary.feedbackCount == 4
            && multiAgentMovementTickFixtureReport?.summary.approved == 2
            && multiAgentMovementTickFixtureReport?.summary.denied == 2
            && multiAgentMovementTickFixtureReport?.summary.sameDestinationConflicts == 1
            && multiAgentMovementTickFixtureReport?.summary.invalidEdges == 1
            && multiAgentMovementTickFixtureReport?.summary.displacementsApplied == 0
            && multiAgentMovementTickFixtureReport?.output.abstractPositionsBefore == multiAgentMovementTickFixtureReport?.output.abstractPositionsAfter
            && multiAgentMovementTickFixtureReport?.output.physicalPositionsBefore == multiAgentMovementTickFixtureReport?.output.physicalPositionsAfter
            && multiAgentMovementTickFixtureReport?.summary.worldUsed == false
            && multiAgentMovementTickFixtureReport?.summary.liveCollisionRead == false
            && multiAgentMovementTickFixtureReport?.summary.physicalMovementApplied == false
            && multiAgentMovementTickFixtureReport?.summary.routeFollowingApplied == false
            && multiAgentMovementTickFixtureReport?.summary.pathfindingPerformed == false
            && multiAgentMovementTickFixtureReport?.summary.replanningPerformed == false
            && multiAgentMovementTickFixtureReport?.summary.avoidancePerformed == false
            && multiAgentMovementTickFixtureReport?.summary.reservationRuntimeUsed == false
            && multiAgentMovementTickFixtureReport?.summary.physicsPerformed == false
            && multiAgentMovementTickFixtureReport?.summary.mutationPerformed == false)
        : nil
let multiAgentMovementTickLiveReadonlyReport =
    isMultiAgentMovementTickLiveReadonlyScenario
        ? makeMultiAgentMovementTickLiveReadonlyReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let multiAgentMovementTickLiveReadonlyInvariantReport =
    isMultiAgentMovementTickLiveReadonlyScenario
        ? makeMultiAgentMovementTickLiveReadonlyInvariantReport(
            report: multiAgentMovementTickLiveReadonlyReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementTickLiveReadonlySuccess =
    isMultiAgentMovementTickLiveReadonlyScenario
        ? ((multiAgentMovementTickLiveReadonlyReport?.success ?? false)
            && (multiAgentMovementTickLiveReadonlyInvariantReport?.success ?? false)
            && multiAgentMovementTickLiveReadonlyReport?.summary.agentCount == 5
            && multiAgentMovementTickLiveReadonlyReport?.summary.physicalPositionCount == 5
            && multiAgentMovementTickLiveReadonlyReport?.summary.intentCount == 5
            && multiAgentMovementTickLiveReadonlyReport?.summary.resolutions == 5
            && multiAgentMovementTickLiveReadonlyReport?.summary.feedbackCount == 5
            && (multiAgentMovementTickLiveReadonlyReport?.summary.occupableDestinations ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.nonOccupableDestinations ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.approved ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.denied ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.collisionDenied ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.sourceMismatch ?? 0) > 0
            && (multiAgentMovementTickLiveReadonlyReport?.summary.invalidEdges ?? 0) > 0
            && multiAgentMovementTickLiveReadonlyReport?.summary.displacementsApplied == 0
            && multiAgentMovementTickLiveReadonlyReport?.output.abstractPositionsBefore == multiAgentMovementTickLiveReadonlyReport?.output.abstractPositionsAfter
            && multiAgentMovementTickLiveReadonlyReport?.output.physicalPositionsBefore == multiAgentMovementTickLiveReadonlyReport?.output.physicalPositionsAfter
            && multiAgentMovementTickLiveReadonlyReport?.summary.worldUsed == true
            && multiAgentMovementTickLiveReadonlyReport?.summary.liveCollisionRead == true
            && multiAgentMovementTickLiveReadonlyReport?.summary.physicalMovementApplied == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.routeFollowingApplied == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.pathfindingPerformed == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.replanningPerformed == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.avoidancePerformed == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.reservationRuntimeUsed == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.physicsPerformed == false
            && multiAgentMovementTickLiveReadonlyReport?.summary.mutationPerformed == false)
        : nil
let multiAgentMovementTickApprovedApplicationReport =
    isMultiAgentMovementTickApprovedApplicationScenario
        ? makeMultiAgentMovementTickApprovedApplicationReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let multiAgentMovementTickApprovedApplicationInvariantReport =
    isMultiAgentMovementTickApprovedApplicationScenario
        ? makeMultiAgentMovementTickApprovedApplicationInvariantReport(
            report: multiAgentMovementTickApprovedApplicationReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementTickApprovedApplicationSuccess =
    isMultiAgentMovementTickApprovedApplicationScenario
        ? ((multiAgentMovementTickApprovedApplicationReport?.success ?? false)
            && (multiAgentMovementTickApprovedApplicationInvariantReport?.success ?? false)
            && multiAgentMovementTickApprovedApplicationReport?.summary.agentCount == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.physicalPositionCount == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.intentCount == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.resolutions == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.feedbackCount == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.occupableDestinations == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.nonOccupableDestinations == 0
            && multiAgentMovementTickApprovedApplicationReport?.summary.approved == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.denied == 0
            && multiAgentMovementTickApprovedApplicationReport?.summary.displacementsApplied == 2
            && multiAgentMovementTickApprovedApplicationReport?.summary.divergenceBeforeMax == 0
            && multiAgentMovementTickApprovedApplicationReport?.summary.divergenceAfterMax == 0
            && multiAgentMovementTickApprovedApplicationReport?.output.abstractPositionsAfter == multiAgentMovementTickApprovedApplicationReport?.output.physicalPositionsAfter
            && multiAgentMovementTickApprovedApplicationReport?.output.resolutions.allSatisfy {
                let abstractDelta = abs($0.abstractAfter.x - $0.abstractBefore.x)
                    + abs($0.abstractAfter.y - $0.abstractBefore.y)
                    + abs($0.abstractAfter.z - $0.abstractBefore.z)
                let physicalDelta = abs($0.physicalAfter.x - $0.physicalBefore.x)
                    + abs($0.physicalAfter.y - $0.physicalBefore.y)
                    + abs($0.physicalAfter.z - $0.physicalBefore.z)
                return $0.feedbackKind == .moved
                    && $0.displacementApplied
                    && abstractDelta == 1
                    && physicalDelta == 1
                    && $0.abstractBefore.y == $0.abstractAfter.y
                    && $0.physicalBefore.y == $0.physicalAfter.y
            } == true
            && multiAgentMovementTickApprovedApplicationReport?.summary.worldUsed == true
            && multiAgentMovementTickApprovedApplicationReport?.summary.liveCollisionRead == true
            && multiAgentMovementTickApprovedApplicationReport?.summary.physicalMovementApplied == true
            && multiAgentMovementTickApprovedApplicationReport?.summary.routeFollowingApplied == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.pathfindingPerformed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.replanningPerformed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.avoidancePerformed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.reservationRuntimeUsed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.physicsPerformed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.terrainMutationPerformed == false
            && multiAgentMovementTickApprovedApplicationReport?.summary.worldMutationPerformed == false)
        : nil
let multiAgentMovementTickHardeningReport =
    isMultiAgentMovementTickHardeningScenario
        ? makeMultiAgentMovementTickHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let multiAgentMovementTickHardeningInvariantReport =
    isMultiAgentMovementTickHardeningScenario
        ? makeMultiAgentMovementTickHardeningInvariantReport(
            report: multiAgentMovementTickHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let multiAgentMovementTickHardeningSuccess =
    isMultiAgentMovementTickHardeningScenario
        ? ((multiAgentMovementTickHardeningReport?.success ?? false)
            && (multiAgentMovementTickHardeningInvariantReport?.success ?? false)
            && multiAgentMovementTickHardeningReport?.summary.cases == 12
            && multiAgentMovementTickHardeningReport?.summary.failed == 0
            && (multiAgentMovementTickHardeningReport?.summary.approvedTotal ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.deniedTotal ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.displacementsApplied ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.collisionDenied ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.partialApprovalCases ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.sameDestinationConflicts ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.swapConflicts ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.sourceMismatch ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.staleIntent ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.invalidEdges ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.divergenceDenied ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.staleCollision ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.allDeniedCases ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.maxAgentsExceeded ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.movedFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByCollisionFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByAgentConflictFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedBySourceMismatchFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByDivergenceFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByStaleIntentFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByInvalidEdgeFeedback ?? 0) > 0
            && (multiAgentMovementTickHardeningReport?.summary.blockedByMaxAgentsFeedback ?? 0) > 0
            && multiAgentMovementTickHardeningReport?.summary.routeFollowingApplied == false
            && multiAgentMovementTickHardeningReport?.summary.pathfindingPerformed == false
            && multiAgentMovementTickHardeningReport?.summary.replanningPerformed == false
            && multiAgentMovementTickHardeningReport?.summary.avoidancePerformed == false
            && multiAgentMovementTickHardeningReport?.summary.reservationRuntimeUsed == false
            && multiAgentMovementTickHardeningReport?.summary.physicsPerformed == false
            && multiAgentMovementTickHardeningReport?.summary.terrainMutationPerformed == false
            && multiAgentMovementTickHardeningReport?.summary.worldMutationPerformed == false)
        : nil
let agentIntentProductionFixtureReport =
    isAgentIntentProductionFixtureScenario
        ? makeAgentIntentProductionFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentIntentProductionFixtureInvariantReport =
    isAgentIntentProductionFixtureScenario
        ? makeAgentIntentProductionFixtureInvariantReport(
            report: agentIntentProductionFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentIntentProductionFixtureSuccess =
    isAgentIntentProductionFixtureScenario
        ? ((agentIntentProductionFixtureReport?.success ?? false)
            && (agentIntentProductionFixtureInvariantReport?.success ?? false)
            && agentIntentProductionFixtureReport?.summary.contexts == 5
            && agentIntentProductionFixtureReport?.summary.proposals == 5
            && agentIntentProductionFixtureReport?.summary.acceptedIntents == 2
            && agentIntentProductionFixtureReport?.summary.rejectedProposals == 3
            && agentIntentProductionFixtureReport?.summary.noIntent == 1
            && agentIntentProductionFixtureReport?.summary.invalidContext == 1
            && agentIntentProductionFixtureReport?.summary.invalidOneEdgeProposals == 1
            && agentIntentProductionFixtureReport?.result.contexts.map(\.agentId)
                != agentIntentProductionFixtureReport?.result.contexts.map(\.agentId).sorted()
            && agentIntentProductionFixtureReport?.result.proposals.map(\.agentId)
                == agentIntentProductionFixtureReport?.result.proposals.map(\.agentId).sorted()
            && agentIntentProductionFixtureReport?.result.acceptedIntents.map(\.agentId)
                == agentIntentProductionFixtureReport?.result.acceptedIntents.map(\.agentId).sorted()
            && agentIntentProductionFixtureReport?.result.acceptedIntents.allSatisfy {
                abs($0.from.x - $0.to.x) + abs($0.from.y - $0.to.y) + abs($0.from.z - $0.to.z) == 1
                    && $0.from.y == $0.to.y
            } == true
            && Set(agentIntentProductionFixtureReport?.result.acceptedIntents.map(\.to) ?? []).count == 1
            && agentIntentProductionFixtureReport?.summary.worldUsed == false
            && agentIntentProductionFixtureReport?.summary.collisionRead == false
            && agentIntentProductionFixtureReport?.summary.movementApplied == false
            && agentIntentProductionFixtureReport?.summary.feedbackConsumed == false
            && agentIntentProductionFixtureReport?.summary.memoryUpdated == false
            && agentIntentProductionFixtureReport?.summary.goalChanged == false
            && agentIntentProductionFixtureReport?.summary.pathfindingPerformed == false
            && agentIntentProductionFixtureReport?.summary.replanningPerformed == false
            && agentIntentProductionFixtureReport?.summary.avoidancePerformed == false
            && agentIntentProductionFixtureReport?.summary.reservationRuntimeUsed == false
            && agentIntentProductionFixtureReport?.summary.mutationPerformed == false)
        : nil
let agentIntentProductionHardeningReport =
    isAgentIntentProductionHardeningScenario
        ? makeAgentIntentProductionHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentIntentProductionHardeningInvariantReport =
    isAgentIntentProductionHardeningScenario
        ? makeAgentIntentProductionHardeningInvariantReport(
            report: agentIntentProductionHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentIntentProductionHardeningSuccess =
    isAgentIntentProductionHardeningScenario
        ? ((agentIntentProductionHardeningReport?.success ?? false)
            && (agentIntentProductionHardeningInvariantReport?.success ?? false)
            && agentIntentProductionHardeningReport?.summary.cases == 10
            && agentIntentProductionHardeningReport?.summary.failed == 0
            && (agentIntentProductionHardeningReport?.summary.acceptedIntentsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.rejectedProposalsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.noIntentTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.invalidContextTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.duplicateAgentContextsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.duplicateProposalsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.invalidOneEdgeProposalsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.staleProposalsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.wrongSourceProposalsTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.maxProposalsExceededTotal ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.acceptedMoveEast ?? 0) > 0
            && (agentIntentProductionHardeningReport?.summary.acceptedMoveWest ?? 0) > 0
            && agentIntentProductionHardeningReport?.cases.allSatisfy { caseResult in
                caseResult.result.acceptedIntents.allSatisfy {
                    abs($0.from.x - $0.to.x) + abs($0.from.y - $0.to.y) + abs($0.from.z - $0.to.z) == 1
                        && $0.from.y == $0.to.y
                }
            } == true
            && agentIntentProductionHardeningReport?.summary.worldUsed == false
            && agentIntentProductionHardeningReport?.summary.collisionRead == false
            && agentIntentProductionHardeningReport?.summary.movementApplied == false
            && agentIntentProductionHardeningReport?.summary.feedbackConsumed == false
            && agentIntentProductionHardeningReport?.summary.memoryUpdated == false
            && agentIntentProductionHardeningReport?.summary.goalChanged == false
            && agentIntentProductionHardeningReport?.summary.pathfindingPerformed == false
            && agentIntentProductionHardeningReport?.summary.replanningPerformed == false
            && agentIntentProductionHardeningReport?.summary.avoidancePerformed == false
            && agentIntentProductionHardeningReport?.summary.reservationRuntimeUsed == false
            && agentIntentProductionHardeningReport?.summary.physicsPerformed == false
            && agentIntentProductionHardeningReport?.summary.mutationPerformed == false)
        : nil
let agentIntentToTickFixtureReport =
    isAgentIntentToTickFixtureScenario
        ? makeAgentIntentToTickFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentIntentToTickFixtureInvariantReport =
    isAgentIntentToTickFixtureScenario
        ? makeAgentIntentToTickFixtureInvariantReport(
            report: agentIntentToTickFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentIntentToTickFixtureSuccess =
    isAgentIntentToTickFixtureScenario
        ? ((agentIntentToTickFixtureReport?.success ?? false)
            && (agentIntentToTickFixtureInvariantReport?.success ?? false)
            && agentIntentToTickFixtureReport?.summary.contexts == 4
            && agentIntentToTickFixtureReport?.summary.proposals == 4
            && agentIntentToTickFixtureReport?.summary.acceptedIntents == 2
            && agentIntentToTickFixtureReport?.summary.rejectedProposals == 2
            && agentIntentToTickFixtureReport?.intentProduction.summary.noIntent == 1
            && agentIntentToTickFixtureReport?.intentProduction.summary.invalidOneEdgeProposals == 1
            && agentIntentToTickFixtureReport?.intentProduction.acceptedIntents.map(\.agentId)
                == agentIntentToTickFixtureReport?.intentProduction.acceptedIntents.map(\.agentId).sorted()
            && agentIntentToTickFixtureReport?.intentProduction.acceptedIntents.allSatisfy {
                abs($0.from.x - $0.to.x) + abs($0.from.y - $0.to.y) + abs($0.from.z - $0.to.z) == 1
                    && $0.from.y == $0.to.y
            } == true
            && agentIntentToTickFixtureReport?.summary.productionAcceptedSameDestination == true
            && agentIntentToTickFixtureReport?.summary.tickResolvedSameDestination == true
            && agentIntentToTickFixtureReport?.summary.tickApproved == 1
            && agentIntentToTickFixtureReport?.summary.tickDenied == 1
            && agentIntentToTickFixtureReport?.summary.tickFeedback == 2
            && agentIntentToTickFixtureReport?.tickOutput.resolutions.contains {
                $0.agentId == "agent_0" && $0.decision == .approved && $0.approved
            } == true
            && agentIntentToTickFixtureReport?.tickOutput.resolutions.contains {
                $0.agentId == "agent_1" && $0.decision == .deniedSameDestinationConflict && !$0.approved
            } == true
            && agentIntentToTickFixtureReport?.tickOutput.feedback.contains {
                $0.agentId == "agent_0" && $0.kind == .approvedForMovement
            } == true
            && agentIntentToTickFixtureReport?.tickOutput.feedback.contains {
                $0.agentId == "agent_1" && $0.kind == .blockedByAgentConflict
            } == true
            && agentIntentToTickFixtureReport?.tickOutput.abstractPositionsBefore
                == agentIntentToTickFixtureReport?.tickOutput.abstractPositionsAfter
            && agentIntentToTickFixtureReport?.tickOutput.physicalPositionsBefore
                == agentIntentToTickFixtureReport?.tickOutput.physicalPositionsAfter
            && agentIntentToTickFixtureReport?.summary.displacementsApplied == 0
            && agentIntentToTickFixtureReport?.summary.worldUsed == false
            && agentIntentToTickFixtureReport?.summary.collisionRead == false
            && agentIntentToTickFixtureReport?.summary.movementApplied == false
            && agentIntentToTickFixtureReport?.summary.feedbackConsumed == false
            && agentIntentToTickFixtureReport?.summary.memoryUpdated == false
            && agentIntentToTickFixtureReport?.summary.goalChanged == false
            && agentIntentToTickFixtureReport?.summary.pathfindingPerformed == false
            && agentIntentToTickFixtureReport?.summary.replanningPerformed == false
            && agentIntentToTickFixtureReport?.summary.avoidancePerformed == false
            && agentIntentToTickFixtureReport?.summary.reservationRuntimeUsed == false
            && agentIntentToTickFixtureReport?.summary.physicsPerformed == false
            && agentIntentToTickFixtureReport?.summary.mutationPerformed == false)
        : nil
let agentIntentToTickLiveReadonlyReport =
    isAgentIntentToTickLiveReadonlyScenario
        ? makeAgentIntentToTickLiveReadonlyReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentIntentToTickLiveReadonlyInvariantReport =
    isAgentIntentToTickLiveReadonlyScenario
        ? makeAgentIntentToTickLiveReadonlyInvariantReport(
            report: agentIntentToTickLiveReadonlyReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentIntentToTickLiveReadonlySuccess =
    isAgentIntentToTickLiveReadonlyScenario
        ? ((agentIntentToTickLiveReadonlyReport?.success ?? false)
            && (agentIntentToTickLiveReadonlyInvariantReport?.success ?? false)
            && agentIntentToTickLiveReadonlyReport?.summary.contexts == 5
            && agentIntentToTickLiveReadonlyReport?.summary.proposals == 5
            && agentIntentToTickLiveReadonlyReport?.summary.acceptedIntents == 3
            && agentIntentToTickLiveReadonlyReport?.summary.rejectedProposals == 2
            && agentIntentToTickLiveReadonlyReport?.intentProduction.summary.noIntent == 1
            && agentIntentToTickLiveReadonlyReport?.intentProduction.summary.invalidOneEdgeProposals == 1
            && agentIntentToTickLiveReadonlyReport?.intentProduction.acceptedIntents.map(\.agentId)
                == agentIntentToTickLiveReadonlyReport?.intentProduction.acceptedIntents.map(\.agentId).sorted()
            && agentIntentToTickLiveReadonlyReport?.intentProduction.acceptedIntents.allSatisfy {
                abs($0.from.x - $0.to.x) + abs($0.from.y - $0.to.y) + abs($0.from.z - $0.to.z) == 1
                    && $0.from.y == $0.to.y
            } == true
            && agentIntentToTickLiveReadonlyReport?.summary.productionReadCollision == false
            && agentIntentToTickLiveReadonlyReport?.summary.tickReadLiveCollision == true
            && agentIntentToTickLiveReadonlyReport?.summary.worldUsed == true
            && agentIntentToTickLiveReadonlyReport?.summary.collisionRead == true
            && agentIntentToTickLiveReadonlyReport?.summary.occupableDestinations == 2
            && agentIntentToTickLiveReadonlyReport?.summary.nonOccupableDestinations == 1
            && agentIntentToTickLiveReadonlyReport?.summary.tickApproved == 2
            && agentIntentToTickLiveReadonlyReport?.summary.tickDenied == 1
            && agentIntentToTickLiveReadonlyReport?.summary.collisionDenied == 1
            && agentIntentToTickLiveReadonlyReport?.summary.tickFeedback == 3
            && agentIntentToTickLiveReadonlyReport?.tickOutput.feedback.filter {
                $0.kind == .approvedForMovement
            }.count == 2
            && agentIntentToTickLiveReadonlyReport?.tickOutput.feedback.contains {
                $0.agentId == "agent_2" && $0.kind == .blockedByCollision
            } == true
            && agentIntentToTickLiveReadonlyReport?.tickOutput.abstractPositionsBefore
                == agentIntentToTickLiveReadonlyReport?.tickOutput.abstractPositionsAfter
            && agentIntentToTickLiveReadonlyReport?.tickOutput.physicalPositionsBefore
                == agentIntentToTickLiveReadonlyReport?.tickOutput.physicalPositionsAfter
            && agentIntentToTickLiveReadonlyReport?.summary.displacementsApplied == 0
            && agentIntentToTickLiveReadonlyReport?.summary.movementApplied == false
            && agentIntentToTickLiveReadonlyReport?.summary.feedbackConsumed == false
            && agentIntentToTickLiveReadonlyReport?.summary.memoryUpdated == false
            && agentIntentToTickLiveReadonlyReport?.summary.goalChanged == false
            && agentIntentToTickLiveReadonlyReport?.summary.pathfindingPerformed == false
            && agentIntentToTickLiveReadonlyReport?.summary.replanningPerformed == false
            && agentIntentToTickLiveReadonlyReport?.summary.avoidancePerformed == false
            && agentIntentToTickLiveReadonlyReport?.summary.reservationRuntimeUsed == false
            && agentIntentToTickLiveReadonlyReport?.summary.physicsPerformed == false
            && agentIntentToTickLiveReadonlyReport?.summary.mutationPerformed == false)
        : nil
let agentIntentToTickApprovedApplicationReport =
    isAgentIntentToTickApprovedApplicationScenario
        ? makeAgentIntentToTickApprovedApplicationReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentIntentToTickApprovedApplicationInvariantReport =
    isAgentIntentToTickApprovedApplicationScenario
        ? makeAgentIntentToTickApprovedApplicationInvariantReport(
            report: agentIntentToTickApprovedApplicationReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentIntentToTickApprovedApplicationSuccess =
    isAgentIntentToTickApprovedApplicationScenario
        ? ((agentIntentToTickApprovedApplicationReport?.success ?? false)
            && (agentIntentToTickApprovedApplicationInvariantReport?.success ?? false)
            && agentIntentToTickApprovedApplicationReport?.summary.contexts == 5
            && agentIntentToTickApprovedApplicationReport?.summary.proposals == 5
            && agentIntentToTickApprovedApplicationReport?.summary.acceptedIntents == 3
            && agentIntentToTickApprovedApplicationReport?.summary.rejectedProposals == 2
            && agentIntentToTickApprovedApplicationReport?.intentProduction.summary.noIntent == 1
            && agentIntentToTickApprovedApplicationReport?.intentProduction.summary.invalidOneEdgeProposals == 1
            && agentIntentToTickApprovedApplicationReport?.intentProduction.acceptedIntents.map(\.agentId)
                == agentIntentToTickApprovedApplicationReport?.intentProduction.acceptedIntents.map(\.agentId).sorted()
            && agentIntentToTickApprovedApplicationReport?.intentProduction.acceptedIntents.allSatisfy {
                abs($0.from.x - $0.to.x) + abs($0.from.y - $0.to.y) + abs($0.from.z - $0.to.z) == 1
                    && $0.from.y == $0.to.y
            } == true
            && agentIntentToTickApprovedApplicationReport?.summary.productionReadCollision == false
            && agentIntentToTickApprovedApplicationReport?.summary.tickReadLiveCollision == true
            && agentIntentToTickApprovedApplicationReport?.summary.worldUsed == true
            && agentIntentToTickApprovedApplicationReport?.summary.collisionRead == true
            && agentIntentToTickApprovedApplicationReport?.summary.occupableDestinations == 2
            && agentIntentToTickApprovedApplicationReport?.summary.nonOccupableDestinations == 1
            && agentIntentToTickApprovedApplicationReport?.summary.tickApproved == 2
            && agentIntentToTickApprovedApplicationReport?.summary.tickDenied == 1
            && agentIntentToTickApprovedApplicationReport?.summary.collisionDenied == 1
            && agentIntentToTickApprovedApplicationReport?.summary.displacementsApplied == 2
            && agentIntentToTickApprovedApplicationReport?.summary.movedFeedback == 2
            && agentIntentToTickApprovedApplicationReport?.summary.blockedByCollisionFeedback == 1
            && agentIntentToTickApprovedApplicationReport?.summary.approvedPositionsMoved == true
            && agentIntentToTickApprovedApplicationReport?.summary.deniedPositionsPreserved == true
            && agentIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceBefore == 0
            && agentIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceAfter == 0
            && agentIntentToTickApprovedApplicationReport?.summary.movementApplied == true
            && agentIntentToTickApprovedApplicationReport?.summary.feedbackConsumed == false
            && agentIntentToTickApprovedApplicationReport?.summary.memoryUpdated == false
            && agentIntentToTickApprovedApplicationReport?.summary.goalChanged == false
            && agentIntentToTickApprovedApplicationReport?.summary.pathfindingPerformed == false
            && agentIntentToTickApprovedApplicationReport?.summary.replanningPerformed == false
            && agentIntentToTickApprovedApplicationReport?.summary.avoidancePerformed == false
            && agentIntentToTickApprovedApplicationReport?.summary.reservationRuntimeUsed == false
            && agentIntentToTickApprovedApplicationReport?.summary.routeFollowingApplied == false
            && agentIntentToTickApprovedApplicationReport?.summary.physicsPerformed == false
            && agentIntentToTickApprovedApplicationReport?.summary.mutationPerformed == false)
        : nil
let agentFeedbackConsumptionFixtureReport =
    isAgentFeedbackConsumptionFixtureScenario
        ? makeAgentFeedbackConsumptionFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentFeedbackConsumptionFixtureInvariantReport =
    isAgentFeedbackConsumptionFixtureScenario
        ? makeAgentFeedbackConsumptionFixtureInvariantReport(
            report: agentFeedbackConsumptionFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentFeedbackConsumptionObservationIds =
    agentFeedbackConsumptionFixtureReport?.result.observations.map(\.agentId) ?? []
let agentFeedbackConsumptionContextIds =
    agentFeedbackConsumptionFixtureReport?.result.acceptedContexts.map(\.agentId) ?? []
let agentFeedbackConsumptionContextsByAgent = Dictionary(
    uniqueKeysWithValues: (agentFeedbackConsumptionFixtureReport?.result.acceptedContexts ?? []).map {
        ($0.agentId, $0)
    }
)
let agentFeedbackConsumptionFixtureSuccess =
    isAgentFeedbackConsumptionFixtureScenario
        ? ((agentFeedbackConsumptionFixtureReport?.success ?? false)
            && (agentFeedbackConsumptionFixtureInvariantReport?.success ?? false)
            && agentFeedbackConsumptionFixtureReport?.summary.feedbackObserved == 6
            && agentFeedbackConsumptionFixtureReport?.summary.feedbackAccepted == 4
            && agentFeedbackConsumptionFixtureReport?.summary.feedbackIgnored == 1
            && agentFeedbackConsumptionFixtureReport?.summary.invalidFeedback == 1
            && agentFeedbackConsumptionFixtureReport?.summary.contextsProduced == 4
            && agentFeedbackConsumptionFixtureReport?.summary.moved == 1
            && agentFeedbackConsumptionFixtureReport?.summary.approvedForMovement == 1
            && agentFeedbackConsumptionFixtureReport?.summary.blockedByCollision == 1
            && agentFeedbackConsumptionFixtureReport?.summary.blockedByAgentConflict == 1
            && agentFeedbackConsumptionFixtureReport?.summary.duplicateFeedback == 1
            && agentFeedbackConsumptionObservationIds == agentFeedbackConsumptionObservationIds.sorted()
            && agentFeedbackConsumptionContextIds == agentFeedbackConsumptionContextIds.sorted()
            && Set(agentFeedbackConsumptionObservationIds).count == agentFeedbackConsumptionObservationIds.count
            && agentFeedbackConsumptionContextsByAgent["agent_0"]?.lastMoveSucceeded == true
            && agentFeedbackConsumptionContextsByAgent["agent_0"]?.lastMoveBlocked == false
            && agentFeedbackConsumptionContextsByAgent["agent_0"]?.lastKnownPosition == LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
            && agentFeedbackConsumptionContextsByAgent["agent_1"]?.lastMoveSucceeded == false
            && agentFeedbackConsumptionContextsByAgent["agent_1"]?.lastMoveBlocked == false
            && agentFeedbackConsumptionContextsByAgent["agent_1"]?.lastKnownPosition == LabTerrainPathNodeKey(x: 9, y: 64, z: 7)
            && agentFeedbackConsumptionContextsByAgent["agent_2"]?.lastMoveBlocked == true
            && agentFeedbackConsumptionContextsByAgent["agent_2"]?.lastBlockReason == .blockedByCollision
            && agentFeedbackConsumptionContextsByAgent["agent_2"]?.lastKnownPosition == LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
            && agentFeedbackConsumptionContextsByAgent["agent_3"]?.lastMoveBlocked == true
            && agentFeedbackConsumptionContextsByAgent["agent_3"]?.lastBlockReason == .blockedByAgentConflict
            && agentFeedbackConsumptionFixtureReport?.summary.collisionRead == false
            && agentFeedbackConsumptionFixtureReport?.summary.movementApplied == false
            && agentFeedbackConsumptionFixtureReport?.summary.intentProduced == false
            && agentFeedbackConsumptionFixtureReport?.summary.memoryUpdated == false
            && agentFeedbackConsumptionFixtureReport?.summary.goalChanged == false
            && agentFeedbackConsumptionFixtureReport?.summary.pathfindingPerformed == false
            && agentFeedbackConsumptionFixtureReport?.summary.replanningPerformed == false
            && agentFeedbackConsumptionFixtureReport?.summary.avoidancePerformed == false
            && agentFeedbackConsumptionFixtureReport?.summary.reservationRuntimeUsed == false
            && agentFeedbackConsumptionFixtureReport?.summary.worldUsed == false
            && agentFeedbackConsumptionFixtureReport?.summary.mutationPerformed == false)
        : nil
let agentFeedbackConsumptionHardeningReport =
    isAgentFeedbackConsumptionHardeningScenario
        ? makeAgentFeedbackConsumptionHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let agentFeedbackConsumptionHardeningInvariantReport =
    isAgentFeedbackConsumptionHardeningScenario
        ? makeAgentFeedbackConsumptionHardeningInvariantReport(
            report: agentFeedbackConsumptionHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let agentFeedbackConsumptionHardeningSummary = agentFeedbackConsumptionHardeningReport?.summary
let agentFeedbackConsumptionHardeningSuccess =
    isAgentFeedbackConsumptionHardeningScenario
        ? ((agentFeedbackConsumptionHardeningReport?.success ?? false)
            && (agentFeedbackConsumptionHardeningInvariantReport?.success ?? false)
            && agentFeedbackConsumptionHardeningSummary?.cases == 12
            && agentFeedbackConsumptionHardeningSummary?.passed == 12
            && agentFeedbackConsumptionHardeningSummary?.failed == 0
            && (agentFeedbackConsumptionHardeningSummary?.feedbackAcceptedTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.feedbackIgnoredTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.invalidFeedbackTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.contextsProducedTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.duplicateFeedbackTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.maxFeedbackExceededTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.tickMismatchFeedbackTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.movedTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.approvedForMovementTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByCollisionTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByAgentConflictTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedBySourceMismatchTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByDivergenceTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByStaleIntentTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByInvalidEdgeTotal ?? 0) > 0
            && (agentFeedbackConsumptionHardeningSummary?.blockedByMaxAgentsTotal ?? 0) > 0
            && agentFeedbackConsumptionHardeningReport?.cases.allSatisfy {
                let observationIds = $0.result.observations.map(\.agentId)
                let contextIds = $0.result.acceptedContexts.map(\.agentId)
                return observationIds == observationIds.sorted()
                    && contextIds == contextIds.sorted()
                    && Set(observationIds).count == observationIds.count
            } == true
            && agentFeedbackConsumptionHardeningSummary?.collisionRead == false
            && agentFeedbackConsumptionHardeningSummary?.movementApplied == false
            && agentFeedbackConsumptionHardeningSummary?.intentProduced == false
            && agentFeedbackConsumptionHardeningSummary?.memoryUpdated == false
            && agentFeedbackConsumptionHardeningSummary?.goalChanged == false
            && agentFeedbackConsumptionHardeningSummary?.pathfindingPerformed == false
            && agentFeedbackConsumptionHardeningSummary?.replanningPerformed == false
            && agentFeedbackConsumptionHardeningSummary?.avoidancePerformed == false
            && agentFeedbackConsumptionHardeningSummary?.reservationRuntimeUsed == false
            && agentFeedbackConsumptionHardeningSummary?.worldUsed == false
            && agentFeedbackConsumptionHardeningSummary?.mutationPerformed == false)
        : nil
let feedbackToAgentIntentContextFixtureReport =
    isFeedbackToAgentIntentContextFixtureScenario
        ? makeFeedbackToAgentIntentContextFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackToAgentIntentContextFixtureInvariantReport =
    isFeedbackToAgentIntentContextFixtureScenario
        ? makeFeedbackToAgentIntentContextFixtureInvariantReport(
            report: feedbackToAgentIntentContextFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackToAgentIntentContextFixtureSummary = feedbackToAgentIntentContextFixtureReport?.summary
let feedbackToAgentIntentContextProposalIds =
    feedbackToAgentIntentContextFixtureReport?.intentProduction.proposals.map(\.agentId) ?? []
let feedbackToAgentIntentContextContextsByAgent = Dictionary(
    uniqueKeysWithValues: (feedbackToAgentIntentContextFixtureReport?.intentContexts ?? []).map {
        ($0.agentId, $0)
    }
)
let feedbackToAgentIntentContextFixtureSuccess =
    isFeedbackToAgentIntentContextFixtureScenario
        ? ((feedbackToAgentIntentContextFixtureReport?.success ?? false)
            && (feedbackToAgentIntentContextFixtureInvariantReport?.success ?? false)
            && feedbackToAgentIntentContextFixtureSummary?.feedbackObserved == 6
            && feedbackToAgentIntentContextFixtureSummary?.feedbackAccepted == 4
            && feedbackToAgentIntentContextFixtureSummary?.feedbackIgnored == 1
            && feedbackToAgentIntentContextFixtureSummary?.invalidFeedback == 1
            && feedbackToAgentIntentContextFixtureSummary?.contextsProduced == 4
            && feedbackToAgentIntentContextFixtureSummary?.duplicateFeedback == 1
            && feedbackToAgentIntentContextFixtureSummary?.intentContexts == 5
            && feedbackToAgentIntentContextFixtureSummary?.contextsWithFeedback == 4
            && feedbackToAgentIntentContextFixtureSummary?.contextsWithoutFeedback == 1
            && feedbackToAgentIntentContextFixtureSummary?.proposals == 5
            && feedbackToAgentIntentContextFixtureSummary?.acceptedIntents == 3
            && feedbackToAgentIntentContextFixtureSummary?.rejectedProposals == 2
            && feedbackToAgentIntentContextFixtureSummary?.noIntent == 1
            && feedbackToAgentIntentContextFixtureSummary?.invalidOneEdgeProposals == 1
            && feedbackToAgentIntentContextProposalIds == feedbackToAgentIntentContextProposalIds.sorted()
            && feedbackToAgentIntentContextContextsByAgent["agent_0"]?.lastFeedback?.kind == .moved
            && feedbackToAgentIntentContextContextsByAgent["agent_1"]?.lastFeedback?.kind == .approvedForMovement
            && feedbackToAgentIntentContextContextsByAgent["agent_2"]?.lastFeedback?.kind == .blockedByCollision
            && feedbackToAgentIntentContextContextsByAgent["agent_3"]?.lastFeedback?.kind == .blockedByAgentConflict
            && feedbackToAgentIntentContextContextsByAgent["agent_4"]?.lastFeedback == nil
            && feedbackToAgentIntentContextFixtureSummary?.behaviorChangedByFeedback == false
            && feedbackToAgentIntentContextFixtureSummary?.feedbackUsedForDecision == false
            && feedbackToAgentIntentContextFixtureReport?.feedbackConsumption.summary.collisionRead == false
            && feedbackToAgentIntentContextFixtureSummary?.collisionRead == false
            && feedbackToAgentIntentContextFixtureSummary?.movementApplied == false
            && feedbackToAgentIntentContextFixtureSummary?.memoryUpdated == false
            && feedbackToAgentIntentContextFixtureSummary?.goalChanged == false
            && feedbackToAgentIntentContextFixtureSummary?.pathfindingPerformed == false
            && feedbackToAgentIntentContextFixtureSummary?.replanningPerformed == false
            && feedbackToAgentIntentContextFixtureSummary?.avoidancePerformed == false
            && feedbackToAgentIntentContextFixtureSummary?.reservationRuntimeUsed == false
            && feedbackToAgentIntentContextFixtureSummary?.worldUsed == false
            && feedbackToAgentIntentContextFixtureSummary?.mutationPerformed == false)
        : nil
let feedbackToAgentIntentContextHardeningReport =
    isFeedbackToAgentIntentContextHardeningScenario
        ? makeFeedbackToAgentIntentContextHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackToAgentIntentContextHardeningInvariantReport =
    isFeedbackToAgentIntentContextHardeningScenario
        ? makeFeedbackToAgentIntentContextHardeningInvariantReport(
            report: feedbackToAgentIntentContextHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackToAgentIntentContextHardeningSummary = feedbackToAgentIntentContextHardeningReport?.summary
let feedbackToAgentIntentContextHardeningSuccess =
    isFeedbackToAgentIntentContextHardeningScenario
        ? ((feedbackToAgentIntentContextHardeningReport?.success ?? false)
            && (feedbackToAgentIntentContextHardeningInvariantReport?.success ?? false)
            && feedbackToAgentIntentContextHardeningSummary?.cases == 14
            && feedbackToAgentIntentContextHardeningSummary?.passed == 14
            && feedbackToAgentIntentContextHardeningSummary?.failed == 0
            && feedbackToAgentIntentContextHardeningReport?.cases.allSatisfy {
                $0.passed && $0.proposalSignatures == $0.baselineProposalSignatures
            } == true
            && (feedbackToAgentIntentContextHardeningSummary?.feedbackAcceptedTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.feedbackIgnoredTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.invalidFeedbackTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.contextsProducedTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.contextsWithFeedbackTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.contextsWithoutFeedbackTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.duplicateFeedbackTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.maxFeedbackExceededTotal ?? 0) > 0
            && (feedbackToAgentIntentContextHardeningSummary?.tickMismatchFeedbackTotal ?? 0) > 0
            && feedbackToAgentIntentContextHardeningSummary?.behaviorChangedByFeedback == false
            && feedbackToAgentIntentContextHardeningSummary?.feedbackUsedForDecision == false
            && feedbackToAgentIntentContextHardeningSummary?.collisionRead == false
            && feedbackToAgentIntentContextHardeningSummary?.movementApplied == false
            && feedbackToAgentIntentContextHardeningSummary?.memoryUpdated == false
            && feedbackToAgentIntentContextHardeningSummary?.goalChanged == false
            && feedbackToAgentIntentContextHardeningSummary?.pathfindingPerformed == false
            && feedbackToAgentIntentContextHardeningSummary?.replanningPerformed == false
            && feedbackToAgentIntentContextHardeningSummary?.avoidancePerformed == false
            && feedbackToAgentIntentContextHardeningSummary?.reservationRuntimeUsed == false
            && feedbackToAgentIntentContextHardeningSummary?.worldUsed == false
            && feedbackToAgentIntentContextHardeningSummary?.mutationPerformed == false)
        : nil
let feedbackAwareIntentPolicyFixtureReport =
    isFeedbackAwareIntentPolicyFixtureScenario
        ? makeFeedbackAwareIntentPolicyFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackAwareIntentPolicyFixtureInvariantReport =
    isFeedbackAwareIntentPolicyFixtureScenario
        ? makeFeedbackAwareIntentPolicyFixtureInvariantReport(
            report: feedbackAwareIntentPolicyFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackAwareIntentPolicyFixtureSummary = feedbackAwareIntentPolicyFixtureReport?.summary
let feedbackAwareIntentPolicyFixtureSuccess =
    isFeedbackAwareIntentPolicyFixtureScenario
        ? ((feedbackAwareIntentPolicyFixtureReport?.success ?? false)
            && (feedbackAwareIntentPolicyFixtureInvariantReport?.success ?? false)
            && feedbackAwareIntentPolicyFixtureReport?.baselinePolicyMode == .baselineV0
            && feedbackAwareIntentPolicyFixtureReport?.feedbackAwarePolicyMode == .feedbackAwareV1
            && feedbackAwareIntentPolicyFixtureSummary?.contexts == 10
            && feedbackAwareIntentPolicyFixtureSummary?.contextsWithFeedback == 9
            && feedbackAwareIntentPolicyFixtureSummary?.contextsWithoutFeedback == 1
            && feedbackAwareIntentPolicyFixtureSummary?.baselineProposals == 10
            && feedbackAwareIntentPolicyFixtureSummary?.feedbackAwareProposals == 10
            && feedbackAwareIntentPolicyFixtureSummary?.acceptedIntents == 3
            && feedbackAwareIntentPolicyFixtureSummary?.rejectedProposals == 7
            && feedbackAwareIntentPolicyFixtureSummary?.noIntent == 7
            && feedbackAwareIntentPolicyFixtureSummary?.invalidOneEdgeProposals == 0
            && feedbackAwareIntentPolicyFixtureSummary?.behaviorChangedByFeedback == true
            && feedbackAwareIntentPolicyFixtureSummary?.behaviorChangedCount == 7
            && feedbackAwareIntentPolicyFixtureSummary?.noFeedbackBaselineKept == 1
            && feedbackAwareIntentPolicyFixtureSummary?.movedBaselineKept == 1
            && feedbackAwareIntentPolicyFixtureSummary?.approvedForMovementBaselineKept == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByCollisionNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByAgentConflictNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedBySourceMismatchNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByDivergenceNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByStaleIntentNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByInvalidEdgeNoIntent == 1
            && feedbackAwareIntentPolicyFixtureSummary?.blockedByMaxAgentsNoIntent == 1
            && feedbackAwareIntentPolicyFixtureReport?.decisions.allSatisfy { decision in
                decision.lastFeedbackKind == nil || decision.feedbackUsedForDecision
            } == true
            && feedbackAwareIntentPolicyFixtureReport?.decisions.first {
                $0.agentId == "agent_8_invalid_edge"
            }?.reason == "feedback_blocked_by_invalid_edge_no_intent"
            && feedbackAwareIntentPolicyFixtureSummary?.collisionRead == false
            && feedbackAwareIntentPolicyFixtureSummary?.worldUsed == false
            && feedbackAwareIntentPolicyFixtureSummary?.movementApplied == false
            && feedbackAwareIntentPolicyFixtureSummary?.memoryUpdated == false
            && feedbackAwareIntentPolicyFixtureSummary?.goalChanged == false
            && feedbackAwareIntentPolicyFixtureSummary?.pathfindingPerformed == false
            && feedbackAwareIntentPolicyFixtureSummary?.replanningPerformed == false
            && feedbackAwareIntentPolicyFixtureSummary?.avoidancePerformed == false
            && feedbackAwareIntentPolicyFixtureSummary?.reservationRuntimeUsed == false
            && feedbackAwareIntentPolicyFixtureSummary?.mutationPerformed == false)
        : nil
let feedbackAwareIntentPolicyHardeningReport =
    isFeedbackAwareIntentPolicyHardeningScenario
        ? makeFeedbackAwareIntentPolicyHardeningReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackAwareIntentPolicyHardeningInvariantReport =
    isFeedbackAwareIntentPolicyHardeningScenario
        ? makeFeedbackAwareIntentPolicyHardeningInvariantReport(
            report: feedbackAwareIntentPolicyHardeningReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackAwareIntentPolicyHardeningSummary = feedbackAwareIntentPolicyHardeningReport?.summary
let feedbackAwareIntentPolicyHardeningSuccess =
    isFeedbackAwareIntentPolicyHardeningScenario
        ? ((feedbackAwareIntentPolicyHardeningReport?.success ?? false)
            && (feedbackAwareIntentPolicyHardeningInvariantReport?.success ?? false)
            && feedbackAwareIntentPolicyHardeningSummary?.cases == 16
            && feedbackAwareIntentPolicyHardeningSummary?.passed == 16
            && feedbackAwareIntentPolicyHardeningSummary?.failed == 0
            && feedbackAwareIntentPolicyHardeningSummary?.feedbackUsedForDecision == true
            && (feedbackAwareIntentPolicyHardeningSummary?.behaviorChangedCountTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByCollisionNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByAgentConflictNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedBySourceMismatchNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByDivergenceNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByStaleIntentNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByInvalidEdgeNoIntentTotal ?? 0) > 0
            && (feedbackAwareIntentPolicyHardeningSummary?.blockedByMaxAgentsNoIntentTotal ?? 0) > 0
            && feedbackAwareIntentPolicyHardeningSummary?.collisionRead == false
            && feedbackAwareIntentPolicyHardeningSummary?.worldUsed == false
            && feedbackAwareIntentPolicyHardeningSummary?.movementApplied == false
            && feedbackAwareIntentPolicyHardeningSummary?.memoryUpdated == false
            && feedbackAwareIntentPolicyHardeningSummary?.goalChanged == false
            && feedbackAwareIntentPolicyHardeningSummary?.pathfindingPerformed == false
            && feedbackAwareIntentPolicyHardeningSummary?.replanningPerformed == false
            && feedbackAwareIntentPolicyHardeningSummary?.avoidancePerformed == false
            && feedbackAwareIntentPolicyHardeningSummary?.reservationRuntimeUsed == false
            && feedbackAwareIntentPolicyHardeningSummary?.mutationPerformed == false)
        : nil
let feedbackAwareIntentToTickFixtureReport =
    isFeedbackAwareIntentToTickFixtureScenario
        ? makeFeedbackAwareIntentToTickFixtureReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackAwareIntentToTickFixtureInvariantReport =
    isFeedbackAwareIntentToTickFixtureScenario
        ? makeFeedbackAwareIntentToTickFixtureInvariantReport(
            report: feedbackAwareIntentToTickFixtureReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackAwareIntentToTickFixtureSummary = feedbackAwareIntentToTickFixtureReport?.summary
let feedbackAwareIntentToTickFixtureSuccess =
    isFeedbackAwareIntentToTickFixtureScenario
        ? ((feedbackAwareIntentToTickFixtureReport?.success ?? false)
            && (feedbackAwareIntentToTickFixtureInvariantReport?.success ?? false)
            && feedbackAwareIntentToTickFixtureSummary?.contexts == 6
            && feedbackAwareIntentToTickFixtureSummary?.contextsWithFeedback == 5
            && feedbackAwareIntentToTickFixtureSummary?.contextsWithoutFeedback == 1
            && feedbackAwareIntentToTickFixtureSummary?.feedbackAwareProposals == 6
            && feedbackAwareIntentToTickFixtureSummary?.feedbackAwareAcceptedIntents == 3
            && feedbackAwareIntentToTickFixtureSummary?.feedbackAwareNoIntent == 3
            && feedbackAwareIntentToTickFixtureSummary?.feedbackAwareInvalidOneEdgeProposals == 0
            && (feedbackAwareIntentToTickFixtureSummary?.baselineMovementIntentInputs ?? 0)
                > (feedbackAwareIntentToTickFixtureSummary?.feedbackAwareMovementIntentInputs ?? 0)
            && feedbackAwareIntentToTickFixtureSummary?.feedbackAwareMovementIntentInputs == 3
            && feedbackAwareIntentToTickFixtureSummary?.noIntentFilteredOut == 3
            && (feedbackAwareIntentToTickFixtureSummary?.movementIntentReduction ?? 0) >= 2
            && feedbackAwareIntentToTickFixtureSummary?.tickIntents == 3
            && feedbackAwareIntentToTickFixtureSummary?.tickApproved == 2
            && feedbackAwareIntentToTickFixtureSummary?.tickDenied == 1
            && feedbackAwareIntentToTickFixtureSummary?.tickDeniedSameDestinationConflict == 1
            && feedbackAwareIntentToTickFixtureSummary?.tickFeedbackEmitted == 3
            && feedbackAwareIntentToTickFixtureSummary?.displacementsApplied == 0
            && feedbackAwareIntentToTickFixtureSummary?.policyReadCollision == false
            && feedbackAwareIntentToTickFixtureSummary?.tickReadCollision == false
            && feedbackAwareIntentToTickFixtureSummary?.movementApplied == false
            && feedbackAwareIntentToTickFixtureSummary?.memoryUpdated == false
            && feedbackAwareIntentToTickFixtureSummary?.goalChanged == false
            && feedbackAwareIntentToTickFixtureSummary?.pathfindingPerformed == false
            && feedbackAwareIntentToTickFixtureSummary?.replanningPerformed == false
            && feedbackAwareIntentToTickFixtureSummary?.avoidancePerformed == false
            && feedbackAwareIntentToTickFixtureSummary?.reservationRuntimeUsed == false
            && feedbackAwareIntentToTickFixtureSummary?.worldUsed == false
            && feedbackAwareIntentToTickFixtureSummary?.mutationPerformed == false)
        : nil
let feedbackAwareIntentToTickLiveReadonlyReport =
    isFeedbackAwareIntentToTickLiveReadonlyScenario
        ? makeFeedbackAwareIntentToTickLiveReadonlyReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackAwareIntentToTickLiveReadonlyInvariantReport =
    isFeedbackAwareIntentToTickLiveReadonlyScenario
        ? makeFeedbackAwareIntentToTickLiveReadonlyInvariantReport(
            report: feedbackAwareIntentToTickLiveReadonlyReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackAwareIntentToTickLiveReadonlySummary =
    feedbackAwareIntentToTickLiveReadonlyReport?.summary
let feedbackAwareIntentToTickLiveReadonlySuccess =
    isFeedbackAwareIntentToTickLiveReadonlyScenario
        ? ((feedbackAwareIntentToTickLiveReadonlyReport?.success ?? false)
            && (feedbackAwareIntentToTickLiveReadonlyInvariantReport?.success ?? false)
            && feedbackAwareIntentToTickLiveReadonlySummary?.contexts == 7
            && feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareProposals == 7
            && feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareAcceptedIntents == 4
            && feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareNoIntent == 3
            && feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareInvalidOneEdgeProposals == 0
            && (feedbackAwareIntentToTickLiveReadonlySummary?.baselineMovementIntentInputs ?? 0)
                > (feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareMovementIntentInputs ?? 0)
            && feedbackAwareIntentToTickLiveReadonlySummary?.feedbackAwareMovementIntentInputs == 4
            && feedbackAwareIntentToTickLiveReadonlySummary?.noIntentFilteredOut == 3
            && (feedbackAwareIntentToTickLiveReadonlySummary?.movementIntentReduction ?? 0) >= 2
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickIntents == 4
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickApproved == 2
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickDenied == 2
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickDeniedSameDestinationConflict == 1
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickDeniedCollision == 1
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickFeedbackEmitted == 4
            && feedbackAwareIntentToTickLiveReadonlySummary?.occupableDestinations == 2
            && feedbackAwareIntentToTickLiveReadonlySummary?.nonOccupableDestinations == 1
            && feedbackAwareIntentToTickLiveReadonlySummary?.displacementsApplied == 0
            && feedbackAwareIntentToTickLiveReadonlySummary?.policyReadCollision == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.policyWorldUsed == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickReadCollision == true
            && feedbackAwareIntentToTickLiveReadonlySummary?.tickWorldReadOnlyUsed == true
            && feedbackAwareIntentToTickLiveReadonlySummary?.movementApplied == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.memoryUpdated == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.goalChanged == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.pathfindingPerformed == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.replanningPerformed == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.avoidancePerformed == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.reservationRuntimeUsed == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.worldMutated == false
            && feedbackAwareIntentToTickLiveReadonlySummary?.mutationPerformed == false)
        : nil
let feedbackAwareIntentToTickApprovedApplicationReport =
    isFeedbackAwareIntentToTickApprovedApplicationScenario
        ? makeFeedbackAwareIntentToTickApprovedApplicationReport(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil
let feedbackAwareIntentToTickApprovedApplicationInvariantReport =
    isFeedbackAwareIntentToTickApprovedApplicationScenario
        ? makeFeedbackAwareIntentToTickApprovedApplicationInvariantReport(
            report: feedbackAwareIntentToTickApprovedApplicationReport,
            scenario: options.scenario,
            seed: options.seed
        )
        : nil
let feedbackAwareIntentToTickApprovedApplicationSummary =
    feedbackAwareIntentToTickApprovedApplicationReport?.summary
let feedbackAwareIntentToTickApprovedApplicationSuccess =
    isFeedbackAwareIntentToTickApprovedApplicationScenario
        ? ((feedbackAwareIntentToTickApprovedApplicationReport?.success ?? false)
            && (feedbackAwareIntentToTickApprovedApplicationInvariantReport?.success ?? false)
            && feedbackAwareIntentToTickApprovedApplicationSummary?.contexts == 7
            && feedbackAwareIntentToTickApprovedApplicationSummary?.contextsWithFeedback == 5
            && feedbackAwareIntentToTickApprovedApplicationSummary?.contextsWithoutFeedback == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareProposals == 7
            && feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareAcceptedIntents == 4
            && feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareNoIntent == 3
            && feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareInvalidOneEdgeProposals == 0
            && (feedbackAwareIntentToTickApprovedApplicationSummary?.baselineMovementIntentInputs ?? 0)
                > (feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareMovementIntentInputs ?? 0)
            && feedbackAwareIntentToTickApprovedApplicationSummary?.feedbackAwareMovementIntentInputs == 4
            && feedbackAwareIntentToTickApprovedApplicationSummary?.noIntentFilteredOut == 3
            && (feedbackAwareIntentToTickApprovedApplicationSummary?.movementIntentReduction ?? 0) >= 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickIntents == 4
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickApproved == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickDenied == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickDeniedSameDestinationConflict == 1
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickDeniedCollision == 1
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickFeedbackEmitted == 4
            && feedbackAwareIntentToTickApprovedApplicationSummary?.approvedAgentsMoved == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.deniedAgentsPreserved == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.noIntentAgentsPreserved == 3
            && feedbackAwareIntentToTickApprovedApplicationSummary?.displacementsApplied == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.abstractPositionsChanged == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.physicalPositionsChanged == 2
            && feedbackAwareIntentToTickApprovedApplicationSummary?.abstractPhysicalDivergenceBefore == 0
            && feedbackAwareIntentToTickApprovedApplicationSummary?.abstractPhysicalDivergenceAfter == 0
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_0_no_feedback"]
                == LabTerrainPathNodeKey(x: 1, y: 64, z: 0)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_4_approved"]
                == LabTerrainPathNodeKey(x: 9, y: 64, z: 8)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_1_moved"]
                == LabTerrainPathNodeKey(x: 2, y: 64, z: 0)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_6_live_collision"]
                == LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_2_collision_feedback"]
                == LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_3_conflict_feedback"]
                == LabTerrainPathNodeKey(x: 4, y: 64, z: 0)
            && feedbackAwareIntentToTickApprovedApplicationReport?.finalPositions["agent_5_invalid_edge_feedback"]
                == LabTerrainPathNodeKey(x: 8, y: 64, z: 0)
            && feedbackAwareIntentToTickApprovedApplicationSummary?.policyReadCollision == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.policyWorldUsed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickReadCollision == true
            && feedbackAwareIntentToTickApprovedApplicationSummary?.tickWorldReadOnlyUsed == true
            && feedbackAwareIntentToTickApprovedApplicationSummary?.movementApplied == true
            && feedbackAwareIntentToTickApprovedApplicationSummary?.memoryUpdated == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.goalChanged == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.pathfindingPerformed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.replanningPerformed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.avoidancePerformed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.reservationRuntimeUsed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.routeFollowingUsed == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.worldMutated == false
            && feedbackAwareIntentToTickApprovedApplicationSummary?.mutationPerformed == false)
        : nil
let alternateLocalHintReport = isAlternateLocalHintFixtureScenario
    ? makeAlternateLocalHintFixtureReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let alternateLocalHintInvariantReport = isAlternateLocalHintFixtureScenario
    ? makeAlternateLocalHintFixtureInvariantReport(
        report: alternateLocalHintReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let alternateLocalHintSummary = alternateLocalHintReport?.summary
let alternateLocalHintSuccess = isAlternateLocalHintFixtureScenario
    ? ((alternateLocalHintReport?.success ?? false)
        && (alternateLocalHintInvariantReport?.success ?? false)
        && alternateLocalHintSummary?.contexts == 6
        && alternateLocalHintSummary?.decisions == 6
        && alternateLocalHintSummary?.contextsWithBlockedFeedback == 4
        && alternateLocalHintSummary?.contextsWithoutFeedback == 1
        && alternateLocalHintSummary?.contextsWithApprovedOrMovedFeedback == 1
        && alternateLocalHintSummary?.candidatesProduced == 4
        && alternateLocalHintSummary?.candidatesSelected == 2
        && alternateLocalHintSummary?.maxAlternates == 2
        && alternateLocalHintSummary?.bounded == true
        && alternateLocalHintSummary?.noFeedbackBaseline == 1
        && alternateLocalHintSummary?.approvedFeedbackBaseline == 1
        && alternateLocalHintSummary?.blockedFeedbackUsed == 2
        && alternateLocalHintSummary?.unknownHintNoAlternate == 1
        && alternateLocalHintSummary?.emptyHintNoAlternate == 1
        && alternateLocalHintSummary?.failedDirectionExcluded == 2
        && alternateLocalHintSummary?.oneEdgeAlternates == true
        && alternateLocalHintSummary?.movementIntentInputs == 4
        && alternateLocalHintSummary?.tickApproved == 4
        && alternateLocalHintSummary?.tickDenied == 0
        && alternateLocalHintSummary?.tickDeniedConflict == 0
        && alternateLocalHintSummary?.tickDeniedCollision == 0
        && alternateLocalHintSummary?.tickFeedbackEmitted == 4
        && alternateLocalHintSummary?.v0Unchanged == true
        && alternateLocalHintSummary?.v1Unchanged == true
        && alternateLocalHintSummary?.v2OptIn == true
        && alternateLocalHintSummary?.policyReadCollision == false
        && alternateLocalHintSummary?.policyWorldUsed == false
        && alternateLocalHintSummary?.tickReadCollision == false
        && alternateLocalHintSummary?.tickWorldUsed == false
        && alternateLocalHintSummary?.movementApplied == false
        && alternateLocalHintSummary?.pathfindingPerformed == false
        && alternateLocalHintSummary?.replanningPerformed == false
        && alternateLocalHintSummary?.avoidancePerformed == false
        && alternateLocalHintSummary?.reservationRuntimeUsed == false
        && alternateLocalHintSummary?.routeFollowingUsed == false
        && alternateLocalHintSummary?.memoryUpdated == false
        && alternateLocalHintSummary?.goalChanged == false
        && alternateLocalHintSummary?.worldMutated == false
        && alternateLocalHintSummary?.mutationPerformed == false)
    : nil
let alternateLocalHintHardeningReport = isAlternateLocalHintHardeningScenario
    ? makeAlternateLocalHintHardeningReport(
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let alternateLocalHintHardeningInvariantReport = isAlternateLocalHintHardeningScenario
    ? makeAlternateLocalHintHardeningInvariantReport(
        report: alternateLocalHintHardeningReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let alternateLocalHintHardeningSummary = alternateLocalHintHardeningReport?.summary
let alternateLocalHintHardeningSuccess = isAlternateLocalHintHardeningScenario
    ? ((alternateLocalHintHardeningReport?.success ?? false)
        && (alternateLocalHintHardeningInvariantReport?.success ?? false)
        && (alternateLocalHintHardeningSummary?.cases ?? 0) >= 18
        && alternateLocalHintHardeningSummary?.passed == alternateLocalHintHardeningSummary?.cases
        && alternateLocalHintHardeningSummary?.failed == 0
        && alternateLocalHintHardeningSummary?.v0Unchanged == true
        && alternateLocalHintHardeningSummary?.v1Unchanged == true
        && alternateLocalHintHardeningSummary?.v2OptIn == true
        && (alternateLocalHintHardeningSummary?.blockedFeedbackKindsCovered ?? 0) >= 7
        && alternateLocalHintHardeningSummary?.maxAlternatesMin == 0
        && (alternateLocalHintHardeningSummary?.maxAlternatesMax ?? 0) >= 3
        && (alternateLocalHintHardeningSummary?.maxAlternatesZeroCases ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.maxAlternatesOneCases ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.maxAlternatesTwoCases ?? 0) >= 7
        && (alternateLocalHintHardeningSummary?.maxAlternatesThreeCases ?? 0) >= 1
        && alternateLocalHintHardeningSummary?.boundedCases == alternateLocalHintHardeningSummary?.cases
        && (alternateLocalHintHardeningSummary?.deterministicOrderingCases ?? 0)
            >= (alternateLocalHintHardeningSummary?.cases ?? 0)
        && (alternateLocalHintHardeningSummary?.unknownHintNoAlternate ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.emptyHintNoAlternate ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.noFeedbackBaseline ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.approvedFeedbackBaseline ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.movedFeedbackBaseline ?? 0) >= 1
        && (alternateLocalHintHardeningSummary?.failedDirectionExcluded ?? 0) >= 7
        && alternateLocalHintHardeningSummary?.oneEdgeAlternates == true
        && (alternateLocalHintHardeningSummary?.repeatabilityChecks ?? 0) >= 1
        && alternateLocalHintHardeningSummary?.repeatabilityFailures == 0
        && (alternateLocalHintHardeningSummary?.movementIntentInputs ?? 0) > 0
        && (alternateLocalHintHardeningSummary?.tickApproved ?? 0) > 0
        && alternateLocalHintHardeningSummary?.tickDeniedCollision == 0
        && alternateLocalHintHardeningSummary?.policyReadCollision == false
        && alternateLocalHintHardeningSummary?.policyWorldUsed == false
        && alternateLocalHintHardeningSummary?.tickReadCollision == false
        && alternateLocalHintHardeningSummary?.tickWorldUsed == false
        && alternateLocalHintHardeningSummary?.movementApplied == false
        && alternateLocalHintHardeningSummary?.pathfindingPerformed == false
        && alternateLocalHintHardeningSummary?.replanningPerformed == false
        && alternateLocalHintHardeningSummary?.avoidancePerformed == false
        && alternateLocalHintHardeningSummary?.reservationRuntimeUsed == false
        && alternateLocalHintHardeningSummary?.routeFollowingUsed == false
        && alternateLocalHintHardeningSummary?.memoryUpdated == false
        && alternateLocalHintHardeningSummary?.goalChanged == false
        && alternateLocalHintHardeningSummary?.worldMutated == false
        && alternateLocalHintHardeningSummary?.mutationPerformed == false)
    : nil
let multiTickClosedLoopReport = isMultiTickClosedLoopFixtureScenario
    ? makeMultiTickClosedLoopFixtureReport(
        scenario: options.scenario,
        seed: options.seed,
        requestedTicks: options.ticks
    )
    : nil
let multiTickClosedLoopInvariantReport = isMultiTickClosedLoopFixtureScenario
    ? makeMultiTickClosedLoopFixtureInvariantReport(
        report: multiTickClosedLoopReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiTickClosedLoopSummary = multiTickClosedLoopReport?.summary
let multiTickClosedLoopSuccess = isMultiTickClosedLoopFixtureScenario
    ? ((multiTickClosedLoopReport?.success ?? false)
        && (multiTickClosedLoopInvariantReport?.success ?? false)
        && multiTickClosedLoopSummary?.requestedTicks == 3
        && multiTickClosedLoopSummary?.executedTicks == 3
        && multiTickClosedLoopSummary?.agents == 4
        && multiTickClosedLoopSummary?.contextsTotal == 12
        && multiTickClosedLoopSummary?.feedbackConsumedTotal == 5
        && multiTickClosedLoopSummary?.feedbackCarriedToNextTickTotal == 8
        && multiTickClosedLoopSummary?.contextsWithFeedbackTotal == 5
        && multiTickClosedLoopSummary?.contextsWithoutFeedbackTotal == 7
        && multiTickClosedLoopSummary?.proposalsTotal == 12
        && multiTickClosedLoopSummary?.acceptedIntentsTotal == 8
        && multiTickClosedLoopSummary?.noIntentTotal == 4
        && multiTickClosedLoopSummary?.noIntentFromBlockedFeedbackTotal == 1
        && multiTickClosedLoopSummary?.movementIntentInputsTotal == 8
        && multiTickClosedLoopSummary?.tickApprovedTotal == 6
        && multiTickClosedLoopSummary?.tickDeniedTotal == 2
        && multiTickClosedLoopSummary?.tickDeniedConflictTotal == 2
        && multiTickClosedLoopSummary?.tickDeniedCollisionTotal == 0
        && multiTickClosedLoopSummary?.feedbackEmittedTotal == 8
        && multiTickClosedLoopSummary?.approvedApplicationsTotal == 0
        && multiTickClosedLoopSummary?.deniedPreservedTotal == 0
        && multiTickClosedLoopSummary?.noIntentPreservedTotal == 0
        && multiTickClosedLoopSummary?.sameTickFeedbackConsumedTotal == 0
        && multiTickClosedLoopSummary?.crossAgentFeedbackLeaksTotal == 0
        && multiTickClosedLoopSummary?.futureFeedbackConsumedTotal == 0
        && multiTickClosedLoopSummary?.policyReadCollision == false
        && multiTickClosedLoopSummary?.tickReadCollision == false
        && multiTickClosedLoopSummary?.policyWorldUsed == false
        && multiTickClosedLoopSummary?.tickWorldReadOnlyUsed == false
        && multiTickClosedLoopSummary?.movementApplied == false
        && multiTickClosedLoopSummary?.memoryUpdated == false
        && multiTickClosedLoopSummary?.goalChanged == false
        && multiTickClosedLoopSummary?.pathfindingPerformed == false
        && multiTickClosedLoopSummary?.replanningPerformed == false
        && multiTickClosedLoopSummary?.avoidancePerformed == false
        && multiTickClosedLoopSummary?.reservationRuntimeUsed == false
        && multiTickClosedLoopSummary?.routeFollowingUsed == false
        && multiTickClosedLoopSummary?.worldMutated == false
        && multiTickClosedLoopSummary?.mutationPerformed == false)
    : nil
let multiTickClosedLoopHardeningReport = isMultiTickClosedLoopHardeningScenario
    ? makeMultiTickClosedLoopHardeningReport(
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiTickClosedLoopHardeningInvariantReport = isMultiTickClosedLoopHardeningScenario
    ? makeMultiTickClosedLoopHardeningInvariantReport(
        report: multiTickClosedLoopHardeningReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiTickClosedLoopHardeningFeedbackReport = multiTickClosedLoopHardeningReport.map {
    makeMultiTickClosedLoopHardeningFeedbackReport(report: $0)
}
let multiTickClosedLoopHardeningSummary = multiTickClosedLoopHardeningReport?.summary
let multiTickClosedLoopHardeningSuccess = isMultiTickClosedLoopHardeningScenario
    ? ((multiTickClosedLoopHardeningReport?.success ?? false)
        && (multiTickClosedLoopHardeningInvariantReport?.success ?? false)
        && (multiTickClosedLoopHardeningSummary?.cases ?? 0) >= 12
        && multiTickClosedLoopHardeningSummary?.passed == multiTickClosedLoopHardeningSummary?.cases
        && multiTickClosedLoopHardeningSummary?.failed == 0
        && (multiTickClosedLoopHardeningSummary?.feedbackCandidatesTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.feedbackConsumedTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.feedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.feedbackDedupedTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.staleFeedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.futureFeedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.sameTickFeedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.crossAgentLeakAttemptsTotal ?? 0) > 0
        && multiTickClosedLoopHardeningSummary?.crossAgentFeedbackLeaksTotal == 0
        && (multiTickClosedLoopHardeningSummary?.unknownAgentFeedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.malformedFeedbackIgnoredTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.missingFeedbackAllowedTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.noIntentFromBlockedFeedbackTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.movementIntentInputsTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.tickApprovedTotal ?? 0) > 0
        && (multiTickClosedLoopHardeningSummary?.tickDeniedConflictTotal ?? 0) > 0
        && multiTickClosedLoopHardeningSummary?.tickDeniedCollisionTotal == 0
        && (multiTickClosedLoopHardeningSummary?.feedbackEmittedTotal ?? 0) > 0
        && multiTickClosedLoopHardeningSummary?.sameTickFeedbackConsumedTotal == 0
        && multiTickClosedLoopHardeningSummary?.futureFeedbackConsumedTotal == 0
        && (multiTickClosedLoopHardeningSummary?.repeatabilityChecks ?? 0) >= 1
        && multiTickClosedLoopHardeningSummary?.repeatabilityFailures == 0
        && multiTickClosedLoopHardeningSummary?.policyReadCollision == false
        && multiTickClosedLoopHardeningSummary?.tickReadCollision == false
        && multiTickClosedLoopHardeningSummary?.policyWorldUsed == false
        && multiTickClosedLoopHardeningSummary?.tickWorldReadOnlyUsed == false
        && multiTickClosedLoopHardeningSummary?.movementApplied == false
        && multiTickClosedLoopHardeningSummary?.memoryUpdated == false
        && multiTickClosedLoopHardeningSummary?.goalChanged == false
        && multiTickClosedLoopHardeningSummary?.pathfindingPerformed == false
        && multiTickClosedLoopHardeningSummary?.replanningPerformed == false
        && multiTickClosedLoopHardeningSummary?.avoidancePerformed == false
        && multiTickClosedLoopHardeningSummary?.reservationRuntimeUsed == false
        && multiTickClosedLoopHardeningSummary?.routeFollowingUsed == false
        && multiTickClosedLoopHardeningSummary?.worldMutated == false
        && multiTickClosedLoopHardeningSummary?.mutationPerformed == false)
    : nil
let multiTickClosedLoopLiveReadonlyReport = isMultiTickClosedLoopLiveReadonlyScenario
    ? makeMultiTickClosedLoopLiveReadonlyReport(
        scenario: options.scenario,
        seed: options.seed,
        requestedTicks: options.ticks
    )
    : nil
let multiTickClosedLoopLiveReadonlyInvariantReport = isMultiTickClosedLoopLiveReadonlyScenario
    ? makeMultiTickClosedLoopLiveReadonlyInvariantReport(
        report: multiTickClosedLoopLiveReadonlyReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiTickClosedLoopLiveReadonlySummary = multiTickClosedLoopLiveReadonlyReport?.summary
let multiTickClosedLoopLiveReadonlySuccess = isMultiTickClosedLoopLiveReadonlyScenario
    ? ((multiTickClosedLoopLiveReadonlyReport?.success ?? false)
        && (multiTickClosedLoopLiveReadonlyInvariantReport?.success ?? false)
        && multiTickClosedLoopLiveReadonlySummary?.requestedTicks == 3
        && multiTickClosedLoopLiveReadonlySummary?.executedTicks == 3
        && multiTickClosedLoopLiveReadonlySummary?.agents == 5
        && multiTickClosedLoopLiveReadonlySummary?.contextsTotal == 15
        && multiTickClosedLoopLiveReadonlySummary?.contextsWithFeedbackTotal == 6
        && multiTickClosedLoopLiveReadonlySummary?.contextsWithoutFeedbackTotal == 9
        && multiTickClosedLoopLiveReadonlySummary?.proposalsTotal == 15
        && multiTickClosedLoopLiveReadonlySummary?.noIntentTotal == 5
        && multiTickClosedLoopLiveReadonlySummary?.noIntentFromBlockedFeedbackTotal == 2
        && multiTickClosedLoopLiveReadonlySummary?.movementIntentInputsTotal == 10
        && multiTickClosedLoopLiveReadonlySummary?.tickApprovedTotal == 6
        && multiTickClosedLoopLiveReadonlySummary?.tickDeniedTotal == 4
        && multiTickClosedLoopLiveReadonlySummary?.tickDeniedConflictTotal == 2
        && multiTickClosedLoopLiveReadonlySummary?.tickDeniedCollisionTotal == 2
        && multiTickClosedLoopLiveReadonlySummary?.tickFeedbackEmittedTotal == 10
        && multiTickClosedLoopLiveReadonlySummary?.feedbackConsumedTotal == 6
        && multiTickClosedLoopLiveReadonlySummary?.feedbackCarriedToNextTickTotal == 10
        && multiTickClosedLoopLiveReadonlySummary?.approvedApplicationsTotal == 0
        && multiTickClosedLoopLiveReadonlySummary?.sameTickFeedbackConsumedTotal == 0
        && multiTickClosedLoopLiveReadonlySummary?.crossAgentFeedbackLeaksTotal == 0
        && multiTickClosedLoopLiveReadonlySummary?.futureFeedbackConsumedTotal == 0
        && multiTickClosedLoopLiveReadonlySummary?.policyReadCollision == false
        && multiTickClosedLoopLiveReadonlySummary?.tickReadCollision == true
        && multiTickClosedLoopLiveReadonlySummary?.policyWorldUsed == false
        && multiTickClosedLoopLiveReadonlySummary?.tickWorldReadOnlyUsed == true
        && multiTickClosedLoopLiveReadonlySummary?.movementApplied == false
        && multiTickClosedLoopLiveReadonlySummary?.memoryUpdated == false
        && multiTickClosedLoopLiveReadonlySummary?.goalChanged == false
        && multiTickClosedLoopLiveReadonlySummary?.pathfindingPerformed == false
        && multiTickClosedLoopLiveReadonlySummary?.replanningPerformed == false
        && multiTickClosedLoopLiveReadonlySummary?.avoidancePerformed == false
        && multiTickClosedLoopLiveReadonlySummary?.reservationRuntimeUsed == false
        && multiTickClosedLoopLiveReadonlySummary?.routeFollowingUsed == false
        && multiTickClosedLoopLiveReadonlySummary?.worldMutated == false
        && multiTickClosedLoopLiveReadonlySummary?.mutationPerformed == false)
    : nil
let multiTickClosedLoopApprovedApplicationReport = isMultiTickClosedLoopApprovedApplicationScenario
    ? makeMultiTickClosedLoopApprovedApplicationReport(
        scenario: options.scenario,
        seed: options.seed,
        requestedTicks: options.ticks
    )
    : nil
let multiTickClosedLoopApprovedApplicationInvariantReport = isMultiTickClosedLoopApprovedApplicationScenario
    ? makeMultiTickClosedLoopApprovedApplicationInvariantReport(
        report: multiTickClosedLoopApprovedApplicationReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let multiTickClosedLoopApprovedApplicationSummary =
    multiTickClosedLoopApprovedApplicationReport?.summary
let multiTickClosedLoopApprovedApplicationSuccess = isMultiTickClosedLoopApprovedApplicationScenario
    ? ((multiTickClosedLoopApprovedApplicationReport?.success ?? false)
        && (multiTickClosedLoopApprovedApplicationInvariantReport?.success ?? false)
        && multiTickClosedLoopApprovedApplicationSummary?.requestedTicks == 3
        && multiTickClosedLoopApprovedApplicationSummary?.executedTicks == 3
        && multiTickClosedLoopApprovedApplicationSummary?.agents == 5
        && multiTickClosedLoopApprovedApplicationSummary?.contextsTotal == 15
        && (multiTickClosedLoopApprovedApplicationSummary?.contextsWithFeedbackTotal ?? 0) >= 5
        && (multiTickClosedLoopApprovedApplicationSummary?.contextsWithoutFeedbackTotal ?? 0) >= 5
        && multiTickClosedLoopApprovedApplicationSummary?.proposalsTotal == 15
        && (multiTickClosedLoopApprovedApplicationSummary?.noIntentFromBlockedFeedbackTotal ?? 0) >= 2
        && (multiTickClosedLoopApprovedApplicationSummary?.movementIntentInputsTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.tickApprovedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.tickDeniedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.tickDeniedConflictTotal ?? 0) >= 1
        && (multiTickClosedLoopApprovedApplicationSummary?.tickDeniedCollisionTotal ?? 0) >= 1
        && (multiTickClosedLoopApprovedApplicationSummary?.tickFeedbackEmittedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.feedbackConsumedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.approvedApplicationsTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.displacementsAppliedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.approvedAgentsMovedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.deniedAgentsPreservedTotal ?? 0) > 0
        && (multiTickClosedLoopApprovedApplicationSummary?.noIntentAgentsPreservedTotal ?? 0) > 0
        && multiTickClosedLoopApprovedApplicationSummary?.abstractPositionsChangedTotal == multiTickClosedLoopApprovedApplicationSummary?.displacementsAppliedTotal
        && multiTickClosedLoopApprovedApplicationSummary?.physicalPositionsChangedTotal == multiTickClosedLoopApprovedApplicationSummary?.displacementsAppliedTotal
        && multiTickClosedLoopApprovedApplicationSummary?.abstractPhysicalDivergenceBeforeMax == 0
        && multiTickClosedLoopApprovedApplicationSummary?.abstractPhysicalDivergenceAfterMax == 0
        && multiTickClosedLoopApprovedApplicationSummary?.sameTickFeedbackConsumedTotal == 0
        && multiTickClosedLoopApprovedApplicationSummary?.crossAgentFeedbackLeaksTotal == 0
        && multiTickClosedLoopApprovedApplicationSummary?.futureFeedbackConsumedTotal == 0
        && multiTickClosedLoopApprovedApplicationSummary?.policyReadCollision == false
        && multiTickClosedLoopApprovedApplicationSummary?.tickReadCollision == true
        && multiTickClosedLoopApprovedApplicationSummary?.policyWorldUsed == false
        && multiTickClosedLoopApprovedApplicationSummary?.tickWorldReadOnlyUsed == true
        && multiTickClosedLoopApprovedApplicationSummary?.movementApplied == true
        && multiTickClosedLoopApprovedApplicationSummary?.memoryUpdated == false
        && multiTickClosedLoopApprovedApplicationSummary?.goalChanged == false
        && multiTickClosedLoopApprovedApplicationSummary?.pathfindingPerformed == false
        && multiTickClosedLoopApprovedApplicationSummary?.replanningPerformed == false
        && multiTickClosedLoopApprovedApplicationSummary?.avoidancePerformed == false
        && multiTickClosedLoopApprovedApplicationSummary?.reservationRuntimeUsed == false
        && multiTickClosedLoopApprovedApplicationSummary?.routeFollowingUsed == false
        && multiTickClosedLoopApprovedApplicationSummary?.worldMutated == false
        && multiTickClosedLoopApprovedApplicationSummary?.mutationPerformed == false)
    : nil
let routeFollowingLiveSnapshot = isRouteFollowingDeniedLiveScenario
    ? makeRouteFollowingDeniedLiveSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        world: requireWorld()
    )
    : (isRouteFollowingApprovedTwoStepScenario
        ? makeRouteFollowingApprovedTwoStepSnapshot(
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted
        )
        : nil)
let isRouteFollowingLiveScenario = isRouteFollowingDeniedLiveScenario
    || isRouteFollowingApprovedTwoStepScenario
let routeFollowingLiveInvariantReport = isRouteFollowingLiveScenario
    ? makeRouteFollowingLiveInvariantReport(
        snapshot: routeFollowingLiveSnapshot,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let routeFollowingLiveDeniedEdges = routeFollowingLiveSnapshot?.perEdgeRecords.filter {
    !$0.displacementApplied
}.count
let routeFollowingLiveDisplacementsApplied = routeFollowingLiveSnapshot?.perEdgeRecords.filter(
    \.displacementApplied
).count
let routeFollowingLiveDeniedSuccess = isRouteFollowingDeniedLiveScenario
    && (routeFollowingLiveSnapshot?.success ?? false)
        && (routeFollowingLiveInvariantReport?.success ?? false)
        && routeFollowingLiveSnapshot?.status == .stoppedCollisionDenied
        && routeFollowingLiveSnapshot?.stoppedAtIndex == 0
        && routeFollowingLiveSnapshot?.attemptedEdges == 1
        && routeFollowingLiveSnapshot?.completedEdges == 0
        && routeFollowingLiveDisplacementsApplied == 0
        && routeFollowingLiveDeniedEdges == 1
        && routeFollowingLiveSnapshot?.finalAbstractPosition == routeFollowingLiveSnapshot?.perEdgeRecords.first?.preAbstractPosition
        && routeFollowingLiveSnapshot?.finalPhysicalPosition == routeFollowingLiveSnapshot?.perEdgeRecords.first?.prePhysicalPosition
        && routeFollowingLiveSnapshot?.divergenceBefore == 0
        && routeFollowingLiveSnapshot?.divergenceAfter == 0
        && routeFollowingLiveSnapshot?.pathfindingPerformedInsideFollower == false
        && routeFollowingLiveSnapshot?.replanningPerformed == false
        && routeFollowingLiveSnapshot?.physicsPerformed == false
        && routeFollowingLiveSnapshot?.mutationPerformed == false
let routeFollowingLiveApprovedSuccess = isRouteFollowingApprovedTwoStepScenario
    && (routeFollowingLiveSnapshot?.success ?? false)
        && (routeFollowingLiveInvariantReport?.success ?? false)
        && routeFollowingLiveSnapshot?.status == .completed
        && routeFollowingLiveSnapshot?.route.count == 3
        && routeFollowingLiveSnapshot?.attemptedEdges == 2
        && routeFollowingLiveSnapshot?.completedEdges == 2
        && routeFollowingLiveDisplacementsApplied == 2
        && routeFollowingLiveDeniedEdges == 0
        && routeFollowingLiveSnapshot?.stoppedAtIndex == nil
        && routeFollowingLiveSnapshot?.finalAbstractPosition == routeFollowingLiveSnapshot?.perEdgeRecords.last?.postAbstractPosition
        && routeFollowingLiveSnapshot?.finalPhysicalPosition == routeFollowingLiveSnapshot?.perEdgeRecords.last?.postPhysicalPosition
        && routeFollowingLiveSnapshot?.divergenceBefore == 0
        && routeFollowingLiveSnapshot?.divergenceAfter == 0
        && routeFollowingLiveSnapshot?.pathfindingPerformedInsideFollower == false
        && routeFollowingLiveSnapshot?.replanningPerformed == false
        && routeFollowingLiveSnapshot?.physicsPerformed == false
        && routeFollowingLiveSnapshot?.mutationPerformed == false
let routeFollowingLiveSuccess = isRouteFollowingLiveScenario
    ? (routeFollowingLiveDeniedSuccess || routeFollowingLiveApprovedSuccess)
    : nil
let routeFollowingLiveHardeningReport = isRouteFollowingLiveHardeningScenario
    ? makeRouteFollowingLiveHardeningReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let routeFollowingLiveHardeningInvariantReport = isRouteFollowingLiveHardeningScenario
    ? makeRouteFollowingLiveHardeningInvariantReport(
        report: routeFollowingLiveHardeningReport,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let routeFollowingLiveHardeningSuccess = isRouteFollowingLiveHardeningScenario
    ? ((routeFollowingLiveHardeningReport?.success ?? false)
        && (routeFollowingLiveHardeningInvariantReport?.success ?? false)
        && routeFollowingLiveHardeningReport?.summary.failed == 0
        && (routeFollowingLiveHardeningReport?.summary.completed ?? 0) >= 1
        && (routeFollowingLiveHardeningReport?.summary.collisionDenied ?? 0) >= 1
        && (routeFollowingLiveHardeningReport?.summary.invalidEdges ?? 0) >= 2
        && (routeFollowingLiveHardeningReport?.summary.sourceMismatch ?? 0) >= 1
        && (routeFollowingLiveHardeningReport?.summary.divergence ?? 0) >= 1
        && (routeFollowingLiveHardeningReport?.summary.staleCollision ?? 0) >= 1
        && (routeFollowingLiveHardeningReport?.summary.maxSteps ?? 0) >= 1)
    : nil
let coreEntityInvariantReport = options.scenario == "core_entity_smoke"
    ? coreEntityBridge.invariantReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        agents: labAgents,
        physicalBridge: physicalBridge,
        world: requireWorld()
    )
    : nil
let physicalBehaviorAgents = isPhysicalBehaviorScenario ? labAgents.count : nil
let physicalBehaviorAgentsMoved = isPhysicalBehaviorScenario
    ? labAgents.filter { $0.movementCount > 0 }.count
    : nil
let physicalBehaviorMoves = isPhysicalBehaviorScenario
    ? labAgents.reduce(0) { $0 + $1.movementCount }
    : nil
let physicalBehaviorTotalDistance = isPhysicalBehaviorScenario
    ? labAgents.reduce(0) { $0 + $1.totalManhattanDistanceMoved }
    : nil
let physicalBehaviorFinalDivergence = isPhysicalBehaviorScenario
    ? coreEntityBridge.totalDivergence(from: labAgents)
    : nil
let physicalBehaviorMaxDivergence = isPhysicalBehaviorScenario
    ? coreEntityBridge.maxDivergence(from: labAgents)
    : nil
let physicalBehaviorLinksCoherent = isPhysicalBehaviorScenario && labAgents.allSatisfy { agent in
    let handles = physicalBridge.handles.filter { $0.agentId == agent.id }
    let entities = coreEntityBridge.entities.filter { $0.labAgentId == agent.id }
    return handles.count == 1
        && entities.count == 1
        && handles[0].physicalId == entities[0].physicalId
} && Set(physicalBridge.handles.map(\.physicalId)).count == physicalBridge.count
    && Set(coreEntityBridge.entities.map(\.id)).count == coreEntityBridge.count
    && physicalBridge.count == labAgents.count
    && coreEntityBridge.count == labAgents.count
let requiredPhysicalBehaviorAgentsMoved = options.scenario == "physical_behavior_multi_smoke" ? 2 : 1
let physicalBehaviorInvariantReport = options.scenario == "physical_behavior_multi_smoke"
    ? coreEntityBridge.physicalBehaviorInvariantReport(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        agents: labAgents,
        physicalBridge: physicalBridge,
        agentsMoved: physicalBehaviorAgentsMoved ?? 0,
        totalMoves: physicalBehaviorMoves ?? 0,
        totalDistance: physicalBehaviorTotalDistance ?? 0
    )
    : nil
let physicalBehaviorSuccess = isPhysicalBehaviorScenario
    ? ((physicalBehaviorAgentsMoved ?? 0) >= requiredPhysicalBehaviorAgentsMoved
        && (physicalBehaviorMoves ?? 0) > 0
        && coreEntitySyncEvents > 0
        && physicalBehaviorFinalDivergence == 0
        && physicalBehaviorMaxDivergence == 0
        && physicalBehaviorLinksCoherent
        && (physicalBehaviorInvariantReport?.success ?? true))
    : nil
let worldInteractionSnapshots: [LabWorldInteractionSnapshot] = {
    guard isWorldObservationScenario else { return [] }
    let coreLinks = coreEntityBridge.snapshotLinks(for: labAgents)
    return labAgents.compactMap { agent in
        guard let handle = physicalBridge.handles.first(where: { $0.agentId == agent.id }),
              let coreLink = coreLinks.first(where: { $0.agentId == agent.id }) else {
            return nil
        }
        return observeBlockBelow(
            world: requireWorld(),
            scenario: options.scenario,
            seed: options.seed,
            ticksCompleted: ticksCompleted,
            agent: agent,
            handle: handle,
            coreLink: coreLink
        )
    }
}()
let worldInteractionSnapshot = isWorldObservationSingleScenario ? worldInteractionSnapshots.first : nil
let worldInteractionMultiSnapshot = isWorldObservationMultiScenario
    ? makeWorldInteractionMultiSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        snapshots: worldInteractionSnapshots,
        agents: labAgents.count,
        placeholders: physicalBridge.count,
        coreEntities: coreEntityBridge.count
    )
    : nil
let worldObservationInvariantReport = worldInteractionMultiSnapshot.map(
    makeWorldObservationInvariantReport
)
let worldInteractionAgents = isWorldObservationScenario ? labAgents.count : nil
let worldInteractionObservations = isWorldObservationScenario ? worldInteractionSnapshots.count : nil
let worldInteractionLoadedObservations = isWorldObservationScenario ? worldInteractionSnapshots.filter { $0.chunk.loaded }.count : nil
let worldInteractionReadyObservations = isWorldObservationScenario ? worldInteractionSnapshots.filter { $0.chunk.ready }.count : nil
let worldInteractionUniqueChunks = isWorldObservationScenario
    ? Set(worldInteractionSnapshots.map { "\($0.chunk.cx),\($0.chunk.cz)" }).count
    : nil
let worldInteractionDistinctBlockIds = isWorldObservationScenario
    ? Set(worldInteractionSnapshots.compactMap(\.blockId)).count
    : nil
let worldInteractionSuccess = isWorldObservationSingleScenario
    ? (worldInteractionSnapshot?.success ?? false)
    : (isWorldObservationMultiScenario
        ? ((worldInteractionMultiSnapshot?.summary.success ?? false)
            && (worldObservationInvariantReport?.success ?? false))
        : nil)
let terrainScanSnapshot: LabTerrainScanSnapshot? = {
    guard let terrainScanContract,
          let agent = labAgents.first,
          let handle = physicalBridge.handles.first(where: { $0.agentId == agent.id }),
          let coreLink = coreEntityBridge.snapshotLinks(for: labAgents).first(where: {
              $0.agentId == agent.id
          }) else {
        return nil
    }
    return scanTerrainAroundBelow(
        world: requireWorld(),
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        agent: agent,
        handle: handle,
        coreLink: coreLink,
        contract: terrainScanContract
    )
}()
let terrainScanInvariantReport: TerrainScanInvariantReport? = terrainScanSnapshot.flatMap { snapshot in
    guard let terrainScanContract else { return nil }
    return makeTerrainScanInvariantReport(
        snapshot: snapshot,
        agents: labAgents.count,
        placeholders: physicalBridge.count,
        coreEntities: coreEntityBridge.count,
        contract: terrainScanContract
    )
}
let terrainSemanticsInvariantReport = terrainScanSnapshot.map(
    makeTerrainSemanticsInvariantReport
)
let terrainScanSuccess = isTerrainScanRun
    ? ((terrainScanSnapshot?.summary.success ?? false)
        && (terrainScanInvariantReport?.success ?? false))
    : nil
let terrainSemanticSuccess = isTerrainScanRun
    ? ((terrainScanSnapshot?.semanticSummary.success ?? false)
        && (terrainSemanticsInvariantReport?.success ?? false))
    : nil
let terrainColumnScanSnapshot: LabTerrainColumnScanSnapshot? = {
    guard let terrainColumnScanContract,
          let agent = labAgents.first,
          let handle = physicalBridge.handles.first(where: { $0.agentId == agent.id }),
          let coreLink = coreEntityBridge.snapshotLinks(for: labAgents).first(where: {
              $0.agentId == agent.id
          }) else {
        return nil
    }
    return scanTerrainColumns(
        world: requireWorld(),
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted,
        agent: agent,
        handle: handle,
        coreLink: coreLink,
        contract: terrainColumnScanContract
    )
}()
let terrainColumnScanInvariantReport: TerrainColumnScanInvariantReport? = terrainColumnScanSnapshot.flatMap { snapshot in
    guard let terrainColumnScanContract else { return nil }
    return makeTerrainColumnScanInvariantReport(
        snapshot: snapshot,
        agents: labAgents.count,
        placeholders: physicalBridge.count,
        coreEntities: coreEntityBridge.count,
        contract: terrainColumnScanContract
    )
}
let terrainColumnDerivedSummary = terrainColumnScanSnapshot.map(
    makeTerrainColumnDerivedSummary
)
let terrainColumnScanSuccess = isTerrainColumnScanRun
    ? ((terrainColumnScanSnapshot?.summary.success ?? false)
        && (terrainColumnScanInvariantReport?.success ?? false))
    : nil
let terrainColumnTraversabilitySuccess = isTerrainColumnScanRun
    ? (terrainColumnDerivedSummary?.success ?? false)
    : nil
let terrainPathfindingColumnSnapshot = isTerrainPathfindingColumnScenario
    ? terrainColumnScanSnapshot.flatMap { makeTerrainLivePathfindingSnapshot(from: $0) }
    : nil
let terrainPathfindingColumnInvariantReport = terrainPathfindingColumnSnapshot.flatMap { snapshot in
    terrainColumnScanSnapshot.map {
        makeTerrainPathfindingColumnInvariantReport(
            columnSnapshot: $0,
            pathfindingSnapshot: snapshot
        )
    }
}
let terrainPathfindingColumnSuccess = isTerrainPathfindingColumnScenario
    ? ((terrainPathfindingColumnSnapshot?.summary.success ?? false)
        && (terrainPathfindingColumnInvariantReport?.success ?? false))
    : nil
let terrainPathfindingPositiveSnapshot = isTerrainPathfindingPositiveScenario
    ? makeTerrainPathfindingPositiveSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let terrainPathfindingPositiveInvariantReport = terrainPathfindingPositiveSnapshot.map(
    makeTerrainPathfindingPositiveInvariantReport
)
let terrainPathfindingPositiveSuccess = isTerrainPathfindingPositiveScenario
    ? ((terrainPathfindingPositiveSnapshot?.summary.success ?? false)
        && (terrainPathfindingPositiveInvariantReport?.success ?? false)
        && terrainPathfindingPositiveSnapshot?.selectedPathfindingSnapshot?.result.status == .found)
    : nil
let terrainLiveMovementPositiveSnapshot = isTerrainLiveMovementScenario
    ? makeTerrainPathfindingPositiveSnapshot(
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
    : nil
let terrainLiveMovementSnapshot = terrainLiveMovementPositiveSnapshot.flatMap {
    makeTerrainLiveMovementSnapshot(
        from: $0,
        scenario: options.scenario,
        seed: options.seed,
        ticksCompleted: ticksCompleted
    )
}
let terrainLiveMovementInvariantReport = isTerrainLiveMovementScenario
    ? makeTerrainLiveMovementInvariantReport(
        positiveSnapshot: terrainLiveMovementPositiveSnapshot,
        movementSnapshot: terrainLiveMovementSnapshot,
        scenario: options.scenario,
        seed: options.seed
    )
    : nil
let terrainLiveMovementSuccess = isTerrainLiveMovementScenario
    ? ((terrainLiveMovementSnapshot?.summary.success ?? false)
        && (terrainLiveMovementInvariantReport?.success ?? false)
        && terrainLiveMovementSnapshot?.selectedPathStatus == .found
        && terrainLiveMovementSnapshot?.finalMovementState.status == .reachedGoal
        && terrainLiveMovementSnapshot?.summary.liveAgentDisplaced == false
        && terrainLiveMovementSnapshot?.summary.collisionPerformed == false
        && terrainLiveMovementSnapshot?.summary.mutationPerformed == false)
    : nil
let runSuccess = successCriteria.ticksCompleted
    && successCriteria.agentsSpawned
    && successCriteria.agentTicksRecorded
    && (coreEntityInvariantReport?.success ?? true)
    && (physicalBehaviorInvariantReport?.success ?? true)
    && (physicalBehaviorSuccess ?? true)
    && (worldObservationInvariantReport?.success ?? true)
    && (worldInteractionSuccess ?? true)
    && (terrainScanSuccess ?? true)
    && (terrainSemanticSuccess ?? true)
    && (terrainSemanticsFixtureSuccess ?? true)
    && (terrainTraversabilitySuccess ?? true)
    && (terrainColumnScanSuccess ?? true)
    && (terrainColumnTraversabilitySuccess ?? true)
    && (terrainPathfindingSuccess ?? true)
    && (terrainPathfindingColumnSuccess ?? true)
    && (terrainPathfindingPositiveSuccess ?? true)
    && (terrainMovementSuccess ?? true)
    && (terrainLiveMovementSuccess ?? true)
    && (terrainCollisionSuccess ?? true)
    && (terrainCollisionLiveSuccess ?? true)
    && (physicalMovementSuccess ?? true)
    && (physicalMovementOccupableSearchSuccess ?? true)
    && (physicalMovementHardeningSuccess ?? true)
    && (routeFollowingFixtureSuccess ?? true)
    && (multiAgentMovementFixtureSuccess ?? true)
    && (multiAgentMovementFixtureHardeningSuccess ?? true)
    && (multiAgentLiveCollisionIntentSuccess ?? true)
    && (multiAgentApprovedPhysicalMovementSuccess ?? true)
    && (multiAgentMovementHardeningSuccess ?? true)
    && (multiAgentMovementTickFixtureSuccess ?? true)
    && (multiAgentMovementTickLiveReadonlySuccess ?? true)
    && (multiAgentMovementTickApprovedApplicationSuccess ?? true)
    && (multiAgentMovementTickHardeningSuccess ?? true)
    && (agentIntentProductionFixtureSuccess ?? true)
    && (agentIntentProductionHardeningSuccess ?? true)
    && (agentIntentToTickFixtureSuccess ?? true)
    && (agentIntentToTickLiveReadonlySuccess ?? true)
    && (agentIntentToTickApprovedApplicationSuccess ?? true)
    && (agentFeedbackConsumptionFixtureSuccess ?? true)
    && (agentFeedbackConsumptionHardeningSuccess ?? true)
    && (feedbackToAgentIntentContextFixtureSuccess ?? true)
    && (feedbackToAgentIntentContextHardeningSuccess ?? true)
    && (feedbackAwareIntentPolicyFixtureSuccess ?? true)
    && (feedbackAwareIntentPolicyHardeningSuccess ?? true)
    && (feedbackAwareIntentToTickFixtureSuccess ?? true)
    && (feedbackAwareIntentToTickLiveReadonlySuccess ?? true)
    && (feedbackAwareIntentToTickApprovedApplicationSuccess ?? true)
    && (alternateLocalHintSuccess ?? true)
    && (alternateLocalHintHardeningSuccess ?? true)
    && (multiTickClosedLoopSuccess ?? true)
    && (multiTickClosedLoopHardeningSuccess ?? true)
    && (multiTickClosedLoopLiveReadonlySuccess ?? true)
    && (multiTickClosedLoopApprovedApplicationSuccess ?? true)
    && (routeFollowingLiveSuccess ?? true)
    && (routeFollowingLiveHardeningSuccess ?? true)

if options.outPath != nil {
    do {
        if options.scenario == "physical_behavior_smoke" {
            try appendEvent(RunEvent(
                type: "lab_physical_behavior_completed",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: physicalBehaviorSuccess,
                agentId: labAgents.first?.id,
                physicalId: physicalBridge.handles.first?.physicalId,
                coreEntityId: coreEntityBridge.entities.first?.id,
                moves: physicalBehaviorMoves,
                totalDistance: physicalBehaviorTotalDistance,
                finalDivergence: physicalBehaviorFinalDivergence
            ))
        } else if options.scenario == "physical_behavior_multi_smoke" {
            try appendEvent(RunEvent(
                type: "lab_physical_behavior_multi_completed",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: physicalBehaviorSuccess,
                agents: physicalBehaviorAgents,
                moves: physicalBehaviorMoves,
                totalDistance: physicalBehaviorTotalDistance,
                finalDivergence: physicalBehaviorFinalDivergence,
                agentsMoved: physicalBehaviorAgentsMoved,
                maxDivergence: physicalBehaviorMaxDivergence
            ))
        }
        if let fixtureReport = terrainSemanticsFixtureReport {
            try appendEvent(RunEvent(
                type: "lab_terrain_semantics_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: fixtureReport.success,
                fixtures: fixtureReport.summary.fixtures,
                passed: fixtureReport.summary.passed,
                failed: fixtureReport.summary.failed,
                unknownCases: fixtureReport.summary.unknownCases,
                airCases: fixtureReport.summary.airCases,
                solidCases: fixtureReport.summary.solidCases,
                liquidCases: fixtureReport.summary.liquidCases,
                plantLikeCases: fixtureReport.summary.plantLikeCases,
                otherCases: fixtureReport.summary.otherCases
            ))
        }
        if let traversabilitySummary = terrainTraversabilitySummary {
            try appendEvent(RunEvent(
                type: "lab_terrain_traversability_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainTraversabilitySuccess,
                unknownCells: traversabilitySummary.unknownCells,
                otherCells: traversabilitySummary.otherCells,
                cellsEvaluated: traversabilitySummary.cellsEvaluated,
                traversableCells: traversabilitySummary.traversableCells,
                blockedCells: traversabilitySummary.blockedCells,
                unsupportedCells: traversabilitySummary.unsupportedCells,
                unsafeCells: traversabilitySummary.unsafeCells,
                occupiedVerticalSpaceCells: traversabilitySummary.occupiedVerticalSpaceCells
            ))
        }
        if let pathfindingSummary = terrainPathfindingFixtureReport?.summary {
            try appendEvent(RunEvent(
                type: "lab_terrain_pathfinding_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainPathfindingSuccess,
                fixtures: pathfindingSummary.fixtures,
                passed: pathfindingSummary.passed,
                failed: pathfindingSummary.failed,
                pathsFound: pathfindingSummary.pathsFound,
                pathsNotFound: pathfindingSummary.pathsNotFound,
                invalidStarts: pathfindingSummary.invalidStarts,
                invalidGoals: pathfindingSummary.invalidGoals,
                searchLimitReached: pathfindingSummary.searchLimitReached,
                unknown: pathfindingSummary.unknown
            ))
        }
        if let movementSummary = terrainMovementFixtureReport?.summary {
            try appendEvent(RunEvent(
                type: "lab_terrain_movement_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainMovementSuccess,
                fixtures: movementSummary.fixtures,
                passed: movementSummary.passed,
                failed: movementSummary.failed,
                stepsPlanned: movementSummary.stepsPlanned,
                stepsExecuted: movementSummary.stepsExecuted,
                reachedGoals: movementSummary.reachedGoals,
                invalidPaths: movementSummary.invalidPaths
            ))
        }
        if let collisionSummary = terrainCollisionFixtureReport?.summary {
            try appendEvent(RunEvent(
                type: "lab_terrain_collision_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainCollisionSuccess,
                fixtures: collisionSummary.fixtures,
                passed: collisionSummary.passed,
                failed: collisionSummary.failed,
                unknown: collisionSummary.unknown,
                occupable: collisionSummary.occupable,
                blocked: collisionSummary.blocked,
                unsupported: collisionSummary.unsupported,
                verticalSpaceOccupied: collisionSummary.verticalSpaceOccupied,
                liquidUnsupported: collisionSummary.liquidUnsupported,
                outOfBounds: collisionSummary.outOfBounds,
                notLoaded: collisionSummary.notLoaded,
                notReady: collisionSummary.notReady
            ))
        }
        if let collisionLiveSnapshot = terrainCollisionLiveSnapshot {
            let summary = collisionLiveSnapshot.summary
            try appendEvent(RunEvent(
                type: "lab_terrain_collision_live_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainCollisionLiveSuccess,
                x: collisionLiveSnapshot.node.x,
                y: collisionLiveSnapshot.node.y,
                z: collisionLiveSnapshot.node.z,
                reason: summary.reason,
                liveAgentDisplaced: summary.liveAgentDisplaced,
                collisionPerformed: false,
                mutationPerformed: summary.mutationPerformed,
                status: summary.status.rawValue,
                samples: summary.samples,
                loadedSamples: summary.loadedSamples,
                readySamples: summary.readySamples,
                physicalPlaceholderDisplaced: summary.physicalPlaceholderDisplaced,
                coreEntityDisplaced: summary.coreEntityDisplaced,
                movementPerformed: summary.movementPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
            ))
        }
        if let physicalMovementSnapshot {
            try appendEvent(RunEvent(
                type: "lab_physical_movement_integration_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: physicalMovementSuccess,
                agentId: physicalMovementSnapshot.agentId,
                fromX: physicalMovementSnapshot.from.x,
                fromY: physicalMovementSnapshot.from.y,
                fromZ: physicalMovementSnapshot.from.z,
                toX: physicalMovementSnapshot.to.x,
                toY: physicalMovementSnapshot.to.y,
                toZ: physicalMovementSnapshot.to.z,
                reason: physicalMovementSnapshot.reason,
                physicalId: physicalMovementSnapshot.physicalId,
                coreEntityId: physicalMovementSnapshot.coreEntityId,
                mutationPerformed: physicalMovementSnapshot.mutationPerformed,
                status: physicalMovementSnapshot.status.rawValue,
                pathfindingPerformed: physicalMovementSnapshot.pathfindingPerformed,
                collisionStatus: physicalMovementSnapshot.collisionStatus.rawValue,
                displacementApplied: physicalMovementSnapshot.displacementApplied,
                routeFollowingPerformed: physicalMovementSnapshot.routeFollowingPerformed,
                physicsPerformed: physicalMovementSnapshot.physicsPerformed,
                divergenceBefore: physicalMovementSnapshot.divergenceBefore,
                divergenceAfter: physicalMovementSnapshot.divergenceAfter
            ))
        }
        if let physicalMovementOccupableSearchSnapshot {
            let summary = physicalMovementOccupableSearchSnapshot.summary
            try appendEvent(RunEvent(
                type: "lab_physical_movement_occupable_search_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: physicalMovementOccupableSearchSuccess,
                x: summary.selectedNode?.x,
                y: summary.selectedNode?.y,
                z: summary.selectedNode?.z,
                candidates: summary.candidatesEvaluated,
                occupableFound: summary.occupableFound,
                selectedCandidateIndex: summary.selectedCandidateIndex,
                mutationPerformed: summary.mutationPerformed,
                status: summary.selectedStatus?.rawValue,
                movementPerformed: summary.movementPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                routeFollowingPerformed: summary.routeFollowingPerformed,
                physicsPerformed: summary.physicsPerformed
            ))
        }
        if let physicalMovementHardeningReport {
            let summary = physicalMovementHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_physical_movement_single_step_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: physicalMovementHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approved,
                denied: summary.denied,
                displacementRefused: summary.displacementRefused,
                cases: summary.cases,
                displacementApplied: summary.displacementApplied > 0
            ))
        }
        if let routeFollowingFixtureReport {
            let summary = routeFollowingFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_route_following_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: routeFollowingFixtureSuccess,
                passed: summary.passed,
                failed: summary.failed,
                completed: summary.completed,
                stopped: summary.stopped,
                attemptedEdges: summary.attemptedEdges,
                completedEdges: summary.completedEdges,
                displacementsApplied: summary.displacementsApplied,
                deniedEdges: summary.deniedEdges,
                cases: summary.cases
            ))
        }
        if let multiAgentMovementFixtureReport {
            let summary = multiAgentMovementFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentMovementFixtureSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                cases: summary.cases,
                agentCount: summary.agentCountTotal,
                intentCount: summary.intentCountTotal,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                occupiedDestinationConflicts: summary.occupiedDestinationConflicts,
                swapConflicts: summary.swapConflicts,
                sourceMismatch: summary.sourceMismatch,
                staleIntent: summary.staleIntent,
                missingAgent: summary.missingAgent,
                invalidEdges: summary.invalidEdges
            ))
        }
        if let multiAgentMovementFixtureHardeningReport {
            let summary = multiAgentMovementFixtureHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_fixture_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentMovementFixtureHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                cases: summary.cases,
                duplicateIntent: summary.duplicateIntent,
                cycleConflicts: summary.cycleConflicts,
                chainDependencies: summary.chainDependencies,
                movingAwayDestination: summary.movingAwayDestination,
                verticalInvalidEdges: summary.verticalInvalidEdges,
                zeroLengthEdges: summary.zeroLengthEdges,
                allDeniedCases: summary.allDeniedCases,
                emptyIntentCases: summary.emptyIntentCases,
                maxAgentsExceeded: summary.maxAgentsExceeded
            ))
        }
        if let multiAgentLiveCollisionIntentReport {
            let summary = multiAgentLiveCollisionIntentReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_live_collision_intent_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentLiveCollisionIntentSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                cases: summary.cases,
                agentCount: summary.agentCountTotal,
                intentCount: summary.intentCountTotal,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                sourceMismatch: summary.sourceMismatch,
                staleIntent: summary.staleIntent,
                invalidEdges: summary.invalidEdges,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.collisionDenied,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied,
                routeFollowingApplied: summary.routeFollowingApplied,
                displacementApplied: summary.displacementApplied
            ))
        }
        if let multiAgentApprovedPhysicalMovementReport {
            let summary = multiAgentApprovedPhysicalMovementReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_approved_physical_movement_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentApprovedPhysicalMovementSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                displacementsApplied: summary.displacementsApplied,
                cases: summary.cases,
                agentCount: summary.agentCountTotal,
                intentCount: summary.intentCountTotal,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                divergenceBeforeMax: summary.divergenceBeforeMax,
                divergenceAfterMax: summary.divergenceAfterMax,
                worldUsed: summary.worldUsed,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied,
                routeFollowingApplied: summary.routeFollowingApplied,
                mutationPerformed: summary.terrainMutationPerformed || summary.worldMutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed
            ))
        }
        if let multiAgentMovementHardeningReport {
            let summary = multiAgentMovementHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentMovementHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                displacementsApplied: summary.displacementsApplied,
                cases: summary.cases,
                agentCount: summary.agentCountTotal,
                intentCount: summary.intentCountTotal,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                swapConflicts: summary.swapConflicts,
                sourceMismatch: summary.sourceMismatch,
                staleIntent: summary.staleIntent,
                invalidEdges: summary.invalidEdges,
                allDeniedCases: summary.allDeniedCases,
                maxAgentsExceeded: summary.maxAgentsExceeded,
                collisionDenied: summary.collisionDenied,
                divergenceDenied: summary.divergenceDenied,
                staleCollision: summary.staleCollision,
                partialApprovalCases: summary.partialApprovalCases,
                divergenceBeforeMax: summary.divergenceBeforeMax,
                divergenceAfterMax: summary.divergenceAfterMax,
                worldUsed: summary.worldUsed,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied,
                routeFollowingApplied: summary.routeFollowingApplied,
                mutationPerformed: summary.terrainMutationPerformed || summary.worldMutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed
            ))
        }
        if let multiAgentMovementTickFixtureReport {
            let summary = multiAgentMovementTickFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_tick_fixture_recorded",
                tick: summary.tick,
                scenario: options.scenario,
                success: multiAgentMovementTickFixtureSuccess,
                approved: summary.approved,
                denied: summary.denied,
                displacementsApplied: summary.displacementsApplied,
                agentCount: summary.agentCount,
                intentCount: summary.intentCount,
                resolutions: summary.resolutions,
                feedback: summary.feedbackCount,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                invalidEdges: summary.invalidEdges
            ))
        }
        if let multiAgentMovementTickLiveReadonlyReport {
            let summary = multiAgentMovementTickLiveReadonlyReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_tick_live_readonly_recorded",
                tick: summary.tick,
                scenario: options.scenario,
                success: multiAgentMovementTickLiveReadonlySuccess,
                approved: summary.approved,
                denied: summary.denied,
                displacementsApplied: summary.displacementsApplied,
                agentCount: summary.agentCount,
                intentCount: summary.intentCount,
                resolutions: summary.resolutions,
                feedback: summary.feedbackCount,
                sourceMismatch: summary.sourceMismatch,
                invalidEdges: summary.invalidEdges,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.collisionDenied,
                worldUsed: summary.worldUsed,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied
            ))
        }
        if let multiAgentMovementTickApprovedApplicationReport {
            let summary = multiAgentMovementTickApprovedApplicationReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_tick_approved_application_recorded",
                tick: summary.tick,
                scenario: options.scenario,
                success: multiAgentMovementTickApprovedApplicationSuccess,
                approved: summary.approved,
                denied: summary.denied,
                displacementsApplied: summary.displacementsApplied,
                agentCount: summary.agentCount,
                intentCount: summary.intentCount,
                resolutions: summary.resolutions,
                feedback: summary.feedbackCount,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                divergenceBeforeMax: summary.divergenceBeforeMax,
                divergenceAfterMax: summary.divergenceAfterMax,
                worldUsed: summary.worldUsed,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied,
                routeFollowingApplied: summary.routeFollowingApplied,
                mutationPerformed: summary.terrainMutationPerformed || summary.worldMutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
            ))
        }
        if let multiAgentMovementTickHardeningReport {
            let summary = multiAgentMovementTickHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_agent_movement_tick_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: multiAgentMovementTickHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                approved: summary.approvedTotal,
                denied: summary.deniedTotal,
                displacementsApplied: summary.displacementsApplied,
                cases: summary.cases,
                tickCount: summary.tickCount,
                agentCount: summary.agentCountTotal,
                intentCount: summary.intentCountTotal,
                resolutions: summary.resolutionCountTotal,
                feedback: summary.feedbackCountTotal,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                swapConflicts: summary.swapConflicts,
                sourceMismatch: summary.sourceMismatch,
                staleIntent: summary.staleIntent,
                invalidEdges: summary.invalidEdges,
                allDeniedCases: summary.allDeniedCases,
                maxAgentsExceeded: summary.maxAgentsExceeded,
                movedFeedback: summary.movedFeedback,
                approvedForMovementFeedback: summary.approvedForMovementFeedback,
                blockedByCollisionFeedback: summary.blockedByCollisionFeedback,
                blockedByAgentConflictFeedback: summary.blockedByAgentConflictFeedback,
                blockedBySourceMismatchFeedback: summary.blockedBySourceMismatchFeedback,
                blockedByDivergenceFeedback: summary.blockedByDivergenceFeedback,
                blockedByStaleIntentFeedback: summary.blockedByStaleIntentFeedback,
                blockedByInvalidEdgeFeedback: summary.blockedByInvalidEdgeFeedback,
                blockedByMaxAgentsFeedback: summary.blockedByMaxAgentsFeedback,
                collisionDenied: summary.collisionDenied,
                divergenceDenied: summary.divergenceDenied,
                staleCollision: summary.staleCollision,
                partialApprovalCases: summary.partialApprovalCases,
                divergenceBeforeMax: summary.divergenceBeforeMax,
                divergenceAfterMax: summary.divergenceAfterMax,
                worldUsed: summary.worldUsed,
                liveCollisionRead: summary.liveCollisionRead,
                physicalMovementApplied: summary.physicalMovementApplied,
                routeFollowingApplied: summary.routeFollowingApplied,
                mutationPerformed: summary.terrainMutationPerformed || summary.worldMutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed
            ))
        }
        if let agentIntentProductionFixtureReport {
            let summary = agentIntentProductionFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_intent_production_fixture_recorded",
                tick: summary.tick,
                scenario: options.scenario,
                success: agentIntentProductionFixtureSuccess,
                agentCount: summary.agentsObserved,
                agentsObserved: summary.agentsObserved,
                contexts: summary.contexts,
                proposals: summary.proposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                noIntent: summary.noIntent,
                invalidContext: summary.invalidContext,
                invalidOneEdgeProposals: summary.invalidOneEdgeProposals,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: summary.feedbackConsumed,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let agentIntentProductionHardeningReport {
            let summary = agentIntentProductionHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_intent_production_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentIntentProductionHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                cases: summary.cases,
                contexts: summary.contextsTotal,
                proposals: summary.proposalsTotal,
                acceptedIntents: summary.acceptedIntentsTotal,
                rejectedProposals: summary.rejectedProposalsTotal,
                noIntent: summary.noIntentTotal,
                invalidContext: summary.invalidContextTotal,
                duplicateAgentContexts: summary.duplicateAgentContextsTotal,
                duplicateProposals: summary.duplicateProposalsTotal,
                invalidOneEdgeProposals: summary.invalidOneEdgeProposalsTotal,
                staleProposals: summary.staleProposalsTotal,
                wrongSourceProposals: summary.wrongSourceProposalsTotal,
                maxProposalsExceeded: summary.maxProposalsExceededTotal,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: summary.feedbackConsumed,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed,
                physicsPerformed: summary.physicsPerformed
            ))
        }
        if let agentIntentToTickFixtureReport {
            let summary = agentIntentToTickFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_intent_to_tick_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentIntentToTickFixtureSuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.proposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                tickAgents: summary.tickAgents,
                tickIntents: summary.tickIntents,
                tickResolutions: summary.tickResolutions,
                tickFeedback: summary.tickFeedback,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                sameDestinationConflicts: summary.sameDestinationConflicts,
                productionAcceptedSameDestination: summary.productionAcceptedSameDestination,
                tickResolvedSameDestination: summary.tickResolvedSameDestination,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: summary.feedbackConsumed,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed,
                physicsPerformed: summary.physicsPerformed
            ))
        }
        if let agentIntentToTickLiveReadonlyReport {
            let summary = agentIntentToTickLiveReadonlyReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_intent_to_tick_live_readonly_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentIntentToTickLiveReadonlySuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.proposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                tickAgents: summary.tickAgents,
                tickIntents: summary.tickIntents,
                tickResolutions: summary.tickResolutions,
                tickFeedback: summary.tickFeedback,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.collisionDenied,
                productionReadCollision: summary.productionReadCollision,
                tickReadCollision: summary.tickReadLiveCollision,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: summary.feedbackConsumed,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed,
                physicsPerformed: summary.physicsPerformed
            ))
        }
        if let agentIntentToTickApprovedApplicationReport {
            let summary = agentIntentToTickApprovedApplicationReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_intent_to_tick_approved_application_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentIntentToTickApprovedApplicationSuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.proposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                tickAgents: summary.tickAgents,
                tickIntents: summary.tickIntents,
                tickResolutions: summary.tickResolutions,
                tickFeedback: summary.tickFeedback,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                movedFeedback: summary.movedFeedback,
                blockedByCollisionFeedback: summary.blockedByCollisionFeedback,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.collisionDenied,
                deniedPositionsPreserved: summary.deniedPositionsPreserved,
                approvedPositionsMoved: summary.approvedPositionsMoved,
                productionReadCollision: summary.productionReadCollision,
                tickReadCollision: summary.tickReadLiveCollision,
                worldUsed: summary.worldUsed,
                routeFollowingApplied: summary.routeFollowingApplied,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: summary.feedbackConsumed,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed,
                physicsPerformed: summary.physicsPerformed,
                divergenceBefore: summary.abstractPhysicalDivergenceBefore,
                divergenceAfter: summary.abstractPhysicalDivergenceAfter
            ))
        }
        if let agentFeedbackConsumptionFixtureReport {
            let summary = agentFeedbackConsumptionFixtureReport.summary
            let resultSummary = agentFeedbackConsumptionFixtureReport.result.summary
            try appendEvent(RunEvent(
                type: "lab_agent_feedback_consumption_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentFeedbackConsumptionFixtureSuccess,
                agentsObserved: summary.agentsObserved,
                feedbackObserved: summary.feedbackObserved,
                feedbackAccepted: summary.feedbackAccepted,
                feedbackIgnored: summary.feedbackIgnored,
                invalidFeedback: summary.invalidFeedback,
                contextsProduced: summary.contextsProduced,
                moved: summary.moved,
                approvedForMovement: summary.approvedForMovement,
                blockedByCollision: summary.blockedByCollision,
                blockedByAgentConflict: summary.blockedByAgentConflict,
                blockedByMaxAgents: resultSummary.blockedByMaxAgents,
                duplicateFeedback: summary.duplicateFeedback,
                intentProduced: summary.intentProduced,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                feedbackConsumed: true,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let agentFeedbackConsumptionHardeningReport {
            let summary = agentFeedbackConsumptionHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_agent_feedback_consumption_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: agentFeedbackConsumptionHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                cases: summary.cases,
                feedbackObservedTotal: summary.feedbackObservedTotal,
                feedbackAcceptedTotal: summary.feedbackAcceptedTotal,
                feedbackIgnoredTotal: summary.feedbackIgnoredTotal,
                invalidFeedbackTotal: summary.invalidFeedbackTotal,
                contextsProducedTotal: summary.contextsProducedTotal,
                duplicateFeedbackTotal: summary.duplicateFeedbackTotal,
                maxFeedbackExceededTotal: summary.maxFeedbackExceededTotal,
                tickMismatchFeedbackTotal: summary.tickMismatchFeedbackTotal,
                movedTotal: summary.movedTotal,
                approvedForMovementTotal: summary.approvedForMovementTotal,
                blockedByCollisionTotal: summary.blockedByCollisionTotal,
                blockedByAgentConflictTotal: summary.blockedByAgentConflictTotal,
                blockedBySourceMismatchTotal: summary.blockedBySourceMismatchTotal,
                blockedByDivergenceTotal: summary.blockedByDivergenceTotal,
                blockedByStaleIntentTotal: summary.blockedByStaleIntentTotal,
                blockedByInvalidEdgeTotal: summary.blockedByInvalidEdgeTotal,
                blockedByMaxAgentsTotal: summary.blockedByMaxAgentsTotal,
                intentProduced: summary.intentProduced,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackToAgentIntentContextFixtureReport {
            let summary = feedbackToAgentIntentContextFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_to_agent_intent_context_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackToAgentIntentContextFixtureSuccess,
                feedbackObserved: summary.feedbackObserved,
                feedbackAccepted: summary.feedbackAccepted,
                feedbackIgnored: summary.feedbackIgnored,
                invalidFeedback: summary.invalidFeedback,
                contextsProduced: summary.contextsProduced,
                proposals: summary.proposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                noIntent: summary.noIntent,
                invalidOneEdgeProposals: summary.invalidOneEdgeProposals,
                duplicateFeedback: summary.duplicateFeedback,
                intentContexts: summary.intentContexts,
                contextsWithFeedback: summary.contextsWithFeedback,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                feedbackUsedForDecision: summary.feedbackUsedForDecision,
                intentProduced: summary.intentProduced,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackToAgentIntentContextHardeningReport {
            let summary = feedbackToAgentIntentContextHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_to_agent_intent_context_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackToAgentIntentContextHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                cases: summary.cases,
                feedbackObservedTotal: summary.feedbackObservedTotal,
                feedbackAcceptedTotal: summary.feedbackAcceptedTotal,
                feedbackIgnoredTotal: summary.feedbackIgnoredTotal,
                invalidFeedbackTotal: summary.invalidFeedbackTotal,
                contextsProducedTotal: summary.contextsProducedTotal,
                duplicateFeedbackTotal: summary.duplicateFeedbackTotal,
                maxFeedbackExceededTotal: summary.maxFeedbackExceededTotal,
                tickMismatchFeedbackTotal: summary.tickMismatchFeedbackTotal,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                feedbackUsedForDecision: summary.feedbackUsedForDecision,
                intentContextsTotal: summary.intentContextsTotal,
                contextsWithFeedbackTotal: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedbackTotal: summary.contextsWithoutFeedbackTotal,
                proposalsTotal: summary.proposalsTotal,
                acceptedIntentsTotal: summary.acceptedIntentsTotal,
                rejectedProposalsTotal: summary.rejectedProposalsTotal,
                noIntentTotal: summary.noIntentTotal,
                invalidOneEdgeProposalsTotal: summary.invalidOneEdgeProposalsTotal,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackAwareIntentPolicyFixtureReport {
            let summary = feedbackAwareIntentPolicyFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_aware_intent_policy_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackAwareIntentPolicyFixtureSuccess,
                policyMode: feedbackAwareIntentPolicyFixtureReport.feedbackAwarePolicyMode.rawValue,
                contexts: summary.contexts,
                proposals: summary.feedbackAwareProposals,
                baselineProposals: summary.baselineProposals,
                feedbackAwareProposals: summary.feedbackAwareProposals,
                acceptedIntents: summary.acceptedIntents,
                rejectedProposals: summary.rejectedProposals,
                noIntent: summary.noIntent,
                invalidOneEdgeProposals: summary.invalidOneEdgeProposals,
                intentContexts: summary.contexts,
                contextsWithFeedback: summary.contextsWithFeedback,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                behaviorChangedCount: summary.behaviorChangedCount,
                feedbackReactions: summary.feedbackReactions,
                noFeedbackBaselineKept: summary.noFeedbackBaselineKept,
                movedBaselineKept: summary.movedBaselineKept,
                approvedForMovementBaselineKept: summary.approvedForMovementBaselineKept,
                blockedByCollisionNoIntent: summary.blockedByCollisionNoIntent,
                blockedByAgentConflictNoIntent: summary.blockedByAgentConflictNoIntent,
                blockedBySourceMismatchNoIntent: summary.blockedBySourceMismatchNoIntent,
                blockedByDivergenceNoIntent: summary.blockedByDivergenceNoIntent,
                blockedByStaleIntentNoIntent: summary.blockedByStaleIntentNoIntent,
                blockedByInvalidEdgeNoIntent: summary.blockedByInvalidEdgeNoIntent,
                blockedByMaxAgentsNoIntent: summary.blockedByMaxAgentsNoIntent,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackAwareIntentPolicyHardeningReport {
            let summary = feedbackAwareIntentPolicyHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_aware_intent_policy_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackAwareIntentPolicyHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                cases: summary.cases,
                contexts: summary.contextsTotal,
                baselineProposals: summary.baselineProposalsTotal,
                feedbackAwareProposals: summary.feedbackAwareProposalsTotal,
                acceptedIntents: summary.acceptedIntentsTotal,
                rejectedProposals: summary.rejectedProposalsTotal,
                noIntent: summary.noIntentTotal,
                invalidOneEdgeProposals: summary.invalidOneEdgeProposalsTotal,
                intentContexts: summary.contextsTotal,
                contextsWithFeedback: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedback: summary.contextsWithoutFeedbackTotal,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                behaviorChangedCount: summary.behaviorChangedCountTotal,
                feedbackUsedForDecision: summary.feedbackUsedForDecision,
                feedbackReactions: summary.feedbackReactionsTotal,
                noFeedbackBaselineKept: summary.noFeedbackBaselineKeptTotal,
                movedBaselineKept: summary.movedBaselineKeptTotal,
                approvedForMovementBaselineKept: summary.approvedForMovementBaselineKeptTotal,
                blockedByCollisionNoIntent: summary.blockedByCollisionNoIntentTotal,
                blockedByAgentConflictNoIntent: summary.blockedByAgentConflictNoIntentTotal,
                blockedBySourceMismatchNoIntent: summary.blockedBySourceMismatchNoIntentTotal,
                blockedByDivergenceNoIntent: summary.blockedByDivergenceNoIntentTotal,
                blockedByStaleIntentNoIntent: summary.blockedByStaleIntentNoIntentTotal,
                blockedByInvalidEdgeNoIntent: summary.blockedByInvalidEdgeNoIntentTotal,
                blockedByMaxAgentsNoIntent: summary.blockedByMaxAgentsNoIntentTotal,
                intentContextsTotal: summary.contextsTotal,
                contextsWithFeedbackTotal: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedbackTotal: summary.contextsWithoutFeedbackTotal,
                baselineProposalsTotal: summary.baselineProposalsTotal,
                feedbackAwareProposalsTotal: summary.feedbackAwareProposalsTotal,
                acceptedIntentsTotal: summary.acceptedIntentsTotal,
                rejectedProposalsTotal: summary.rejectedProposalsTotal,
                noIntentTotal: summary.noIntentTotal,
                invalidOneEdgeProposalsTotal: summary.invalidOneEdgeProposalsTotal,
                feedbackReactionsTotal: summary.feedbackReactionsTotal,
                behaviorChangedCountTotal: summary.behaviorChangedCountTotal,
                noFeedbackBaselineKeptTotal: summary.noFeedbackBaselineKeptTotal,
                movedBaselineKeptTotal: summary.movedBaselineKeptTotal,
                approvedForMovementBaselineKeptTotal: summary.approvedForMovementBaselineKeptTotal,
                blockedByCollisionNoIntentTotal: summary.blockedByCollisionNoIntentTotal,
                blockedByAgentConflictNoIntentTotal: summary.blockedByAgentConflictNoIntentTotal,
                blockedBySourceMismatchNoIntentTotal: summary.blockedBySourceMismatchNoIntentTotal,
                blockedByDivergenceNoIntentTotal: summary.blockedByDivergenceNoIntentTotal,
                blockedByStaleIntentNoIntentTotal: summary.blockedByStaleIntentNoIntentTotal,
                blockedByInvalidEdgeNoIntentTotal: summary.blockedByInvalidEdgeNoIntentTotal,
                blockedByMaxAgentsNoIntentTotal: summary.blockedByMaxAgentsNoIntentTotal,
                worldUsed: summary.worldUsed,
                collisionRead: summary.collisionRead,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackAwareIntentToTickFixtureReport {
            let summary = feedbackAwareIntentToTickFixtureReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_aware_intent_to_tick_fixture_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackAwareIntentToTickFixtureSuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.feedbackAwareProposals,
                baselineProposals: summary.baselineProposals,
                feedbackAwareProposals: summary.feedbackAwareProposals,
                acceptedIntents: summary.feedbackAwareAcceptedIntents,
                rejectedProposals: summary.feedbackAwareRejectedProposals,
                noIntent: summary.feedbackAwareNoIntent,
                invalidOneEdgeProposals: summary.feedbackAwareInvalidOneEdgeProposals,
                tickIntents: summary.tickIntents,
                tickFeedback: summary.tickFeedbackEmitted,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                sameDestinationConflicts: summary.tickDeniedSameDestinationConflict,
                intentContexts: summary.contexts,
                contextsWithFeedback: summary.contextsWithFeedback,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                behaviorChangedCount: summary.behaviorChangedCount,
                baselineMovementIntentInputs: summary.baselineMovementIntentInputs,
                feedbackAwareMovementIntentInputs: summary.feedbackAwareMovementIntentInputs,
                movementIntentReduction: summary.movementIntentReduction,
                noIntentFilteredOut: summary.noIntentFilteredOut,
                feedbackAwareAcceptedIntents: summary.feedbackAwareAcceptedIntents,
                feedbackAwareRejectedProposals: summary.feedbackAwareRejectedProposals,
                feedbackAwareNoIntent: summary.feedbackAwareNoIntent,
                tickDeniedSameDestinationConflict: summary.tickDeniedSameDestinationConflict,
                tickFeedbackEmitted: summary.tickFeedbackEmitted,
                policyReadCollision: summary.policyReadCollision,
                productionReadCollision: summary.policyReadCollision,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.worldUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackAwareIntentToTickLiveReadonlyReport {
            let summary = feedbackAwareIntentToTickLiveReadonlyReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_aware_intent_to_tick_live_readonly_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackAwareIntentToTickLiveReadonlySuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.feedbackAwareProposals,
                baselineProposals: summary.baselineProposals,
                feedbackAwareProposals: summary.feedbackAwareProposals,
                acceptedIntents: summary.feedbackAwareAcceptedIntents,
                rejectedProposals: summary.feedbackAwareRejectedProposals,
                noIntent: summary.feedbackAwareNoIntent,
                invalidOneEdgeProposals: summary.feedbackAwareInvalidOneEdgeProposals,
                tickIntents: summary.tickIntents,
                tickFeedback: summary.tickFeedbackEmitted,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                sameDestinationConflicts: summary.tickDeniedSameDestinationConflict,
                intentContexts: summary.contexts,
                contextsWithFeedback: summary.contextsWithFeedback,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                behaviorChangedCount: summary.behaviorChangedCount,
                baselineMovementIntentInputs: summary.baselineMovementIntentInputs,
                feedbackAwareMovementIntentInputs: summary.feedbackAwareMovementIntentInputs,
                movementIntentReduction: summary.movementIntentReduction,
                noIntentFilteredOut: summary.noIntentFilteredOut,
                feedbackAwareAcceptedIntents: summary.feedbackAwareAcceptedIntents,
                feedbackAwareRejectedProposals: summary.feedbackAwareRejectedProposals,
                feedbackAwareNoIntent: summary.feedbackAwareNoIntent,
                tickDeniedSameDestinationConflict: summary.tickDeniedSameDestinationConflict,
                tickFeedbackEmitted: summary.tickFeedbackEmitted,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.tickDeniedCollision,
                productionReadCollision: summary.policyReadCollision,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let feedbackAwareIntentToTickApprovedApplicationReport {
            let summary = feedbackAwareIntentToTickApprovedApplicationReport.summary
            try appendEvent(RunEvent(
                type: "lab_feedback_aware_intent_to_tick_approved_application_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: feedbackAwareIntentToTickApprovedApplicationSuccess,
                displacementsApplied: summary.displacementsApplied,
                contexts: summary.contexts,
                proposals: summary.feedbackAwareProposals,
                baselineProposals: summary.baselineProposals,
                feedbackAwareProposals: summary.feedbackAwareProposals,
                acceptedIntents: summary.feedbackAwareAcceptedIntents,
                rejectedProposals: summary.feedbackAwareRejectedProposals,
                noIntent: summary.feedbackAwareNoIntent,
                invalidOneEdgeProposals: summary.feedbackAwareInvalidOneEdgeProposals,
                tickIntents: summary.tickIntents,
                tickFeedback: summary.tickFeedbackEmitted,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                sameDestinationConflicts: summary.tickDeniedSameDestinationConflict,
                intentContexts: summary.contexts,
                contextsWithFeedback: summary.contextsWithFeedback,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                behaviorChangedByFeedback: summary.behaviorChangedByFeedback,
                behaviorChangedCount: summary.behaviorChangedCount,
                baselineMovementIntentInputs: summary.baselineMovementIntentInputs,
                feedbackAwareMovementIntentInputs: summary.feedbackAwareMovementIntentInputs,
                movementIntentReduction: summary.movementIntentReduction,
                noIntentFilteredOut: summary.noIntentFilteredOut,
                feedbackAwareAcceptedIntents: summary.feedbackAwareAcceptedIntents,
                feedbackAwareRejectedProposals: summary.feedbackAwareRejectedProposals,
                feedbackAwareNoIntent: summary.feedbackAwareNoIntent,
                tickDeniedSameDestinationConflict: summary.tickDeniedSameDestinationConflict,
                tickFeedbackEmitted: summary.tickFeedbackEmitted,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                approvedAgentsMoved: summary.approvedAgentsMoved,
                deniedAgentsPreserved: summary.deniedAgentsPreserved,
                noIntentAgentsPreserved: summary.noIntentAgentsPreserved,
                abstractPositionsChanged: summary.abstractPositionsChanged,
                physicalPositionsChanged: summary.physicalPositionsChanged,
                abstractPhysicalDivergenceBefore: summary.abstractPhysicalDivergenceBefore,
                abstractPhysicalDivergenceAfter: summary.abstractPhysicalDivergenceAfter,
                routeFollowingUsed: summary.routeFollowingUsed,
                occupableDestinations: summary.occupableDestinations,
                nonOccupableDestinations: summary.nonOccupableDestinations,
                collisionDenied: summary.tickDeniedCollision,
                productionReadCollision: summary.policyReadCollision,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let alternateLocalHintReport {
            let summary = alternateLocalHintReport.summary
            try appendEvent(RunEvent(
                type: "lab_alternate_local_hint_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: alternateLocalHintSuccess,
                candidates: summary.candidatesProduced,
                decisions: summary.decisions,
                contextsWithBlockedFeedback: summary.contextsWithBlockedFeedback,
                contextsWithApprovedOrMovedFeedback: summary.contextsWithApprovedOrMovedFeedback,
                candidatesProduced: summary.candidatesProduced,
                candidatesSelected: summary.candidatesSelected,
                candidatesFiltered: summary.candidatesFiltered,
                maxAlternates: summary.maxAlternates,
                bounded: summary.bounded,
                noFeedbackBaseline: summary.noFeedbackBaseline,
                approvedFeedbackBaseline: summary.approvedFeedbackBaseline,
                movedFeedbackBaseline: summary.movedFeedbackBaseline,
                blockedFeedbackUsed: summary.blockedFeedbackUsed,
                unknownHintNoAlternate: summary.unknownHintNoAlternate,
                emptyHintNoAlternate: summary.emptyHintNoAlternate,
                failedDirectionExcluded: summary.failedDirectionExcluded,
                oneEdgeAlternates: summary.oneEdgeAlternates,
                movementIntentInputs: summary.movementIntentInputs,
                tickDeniedConflict: summary.tickDeniedConflict,
                tickDeniedCollision: summary.tickDeniedCollision,
                v0Unchanged: summary.v0Unchanged,
                v1Unchanged: summary.v1Unchanged,
                v2OptIn: summary.v2OptIn,
                tickWorldUsed: summary.tickWorldUsed,
                contexts: summary.contexts,
                tickFeedback: summary.tickFeedbackEmitted,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                movementIntentInputsTotal: summary.movementIntentInputs,
                tickFeedbackEmitted: summary.tickFeedbackEmitted,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                worldMutated: summary.worldMutated,
                routeFollowingUsed: summary.routeFollowingUsed,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let alternateLocalHintHardeningReport {
            let summary = alternateLocalHintHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_alternate_local_hint_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: alternateLocalHintHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                candidates: summary.candidatesProduced,
                decisions: summary.decisions,
                contextsWithBlockedFeedback: summary.contextsWithBlockedFeedback,
                contextsWithApprovedOrMovedFeedback: summary.contextsWithApprovedOrMovedFeedback,
                candidatesProduced: summary.candidatesProduced,
                candidatesSelected: summary.candidatesSelected,
                candidatesFiltered: summary.candidatesFiltered,
                maxAlternates: summary.maxAlternatesMax,
                blockedFeedbackKindsCovered: summary.blockedFeedbackKindsCovered,
                maxAlternatesMin: summary.maxAlternatesMin,
                maxAlternatesMax: summary.maxAlternatesMax,
                maxAlternatesZeroCases: summary.maxAlternatesZeroCases,
                maxAlternatesOneCases: summary.maxAlternatesOneCases,
                maxAlternatesTwoCases: summary.maxAlternatesTwoCases,
                maxAlternatesThreeCases: summary.maxAlternatesThreeCases,
                boundedCases: summary.boundedCases,
                deterministicOrderingCases: summary.deterministicOrderingCases,
                duplicateHintCases: summary.duplicateHintCases,
                duplicateHintsFiltered: summary.duplicateHintsFiltered,
                noFeedbackBaseline: summary.noFeedbackBaseline,
                approvedFeedbackBaseline: summary.approvedFeedbackBaseline,
                movedFeedbackBaseline: summary.movedFeedbackBaseline,
                unknownHintNoAlternate: summary.unknownHintNoAlternate,
                emptyHintNoAlternate: summary.emptyHintNoAlternate,
                failedDirectionExcluded: summary.failedDirectionExcluded,
                oneEdgeAlternates: summary.oneEdgeAlternates,
                movementIntentInputs: summary.movementIntentInputs,
                tickDeniedConflict: summary.tickDeniedConflict,
                tickDeniedCollision: summary.tickDeniedCollision,
                v0Unchanged: summary.v0Unchanged,
                v1Unchanged: summary.v1Unchanged,
                v2OptIn: summary.v2OptIn,
                tickWorldUsed: summary.tickWorldUsed,
                cases: summary.cases,
                contexts: summary.contexts,
                tickFeedback: summary.tickFeedbackEmitted,
                tickApproved: summary.tickApproved,
                tickDenied: summary.tickDenied,
                contextsWithoutFeedback: summary.contextsWithoutFeedback,
                tickFeedbackEmitted: summary.tickFeedbackEmitted,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                worldMutated: summary.worldMutated,
                repeatabilityChecks: summary.repeatabilityChecks,
                repeatabilityFailures: summary.repeatabilityFailures,
                routeFollowingUsed: summary.routeFollowingUsed,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let multiTickClosedLoopReport {
            let summary = multiTickClosedLoopReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_tick_closed_loop_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                ticksRequested: summary.requestedTicks,
                requestedTicks: summary.requestedTicks,
                executedTicks: summary.executedTicks,
                success: multiTickClosedLoopSuccess,
                agents: summary.agents,
                contextsTotal: summary.contextsTotal,
                contextsWithFeedbackTotal: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedbackTotal: summary.contextsWithoutFeedbackTotal,
                feedbackConsumedTotal: summary.feedbackConsumedTotal,
                feedbackCarriedToNextTickTotal: summary.feedbackCarriedToNextTickTotal,
                proposalsTotal: summary.proposalsTotal,
                acceptedIntentsTotal: summary.acceptedIntentsTotal,
                noIntentTotal: summary.noIntentTotal,
                noIntentFromBlockedFeedbackTotal: summary.noIntentFromBlockedFeedbackTotal,
                blockedByAgentConflictNoIntentTotal: summary.noIntentFromBlockedFeedbackTotal,
                movementIntentInputsTotal: summary.movementIntentInputsTotal,
                tickDeniedConflictTotal: summary.tickDeniedConflictTotal,
                tickDeniedCollisionTotal: summary.tickDeniedCollisionTotal,
                tickApprovedTotal: summary.tickApprovedTotal,
                tickDeniedTotal: summary.tickDeniedTotal,
                feedbackEmittedTotal: summary.feedbackEmittedTotal,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                approvedApplicationsTotal: summary.approvedApplicationsTotal,
                deniedPreservedTotal: summary.deniedPreservedTotal,
                noIntentPreservedTotal: summary.noIntentPreservedTotal,
                sameTickFeedbackConsumedTotal: summary.sameTickFeedbackConsumedTotal,
                crossAgentFeedbackLeaksTotal: summary.crossAgentFeedbackLeaksTotal,
                futureFeedbackConsumedTotal: summary.futureFeedbackConsumedTotal,
                routeFollowingUsed: summary.routeFollowingUsed,
                productionReadCollision: summary.policyReadCollision,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let multiTickClosedLoopHardeningReport {
            let summary = multiTickClosedLoopHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_tick_closed_loop_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                requestedTicks: summary.requestedTicksTotal,
                executedTicks: summary.executedTicksTotal,
                requestedTicksTotal: summary.requestedTicksTotal,
                executedTicksTotal: summary.executedTicksTotal,
                success: multiTickClosedLoopHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                cases: summary.cases,
                feedbackIgnoredTotal: summary.feedbackIgnoredTotal,
                contextsTotal: summary.contextsTotal,
                feedbackConsumedTotal: summary.feedbackConsumedTotal,
                noIntentFromBlockedFeedbackTotal: summary.noIntentFromBlockedFeedbackTotal,
                agentsTotal: summary.agentsTotal,
                movementIntentInputsTotal: summary.movementIntentInputsTotal,
                tickDeniedConflictTotal: summary.tickDeniedConflictTotal,
                tickDeniedCollisionTotal: summary.tickDeniedCollisionTotal,
                tickApprovedTotal: summary.tickApprovedTotal,
                tickDeniedTotal: summary.tickDeniedTotal,
                feedbackEmittedTotal: summary.feedbackEmittedTotal,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                feedbackCandidatesTotal: summary.feedbackCandidatesTotal,
                feedbackDedupedTotal: summary.feedbackDedupedTotal,
                missingFeedbackAllowedTotal: summary.missingFeedbackAllowedTotal,
                staleFeedbackIgnoredTotal: summary.staleFeedbackIgnoredTotal,
                futureFeedbackIgnoredTotal: summary.futureFeedbackIgnoredTotal,
                sameTickFeedbackIgnoredTotal: summary.sameTickFeedbackIgnoredTotal,
                crossAgentLeakAttemptsTotal: summary.crossAgentLeakAttemptsTotal,
                unknownAgentFeedbackIgnoredTotal: summary.unknownAgentFeedbackIgnoredTotal,
                malformedFeedbackIgnoredTotal: summary.malformedFeedbackIgnoredTotal,
                sameTickFeedbackConsumedTotal: summary.sameTickFeedbackConsumedTotal,
                crossAgentFeedbackLeaksTotal: summary.crossAgentFeedbackLeaksTotal,
                futureFeedbackConsumedTotal: summary.futureFeedbackConsumedTotal,
                repeatabilityChecks: summary.repeatabilityChecks,
                repeatabilityFailures: summary.repeatabilityFailures,
                routeFollowingUsed: summary.routeFollowingUsed,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let multiTickClosedLoopLiveReadonlyReport {
            let summary = multiTickClosedLoopLiveReadonlyReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_tick_closed_loop_live_readonly_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                requestedTicks: summary.requestedTicks,
                executedTicks: summary.executedTicks,
                success: multiTickClosedLoopLiveReadonlySuccess,
                agents: summary.agents,
                contextsTotal: summary.contextsTotal,
                contextsWithFeedbackTotal: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedbackTotal: summary.contextsWithoutFeedbackTotal,
                feedbackConsumedTotal: summary.feedbackConsumedTotal,
                feedbackCarriedToNextTickTotal: summary.feedbackCarriedToNextTickTotal,
                proposalsTotal: summary.proposalsTotal,
                acceptedIntentsTotal: summary.acceptedIntentsTotal,
                noIntentTotal: summary.noIntentTotal,
                noIntentFromBlockedFeedbackTotal: summary.noIntentFromBlockedFeedbackTotal,
                movementIntentInputsTotal: summary.movementIntentInputsTotal,
                tickDeniedConflictTotal: summary.tickDeniedConflictTotal,
                tickDeniedCollisionTotal: summary.tickDeniedCollisionTotal,
                tickFeedbackEmittedTotal: summary.tickFeedbackEmittedTotal,
                occupableDestinationsTotal: summary.occupableDestinationsTotal,
                nonOccupableDestinationsTotal: summary.nonOccupableDestinationsTotal,
                tickApprovedTotal: summary.tickApprovedTotal,
                tickDeniedTotal: summary.tickDeniedTotal,
                feedbackEmittedTotal: summary.tickFeedbackEmittedTotal,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                approvedApplicationsTotal: summary.approvedApplicationsTotal,
                sameTickFeedbackConsumedTotal: summary.sameTickFeedbackConsumedTotal,
                crossAgentFeedbackLeaksTotal: summary.crossAgentFeedbackLeaksTotal,
                futureFeedbackConsumedTotal: summary.futureFeedbackConsumedTotal,
                routeFollowingUsed: summary.routeFollowingUsed,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let multiTickClosedLoopApprovedApplicationReport {
            let summary = multiTickClosedLoopApprovedApplicationReport.summary
            try appendEvent(RunEvent(
                type: "lab_multi_tick_closed_loop_approved_application_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                requestedTicks: summary.requestedTicks,
                executedTicks: summary.executedTicks,
                success: multiTickClosedLoopApprovedApplicationSuccess,
                agents: summary.agents,
                displacementsApplied: summary.displacementsAppliedTotal,
                contextsTotal: summary.contextsTotal,
                contextsWithFeedbackTotal: summary.contextsWithFeedbackTotal,
                contextsWithoutFeedbackTotal: summary.contextsWithoutFeedbackTotal,
                feedbackConsumedTotal: summary.feedbackConsumedTotal,
                feedbackCarriedToNextTickTotal: summary.feedbackCarriedToNextTickTotal,
                proposalsTotal: summary.proposalsTotal,
                acceptedIntentsTotal: summary.acceptedIntentsTotal,
                noIntentTotal: summary.noIntentTotal,
                noIntentFromBlockedFeedbackTotal: summary.noIntentFromBlockedFeedbackTotal,
                movementIntentInputsTotal: summary.movementIntentInputsTotal,
                tickDeniedConflictTotal: summary.tickDeniedConflictTotal,
                tickDeniedCollisionTotal: summary.tickDeniedCollisionTotal,
                tickFeedbackEmittedTotal: summary.tickFeedbackEmittedTotal,
                occupableDestinationsTotal: summary.occupableDestinationsTotal,
                nonOccupableDestinationsTotal: summary.nonOccupableDestinationsTotal,
                tickApprovedTotal: summary.tickApprovedTotal,
                tickDeniedTotal: summary.tickDeniedTotal,
                feedbackEmittedTotal: summary.tickFeedbackEmittedTotal,
                policyReadCollision: summary.policyReadCollision,
                policyWorldUsed: summary.policyWorldUsed,
                tickWorldReadOnlyUsed: summary.tickWorldReadOnlyUsed,
                worldMutated: summary.worldMutated,
                approvedAgentsMoved: summary.approvedAgentsMovedTotal,
                approvedApplicationsTotal: summary.approvedApplicationsTotal,
                deniedAgentsPreserved: summary.deniedAgentsPreservedTotal,
                deniedPreservedTotal: summary.deniedAgentsPreservedTotal,
                noIntentAgentsPreserved: summary.noIntentAgentsPreservedTotal,
                noIntentPreservedTotal: summary.noIntentAgentsPreservedTotal,
                sameTickFeedbackConsumedTotal: summary.sameTickFeedbackConsumedTotal,
                crossAgentFeedbackLeaksTotal: summary.crossAgentFeedbackLeaksTotal,
                futureFeedbackConsumedTotal: summary.futureFeedbackConsumedTotal,
                abstractPositionsChanged: summary.abstractPositionsChangedTotal,
                physicalPositionsChanged: summary.physicalPositionsChangedTotal,
                abstractPhysicalDivergenceBefore: summary.abstractPhysicalDivergenceBeforeMax,
                abstractPhysicalDivergenceAfter: summary.abstractPhysicalDivergenceAfterMax,
                routeFollowingUsed: summary.routeFollowingUsed,
                tickReadCollision: summary.tickReadCollision,
                worldUsed: summary.policyWorldUsed || summary.tickWorldReadOnlyUsed,
                collisionRead: summary.policyReadCollision || summary.tickReadCollision,
                movementApplied: summary.movementApplied,
                memoryUpdated: summary.memoryUpdated,
                goalChanged: summary.goalChanged,
                avoidancePerformed: summary.avoidancePerformed,
                reservationRuntimeUsed: summary.reservationRuntimeUsed,
                mutationPerformed: summary.mutationPerformed,
                pathfindingPerformed: summary.pathfindingPerformed,
                replanningPerformed: summary.replanningPerformed
            ))
        }
        if let routeFollowingLiveSnapshot {
            try appendEvent(RunEvent(
                type: "lab_route_following_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: routeFollowingLiveSuccess,
                agentId: routeFollowingLiveSnapshot.agentId,
                reason: routeFollowingLiveSnapshot.reason,
                physicalId: routeFollowingLiveSnapshot.physicalId,
                attemptedEdges: routeFollowingLiveSnapshot.attemptedEdges,
                completedEdges: routeFollowingLiveSnapshot.completedEdges,
                displacementsApplied: routeFollowingLiveDisplacementsApplied,
                deniedEdges: routeFollowingLiveDeniedEdges,
                routeLength: routeFollowingLiveSnapshot.route.count,
                stoppedAtIndex: routeFollowingLiveSnapshot.stoppedAtIndex,
                mutationPerformed: routeFollowingLiveSnapshot.mutationPerformed,
                status: routeFollowingLiveSnapshot.status.rawValue,
                routeFollowingPerformed: routeFollowingLiveSnapshot.routeFollowingPerformed,
                pathfindingInsideFollower: routeFollowingLiveSnapshot.pathfindingPerformedInsideFollower,
                replanningPerformed: routeFollowingLiveSnapshot.replanningPerformed,
                physicsPerformed: routeFollowingLiveSnapshot.physicsPerformed
            ))
        }
        if let routeFollowingLiveHardeningReport {
            let summary = routeFollowingLiveHardeningReport.summary
            try appendEvent(RunEvent(
                type: "lab_route_following_live_hardening_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: routeFollowingLiveHardeningSuccess,
                passed: summary.passed,
                failed: summary.failed,
                completed: summary.completed,
                stopped: summary.stopped,
                attemptedEdges: summary.attemptedEdges,
                completedEdges: summary.completedEdges,
                displacementsApplied: summary.displacementsApplied,
                deniedEdges: summary.deniedEdges,
                cases: summary.cases
            ))
        }
        if let terrainColumnScanSnapshot {
            try appendEvent(RunEvent(
                type: "lab_terrain_column_scan_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainColumnScanSuccess,
                agentId: terrainColumnScanSnapshot.agentId,
                uniqueChunks: terrainColumnScanSnapshot.summary.uniqueChunks,
                radius: terrainColumnScanSnapshot.radius,
                cellsPlanned: terrainColumnScanSnapshot.summary.cellsPlanned,
                cellsObserved: terrainColumnScanSnapshot.summary.cellsObserved,
                loadedCells: terrainColumnScanSnapshot.summary.loadedCells,
                readyCells: terrainColumnScanSnapshot.summary.readyCells,
                columns: terrainColumnScanSnapshot.summary.columnsObserved
            ))
        }
        if let pathfindingColumnSnapshot = terrainPathfindingColumnSnapshot {
            let summary = pathfindingColumnSnapshot.summary
            try appendEvent(RunEvent(
                type: "lab_terrain_pathfinding_column_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainPathfindingColumnSuccess,
                agentId: pathfindingColumnSnapshot.agentId,
                nodes: summary.nodes,
                traversableNodes: summary.traversableNodes,
                unsafeNodes: summary.unsafeNodes,
                unknownNodes: summary.unknownNodes,
                startStatus: summary.startStatus,
                goalStatus: summary.goalStatus,
                pathStatus: summary.pathStatus.rawValue,
                pathLength: summary.pathLength,
                visited: summary.visited
            ))
        }
        if let positiveSnapshot = terrainPathfindingPositiveSnapshot,
           let selected = positiveSnapshot.selectedPathfindingSnapshot {
            try appendEvent(RunEvent(
                type: "lab_terrain_pathfinding_column_positive_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainPathfindingPositiveSuccess,
                nodes: selected.nodeCount,
                traversableNodes: selected.summary.traversableNodes,
                pathStatus: selected.result.status.rawValue,
                pathLength: selected.result.path.count,
                visited: selected.result.visited,
                candidates: positiveSnapshot.summary.candidates,
                selectedCandidateIndex: positiveSnapshot.summary.selectedCandidateIndex,
                selectedSeed: positiveSnapshot.summary.selectedSeed,
                agentX: positiveSnapshot.summary.selectedAgentX,
                agentZ: positiveSnapshot.summary.selectedAgentZ
            ))
        }
        if let liveMovementSnapshot = terrainLiveMovementSnapshot {
            let summary = liveMovementSnapshot.summary
            try appendEvent(RunEvent(
                type: "lab_terrain_live_movement_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainLiveMovementSuccess,
                pathLength: summary.pathLength,
                selectedCandidateIndex: liveMovementSnapshot.selectedCandidateIndex,
                stepsExecuted: summary.stepsExecuted,
                reachedGoal: summary.reachedGoal,
                finalStatus: summary.finalStatus.rawValue,
                liveAgentDisplaced: summary.liveAgentDisplaced,
                collisionPerformed: summary.collisionPerformed,
                mutationPerformed: summary.mutationPerformed
            ))
        }
        if let terrainScanSnapshot {
            try appendEvent(RunEvent(
                type: "lab_terrain_scan_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainScanSuccess,
                agentId: terrainScanSnapshot.agentId,
                physicalId: terrainScanSnapshot.physicalId,
                coreEntityId: terrainScanSnapshot.coreEntityId,
                uniqueChunks: terrainScanSnapshot.summary.uniqueChunks,
                distinctBlockIds: terrainScanSnapshot.summary.distinctBlockIds,
                radius: terrainScanSnapshot.radius,
                cellsPlanned: terrainScanSnapshot.summary.cellsPlanned,
                cellsObserved: terrainScanSnapshot.summary.cellsObserved,
                loadedCells: terrainScanSnapshot.summary.loadedCells,
                readyCells: terrainScanSnapshot.summary.readyCells
            ))
            try appendEvent(RunEvent(
                type: "lab_terrain_semantics_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: terrainSemanticSuccess,
                agentId: terrainScanSnapshot.agentId,
                radius: terrainScanSnapshot.radius,
                cellsClassified: terrainScanSnapshot.semanticSummary.cellsClassified,
                unknownCells: terrainScanSnapshot.semanticSummary.unknownCells,
                airCells: terrainScanSnapshot.semanticSummary.airCells,
                solidCells: terrainScanSnapshot.semanticSummary.solidCells,
                liquidCells: terrainScanSnapshot.semanticSummary.liquidCells,
                plantLikeCells: terrainScanSnapshot.semanticSummary.plantLikeCells,
                otherCells: terrainScanSnapshot.semanticSummary.otherCells
            ))
        } else if let worldInteractionMultiSnapshot {
            try appendEvent(RunEvent(
                type: "lab_world_observation_multi_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: worldInteractionMultiSnapshot.summary.success,
                agents: worldInteractionMultiSnapshot.summary.agents,
                observations: worldInteractionMultiSnapshot.summary.observations,
                loadedObservations: worldInteractionMultiSnapshot.summary.loadedObservations,
                readyObservations: worldInteractionMultiSnapshot.summary.readyObservations,
                uniqueChunks: worldInteractionMultiSnapshot.summary.uniqueChunks,
                distinctBlockIds: worldInteractionMultiSnapshot.summary.distinctBlockIds
            ))
        } else if let worldInteractionSnapshot {
            try appendEvent(RunEvent(
                type: "lab_world_observation_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: worldInteractionSnapshot.success,
                chunkX: worldInteractionSnapshot.chunk.cx,
                chunkZ: worldInteractionSnapshot.chunk.cz,
                agentId: worldInteractionSnapshot.agentId,
                x: worldInteractionSnapshot.target.x,
                y: worldInteractionSnapshot.target.y,
                z: worldInteractionSnapshot.target.z,
                physicalId: worldInteractionSnapshot.physicalId,
                coreEntityId: worldInteractionSnapshot.coreEntityId,
                relation: worldInteractionSnapshot.relation,
                loaded: worldInteractionSnapshot.chunk.loaded,
                ready: worldInteractionSnapshot.chunk.ready,
                blockId: worldInteractionSnapshot.blockId,
                meta: worldInteractionSnapshot.meta,
                blockName: worldInteractionSnapshot.blockName
            ))
        } else if isTerrainScanRun {
            try appendEvent(RunEvent(
                type: "lab_terrain_scan_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: false,
                radius: terrainScanContract?.radius,
                cellsPlanned: terrainScanContract?.expectedCellsPlanned,
                cellsObserved: 0,
                loadedCells: 0,
                readyCells: 0
            ))
        } else if isWorldObservationScenario {
            try appendEvent(RunEvent(
                type: isWorldObservationMultiScenario
                    ? "lab_world_observation_multi_recorded"
                    : "lab_world_observation_recorded",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: false,
                relation: "below",
                loaded: false,
                ready: false
            ))
        }
        try appendEvent(RunEvent(
            type: "run_finished",
            tick: ticksCompleted,
            scenario: nil,
            seed: nil,
            ticksRequested: nil,
            worldTime: world?.time ?? 0,
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
        if let world,
           let snapshot = makeWorldSnapshot(
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
        if !labAgents.isEmpty, options.scenario == "agent_smoke" || options.scenario == "agents_basic" || options.scenario == "seek_safety_smoke" || options.scenario == "long_run_smoke" || options.scenario == "regression_smoke" || options.scenario == "physical_placeholder_smoke" || options.scenario == "physical_sync_smoke" || options.scenario == "core_entity_smoke" || isPhysicalBehaviorScenario || isWorldInteractionScenario {
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
        if options.scenario == "physical_placeholder_smoke" || options.scenario == "physical_sync_smoke" || options.scenario == "core_entity_smoke" || isPhysicalBehaviorScenario || isWorldInteractionScenario {
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
        if options.scenario == "core_entity_smoke" || isPhysicalBehaviorScenario || isWorldInteractionScenario {
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
        if options.scenario == "physical_behavior_smoke",
           let agent = labAgents.first,
           let coreLink = coreEntityBridge.snapshotLinks(for: labAgents).first,
           let behaviorSuccess = physicalBehaviorSuccess {
            try writeJSON(
                PhysicalBehaviorSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    agentId: agent.id,
                    physicalId: coreLink.physicalId,
                    coreEntityId: coreLink.coreEntityId,
                    startPosition: agent.homePosition,
                    finalAbstractPosition: agent.position,
                    finalCoreEntityPosition: coreLink.coreEntityPosition,
                    moves: physicalBehaviorMoves ?? 0,
                    totalDistance: physicalBehaviorTotalDistance ?? 0,
                    finalDivergence: physicalBehaviorFinalDivergence ?? 0,
                    success: behaviorSuccess
                ),
                to: outURL.appendingPathComponent("physical_behavior_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "physical_behavior_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: behaviorSuccess,
                path: "physical_behavior_snapshot.json"
            ))
        } else if options.scenario == "physical_behavior_multi_smoke",
                  let behaviorSuccess = physicalBehaviorSuccess {
            let coreLinks = coreEntityBridge.snapshotLinks(for: labAgents)
            let agentSnapshots = labAgents.compactMap { agent -> PhysicalBehaviorAgentSnapshot? in
                guard let coreLink = coreLinks.first(where: { $0.agentId == agent.id }) else {
                    return nil
                }
                return PhysicalBehaviorAgentSnapshot(
                    agentId: agent.id,
                    physicalId: coreLink.physicalId,
                    coreEntityId: coreLink.coreEntityId,
                    startPosition: agent.homePosition,
                    finalAbstractPosition: agent.position,
                    finalCoreEntityPosition: coreLink.coreEntityPosition,
                    moves: agent.movementCount,
                    totalDistance: agent.totalManhattanDistanceMoved,
                    finalDivergence: coreLink.divergence
                )
            }
            try writeJSON(
                PhysicalBehaviorMultiSnapshot(
                    scenario: options.scenario,
                    seed: options.seed,
                    ticksCompleted: ticksCompleted,
                    agents: agentSnapshots,
                    agentsMoved: physicalBehaviorAgentsMoved ?? 0,
                    totalMoves: physicalBehaviorMoves ?? 0,
                    totalDistance: physicalBehaviorTotalDistance ?? 0,
                    finalDivergence: physicalBehaviorFinalDivergence ?? 0,
                    maxDivergence: physicalBehaviorMaxDivergence ?? 0,
                    success: behaviorSuccess
                ),
                to: outURL.appendingPathComponent("physical_behavior_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "physical_behavior_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: behaviorSuccess,
                path: "physical_behavior_snapshot.json",
                agents: agentSnapshots.count
            ))
            if let physicalBehaviorInvariantReport {
                try writeJSON(
                    physicalBehaviorInvariantReport,
                    to: outURL.appendingPathComponent("physical_behavior_invariant_report.json")
                )
                try appendEvent(RunEvent(
                    type: "physical_behavior_invariant_report_written",
                    tick: ticksCompleted,
                    scenario: options.scenario,
                    success: physicalBehaviorInvariantReport.success,
                    path: "physical_behavior_invariant_report.json"
                ))
            }
        }
        if let terrainSemanticsFixtureReport {
            try writeJSON(
                terrainSemanticsFixtureReport,
                to: outURL.appendingPathComponent("terrain_semantics_fixture_report.json")
            )
        }
        if let terrainTraversabilityFixtureReport {
            try writeJSON(
                terrainTraversabilityFixtureReport,
                to: outURL.appendingPathComponent("terrain_traversability_fixture_report.json")
            )
        }
        if let terrainTraversabilityInvariantReport {
            try writeJSON(
                terrainTraversabilityInvariantReport,
                to: outURL.appendingPathComponent("terrain_traversability_invariant_report.json")
            )
        }
        if let terrainPathfindingFixtureReport {
            try writeJSON(
                terrainPathfindingFixtureReport,
                to: outURL.appendingPathComponent("terrain_pathfinding_fixture_report.json")
            )
        }
        if let terrainPathfindingInvariantReport {
            try writeJSON(
                terrainPathfindingInvariantReport,
                to: outURL.appendingPathComponent("terrain_pathfinding_invariant_report.json")
            )
        }
        if let terrainMovementFixtureReport {
            try writeJSON(
                terrainMovementFixtureReport,
                to: outURL.appendingPathComponent("terrain_path_movement_fixture_report.json")
            )
        }
        if let terrainMovementInvariantReport {
            try writeJSON(
                terrainMovementInvariantReport,
                to: outURL.appendingPathComponent("terrain_path_movement_invariant_report.json")
            )
        }
        if let terrainCollisionFixtureReport {
            try writeJSON(
                terrainCollisionFixtureReport,
                to: outURL.appendingPathComponent("terrain_collision_fixture_report.json")
            )
        }
        if let terrainCollisionInvariantReport {
            try writeJSON(
                terrainCollisionInvariantReport,
                to: outURL.appendingPathComponent("terrain_collision_invariant_report.json")
            )
        }
        if let terrainCollisionLiveSnapshot {
            try writeJSON(
                terrainCollisionLiveSnapshot,
                to: outURL.appendingPathComponent("terrain_collision_live_snapshot.json")
            )
        }
        if let terrainCollisionLiveInvariantReport {
            try writeJSON(
                terrainCollisionLiveInvariantReport,
                to: outURL.appendingPathComponent("terrain_collision_live_invariant_report.json")
            )
        }
        if let physicalMovementSnapshot {
            try writeJSON(
                physicalMovementSnapshot,
                to: outURL.appendingPathComponent("physical_movement_integration_snapshot.json")
            )
        }
        if let physicalMovementInvariantReport {
            try writeJSON(
                physicalMovementInvariantReport,
                to: outURL.appendingPathComponent("physical_movement_integration_invariant_report.json")
            )
        }
        if let physicalMovementOccupableSearchSnapshot {
            try writeJSON(
                physicalMovementOccupableSearchSnapshot,
                to: outURL.appendingPathComponent("physical_movement_occupable_search_snapshot.json")
            )
        }
        if let physicalMovementOccupableSearchInvariantReport {
            try writeJSON(
                physicalMovementOccupableSearchInvariantReport,
                to: outURL.appendingPathComponent("physical_movement_occupable_search_invariant_report.json")
            )
        }
        if let physicalMovementHardeningReport {
            try writeJSON(
                physicalMovementHardeningReport,
                to: outURL.appendingPathComponent("physical_movement_single_step_hardening_report.json")
            )
        }
        if let physicalMovementHardeningInvariantReport {
            try writeJSON(
                physicalMovementHardeningInvariantReport,
                to: outURL.appendingPathComponent("physical_movement_single_step_hardening_invariant_report.json")
            )
        }
        if let routeFollowingFixtureReport {
            try writeJSON(
                routeFollowingFixtureReport,
                to: outURL.appendingPathComponent("route_following_fixture_report.json")
            )
        }
        if let routeFollowingFixtureInvariantReport {
            try writeJSON(
                routeFollowingFixtureInvariantReport,
                to: outURL.appendingPathComponent("route_following_fixture_invariant_report.json")
            )
        }
        if let multiAgentMovementFixtureReport {
            try writeJSON(
                multiAgentMovementFixtureReport,
                to: outURL.appendingPathComponent("multi_agent_movement_fixture_report.json")
            )
        }
        if let multiAgentMovementFixtureInvariantReport {
            try writeJSON(
                multiAgentMovementFixtureInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_fixture_invariant_report.json")
            )
        }
        if let multiAgentMovementFixtureHardeningReport {
            try writeJSON(
                multiAgentMovementFixtureHardeningReport,
                to: outURL.appendingPathComponent("multi_agent_movement_fixture_hardening_report.json")
            )
        }
        if let multiAgentMovementFixtureHardeningInvariantReport {
            try writeJSON(
                multiAgentMovementFixtureHardeningInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_fixture_hardening_invariant_report.json")
            )
        }
        if let multiAgentLiveCollisionIntentReport {
            try writeJSON(
                multiAgentLiveCollisionIntentReport,
                to: outURL.appendingPathComponent("multi_agent_live_collision_intent_report.json")
            )
        }
        if let multiAgentLiveCollisionIntentInvariantReport {
            try writeJSON(
                multiAgentLiveCollisionIntentInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_live_collision_intent_invariant_report.json")
            )
        }
        if let multiAgentApprovedPhysicalMovementReport {
            try writeJSON(
                multiAgentApprovedPhysicalMovementReport,
                to: outURL.appendingPathComponent("multi_agent_approved_physical_movement_report.json")
            )
        }
        if let multiAgentApprovedPhysicalMovementInvariantReport {
            try writeJSON(
                multiAgentApprovedPhysicalMovementInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_approved_physical_movement_invariant_report.json")
            )
        }
        if let multiAgentMovementHardeningReport {
            try writeJSON(
                multiAgentMovementHardeningReport,
                to: outURL.appendingPathComponent("multi_agent_movement_hardening_report.json")
            )
        }
        if let multiAgentMovementHardeningInvariantReport {
            try writeJSON(
                multiAgentMovementHardeningInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_hardening_invariant_report.json")
            )
        }
        if let multiAgentMovementTickFixtureReport {
            try writeJSON(
                multiAgentMovementTickFixtureReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_fixture_report.json")
            )
            try writeJSON(
                multiAgentMovementTickFixtureReport.output.feedback,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_fixture_feedback.json")
            )
        }
        if let multiAgentMovementTickFixtureInvariantReport {
            try writeJSON(
                multiAgentMovementTickFixtureInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_fixture_invariant_report.json")
            )
        }
        if let multiAgentMovementTickLiveReadonlyReport {
            try writeJSON(
                multiAgentMovementTickLiveReadonlyReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_live_readonly_report.json")
            )
            try writeJSON(
                multiAgentMovementTickLiveReadonlyReport.output.feedback,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_live_readonly_feedback.json")
            )
        }
        if let multiAgentMovementTickLiveReadonlyInvariantReport {
            try writeJSON(
                multiAgentMovementTickLiveReadonlyInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_live_readonly_invariant_report.json")
            )
        }
        if let multiAgentMovementTickApprovedApplicationReport {
            try writeJSON(
                multiAgentMovementTickApprovedApplicationReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_approved_application_report.json")
            )
            try writeJSON(
                multiAgentMovementTickApprovedApplicationReport.output.feedback,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_approved_application_feedback.json")
            )
        }
        if let multiAgentMovementTickApprovedApplicationInvariantReport {
            try writeJSON(
                multiAgentMovementTickApprovedApplicationInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_approved_application_invariant_report.json")
            )
        }
        if let multiAgentMovementTickHardeningReport {
            try writeJSON(
                multiAgentMovementTickHardeningReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_hardening_report.json")
            )
            try writeJSON(
                multiAgentMovementTickHardeningReport.cases.flatMap(\.feedback),
                to: outURL.appendingPathComponent("multi_agent_movement_tick_hardening_feedback.json")
            )
        }
        if let multiAgentMovementTickHardeningInvariantReport {
            try writeJSON(
                multiAgentMovementTickHardeningInvariantReport,
                to: outURL.appendingPathComponent("multi_agent_movement_tick_hardening_invariant_report.json")
            )
        }
        if let agentIntentProductionFixtureReport {
            try writeJSON(
                agentIntentProductionFixtureReport,
                to: outURL.appendingPathComponent("agent_intent_production_fixture_report.json")
            )
            try writeJSON(
                agentIntentProductionFixtureReport.result,
                to: outURL.appendingPathComponent("agent_intent_proposals.json")
            )
        }
        if let agentIntentProductionFixtureInvariantReport {
            try writeJSON(
                agentIntentProductionFixtureInvariantReport,
                to: outURL.appendingPathComponent("agent_intent_production_fixture_invariant_report.json")
            )
        }
        if let agentIntentProductionHardeningReport {
            try writeJSON(
                agentIntentProductionHardeningReport,
                to: outURL.appendingPathComponent("agent_intent_production_hardening_report.json")
            )
            try writeJSON(
                agentIntentProductionHardeningReport.cases,
                to: outURL.appendingPathComponent("agent_intent_proposals.json")
            )
        }
        if let agentIntentProductionHardeningInvariantReport {
            try writeJSON(
                agentIntentProductionHardeningInvariantReport,
                to: outURL.appendingPathComponent("agent_intent_production_hardening_invariant_report.json")
            )
        }
        if let agentIntentToTickFixtureReport {
            try writeJSON(
                agentIntentToTickFixtureReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_fixture_report.json")
            )
            try writeJSON(
                agentIntentToTickFixtureReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_fixture_proposals.json")
            )
        }
        if let agentIntentToTickFixtureInvariantReport {
            try writeJSON(
                agentIntentToTickFixtureInvariantReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_fixture_invariant_report.json")
            )
        }
        if let agentIntentToTickLiveReadonlyReport {
            try writeJSON(
                agentIntentToTickLiveReadonlyReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_live_readonly_report.json")
            )
            try writeJSON(
                agentIntentToTickLiveReadonlyReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_live_readonly_proposals.json")
            )
        }
        if let agentIntentToTickLiveReadonlyInvariantReport {
            try writeJSON(
                agentIntentToTickLiveReadonlyInvariantReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_live_readonly_invariant_report.json")
            )
        }
        if let agentIntentToTickApprovedApplicationReport {
            try writeJSON(
                agentIntentToTickApprovedApplicationReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_approved_application_report.json")
            )
            try writeJSON(
                agentIntentToTickApprovedApplicationReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_approved_application_proposals.json")
            )
        }
        if let agentIntentToTickApprovedApplicationInvariantReport {
            try writeJSON(
                agentIntentToTickApprovedApplicationInvariantReport,
                to: outURL.appendingPathComponent("agent_intent_to_tick_approved_application_invariant_report.json")
            )
        }
        if let agentFeedbackConsumptionFixtureReport {
            try writeJSON(
                agentFeedbackConsumptionFixtureReport,
                to: outURL.appendingPathComponent("agent_feedback_consumption_fixture_report.json")
            )
            try writeJSON(
                agentFeedbackConsumptionFixtureReport.result,
                to: outURL.appendingPathComponent("agent_feedback_contexts.json")
            )
        }
        if let agentFeedbackConsumptionFixtureInvariantReport {
            try writeJSON(
                agentFeedbackConsumptionFixtureInvariantReport,
                to: outURL.appendingPathComponent("agent_feedback_consumption_fixture_invariant_report.json")
            )
        }
        if let agentFeedbackConsumptionHardeningReport {
            try writeJSON(
                agentFeedbackConsumptionHardeningReport,
                to: outURL.appendingPathComponent("agent_feedback_consumption_hardening_report.json")
            )
            try writeJSON(
                agentFeedbackConsumptionHardeningReport.cases,
                to: outURL.appendingPathComponent("agent_feedback_consumption_hardening_cases.json")
            )
        }
        if let agentFeedbackConsumptionHardeningInvariantReport {
            try writeJSON(
                agentFeedbackConsumptionHardeningInvariantReport,
                to: outURL.appendingPathComponent("agent_feedback_consumption_hardening_invariant_report.json")
            )
        }
        if let feedbackToAgentIntentContextFixtureReport {
            try writeJSON(
                feedbackToAgentIntentContextFixtureReport,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_context_fixture_report.json")
            )
            try writeJSON(
                feedbackToAgentIntentContextFixtureReport,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_contexts.json")
            )
        }
        if let feedbackToAgentIntentContextFixtureInvariantReport {
            try writeJSON(
                feedbackToAgentIntentContextFixtureInvariantReport,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_context_fixture_invariant_report.json")
            )
        }
        if let feedbackToAgentIntentContextHardeningReport {
            try writeJSON(
                feedbackToAgentIntentContextHardeningReport,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_context_hardening_report.json")
            )
            try writeJSON(
                feedbackToAgentIntentContextHardeningReport.cases,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_context_hardening_cases.json")
            )
        }
        if let feedbackToAgentIntentContextHardeningInvariantReport {
            try writeJSON(
                feedbackToAgentIntentContextHardeningInvariantReport,
                to: outURL.appendingPathComponent("feedback_to_agent_intent_context_hardening_invariant_report.json")
            )
        }
        if let feedbackAwareIntentPolicyFixtureReport {
            try writeJSON(
                feedbackAwareIntentPolicyFixtureReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_fixture_report.json")
            )
            try writeJSON(
                feedbackAwareIntentPolicyFixtureReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_decisions.json")
            )
        }
        if let feedbackAwareIntentPolicyFixtureInvariantReport {
            try writeJSON(
                feedbackAwareIntentPolicyFixtureInvariantReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_fixture_invariant_report.json")
            )
        }
        if let feedbackAwareIntentPolicyHardeningReport {
            try writeJSON(
                feedbackAwareIntentPolicyHardeningReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_hardening_report.json")
            )
            try writeJSON(
                feedbackAwareIntentPolicyHardeningReport.cases,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_hardening_cases.json")
            )
        }
        if let feedbackAwareIntentPolicyHardeningInvariantReport {
            try writeJSON(
                feedbackAwareIntentPolicyHardeningInvariantReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_policy_hardening_invariant_report.json")
            )
        }
        if let feedbackAwareIntentToTickFixtureReport {
            try writeJSON(
                feedbackAwareIntentToTickFixtureReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_fixture_report.json")
            )
            try writeJSON(
                feedbackAwareIntentToTickFixtureReport.handoff,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_handoff.json")
            )
        }
        if let feedbackAwareIntentToTickFixtureInvariantReport {
            try writeJSON(
                feedbackAwareIntentToTickFixtureInvariantReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_fixture_invariant_report.json")
            )
        }
        if let feedbackAwareIntentToTickLiveReadonlyReport {
            try writeJSON(
                feedbackAwareIntentToTickLiveReadonlyReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_live_readonly_report.json")
            )
            try writeJSON(
                feedbackAwareIntentToTickLiveReadonlyReport.handoff,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_live_readonly_handoff.json")
            )
        }
        if let feedbackAwareIntentToTickLiveReadonlyInvariantReport {
            try writeJSON(
                feedbackAwareIntentToTickLiveReadonlyInvariantReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_live_readonly_invariant_report.json")
            )
        }
        if let feedbackAwareIntentToTickApprovedApplicationReport {
            try writeJSON(
                feedbackAwareIntentToTickApprovedApplicationReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_approved_application_report.json")
            )
            try writeJSON(
                feedbackAwareIntentToTickApprovedApplicationReport.handoff,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_approved_application_handoff.json")
            )
        }
        if let feedbackAwareIntentToTickApprovedApplicationInvariantReport {
            try writeJSON(
                feedbackAwareIntentToTickApprovedApplicationInvariantReport,
                to: outURL.appendingPathComponent("feedback_aware_intent_to_tick_approved_application_invariant_report.json")
            )
        }
        if let alternateLocalHintReport {
            try writeJSON(
                alternateLocalHintReport,
                to: outURL.appendingPathComponent("alternate_local_hint_report.json")
            )
            try writeJSON(
                alternateLocalHintReport.handoff,
                to: outURL.appendingPathComponent("alternate_local_hint_handoff.json")
            )
            try writeJSON(
                alternateLocalHintReport.decisions,
                to: outURL.appendingPathComponent("alternate_local_hint_decisions.json")
            )
        }
        if let alternateLocalHintInvariantReport {
            try writeJSON(
                alternateLocalHintInvariantReport,
                to: outURL.appendingPathComponent("alternate_local_hint_invariant_report.json")
            )
        }
        if let alternateLocalHintHardeningReport {
            try writeJSON(
                alternateLocalHintHardeningReport,
                to: outURL.appendingPathComponent("alternate_local_hint_hardening_report.json")
            )
            try writeJSON(
                alternateLocalHintHardeningReport.cases,
                to: outURL.appendingPathComponent("alternate_local_hint_hardening_cases.json")
            )
            try writeJSON(
                alternateLocalHintHardeningReport.cases.map(\.decision),
                to: outURL.appendingPathComponent("alternate_local_hint_hardening_decisions.json")
            )
            try writeJSON(
                alternateLocalHintHardeningReport.handoff,
                to: outURL.appendingPathComponent("alternate_local_hint_hardening_handoff.json")
            )
        }
        if let alternateLocalHintHardeningInvariantReport {
            try writeJSON(
                alternateLocalHintHardeningInvariantReport,
                to: outURL.appendingPathComponent("alternate_local_hint_hardening_invariant_report.json")
            )
        }
        if let multiTickClosedLoopReport {
            try writeJSON(
                multiTickClosedLoopReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_report.json")
            )
            try writeJSON(
                multiTickClosedLoopReport.tickRecords,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_ticks.json")
            )
            try writeJSON(
                multiTickClosedLoopReport.feedbackLedger,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_feedback.json")
            )
        }
        if let multiTickClosedLoopInvariantReport {
            try writeJSON(
                multiTickClosedLoopInvariantReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_invariant_report.json")
            )
        }
        if let multiTickClosedLoopHardeningReport {
            try writeJSON(
                multiTickClosedLoopHardeningReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_hardening_report.json")
            )
            try writeJSON(
                multiTickClosedLoopHardeningReport.cases,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_hardening_cases.json")
            )
        }
        if let multiTickClosedLoopHardeningInvariantReport {
            try writeJSON(
                multiTickClosedLoopHardeningInvariantReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_hardening_invariant_report.json")
            )
        }
        if let multiTickClosedLoopHardeningFeedbackReport {
            try writeJSON(
                multiTickClosedLoopHardeningFeedbackReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_hardening_feedback.json")
            )
        }
        if let multiTickClosedLoopLiveReadonlyReport {
            try writeJSON(
                multiTickClosedLoopLiveReadonlyReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_live_readonly_report.json")
            )
            try writeJSON(
                multiTickClosedLoopLiveReadonlyReport.tickRecords,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_live_readonly_ticks.json")
            )
            try writeJSON(
                multiTickClosedLoopLiveReadonlyReport.feedbackLedger,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_live_readonly_feedback.json")
            )
        }
        if let multiTickClosedLoopLiveReadonlyInvariantReport {
            try writeJSON(
                multiTickClosedLoopLiveReadonlyInvariantReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_live_readonly_invariant_report.json")
            )
        }
        if let multiTickClosedLoopApprovedApplicationReport {
            try writeJSON(
                multiTickClosedLoopApprovedApplicationReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_approved_application_report.json")
            )
            try writeJSON(
                multiTickClosedLoopApprovedApplicationReport.tickRecords,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_approved_application_ticks.json")
            )
            try writeJSON(
                multiTickClosedLoopApprovedApplicationReport.feedbackLedger,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_approved_application_feedback.json")
            )
        }
        if let multiTickClosedLoopApprovedApplicationInvariantReport {
            try writeJSON(
                multiTickClosedLoopApprovedApplicationInvariantReport,
                to: outURL.appendingPathComponent("multi_tick_closed_loop_approved_application_invariant_report.json")
            )
        }
        if let routeFollowingLiveSnapshot {
            try writeJSON(
                routeFollowingLiveSnapshot,
                to: outURL.appendingPathComponent("route_following_live_snapshot.json")
            )
        }
        if let routeFollowingLiveInvariantReport {
            try writeJSON(
                routeFollowingLiveInvariantReport,
                to: outURL.appendingPathComponent("route_following_live_invariant_report.json")
            )
        }
        if let routeFollowingLiveHardeningReport {
            try writeJSON(
                routeFollowingLiveHardeningReport,
                to: outURL.appendingPathComponent("route_following_live_hardening_report.json")
            )
        }
        if let routeFollowingLiveHardeningInvariantReport {
            try writeJSON(
                routeFollowingLiveHardeningInvariantReport,
                to: outURL.appendingPathComponent("route_following_live_hardening_invariant_report.json")
            )
        }
        if let terrainColumnScanSnapshot {
            try writeJSON(
                terrainColumnScanSnapshot,
                to: outURL.appendingPathComponent("terrain_column_scan_snapshot.json")
            )
            if let terrainColumnScanInvariantReport {
                try writeJSON(
                    terrainColumnScanInvariantReport,
                    to: outURL.appendingPathComponent("terrain_column_scan_invariant_report.json")
                )
            }
        }
        if let terrainPathfindingColumnSnapshot {
            try writeJSON(
                terrainPathfindingColumnSnapshot,
                to: outURL.appendingPathComponent("terrain_pathfinding_column_snapshot.json")
            )
        }
        if let terrainPathfindingColumnInvariantReport {
            try writeJSON(
                terrainPathfindingColumnInvariantReport,
                to: outURL.appendingPathComponent("terrain_pathfinding_column_invariant_report.json")
            )
        }
        if let terrainPathfindingPositiveSnapshot {
            try writeJSON(
                terrainPathfindingPositiveSnapshot,
                to: outURL.appendingPathComponent("terrain_pathfinding_column_positive_snapshot.json")
            )
        }
        if let terrainPathfindingPositiveInvariantReport {
            try writeJSON(
                terrainPathfindingPositiveInvariantReport,
                to: outURL.appendingPathComponent("terrain_pathfinding_column_positive_invariant_report.json")
            )
        }
        if let terrainLiveMovementSnapshot {
            try writeJSON(
                terrainLiveMovementSnapshot,
                to: outURL.appendingPathComponent("terrain_path_live_movement_snapshot.json")
            )
        }
        if let terrainLiveMovementInvariantReport {
            try writeJSON(
                terrainLiveMovementInvariantReport,
                to: outURL.appendingPathComponent("terrain_path_live_movement_invariant_report.json")
            )
        }
        if let terrainScanSnapshot {
            try writeJSON(
                terrainScanSnapshot,
                to: outURL.appendingPathComponent("terrain_scan_snapshot.json")
            )
            if let terrainScanInvariantReport {
                try writeJSON(
                    terrainScanInvariantReport,
                    to: outURL.appendingPathComponent("terrain_scan_invariant_report.json")
                )
            }
            if let terrainSemanticsInvariantReport {
                try writeJSON(
                    terrainSemanticsInvariantReport,
                    to: outURL.appendingPathComponent("terrain_semantics_invariant_report.json")
                )
            }
        } else if let worldInteractionMultiSnapshot {
            try writeJSON(
                worldInteractionMultiSnapshot,
                to: outURL.appendingPathComponent("world_interaction_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "world_interaction_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: worldInteractionMultiSnapshot.summary.success,
                path: "world_interaction_snapshot.json",
                agents: worldInteractionMultiSnapshot.summary.agents
            ))
            if let worldObservationInvariantReport {
                try writeJSON(
                    worldObservationInvariantReport,
                    to: outURL.appendingPathComponent("world_observation_invariant_report.json")
                )
                try appendEvent(RunEvent(
                    type: "world_observation_invariant_report_written",
                    tick: ticksCompleted,
                    scenario: options.scenario,
                    success: worldObservationInvariantReport.success,
                    path: "world_observation_invariant_report.json"
                ))
            }
        } else if let worldInteractionSnapshot {
            try writeJSON(
                worldInteractionSnapshot,
                to: outURL.appendingPathComponent("world_interaction_snapshot.json")
            )
            try appendEvent(RunEvent(
                type: "world_interaction_snapshot_written",
                tick: ticksCompleted,
                scenario: options.scenario,
                success: worldInteractionSnapshot.success,
                path: "world_interaction_snapshot.json"
            ))
        }
        let metrics = RunMetrics(
            scenario: options.scenario,
            seed: options.seed,
            ticksRequested: options.ticks,
            ticksCompleted: ticksCompleted,
            worldTime: world?.time ?? 0,
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
            worldEntitiesCount: coreEntityBridge.count == 0 ? nil : requireWorld().entities.count,
            physicalBehaviorTicks: isPhysicalBehaviorScenario ? ticksCompleted : nil,
            physicalBehaviorAgents: physicalBehaviorAgents,
            physicalBehaviorAgentsMoved: physicalBehaviorAgentsMoved,
            physicalBehaviorMoves: physicalBehaviorMoves,
            physicalBehaviorCoreSyncs: isPhysicalBehaviorScenario ? coreEntitySyncEvents : nil,
            physicalBehaviorTotalDistance: physicalBehaviorTotalDistance,
            physicalBehaviorFinalDivergence: physicalBehaviorFinalDivergence,
            physicalBehaviorMaxDivergence: physicalBehaviorMaxDivergence,
            physicalBehaviorSuccess: physicalBehaviorSuccess,
            worldInteractionAgents: worldInteractionAgents,
            worldInteractionObservations: worldInteractionObservations,
            worldInteractionLoadedObservations: worldInteractionLoadedObservations,
            worldInteractionReadyObservations: worldInteractionReadyObservations,
            worldInteractionUniqueChunks: worldInteractionUniqueChunks,
            worldInteractionDistinctBlockIds: worldInteractionDistinctBlockIds,
            worldInteractionBlockId: isWorldObservationSingleScenario ? worldInteractionSnapshot?.blockId : nil,
            worldInteractionMeta: isWorldObservationSingleScenario ? worldInteractionSnapshot?.meta : nil,
            worldInteractionSuccess: worldInteractionSuccess,
            terrainScanAgents: isTerrainScanRun ? labAgents.count : nil,
            terrainScanRadius: terrainScanSnapshot?.radius,
            terrainScanCellsPlanned: terrainScanSnapshot?.summary.cellsPlanned,
            terrainScanCellsObserved: terrainScanSnapshot?.summary.cellsObserved,
            terrainScanLoadedCells: terrainScanSnapshot?.summary.loadedCells,
            terrainScanReadyCells: terrainScanSnapshot?.summary.readyCells,
            terrainScanDistinctBlockIds: terrainScanSnapshot?.summary.distinctBlockIds,
            terrainScanUniqueChunks: terrainScanSnapshot?.summary.uniqueChunks,
            terrainScanSuccess: terrainScanSuccess,
            terrainSemanticCells: terrainScanSnapshot?.semanticSummary.cellsClassified,
            terrainSemanticUnknownCells: terrainScanSnapshot?.semanticSummary.unknownCells,
            terrainSemanticAirCells: terrainScanSnapshot?.semanticSummary.airCells,
            terrainSemanticSolidCells: terrainScanSnapshot?.semanticSummary.solidCells,
            terrainSemanticLiquidCells: terrainScanSnapshot?.semanticSummary.liquidCells,
            terrainSemanticPlantLikeCells: terrainScanSnapshot?.semanticSummary.plantLikeCells,
            terrainSemanticOtherCells: terrainScanSnapshot?.semanticSummary.otherCells,
            terrainSemanticSuccess: terrainSemanticSuccess,
            terrainSemanticFixtureCases: terrainSemanticsFixtureReport?.summary.fixtures,
            terrainSemanticFixturePassed: terrainSemanticsFixtureReport?.summary.passed,
            terrainSemanticFixtureFailed: terrainSemanticsFixtureReport?.summary.failed,
            terrainSemanticFixtureUnknownCases: terrainSemanticsFixtureReport?.summary.unknownCases,
            terrainSemanticFixtureAirCases: terrainSemanticsFixtureReport?.summary.airCases,
            terrainSemanticFixtureSolidCases: terrainSemanticsFixtureReport?.summary.solidCases,
            terrainSemanticFixtureLiquidCases: terrainSemanticsFixtureReport?.summary.liquidCases,
            terrainSemanticFixturePlantLikeCases: terrainSemanticsFixtureReport?.summary.plantLikeCases,
            terrainSemanticFixtureOtherCases: terrainSemanticsFixtureReport?.summary.otherCases,
            terrainSemanticFixtureSuccess: terrainSemanticsFixtureSuccess,
            terrainTraversabilityCells: terrainTraversabilitySummary?.cellsEvaluated,
            terrainTraversabilityTraversableCells: terrainTraversabilitySummary?.traversableCells,
            terrainTraversabilityBlockedCells: terrainTraversabilitySummary?.blockedCells,
            terrainTraversabilityUnknownCells: terrainTraversabilitySummary?.unknownCells,
            terrainTraversabilityUnsupportedCells: terrainTraversabilitySummary?.unsupportedCells,
            terrainTraversabilityUnsafeCells: terrainTraversabilitySummary?.unsafeCells,
            terrainTraversabilityOccupiedVerticalSpaceCells: terrainTraversabilitySummary?.occupiedVerticalSpaceCells,
            terrainTraversabilityOtherCells: terrainTraversabilitySummary?.otherCells,
            terrainTraversabilitySuccess: terrainTraversabilitySuccess,
            terrainTraversabilityFixtureCases: terrainTraversabilityFixtureReport?.summary.fixtures,
            terrainTraversabilityFixturePassed: terrainTraversabilityFixtureReport?.summary.passed,
            terrainTraversabilityFixtureFailed: terrainTraversabilityFixtureReport?.summary.failed,
            terrainColumnScanColumns: terrainColumnScanSnapshot?.summary.columnsPlanned,
            terrainColumnScanColumnsObserved: terrainColumnScanSnapshot?.summary.columnsObserved,
            terrainColumnScanCellsPlanned: terrainColumnScanSnapshot?.summary.cellsPlanned,
            terrainColumnScanCellsObserved: terrainColumnScanSnapshot?.summary.cellsObserved,
            terrainColumnScanLoadedCells: terrainColumnScanSnapshot?.summary.loadedCells,
            terrainColumnScanReadyCells: terrainColumnScanSnapshot?.summary.readyCells,
            terrainColumnScanUniqueChunks: terrainColumnScanSnapshot?.summary.uniqueChunks,
            terrainColumnScanSuccess: terrainColumnScanSuccess,
            terrainColumnSemanticCells: terrainColumnDerivedSummary?.semanticCells,
            terrainColumnTraversabilityCells: terrainColumnDerivedSummary?.traversabilityCells,
            terrainColumnTraversableCells: terrainColumnDerivedSummary?.traversableCells,
            terrainColumnUnsafeCells: terrainColumnDerivedSummary?.unsafeCells,
            terrainColumnUnknownCells: terrainColumnDerivedSummary?.unknownCells,
            terrainColumnUnsupportedCells: terrainColumnDerivedSummary?.unsupportedCells,
            terrainColumnOccupiedVerticalSpaceCells: terrainColumnDerivedSummary?.occupiedVerticalSpaceCells,
            terrainColumnTraversabilitySuccess: terrainColumnTraversabilitySuccess,
            terrainPathfindingFixtureCases: terrainPathfindingFixtureReport?.summary.fixtures,
            terrainPathfindingFixturePassed: terrainPathfindingFixtureReport?.summary.passed,
            terrainPathfindingFixtureFailed: terrainPathfindingFixtureReport?.summary.failed,
            terrainPathfindingPathsFound: terrainPathfindingFixtureReport?.summary.pathsFound,
            terrainPathfindingPathsNotFound: terrainPathfindingFixtureReport?.summary.pathsNotFound,
            terrainPathfindingInvalidStarts: terrainPathfindingFixtureReport?.summary.invalidStarts,
            terrainPathfindingInvalidGoals: terrainPathfindingFixtureReport?.summary.invalidGoals,
            terrainPathfindingSearchLimitReached: terrainPathfindingFixtureReport?.summary.searchLimitReached,
            terrainPathfindingUnknown: terrainPathfindingFixtureReport?.summary.unknown,
            terrainPathfindingSuccess: terrainPathfindingSuccess,
            terrainPathfindingColumnNodes: terrainPathfindingColumnSnapshot?.summary.nodes,
            terrainPathfindingColumnTraversableNodes: terrainPathfindingColumnSnapshot?.summary.traversableNodes,
            terrainPathfindingColumnUnsafeNodes: terrainPathfindingColumnSnapshot?.summary.unsafeNodes,
            terrainPathfindingColumnUnknownNodes: terrainPathfindingColumnSnapshot?.summary.unknownNodes,
            terrainPathfindingColumnPathFound: terrainPathfindingColumnSnapshot.map {
                $0.result.status == LabTerrainPathfindingStatus.found
            },
            terrainPathfindingColumnPathLength: terrainPathfindingColumnSnapshot?.summary.pathLength,
            terrainPathfindingColumnVisited: terrainPathfindingColumnSnapshot?.summary.visited,
            terrainPathfindingColumnSuccess: terrainPathfindingColumnSuccess,
            terrainPathfindingColumnPositiveCandidates: terrainPathfindingPositiveSnapshot?.summary.candidates,
            terrainPathfindingColumnPositiveCandidateIndex: terrainPathfindingPositiveSnapshot?.summary.selectedCandidateIndex,
            terrainPathfindingColumnPositiveFound: terrainPathfindingPositiveSnapshot?.summary.pathFound,
            terrainPathfindingColumnPositivePathLength: terrainPathfindingPositiveSnapshot?.summary.pathLength,
            terrainPathfindingColumnPositiveVisited: terrainPathfindingPositiveSnapshot?.summary.visited,
            terrainPathfindingColumnPositiveSuccess: terrainPathfindingPositiveSuccess,
            terrainMovementFixtureCases: terrainMovementFixtureReport?.summary.fixtures,
            terrainMovementFixturePassed: terrainMovementFixtureReport?.summary.passed,
            terrainMovementFixtureFailed: terrainMovementFixtureReport?.summary.failed,
            terrainMovementStepsPlanned: terrainMovementFixtureReport?.summary.stepsPlanned,
            terrainMovementStepsExecuted: terrainMovementFixtureReport?.summary.stepsExecuted,
            terrainMovementReachedGoals: terrainMovementFixtureReport?.summary.reachedGoals,
            terrainMovementInvalidPaths: terrainMovementFixtureReport?.summary.invalidPaths,
            terrainMovementSuccess: terrainMovementSuccess,
            terrainLiveMovementPathLength: terrainLiveMovementSnapshot?.summary.pathLength,
            terrainLiveMovementStepsExecuted: terrainLiveMovementSnapshot?.summary.stepsExecuted,
            terrainLiveMovementReachedGoal: terrainLiveMovementSnapshot?.summary.reachedGoal,
            terrainLiveMovementFinalStatus: terrainLiveMovementSnapshot?.summary.finalStatus.rawValue,
            terrainLiveMovementLiveAgentDisplaced: terrainLiveMovementSnapshot?.summary.liveAgentDisplaced,
            terrainLiveMovementCollisionPerformed: terrainLiveMovementSnapshot?.summary.collisionPerformed,
            terrainLiveMovementMutationPerformed: terrainLiveMovementSnapshot?.summary.mutationPerformed,
            terrainLiveMovementSuccess: terrainLiveMovementSuccess,
            terrainCollisionFixtureCases: terrainCollisionFixtureReport?.summary.fixtures,
            terrainCollisionFixturePassed: terrainCollisionFixtureReport?.summary.passed,
            terrainCollisionFixtureFailed: terrainCollisionFixtureReport?.summary.failed,
            terrainCollisionOccupable: terrainCollisionFixtureReport?.summary.occupable,
            terrainCollisionBlocked: terrainCollisionFixtureReport?.summary.blocked,
            terrainCollisionUnsupported: terrainCollisionFixtureReport?.summary.unsupported,
            terrainCollisionVerticalSpaceOccupied: terrainCollisionFixtureReport?.summary.verticalSpaceOccupied,
            terrainCollisionLiquidUnsupported: terrainCollisionFixtureReport?.summary.liquidUnsupported,
            terrainCollisionUnknown: terrainCollisionFixtureReport?.summary.unknown,
            terrainCollisionOutOfBounds: terrainCollisionFixtureReport?.summary.outOfBounds,
            terrainCollisionNotLoaded: terrainCollisionFixtureReport?.summary.notLoaded,
            terrainCollisionNotReady: terrainCollisionFixtureReport?.summary.notReady,
            terrainCollisionFixtureSuccess: terrainCollisionSuccess,
            terrainCollisionLiveSamples: terrainCollisionLiveSnapshot?.summary.samples,
            terrainCollisionLiveLoadedSamples: terrainCollisionLiveSnapshot?.summary.loadedSamples,
            terrainCollisionLiveReadySamples: terrainCollisionLiveSnapshot?.summary.readySamples,
            terrainCollisionLiveStatus: terrainCollisionLiveSnapshot?.summary.status.rawValue,
            terrainCollisionLiveOccupable: terrainCollisionLiveSnapshot.map { $0.summary.status == .occupable },
            terrainCollisionLiveBlocked: terrainCollisionLiveSnapshot.map { $0.summary.status == .blocked },
            terrainCollisionLiveUnsupported: terrainCollisionLiveSnapshot.map { $0.summary.status == .unsupported },
            terrainCollisionLiveVerticalSpaceOccupied: terrainCollisionLiveSnapshot.map { $0.summary.status == .verticalSpaceOccupied },
            terrainCollisionLiveLiquidUnsupported: terrainCollisionLiveSnapshot.map { $0.summary.status == .liquidUnsupported },
            terrainCollisionLiveUnknown: terrainCollisionLiveSnapshot.map { $0.summary.status == .unknown },
            terrainCollisionLiveOutOfBounds: terrainCollisionLiveSnapshot.map { $0.summary.status == .outOfBounds },
            terrainCollisionLiveNotLoaded: terrainCollisionLiveSnapshot.map { $0.summary.status == .notLoaded },
            terrainCollisionLiveNotReady: terrainCollisionLiveSnapshot.map { $0.summary.status == .notReady },
            terrainCollisionLiveMovementPerformed: terrainCollisionLiveSnapshot?.summary.movementPerformed,
            terrainCollisionLivePathfindingPerformed: terrainCollisionLiveSnapshot?.summary.pathfindingPerformed,
            terrainCollisionLiveMutationPerformed: terrainCollisionLiveSnapshot?.summary.mutationPerformed,
            terrainCollisionLiveSuccess: terrainCollisionLiveSuccess,
            physicalMovementAttempted: physicalMovementSnapshot.map { _ in true },
            physicalMovementApproved: physicalMovementSnapshot.map { $0.status == .approved },
            physicalMovementDenied: physicalMovementSnapshot.map {
                $0.status == .collisionDenied || $0.status == .denied
            },
            physicalMovementStatus: physicalMovementSnapshot?.status.rawValue,
            physicalMovementReason: physicalMovementSnapshot?.reason,
            physicalMovementFromX: physicalMovementSnapshot?.from.x,
            physicalMovementFromY: physicalMovementSnapshot?.from.y,
            physicalMovementFromZ: physicalMovementSnapshot?.from.z,
            physicalMovementToX: physicalMovementSnapshot?.to.x,
            physicalMovementToY: physicalMovementSnapshot?.to.y,
            physicalMovementToZ: physicalMovementSnapshot?.to.z,
            physicalMovementCollisionStatus: physicalMovementSnapshot?.collisionStatus.rawValue,
            physicalMovementDisplacementApplied: physicalMovementSnapshot?.displacementApplied,
            physicalMovementPathfindingPerformed: physicalMovementSnapshot?.pathfindingPerformed,
            physicalMovementRouteFollowingPerformed: physicalMovementSnapshot?.routeFollowingPerformed,
            physicalMovementPhysicsPerformed: physicalMovementSnapshot?.physicsPerformed,
            physicalMovementMutationPerformed: physicalMovementSnapshot?.mutationPerformed,
            physicalMovementDivergenceBefore: physicalMovementSnapshot?.divergenceBefore,
            physicalMovementDivergenceAfter: physicalMovementSnapshot?.divergenceAfter,
            physicalMovementSuccess: physicalMovementSuccess,
            physicalMovementOccupableSearchCandidates: physicalMovementOccupableSearchSnapshot?.summary.candidatesEvaluated,
            physicalMovementOccupableSearchFound: physicalMovementOccupableSearchSnapshot?.summary.occupableFound,
            physicalMovementOccupableSearchSelectedIndex: physicalMovementOccupableSearchSnapshot?.summary.selectedCandidateIndex,
            physicalMovementOccupableSearchSelectedX: physicalMovementOccupableSearchSnapshot?.summary.selectedNode?.x,
            physicalMovementOccupableSearchSelectedY: physicalMovementOccupableSearchSnapshot?.summary.selectedNode?.y,
            physicalMovementOccupableSearchSelectedZ: physicalMovementOccupableSearchSnapshot?.summary.selectedNode?.z,
            physicalMovementOccupableSearchSelectedStatus: physicalMovementOccupableSearchSnapshot?.summary.selectedStatus?.rawValue,
            physicalMovementOccupableSearchMovementPerformed: physicalMovementOccupableSearchSnapshot?.summary.movementPerformed,
            physicalMovementOccupableSearchPathfindingPerformed: physicalMovementOccupableSearchSnapshot?.summary.pathfindingPerformed,
            physicalMovementOccupableSearchRouteFollowingPerformed: physicalMovementOccupableSearchSnapshot?.summary.routeFollowingPerformed,
            physicalMovementOccupableSearchPhysicsPerformed: physicalMovementOccupableSearchSnapshot?.summary.physicsPerformed,
            physicalMovementOccupableSearchMutationPerformed: physicalMovementOccupableSearchSnapshot?.summary.mutationPerformed,
            physicalMovementOccupableSearchSuccess: physicalMovementOccupableSearchSuccess,
            physicalMovementHardeningCases: physicalMovementHardeningReport?.summary.cases,
            physicalMovementHardeningPassed: physicalMovementHardeningReport?.summary.passed,
            physicalMovementHardeningFailed: physicalMovementHardeningReport?.summary.failed,
            physicalMovementHardeningApproved: physicalMovementHardeningReport?.summary.approved,
            physicalMovementHardeningDenied: physicalMovementHardeningReport?.summary.denied,
            physicalMovementHardeningCollisionDenied: physicalMovementHardeningReport?.summary.collisionDenied,
            physicalMovementHardeningSourceMismatch: physicalMovementHardeningReport?.summary.sourceMismatch,
            physicalMovementHardeningMissingPhysicalHandle: physicalMovementHardeningReport?.summary.missingPhysicalHandle,
            physicalMovementHardeningDivergenceBeforeMove: physicalMovementHardeningReport?.summary.divergenceBeforeMove,
            physicalMovementHardeningDisplacementApplied: physicalMovementHardeningReport?.summary.displacementApplied,
            physicalMovementHardeningDisplacementRefused: physicalMovementHardeningReport?.summary.displacementRefused,
            physicalMovementHardeningSuccess: physicalMovementHardeningSuccess,
            multiAgentMovementFixtureCases: multiAgentMovementFixtureReport?.summary.cases,
            multiAgentMovementFixturePassed: multiAgentMovementFixtureReport?.summary.passed,
            multiAgentMovementFixtureFailed: multiAgentMovementFixtureReport?.summary.failed,
            multiAgentMovementFixtureAgentCount: multiAgentMovementFixtureReport?.summary.agentCountTotal,
            multiAgentMovementFixtureIntentCount: multiAgentMovementFixtureReport?.summary.intentCountTotal,
            multiAgentMovementFixtureApproved: multiAgentMovementFixtureReport?.summary.approvedTotal,
            multiAgentMovementFixtureDenied: multiAgentMovementFixtureReport?.summary.deniedTotal,
            multiAgentMovementFixtureSameDestinationConflicts: multiAgentMovementFixtureReport?.summary.sameDestinationConflicts,
            multiAgentMovementFixtureOccupiedDestinationConflicts: multiAgentMovementFixtureReport?.summary.occupiedDestinationConflicts,
            multiAgentMovementFixtureSwapConflicts: multiAgentMovementFixtureReport?.summary.swapConflicts,
            multiAgentMovementFixtureSourceMismatch: multiAgentMovementFixtureReport?.summary.sourceMismatch,
            multiAgentMovementFixtureStaleIntent: multiAgentMovementFixtureReport?.summary.staleIntent,
            multiAgentMovementFixtureMissingAgent: multiAgentMovementFixtureReport?.summary.missingAgent,
            multiAgentMovementFixtureInvalidEdges: multiAgentMovementFixtureReport?.summary.invalidEdges,
            multiAgentMovementFixturePathfindingPerformed: multiAgentMovementFixtureReport?.summary.pathfindingPerformed,
            multiAgentMovementFixtureReplanningPerformed: multiAgentMovementFixtureReport?.summary.replanningPerformed,
            multiAgentMovementFixturePhysicsPerformed: multiAgentMovementFixtureReport?.summary.physicsPerformed,
            multiAgentMovementFixtureMutationPerformed: multiAgentMovementFixtureReport?.summary.mutationPerformed,
            multiAgentMovementFixtureSuccess: multiAgentMovementFixtureSuccess,
            multiAgentMovementFixtureHardeningCases: multiAgentMovementFixtureHardeningReport?.summary.cases,
            multiAgentMovementFixtureHardeningPassed: multiAgentMovementFixtureHardeningReport?.summary.passed,
            multiAgentMovementFixtureHardeningFailed: multiAgentMovementFixtureHardeningReport?.summary.failed,
            multiAgentMovementFixtureHardeningApproved: multiAgentMovementFixtureHardeningReport?.summary.approvedTotal,
            multiAgentMovementFixtureHardeningDenied: multiAgentMovementFixtureHardeningReport?.summary.deniedTotal,
            multiAgentMovementFixtureHardeningDuplicateIntent: multiAgentMovementFixtureHardeningReport?.summary.duplicateIntent,
            multiAgentMovementFixtureHardeningCycleConflicts: multiAgentMovementFixtureHardeningReport?.summary.cycleConflicts,
            multiAgentMovementFixtureHardeningChainDependencies: multiAgentMovementFixtureHardeningReport?.summary.chainDependencies,
            multiAgentMovementFixtureHardeningMovingAwayDestination: multiAgentMovementFixtureHardeningReport?.summary.movingAwayDestination,
            multiAgentMovementFixtureHardeningVerticalInvalidEdges: multiAgentMovementFixtureHardeningReport?.summary.verticalInvalidEdges,
            multiAgentMovementFixtureHardeningZeroLengthEdges: multiAgentMovementFixtureHardeningReport?.summary.zeroLengthEdges,
            multiAgentMovementFixtureHardeningAllDeniedCases: multiAgentMovementFixtureHardeningReport?.summary.allDeniedCases,
            multiAgentMovementFixtureHardeningEmptyIntentCases: multiAgentMovementFixtureHardeningReport?.summary.emptyIntentCases,
            multiAgentMovementFixtureHardeningMaxAgentsExceeded: multiAgentMovementFixtureHardeningReport?.summary.maxAgentsExceeded,
            multiAgentMovementFixtureHardeningWorldUsed: multiAgentMovementFixtureHardeningReport?.summary.worldUsed,
            multiAgentMovementFixtureHardeningPathfindingPerformed: multiAgentMovementFixtureHardeningReport?.summary.pathfindingPerformed,
            multiAgentMovementFixtureHardeningReplanningPerformed: multiAgentMovementFixtureHardeningReport?.summary.replanningPerformed,
            multiAgentMovementFixtureHardeningPhysicsPerformed: multiAgentMovementFixtureHardeningReport?.summary.physicsPerformed,
            multiAgentMovementFixtureHardeningMutationPerformed: multiAgentMovementFixtureHardeningReport?.summary.mutationPerformed,
            multiAgentMovementFixtureHardeningSuccess: multiAgentMovementFixtureHardeningSuccess,
            multiAgentLiveCollisionIntentCases: multiAgentLiveCollisionIntentReport?.summary.cases,
            multiAgentLiveCollisionIntentPassed: multiAgentLiveCollisionIntentReport?.summary.passed,
            multiAgentLiveCollisionIntentFailed: multiAgentLiveCollisionIntentReport?.summary.failed,
            multiAgentLiveCollisionIntentAgentCount: multiAgentLiveCollisionIntentReport?.summary.agentCountTotal,
            multiAgentLiveCollisionIntentIntentCount: multiAgentLiveCollisionIntentReport?.summary.intentCountTotal,
            multiAgentLiveCollisionIntentApproved: multiAgentLiveCollisionIntentReport?.summary.approvedTotal,
            multiAgentLiveCollisionIntentDenied: multiAgentLiveCollisionIntentReport?.summary.deniedTotal,
            multiAgentLiveCollisionIntentOccupableDestinations: multiAgentLiveCollisionIntentReport?.summary.occupableDestinations,
            multiAgentLiveCollisionIntentNonOccupableDestinations: multiAgentLiveCollisionIntentReport?.summary.nonOccupableDestinations,
            multiAgentLiveCollisionIntentCollisionDenied: multiAgentLiveCollisionIntentReport?.summary.collisionDenied,
            multiAgentLiveCollisionIntentSameDestinationConflicts: multiAgentLiveCollisionIntentReport?.summary.sameDestinationConflicts,
            multiAgentLiveCollisionIntentSourceMismatch: multiAgentLiveCollisionIntentReport?.summary.sourceMismatch,
            multiAgentLiveCollisionIntentInvalidEdges: multiAgentLiveCollisionIntentReport?.summary.invalidEdges,
            multiAgentLiveCollisionIntentStaleIntent: multiAgentLiveCollisionIntentReport?.summary.staleIntent,
            multiAgentLiveCollisionIntentWorldUsed: multiAgentLiveCollisionIntentReport?.summary.worldUsed,
            multiAgentLiveCollisionIntentLiveCollisionRead: multiAgentLiveCollisionIntentReport?.summary.liveCollisionRead,
            multiAgentLiveCollisionIntentDisplacementApplied: multiAgentLiveCollisionIntentReport?.summary.displacementApplied,
            multiAgentLiveCollisionIntentPhysicalMovementApplied: multiAgentLiveCollisionIntentReport?.summary.physicalMovementApplied,
            multiAgentLiveCollisionIntentRouteFollowingApplied: multiAgentLiveCollisionIntentReport?.summary.routeFollowingApplied,
            multiAgentLiveCollisionIntentPathfindingPerformed: multiAgentLiveCollisionIntentReport?.summary.pathfindingPerformed,
            multiAgentLiveCollisionIntentReplanningPerformed: multiAgentLiveCollisionIntentReport?.summary.replanningPerformed,
            multiAgentLiveCollisionIntentPhysicsPerformed: multiAgentLiveCollisionIntentReport?.summary.physicsPerformed,
            multiAgentLiveCollisionIntentMutationPerformed: multiAgentLiveCollisionIntentReport?.summary.mutationPerformed,
            multiAgentLiveCollisionIntentSuccess: multiAgentLiveCollisionIntentSuccess,
            multiAgentApprovedPhysicalMovementCases: multiAgentApprovedPhysicalMovementReport?.summary.cases,
            multiAgentApprovedPhysicalMovementPassed: multiAgentApprovedPhysicalMovementReport?.summary.passed,
            multiAgentApprovedPhysicalMovementFailed: multiAgentApprovedPhysicalMovementReport?.summary.failed,
            multiAgentApprovedPhysicalMovementAgentCount: multiAgentApprovedPhysicalMovementReport?.summary.agentCountTotal,
            multiAgentApprovedPhysicalMovementIntentCount: multiAgentApprovedPhysicalMovementReport?.summary.intentCountTotal,
            multiAgentApprovedPhysicalMovementApproved: multiAgentApprovedPhysicalMovementReport?.summary.approvedTotal,
            multiAgentApprovedPhysicalMovementDenied: multiAgentApprovedPhysicalMovementReport?.summary.deniedTotal,
            multiAgentApprovedPhysicalMovementDisplacementsApplied: multiAgentApprovedPhysicalMovementReport?.summary.displacementsApplied,
            multiAgentApprovedPhysicalMovementOccupableDestinations: multiAgentApprovedPhysicalMovementReport?.summary.occupableDestinations,
            multiAgentApprovedPhysicalMovementNonOccupableDestinations: multiAgentApprovedPhysicalMovementReport?.summary.nonOccupableDestinations,
            multiAgentApprovedPhysicalMovementDivergenceBeforeMax: multiAgentApprovedPhysicalMovementReport?.summary.divergenceBeforeMax,
            multiAgentApprovedPhysicalMovementDivergenceAfterMax: multiAgentApprovedPhysicalMovementReport?.summary.divergenceAfterMax,
            multiAgentApprovedPhysicalMovementWorldUsed: multiAgentApprovedPhysicalMovementReport?.summary.worldUsed,
            multiAgentApprovedPhysicalMovementLiveCollisionRead: multiAgentApprovedPhysicalMovementReport?.summary.liveCollisionRead,
            multiAgentApprovedPhysicalMovementPhysicalMovementApplied: multiAgentApprovedPhysicalMovementReport?.summary.physicalMovementApplied,
            multiAgentApprovedPhysicalMovementRouteFollowingApplied: multiAgentApprovedPhysicalMovementReport?.summary.routeFollowingApplied,
            multiAgentApprovedPhysicalMovementPathfindingPerformed: multiAgentApprovedPhysicalMovementReport?.summary.pathfindingPerformed,
            multiAgentApprovedPhysicalMovementReplanningPerformed: multiAgentApprovedPhysicalMovementReport?.summary.replanningPerformed,
            multiAgentApprovedPhysicalMovementPhysicsPerformed: multiAgentApprovedPhysicalMovementReport?.summary.physicsPerformed,
            multiAgentApprovedPhysicalMovementTerrainMutationPerformed: multiAgentApprovedPhysicalMovementReport?.summary.terrainMutationPerformed,
            multiAgentApprovedPhysicalMovementWorldMutationPerformed: multiAgentApprovedPhysicalMovementReport?.summary.worldMutationPerformed,
            multiAgentApprovedPhysicalMovementSuccess: multiAgentApprovedPhysicalMovementSuccess,
            multiAgentMovementHardeningCases: multiAgentMovementHardeningReport?.summary.cases,
            multiAgentMovementHardeningPassed: multiAgentMovementHardeningReport?.summary.passed,
            multiAgentMovementHardeningFailed: multiAgentMovementHardeningReport?.summary.failed,
            multiAgentMovementHardeningAgentCount: multiAgentMovementHardeningReport?.summary.agentCountTotal,
            multiAgentMovementHardeningIntentCount: multiAgentMovementHardeningReport?.summary.intentCountTotal,
            multiAgentMovementHardeningApproved: multiAgentMovementHardeningReport?.summary.approvedTotal,
            multiAgentMovementHardeningDenied: multiAgentMovementHardeningReport?.summary.deniedTotal,
            multiAgentMovementHardeningDisplacementsApplied: multiAgentMovementHardeningReport?.summary.displacementsApplied,
            multiAgentMovementHardeningOccupableDestinations: multiAgentMovementHardeningReport?.summary.occupableDestinations,
            multiAgentMovementHardeningNonOccupableDestinations: multiAgentMovementHardeningReport?.summary.nonOccupableDestinations,
            multiAgentMovementHardeningCollisionDenied: multiAgentMovementHardeningReport?.summary.collisionDenied,
            multiAgentMovementHardeningSameDestinationConflicts: multiAgentMovementHardeningReport?.summary.sameDestinationConflicts,
            multiAgentMovementHardeningSwapConflicts: multiAgentMovementHardeningReport?.summary.swapConflicts,
            multiAgentMovementHardeningSourceMismatch: multiAgentMovementHardeningReport?.summary.sourceMismatch,
            multiAgentMovementHardeningStaleIntent: multiAgentMovementHardeningReport?.summary.staleIntent,
            multiAgentMovementHardeningInvalidEdges: multiAgentMovementHardeningReport?.summary.invalidEdges,
            multiAgentMovementHardeningDivergenceDenied: multiAgentMovementHardeningReport?.summary.divergenceDenied,
            multiAgentMovementHardeningStaleCollision: multiAgentMovementHardeningReport?.summary.staleCollision,
            multiAgentMovementHardeningPartialApprovalCases: multiAgentMovementHardeningReport?.summary.partialApprovalCases,
            multiAgentMovementHardeningAllDeniedCases: multiAgentMovementHardeningReport?.summary.allDeniedCases,
            multiAgentMovementHardeningMaxAgentsExceeded: multiAgentMovementHardeningReport?.summary.maxAgentsExceeded,
            multiAgentMovementHardeningDivergenceBeforeMax: multiAgentMovementHardeningReport?.summary.divergenceBeforeMax,
            multiAgentMovementHardeningDivergenceAfterMax: multiAgentMovementHardeningReport?.summary.divergenceAfterMax,
            multiAgentMovementHardeningWorldUsed: multiAgentMovementHardeningReport?.summary.worldUsed,
            multiAgentMovementHardeningLiveCollisionRead: multiAgentMovementHardeningReport?.summary.liveCollisionRead,
            multiAgentMovementHardeningPhysicalMovementApplied: multiAgentMovementHardeningReport?.summary.physicalMovementApplied,
            multiAgentMovementHardeningRouteFollowingApplied: multiAgentMovementHardeningReport?.summary.routeFollowingApplied,
            multiAgentMovementHardeningPathfindingPerformed: multiAgentMovementHardeningReport?.summary.pathfindingPerformed,
            multiAgentMovementHardeningReplanningPerformed: multiAgentMovementHardeningReport?.summary.replanningPerformed,
            multiAgentMovementHardeningPhysicsPerformed: multiAgentMovementHardeningReport?.summary.physicsPerformed,
            multiAgentMovementHardeningTerrainMutationPerformed: multiAgentMovementHardeningReport?.summary.terrainMutationPerformed,
            multiAgentMovementHardeningWorldMutationPerformed: multiAgentMovementHardeningReport?.summary.worldMutationPerformed,
            multiAgentMovementHardeningSuccess: multiAgentMovementHardeningSuccess,
            multiAgentMovementTickFixtureInputs: multiAgentMovementTickFixtureReport.map { _ in 1 },
            multiAgentMovementTickFixtureAgents: multiAgentMovementTickFixtureReport?.summary.agentCount,
            multiAgentMovementTickFixturePhysicalPositions: multiAgentMovementTickFixtureReport?.summary.physicalPositionCount,
            multiAgentMovementTickFixtureIntents: multiAgentMovementTickFixtureReport?.summary.intentCount,
            multiAgentMovementTickFixtureResolutions: multiAgentMovementTickFixtureReport?.summary.resolutions,
            multiAgentMovementTickFixtureFeedback: multiAgentMovementTickFixtureReport?.summary.feedbackCount,
            multiAgentMovementTickFixtureApproved: multiAgentMovementTickFixtureReport?.summary.approved,
            multiAgentMovementTickFixtureDenied: multiAgentMovementTickFixtureReport?.summary.denied,
            multiAgentMovementTickFixtureDisplacementsApplied: multiAgentMovementTickFixtureReport?.summary.displacementsApplied,
            multiAgentMovementTickFixtureSameDestinationConflicts: multiAgentMovementTickFixtureReport?.summary.sameDestinationConflicts,
            multiAgentMovementTickFixtureInvalidEdges: multiAgentMovementTickFixtureReport?.summary.invalidEdges,
            multiAgentMovementTickFixtureWorldUsed: multiAgentMovementTickFixtureReport?.summary.worldUsed,
            multiAgentMovementTickFixtureLiveCollisionRead: multiAgentMovementTickFixtureReport?.summary.liveCollisionRead,
            multiAgentMovementTickFixturePhysicalMovementApplied: multiAgentMovementTickFixtureReport?.summary.physicalMovementApplied,
            multiAgentMovementTickFixtureRouteFollowingApplied: multiAgentMovementTickFixtureReport?.summary.routeFollowingApplied,
            multiAgentMovementTickFixturePathfindingPerformed: multiAgentMovementTickFixtureReport?.summary.pathfindingPerformed,
            multiAgentMovementTickFixtureReplanningPerformed: multiAgentMovementTickFixtureReport?.summary.replanningPerformed,
            multiAgentMovementTickFixtureAvoidancePerformed: multiAgentMovementTickFixtureReport?.summary.avoidancePerformed,
            multiAgentMovementTickFixtureReservationRuntimeUsed: multiAgentMovementTickFixtureReport?.summary.reservationRuntimeUsed,
            multiAgentMovementTickFixturePhysicsPerformed: multiAgentMovementTickFixtureReport?.summary.physicsPerformed,
            multiAgentMovementTickFixtureMutationPerformed: multiAgentMovementTickFixtureReport?.summary.mutationPerformed,
            multiAgentMovementTickFixtureSuccess: multiAgentMovementTickFixtureSuccess,
            multiAgentMovementTickLiveReadonlyInputs: multiAgentMovementTickLiveReadonlyReport.map { _ in 1 },
            multiAgentMovementTickLiveReadonlyAgents: multiAgentMovementTickLiveReadonlyReport?.summary.agentCount,
            multiAgentMovementTickLiveReadonlyPhysicalPositions: multiAgentMovementTickLiveReadonlyReport?.summary.physicalPositionCount,
            multiAgentMovementTickLiveReadonlyIntents: multiAgentMovementTickLiveReadonlyReport?.summary.intentCount,
            multiAgentMovementTickLiveReadonlyResolutions: multiAgentMovementTickLiveReadonlyReport?.summary.resolutions,
            multiAgentMovementTickLiveReadonlyFeedback: multiAgentMovementTickLiveReadonlyReport?.summary.feedbackCount,
            multiAgentMovementTickLiveReadonlyApproved: multiAgentMovementTickLiveReadonlyReport?.summary.approved,
            multiAgentMovementTickLiveReadonlyDenied: multiAgentMovementTickLiveReadonlyReport?.summary.denied,
            multiAgentMovementTickLiveReadonlyOccupableDestinations: multiAgentMovementTickLiveReadonlyReport?.summary.occupableDestinations,
            multiAgentMovementTickLiveReadonlyNonOccupableDestinations: multiAgentMovementTickLiveReadonlyReport?.summary.nonOccupableDestinations,
            multiAgentMovementTickLiveReadonlyCollisionDenied: multiAgentMovementTickLiveReadonlyReport?.summary.collisionDenied,
            multiAgentMovementTickLiveReadonlySourceMismatch: multiAgentMovementTickLiveReadonlyReport?.summary.sourceMismatch,
            multiAgentMovementTickLiveReadonlyInvalidEdges: multiAgentMovementTickLiveReadonlyReport?.summary.invalidEdges,
            multiAgentMovementTickLiveReadonlyStaleIntent: multiAgentMovementTickLiveReadonlyReport?.summary.staleIntent,
            multiAgentMovementTickLiveReadonlyDisplacementsApplied: multiAgentMovementTickLiveReadonlyReport?.summary.displacementsApplied,
            multiAgentMovementTickLiveReadonlyWorldUsed: multiAgentMovementTickLiveReadonlyReport?.summary.worldUsed,
            multiAgentMovementTickLiveReadonlyLiveCollisionRead: multiAgentMovementTickLiveReadonlyReport?.summary.liveCollisionRead,
            multiAgentMovementTickLiveReadonlyPhysicalMovementApplied: multiAgentMovementTickLiveReadonlyReport?.summary.physicalMovementApplied,
            multiAgentMovementTickLiveReadonlyRouteFollowingApplied: multiAgentMovementTickLiveReadonlyReport?.summary.routeFollowingApplied,
            multiAgentMovementTickLiveReadonlyPathfindingPerformed: multiAgentMovementTickLiveReadonlyReport?.summary.pathfindingPerformed,
            multiAgentMovementTickLiveReadonlyReplanningPerformed: multiAgentMovementTickLiveReadonlyReport?.summary.replanningPerformed,
            multiAgentMovementTickLiveReadonlyAvoidancePerformed: multiAgentMovementTickLiveReadonlyReport?.summary.avoidancePerformed,
            multiAgentMovementTickLiveReadonlyReservationRuntimeUsed: multiAgentMovementTickLiveReadonlyReport?.summary.reservationRuntimeUsed,
            multiAgentMovementTickLiveReadonlyPhysicsPerformed: multiAgentMovementTickLiveReadonlyReport?.summary.physicsPerformed,
            multiAgentMovementTickLiveReadonlyMutationPerformed: multiAgentMovementTickLiveReadonlyReport?.summary.mutationPerformed,
            multiAgentMovementTickLiveReadonlySuccess: multiAgentMovementTickLiveReadonlySuccess,
            multiAgentMovementTickApprovedApplicationInputs: multiAgentMovementTickApprovedApplicationReport.map { _ in 1 },
            multiAgentMovementTickApprovedApplicationAgents: multiAgentMovementTickApprovedApplicationReport?.summary.agentCount,
            multiAgentMovementTickApprovedApplicationPhysicalPositions: multiAgentMovementTickApprovedApplicationReport?.summary.physicalPositionCount,
            multiAgentMovementTickApprovedApplicationIntents: multiAgentMovementTickApprovedApplicationReport?.summary.intentCount,
            multiAgentMovementTickApprovedApplicationResolutions: multiAgentMovementTickApprovedApplicationReport?.summary.resolutions,
            multiAgentMovementTickApprovedApplicationFeedback: multiAgentMovementTickApprovedApplicationReport?.summary.feedbackCount,
            multiAgentMovementTickApprovedApplicationApproved: multiAgentMovementTickApprovedApplicationReport?.summary.approved,
            multiAgentMovementTickApprovedApplicationDenied: multiAgentMovementTickApprovedApplicationReport?.summary.denied,
            multiAgentMovementTickApprovedApplicationOccupableDestinations: multiAgentMovementTickApprovedApplicationReport?.summary.occupableDestinations,
            multiAgentMovementTickApprovedApplicationNonOccupableDestinations: multiAgentMovementTickApprovedApplicationReport?.summary.nonOccupableDestinations,
            multiAgentMovementTickApprovedApplicationDisplacementsApplied: multiAgentMovementTickApprovedApplicationReport?.summary.displacementsApplied,
            multiAgentMovementTickApprovedApplicationDivergenceBeforeMax: multiAgentMovementTickApprovedApplicationReport?.summary.divergenceBeforeMax,
            multiAgentMovementTickApprovedApplicationDivergenceAfterMax: multiAgentMovementTickApprovedApplicationReport?.summary.divergenceAfterMax,
            multiAgentMovementTickApprovedApplicationWorldUsed: multiAgentMovementTickApprovedApplicationReport?.summary.worldUsed,
            multiAgentMovementTickApprovedApplicationLiveCollisionRead: multiAgentMovementTickApprovedApplicationReport?.summary.liveCollisionRead,
            multiAgentMovementTickApprovedApplicationPhysicalMovementApplied: multiAgentMovementTickApprovedApplicationReport?.summary.physicalMovementApplied,
            multiAgentMovementTickApprovedApplicationRouteFollowingApplied: multiAgentMovementTickApprovedApplicationReport?.summary.routeFollowingApplied,
            multiAgentMovementTickApprovedApplicationPathfindingPerformed: multiAgentMovementTickApprovedApplicationReport?.summary.pathfindingPerformed,
            multiAgentMovementTickApprovedApplicationReplanningPerformed: multiAgentMovementTickApprovedApplicationReport?.summary.replanningPerformed,
            multiAgentMovementTickApprovedApplicationAvoidancePerformed: multiAgentMovementTickApprovedApplicationReport?.summary.avoidancePerformed,
            multiAgentMovementTickApprovedApplicationReservationRuntimeUsed: multiAgentMovementTickApprovedApplicationReport?.summary.reservationRuntimeUsed,
            multiAgentMovementTickApprovedApplicationPhysicsPerformed: multiAgentMovementTickApprovedApplicationReport?.summary.physicsPerformed,
            multiAgentMovementTickApprovedApplicationTerrainMutationPerformed: multiAgentMovementTickApprovedApplicationReport?.summary.terrainMutationPerformed,
            multiAgentMovementTickApprovedApplicationWorldMutationPerformed: multiAgentMovementTickApprovedApplicationReport?.summary.worldMutationPerformed,
            multiAgentMovementTickApprovedApplicationSuccess: multiAgentMovementTickApprovedApplicationSuccess,
            multiAgentMovementTickHardeningCases: multiAgentMovementTickHardeningReport?.summary.cases,
            multiAgentMovementTickHardeningPassed: multiAgentMovementTickHardeningReport?.summary.passed,
            multiAgentMovementTickHardeningFailed: multiAgentMovementTickHardeningReport?.summary.failed,
            multiAgentMovementTickHardeningTicks: multiAgentMovementTickHardeningReport?.summary.tickCount,
            multiAgentMovementTickHardeningAgents: multiAgentMovementTickHardeningReport?.summary.agentCountTotal,
            multiAgentMovementTickHardeningIntents: multiAgentMovementTickHardeningReport?.summary.intentCountTotal,
            multiAgentMovementTickHardeningResolutions: multiAgentMovementTickHardeningReport?.summary.resolutionCountTotal,
            multiAgentMovementTickHardeningFeedback: multiAgentMovementTickHardeningReport?.summary.feedbackCountTotal,
            multiAgentMovementTickHardeningApproved: multiAgentMovementTickHardeningReport?.summary.approvedTotal,
            multiAgentMovementTickHardeningDenied: multiAgentMovementTickHardeningReport?.summary.deniedTotal,
            multiAgentMovementTickHardeningDisplacementsApplied: multiAgentMovementTickHardeningReport?.summary.displacementsApplied,
            multiAgentMovementTickHardeningOccupableDestinations: multiAgentMovementTickHardeningReport?.summary.occupableDestinations,
            multiAgentMovementTickHardeningNonOccupableDestinations: multiAgentMovementTickHardeningReport?.summary.nonOccupableDestinations,
            multiAgentMovementTickHardeningCollisionDenied: multiAgentMovementTickHardeningReport?.summary.collisionDenied,
            multiAgentMovementTickHardeningSameDestinationConflicts: multiAgentMovementTickHardeningReport?.summary.sameDestinationConflicts,
            multiAgentMovementTickHardeningSwapConflicts: multiAgentMovementTickHardeningReport?.summary.swapConflicts,
            multiAgentMovementTickHardeningSourceMismatch: multiAgentMovementTickHardeningReport?.summary.sourceMismatch,
            multiAgentMovementTickHardeningStaleIntent: multiAgentMovementTickHardeningReport?.summary.staleIntent,
            multiAgentMovementTickHardeningInvalidEdges: multiAgentMovementTickHardeningReport?.summary.invalidEdges,
            multiAgentMovementTickHardeningDivergenceDenied: multiAgentMovementTickHardeningReport?.summary.divergenceDenied,
            multiAgentMovementTickHardeningStaleCollision: multiAgentMovementTickHardeningReport?.summary.staleCollision,
            multiAgentMovementTickHardeningPartialApprovalCases: multiAgentMovementTickHardeningReport?.summary.partialApprovalCases,
            multiAgentMovementTickHardeningAllDeniedCases: multiAgentMovementTickHardeningReport?.summary.allDeniedCases,
            multiAgentMovementTickHardeningMaxAgentsExceeded: multiAgentMovementTickHardeningReport?.summary.maxAgentsExceeded,
            multiAgentMovementTickHardeningMovedFeedback: multiAgentMovementTickHardeningReport?.summary.movedFeedback,
            multiAgentMovementTickHardeningApprovedForMovementFeedback: multiAgentMovementTickHardeningReport?.summary.approvedForMovementFeedback,
            multiAgentMovementTickHardeningBlockedByCollisionFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByCollisionFeedback,
            multiAgentMovementTickHardeningBlockedByAgentConflictFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByAgentConflictFeedback,
            multiAgentMovementTickHardeningBlockedBySourceMismatchFeedback: multiAgentMovementTickHardeningReport?.summary.blockedBySourceMismatchFeedback,
            multiAgentMovementTickHardeningBlockedByDivergenceFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByDivergenceFeedback,
            multiAgentMovementTickHardeningBlockedByStaleIntentFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByStaleIntentFeedback,
            multiAgentMovementTickHardeningBlockedByInvalidEdgeFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByInvalidEdgeFeedback,
            multiAgentMovementTickHardeningBlockedByMaxAgentsFeedback: multiAgentMovementTickHardeningReport?.summary.blockedByMaxAgentsFeedback,
            multiAgentMovementTickHardeningDivergenceBeforeMax: multiAgentMovementTickHardeningReport?.summary.divergenceBeforeMax,
            multiAgentMovementTickHardeningDivergenceAfterMax: multiAgentMovementTickHardeningReport?.summary.divergenceAfterMax,
            multiAgentMovementTickHardeningWorldUsed: multiAgentMovementTickHardeningReport?.summary.worldUsed,
            multiAgentMovementTickHardeningLiveCollisionRead: multiAgentMovementTickHardeningReport?.summary.liveCollisionRead,
            multiAgentMovementTickHardeningPhysicalMovementApplied: multiAgentMovementTickHardeningReport?.summary.physicalMovementApplied,
            multiAgentMovementTickHardeningRouteFollowingApplied: multiAgentMovementTickHardeningReport?.summary.routeFollowingApplied,
            multiAgentMovementTickHardeningPathfindingPerformed: multiAgentMovementTickHardeningReport?.summary.pathfindingPerformed,
            multiAgentMovementTickHardeningReplanningPerformed: multiAgentMovementTickHardeningReport?.summary.replanningPerformed,
            multiAgentMovementTickHardeningAvoidancePerformed: multiAgentMovementTickHardeningReport?.summary.avoidancePerformed,
            multiAgentMovementTickHardeningReservationRuntimeUsed: multiAgentMovementTickHardeningReport?.summary.reservationRuntimeUsed,
            multiAgentMovementTickHardeningPhysicsPerformed: multiAgentMovementTickHardeningReport?.summary.physicsPerformed,
            multiAgentMovementTickHardeningTerrainMutationPerformed: multiAgentMovementTickHardeningReport?.summary.terrainMutationPerformed,
            multiAgentMovementTickHardeningWorldMutationPerformed: multiAgentMovementTickHardeningReport?.summary.worldMutationPerformed,
            multiAgentMovementTickHardeningSuccess: multiAgentMovementTickHardeningSuccess,
            agentIntentProductionFixtureAgentsObserved: agentIntentProductionFixtureReport?.summary.agentsObserved,
            agentIntentProductionFixtureContexts: agentIntentProductionFixtureReport?.summary.contexts,
            agentIntentProductionFixtureProposals: agentIntentProductionFixtureReport?.summary.proposals,
            agentIntentProductionFixtureAcceptedIntents: agentIntentProductionFixtureReport?.summary.acceptedIntents,
            agentIntentProductionFixtureRejectedProposals: agentIntentProductionFixtureReport?.summary.rejectedProposals,
            agentIntentProductionFixtureNoIntent: agentIntentProductionFixtureReport?.summary.noIntent,
            agentIntentProductionFixtureInvalidContext: agentIntentProductionFixtureReport?.summary.invalidContext,
            agentIntentProductionFixtureDuplicateAgentContexts: agentIntentProductionFixtureReport?.summary.duplicateAgentContexts,
            agentIntentProductionFixtureInvalidOneEdgeProposals: agentIntentProductionFixtureReport?.summary.invalidOneEdgeProposals,
            agentIntentProductionFixtureAcceptedMoveEast: agentIntentProductionFixtureReport?.summary.acceptedMoveEast,
            agentIntentProductionFixtureAcceptedMoveWest: agentIntentProductionFixtureReport?.summary.acceptedMoveWest,
            agentIntentProductionFixtureAcceptedMoveNorth: agentIntentProductionFixtureReport?.summary.acceptedMoveNorth,
            agentIntentProductionFixtureAcceptedMoveSouth: agentIntentProductionFixtureReport?.summary.acceptedMoveSouth,
            agentIntentProductionFixtureWorldUsed: agentIntentProductionFixtureReport?.summary.worldUsed,
            agentIntentProductionFixtureCollisionRead: agentIntentProductionFixtureReport?.summary.collisionRead,
            agentIntentProductionFixtureMovementApplied: agentIntentProductionFixtureReport?.summary.movementApplied,
            agentIntentProductionFixtureFeedbackConsumed: agentIntentProductionFixtureReport?.summary.feedbackConsumed,
            agentIntentProductionFixtureMemoryUpdated: agentIntentProductionFixtureReport?.summary.memoryUpdated,
            agentIntentProductionFixtureGoalChanged: agentIntentProductionFixtureReport?.summary.goalChanged,
            agentIntentProductionFixturePathfindingPerformed: agentIntentProductionFixtureReport?.summary.pathfindingPerformed,
            agentIntentProductionFixtureReplanningPerformed: agentIntentProductionFixtureReport?.summary.replanningPerformed,
            agentIntentProductionFixtureAvoidancePerformed: agentIntentProductionFixtureReport?.summary.avoidancePerformed,
            agentIntentProductionFixtureReservationRuntimeUsed: agentIntentProductionFixtureReport?.summary.reservationRuntimeUsed,
            agentIntentProductionFixtureMutationPerformed: agentIntentProductionFixtureReport?.summary.mutationPerformed,
            agentIntentProductionFixtureSuccess: agentIntentProductionFixtureSuccess,
            agentIntentProductionHardeningCases: agentIntentProductionHardeningReport?.summary.cases,
            agentIntentProductionHardeningPassed: agentIntentProductionHardeningReport?.summary.passed,
            agentIntentProductionHardeningFailed: agentIntentProductionHardeningReport?.summary.failed,
            agentIntentProductionHardeningContexts: agentIntentProductionHardeningReport?.summary.contextsTotal,
            agentIntentProductionHardeningProposals: agentIntentProductionHardeningReport?.summary.proposalsTotal,
            agentIntentProductionHardeningAcceptedIntents: agentIntentProductionHardeningReport?.summary.acceptedIntentsTotal,
            agentIntentProductionHardeningRejectedProposals: agentIntentProductionHardeningReport?.summary.rejectedProposalsTotal,
            agentIntentProductionHardeningNoIntent: agentIntentProductionHardeningReport?.summary.noIntentTotal,
            agentIntentProductionHardeningInvalidContext: agentIntentProductionHardeningReport?.summary.invalidContextTotal,
            agentIntentProductionHardeningDuplicateAgentContexts: agentIntentProductionHardeningReport?.summary.duplicateAgentContextsTotal,
            agentIntentProductionHardeningDuplicateProposals: agentIntentProductionHardeningReport?.summary.duplicateProposalsTotal,
            agentIntentProductionHardeningInvalidOneEdgeProposals: agentIntentProductionHardeningReport?.summary.invalidOneEdgeProposalsTotal,
            agentIntentProductionHardeningStaleProposals: agentIntentProductionHardeningReport?.summary.staleProposalsTotal,
            agentIntentProductionHardeningWrongSourceProposals: agentIntentProductionHardeningReport?.summary.wrongSourceProposalsTotal,
            agentIntentProductionHardeningMaxProposalsExceeded: agentIntentProductionHardeningReport?.summary.maxProposalsExceededTotal,
            agentIntentProductionHardeningAcceptedMoveEast: agentIntentProductionHardeningReport?.summary.acceptedMoveEast,
            agentIntentProductionHardeningAcceptedMoveWest: agentIntentProductionHardeningReport?.summary.acceptedMoveWest,
            agentIntentProductionHardeningAcceptedMoveNorth: agentIntentProductionHardeningReport?.summary.acceptedMoveNorth,
            agentIntentProductionHardeningAcceptedMoveSouth: agentIntentProductionHardeningReport?.summary.acceptedMoveSouth,
            agentIntentProductionHardeningWorldUsed: agentIntentProductionHardeningReport?.summary.worldUsed,
            agentIntentProductionHardeningCollisionRead: agentIntentProductionHardeningReport?.summary.collisionRead,
            agentIntentProductionHardeningMovementApplied: agentIntentProductionHardeningReport?.summary.movementApplied,
            agentIntentProductionHardeningFeedbackConsumed: agentIntentProductionHardeningReport?.summary.feedbackConsumed,
            agentIntentProductionHardeningMemoryUpdated: agentIntentProductionHardeningReport?.summary.memoryUpdated,
            agentIntentProductionHardeningGoalChanged: agentIntentProductionHardeningReport?.summary.goalChanged,
            agentIntentProductionHardeningPathfindingPerformed: agentIntentProductionHardeningReport?.summary.pathfindingPerformed,
            agentIntentProductionHardeningReplanningPerformed: agentIntentProductionHardeningReport?.summary.replanningPerformed,
            agentIntentProductionHardeningAvoidancePerformed: agentIntentProductionHardeningReport?.summary.avoidancePerformed,
            agentIntentProductionHardeningReservationRuntimeUsed: agentIntentProductionHardeningReport?.summary.reservationRuntimeUsed,
            agentIntentProductionHardeningPhysicsPerformed: agentIntentProductionHardeningReport?.summary.physicsPerformed,
            agentIntentProductionHardeningMutationPerformed: agentIntentProductionHardeningReport?.summary.mutationPerformed,
            agentIntentProductionHardeningSuccess: agentIntentProductionHardeningSuccess,
            agentIntentToTickFixtureContexts: agentIntentToTickFixtureReport?.summary.contexts,
            agentIntentToTickFixtureProposals: agentIntentToTickFixtureReport?.summary.proposals,
            agentIntentToTickFixtureAcceptedIntents: agentIntentToTickFixtureReport?.summary.acceptedIntents,
            agentIntentToTickFixtureRejectedProposals: agentIntentToTickFixtureReport?.summary.rejectedProposals,
            agentIntentToTickFixtureNoIntent: agentIntentToTickFixtureReport?.intentProduction.summary.noIntent,
            agentIntentToTickFixtureInvalidOneEdgeProposals: agentIntentToTickFixtureReport?.intentProduction.summary.invalidOneEdgeProposals,
            agentIntentToTickFixtureTickAgents: agentIntentToTickFixtureReport?.summary.tickAgents,
            agentIntentToTickFixtureTickIntents: agentIntentToTickFixtureReport?.summary.tickIntents,
            agentIntentToTickFixtureTickResolutions: agentIntentToTickFixtureReport?.summary.tickResolutions,
            agentIntentToTickFixtureTickFeedback: agentIntentToTickFixtureReport?.summary.tickFeedback,
            agentIntentToTickFixtureTickApproved: agentIntentToTickFixtureReport?.summary.tickApproved,
            agentIntentToTickFixtureTickDenied: agentIntentToTickFixtureReport?.summary.tickDenied,
            agentIntentToTickFixtureSameDestinationConflicts: agentIntentToTickFixtureReport?.summary.sameDestinationConflicts,
            agentIntentToTickFixtureDisplacementsApplied: agentIntentToTickFixtureReport?.summary.displacementsApplied,
            agentIntentToTickFixtureProductionAcceptedSameDestination: agentIntentToTickFixtureReport?.summary.productionAcceptedSameDestination,
            agentIntentToTickFixtureTickResolvedSameDestination: agentIntentToTickFixtureReport?.summary.tickResolvedSameDestination,
            agentIntentToTickFixtureWorldUsed: agentIntentToTickFixtureReport?.summary.worldUsed,
            agentIntentToTickFixtureCollisionRead: agentIntentToTickFixtureReport?.summary.collisionRead,
            agentIntentToTickFixtureMovementApplied: agentIntentToTickFixtureReport?.summary.movementApplied,
            agentIntentToTickFixtureFeedbackConsumed: agentIntentToTickFixtureReport?.summary.feedbackConsumed,
            agentIntentToTickFixtureMemoryUpdated: agentIntentToTickFixtureReport?.summary.memoryUpdated,
            agentIntentToTickFixtureGoalChanged: agentIntentToTickFixtureReport?.summary.goalChanged,
            agentIntentToTickFixturePathfindingPerformed: agentIntentToTickFixtureReport?.summary.pathfindingPerformed,
            agentIntentToTickFixtureReplanningPerformed: agentIntentToTickFixtureReport?.summary.replanningPerformed,
            agentIntentToTickFixtureAvoidancePerformed: agentIntentToTickFixtureReport?.summary.avoidancePerformed,
            agentIntentToTickFixtureReservationRuntimeUsed: agentIntentToTickFixtureReport?.summary.reservationRuntimeUsed,
            agentIntentToTickFixturePhysicsPerformed: agentIntentToTickFixtureReport?.summary.physicsPerformed,
            agentIntentToTickFixtureMutationPerformed: agentIntentToTickFixtureReport?.summary.mutationPerformed,
            agentIntentToTickFixtureSuccess: agentIntentToTickFixtureSuccess,
            agentIntentToTickLiveReadonlyContexts: agentIntentToTickLiveReadonlyReport?.summary.contexts,
            agentIntentToTickLiveReadonlyProposals: agentIntentToTickLiveReadonlyReport?.summary.proposals,
            agentIntentToTickLiveReadonlyAcceptedIntents: agentIntentToTickLiveReadonlyReport?.summary.acceptedIntents,
            agentIntentToTickLiveReadonlyRejectedProposals: agentIntentToTickLiveReadonlyReport?.summary.rejectedProposals,
            agentIntentToTickLiveReadonlyNoIntent: agentIntentToTickLiveReadonlyReport?.intentProduction.summary.noIntent,
            agentIntentToTickLiveReadonlyInvalidOneEdgeProposals: agentIntentToTickLiveReadonlyReport?.intentProduction.summary.invalidOneEdgeProposals,
            agentIntentToTickLiveReadonlyTickAgents: agentIntentToTickLiveReadonlyReport?.summary.tickAgents,
            agentIntentToTickLiveReadonlyTickIntents: agentIntentToTickLiveReadonlyReport?.summary.tickIntents,
            agentIntentToTickLiveReadonlyTickResolutions: agentIntentToTickLiveReadonlyReport?.summary.tickResolutions,
            agentIntentToTickLiveReadonlyTickFeedback: agentIntentToTickLiveReadonlyReport?.summary.tickFeedback,
            agentIntentToTickLiveReadonlyTickApproved: agentIntentToTickLiveReadonlyReport?.summary.tickApproved,
            agentIntentToTickLiveReadonlyTickDenied: agentIntentToTickLiveReadonlyReport?.summary.tickDenied,
            agentIntentToTickLiveReadonlyOccupableDestinations: agentIntentToTickLiveReadonlyReport?.summary.occupableDestinations,
            agentIntentToTickLiveReadonlyNonOccupableDestinations: agentIntentToTickLiveReadonlyReport?.summary.nonOccupableDestinations,
            agentIntentToTickLiveReadonlyCollisionDenied: agentIntentToTickLiveReadonlyReport?.summary.collisionDenied,
            agentIntentToTickLiveReadonlyDisplacementsApplied: agentIntentToTickLiveReadonlyReport?.summary.displacementsApplied,
            agentIntentToTickLiveReadonlyProductionReadCollision: agentIntentToTickLiveReadonlyReport?.summary.productionReadCollision,
            agentIntentToTickLiveReadonlyTickReadCollision: agentIntentToTickLiveReadonlyReport?.summary.tickReadLiveCollision,
            agentIntentToTickLiveReadonlyWorldUsed: agentIntentToTickLiveReadonlyReport?.summary.worldUsed,
            agentIntentToTickLiveReadonlyCollisionRead: agentIntentToTickLiveReadonlyReport?.summary.collisionRead,
            agentIntentToTickLiveReadonlyMovementApplied: agentIntentToTickLiveReadonlyReport?.summary.movementApplied,
            agentIntentToTickLiveReadonlyFeedbackConsumed: agentIntentToTickLiveReadonlyReport?.summary.feedbackConsumed,
            agentIntentToTickLiveReadonlyMemoryUpdated: agentIntentToTickLiveReadonlyReport?.summary.memoryUpdated,
            agentIntentToTickLiveReadonlyGoalChanged: agentIntentToTickLiveReadonlyReport?.summary.goalChanged,
            agentIntentToTickLiveReadonlyPathfindingPerformed: agentIntentToTickLiveReadonlyReport?.summary.pathfindingPerformed,
            agentIntentToTickLiveReadonlyReplanningPerformed: agentIntentToTickLiveReadonlyReport?.summary.replanningPerformed,
            agentIntentToTickLiveReadonlyAvoidancePerformed: agentIntentToTickLiveReadonlyReport?.summary.avoidancePerformed,
            agentIntentToTickLiveReadonlyReservationRuntimeUsed: agentIntentToTickLiveReadonlyReport?.summary.reservationRuntimeUsed,
            agentIntentToTickLiveReadonlyPhysicsPerformed: agentIntentToTickLiveReadonlyReport?.summary.physicsPerformed,
            agentIntentToTickLiveReadonlyMutationPerformed: agentIntentToTickLiveReadonlyReport?.summary.mutationPerformed,
            agentIntentToTickLiveReadonlySuccess: agentIntentToTickLiveReadonlySuccess,
            agentIntentToTickApprovedApplicationContexts: agentIntentToTickApprovedApplicationReport?.summary.contexts,
            agentIntentToTickApprovedApplicationProposals: agentIntentToTickApprovedApplicationReport?.summary.proposals,
            agentIntentToTickApprovedApplicationAcceptedIntents: agentIntentToTickApprovedApplicationReport?.summary.acceptedIntents,
            agentIntentToTickApprovedApplicationRejectedProposals: agentIntentToTickApprovedApplicationReport?.summary.rejectedProposals,
            agentIntentToTickApprovedApplicationNoIntent: agentIntentToTickApprovedApplicationReport?.intentProduction.summary.noIntent,
            agentIntentToTickApprovedApplicationInvalidOneEdgeProposals: agentIntentToTickApprovedApplicationReport?.intentProduction.summary.invalidOneEdgeProposals,
            agentIntentToTickApprovedApplicationTickAgents: agentIntentToTickApprovedApplicationReport?.summary.tickAgents,
            agentIntentToTickApprovedApplicationTickIntents: agentIntentToTickApprovedApplicationReport?.summary.tickIntents,
            agentIntentToTickApprovedApplicationTickResolutions: agentIntentToTickApprovedApplicationReport?.summary.tickResolutions,
            agentIntentToTickApprovedApplicationTickFeedback: agentIntentToTickApprovedApplicationReport?.summary.tickFeedback,
            agentIntentToTickApprovedApplicationTickApproved: agentIntentToTickApprovedApplicationReport?.summary.tickApproved,
            agentIntentToTickApprovedApplicationTickDenied: agentIntentToTickApprovedApplicationReport?.summary.tickDenied,
            agentIntentToTickApprovedApplicationOccupableDestinations: agentIntentToTickApprovedApplicationReport?.summary.occupableDestinations,
            agentIntentToTickApprovedApplicationNonOccupableDestinations: agentIntentToTickApprovedApplicationReport?.summary.nonOccupableDestinations,
            agentIntentToTickApprovedApplicationCollisionDenied: agentIntentToTickApprovedApplicationReport?.summary.collisionDenied,
            agentIntentToTickApprovedApplicationDisplacementsApplied: agentIntentToTickApprovedApplicationReport?.summary.displacementsApplied,
            agentIntentToTickApprovedApplicationMovedFeedback: agentIntentToTickApprovedApplicationReport?.summary.movedFeedback,
            agentIntentToTickApprovedApplicationBlockedByCollisionFeedback: agentIntentToTickApprovedApplicationReport?.summary.blockedByCollisionFeedback,
            agentIntentToTickApprovedApplicationDivergenceBefore: agentIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceBefore,
            agentIntentToTickApprovedApplicationDivergenceAfter: agentIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceAfter,
            agentIntentToTickApprovedApplicationDeniedPositionsPreserved: agentIntentToTickApprovedApplicationReport?.summary.deniedPositionsPreserved,
            agentIntentToTickApprovedApplicationApprovedPositionsMoved: agentIntentToTickApprovedApplicationReport?.summary.approvedPositionsMoved,
            agentIntentToTickApprovedApplicationProductionReadCollision: agentIntentToTickApprovedApplicationReport?.summary.productionReadCollision,
            agentIntentToTickApprovedApplicationTickReadCollision: agentIntentToTickApprovedApplicationReport?.summary.tickReadLiveCollision,
            agentIntentToTickApprovedApplicationWorldUsed: agentIntentToTickApprovedApplicationReport?.summary.worldUsed,
            agentIntentToTickApprovedApplicationCollisionRead: agentIntentToTickApprovedApplicationReport?.summary.collisionRead,
            agentIntentToTickApprovedApplicationMovementApplied: agentIntentToTickApprovedApplicationReport?.summary.movementApplied,
            agentIntentToTickApprovedApplicationFeedbackConsumed: agentIntentToTickApprovedApplicationReport?.summary.feedbackConsumed,
            agentIntentToTickApprovedApplicationMemoryUpdated: agentIntentToTickApprovedApplicationReport?.summary.memoryUpdated,
            agentIntentToTickApprovedApplicationGoalChanged: agentIntentToTickApprovedApplicationReport?.summary.goalChanged,
            agentIntentToTickApprovedApplicationPathfindingPerformed: agentIntentToTickApprovedApplicationReport?.summary.pathfindingPerformed,
            agentIntentToTickApprovedApplicationReplanningPerformed: agentIntentToTickApprovedApplicationReport?.summary.replanningPerformed,
            agentIntentToTickApprovedApplicationAvoidancePerformed: agentIntentToTickApprovedApplicationReport?.summary.avoidancePerformed,
            agentIntentToTickApprovedApplicationReservationRuntimeUsed: agentIntentToTickApprovedApplicationReport?.summary.reservationRuntimeUsed,
            agentIntentToTickApprovedApplicationRouteFollowingApplied: agentIntentToTickApprovedApplicationReport?.summary.routeFollowingApplied,
            agentIntentToTickApprovedApplicationPhysicsPerformed: agentIntentToTickApprovedApplicationReport?.summary.physicsPerformed,
            agentIntentToTickApprovedApplicationMutationPerformed: agentIntentToTickApprovedApplicationReport?.summary.mutationPerformed,
            agentIntentToTickApprovedApplicationSuccess: agentIntentToTickApprovedApplicationSuccess,
            agentFeedbackConsumptionFixtureAgentsObserved: agentFeedbackConsumptionFixtureReport?.summary.agentsObserved,
            agentFeedbackConsumptionFixtureFeedbackObserved: agentFeedbackConsumptionFixtureReport?.summary.feedbackObserved,
            agentFeedbackConsumptionFixtureFeedbackAccepted: agentFeedbackConsumptionFixtureReport?.summary.feedbackAccepted,
            agentFeedbackConsumptionFixtureFeedbackIgnored: agentFeedbackConsumptionFixtureReport?.summary.feedbackIgnored,
            agentFeedbackConsumptionFixtureInvalidFeedback: agentFeedbackConsumptionFixtureReport?.summary.invalidFeedback,
            agentFeedbackConsumptionFixtureContextsProduced: agentFeedbackConsumptionFixtureReport?.summary.contextsProduced,
            agentFeedbackConsumptionFixtureMoved: agentFeedbackConsumptionFixtureReport?.summary.moved,
            agentFeedbackConsumptionFixtureApprovedForMovement: agentFeedbackConsumptionFixtureReport?.summary.approvedForMovement,
            agentFeedbackConsumptionFixtureBlockedByCollision: agentFeedbackConsumptionFixtureReport?.summary.blockedByCollision,
            agentFeedbackConsumptionFixtureBlockedByAgentConflict: agentFeedbackConsumptionFixtureReport?.summary.blockedByAgentConflict,
            agentFeedbackConsumptionFixtureBlockedBySourceMismatch: agentFeedbackConsumptionFixtureReport?.result.summary.blockedBySourceMismatch,
            agentFeedbackConsumptionFixtureBlockedByDivergence: agentFeedbackConsumptionFixtureReport?.result.summary.blockedByDivergence,
            agentFeedbackConsumptionFixtureBlockedByStaleIntent: agentFeedbackConsumptionFixtureReport?.result.summary.blockedByStaleIntent,
            agentFeedbackConsumptionFixtureBlockedByInvalidEdge: agentFeedbackConsumptionFixtureReport?.result.summary.blockedByInvalidEdge,
            agentFeedbackConsumptionFixtureBlockedByMaxAgents: agentFeedbackConsumptionFixtureReport?.result.summary.blockedByMaxAgents,
            agentFeedbackConsumptionFixtureDuplicateFeedback: agentFeedbackConsumptionFixtureReport?.summary.duplicateFeedback,
            agentFeedbackConsumptionFixtureMemoryUpdated: agentFeedbackConsumptionFixtureReport?.summary.memoryUpdated,
            agentFeedbackConsumptionFixtureGoalChanged: agentFeedbackConsumptionFixtureReport?.summary.goalChanged,
            agentFeedbackConsumptionFixturePathfindingPerformed: agentFeedbackConsumptionFixtureReport?.summary.pathfindingPerformed,
            agentFeedbackConsumptionFixtureReplanningPerformed: agentFeedbackConsumptionFixtureReport?.summary.replanningPerformed,
            agentFeedbackConsumptionFixtureAvoidancePerformed: agentFeedbackConsumptionFixtureReport?.summary.avoidancePerformed,
            agentFeedbackConsumptionFixtureReservationRuntimeUsed: agentFeedbackConsumptionFixtureReport?.summary.reservationRuntimeUsed,
            agentFeedbackConsumptionFixtureMovementApplied: agentFeedbackConsumptionFixtureReport?.summary.movementApplied,
            agentFeedbackConsumptionFixtureCollisionRead: agentFeedbackConsumptionFixtureReport?.summary.collisionRead,
            agentFeedbackConsumptionFixtureIntentProduced: agentFeedbackConsumptionFixtureReport?.summary.intentProduced,
            agentFeedbackConsumptionFixtureWorldUsed: agentFeedbackConsumptionFixtureReport?.summary.worldUsed,
            agentFeedbackConsumptionFixtureMutationPerformed: agentFeedbackConsumptionFixtureReport?.summary.mutationPerformed,
            agentFeedbackConsumptionFixtureSuccess: agentFeedbackConsumptionFixtureSuccess,
            agentFeedbackConsumptionHardeningCases: agentFeedbackConsumptionHardeningReport?.summary.cases,
            agentFeedbackConsumptionHardeningPassed: agentFeedbackConsumptionHardeningReport?.summary.passed,
            agentFeedbackConsumptionHardeningFailed: agentFeedbackConsumptionHardeningReport?.summary.failed,
            agentFeedbackConsumptionHardeningFeedbackObservedTotal: agentFeedbackConsumptionHardeningReport?.summary.feedbackObservedTotal,
            agentFeedbackConsumptionHardeningFeedbackAcceptedTotal: agentFeedbackConsumptionHardeningReport?.summary.feedbackAcceptedTotal,
            agentFeedbackConsumptionHardeningFeedbackIgnoredTotal: agentFeedbackConsumptionHardeningReport?.summary.feedbackIgnoredTotal,
            agentFeedbackConsumptionHardeningInvalidFeedbackTotal: agentFeedbackConsumptionHardeningReport?.summary.invalidFeedbackTotal,
            agentFeedbackConsumptionHardeningContextsProducedTotal: agentFeedbackConsumptionHardeningReport?.summary.contextsProducedTotal,
            agentFeedbackConsumptionHardeningDuplicateFeedbackTotal: agentFeedbackConsumptionHardeningReport?.summary.duplicateFeedbackTotal,
            agentFeedbackConsumptionHardeningMaxFeedbackExceededTotal: agentFeedbackConsumptionHardeningReport?.summary.maxFeedbackExceededTotal,
            agentFeedbackConsumptionHardeningTickMismatchFeedbackTotal: agentFeedbackConsumptionHardeningReport?.summary.tickMismatchFeedbackTotal,
            agentFeedbackConsumptionHardeningMovedTotal: agentFeedbackConsumptionHardeningReport?.summary.movedTotal,
            agentFeedbackConsumptionHardeningApprovedForMovementTotal: agentFeedbackConsumptionHardeningReport?.summary.approvedForMovementTotal,
            agentFeedbackConsumptionHardeningBlockedByCollisionTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByCollisionTotal,
            agentFeedbackConsumptionHardeningBlockedByAgentConflictTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByAgentConflictTotal,
            agentFeedbackConsumptionHardeningBlockedBySourceMismatchTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedBySourceMismatchTotal,
            agentFeedbackConsumptionHardeningBlockedByDivergenceTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByDivergenceTotal,
            agentFeedbackConsumptionHardeningBlockedByStaleIntentTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByStaleIntentTotal,
            agentFeedbackConsumptionHardeningBlockedByInvalidEdgeTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByInvalidEdgeTotal,
            agentFeedbackConsumptionHardeningBlockedByMaxAgentsTotal: agentFeedbackConsumptionHardeningReport?.summary.blockedByMaxAgentsTotal,
            agentFeedbackConsumptionHardeningMemoryUpdated: agentFeedbackConsumptionHardeningReport?.summary.memoryUpdated,
            agentFeedbackConsumptionHardeningGoalChanged: agentFeedbackConsumptionHardeningReport?.summary.goalChanged,
            agentFeedbackConsumptionHardeningPathfindingPerformed: agentFeedbackConsumptionHardeningReport?.summary.pathfindingPerformed,
            agentFeedbackConsumptionHardeningReplanningPerformed: agentFeedbackConsumptionHardeningReport?.summary.replanningPerformed,
            agentFeedbackConsumptionHardeningAvoidancePerformed: agentFeedbackConsumptionHardeningReport?.summary.avoidancePerformed,
            agentFeedbackConsumptionHardeningReservationRuntimeUsed: agentFeedbackConsumptionHardeningReport?.summary.reservationRuntimeUsed,
            agentFeedbackConsumptionHardeningMovementApplied: agentFeedbackConsumptionHardeningReport?.summary.movementApplied,
            agentFeedbackConsumptionHardeningCollisionRead: agentFeedbackConsumptionHardeningReport?.summary.collisionRead,
            agentFeedbackConsumptionHardeningIntentProduced: agentFeedbackConsumptionHardeningReport?.summary.intentProduced,
            agentFeedbackConsumptionHardeningWorldUsed: agentFeedbackConsumptionHardeningReport?.summary.worldUsed,
            agentFeedbackConsumptionHardeningMutationPerformed: agentFeedbackConsumptionHardeningReport?.summary.mutationPerformed,
            agentFeedbackConsumptionHardeningSuccess: agentFeedbackConsumptionHardeningSuccess,
            feedbackToAgentIntentContextFixtureFeedbackObserved: feedbackToAgentIntentContextFixtureReport?.summary.feedbackObserved,
            feedbackToAgentIntentContextFixtureFeedbackAccepted: feedbackToAgentIntentContextFixtureReport?.summary.feedbackAccepted,
            feedbackToAgentIntentContextFixtureFeedbackIgnored: feedbackToAgentIntentContextFixtureReport?.summary.feedbackIgnored,
            feedbackToAgentIntentContextFixtureInvalidFeedback: feedbackToAgentIntentContextFixtureReport?.summary.invalidFeedback,
            feedbackToAgentIntentContextFixtureContextsProduced: feedbackToAgentIntentContextFixtureReport?.summary.contextsProduced,
            feedbackToAgentIntentContextFixtureDuplicateFeedback: feedbackToAgentIntentContextFixtureReport?.summary.duplicateFeedback,
            feedbackToAgentIntentContextFixtureIntentContexts: feedbackToAgentIntentContextFixtureReport?.summary.intentContexts,
            feedbackToAgentIntentContextFixtureContextsWithFeedback: feedbackToAgentIntentContextFixtureReport?.summary.contextsWithFeedback,
            feedbackToAgentIntentContextFixtureContextsWithoutFeedback: feedbackToAgentIntentContextFixtureReport?.summary.contextsWithoutFeedback,
            feedbackToAgentIntentContextFixtureProposals: feedbackToAgentIntentContextFixtureReport?.summary.proposals,
            feedbackToAgentIntentContextFixtureAcceptedIntents: feedbackToAgentIntentContextFixtureReport?.summary.acceptedIntents,
            feedbackToAgentIntentContextFixtureRejectedProposals: feedbackToAgentIntentContextFixtureReport?.summary.rejectedProposals,
            feedbackToAgentIntentContextFixtureNoIntent: feedbackToAgentIntentContextFixtureReport?.summary.noIntent,
            feedbackToAgentIntentContextFixtureInvalidOneEdgeProposals: feedbackToAgentIntentContextFixtureReport?.summary.invalidOneEdgeProposals,
            feedbackToAgentIntentContextFixtureBehaviorChangedByFeedback: feedbackToAgentIntentContextFixtureReport?.summary.behaviorChangedByFeedback,
            feedbackToAgentIntentContextFixtureFeedbackUsedForDecision: feedbackToAgentIntentContextFixtureReport?.summary.feedbackUsedForDecision,
            feedbackToAgentIntentContextFixtureMovementApplied: feedbackToAgentIntentContextFixtureReport?.summary.movementApplied,
            feedbackToAgentIntentContextFixtureCollisionRead: feedbackToAgentIntentContextFixtureReport?.summary.collisionRead,
            feedbackToAgentIntentContextFixtureIntentProduced: feedbackToAgentIntentContextFixtureReport?.summary.intentProduced,
            feedbackToAgentIntentContextFixtureMemoryUpdated: feedbackToAgentIntentContextFixtureReport?.summary.memoryUpdated,
            feedbackToAgentIntentContextFixtureGoalChanged: feedbackToAgentIntentContextFixtureReport?.summary.goalChanged,
            feedbackToAgentIntentContextFixturePathfindingPerformed: feedbackToAgentIntentContextFixtureReport?.summary.pathfindingPerformed,
            feedbackToAgentIntentContextFixtureReplanningPerformed: feedbackToAgentIntentContextFixtureReport?.summary.replanningPerformed,
            feedbackToAgentIntentContextFixtureAvoidancePerformed: feedbackToAgentIntentContextFixtureReport?.summary.avoidancePerformed,
            feedbackToAgentIntentContextFixtureReservationRuntimeUsed: feedbackToAgentIntentContextFixtureReport?.summary.reservationRuntimeUsed,
            feedbackToAgentIntentContextFixtureWorldUsed: feedbackToAgentIntentContextFixtureReport?.summary.worldUsed,
            feedbackToAgentIntentContextFixtureMutationPerformed: feedbackToAgentIntentContextFixtureReport?.summary.mutationPerformed,
            feedbackToAgentIntentContextFixtureSuccess: feedbackToAgentIntentContextFixtureSuccess,
            feedbackToAgentIntentContextHardeningCases: feedbackToAgentIntentContextHardeningReport?.summary.cases,
            feedbackToAgentIntentContextHardeningPassed: feedbackToAgentIntentContextHardeningReport?.summary.passed,
            feedbackToAgentIntentContextHardeningFailed: feedbackToAgentIntentContextHardeningReport?.summary.failed,
            feedbackToAgentIntentContextHardeningFeedbackObservedTotal: feedbackToAgentIntentContextHardeningReport?.summary.feedbackObservedTotal,
            feedbackToAgentIntentContextHardeningFeedbackAcceptedTotal: feedbackToAgentIntentContextHardeningReport?.summary.feedbackAcceptedTotal,
            feedbackToAgentIntentContextHardeningFeedbackIgnoredTotal: feedbackToAgentIntentContextHardeningReport?.summary.feedbackIgnoredTotal,
            feedbackToAgentIntentContextHardeningInvalidFeedbackTotal: feedbackToAgentIntentContextHardeningReport?.summary.invalidFeedbackTotal,
            feedbackToAgentIntentContextHardeningContextsProducedTotal: feedbackToAgentIntentContextHardeningReport?.summary.contextsProducedTotal,
            feedbackToAgentIntentContextHardeningDuplicateFeedbackTotal: feedbackToAgentIntentContextHardeningReport?.summary.duplicateFeedbackTotal,
            feedbackToAgentIntentContextHardeningMaxFeedbackExceededTotal: feedbackToAgentIntentContextHardeningReport?.summary.maxFeedbackExceededTotal,
            feedbackToAgentIntentContextHardeningTickMismatchFeedbackTotal: feedbackToAgentIntentContextHardeningReport?.summary.tickMismatchFeedbackTotal,
            feedbackToAgentIntentContextHardeningIntentContextsTotal: feedbackToAgentIntentContextHardeningReport?.summary.intentContextsTotal,
            feedbackToAgentIntentContextHardeningContextsWithFeedbackTotal: feedbackToAgentIntentContextHardeningReport?.summary.contextsWithFeedbackTotal,
            feedbackToAgentIntentContextHardeningContextsWithoutFeedbackTotal: feedbackToAgentIntentContextHardeningReport?.summary.contextsWithoutFeedbackTotal,
            feedbackToAgentIntentContextHardeningProposalsTotal: feedbackToAgentIntentContextHardeningReport?.summary.proposalsTotal,
            feedbackToAgentIntentContextHardeningAcceptedIntentsTotal: feedbackToAgentIntentContextHardeningReport?.summary.acceptedIntentsTotal,
            feedbackToAgentIntentContextHardeningRejectedProposalsTotal: feedbackToAgentIntentContextHardeningReport?.summary.rejectedProposalsTotal,
            feedbackToAgentIntentContextHardeningNoIntentTotal: feedbackToAgentIntentContextHardeningReport?.summary.noIntentTotal,
            feedbackToAgentIntentContextHardeningInvalidOneEdgeProposalsTotal: feedbackToAgentIntentContextHardeningReport?.summary.invalidOneEdgeProposalsTotal,
            feedbackToAgentIntentContextHardeningBehaviorChangedByFeedback: feedbackToAgentIntentContextHardeningReport?.summary.behaviorChangedByFeedback,
            feedbackToAgentIntentContextHardeningFeedbackUsedForDecision: feedbackToAgentIntentContextHardeningReport?.summary.feedbackUsedForDecision,
            feedbackToAgentIntentContextHardeningMovementApplied: feedbackToAgentIntentContextHardeningReport?.summary.movementApplied,
            feedbackToAgentIntentContextHardeningCollisionRead: feedbackToAgentIntentContextHardeningReport?.summary.collisionRead,
            feedbackToAgentIntentContextHardeningMemoryUpdated: feedbackToAgentIntentContextHardeningReport?.summary.memoryUpdated,
            feedbackToAgentIntentContextHardeningGoalChanged: feedbackToAgentIntentContextHardeningReport?.summary.goalChanged,
            feedbackToAgentIntentContextHardeningPathfindingPerformed: feedbackToAgentIntentContextHardeningReport?.summary.pathfindingPerformed,
            feedbackToAgentIntentContextHardeningReplanningPerformed: feedbackToAgentIntentContextHardeningReport?.summary.replanningPerformed,
            feedbackToAgentIntentContextHardeningAvoidancePerformed: feedbackToAgentIntentContextHardeningReport?.summary.avoidancePerformed,
            feedbackToAgentIntentContextHardeningReservationRuntimeUsed: feedbackToAgentIntentContextHardeningReport?.summary.reservationRuntimeUsed,
            feedbackToAgentIntentContextHardeningWorldUsed: feedbackToAgentIntentContextHardeningReport?.summary.worldUsed,
            feedbackToAgentIntentContextHardeningMutationPerformed: feedbackToAgentIntentContextHardeningReport?.summary.mutationPerformed,
            feedbackToAgentIntentContextHardeningSuccess: feedbackToAgentIntentContextHardeningSuccess,
            feedbackAwareIntentPolicyFixtureContexts: feedbackAwareIntentPolicyFixtureReport?.summary.contexts,
            feedbackAwareIntentPolicyFixtureContextsWithFeedback: feedbackAwareIntentPolicyFixtureReport?.summary.contextsWithFeedback,
            feedbackAwareIntentPolicyFixtureContextsWithoutFeedback: feedbackAwareIntentPolicyFixtureReport?.summary.contextsWithoutFeedback,
            feedbackAwareIntentPolicyFixtureBaselineProposals: feedbackAwareIntentPolicyFixtureReport?.summary.baselineProposals,
            feedbackAwareIntentPolicyFixtureFeedbackAwareProposals: feedbackAwareIntentPolicyFixtureReport?.summary.feedbackAwareProposals,
            feedbackAwareIntentPolicyFixtureAcceptedIntents: feedbackAwareIntentPolicyFixtureReport?.summary.acceptedIntents,
            feedbackAwareIntentPolicyFixtureRejectedProposals: feedbackAwareIntentPolicyFixtureReport?.summary.rejectedProposals,
            feedbackAwareIntentPolicyFixtureNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.noIntent,
            feedbackAwareIntentPolicyFixtureInvalidOneEdgeProposals: feedbackAwareIntentPolicyFixtureReport?.summary.invalidOneEdgeProposals,
            feedbackAwareIntentPolicyFixtureFeedbackReactions: feedbackAwareIntentPolicyFixtureReport?.summary.feedbackReactions,
            feedbackAwareIntentPolicyFixtureBehaviorChangedByFeedback: feedbackAwareIntentPolicyFixtureReport?.summary.behaviorChangedByFeedback,
            feedbackAwareIntentPolicyFixtureBehaviorChangedCount: feedbackAwareIntentPolicyFixtureReport?.summary.behaviorChangedCount,
            feedbackAwareIntentPolicyFixtureNoFeedbackBaselineKept: feedbackAwareIntentPolicyFixtureReport?.summary.noFeedbackBaselineKept,
            feedbackAwareIntentPolicyFixtureMovedBaselineKept: feedbackAwareIntentPolicyFixtureReport?.summary.movedBaselineKept,
            feedbackAwareIntentPolicyFixtureApprovedForMovementBaselineKept: feedbackAwareIntentPolicyFixtureReport?.summary.approvedForMovementBaselineKept,
            feedbackAwareIntentPolicyFixtureBlockedByCollisionNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByCollisionNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedByAgentConflictNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByAgentConflictNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedBySourceMismatchNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedBySourceMismatchNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedByDivergenceNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByDivergenceNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedByStaleIntentNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByStaleIntentNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedByInvalidEdgeNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByInvalidEdgeNoIntent,
            feedbackAwareIntentPolicyFixtureBlockedByMaxAgentsNoIntent: feedbackAwareIntentPolicyFixtureReport?.summary.blockedByMaxAgentsNoIntent,
            feedbackAwareIntentPolicyFixtureCollisionRead: feedbackAwareIntentPolicyFixtureReport?.summary.collisionRead,
            feedbackAwareIntentPolicyFixtureMovementApplied: feedbackAwareIntentPolicyFixtureReport?.summary.movementApplied,
            feedbackAwareIntentPolicyFixtureMemoryUpdated: feedbackAwareIntentPolicyFixtureReport?.summary.memoryUpdated,
            feedbackAwareIntentPolicyFixtureGoalChanged: feedbackAwareIntentPolicyFixtureReport?.summary.goalChanged,
            feedbackAwareIntentPolicyFixturePathfindingPerformed: feedbackAwareIntentPolicyFixtureReport?.summary.pathfindingPerformed,
            feedbackAwareIntentPolicyFixtureReplanningPerformed: feedbackAwareIntentPolicyFixtureReport?.summary.replanningPerformed,
            feedbackAwareIntentPolicyFixtureAvoidancePerformed: feedbackAwareIntentPolicyFixtureReport?.summary.avoidancePerformed,
            feedbackAwareIntentPolicyFixtureReservationRuntimeUsed: feedbackAwareIntentPolicyFixtureReport?.summary.reservationRuntimeUsed,
            feedbackAwareIntentPolicyFixtureWorldUsed: feedbackAwareIntentPolicyFixtureReport?.summary.worldUsed,
            feedbackAwareIntentPolicyFixtureMutationPerformed: feedbackAwareIntentPolicyFixtureReport?.summary.mutationPerformed,
            feedbackAwareIntentPolicyFixtureSuccess: feedbackAwareIntentPolicyFixtureSuccess,
            feedbackAwareIntentPolicyHardeningCases: feedbackAwareIntentPolicyHardeningReport?.summary.cases,
            feedbackAwareIntentPolicyHardeningPassed: feedbackAwareIntentPolicyHardeningReport?.summary.passed,
            feedbackAwareIntentPolicyHardeningFailed: feedbackAwareIntentPolicyHardeningReport?.summary.failed,
            feedbackAwareIntentPolicyHardeningContextsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.contextsTotal,
            feedbackAwareIntentPolicyHardeningContextsWithFeedbackTotal: feedbackAwareIntentPolicyHardeningReport?.summary.contextsWithFeedbackTotal,
            feedbackAwareIntentPolicyHardeningContextsWithoutFeedbackTotal: feedbackAwareIntentPolicyHardeningReport?.summary.contextsWithoutFeedbackTotal,
            feedbackAwareIntentPolicyHardeningBaselineProposalsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.baselineProposalsTotal,
            feedbackAwareIntentPolicyHardeningFeedbackAwareProposalsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.feedbackAwareProposalsTotal,
            feedbackAwareIntentPolicyHardeningAcceptedIntentsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.acceptedIntentsTotal,
            feedbackAwareIntentPolicyHardeningRejectedProposalsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.rejectedProposalsTotal,
            feedbackAwareIntentPolicyHardeningNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.noIntentTotal,
            feedbackAwareIntentPolicyHardeningInvalidOneEdgeProposalsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.invalidOneEdgeProposalsTotal,
            feedbackAwareIntentPolicyHardeningFeedbackReactionsTotal: feedbackAwareIntentPolicyHardeningReport?.summary.feedbackReactionsTotal,
            feedbackAwareIntentPolicyHardeningBehaviorChangedByFeedback: feedbackAwareIntentPolicyHardeningReport?.summary.behaviorChangedByFeedback,
            feedbackAwareIntentPolicyHardeningBehaviorChangedCountTotal: feedbackAwareIntentPolicyHardeningReport?.summary.behaviorChangedCountTotal,
            feedbackAwareIntentPolicyHardeningNoFeedbackBaselineKeptTotal: feedbackAwareIntentPolicyHardeningReport?.summary.noFeedbackBaselineKeptTotal,
            feedbackAwareIntentPolicyHardeningMovedBaselineKeptTotal: feedbackAwareIntentPolicyHardeningReport?.summary.movedBaselineKeptTotal,
            feedbackAwareIntentPolicyHardeningApprovedForMovementBaselineKeptTotal: feedbackAwareIntentPolicyHardeningReport?.summary.approvedForMovementBaselineKeptTotal,
            feedbackAwareIntentPolicyHardeningBlockedByCollisionNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByCollisionNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedByAgentConflictNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByAgentConflictNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedBySourceMismatchNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedBySourceMismatchNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedByDivergenceNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByDivergenceNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedByStaleIntentNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByStaleIntentNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedByInvalidEdgeNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByInvalidEdgeNoIntentTotal,
            feedbackAwareIntentPolicyHardeningBlockedByMaxAgentsNoIntentTotal: feedbackAwareIntentPolicyHardeningReport?.summary.blockedByMaxAgentsNoIntentTotal,
            feedbackAwareIntentPolicyHardeningFeedbackUsedForDecision: feedbackAwareIntentPolicyHardeningReport?.summary.feedbackUsedForDecision,
            feedbackAwareIntentPolicyHardeningCollisionRead: feedbackAwareIntentPolicyHardeningReport?.summary.collisionRead,
            feedbackAwareIntentPolicyHardeningMovementApplied: feedbackAwareIntentPolicyHardeningReport?.summary.movementApplied,
            feedbackAwareIntentPolicyHardeningMemoryUpdated: feedbackAwareIntentPolicyHardeningReport?.summary.memoryUpdated,
            feedbackAwareIntentPolicyHardeningGoalChanged: feedbackAwareIntentPolicyHardeningReport?.summary.goalChanged,
            feedbackAwareIntentPolicyHardeningPathfindingPerformed: feedbackAwareIntentPolicyHardeningReport?.summary.pathfindingPerformed,
            feedbackAwareIntentPolicyHardeningReplanningPerformed: feedbackAwareIntentPolicyHardeningReport?.summary.replanningPerformed,
            feedbackAwareIntentPolicyHardeningAvoidancePerformed: feedbackAwareIntentPolicyHardeningReport?.summary.avoidancePerformed,
            feedbackAwareIntentPolicyHardeningReservationRuntimeUsed: feedbackAwareIntentPolicyHardeningReport?.summary.reservationRuntimeUsed,
            feedbackAwareIntentPolicyHardeningWorldUsed: feedbackAwareIntentPolicyHardeningReport?.summary.worldUsed,
            feedbackAwareIntentPolicyHardeningMutationPerformed: feedbackAwareIntentPolicyHardeningReport?.summary.mutationPerformed,
            feedbackAwareIntentPolicyHardeningSuccess: feedbackAwareIntentPolicyHardeningSuccess,
            feedbackAwareIntentToTickFixtureContexts: feedbackAwareIntentToTickFixtureReport?.summary.contexts,
            feedbackAwareIntentToTickFixtureContextsWithFeedback: feedbackAwareIntentToTickFixtureReport?.summary.contextsWithFeedback,
            feedbackAwareIntentToTickFixtureContextsWithoutFeedback: feedbackAwareIntentToTickFixtureReport?.summary.contextsWithoutFeedback,
            feedbackAwareIntentToTickFixtureBaselineProposals: feedbackAwareIntentToTickFixtureReport?.summary.baselineProposals,
            feedbackAwareIntentToTickFixtureFeedbackAwareProposals: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareProposals,
            feedbackAwareIntentToTickFixtureBaselineMovementIntentInputs: feedbackAwareIntentToTickFixtureReport?.summary.baselineMovementIntentInputs,
            feedbackAwareIntentToTickFixtureFeedbackAwareMovementIntentInputs: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareMovementIntentInputs,
            feedbackAwareIntentToTickFixtureMovementIntentReduction: feedbackAwareIntentToTickFixtureReport?.summary.movementIntentReduction,
            feedbackAwareIntentToTickFixtureNoIntentFilteredOut: feedbackAwareIntentToTickFixtureReport?.summary.noIntentFilteredOut,
            feedbackAwareIntentToTickFixtureFeedbackAwareAcceptedIntents: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareAcceptedIntents,
            feedbackAwareIntentToTickFixtureFeedbackAwareRejectedProposals: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareRejectedProposals,
            feedbackAwareIntentToTickFixtureFeedbackAwareNoIntent: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareNoIntent,
            feedbackAwareIntentToTickFixtureFeedbackAwareInvalidOneEdgeProposals: feedbackAwareIntentToTickFixtureReport?.summary.feedbackAwareInvalidOneEdgeProposals,
            feedbackAwareIntentToTickFixtureBehaviorChangedByFeedback: feedbackAwareIntentToTickFixtureReport?.summary.behaviorChangedByFeedback,
            feedbackAwareIntentToTickFixtureBehaviorChangedCount: feedbackAwareIntentToTickFixtureReport?.summary.behaviorChangedCount,
            feedbackAwareIntentToTickFixtureTickIntents: feedbackAwareIntentToTickFixtureReport?.summary.tickIntents,
            feedbackAwareIntentToTickFixtureTickApproved: feedbackAwareIntentToTickFixtureReport?.summary.tickApproved,
            feedbackAwareIntentToTickFixtureTickDenied: feedbackAwareIntentToTickFixtureReport?.summary.tickDenied,
            feedbackAwareIntentToTickFixtureTickDeniedSameDestinationConflict: feedbackAwareIntentToTickFixtureReport?.summary.tickDeniedSameDestinationConflict,
            feedbackAwareIntentToTickFixtureTickFeedbackEmitted: feedbackAwareIntentToTickFixtureReport?.summary.tickFeedbackEmitted,
            feedbackAwareIntentToTickFixtureDisplacementsApplied: feedbackAwareIntentToTickFixtureReport?.summary.displacementsApplied,
            feedbackAwareIntentToTickFixturePolicyReadCollision: feedbackAwareIntentToTickFixtureReport?.summary.policyReadCollision,
            feedbackAwareIntentToTickFixtureTickReadCollision: feedbackAwareIntentToTickFixtureReport?.summary.tickReadCollision,
            feedbackAwareIntentToTickFixtureMovementApplied: feedbackAwareIntentToTickFixtureReport?.summary.movementApplied,
            feedbackAwareIntentToTickFixtureMemoryUpdated: feedbackAwareIntentToTickFixtureReport?.summary.memoryUpdated,
            feedbackAwareIntentToTickFixtureGoalChanged: feedbackAwareIntentToTickFixtureReport?.summary.goalChanged,
            feedbackAwareIntentToTickFixturePathfindingPerformed: feedbackAwareIntentToTickFixtureReport?.summary.pathfindingPerformed,
            feedbackAwareIntentToTickFixtureReplanningPerformed: feedbackAwareIntentToTickFixtureReport?.summary.replanningPerformed,
            feedbackAwareIntentToTickFixtureAvoidancePerformed: feedbackAwareIntentToTickFixtureReport?.summary.avoidancePerformed,
            feedbackAwareIntentToTickFixtureReservationRuntimeUsed: feedbackAwareIntentToTickFixtureReport?.summary.reservationRuntimeUsed,
            feedbackAwareIntentToTickFixtureWorldUsed: feedbackAwareIntentToTickFixtureReport?.summary.worldUsed,
            feedbackAwareIntentToTickFixtureMutationPerformed: feedbackAwareIntentToTickFixtureReport?.summary.mutationPerformed,
            feedbackAwareIntentToTickFixtureSuccess: feedbackAwareIntentToTickFixtureSuccess,
            feedbackAwareIntentToTickLiveReadonlyContexts: feedbackAwareIntentToTickLiveReadonlyReport?.summary.contexts,
            feedbackAwareIntentToTickLiveReadonlyContextsWithFeedback: feedbackAwareIntentToTickLiveReadonlyReport?.summary.contextsWithFeedback,
            feedbackAwareIntentToTickLiveReadonlyContextsWithoutFeedback: feedbackAwareIntentToTickLiveReadonlyReport?.summary.contextsWithoutFeedback,
            feedbackAwareIntentToTickLiveReadonlyBaselineProposals: feedbackAwareIntentToTickLiveReadonlyReport?.summary.baselineProposals,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareProposals: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareProposals,
            feedbackAwareIntentToTickLiveReadonlyBaselineMovementIntentInputs: feedbackAwareIntentToTickLiveReadonlyReport?.summary.baselineMovementIntentInputs,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareMovementIntentInputs: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareMovementIntentInputs,
            feedbackAwareIntentToTickLiveReadonlyMovementIntentReduction: feedbackAwareIntentToTickLiveReadonlyReport?.summary.movementIntentReduction,
            feedbackAwareIntentToTickLiveReadonlyNoIntentFilteredOut: feedbackAwareIntentToTickLiveReadonlyReport?.summary.noIntentFilteredOut,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareAcceptedIntents: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareAcceptedIntents,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareRejectedProposals: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareRejectedProposals,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareNoIntent: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareNoIntent,
            feedbackAwareIntentToTickLiveReadonlyFeedbackAwareInvalidOneEdgeProposals: feedbackAwareIntentToTickLiveReadonlyReport?.summary.feedbackAwareInvalidOneEdgeProposals,
            feedbackAwareIntentToTickLiveReadonlyBehaviorChangedByFeedback: feedbackAwareIntentToTickLiveReadonlyReport?.summary.behaviorChangedByFeedback,
            feedbackAwareIntentToTickLiveReadonlyBehaviorChangedCount: feedbackAwareIntentToTickLiveReadonlyReport?.summary.behaviorChangedCount,
            feedbackAwareIntentToTickLiveReadonlyTickIntents: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickIntents,
            feedbackAwareIntentToTickLiveReadonlyTickApproved: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickApproved,
            feedbackAwareIntentToTickLiveReadonlyTickDenied: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickDenied,
            feedbackAwareIntentToTickLiveReadonlyTickDeniedSameDestinationConflict: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickDeniedSameDestinationConflict,
            feedbackAwareIntentToTickLiveReadonlyTickDeniedCollision: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickDeniedCollision,
            feedbackAwareIntentToTickLiveReadonlyTickFeedbackEmitted: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickFeedbackEmitted,
            feedbackAwareIntentToTickLiveReadonlyOccupableDestinations: feedbackAwareIntentToTickLiveReadonlyReport?.summary.occupableDestinations,
            feedbackAwareIntentToTickLiveReadonlyNonOccupableDestinations: feedbackAwareIntentToTickLiveReadonlyReport?.summary.nonOccupableDestinations,
            feedbackAwareIntentToTickLiveReadonlyDisplacementsApplied: feedbackAwareIntentToTickLiveReadonlyReport?.summary.displacementsApplied,
            feedbackAwareIntentToTickLiveReadonlyPolicyReadCollision: feedbackAwareIntentToTickLiveReadonlyReport?.summary.policyReadCollision,
            feedbackAwareIntentToTickLiveReadonlyTickReadCollision: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickReadCollision,
            feedbackAwareIntentToTickLiveReadonlyPolicyWorldUsed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.policyWorldUsed,
            feedbackAwareIntentToTickLiveReadonlyTickWorldReadOnlyUsed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.tickWorldReadOnlyUsed,
            feedbackAwareIntentToTickLiveReadonlyMovementApplied: feedbackAwareIntentToTickLiveReadonlyReport?.summary.movementApplied,
            feedbackAwareIntentToTickLiveReadonlyMemoryUpdated: feedbackAwareIntentToTickLiveReadonlyReport?.summary.memoryUpdated,
            feedbackAwareIntentToTickLiveReadonlyGoalChanged: feedbackAwareIntentToTickLiveReadonlyReport?.summary.goalChanged,
            feedbackAwareIntentToTickLiveReadonlyPathfindingPerformed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.pathfindingPerformed,
            feedbackAwareIntentToTickLiveReadonlyReplanningPerformed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.replanningPerformed,
            feedbackAwareIntentToTickLiveReadonlyAvoidancePerformed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.avoidancePerformed,
            feedbackAwareIntentToTickLiveReadonlyReservationRuntimeUsed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.reservationRuntimeUsed,
            feedbackAwareIntentToTickLiveReadonlyWorldMutated: feedbackAwareIntentToTickLiveReadonlyReport?.summary.worldMutated,
            feedbackAwareIntentToTickLiveReadonlyMutationPerformed: feedbackAwareIntentToTickLiveReadonlyReport?.summary.mutationPerformed,
            feedbackAwareIntentToTickLiveReadonlySuccess: feedbackAwareIntentToTickLiveReadonlySuccess,
            feedbackAwareIntentToTickApprovedApplicationContexts: feedbackAwareIntentToTickApprovedApplicationReport?.summary.contexts,
            feedbackAwareIntentToTickApprovedApplicationContextsWithFeedback: feedbackAwareIntentToTickApprovedApplicationReport?.summary.contextsWithFeedback,
            feedbackAwareIntentToTickApprovedApplicationContextsWithoutFeedback: feedbackAwareIntentToTickApprovedApplicationReport?.summary.contextsWithoutFeedback,
            feedbackAwareIntentToTickApprovedApplicationBaselineProposals: feedbackAwareIntentToTickApprovedApplicationReport?.summary.baselineProposals,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareProposals: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareProposals,
            feedbackAwareIntentToTickApprovedApplicationBaselineMovementIntentInputs: feedbackAwareIntentToTickApprovedApplicationReport?.summary.baselineMovementIntentInputs,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareMovementIntentInputs: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareMovementIntentInputs,
            feedbackAwareIntentToTickApprovedApplicationMovementIntentReduction: feedbackAwareIntentToTickApprovedApplicationReport?.summary.movementIntentReduction,
            feedbackAwareIntentToTickApprovedApplicationNoIntentFilteredOut: feedbackAwareIntentToTickApprovedApplicationReport?.summary.noIntentFilteredOut,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareAcceptedIntents: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareAcceptedIntents,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareRejectedProposals: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareRejectedProposals,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareNoIntent: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareNoIntent,
            feedbackAwareIntentToTickApprovedApplicationFeedbackAwareInvalidOneEdgeProposals: feedbackAwareIntentToTickApprovedApplicationReport?.summary.feedbackAwareInvalidOneEdgeProposals,
            feedbackAwareIntentToTickApprovedApplicationBehaviorChangedByFeedback: feedbackAwareIntentToTickApprovedApplicationReport?.summary.behaviorChangedByFeedback,
            feedbackAwareIntentToTickApprovedApplicationBehaviorChangedCount: feedbackAwareIntentToTickApprovedApplicationReport?.summary.behaviorChangedCount,
            feedbackAwareIntentToTickApprovedApplicationTickIntents: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickIntents,
            feedbackAwareIntentToTickApprovedApplicationTickApproved: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickApproved,
            feedbackAwareIntentToTickApprovedApplicationTickDenied: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickDenied,
            feedbackAwareIntentToTickApprovedApplicationTickDeniedSameDestinationConflict: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickDeniedSameDestinationConflict,
            feedbackAwareIntentToTickApprovedApplicationTickDeniedCollision: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickDeniedCollision,
            feedbackAwareIntentToTickApprovedApplicationTickFeedbackEmitted: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickFeedbackEmitted,
            feedbackAwareIntentToTickApprovedApplicationOccupableDestinations: feedbackAwareIntentToTickApprovedApplicationReport?.summary.occupableDestinations,
            feedbackAwareIntentToTickApprovedApplicationNonOccupableDestinations: feedbackAwareIntentToTickApprovedApplicationReport?.summary.nonOccupableDestinations,
            feedbackAwareIntentToTickApprovedApplicationApprovedAgentsMoved: feedbackAwareIntentToTickApprovedApplicationReport?.summary.approvedAgentsMoved,
            feedbackAwareIntentToTickApprovedApplicationDeniedAgentsPreserved: feedbackAwareIntentToTickApprovedApplicationReport?.summary.deniedAgentsPreserved,
            feedbackAwareIntentToTickApprovedApplicationNoIntentAgentsPreserved: feedbackAwareIntentToTickApprovedApplicationReport?.summary.noIntentAgentsPreserved,
            feedbackAwareIntentToTickApprovedApplicationDisplacementsApplied: feedbackAwareIntentToTickApprovedApplicationReport?.summary.displacementsApplied,
            feedbackAwareIntentToTickApprovedApplicationAbstractPositionsChanged: feedbackAwareIntentToTickApprovedApplicationReport?.summary.abstractPositionsChanged,
            feedbackAwareIntentToTickApprovedApplicationPhysicalPositionsChanged: feedbackAwareIntentToTickApprovedApplicationReport?.summary.physicalPositionsChanged,
            feedbackAwareIntentToTickApprovedApplicationAbstractPhysicalDivergenceBefore: feedbackAwareIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceBefore,
            feedbackAwareIntentToTickApprovedApplicationAbstractPhysicalDivergenceAfter: feedbackAwareIntentToTickApprovedApplicationReport?.summary.abstractPhysicalDivergenceAfter,
            feedbackAwareIntentToTickApprovedApplicationPolicyReadCollision: feedbackAwareIntentToTickApprovedApplicationReport?.summary.policyReadCollision,
            feedbackAwareIntentToTickApprovedApplicationTickReadCollision: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickReadCollision,
            feedbackAwareIntentToTickApprovedApplicationPolicyWorldUsed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.policyWorldUsed,
            feedbackAwareIntentToTickApprovedApplicationTickWorldReadOnlyUsed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.tickWorldReadOnlyUsed,
            feedbackAwareIntentToTickApprovedApplicationMovementApplied: feedbackAwareIntentToTickApprovedApplicationReport?.summary.movementApplied,
            feedbackAwareIntentToTickApprovedApplicationMemoryUpdated: feedbackAwareIntentToTickApprovedApplicationReport?.summary.memoryUpdated,
            feedbackAwareIntentToTickApprovedApplicationGoalChanged: feedbackAwareIntentToTickApprovedApplicationReport?.summary.goalChanged,
            feedbackAwareIntentToTickApprovedApplicationPathfindingPerformed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.pathfindingPerformed,
            feedbackAwareIntentToTickApprovedApplicationReplanningPerformed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.replanningPerformed,
            feedbackAwareIntentToTickApprovedApplicationAvoidancePerformed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.avoidancePerformed,
            feedbackAwareIntentToTickApprovedApplicationReservationRuntimeUsed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.reservationRuntimeUsed,
            feedbackAwareIntentToTickApprovedApplicationRouteFollowingUsed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.routeFollowingUsed,
            feedbackAwareIntentToTickApprovedApplicationWorldMutated: feedbackAwareIntentToTickApprovedApplicationReport?.summary.worldMutated,
            feedbackAwareIntentToTickApprovedApplicationMutationPerformed: feedbackAwareIntentToTickApprovedApplicationReport?.summary.mutationPerformed,
            feedbackAwareIntentToTickApprovedApplicationSuccess: feedbackAwareIntentToTickApprovedApplicationSuccess,
            alternateLocalHintContexts: alternateLocalHintReport?.summary.contexts,
            alternateLocalHintDecisions: alternateLocalHintReport?.summary.decisions,
            alternateLocalHintContextsWithBlockedFeedback: alternateLocalHintReport?.summary.contextsWithBlockedFeedback,
            alternateLocalHintContextsWithoutFeedback: alternateLocalHintReport?.summary.contextsWithoutFeedback,
            alternateLocalHintContextsWithApprovedOrMovedFeedback: alternateLocalHintReport?.summary.contextsWithApprovedOrMovedFeedback,
            alternateLocalHintCandidatesProduced: alternateLocalHintReport?.summary.candidatesProduced,
            alternateLocalHintCandidatesSelected: alternateLocalHintReport?.summary.candidatesSelected,
            alternateLocalHintCandidatesFiltered: alternateLocalHintReport?.summary.candidatesFiltered,
            alternateLocalHintMaxAlternates: alternateLocalHintReport?.summary.maxAlternates,
            alternateLocalHintBounded: alternateLocalHintReport?.summary.bounded,
            alternateLocalHintNoFeedbackBaseline: alternateLocalHintReport?.summary.noFeedbackBaseline,
            alternateLocalHintApprovedFeedbackBaseline: alternateLocalHintReport?.summary.approvedFeedbackBaseline,
            alternateLocalHintMovedFeedbackBaseline: alternateLocalHintReport?.summary.movedFeedbackBaseline,
            alternateLocalHintBlockedFeedbackUsed: alternateLocalHintReport?.summary.blockedFeedbackUsed,
            alternateLocalHintUnknownHintNoAlternate: alternateLocalHintReport?.summary.unknownHintNoAlternate,
            alternateLocalHintEmptyHintNoAlternate: alternateLocalHintReport?.summary.emptyHintNoAlternate,
            alternateLocalHintFailedDirectionExcluded: alternateLocalHintReport?.summary.failedDirectionExcluded,
            alternateLocalHintOneEdgeAlternates: alternateLocalHintReport?.summary.oneEdgeAlternates,
            alternateLocalHintMovementIntentInputs: alternateLocalHintReport?.summary.movementIntentInputs,
            alternateLocalHintTickApproved: alternateLocalHintReport?.summary.tickApproved,
            alternateLocalHintTickDenied: alternateLocalHintReport?.summary.tickDenied,
            alternateLocalHintTickDeniedConflict: alternateLocalHintReport?.summary.tickDeniedConflict,
            alternateLocalHintTickDeniedCollision: alternateLocalHintReport?.summary.tickDeniedCollision,
            alternateLocalHintTickFeedbackEmitted: alternateLocalHintReport?.summary.tickFeedbackEmitted,
            alternateLocalHintV0Unchanged: alternateLocalHintReport?.summary.v0Unchanged,
            alternateLocalHintV1Unchanged: alternateLocalHintReport?.summary.v1Unchanged,
            alternateLocalHintV2OptIn: alternateLocalHintReport?.summary.v2OptIn,
            alternateLocalHintPolicyReadCollision: alternateLocalHintReport?.summary.policyReadCollision,
            alternateLocalHintPolicyWorldUsed: alternateLocalHintReport?.summary.policyWorldUsed,
            alternateLocalHintTickReadCollision: alternateLocalHintReport?.summary.tickReadCollision,
            alternateLocalHintTickWorldUsed: alternateLocalHintReport?.summary.tickWorldUsed,
            alternateLocalHintMovementApplied: alternateLocalHintReport?.summary.movementApplied,
            alternateLocalHintPathfindingPerformed: alternateLocalHintReport?.summary.pathfindingPerformed,
            alternateLocalHintReplanningPerformed: alternateLocalHintReport?.summary.replanningPerformed,
            alternateLocalHintAvoidancePerformed: alternateLocalHintReport?.summary.avoidancePerformed,
            alternateLocalHintReservationRuntimeUsed: alternateLocalHintReport?.summary.reservationRuntimeUsed,
            alternateLocalHintRouteFollowingUsed: alternateLocalHintReport?.summary.routeFollowingUsed,
            alternateLocalHintMemoryUpdated: alternateLocalHintReport?.summary.memoryUpdated,
            alternateLocalHintGoalChanged: alternateLocalHintReport?.summary.goalChanged,
            alternateLocalHintWorldMutated: alternateLocalHintReport?.summary.worldMutated,
            alternateLocalHintMutationPerformed: alternateLocalHintReport?.summary.mutationPerformed,
            alternateLocalHintSuccess: alternateLocalHintSuccess,
            alternateLocalHintHardeningCases: alternateLocalHintHardeningReport?.summary.cases,
            alternateLocalHintHardeningPassed: alternateLocalHintHardeningReport?.summary.passed,
            alternateLocalHintHardeningFailed: alternateLocalHintHardeningReport?.summary.failed,
            alternateLocalHintHardeningContexts: alternateLocalHintHardeningReport?.summary.contexts,
            alternateLocalHintHardeningDecisions: alternateLocalHintHardeningReport?.summary.decisions,
            alternateLocalHintHardeningContextsWithBlockedFeedback: alternateLocalHintHardeningReport?.summary.contextsWithBlockedFeedback,
            alternateLocalHintHardeningContextsWithoutFeedback: alternateLocalHintHardeningReport?.summary.contextsWithoutFeedback,
            alternateLocalHintHardeningContextsWithApprovedOrMovedFeedback: alternateLocalHintHardeningReport?.summary.contextsWithApprovedOrMovedFeedback,
            alternateLocalHintHardeningBlockedFeedbackKindsCovered: alternateLocalHintHardeningReport?.summary.blockedFeedbackKindsCovered,
            alternateLocalHintHardeningCandidatesProduced: alternateLocalHintHardeningReport?.summary.candidatesProduced,
            alternateLocalHintHardeningCandidatesSelected: alternateLocalHintHardeningReport?.summary.candidatesSelected,
            alternateLocalHintHardeningCandidatesFiltered: alternateLocalHintHardeningReport?.summary.candidatesFiltered,
            alternateLocalHintHardeningMaxAlternatesMin: alternateLocalHintHardeningReport?.summary.maxAlternatesMin,
            alternateLocalHintHardeningMaxAlternatesMax: alternateLocalHintHardeningReport?.summary.maxAlternatesMax,
            alternateLocalHintHardeningMaxAlternatesZeroCases: alternateLocalHintHardeningReport?.summary.maxAlternatesZeroCases,
            alternateLocalHintHardeningMaxAlternatesOneCases: alternateLocalHintHardeningReport?.summary.maxAlternatesOneCases,
            alternateLocalHintHardeningMaxAlternatesTwoCases: alternateLocalHintHardeningReport?.summary.maxAlternatesTwoCases,
            alternateLocalHintHardeningMaxAlternatesThreeCases: alternateLocalHintHardeningReport?.summary.maxAlternatesThreeCases,
            alternateLocalHintHardeningBoundedCases: alternateLocalHintHardeningReport?.summary.boundedCases,
            alternateLocalHintHardeningDeterministicOrderingCases: alternateLocalHintHardeningReport?.summary.deterministicOrderingCases,
            alternateLocalHintHardeningDuplicateHintCases: alternateLocalHintHardeningReport?.summary.duplicateHintCases,
            alternateLocalHintHardeningDuplicateHintsFiltered: alternateLocalHintHardeningReport?.summary.duplicateHintsFiltered,
            alternateLocalHintHardeningUnknownHintNoAlternate: alternateLocalHintHardeningReport?.summary.unknownHintNoAlternate,
            alternateLocalHintHardeningEmptyHintNoAlternate: alternateLocalHintHardeningReport?.summary.emptyHintNoAlternate,
            alternateLocalHintHardeningNoFeedbackBaseline: alternateLocalHintHardeningReport?.summary.noFeedbackBaseline,
            alternateLocalHintHardeningApprovedFeedbackBaseline: alternateLocalHintHardeningReport?.summary.approvedFeedbackBaseline,
            alternateLocalHintHardeningMovedFeedbackBaseline: alternateLocalHintHardeningReport?.summary.movedFeedbackBaseline,
            alternateLocalHintHardeningFailedDirectionExcluded: alternateLocalHintHardeningReport?.summary.failedDirectionExcluded,
            alternateLocalHintHardeningOneEdgeAlternates: alternateLocalHintHardeningReport?.summary.oneEdgeAlternates,
            alternateLocalHintHardeningRepeatabilityChecks: alternateLocalHintHardeningReport?.summary.repeatabilityChecks,
            alternateLocalHintHardeningRepeatabilityFailures: alternateLocalHintHardeningReport?.summary.repeatabilityFailures,
            alternateLocalHintHardeningMovementIntentInputs: alternateLocalHintHardeningReport?.summary.movementIntentInputs,
            alternateLocalHintHardeningTickApproved: alternateLocalHintHardeningReport?.summary.tickApproved,
            alternateLocalHintHardeningTickDenied: alternateLocalHintHardeningReport?.summary.tickDenied,
            alternateLocalHintHardeningTickDeniedConflict: alternateLocalHintHardeningReport?.summary.tickDeniedConflict,
            alternateLocalHintHardeningTickDeniedCollision: alternateLocalHintHardeningReport?.summary.tickDeniedCollision,
            alternateLocalHintHardeningTickFeedbackEmitted: alternateLocalHintHardeningReport?.summary.tickFeedbackEmitted,
            alternateLocalHintHardeningV0Unchanged: alternateLocalHintHardeningReport?.summary.v0Unchanged,
            alternateLocalHintHardeningV1Unchanged: alternateLocalHintHardeningReport?.summary.v1Unchanged,
            alternateLocalHintHardeningV2OptIn: alternateLocalHintHardeningReport?.summary.v2OptIn,
            alternateLocalHintHardeningPolicyReadCollision: alternateLocalHintHardeningReport?.summary.policyReadCollision,
            alternateLocalHintHardeningPolicyWorldUsed: alternateLocalHintHardeningReport?.summary.policyWorldUsed,
            alternateLocalHintHardeningTickReadCollision: alternateLocalHintHardeningReport?.summary.tickReadCollision,
            alternateLocalHintHardeningTickWorldUsed: alternateLocalHintHardeningReport?.summary.tickWorldUsed,
            alternateLocalHintHardeningMovementApplied: alternateLocalHintHardeningReport?.summary.movementApplied,
            alternateLocalHintHardeningPathfindingPerformed: alternateLocalHintHardeningReport?.summary.pathfindingPerformed,
            alternateLocalHintHardeningReplanningPerformed: alternateLocalHintHardeningReport?.summary.replanningPerformed,
            alternateLocalHintHardeningAvoidancePerformed: alternateLocalHintHardeningReport?.summary.avoidancePerformed,
            alternateLocalHintHardeningReservationRuntimeUsed: alternateLocalHintHardeningReport?.summary.reservationRuntimeUsed,
            alternateLocalHintHardeningRouteFollowingUsed: alternateLocalHintHardeningReport?.summary.routeFollowingUsed,
            alternateLocalHintHardeningMemoryUpdated: alternateLocalHintHardeningReport?.summary.memoryUpdated,
            alternateLocalHintHardeningGoalChanged: alternateLocalHintHardeningReport?.summary.goalChanged,
            alternateLocalHintHardeningWorldMutated: alternateLocalHintHardeningReport?.summary.worldMutated,
            alternateLocalHintHardeningMutationPerformed: alternateLocalHintHardeningReport?.summary.mutationPerformed,
            alternateLocalHintHardeningSuccess: alternateLocalHintHardeningSuccess,
            multiTickClosedLoopTicks: multiTickClosedLoopReport?.summary.executedTicks,
            multiTickClosedLoopAgents: multiTickClosedLoopReport?.summary.agents,
            multiTickClosedLoopContextsTotal: multiTickClosedLoopReport?.summary.contextsTotal,
            multiTickClosedLoopFeedbackConsumedTotal: multiTickClosedLoopReport?.summary.feedbackConsumedTotal,
            multiTickClosedLoopFeedbackCarriedToNextTickTotal: multiTickClosedLoopReport?.summary.feedbackCarriedToNextTickTotal,
            multiTickClosedLoopContextsWithFeedbackTotal: multiTickClosedLoopReport?.summary.contextsWithFeedbackTotal,
            multiTickClosedLoopContextsWithoutFeedbackTotal: multiTickClosedLoopReport?.summary.contextsWithoutFeedbackTotal,
            multiTickClosedLoopProposalsTotal: multiTickClosedLoopReport?.summary.proposalsTotal,
            multiTickClosedLoopAcceptedIntentsTotal: multiTickClosedLoopReport?.summary.acceptedIntentsTotal,
            multiTickClosedLoopNoIntentTotal: multiTickClosedLoopReport?.summary.noIntentTotal,
            multiTickClosedLoopNoIntentFromBlockedFeedbackTotal: multiTickClosedLoopReport?.summary.noIntentFromBlockedFeedbackTotal,
            multiTickClosedLoopMovementIntentInputsTotal: multiTickClosedLoopReport?.summary.movementIntentInputsTotal,
            multiTickClosedLoopTickApprovedTotal: multiTickClosedLoopReport?.summary.tickApprovedTotal,
            multiTickClosedLoopTickDeniedTotal: multiTickClosedLoopReport?.summary.tickDeniedTotal,
            multiTickClosedLoopTickDeniedConflictTotal: multiTickClosedLoopReport?.summary.tickDeniedConflictTotal,
            multiTickClosedLoopTickDeniedCollisionTotal: multiTickClosedLoopReport?.summary.tickDeniedCollisionTotal,
            multiTickClosedLoopFeedbackEmittedTotal: multiTickClosedLoopReport?.summary.feedbackEmittedTotal,
            multiTickClosedLoopApprovedApplicationsTotal: multiTickClosedLoopReport?.summary.approvedApplicationsTotal,
            multiTickClosedLoopDeniedPreservedTotal: multiTickClosedLoopReport?.summary.deniedPreservedTotal,
            multiTickClosedLoopNoIntentPreservedTotal: multiTickClosedLoopReport?.summary.noIntentPreservedTotal,
            multiTickClosedLoopSameTickFeedbackConsumedTotal: multiTickClosedLoopReport?.summary.sameTickFeedbackConsumedTotal,
            multiTickClosedLoopCrossAgentFeedbackLeaksTotal: multiTickClosedLoopReport?.summary.crossAgentFeedbackLeaksTotal,
            multiTickClosedLoopFutureFeedbackConsumedTotal: multiTickClosedLoopReport?.summary.futureFeedbackConsumedTotal,
            multiTickClosedLoopPolicyReadCollision: multiTickClosedLoopReport?.summary.policyReadCollision,
            multiTickClosedLoopTickReadCollision: multiTickClosedLoopReport?.summary.tickReadCollision,
            multiTickClosedLoopPolicyWorldUsed: multiTickClosedLoopReport?.summary.policyWorldUsed,
            multiTickClosedLoopTickWorldReadOnlyUsed: multiTickClosedLoopReport?.summary.tickWorldReadOnlyUsed,
            multiTickClosedLoopMovementApplied: multiTickClosedLoopReport?.summary.movementApplied,
            multiTickClosedLoopMemoryUpdated: multiTickClosedLoopReport?.summary.memoryUpdated,
            multiTickClosedLoopGoalChanged: multiTickClosedLoopReport?.summary.goalChanged,
            multiTickClosedLoopPathfindingPerformed: multiTickClosedLoopReport?.summary.pathfindingPerformed,
            multiTickClosedLoopReplanningPerformed: multiTickClosedLoopReport?.summary.replanningPerformed,
            multiTickClosedLoopAvoidancePerformed: multiTickClosedLoopReport?.summary.avoidancePerformed,
            multiTickClosedLoopReservationRuntimeUsed: multiTickClosedLoopReport?.summary.reservationRuntimeUsed,
            multiTickClosedLoopRouteFollowingUsed: multiTickClosedLoopReport?.summary.routeFollowingUsed,
            multiTickClosedLoopWorldMutated: multiTickClosedLoopReport?.summary.worldMutated,
            multiTickClosedLoopMutationPerformed: multiTickClosedLoopReport?.summary.mutationPerformed,
            multiTickClosedLoopSuccess: multiTickClosedLoopSuccess,
            multiTickClosedLoopHardeningCases: multiTickClosedLoopHardeningReport?.summary.cases,
            multiTickClosedLoopHardeningPassed: multiTickClosedLoopHardeningReport?.summary.passed,
            multiTickClosedLoopHardeningFailed: multiTickClosedLoopHardeningReport?.summary.failed,
            multiTickClosedLoopHardeningRequestedTicksTotal: multiTickClosedLoopHardeningReport?.summary.requestedTicksTotal,
            multiTickClosedLoopHardeningExecutedTicksTotal: multiTickClosedLoopHardeningReport?.summary.executedTicksTotal,
            multiTickClosedLoopHardeningAgentsTotal: multiTickClosedLoopHardeningReport?.summary.agentsTotal,
            multiTickClosedLoopHardeningContextsTotal: multiTickClosedLoopHardeningReport?.summary.contextsTotal,
            multiTickClosedLoopHardeningFeedbackCandidatesTotal: multiTickClosedLoopHardeningReport?.summary.feedbackCandidatesTotal,
            multiTickClosedLoopHardeningFeedbackConsumedTotal: multiTickClosedLoopHardeningReport?.summary.feedbackConsumedTotal,
            multiTickClosedLoopHardeningFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.feedbackIgnoredTotal,
            multiTickClosedLoopHardeningFeedbackDedupedTotal: multiTickClosedLoopHardeningReport?.summary.feedbackDedupedTotal,
            multiTickClosedLoopHardeningMissingFeedbackAllowedTotal: multiTickClosedLoopHardeningReport?.summary.missingFeedbackAllowedTotal,
            multiTickClosedLoopHardeningStaleFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.staleFeedbackIgnoredTotal,
            multiTickClosedLoopHardeningFutureFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.futureFeedbackIgnoredTotal,
            multiTickClosedLoopHardeningSameTickFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.sameTickFeedbackIgnoredTotal,
            multiTickClosedLoopHardeningCrossAgentLeakAttemptsTotal: multiTickClosedLoopHardeningReport?.summary.crossAgentLeakAttemptsTotal,
            multiTickClosedLoopHardeningCrossAgentFeedbackLeaksTotal: multiTickClosedLoopHardeningReport?.summary.crossAgentFeedbackLeaksTotal,
            multiTickClosedLoopHardeningUnknownAgentFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.unknownAgentFeedbackIgnoredTotal,
            multiTickClosedLoopHardeningMalformedFeedbackIgnoredTotal: multiTickClosedLoopHardeningReport?.summary.malformedFeedbackIgnoredTotal,
            multiTickClosedLoopHardeningNoIntentFromBlockedFeedbackTotal: multiTickClosedLoopHardeningReport?.summary.noIntentFromBlockedFeedbackTotal,
            multiTickClosedLoopHardeningMovementIntentInputsTotal: multiTickClosedLoopHardeningReport?.summary.movementIntentInputsTotal,
            multiTickClosedLoopHardeningTickApprovedTotal: multiTickClosedLoopHardeningReport?.summary.tickApprovedTotal,
            multiTickClosedLoopHardeningTickDeniedTotal: multiTickClosedLoopHardeningReport?.summary.tickDeniedTotal,
            multiTickClosedLoopHardeningTickDeniedConflictTotal: multiTickClosedLoopHardeningReport?.summary.tickDeniedConflictTotal,
            multiTickClosedLoopHardeningTickDeniedCollisionTotal: multiTickClosedLoopHardeningReport?.summary.tickDeniedCollisionTotal,
            multiTickClosedLoopHardeningFeedbackEmittedTotal: multiTickClosedLoopHardeningReport?.summary.feedbackEmittedTotal,
            multiTickClosedLoopHardeningSameTickFeedbackConsumedTotal: multiTickClosedLoopHardeningReport?.summary.sameTickFeedbackConsumedTotal,
            multiTickClosedLoopHardeningFutureFeedbackConsumedTotal: multiTickClosedLoopHardeningReport?.summary.futureFeedbackConsumedTotal,
            multiTickClosedLoopHardeningRepeatabilityChecks: multiTickClosedLoopHardeningReport?.summary.repeatabilityChecks,
            multiTickClosedLoopHardeningRepeatabilityFailures: multiTickClosedLoopHardeningReport?.summary.repeatabilityFailures,
            multiTickClosedLoopHardeningPolicyReadCollision: multiTickClosedLoopHardeningReport?.summary.policyReadCollision,
            multiTickClosedLoopHardeningTickReadCollision: multiTickClosedLoopHardeningReport?.summary.tickReadCollision,
            multiTickClosedLoopHardeningPolicyWorldUsed: multiTickClosedLoopHardeningReport?.summary.policyWorldUsed,
            multiTickClosedLoopHardeningTickWorldReadOnlyUsed: multiTickClosedLoopHardeningReport?.summary.tickWorldReadOnlyUsed,
            multiTickClosedLoopHardeningMovementApplied: multiTickClosedLoopHardeningReport?.summary.movementApplied,
            multiTickClosedLoopHardeningMemoryUpdated: multiTickClosedLoopHardeningReport?.summary.memoryUpdated,
            multiTickClosedLoopHardeningGoalChanged: multiTickClosedLoopHardeningReport?.summary.goalChanged,
            multiTickClosedLoopHardeningPathfindingPerformed: multiTickClosedLoopHardeningReport?.summary.pathfindingPerformed,
            multiTickClosedLoopHardeningReplanningPerformed: multiTickClosedLoopHardeningReport?.summary.replanningPerformed,
            multiTickClosedLoopHardeningAvoidancePerformed: multiTickClosedLoopHardeningReport?.summary.avoidancePerformed,
            multiTickClosedLoopHardeningReservationRuntimeUsed: multiTickClosedLoopHardeningReport?.summary.reservationRuntimeUsed,
            multiTickClosedLoopHardeningRouteFollowingUsed: multiTickClosedLoopHardeningReport?.summary.routeFollowingUsed,
            multiTickClosedLoopHardeningWorldMutated: multiTickClosedLoopHardeningReport?.summary.worldMutated,
            multiTickClosedLoopHardeningMutationPerformed: multiTickClosedLoopHardeningReport?.summary.mutationPerformed,
            multiTickClosedLoopHardeningSuccess: multiTickClosedLoopHardeningSuccess,
            multiTickClosedLoopLiveReadonlyRequestedTicks: multiTickClosedLoopLiveReadonlyReport?.summary.requestedTicks,
            multiTickClosedLoopLiveReadonlyExecutedTicks: multiTickClosedLoopLiveReadonlyReport?.summary.executedTicks,
            multiTickClosedLoopLiveReadonlyAgents: multiTickClosedLoopLiveReadonlyReport?.summary.agents,
            multiTickClosedLoopLiveReadonlyContextsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.contextsTotal,
            multiTickClosedLoopLiveReadonlyFeedbackConsumedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.feedbackConsumedTotal,
            multiTickClosedLoopLiveReadonlyFeedbackCarriedToNextTickTotal: multiTickClosedLoopLiveReadonlyReport?.summary.feedbackCarriedToNextTickTotal,
            multiTickClosedLoopLiveReadonlyContextsWithFeedbackTotal: multiTickClosedLoopLiveReadonlyReport?.summary.contextsWithFeedbackTotal,
            multiTickClosedLoopLiveReadonlyContextsWithoutFeedbackTotal: multiTickClosedLoopLiveReadonlyReport?.summary.contextsWithoutFeedbackTotal,
            multiTickClosedLoopLiveReadonlyProposalsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.proposalsTotal,
            multiTickClosedLoopLiveReadonlyAcceptedIntentsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.acceptedIntentsTotal,
            multiTickClosedLoopLiveReadonlyNoIntentTotal: multiTickClosedLoopLiveReadonlyReport?.summary.noIntentTotal,
            multiTickClosedLoopLiveReadonlyNoIntentFromBlockedFeedbackTotal: multiTickClosedLoopLiveReadonlyReport?.summary.noIntentFromBlockedFeedbackTotal,
            multiTickClosedLoopLiveReadonlyMovementIntentInputsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.movementIntentInputsTotal,
            multiTickClosedLoopLiveReadonlyTickApprovedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.tickApprovedTotal,
            multiTickClosedLoopLiveReadonlyTickDeniedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.tickDeniedTotal,
            multiTickClosedLoopLiveReadonlyTickDeniedConflictTotal: multiTickClosedLoopLiveReadonlyReport?.summary.tickDeniedConflictTotal,
            multiTickClosedLoopLiveReadonlyTickDeniedCollisionTotal: multiTickClosedLoopLiveReadonlyReport?.summary.tickDeniedCollisionTotal,
            multiTickClosedLoopLiveReadonlyTickFeedbackEmittedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.tickFeedbackEmittedTotal,
            multiTickClosedLoopLiveReadonlyOccupableDestinationsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.occupableDestinationsTotal,
            multiTickClosedLoopLiveReadonlyNonOccupableDestinationsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.nonOccupableDestinationsTotal,
            multiTickClosedLoopLiveReadonlyApprovedApplicationsTotal: multiTickClosedLoopLiveReadonlyReport?.summary.approvedApplicationsTotal,
            multiTickClosedLoopLiveReadonlySameTickFeedbackConsumedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.sameTickFeedbackConsumedTotal,
            multiTickClosedLoopLiveReadonlyCrossAgentFeedbackLeaksTotal: multiTickClosedLoopLiveReadonlyReport?.summary.crossAgentFeedbackLeaksTotal,
            multiTickClosedLoopLiveReadonlyFutureFeedbackConsumedTotal: multiTickClosedLoopLiveReadonlyReport?.summary.futureFeedbackConsumedTotal,
            multiTickClosedLoopLiveReadonlyPolicyReadCollision: multiTickClosedLoopLiveReadonlyReport?.summary.policyReadCollision,
            multiTickClosedLoopLiveReadonlyTickReadCollision: multiTickClosedLoopLiveReadonlyReport?.summary.tickReadCollision,
            multiTickClosedLoopLiveReadonlyPolicyWorldUsed: multiTickClosedLoopLiveReadonlyReport?.summary.policyWorldUsed,
            multiTickClosedLoopLiveReadonlyTickWorldReadOnlyUsed: multiTickClosedLoopLiveReadonlyReport?.summary.tickWorldReadOnlyUsed,
            multiTickClosedLoopLiveReadonlyMovementApplied: multiTickClosedLoopLiveReadonlyReport?.summary.movementApplied,
            multiTickClosedLoopLiveReadonlyMemoryUpdated: multiTickClosedLoopLiveReadonlyReport?.summary.memoryUpdated,
            multiTickClosedLoopLiveReadonlyGoalChanged: multiTickClosedLoopLiveReadonlyReport?.summary.goalChanged,
            multiTickClosedLoopLiveReadonlyPathfindingPerformed: multiTickClosedLoopLiveReadonlyReport?.summary.pathfindingPerformed,
            multiTickClosedLoopLiveReadonlyReplanningPerformed: multiTickClosedLoopLiveReadonlyReport?.summary.replanningPerformed,
            multiTickClosedLoopLiveReadonlyAvoidancePerformed: multiTickClosedLoopLiveReadonlyReport?.summary.avoidancePerformed,
            multiTickClosedLoopLiveReadonlyReservationRuntimeUsed: multiTickClosedLoopLiveReadonlyReport?.summary.reservationRuntimeUsed,
            multiTickClosedLoopLiveReadonlyRouteFollowingUsed: multiTickClosedLoopLiveReadonlyReport?.summary.routeFollowingUsed,
            multiTickClosedLoopLiveReadonlyWorldMutated: multiTickClosedLoopLiveReadonlyReport?.summary.worldMutated,
            multiTickClosedLoopLiveReadonlyMutationPerformed: multiTickClosedLoopLiveReadonlyReport?.summary.mutationPerformed,
            multiTickClosedLoopLiveReadonlySuccess: multiTickClosedLoopLiveReadonlySuccess,
            multiTickClosedLoopApprovedApplicationRequestedTicks: multiTickClosedLoopApprovedApplicationReport?.summary.requestedTicks,
            multiTickClosedLoopApprovedApplicationExecutedTicks: multiTickClosedLoopApprovedApplicationReport?.summary.executedTicks,
            multiTickClosedLoopApprovedApplicationAgents: multiTickClosedLoopApprovedApplicationReport?.summary.agents,
            multiTickClosedLoopApprovedApplicationContextsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.contextsTotal,
            multiTickClosedLoopApprovedApplicationFeedbackConsumedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.feedbackConsumedTotal,
            multiTickClosedLoopApprovedApplicationFeedbackCarriedToNextTickTotal: multiTickClosedLoopApprovedApplicationReport?.summary.feedbackCarriedToNextTickTotal,
            multiTickClosedLoopApprovedApplicationContextsWithFeedbackTotal: multiTickClosedLoopApprovedApplicationReport?.summary.contextsWithFeedbackTotal,
            multiTickClosedLoopApprovedApplicationContextsWithoutFeedbackTotal: multiTickClosedLoopApprovedApplicationReport?.summary.contextsWithoutFeedbackTotal,
            multiTickClosedLoopApprovedApplicationProposalsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.proposalsTotal,
            multiTickClosedLoopApprovedApplicationAcceptedIntentsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.acceptedIntentsTotal,
            multiTickClosedLoopApprovedApplicationNoIntentTotal: multiTickClosedLoopApprovedApplicationReport?.summary.noIntentTotal,
            multiTickClosedLoopApprovedApplicationNoIntentFromBlockedFeedbackTotal: multiTickClosedLoopApprovedApplicationReport?.summary.noIntentFromBlockedFeedbackTotal,
            multiTickClosedLoopApprovedApplicationMovementIntentInputsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.movementIntentInputsTotal,
            multiTickClosedLoopApprovedApplicationTickApprovedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.tickApprovedTotal,
            multiTickClosedLoopApprovedApplicationTickDeniedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.tickDeniedTotal,
            multiTickClosedLoopApprovedApplicationTickDeniedConflictTotal: multiTickClosedLoopApprovedApplicationReport?.summary.tickDeniedConflictTotal,
            multiTickClosedLoopApprovedApplicationTickDeniedCollisionTotal: multiTickClosedLoopApprovedApplicationReport?.summary.tickDeniedCollisionTotal,
            multiTickClosedLoopApprovedApplicationTickFeedbackEmittedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.tickFeedbackEmittedTotal,
            multiTickClosedLoopApprovedApplicationOccupableDestinationsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.occupableDestinationsTotal,
            multiTickClosedLoopApprovedApplicationNonOccupableDestinationsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.nonOccupableDestinationsTotal,
            multiTickClosedLoopApprovedApplicationApprovedApplicationsTotal: multiTickClosedLoopApprovedApplicationReport?.summary.approvedApplicationsTotal,
            multiTickClosedLoopApprovedApplicationApprovedAgentsMovedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.approvedAgentsMovedTotal,
            multiTickClosedLoopApprovedApplicationDeniedAgentsPreservedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.deniedAgentsPreservedTotal,
            multiTickClosedLoopApprovedApplicationNoIntentAgentsPreservedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.noIntentAgentsPreservedTotal,
            multiTickClosedLoopApprovedApplicationDisplacementsAppliedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.displacementsAppliedTotal,
            multiTickClosedLoopApprovedApplicationAbstractPositionsChangedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.abstractPositionsChangedTotal,
            multiTickClosedLoopApprovedApplicationPhysicalPositionsChangedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.physicalPositionsChangedTotal,
            multiTickClosedLoopApprovedApplicationAbstractPhysicalDivergenceBeforeMax: multiTickClosedLoopApprovedApplicationReport?.summary.abstractPhysicalDivergenceBeforeMax,
            multiTickClosedLoopApprovedApplicationAbstractPhysicalDivergenceAfterMax: multiTickClosedLoopApprovedApplicationReport?.summary.abstractPhysicalDivergenceAfterMax,
            multiTickClosedLoopApprovedApplicationSameTickFeedbackConsumedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.sameTickFeedbackConsumedTotal,
            multiTickClosedLoopApprovedApplicationCrossAgentFeedbackLeaksTotal: multiTickClosedLoopApprovedApplicationReport?.summary.crossAgentFeedbackLeaksTotal,
            multiTickClosedLoopApprovedApplicationFutureFeedbackConsumedTotal: multiTickClosedLoopApprovedApplicationReport?.summary.futureFeedbackConsumedTotal,
            multiTickClosedLoopApprovedApplicationPolicyReadCollision: multiTickClosedLoopApprovedApplicationReport?.summary.policyReadCollision,
            multiTickClosedLoopApprovedApplicationTickReadCollision: multiTickClosedLoopApprovedApplicationReport?.summary.tickReadCollision,
            multiTickClosedLoopApprovedApplicationPolicyWorldUsed: multiTickClosedLoopApprovedApplicationReport?.summary.policyWorldUsed,
            multiTickClosedLoopApprovedApplicationTickWorldReadOnlyUsed: multiTickClosedLoopApprovedApplicationReport?.summary.tickWorldReadOnlyUsed,
            multiTickClosedLoopApprovedApplicationMovementApplied: multiTickClosedLoopApprovedApplicationReport?.summary.movementApplied,
            multiTickClosedLoopApprovedApplicationMemoryUpdated: multiTickClosedLoopApprovedApplicationReport?.summary.memoryUpdated,
            multiTickClosedLoopApprovedApplicationGoalChanged: multiTickClosedLoopApprovedApplicationReport?.summary.goalChanged,
            multiTickClosedLoopApprovedApplicationPathfindingPerformed: multiTickClosedLoopApprovedApplicationReport?.summary.pathfindingPerformed,
            multiTickClosedLoopApprovedApplicationReplanningPerformed: multiTickClosedLoopApprovedApplicationReport?.summary.replanningPerformed,
            multiTickClosedLoopApprovedApplicationAvoidancePerformed: multiTickClosedLoopApprovedApplicationReport?.summary.avoidancePerformed,
            multiTickClosedLoopApprovedApplicationReservationRuntimeUsed: multiTickClosedLoopApprovedApplicationReport?.summary.reservationRuntimeUsed,
            multiTickClosedLoopApprovedApplicationRouteFollowingUsed: multiTickClosedLoopApprovedApplicationReport?.summary.routeFollowingUsed,
            multiTickClosedLoopApprovedApplicationWorldMutated: multiTickClosedLoopApprovedApplicationReport?.summary.worldMutated,
            multiTickClosedLoopApprovedApplicationMutationPerformed: multiTickClosedLoopApprovedApplicationReport?.summary.mutationPerformed,
            multiTickClosedLoopApprovedApplicationSuccess: multiTickClosedLoopApprovedApplicationSuccess,
            routeFollowingFixtureCases: routeFollowingFixtureReport?.summary.cases,
            routeFollowingFixturePassed: routeFollowingFixtureReport?.summary.passed,
            routeFollowingFixtureFailed: routeFollowingFixtureReport?.summary.failed,
            routeFollowingFixtureCompleted: routeFollowingFixtureReport?.summary.completed,
            routeFollowingFixtureStopped: routeFollowingFixtureReport?.summary.stopped,
            routeFollowingFixtureAttemptedEdges: routeFollowingFixtureReport?.summary.attemptedEdges,
            routeFollowingFixtureCompletedEdges: routeFollowingFixtureReport?.summary.completedEdges,
            routeFollowingFixtureDisplacementsApplied: routeFollowingFixtureReport?.summary.displacementsApplied,
            routeFollowingFixtureDeniedEdges: routeFollowingFixtureReport?.summary.deniedEdges,
            routeFollowingFixtureCollisionDenied: routeFollowingFixtureReport?.summary.collisionDenied,
            routeFollowingFixtureInvalidEdges: routeFollowingFixtureReport?.summary.invalidEdges,
            routeFollowingFixtureSourceMismatch: routeFollowingFixtureReport?.summary.sourceMismatch,
            routeFollowingFixtureDivergence: routeFollowingFixtureReport?.summary.divergence,
            routeFollowingFixtureMaxSteps: routeFollowingFixtureReport?.summary.maxSteps,
            routeFollowingFixtureSuccess: routeFollowingFixtureSuccess,
            routeFollowingLiveAttempted: routeFollowingLiveSnapshot.map { _ in true },
            routeFollowingLiveCompleted: routeFollowingLiveSnapshot.map { $0.status == .completed },
            routeFollowingLiveStopped: routeFollowingLiveSnapshot.map { $0.status != .completed },
            routeFollowingLiveStatus: routeFollowingLiveSnapshot?.status.rawValue,
            routeFollowingLiveReason: routeFollowingLiveSnapshot?.reason,
            routeFollowingLiveRouteLength: routeFollowingLiveSnapshot?.route.count,
            routeFollowingLiveAttemptedEdges: routeFollowingLiveSnapshot?.attemptedEdges,
            routeFollowingLiveCompletedEdges: routeFollowingLiveSnapshot?.completedEdges,
            routeFollowingLiveStoppedAtIndex: routeFollowingLiveSnapshot?.stoppedAtIndex,
            routeFollowingLiveDisplacementsApplied: routeFollowingLiveDisplacementsApplied,
            routeFollowingLiveDeniedEdges: routeFollowingLiveDeniedEdges,
            routeFollowingLiveCollisionDenied: routeFollowingLiveSnapshot.map {
                $0.status == .stoppedCollisionDenied ? 1 : 0
            },
            routeFollowingLiveInvalidEdges: routeFollowingLiveSnapshot.map {
                $0.status == .stoppedInvalidEdge ? 1 : 0
            },
            routeFollowingLiveSourceMismatch: routeFollowingLiveSnapshot.map {
                $0.status == .stoppedSourceMismatch ? 1 : 0
            },
            routeFollowingLiveDivergence: routeFollowingLiveSnapshot.map {
                $0.status == .stoppedDivergence ? 1 : 0
            },
            routeFollowingLivePathfindingInsideFollower: routeFollowingLiveSnapshot?.pathfindingPerformedInsideFollower,
            routeFollowingLiveReplanningPerformed: routeFollowingLiveSnapshot?.replanningPerformed,
            routeFollowingLivePhysicsPerformed: routeFollowingLiveSnapshot?.physicsPerformed,
            routeFollowingLiveMutationPerformed: routeFollowingLiveSnapshot?.mutationPerformed,
            routeFollowingLiveSuccess: routeFollowingLiveSuccess,
            routeFollowingLiveHardeningCases: routeFollowingLiveHardeningReport?.summary.cases,
            routeFollowingLiveHardeningPassed: routeFollowingLiveHardeningReport?.summary.passed,
            routeFollowingLiveHardeningFailed: routeFollowingLiveHardeningReport?.summary.failed,
            routeFollowingLiveHardeningCompleted: routeFollowingLiveHardeningReport?.summary.completed,
            routeFollowingLiveHardeningStopped: routeFollowingLiveHardeningReport?.summary.stopped,
            routeFollowingLiveHardeningAttemptedEdges: routeFollowingLiveHardeningReport?.summary.attemptedEdges,
            routeFollowingLiveHardeningCompletedEdges: routeFollowingLiveHardeningReport?.summary.completedEdges,
            routeFollowingLiveHardeningDisplacementsApplied: routeFollowingLiveHardeningReport?.summary.displacementsApplied,
            routeFollowingLiveHardeningDeniedEdges: routeFollowingLiveHardeningReport?.summary.deniedEdges,
            routeFollowingLiveHardeningCollisionDenied: routeFollowingLiveHardeningReport?.summary.collisionDenied,
            routeFollowingLiveHardeningInvalidEdges: routeFollowingLiveHardeningReport?.summary.invalidEdges,
            routeFollowingLiveHardeningSourceMismatch: routeFollowingLiveHardeningReport?.summary.sourceMismatch,
            routeFollowingLiveHardeningDivergence: routeFollowingLiveHardeningReport?.summary.divergence,
            routeFollowingLiveHardeningStaleCollision: routeFollowingLiveHardeningReport?.summary.staleCollision,
            routeFollowingLiveHardeningMaxSteps: routeFollowingLiveHardeningReport?.summary.maxSteps,
            routeFollowingLiveHardeningSuccess: routeFollowingLiveHardeningSuccess,
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

if let world {
    print("PebbleLab headless scenario=\(options.scenario) dim=\(world.dim.rawValue) seed=\(world.seed) ticks=\(world.time)")
} else {
    print("PebbleLab headless scenario=\(options.scenario) dim=fixture seed=\(options.seed) ticks=\(ticksCompleted)")
}
