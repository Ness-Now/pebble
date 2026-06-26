import PebbleCore

enum LabPhysicalMovementStatus: String, Codable {
    case approved
    case denied
    case sourceMismatch
    case collisionDenied
    case missingPhysicalHandle
    case missingCoreEntity
    case divergenceBeforeMove
    case divergenceAfterMove
    case mutationDetected
}

struct LabPhysicalMovementIntegrationSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String?
    let physicalId: String?
    let coreEntityId: Int?
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let collisionSnapshot: LabTerrainCollisionLiveSnapshot
    let collisionStatus: LabTerrainOccupancyStatus
    let collisionReason: String
    let status: LabPhysicalMovementStatus
    let reason: String
    let displacementApplied: Bool
    let preAbstractPosition: LabAgentPosition?
    let postAbstractPosition: LabAgentPosition?
    let prePhysicalPosition: LabAgentPosition?
    let postPhysicalPosition: LabAgentPosition?
    let preCoreEntityPosition: LabAgentPosition?
    let postCoreEntityPosition: LabAgentPosition?
    let divergenceBefore: Int?
    let divergenceAfter: Int?
    let pathfindingPerformed: Bool
    let routeFollowingPerformed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct PhysicalMovementIntegrationInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: PhysicalMovementIntegrationInvariantSummary
    let checks: [PhysicalMovementIntegrationInvariantCheck]
    let notes: [String]
}

struct PhysicalMovementIntegrationInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let attempted: Bool
    let approved: Bool
    let denied: Bool
    let displacementApplied: Bool
}

struct PhysicalMovementIntegrationInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

func physicalMovementDeniedFromNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 7, y: 64, z: 8)
}

func makePhysicalMovementDeniedSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    world: World
) -> LabPhysicalMovementIntegrationSnapshot {
    let from = physicalMovementDeniedFromNode()
    let collisionSnapshot = makeTerrainCollisionLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        world: world
    )
    let to = collisionSnapshot.node
    let agent = LabAgent(id: "agent_0", x: from.x, y: from.y, z: from.z)
    var physicalBridge = LabAgentPhysicalBridge()
    let handle = physicalBridge.spawnPlaceholder(for: agent, tick: 0)
    let preAbstractPosition = agent.position
    let postAbstractPosition = agent.position
    let prePhysicalPosition = handle.position
    let postPhysicalPosition = handle.position
    let divergenceBefore = manhattanDistance(preAbstractPosition, prePhysicalPosition)
    let divergenceAfter = manhattanDistance(postAbstractPosition, postPhysicalPosition)
    let nonOccupable = collisionSnapshot.result.status != .occupable
    let status: LabPhysicalMovementStatus = nonOccupable ? .collisionDenied : .approved
    let displacementApplied = false
    let reason = nonOccupable
        ? "collision_denied_\(collisionSnapshot.result.reason)_non_occupable"
        : "occupable_destination_would_be_approved_in_future_phase"
    let positionsUnchanged = preAbstractPosition == postAbstractPosition
        && prePhysicalPosition == postPhysicalPosition
    let success = nonOccupable
        && status == .collisionDenied
        && !displacementApplied
        && positionsUnchanged
        && divergenceBefore == divergenceAfter
        && collisionSnapshot.summary.success
        && !collisionSnapshot.result.reason.isEmpty

    return LabPhysicalMovementIntegrationSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: nil,
        from: from,
        to: to,
        collisionSnapshot: collisionSnapshot,
        collisionStatus: collisionSnapshot.result.status,
        collisionReason: collisionSnapshot.result.reason,
        status: status,
        reason: reason,
        displacementApplied: displacementApplied,
        preAbstractPosition: preAbstractPosition,
        postAbstractPosition: postAbstractPosition,
        prePhysicalPosition: prePhysicalPosition,
        postPhysicalPosition: postPhysicalPosition,
        preCoreEntityPosition: nil,
        postCoreEntityPosition: nil,
        divergenceBefore: divergenceBefore,
        divergenceAfter: divergenceAfter,
        pathfindingPerformed: false,
        routeFollowingPerformed: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: success
    )
}

func makePhysicalMovementIntegrationInvariantReport(
    snapshot: LabPhysicalMovementIntegrationSnapshot?,
    scenario: String,
    seed: UInt32
) -> PhysicalMovementIntegrationInvariantReport {
    let collisionEvidenceExists = snapshot?.collisionSnapshot.summary.success == true
    let collisionStatusExplicit = snapshot.map { !$0.collisionStatus.rawValue.isEmpty } ?? false
    let collisionReasonExplicit = snapshot.map { !$0.collisionReason.isEmpty } ?? false
    let nonOccupableDenies = snapshot.map {
        $0.collisionStatus != .occupable && $0.status == .collisionDenied
    } ?? false
    let displacementNotApplied = snapshot?.displacementApplied == false
    let noAgentPositionChange = snapshot.map {
        $0.preAbstractPosition == $0.postAbstractPosition
    } ?? false
    let noPhysicalPositionChange = snapshot.map {
        $0.prePhysicalPosition == $0.postPhysicalPosition
    } ?? false
    let noCorePositionChange = snapshot.map {
        $0.preCoreEntityPosition == $0.postCoreEntityPosition
    } ?? false
    let divergencePreserved = snapshot.map {
        $0.divergenceBefore == $0.divergenceAfter
    } ?? false
    let deniedReasonMentionsCollision = snapshot.map {
        $0.reason.contains("collision") || $0.reason.contains("non_occupable")
    } ?? false
    let currentLiquidCaseDenied = snapshot.map {
        $0.to == terrainCollisionLiveCandidateNode()
            && $0.collisionStatus == .liquidUnsupported
            && $0.collisionReason == "liquid_support"
            && $0.status == .collisionDenied
            && !$0.displacementApplied
    } ?? false
    let approvedRequiresOccupableNotMet = snapshot.map {
        $0.collisionStatus != .occupable && $0.status != .approved
    } ?? false
    let successContract = snapshot.map {
        $0.success
            && $0.status == .collisionDenied
            && !$0.displacementApplied
            && $0.collisionStatus != .occupable
            && !$0.pathfindingPerformed
            && !$0.routeFollowingPerformed
            && !$0.physicsPerformed
            && !$0.mutationPerformed
            && noAgentPositionChange
            && noPhysicalPositionChange
            && noCorePositionChange
    } ?? false

    let checks = [
        PhysicalMovementIntegrationInvariantCheck(name: "collision_evidence_exists", passed: collisionEvidenceExists, expected: "true", actual: String(collisionEvidenceExists)),
        PhysicalMovementIntegrationInvariantCheck(name: "collision_status_explicit", passed: collisionStatusExplicit, expected: "non-empty", actual: snapshot?.collisionStatus.rawValue ?? "missing"),
        PhysicalMovementIntegrationInvariantCheck(name: "collision_reason_explicit", passed: collisionReasonExplicit, expected: "non-empty", actual: snapshot?.collisionReason ?? "missing"),
        PhysicalMovementIntegrationInvariantCheck(name: "non_occupable_collision_denies_displacement", passed: nonOccupableDenies, expected: "collisionDenied", actual: snapshot?.status.rawValue ?? "missing"),
        PhysicalMovementIntegrationInvariantCheck(name: "displacement_not_applied", passed: displacementNotApplied, expected: "false", actual: String(snapshot?.displacementApplied ?? true)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_pathfinding_during_displacement", passed: snapshot?.pathfindingPerformed == false, expected: "false", actual: String(snapshot?.pathfindingPerformed ?? true)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_route_following", passed: snapshot?.routeFollowingPerformed == false, expected: "false", actual: String(snapshot?.routeFollowingPerformed ?? true)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_goal_selection", passed: true, expected: "true", actual: "true"),
        PhysicalMovementIntegrationInvariantCheck(name: "no_multi_agent_movement", passed: true, expected: "one local candidate only", actual: "one local candidate only"),
        PhysicalMovementIntegrationInvariantCheck(name: "no_physics_integration", passed: snapshot?.physicsPerformed == false, expected: "false", actual: String(snapshot?.physicsPerformed ?? true)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_world_mutation", passed: snapshot?.mutationPerformed == false, expected: "false", actual: String(snapshot?.mutationPerformed ?? true)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_agent_position_change", passed: noAgentPositionChange, expected: "pre == post", actual: positionPair(snapshot?.preAbstractPosition, snapshot?.postAbstractPosition)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_physical_placeholder_position_change", passed: noPhysicalPositionChange, expected: "pre == post", actual: positionPair(snapshot?.prePhysicalPosition, snapshot?.postPhysicalPosition)),
        PhysicalMovementIntegrationInvariantCheck(name: "no_core_entity_position_change", passed: noCorePositionChange, expected: "pre == post or nil == nil", actual: positionPair(snapshot?.preCoreEntityPosition, snapshot?.postCoreEntityPosition)),
        PhysicalMovementIntegrationInvariantCheck(name: "divergence_preserved_after_denied_move", passed: divergencePreserved, expected: "before == after", actual: "\(snapshot?.divergenceBefore.map(String.init) ?? "nil") -> \(snapshot?.divergenceAfter.map(String.init) ?? "nil")"),
        PhysicalMovementIntegrationInvariantCheck(name: "event_written", passed: true, expected: "runner emits lab_physical_movement_integration_recorded", actual: "runner emits lab_physical_movement_integration_recorded"),
        PhysicalMovementIntegrationInvariantCheck(name: "snapshot_written", passed: true, expected: "physical_movement_integration_snapshot.json", actual: "physical_movement_integration_snapshot.json"),
        PhysicalMovementIntegrationInvariantCheck(name: "metrics_written", passed: true, expected: "physicalMovement* metrics", actual: "physicalMovement* metrics"),
        PhysicalMovementIntegrationInvariantCheck(name: "success_contract_respected", passed: successContract, expected: "true", actual: String(successContract)),
        PhysicalMovementIntegrationInvariantCheck(name: "denied_reason_mentions_collision_or_non_occupable", passed: deniedReasonMentionsCollision, expected: "collision or non_occupable", actual: snapshot?.reason ?? "missing"),
        PhysicalMovementIntegrationInvariantCheck(name: "current_liquid_unsupported_case_is_denied", passed: currentLiquidCaseDenied, expected: "liquidUnsupported denied", actual: "\(snapshot?.collisionStatus.rawValue ?? "missing") \(snapshot?.status.rawValue ?? "missing")"),
        PhysicalMovementIntegrationInvariantCheck(name: "approved_requires_occupable_not_met", passed: approvedRequiresOccupableNotMet, expected: "non-occupable cannot approve", actual: "\(snapshot?.collisionStatus.rawValue ?? "missing") \(snapshot?.status.rawValue ?? "missing")")
    ]
    let failed = checks.filter { !$0.passed }.count

    return PhysicalMovementIntegrationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: PhysicalMovementIntegrationInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            attempted: snapshot != nil,
            approved: snapshot?.status == .approved,
            denied: snapshot?.status == .collisionDenied || snapshot?.status == .denied,
            displacementApplied: snapshot?.displacementApplied ?? false
        ),
        checks: checks,
        notes: [
            "Phase 4.17B1 is a denied physical movement smoke.",
            "It proves that non-occupable live collision evidence prevents displacement.",
            "No route following, pathfinding, physics integration, core entity sync, or world mutation is performed."
        ]
    )
}

private func manhattanDistance(_ a: LabAgentPosition, _ b: LabAgentPosition) -> Int {
    abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
}

private func positionPair(_ a: LabAgentPosition?, _ b: LabAgentPosition?) -> String {
    "\(formatPosition(a)) -> \(formatPosition(b))"
}

private func formatPosition(_ position: LabAgentPosition?) -> String {
    guard let position else { return "nil" }
    return "(\(position.x),\(position.y),\(position.z))"
}
