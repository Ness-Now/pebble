import Foundation
import PebbleAgents

private func boundedNavigationAgent(
    position: AgentPosition,
    home: AgentPosition
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_0",
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: home,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "bounded navigation fixture", startedAtTick: 0, urgency: 0
        ),
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

private func boundedNavigationSession(
    position: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
    home: AgentPosition = AgentPosition(x: 0, y: 64, z: 0),
    maximumReplans: Int = 3
) -> AgentSimulationSession {
    try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 509,
            memoryPolicy: .bounded(maxEntries: 32),
            navigationMaxReplans: maximumReplans,
            navigationReplanCooldownTicks: 1
        ),
        agents: [boundedNavigationAgent(position: position, home: home)]
    )
}

private func boundedNavigationCandidate(
    id: String,
    target: AgentPosition,
    tick: Int
) -> AgentAutonomousActivityCandidate {
    AgentAutonomousActivityCandidate(
        candidateID: id,
        actorID: AgentID(rawValue: "agent_0")!,
        domain: .wildGathering,
        actionKey: "gather",
        stableReference: "bounded-navigation:\(id)",
        target: target,
        source: .opportunity,
        priorityBand: 30,
        urgency: 70,
        distance: 0,
        observedAtTick: tick
    )
}

private func boundedNavigationObservation(
    origin: AgentPosition,
    target: AgentPosition,
    traversableX: ClosedRange<Int>,
    targetBlocked: Bool
) -> AgentNavigationObservation {
    AgentNavigationObservation(
        worldTick: 0,
        origin: origin,
        target: target,
        cells: traversableX.map { x in
            let position = AgentPosition(x: x, y: origin.y, z: origin.z)
            return AgentNavigationCell(
                position: position,
                status: targetBlocked && position == target ? .blocked : .traversable
            )
        }
    )
}

private func publishBoundedEastStep(
    result: AgentSessionTickResult,
    session: inout AgentSimulationSession
) {
    let agent = session.snapshot().agents[0]
    let action = result.agents[0].action
    let destination = AgentPosition(
        x: agent.position.x + 1,
        y: agent.position.y,
        z: agent.position.z
    )
    try! session.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: AgentMovementOutcome(
                agentId: agent.id,
                tick: session.tick,
                status: .moved,
                fromPosition: agent.position,
                toPosition: destination,
                requestedDirection: .east,
                requestedDX: 1,
                requestedDY: 0,
                requestedDZ: 0,
                appliedDX: 1,
                appliedDY: 0,
                appliedDZ: 0,
                goalKind: .civilizationActivity,
                actionReason: action.reason,
                resolutionReason: "PebbleCore path and Entity.move verified",
                worldTickObserved: 0,
                distanceFromHomeBefore: agent.distanceFromHome,
                distanceFromHomeAfter: abs(destination.x - agent.homePosition.x),
                distanceReducedTowardHome: max(
                    0,
                    agent.distanceFromHome - abs(destination.x - agent.homePosition.x)
                )
            )
        )
    ])
}

private func boundedExplorationObservation(
    position: AgentPosition
) -> AgentWorldObservation {
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: true,
            surfaceY: position.y,
            height: position.y,
            blockBelow: 1,
            blockAtFeet: 0,
            blockAtHead: 0,
            groundPresent: true,
            feetClear: true,
            headClear: true
        )
    }
    return try! AgentWorldObservation(
        worldTick: 0,
        position: position,
        center: column(position),
        neighbors: AgentCardinalDirection.allCases.map { direction in
            let neighbor = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            return AgentWorldNeighborObservation(
                direction: direction,
                column: column(neighbor),
                stepDelta: 0,
                traversable: true,
                dangerousDrop: false
            )
        },
        biomeId: 1,
        biomeName: "plains",
        combinedLight: 15,
        skyLight: 15,
        blockLight: 0,
        dayTime: 0,
        raining: false,
        thundering: false
    )
}

func runPebbleAgentsBoundedAutonomousNavigationSmoke() {
    section("Gate B convergence bounded autonomous navigation")

    let origin = AgentPosition(x: 0, y: 64, z: 0)
    let outsideLocalObservation = AgentPosition(x: 12, y: 64, z: 0)
    let remoteOrigin = AgentPosition(x: 8, y: 64, z: 0)
    let localActivity = AgentPosition(x: 12, y: 64, z: 0)
    check(
        "navigation radius is a local segment radius",
        AgentBoundedTravel.isLocallyBoundedSegment(
            from: remoteOrigin,
            to: localActivity
        )
    )
    check(
        "remote destination requires progressive waypoint",
        AgentBoundedTravel.requiresWaypoint(from: origin, to: outsideLocalObservation)
    )
    let outwardWaypoint = AgentBoundedTravel.desiredWaypoint(
        from: origin,
        toward: outsideLocalObservation
    )
    check(
        "progressive waypoint is deterministic and local",
        outwardWaypoint == AgentPosition(x: 4, y: 64, z: 0)
            && AgentBoundedTravel.isLocallyBoundedSegment(from: origin, to: outwardWaypoint)
    )
    check(
        "non-progressing waypoint is refused",
        !AgentBoundedTravel.permitsNormalizedWaypoint(
            AgentPosition(x: -1, y: 64, z: 0),
            desiredWaypoint: outwardWaypoint,
            current: origin,
            destination: outsideLocalObservation
        )
    )

    let migrationTarget = AgentPosition(x: 4, y: 64, z: 0)
    let migrationProgress = AgentNavigationProgress(
        status: .active,
        route: AgentNavigationRoute(
            purpose: .migrationArrival,
            target: migrationTarget,
            positions: [origin, AgentPosition(x: 1, y: 64, z: 0), migrationTarget],
            plannedAtTick: 0,
            visitedNodeCount: 3
        ),
        routeIndex: 0,
        lastPlanTick: 0
    )
    let migrationAgent = AgentSessionAgentState(
        id: "agent_0",
        state: "idle",
        position: origin,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: origin,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .migrateToSettlement,
            reason: "population route remains authoritative",
            startedAtTick: 0,
            urgency: 90
        ),
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
        navigationProgress: migrationProgress
    )
    var migrationSession = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 509,
            memoryPolicy: .bounded(maxEntries: 32)
        ),
        agents: [migrationAgent]
    )
    try! migrationSession.setAutonomousActivityEnabled(true)
    _ = try! migrationSession.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "deferred-by-migration",
            target: outsideLocalObservation,
            tick: migrationSession.tick
        )
    ])
    check(
        "activity arbitration preserves another domain's active route",
        migrationSession.snapshot().agents[0].navigationProgress
            == migrationProgress
    )
    check(
        "admission-validated migration route keeps its separate range contract",
        !AgentNavigationPurpose.migrationArrival.targetMustFitLocalObservationRadius
            && AgentNavigationPurpose.civilizationActivity
                .targetMustFitLocalObservationRadius
    )

    var progressive = boundedNavigationSession()
    try! progressive.setAutonomousActivityEnabled(true)
    _ = try! progressive.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "progressive",
            target: outsideLocalObservation,
            tick: progressive.tick
        )
    ])
    var progressTick = try! progressive.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: boundedNavigationObservation(
                origin: origin,
                target: outwardWaypoint,
                traversableX: 0...4,
                targetBlocked: false
            )
        )
    ])
    check(
        "long activity plans first bounded waypoint",
        progressTick.agents[0].snapshot.navigationProgress.route?.purpose
            == .civilizationActivity
            && progressTick.agents[0].snapshot.navigationProgress.route?.target
                == outwardWaypoint
    )
    check(
        "waypoint emits normal physical movement intent",
        progressTick.agents[0].action.name == "approach_activity"
            && progressTick.agents[0].action.dx == 1
    )
    for _ in 0..<4 {
        publishBoundedEastStep(result: progressTick, session: &progressive)
        if progressive.snapshot().agents[0].position == outwardWaypoint { break }
        let current = progressive.snapshot().agents[0].position
        progressTick = try! progressive.advanceTick(perceptions: [
            AgentPerceptionInput(
                agentId: "agent_0",
                navigationObservation: boundedNavigationObservation(
                    origin: current,
                    target: outwardWaypoint,
                    traversableX: current.x...outwardWaypoint.x,
                    targetBlocked: false
                )
            )
        ])
    }
    check(
        "first waypoint is reached through verified one-step publications",
        progressive.snapshot().agents[0].position == outwardWaypoint
            && progressive.snapshot().agents[0].navigationProgress.status == .arrived
    )
    let secondSegment = try! progressive.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: boundedNavigationObservation(
                origin: outwardWaypoint,
                target: outsideLocalObservation,
                traversableX: 4...12,
                targetBlocked: true
            )
        )
    ])
    check(
        "successful waypoint progression refreshes retry budget",
        secondSegment.agents[0].snapshot.navigationProgress.route?.target
            == outsideLocalObservation
            && secondSegment.agents[0].snapshot.navigationProgress.replanCount == 0
    )

    var beyondHome = boundedNavigationSession(position: remoteOrigin, home: origin)
    try! beyondHome.setAutonomousActivityEnabled(true)
    _ = try! beyondHome.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "local-beyond-home-radius",
            target: localActivity,
            tick: beyondHome.tick
        )
    ])
    let beyondTick = try! beyondHome.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: boundedNavigationObservation(
                origin: remoteOrigin,
                target: localActivity,
                traversableX: 8...12,
                targetBlocked: true
            )
        )
    ])
    publishBoundedEastStep(result: beyondTick, session: &beyondHome)
    check(
        "valid local activity step may cross former global home radius",
        beyondHome.snapshot().agents[0].position == AgentPosition(x: 9, y: 64, z: 0)
            && beyondHome.snapshot().agents[0].distanceFromHome == 9
    )

    let boundaryPosition = AgentPosition(x: 8, y: 64, z: 0)
    let boundaryOutcome = AgentMovementOutcome(
        agentId: "agent_0",
        tick: 0,
        status: .moved,
        fromPosition: AgentPosition(x: 7, y: 64, z: 0),
        toPosition: boundaryPosition,
        requestedDirection: .east,
        requestedDX: 1,
        requestedDY: 0,
        requestedDZ: 0,
        appliedDX: 1,
        appliedDY: 0,
        appliedDZ: 0,
        goalKind: .explore,
        actionReason: "explore",
        resolutionReason: "safe cardinal movement",
        worldTickObserved: 0,
        distanceFromHomeBefore: 7,
        distanceFromHomeAfter: 8,
        distanceReducedTowardHome: 0
    )
    let explorationTrace = AgentFeedbackLoop.adjustAction(
        agentId: "agent_0",
        tick: 1,
        position: boundaryPosition,
        homePosition: origin,
        goal: AgentGoal(
            kind: .explore, reason: "bounded exploration", startedAtTick: 0, urgency: 1
        ),
        baseAction: AgentAction(
            name: "move_abstract", reason: "explore east", tick: 1,
            dx: 1, dy: 0, dz: 0
        ),
        worldObservation: boundedExplorationObservation(position: boundaryPosition),
        occupiedPositions: [],
        lastMovementOutcome: boundaryOutcome,
        retrievedMemories: [],
        configuration: .live
    )
    check(
        "true exploration boundary prevents repeated outward step",
        explorationTrace.finalDirection == .west
            && explorationTrace.dominantFactor.kind == .explorationBoundary
    )
    check(
        "exploration outside its true boundary requires strict homeward progress",
        AgentFeedbackLoop.respectsExplorationHomeBoundary(
            distanceBefore: 7, distanceAfter: 8, maximumDistance: 8
        )
            && AgentFeedbackLoop.respectsExplorationHomeBoundary(
                distanceBefore: 8, distanceAfter: 7, maximumDistance: 8
            )
            && !AgentFeedbackLoop.respectsExplorationHomeBoundary(
                distanceBefore: 8, distanceAfter: 8, maximumDistance: 8
            )
            && !AgentFeedbackLoop.respectsExplorationHomeBoundary(
                distanceBefore: 9, distanceAfter: 10, maximumDistance: 8
            )
    )

    var terminal = boundedNavigationSession(maximumReplans: 0)
    try! terminal.setAutonomousActivityEnabled(true)
    let blockedTarget = AgentPosition(x: 3, y: 64, z: 0)
    _ = try! terminal.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "blocked-route", target: blockedTarget, tick: terminal.tick
        )
    ])
    let unavailableRoute = boundedNavigationObservation(
        origin: origin,
        target: blockedTarget,
        traversableX: 0...0,
        targetBlocked: true
    )
    _ = try! terminal.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: unavailableRoute
        )
    ])
    _ = try! terminal.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "blocked-route", target: blockedTarget, tick: terminal.tick
        )
    ])
    _ = try! terminal.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_0",
            navigationObservation: unavailableRoute
        )
    ])
    check(
        "bounded navigation reaches explicit terminal replan state",
        terminal.snapshot().agents[0].navigationProgress.lastFailure
            == .replanLimitReached
    )
    let blockedSelection = try! terminal.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "blocked-route", target: blockedTarget, tick: terminal.tick
        )
    ])
    let terminalActivity = terminal.autonomousActivitySnapshot()
    check(
        "terminal route closes activity through existing blocked lifecycle",
        blockedSelection.isEmpty
            && terminalActivity.activeActivities.isEmpty
            && terminalActivity.counters.blockCount == 1
    )
    check(
        "terminal route enters bounded candidate cooldown",
        terminalActivity.cooldowns.first?.candidateID == "blocked-route"
    )
    _ = try! terminal.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "blocked-route", target: blockedTarget, tick: terminal.tick
        )
    ])
    check(
        "terminal route does not append retry storm records",
        terminal.autonomousActivitySnapshot().counters.blockCount == 1
    )
    let alternative = try! terminal.selectAutonomousActivities([
        boundedNavigationCandidate(
            id: "blocked-route", target: blockedTarget, tick: terminal.tick
        ),
        boundedNavigationCandidate(
            id: "local-alternative",
            target: AgentPosition(x: 1, y: 64, z: 0),
            tick: terminal.tick
        ),
    ])
    check(
        "cooldown permits deterministic causal alternative",
        alternative.first?.candidate.candidateID == "local-alternative"
            && terminal.snapshot().agents[0].navigationProgress.replanCount == 0
    )

    let homeWaypoint = AgentBoundedTravel.desiredWaypoint(
        from: outsideLocalObservation,
        toward: origin
    )
    check(
        "return-home travel uses the same bounded waypoint contract",
        homeWaypoint == AgentPosition(x: 8, y: 64, z: 0)
            && AgentBoundedTravel.isLocallyBoundedSegment(
                from: outsideLocalObservation,
                to: homeWaypoint
            )
            && abs(homeWaypoint.x - origin.x) < abs(outsideLocalObservation.x - origin.x)
    )
}
