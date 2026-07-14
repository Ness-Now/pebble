import Foundation
import simd
import PebbleAgents
import PebbleCore

func runPebbleAgentsResourceSmoke() {
// ---------------------------------------------------------------------------
section("PebbleAgents autonomous adjacent resource harvest G2")
do {
    let observer = AgentPosition(x: 10, y: 64, z: 10)
    func resourceObservation(
        _ direction: AgentCardinalDirection,
        target: AgentPosition? = nil,
        quantity: Int = 1
    ) -> AgentResourceObservation {
        AgentResourceObservation(
            resource: .sandboxResource,
            target: target ?? AgentPosition(
                x: observer.x + direction.dx,
                y: observer.y,
                z: observer.z + direction.dz
            ),
            direction: direction,
            quantityAvailable: quantity,
            source: .sandboxFixture
        )
    }

    let north = resourceObservation(.north)
    let south = resourceObservation(.south)
    let normalized = try! AgentResourcePerception.normalize(
        observerPosition: observer,
        observations: [south, north]
    )
    check("G2 adjacent resource observation valid", normalized.count == 2)
    check("G2 resource observation order deterministic",
          normalized.map(\.direction) == [.north, .south])
    check("G2 resource observation contract exact",
          normalized[0].resource == .sandboxResource
              && normalized[0].quantityAvailable == 1
              && normalized[0].source == .sandboxFixture)
    check("G2 non-adjacent resource rejected", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [resourceObservation(
                    .east,
                    target: AgentPosition(x: observer.x + 2, y: observer.y, z: observer.z)
                )]
            )
            return false
        } catch AgentResourceObservationError.targetOutsideRadius { return true }
        catch { return false }
    }())
    check("G2 inconsistent resource direction rejected", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [resourceObservation(.north, target: south.target)]
            )
            return false
        } catch AgentResourceObservationError.directionMismatch { return true }
        catch { return false }
    }())
    check("G2 duplicate resource target rejected", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [north, north]
            )
            return false
        } catch AgentResourceObservationError.duplicateTarget { return true }
        catch { return false }
    }())
    check("G2 non-positive resource quantity rejected", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [resourceObservation(.north, quantity: 0)]
            )
            return false
        } catch AgentResourceObservationError.nonPositiveQuantity { return true }
        catch { return false }
    }())
    check("G2 perception defaults to no resource",
          AgentPerceptionInput(agentId: "agent_0").resourceObservations.isEmpty)

    func needs(
        fatigue: Double = 0,
        curiosity: Double = 0,
        safety: Double = 1
    ) -> AgentNeeds {
        AgentNeeds(hunger: 0, fatigue: fatigue, curiosity: curiosity, safety: safety)
    }
    func selectedGoal(
        health: Int = 100,
        fear: Int = 0,
        needs: AgentNeeds = AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        nearby: Bool = false,
        resource: Bool = true,
        capacity: Bool = true,
        current: AgentGoalKind = .idle
    ) -> AgentGoalChange? {
        AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
            tick: 9,
            health: health,
            fear: fear,
            needs: needs,
            hasNearbyAgents: nearby,
            hasCollectibleAdjacentResource: resource,
            hasInventoryCapacity: capacity,
            currentGoalKind: current
        ))
    }
    let collect = selectedGoal()
    check("G2 resource with capacity selects collect",
          collect?.goal.kind == .collectResource)
    check("G2 collect goal contract exact",
          collect?.goal.reason == "adjacent sandbox resource available"
              && collect?.goal.urgency == 65
              && collect?.goal.startedAtTick == 9)
    check("G2 full inventory prevents collect",
          selectedGoal(needs: needs(curiosity: 0.8), capacity: false)?.goal.kind == .explore)
    check("G2 critical health outranks resource",
          selectedGoal(health: 25)?.goal.kind == .seekSafety)
    check("G2 high fear outranks resource",
          selectedGoal(fear: 70)?.goal.kind == .seekSafety)
    check("G2 low safety outranks resource",
          selectedGoal(needs: needs(safety: 0.49))?.goal.kind == .seekSafety)
    check("G2 fatigue outranks resource",
          selectedGoal(needs: needs(fatigue: 0.02, curiosity: 0.9))?.goal.kind == .rest)
    check("G2 resource outranks curiosity",
          selectedGoal(needs: needs(curiosity: 0.9))?.goal.kind == .collectResource)
    check("G2 resource outranks nearby agent",
          selectedGoal(nearby: true)?.goal.kind == .collectResource)
    check("G2 resource disappearance leaves collect goal",
          selectedGoal(resource: false, current: .collectResource)?.goal.kind == .idle)

    let harvest = AgentActionDecider.decide(AgentActionDecisionInput(
        agentId: "agent_0",
        tick: 9,
        goalKind: .collectResource,
        position: observer,
        homePosition: observer,
        resourceObservations: [south, north]
    ))
    check("G2 collect produces harvest action", harvest.name == "harvest_block")
    check("G2 harvest target deterministic", harvest.target == north.target)
    check("G2 harvest resource exact", harvest.resource == .sandboxResource)
    check("G2 harvest reason exact",
          harvest.reason == "goal collectResource: adjacent sandbox resource")
    check("G2 harvest has no movement deltas",
          harvest.dx == nil && harvest.dy == nil && harvest.dz == nil)
    let harvestJSON = (try? JSONEncoder().encode(harvest)).flatMap {
        try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
    }
    check("G2 harvest JSON carries target and resource",
          harvestJSON?["resource"] as? String == "sandboxResource"
              && (harvestJSON?["target"] as? [String: Any])?["x"] as? Int == north.target.x)

    func state(inventory: AgentResourceInventory = AgentResourceInventory()) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: "agent_0",
            state: "idle",
            position: observer,
            needs: needs(curiosity: 0.2),
            health: 100,
            fear: 0,
            homePosition: observer,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: [],
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
            totalDistanceReducedTowardHome: 0,
            resourceInventory: inventory
        )
    }
    func session(inventory: AgentResourceInventory = AgentResourceInventory()) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 99,
                memoryPolicy: .bounded(maxEntries: 32)
            ),
            agents: [state(inventory: inventory)]
        )
    }

    var loop = session()
    let inventoryBeforeTick = loop.snapshot().agents[0].resourceInventory
    let firstTick = try! loop.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", resourceObservations: [north]),
    ])
    let afterDecision = loop.snapshot().agents[0]
    check("G2 session tick selects collect and harvest",
          firstTick.agents[0].goalChange?.to == .collectResource
              && firstTick.agents[0].action.name == "harvest_block")
    check("G2 advanceTick does not mutate inventory",
          afterDecision.resourceInventory == inventoryBeforeTick)
    check("G2 harvest cognitive effect awaits outcome",
          afterDecision.state == "interacting"
              && afterDecision.lastActionEffect?.effect == "awaiting interaction outcome")
    check("G2 session snapshot exposes resource observation",
          afterDecision.lastResourceObservations == [north])
    let movement = AgentMovementCoordinator.resolve(snapshot: loop.snapshot())[0]
    check("G2 harvest never becomes movement",
          movement.status == .notRequested
              && movement.fromPosition == movement.toPosition
              && movement.appliedDX == 0 && movement.appliedDY == 0 && movement.appliedDZ == 0)
    check("G2 harvest leaves movement count unchanged", afterDecision.movementCount == 0)

    let interactionId = "g2:agent_0:1"
    let successfulOutcome = AgentInteractionOutcome(
        interactionId: interactionId,
        agentId: "agent_0",
        tick: 1,
        target: north.target,
        resource: .sandboxResource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .sandboxResource, quantity: 1),
        reason: "sandbox resource harvested"
    )
    try! loop.prevalidateInteraction(AgentInteractionIntent(
        interactionId: interactionId,
        agentId: "agent_0",
        tick: 1,
        target: north.target,
        resource: .sandboxResource
    ))
    try! loop.applyInteractionOutcome(successfulOutcome)
    let afterOutcome = loop.snapshot().agents[0]
    check("G2 external outcome credits exactly once",
          afterOutcome.resourceInventory.totalCount == 1)
    check("G2 external outcome writes one harvest memory",
          afterOutcome.recentMemory.filter { $0.type == "resource_harvested" }.count == 1)
    let secondTick = try! loop.advanceTick(perceptions: [AgentPerceptionInput(agentId: "agent_0")])
    let afterSecondTick = loop.snapshot().agents[0]
    check("G2 next tick does not repeat harvest",
          secondTick.agents[0].action.name != "harvest_block"
              && afterSecondTick.currentGoal.kind != .collectResource)
    check("G2 next tick gives no second credit",
          afterSecondTick.resourceInventory.totalCount == 1)
    check("G2 next tick gives no second harvest memory",
          afterSecondTick.recentMemory.filter { $0.type == "resource_harvested" }.count == 1)

    var full = AgentResourceInventory(capacity: 1)
    _ = full.add(.sandboxResource)
    var fullLoop = session(inventory: full)
    let fullTick = try! fullLoop.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", resourceObservations: [north]),
    ])
    check("G2 full session does not choose harvest",
          fullTick.agents[0].action.name != "harvest_block")

    var deterministicA = session()
    var deterministicB = session()
    let deterministicInput = [AgentPerceptionInput(agentId: "agent_0", resourceObservations: [south, north])]
    _ = try! deterministicA.advanceTick(perceptions: deterministicInput)
    _ = try! deterministicB.advanceTick(perceptions: deterministicInput)
    check("G2 identical runs are deterministic", deterministicA.snapshot() == deterministicB.snapshot())
}

// ---------------------------------------------------------------------------
section("PebbleAgents distant resource survey and target lock H1")
do {
    let observer = AgentPosition(x: 20, y: 70, z: 20)
    func observation(
        _ direction: AgentCardinalDirection,
        distance: Int,
        target: AgentPosition? = nil,
        reportedDistance: Int? = nil
    ) -> AgentResourceObservation {
        AgentResourceObservation(
            resource: .sandboxResource,
            target: target ?? AgentPosition(
                x: observer.x + direction.dx * distance,
                y: observer.y,
                z: observer.z + direction.dz * distance
            ),
            direction: direction,
            distanceManhattan: reportedDistance ?? distance,
            quantityAvailable: 1,
            source: .sandboxFixture
        )
    }

    check("H1 resource radius default is one", {
        let configuration = try! AgentSessionConfiguration(seed: 1, memoryPolicy: .legacyUnbounded)
        return configuration.resourceObservationRadius == 1
    }())
    check("H1 resource radius zero rejected", {
        do {
            _ = try AgentSessionConfiguration(seed: 1, resourceObservationRadius: 0, memoryPolicy: .legacyUnbounded)
            return false
        } catch AgentSessionError.invalidResourceObservationRadius(0) { return true }
        catch { return false }
    }())
    check("H1 resource radius nine rejected", {
        do {
            _ = try AgentSessionConfiguration(seed: 1, resourceObservationRadius: 9, memoryPolicy: .legacyUnbounded)
            return false
        } catch AgentSessionError.invalidResourceObservationRadius(9) { return true }
        catch { return false }
    }())
    check("H1 resource radius one accepted",
          (try? AgentSessionConfiguration(seed: 1, resourceObservationRadius: 1, memoryPolicy: .legacyUnbounded))?.resourceObservationRadius == 1)
    check("H1 resource radius eight accepted",
          (try? AgentSessionConfiguration(seed: 1, resourceObservationRadius: 8, memoryPolicy: .legacyUnbounded))?.resourceObservationRadius == 8)

    let adjacent = observation(.north, distance: 1)
    let northTwo = observation(.north, distance: 2)
    let eastTwo = observation(.east, distance: 2)
    let westFour = observation(.west, distance: 4)
    let southEight = observation(.south, distance: 8)
    check("H1 adjacent accepted at radius one",
          (try? AgentResourcePerception.normalize(observerPosition: observer, observations: [adjacent], maximumDistance: 1)) == [adjacent])
    check("H1 distance two refused at radius one", {
        do {
            _ = try AgentResourcePerception.normalize(observerPosition: observer, observations: [northTwo], maximumDistance: 1)
            return false
        } catch AgentResourceObservationError.targetOutsideRadius { return true }
        catch { return false }
    }())
    check("H1 distance two accepted at radius eight",
          (try? AgentResourcePerception.normalize(observerPosition: observer, observations: [northTwo], maximumDistance: 8)) == [northTwo])
    check("H1 distance eight accepted",
          (try? AgentResourcePerception.normalize(observerPosition: observer, observations: [southEight], maximumDistance: 8)) == [southEight])
    check("H1 distance nine refused", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [observation(.east, distance: 9)],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.targetOutsideRadius { return true }
        catch { return false }
    }())
    check("H1 vertical resource refused", {
        let target = AgentPosition(x: observer.x + 2, y: observer.y + 1, z: observer.z)
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [observation(.east, distance: 2, target: target, reportedDistance: 2)],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.verticalDifference { return true }
        catch { return false }
    }())
    check("H1 observer position resource refused", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [observation(.north, distance: 0, target: observer, reportedDistance: 0)],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.targetMatchesObserver { return true }
        catch { return false }
    }())
    check("H1 reported distance mismatch refused", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [observation(.west, distance: 4, reportedDistance: 3)],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.distanceMismatch { return true }
        catch { return false }
    }())
    check("H1 deterministic X priority direction",
          AgentResourcePerception.direction(
              observerPosition: observer,
              target: AgentPosition(x: observer.x + 3, y: observer.y, z: observer.z + 3)
          ) == .east)
    check("H1 inconsistent distant direction refused", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [AgentResourceObservation(
                    resource: .sandboxResource,
                    target: eastTwo.target,
                    direction: .west,
                    distanceManhattan: 2,
                    quantityAvailable: 1,
                    source: .sandboxFixture
                )],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.directionMismatch { return true }
        catch { return false }
    }())
    check("H1 duplicate distant target refused", {
        do {
            _ = try AgentResourcePerception.normalize(
                observerPosition: observer,
                observations: [northTwo, northTwo],
                maximumDistance: 8
            )
            return false
        } catch AgentResourceObservationError.duplicateTarget { return true }
        catch { return false }
    }())
    let ordered = try! AgentResourcePerception.normalize(
        observerPosition: observer,
        observations: [westFour, eastTwo, northTwo, adjacent],
        maximumDistance: 8
    )
    check("H1 observations sorted by distance", ordered.map(\.distanceManhattan) == [1, 2, 2, 4])
    check("H1 equal distance sorted by canonical direction", ordered[1].direction == .north && ordered[2].direction == .east)
    check("H1 maximum observations enforced", {
        let nine = (1...8).map { observation(.east, distance: $0) } + [observation(.west, distance: 1)]
        do {
            _ = try AgentResourcePerception.normalize(observerPosition: observer, observations: nine, maximumDistance: 8)
            return false
        } catch AgentResourceObservationError.tooManyObservations(9) { return true }
        catch { return false }
    }())

    let emptyInventory = AgentResourceInventory()
    let selected = AgentResourceTargeting.select(
        current: nil,
        observations: [westFour, eastTwo, adjacent, northTwo],
        inventory: emptyInventory,
        tick: 3
    )
    check("H1 closest target selected", selected?.target == adjacent.target)
    check("H1 target timestamps initialized", selected?.selectedAtTick == 3 && selected?.lastSeenAtTick == 3)
    let locked = AgentResourceTarget(
        resource: .sandboxResource,
        target: westFour.target,
        source: .sandboxFixture,
        distanceManhattan: 4,
        selectedAtTick: 1,
        lastSeenAtTick: 1
    )
    let retained = AgentResourceTargeting.select(
        current: locked,
        observations: ordered,
        inventory: emptyInventory,
        tick: 4
    )
    check("H1 existing target retained over closer candidate", retained?.target == westFour.target)
    check("H1 selected tick stable while retained", retained?.selectedAtTick == 1)
    check("H1 last seen tick advances", retained?.lastSeenAtTick == 4)
    let replaced = AgentResourceTargeting.select(
        current: locked,
        observations: [northTwo, eastTwo],
        inventory: emptyInventory,
        tick: 5
    )
    check("H1 disappeared target replaced deterministically", replaced?.target == northTwo.target)
    check("H1 no observation clears target",
          AgentResourceTargeting.select(current: locked, observations: [], inventory: emptyInventory, tick: 5) == nil)
    var fullInventory = AgentResourceInventory(capacity: 1)
    _ = fullInventory.add(.sandboxResource)
    check("H1 full inventory clears target",
          AgentResourceTargeting.select(current: locked, observations: [westFour], inventory: fullInventory, tick: 5) == nil)

    func state(
        inventory: AgentResourceInventory = AgentResourceInventory(),
        health: Int = 100,
        fear: Int = 0,
        fatigue: Double = 0,
        safety: Double = 1
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: "agent_h1",
            state: "idle",
            position: observer,
            needs: AgentNeeds(hunger: 0, fatigue: fatigue, curiosity: 0.9, safety: safety),
            health: health,
            fear: fear,
            homePosition: observer,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
            lastAction: nil,
            lastActionEffect: nil,
            memory: [],
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
            totalDistanceReducedTowardHome: 0,
            resourceInventory: inventory
        )
    }
    func session(_ initialState: AgentSessionAgentState = state()) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 51,
                resourceObservationRadius: 8,
                memoryPolicy: .bounded(maxEntries: 32)
            ),
            agents: [initialState]
        )
    }
    var distantSession = session()
    let first = try! distantSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_h1", resourceObservations: [westFour]),
    ])
    let firstSnapshot = distantSession.snapshot().agents[0]
    check("H1 distant target selects collect goal", firstSnapshot.currentGoal.kind == .collectResource)
    check("H1 distant target produces approach action", first.agents[0].action.name == "approach_resource")
    check("H1 approach target and resource exact",
          first.agents[0].action.target == westFour.target && first.agents[0].action.resource == .sandboxResource)
    check("H1 approach reason exact", first.agents[0].action.reason == "goal collectResource: distant target selected")
    check("H1 approach has no movement deltas",
          first.agents[0].action.dx == nil && first.agents[0].action.dy == nil && first.agents[0].action.dz == nil)
    check("H1 approach cognitive effect exact",
          firstSnapshot.state == "planning" && firstSnapshot.lastActionEffect?.effect == "awaiting bounded navigation")
    let movement = AgentMovementCoordinator.resolve(snapshot: distantSession.snapshot())[0]
    check("H1 approach movement not requested",
          movement.status == .notRequested && movement.fromPosition == movement.toPosition)
    check("H1 approach keeps inventory empty", firstSnapshot.resourceInventory.isEmpty)
    check("H1 approach writes no harvest memory",
          !firstSnapshot.recentMemory.contains { $0.type == "resource_harvested" })
    check("H1 approach keeps movement and position unchanged",
          firstSnapshot.movementCount == 0 && firstSnapshot.position == observer)
    let selectedAt = firstSnapshot.activeResourceTarget?.selectedAtTick
    _ = try! distantSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_h1", resourceObservations: [westFour]),
    ])
    let secondSnapshot = distantSession.snapshot().agents[0]
    check("H1 second tick retains target", secondSnapshot.activeResourceTarget?.target == westFour.target)
    check("H1 second tick selectedAt stable", secondSnapshot.activeResourceTarget?.selectedAtTick == selectedAt)
    check("H1 second tick lastSeen advances", secondSnapshot.activeResourceTarget?.lastSeenAtTick == 2)
    check("H1 second tick still no harvest or movement",
          secondSnapshot.lastAction?.name == "approach_resource"
              && secondSnapshot.resourceInventory.isEmpty
              && secondSnapshot.movementCount == 0)
    let third = try! distantSession.advanceTick(perceptions: [AgentPerceptionInput(agentId: "agent_h1")])
    let thirdSnapshot = distantSession.snapshot().agents[0]
    check("H1 missing observation clears target", thirdSnapshot.activeResourceTarget == nil)
    check("H1 missing observation exits approach", third.agents[0].action.name != "approach_resource")
    check("H1 distant sequence never harvested",
          thirdSnapshot.resourceInventory.isEmpty
              && !thirdSnapshot.recentMemory.contains { $0.type == "resource_harvested" })

    let adjacentTarget = AgentResourceTarget(
        resource: .sandboxResource,
        target: adjacent.target,
        source: .sandboxFixture,
        distanceManhattan: 1,
        selectedAtTick: 1,
        lastSeenAtTick: 1
    )
    let adjacentAction = AgentActionDecider.decide(AgentActionDecisionInput(
        agentId: "agent_h1",
        tick: 1,
        goalKind: .collectResource,
        position: observer,
        homePosition: observer,
        activeResourceTarget: adjacentTarget
    ))
    check("H1 preserves G2 adjacent harvest action", adjacentAction.name == "harvest_block")

    func priorityState(health: Int = 100, fear: Int = 0, fatigue: Double = 0) -> AgentSessionAgentState {
        state(health: health, fear: fear, fatigue: fatigue)
    }
    for (label, initialState, expected) in [
        ("health", priorityState(health: 25), AgentGoalKind.seekSafety),
        ("fear", priorityState(fear: 70), AgentGoalKind.seekSafety),
        ("safety", state(safety: 0.49), AgentGoalKind.seekSafety),
        ("fatigue", priorityState(fatigue: 0.02), AgentGoalKind.rest),
    ] {
        var prioritySession = session(initialState)
        _ = try! prioritySession.advanceTick(perceptions: [
            AgentPerceptionInput(agentId: "agent_h1", resourceObservations: [westFour]),
        ])
        let prioritySnapshot = prioritySession.snapshot().agents[0]
        check("H1 \(label) priority dominates target",
              prioritySnapshot.currentGoal.kind == expected && prioritySnapshot.activeResourceTarget != nil)
    }
}

}
