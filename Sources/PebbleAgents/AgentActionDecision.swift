public struct AgentPosition: Codable, Equatable, Hashable {
    public let x: Int
    public let y: Int
    public let z: Int

    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public enum AgentGoalKind: String, Codable, Equatable {
    case idle
    case rest
    case seekSafety
    case collectResource
    case explore
    case observeOtherAgent
}

public struct AgentGoal: Codable, Equatable {
    public let kind: AgentGoalKind
    public let reason: String
    public let startedAtTick: Int
    public let urgency: Int

    public init(kind: AgentGoalKind, reason: String, startedAtTick: Int, urgency: Int) {
        self.kind = kind
        self.reason = reason
        self.startedAtTick = startedAtTick
        self.urgency = urgency
    }
}

public struct AgentAction: Encodable {
    public let name: String
    public let reason: String
    public let tick: Int
    public let dx: Int?
    public let dy: Int?
    public let dz: Int?
    public let target: AgentPosition?
    public let resource: AgentResourceKind?

    public init(
        name: String,
        reason: String,
        tick: Int,
        dx: Int? = nil,
        dy: Int? = nil,
        dz: Int? = nil,
        target: AgentPosition? = nil,
        resource: AgentResourceKind? = nil
    ) {
        self.name = name
        self.reason = reason
        self.tick = tick
        self.dx = dx
        self.dy = dy
        self.dz = dz
        self.target = target
        self.resource = resource
    }
}

public struct AgentActionDecisionInput {
    public let agentId: String
    public let tick: Int
    public let goalKind: AgentGoalKind
    public let position: AgentPosition
    public let homePosition: AgentPosition
    public let resourceObservations: [AgentResourceObservation]
    public let activeResourceTarget: AgentResourceTarget?
    public let navigationProgress: AgentNavigationProgress
    public let resourceReservation: AgentResourceReservation?

    public init(
        agentId: String,
        tick: Int,
        goalKind: AgentGoalKind,
        position: AgentPosition,
        homePosition: AgentPosition,
        resourceObservations: [AgentResourceObservation] = [],
        activeResourceTarget: AgentResourceTarget? = nil,
        navigationProgress: AgentNavigationProgress = AgentNavigationProgress(),
        resourceReservation: AgentResourceReservation? = nil
    ) {
        self.agentId = agentId
        self.tick = tick
        self.goalKind = goalKind
        self.position = position
        self.homePosition = homePosition
        self.resourceObservations = resourceObservations
        self.activeResourceTarget = activeResourceTarget
        self.navigationProgress = navigationProgress
        self.resourceReservation = resourceReservation
    }
}

public enum AgentActionDecider {
    public static func decide(_ input: AgentActionDecisionInput) -> AgentAction {
        switch input.goalKind {
        case .seekSafety:
            if let step = movementStepTowardHome(
                position: input.position,
                homePosition: input.homePosition
            ) {
                return AgentAction(
                    name: "move_abstract",
                    reason: "goal seekSafety",
                    tick: input.tick,
                    dx: step.dx,
                    dy: 0,
                    dz: step.dz
                )
            }
            return AgentAction(
                name: "wait",
                reason: "goal seekSafety at home",
                tick: input.tick
            )
        case .rest:
            return AgentAction(name: "rest", reason: "goal rest", tick: input.tick)
        case .collectResource:
            let observations = (try? AgentResourcePerception.normalize(
                observerPosition: input.position,
                observations: input.resourceObservations,
                maximumDistance: AgentResourcePerception.maximumDistance
            )) ?? []
            let target = input.activeResourceTarget ?? observations.first.map {
                AgentResourceTarget(
                    resource: $0.resource,
                    target: $0.target,
                    source: $0.source,
                    distanceManhattan: $0.distanceManhattan,
                    selectedAtTick: input.tick,
                    lastSeenAtTick: input.tick
                )
            }
            guard let target else {
                return AgentAction(
                    name: "wait",
                    reason: "goal collectResource: resource unavailable",
                    tick: input.tick
                )
            }
            if target.distanceManhattan > 1 {
                if input.navigationProgress.lastFailure == .reservationConflict
                    || input.navigationProgress.lastFailure == .reservationLost {
                    return AgentAction(
                        name: "wait",
                        reason: "goal collectResource: reservation unavailable",
                        tick: input.tick,
                        target: target.target,
                        resource: target.resource
                    )
                }
                if input.resourceReservation?.agentId == input.agentId,
                   input.resourceReservation?.target == target.target,
                   let next = input.navigationProgress.nextStep {
                    let dx = next.x - input.position.x
                    let dy = next.y - input.position.y
                    let dz = next.z - input.position.z
                    if abs(dx) + abs(dz) == 1, (-1...1).contains(dy) {
                        return AgentAction(
                            name: "approach_resource",
                            reason: "goal collectResource: follow bounded route",
                            tick: input.tick,
                            dx: dx,
                            dy: dy,
                            dz: dz,
                            target: target.target,
                            resource: target.resource
                        )
                    }
                }
                return AgentAction(
                    name: "approach_resource",
                    reason: "goal collectResource: distant target selected",
                    tick: input.tick,
                    target: target.target,
                    resource: target.resource
                )
            }
            return AgentAction(
                name: "harvest_block",
                reason: "goal collectResource: adjacent sandbox resource",
                tick: input.tick,
                target: target.target,
                resource: target.resource
            )
        case .observeOtherAgent:
            return AgentAction(
                name: "observe_area",
                reason: "goal observeOtherAgent",
                tick: input.tick
            )
        case .explore:
            let direction = explorationDirection(agentId: input.agentId, tick: input.tick)
            return AgentAction(
                name: "move_abstract",
                reason: "goal explore",
                tick: input.tick,
                dx: direction.dx,
                dy: 0,
                dz: direction.dz
            )
        case .idle:
            return AgentAction(name: "wait", reason: "goal idle", tick: input.tick)
        }
    }

    private static func movementStepTowardHome(
        position: AgentPosition,
        homePosition: AgentPosition
    ) -> (dx: Int, dz: Int)? {
        let dxToHome = homePosition.x - position.x
        let dzToHome = homePosition.z - position.z

        if dxToHome == 0 && dzToHome == 0 {
            return nil
        }

        if abs(dxToHome) >= abs(dzToHome), dxToHome != 0 {
            return (dxToHome > 0 ? 1 : -1, 0)
        }

        if dzToHome != 0 {
            return (0, dzToHome > 0 ? 1 : -1)
        }

        return nil
    }

    private static func explorationDirection(agentId: String, tick: Int) -> (dx: Int, dz: Int) {
        let suffix = agentId.split(separator: "_").last.flatMap { Int($0) } ?? 0
        switch (suffix + tick) % 4 {
        case 0:
            return (1, 0)
        case 1:
            return (0, 1)
        case 2:
            return (-1, 0)
        default:
            return (0, -1)
        }
    }
}
