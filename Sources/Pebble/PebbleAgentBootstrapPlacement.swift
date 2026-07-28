import PebbleAgents
import PebbleCore

struct PebbleAgentBootstrapPlacementPlan {
    static let agentIDs = ["agent_0", "agent_1", "agent_2"]

    let positionsByAgentID: [String: AgentPosition]
    let candidatesEvaluated: Int
    let maximumCandidateEvaluations: Int
    let rejectionCounts: [EntityPlacementRejection: Int]

    var traceSummary: String {
        let positions = Self.agentIDs.compactMap { id in
            positionsByAgentID[id].map { position in
                "\(id):\(position.x),\(position.y),\(position.z)"
            }
        }.joined(separator: ";")
        let rejections = rejectionCounts.keys.sorted { $0.rawValue < $1.rawValue }
            .map { "\($0.rawValue)=\(rejectionCounts[$0] ?? 0)" }
            .joined(separator: ",")
        return "positions=\(positions) candidates=\(candidatesEvaluated)"
            + "/\(maximumCandidateEvaluations) rejections="
            + (rejections.isEmpty ? "none" : rejections)
    }
}

struct PebbleAgentBootstrapPlacementResolver {
    enum ResolutionError: Error {
        case insufficientSafePositions(
            found: Int,
            required: Int,
            candidates: Int,
            maximumCandidates: Int,
            rejections: String
        )
    }

    static let configuration = BoundedEntityPlacementSearchConfiguration(
        requiredCount: PebbleAgentBootstrapPlacementPlan.agentIDs.count,
        horizontalRadius: 12,
        verticalRadius: 8,
        maximumCandidateEvaluations: 12_000,
        bodyWidth: 0.6,
        bodyHeight: 1.8,
        minimumSelectedHorizontalDistance: 1,
        minimumReservedHorizontalDistance: 2,
        minimumEgressCount: 1,
        maximumSafeDrop: 1
    )

    func resolve(
        world: World,
        anchor: AgentPosition,
        player: Player,
        socialEnabled: Bool
    ) throws -> PebbleAgentBootstrapPlacementPlan {
        let recipient = socialEnabled
            ? AgentPosition(x: anchor.x + 8, y: anchor.y, z: anchor.z - 3)
            : AgentPosition(x: anchor.x + 2, y: anchor.y, z: anchor.z)
        let preferred = [
            AgentPosition(x: anchor.x + 6, y: anchor.y, z: anchor.z - 3),
            AgentPosition(x: anchor.x + 7, y: anchor.y, z: anchor.z - 3),
            recipient,
        ]
        let result = findSafeEntityPlacements(
            in: world,
            anchor: corePosition(anchor),
            preferredPositions: preferred.map(corePosition),
            reservedPoints: [EntityPlacementReservedPoint(
                x: player.x,
                y: player.y,
                z: player.z
            )],
            configuration: Self.configuration
        )
        let rejectionSummary = result.rejectionCounts.keys
            .sorted { $0.rawValue < $1.rawValue }
            .map { "\($0.rawValue)=\(result.rejectionCounts[$0] ?? 0)" }
            .joined(separator: ",")
        guard result.isComplete else {
            throw ResolutionError.insufficientSafePositions(
                found: result.positions.count,
                required: result.requiredCount,
                candidates: result.candidatesEvaluated,
                maximumCandidates: result.maximumCandidateEvaluations,
                rejections: rejectionSummary.isEmpty ? "none" : rejectionSummary
            )
        }
        let positions = Dictionary(uniqueKeysWithValues: zip(
            PebbleAgentBootstrapPlacementPlan.agentIDs,
            result.positions.map(agentPosition)
        ))
        return PebbleAgentBootstrapPlacementPlan(
            positionsByAgentID: positions,
            candidatesEvaluated: result.candidatesEvaluated,
            maximumCandidateEvaluations: result.maximumCandidateEvaluations,
            rejectionCounts: result.rejectionCounts
        )
    }

    private func corePosition(_ position: AgentPosition) -> EntityPlacementPosition {
        EntityPlacementPosition(x: position.x, y: position.y, z: position.z)
    }

    private func agentPosition(_ position: EntityPlacementPosition) -> AgentPosition {
        AgentPosition(x: position.x, y: position.y, z: position.z)
    }
}
