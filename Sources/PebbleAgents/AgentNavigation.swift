public enum AgentNavigationCellStatus: String, Codable, Equatable {
    case traversable
    case blocked
    case unavailable
    case dangerousDrop
}

public struct AgentNavigationCell: Codable, Equatable {
    public let position: AgentPosition
    public let status: AgentNavigationCellStatus

    public init(position: AgentPosition, status: AgentNavigationCellStatus) {
        self.position = position
        self.status = status
    }
}

public enum AgentNavigationGoalMode: String, Codable, Equatable {
    case exact
    case cardinalAdjacent
}

public struct AgentNavigationObservation: Codable, Equatable {
    public static let maximumRadius = 8
    public static let maximumCellCount = 512

    public let worldTick: Int
    public let origin: AgentPosition
    public let target: AgentPosition
    public let radius: Int
    public let cells: [AgentNavigationCell]

    public init(
        worldTick: Int,
        origin: AgentPosition,
        target: AgentPosition,
        radius: Int = maximumRadius,
        cells: [AgentNavigationCell]
    ) {
        self.worldTick = worldTick
        self.origin = origin
        self.target = target
        self.radius = radius
        self.cells = cells
    }
}

public enum AgentNavigationFailure: String, Codable, Equatable {
    case invalidConfiguration
    case invalidStart
    case invalidGoal
    case radiusExceeded
    case nodeLimitReached
    case stepLimitReached
    case cellUnavailable
    case stepOutOfRange
    case dangerousDrop
    case noRoute
    case reservationConflict
    case reservationLost
    case targetMissing
    case targetChanged
    case targetGone
    case perceptionMissing
    case perceptionStale
    case nextStepInvalid
    case movementBlocked
    case replanLimitReached
    case harvested
    case delivered
}

public struct AgentNavigationRequest {
    public let start: AgentPosition
    public let target: AgentPosition
    public let goalMode: AgentNavigationGoalMode
    public let cells: [AgentNavigationCell]
    public let radius: Int
    public let maxVisitedNodes: Int
    public let maxSteps: Int

    public init(
        start: AgentPosition,
        target: AgentPosition,
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent,
        cells: [AgentNavigationCell],
        radius: Int = AgentNavigationObservation.maximumRadius,
        maxVisitedNodes: Int = 256,
        maxSteps: Int = 16
    ) {
        self.start = start
        self.target = target
        self.goalMode = goalMode
        self.cells = cells
        self.radius = radius
        self.maxVisitedNodes = maxVisitedNodes
        self.maxSteps = maxSteps
    }
}

public struct AgentNavigationPlan: Codable, Equatable {
    public let positions: [AgentPosition]
    public let visitedNodeCount: Int
    public let failure: AgentNavigationFailure?

    public var found: Bool { failure == nil && !positions.isEmpty }

    public init(
        positions: [AgentPosition],
        visitedNodeCount: Int,
        failure: AgentNavigationFailure?
    ) {
        self.positions = positions
        self.visitedNodeCount = visitedNodeCount
        self.failure = failure
    }
}

public enum AgentBoundedRoutePlanner {
    public static let maximumVisitedNodes = 256
    public static let maximumRouteSteps = 16
    public static let neighborOrder = AgentCardinalDirection.allCases

    public static func plan(_ request: AgentNavigationRequest) -> AgentNavigationPlan {
        guard (1...AgentNavigationObservation.maximumRadius).contains(request.radius),
              (1...maximumVisitedNodes).contains(request.maxVisitedNodes),
              (0...maximumRouteSteps).contains(request.maxSteps),
              request.cells.count <= AgentNavigationObservation.maximumCellCount else {
            return failed(.invalidConfiguration)
        }
        let targetDistance = horizontalDistance(request.start, request.target)
        guard targetDistance <= request.radius else { return failed(.radiusExceeded) }

        var statusByPosition: [AgentPosition: AgentNavigationCellStatus] = [:]
        var uniqueCells: [AgentNavigationCell] = []
        for cell in request.cells where statusByPosition[cell.position] == nil {
            guard horizontalDistance(request.start, cell.position) <= request.radius else { continue }
            statusByPosition[cell.position] = cell.status
            uniqueCells.append(cell)
        }
        let orderedCells = uniqueCells.sorted(by: cellSort)
        guard statusByPosition[request.start] == .traversable else {
            return failed(.invalidStart)
        }
        if request.goalMode == .exact,
           statusByPosition[request.target] != .traversable {
            return failed(.invalidGoal)
        }
        if reachedGoal(request.start, target: request.target, mode: request.goalMode) {
            return AgentNavigationPlan(positions: [request.start], visitedNodeCount: 1, failure: nil)
        }
        guard request.maxSteps > 0 else {
            return AgentNavigationPlan(positions: [], visitedNodeCount: 1, failure: .stepLimitReached)
        }

        var queue = [request.start]
        var queueIndex = 0
        var visited: Set<AgentPosition> = [request.start]
        var predecessor: [AgentPosition: AgentPosition] = [:]
        var depth: [AgentPosition: Int] = [request.start: 0]
        var hitStepLimit = false
        var sawUnavailable = false
        var sawDangerousDrop = false
        var sawOutOfRangeStep = false

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1
            let currentDepth = depth[current] ?? 0
            guard currentDepth < request.maxSteps else {
                hitStepLimit = true
                continue
            }

            for direction in neighborOrder {
                let horizontal = orderedCells.filter {
                    $0.position.x == current.x + direction.dx
                        && $0.position.z == current.z + direction.dz
                        && horizontalDistance(request.start, $0.position) <= request.radius
                        && !(request.goalMode == .cardinalAdjacent && $0.position == request.target)
                }
                if horizontal.contains(where: { $0.status == .unavailable }) { sawUnavailable = true }
                if horizontal.contains(where: { $0.status == .dangerousDrop }) { sawDangerousDrop = true }
                if horizontal.contains(where: {
                    $0.status == .traversable && !(-1...1).contains($0.position.y - current.y)
                }) { sawOutOfRangeStep = true }

                let candidates = horizontal.filter {
                    $0.status == .traversable
                        && (-1...1).contains($0.position.y - current.y)
                        && !visited.contains($0.position)
                }.sorted { lhs, rhs in
                    let lhsRank = verticalRank(lhs.position.y - current.y)
                    let rhsRank = verticalRank(rhs.position.y - current.y)
                    if lhsRank != rhsRank { return lhsRank < rhsRank }
                    return cellSort(lhs, rhs)
                }

                for candidate in candidates {
                    guard visited.count < request.maxVisitedNodes else {
                        return AgentNavigationPlan(
                            positions: [],
                            visitedNodeCount: visited.count,
                            failure: .nodeLimitReached
                        )
                    }
                    let next = candidate.position
                    visited.insert(next)
                    predecessor[next] = current
                    depth[next] = currentDepth + 1
                    if reachedGoal(next, target: request.target, mode: request.goalMode) {
                        return AgentNavigationPlan(
                            positions: reconstructPath(to: next, predecessor: predecessor),
                            visitedNodeCount: visited.count,
                            failure: nil
                        )
                    }
                    queue.append(next)
                }
            }
        }

        let failure: AgentNavigationFailure
        if hitStepLimit { failure = .stepLimitReached }
        else if sawUnavailable { failure = .cellUnavailable }
        else if sawDangerousDrop { failure = .dangerousDrop }
        else if sawOutOfRangeStep { failure = .stepOutOfRange }
        else { failure = .noRoute }
        return AgentNavigationPlan(
            positions: [],
            visitedNodeCount: visited.count,
            failure: failure
        )
    }

    private static func reconstructPath(
        to destination: AgentPosition,
        predecessor: [AgentPosition: AgentPosition]
    ) -> [AgentPosition] {
        var path = [destination]
        var cursor = destination
        while let previous = predecessor[cursor] {
            path.append(previous)
            cursor = previous
        }
        return path.reversed()
    }

    private static func reachedGoal(
        _ position: AgentPosition,
        target: AgentPosition,
        mode: AgentNavigationGoalMode
    ) -> Bool {
        switch mode {
        case .exact:
            return position == target
        case .cardinalAdjacent:
            return AgentInteractionSandbox.isCardinalAdjacent(target: target, actor: position)
        }
    }

    private static func cellSort(_ lhs: AgentNavigationCell, _ rhs: AgentNavigationCell) -> Bool {
        if lhs.position.x != rhs.position.x { return lhs.position.x < rhs.position.x }
        if lhs.position.z != rhs.position.z { return lhs.position.z < rhs.position.z }
        if lhs.position.y != rhs.position.y { return lhs.position.y < rhs.position.y }
        return lhs.status.rawValue < rhs.status.rawValue
    }

    private static func verticalRank(_ deltaY: Int) -> Int {
        switch deltaY {
        case 0: return 0
        case 1: return 1
        default: return 2
        }
    }

    private static func horizontalDistance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.z - rhs.z)
    }

    private static func failed(_ failure: AgentNavigationFailure) -> AgentNavigationPlan {
        AgentNavigationPlan(positions: [], visitedNodeCount: 0, failure: failure)
    }
}

public enum AgentNavigationStatus: String, Codable, Equatable {
    case idle
    case active
    case arrived
    case failed
}

public enum AgentNavigationPurpose: String, Codable, Equatable {
    case resource
    case homeDelivery
    case homeRest
    case constructionWork
}

public struct AgentNavigationRoute: Codable, Equatable {
    public let purpose: AgentNavigationPurpose
    public let target: AgentPosition
    public let resource: AgentResourceKind?
    public let positions: [AgentPosition]
    public let plannedAtTick: Int
    public let visitedNodeCount: Int

    public init(
        purpose: AgentNavigationPurpose = .resource,
        target: AgentPosition,
        resource: AgentResourceKind? = nil,
        positions: [AgentPosition],
        plannedAtTick: Int,
        visitedNodeCount: Int
    ) {
        self.purpose = purpose
        self.target = target
        self.resource = resource
        self.positions = positions
        self.plannedAtTick = plannedAtTick
        self.visitedNodeCount = visitedNodeCount
    }
}

public struct AgentNavigationProgress: Codable, Equatable {
    public let status: AgentNavigationStatus
    public let route: AgentNavigationRoute?
    public let routeIndex: Int
    public let replanCount: Int
    public let consecutiveBlockedMoves: Int
    public let lastPlanTick: Int?
    public let lastInvalidation: AgentNavigationFailure?
    public let lastFailure: AgentNavigationFailure?

    public var nextStep: AgentPosition? {
        guard let route, route.positions.indices.contains(routeIndex + 1) else { return nil }
        return route.positions[routeIndex + 1]
    }

    public var stepsRemaining: Int {
        guard let route else { return 0 }
        return max(0, route.positions.count - routeIndex - 1)
    }

    public init(
        status: AgentNavigationStatus = .idle,
        route: AgentNavigationRoute? = nil,
        routeIndex: Int = 0,
        replanCount: Int = 0,
        consecutiveBlockedMoves: Int = 0,
        lastPlanTick: Int? = nil,
        lastInvalidation: AgentNavigationFailure? = nil,
        lastFailure: AgentNavigationFailure? = nil
    ) {
        self.status = status
        self.route = route
        self.routeIndex = routeIndex
        self.replanCount = replanCount
        self.consecutiveBlockedMoves = consecutiveBlockedMoves
        self.lastPlanTick = lastPlanTick
        self.lastInvalidation = lastInvalidation
        self.lastFailure = lastFailure
    }
}

public struct AgentResourceReservation: Codable, Equatable {
    public let agentId: String
    public let target: AgentPosition
    public let resource: AgentResourceKind
    public let source: AgentResourceObservationSource
    public let expectedBlockFingerprint: Int?
    public let acquiredAtTick: Int
    public let expiresAtTick: Int

    public init(
        agentId: String,
        target: AgentPosition,
        resource: AgentResourceKind,
        source: AgentResourceObservationSource = .sandboxFixture,
        expectedBlockFingerprint: Int? = nil,
        acquiredAtTick: Int,
        expiresAtTick: Int
    ) {
        self.agentId = agentId
        self.target = target
        self.resource = resource
        self.source = source
        self.expectedBlockFingerprint = expectedBlockFingerprint
        self.acquiredAtTick = acquiredAtTick
        self.expiresAtTick = expiresAtTick
    }

    public func isExpired(at tick: Int) -> Bool { tick > expiresAtTick }
}
