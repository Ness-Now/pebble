public enum AgentFeedbackLoopConfigurationError: Error, Equatable {
    case invalidMaxRetrievedRecords(Int)
    case invalidMaxMemoryAgeTicks(Int)
    case invalidDuplicateWindowTicks(Int)
    case invalidMaxExploreDistanceFromHome(Int)
}

public struct AgentFeedbackLoopConfiguration: Equatable {
    public let maxRetrievedRecords: Int
    public let maxMemoryAgeTicks: Int
    public let duplicateWindowTicks: Int
    public let maxExploreDistanceFromHome: Int

    public init(
        maxRetrievedRecords: Int = 3,
        maxMemoryAgeTicks: Int = 16,
        duplicateWindowTicks: Int = 8,
        maxExploreDistanceFromHome: Int = 8
    ) throws {
        guard maxRetrievedRecords > 0 else {
            throw AgentFeedbackLoopConfigurationError.invalidMaxRetrievedRecords(maxRetrievedRecords)
        }
        guard maxMemoryAgeTicks > 0 else {
            throw AgentFeedbackLoopConfigurationError.invalidMaxMemoryAgeTicks(maxMemoryAgeTicks)
        }
        guard duplicateWindowTicks >= 0 else {
            throw AgentFeedbackLoopConfigurationError.invalidDuplicateWindowTicks(duplicateWindowTicks)
        }
        guard maxExploreDistanceFromHome > 0 else {
            throw AgentFeedbackLoopConfigurationError.invalidMaxExploreDistanceFromHome(maxExploreDistanceFromHome)
        }
        self.maxRetrievedRecords = maxRetrievedRecords
        self.maxMemoryAgeTicks = maxMemoryAgeTicks
        self.duplicateWindowTicks = duplicateWindowTicks
        self.maxExploreDistanceFromHome = maxExploreDistanceFromHome
    }

    public static let live = try! AgentFeedbackLoopConfiguration()
}

public struct AgentRetrievedMemory: Encodable, Equatable {
    public let tick: Int
    public let type: String
    public let summary: String
    public let importance: Double
    public let ageTicks: Int
    public let matchedCurrentFeedback: Bool

    public init(
        tick: Int,
        type: String,
        summary: String,
        importance: Double,
        ageTicks: Int,
        matchedCurrentFeedback: Bool
    ) {
        self.tick = tick
        self.type = type
        self.summary = summary
        self.importance = importance
        self.ageTicks = ageTicks
        self.matchedCurrentFeedback = matchedCurrentFeedback
    }
}

public enum AgentDecisionFactorKind: String, Codable, Equatable {
    case basePolicy
    case movementFeedback
    case explorationBoundary
}

public struct AgentDecisionFactor: Encodable, Equatable {
    public let kind: AgentDecisionFactorKind
    public let weight: Int
    public let summary: String
    public let memoryTick: Int?

    public init(kind: AgentDecisionFactorKind, weight: Int, summary: String, memoryTick: Int? = nil) {
        self.kind = kind
        self.weight = weight
        self.summary = summary
        self.memoryTick = memoryTick
    }
}

public struct AgentFeedbackDecisionTrace: Encodable, Equatable {
    public let tick: Int
    public let baseAction: AgentAction
    public let finalAction: AgentAction
    public let baseDirection: AgentCardinalDirection?
    public let finalDirection: AgentCardinalDirection?
    public let memoryRecordsUsed: [AgentRetrievedMemory]
    public let decisionFactors: [AgentDecisionFactor]
    public let dominantFactor: AgentDecisionFactor
    public let actionChanged: Bool
    public let reason: String

    public init(
        tick: Int,
        baseAction: AgentAction,
        finalAction: AgentAction,
        baseDirection: AgentCardinalDirection?,
        finalDirection: AgentCardinalDirection?,
        memoryRecordsUsed: [AgentRetrievedMemory],
        decisionFactors: [AgentDecisionFactor],
        dominantFactor: AgentDecisionFactor,
        actionChanged: Bool,
        reason: String
    ) {
        self.tick = tick
        self.baseAction = baseAction
        self.finalAction = finalAction
        self.baseDirection = baseDirection
        self.finalDirection = finalDirection
        self.memoryRecordsUsed = memoryRecordsUsed
        self.decisionFactors = decisionFactors
        self.dominantFactor = dominantFactor
        self.actionChanged = actionChanged
        self.reason = reason
    }

    public static func == (lhs: AgentFeedbackDecisionTrace, rhs: AgentFeedbackDecisionTrace) -> Bool {
        lhs.tick == rhs.tick
            && actionsEqual(lhs.baseAction, rhs.baseAction)
            && actionsEqual(lhs.finalAction, rhs.finalAction)
            && lhs.baseDirection == rhs.baseDirection
            && lhs.finalDirection == rhs.finalDirection
            && lhs.memoryRecordsUsed == rhs.memoryRecordsUsed
            && lhs.decisionFactors == rhs.decisionFactors
            && lhs.dominantFactor == rhs.dominantFactor
            && lhs.actionChanged == rhs.actionChanged
            && lhs.reason == rhs.reason
    }
}

public enum AgentFeedbackLoop {
    public static func movementMemoryEntry(outcome: AgentMovementOutcome) -> AgentMemoryEntry? {
        switch outcome.status {
        case .notRequested:
            return nil
        case .moved:
            let direction = appliedDirection(outcome)?.rawValue ?? "unknown"
            return AgentMemoryEntry(
                tick: outcome.tick,
                type: "moved_live",
                summary: "\(outcome.agentId) moved live from \(positionText(outcome.fromPosition)) to \(positionText(outcome.toPosition)) toward \(direction)",
                importance: 0.20
            )
        case .blocked:
            let direction = outcome.requestedDirection?.rawValue ?? "unknown"
            return AgentMemoryEntry(
                tick: outcome.tick,
                type: "movement_blocked",
                summary: "\(outcome.agentId) movement blocked at \(positionText(outcome.fromPosition)) toward \(direction): \(outcome.resolutionReason)",
                importance: 0.25
            )
        }
    }

    public static func isDuplicateBlockedMemory(
        candidate: AgentMemoryEntry,
        memory: [AgentMemoryEntry],
        currentTick: Int,
        configuration: AgentFeedbackLoopConfiguration
    ) -> Bool {
        guard candidate.type == "movement_blocked" else { return false }
        return memory.contains {
            $0.type == candidate.type
                && $0.summary == candidate.summary
                && currentTick - $0.tick >= 0
                && currentTick - $0.tick <= configuration.duplicateWindowTicks
        }
    }

    public static func retrieveMovementMemories(
        memory: [AgentMemoryEntry],
        currentTick: Int,
        lastMovementOutcome: AgentMovementOutcome?,
        configuration: AgentFeedbackLoopConfiguration
    ) -> [AgentRetrievedMemory] {
        let expectedType: String?
        switch lastMovementOutcome?.status {
        case .moved?: expectedType = "moved_live"
        case .blocked?: expectedType = "movement_blocked"
        case .notRequested?, nil: expectedType = nil
        }
        return memory.compactMap { entry -> AgentRetrievedMemory? in
            guard entry.type == "movement_blocked" || entry.type == "moved_live" else { return nil }
            let age = currentTick - entry.tick
            guard age >= 1, age <= configuration.maxMemoryAgeTicks else { return nil }
            let matched = entry.tick == lastMovementOutcome?.tick && entry.type == expectedType
            return AgentRetrievedMemory(
                tick: entry.tick,
                type: entry.type,
                summary: entry.summary,
                importance: entry.importance,
                ageTicks: age,
                matchedCurrentFeedback: matched
            )
        }.sorted {
            if $0.matchedCurrentFeedback != $1.matchedCurrentFeedback {
                return $0.matchedCurrentFeedback && !$1.matchedCurrentFeedback
            }
            if $0.importance != $1.importance { return $0.importance > $1.importance }
            if $0.tick != $1.tick { return $0.tick > $1.tick }
            if $0.type != $1.type { return $0.type < $1.type }
            return $0.summary < $1.summary
        }.prefix(configuration.maxRetrievedRecords).map { $0 }
    }

    public static func adjustAction(
        agentId: String,
        tick: Int,
        position: AgentPosition,
        homePosition: AgentPosition,
        goal: AgentGoal,
        baseAction: AgentAction,
        worldObservation: AgentWorldObservation?,
        occupiedPositions: [AgentPosition],
        lastMovementOutcome: AgentMovementOutcome?,
        retrievedMemories: [AgentRetrievedMemory],
        configuration: AgentFeedbackLoopConfiguration
    ) -> AgentFeedbackDecisionTrace {
        let baseFactor = AgentDecisionFactor(
            kind: .basePolicy,
            weight: 10,
            summary: "base policy action",
            memoryTick: nil
        )
        var finalAction = baseAction
        var factors = [baseFactor]
        var used: [AgentRetrievedMemory] = []
        var reason = "base policy retained"
        let baseDirection = direction(dx: baseAction.dx, dz: baseAction.dz)
        let distanceHome = distance(position, homePosition)
        let safe = safeCandidates(
            position: position,
            observation: worldObservation,
            occupiedPositions: occupiedPositions
        )

        if goal.kind == .explore,
           baseAction.name == "move_abstract",
           lastMovementOutcome != nil,
           distanceHome >= configuration.maxExploreDistanceFromHome {
            if let candidate = bestHomeCandidate(safe, position: position, home: homePosition) {
                finalAction = movementAction(
                    tick: tick,
                    direction: candidate.direction,
                    reason: "exploration boundary redirected toward home"
                )
            } else {
                finalAction = AgentAction(
                    name: "wait",
                    reason: "exploration boundary found no safe home step",
                    tick: tick
                )
            }
            reason = finalAction.reason
            factors.append(AgentDecisionFactor(
                kind: .explorationBoundary,
                weight: 80,
                summary: reason
            ))
        } else if baseAction.name == "move_abstract",
                  let outcome = lastMovementOutcome,
                  let matched = retrievedMemories.first(where: \.matchedCurrentFeedback) {
            switch (outcome.status, goal.kind) {
            case (.blocked, .explore) where outcome.fromPosition == position:
                let blockedDirection = outcome.requestedDirection
                let alternative = cyclicDirections(after: blockedDirection).compactMap { direction in
                    safe.first { $0.direction == direction }
                }.first
                let proposedAction: AgentAction
                if let alternative {
                    proposedAction = movementAction(
                        tick: tick,
                        direction: alternative.direction,
                        reason: "feedback memory avoided \(blockedDirection?.rawValue ?? "unknown"); alternate \(alternative.direction.rawValue)"
                    )
                } else {
                    proposedAction = AgentAction(
                        name: "wait",
                        reason: "feedback memory blocked \(blockedDirection?.rawValue ?? "unknown"); no safe alternate",
                        tick: tick
                    )
                }
                if !actionsOperationallyEqual(baseAction, proposedAction) {
                    finalAction = proposedAction
                    used = [matched]
                }
            case (.blocked, .seekSafety) where outcome.fromPosition == position:
                let proposedAction: AgentAction
                if let candidate = bestHomeCandidate(safe, position: position, home: homePosition) {
                    proposedAction = movementAction(
                        tick: tick,
                        direction: candidate.direction,
                        reason: "feedback memory redirected toward home via \(candidate.direction.rawValue)"
                    )
                } else {
                    proposedAction = AgentAction(
                        name: "wait",
                        reason: "feedback memory found no safer home step",
                        tick: tick
                    )
                }
                if !actionsOperationallyEqual(baseAction, proposedAction) {
                    finalAction = proposedAction
                    used = [matched]
                }
            case (.moved, .explore) where outcome.toPosition == position:
                if let direction = appliedDirection(outcome),
                   let candidate = safe.first(where: { $0.direction == direction }),
                   distance(candidate.position, homePosition) <= configuration.maxExploreDistanceFromHome {
                    let continuedAction = movementAction(
                        tick: tick,
                        direction: direction,
                        reason: "movement success memory continued \(direction.rawValue)"
                    )
                    if !actionsOperationallyEqual(baseAction, continuedAction) {
                        finalAction = continuedAction
                        used = [matched]
                    }
                }
            default:
                break
            }
            if !used.isEmpty {
                reason = finalAction.reason
                factors.append(AgentDecisionFactor(
                    kind: .movementFeedback,
                    weight: actionsOperationallyEqual(baseAction, finalAction) ? 30 : 100,
                    summary: reason,
                    memoryTick: matched.tick
                ))
            }
        }

        let changed = !actionsOperationallyEqual(baseAction, finalAction)
        let dominant = factors.sorted {
            if $0.weight != $1.weight { return $0.weight > $1.weight }
            return $0.kind.rawValue < $1.kind.rawValue
        }[0]
        return AgentFeedbackDecisionTrace(
            tick: tick,
            baseAction: baseAction,
            finalAction: finalAction,
            baseDirection: baseDirection,
            finalDirection: direction(dx: finalAction.dx, dz: finalAction.dz),
            memoryRecordsUsed: used,
            decisionFactors: factors,
            dominantFactor: dominant,
            actionChanged: changed,
            reason: reason
        )
    }

    private struct Candidate {
        let direction: AgentCardinalDirection
        let position: AgentPosition
    }

    private static func safeCandidates(
        position: AgentPosition,
        observation: AgentWorldObservation?,
        occupiedPositions: [AgentPosition]
    ) -> [Candidate] {
        guard let observation, observation.position == position else { return [] }
        return AgentCardinalDirection.allCases.compactMap { direction in
            guard let neighbor = observation.neighbors.first(where: { $0.direction == direction }),
                  neighbor.traversable,
                  !neighbor.dangerousDrop,
                  neighbor.column.chunkReady,
                  neighbor.column.groundPresent,
                  neighbor.column.feetClear,
                  neighbor.column.headClear,
                  let step = neighbor.stepDelta,
                  (-1...1).contains(step) else { return nil }
            let target = AgentPosition(
                x: position.x + direction.dx,
                y: position.y + step,
                z: position.z + direction.dz
            )
            guard !occupiedPositions.contains(target) || target == position else { return nil }
            return Candidate(direction: direction, position: target)
        }
    }

    private static func bestHomeCandidate(
        _ candidates: [Candidate],
        position: AgentPosition,
        home: AgentPosition
    ) -> Candidate? {
        let before = distance(position, home)
        return candidates.filter { distance($0.position, home) < before }.sorted {
            let left = before - distance($0.position, home)
            let right = before - distance($1.position, home)
            if left != right { return left > right }
            return canonicalIndex($0.direction) < canonicalIndex($1.direction)
        }.first
    }

    private static func cyclicDirections(after direction: AgentCardinalDirection?) -> [AgentCardinalDirection] {
        guard let direction, let index = AgentCardinalDirection.allCases.firstIndex(of: direction) else {
            return AgentCardinalDirection.allCases
        }
        return (1...3).map { AgentCardinalDirection.allCases[(index + $0) % 4] }
    }

    private static func movementAction(
        tick: Int,
        direction: AgentCardinalDirection,
        reason: String
    ) -> AgentAction {
        AgentAction(
            name: "move_abstract",
            reason: reason,
            tick: tick,
            dx: direction.dx,
            dy: 0,
            dz: direction.dz
        )
    }

    private static func direction(dx: Int?, dz: Int?) -> AgentCardinalDirection? {
        AgentCardinalDirection.allCases.first { $0.dx == (dx ?? 0) && $0.dz == (dz ?? 0) }
    }

    private static func appliedDirection(_ outcome: AgentMovementOutcome) -> AgentCardinalDirection? {
        AgentCardinalDirection.allCases.first {
            $0.dx == outcome.appliedDX && $0.dz == outcome.appliedDZ
        }
    }

    private static func canonicalIndex(_ direction: AgentCardinalDirection) -> Int {
        AgentCardinalDirection.allCases.firstIndex(of: direction) ?? 0
    }

    private static func distance(_ lhs: AgentPosition, _ rhs: AgentPosition) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) + abs(lhs.z - rhs.z)
    }

    private static func positionText(_ position: AgentPosition) -> String {
        "(\(position.x),\(position.y),\(position.z))"
    }
}

private func actionsEqual(_ lhs: AgentAction, _ rhs: AgentAction) -> Bool {
    lhs.name == rhs.name
        && lhs.reason == rhs.reason
        && lhs.tick == rhs.tick
        && lhs.dx == rhs.dx
        && lhs.dy == rhs.dy
        && lhs.dz == rhs.dz
        && lhs.target == rhs.target
        && lhs.resource == rhs.resource
}

private func actionsOperationallyEqual(_ lhs: AgentAction, _ rhs: AgentAction) -> Bool {
    lhs.name == rhs.name
        && lhs.tick == rhs.tick
        && lhs.dx == rhs.dx
        && lhs.dy == rhs.dy
        && lhs.dz == rhs.dz
        && lhs.target == rhs.target
        && lhs.resource == rhs.resource
}
