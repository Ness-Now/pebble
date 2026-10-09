/// Prospective bounded proposal memory. This is not a physical path proof or
/// another navigation owner. Session derives it from the current observations
/// using its existing planner and movement admission contract. Historical
/// observations omit it, so schemas 44/45/46 and old replay inputs are unchanged.
public struct AgentCareNavigationProposal: Codable, Equatable {
    public let version: Int
    public let contextDigest: String
    public let intentDigest: String?
    public let progressDigest: String
    public let attemptedIntentDigests: [String]
    public static let maximumDistinctAttempts = 4

    private enum CodingKeys: String, CodingKey { case version, contextDigest, intentDigest, progressDigest, attemptedIntentDigests }

    private init(version: Int, contextDigest: String, intentDigest: String?, progressDigest: String, attemptedIntentDigests: [String]) {
        self.version = version; self.contextDigest = contextDigest; self.intentDigest = intentDigest
        self.progressDigest = progressDigest
        self.attemptedIntentDigests = attemptedIntentDigests
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .version)
        let context = try values.decode(String.self, forKey: .contextDigest)
        let intent = try values.decodeIfPresent(String.self, forKey: .intentDigest)
        let progress = try values.decode(String.self, forKey: .progressDigest)
        let attempted = try values.decode([String].self, forKey: .attemptedIntentDigests)
        func valid(_ digest: String) -> Bool {
            (1...16).contains(digest.utf8.count) && digest.utf8.allSatisfy {
                (48...57).contains($0) || (97...102).contains($0)
            }
        }
        guard version == 1, valid(context), intent.map(valid) ?? true, valid(progress), attempted.count <= Self.maximumDistinctAttempts,
              attempted.allSatisfy(valid), Set(attempted).count == attempted.count else {
            throw DecodingError.dataCorruptedError(forKey: .version, in: values,
                debugDescription: "invalid bounded care proposal memory")
        }
        self.init(version: version, contextDigest: context, intentDigest: intent, progressDigest: progress, attemptedIntentDigests: attempted)
    }

    public static func observe(
        navigation: AgentNavigationObservation,
        world: AgentWorldObservation,
        goalMode: AgentNavigationGoalMode = .cardinalAdjacent,
        previous: AgentCareNavigationProposal?
    ) -> (observation: Self, plan: AgentNavigationPlan?) {
        let progress = digest([position(navigation.origin), position(navigation.target), goalMode.rawValue])
        let attempted = previous?.progressDigest == progress ? previous!.attemptedIntentDigests : []
        let context = digest([
            position(navigation.origin), position(navigation.target),
            String(navigation.radius), goalMode.rawValue,
            world.physicalMovementAssessmentVersion.map(String.init) ?? "historical",
            String(world.position == navigation.origin && world.worldTick == navigation.worldTick),
            world.physicalReadinessContextDigest,
            navigation.cells.map {
                position($0.position) + ":" + $0.status.rawValue
            }.sorted().joined(separator: ";")
        ])
        if let previous, previous.version == 1, previous.contextDigest == context {
            return (previous, nil)
        }
        let plan = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
            start: navigation.origin, target: navigation.target,
            goalMode: goalMode, cells: navigation.cells,
            radius: navigation.radius,
            maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
            maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
        ))
        var identity: String?
        if world.physicalMovementAssessmentVersion == 1,
           world.position == navigation.origin,
           world.worldTick == navigation.worldTick,
           plan.found, plan.positions.count > 1 {
            let next = plan.positions[1]
            let dx = next.x - navigation.origin.x
            let dy = next.y - navigation.origin.y
            let dz = next.z - navigation.origin.z
            if abs(dx) + abs(dz) == 1,
               let neighbor = world.neighbors.first(where: {
                   $0.direction.dx == dx && $0.direction.dz == dz
               }), AgentMovementCoordinator.terrainRefusal(neighbor: neighbor, requestedDY: dy) == nil {
                identity = digest([
                    position(navigation.target),
                    plan.positions.map(position).joined(separator: ";"),
                    world.physicalCoverageDigest ?? "unspecified"
                ])
            }
        }
        return (Self(version: 1, contextDigest: context, intentDigest: identity,
                     progressDigest: progress, attemptedIntentDigests: attempted), plan)
    }

    /// The same admissible intent gets one bounded episode, even if blocked
    /// observations temporarily intervene. Unknown readiness never erases it.
    /// At most four distinct episodes at one physical origin/target; verified
    /// progress or a new target opens a new context. Replan/cooldown limits
    /// remain unchanged within each episode. This also bounds A/B/A churn.
    public func refreshesExhaustedBudget(
        progress: AgentNavigationProgress, tick: Int, maximumReplans: Int, cooldown: Int
    ) -> Bool {
        guard let last = progress.lastPlanTick, let intent = intentDigest,
              progress.status == .failed || progress.route == nil || progress.consecutiveBlockedMoves > 0
        else { return false }
        return progress.replanCount >= maximumReplans && tick - last >= cooldown
            && !attemptedIntentDigests.contains(intent)
            && attemptedIntentDigests.count < Self.maximumDistinctAttempts
    }

    public func recordingAttempt() -> Self {
        var attempted = attemptedIntentDigests
        if let intent = intentDigest, !attempted.contains(intent), attempted.count < Self.maximumDistinctAttempts {
            attempted.append(intent)
        }
        return Self(version: version, contextDigest: contextDigest, intentDigest: intentDigest,
                    progressDigest: progressDigest, attemptedIntentDigests: attempted)
    }

    private static func position(_ position: AgentPosition) -> String {
        "\(position.x):\(position.y):\(position.z)"
    }

    private static func digest(_ values: [String]) -> String {
        var hash: UInt64 = 1469598103934665603
        for value in values {
            for byte in value.utf8 { hash ^= UInt64(byte); hash &*= 1099511628211 }
            hash ^= 0xff; hash &*= 1099511628211
        }
        return String(hash, radix: 16)
    }
}
