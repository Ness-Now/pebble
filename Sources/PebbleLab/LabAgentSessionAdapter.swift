import PebbleAgents
import PebbleCore

enum LabAgentSessionAdapterError: Error {
    case duplicateFacadeAgentId(String)
    case facadeAgentSetMismatch
    case facadeStateDiverged(String)
    case sessionTickMismatch(expected: Int, actual: Int)
}

struct LabAgentSessionTickOutput {
    let facadeIndex: Int
    let memoryStart: Int
    let goalChange: LabGoalChange?
    let movement: LabAgentMovement?
}

final class LabAgentSessionAdapter {
    private var session: AgentSimulationSession

    init(seed: UInt32, agents: [LabAgent], initialTick: Int = 0) throws {
        let configuration = try AgentSessionConfiguration(
            seed: seed,
            nearbyRadius: 8,
            recentMemorySnapshotLimit: 10,
            memoryPolicy: .legacyUnbounded
        )
        session = try AgentSimulationSession(
            configuration: configuration,
            agents: agents.map(Self.makeSharedState),
            initialTick: initialTick
        )
        try verifyFacade(agents)
    }

    var snapshot: PebbleAgents.AgentSessionSnapshot {
        session.snapshot()
    }

    func tick(
        agents: inout [LabAgent],
        world: World,
        tick: Int
    ) throws -> [LabAgentSessionTickOutput] {
        try verifyFacade(agents)
        let expectedTick = session.tick + 1
        guard tick == expectedTick else {
            throw LabAgentSessionAdapterError.sessionTickMismatch(
                expected: expectedTick,
                actual: tick
            )
        }

        let indexById = try makeIndexById(agents)
        let orderedIds = session.snapshot().agents.map(\.id)
        var memoryStarts: [String: Int] = [:]
        var perceptions: [AgentPerceptionInput] = []

        for id in orderedIds {
            guard let index = indexById[id] else {
                throw LabAgentSessionAdapterError.facadeAgentSetMismatch
            }
            let memoryStart = agents[index].memory.count
            memoryStarts[id] = memoryStart
            let observationCountBefore = agents[index].observationCount
            agents[index].observe(world: world, tick: tick)
            perceptions.append(AgentPerceptionInput(
                agentId: id,
                observationCountIncrement: agents[index].observationCount - observationCountBefore,
                externalMemoryEntries: Array(agents[index].memory.dropFirst(memoryStart))
            ))
        }

        let tickResult = try session.advanceTick(perceptions: perceptions)
        var outputs: [LabAgentSessionTickOutput] = []

        for agentResult in tickResult.agents {
            guard let index = indexById[agentResult.agentId],
                  let memoryStart = memoryStarts[agentResult.agentId]
            else {
                throw LabAgentSessionAdapterError.facadeAgentSetMismatch
            }

            try applySharedState(session.state(for: agentResult.agentId), to: &agents[index])
            let memoryBeforeMovement = agents[index].memory.count
            let movement = agents[index].applyAbstractMovement(tick: tick)
            let movementMemories = Array(agents[index].memory.dropFirst(memoryBeforeMovement))

            try session.applyExternalUpdate(AgentExternalUpdate(
                agentId: agentResult.agentId,
                position: agents[index].position,
                memoryEntries: movementMemories,
                movementCount: agents[index].movementCount,
                totalManhattanDistanceMoved: agents[index].totalManhattanDistanceMoved,
                returnHomeMoveCount: agents[index].returnHomeMoveCount,
                totalDistanceReducedTowardHome: agents[index].totalDistanceReducedTowardHome
            ))
            try applySharedState(session.state(for: agentResult.agentId), to: &agents[index])

            outputs.append(LabAgentSessionTickOutput(
                facadeIndex: index,
                memoryStart: memoryStart,
                goalChange: agentResult.goalChange,
                movement: movement
            ))
        }

        try verifyFacade(agents)
        return outputs
    }

    private static func makeSharedState(_ agent: LabAgent) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: agent.id,
            state: agent.state,
            position: agent.position,
            needs: agent.needs,
            health: agent.health,
            fear: agent.fear,
            homePosition: agent.homePosition,
            nearbyAgents: agent.nearbyAgents,
            currentGoal: agent.currentGoal,
            lastAction: agent.lastAction,
            lastActionEffect: agent.lastActionEffect,
            memory: agent.memory,
            tickCreated: agent.tickCreated,
            ticksAlive: agent.ticksAlive,
            observationCount: agent.observationCount,
            nearbyObservationCount: agent.nearbyObservationCount,
            goalSelectionCount: agent.goalSelectionCount,
            goalChangeCount: agent.goalChangeCount,
            actionCount: agent.actionCount,
            actionEffectCount: agent.actionEffectCount,
            movementCount: agent.movementCount,
            totalManhattanDistanceMoved: agent.totalManhattanDistanceMoved,
            returnHomeMoveCount: agent.returnHomeMoveCount,
            totalDistanceReducedTowardHome: agent.totalDistanceReducedTowardHome
        )
    }

    private func applySharedState(
        _ state: AgentSessionAgentState,
        to agent: inout LabAgent
    ) throws {
        guard state.id == agent.id else {
            throw LabAgentSessionAdapterError.facadeStateDiverged(agent.id)
        }
        agent.state = state.state
        agent.position = state.position
        agent.needs = state.needs
        agent.health = state.health
        agent.fear = state.fear
        agent.homePosition = state.homePosition
        agent.nearbyAgents = state.nearbyAgents
        agent.currentGoal = state.currentGoal
        agent.lastAction = state.lastAction
        agent.lastActionEffect = state.lastActionEffect
        agent.memory = state.memory
        agent.ticksAlive = state.ticksAlive
        agent.observationCount = state.observationCount
        agent.nearbyObservationCount = state.nearbyObservationCount
        agent.goalSelectionCount = state.goalSelectionCount
        agent.goalChangeCount = state.goalChangeCount
        agent.actionCount = state.actionCount
        agent.actionEffectCount = state.actionEffectCount
        agent.movementCount = state.movementCount
        agent.totalManhattanDistanceMoved = state.totalManhattanDistanceMoved
        agent.returnHomeMoveCount = state.returnHomeMoveCount
        agent.totalDistanceReducedTowardHome = state.totalDistanceReducedTowardHome
    }

    private func verifyFacade(_ agents: [LabAgent]) throws {
        let indexById = try makeIndexById(agents)
        let snapshots = session.snapshot().agents
        guard indexById.count == snapshots.count else {
            throw LabAgentSessionAdapterError.facadeAgentSetMismatch
        }
        for snapshot in snapshots {
            guard let index = indexById[snapshot.id] else {
                throw LabAgentSessionAdapterError.facadeAgentSetMismatch
            }
            let sharedState = try session.state(for: snapshot.id)
            guard sharedStateMatchesFacade(sharedState, agents[index]) else {
                throw LabAgentSessionAdapterError.facadeStateDiverged(snapshot.id)
            }
        }
    }

    private func makeIndexById(_ agents: [LabAgent]) throws -> [String: Int] {
        var result: [String: Int] = [:]
        for (index, agent) in agents.enumerated() {
            guard result[agent.id] == nil else {
                throw LabAgentSessionAdapterError.duplicateFacadeAgentId(agent.id)
            }
            result[agent.id] = index
        }
        return result
    }

    private func sharedStateMatchesFacade(
        _ shared: AgentSessionAgentState,
        _ facade: LabAgent
    ) -> Bool {
        shared.id == facade.id
            && shared.state == facade.state
            && shared.position == facade.position
            && needsEqual(shared.needs, facade.needs)
            && shared.health == facade.health
            && shared.fear == facade.fear
            && shared.homePosition == facade.homePosition
            && shared.nearbyAgents == facade.nearbyAgents
            && shared.currentGoal == facade.currentGoal
            && actionsEqual(shared.lastAction, facade.lastAction)
            && effectsEqual(shared.lastActionEffect, facade.lastActionEffect)
            && memoriesEqual(shared.memory, facade.memory)
            && shared.tickCreated == facade.tickCreated
            && shared.ticksAlive == facade.ticksAlive
            && shared.observationCount == facade.observationCount
            && shared.nearbyObservationCount == facade.nearbyObservationCount
            && shared.goalSelectionCount == facade.goalSelectionCount
            && shared.goalChangeCount == facade.goalChangeCount
            && shared.actionCount == facade.actionCount
            && shared.actionEffectCount == facade.actionEffectCount
            && shared.movementCount == facade.movementCount
            && shared.totalManhattanDistanceMoved == facade.totalManhattanDistanceMoved
            && shared.returnHomeMoveCount == facade.returnHomeMoveCount
            && shared.totalDistanceReducedTowardHome == facade.totalDistanceReducedTowardHome
    }
}

private func needsEqual(_ lhs: AgentNeeds, _ rhs: AgentNeeds) -> Bool {
    lhs.hunger == rhs.hunger
        && lhs.fatigue == rhs.fatigue
        && lhs.curiosity == rhs.curiosity
        && lhs.safety == rhs.safety
}

private func actionsEqual(_ lhs: AgentAction?, _ rhs: AgentAction?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case let (lhs?, rhs?):
        return lhs.name == rhs.name
            && lhs.reason == rhs.reason
            && lhs.tick == rhs.tick
            && lhs.dx == rhs.dx
            && lhs.dy == rhs.dy
            && lhs.dz == rhs.dz
            && lhs.target == rhs.target
            && lhs.resource == rhs.resource
    default:
        return false
    }
}

private func effectsEqual(_ lhs: AgentActionEffect?, _ rhs: AgentActionEffect?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case let (lhs?, rhs?):
        return lhs.action == rhs.action
            && lhs.effect == rhs.effect
            && lhs.tick == rhs.tick
            && lhs.hungerBefore == rhs.hungerBefore
            && lhs.hungerAfter == rhs.hungerAfter
            && lhs.fatigueBefore == rhs.fatigueBefore
            && lhs.fatigueAfter == rhs.fatigueAfter
            && lhs.curiosityBefore == rhs.curiosityBefore
            && lhs.curiosityAfter == rhs.curiosityAfter
            && lhs.safetyBefore == rhs.safetyBefore
            && lhs.safetyAfter == rhs.safetyAfter
            && lhs.fearBefore == rhs.fearBefore
            && lhs.fearAfter == rhs.fearAfter
            && lhs.stateBefore == rhs.stateBefore
            && lhs.stateAfter == rhs.stateAfter
    default:
        return false
    }
}

private func memoriesEqual(_ lhs: [AgentMemoryEntry], _ rhs: [AgentMemoryEntry]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { left, right in
        left.tick == right.tick
            && left.type == right.type
            && left.summary == right.summary
            && left.importance == right.importance
    }
}
