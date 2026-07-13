public enum AgentMovementStatus: String, Codable, Equatable {
    case notRequested
    case moved
    case blocked
}

public struct AgentMovementOutcome: Encodable, Equatable {
    public let agentId: String
    public let tick: Int
    public let status: AgentMovementStatus
    public let fromPosition: AgentPosition
    public let toPosition: AgentPosition
    public let requestedDirection: AgentCardinalDirection?
    public let requestedDX: Int
    public let requestedDY: Int
    public let requestedDZ: Int
    public let appliedDX: Int
    public let appliedDY: Int
    public let appliedDZ: Int
    public let goalKind: AgentGoalKind
    public let actionReason: String
    public let resolutionReason: String
    public let worldTickObserved: Int?
    public let distanceFromHomeBefore: Int
    public let distanceFromHomeAfter: Int
    public let distanceReducedTowardHome: Int

    public init(
        agentId: String,
        tick: Int,
        status: AgentMovementStatus,
        fromPosition: AgentPosition,
        toPosition: AgentPosition,
        requestedDirection: AgentCardinalDirection?,
        requestedDX: Int,
        requestedDY: Int,
        requestedDZ: Int,
        appliedDX: Int,
        appliedDY: Int,
        appliedDZ: Int,
        goalKind: AgentGoalKind,
        actionReason: String,
        resolutionReason: String,
        worldTickObserved: Int?,
        distanceFromHomeBefore: Int,
        distanceFromHomeAfter: Int,
        distanceReducedTowardHome: Int
    ) {
        self.agentId = agentId
        self.tick = tick
        self.status = status
        self.fromPosition = fromPosition
        self.toPosition = toPosition
        self.requestedDirection = requestedDirection
        self.requestedDX = requestedDX
        self.requestedDY = requestedDY
        self.requestedDZ = requestedDZ
        self.appliedDX = appliedDX
        self.appliedDY = appliedDY
        self.appliedDZ = appliedDZ
        self.goalKind = goalKind
        self.actionReason = actionReason
        self.resolutionReason = resolutionReason
        self.worldTickObserved = worldTickObserved
        self.distanceFromHomeBefore = distanceFromHomeBefore
        self.distanceFromHomeAfter = distanceFromHomeAfter
        self.distanceReducedTowardHome = distanceReducedTowardHome
    }
}

public enum AgentMovementCoordinator {
    public static func resolve(snapshot: AgentSessionSnapshot) -> [AgentMovementOutcome] {
        let agents = snapshot.agents.sorted { $0.id < $1.id }
        let occupied = agents.map { positionKey($0.position) }
        var outcomes = agents.map { resolve(agent: $0, tick: snapshot.tick, occupied: occupied) }

        let movedTargets = outcomes.filter { $0.status == .moved }
        for target in movedTargets.map({ positionKey($0.toPosition) }) {
            let contenders = outcomes.indices.filter {
                outcomes[$0].status == .moved && positionKey(outcomes[$0].toPosition) == target
            }
            guard contenders.count > 1 else { continue }
            let winner = contenders.min { outcomes[$0].agentId < outcomes[$1].agentId }!
            for index in contenders where index != winner {
                outcomes[index] = blocked(from: outcomes[index], reason: "target conflict")
            }
        }
        return outcomes.sorted { $0.agentId < $1.agentId }
    }

    private static func resolve(
        agent: AgentSnapshot,
        tick: Int,
        occupied: [String]
    ) -> AgentMovementOutcome {
        guard let action = agent.lastAction,
              action.name == "move_abstract"
                || action.name == "approach_resource"
                || action.name == "return_home"
                || action.name == "approach_construction" else {
            return stationary(
                agent: agent,
                tick: tick,
                status: .notRequested,
                action: agent.lastAction,
                direction: nil,
                reason: "no movement intent",
                worldTick: agent.lastWorldObservation?.worldTick
            )
        }

        let dx = action.dx ?? 0
        let dy = action.dy ?? 0
        let dz = action.dz ?? 0
        if action.name == "approach_resource" || action.name == "return_home"
            || action.name == "approach_construction",
           action.dx == nil || action.dz == nil
                || !(action.dy == nil || (-1...1).contains(dy))
                || abs(dx) + abs(dz) != 1 {
            return stationary(
                agent: agent,
                tick: tick,
                status: .notRequested,
                action: action,
                direction: nil,
                reason: "approach has no valid route step",
                worldTick: agent.lastWorldObservation?.worldTick
            )
        }
        let validVerticalIntent = action.name == "approach_resource" || action.name == "return_home"
            || action.name == "approach_construction"
            ? (-1...1).contains(dy)
            : (action.dy == nil || action.dy == 0)
        guard validVerticalIntent, abs(dx) + abs(dz) == 1 else {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: nil, reason: "invalid movement intent", worldTick: agent.lastWorldObservation?.worldTick)
        }
        let direction = cardinalDirection(dx: dx, dz: dz)!
        guard let observation = agent.lastWorldObservation else {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: "missing world observation", worldTick: nil)
        }
        guard observation.position == agent.position else {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: "stale world observation", worldTick: observation.worldTick)
        }
        guard let neighbor = observation.neighbors.first(where: { $0.direction == direction }) else {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: "missing neighbor observation", worldTick: observation.worldTick)
        }
        let reason: String?
        if !neighbor.column.chunkReady { reason = "target chunk unavailable" }
        else if neighbor.dangerousDrop { reason = "dangerous drop" }
        else if !neighbor.column.groundPresent { reason = "no ground at target" }
        else if !neighbor.column.feetClear || !neighbor.column.headClear { reason = "target body space blocked" }
        else if neighbor.stepDelta == nil { reason = "unknown target step" }
        else if !(-1...1).contains(neighbor.stepDelta!) { reason = "target step out of range" }
        else if !neighbor.traversable { reason = "neighbor not traversable" }
        else { reason = nil }
        if let reason {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: reason, worldTick: observation.worldTick)
        }

        let step = neighbor.stepDelta!
        if action.name == "approach_resource" || action.name == "return_home"
            || action.name == "approach_construction", step != dy {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: "route step height changed", worldTick: observation.worldTick)
        }
        let target = AgentPosition(
            x: agent.position.x + direction.dx,
            y: agent.position.y + step,
            z: agent.position.z + direction.dz
        )
        if occupied.contains(positionKey(target)) {
            return stationary(agent: agent, tick: tick, status: .blocked, action: action, direction: direction, reason: "target occupied", worldTick: observation.worldTick)
        }

        let before = distance(agent.position, agent.homePosition)
        let after = distance(target, agent.homePosition)
        return AgentMovementOutcome(
            agentId: agent.id,
            tick: tick,
            status: .moved,
            fromPosition: agent.position,
            toPosition: target,
            requestedDirection: direction,
            requestedDX: dx,
            requestedDY: dy,
            requestedDZ: dz,
            appliedDX: direction.dx,
            appliedDY: step,
            appliedDZ: direction.dz,
            goalKind: agent.currentGoal.kind,
            actionReason: action.reason,
            resolutionReason: "safe cardinal movement",
            worldTickObserved: observation.worldTick,
            distanceFromHomeBefore: before,
            distanceFromHomeAfter: after,
            distanceReducedTowardHome: max(0, before - after)
        )
    }

    private static func stationary(
        agent: AgentSnapshot,
        tick: Int,
        status: AgentMovementStatus,
        action: AgentAction?,
        direction: AgentCardinalDirection?,
        reason: String,
        worldTick: Int?
    ) -> AgentMovementOutcome {
        let distanceHome = distance(agent.position, agent.homePosition)
        return AgentMovementOutcome(
            agentId: agent.id,
            tick: tick,
            status: status,
            fromPosition: agent.position,
            toPosition: agent.position,
            requestedDirection: direction,
            requestedDX: action?.dx ?? 0,
            requestedDY: action?.dy ?? 0,
            requestedDZ: action?.dz ?? 0,
            appliedDX: 0,
            appliedDY: 0,
            appliedDZ: 0,
            goalKind: agent.currentGoal.kind,
            actionReason: action?.reason ?? "",
            resolutionReason: reason,
            worldTickObserved: worldTick,
            distanceFromHomeBefore: distanceHome,
            distanceFromHomeAfter: distanceHome,
            distanceReducedTowardHome: 0
        )
    }

    private static func blocked(from outcome: AgentMovementOutcome, reason: String) -> AgentMovementOutcome {
        AgentMovementOutcome(
            agentId: outcome.agentId,
            tick: outcome.tick,
            status: .blocked,
            fromPosition: outcome.fromPosition,
            toPosition: outcome.fromPosition,
            requestedDirection: outcome.requestedDirection,
            requestedDX: outcome.requestedDX,
            requestedDY: outcome.requestedDY,
            requestedDZ: outcome.requestedDZ,
            appliedDX: 0,
            appliedDY: 0,
            appliedDZ: 0,
            goalKind: outcome.goalKind,
            actionReason: outcome.actionReason,
            resolutionReason: reason,
            worldTickObserved: outcome.worldTickObserved,
            distanceFromHomeBefore: outcome.distanceFromHomeBefore,
            distanceFromHomeAfter: outcome.distanceFromHomeBefore,
            distanceReducedTowardHome: 0
        )
    }

    private static func cardinalDirection(dx: Int, dz: Int) -> AgentCardinalDirection? {
        switch (dx, dz) {
        case (0, -1): return .north
        case (1, 0): return .east
        case (0, 1): return .south
        case (-1, 0): return .west
        default: return nil
        }
    }

    private static func distance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private static func positionKey(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }
}
