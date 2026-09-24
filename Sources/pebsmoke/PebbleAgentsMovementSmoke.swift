import Foundation
import simd
import PebbleAgents
import PebbleCore

func runPebbleAgentsMovementSmoke() {
// ---------------------------------------------------------------------------
section("PebbleAgents safe cardinal movement")
do {
    let origin = AgentPosition(x: 0, y: 64, z: 0)

    func movementColumn(
        _ position: AgentPosition,
        ready: Bool = true,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true
    ) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: ready,
            surfaceY: ready ? position.y : nil,
            height: ready ? position.y : nil,
            blockBelow: ready ? (ground ? 1 : 0) : nil,
            blockAtFeet: ready ? (feet ? 0 : 1) : nil,
            blockAtHead: ready ? (head ? 0 : 1) : nil,
            groundPresent: ready && ground,
            feetClear: ready && feet,
            headClear: ready && head
        )
    }

    func movementObservation(
        position: AgentPosition = origin,
        target: AgentCardinalDirection = .east,
        ready: Bool = true,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true,
        step: Int? = 0,
        traversable: Bool = true,
        drop: Bool = false,
        worldTick: Int = 7,
        physicalCoverageDigest: String = "coverage-A"
    ) -> AgentWorldObservation {
        let neighbors = AgentCardinalDirection.allCases.map { direction in
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            let customized = direction == target
            return AgentWorldNeighborObservation(
                direction: direction,
                column: movementColumn(
                    neighborPosition,
                    ready: customized ? ready : true,
                    ground: customized ? ground : true,
                    feet: customized ? feet : true,
                    head: customized ? head : true
                ),
                stepDelta: customized ? step : 0,
                traversable: customized ? traversable : true,
                dangerousDrop: customized ? drop : false
            )
        }
        return try! AgentWorldObservation(
            worldTick: worldTick,
            position: position,
            center: movementColumn(position),
            neighbors: neighbors,
            biomeId: 1,
            biomeName: "plains",
            combinedLight: 15,
            skyLight: 15,
            blockLight: 0,
            dayTime: 0,
            raining: false,
            thundering: false,
            physicalCoverageDigest: physicalCoverageDigest
        )
    }

    func movementState(
        id: String = "agent_a",
        position: AgentPosition = origin,
        home: AgentPosition = origin,
        goal: AgentGoalKind = .explore,
        needs: AgentNeeds = AgentNeeds(
            hunger: 0.2, fatigue: 0.1, curiosity: 0.8, safety: 0.9
        ),
        health: Int = 90,
        action: AgentAction? = AgentAction(
            name: "move_abstract", reason: "goal explore", tick: 0, dx: 1, dy: 0, dz: 0
        ),
        observation: AgentWorldObservation? = movementObservation(),
        navigationProgress: AgentNavigationProgress = AgentNavigationProgress()
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "moving",
            position: position,
            needs: needs,
            health: health,
            fear: 12,
            homePosition: home,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: goal, reason: "test", startedAtTick: 0, urgency: 1),
            lastAction: action,
            lastActionEffect: nil,
            memory: [],
            tickCreated: 0,
            ticksAlive: 0,
            observationCount: 0,
            nearbyObservationCount: 0,
            goalSelectionCount: 0,
            goalChangeCount: 0,
            actionCount: 3,
            actionEffectCount: 2,
            movementCount: 0,
            totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0,
            totalDistanceReducedTowardHome: 0,
            lastWorldObservation: observation,
            navigationProgress: navigationProgress
        )
    }

    func movementSession(
        _ states: [AgentSessionAgentState],
        policy: AgentMemoryPolicy = .legacyUnbounded
    ) -> AgentSimulationSession {
        let configuration = try! AgentSessionConfiguration(
            seed: 7,
            recentMemorySnapshotLimit: 20,
            memoryPolicy: policy
        )
        return try! AgentSimulationSession(configuration: configuration, agents: states)
    }

    func resolved(_ state: AgentSessionAgentState) -> AgentMovementOutcome {
        AgentMovementCoordinator.resolve(snapshot: movementSession([state]).snapshot())[0]
    }

    func runIncrement06FreshProcessRestartPhase(_ phase: String) {
        guard let root = ProcessInfo.processInfo.environment[
            "PEBBLELAB_INCREMENT06_RESTART_ROOT"
        ], root.hasPrefix("/tmp/"), root != "/tmp/" else {
            check("increment 06 fresh restart root is isolated", false)
            return
        }
        let checkpointURL = URL(fileURLWithPath: root)
            .appendingPathComponent("checkpoint.json")
        let expectedURL = URL(fileURLWithPath: root)
            .appendingPathComponent("expected-continuation.json")
        let directObservationA = movementObservation(
            physicalCoverageDigest: "restart-coverage-A"
        )
        let directObservationB = movementObservation(
            worldTick: 12,
            physicalCoverageDigest: "restart-coverage-B"
        )
        let directState = movementState(
            id: "agent_direct_restart",
            home: AgentPosition(x: 1, y: 64, z: 0),
            goal: .seekSafety,
            needs: AgentNeeds(
                hunger: 0, fatigue: 0, curiosity: 0, safety: 0.9
            ),
            health: 20,
            action: AgentAction(
                name: "move_abstract", reason: "goal seekSafety", tick: 0,
                dx: 1, dy: 0, dz: 0
            ),
            observation: directObservationA
        )
        let routedOrigin = AgentPosition(x: 4, y: 64, z: 0)
        let routedObservation = movementObservation(
            position: routedOrigin,
            physicalCoverageDigest: "restart-route-coverage"
        )
        let routedTarget = AgentPosition(x: 5, y: 64, z: 0)
        let routedState = movementState(
            id: "agent_routed_restart",
            position: routedOrigin,
            home: routedOrigin,
            action: AgentAction(
                name: "approach_activity", reason: "bounded routed work",
                tick: 0, dx: 1, dy: 0, dz: 0, target: routedTarget
            ),
            observation: routedObservation,
            navigationProgress: AgentNavigationProgress(
                status: .active,
                route: AgentNavigationRoute(
                    purpose: .civilizationActivity,
                    target: routedTarget,
                    positions: [routedOrigin, routedTarget],
                    plannedAtTick: 0,
                    visitedNodeCount: 2
                ),
                routeIndex: 0,
                replanCount: 2,
                consecutiveBlockedMoves: 0,
                lastPlanTick: 0
            )
        )

        func readiness(
            state: AgentSessionAgentState,
            reason: AgentPathReadinessReason
        ) -> AgentMovementOutcome {
            let intent = resolved(state)
            return AgentMovementOutcome(
                agentId: intent.agentId,
                tick: intent.tick,
                status: .readinessUnavailable,
                fromPosition: intent.fromPosition,
                toPosition: intent.fromPosition,
                requestedDirection: intent.requestedDirection,
                requestedDX: intent.requestedDX,
                requestedDY: intent.requestedDY,
                requestedDZ: intent.requestedDZ,
                appliedDX: 0,
                appliedDY: 0,
                appliedDZ: 0,
                goalKind: intent.goalKind,
                actionReason: intent.actionReason,
                resolutionReason:
                    "PebbleCore bounded path readiness \(reason.rawValue)",
                pathReadinessReason: reason,
                pathReadinessRequestIdentity: AgentMovementRequestIdentity(
                    action: state.lastAction!, goal: state.currentGoal
                ),
                pathReadinessContextDigest:
                    state.lastWorldObservation!.physicalReadinessContextDigest,
                worldTickObserved: intent.worldTickObserved,
                distanceFromHomeBefore: intent.distanceFromHomeBefore,
                distanceFromHomeAfter: intent.distanceFromHomeBefore,
                distanceReducedTowardHome: 0
            )
        }

        func continueAcrossBoundary(
            _ session: inout AgentSimulationSession
        ) throws -> (
            unchangedAction: String?, changedAction: String?,
            changedDominantFactor: AgentDecisionFactorKind?
        ) {
            _ = try session.advanceTick(perceptions: [
                AgentPerceptionInput(
                    agentId: directState.id,
                    worldObservation: directObservationA
                ),
                AgentPerceptionInput(
                    agentId: routedState.id,
                    worldObservation: routedObservation
                ),
            ])
            let unchangedAction = session.snapshot().agents.first {
                $0.id == directState.id
            }?.lastAction?.name
            try session.applyMovementOutcomes(
                AgentMovementCoordinator.resolve(snapshot: session.snapshot())
            )
            _ = try session.advanceTick(perceptions: [
                AgentPerceptionInput(
                    agentId: directState.id,
                    worldObservation: directObservationB
                ),
                AgentPerceptionInput(
                    agentId: routedState.id,
                    worldObservation: routedObservation
                ),
            ])
            let changed = session.snapshot().agents.first {
                $0.id == directState.id
            }
            return (
                unchangedAction,
                changed?.lastAction?.name,
                changed?.lastFeedbackDecisionTrace?.dominantFactor.kind
            )
        }

        switch phase {
        case "write":
            do {
                var session = movementSession([directState, routedState])
                try session.applyVerifiedPhysicalMovements([
                    AgentVerifiedPhysicalMovement(
                        kind: .navigationStep,
                        outcome: readiness(
                            state: directState, reason: .nodeBudgetExhausted
                        )
                    ),
                    AgentVerifiedPhysicalMovement(
                        kind: .navigationStep,
                        outcome: readiness(
                            state: routedState, reason: .coverageLimited
                        )
                    ),
                ])
                let checkpoint = try session.makeCheckpoint()
                let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
                try checkpointBytes.write(to: checkpointURL, options: .atomic)
                var continuous = session
                _ = try continueAcrossBoundary(&continuous)
                try continuous.durableStateBytes().write(
                    to: expectedURL, options: .atomic
                )
                let snapshot = session.snapshot()
                check("increment 06 fresh restart writer schema 45",
                      checkpoint.schemaVersion == 45)
                check("increment 06 fresh restart writer direct deferred",
                      snapshot.agents.first {
                          $0.id == directState.id
                      }?.lastMovementOutcome?.status == .readinessUnavailable)
                check("increment 06 fresh restart writer routed budget consumed",
                      snapshot.agents.first {
                          $0.id == routedState.id
                      }?.navigationProgress.replanCount == 2)
            } catch {
                check("increment 06 fresh restart writer completed", false,
                      "\(error)")
            }
        case "read":
            do {
                let checkpointBytes = try Data(contentsOf: checkpointURL)
                let checkpoint = try AgentCheckpointCodec.decode(
                    AgentSessionCheckpoint.self, from: checkpointBytes
                )
                var restarted = try AgentSimulationSession.restoring(checkpoint)
                let restored = restarted.snapshot()
                check("increment 06 fresh restart reader schema 45",
                      checkpoint.schemaVersion == 45)
                check("increment 06 fresh restart retains direct deferral",
                      restored.agents.first {
                          $0.id == directState.id
                      }?.lastMovementOutcome?.pathReadinessReason
                          == .nodeBudgetExhausted)
                check("increment 06 fresh restart retains routed budget",
                      restored.agents.first {
                          $0.id == routedState.id
                      }?.navigationProgress.replanCount == 2)
                let continuation = try continueAcrossBoundary(&restarted)
                check("increment 06 unchanged direct request stays deferred",
                      continuation.unchangedAction == "wait")
                check("increment 06 changed context re-enables one request",
                      continuation.changedAction == "move_abstract"
                          && continuation.changedDominantFactor
                          != .pathReadinessDeferral)
                check("increment 06 fresh restart continuation is byte exact",
                      try restarted.durableStateBytes()
                          == Data(contentsOf: expectedURL))
            } catch {
                check("increment 06 fresh restart reader completed", false,
                      "\(error)")
            }
        default:
            check("increment 06 fresh restart phase recognized", false, phase)
        }
    }

    if let phase = ProcessInfo.processInfo.environment[
        "PEBBLELAB_INCREMENT06_RESTART_PHASE"
    ] {
        runIncrement06FreshProcessRestartPhase(phase)
        return
    }

    let noAction = resolved(movementState(action: nil))
    check("movement no action not requested", noAction.status == .notRequested)
    check("movement no action reason", noAction.resolutionReason == "no movement intent")
    let waitAction = AgentAction(name: "wait", reason: "goal idle", tick: 0)
    check("movement non movement action not requested", resolved(movementState(action: waitAction)).status == .notRequested)

    func invalidAction(dx: Int?, dy: Int?, dz: Int?) -> AgentMovementOutcome {
        resolved(movementState(action: AgentAction(
            name: "move_abstract", reason: "invalid", tick: 0, dx: dx, dy: dy, dz: dz
        )))
    }
    check("movement zero delta blocked", invalidAction(dx: 0, dy: 0, dz: 0).resolutionReason == "invalid movement intent")
    check("movement diagonal blocked", invalidAction(dx: 1, dy: 0, dz: 1).status == .blocked)
    check("movement multi case blocked", invalidAction(dx: 2, dy: 0, dz: 0).status == .blocked)
    check("movement vertical blocked", invalidAction(dx: 0, dy: 1, dz: 0).status == .blocked)
    check("movement missing observation blocked", resolved(movementState(observation: nil)).resolutionReason == "missing world observation")
    let stale = movementObservation(position: AgentPosition(x: 4, y: 64, z: 0))
    check("movement stale observation blocked", resolved(movementState(observation: stale)).resolutionReason == "stale world observation")

    let directions: [(AgentCardinalDirection, Int, Int)] = [
        (.north, 0, -1), (.east, 1, 0), (.south, 0, 1), (.west, -1, 0),
    ]
    var directionOutcomes: [AgentMovementOutcome] = []
    for (direction, dx, dz) in directions {
        let outcome = resolved(movementState(
            action: AgentAction(name: "move_abstract", reason: "direction", tick: 0, dx: dx, dy: 0, dz: dz),
            observation: movementObservation(target: direction)
        ))
        directionOutcomes.append(outcome)
    }
    check("movement north direction", directionOutcomes[0].requestedDirection == .north && directionOutcomes[0].toPosition.z == -1)
    check("movement east direction", directionOutcomes[1].requestedDirection == .east && directionOutcomes[1].toPosition.x == 1)
    check("movement south direction", directionOutcomes[2].requestedDirection == .south && directionOutcomes[2].toPosition.z == 1)
    check("movement west direction", directionOutcomes[3].requestedDirection == .west && directionOutcomes[3].toPosition.x == -1)

    check("movement unavailable chunk blocked",
          resolved(movementState(observation: movementObservation(ready: false))).resolutionReason == "target chunk unavailable")
    check("movement dangerous drop blocked",
          resolved(movementState(observation: movementObservation(drop: true))).resolutionReason == "dangerous drop")
    check("movement no ground blocked",
          resolved(movementState(observation: movementObservation(ground: false))).resolutionReason == "no ground at target")
    check("movement feet blocked",
          resolved(movementState(observation: movementObservation(feet: false))).resolutionReason == "target body space blocked")
    check("movement head blocked",
          resolved(movementState(observation: movementObservation(head: false))).resolutionReason == "target body space blocked")
    check("movement unknown step blocked",
          resolved(movementState(observation: movementObservation(step: nil))).resolutionReason == "unknown target step")
    check("movement low step blocked",
          resolved(movementState(observation: movementObservation(step: -2))).resolutionReason == "target step out of range")
    check("movement high step blocked",
          resolved(movementState(observation: movementObservation(step: 2))).resolutionReason == "target step out of range")
    check("movement non traversable blocked",
          resolved(movementState(observation: movementObservation(traversable: false))).resolutionReason == "neighbor not traversable")

    let flat = resolved(movementState())
    check("movement flat cardinal moved", flat.status == .moved && flat.appliedDX == 1 && flat.appliedDY == 0 && flat.appliedDZ == 0)
    let up = resolved(movementState(observation: movementObservation(step: 1)))
    check("movement step up", up.status == .moved && up.toPosition.y == 65 && up.appliedDY == 1)
    let down = resolved(movementState(observation: movementObservation(step: -1)))
    check("movement step down", down.status == .moved && down.toPosition.y == 63 && down.appliedDY == -1)

    let towardHome = resolved(movementState(
        position: origin,
        home: AgentPosition(x: 2, y: 64, z: 0),
        goal: .seekSafety,
        action: AgentAction(name: "move_abstract", reason: "goal seekSafety", tick: 0, dx: 1, dy: 0, dz: 0)
    ))
    check("movement distance home before", towardHome.distanceFromHomeBefore == 2)
    check("movement distance home after", towardHome.distanceFromHomeAfter == 1)
    check("movement distance reduced home", towardHome.distanceReducedTowardHome == 1)
    check("movement stationary distance unchanged",
          noAction.distanceFromHomeBefore == noAction.distanceFromHomeAfter && noAction.distanceReducedTowardHome == 0)

    let occupiedStates = [
        movementState(id: "agent_a"),
        movementState(id: "agent_b", position: AgentPosition(x: 1, y: 64, z: 0), home: AgentPosition(x: 1, y: 64, z: 0), action: nil,
                      observation: movementObservation(position: AgentPosition(x: 1, y: 64, z: 0))),
    ]
    let occupiedOutcomes = AgentMovementCoordinator.resolve(snapshot: movementSession(occupiedStates).snapshot())
    check("movement occupied target blocked", occupiedOutcomes[0].resolutionReason == "target occupied")

    let swapStates = [
        movementState(id: "agent_a"),
        movementState(
            id: "agent_b",
            position: AgentPosition(x: 1, y: 64, z: 0),
            home: AgentPosition(x: 1, y: 64, z: 0),
            action: AgentAction(name: "move_abstract", reason: "swap", tick: 0, dx: -1, dy: 0, dz: 0),
            observation: movementObservation(position: AgentPosition(x: 1, y: 64, z: 0), target: .west)
        ),
    ]
    let swap = AgentMovementCoordinator.resolve(snapshot: movementSession(swapStates).snapshot())
    check("movement swap first blocked", swap[0].resolutionReason == "target occupied")
    check("movement swap second blocked", swap[1].resolutionReason == "target occupied")

    let conflictStates = [
        movementState(id: "agent_b", position: AgentPosition(x: 1, y: 64, z: 0), home: AgentPosition(x: 1, y: 64, z: 0),
                      action: AgentAction(name: "move_abstract", reason: "west", tick: 0, dx: -1, dy: 0, dz: 0),
                      observation: movementObservation(position: AgentPosition(x: 1, y: 64, z: 0), target: .west)),
        movementState(id: "agent_a", position: AgentPosition(x: -1, y: 64, z: 0), home: AgentPosition(x: -1, y: 64, z: 0),
                      action: AgentAction(name: "move_abstract", reason: "east", tick: 0, dx: 1, dy: 0, dz: 0),
                      observation: movementObservation(position: AgentPosition(x: -1, y: 64, z: 0))),
    ]
    let conflict = AgentMovementCoordinator.resolve(snapshot: movementSession(conflictStates).snapshot())
    let conflictPermuted = AgentMovementCoordinator.resolve(snapshot: movementSession(Array(conflictStates.reversed())).snapshot())
    check("movement conflict results sorted", conflict.map(\.agentId) == ["agent_a", "agent_b"])
    check("movement conflict lexical winner", conflict[0].status == .moved)
    check("movement conflict loser blocked", conflict[1].status == .blocked && conflict[1].resolutionReason == "target conflict")
    check("movement conflict source order independent", conflict == conflictPermuted)
    check("movement coordinator deterministic", conflict == AgentMovementCoordinator.resolve(snapshot: movementSession(conflictStates).snapshot()))

    var applySession = movementSession([movementState()])
    let applyBefore = applySession.snapshot()
    try! applySession.applyMovementOutcomes([flat])
    let applied = applySession.snapshot().agents[0]
    check("movement apply updates position", applied.position == AgentPosition(x: 1, y: 64, z: 0))
    check("movement apply increments count", applied.movementCount == 1)
    check("movement apply horizontal distance one", applied.totalManhattanDistanceMoved == 1)
    check("movement apply moved memory", applied.recentMemory.last?.type == "moved_live")
    check("movement apply stores outcome", applied.lastMovementOutcome == flat)
    check("movement snapshot exposes outcome", applySession.snapshot().agents[0].lastMovementOutcome?.status == .moved)
    check("movement old snapshot immutable", applyBefore.agents[0].position == origin && applyBefore.agents[0].lastMovementOutcome == nil)
    check("movement apply needs unchanged", applied.needs == applyBefore.agents[0].needs)
    check("movement apply fear unchanged", applied.fear == applyBefore.agents[0].fear)
    check("movement apply action counters unchanged", applied.actionCount == 3 && applied.actionEffectCount == 2)

    var verticalSession = movementSession([movementState(observation: movementObservation(step: 1))])
    try! verticalSession.applyMovementOutcomes([up])
    check("movement vertical still distance one", verticalSession.snapshot().agents[0].totalManhattanDistanceMoved == 1)

    var homeSession = movementSession([movementState(
        home: AgentPosition(x: 2, y: 64, z: 0),
        goal: .seekSafety,
        action: AgentAction(name: "move_abstract", reason: "goal seekSafety", tick: 0, dx: 1, dy: 0, dz: 0)
    )])
    try! homeSession.applyMovementOutcomes([towardHome])
    let homeApplied = homeSession.snapshot().agents[0]
    check("movement return home count", homeApplied.returnHomeMoveCount == 1)
    check("movement return home reduced total", homeApplied.totalDistanceReducedTowardHome == 1)
    check("movement explore no return home count", applied.returnHomeMoveCount == 0)

    var blockedSession = movementSession([movementState(observation: movementObservation(drop: true))])
    let blockedOutcome = resolved(movementState(observation: movementObservation(drop: true)))
    try! blockedSession.applyMovementOutcomes([blockedOutcome])
    let blockedApplied = blockedSession.snapshot().agents[0]
    check("movement blocked preserves position", blockedApplied.position == origin)
    check("movement blocked preserves count", blockedApplied.movementCount == 0)
    check("movement blocked memory", blockedApplied.recentMemory.last?.type == "movement_blocked")

    var idleSession = movementSession([movementState(action: nil)])
    try! idleSession.applyMovementOutcomes([noAction])
    check("movement not requested no memory", idleSession.snapshot().agents[0].memoryCount == 0)

    section("PS01 Increment 06 readiness-local cohort publication")
    let readinessState = movementState()
    let readinessIntent = resolved(readinessState)
    let readinessOutcome = AgentMovementOutcome(
        agentId: readinessIntent.agentId,
        tick: readinessIntent.tick,
        status: .readinessUnavailable,
        fromPosition: readinessIntent.fromPosition,
        toPosition: readinessIntent.fromPosition,
        requestedDirection: readinessIntent.requestedDirection,
        requestedDX: readinessIntent.requestedDX,
        requestedDY: readinessIntent.requestedDY,
        requestedDZ: readinessIntent.requestedDZ,
        appliedDX: 0,
        appliedDY: 0,
        appliedDZ: 0,
        goalKind: readinessIntent.goalKind,
        actionReason: readinessIntent.actionReason,
        resolutionReason: "PebbleCore bounded path readiness nodeBudgetExhausted",
        pathReadinessReason: .nodeBudgetExhausted,
        pathReadinessRequestIdentity: AgentMovementRequestIdentity(
            action: readinessState.lastAction!, goal: readinessState.currentGoal
        ),
        pathReadinessContextDigest:
            readinessState.lastWorldObservation!
                .physicalReadinessContextDigest,
        worldTickObserved: readinessIntent.worldTickObserved,
        distanceFromHomeBefore: readinessIntent.distanceFromHomeBefore,
        distanceFromHomeAfter: readinessIntent.distanceFromHomeBefore,
        distanceReducedTowardHome: 0
    )
    var readinessSession = movementSession([readinessState])
    let readinessBefore = readinessSession.snapshot().agents[0]
    try! readinessSession.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: readinessOutcome
        )
    ])
    let readinessAfter = readinessSession.snapshot().agents[0]
    check("increment 06 readiness outcome is durable and explicit",
          readinessAfter.lastMovementOutcome?.status == .readinessUnavailable
              && readinessAfter.lastMovementOutcome?.pathReadinessReason
                  == .nodeBudgetExhausted)
    check("increment 06 readiness outcome stays physically stationary",
          readinessAfter.position == readinessBefore.position
              && readinessAfter.movementCount == readinessBefore.movementCount)
    check("increment 06 readiness does not claim a physical block",
          readinessAfter.memoryCount == readinessBefore.memoryCount
              && readinessAfter.feedbackMemoryWriteCount
                  == readinessBefore.feedbackMemoryWriteCount)
    check("increment 06 checkpoint vocabulary is schema 45",
          (try! readinessSession.makeCheckpoint()).schemaVersion
              == AgentCheckpointSchema.pathReadinessLivenessVersion)

    let directDeferralOutcome = AgentMovementOutcome(
        agentId: "agent_3",
        tick: readinessOutcome.tick,
        status: readinessOutcome.status,
        fromPosition: readinessOutcome.fromPosition,
        toPosition: readinessOutcome.toPosition,
        requestedDirection: readinessOutcome.requestedDirection,
        requestedDX: readinessOutcome.requestedDX,
        requestedDY: readinessOutcome.requestedDY,
        requestedDZ: readinessOutcome.requestedDZ,
        appliedDX: readinessOutcome.appliedDX,
        appliedDY: readinessOutcome.appliedDY,
        appliedDZ: readinessOutcome.appliedDZ,
        goalKind: readinessOutcome.goalKind,
        actionReason: readinessOutcome.actionReason,
        resolutionReason: readinessOutcome.resolutionReason,
        pathReadinessReason: readinessOutcome.pathReadinessReason,
        pathReadinessRequestIdentity:
            readinessOutcome.pathReadinessRequestIdentity,
        pathReadinessContextDigest:
            readinessOutcome.pathReadinessContextDigest,
        worldTickObserved: readinessOutcome.worldTickObserved,
        distanceFromHomeBefore: readinessOutcome.distanceFromHomeBefore,
        distanceFromHomeAfter: readinessOutcome.distanceFromHomeAfter,
        distanceReducedTowardHome: readinessOutcome.distanceReducedTowardHome
    )
    var directDeferralSession = movementSession([movementState(
        id: "agent_3",
        needs: AgentNeeds(
            hunger: 0, fatigue: 0, curiosity: 0.8, safety: 0.9
        )
    )])
    try! directDeferralSession.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: directDeferralOutcome
        )
    ])
    _ = try! directDeferralSession.advanceTick()
    let firstDirectDeferral = directDeferralSession.snapshot().agents[0]
    check("increment 06 direct uncertainty enters durable passive deferral",
          firstDirectDeferral.lastAction?.name == "wait"
              && firstDirectDeferral.lastFeedbackDecisionTrace?.dominantFactor.kind
                  == .pathReadinessDeferral)
    let firstDeferredOutcomes = AgentMovementCoordinator.resolve(
        snapshot: directDeferralSession.snapshot()
    )
    try! directDeferralSession.applyMovementOutcomes(firstDeferredOutcomes)
    check("increment 06 passive deferral preserves typed uncertainty authority",
          directDeferralSession.snapshot().agents[0].lastMovementOutcome
              == directDeferralOutcome)
    _ = try! directDeferralSession.advanceTick()
    check("increment 06 exact direct request cannot retry after an intervening wait",
          directDeferralSession.snapshot().agents[0].lastAction?.name
              == "move_abstract"
              && directDeferralSession.snapshot().agents[0]
                  .lastFeedbackDecisionTrace?.baseDirection == .south
              && directDeferralSession.snapshot().agents[0]
                  .lastFeedbackDecisionTrace?.finalDirection == .south)

    let safetyObservationA = movementObservation(
        physicalCoverageDigest: "coverage-A"
    )
    let safetyObservationB = movementObservation(
        worldTick: 12, physicalCoverageDigest: "coverage-B"
    )
    let safetyState = movementState(
        id: "agent_safety",
        home: AgentPosition(x: 1, y: 64, z: 0),
        goal: .seekSafety,
        needs: AgentNeeds(
            hunger: 0, fatigue: 0, curiosity: 0, safety: 0.9
        ),
        health: 20,
        action: AgentAction(
            name: "move_abstract", reason: "goal seekSafety", tick: 0,
            dx: 1, dy: 0, dz: 0
        ),
        observation: safetyObservationA
    )
    let safetyIntent = resolved(safetyState)
    let safetyReadiness = AgentMovementOutcome(
        agentId: safetyIntent.agentId,
        tick: safetyIntent.tick,
        status: .readinessUnavailable,
        fromPosition: safetyIntent.fromPosition,
        toPosition: safetyIntent.fromPosition,
        requestedDirection: safetyIntent.requestedDirection,
        requestedDX: safetyIntent.requestedDX,
        requestedDY: safetyIntent.requestedDY,
        requestedDZ: safetyIntent.requestedDZ,
        appliedDX: 0,
        appliedDY: 0,
        appliedDZ: 0,
        goalKind: safetyIntent.goalKind,
        actionReason: safetyIntent.actionReason,
        resolutionReason:
            "PebbleCore bounded path readiness nodeBudgetExhausted",
        pathReadinessReason: .nodeBudgetExhausted,
        pathReadinessRequestIdentity: AgentMovementRequestIdentity(
            action: safetyState.lastAction!, goal: safetyState.currentGoal
        ),
        pathReadinessContextDigest:
            safetyObservationA.physicalReadinessContextDigest,
        worldTickObserved: safetyIntent.worldTickObserved,
        distanceFromHomeBefore: safetyIntent.distanceFromHomeBefore,
        distanceFromHomeAfter: safetyIntent.distanceFromHomeBefore,
        distanceReducedTowardHome: 0
    )
    var safetyDeferral = movementSession([safetyState])
    try! safetyDeferral.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep, outcome: safetyReadiness
        )
    ])
    _ = try! safetyDeferral.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_safety", worldObservation: safetyObservationA
        ),
    ])
    try! safetyDeferral.applyMovementOutcomes(
        AgentMovementCoordinator.resolve(snapshot: safetyDeferral.snapshot())
    )
    let safetyDeferredCheckpoint = try! safetyDeferral.makeCheckpoint()
    var safetyContinuous = safetyDeferral
    var safetyRestarted = try! AgentSimulationSession.restoring(
        safetyDeferredCheckpoint
    )
    for index in 0..<2 {
        _ = try! safetyContinuous.advanceTick(perceptions: [
            AgentPerceptionInput(
                agentId: "agent_safety", worldObservation: safetyObservationA
            ),
        ])
        _ = try! safetyRestarted.advanceTick(perceptions: [
            AgentPerceptionInput(
                agentId: "agent_safety", worldObservation: safetyObservationA
            ),
        ])
        check("increment 06 unchanged direct context remains deferred \(index)",
              safetyContinuous.snapshot().agents[0].lastAction?.name == "wait"
                  && safetyRestarted.snapshot().agents[0].lastAction?.name
                      == "wait")
        let continuousStationary = AgentMovementCoordinator.resolve(
            snapshot: safetyContinuous.snapshot()
        )
        let restartedStationary = AgentMovementCoordinator.resolve(
            snapshot: safetyRestarted.snapshot()
        )
        try! safetyContinuous.applyMovementOutcomes(continuousStationary)
        try! safetyRestarted.applyMovementOutcomes(restartedStationary)
    }
    check("increment 06 restart grants no unchanged direct retry",
          (try! safetyContinuous.durableStateBytes())
              == (try! safetyRestarted.durableStateBytes())
              && safetyContinuous.snapshot().agents[0]
                  .lastMovementOutcome == safetyReadiness)
    _ = try! safetyContinuous.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_safety", worldObservation: safetyObservationB
        ),
    ])
    _ = try! safetyRestarted.advanceTick(perceptions: [
        AgentPerceptionInput(
            agentId: "agent_safety", worldObservation: safetyObservationB
        ),
    ])
    let safetyContinuousAfterChange = safetyContinuous.snapshot().agents[0]
    let safetyRestartedAfterChange = safetyRestarted.snapshot().agents[0]
    check("increment 06 changed Core coverage context invalidates direct deferral",
          safetyContinuousAfterChange.lastAction?.name == "move_abstract"
              && safetyContinuousAfterChange.lastFeedbackDecisionTrace?
                  .dominantFactor.kind != .pathReadinessDeferral)
    check("increment 06 context invalidation is restart equivalent",
          safetyContinuousAfterChange.lastAction
              == safetyRestartedAfterChange.lastAction
              && (try! safetyContinuous.durableStateBytes())
                  == (try! safetyRestarted.durableStateBytes()))
    check("increment 06 invalidation only re-enables bounded Core request",
          AgentMovementCoordinator.resolve(
              snapshot: safetyContinuous.snapshot()
          )[0].status == .moved
              && safetyContinuousAfterChange.position
                  == safetyReadiness.fromPosition)

    func temporalV44Checkpoint(
        from checkpoint: AgentSessionCheckpoint
    ) -> AgentSessionCheckpoint {
        var root = try! JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        durable["schemaVersion"] = AgentCheckpointSchema.temporalPhysiologyVersion
        let durableData = try! JSONSerialization.data(
            withJSONObject: durable,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let durableState = try! AgentCheckpointCodec.decode(
            AgentSessionDurableState.self,
            from: durableData
        )
        let canonicalDurable = try! AgentCheckpointCodec.encode(durableState)
        let digest = AgentCheckpointDigest.sha256(canonicalDurable)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(checkpoint.simulationID.rawValue.utf8)
        )
        root["schemaVersion"] = AgentCheckpointSchema.temporalPhysiologyVersion
        root["durableState"] = try! JSONSerialization.jsonObject(
            with: canonicalDurable
        )
        root["semanticDigest"] = digest.rawValue
        root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(checkpoint.tick.rawValue)-\(digest.rawValue.prefix(16))"
        return try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: JSONSerialization.data(
                withJSONObject: root,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
    }

    let illicitReadinessV44 = temporalV44Checkpoint(
        from: try! directDeferralSession.makeCheckpoint()
    )
    do {
        _ = try AgentSimulationSession.restoring(illicitReadinessV44)
        check("increment 06 schema 44 rejects readiness-only vocabulary", false)
    } catch AgentCheckpointError.invalidAgent("agent_3") {
        check("increment 06 schema 44 rejects readiness-only vocabulary", true)
    } catch {
        check("increment 06 schema 44 rejects readiness-only vocabulary", false,
              "unexpected \(error)")
    }

    let preReadinessV45Session = movementSession([movementState()])
    let temporalV44 = temporalV44Checkpoint(
        from: try! preReadinessV45Session.makeCheckpoint()
    )
    var restoredTemporalV44 = try! AgentSimulationSession.restoring(temporalV44)
    check("increment 06 clean schema 44 checkpoint restores without relabeling",
          (try! restoredTemporalV44.makeCheckpoint()).schemaVersion
              == AgentCheckpointSchema.temporalPhysiologyVersion)
    var temporalV44Recorder = try! AgentReplayRecorder(
        checkpoint: temporalV44,
        session: restoredTemporalV44
    )
    try! temporalV44Recorder.apply(
        .verifiedPhysicalMovements([
            AgentVerifiedPhysicalMovement(
                kind: .navigationStep,
                outcome: readinessOutcome
            )
        ]),
        to: &restoredTemporalV44
    )
    let promotedJournal = try! temporalV44Recorder.journal(
        named: AgentCheckpointName(rawValue: "ps01-i06-v44-promotion")!
    )
    let promotedReplay = try! AgentSessionReplayer.replay(
        checkpoint: temporalV44,
        journal: promotedJournal
    )
    check("increment 06 first readiness publication promotes v44 to v45",
          (try! restoredTemporalV44.makeCheckpoint()).schemaVersion
              == AgentCheckpointSchema.pathReadinessLivenessVersion
              && promotedJournal.manifest.schemaVersion
                  == AgentReplaySchema.pathReadinessLivenessVersion)
    check("increment 06 v44 boundary promotion replay is byte exact",
          promotedReplay.report.verified
              && (try! promotedReplay.session.durableStateBytes())
                  == (try! restoredTemporalV44.durableStateBytes()))

    var unverifiedReadinessSession = movementSession([movementState()])
    let unverifiedReadinessBefore = unverifiedReadinessSession.snapshot()
    do {
        try unverifiedReadinessSession.applyMovementOutcomes([readinessOutcome])
        check("increment 06 unverified readiness publication refused", false)
    } catch AgentSessionError.invalidStationaryMovement("agent_a") {
        check("increment 06 unverified readiness publication refused", true)
    } catch {
        check("increment 06 unverified readiness publication refused", false,
              "unexpected \(error)")
    }
    check("increment 06 unverified readiness rejection is atomic",
          unverifiedReadinessSession.snapshot() == unverifiedReadinessBefore)

    let readinessRoute = AgentNavigationRoute(
        purpose: .resource,
        target: AgentPosition(x: 1, y: 64, z: 0),
        positions: [origin, AgentPosition(x: 1, y: 64, z: 0)],
        plannedAtTick: 0,
        visitedNodeCount: 2
    )
    var routedReadinessSession = movementSession([movementState(
        navigationProgress: AgentNavigationProgress(
            status: .active,
            route: readinessRoute,
            routeIndex: 0,
            lastPlanTick: 0
        )
    )])
    try! routedReadinessSession.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: readinessOutcome)
    ])
    let routedReadiness = routedReadinessSession.snapshot().agents[0]
        .navigationProgress
    check("increment 06 routed uncertainty preserves route and truth",
          routedReadiness.route == readinessRoute
              && routedReadiness.consecutiveBlockedMoves == 1
              && routedReadiness.lastInvalidation
                  == .physicalPathReadinessUnavailable
              && routedReadiness.lastFailure
                  == .physicalPathReadinessUnavailable)
    check("increment 06 routed retry authority remains finitely bounded",
          routedReadinessSession.configuration.navigationMaxReplans == 3)
    let routedReadinessCheckpoint = try! routedReadinessSession.makeCheckpoint()
    let routedReadinessRestored = try! AgentSimulationSession.restoring(
        AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: AgentCheckpointCodec.encode(routedReadinessCheckpoint)
        )
    )
    check("increment 06 native v45 restart preserves routed retry state",
          routedReadinessRestored.snapshot().agents[0].navigationProgress
              == routedReadiness
              && routedReadinessRestored.snapshot().agents[0]
                  .lastMovementOutcome == readinessOutcome
              && routedReadinessRestored.configuration.navigationMaxReplans == 3)

    let readinessB = AgentMovementOutcome(
        agentId: conflict[1].agentId,
        tick: conflict[1].tick,
        status: .readinessUnavailable,
        fromPosition: conflict[1].fromPosition,
        toPosition: conflict[1].fromPosition,
        requestedDirection: conflict[1].requestedDirection,
        requestedDX: conflict[1].requestedDX,
        requestedDY: conflict[1].requestedDY,
        requestedDZ: conflict[1].requestedDZ,
        appliedDX: 0,
        appliedDY: 0,
        appliedDZ: 0,
        goalKind: conflict[1].goalKind,
        actionReason: conflict[1].actionReason,
        resolutionReason: "PebbleCore bounded path readiness coverageLimited",
        pathReadinessReason: .coverageLimited,
        pathReadinessRequestIdentity: AgentMovementRequestIdentity(
            action: conflictStates[0].lastAction!,
            goal: conflictStates[0].currentGoal
        ),
        pathReadinessContextDigest: conflictStates[0]
            .lastWorldObservation!.physicalReadinessContextDigest,
        worldTickObserved: conflict[1].worldTickObserved,
        distanceFromHomeBefore: conflict[1].distanceFromHomeBefore,
        distanceFromHomeAfter: conflict[1].distanceFromHomeBefore,
        distanceReducedTowardHome: 0
    )
    var mixedCohort = movementSession(conflictStates)
    let mixedCheckpoint = try! mixedCohort.makeCheckpoint()
    var mixedRecorder = try! AgentReplayRecorder(
        checkpoint: mixedCheckpoint,
        session: mixedCohort
    )
    let mixedOperation = AgentReplayOperation.verifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: conflict[0]
        ),
        AgentVerifiedPhysicalMovement(
            kind: .navigationStep,
            outcome: readinessB
        ),
    ])
    _ = try! mixedRecorder.apply(mixedOperation, to: &mixedCohort)
    let mixedSnapshot = mixedCohort.snapshot()
    check("increment 06 ready peer moves in the same cohort",
          mixedSnapshot.agents.first { $0.id == "agent_a" }?.movementCount == 1)
    check("increment 06 indeterminate peer stays in the same cohort",
          mixedSnapshot.agents.first { $0.id == "agent_b" }?
              .lastMovementOutcome?.status == .readinessUnavailable)
    let mixedJournal = try! mixedRecorder.journal(
        named: AgentCheckpointName(rawValue: "ps01-i06-mixed-cohort")!
    )
    let mixedReplay = try! AgentSessionReplayer.replay(
        checkpoint: mixedCheckpoint,
        journal: mixedJournal
    )
    check("increment 06 mixed cohort replay is byte exact",
          mixedReplay.report.verified
              && (try! mixedReplay.session.durableStateBytes())
                  == (try! mixedCohort.durableStateBytes()))
    let mixedEncoded = try! AgentCheckpointCodec.encode(
        mixedCohort.makeCheckpoint()
    )
    let mixedDecoded = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: mixedEncoded
    )
    let mixedRestored = try! AgentSimulationSession.restoring(mixedDecoded)
    check("increment 06 mixed cohort checkpoint is byte exact",
          (try! mixedRestored.durableStateBytes())
              == (try! mixedCohort.durableStateBytes()))

    let forgedReadinessB = AgentMovementOutcome(
        agentId: readinessB.agentId,
        tick: readinessB.tick,
        status: readinessB.status,
        fromPosition: readinessB.fromPosition,
        toPosition: readinessB.toPosition,
        requestedDirection: readinessB.requestedDirection,
        requestedDX: readinessB.requestedDX,
        requestedDY: readinessB.requestedDY,
        requestedDZ: readinessB.requestedDZ,
        appliedDX: readinessB.appliedDX,
        appliedDY: readinessB.appliedDY,
        appliedDZ: readinessB.appliedDZ,
        goalKind: readinessB.goalKind,
        actionReason: "forged request",
        resolutionReason: readinessB.resolutionReason,
        pathReadinessReason: readinessB.pathReadinessReason,
        pathReadinessRequestIdentity:
            readinessB.pathReadinessRequestIdentity,
        pathReadinessContextDigest:
            readinessB.pathReadinessContextDigest,
        worldTickObserved: readinessB.worldTickObserved,
        distanceFromHomeBefore: readinessB.distanceFromHomeBefore,
        distanceFromHomeAfter: readinessB.distanceFromHomeAfter,
        distanceReducedTowardHome: readinessB.distanceReducedTowardHome
    )
    var forgedMixedCohort = movementSession(conflictStates)
    let forgedMixedBefore = forgedMixedCohort.snapshot()
    do {
        try forgedMixedCohort.applyVerifiedPhysicalMovements([
            AgentVerifiedPhysicalMovement(
                kind: .navigationStep,
                outcome: conflict[0]
            ),
            AgentVerifiedPhysicalMovement(
                kind: .navigationStep,
                outcome: forgedReadinessB
            ),
        ])
        check("increment 06 forged readiness request refused", false)
    } catch AgentSessionError.invalidStationaryMovement("agent_b") {
        check("increment 06 forged readiness request refused", true)
    } catch {
        check("increment 06 forged readiness request refused", false,
              "unexpected \(error)")
    }
    check("increment 06 invalid mixed cohort is wholly unpublished",
          forgedMixedCohort.snapshot() == forgedMixedBefore)

    var deterministicReadinessA = movementSession([movementState()])
    var deterministicReadinessB = movementSession([movementState()])
    try! deterministicReadinessA.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: readinessOutcome)
    ])
    try! deterministicReadinessB.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: readinessOutcome)
    ])
    check("increment 06 readiness publication is deterministic",
          (try! deterministicReadinessA.durableStateBytes())
              == (try! deterministicReadinessB.durableStateBytes()))

    var boundedMovement = movementSession([movementState()], policy: .bounded(maxEntries: 1))
    try! boundedMovement.applyMovementOutcomes([flat])
    check("movement bounded memory respected", boundedMovement.snapshot().agents[0].memoryCount == 1)

    var twoAgentSession = movementSession(conflictStates)
    let twoBefore = twoAgentSession.snapshot()
    do {
        try twoAgentSession.applyMovementOutcomes([conflict[0], conflict[0]])
        check("movement duplicate outcome refused", false)
    } catch AgentSessionError.duplicateMovementOutcome("agent_a") {
        check("movement duplicate outcome refused", true)
    } catch {
        check("movement duplicate outcome refused", false, "unexpected \(error)")
    }
    check("movement duplicate error tick unchanged", twoAgentSession.tick == 0)
    check("movement duplicate error state unchanged", twoAgentSession.snapshot() == twoBefore)

    let forcedConflictB = AgentMovementOutcome(
        agentId: "agent_b", tick: 0, status: .moved,
        fromPosition: AgentPosition(x: 1, y: 64, z: 0), toPosition: origin,
        requestedDirection: .west, requestedDX: -1, requestedDY: 0, requestedDZ: 0,
        appliedDX: -1, appliedDY: 0, appliedDZ: 0,
        goalKind: .explore, actionReason: "west", resolutionReason: "safe cardinal movement",
        worldTickObserved: 7, distanceFromHomeBefore: 0, distanceFromHomeAfter: 1,
        distanceReducedTowardHome: 0
    )
    do {
        try twoAgentSession.applyMovementOutcomes([conflict[0], forcedConflictB])
        check("movement duplicate destination refused", false)
    } catch AgentSessionError.duplicateMovementDestination {
        check("movement duplicate destination refused", true)
    } catch {
        check("movement duplicate destination refused", false, "unexpected \(error)")
    }

    let forcedOccupiedA = AgentMovementOutcome(
        agentId: "agent_a", tick: 0, status: .moved,
        fromPosition: origin, toPosition: AgentPosition(x: 1, y: 64, z: 0),
        requestedDirection: .east, requestedDX: 1, requestedDY: 0, requestedDZ: 0,
        appliedDX: 1, appliedDY: 0, appliedDZ: 0,
        goalKind: .explore, actionReason: "goal explore", resolutionReason: "safe cardinal movement",
        worldTickObserved: 7, distanceFromHomeBefore: 0, distanceFromHomeAfter: 1,
        distanceReducedTowardHome: 0
    )
    let stationaryB = AgentMovementCoordinator.resolve(snapshot: movementSession(occupiedStates).snapshot())[1]
    var occupiedApplySession = movementSession(occupiedStates)
    do {
        try occupiedApplySession.applyMovementOutcomes([forcedOccupiedA, stationaryB])
        check("movement occupied destination apply refused", false)
    } catch AgentSessionError.occupiedMovementDestination("agent_a") {
        check("movement occupied destination apply refused", true)
    } catch {
        check("movement occupied destination apply refused", false, "unexpected \(error)")
    }

    do {
        try twoAgentSession.applyMovementOutcomes([conflict[0]])
        check("movement missing outcome refused", false)
    } catch AgentSessionError.movementOutcomeCountMismatch(expected: 2, actual: 1) {
        check("movement missing outcome refused", true)
    } catch {
        check("movement missing outcome refused", false, "unexpected \(error)")
    }

    let unknown = AgentMovementOutcome(
        agentId: "unknown", tick: flat.tick, status: flat.status,
        fromPosition: flat.fromPosition, toPosition: flat.toPosition,
        requestedDirection: flat.requestedDirection,
        requestedDX: flat.requestedDX, requestedDY: flat.requestedDY, requestedDZ: flat.requestedDZ,
        appliedDX: flat.appliedDX, appliedDY: flat.appliedDY, appliedDZ: flat.appliedDZ,
        goalKind: flat.goalKind, actionReason: flat.actionReason, resolutionReason: flat.resolutionReason,
        worldTickObserved: flat.worldTickObserved,
        distanceFromHomeBefore: flat.distanceFromHomeBefore,
        distanceFromHomeAfter: flat.distanceFromHomeAfter,
        distanceReducedTowardHome: flat.distanceReducedTowardHome
    )
    var unknownSession = movementSession([movementState()])
    do {
        try unknownSession.applyMovementOutcomes([unknown])
        check("movement unknown agent refused", false)
    } catch AgentSessionError.unknownAgentId("unknown") {
        check("movement unknown agent refused", true)
    } catch {
        check("movement unknown agent refused", false, "unexpected \(error)")
    }

    func altered(
        _ source: AgentMovementOutcome,
        tick: Int? = nil,
        from: AgentPosition? = nil,
        to: AgentPosition? = nil,
        goal: AgentGoalKind? = nil,
        appliedDX: Int? = nil
    ) -> AgentMovementOutcome {
        AgentMovementOutcome(
            agentId: source.agentId,
            tick: tick ?? source.tick,
            status: source.status,
            fromPosition: from ?? source.fromPosition,
            toPosition: to ?? source.toPosition,
            requestedDirection: source.requestedDirection,
            requestedDX: source.requestedDX,
            requestedDY: source.requestedDY,
            requestedDZ: source.requestedDZ,
            appliedDX: appliedDX ?? source.appliedDX,
            appliedDY: source.appliedDY,
            appliedDZ: source.appliedDZ,
            goalKind: goal ?? source.goalKind,
            actionReason: source.actionReason,
            resolutionReason: source.resolutionReason,
            worldTickObserved: source.worldTickObserved,
            distanceFromHomeBefore: source.distanceFromHomeBefore,
            distanceFromHomeAfter: source.distanceFromHomeAfter,
            distanceReducedTowardHome: source.distanceReducedTowardHome
        )
    }

    func rejected(_ outcome: AgentMovementOutcome) -> Bool {
        var candidate = movementSession([movementState()])
        do {
            try candidate.applyMovementOutcomes([outcome])
            return false
        } catch {
            return candidate.snapshot() == movementSession([movementState()]).snapshot()
        }
    }
    check("movement tick mismatch refused", rejected(altered(flat, tick: 1)))
    check("movement from mismatch refused", rejected(altered(flat, from: AgentPosition(x: 9, y: 64, z: 0))))
    check("movement goal mismatch refused", rejected(altered(flat, goal: .rest)))
    check("movement delta mismatch refused", rejected(altered(flat, appliedDX: 0)))

    let occupiedInvalid = AgentMovementOutcome(
        agentId: "agent_a", tick: 0, status: .moved,
        fromPosition: AgentPosition(x: -1, y: 64, z: 0),
        toPosition: AgentPosition(x: 1, y: 64, z: 0),
        requestedDirection: .east, requestedDX: 1, requestedDY: 0, requestedDZ: 0,
        appliedDX: 2, appliedDY: 0, appliedDZ: 0,
        goalKind: .explore, actionReason: "east", resolutionReason: "invalid",
        worldTickObserved: 7, distanceFromHomeBefore: 0, distanceFromHomeAfter: 2,
        distanceReducedTowardHome: 0
    )
    check("movement multi cardinal apply refused", {
        var candidate = movementSession([conflictStates[1]])
        do { try candidate.applyMovementOutcomes([occupiedInvalid]); return false } catch { return true }
    }())

    section("CIV-19 verified physical movement publication")
    let coreSelectedPosition = AgentPosition(x: 0, y: 64, z: 1)
    let physicalOutcome = AgentMovementOutcome(
        agentId: flat.agentId, tick: flat.tick, status: .moved,
        fromPosition: flat.fromPosition, toPosition: coreSelectedPosition,
        requestedDirection: flat.requestedDirection,
        requestedDX: flat.requestedDX, requestedDY: flat.requestedDY,
        requestedDZ: flat.requestedDZ,
        appliedDX: 0, appliedDY: 0, appliedDZ: 1,
        goalKind: flat.goalKind, actionReason: flat.actionReason,
        resolutionReason: "PebbleCore path and Entity.move verified",
        worldTickObserved: 8,
        distanceFromHomeBefore: 0, distanceFromHomeAfter: 1,
        distanceReducedTowardHome: 0
    )
    var physicalPublication = movementSession([movementState()])
    try! physicalPublication.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: physicalOutcome)
    ])
    check("CIV-19 physical result may differ from coarse suggested cell",
          physicalPublication.snapshot().agents[0].position == coreSelectedPosition)

    let reconcileOutcome = AgentMovementOutcome(
        agentId: flat.agentId, tick: flat.tick, status: .moved,
        fromPosition: flat.fromPosition,
        toPosition: AgentPosition(x: 1, y: 64, z: 0),
        requestedDirection: nil, requestedDX: 0, requestedDY: 0, requestedDZ: 0,
        appliedDX: 1, appliedDY: 0, appliedDZ: 0,
        goalKind: flat.goalKind, actionReason: flat.actionReason,
        resolutionReason: "verified physical truth reconciliation",
        worldTickObserved: 8,
        distanceFromHomeBefore: 0, distanceFromHomeAfter: 1,
        distanceReducedTowardHome: 0
    )
    var reconciliation = movementSession([movementState()])
    try! reconciliation.applyVerifiedPhysicalMovements([
        AgentVerifiedPhysicalMovement(kind: .reconciliation, outcome: reconcileOutcome)
    ])
    check("CIV-19 physical truth reconciliation is explicit",
          reconciliation.snapshot().agents[0].position == reconcileOutcome.toPosition)
    check("CIV-19 reconciliation does not invent cognitive movement",
          reconciliation.snapshot().agents[0].movementCount == 0)

    var invalidPhysicalPublication = movementSession([movementState()])
    let invalidPhysicalBefore = invalidPhysicalPublication.snapshot()
    let invalidPhysical = AgentMovementOutcome(
        agentId: flat.agentId, tick: flat.tick, status: .moved,
        fromPosition: flat.fromPosition,
        toPosition: AgentPosition(x: 3, y: 64, z: 0),
        requestedDirection: flat.requestedDirection,
        requestedDX: flat.requestedDX, requestedDY: flat.requestedDY,
        requestedDZ: flat.requestedDZ,
        appliedDX: 3, appliedDY: 0, appliedDZ: 0,
        goalKind: flat.goalKind, actionReason: flat.actionReason,
        resolutionReason: "invalid unbounded result", worldTickObserved: 8,
        distanceFromHomeBefore: 0, distanceFromHomeAfter: 3,
        distanceReducedTowardHome: 0
    )
    check("CIV-19 invalid physical publication is atomic", {
        do {
            try invalidPhysicalPublication.applyVerifiedPhysicalMovements([
                AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: invalidPhysical)
            ])
            return false
        } catch {
            return invalidPhysicalPublication.snapshot() == invalidPhysicalBefore
        }
    }())

    var replayPhysical = movementSession([movementState()])
    let physicalCheckpoint = try! replayPhysical.makeCheckpoint()
    var physicalRecorder = try! AgentReplayRecorder(
        checkpoint: physicalCheckpoint, session: replayPhysical
    )
    _ = try! physicalRecorder.apply(
        AgentReplayOperation.verifiedPhysicalMovements([
            AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: physicalOutcome)
        ]),
        to: &replayPhysical
    )
    check("CIV-19 verified physical result is replayable",
          replayPhysical.snapshot().agents[0].position == coreSelectedPosition
              && physicalRecorder.records.last?.operationKind == .verifiedPhysicalMovements)

    let legacyMovementPath = movementSession([movementState()])
    let legacyMovementBefore = legacyMovementPath.snapshot()
    check("movement old path outcome nil", legacyMovementPath.snapshot().agents[0].lastMovementOutcome == nil)
    check("movement old path unchanged without apply", legacyMovementPath.snapshot() == legacyMovementBefore)
    let movementEncoder = JSONEncoder()
    movementEncoder.outputFormatting = [.sortedKeys]
    let legacyJSON = String(data: try! movementEncoder.encode(legacyMovementPath.snapshot()), encoding: .utf8)!
    check("movement old snapshot omits outcome JSON", !legacyJSON.contains("lastMovementOutcome"))
}

// ---------------------------------------------------------------------------
section("PebbleAgents closed feedback-memory-decision loop")
do {
    let feedbackConfig = AgentFeedbackLoopConfiguration.live
    let feedbackOrigin = AgentPosition(x: 0, y: 64, z: 0)

    func feedbackColumn(
        _ position: AgentPosition,
        ready: Bool = true,
        ground: Bool = true,
        feet: Bool = true,
        head: Bool = true
    ) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position,
            chunkReady: ready,
            surfaceY: ready ? position.y : nil,
            height: ready ? position.y : nil,
            blockBelow: ready ? (ground ? 1 : 0) : nil,
            blockAtFeet: ready ? (feet ? 0 : 1) : nil,
            blockAtHead: ready ? (head ? 0 : 1) : nil,
            groundPresent: ready && ground,
            feetClear: ready && feet,
            headClear: ready && head
        )
    }

    struct FeedbackNeighborRule {
        let ready: Bool
        let ground: Bool
        let feet: Bool
        let head: Bool
        let step: Int?
        let traversable: Bool
        let drop: Bool

        static let safe = FeedbackNeighborRule(
            ready: true, ground: true, feet: true, head: true,
            step: 0, traversable: true, drop: false
        )
    }

    func feedbackObservation(
        position: AgentPosition = feedbackOrigin,
        rules: [AgentCardinalDirection: FeedbackNeighborRule] = [:],
        tick: Int = 1,
        physicalCoverageDigest: String = "coverage-A"
    ) -> AgentWorldObservation {
        let neighbors = AgentCardinalDirection.allCases.map { direction in
            let rule = rules[direction] ?? .safe
            let neighborPosition = AgentPosition(
                x: position.x + direction.dx,
                y: position.y,
                z: position.z + direction.dz
            )
            return AgentWorldNeighborObservation(
                direction: direction,
                column: feedbackColumn(
                    neighborPosition,
                    ready: rule.ready,
                    ground: rule.ground,
                    feet: rule.feet,
                    head: rule.head
                ),
                stepDelta: rule.step,
                traversable: rule.traversable,
                dangerousDrop: rule.drop
            )
        }
        return try! AgentWorldObservation(
            worldTick: tick,
            position: position,
            center: feedbackColumn(position),
            neighbors: neighbors,
            biomeId: 1,
            biomeName: "plains",
            combinedLight: 15,
            skyLight: 15,
            blockLight: 0,
            dayTime: tick,
            raining: false,
            thundering: false,
            physicalCoverageDigest: physicalCoverageDigest
        )
    }

    func feedbackOutcome(
        id: String = "agent_0",
        tick: Int = 4,
        status: AgentMovementStatus,
        from: AgentPosition = feedbackOrigin,
        to: AgentPosition? = nil,
        direction: AgentCardinalDirection? = .east,
        reason: String = "target body space blocked",
        goal: AgentGoalKind = .explore,
        pathReadinessReason: AgentPathReadinessReason? = nil
    ) -> AgentMovementOutcome {
        let destination: AgentPosition
        if let to {
            destination = to
        } else if status == .moved, let direction {
            destination = AgentPosition(
                x: from.x + direction.dx,
                y: from.y,
                z: from.z + direction.dz
            )
        } else {
            destination = from
        }
        let before = abs(from.x) + abs(from.y - 64) + abs(from.z)
        let after = abs(destination.x) + abs(destination.y - 64) + abs(destination.z)
        let goalIdentity = AgentGoal(
            kind: goal, reason: "test", startedAtTick: 1, urgency: 1
        )
        let action = AgentAction(
            name: "move_abstract",
            reason: goal == .explore ? "goal explore" : "goal seekSafety",
            tick: 5,
            dx: direction?.dx,
            dy: direction == nil ? nil : 0,
            dz: direction?.dz
        )
        return AgentMovementOutcome(
            agentId: id,
            tick: tick,
            status: status,
            fromPosition: from,
            toPosition: destination,
            requestedDirection: direction,
            requestedDX: direction?.dx ?? 0,
            requestedDY: 0,
            requestedDZ: direction?.dz ?? 0,
            appliedDX: status == .moved ? (direction?.dx ?? 0) : 0,
            appliedDY: 0,
            appliedDZ: status == .moved ? (direction?.dz ?? 0) : 0,
            goalKind: goal,
            actionReason: goal == .explore ? "goal explore" : "goal seekSafety",
            resolutionReason: reason,
            pathReadinessReason: pathReadinessReason,
            pathReadinessRequestIdentity: status == .readinessUnavailable
                ? AgentMovementRequestIdentity(
                    action: action, goal: goalIdentity
                ) : nil,
            pathReadinessContextDigest: status == .readinessUnavailable
                ? feedbackObservation(position: from)
                    .physicalReadinessContextDigest : nil,
            worldTickObserved: tick,
            distanceFromHomeBefore: before,
            distanceFromHomeAfter: after,
            distanceReducedTowardHome: max(0, before - after)
        )
    }

    let notRequestedFeedback = feedbackOutcome(status: .notRequested, direction: nil)
    let movedFeedback = feedbackOutcome(status: .moved)
    let blockedFeedback = feedbackOutcome(status: .blocked)
    let readinessFeedback = feedbackOutcome(
        status: .readinessUnavailable,
        reason: "PebbleCore bounded path readiness nodeBudgetExhausted",
        pathReadinessReason: .nodeBudgetExhausted
    )
    let movedMemory = AgentFeedbackLoop.movementMemoryEntry(outcome: movedFeedback)
    let blockedMemory = AgentFeedbackLoop.movementMemoryEntry(outcome: blockedFeedback)
    check("feedback writer not requested nil",
          AgentFeedbackLoop.movementMemoryEntry(outcome: notRequestedFeedback) == nil)
    check("feedback writer moved type", movedMemory?.type == "moved_live")
    check("feedback writer blocked type", blockedMemory?.type == "movement_blocked")
    check("feedback writer moved summary",
          movedMemory?.summary == "agent_0 moved live from (0,64,0) to (1,64,0) toward east")
    check("feedback writer blocked summary",
          blockedMemory?.summary == "agent_0 movement blocked at (0,64,0) toward east: target body space blocked")
    check("feedback writer moved importance", movedMemory?.importance == 0.20)
    check("feedback writer blocked importance", blockedMemory?.importance == 0.25)
    let unknownDirection = AgentFeedbackLoop.movementMemoryEntry(
        outcome: feedbackOutcome(status: .blocked, direction: nil)
    )
    check("feedback writer unknown direction", unknownDirection?.summary.contains("toward unknown") == true)

    let priorBlocked = AgentMemoryEntry(
        tick: 2,
        type: blockedMemory!.type,
        summary: blockedMemory!.summary,
        importance: blockedMemory!.importance
    )
    check("feedback dedup exact blocked",
          AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: blockedMemory!, memory: [priorBlocked], currentTick: 4,
            configuration: feedbackConfig
          ))
    let otherPositionMemory = AgentFeedbackLoop.movementMemoryEntry(
        outcome: feedbackOutcome(status: .blocked, from: AgentPosition(x: 1, y: 64, z: 0))
    )!
    check("feedback dedup position discriminates",
          !AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: otherPositionMemory, memory: [priorBlocked], currentTick: 4,
            configuration: feedbackConfig
          ))
    let otherDirectionMemory = AgentFeedbackLoop.movementMemoryEntry(
        outcome: feedbackOutcome(status: .blocked, direction: .south)
    )!
    check("feedback dedup direction discriminates",
          !AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: otherDirectionMemory, memory: [priorBlocked], currentTick: 4,
            configuration: feedbackConfig
          ))
    let otherReasonMemory = AgentFeedbackLoop.movementMemoryEntry(
        outcome: feedbackOutcome(status: .blocked, reason: "dangerous drop")
    )!
    check("feedback dedup reason discriminates",
          !AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: otherReasonMemory, memory: [priorBlocked], currentTick: 4,
            configuration: feedbackConfig
          ))
    check("feedback dedup outside window accepted",
          !AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: blockedMemory!,
            memory: [AgentMemoryEntry(tick: -5, type: priorBlocked.type, summary: priorBlocked.summary, importance: 0.25)],
            currentTick: 4,
            configuration: feedbackConfig
          ))
    check("feedback moved never deduplicated",
          !AgentFeedbackLoop.isDuplicateBlockedMemory(
            candidate: movedMemory!, memory: [movedMemory!], currentTick: 5,
            configuration: feedbackConfig
          ))

    do {
        _ = try AgentFeedbackLoopConfiguration(maxRetrievedRecords: 0)
        check("feedback invalid retrieval max refused", false)
    } catch AgentFeedbackLoopConfigurationError.invalidMaxRetrievedRecords(0) {
        check("feedback invalid retrieval max refused", true)
    } catch {
        check("feedback invalid retrieval max refused", false)
    }
    do {
        _ = try AgentFeedbackLoopConfiguration(maxMemoryAgeTicks: 0)
        check("feedback invalid age refused", false)
    } catch AgentFeedbackLoopConfigurationError.invalidMaxMemoryAgeTicks(0) {
        check("feedback invalid age refused", true)
    } catch {
        check("feedback invalid age refused", false)
    }
    do {
        _ = try AgentFeedbackLoopConfiguration(duplicateWindowTicks: -1)
        check("feedback invalid dedup window refused", false)
    } catch AgentFeedbackLoopConfigurationError.invalidDuplicateWindowTicks(-1) {
        check("feedback invalid dedup window refused", true)
    } catch {
        check("feedback invalid dedup window refused", false)
    }
    do {
        _ = try AgentFeedbackLoopConfiguration(maxExploreDistanceFromHome: 0)
        check("feedback invalid explore bound refused", false)
    } catch AgentFeedbackLoopConfigurationError.invalidMaxExploreDistanceFromHome(0) {
        check("feedback invalid explore bound refused", true)
    } catch {
        check("feedback invalid explore bound refused", false)
    }
    check("feedback live defaults exact",
          feedbackConfig.maxRetrievedRecords == 3
              && feedbackConfig.maxMemoryAgeTicks == 16
              && feedbackConfig.duplicateWindowTicks == 8
              && feedbackConfig.maxExploreDistanceFromHome == 8)

    let retrievalSource = [
        AgentMemoryEntry(tick: 9, type: "other", summary: "excluded", importance: 1),
        AgentMemoryEntry(tick: 4, type: "movement_blocked", summary: "exact", importance: 0.25),
        AgentMemoryEntry(tick: 8, type: "moved_live", summary: "recent", importance: 0.20),
        AgentMemoryEntry(tick: 7, type: "movement_blocked", summary: "important", importance: 0.90),
        AgentMemoryEntry(tick: -20, type: "moved_live", summary: "old", importance: 1),
        AgentMemoryEntry(tick: 11, type: "moved_live", summary: "future", importance: 1),
    ]
    let retrievalBefore = retrievalSource.map(\.summary)
    let retrieved = AgentFeedbackLoop.retrieveMovementMemories(
        memory: retrievalSource,
        currentTick: 10,
        lastMovementOutcome: blockedFeedback,
        configuration: feedbackConfig
    )
    check("feedback retrieval excludes unrelated", !retrieved.contains { $0.type == "other" })
    check("feedback retrieval excludes old", !retrieved.contains { $0.summary == "old" })
    check("feedback retrieval excludes future", !retrieved.contains { $0.summary == "future" })
    check("feedback retrieval exact first", retrieved.first?.summary == "exact")
    check("feedback retrieval exact matched", retrieved.first?.matchedCurrentFeedback == true)
    check("feedback retrieval exact age", retrieved.first?.ageTicks == 6)
    check("feedback retrieval limit", retrieved.count == 3)
    check("feedback retrieval source immutable", retrievalSource.map(\.summary) == retrievalBefore)
    check("feedback retrieval deterministic",
          retrieved == AgentFeedbackLoop.retrieveMovementMemories(
            memory: retrievalSource, currentTick: 10,
            lastMovementOutcome: blockedFeedback, configuration: feedbackConfig
          ))
    check("feedback retrieval importance after exact", retrieved.dropFirst().first?.summary == "important")

    let tieMemories = [
        AgentMemoryEntry(tick: 5, type: "moved_live", summary: "z", importance: 0.5),
        AgentMemoryEntry(tick: 5, type: "movement_blocked", summary: "z", importance: 0.5),
        AgentMemoryEntry(tick: 5, type: "movement_blocked", summary: "a", importance: 0.5),
        AgentMemoryEntry(tick: 6, type: "moved_live", summary: "newer", importance: 0.5),
    ]
    let tied = AgentFeedbackLoop.retrieveMovementMemories(
        memory: tieMemories,
        currentTick: 8,
        lastMovementOutcome: nil,
        configuration: feedbackConfig
    )
    check("feedback retrieval tick descending", tied[0].summary == "newer")
    check("feedback retrieval type tie break", tied[1].type == "moved_live")
    let tieConfig = try! AgentFeedbackLoopConfiguration(maxRetrievedRecords: 4)
    let allTied = AgentFeedbackLoop.retrieveMovementMemories(
        memory: tieMemories,
        currentTick: 8,
        lastMovementOutcome: nil,
        configuration: tieConfig
    )
    check("feedback retrieval summary tie break",
          allTied[2].summary == "a" && allTied[3].summary == "z")
    check("feedback retrieval unmatched exact false", tied.allSatisfy { !$0.matchedCurrentFeedback })

    func feedbackTrace(
        position: AgentPosition = feedbackOrigin,
        home: AgentPosition = feedbackOrigin,
        goal: AgentGoalKind = .explore,
        baseDirection: AgentCardinalDirection = .east,
        observation: AgentWorldObservation? = feedbackObservation(),
        occupied: [AgentPosition] = [],
        outcome: AgentMovementOutcome? = nil,
        memories: [AgentRetrievedMemory] = []
    ) -> AgentFeedbackDecisionTrace {
        AgentFeedbackLoop.adjustAction(
            agentId: "agent_0",
            tick: 5,
            position: position,
            homePosition: home,
            goal: AgentGoal(kind: goal, reason: "test", startedAtTick: 1, urgency: 1),
            baseAction: AgentAction(
                name: "move_abstract", reason: "goal \(goal.rawValue)", tick: 5,
                dx: baseDirection.dx, dy: 0, dz: baseDirection.dz
            ),
            worldObservation: observation,
            occupiedPositions: occupied,
            lastMovementOutcome: outcome,
            retrievedMemories: memories,
            configuration: feedbackConfig
        )
    }

    let baseTrace = feedbackTrace()
    check("feedback adjust no memory base retained", !baseTrace.actionChanged)
    check("feedback adjust no memory reason", baseTrace.reason == "base policy retained")
    check("feedback adjust base factor", baseTrace.decisionFactors == [
        AgentDecisionFactor(kind: .basePolicy, weight: 10, summary: "base policy action")
    ])
    check("feedback adjust base dominant", baseTrace.dominantFactor.kind == .basePolicy)
    let outcomeOnlyTrace = feedbackTrace(outcome: blockedFeedback)
    check("feedback adjust outcome without memory retained", !outcomeOnlyTrace.actionChanged)

    let readinessRetrieved = AgentFeedbackLoop.retrieveMovementMemories(
        memory: retrievalSource,
        currentTick: 10,
        lastMovementOutcome: readinessFeedback,
        configuration: feedbackConfig
    )
    check("increment 06 readiness matches no blocked or moved memory",
          readinessRetrieved.allSatisfy { !$0.matchedCurrentFeedback })
    let readinessTrace = feedbackTrace(
        outcome: readinessFeedback,
        memories: readinessRetrieved
    )
    check("increment 06 identical uncertain request deterministically defers",
          readinessTrace.actionChanged
              && readinessTrace.finalAction.name == "wait"
              && readinessTrace.finalDirection == nil
              && readinessTrace.finalAction.reason
                  == "bounded direct physical path readiness deferred until intent changes")
    check("increment 06 deferral is technical rather than blocked feedback",
          readinessTrace.decisionFactors.contains {
              $0.kind == .pathReadinessDeferral && $0.weight == 110
          }
              && !readinessTrace.decisionFactors.contains {
                  $0.kind == .movementFeedback
              }
              && readinessTrace.memoryRecordsUsed.isEmpty)
    check("increment 06 deferral is deterministic",
          readinessTrace == feedbackTrace(
            outcome: readinessFeedback,
            memories: readinessRetrieved
          ))
    let changedReadinessIntent = feedbackTrace(
        baseDirection: .south,
        outcome: readinessFeedback
    )
    check("increment 06 reconsidered different intent remains eligible",
          !changedReadinessIntent.actionChanged
              && changedReadinessIntent.finalDirection == .south)
    check("increment 06 readiness classifications remain exhaustive and distinct",
          Set(AgentPathReadinessReason.allCases.map(\.rawValue)).count == 3)

    let exactBlockedRecord = AgentRetrievedMemory(
        tick: 4, type: "movement_blocked", summary: blockedMemory!.summary,
        importance: 0.25, ageTicks: 1, matchedCurrentFeedback: true
    )
    let blockedTrace = feedbackTrace(outcome: blockedFeedback, memories: [exactBlockedRecord])
    check("feedback blocked explore alternate south", blockedTrace.finalDirection == .south)
    check("feedback blocked excludes east", blockedTrace.finalDirection != .east)
    check("feedback blocked reason exact",
          blockedTrace.reason == "feedback memory avoided east; alternate south")
    check("feedback blocked action changed", blockedTrace.actionChanged)
    check("feedback blocked record used", blockedTrace.memoryRecordsUsed == [exactBlockedRecord])
    check("feedback blocked movement factor",
          blockedTrace.decisionFactors.contains { $0.kind == .movementFeedback && $0.weight == 100 })
    check("feedback blocked dominant", blockedTrace.dominantFactor.kind == .movementFeedback)

    let southOccupied = AgentPosition(x: 0, y: 64, z: 1)
    let occupiedTrace = feedbackTrace(
        occupied: [southOccupied],
        outcome: blockedFeedback,
        memories: [exactBlockedRecord]
    )
    check("feedback alternate occupied excluded", occupiedTrace.finalDirection == .west)
    let dropRule = FeedbackNeighborRule(
        ready: true, ground: false, feet: true, head: true,
        step: -2, traversable: false, drop: true
    )
    let dropTrace = feedbackTrace(
        observation: feedbackObservation(rules: [.south: dropRule]),
        outcome: blockedFeedback,
        memories: [exactBlockedRecord]
    )
    check("feedback alternate drop excluded", dropTrace.finalDirection == .west)
    let unavailableRule = FeedbackNeighborRule(
        ready: false, ground: false, feet: false, head: false,
        step: nil, traversable: false, drop: false
    )
    let unavailableTrace = feedbackTrace(
        observation: feedbackObservation(rules: [.south: unavailableRule]),
        outcome: blockedFeedback,
        memories: [exactBlockedRecord]
    )
    check("feedback alternate chunk excluded", unavailableTrace.finalDirection == .west)
    let invalidStepRule = FeedbackNeighborRule(
        ready: true, ground: true, feet: true, head: true,
        step: 2, traversable: true, drop: false
    )
    let invalidStepTrace = feedbackTrace(
        observation: feedbackObservation(rules: [.south: invalidStepRule]),
        outcome: blockedFeedback,
        memories: [exactBlockedRecord]
    )
    check("feedback alternate invalid step excluded", invalidStepTrace.finalDirection == .west)
    let noSafeRules = Dictionary(
        uniqueKeysWithValues: AgentCardinalDirection.allCases.map { ($0, unavailableRule) }
    )
    let noAlternateTrace = feedbackTrace(
        observation: feedbackObservation(rules: noSafeRules),
        outcome: blockedFeedback,
        memories: [exactBlockedRecord]
    )
    check("feedback blocked no alternate waits", noAlternateTrace.finalAction.name == "wait")
    check("feedback blocked no alternate reason",
          noAlternateTrace.reason == "feedback memory blocked east; no safe alternate")

    let safetyPosition = AgentPosition(x: 2, y: 64, z: 2)
    let safetyOutcome = feedbackOutcome(
        tick: 4, status: .blocked, from: safetyPosition, direction: .east,
        goal: .seekSafety
    )
    let safetyRecord = AgentRetrievedMemory(
        tick: 4, type: "movement_blocked", summary: "safety",
        importance: 0.25, ageTicks: 1, matchedCurrentFeedback: true
    )
    let safetyTrace = feedbackTrace(
        position: safetyPosition,
        home: feedbackOrigin,
        goal: .seekSafety,
        observation: feedbackObservation(position: safetyPosition),
        outcome: safetyOutcome,
        memories: [safetyRecord]
    )
    check("feedback safety reduces home", safetyTrace.finalDirection == .north)
    check("feedback safety tie canonical", safetyTrace.finalDirection == .north)
    let noReductionTrace = feedbackTrace(
        position: safetyPosition,
        home: feedbackOrigin,
        goal: .seekSafety,
        observation: feedbackObservation(position: safetyPosition, rules: [
            .north: unavailableRule, .west: unavailableRule,
        ]),
        outcome: safetyOutcome,
        memories: [safetyRecord]
    )
    check("feedback safety no reduction waits", noReductionTrace.finalAction.name == "wait")
    check("feedback safety no reduction reason",
          noReductionTrace.reason == "feedback memory found no safer home step")

    let movedRecord = AgentRetrievedMemory(
        tick: 4, type: "moved_live", summary: movedMemory!.summary,
        importance: 0.20, ageTicks: 1, matchedCurrentFeedback: true
    )
    let movedCurrent = movedFeedback.toPosition
    let continued = feedbackTrace(
        position: movedCurrent,
        home: feedbackOrigin,
        baseDirection: .south,
        observation: feedbackObservation(position: movedCurrent),
        outcome: movedFeedback,
        memories: [movedRecord]
    )
    check("feedback moved success continues", continued.finalDirection == .east)
    check("feedback moved success modifies base", continued.actionChanged)
    check("feedback moved success reason",
          continued.reason == "movement success memory continued east")
    let continuationOccupied = feedbackTrace(
        position: movedCurrent,
        home: feedbackOrigin,
        baseDirection: .south,
        observation: feedbackObservation(position: movedCurrent),
        occupied: [AgentPosition(x: 2, y: 64, z: 0)],
        outcome: movedFeedback,
        memories: [movedRecord]
    )
    check("feedback continuation occupied refused", continuationOccupied.finalDirection == .south)
    let continuationDrop = feedbackTrace(
        position: movedCurrent,
        home: feedbackOrigin,
        baseDirection: .south,
        observation: feedbackObservation(position: movedCurrent, rules: [.east: dropRule]),
        outcome: movedFeedback,
        memories: [movedRecord]
    )
    check("feedback continuation dangerous refused", continuationDrop.finalDirection == .south)

    let boundaryPosition = AgentPosition(x: 8, y: 64, z: 0)
    let boundaryTrace = feedbackTrace(
        position: boundaryPosition,
        home: feedbackOrigin,
        baseDirection: .east,
        observation: feedbackObservation(position: boundaryPosition),
        outcome: movedFeedback
    )
    check("feedback boundary redirects home", boundaryTrace.finalDirection == .west)
    check("feedback boundary factor", boundaryTrace.dominantFactor.kind == .explorationBoundary)
    check("feedback boundary reason",
          boundaryTrace.reason == "exploration boundary redirected toward home")
    check("feedback boundary not memory influenced", boundaryTrace.memoryRecordsUsed.isEmpty)
    let boundaryWait = feedbackTrace(
        position: boundaryPosition,
        home: feedbackOrigin,
        observation: feedbackObservation(position: boundaryPosition, rules: [.west: unavailableRule]),
        outcome: movedFeedback
    )
    check("feedback boundary no return waits", boundaryWait.finalAction.name == "wait")

    func feedbackState(
        id: String = "agent_0",
        position: AgentPosition = feedbackOrigin,
        home: AgentPosition = feedbackOrigin,
        observation: AgentWorldObservation? = nil
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: position,
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.9, safety: 1),
            health: 100,
            fear: 0,
            homePosition: home,
            nearbyAgents: [],
            currentGoal: AgentGoal(kind: .explore, reason: "initial", startedAtTick: 0, urgency: 60),
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
            lastWorldObservation: observation
        )
    }

    func feedbackSession(
        states: [AgentSessionAgentState],
        memoryLimit: Int = 64
    ) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 42,
                recentMemorySnapshotLimit: 16,
                memoryPolicy: .bounded(maxEntries: memoryLimit)
            ),
            agents: states
        )
    }

    let southBlockedObservation = feedbackObservation(rules: [
        .south: unavailableRule,
        .west: unavailableRule,
    ])
    var closedSession = feedbackSession(states: [feedbackState()])
    let firstTick = try! closedSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: southBlockedObservation),
    ])
    let firstOutcomes = AgentMovementCoordinator.resolve(snapshot: closedSession.snapshot())
    check("feedback session first action south", firstTick.agents[0].action.dz == 1)
    check("feedback session first outcome blocked", firstOutcomes[0].status == .blocked)
    try! closedSession.applyMovementOutcomes(firstOutcomes)
    let afterBlocked = closedSession.snapshot().agents[0]
    check("feedback session writes real blocked memory",
          afterBlocked.recentMemory.contains { $0.type == "movement_blocked" })
    check("feedback session write counter", afterBlocked.feedbackMemoryWriteCount == 1)
    let oldFeedbackSnapshot = closedSession.snapshot()
    let secondTick = try! closedSession.advanceTick(perceptions: [
        AgentPerceptionInput(agentId: "agent_0", worldObservation: southBlockedObservation),
    ])
    let afterInfluence = closedSession.snapshot().agents[0]
    check("feedback session retrieves next tick", afterInfluence.memoryRetrievalCount == 1)
    check("feedback session influences next tick", afterInfluence.memoryInfluencedDecisionCount == 1)
    check("feedback session final action modified", secondTick.agents[0].action.dz == -1)
    check("feedback session last action final", afterInfluence.lastAction?.dz == -1)
    check("feedback session action chosen final",
          afterInfluence.recentMemory.contains {
              $0.type == "action_chosen" && $0.summary.contains("feedback memory avoided south; alternate north")
          })
    check("feedback session effect final",
          secondTick.agents[0].actionEffect.action == "move_abstract")
    check("feedback session action count once", afterInfluence.actionCount == 2)
    check("feedback session trace exposed", afterInfluence.lastFeedbackDecisionTrace?.actionChanged == true)
    check("feedback session old snapshot immutable",
          oldFeedbackSnapshot.agents[0].memoryRetrievalCount == 0
              && oldFeedbackSnapshot.agents[0].lastFeedbackDecisionTrace?.tick == 1)
    let secondOutcomes = AgentMovementCoordinator.resolve(snapshot: closedSession.snapshot())
    check("feedback session alternate movement succeeds", secondOutcomes[0].status == .moved)
    try! closedSession.applyMovementOutcomes(secondOutcomes)
    check("feedback session bounded memory", closedSession.snapshot().agents[0].memoryCount <= 64)

    var legacyFeedbackSession = feedbackSession(states: [feedbackState()])
    _ = try! legacyFeedbackSession.advanceTick()
    let legacyFeedbackSnapshot = legacyFeedbackSession.snapshot().agents[0]
    check("feedback session no outcome retrieval zero", legacyFeedbackSnapshot.memoryRetrievalCount == 0)
    check("feedback session no outcome influence zero", legacyFeedbackSnapshot.memoryInfluencedDecisionCount == 0)
    check("feedback session no outcome base trace",
          legacyFeedbackSnapshot.lastFeedbackDecisionTrace?.reason == "base policy retained")
    let feedbackEncoder = JSONEncoder()
    feedbackEncoder.outputFormatting = [.sortedKeys]
    let legacyFeedbackJSON = String(
        data: try! feedbackEncoder.encode(legacyFeedbackSession.snapshot()),
        encoding: .utf8
    )!
    check("feedback session historical JSON omits trace",
          !legacyFeedbackJSON.contains("lastFeedbackDecisionTrace")
              && !legacyFeedbackJSON.contains("memoryRetrievalCount"))

    struct SyntheticFeedbackRun {
        let snapshot: AgentSessionSnapshot
        let influenced: [String]
        let positions: [String]
        let actions: [String]
        let outcomes: [String]
        let memoryCounters: [String]
        let goalKinds: Set<String>
        let blockedOutcomes: Int
        let alternateMoves: Int
        let dangerousMoves: Int
        let movedAgents: Int
        let maximumDistance: Int
        let maximumMemory: Int
        let deduplicated: Int
    }

    func syntheticObservation(position: AgentPosition, tick: Int) -> AgentWorldObservation {
        var rules: [AgentCardinalDirection: FeedbackNeighborRule] = [
            .north: unavailableRule,
            .south: dropRule,
        ]
        if position.x >= 1 { rules[.east] = unavailableRule }
        if position.x <= -1 { rules[.west] = unavailableRule }
        return feedbackObservation(position: position, rules: rules, tick: tick)
    }

    func runSyntheticFeedback(
        ticks: Int = 240,
        memoryLimit: Int = 64,
        checkUniquePositions: Bool = true
    ) -> SyntheticFeedbackRun {
        var session = feedbackSession(states: [
            feedbackState(id: "agent_0", position: AgentPosition(x: -1, y: 64, z: 0), home: AgentPosition(x: -1, y: 64, z: 0)),
            feedbackState(id: "agent_1", position: AgentPosition(x: 0, y: 64, z: -1), home: AgentPosition(x: 0, y: 64, z: -1)),
            feedbackState(id: "agent_2", position: AgentPosition(x: 1, y: 64, z: 0), home: AgentPosition(x: 1, y: 64, z: 0)),
        ], memoryLimit: memoryLimit)
        var influenced: [String] = []
        var positions: [String] = []
        var actions: [String] = []
        var outcomeTimeline: [String] = []
        var memoryCounters: [String] = []
        var goalKinds = Set<String>()
        var maximumDistance = 0
        var maximumMemory = 0
        var blockedOutcomes = 0
        var alternateMoves = 0
        var dangerousMoves = 0
        for tick in 1...ticks {
            let before = session.snapshot()
            let perceptions = before.agents.map {
                AgentPerceptionInput(
                    agentId: $0.id,
                    worldObservation: syntheticObservation(position: $0.position, tick: tick)
                )
            }
            _ = try! session.advanceTick(perceptions: perceptions)
            let cognitive = session.snapshot()
            goalKinds.formUnion(cognitive.agents.map { $0.currentGoal.kind.rawValue })
            actions.append(cognitive.agents.map {
                let trace = $0.lastFeedbackDecisionTrace
                return "\($0.id):\(trace?.finalAction.name ?? "none"):\(trace?.finalDirection?.rawValue ?? "none"):\(trace?.actionChanged == true ? 1 : 0)"
            }.joined(separator: ";"))
            for agent in cognitive.agents where agent.lastFeedbackDecisionTrace?.actionChanged == true {
                influenced.append("\(tick):\(agent.id):\(agent.lastFeedbackDecisionTrace?.reason ?? "")")
            }
            let outcomes = AgentMovementCoordinator.resolve(snapshot: cognitive)
            outcomeTimeline.append(outcomes.map {
                "\($0.agentId):\($0.status.rawValue):\($0.requestedDirection?.rawValue ?? "none"):\($0.toPosition.x),\($0.toPosition.y),\($0.toPosition.z)"
            }.joined(separator: ";"))
            blockedOutcomes += outcomes.filter { $0.status == .blocked }.count
            dangerousMoves += outcomes.filter {
                $0.status == .moved && $0.requestedDirection == .south
            }.count
            alternateMoves += outcomes.filter { outcome in
                guard outcome.status == .moved,
                      let agent = cognitive.agents.first(where: { $0.id == outcome.agentId }),
                      let trace = agent.lastFeedbackDecisionTrace else { return false }
                return trace.actionChanged && !trace.memoryRecordsUsed.isEmpty
            }.count
            try! session.applyMovementOutcomes(outcomes)
            let final = session.snapshot()
            positions.append(final.agents.map {
                "\($0.id)=\($0.position.x),\($0.position.y),\($0.position.z)"
            }.joined(separator: ";"))
            maximumDistance = max(maximumDistance, final.agents.map(\.distanceFromHome).max() ?? 0)
            maximumMemory = max(maximumMemory, final.agents.map(\.memoryCount).max() ?? 0)
            memoryCounters.append(final.agents.map {
                "\($0.id):\($0.memoryCount):\($0.memoryRetrievalCount):\($0.memoryInfluencedDecisionCount):\($0.feedbackMemoryDeduplicatedCount)"
            }.joined(separator: ";"))
            if checkUniquePositions {
                check("feedback synthetic unique positions tick \(tick)",
                      Set(final.agents.map { "\($0.position.x),\($0.position.y),\($0.position.z)" }).count == 3)
            }
        }
        let final = session.snapshot()
        return SyntheticFeedbackRun(
            snapshot: final,
            influenced: influenced,
            positions: positions,
            actions: actions,
            outcomes: outcomeTimeline,
            memoryCounters: memoryCounters,
            goalKinds: goalKinds,
            blockedOutcomes: blockedOutcomes,
            alternateMoves: alternateMoves,
            dangerousMoves: dangerousMoves,
            movedAgents: final.agents.filter { $0.movementCount > 0 }.count,
            maximumDistance: maximumDistance,
            maximumMemory: maximumMemory,
            deduplicated: final.agents.reduce(0) { $0 + $1.feedbackMemoryDeduplicatedCount }
        )
    }

    let synthetic1 = runSyntheticFeedback()
    let synthetic2 = runSyntheticFeedback()
    check("feedback synthetic reaches 240 ticks", synthetic1.snapshot.tick == 240)
    check("feedback synthetic writes movement feedback",
          synthetic1.snapshot.agents.reduce(0) { $0 + $1.feedbackMemoryWriteCount } > 0)
    check("feedback synthetic records blocked outcomes", synthetic1.blockedOutcomes > 0)
    check("feedback synthetic retrieves memory",
          synthetic1.snapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount } > 0)
    check("feedback synthetic influences decisions", !synthetic1.influenced.isEmpty)
    check("feedback synthetic alternate succeeds", synthetic1.alternateMoves > 0)
    check("feedback synthetic executes no dangerous move", synthetic1.dangerousMoves == 0)
    check("feedback synthetic moves two agents", synthetic1.movedAgents >= 2)
    check("feedback synthetic distance bounded", synthetic1.maximumDistance <= 8)
    check("feedback synthetic memory bounded", synthetic1.maximumMemory <= 64)
    check("feedback synthetic deduplicates", synthetic1.deduplicated > 0)
    check("feedback synthetic deterministic snapshot", synthetic1.snapshot == synthetic2.snapshot)
    check("feedback synthetic deterministic influences", synthetic1.influenced == synthetic2.influenced)
    check("feedback synthetic deterministic positions", synthetic1.positions == synthetic2.positions)

    section("PebbleAgents stabilized prototype endurance")
    let endurance1 = runSyntheticFeedback(ticks: 1200, memoryLimit: 128, checkUniquePositions: false)
    let endurance2 = runSyntheticFeedback(ticks: 1200, memoryLimit: 128, checkUniquePositions: false)
    let enduranceRetrieved = endurance1.snapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount }
    let enduranceInfluenced = endurance1.snapshot.agents.reduce(0) { $0 + $1.memoryInfluencedDecisionCount }
    let enduranceWrites = endurance1.snapshot.agents.reduce(0) { $0 + $1.feedbackMemoryWriteCount }
    check("endurance reaches 1200 ticks", endurance1.snapshot.tick == 1200)
    check("endurance three agents", endurance1.snapshot.agentCount == 3)
    check("endurance memory bounded 128", endurance1.maximumMemory <= 128)
    check("endurance distance bounded 8", endurance1.maximumDistance <= 8)
    check("endurance no dangerous drop", endurance1.dangerousMoves == 0)
    check("endurance all positions unique", endurance1.positions.allSatisfy {
        Set($0.components(separatedBy: ";")).count == 3
    })
    check("endurance retrieves memory", enduranceRetrieved > 0)
    check("endurance influences decisions", enduranceInfluenced > 0)
    check("endurance deduplicates feedback", endurance1.deduplicated > 0)
    check("endurance writes feedback", enduranceWrites > 0)
    check("endurance records blocked outcomes", endurance1.blockedOutcomes > 0)
    check("endurance executes influenced alternate", endurance1.alternateMoves > 0)
    check("endurance moves multiple agents", endurance1.movedAgents >= 2)
    check("endurance observes multiple goals", endurance1.goalKinds.count >= 2)
    check("endurance position timeline complete", endurance1.positions.count == 1200)
    check("endurance action timeline complete", endurance1.actions.count == 1200)
    check("endurance outcome timeline complete", endurance1.outcomes.count == 1200)
    check("endurance memory timeline complete", endurance1.memoryCounters.count == 1200)
    check("endurance deterministic snapshot", endurance1.snapshot == endurance2.snapshot)
    check("endurance deterministic positions", endurance1.positions == endurance2.positions)
    check("endurance deterministic actions", endurance1.actions == endurance2.actions)
    check("endurance deterministic outcomes", endurance1.outcomes == endurance2.outcomes)
    check("endurance deterministic memory counters", endurance1.memoryCounters == endurance2.memoryCounters)
    check("endurance deterministic influences", endurance1.influenced == endurance2.influenced)
    check("endurance deterministic goals", endurance1.goalKinds == endurance2.goalKinds)
    for checkpoint in stride(from: 59, to: 1200, by: 60) {
        check("endurance checkpoint \(checkpoint + 1) deterministic",
              endurance1.positions[checkpoint] == endurance2.positions[checkpoint])
        check("endurance checkpoint \(checkpoint + 1) unique",
              Set(endurance1.positions[checkpoint].components(separatedBy: ";")).count == 3)
    }

    section("PebbleAgents transactional interaction G1")
    var inventory = AgentResourceInventory(capacity: 3)
    check("G1 inventory initially empty", inventory.isEmpty && inventory.totalCount == 0)
    check("G1 inventory accepts one", inventory.add(.sandboxResource))
    check("G1 inventory count exact", inventory.count(of: .sandboxResource) == 1)
    check("G1 inventory reaches exact capacity", inventory.add(.sandboxResource, quantity: 2) && inventory.totalCount == 3)
    let fullBefore = inventory
    check("G1 inventory overflow rejected", !inventory.add(.sandboxResource))
    check("G1 inventory overflow no partial mutation", inventory == fullBefore)
    let inventoryEncoder = JSONEncoder()
    inventoryEncoder.outputFormatting = [.sortedKeys]
    let inventoryJSON1 = try! inventoryEncoder.encode(inventory)
    let inventoryJSON2 = try! inventoryEncoder.encode(inventory)
    check("G1 inventory deterministic encoding", inventoryJSON1 == inventoryJSON2)
    let sandboxAnchor = AgentPosition(x: 0, y: 64, z: 0)
    check("G1 sandbox boundary included",
          AgentInteractionSandbox.contains(
              target: AgentPosition(x: 8, y: 80, z: -8),
              anchor: sandboxAnchor,
              horizontalRadius: 8
          ))
    check("G1 outside sandbox rejected",
          !AgentInteractionSandbox.contains(
              target: AgentPosition(x: 9, y: 64, z: 0),
              anchor: sandboxAnchor,
              horizontalRadius: 8
          ))
    check("G1 adjacent cardinal accepted",
          AgentInteractionSandbox.isCardinalAdjacent(
              target: AgentPosition(x: 1, y: 64, z: 0),
              actor: sandboxAnchor
          ))
    check("G1 non-adjacent target rejected",
          !AgentInteractionSandbox.isCardinalAdjacent(
              target: AgentPosition(x: 2, y: 64, z: 0),
              actor: sandboxAnchor
          ))
    check("G1 vertical target rejected",
          !AgentInteractionSandbox.isCardinalAdjacent(
              target: AgentPosition(x: 1, y: 65, z: 0),
              actor: sandboxAnchor
          ))

    func interactionState(
        id: String = "agent_0",
        inventory: AgentResourceInventory = AgentResourceInventory()
    ) -> AgentSessionAgentState {
        AgentSessionAgentState(
            id: id,
            state: "idle",
            position: AgentPosition(x: 0, y: 64, z: 0),
            needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
            health: 100,
            fear: 0,
            homePosition: AgentPosition(x: 0, y: 64, z: 0),
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

    func interactionSession(inventory: AgentResourceInventory = AgentResourceInventory()) -> AgentSimulationSession {
        try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(seed: 7, memoryPolicy: .bounded(maxEntries: 16)),
            agents: [interactionState(inventory: inventory)]
        )
    }

    let interactionTarget = AgentPosition(x: 1, y: 64, z: 0)
    func intent(_ id: String = "harvest-1", agentId: String = "agent_0", tick: Int = 0) -> AgentInteractionIntent {
        AgentInteractionIntent(
            interactionId: id,
            agentId: agentId,
            tick: tick,
            target: interactionTarget,
            resource: .sandboxResource
        )
    }
    func outcome(
        _ id: String = "harvest-1",
        status: AgentInteractionStatus = .succeeded,
        quantity: Int = 1,
        tick: Int = 0,
        agentId: String = "agent_0"
    ) -> AgentInteractionOutcome {
        AgentInteractionOutcome(
            interactionId: id,
            agentId: agentId,
            tick: tick,
            target: interactionTarget,
            resource: .sandboxResource,
            status: status,
            inventoryDelta: AgentInventoryDelta(resource: .sandboxResource, quantity: quantity),
            reason: status == .succeeded ? "sandbox resource harvested" : "test blocked"
        )
    }

    var interaction = interactionSession()
    check("G1 session prevalidation succeeds", (try? interaction.prevalidateInteraction(intent())) != nil)
    let interactionBefore = interaction.snapshot().agents[0]
    try! interaction.applyInteractionOutcome(outcome())
    let interactionAfter = interaction.snapshot().agents[0]
    check("G1 successful outcome adds exactly one", interactionAfter.resourceInventory.totalCount == 1)
    check("G1 successful outcome exposed", interactionAfter.lastInteractionOutcome?.status == .succeeded)
    check("G1 success writes one memory", interactionAfter.memoryCount == interactionBefore.memoryCount + 1)
    check("G1 success memory type exact", interactionAfter.recentMemory.last?.type == "resource_harvested")
    check("G1 duplicate outcome rejected", {
        do { try interaction.applyInteractionOutcome(outcome()); return false }
        catch AgentSessionError.duplicateInteraction { return true }
        catch { return false }
    }())
    check("G1 unknown agent rejected", {
        do { try interaction.prevalidateInteraction(intent("unknown", agentId: "missing")); return false }
        catch AgentSessionError.unknownAgentId { return true }
        catch { return false }
    }())
    check("G1 wrong tick rejected", {
        do { try interaction.prevalidateInteraction(intent("wrong-tick", tick: 1)); return false }
        catch AgentSessionError.interactionTickMismatch { return true }
        catch { return false }
    }())

    var blockedSession = interactionSession()
    try! blockedSession.applyInteractionOutcome(outcome("blocked", status: .blocked, quantity: 0))
    let blockedSnapshot = blockedSession.snapshot().agents[0]
    check("G1 blocked outcome adds no inventory", blockedSnapshot.resourceInventory.isEmpty)
    check("G1 blocked outcome writes blocked memory", blockedSnapshot.recentMemory.last?.type == "interaction_blocked")
    check("G1 blocked outcome writes no success memory",
          !blockedSnapshot.recentMemory.contains { $0.type == "resource_harvested" })

    var fullInventory = AgentResourceInventory(capacity: 1)
    _ = fullInventory.add(.sandboxResource)
    var fullSession = interactionSession(inventory: fullInventory)
    check("G1 full inventory prevalidation rejected", {
        do { try fullSession.prevalidateInteraction(intent("full")); return false }
        catch AgentSessionError.inventoryFull { return true }
        catch { return false }
    }())
    try! fullSession.applyInteractionOutcome(outcome("full", status: .inventoryFull, quantity: 0))
    let fullSnapshot = fullSession.snapshot().agents[0]
    check("G1 full outcome preserves capacity", fullSnapshot.resourceInventory.totalCount == 1)
    check("G1 full outcome memory type", fullSnapshot.recentMemory.last?.type == "inventory_full")

    var invalidSession = interactionSession()
    let invalidBefore = invalidSession.snapshot().agents[0]
    check("G1 successful outcome exact delta enforced", {
        do { try invalidSession.applyInteractionOutcome(outcome("invalid", quantity: 2)); return false }
        catch AgentSessionError.invalidInteractionOutcome { return true }
        catch { return false }
    }())
    let invalidAfter = invalidSession.snapshot().agents[0]
    check("G1 invalid success has no partial mutation",
          invalidAfter.resourceInventory == invalidBefore.resourceInventory
              && invalidAfter.memoryCount == invalidBefore.memoryCount
              && invalidAfter.lastInteractionOutcome == nil)

}

}
