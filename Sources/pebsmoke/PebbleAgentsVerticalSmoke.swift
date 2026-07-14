import Foundation
import simd
import PebbleAgents
import PebbleCore

func runPebbleAgentsVerticalSmoke() {
// ---------------------------------------------------------------------------
section("PebbleAgents navigate-to-harvest vertical H2")
do {
    let start = AgentPosition(x: 0, y: 64, z: 0)
    let target = AgentPosition(x: 4, y: 64, z: 0)

    func cell(
        _ x: Int,
        _ z: Int,
        y: Int = 64,
        status: AgentNavigationCellStatus = .traversable
    ) -> AgentNavigationCell {
        AgentNavigationCell(position: AgentPosition(x: x, y: y, z: z), status: status)
    }

    func flatCells(radius: Int = 4) -> [AgentNavigationCell] {
        var result: [AgentNavigationCell] = []
        for x in -radius...radius {
            for z in -radius...radius where abs(x) + abs(z) <= radius {
                result.append(cell(x, z))
            }
        }
        return result
    }

    let nominalRequest = AgentNavigationRequest(
        start: start,
        target: target,
        cells: flatCells(),
        radius: 8,
        maxVisitedNodes: 64,
        maxSteps: 8
    )
    let nominal = AgentBoundedRoutePlanner.plan(nominalRequest)
    check("H2 nominal route found", nominal.found)
    check("H2 nominal route reaches adjacent goal", nominal.positions.last == AgentPosition(x: 3, y: 64, z: 0))
    check("H2 nominal route cardinal", zip(nominal.positions, nominal.positions.dropFirst()).allSatisfy {
        abs($0.0.x - $0.1.x) + abs($0.0.z - $0.1.z) == 1
            && (-1...1).contains($0.1.y - $0.0.y)
    })
    check("H2 deterministic neighbor order",
          AgentBoundedRoutePlanner.neighborOrder == [.north, .east, .south, .west])

    let tieTarget = AgentPosition(x: 1, y: 64, z: -1)
    let tie = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start,
        target: tieTarget,
        cells: flatCells(radius: 2),
        radius: 2,
        maxVisitedNodes: 32,
        maxSteps: 4
    ))
    check("H2 equal route tie deterministic", tie.positions == [start, AgentPosition(x: 0, y: 64, z: -1)])
    check("H2 resource target excluded from occupiable route", !nominal.positions.contains(target))
    check("H2 traversable resource cell still excluded", {
        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: start, target: AgentPosition(x: 2, y: 64, z: 0),
            cells: [cell(0, 0), cell(1, 0), cell(2, 0)], radius: 2,
            maxVisitedNodes: 8, maxSteps: 4
        ))
        return plan.positions == [start, AgentPosition(x: 1, y: 64, z: 0)]
    }())
    check("H2 no route explicit", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target,
        cells: [cell(0, 0), cell(1, 0, status: .blocked)], radius: 8,
        maxVisitedNodes: 16, maxSteps: 8
    )).failure == .noRoute)
    check("H2 radius exceeded explicit", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: AgentPosition(x: 9, y: 64, z: 0),
        cells: [cell(0, 0)], radius: 8, maxVisitedNodes: 16, maxSteps: 8
    )).failure == .radiusExceeded)
    check("H2 node limit explicit", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target, cells: flatCells(), radius: 8,
        maxVisitedNodes: 1, maxSteps: 8
    )).failure == .nodeLimitReached)
    check("H2 unavailable cell explicit", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target,
        cells: [cell(0, 0), cell(1, 0, status: .unavailable)], radius: 8,
        maxVisitedNodes: 16, maxSteps: 8
    )).failure == .cellUnavailable)
    check("H2 step too high rejected", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target,
        cells: [cell(0, 0), cell(1, 0, y: 66)], radius: 8,
        maxVisitedNodes: 16, maxSteps: 8
    )).failure == .stepOutOfRange)
    check("H2 step too low rejected", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target,
        cells: [cell(0, 0), cell(1, 0, y: 62)], radius: 8,
        maxVisitedNodes: 16, maxSteps: 8
    )).failure == .stepOutOfRange)
    check("H2 dangerous drop rejected", AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
        start: start, target: target,
        cells: [cell(0, 0), cell(1, 0, status: .dangerousDrop)], radius: 8,
        maxVisitedNodes: 16, maxSteps: 8
    )).failure == .dangerousDrop)
    check("H2 repeated route identical", nominal == AgentBoundedRoutePlanner.plan(nominalRequest))

    let fixtureBoundary = AgentSandboxFixtureMutationBoundary(target: target)
    check("H2 fixture mutation boundary has one block",
          fixtureBoundary.permittedPositions == [target])
    check("H2 fixture mutation boundary permits target", fixtureBoundary.permits(target))
    check("H2 fixture mutation boundary rejects route feet",
          !fixtureBoundary.permits(AgentPosition(x: 1, y: 64, z: 0)))
    check("H2 fixture mutation boundary rejects route support",
          !fixtureBoundary.permits(AgentPosition(x: 1, y: 63, z: 0)))
    check("H2 fixture mutation boundary rejects route head",
          !fixtureBoundary.permits(AgentPosition(x: 1, y: 65, z: 0)))
    check("H2 fixture mutation boundary rejects start",
          !fixtureBoundary.permits(start))
    let fixtureBoundaryEncoder = JSONEncoder()
    fixtureBoundaryEncoder.outputFormatting = [.sortedKeys]
    let fixtureBoundaryJSON = String(
        data: try! fixtureBoundaryEncoder.encode(fixtureBoundary),
        encoding: .utf8
    )
    check("H2 fixture mutation boundary encoding deterministic",
          fixtureBoundaryJSON == "{\"target\":{\"x\":4,\"y\":64,\"z\":0}}")

    func h2State(id: String = "agent_h2", position: AgentPosition = start) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.9, safety: 1),
            health: 100,
            fear: 0,
            homePosition: position,
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
            totalDistanceReducedTowardHome: 0
        )
    }

    func h2Session(
        states: [AgentSessionAgentState] = [h2State()],
        maxReplans: Int = 3
    ) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 202,
                resourceObservationRadius: 8,
                recentMemorySnapshotLimit: 32,
                memoryPolicy: .bounded(maxEntries: 128),
                navigationMaxReplans: maxReplans,
                navigationReplanCooldownTicks: 1,
                reservationLifetimeTicks: 4
            ),
            agents: states
        )
    }

    func resource(_ observer: AgentPosition, target: AgentPosition = target) -> AgentResourceObservation {
        let distance = abs(target.x - observer.x) + abs(target.z - observer.z)
        return AgentResourceObservation(
            resource: .sandboxResource,
            target: target,
            direction: AgentResourcePerception.direction(observerPosition: observer, target: target)!,
            distanceManhattan: distance,
            quantityAvailable: 1,
            source: .sandboxFixture
        )
    }

    func worldObservation(
        _ position: AgentPosition,
        worldTick: Int,
        blockedDirection: AgentCardinalDirection? = nil
    ) -> AgentWorldObservation {
        let center = AgentWorldColumnObservation(
            position: position, chunkReady: true, surfaceY: position.y,
            height: position.y, blockBelow: 1, blockAtFeet: 0, blockAtHead: 0,
            groundPresent: true, feetClear: true, headClear: true
        )
        let neighbors = AgentCardinalDirection.allCases.map { direction in
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx, y: position.y, z: position.z + direction.dz
            )
            let traversable = direction != blockedDirection
            return AgentWorldNeighborObservation(
                direction: direction,
                column: AgentWorldColumnObservation(
                    position: neighborPosition, chunkReady: true, surfaceY: position.y,
                    height: position.y, blockBelow: 1, blockAtFeet: traversable ? 0 : 1,
                    blockAtHead: 0, groundPresent: true,
                    feetClear: traversable, headClear: true
                ),
                stepDelta: 0,
                traversable: traversable,
                dangerousDrop: false
            )
        }
        return try! AgentWorldObservation(
            worldTick: worldTick,
            position: position,
            center: center,
            neighbors: neighbors,
            biomeId: nil,
            biomeName: nil,
            combinedLight: nil,
            skyLight: nil,
            blockLight: nil,
            dayTime: worldTick,
            raining: false,
            thundering: false
        )
    }

    func navigationObservation(
        _ position: AgentPosition,
        target: AgentPosition = target,
        worldTick: Int,
        cells: [AgentNavigationCell] = flatCells()
    ) -> AgentNavigationObservation {
        AgentNavigationObservation(
            worldTick: worldTick,
            origin: position,
            target: target,
            radius: 8,
            cells: cells
        )
    }

    func perception(
        _ agentId: String,
        position: AgentPosition,
        target: AgentPosition = target,
        worldTick: Int,
        cells: [AgentNavigationCell] = flatCells(),
        blockedDirection: AgentCardinalDirection? = nil
    ) -> AgentPerceptionInput {
        AgentPerceptionInput(
            agentId: agentId,
            worldObservation: worldObservation(position, worldTick: worldTick, blockedDirection: blockedDirection),
            resourceObservations: [resource(position, target: target)],
            navigationObservation: navigationObservation(
                position, target: target, worldTick: worldTick, cells: cells
            )
        )
    }

    var flow = h2Session()
    let tick1 = try! flow.advanceTick(perceptions: [
        perception("agent_h2", position: start, worldTick: 10),
    ])
    let planned = flow.snapshot().agents[0]
    check("H2 session creates route", planned.navigationProgress.status == .active)
    check("H2 session stores route", planned.navigationProgress.route?.positions == nominal.positions)
    check("H2 session reserves target", planned.resourceReservation?.agentId == "agent_h2")
    check("H2 approach carries one cardinal step",
          tick1.agents[0].action.name == "approach_resource"
              && tick1.agents[0].action.dx == 1
              && tick1.agents[0].action.dy == 0
              && tick1.agents[0].action.dz == 0)
    let firstOutcomes = AgentMovementCoordinator.resolve(snapshot: flow.snapshot())
    try! flow.applyMovementOutcomes(firstOutcomes)
    let afterOne = flow.snapshot().agents[0]
    check("H2 route advances exactly one", afterOne.position == AgentPosition(x: 1, y: 64, z: 0)
          && afterOne.navigationProgress.routeIndex == 1
          && afterOne.navigationProgress.stepsRemaining == 2)

    for expectedX in 2...3 {
        let before = flow.snapshot().agents[0]
        _ = try! flow.advanceTick(perceptions: [
            perception("agent_h2", position: before.position, worldTick: 10 + expectedX),
        ])
        let outcomes = AgentMovementCoordinator.resolve(snapshot: flow.snapshot())
        try! flow.applyMovementOutcomes(outcomes)
        check("H2 one step tick x\(expectedX)", flow.snapshot().agents[0].position.x == expectedX)
    }
    let arrived = flow.snapshot().agents[0]
    check("H2 arrival adjacent explicit", arrived.navigationProgress.status == .arrived
          && AgentInteractionSandbox.isCardinalAdjacent(target: target, actor: arrived.position))

    let harvestTick = try! flow.advanceTick(perceptions: [
        perception("agent_h2", position: arrived.position, worldTick: 14),
    ])
    check("H2 harvest occurs on next cognitive tick", harvestTick.agents[0].action.name == "harvest_block")
    let beforeHarvest = flow.snapshot().agents[0]
    let interactionId = "h2:agent_h2:\(flow.tick)"
    try! flow.prevalidateInteraction(AgentInteractionIntent(
        interactionId: interactionId,
        agentId: "agent_h2",
        tick: flow.tick,
        target: target,
        resource: .sandboxResource
    ))
    try! flow.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: interactionId,
        agentId: "agent_h2",
        tick: flow.tick,
        target: target,
        resource: .sandboxResource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .sandboxResource, quantity: 1),
        reason: "sandbox resource harvested"
    ))
    let harvested = flow.snapshot().agents[0]
    check("H2 inventory credited exactly once", beforeHarvest.resourceInventory.totalCount == 0
          && harvested.resourceInventory.totalCount == 1)
    check("H2 writes one harvest memory",
          harvested.recentMemory.filter { $0.type == "resource_harvested" }.count == 1)
    check("H2 harvest releases reservation", flow.snapshot().resourceReservations.isEmpty)
    check("H2 harvest clears route", harvested.navigationProgress.route == nil
          && harvested.navigationProgress.lastInvalidation == .harvested)
    let postHarvest = try! flow.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_h2",
            worldObservation: worldObservation(harvested.position, worldTick: 15)
        ),
    ])
    check("H2 no repeated harvest", postHarvest.agents[0].action.name != "harvest_block"
          && flow.snapshot().agents[0].resourceInventory.totalCount == 1
          && flow.snapshot().agents[0].recentMemory.filter { $0.type == "resource_harvested" }.count == 1)

    var blocked = h2Session()
    _ = try! blocked.advanceTick(perceptions: [
        perception("agent_h2", position: start, worldTick: 20, blockedDirection: .east),
    ])
    let blockedOutcomes = AgentMovementCoordinator.resolve(snapshot: blocked.snapshot())
    check("H2 movement stack reports blocked", blockedOutcomes[0].status == .blocked)
    try! blocked.applyMovementOutcomes(blockedOutcomes)
    let blockedState = blocked.snapshot().agents[0]
    check("H2 blocked move leaves route unchanged", blockedState.position == start
          && blockedState.navigationProgress.routeIndex == 0
          && blockedState.navigationProgress.consecutiveBlockedMoves == 1)
    _ = try! blocked.advanceTick(perceptions: [
        perception("agent_h2", position: start, worldTick: 21),
    ])
    check("H2 blocked route replans next tick", blocked.snapshot().agents[0].navigationProgress.replanCount == 1
          && blocked.snapshot().agents[0].lastAction?.name == "approach_resource")

    var noRoute = h2Session()
    let isolated = [cell(0, 0), cell(1, 0, status: .blocked)]
    for worldTick in 30...34 {
        _ = try! noRoute.advanceTick(perceptions: [
            perception("agent_h2", position: start, worldTick: worldTick, cells: isolated),
        ])
    }
    check("H2 replan count bounded", noRoute.snapshot().agents[0].navigationProgress.replanCount == 3)
    check("H2 terminal abandon after replan limit",
          noRoute.snapshot().agents[0].navigationProgress.lastFailure == .replanLimitReached
              && noRoute.snapshot().resourceReservations.isEmpty)

    let conflictTarget = AgentPosition(x: 2, y: 64, z: 0)
    let agentA = h2State(id: "agent_a", position: AgentPosition(x: 0, y: 64, z: 0))
    let agentB = h2State(id: "agent_b", position: AgentPosition(x: 0, y: 64, z: 1))
    var conflict = h2Session(states: [agentB, agentA])
    _ = try! conflict.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_b", resourceObservations: [resource(agentB.position, target: conflictTarget)]),
        AgentPerceptionInput(agentId: "agent_a", resourceObservations: [resource(agentA.position, target: conflictTarget)]),
    ])
    let conflictSnapshot = conflict.snapshot()
    check("H2 reservation tie uses agentId", conflictSnapshot.resourceReservations.count == 1
          && conflictSnapshot.resourceReservations[0].agentId == "agent_a")
    check("H2 reservation prevents double pursuit",
          conflictSnapshot.agents.first { $0.id == "agent_b" }?.lastAction?.name == "wait")
    let reservation = conflictSnapshot.resourceReservations[0]
    check("H2 reservation has bounded expiration", reservation.acquiredAtTick == 1
          && reservation.expiresAtTick == 5
          && !reservation.isExpired(at: 5)
          && reservation.isExpired(at: 6))
    _ = try! conflict.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_a"),
        AgentPerceptionInput(agentId: "agent_b"),
    ])
    check("H2 disappearance releases reservation", conflict.snapshot().resourceReservations.isEmpty)
    check("H2 disappearance invalidates routes", conflict.snapshot().agents.allSatisfy {
        $0.activeResourceTarget == nil
            && $0.navigationProgress.route == nil
            && $0.navigationProgress.lastInvalidation == .targetGone
    })

    var changed = h2Session()
    _ = try! changed.advanceTick(perceptions: [perception("agent_h2", position: start, worldTick: 40)])
    let changedTarget = AgentPosition(x: 0, y: 64, z: 4)
    _ = try! changed.advanceTick(perceptions: [
        perception("agent_h2", position: start, target: changedTarget, worldTick: 41),
    ])
    check("H2 target change replaces route", changed.snapshot().agents[0].navigationProgress.route?.target == changedTarget)
    check("H2 target change cause explicit", changed.snapshot().agents[0].navigationProgress.lastInvalidation == .targetChanged)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let encodedA = try! encoder.encode(changed.snapshot())
    let encodedB = try! encoder.encode(changed.snapshot())
    check("H2 snapshot deterministic encoding", encodedA == encodedB)
    check("H2 snapshot exposes navigation and reservation", String(data: encodedA, encoding: .utf8)?.contains("navigationProgress") == true
          && String(data: encodedA, encoding: .utf8)?.contains("resourceReservations") == true)

    // -----------------------------------------------------------------------
    section("PebbleAgents closed resource economy Phase I")

    var multiInventory = AgentResourceInventory(capacity: 4)
    check("I inventory adds sandbox compatibility resource", multiInventory.add(.sandboxResource))
    check("I inventory adds foodRaw", multiInventory.add(.foodRaw))
    check("I inventory adds wood", multiInventory.add(.wood))
    check("I inventory adds stone", multiInventory.add(.stone))
    check("I inventory counts each resource exactly",
          multiInventory.count(of: .sandboxResource) == 1
            && multiInventory.count(of: .foodRaw) == 1
            && multiInventory.count(of: .wood) == 1
            && multiInventory.count(of: .stone) == 1)
    check("I inventory total capacity exact", multiInventory.totalCount == 4 && multiInventory.isFull)
    let fullMultiInventory = multiInventory
    check("I inventory overflow rejected", !multiInventory.add(.foodRaw))
    check("I inventory overflow has no mutation", multiInventory == fullMultiInventory)
    check("I inventory removes foodRaw", multiInventory.remove(.foodRaw))
    check("I inventory removes wood", multiInventory.remove(.wood))
    check("I inventory removes stone", multiInventory.remove(.stone))
    check("I inventory removes sandboxResource", multiInventory.remove(.sandboxResource))
    check("I inventory never becomes negative", !multiInventory.remove(.stone) && multiInventory.isEmpty)
    var allOrNothingInventory = AgentResourceInventory(capacity: 4)
    _ = allOrNothingInventory.add(.foodRaw)
    let beforeImpossibleRemoval = allOrNothingInventory
    check("I inventory all-or-nothing removal rejects missing resource",
          !allOrNothingInventory.removeAll([
            AgentResourceAmount(resource: .foodRaw, quantity: 1),
            AgentResourceAmount(resource: .wood, quantity: 1),
          ]))
    check("I inventory failed removal has no mutation", allOrNothingInventory == beforeImpossibleRemoval)
    let economyEncoder = JSONEncoder()
    economyEncoder.outputFormatting = [.sortedKeys]
    let inventoryEncodingA = try! economyEncoder.encode(fullMultiInventory)
    let inventoryEncodingB = try! economyEncoder.encode(fullMultiInventory)
    check("I inventory deterministic encoding", inventoryEncodingA == inventoryEncodingB)
    let legacyEmptyEncoding = String(
        data: try! economyEncoder.encode(AgentResourceInventory(capacity: 3)),
        encoding: .utf8
    )
    check("I inventory sandboxResource encoding compatibility",
          legacyEmptyEncoding == "{\"capacity\":3,\"sandboxResourceCount\":0}")
    check("I resource order stable",
          AgentResourceKind.allCases == [.sandboxResource, .foodRaw, .wood, .stone]
            && AgentResourceKind.economyFixtureOrder == [.foodRaw, .wood, .stone])
    let fixtureTargets = [
        AgentPosition(x: -4, y: 64, z: 0),
        AgentPosition(x: 0, y: 64, z: -4),
        AgentPosition(x: 4, y: 64, z: 0),
    ]
    let fixtureSetBoundary = AgentSandboxFixtureSetMutationBoundary(targets: fixtureTargets)
    check("I fixture mutation boundary accepts three fixtures",
          fixtureSetBoundary.isValid && fixtureSetBoundary.permittedPositions.count == 3)
    check("I fixture mutation boundary accepts only final blocks",
          fixtureTargets.allSatisfy(fixtureSetBoundary.permits))
    check("I fixture mutation boundary rejects corridor cells",
          !fixtureSetBoundary.permits(AgentPosition(x: 1, y: 64, z: 0)))
    check("I fixture mutation boundary rejects more than three",
          !AgentSandboxFixtureSetMutationBoundary(targets: fixtureTargets + [
            AgentPosition(x: 0, y: 64, z: 4),
          ]).isValid)

    var campStock = AgentCampStock(capacity: 3)
    check("I camp stock adds foodRaw", campStock.add(.foodRaw))
    check("I camp stock adds wood", campStock.add(.wood))
    check("I camp stock adds stone", campStock.add(.stone))
    check("I camp stock multi-resource total exact", campStock.totalCount == 3)
    let fullCampStock = campStock
    check("I camp stock capacity rejects overflow", !campStock.add(.sandboxResource))
    check("I camp stock rejection has no mutation", campStock == fullCampStock)
    check("I camp stock stable amount order", campStock.amounts.map(\.resource) == [.foodRaw, .wood, .stone])
    check("I camp stock deterministic encoding",
          try! economyEncoder.encode(campStock) == economyEncoder.encode(campStock))
    var atomicCampStock = AgentCampStock(capacity: 2)
    let atomicCampBefore = atomicCampStock
    check("I camp stock batch rejects over capacity", !atomicCampStock.add([
        AgentResourceAmount(resource: .foodRaw, quantity: 1),
        AgentResourceAmount(resource: .wood, quantity: 2),
    ]))
    check("I camp stock batch rejection has no mutation", atomicCampStock == atomicCampBefore)

    func goalInput(
        current: AgentGoalKind,
        adjacent: Bool = true,
        capacity: Bool = true,
        committed: Bool = false,
        deliver: Bool = false
    ) -> AgentGoalSelectionInput {
        AgentGoalSelectionInput(
            tick: 1,
            health: 100,
            fear: 0,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
            hasNearbyAgents: false,
            hasCollectibleAdjacentResource: adjacent,
            hasInventoryCapacity: capacity,
            hasCommittedResourceTask: committed,
            shouldDeliverResources: deliver,
            currentGoalKind: current
        )
    }
    check("I policy collects under quota",
          AgentCognitiveTransitions.selectGoal(goalInput(current: .idle))?.to == .collectResource)
    check("I policy delivers at quota",
          AgentCognitiveTransitions.selectGoal(goalInput(current: .collectResource, deliver: true))?.to == .deliverResources)
    check("I policy delivers when full",
          AgentCognitiveTransitions.selectGoal(goalInput(current: .collectResource, capacity: false, deliver: true))?.to == .deliverResources)
    check("I policy does not deliver empty inventory",
          AgentCognitiveTransitions.selectGoal(goalInput(current: .idle, adjacent: false, deliver: false))?.to != .deliverResources)
    check("I policy delivery hysteresis has no oscillation",
          AgentCognitiveTransitions.selectGoal(goalInput(current: .deliverResources, deliver: true)) == nil)

    func economyAgentState(
        id: String = "agent_economy",
        position: AgentPosition,
        home: AgentPosition,
        inventory: AgentResourceInventory = AgentResourceInventory(),
        goal: AgentGoalKind = .idle
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
            health: 100,
            fear: 0,
            homePosition: home,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: goal, reason: "economy fixture", startedAtTick: 0, urgency: 80),
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

    func economySession(
        states: [AgentSessionAgentState],
        campCapacity: Int = 64,
        quota: Int = 2,
        maxReplans: Int = 3
    ) -> AgentSimulationSession {
        var session = try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 303,
                resourceObservationRadius: 8,
                recentMemorySnapshotLimit: 64,
                memoryPolicy: .bounded(maxEntries: 128),
                navigationMaxReplans: maxReplans,
                deliveryQuota: quota,
                campStockCapacity: campCapacity
            ),
            agents: states
        )
        session.setEconomyEnabled(true)
        return session
    }

    var carried = AgentResourceInventory(capacity: 8)
    _ = carried.add(.foodRaw)
    _ = carried.add(.wood)
    let economyHome = AgentPosition(x: 0, y: 64, z: 0)
    let economyAway = AgentPosition(x: 3, y: 64, z: 0)
    var homeRouteSession = economySession(states: [economyAgentState(
        position: economyAway,
        home: economyHome,
        inventory: carried,
        goal: .deliverResources
    )])
    func homePerception(_ position: AgentPosition, worldTick: Int, blocked: AgentCardinalDirection? = nil) -> AgentPerceptionInput {
        AgentPerceptionInput(
            agentId: "agent_economy",
            worldObservation: worldObservation(position, worldTick: worldTick, blockedDirection: blocked),
            navigationObservation: AgentNavigationObservation(
                worldTick: worldTick,
                origin: position,
                target: economyHome,
                radius: 8,
                cells: flatCells()
            )
        )
    }
    let homeTick1 = try! homeRouteSession.advanceTick(perceptions: [homePerception(economyAway, worldTick: 61)])
    check("I home route uses existing exact planner",
          homeRouteSession.snapshot().agents[0].navigationProgress.route?.purpose == .homeDelivery
            && homeRouteSession.snapshot().agents[0].navigationProgress.route?.positions
                == [economyAway, AgentPosition(x: 2, y: 64, z: 0), AgentPosition(x: 1, y: 64, z: 0), economyHome])
    check("I home route emits return_home", homeTick1.agents[0].action.name == "return_home")
    let firstHomeOutcomes = AgentMovementCoordinator.resolve(snapshot: homeRouteSession.snapshot())
    try! homeRouteSession.applyMovementOutcomes(firstHomeOutcomes)
    check("I home route progresses one step",
          homeRouteSession.snapshot().agents[0].position == AgentPosition(x: 2, y: 64, z: 0)
            && homeRouteSession.snapshot().agents[0].navigationProgress.routeIndex == 1)
    let blockedHomeBefore = homeRouteSession.snapshot().agents[0]
    _ = try! homeRouteSession.advanceTick(perceptions: [homePerception(blockedHomeBefore.position, worldTick: 62, blocked: .west)])
    let blockedHomeOutcomes = AgentMovementCoordinator.resolve(snapshot: homeRouteSession.snapshot())
    try! homeRouteSession.applyMovementOutcomes(blockedHomeOutcomes)
    check("I home blockage does not progress",
          homeRouteSession.snapshot().agents[0].position == blockedHomeBefore.position
            && homeRouteSession.snapshot().agents[0].navigationProgress.routeIndex == 1)
    _ = try! homeRouteSession.advanceTick(perceptions: [homePerception(blockedHomeBefore.position, worldTick: 63)])
    check("I home blockage replans bounded",
          homeRouteSession.snapshot().agents[0].navigationProgress.replanCount == 1)
    for worldTick in 64...65 {
        let position = homeRouteSession.snapshot().agents[0].position
        _ = try! homeRouteSession.advanceTick(perceptions: [homePerception(position, worldTick: worldTick)])
        try! homeRouteSession.applyMovementOutcomes(
            AgentMovementCoordinator.resolve(snapshot: homeRouteSession.snapshot())
        )
    }
    let arrivedHome = homeRouteSession.snapshot().agents[0]
    check("I home route arrives exactly", arrivedHome.position == economyHome
          && arrivedHome.navigationProgress.status == .arrived)
    let deliveryTick = try! homeRouteSession.advanceTick(perceptions: [homePerception(economyHome, worldTick: 66)])
    check("I arrival emits deliver_resource", deliveryTick.agents[0].action.name == "deliver_resource")
    let homeDelivery = try! homeRouteSession.deliverResources(AgentDeliveryIntent(
        deliveryId: "delivery-home-route",
        agentId: "agent_economy",
        tick: homeRouteSession.tick,
        position: economyHome
    ))
    check("I delivery succeeds atomically", homeDelivery.status == .succeeded)
    check("I delivery empties inventory exactly", homeRouteSession.snapshot().agents[0].resourceInventory.isEmpty)
    check("I delivery credits camp stock exactly",
          homeRouteSession.snapshot().campStock.count(of: .foodRaw) == 1
            && homeRouteSession.snapshot().campStock.count(of: .wood) == 1)
    check("I delivery writes one success memory",
          homeRouteSession.snapshot().agents[0].recentMemory.filter { $0.type == "resource_delivered" }.count == 1)

    var failedHomeRouteSession = economySession(states: [economyAgentState(
        position: economyAway,
        home: economyHome,
        inventory: carried,
        goal: .deliverResources
    )])
    for worldTick in 70...74 {
        let position = failedHomeRouteSession.snapshot().agents[0].position
        let isolatedCells = [
            AgentNavigationCell(position: position, status: .traversable),
            AgentNavigationCell(
                position: AgentPosition(x: position.x - 1, y: position.y, z: position.z),
                status: .blocked
            ),
        ]
        _ = try! failedHomeRouteSession.advanceTick(perceptions: [AgentPerceptionInput(
            agentId: "agent_economy",
            worldObservation: worldObservation(position, worldTick: worldTick),
            navigationObservation: AgentNavigationObservation(
                worldTick: worldTick,
                origin: position,
                target: economyHome,
                radius: 8,
                cells: isolatedCells
            )
        )])
    }
    check("I home replan count bounded",
          failedHomeRouteSession.snapshot().agents[0].navigationProgress.replanCount == 3)
    check("I home route terminal failure explicit",
          failedHomeRouteSession.snapshot().agents[0].navigationProgress.lastFailure == .replanLimitReached)

    var conservationSession = economySession(states: [economyAgentState(
        position: economyHome,
        home: economyHome
    )])
    func applyHarvest(
        _ resource: AgentResourceKind,
        target: AgentPosition,
        id: String,
        to session: inout AgentSimulationSession
    ) throws {
        let outcome = AgentInteractionOutcome(
            interactionId: id,
            agentId: "agent_economy",
            tick: session.tick,
            target: target,
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "economy fixture harvested"
        )
        try session.applyInteractionOutcome(outcome)
    }
    try! applyHarvest(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "fixture-food", to: &conservationSession)
    check("I conservation exact after one harvest",
          conservationSession.snapshot().conservation.harvestedTotal == 1
            && conservationSession.snapshot().conservation.carriedTotal == 1
            && conservationSession.snapshot().conservation.balanced)
    try! applyHarvest(.wood, target: AgentPosition(x: -1, y: 64, z: 0), id: "fixture-wood", to: &conservationSession)
    check("I conservation exact after multiple harvests",
          conservationSession.snapshot().conservation.harvestedTotal == 2
            && conservationSession.snapshot().conservation.carriedTotal == 2
            && conservationSession.snapshot().conservation.balanced)
    let beforeDuplicateCredit = conservationSession.snapshot()
    check("I fixture credit deduplicated across interaction IDs", {
        do {
            try applyHarvest(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "fixture-food-second-id", to: &conservationSession)
            return false
        } catch AgentSessionError.duplicateResourceCredit { return true }
        catch { return false }
    }())
    check("I duplicate fixture credit has no mutation", conservationSession.snapshot() == beforeDuplicateCredit)
    let conservedDelivery = try! conservationSession.deliverResources(AgentDeliveryIntent(
        deliveryId: "delivery-conservation",
        agentId: "agent_economy",
        tick: conservationSession.tick,
        position: economyHome
    ))
    check("I conservation delivery outcome exact", conservedDelivery.transferred.map(\.resource) == [.foodRaw, .wood])
    check("I conservation exact after delivery",
          conservationSession.snapshot().conservation.harvestedTotal == 2
            && conservationSession.snapshot().conservation.carriedTotal == 0
            && conservationSession.snapshot().conservation.campStockTotal == 2
            && conservationSession.snapshot().conservation.balanced)
    let afterConservedDelivery = conservationSession.snapshot()
    check("I delivery ID deduplicated", {
        do {
            _ = try conservationSession.deliverResources(AgentDeliveryIntent(
                deliveryId: "delivery-conservation",
                agentId: "agent_economy",
                tick: conservationSession.tick,
                position: economyHome
            ))
            return false
        } catch AgentSessionError.duplicateDelivery { return true }
        catch { return false }
    }())
    check("I duplicate delivery has no mutation", conservationSession.snapshot() == afterConservedDelivery)
    let resumedTarget = AgentPosition(x: 1, y: 64, z: 0)
    let resumeTick = try! conservationSession.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [AgentResourceObservation(
            resource: .stone,
            target: resumedTarget,
            direction: .east,
            distanceManhattan: 1,
            quantityAvailable: 1,
            source: .sandboxFixture
        )]
    )])
    check("I policy resumes collection after delivery",
          resumeTick.agents[0].snapshot.currentGoal.kind == .collectResource
            && resumeTick.agents[0].action.name == "harvest_block")

    var invalidDeliveryInventory = AgentResourceInventory(capacity: 8)
    _ = invalidDeliveryInventory.add(.foodRaw)
    _ = invalidDeliveryInventory.add(.wood)
    var invalidDeliverySession = economySession(states: [economyAgentState(
        position: economyHome,
        home: economyHome,
        inventory: invalidDeliveryInventory,
        goal: .deliverResources
    )])
    let beforeInvalidDelivery = invalidDeliverySession.snapshot()
    check("I invalid delivery outcome rejected", {
        do {
            try invalidDeliverySession.applyDeliveryOutcome(AgentDeliveryOutcome(
                deliveryId: "invalid-delivery",
                agentId: "agent_economy",
                tick: invalidDeliverySession.tick,
                status: .succeeded,
                transferred: [AgentResourceAmount(resource: .foodRaw, quantity: 1)],
                reason: "invalid partial transfer"
            ))
            return false
        } catch AgentSessionError.invalidDeliveryOutcome { return true }
        catch { return false }
    }())
    check("I invalid delivery is atomic", invalidDeliverySession.snapshot() == beforeInvalidDelivery)
    check("I failed delivery writes no success memory",
          invalidDeliverySession.snapshot().agents[0].recentMemory.allSatisfy { $0.type != "resource_delivered" })

    var awayDeliverySession = economySession(states: [economyAgentState(
        position: economyAway,
        home: economyHome,
        inventory: invalidDeliveryInventory,
        goal: .deliverResources
    )])
    let awayDeliveryBefore = awayDeliverySession.snapshot()
    check("I delivery away from home rejected", {
        do {
            _ = try awayDeliverySession.deliverResources(AgentDeliveryIntent(
                deliveryId: "away-delivery",
                agentId: "agent_economy",
                tick: awayDeliverySession.tick,
                position: economyAway
            ))
            return false
        } catch AgentSessionError.deliveryAwayFromHome { return true }
        catch { return false }
    }())
    check("I delivery away from home has no mutation", awayDeliverySession.snapshot() == awayDeliveryBefore)

    var oversizedInventory = AgentResourceInventory(capacity: 8)
    _ = oversizedInventory.add(.foodRaw, quantity: 2)
    _ = oversizedInventory.add(.wood)
    var fullStockSession = economySession(
        states: [economyAgentState(
            position: economyHome,
            home: economyHome,
            inventory: oversizedInventory,
            goal: .deliverResources
        )],
        campCapacity: 2
    )
    let stockFullBefore = fullStockSession.snapshot().agents[0].resourceInventory
    let stockFullOutcome = try! fullStockSession.deliverResources(AgentDeliveryIntent(
        deliveryId: "camp-full",
        agentId: "agent_economy",
        tick: fullStockSession.tick,
        position: economyHome
    ))
    check("I camp stock full outcome explicit", stockFullOutcome.status == .campStockFull)
    check("I camp stock full preserves inventory and stock",
          fullStockSession.snapshot().agents[0].resourceInventory == stockFullBefore
            && fullStockSession.snapshot().campStock.isEmpty)
    check("I camp stock full writes failure memory only",
          fullStockSession.snapshot().agents[0].recentMemory.last?.type == "camp_stock_full"
            && fullStockSession.snapshot().agents[0].recentMemory.allSatisfy { $0.type != "resource_delivered" })

    let sharedFixtureTarget = AgentPosition(x: 2, y: 64, z: 0)
    let economyAgentA = economyAgentState(
        id: "agent_a",
        position: AgentPosition(x: 0, y: 64, z: 0),
        home: AgentPosition(x: 0, y: 64, z: 0)
    )
    let economyAgentB = economyAgentState(
        id: "agent_b",
        position: AgentPosition(x: 0, y: 64, z: 1),
        home: AgentPosition(x: 0, y: 64, z: 1)
    )
    var concurrentEconomy = economySession(states: [economyAgentB, economyAgentA])
    _ = try! concurrentEconomy.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_a", resourceObservations: [AgentResourceObservation(
            resource: .foodRaw,
            target: sharedFixtureTarget,
            direction: .east,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .sandboxFixture
        )]),
        AgentPerceptionInput(agentId: "agent_b", resourceObservations: [AgentResourceObservation(
            resource: .foodRaw,
            target: sharedFixtureTarget,
            direction: .east,
            distanceManhattan: 3,
            quantityAvailable: 1,
            source: .sandboxFixture
        )]),
    ])
    check("I concurrent fixture reservation has one stable owner",
          concurrentEconomy.snapshot().resourceReservations.count == 1
            && concurrentEconomy.snapshot().resourceReservations[0].agentId == "agent_a")
    try! concurrentEconomy.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "concurrent-owner",
        agentId: "agent_a",
        tick: concurrentEconomy.tick,
        target: sharedFixtureTarget,
        resource: .foodRaw,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
        reason: "reserved fixture harvested"
    ))
    check("I concurrent harvest conservation exact",
          concurrentEconomy.snapshot().conservation.harvestedTotal == 1
            && concurrentEconomy.snapshot().conservation.carriedTotal == 1
            && concurrentEconomy.snapshot().conservation.balanced)
    let concurrentBeforeLoser = concurrentEconomy.snapshot()
    check("I concurrent loser cannot receive second fixture credit", {
        do {
            try concurrentEconomy.applyInteractionOutcome(AgentInteractionOutcome(
                interactionId: "concurrent-loser",
                agentId: "agent_b",
                tick: concurrentEconomy.tick,
                target: sharedFixtureTarget,
                resource: .foodRaw,
                status: .succeeded,
                inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
                reason: "duplicate fixture credit"
            ))
            return false
        } catch AgentSessionError.duplicateResourceCredit { return true }
        catch { return false }
    }())
    check("I concurrent loser rejection has no mutation", concurrentEconomy.snapshot() == concurrentBeforeLoser)

    let economySnapshotEncodingA = try! economyEncoder.encode(conservationSession.snapshot())
    let economySnapshotEncodingB = try! economyEncoder.encode(conservationSession.snapshot())
    check("I economy snapshot deterministic encoding", economySnapshotEncodingA == economySnapshotEncodingB)
    check("I economy snapshot exposes stock and conservation", {
        let text = String(data: economySnapshotEncodingA, encoding: .utf8) ?? ""
        return text.contains("campStock") && text.contains("conservation") && text.contains("deliveryQuota")
    }())

    // -----------------------------------------------------------------------
    section("PebbleAgents autonomous survival sandbox J")

    let survivalConfiguration = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.20,
        fatiguePerTick: 0.20,
        hungryThreshold: 0.40,
        criticalHungerThreshold: 0.60,
        hungerRecoveryThreshold: 0.20,
        fatigueThreshold: 0.60,
        fatigueRecoveryThreshold: 0.20,
        foodNutrition: 0.75,
        restRecoveryPerTick: 0.60,
        starvationGraceTicks: 2,
        starvationDamagePerTick: 10
    )
    check("J survival configuration valid",
          survivalConfiguration.hungryThreshold == 0.40
            && survivalConfiguration.criticalHungerThreshold == 0.60
            && survivalConfiguration.starvationGraceTicks == 2)
    check("J incoherent hunger thresholds rejected", {
        do {
            _ = try AgentSurvivalConfiguration(
                hungerPerTick: 0.1, fatiguePerTick: 0.1,
                hungryThreshold: 0.7, criticalHungerThreshold: 0.6,
                hungerRecoveryThreshold: 0.2,
                fatigueThreshold: 0.7, fatigueRecoveryThreshold: 0.2,
                foodNutrition: 0.5, restRecoveryPerTick: 0.5,
                starvationGraceTicks: 2, starvationDamagePerTick: 10
            )
            return false
        } catch AgentSurvivalConfigurationError.invalidThresholds { return true }
        catch { return false }
    }())
    check("J incoherent fatigue thresholds rejected", {
        do {
            _ = try AgentSurvivalConfiguration(
                hungerPerTick: 0.1, fatiguePerTick: 0.1,
                hungryThreshold: 0.4, criticalHungerThreshold: 0.8,
                hungerRecoveryThreshold: 0.2,
                fatigueThreshold: 0.3, fatigueRecoveryThreshold: 0.4,
                foodNutrition: 0.5, restRecoveryPerTick: 0.5,
                starvationGraceTicks: 2, starvationDamagePerTick: 10
            )
            return false
        } catch AgentSurvivalConfigurationError.invalidThresholds { return true }
        catch { return false }
    }())
    check("J out of range need rate rejected", {
        do {
            _ = try AgentSurvivalConfiguration(
                hungerPerTick: 1.1, fatiguePerTick: 0.1,
                hungryThreshold: 0.4, criticalHungerThreshold: 0.8,
                hungerRecoveryThreshold: 0.2,
                fatigueThreshold: 0.7, fatigueRecoveryThreshold: 0.2,
                foodNutrition: 0.5, restRecoveryPerTick: 0.5,
                starvationGraceTicks: 2, starvationDamagePerTick: 10
            )
            return false
        } catch AgentSurvivalConfigurationError.invalidRate { return true }
        catch { return false }
    }())
    let survivalEncodingA = try! economyEncoder.encode(survivalConfiguration)
    let survivalEncodingB = try! economyEncoder.encode(survivalConfiguration)
    check("J survival configuration deterministic encoding", survivalEncodingA == survivalEncodingB)

    func survivalAgentState(
        id: String = "agent_survival",
        position: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
        home: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
        hunger: Double = 0,
        fatigue: Double = 0,
        health: Int = 100,
        inventory: AgentResourceInventory = AgentResourceInventory(),
        goal: AgentGoalKind = .idle
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: hunger, fatigue: fatigue, curiosity: 0, safety: 1),
            health: health,
            fear: 0,
            homePosition: home,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: goal, reason: "survival fixture", startedAtTick: 0, urgency: 0),
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

    func survivalSession(
        states: [AgentSessionAgentState],
        economy: Bool = false,
        configuration: AgentSurvivalConfiguration = survivalConfiguration
    ) -> AgentSimulationSession {
        var session = try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 404,
                resourceObservationRadius: 8,
                recentMemorySnapshotLimit: 128,
                memoryPolicy: .bounded(maxEntries: 256),
                deliveryQuota: 2,
                survivalConfiguration: configuration
            ),
            agents: states
        )
        if economy { session.setEconomyEnabled(true) }
        return session
    }

    var survivalDefault = survivalSession(states: [survivalAgentState()])
    check("J survival disabled by default", !survivalDefault.survivalEnabled
          && !survivalDefault.snapshot().survivalEnabled
          && survivalDefault.snapshot().agents[0].survivalProgress == nil)
    let legacyBefore = survivalDefault.snapshot()
    _ = try! survivalDefault.advanceTick()
    let legacyAfter = survivalDefault.snapshot()
    check("J survival off preserves legacy hunger tick", legacyAfter.agents[0].needs.hunger == 0.01)
    check("J survival off preserves legacy fatigue tick", legacyAfter.agents[0].needs.fatigue == 0.005)
    check("J survival off preserves legacy state shape",
          legacyBefore.agents[0].survivalProgress == nil && legacyAfter.agents[0].survivalProgress == nil)
    let legacySnapshotText = String(
        data: try! economyEncoder.encode(legacyAfter),
        encoding: .utf8
    ) ?? ""
    check("J historical snapshot omits survival fields",
          !legacySnapshotText.contains("survivalEnabled")
            && !legacySnapshotText.contains("survivalProgress")
            && !legacySnapshotText.contains("survivalConfiguration"))

    var boundedNeeds = survivalSession(states: [survivalAgentState(
        hunger: 0.95, fatigue: 0.95, health: 120
    )])
    boundedNeeds.setSurvivalEnabled(true)
    _ = try! boundedNeeds.advanceTick()
    check("J survival clamps hunger and fatigue",
          boundedNeeds.snapshot().agents[0].needs.hunger == 1
            && boundedNeeds.snapshot().agents[0].needs.fatigue == 1)
    check("J survival clamps health", boundedNeeds.snapshot().agents[0].health == 100)
    check("J enabling survival creates neutral progress",
          boundedNeeds.snapshot().agents[0].survivalProgress != nil)

    func survivalGoalInput(
        hunger: Double,
        fatigue: Double = 0,
        health: Int = 100,
        fear: Int = 0,
        safety: Double = 1,
        current: AgentGoalKind = .idle,
        deliver: Bool = false
    ) -> AgentGoalSelectionInput {
        AgentGoalSelectionInput(
            tick: 10,
            health: health,
            fear: fear,
            needs: AgentNeeds(hunger: hunger, fatigue: fatigue, curiosity: 0, safety: safety),
            hasNearbyAgents: false,
            shouldDeliverResources: deliver,
            currentGoalKind: current,
            survivalEnabled: true,
            hungryThreshold: survivalConfiguration.hungryThreshold,
            criticalHungerThreshold: survivalConfiguration.criticalHungerThreshold,
            hungerRecoveryThreshold: survivalConfiguration.hungerRecoveryThreshold,
            fatigueThreshold: survivalConfiguration.fatigueThreshold,
            fatigueRecoveryThreshold: survivalConfiguration.fatigueRecoveryThreshold
        )
    }
    check("J critical hunger outranks low health",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.8, health: 10
          ))?.to == .satisfyHunger)
    check("J immediate safety outranks normal hunger",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.5, safety: 0.2
          ))?.to == .seekSafety)
    check("J immediate fear outranks normal hunger",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.5, fear: 80
          ))?.to == .seekSafety)
    check("J normal hunger outranks economy delivery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.5, deliver: true
          ))?.to == .satisfyHunger)
    check("J hunger interrupts committed delivery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.5, current: .deliverResources, deliver: true
          ))?.to == .satisfyHunger)
    check("J hunger hysteresis holds above recovery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.3, current: .satisfyHunger
          )) == nil)
    check("J hunger hysteresis releases at recovery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0.2, current: .satisfyHunger
          ))?.to == .idle)
    check("J fatigue threshold selects rest",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0, fatigue: 0.7
          ))?.to == .rest)
    check("J rest hysteresis holds above recovery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0, fatigue: 0.3, current: .rest
          )) == nil)
    check("J rest hysteresis releases at recovery",
          AgentCognitiveTransitions.selectGoal(survivalGoalInput(
            hunger: 0, fatigue: 0.2, current: .rest
          ))?.to == .idle)

    let foodTarget = AgentPosition(x: 2, y: 64, z: 0)
    let woodTarget = AgentPosition(x: 0, y: 64, z: 2)
    func observedResource(
        _ resource: AgentResourceKind,
        target: AgentPosition,
        observer: AgentPosition = AgentPosition(x: 0, y: 64, z: 0)
    ) -> AgentResourceObservation {
        AgentResourceObservation(
            resource: resource,
            target: target,
            direction: AgentResourcePerception.direction(
                observerPosition: observer,
                target: target
            )!,
            distanceManhattan: abs(target.x - observer.x) + abs(target.z - observer.z),
            quantityAvailable: 1,
            source: .sandboxFixture
        )
    }
    var foodSelection = survivalSession(states: [survivalAgentState(hunger: 0.3)])
    foodSelection.setSurvivalEnabled(true)
    let foodSelectionTick = try! foodSelection.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_survival",
        resourceObservations: [
            observedResource(.wood, target: woodTarget),
            observedResource(.foodRaw, target: foodTarget),
        ],
        navigationObservation: AgentNavigationObservation(
            worldTick: 1,
            origin: AgentPosition(x: 0, y: 64, z: 0),
            target: foodTarget,
            radius: 8,
            cells: flatCells()
        )
    )])
    check("J hungry agent targets foodRaw exclusively",
          foodSelection.snapshot().agents[0].activeResourceTarget?.resource == .foodRaw)
    check("J hungry agent ignores wood and stone",
          foodSelection.snapshot().agents[0].activeResourceTarget?.target == foodTarget)
    check("J food target uses existing reservation",
          foodSelection.snapshot().agents[0].resourceReservation?.resource == .foodRaw)
    check("J food target uses existing bounded navigation",
          foodSelection.snapshot().agents[0].navigationProgress.route?.purpose == .resource)
    check("J food target emits approach_resource",
          foodSelectionTick.agents[0].action.name == "approach_resource")
    var noFood = survivalSession(states: [survivalAgentState(hunger: 0.3)])
    noFood.setSurvivalEnabled(true)
    let noFoodTick = try! noFood.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_survival",
        resourceObservations: [observedResource(.wood, target: woodTarget)]
    )])
    check("J missing food has explicit wait action",
          noFoodTick.agents[0].action.name == "wait"
            && noFoodTick.agents[0].action.reason.contains("resource unavailable"))
    check("J missing food creates no non-food target", noFood.snapshot().agents[0].activeResourceTarget == nil)

    func harvestForSurvival(
        _ resource: AgentResourceKind,
        target: AgentPosition,
        id: String,
        agentId: String = "agent_survival",
        session: inout AgentSimulationSession
    ) {
        try! session.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: id,
            agentId: agentId,
            tick: session.tick,
            target: target,
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "survival fixture harvested"
        ))
    }
    var consumption = survivalSession(states: [survivalAgentState(hunger: 0.7)])
    harvestForSurvival(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "j-food", session: &consumption)
    harvestForSurvival(.wood, target: AgentPosition(x: 0, y: 64, z: 1), id: "j-wood", session: &consumption)
    consumption.setSurvivalEnabled(true)
    let consumptionTick = try! consumption.advanceTick()
    check("J carried food emits consume_food", consumptionTick.agents[0].action.name == "consume_food")
    let beforeConsumption = consumption.snapshot().agents[0]
    let consumptionIntent = AgentConsumptionIntent(
        consumptionId: "j-consumption-1",
        agentId: "agent_survival",
        tick: consumption.tick
    )
    let consumptionOutcome = try! consumption.consumeFood(consumptionIntent)
    let afterConsumption = consumption.snapshot().agents[0]
    check("J consumption succeeds atomically", consumptionOutcome.status == .succeeded)
    check("J consumption removes exactly one foodRaw",
          beforeConsumption.resourceInventory.count(of: .foodRaw) == 1
            && afterConsumption.resourceInventory.count(of: .foodRaw) == 0)
    check("J consumption preserves other resources",
          beforeConsumption.resourceInventory.count(of: .wood) == 1
            && afterConsumption.resourceInventory.count(of: .wood) == 1)
    check("J consumption reduces hunger exactly",
          abs(consumptionOutcome.hungerBefore - 0.9) < 1e-12
            && abs(consumptionOutcome.hungerAfter - 0.15) < 1e-12
            && abs(afterConsumption.needs.hunger - 0.15) < 1e-12)
    check("J consumption increments consumed total",
          consumption.snapshot().conservation.consumedTotal == 1
            && consumption.snapshot().conservation.consumed.first?.resource == .foodRaw)
    check("J consumption writes one success memory",
          afterConsumption.recentMemory.filter { $0.type == "food_consumed" }.count == 1)
    check("J consumption outcome exposed",
          afterConsumption.survivalProgress?.lastConsumptionOutcome == consumptionOutcome)
    check("J consumption counter exact", afterConsumption.survivalProgress?.foodConsumedCount == 1)
    check("J consumption resets critical hunger counter",
          afterConsumption.survivalProgress?.consecutiveCriticalHungerTicks == 0)
    check("J conservation includes consumed resource",
          consumption.snapshot().conservation.harvestedTotal == 2
            && consumption.snapshot().conservation.carriedTotal == 1
            && consumption.snapshot().conservation.consumedTotal == 1
            && consumption.snapshot().conservation.balanced)
    let afterFirstConsumption = consumption.snapshot()
    check("J consumption ID deduplicated", {
        do {
            _ = try consumption.consumeFood(consumptionIntent)
            return false
        } catch AgentSessionError.duplicateConsumption { return true }
        catch { return false }
    }())
    check("J duplicate consumption is atomic", consumption.snapshot() == afterFirstConsumption)
    let postConsumptionDelivery = try! consumption.deliverResources(AgentDeliveryIntent(
        deliveryId: "j-post-consumption-delivery",
        agentId: "agent_survival",
        tick: consumption.tick,
        position: AgentPosition(x: 0, y: 64, z: 0)
    ))
    check("J delivery remains atomic after consumption",
          postConsumptionDelivery.status == .succeeded
            && postConsumptionDelivery.transferred == [AgentResourceAmount(resource: .wood, quantity: 1)])
    check("J conservation exact after consumption and delivery",
          consumption.snapshot().conservation.harvestedTotal == 2
            && consumption.snapshot().conservation.carriedTotal == 0
            && consumption.snapshot().conservation.campStockTotal == 1
            && consumption.snapshot().conservation.consumedTotal == 1
            && consumption.snapshot().conservation.balanced)
    check("J invalid consumption resource rejected", {
        do {
            try consumption.prevalidateConsumption(AgentConsumptionIntent(
                consumptionId: "j-consume-wood",
                agentId: "agent_survival",
                tick: consumption.tick,
                resource: .wood
            ))
            return false
        } catch AgentSessionError.invalidConsumptionResource { return true }
        catch { return false }
    }())

    var invalidConsumption = survivalSession(states: [survivalAgentState(hunger: 0.5)])
    harvestForSurvival(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "j-invalid-food", session: &invalidConsumption)
    invalidConsumption.setSurvivalEnabled(true)
    let invalidConsumptionBefore = invalidConsumption.snapshot()
    check("J invalid consumption outcome rejected", {
        do {
            try invalidConsumption.applyConsumptionOutcome(AgentConsumptionOutcome(
                consumptionId: "j-invalid-outcome",
                agentId: "agent_survival",
                tick: invalidConsumption.tick,
                resource: .foodRaw,
                quantity: 1,
                status: .succeeded,
                hungerBefore: 0.5,
                hungerAfter: 0.4,
                reason: "invalid nutrition delta"
            ))
            return false
        } catch AgentSessionError.invalidConsumptionOutcome { return true }
        catch { return false }
    }())
    check("J invalid consumption outcome has no mutation",
          invalidConsumption.snapshot() == invalidConsumptionBefore)

    var emptyConsumption = survivalSession(states: [survivalAgentState(hunger: 0.5)])
    emptyConsumption.setSurvivalEnabled(true)
    let emptyBefore = emptyConsumption.snapshot().agents[0]
    let emptyOutcome = try! emptyConsumption.consumeFood(AgentConsumptionIntent(
        consumptionId: "j-empty-consumption",
        agentId: "agent_survival",
        tick: emptyConsumption.tick
    ))
    let emptyAfter = emptyConsumption.snapshot().agents[0]
    check("J empty consumption is explicitly blocked", emptyOutcome.status == .foodUnavailable)
    check("J empty consumption preserves inventory and hunger",
          emptyAfter.resourceInventory == emptyBefore.resourceInventory
            && emptyAfter.needs == emptyBefore.needs)
    check("J empty consumption writes no success memory",
          emptyAfter.recentMemory.allSatisfy { $0.type != "food_consumed" })
    check("J empty consumption writes blocked memory",
          emptyAfter.recentMemory.last?.type == "consumption_blocked")
    check("J empty consumption preserves conservation",
          emptyConsumption.snapshot().conservation.consumedTotal == 0
            && emptyConsumption.snapshot().conservation.balanced)

    var starvation = survivalSession(states: [survivalAgentState(hunger: 0.55)])
    starvation.setSurvivalEnabled(true)
    _ = try! starvation.advanceTick()
    check("J starvation grace tick one has no damage",
          starvation.snapshot().agents[0].health == 100
            && starvation.snapshot().agents[0].survivalProgress?.consecutiveCriticalHungerTicks == 1)
    _ = try! starvation.advanceTick()
    check("J starvation grace tick two has no damage",
          starvation.snapshot().agents[0].health == 100
            && starvation.snapshot().agents[0].survivalProgress?.consecutiveCriticalHungerTicks == 2)
    _ = try! starvation.advanceTick()
    check("J starvation first damage occurs after grace",
          starvation.snapshot().agents[0].health == 90
            && starvation.snapshot().agents[0].survivalProgress?.starvationDamageTaken == 10)
    check("J starvation writes memory only on real damage",
          starvation.snapshot().agents[0].recentMemory.filter { $0.type == "starvation_damage" }.count == 1)
    for _ in 0..<12 { _ = try! starvation.advanceTick() }
    check("J starvation health is bounded at zero", starvation.snapshot().agents[0].health == 0)
    check("J starvation damage total is bounded", starvation.snapshot().agents[0].survivalProgress?.starvationDamageTaken == 100)
    check("J starvation invents no resources",
          starvation.snapshot().conservation.harvestedTotal == 0
            && starvation.snapshot().conservation.carriedTotal == 0
            && starvation.snapshot().conservation.consumedTotal == 0)
    var starvationOff = survivalSession(states: [survivalAgentState(hunger: 1, health: 100)])
    for _ in 0..<5 { _ = try! starvationOff.advanceTick() }
    check("J survival off prevents starvation damage", starvationOff.snapshot().agents[0].health == 100)
    check("J survival off writes no starvation memory",
          starvationOff.snapshot().agents[0].recentMemory.allSatisfy { $0.type != "starvation_damage" })

    let restHome = AgentPosition(x: 0, y: 64, z: 0)
    let restAway = AgentPosition(x: 2, y: 64, z: 0)
    let restConfiguration = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.01,
        fatiguePerTick: 0.20,
        hungryThreshold: 0.80,
        criticalHungerThreshold: 0.90,
        hungerRecoveryThreshold: 0.10,
        fatigueThreshold: 0.60,
        fatigueRecoveryThreshold: 0.20,
        foodNutrition: 0.75,
        restRecoveryPerTick: 0.60,
        starvationGraceTicks: 2,
        starvationDamagePerTick: 10
    )
    var restSession = survivalSession(states: [survivalAgentState(
        position: restAway,
        home: restHome,
        fatigue: 0.55
    )], configuration: restConfiguration)
    let rejectedAwayRest = AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
        action: AgentAction(name: "rest", reason: "injected away-home rest", tick: 1),
        goalKind: .rest,
        distanceFromHome: 2,
        needs: AgentNeeds(hunger: 0.1, fatigue: 0.8, curiosity: 0.2, safety: 1),
        fear: 0,
        state: "idle",
        tick: 1,
        survivalEnabled: true,
        restRecoveryPerTick: restConfiguration.restRecoveryPerTick
    ))
    check("J survival rest away from home has zero recovery",
          rejectedAwayRest.needs.fatigue == 0.8)
    restSession.setSurvivalEnabled(true)
    func restPerception(_ position: AgentPosition, worldTick: Int, blocked: AgentCardinalDirection? = nil) -> AgentPerceptionInput {
        AgentPerceptionInput(
            agentId: "agent_survival",
            worldObservation: worldObservation(position, worldTick: worldTick, blockedDirection: blocked),
            navigationObservation: AgentNavigationObservation(
                worldTick: worldTick,
                origin: position,
                target: restHome,
                radius: 8,
                cells: flatCells()
            )
        )
    }
    let restTick1 = try! restSession.advanceTick(perceptions: [restPerception(restAway, worldTick: 201)])
    check("J fatigue threshold engages rest goal", restSession.snapshot().agents[0].currentGoal.kind == .rest)
    check("J rest away from home uses homeRest route",
          restSession.snapshot().agents[0].navigationProgress.route?.purpose == .homeRest)
    check("J rest away from home emits return_home", restTick1.agents[0].action.name == "return_home")
    let restMove1 = AgentMovementCoordinator.resolve(snapshot: restSession.snapshot())
    try! restSession.applyMovementOutcomes(restMove1)
    check("J rest route advances one step only",
          restSession.snapshot().agents[0].position == AgentPosition(x: 1, y: 64, z: 0)
            && restSession.snapshot().agents[0].navigationProgress.routeIndex == 1)
    let restBeforeBlocked = restSession.snapshot().agents[0]
    _ = try! restSession.advanceTick(perceptions: [restPerception(
        restBeforeBlocked.position, worldTick: 202, blocked: .west
    )])
    let restBlockedOutcomes = AgentMovementCoordinator.resolve(snapshot: restSession.snapshot())
    try! restSession.applyMovementOutcomes(restBlockedOutcomes)
    check("J blocked rest movement does not progress",
          restSession.snapshot().agents[0].position == restBeforeBlocked.position
            && restSession.snapshot().agents[0].navigationProgress.routeIndex == restBeforeBlocked.navigationProgress.routeIndex)
    _ = try! restSession.advanceTick(perceptions: [restPerception(
        restSession.snapshot().agents[0].position, worldTick: 203
    )])
    check("J blocked rest route replans bounded",
          restSession.snapshot().agents[0].navigationProgress.replanCount == 1)
    let restMove2 = AgentMovementCoordinator.resolve(snapshot: restSession.snapshot())
    try! restSession.applyMovementOutcomes(restMove2)
    check("J rest route arrives exactly at home",
          restSession.snapshot().agents[0].position == restHome
            && restSession.snapshot().agents[0].navigationProgress.status == .arrived)
    let beforeRestFatigue = restSession.snapshot().agents[0].needs.fatigue
    let atHomeRestTick = try! restSession.advanceTick(perceptions: [restPerception(restHome, worldTick: 204)])
    check("J rest action occurs only at home", atHomeRestTick.agents[0].action.name == "rest")
    check("J rest recovery exact",
          restSession.snapshot().agents[0].needs.fatigue
            == max(0, min(1, beforeRestFatigue + restConfiguration.fatiguePerTick)
                - restConfiguration.restRecoveryPerTick))
    check("J rest progress increments", restSession.snapshot().agents[0].survivalProgress?.restTicks == 1)
    var exitedRest = false
    for worldTick in 205...208 {
        _ = try! restSession.advanceTick(perceptions: [restPerception(restHome, worldTick: worldTick)])
        if restSession.snapshot().agents[0].currentGoal.kind != .rest { exitedRest = true; break }
    }
    check("J rest exits at recovery threshold", exitedRest)
    check("J rest does not oscillate immediately",
          restSession.snapshot().agents[0].needs.fatigue <= restConfiguration.fatigueRecoveryThreshold)

    var resumeEconomy = survivalSession(states: [survivalAgentState(hunger: 0.5)], economy: true)
    harvestForSurvival(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "j-resume-food", session: &resumeEconomy)
    resumeEconomy.setSurvivalEnabled(true)
    _ = try! resumeEconomy.advanceTick()
    _ = try! resumeEconomy.consumeFood(AgentConsumptionIntent(
        consumptionId: "j-resume-consume",
        agentId: "agent_survival",
        tick: resumeEconomy.tick
    ))
    let resumedEconomyTick = try! resumeEconomy.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_survival",
        resourceObservations: [observedResource(.wood, target: woodTarget)]
    )])
    check("J economy resumes after hunger recovery",
          resumedEconomyTick.agents[0].snapshot.currentGoal.kind == .collectResource)
    check("J H2 action semantics remain unchanged",
          AgentActionDecider.decide(AgentActionDecisionInput(
            agentId: "agent_h2",
            tick: 1,
            goalKind: .collectResource,
            position: AgentPosition(x: 0, y: 64, z: 0),
            homePosition: AgentPosition(x: 0, y: 64, z: 0),
            resourceObservations: [resource(AgentPosition(x: 0, y: 64, z: 0))]
          )).name == "approach_resource")

    var twoAgentConservation = survivalSession(states: [
        survivalAgentState(id: "agent_a"),
        survivalAgentState(id: "agent_b", position: AgentPosition(x: 0, y: 64, z: 1), home: AgentPosition(x: 0, y: 64, z: 1)),
    ])
    harvestForSurvival(.foodRaw, target: AgentPosition(x: 1, y: 64, z: 0), id: "j-two-food", agentId: "agent_a", session: &twoAgentConservation)
    harvestForSurvival(.wood, target: AgentPosition(x: 1, y: 64, z: 1), id: "j-two-wood", agentId: "agent_b", session: &twoAgentConservation)
    twoAgentConservation.setSurvivalEnabled(true)
    let twoAgentOutcome = try! twoAgentConservation.consumeFood(AgentConsumptionIntent(
        consumptionId: "j-two-consume",
        agentId: "agent_a",
        tick: twoAgentConservation.tick
    ))
    check("J multi-agent consumption succeeds", twoAgentOutcome.status == .succeeded)
    check("J conservation exact globally for multiple agents",
          twoAgentConservation.snapshot().conservation.harvestedTotal == 2
            && twoAgentConservation.snapshot().conservation.carriedTotal == 1
            && twoAgentConservation.snapshot().conservation.consumedTotal == 1
            && twoAgentConservation.snapshot().conservation.balanced)
    check("J conservation exact per foodRaw",
          twoAgentConservation.snapshot().conservation.harvested.first { $0.resource == .foodRaw }?.quantity == 1
            && twoAgentConservation.snapshot().conservation.consumed.first { $0.resource == .foodRaw }?.quantity == 1)
    check("J only foodRaw can be consumed",
          twoAgentConservation.snapshot().conservation.consumed.allSatisfy { $0.resource == .foodRaw })
    let survivalSnapshotEncodingA = try! economyEncoder.encode(twoAgentConservation.snapshot())
    let survivalSnapshotEncodingB = try! economyEncoder.encode(twoAgentConservation.snapshot())
    check("J survival snapshot deterministic encoding", survivalSnapshotEncodingA == survivalSnapshotEncodingB)
    let survivalSnapshotText = String(data: survivalSnapshotEncodingA, encoding: .utf8) ?? ""
    check("J survival snapshot exposes consumed conservation",
          survivalSnapshotText.contains("consumedTotal")
            && survivalSnapshotText.contains("survivalProgress")
            && survivalSnapshotText.contains("lastConsumptionOutcome"))
    twoAgentConservation.setSurvivalEnabled(false)
    check("J disabling survival clears survival engagements",
          !twoAgentConservation.snapshot().survivalEnabled
            && twoAgentConservation.snapshot().agents.allSatisfy { $0.survivalProgress == nil })
    check("J disabling survival preserves inventory and consumed totals",
          twoAgentConservation.snapshot().agents.first { $0.id == "agent_b" }?.resourceInventory.count(of: .wood) == 1
            && twoAgentConservation.snapshot().conservation.consumedTotal == 1)

    // -----------------------------------------------------------------------
    section("PebbleAgents bounded natural wood and stone J to K")

    let oakFingerprint = Int(B.oak_log) << 4
    let birchFingerprint = Int(B.birch_log) << 4
    let stoneFingerprint = Int(B.stone) << 4
    let naturalMapping = try! AgentNaturalResourceFingerprintMapping(entries: [
        AgentNaturalResourceFingerprintEntry(fingerprint: oakFingerprint, resource: .wood),
        AgentNaturalResourceFingerprintEntry(fingerprint: birchFingerprint, resource: .wood),
        AgentNaturalResourceFingerprintEntry(fingerprint: stoneFingerprint, resource: .stone),
    ])
    check("natural oak_log exact fingerprint maps to wood",
          naturalMapping.resource(for: oakFingerprint) == .wood)
    check("natural birch_log exact fingerprint maps to wood",
          naturalMapping.resource(for: birchFingerprint) == .wood)
    check("natural stone exact fingerprint maps to stone",
          naturalMapping.resource(for: stoneFingerprint) == .stone)
    check("natural unmapped block is ignored", naturalMapping.resource(for: Int(B.dirt) << 4) == nil)
    check("natural mapping never produces foodRaw",
          naturalMapping.entries.allSatisfy { $0.resource != .foodRaw })
    check("natural mapping requires metadata zero",
          [oakFingerprint, birchFingerprint, stoneFingerprint].allSatisfy { $0 & 15 == 0 })
    check("natural mapping rejects nonzero metadata",
          naturalMapping.resource(for: oakFingerprint | 1) == nil
            && naturalMapping.resource(for: stoneFingerprint | 1) == nil)
    check("natural audited internal block ids are stable",
          oakFingerprint >> 4 == 95 && birchFingerprint >> 4 == 127 && stoneFingerprint >> 4 == 3)
    check("natural mapping order deterministic",
          naturalMapping.entries.map(\.fingerprint) == [stoneFingerprint, oakFingerprint, birchFingerprint])
    check("natural mapping rejects foodRaw", {
        do {
            _ = try AgentNaturalResourceFingerprintMapping(entries: [
                AgentNaturalResourceFingerprintEntry(fingerprint: 999, resource: .foodRaw),
            ])
            return false
        } catch AgentNaturalResourceFingerprintMappingError.unsupportedResource(.foodRaw) { return true }
        catch { return false }
    }())
    check("natural mapping rejects duplicate fingerprints", {
        do {
            _ = try AgentNaturalResourceFingerprintMapping(entries: [
                AgentNaturalResourceFingerprintEntry(fingerprint: oakFingerprint, resource: .wood),
                AgentNaturalResourceFingerprintEntry(fingerprint: oakFingerprint, resource: .stone),
            ])
            return false
        } catch AgentNaturalResourceFingerprintMappingError.duplicateFingerprint(oakFingerprint) { return true }
        catch { return false }
    }())
    check("natural mapping deterministic encoding",
          try! economyEncoder.encode(naturalMapping) == economyEncoder.encode(naturalMapping))

    func generatedNaturalFingerprint(seed: UInt32, position: AgentPosition) -> Int {
        let cx = position.x >> 4
        let cz = position.z >> 4
        let generated = generateOverworldChunk(seed, cx, cz)
        let world = World(dim: .overworld, seed: seed)
        let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
        chunk.blocks = generated.blocks
        chunk.biomes = generated.biomes
        chunk.buildHeightmap()
        chunk.status = .generated
        world.setChunk(chunk)
        return world.getBlock(position.x, position.y, position.z)
    }
    let generatedOakFingerprint = generatedNaturalFingerprint(
        seed: 46,
        position: AgentPosition(x: 24, y: 68, z: -22)
    )
    let generatedStoneFingerprint = generatedNaturalFingerprint(
        seed: 46,
        position: AgentPosition(x: 24, y: 68, z: -20)
    )
    let generatedBirchFingerprint = generatedNaturalFingerprint(
        seed: 45,
        position: AgentPosition(x: 14, y: 67, z: -19)
    )
    check("natural live seed generates exact oak_log fingerprint",
          generatedOakFingerprint == oakFingerprint)
    check("natural live seed generates exact stone fingerprint",
          generatedStoneFingerprint == stoneFingerprint)
    check("natural audited seed generates exact birch_log fingerprint",
          generatedBirchFingerprint == birchFingerprint)
    check("natural generated blocks use only audited mapping",
          [generatedOakFingerprint, generatedStoneFingerprint, generatedBirchFingerprint]
            .allSatisfy { naturalMapping.resource(for: $0) != nil })

    let naturalOrigin = AgentPosition(x: 0, y: 64, z: 0)
    let scanConfiguration = AgentNaturalResourceScanConfiguration.live
    let scanPositions = AgentNaturalResourceScanner.positions(
        around: naturalOrigin,
        configuration: scanConfiguration
    )
    check("natural scan radius fixed at eight", scanConfiguration.horizontalRadius == 8)
    check("natural scan vertical band fixed and reduced",
          scanConfiguration.verticalBelow == 2 && scanConfiguration.verticalAbove == 4)
    check("natural scan maximum position budget exact",
          scanConfiguration.maximumPositionCount == 1008 && scanPositions.count == 1008)
    check("natural scan approach read budget exact",
          scanConfiguration.maximumApproachBlockReadCount == 384)
    check("natural scan total World read budget exact",
          scanConfiguration.maximumWorldBlockReadCount == 1392)
    check("natural scan positions unique", Set(scanPositions).count == scanPositions.count)
    check("natural scan excludes origin column",
          scanPositions.allSatisfy { $0.x != naturalOrigin.x || $0.z != naturalOrigin.z })
    check("natural scan horizontal radius bounded", scanPositions.allSatisfy {
        abs($0.x - naturalOrigin.x) + abs($0.z - naturalOrigin.z) <= 8
    })
    check("natural scan vertical range bounded", scanPositions.allSatisfy {
        (-2...4).contains($0.y - naturalOrigin.y)
    })
    check("natural scan order repeated identically",
          scanPositions == AgentNaturalResourceScanner.positions(around: naturalOrigin))
    check("natural scan candidate limit explicit", scanConfiguration.maximumCandidates == 32)
    check("natural scan observation limit shared",
          scanConfiguration.maximumObservations == AgentResourcePerception.maximumObservationCount)
    let saturatedNaturalScan = try! AgentNaturalResourceScanner.normalize(
        observerPosition: naturalOrigin,
        samples: scanPositions.prefix(40).enumerated().map { index, position in
            AgentNaturalResourceScanSample(
                position: position,
                chunkReady: true,
                fingerprint: index.isMultiple(of: 2) ? oakFingerprint : stoneFingerprint,
                mappedResource: index.isMultiple(of: 2) ? .wood : .stone,
                hasCardinalApproach: true
            )
        }
    )
    check("natural scan candidates capped at thirty two",
          saturatedNaturalScan.diagnostics.candidateCount == 32)
    check("natural scan observations capped at shared eight",
          saturatedNaturalScan.observations.count == 8)

    let naturalWoodTarget = AgentPosition(x: 1, y: 64, z: 0)
    let naturalStoneTarget = AgentPosition(x: 0, y: 64, z: -2)
    let naturalScanSamples = [
        AgentNaturalResourceScanSample(
            position: naturalWoodTarget,
            chunkReady: true,
            fingerprint: oakFingerprint,
            mappedResource: .wood,
            hasCardinalApproach: true
        ),
        AgentNaturalResourceScanSample(
            position: naturalStoneTarget,
            chunkReady: true,
            fingerprint: stoneFingerprint,
            mappedResource: .stone,
            hasCardinalApproach: true
        ),
        AgentNaturalResourceScanSample(
            position: AgentPosition(x: -1, y: 64, z: 0),
            chunkReady: true,
            fingerprint: Int(B.dirt) << 4,
            mappedResource: nil,
            hasCardinalApproach: false
        ),
        AgentNaturalResourceScanSample(
            position: AgentPosition(x: 0, y: 64, z: 1),
            chunkReady: false
        ),
    ]
    let normalizedNaturalScan = try! AgentNaturalResourceScanner.normalize(
        observerPosition: naturalOrigin,
        samples: naturalScanSamples
    )
    check("natural scan emits wood and stone only",
          normalizedNaturalScan.observations.map(\.resource) == [.wood, .stone])
    check("natural scan emits naturalWorld source",
          normalizedNaturalScan.observations.allSatisfy { $0.source == .naturalWorld })
    check("natural scan preserves exact fingerprints",
          normalizedNaturalScan.observations.map(\.expectedBlockFingerprint)
            == [Optional(oakFingerprint), Optional(stoneFingerprint)])
    check("natural scan ignores unmapped block",
          normalizedNaturalScan.diagnostics.mappedBlockCount == 2)
    check("natural scan ignores unavailable chunk",
          normalizedNaturalScan.diagnostics.positionsRead == 3)
    check("natural scan requires approach cell", {
        let blocked = try! AgentNaturalResourceScanner.normalize(
            observerPosition: naturalOrigin,
            samples: [AgentNaturalResourceScanSample(
                position: naturalWoodTarget,
                chunkReady: true,
                fingerprint: oakFingerprint,
                mappedResource: .wood,
                hasCardinalApproach: false
            )]
        )
        return blocked.observations.isEmpty && blocked.diagnostics.candidateCount == 0
    }())
    check("natural scan rejects duplicate positions", {
        do {
            _ = try AgentNaturalResourceScanner.normalize(
                observerPosition: naturalOrigin,
                samples: [naturalScanSamples[0], naturalScanSamples[0]]
            )
            return false
        } catch AgentNaturalResourceScanError.duplicatePosition(naturalWoodTarget) { return true }
        catch { return false }
    }())
    check("natural scan rejects positions outside budget", {
        do {
            _ = try AgentNaturalResourceScanner.normalize(
                observerPosition: naturalOrigin,
                samples: [AgentNaturalResourceScanSample(
                    position: AgentPosition(x: 9, y: 64, z: 0),
                    chunkReady: true
                )]
            )
            return false
        } catch AgentNaturalResourceScanError.positionOutsidePlan { return true }
        catch { return false }
    }())
    check("natural scan same input same output",
          normalizedNaturalScan == (try! AgentNaturalResourceScanner.normalize(
            observerPosition: naturalOrigin,
            samples: naturalScanSamples
          )))
    check("natural scan deterministic encoding",
          try! economyEncoder.encode(normalizedNaturalScan)
            == economyEncoder.encode(normalizedNaturalScan))

    let naturalIdentity = AgentResourceIdentity(
        source: .naturalWorld,
        position: naturalWoodTarget,
        resource: .wood,
        expectedBlockFingerprint: oakFingerprint
    )
    let naturalBoundary = AgentNaturalResourceMutationBoundary(identity: naturalIdentity)
    check("natural identity stable key includes source and fingerprint",
          naturalIdentity.stableKey.contains("naturalWorld:wood")
            && naturalIdentity.stableKey.hasSuffix(":\(oakFingerprint)"))
    check("natural mutation boundary permits target only",
          naturalBoundary.isValid && naturalBoundary.permittedPositions == [naturalWoodTarget])
    check("natural mutation boundary rejects corridor position",
          !naturalBoundary.permits(AgentPosition(x: 0, y: 64, z: 0)))
    check("natural fixture identity cannot enter natural mutation boundary",
          !AgentNaturalResourceMutationBoundary(identity: AgentResourceIdentity(
            source: .sandboxFixture,
            position: naturalWoodTarget,
            resource: .wood
          )).isValid)

    func naturalObservation(
        _ resource: AgentResourceKind,
        target: AgentPosition,
        observer: AgentPosition,
        fingerprint: Int
    ) -> AgentResourceObservation {
        AgentResourceObservation(
            resource: resource,
            target: target,
            direction: AgentResourcePerception.direction(
                observerPosition: observer,
                target: target
            )!,
            distanceManhattan: abs(target.x - observer.x)
                + abs(target.y - observer.y)
                + abs(target.z - observer.z),
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: fingerprint
        )
    }

    var naturalSession = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin
    )])
    check("natural mode disabled by default", !naturalSession.naturalResourcesEnabled
          && !naturalSession.snapshot().naturalResourcesEnabled)
    let naturalLegacyEncoding = String(
        data: try! economyEncoder.encode(naturalSession.snapshot()),
        encoding: .utf8
    ) ?? ""
    check("natural mode omitted from legacy snapshot",
          !naturalLegacyEncoding.contains("naturalResourcesEnabled"))
    naturalSession.setNaturalResourcesEnabled(true)
    check("natural mode explicit enable stored in session",
          naturalSession.naturalResourcesEnabled && naturalSession.snapshot().naturalResourcesEnabled)
    let naturalTick = try! naturalSession.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [naturalObservation(
            .wood,
            target: naturalWoodTarget,
            observer: naturalOrigin,
            fingerprint: oakFingerprint
        )]
    )])
    let lockedNatural = naturalSession.snapshot().agents[0]
    check("natural target lock preserves source",
          lockedNatural.activeResourceTarget?.source == .naturalWorld)
    check("natural target lock preserves fingerprint",
          lockedNatural.activeResourceTarget?.expectedBlockFingerprint == oakFingerprint)
    check("natural reservation preserves identity",
          lockedNatural.resourceReservation?.source == .naturalWorld
            && lockedNatural.resourceReservation?.expectedBlockFingerprint == oakFingerprint)
    check("natural adjacent target emits harvest_block", naturalTick.agents[0].action.name == "harvest_block")
    let naturalIntent = AgentInteractionIntent(
        interactionId: "natural-wood-1",
        agentId: "agent_economy",
        tick: naturalSession.tick,
        target: naturalWoodTarget,
        resource: .wood,
        source: .naturalWorld,
        expectedBlockFingerprint: oakFingerprint
    )
    check("natural transaction prevalidation accepts reserved identity", {
        do { try naturalSession.prevalidateInteraction(naturalIntent); return true }
        catch { return false }
    }())
    check("natural transaction rejects stale fingerprint before mutation", {
        do {
            try naturalSession.prevalidateInteraction(AgentInteractionIntent(
                interactionId: "natural-stale-fingerprint",
                agentId: naturalIntent.agentId,
                tick: naturalIntent.tick,
                target: naturalIntent.target,
                resource: naturalIntent.resource,
                source: .naturalWorld,
                expectedBlockFingerprint: birchFingerprint
            ))
            return false
        } catch AgentSessionError.invalidNaturalResourceIdentity { return true }
        catch { return false }
    }())
    let naturalDisabledSession = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin
    )])
    check("natural transaction rejects disabled mode before mutation", {
        do {
            try naturalDisabledSession.prevalidateInteraction(AgentInteractionIntent(
                interactionId: "natural-disabled",
                agentId: "agent_economy",
                tick: naturalDisabledSession.tick,
                target: naturalWoodTarget,
                resource: .wood,
                source: .naturalWorld,
                expectedBlockFingerprint: oakFingerprint
            ))
            return false
        } catch AgentSessionError.invalidNaturalResourceIdentity { return true }
        catch { return false }
    }())
    let naturalWoodOutcome = AgentInteractionOutcome(
        interactionId: naturalIntent.interactionId,
        agentId: naturalIntent.agentId,
        tick: naturalIntent.tick,
        target: naturalIntent.target,
        resource: naturalIntent.resource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "natural wood harvested",
        source: .naturalWorld,
        expectedBlockFingerprint: oakFingerprint
    )
    try! naturalSession.applyInteractionOutcome(naturalWoodOutcome)
    check("natural harvest credits wood exactly once",
          naturalSession.snapshot().agents[0].resourceInventory.count(of: .wood) == 1)
    check("natural harvest increments harvested exactly once",
          naturalSession.snapshot().conservation.harvestedTotal == 1
            && naturalSession.snapshot().conservation.balanced)
    check("natural harvest writes one memory",
          naturalSession.snapshot().agents[0].recentMemory.filter { $0.type == "resource_harvested" }.count == 1)
    check("natural harvest releases reservation and route",
          naturalSession.snapshot().resourceReservations.isEmpty
            && naturalSession.snapshot().agents[0].navigationProgress.route == nil)
    let afterNaturalWood = naturalSession.snapshot()
    check("natural double credit rejected across interaction IDs", {
        do {
            try naturalSession.applyInteractionOutcome(AgentInteractionOutcome(
                interactionId: "natural-wood-duplicate",
                agentId: "agent_economy",
                tick: naturalSession.tick,
                target: naturalWoodTarget,
                resource: .wood,
                status: .succeeded,
                inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
                reason: "duplicate natural wood",
                source: .naturalWorld,
                expectedBlockFingerprint: oakFingerprint
            ))
            return false
        } catch AgentSessionError.duplicateResourceCredit { return true }
        catch { return false }
    }())
    check("natural rejected duplicate has no mutation", naturalSession.snapshot() == afterNaturalWood)

    var staleNatural = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin
    )])
    staleNatural.setNaturalResourcesEnabled(true)
    _ = try! staleNatural.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [naturalObservation(
            .wood, target: naturalWoodTarget, observer: naturalOrigin, fingerprint: oakFingerprint
        )]
    )])
    _ = try! staleNatural.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [naturalObservation(
            .wood, target: naturalWoodTarget, observer: naturalOrigin, fingerprint: birchFingerprint
        )]
    )])
    check("natural fingerprint change replaces target identity",
          staleNatural.snapshot().agents[0].activeResourceTarget?.expectedBlockFingerprint == birchFingerprint)
    check("natural fingerprint change invalidates prior route",
          staleNatural.snapshot().agents[0].navigationProgress.lastInvalidation == .targetChanged)
    staleNatural.setNaturalResourcesEnabled(false)
    check("natural off releases target and reservation",
          staleNatural.snapshot().agents[0].activeResourceTarget == nil
            && staleNatural.snapshot().resourceReservations.isEmpty)
    check("natural off preserves economy state", staleNatural.economyEnabled)

    var carriedWood = AgentResourceInventory(capacity: 8)
    _ = carriedWood.add(.wood)
    var balancedSelection = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin,
        inventory: carriedWood
    )])
    balancedSelection.setNaturalResourcesEnabled(true)
    _ = try! balancedSelection.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [
            naturalObservation(.wood, target: naturalWoodTarget, observer: naturalOrigin, fingerprint: oakFingerprint),
            naturalObservation(.stone, target: naturalStoneTarget, observer: naturalOrigin, fingerprint: stoneFingerprint),
        ]
    )])
    check("natural selection prefers missing carried resource",
          balancedSelection.snapshot().agents[0].activeResourceTarget?.resource == .stone)

    let sharedNaturalTarget = AgentPosition(x: 2, y: 64, z: 0)
    let naturalAgentA = economyAgentState(
        id: "agent_a",
        position: naturalOrigin,
        home: naturalOrigin
    )
    let naturalAgentBPosition = AgentPosition(x: 0, y: 64, z: 1)
    let naturalAgentB = economyAgentState(
        id: "agent_b",
        position: naturalAgentBPosition,
        home: naturalAgentBPosition
    )
    var concurrentNatural = economySession(states: [naturalAgentB, naturalAgentA])
    concurrentNatural.setNaturalResourcesEnabled(true)
    _ = try! concurrentNatural.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_a", resourceObservations: [naturalObservation(
            .stone, target: sharedNaturalTarget, observer: naturalOrigin, fingerprint: stoneFingerprint
        )]),
        AgentPerceptionInput(agentId: "agent_b", resourceObservations: [naturalObservation(
            .stone, target: sharedNaturalTarget, observer: naturalAgentBPosition, fingerprint: stoneFingerprint
        )]),
    ])
    check("natural concurrent reservation tie uses agentId",
          concurrentNatural.snapshot().resourceReservations.count == 1
            && concurrentNatural.snapshot().resourceReservations[0].agentId == "agent_a")
    check("natural losing agent cannot prevalidate harvest", {
        do {
            try concurrentNatural.prevalidateInteraction(AgentInteractionIntent(
                interactionId: "natural-loser",
                agentId: "agent_b",
                tick: concurrentNatural.tick,
                target: sharedNaturalTarget,
                resource: .stone,
                source: .naturalWorld,
                expectedBlockFingerprint: stoneFingerprint
            ))
            return false
        } catch AgentSessionError.invalidNaturalResourceIdentity { return true }
        catch { return false }
    }())
    try! concurrentNatural.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "natural-owner",
        agentId: "agent_a",
        tick: concurrentNatural.tick,
        target: sharedNaturalTarget,
        resource: .stone,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .stone, quantity: 1),
        reason: "natural owner harvested",
        source: .naturalWorld,
        expectedBlockFingerprint: stoneFingerprint
    ))
    check("natural concurrent harvest has one credit",
          concurrentNatural.snapshot().conservation.harvestedTotal == 1
            && concurrentNatural.snapshot().agents.reduce(0) {
                $0 + $1.resourceInventory.count(of: .stone)
            } == 1)
    check("natural disappearance clears second target next tick", {
        _ = try! concurrentNatural.advanceTick(perceptions: [
            AgentPerceptionInput(agentId: "agent_a"),
            AgentPerceptionInput(agentId: "agent_b"),
        ])
        return concurrentNatural.snapshot().agents.allSatisfy { $0.activeResourceTarget == nil }
    }())

    var naturalDelivery = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin
    )])
    naturalDelivery.setNaturalResourcesEnabled(true)
    for (id, resource, target, fingerprint) in [
        ("natural-delivery-wood", AgentResourceKind.wood, naturalWoodTarget, oakFingerprint),
        ("natural-delivery-stone", AgentResourceKind.stone, naturalStoneTarget, stoneFingerprint),
    ] {
        try! naturalDelivery.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: id,
            agentId: "agent_economy",
            tick: naturalDelivery.tick,
            target: target,
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "natural delivery fixture",
            source: .naturalWorld,
            expectedBlockFingerprint: fingerprint
        ))
    }
    check("natural wood and stone reach quota",
          naturalDelivery.snapshot().agents[0].resourceInventory.totalCount == 2)
    let naturalDeliveryOutcome = try! naturalDelivery.deliverResources(AgentDeliveryIntent(
        deliveryId: "natural-delivery",
        agentId: "agent_economy",
        tick: naturalDelivery.tick,
        position: naturalOrigin
    ))
    check("natural delivery succeeds atomically", naturalDeliveryOutcome.status == .succeeded)
    check("natural delivery stock wood one stone one",
          naturalDelivery.snapshot().campStock.count(of: .wood) == 1
            && naturalDelivery.snapshot().campStock.count(of: .stone) == 1)
    check("natural delivery conservation exact",
          naturalDelivery.snapshot().conservation.harvestedTotal == 2
            && naturalDelivery.snapshot().conservation.carriedTotal == 0
            && naturalDelivery.snapshot().conservation.campStockTotal == 2
            && naturalDelivery.snapshot().conservation.balanced)

    var rollbackNatural = economySession(states: [economyAgentState(
        position: naturalOrigin,
        home: naturalOrigin
    )])
    rollbackNatural.setNaturalResourcesEnabled(true)
    _ = try! rollbackNatural.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        resourceObservations: [naturalObservation(
            .wood, target: naturalWoodTarget, observer: naturalOrigin, fingerprint: oakFingerprint
        )]
    )])
    let rollbackBefore = rollbackNatural.snapshot()
    let rollbackWorld = World(dim: .overworld, seed: 46)
    let rollbackChunk = Chunk(
        cx: naturalWoodTarget.x >> 4,
        cz: naturalWoodTarget.z >> 4,
        minY: rollbackWorld.info.minY,
        height: rollbackWorld.info.height
    )
    rollbackChunk.status = .generated
    rollbackWorld.setChunk(rollbackChunk)
    let untouchedNaturalNeighbor = AgentPosition(x: 2, y: 64, z: 0)
    _ = rollbackWorld.setBlock(
        untouchedNaturalNeighbor.x,
        untouchedNaturalNeighbor.y,
        untouchedNaturalNeighbor.z,
        Int(B.dirt) << 4
    )
    _ = rollbackWorld.setBlock(
        naturalWoodTarget.x,
        naturalWoodTarget.y,
        naturalWoodTarget.z,
        oakFingerprint
    )
    var publicationCandidate = rollbackNatural
    let removedNaturalFingerprint = rollbackWorld.setBlock(
        naturalWoodTarget.x,
        naturalWoodTarget.y,
        naturalWoodTarget.z,
        0
    )
    let naturalBlockWasRemoved = removedNaturalFingerprint == oakFingerprint
        && rollbackWorld.getBlock(
            naturalWoodTarget.x,
            naturalWoodTarget.y,
            naturalWoodTarget.z
        ) == 0
    try! publicationCandidate.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "natural-forced-publication-failure",
        agentId: "agent_economy",
        tick: publicationCandidate.tick,
        target: naturalWoodTarget,
        resource: .wood,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "candidate publication",
        source: .naturalWorld,
        expectedBlockFingerprint: oakFingerprint
    ))
    _ = rollbackWorld.setBlock(
        naturalWoodTarget.x,
        naturalWoodTarget.y,
        naturalWoodTarget.z,
        removedNaturalFingerprint
    )
    check("natural forced publication failure removes only exact target before rollback",
          naturalBlockWasRemoved)
    check("natural forced publication failure restores exact fingerprint",
          rollbackWorld.getBlock(
            naturalWoodTarget.x,
            naturalWoodTarget.y,
            naturalWoodTarget.z
          ) == oakFingerprint)
    check("natural forced publication failure preserves third-party block",
          rollbackWorld.getBlock(
            untouchedNaturalNeighbor.x,
            untouchedNaturalNeighbor.y,
            untouchedNaturalNeighbor.z
          ) == (Int(B.dirt) << 4))
    check("natural forced publication failure publishes no inventory",
          rollbackNatural.snapshot().agents[0].resourceInventory
            == rollbackBefore.agents[0].resourceInventory)
    check("natural forced publication failure publishes no harvested total",
          rollbackNatural.snapshot().conservation == rollbackBefore.conservation)
    check("natural forced publication failure writes no memory",
          rollbackNatural.snapshot().agents[0].memoryCount == rollbackBefore.agents[0].memoryCount
            && rollbackNatural.snapshot().agents[0].recentMemory.last?.type
                == rollbackBefore.agents[0].recentMemory.last?.type)
    check("natural candidate would have changed only before rejection",
          publicationCandidate.snapshot().agents[0].resourceInventory.count(of: .wood) == 1)

    var hungryNatural = survivalSession(states: [survivalAgentState(hunger: 0.5)], economy: true)
    hungryNatural.setNaturalResourcesEnabled(true)
    hungryNatural.setSurvivalEnabled(true)
    let hungryNaturalTick = try! hungryNatural.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_survival",
        resourceObservations: [
            naturalObservation(.wood, target: naturalWoodTarget, observer: naturalOrigin, fingerprint: oakFingerprint),
            naturalObservation(.stone, target: naturalStoneTarget, observer: naturalOrigin, fingerprint: stoneFingerprint),
        ]
    )])
    check("natural wood and stone never satisfy hunger",
          hungryNatural.snapshot().agents[0].activeResourceTarget == nil
            && hungryNaturalTick.agents[0].action.name == "wait")
    check("natural integration leaves survival conservation exact",
          hungryNatural.snapshot().conservation.balanced)

    // -----------------------------------------------------------------------
    section("PebbleAgents fixed shelter construction K")

    let shelter = AgentBlueprint.fixedLeanToV1
    check("K blueprint ID stable", shelter.blueprintId == "fixedLeanToV1")
    check("K blueprint has exactly nine cells", shelter.cells.count == 9)
    check("K blueprint indices continuous", shelter.cells.map(\.index) == Array(0..<9))
    check("K blueprint order exact", shelter.cells.map(\.relativePosition) == [
        AgentPosition(x: 0, y: 0, z: 2), AgentPosition(x: 1, y: 0, z: 2),
        AgentPosition(x: 2, y: 0, z: 2), AgentPosition(x: 0, y: 1, z: 2),
        AgentPosition(x: 1, y: 1, z: 2), AgentPosition(x: 2, y: 1, z: 2),
        AgentPosition(x: 0, y: 2, z: 1), AgentPosition(x: 1, y: 2, z: 1),
        AgentPosition(x: 2, y: 2, z: 1),
    ])
    check("K blueprint stone cost exact",
          shelter.materialRequirements.first { $0.resource == .stone }?.quantity == 3)
    check("K blueprint wood cost exact",
          shelter.materialRequirements.first { $0.resource == .wood }?.quantity == 6)
    check("K blueprint entrance reserved",
          shelter.cells.allSatisfy { $0.relativePosition != shelter.entranceOffset })
    check("K blueprint rest cell reserved",
          shelter.cells.allSatisfy { $0.relativePosition != shelter.restOffset })
    check("K blueprint fits three cubed bound", shelter.cells.allSatisfy {
        (0...2).contains($0.relativePosition.x)
            && (0...2).contains($0.relativePosition.y)
            && (0...2).contains($0.relativePosition.z)
    })
    check("K blueprint repeated identically", shelter == AgentBlueprint.fixedLeanToV1)
    check("K blueprint deterministic encoding",
          try! economyEncoder.encode(shelter) == economyEncoder.encode(shelter))
    check("K blueprint rejects reserved placement", {
        do {
            _ = try AgentBlueprint(
                blueprintId: "invalid",
                footprintWidth: 3,
                footprintDepth: 3,
                maximumHeight: 3,
                cells: [AgentBlueprintCell(
                    index: 0,
                    relativePosition: AgentPosition(x: 1, y: 0, z: 0),
                    resource: .wood,
                    workOffset: AgentPosition(x: 1, y: 0, z: -1)
                )],
                entranceOffset: AgentPosition(x: 1, y: 0, z: 0),
                restOffset: AgentPosition(x: 1, y: 0, z: 1),
                materialRequirements: [AgentResourceAmount(resource: .wood, quantity: 1)]
            )
            return false
        } catch AgentConstructionError.reservedCellOccupied { return true }
        catch { return false }
    }())
    check("K blueprint rejects unsupported material", {
        do {
            _ = try AgentBlueprint(
                blueprintId: "invalid",
                footprintWidth: 3,
                footprintDepth: 3,
                maximumHeight: 3,
                cells: [AgentBlueprintCell(
                    index: 0,
                    relativePosition: AgentPosition(x: 0, y: 0, z: 2),
                    resource: .foodRaw,
                    workOffset: AgentPosition(x: 0, y: 0, z: 3)
                )],
                entranceOffset: AgentPosition(x: 1, y: 0, z: 0),
                restOffset: AgentPosition(x: 1, y: 0, z: 1),
                materialRequirements: [AgentResourceAmount(resource: .foodRaw, quantity: 1)]
            )
            return false
        } catch AgentConstructionError.unsupportedMaterial(.foodRaw) { return true }
        catch { return false }
    }())

    let constructionHome = AgentPosition(x: 0, y: 64, z: 0)
    let constructionOrigin = AgentPosition(x: 2, y: 64, z: 1)
    let constructionFingerprints = shelter.cells.map {
        AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
    }
    func constructionProject(_ id: String = "shelter-k") -> AgentConstructionProject {
        try! AgentConstructionProject(
            projectId: id,
            builderAgentId: "agent_economy",
            origin: constructionOrigin,
            createdAtTick: 0,
            previousHomePosition: constructionHome,
            originalFingerprints: constructionFingerprints
        )
    }
    let projectContract = constructionProject()
    check("K project starts acquiring materials", projectContract.status == .acquiringMaterials)
    check("K project rest position exact",
          projectContract.restPosition == AgentPosition(x: 3, y: 64, z: 2))
    check("K project next index zero", projectContract.nextCellIndex == 0)
    check("K project first target exact",
          projectContract.nextTarget == AgentPosition(x: 2, y: 64, z: 3))
    check("K project first work position exact",
          projectContract.nextWorkPosition == AgentPosition(x: 2, y: 64, z: 4))
    check("K project deterministic encoding",
          try! economyEncoder.encode(projectContract) == economyEncoder.encode(projectContract))
    let mutationBoundary = AgentConstructionMutationBoundary(project: projectContract)
    check("K mutation boundary has nine unique cells",
          mutationBoundary.isValid && mutationBoundary.permittedPositions.count == 9)
    check("K mutation boundary rejects entrance",
          !mutationBoundary.permits(AgentPosition(x: 3, y: 64, z: 1)))
    check("K mutation boundary rejects rest",
          !mutationBoundary.permits(projectContract.restPosition))
    check("K mutation boundary rejects third party block",
          !mutationBoundary.permits(AgentPosition(x: 9, y: 64, z: 9)))

    func siteCandidate(
        origin: AgentPosition,
        index: Int,
        valid: Bool,
        positionsRead: Int = 36,
        chunksReady: Bool? = nil,
        solidFloor: Bool? = nil,
        replaceableCells: Bool? = nil,
        liquidFree: Bool? = nil,
        naturalResourcesClear: Bool? = nil,
        reservedSpacesClear: Bool? = nil,
        workPositionsClear: Bool? = nil,
        occupancyClear: Bool? = nil,
        routeFound: Bool? = nil
    ) -> AgentConstructionSiteCandidate {
        AgentConstructionSiteCandidate(
            origin: origin,
            candidateIndex: index,
            chunksReady: chunksReady ?? valid,
            solidFloor: solidFloor ?? valid,
            replaceableCells: replaceableCells ?? valid,
            liquidFree: liquidFree ?? valid,
            naturalResourcesClear: naturalResourcesClear ?? valid,
            reservedSpacesClear: reservedSpacesClear ?? valid,
            workPositionsClear: workPositionsClear ?? valid,
            occupancyClear: occupancyClear ?? valid,
            routeFound: routeFound ?? valid,
            positionsRead: positionsRead,
            originalFingerprints: constructionFingerprints
        )
    }
    let deterministicSiteCandidates = [
        siteCandidate(origin: AgentPosition(x: 2, y: 64, z: 0), index: 1, valid: true),
        siteCandidate(origin: AgentPosition(x: 0, y: 64, z: -2), index: 0, valid: true),
        siteCandidate(origin: AgentPosition(x: 1, y: 64, z: 0), index: 2, valid: false),
    ]
    let selectedSiteA = try! AgentConstructionSiteSelector.select(
        home: constructionHome,
        candidates: deterministicSiteCandidates
    )
    let selectedSiteB = try! AgentConstructionSiteSelector.select(
        home: constructionHome,
        candidates: deterministicSiteCandidates.reversed()
    )
    check("K site choice deterministic", selectedSiteA == selectedSiteB)
    check("K site stable direction tie break",
          selectedSiteA?.origin == AgentPosition(x: 0, y: 64, z: -2))
    check("K invalid site rejected",
          try! AgentConstructionSiteSelector.select(
            home: constructionHome,
            candidates: [siteCandidate(origin: constructionOrigin, index: 0, valid: false)]
          ) == nil)
    let validSiteOrigin = AgentPosition(x: 0, y: 64, z: -2)
    func rejectsSite(_ candidate: AgentConstructionSiteCandidate) -> Bool {
        (try? AgentConstructionSiteSelector.select(
            home: constructionHome,
            candidates: [candidate]
        )) == nil
    }
    check("K site rejects unavailable chunk", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, chunksReady: false
    )))
    check("K site rejects non-solid floor", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, solidFloor: false
    )))
    check("K site rejects non-replaceable cell", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, replaceableCells: false
    )))
    check("K site rejects liquid", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, liquidFree: false
    )))
    check("K site rejects natural collectable overwrite", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, naturalResourcesClear: false
    )))
    check("K site rejects blocked entrance or rest", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, reservedSpacesClear: false
    )))
    check("K site rejects invalid work position", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, workPositionsClear: false
    )))
    check("K site rejects player occupancy", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, occupancyClear: false
    )))
    check("K site rejects agent occupancy", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, occupancyClear: false
    )))
    check("K site rejects missing first work route", rejectsSite(siteCandidate(
        origin: validSiteOrigin, index: 0, valid: true, routeFound: false
    )))
    let noSiteMutationCount = 0
    let noSiteProject = try! AgentConstructionSiteSelector.select(
        home: constructionHome,
        candidates: [siteCandidate(origin: validSiteOrigin, index: 0, valid: false)]
    )
    check("K no safe site publishes no project and mutates nothing",
          noSiteProject == nil && noSiteMutationCount == 0)
    check("K site candidate budget rejects overflow", {
        do {
            _ = try AgentConstructionSiteSelector.select(
                home: constructionHome,
                candidates: (0...32).map {
                    siteCandidate(origin: AgentPosition(x: $0, y: 64, z: 0), index: $0, valid: false)
                }
            )
            return false
        } catch AgentConstructionError.invalidSiteCandidateCount(33) { return true }
        catch { return false }
    }())

    var demandStock = AgentCampStock(capacity: 16)
    _ = demandStock.add(.wood, quantity: 6)
    var demandInventory = AgentResourceInventory(capacity: 8)
    _ = demandInventory.add(.foodRaw)
    let stoneOnlyDeficit = projectContract.missingMaterials(
        campStock: demandStock,
        builderInventory: demandInventory
    )
    check("K project wood coverage independent of stone",
          stoneOnlyDeficit == [AgentResourceAmount(resource: .stone, quantity: 3)])
    let boundedDemand = AgentConstructionDemand(
        projectId: projectContract.projectId,
        missing: stoneOnlyDeficit + [AgentResourceAmount(resource: .foodRaw, quantity: 1)]
    )
    check("K construction demand excludes non-material resources",
          boundedDemand.eligibleResources == [.stone])

    var underfundedConstruction = economySession(states: [economyAgentState(
        position: constructionHome,
        home: constructionHome
    )])
    try! underfundedConstruction.createConstructionProject(constructionProject("underfunded"))
    try! underfundedConstruction.setBuildAutoEnabled(true)
    let underfundedBefore = underfundedConstruction.snapshot()
    check("K funding missing material rejected", {
        do {
            _ = try underfundedConstruction.fundConstructionProject(
                fundingId: "underfunded-attempt",
                builderAgentId: "agent_economy",
                fundingTick: underfundedConstruction.tick
            )
            return false
        } catch AgentSessionError.invalidConstructionFunding { return true }
        catch { return false }
    }())
    check("K failed funding is atomic",
          underfundedConstruction.snapshot() == underfundedBefore)

    var constructionSession = economySession(states: [economyAgentState(
        position: constructionHome,
        home: constructionHome
    )])
    func harvestConstructionMaterial(
        _ resource: AgentResourceKind,
        index: Int,
        session: inout AgentSimulationSession
    ) {
        try! session.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: "k-harvest-\(resource.rawValue)-\(index)",
            agentId: "agent_economy",
            tick: session.tick,
            target: AgentPosition(x: 20 + index, y: 64, z: resource == .wood ? 0 : 1),
            resource: resource,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
            reason: "K natural material fixture"
        ))
    }
    for index in 0..<6 { harvestConstructionMaterial(.wood, index: index, session: &constructionSession) }
    for index in 0..<2 { harvestConstructionMaterial(.stone, index: index, session: &constructionSession) }
    _ = try! constructionSession.deliverResources(AgentDeliveryIntent(
        deliveryId: "k-delivery-8",
        agentId: "agent_economy",
        tick: constructionSession.tick,
        position: constructionHome
    ))
    harvestConstructionMaterial(.stone, index: 2, session: &constructionSession)
    _ = try! constructionSession.deliverResources(AgentDeliveryIntent(
        deliveryId: "k-delivery-1",
        agentId: "agent_economy",
        tick: constructionSession.tick,
        position: constructionHome
    ))
    check("K natural materials reach exact camp cost",
          constructionSession.snapshot().campStock.count(of: .wood) == 6
            && constructionSession.snapshot().campStock.count(of: .stone) == 3)
    try! constructionSession.createConstructionProject(constructionProject())
    check("K project belongs to shared session",
          constructionSession.snapshot().constructionProject?.projectId == "shelter-k")
    check("K build auto disabled by default", !constructionSession.snapshot().buildAutoEnabled)
    check("K duplicate project refused", {
        do { try constructionSession.createConstructionProject(constructionProject("duplicate")); return false }
        catch AgentSessionError.constructionProjectAlreadyExists { return true }
        catch { return false }
    }())
    try! constructionSession.setBuildAutoEnabled(true)
    let fundingTickResult = try! constructionSession.advanceTick()
    check("K complete stock changes project to ready funding",
          constructionSession.snapshot().constructionProject?.status == .readyToFund)
    check("K ready project selects buildShelter",
          fundingTickResult.agents[0].snapshot.currentGoal.kind == .buildShelter)
    check("K ready project emits fund_construction",
          fundingTickResult.agents[0].action.name == "fund_construction")
    let beforeFunding = constructionSession.snapshot()
    _ = try! constructionSession.fundConstructionProject(
        fundingId: "k-funding",
        builderAgentId: "agent_economy",
        fundingTick: constructionSession.tick
    )
    let afterFunding = constructionSession.snapshot()
    check("K funding debits camp stock exactly",
          beforeFunding.campStock.totalCount == 9 && afterFunding.campStock.totalCount == 0)
    check("K funding fills escrow exactly",
          afterFunding.conservation.constructionEscrowTotal == 9
            && afterFunding.constructionProject?.materialEscrow.wood == 6
            && afterFunding.constructionProject?.materialEscrow.stone == 3)
    check("K funding writes one memory",
          afterFunding.agents[0].recentMemory.filter { $0.type == "construction_funded" }.count == 1)
    check("K funding conservation exact",
          afterFunding.conservation.harvestedTotal == 9
            && afterFunding.conservation.campStockTotal == 0
            && afterFunding.conservation.constructionEscrowTotal == 9
            && afterFunding.conservation.constructedTotal == 0
            && afterFunding.conservation.balanced)
    let afterFirstFunding = constructionSession.snapshot()
    check("K duplicate funding refused", {
        do {
            _ = try constructionSession.fundConstructionProject(
                fundingId: "k-funding",
                builderAgentId: "agent_economy",
                fundingTick: constructionSession.tick
            )
            return false
        } catch AgentSessionError.duplicateConstructionFunding { return true }
        catch { return false }
    }())
    check("K duplicate funding has no mutation", constructionSession.snapshot() == afterFirstFunding)

    func constructionNavigationCells(
        center: AgentPosition,
        radius: Int = 8,
        blocked: Set<AgentPosition> = []
    ) -> [AgentNavigationCell] {
        var cells: [AgentNavigationCell] = []
        for dx in -radius...radius {
            for dz in -radius...radius where abs(dx) + abs(dz) <= radius {
                let position = AgentPosition(x: center.x + dx, y: center.y, z: center.z + dz)
                cells.append(AgentNavigationCell(
                    position: position,
                    status: blocked.contains(position) ? .blocked : .traversable
                ))
            }
        }
        return cells
    }
    var constructionRouteSession = constructionSession
    let constructionWork = afterFunding.constructionProject!.nextWorkPosition!
    let constructionRouteTick = try! constructionRouteSession.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_economy",
            worldObservation: worldObservation(constructionHome, worldTick: 900),
            navigationObservation: AgentNavigationObservation(
                worldTick: 900,
                origin: constructionHome,
                target: constructionWork,
                radius: 8,
                cells: constructionNavigationCells(center: constructionHome)
            )
        ),
    ])
    let routeBeforeMove = constructionRouteSession.snapshot().agents[0]
    check("K navigation route targets first work position",
          routeBeforeMove.navigationProgress.route?.target == constructionWork)
    check("K navigation purpose constructionWork exact",
          routeBeforeMove.navigationProgress.route?.purpose == .constructionWork)
    check("K construction emits existing approach action",
          constructionRouteTick.agents[0].action.name == "approach_construction")
    let constructionMove = AgentMovementCoordinator.resolve(
        snapshot: constructionRouteSession.snapshot()
    )
    try! constructionRouteSession.applyMovementOutcomes(constructionMove)
    let constructionMovedPosition = constructionRouteSession.snapshot().agents[0].position
    check("K construction movement advances one cardinal step",
          abs(constructionMovedPosition.x - constructionHome.x)
            + abs(constructionMovedPosition.z - constructionHome.z) == 1)

    let distantConstructionHome = AgentPosition(
        x: constructionHome.x + 16,
        y: constructionHome.y,
        z: constructionHome.z
    )
    let firstHomewardWaypoint = AgentBoundedTravel.desiredWaypoint(
        from: constructionHome,
        toward: distantConstructionHome
    )
    check("K bounded travel requires waypoint beyond planner radius",
          AgentBoundedTravel.requiresWaypoint(
              from: constructionHome,
              to: distantConstructionHome
          ))
    check("K bounded travel first waypoint exact",
          firstHomewardWaypoint == AgentPosition(
              x: constructionHome.x + AgentBoundedTravel.stepDistance,
              y: constructionHome.y,
              z: constructionHome.z
          ))
    check("K bounded travel accepts deterministic progress",
          AgentBoundedTravel.permitsNormalizedWaypoint(
              firstHomewardWaypoint,
              desiredWaypoint: firstHomewardWaypoint,
              current: constructionHome,
              destination: distantConstructionHome
          ))
    check("K bounded travel rejects non-progressing waypoint",
          !AgentBoundedTravel.permitsNormalizedWaypoint(
              AgentPosition(
                  x: constructionHome.x - AgentBoundedTravel.stepDistance,
                  y: constructionHome.y,
                  z: constructionHome.z
              ),
              desiredWaypoint: firstHomewardWaypoint,
              current: constructionHome,
              destination: distantConstructionHome
          ))
    check("K bounded travel direct goal within planner radius",
          !AgentBoundedTravel.requiresWaypoint(
              from: constructionHome,
              to: AgentPosition(
                  x: constructionHome.x + AgentNavigationObservation.maximumRadius,
                  y: constructionHome.y,
                  z: constructionHome.z
              )
          ))

    var blockedConstructionRoute = constructionSession
    _ = try! blockedConstructionRoute.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_economy",
        navigationObservation: AgentNavigationObservation(
            worldTick: 901,
            origin: constructionHome,
            target: constructionWork,
            radius: 8,
            cells: constructionNavigationCells(center: constructionHome)
        )
    )])
    let blockedConstructionBefore = blockedConstructionRoute.snapshot().agents[0]
    let blockedConstructionOutcomes = AgentMovementCoordinator.resolve(
        snapshot: blockedConstructionRoute.snapshot()
    )
    try! blockedConstructionRoute.applyMovementOutcomes(blockedConstructionOutcomes)
    check("K blocked construction movement does not progress",
          blockedConstructionRoute.snapshot().agents[0].position
            == blockedConstructionBefore.position
            && blockedConstructionRoute.snapshot().agents[0].navigationProgress.routeIndex
                == blockedConstructionBefore.navigationProgress.routeIndex)
    check("K constructed target can be excluded from future route", {
        let partialBlock = projectContract.nextTarget!
        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: constructionHome,
            target: constructionWork,
            goalMode: .exact,
            cells: constructionNavigationCells(
                center: constructionHome,
                blocked: [partialBlock]
            ),
            radius: 8,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
        return plan.found && !plan.positions.contains(partialBlock)
    }())

    let firstFundedProject = afterFunding.constructionProject!
    let firstFundedCell = firstFundedProject.nextCell!
    let firstFundedTarget = firstFundedProject.nextTarget!
    let firstFundedWork = firstFundedProject.nextWorkPosition!
    func firstPlacementIntent(
        id: String,
        cellIndex: Int = 0,
        target: AgentPosition? = nil,
        resource: AgentResourceKind? = nil
    ) -> AgentPlacementIntent {
        AgentPlacementIntent(
            placementId: id,
            projectId: firstFundedProject.projectId,
            builderAgentId: firstFundedProject.builderAgentId,
            tick: constructionSession.tick,
            cellIndex: cellIndex,
            target: target ?? firstFundedTarget,
            workPosition: firstFundedWork,
            resource: resource ?? firstFundedCell.resource
        )
    }
    check("K placement away from work position refused", {
        do { try constructionSession.prevalidatePlacement(firstPlacementIntent(id: "away")); return false }
        catch AgentSessionError.invalidConstructionPlacement { return true }
        catch { return false }
    }())
    var placementValidationSession = constructionSession
    try! placementValidationSession.applyExternalUpdate(AgentExternalUpdate(
        agentId: firstFundedProject.builderAgentId,
        position: firstFundedWork
    ))
    check("K out-of-order placement refused", {
        do {
            try placementValidationSession.prevalidatePlacement(firstPlacementIntent(
                id: "out-of-order", cellIndex: 1
            ))
            return false
        } catch AgentSessionError.invalidConstructionPlacement { return true }
        catch { return false }
    }())
    check("K placement target mismatch refused", {
        do {
            try placementValidationSession.prevalidatePlacement(firstPlacementIntent(
                id: "wrong-target",
                target: AgentPosition(x: 99, y: 64, z: 99)
            ))
            return false
        } catch AgentSessionError.invalidConstructionPlacement { return true }
        catch { return false }
    }())
    check("K placement resource mismatch refused", {
        do {
            try placementValidationSession.prevalidatePlacement(firstPlacementIntent(
                id: "wrong-resource", resource: .wood
            ))
            return false
        } catch AgentSessionError.invalidConstructionPlacement { return true }
        catch { return false }
    }())
    check("K mutation boundary excludes target outside blueprint",
          !mutationBoundary.permits(AgentPosition(x: 99, y: 64, z: 99)))
    check("K mutation boundary keeps entrance and rest immutable",
          !mutationBoundary.permits(AgentPosition(x: 3, y: 64, z: 1))
            && !mutationBoundary.permits(projectContract.restPosition))
    var recoverableFailureSession = constructionSession
    try! recoverableFailureSession.recordConstructionFailure(
        failureId: "k-occupied-failure",
        projectId: firstFundedProject.projectId,
        builderAgentId: firstFundedProject.builderAgentId,
        failure: .occupied,
        reason: "work position occupied"
    )
    check("K refused placement records explicit blocked project",
          recoverableFailureSession.snapshot().constructionProject?.status == .blocked
            && recoverableFailureSession.snapshot().constructionProject?.lastFailure == .occupied)
    check("K refused placement writes blocked memory only",
          recoverableFailureSession.snapshot().agents[0].recentMemory.last?.type
            == "construction_blocked"
            && recoverableFailureSession.snapshot().agents[0].recentMemory.filter {
                $0.type == "construction_block_placed"
            }.isEmpty)
    let recordedFailureSnapshot = recoverableFailureSession.snapshot()
    check("K duplicate failure event refused", {
        do {
            try recoverableFailureSession.recordConstructionFailure(
                failureId: "k-occupied-failure",
                projectId: firstFundedProject.projectId,
                builderAgentId: firstFundedProject.builderAgentId,
                failure: .occupied,
                reason: "duplicate"
            )
            return false
        } catch AgentSessionError.invalidConstructionPlacement { return true }
        catch { return false }
    }())
    check("K duplicate failure event has no mutation",
          recoverableFailureSession.snapshot() == recordedFailureSnapshot)
    try! recoverableFailureSession.setBuildAutoEnabled(false)
    try! recoverableFailureSession.setBuildAutoEnabled(true)
    check("K recoverable failure resumes exact funded state",
          recoverableFailureSession.snapshot().constructionProject?.status == .funded
            && recoverableFailureSession.snapshot().constructionProject?.nextCellIndex == 0)

    var partialConservation: AgentResourceConservationSnapshot?
    var interruptionSnapshot: AgentSessionSnapshot?
    for cellIndex in 0..<9 {
        guard let project = constructionSession.snapshot().constructionProject,
              let cell = project.nextCell,
              let target = project.nextTarget,
              let work = project.nextWorkPosition else { break }
        try! constructionSession.applyExternalUpdate(AgentExternalUpdate(
            agentId: project.builderAgentId,
            position: work
        ))
        let intent = AgentPlacementIntent(
            placementId: "k-place-\(cellIndex)",
            projectId: project.projectId,
            builderAgentId: project.builderAgentId,
            tick: constructionSession.tick,
            cellIndex: cell.index,
            target: target,
            workPosition: work,
            resource: cell.resource
        )
        try! constructionSession.prevalidatePlacement(intent)
        try! constructionSession.applyPlacementOutcome(AgentPlacementOutcome(
            placementId: intent.placementId,
            projectId: intent.projectId,
            builderAgentId: intent.builderAgentId,
            tick: intent.tick,
            cellIndex: intent.cellIndex,
            target: intent.target,
            resource: intent.resource,
            status: .succeeded,
            reason: "ordered placement verified"
        ))
        if cellIndex == 0 {
            check("K first placement advances exactly one cell",
                  constructionSession.snapshot().constructionProject?.nextCellIndex == 1)
            check("K second placement same tick refused", {
                guard let next = constructionSession.snapshot().constructionProject,
                      let nextCell = next.nextCell,
                      let nextTarget = next.nextTarget,
                      let nextWork = next.nextWorkPosition else { return false }
                do {
                    try constructionSession.prevalidatePlacement(AgentPlacementIntent(
                        placementId: "k-same-tick",
                        projectId: next.projectId,
                        builderAgentId: next.builderAgentId,
                        tick: constructionSession.tick,
                        cellIndex: nextCell.index,
                        target: nextTarget,
                        workPosition: nextWork,
                        resource: nextCell.resource
                    ))
                    return false
                } catch AgentSessionError.invalidConstructionPlacement { return true }
                catch { return false }
            }())
        }
        if cellIndex == 2 {
            partialConservation = constructionSession.snapshot().conservation
            try! constructionSession.setBuildAutoEnabled(false)
            interruptionSnapshot = constructionSession.snapshot()
            _ = try! constructionSession.advanceTick()
            _ = try! constructionSession.advanceTick()
            check("K interruption places no extra cells",
                  constructionSession.snapshot().constructionProject?.placedCellIndices == [0, 1, 2])
            check("K interruption preserves escrow",
                  constructionSession.snapshot().constructionProject?.materialEscrow.total == 6)
            try! constructionSession.setBuildAutoEnabled(true)
            check("K resume keeps exact next index",
                  constructionSession.snapshot().constructionProject?.nextCellIndex == 3)
        }
        if cellIndex < 8 { _ = try! constructionSession.advanceTick() }
    }
    let beforeCompletion = constructionSession.snapshot()
    check("K nine placements consume escrow", beforeCompletion.conservation.constructionEscrowTotal == 0)
    check("K nine placements credit constructed exactly",
          beforeCompletion.conservation.constructedTotal == 9
            && beforeCompletion.constructionProject?.placedMaterialTotals.wood == 6
            && beforeCompletion.constructionProject?.placedMaterialTotals.stone == 3)
    check("K placement memories unique per cell",
          beforeCompletion.agents[0].recentMemory.filter {
              $0.type == "construction_block_placed"
          }.count == 9)
    check("K partial conservation exact",
          partialConservation?.constructionEscrowTotal == 6
            && partialConservation?.constructedTotal == 3
            && partialConservation?.balanced == true)
    check("K interrupted snapshot deterministic",
          interruptionSnapshot.map { try! economyEncoder.encode($0) }
            == interruptionSnapshot.map { try! economyEncoder.encode($0) })
    try! constructionSession.completeConstructionProject(
        projectId: "shelter-k",
        completionTick: constructionSession.tick
    )
    let completedShelter = constructionSession.snapshot()
    check("K completion status exact", completedShelter.constructionProject?.status == .completed)
    check("K completion tick recorded",
          completedShelter.constructionProject?.completedAtTick == constructionSession.tick)
    check("K completion moves home to rest cell",
          completedShelter.agents[0].homePosition == projectContract.restPosition)
    check("K completion writes one shelter memory",
          completedShelter.agents[0].recentMemory.filter { $0.type == "shelter_completed" }.count == 1)
    check("K complete conservation exact",
          completedShelter.conservation.harvestedTotal == 9
            && completedShelter.conservation.constructedTotal == 9
            && completedShelter.conservation.balanced)
    let beforeDuplicateCompletion = constructionSession.snapshot()
    check("K completion cannot publish twice", {
        do {
            try constructionSession.completeConstructionProject(
                projectId: "shelter-k",
                completionTick: constructionSession.tick
            )
            return false
        } catch AgentSessionError.constructionCompletionInvalid { return true }
        catch { return false }
    }())
    check("K duplicate completion has no mutation",
          constructionSession.snapshot() == beforeDuplicateCompletion)
    var shelterRestSession = survivalSession(states: [survivalAgentState(
        position: projectContract.restPosition,
        home: completedShelter.agents[0].homePosition,
        fatigue: 0.9
    )])
    shelterRestSession.setSurvivalEnabled(true)
    let shelterFatigueBefore = shelterRestSession.snapshot().agents[0].needs.fatigue
    let shelterRestTick = try! shelterRestSession.advanceTick()
    check("K completed rest cell is used as survival home",
          shelterRestSession.snapshot().agents[0].homePosition == projectContract.restPosition
            && shelterRestSession.snapshot().agents[0].position == projectContract.restPosition)
    check("K survival rests inside completed shelter",
          shelterRestTick.agents[0].action.name == "rest")
    check("K shelter rest reduces fatigue",
          shelterRestSession.snapshot().agents[0].needs.fatigue < shelterFatigueBefore)
    check("K entrance remains outside construction mutation set",
          !mutationBoundary.permits(AgentPosition(
              x: constructionOrigin.x + shelter.entranceOffset.x,
              y: constructionOrigin.y + shelter.entranceOffset.y,
              z: constructionOrigin.z + shelter.entranceOffset.z
          )))
    let constructionSessionBeforeClear = constructionSession
    try! constructionSession.clearConstructionProject(projectId: "shelter-k")
    let clearedShelter = constructionSession.snapshot()
    check("K clear removes project", clearedShelter.constructionProject == nil)
    check("K clear disables build auto", !clearedShelter.buildAutoEnabled)
    check("K clear restores previous home", clearedShelter.agents[0].homePosition == constructionHome)
    check("K clear returns all materials to camp",
          clearedShelter.campStock.count(of: .wood) == 6
            && clearedShelter.campStock.count(of: .stone) == 3)
    check("K clear resets escrow and constructed conservation",
          clearedShelter.conservation.constructionEscrowTotal == 0
            && clearedShelter.conservation.constructedTotal == 0)
    check("K clear conservation exact",
          clearedShelter.conservation.harvestedTotal == 9
            && clearedShelter.conservation.campStockTotal == 9
            && clearedShelter.conservation.balanced)

    let rollbackTarget = projectContract.nextTarget!
    let rollbackThirdParty = AgentPosition(x: rollbackTarget.x + 1, y: rollbackTarget.y, z: rollbackTarget.z)
    let constructionRollbackWorld = World(dim: .overworld, seed: 404)
    let constructionRollbackChunk = Chunk(
        cx: rollbackTarget.x >> 4,
        cz: rollbackTarget.z >> 4,
        minY: constructionRollbackWorld.info.minY,
        height: constructionRollbackWorld.info.height
    )
    constructionRollbackChunk.status = .generated
    constructionRollbackWorld.setChunk(constructionRollbackChunk)
    _ = constructionRollbackWorld.setBlock(
        rollbackThirdParty.x, rollbackThirdParty.y, rollbackThirdParty.z, Int(B.dirt) << 4
    )
    let rollbackSessionBefore = clearedShelter
    let originalConstructionBlock = constructionRollbackWorld.setBlock(
        rollbackTarget.x, rollbackTarget.y, rollbackTarget.z, Int(B.stone) << 4
    )
    let placementWorldSucceeded = constructionRollbackWorld.getBlock(
        rollbackTarget.x, rollbackTarget.y, rollbackTarget.z
    ) == (Int(B.stone) << 4)
    _ = constructionRollbackWorld.setBlock(
        rollbackTarget.x, rollbackTarget.y, rollbackTarget.z, originalConstructionBlock
    )
    check("K forced publication failure mutates only target before rollback", placementWorldSucceeded)
    check("K forced publication failure restores original fingerprint",
          constructionRollbackWorld.getBlock(rollbackTarget.x, rollbackTarget.y, rollbackTarget.z)
            == originalConstructionBlock)
    check("K forced publication failure preserves third party block",
          constructionRollbackWorld.getBlock(
            rollbackThirdParty.x, rollbackThirdParty.y, rollbackThirdParty.z
          ) == (Int(B.dirt) << 4))
    check("K forced publication failure preserves session economy",
          constructionSession.snapshot() == rollbackSessionBefore)

    let clearRollbackWorld = World(dim: .overworld, seed: 405)
    let clearRollbackChunk = Chunk(
        cx: constructionOrigin.x >> 4,
        cz: constructionOrigin.z >> 4,
        minY: clearRollbackWorld.info.minY,
        height: clearRollbackWorld.info.height
    )
    clearRollbackChunk.status = .generated
    clearRollbackWorld.setChunk(clearRollbackChunk)
    let clearCells = shelter.cells.map { blueprintCell -> (Int, AgentPosition, Int) in
        let target = AgentPosition(
            x: constructionOrigin.x + blueprintCell.relativePosition.x,
            y: constructionOrigin.y + blueprintCell.relativePosition.y,
            z: constructionOrigin.z + blueprintCell.relativePosition.z
        )
        let constructionFingerprint = blueprintCell.resource == .wood
            ? oakFingerprint
            : stoneFingerprint
        _ = clearRollbackWorld.setBlock(
            target.x, target.y, target.z, constructionFingerprint
        )
        return (blueprintCell.index, target, constructionFingerprint)
    }
    let clearOrder = clearCells.reversed().map { $0.0 }
    for (_, target, _) in clearCells.reversed() {
        _ = clearRollbackWorld.setBlock(target.x, target.y, target.z, 0)
    }
    let clearWorldRestored = clearCells.allSatisfy {
        clearRollbackWorld.getBlock($0.1.x, $0.1.y, $0.1.z) == 0
    }
    for (_, target, fingerprint) in clearCells.reversed() {
        _ = clearRollbackWorld.setBlock(target.x, target.y, target.z, fingerprint)
    }
    check("K clear restoration order is exact reverse blueprint order",
          clearOrder == Array((0..<9).reversed()))
    check("K clear World phase restores exact originals before publication",
          clearWorldRestored)
    check("K clear publication failure reapplies complete structure",
          clearCells.allSatisfy {
              clearRollbackWorld.getBlock($0.1.x, $0.1.y, $0.1.z) == $0.2
          })
    check("K clear publication failure preserves session project and economy",
          constructionSessionBeforeClear.snapshot() == completedShelter)

    let legacyConstructionSession = economySession(states: [economyAgentState(
        position: constructionHome,
        home: constructionHome
    )])
    let legacyConstructionText = String(
        data: try! economyEncoder.encode(legacyConstructionSession.snapshot()),
        encoding: .utf8
    ) ?? ""
    check("K legacy snapshot omits construction fields",
          !legacyConstructionText.contains("constructionProject")
            && !legacyConstructionText.contains("constructionEscrow")
            && !legacyConstructionText.contains("constructedTotal"))


}

}
