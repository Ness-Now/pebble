import Foundation
import simd
import PebbleAgents
import PebbleCore

func runPebbleAgentsRuntimeSmoke() {
// ---------------------------------------------------------------------------
section("PebbleAgents action decision")
do {
    func decide(
        agentId: String = "agent_0",
        tick: Int = 7,
        goalKind: AgentGoalKind,
        position: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
        homePosition: AgentPosition = AgentPosition(x: 0, y: 64, z: 0)
    ) -> AgentAction {
        AgentActionDecider.decide(AgentActionDecisionInput(
            agentId: agentId,
            tick: tick,
            goalKind: goalKind,
            position: position,
            homePosition: homePosition
        ))
    }

    func position(_ x: Int, _ z: Int) -> AgentPosition {
        AgentPosition(x: x, y: 64, z: z)
    }

    let idle = decide(goalKind: .idle)
    check("agent action idle waits",
          idle.name == "wait" && idle.reason == "goal idle")

    let rest = decide(goalKind: .rest)
    check("agent action rest",
          rest.name == "rest" && rest.reason == "goal rest")

    let observe = decide(goalKind: .observeOtherAgent)
    check("agent action observes other agent",
          observe.name == "observe_area" && observe.reason == "goal observeOtherAgent")

    let exploreEast = decide(tick: 0, goalKind: .explore)
    check("agent action explore east",
          exploreEast.name == "move_abstract" && exploreEast.reason == "goal explore"
              && exploreEast.dx == 1 && exploreEast.dy == 0 && exploreEast.dz == 0)

    let exploreSouth = decide(tick: 1, goalKind: .explore)
    check("agent action explore south",
          exploreSouth.dx == 0 && exploreSouth.dy == 0 && exploreSouth.dz == 1)

    let exploreWest = decide(tick: 2, goalKind: .explore)
    check("agent action explore west",
          exploreWest.dx == -1 && exploreWest.dy == 0 && exploreWest.dz == 0)

    let exploreNorth = decide(tick: 3, goalKind: .explore)
    check("agent action explore north",
          exploreNorth.dx == 0 && exploreNorth.dy == 0 && exploreNorth.dz == -1)

    let exploreFallback = decide(agentId: "agent_alpha", tick: 0, goalKind: .explore)
    check("agent action explore id fallback",
          exploreFallback.dx == 1 && exploreFallback.dy == 0 && exploreFallback.dz == 0)

    let home = position(4, 9)
    let atHome = decide(goalKind: .seekSafety, position: home, homePosition: home)
    check("agent action seek safety at home waits",
          atHome.name == "wait" && atHome.reason == "goal seekSafety at home"
              && atHome.dx == nil && atHome.dy == nil && atHome.dz == nil)

    let positiveX = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(3, 1)
    )
    check("agent action seek safety positive x",
          positiveX.name == "move_abstract" && positiveX.reason == "goal seekSafety"
              && positiveX.dx == 1 && positiveX.dy == 0 && positiveX.dz == 0)

    let negativeX = decide(
        goalKind: .seekSafety,
        position: position(3, 1),
        homePosition: position(0, 0)
    )
    check("agent action seek safety negative x",
          negativeX.dx == -1 && negativeX.dy == 0 && negativeX.dz == 0)

    let positiveZ = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(1, 3)
    )
    check("agent action seek safety positive z",
          positiveZ.dx == 0 && positiveZ.dy == 0 && positiveZ.dz == 1)

    let negativeZ = decide(
        goalKind: .seekSafety,
        position: position(1, 3),
        homePosition: position(0, 0)
    )
    check("agent action seek safety negative z",
          negativeZ.dx == 0 && negativeZ.dy == 0 && negativeZ.dz == -1)

    let tie = decide(
        goalKind: .seekSafety,
        position: position(0, 0),
        homePosition: position(-2, 2)
    )
    check("agent action seek safety tie prefers x",
          tie.dx == -1 && tie.dy == 0 && tie.dz == 0)

    let contractAction = AgentAction(
        name: "move_abstract",
        reason: "goal explore",
        tick: 9,
        dx: -1,
        dy: 0,
        dz: 0
    )
    let contractData = try? JSONEncoder().encode(contractAction)
    let contractObject = contractData.flatMap {
        try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
    }
    let preservedTick = decide(tick: 123, goalKind: .rest).tick
    check("agent action tick reason deltas and JSON contract",
          preservedTick == 123
              && idle.dx == nil && idle.dy == nil && idle.dz == nil
              && contractAction.tick == 9 && contractAction.reason == "goal explore"
              && contractAction.dx == -1 && contractAction.dy == 0 && contractAction.dz == 0
              && Set(contractObject?.keys.map { $0 } ?? []) == Set(["name", "reason", "tick", "dx", "dy", "dz"])
              && contractObject?["name"] as? String == "move_abstract"
              && contractObject?["reason"] as? String == "goal explore"
              && contractObject?["tick"] as? Int == 9
              && contractObject?["dx"] as? Int == -1
              && contractObject?["dy"] as? Int == 0
              && contractObject?["dz"] as? Int == 0)
}

// ---------------------------------------------------------------------------
section("PebbleAgents cognitive transitions")
do {
    func needs(
        hunger: Double = 0.1,
        fatigue: Double = 0.01,
        curiosity: Double = 0.4,
        safety: Double = 1
    ) -> AgentNeeds {
        AgentNeeds(hunger: hunger, fatigue: fatigue, curiosity: curiosity, safety: safety)
    }

    let tickNeeds = needs(hunger: 0.2, fatigue: 0.01, curiosity: 0.7, safety: 0.6)
    let tickResult = AgentCognitiveTransitions.advanceTick(needs: tickNeeds)
    check("cognitive tick hunger +0.01", abs(tickResult.needs.hunger - 0.21) <= 1e-12)
    check("cognitive tick fatigue +0.005", tickResult.needs.fatigue == 0.015)
    check("cognitive tick curiosity unchanged", tickResult.needs.curiosity == 0.7)
    check("cognitive tick safety unchanged", tickResult.needs.safety == 0.6)
    check("cognitive tick state idle", tickResult.state == "idle")

    let observerPosition = AgentPosition(x: 10, y: 64, z: 10)
    let nearby = AgentCognitiveTransitions.observeNearbyAgents(
        observerId: "observer",
        observerPosition: observerPosition,
        peers: [
            AgentPeerSnapshot(id: "observer", position: observerPosition),
            AgentPeerSnapshot(id: "near_b", position: AgentPosition(x: 12, y: 65, z: 8)),
            AgentPeerSnapshot(id: "edge", position: AgentPosition(x: 18, y: 64, z: 10)),
            AgentPeerSnapshot(id: "outside", position: AgentPosition(x: 19, y: 64, z: 10)),
            AgentPeerSnapshot(id: "near_a", position: AgentPosition(x: 9, y: 64, z: 10)),
        ],
        radius: 8
    )
    check("cognitive nearby excludes self", !nearby.contains { $0.id == "observer" })
    check("cognitive nearby includes in radius", nearby.contains { $0.id == "near_b" })
    check("cognitive nearby includes exact radius", nearby.contains { $0.id == "edge" })
    check("cognitive nearby excludes outside radius", !nearby.contains { $0.id == "outside" })
    check("cognitive nearby deltas exact",
          nearby.first?.dx == 2 && nearby.first?.dy == 1 && nearby.first?.dz == -2)
    check("cognitive nearby Manhattan exact", nearby.first?.distanceManhattan == 5)
    check("cognitive nearby preserves input order", nearby.map(\.id) == ["near_b", "edge", "near_a"])

    func selectGoal(
        tick: Int = 42,
        health: Int = 100,
        fear: Int = 0,
        needs selectedNeeds: AgentNeeds = AgentNeeds(
            hunger: 0,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        hasNearbyAgents: Bool = false,
        currentGoalKind: AgentGoalKind = .idle
    ) -> AgentGoalChange? {
        AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
            tick: tick,
            health: health,
            fear: fear,
            needs: selectedNeeds,
            hasNearbyAgents: hasNearbyAgents,
            currentGoalKind: currentGoalKind
        ))
    }

    let healthGoal = selectGoal(health: 25)
    check("cognitive goal health path",
          healthGoal?.to == .seekSafety && healthGoal?.goal.reason == "health <= 25"
              && healthGoal?.goal.urgency == 100 && healthGoal?.goal.startedAtTick == 42)

    let fearGoal = selectGoal(fear: 70)
    check("cognitive goal fear path",
          fearGoal?.to == .seekSafety && fearGoal?.goal.reason == "fear >= 70"
              && fearGoal?.goal.urgency == 85 && fearGoal?.goal.startedAtTick == 42)

    let safetyGoal = selectGoal(needs: needs(safety: 0.49))
    check("cognitive goal safety path",
          safetyGoal?.to == .seekSafety && safetyGoal?.goal.reason == "safety < 0.5"
              && safetyGoal?.goal.urgency == 90 && safetyGoal?.goal.startedAtTick == 42)

    let fatigueGoal = selectGoal(needs: needs(fatigue: 0.02))
    check("cognitive goal fatigue path",
          fatigueGoal?.to == .rest && fatigueGoal?.goal.reason == "fatigue >= 0.02"
              && fatigueGoal?.goal.urgency == 70 && fatigueGoal?.goal.startedAtTick == 42)

    let highCuriosityGoal = selectGoal(needs: needs(curiosity: 0.8))
    check("cognitive goal high curiosity path",
          highCuriosityGoal?.to == .explore
              && highCuriosityGoal?.goal.reason == "curiosity >= 0.8"
              && highCuriosityGoal?.goal.urgency == 60
              && highCuriosityGoal?.goal.startedAtTick == 42)

    let nearbyGoal = selectGoal(hasNearbyAgents: true)
    check("cognitive goal nearby path",
          nearbyGoal?.to == .observeOtherAgent
              && nearbyGoal?.goal.reason == "nearby agent detected"
              && nearbyGoal?.goal.urgency == 50 && nearbyGoal?.goal.startedAtTick == 42)

    let lowCuriosityGoal = selectGoal(needs: needs(curiosity: 0.5))
    check("cognitive goal low curiosity path",
          lowCuriosityGoal?.to == .explore
              && lowCuriosityGoal?.goal.reason == "curiosity >= 0.5"
              && lowCuriosityGoal?.goal.urgency == 40
              && lowCuriosityGoal?.goal.startedAtTick == 42)

    let idleGoal = selectGoal(currentGoalKind: .explore)
    check("cognitive goal idle path",
          idleGoal?.to == .idle && idleGoal?.goal.reason == "no active need"
              && idleGoal?.goal.urgency == 0 && idleGoal?.goal.startedAtTick == 42)

    check("cognitive goal same kind returns nil", selectGoal(health: 25, currentGoalKind: .seekSafety) == nil)
    check("cognitive goal health priority over fear",
          selectGoal(health: 20, fear: 80)?.goal.reason == "health <= 25")
    check("cognitive goal fear priority over safety",
          selectGoal(fear: 80, needs: needs(safety: 0))?.goal.reason == "fear >= 70")
    check("cognitive goal fatigue priority over curiosity",
          selectGoal(needs: needs(fatigue: 0.02, curiosity: 0.9))?.goal.reason == "fatigue >= 0.02")
    check("cognitive goal high curiosity priority over nearby",
          selectGoal(needs: needs(curiosity: 0.9), hasNearbyAgents: true)?.goal.reason == "curiosity >= 0.8")

    func applyEffect(
        actionName: String,
        goalKind: AgentGoalKind = .idle,
        distanceFromHome: Int = 5,
        needs effectNeeds: AgentNeeds = AgentNeeds(
            hunger: 0.3,
            fatigue: 0.03,
            curiosity: 0.5,
            safety: 0.8
        ),
        fear: Int = 5,
        state: String = "before",
        tick: Int = 17
    ) -> AgentActionEffectResult {
        AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
            action: AgentAction(name: actionName, reason: "test", tick: tick),
            goalKind: goalKind,
            distanceFromHome: distanceFromHome,
            needs: effectNeeds,
            fear: fear,
            state: state,
            tick: tick
        ))
    }

    let restEffect = applyEffect(actionName: "rest")
    check("cognitive effect rest",
          restEffect.needs.fatigue == 0.009999999999999998 && restEffect.fear == 4
              && restEffect.state == "resting"
              && restEffect.actionEffect.effect == "fatigue -0.02, fear -1")
    check("cognitive effect rest clamps fatigue",
          applyEffect(actionName: "rest", needs: needs(fatigue: 0.01)).needs.fatigue == 0)
    check("cognitive effect rest clamps fear",
          applyEffect(actionName: "rest", fear: 0).fear == 0)

    let observeEffect = applyEffect(actionName: "observe_area")
    check("cognitive effect observe area",
          observeEffect.needs.curiosity == 0.51 && observeEffect.state == "observing"
              && observeEffect.actionEffect.effect == "curiosity +0.01")
    check("cognitive effect observe clamps curiosity",
          applyEffect(actionName: "observe_area", needs: needs(curiosity: 0.999)).needs.curiosity == 1)

    let safeMoveEffect = applyEffect(actionName: "move_abstract", goalKind: .seekSafety)
    check("cognitive effect move seek safety",
          safeMoveEffect.fear == 4 && safeMoveEffect.state == "moving"
              && safeMoveEffect.actionEffect.effect == "fear -1")

    let exploreMoveEffect = applyEffect(actionName: "move_abstract", goalKind: .explore)
    check("cognitive effect move explore",
          exploreMoveEffect.needs.curiosity == 0.495 && exploreMoveEffect.state == "moving"
              && exploreMoveEffect.actionEffect.effect == "curiosity -0.005")
    check("cognitive effect move clamps curiosity",
          applyEffect(
              actionName: "move_abstract",
              goalKind: .explore,
              needs: needs(curiosity: 0.001)
          ).needs.curiosity == 0)

    let nearWaitEffect = applyEffect(actionName: "wait", goalKind: .seekSafety, distanceFromHome: 1)
    check("cognitive effect wait safety near",
          nearWaitEffect.fear == 3 && nearWaitEffect.state == "waiting"
              && nearWaitEffect.actionEffect.effect == "fear -2")

    let farWaitEffect = applyEffect(actionName: "wait", goalKind: .seekSafety, distanceFromHome: 2)
    check("cognitive effect wait safety far",
          farWaitEffect.fear == 4 && farWaitEffect.actionEffect.effect == "fear -1")

    let idleWaitEffect = applyEffect(actionName: "wait", goalKind: .idle)
    check("cognitive effect wait non safety",
          idleWaitEffect.fear == 5 && idleWaitEffect.needs.curiosity == 0.5
              && idleWaitEffect.state == "waiting"
              && idleWaitEffect.actionEffect.effect == "no need change")

    let unknownEffect = applyEffect(actionName: "unknown", state: "custom")
    check("cognitive effect unknown preserves values",
          unknownEffect.fear == 5 && unknownEffect.needs.hunger == 0.3
              && unknownEffect.needs.fatigue == 0.03 && unknownEffect.needs.curiosity == 0.5
              && unknownEffect.needs.safety == 0.8 && unknownEffect.actionEffect.effect == "no effect")
    check("cognitive effect unknown preserves state", unknownEffect.state == "custom")
    check("cognitive effect before after fields exact",
          restEffect.actionEffect.action == "rest" && restEffect.actionEffect.tick == 17
              && restEffect.actionEffect.hungerBefore == 0.3
              && restEffect.actionEffect.hungerAfter == 0.3
              && restEffect.actionEffect.fatigueBefore == 0.03
              && restEffect.actionEffect.fatigueAfter == 0.009999999999999998
              && restEffect.actionEffect.curiosityBefore == 0.5
              && restEffect.actionEffect.curiosityAfter == 0.5
              && restEffect.actionEffect.safetyBefore == 0.8
              && restEffect.actionEffect.safetyAfter == 0.8
              && restEffect.actionEffect.fearBefore == 5
              && restEffect.actionEffect.fearAfter == 4
              && restEffect.actionEffect.stateBefore == "before"
              && restEffect.actionEffect.stateAfter == "resting")

    let firstMemory = AgentMemoryEntry(tick: 1, type: "first", summary: "one", importance: 0.1)
    let secondMemory = AgentMemoryEntry(tick: 2, type: "second", summary: "two", importance: 0.2)
    var memory: [AgentMemoryEntry] = []
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    check("cognitive memory append adds one", memory.count == 1)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(secondMemory, to: &memory)
    check("cognitive memory append preserves order", memory.map(\.type) == ["first", "second"])
    for tick in 3...22 {
        AgentCognitiveTransitions.appendLegacyUnboundedMemory(
            AgentMemoryEntry(tick: tick, type: "extra", summary: "entry", importance: 0.3),
            to: &memory
        )
    }
    check("cognitive memory append remains unbounded", memory.count == 22)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    AgentCognitiveTransitions.appendLegacyUnboundedMemory(firstMemory, to: &memory)
    check("cognitive memory append does not deduplicate",
          memory.count == 24 && memory.suffix(2).allSatisfy { $0.type == "first" })
}

// ---------------------------------------------------------------------------
section("PebbleAgents multi-agent session and snapshots")
do {
    func sessionConfiguration(
        seed: UInt32 = 77,
        nearbyRadius: Int = 8,
        recentMemorySnapshotLimit: Int = 3,
        memoryPolicy: AgentMemoryPolicy = .legacyUnbounded
    ) -> AgentSessionConfiguration {
        try! AgentSessionConfiguration(
            seed: seed,
            nearbyRadius: nearbyRadius,
            recentMemorySnapshotLimit: recentMemorySnapshotLimit,
            memoryPolicy: memoryPolicy
        )
    }

    func sessionMemory(_ tick: Int, type: String? = nil) -> AgentMemoryEntry {
        AgentMemoryEntry(
            tick: tick,
            type: type ?? "memory_\(tick)",
            summary: "memory \(tick)",
            importance: Double(tick) / 100
        )
    }

    func sessionState(
        id: String,
        x: Int = 0,
        health: Int = 100,
        curiosity: Double = 0.9,
        memory: [AgentMemoryEntry] = []
    ) -> AgentSessionAgentState {
        let position = AgentPosition(x: x, y: 64, z: 0)
        return AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: curiosity, safety: 1),
            health: health,
            fear: 10,
            homePosition: AgentPosition(x: 0, y: 64, z: 0),
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: memory,
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0
        )
    }

    func session(
        _ states: [AgentSessionAgentState],
        configuration: AgentSessionConfiguration = sessionConfiguration(),
        initialTick: Int = 0
    ) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: configuration,
            agents: states,
            initialTick: initialTick
        )
    }

    let emptySession = session([])
    check("session construction empty accepted", emptySession.snapshot().agentCount == 0)

    let oneSession = session([sessionState(id: "agent_0")])
    check("session construction one agent", oneSession.snapshot().agentCount == 1)

    let threeStates = (0..<3).map { sessionState(id: "agent_\($0)", x: $0 * 2) }
    let threeSession = session(threeStates)
    check("session construction three agents", threeSession.snapshot().agentCount == 3)

    let tenStates = (0..<10).map { sessionState(id: "agent_\($0)", x: $0) }
    let tenSession = session(tenStates)
    check("session construction ten agents", tenSession.snapshot().agentCount == 10)
    check("session construction seed preserved", threeSession.snapshot().seed == 77)

    let initialTickSession = session([], initialTick: 12)
    check("session construction initial tick exact", initialTickSession.snapshot().tick == 12)

    do {
        _ = try AgentSimulationSession(
            configuration: sessionConfiguration(),
            agents: [sessionState(id: "duplicate"), sessionState(id: "duplicate")]
        )
        check("session construction duplicate id refused", false)
    } catch AgentSessionError.duplicateAgentId("duplicate") {
        check("session construction duplicate id refused", true)
    } catch {
        check("session construction duplicate id refused", false, "unexpected \(error)")
    }

    check("session configuration legacy explicit",
          sessionConfiguration().memoryPolicy == .legacyUnbounded)
    check("session configuration bounded valid",
          sessionConfiguration(memoryPolicy: .bounded(maxEntries: 4)).memoryPolicy
              == .bounded(maxEntries: 4))
    do {
        _ = try AgentSessionConfiguration(
            seed: 1,
            nearbyRadius: 8,
            recentMemorySnapshotLimit: 3,
            memoryPolicy: .bounded(maxEntries: 0)
        )
        check("session configuration bounded invalid refused", false)
    } catch AgentSessionError.invalidMemoryBound(0) {
        check("session configuration bounded invalid refused", true)
    } catch {
        check("session configuration bounded invalid refused", false, "unexpected \(error)")
    }

    let permutedStates = [
        sessionState(id: "agent_c", x: 4),
        sessionState(id: "agent_a", x: 0),
        sessionState(id: "agent_b", x: 2),
    ]
    var orderedSession = session(permutedStates)
    check("session order accepts permuted input", orderedSession.snapshot().agentCount == 3)
    check("session order snapshot sorted",
          orderedSession.snapshot().agents.map(\.id) == ["agent_a", "agent_b", "agent_c"])
    let orderedTick1 = try! orderedSession.advanceTick()
    check("session order tick result sorted",
          orderedTick1.agents.map(\.agentId) == ["agent_a", "agent_b", "agent_c"])
    let orderedTick2 = try! orderedSession.advanceTick()
    check("session order stable multiple ticks",
          orderedTick2.agents.map(\.agentId) == ["agent_a", "agent_b", "agent_c"])
    let reverseSession = session(Array(permutedStates.reversed()))
    check("session order independent from source order",
          reverseSession.snapshot() == session(permutedStates).snapshot())

    let snapshotMemories = (1...5).map { sessionMemory($0) }
    let snapshotSession = session([
        sessionState(id: "snapshot", x: 3, memory: snapshotMemories),
    ])
    let snapshot = snapshotSession.snapshot()
    let snapshotAgent = snapshot.agents[0]
    check("session snapshot agentCount exact", snapshot.agentCount == 1)
    check("session snapshot properties exact",
          snapshotAgent.id == "snapshot" && snapshotAgent.position == AgentPosition(x: 3, y: 64, z: 0))

    let deadSnapshot = session([sessionState(id: "dead", health: 0)]).snapshot().agents[0]
    check("session snapshot isAlive derived", !deadSnapshot.isAlive)
    check("session snapshot distance home exact", snapshotAgent.distanceFromHome == 3)
    check("session snapshot memoryCount exact", snapshotAgent.memoryCount == 5)
    check("session snapshot recent memory limited", snapshotAgent.recentMemory.count == 3)
    check("session snapshot recent memory order",
          snapshotAgent.recentMemory.map { $0.tick } == [3, 4, 5])

    var mutableSource = snapshotMemories
    let independentSnapshot = session([
        sessionState(id: "copy", memory: mutableSource),
    ]).snapshot()
    mutableSource.append(sessionMemory(6))
    check("session snapshot independent source copy",
          independentSnapshot.agents[0].memoryCount == 5 && mutableSource.count == 6)
    check("session snapshot deterministic equality", snapshotSession.snapshot() == snapshotSession.snapshot())

    let snapshotEncoder = JSONEncoder()
    snapshotEncoder.outputFormatting = [.sortedKeys]
    let snapshotJSON1 = try? snapshotEncoder.encode(snapshotSession.snapshot())
    let snapshotJSON2 = try? snapshotEncoder.encode(snapshotSession.snapshot())
    check("session snapshot JSON deterministic", snapshotJSON1 != nil && snapshotJSON1 == snapshotJSON2)

    var tickSession = session([
        sessionState(id: "agent_b", x: 4, curiosity: 0.1),
        sessionState(id: "agent_a", x: 0, curiosity: 0.9),
    ])
    let tickBefore = tickSession.snapshot()
    let tickResult = try! tickSession.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_a",
            observationCountIncrement: 1,
            externalMemoryEntries: [sessionMemory(1, type: "observed")]
        ),
        AgentPerceptionInput(
            agentId: "agent_b",
            observationCountIncrement: 1,
            externalMemoryEntries: [sessionMemory(1, type: "observed")]
        ),
    ])
    let tickAfter = tickSession.snapshot()
    check("session tick increments once", tickResult.tick == 1 && tickAfter.tick == 1)
    check("session tick evolves needs",
          tickAfter.agents[0].needs.hunger == tickBefore.agents[0].needs.hunger + 0.01)
    check("session tick nearby from start snapshot",
          tickAfter.agents.allSatisfy { $0.nearbyAgents.count == 1 })
    check("session tick nearby excludes same id",
          tickAfter.agents.allSatisfy { agent in
              !agent.nearbyAgents.contains { $0.id == agent.id }
          })
    check("session tick selects goal", tickAfter.agents[0].currentGoal.kind == .explore)
    check("session tick chooses action", tickAfter.agents[0].lastAction?.name == "move_abstract")
    check("session tick applies effect",
          tickAfter.agents[0].lastActionEffect?.effect == "curiosity -0.005")
    check("session tick increments counters",
          tickAfter.agents.allSatisfy {
              $0.ticksAlive == 1 && $0.observationCount == 1
                  && $0.goalSelectionCount == 1 && $0.actionCount == 1
                  && $0.actionEffectCount == 1
          })
    check("session tick appends action memory",
          tickAfter.agents[0].recentMemory.contains { $0.type == "action_chosen" })
    check("session tick appends effect memory",
          tickAfter.agents[0].recentMemory.contains { $0.type == "action_effect_applied" })

    var identicalSession1 = session(threeStates)
    var identicalSession2 = session(threeStates)
    _ = try! identicalSession1.advanceTick()
    _ = try! identicalSession2.advanceTick()
    check("session tick identical sessions deterministic",
          identicalSession1.snapshot() == identicalSession2.snapshot())

    var permutedSession1 = session(permutedStates)
    var permutedSession2 = session(Array(permutedStates.reversed()))
    _ = try! permutedSession1.advanceTick()
    _ = try! permutedSession2.advanceTick()
    check("session tick permuted input deterministic",
          permutedSession1.snapshot() == permutedSession2.snapshot())
    check("session tick earlier agent does not alter later perception",
          tickAfter.agents[0].nearbyAgents.first?.id == "agent_b"
              && tickAfter.agents[1].nearbyAgents.first?.id == "agent_a")

    var externalSession = session([
        sessionState(id: "external_a", x: 0, memory: [sessionMemory(0)]),
        sessionState(id: "external_b", x: 2),
    ])
    try! externalSession.applyExternalUpdate(AgentExternalUpdate(
        agentId: "external_a",
        position: AgentPosition(x: 5, y: 64, z: 0),
        memoryEntries: [sessionMemory(1, type: "moved_abstract")],
        movementCount: 1,
        totalManhattanDistanceMoved: 5,
        returnHomeMoveCount: 1,
        totalDistanceReducedTowardHome: 2
    ))
    let externalSnapshot = externalSession.snapshot()
    let externalA = externalSnapshot.agents.first { $0.id == "external_a" }!
    let externalB = externalSnapshot.agents.first { $0.id == "external_b" }!
    check("session external position synchronized", externalA.position.x == 5)
    check("session external memory synchronized", externalA.memoryCount == 2)
    check("session external movement count synchronized", externalA.movementCount == 1)
    check("session external distance home updated", externalA.distanceFromHome == 5)
    check("session external next snapshot reflects update",
          externalA.totalManhattanDistanceMoved == 5
              && externalA.returnHomeMoveCount == 1
              && externalA.totalDistanceReducedTowardHome == 2)
    do {
        try externalSession.applyExternalUpdate(AgentExternalUpdate(agentId: "unknown"))
        check("session external unknown agent refused", false)
    } catch AgentSessionError.unknownAgentId("unknown") {
        check("session external unknown agent refused", true)
    } catch {
        check("session external unknown agent refused", false, "unexpected \(error)")
    }
    check("session external update isolates other agents",
          externalB.position.x == 2 && externalB.memoryCount == 0 && externalB.movementCount == 0)

    let manyMemories = (1...8).map { sessionMemory($0) }
    let legacySession = session([
        sessionState(id: "legacy", memory: manyMemories),
    ], configuration: sessionConfiguration(memoryPolicy: .legacyUnbounded))
    check("session memory legacy does not truncate", legacySession.snapshot().agents[0].memoryCount == 8)

    let boundedConfiguration = sessionConfiguration(
        recentMemorySnapshotLimit: 5,
        memoryPolicy: .bounded(maxEntries: 3)
    )
    var boundedSession = session([
        sessionState(id: "bounded", memory: manyMemories),
    ], configuration: boundedConfiguration)
    check("session memory bounded truncates maximum", boundedSession.snapshot().agents[0].memoryCount == 3)
    check("session memory bounded keeps latest",
          boundedSession.snapshot().agents[0].recentMemory.map { $0.tick } == [6, 7, 8])
    let boundedBefore = boundedSession.snapshot()
    try! boundedSession.applyExternalUpdate(AgentExternalUpdate(
        agentId: "bounded",
        memoryEntries: [sessionMemory(9)]
    ))
    check("session memory bounded remains deterministic",
          boundedBefore.agents[0].recentMemory.map { $0.tick } == [6, 7, 8]
              && boundedSession.snapshot().agents[0].recentMemory.map { $0.tick } == [7, 8, 9])
}

// ---------------------------------------------------------------------------
section("PebbleAgents read-only World perception")
do {
    let basePosition = AgentPosition(x: 10, y: 64, z: 20)

    func perceptionColumn(
        _ position: AgentPosition,
        ready: Bool = true,
        surface: Int? = 64,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true
    ) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: ready,
            surfaceY: ready ? surface : nil,
            height: ready ? surface : nil,
            blockBelow: ready ? (ground ? 16 : 0) : nil,
            blockAtFeet: ready ? (feet ? 0 : 16) : nil,
            blockAtHead: ready ? (head ? 0 : 16) : nil,
            groundPresent: ready && ground,
            feetClear: ready && feet,
            headClear: ready && head
        )
    }

    func perceptionObservation(
        position: AgentPosition = basePosition,
        centerReady: Bool = true,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true,
        traversable: [AgentCardinalDirection] = AgentCardinalDirection.allCases,
        drops: [AgentCardinalDirection] = [],
        light: Int? = 15,
        varied: Bool = false,
        worldTick: Int = 40
    ) -> AgentWorldObservation {
        let center = perceptionColumn(
            position,
            ready: centerReady,
            surface: 64,
            ground: ground,
            feet: feet,
            head: head
        )
        let neighbors = AgentCardinalDirection.allCases.reversed().map { direction -> AgentWorldNeighborObservation in
            let isDrop = drops.contains(direction)
            let delta = isDrop ? -2 : (varied && direction == .north ? 1 : 0)
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            return AgentWorldNeighborObservation(
                direction: direction,
                column: perceptionColumn(
                    neighborPosition,
                    surface: 64 + delta,
                    ground: !isDrop
                ),
                stepDelta: delta,
                traversable: traversable.contains(direction) && !isDrop,
                dangerousDrop: isDrop
            )
        }
        return try! AgentWorldObservation(
            worldTick: worldTick,
            position: position,
            center: center,
            neighbors: neighbors,
            biomeId: centerReady ? 1 : nil,
            biomeName: centerReady ? "plains" : nil,
            combinedLight: centerReady ? light : nil,
            skyLight: centerReady ? 15 : nil,
            blockLight: centerReady ? 0 : nil,
            dayTime: 6000,
            raining: false,
            thundering: false
        )
    }

    check("world cardinal canonical order",
          AgentCardinalDirection.allCases == [.north, .east, .south, .west])
    check("world north offset", AgentCardinalDirection.north.dx == 0 && AgentCardinalDirection.north.dz == -1)
    check("world east offset", AgentCardinalDirection.east.dx == 1 && AgentCardinalDirection.east.dz == 0)
    check("world south offset", AgentCardinalDirection.south.dx == 0 && AgentCardinalDirection.south.dz == 1)
    check("world west offset", AgentCardinalDirection.west.dx == -1 && AgentCardinalDirection.west.dz == 0)

    let stableObservation = perceptionObservation()
    check("world observation canonicalizes permuted neighbors",
          stableObservation.neighbors.map(\.direction) == [.north, .east, .south, .west])
    do {
        var duplicated = stableObservation.neighbors
        duplicated[3] = duplicated[0]
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: duplicated, biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation duplicate direction refused", false)
    } catch AgentWorldObservationError.duplicateDirection(.north) {
        check("world observation duplicate direction refused", true)
    } catch {
        check("world observation duplicate direction refused", false, "unexpected \(error)")
    }
    do {
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: Array(stableObservation.neighbors.prefix(3)), biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation missing neighbor refused", false)
    } catch AgentWorldObservationError.invalidNeighborCount(3) {
        check("world observation missing neighbor refused", true)
    } catch {
        check("world observation missing neighbor refused", false, "unexpected \(error)")
    }
    do {
        var invalid = stableObservation.neighbors
        invalid[0] = AgentWorldNeighborObservation(
            direction: .north,
            column: perceptionColumn(basePosition),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
        _ = try AgentWorldObservation(
            worldTick: 1, position: basePosition, center: stableObservation.center,
            neighbors: invalid, biomeId: 1, biomeName: "plains",
            combinedLight: 15, skyLight: 15, blockLight: 0,
            dayTime: 0, raining: false, thundering: false
        )
        check("world observation invalid neighbor position refused", false)
    } catch AgentWorldObservationError.invalidNeighborPosition(.north) {
        check("world observation invalid neighbor position refused", true)
    } catch {
        check("world observation invalid neighbor position refused", false, "unexpected \(error)")
    }
    let countedObservation = perceptionObservation(
        traversable: [.north, .south],
        drops: [.east]
    )
    check("world observation counters exact",
          countedObservation.traversableNeighborCount == 2
              && countedObservation.blockedNeighborCount == 2
              && countedObservation.dangerousDropCount == 1)
    let worldEncoder = JSONEncoder()
    worldEncoder.outputFormatting = [.sortedKeys]
    let worldJSON1 = try? worldEncoder.encode(stableObservation)
    let worldJSON2 = try? worldEncoder.encode(stableObservation)
    check("world observation JSON deterministic", worldJSON1 != nil && worldJSON1 == worldJSON2)
    check("world observation equality", stableObservation == perceptionObservation())

    func interpreted(
        _ observation: AgentWorldObservation,
        curiosity: Double = 0.2,
        safety: Double = 1,
        fear: Int = 10
    ) -> AgentWorldPerceptionEffect {
        AgentWorldPerceptionInterpreter.interpret(
            agentId: "agent_0",
            tick: 1,
            observation: observation,
            needs: AgentNeeds(hunger: 0.3, fatigue: 0.4, curiosity: curiosity, safety: safety),
            fear: fear
        )
    }

    let unavailableEffect = interpreted(perceptionObservation(centerReady: false))
    check("world interpreter chunk unavailable", unavailableEffect.reason == "center chunk unavailable" && unavailableEffect.safetyAfter == 0.20 && unavailableEffect.fearAfter == 18)
    let noGroundEffect = interpreted(perceptionObservation(ground: false))
    check("world interpreter no ground", noGroundEffect.reason == "no ground below" && noGroundEffect.safetyAfter == 0.10 && abs(noGroundEffect.curiosityAfter - 0.21) < 1e-12)
    let blockedEffect = interpreted(perceptionObservation(feet: false))
    check("world interpreter body blocked", blockedEffect.reason == "body space blocked" && blockedEffect.safetyAfter == 0.25)
    let multipleDropsEffect = interpreted(perceptionObservation(drops: [.north, .east]))
    check("world interpreter multiple drops", multipleDropsEffect.reason == "multiple nearby drops" && multipleDropsEffect.fearAfter == 15)
    let noTraversalEffect = interpreted(perceptionObservation(traversable: []))
    check("world interpreter no traversable neighbor", noTraversalEffect.reason == "no traversable neighbor" && noTraversalEffect.safetyAfter == 0.35)
    let oneDropEffect = interpreted(perceptionObservation(drops: [.west]))
    check("world interpreter one drop", oneDropEffect.reason == "nearby drop" && oneDropEffect.safetyAfter == 0.65)
    let darkEffect = interpreted(perceptionObservation(light: 3))
    check("world interpreter very low light", darkEffect.reason == "very low light" && darkEffect.fearAfter == 14)
    let flatEffect = interpreted(stableObservation)
    check("world interpreter stable flat terrain", flatEffect.reason == "local terrain stable" && abs(flatEffect.curiosityAfter - 0.205) < 1e-12)
    let variedEffect = interpreted(perceptionObservation(varied: true))
    check("world interpreter stable varied terrain", variedEffect.reason == "local terrain stable" && variedEffect.curiosityAfter == 0.22)
    check("world interpreter fear clamp zero", interpreted(stableObservation, fear: 0).fearAfter == 0)
    check("world interpreter fear clamp one hundred", interpreted(perceptionObservation(ground: false), fear: 99).fearAfter == 100)
    check("world interpreter curiosity clamp one", interpreted(perceptionObservation(drops: [.west]), curiosity: 0.99).curiosityAfter == 1)
    let immutableNeeds = AgentNeeds(hunger: 0.3, fatigue: 0.4, curiosity: 0.2, safety: 1)
    _ = AgentWorldPerceptionInterpreter.interpret(agentId: "agent_0", tick: 1, observation: stableObservation, needs: immutableNeeds, fear: 10)
    check("world interpreter hunger unchanged", immutableNeeds.hunger == 0.3)
    check("world interpreter fatigue unchanged", immutableNeeds.fatigue == 0.4)
    check("world interpreter memory summary deterministic",
          flatEffect.memorySummary == "agent_0 observed world: local terrain stable; traversable=4/4 blocked=0 drops=0 light=15")
    check("world interpreter importance critical", noGroundEffect.memoryImportance == 0.50)
    check("world interpreter importance caution", oneDropEffect.memoryImportance == 0.30)
    check("world interpreter importance stable", flatEffect.memoryImportance == 0.20)

    func phaseCState(id: String = "agent_0", memory: [AgentMemoryEntry] = []) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: basePosition,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
            health: 100,
            fear: 10,
            homePosition: basePosition,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: memory,
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 0,
            actionEffectCount: 0,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0
        )
    }

    func phaseCSession(
        policy: AgentMemoryPolicy = .legacyUnbounded
    ) -> AgentSimulationSession {
        let configuration = try! AgentSessionConfiguration(
            seed: 99,
            nearbyRadius: 8,
            recentMemorySnapshotLimit: 10,
            memoryPolicy: policy
        )
        return try! AgentSimulationSession(configuration: configuration, agents: [phaseCState()])
    }

    var worldSession = phaseCSession()
    let oldSnapshot = worldSession.snapshot()
    let worldResult = try! worldSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: noGroundEffect.reason == "no ground below" ? perceptionObservation(ground: false) : stableObservation),
    ])
    let perceived = worldSession.snapshot().agents[0]
    check("world session stores observation", perceived.lastWorldObservation?.worldTick == 40)
    check("world session stores effect", perceived.lastWorldPerceptionEffect?.reason == "no ground below")
    check("world session observation count automatic", perceived.observationCount == 1)
    check("world session safety before goal", perceived.needs.safety == 0.10)
    check("world session danger selects safety goal", perceived.currentGoal.kind == .seekSafety && perceived.currentGoal.reason == "safety < 0.5")
    check("world session adds observed memory", perceived.recentMemory.contains { $0.type == "world_observed" })
    check("world session memory order",
          worldResult.agents[0].memoriesAdded.map(\.type) == ["world_observed", "action_chosen", "action_effect_applied"])
    check("world session result contains effect", worldResult.agents[0].worldPerceptionEffect?.reason == "no ground below")
    check("world session snapshot contains perception", perceived.lastWorldObservation != nil && perceived.lastWorldPerceptionEffect != nil)
    check("world session old snapshot immutable", oldSnapshot.agents[0].lastWorldObservation == nil && oldSnapshot.agents[0].observationCount == 0)

    var mismatchSession = phaseCSession()
    let mismatchBefore = mismatchSession.snapshot()
    let mismatchObservation = perceptionObservation(position: AgentPosition(x: 11, y: 64, z: 20))
    do {
        _ = try mismatchSession.advanceTick(perceptions: [
            AgentPerceptionInput(agentId: "agent_0", worldObservation: mismatchObservation),
        ])
        check("world session position mismatch refused", false)
    } catch AgentSessionError.worldObservationPositionMismatch("agent_0") {
        check("world session position mismatch refused", true)
    } catch {
        check("world session position mismatch refused", false, "unexpected \(error)")
    }
    check("world session mismatch leaves tick unchanged", mismatchSession.snapshot().tick == 0)
    check("world session mismatch leaves state unchanged", mismatchSession.snapshot() == mismatchBefore)

    var legacyPathSession = phaseCSession()
    let legacyResult = try! legacyPathSession.advanceTick()
    check("world session absent observation preserves path",
          legacyResult.agents[0].worldPerceptionEffect == nil
              && legacyPathSession.snapshot().agents[0].lastWorldObservation == nil)
    let legacySnapshotJSON = (try? worldEncoder.encode(legacyPathSession.snapshot())).flatMap {
        String(data: $0, encoding: .utf8)
    } ?? ""
    check("world session absent observation omits new JSON keys",
          !legacySnapshotJSON.contains("lastWorldObservation")
              && !legacySnapshotJSON.contains("lastWorldPerceptionEffect"))
    var historicalInputSession = phaseCSession()
    _ = try! historicalInputSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", observationCountIncrement: 2),
    ])
    check("world session historical observation increment", historicalInputSession.snapshot().agents[0].observationCount == 2)

    var boundedWorldSession = phaseCSession(policy: .bounded(maxEntries: 2))
    _ = try! boundedWorldSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    check("world session bounded memory still truncates",
          boundedWorldSession.snapshot().agents[0].memoryCount == 2
              && boundedWorldSession.snapshot().agents[0].recentMemory.map(\.type) == ["action_chosen", "action_effect_applied"])

    var deterministicWorldSession1 = phaseCSession()
    var deterministicWorldSession2 = phaseCSession()
    _ = try! deterministicWorldSession1.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    _ = try! deterministicWorldSession2.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: stableObservation),
    ])
    check("world session deterministic identical inputs",
          deterministicWorldSession1.snapshot() == deterministicWorldSession2.snapshot())
}

}
