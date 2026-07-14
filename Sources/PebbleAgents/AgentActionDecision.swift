public struct AgentPosition: Codable, Equatable, Hashable, Sendable {
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
    case deliverResources
    case satisfyHunger
    case buildShelter
    case shareInformation
    case verifySocialInformation
    case considerSharedTask
    case fulfillSharedTask
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
    public let survivalEnabled: Bool
    public let hasFoodRaw: Bool
    public let constructionProject: AgentConstructionProject?
    public let socialVerificationTarget: AgentPosition?
    public let socialVerificationResource: AgentResourceKind?
    public let canAcceptSharedTask: Bool

    public init(
        agentId: String,
        tick: Int,
        goalKind: AgentGoalKind,
        position: AgentPosition,
        homePosition: AgentPosition,
        resourceObservations: [AgentResourceObservation] = [],
        activeResourceTarget: AgentResourceTarget? = nil,
        navigationProgress: AgentNavigationProgress = AgentNavigationProgress(),
        resourceReservation: AgentResourceReservation? = nil,
        survivalEnabled: Bool = false,
        hasFoodRaw: Bool = false,
        constructionProject: AgentConstructionProject? = nil,
        socialVerificationTarget: AgentPosition? = nil,
        socialVerificationResource: AgentResourceKind? = nil,
        canAcceptSharedTask: Bool = false
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
        self.survivalEnabled = survivalEnabled
        self.hasFoodRaw = hasFoodRaw
        self.constructionProject = constructionProject
        self.socialVerificationTarget = socialVerificationTarget
        self.socialVerificationResource = socialVerificationResource
        self.canAcceptSharedTask = canAcceptSharedTask
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
            if input.survivalEnabled, input.position != input.homePosition {
                return returnHomeAction(input, goalName: "rest")
            }
            return AgentAction(name: "rest", reason: "goal rest", tick: input.tick)
        case .collectResource:
            return resourceAction(input, goalName: "collectResource")
        case .satisfyHunger:
            if input.hasFoodRaw {
                return AgentAction(
                    name: "consume_food",
                    reason: "goal satisfyHunger: foodRaw carried",
                    tick: input.tick,
                    resource: .foodRaw
                )
            }
            let foodObservations = input.resourceObservations.filter { $0.resource == .foodRaw }
            let foodTarget = input.activeResourceTarget?.resource == .foodRaw
                ? input.activeResourceTarget
                : nil
            let foodInput = AgentActionDecisionInput(
                agentId: input.agentId,
                tick: input.tick,
                goalKind: input.goalKind,
                position: input.position,
                homePosition: input.homePosition,
                resourceObservations: foodObservations,
                activeResourceTarget: foodTarget,
                navigationProgress: input.navigationProgress,
                resourceReservation: input.resourceReservation,
                survivalEnabled: true,
                hasFoodRaw: false
            )
            return resourceAction(foodInput, goalName: "satisfyHunger")
        case .deliverResources:
            return returnHomeAction(input, goalName: "deliverResources")
        case .buildShelter:
            return constructionAction(input)
        case .shareInformation:
            return AgentAction(
                name: "share_information",
                reason: "goal shareInformation: directed grounded fact",
                tick: input.tick
            )
        case .verifySocialInformation:
            guard let target = input.socialVerificationTarget else {
                return AgentAction(
                    name: "wait",
                    reason: "goal verifySocialInformation: belief unavailable",
                    tick: input.tick
                )
            }
            if abs(target.x - input.position.x) + abs(target.y - input.position.y)
                + abs(target.z - input.position.z) <= 1 {
                return AgentAction(
                    name: "verify_information",
                    reason: "goal verifySocialInformation: read exact World cell",
                    tick: input.tick,
                    target: target,
                    resource: input.socialVerificationResource
                )
            }
            if let next = input.navigationProgress.nextStep {
                let dx = next.x - input.position.x
                let dy = next.y - input.position.y
                let dz = next.z - input.position.z
                if abs(dx) + abs(dz) == 1, (-1...1).contains(dy) {
                    return AgentAction(
                        name: "approach_information",
                        reason: "goal verifySocialInformation: follow bounded social route",
                        tick: input.tick,
                        dx: dx,
                        dy: dy,
                        dz: dz,
                        target: target,
                        resource: input.socialVerificationResource
                    )
                }
            }
            return AgentAction(
                name: "approach_information",
                reason: "goal verifySocialInformation: awaiting bounded social route",
                tick: input.tick,
                target: target,
                resource: input.socialVerificationResource
            )
        case .considerSharedTask:
            return AgentAction(
                name: input.canAcceptSharedTask ? "accept_task" : "decline_task",
                reason: input.canAcceptSharedTask
                    ? "goal considerSharedTask: voluntary bounded acceptance"
                    : "goal considerSharedTask: acceptance conditions not met",
                tick: input.tick
            )
        case .fulfillSharedTask:
            return resourceAction(input, goalName: "fulfillSharedTask")
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

    private static func constructionAction(_ input: AgentActionDecisionInput) -> AgentAction {
        guard let project = input.constructionProject,
              project.builderAgentId == input.agentId else {
            return AgentAction(
                name: "wait",
                reason: "goal buildShelter: project unavailable",
                tick: input.tick
            )
        }
        switch project.status {
        case .readyToFund:
            if input.position == input.homePosition {
                return AgentAction(
                    name: "fund_construction",
                    reason: "goal buildShelter: materials ready at camp",
                    tick: input.tick
                )
            }
            return returnHomeAction(input, goalName: "buildShelter")
        case .funded, .building:
            guard let target = project.nextTarget,
                  let workPosition = project.nextWorkPosition,
                  let resource = project.nextCell?.resource else {
                return AgentAction(
                    name: "wait",
                    reason: "goal buildShelter: completion verification pending",
                    tick: input.tick
                )
            }
            if input.position == workPosition {
                return AgentAction(
                    name: "place_block",
                    reason: "goal buildShelter: place ordered blueprint cell",
                    tick: input.tick,
                    target: target,
                    resource: resource
                )
            }
            if let next = input.navigationProgress.nextStep {
                let dx = next.x - input.position.x
                let dy = next.y - input.position.y
                let dz = next.z - input.position.z
                if abs(dx) + abs(dz) == 1, (-1...1).contains(dy) {
                    return AgentAction(
                        name: "approach_construction",
                        reason: "goal buildShelter: follow bounded work route",
                        tick: input.tick,
                        dx: dx,
                        dy: dy,
                        dz: dz,
                        target: workPosition,
                        resource: resource
                    )
                }
            }
            return AgentAction(
                name: "approach_construction",
                reason: "goal buildShelter: awaiting bounded work route",
                tick: input.tick,
                target: workPosition,
                resource: resource
            )
        case .blocked:
            return AgentAction(
                name: "wait",
                reason: "goal buildShelter: project blocked",
                tick: input.tick
            )
        case .planned, .acquiringMaterials:
            return AgentAction(
                name: "wait",
                reason: "goal buildShelter: materials still required",
                tick: input.tick
            )
        case .completed:
            return AgentAction(
                name: "wait",
                reason: "goal buildShelter: shelter completed",
                tick: input.tick
            )
        }
    }

    private static func resourceAction(
        _ input: AgentActionDecisionInput,
        goalName: String
    ) -> AgentAction {
            if input.navigationProgress.route?.purpose == .constructionSurvey {
                if let next = input.navigationProgress.nextStep {
                    let dx = next.x - input.position.x
                    let dy = next.y - input.position.y
                    let dz = next.z - input.position.z
                    if abs(dx) + abs(dz) == 1, (-1...1).contains(dy) {
                        return AgentAction(
                            name: "approach_resource",
                            reason: "goal \(goalName): bounded construction material survey",
                            tick: input.tick,
                            dx: dx,
                            dy: dy,
                            dz: dz,
                            target: input.navigationProgress.route?.target
                        )
                    }
                }
                return AgentAction(
                    name: "wait",
                    reason: "goal \(goalName): construction survey waypoint reached",
                    tick: input.tick,
                    target: input.navigationProgress.route?.target
                )
            }
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
                    reason: "goal \(goalName): resource unavailable",
                    tick: input.tick
                )
            }
            if target.distanceManhattan > 1 {
                if input.navigationProgress.lastFailure == .reservationConflict
                    || input.navigationProgress.lastFailure == .reservationLost {
                    return AgentAction(
                        name: "wait",
                        reason: "goal \(goalName): reservation unavailable",
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
                            reason: "goal \(goalName): follow bounded route",
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
                    reason: "goal \(goalName): distant target selected",
                    tick: input.tick,
                    target: target.target,
                    resource: target.resource
                )
            }
            return AgentAction(
                name: "harvest_block",
                reason: "goal \(goalName): adjacent sandbox resource",
                tick: input.tick,
                target: target.target,
                resource: target.resource
            )
    }

    private static func returnHomeAction(
        _ input: AgentActionDecisionInput,
        goalName: String
    ) -> AgentAction {
            if input.position == input.homePosition {
                if goalName == "rest" {
                    return AgentAction(name: "rest", reason: "goal rest at home", tick: input.tick)
                }
                return AgentAction(
                    name: "deliver_resource",
                    reason: "goal \(goalName): at home",
                    tick: input.tick,
                    target: input.homePosition
                )
            }
            if let next = input.navigationProgress.nextStep {
                let dx = next.x - input.position.x
                let dy = next.y - input.position.y
                let dz = next.z - input.position.z
                if abs(dx) + abs(dz) == 1, (-1...1).contains(dy) {
                    return AgentAction(
                        name: "return_home",
                        reason: "goal \(goalName): follow bounded route",
                        tick: input.tick,
                        dx: dx,
                        dy: dy,
                        dz: dz,
                        target: input.homePosition
                    )
                }
            }
            return AgentAction(
                name: "return_home",
                reason: "goal \(goalName): awaiting bounded route",
                tick: input.tick,
                target: input.homePosition
            )
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
