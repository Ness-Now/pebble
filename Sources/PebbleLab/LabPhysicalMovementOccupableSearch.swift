import PebbleCore

struct LabPhysicalMovementOccupableCandidate: Codable {
    let index: Int
    let seed: UInt32
    let node: LabTerrainPathNodeKey
    let collisionSnapshot: LabTerrainCollisionLiveSnapshot
    let status: LabTerrainOccupancyStatus
    let reason: String
    let selected: Bool
}

struct LabPhysicalMovementOccupableSearchSummary: Codable {
    let candidatesEvaluated: Int
    let occupableFound: Bool
    let selectedCandidateIndex: Int?
    let selectedSeed: UInt32?
    let selectedNode: LabTerrainPathNodeKey?
    let selectedStatus: LabTerrainOccupancyStatus?
    let movementPerformed: Bool
    let agentDisplaced: Bool
    let physicalPlaceholderDisplaced: Bool
    let coreEntityDisplaced: Bool
    let pathfindingPerformed: Bool
    let routeFollowingPerformed: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabPhysicalMovementOccupableSearchSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let strategy: String
    let candidates: [LabPhysicalMovementOccupableCandidate]
    let summary: LabPhysicalMovementOccupableSearchSummary
}

struct PhysicalMovementOccupableSearchInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: PhysicalMovementOccupableSearchInvariantSummary
    let checks: [PhysicalMovementOccupableSearchInvariantCheck]
    let notes: [String]
}

struct PhysicalMovementOccupableSearchInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let candidatesEvaluated: Int
    let occupableFound: Bool
    let selectedCandidateIndex: Int?
}

struct PhysicalMovementOccupableSearchInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private struct PhysicalMovementOccupableSearchPlan: Equatable {
    let seed: UInt32
    let node: LabTerrainPathNodeKey
}

private func physicalMovementOccupableSearchPlans(seed: UInt32) -> [PhysicalMovementOccupableSearchPlan] {
    [
        PhysicalMovementOccupableSearchPlan(
            seed: seed,
            node: terrainCollisionLiveCandidateNode()
        ),
        PhysicalMovementOccupableSearchPlan(
            seed: 99,
            node: terrainCollisionLiveCandidateNode()
        ),
        PhysicalMovementOccupableSearchPlan(
            seed: 99,
            node: LabTerrainPathNodeKey(x: 9, y: 64, z: 8)
        )
    ]
}

private func preparePhysicalMovementOccupableSearchWorld(
    seed: UInt32,
    around node: LabTerrainPathNodeKey
) -> World {
    let world = World(dim: .overworld, seed: seed)
    let centerCX = floorDiv(node.x, CHUNK_W)
    let centerCZ = floorDiv(node.z, CHUNK_W)

    for cz in (centerCZ - 1)...(centerCZ + 1) {
        for cx in (centerCX - 1)...(centerCX + 1) {
            let generated = generateChunk(.overworld, world.seed, cx, cz)
            let chunk = Chunk(cx: cx, cz: cz, minY: world.info.minY, height: world.info.height)
            chunk.blocks = generated.blocks
            chunk.biomes = generated.biomes
            chunk.buildHeightmap()
            chunk.scanSpecials()
            world.setChunk(chunk)
            world.light.initChunkLight(chunk)
        }
    }
    return world
}

func makePhysicalMovementOccupableSearchSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    world: World
) -> LabPhysicalMovementOccupableSearchSnapshot {
    let plans = physicalMovementOccupableSearchPlans(seed: seed)
    let rawCandidates = plans.map { plan in
        let candidateWorld = plan.seed == seed
            ? world
            : preparePhysicalMovementOccupableSearchWorld(
                seed: plan.seed,
                around: plan.node
            )
        return makeTerrainCollisionLiveSnapshot(
            scenario: scenario,
            seed: plan.seed,
            ticksCompleted: ticksCompleted,
            world: candidateWorld,
            node: plan.node
        )
    }
    let selectedIndex = rawCandidates.firstIndex {
        $0.result.status == .occupable
    }
    let candidates = rawCandidates.enumerated().map { index, collisionSnapshot in
        LabPhysicalMovementOccupableCandidate(
            index: index,
            seed: collisionSnapshot.seed,
            node: collisionSnapshot.node,
            collisionSnapshot: collisionSnapshot,
            status: collisionSnapshot.result.status,
            reason: collisionSnapshot.result.reason,
            selected: index == selectedIndex
        )
    }
    let selected = selectedIndex.map { candidates[$0] }
    let movementPerformed = false
    let agentDisplaced = false
    let physicalPlaceholderDisplaced = false
    let coreEntityDisplaced = false
    let pathfindingPerformed = false
    let routeFollowingPerformed = false
    let physicsPerformed = false
    let mutationPerformed = false
    let success = selected?.status == .occupable
        && !movementPerformed
        && !agentDisplaced
        && !physicalPlaceholderDisplaced
        && !coreEntityDisplaced
        && !pathfindingPerformed
        && !routeFollowingPerformed
        && !physicsPerformed
        && !mutationPerformed

    return LabPhysicalMovementOccupableSearchSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        strategy: "bounded_multi_seed_known_live_collision_candidates_deterministic_order",
        candidates: candidates,
        summary: LabPhysicalMovementOccupableSearchSummary(
            candidatesEvaluated: candidates.count,
            occupableFound: selected != nil,
            selectedCandidateIndex: selected?.index,
            selectedSeed: selected?.seed,
            selectedNode: selected?.node,
            selectedStatus: selected?.status,
            movementPerformed: movementPerformed,
            agentDisplaced: agentDisplaced,
            physicalPlaceholderDisplaced: physicalPlaceholderDisplaced,
            coreEntityDisplaced: coreEntityDisplaced,
            pathfindingPerformed: pathfindingPerformed,
            routeFollowingPerformed: routeFollowingPerformed,
            physicsPerformed: physicsPerformed,
            mutationPerformed: mutationPerformed,
            success: success
        )
    )
}

func makePhysicalMovementOccupableSearchInvariantReport(
    snapshot: LabPhysicalMovementOccupableSearchSnapshot?,
    scenario: String,
    seed: UInt32
) -> PhysicalMovementOccupableSearchInvariantReport {
    let candidates = snapshot?.candidates ?? []
    let expectedPlans = physicalMovementOccupableSearchPlans(seed: seed)
    let selected = candidates.first(where: \.selected)
    let selectedIndex = selected?.index
    let firstOccupableIndex = candidates.firstIndex { $0.status == .occupable }
    let explicitStatuses = !candidates.isEmpty
        && candidates.allSatisfy { !$0.status.rawValue.isEmpty }
    let explicitReasons = !candidates.isEmpty
        && candidates.allSatisfy { !$0.reason.isEmpty }
    let coordinatesPreserved = !candidates.isEmpty
        && candidates.allSatisfy { candidate in
            candidate.node == candidate.collisionSnapshot.node
                && candidate.collisionSnapshot.fixture.x == candidate.node.x
                && candidate.collisionSnapshot.fixture.y == candidate.node.y
                && candidate.collisionSnapshot.fixture.z == candidate.node.z
        }
    let noMovement = snapshot?.summary.movementPerformed == false
    let noAgent = snapshot?.summary.agentDisplaced == false
    let noPhysical = snapshot?.summary.physicalPlaceholderDisplaced == false
    let noCore = snapshot?.summary.coreEntityDisplaced == false
    let noPathfinding = snapshot?.summary.pathfindingPerformed == false
    let noRoute = snapshot?.summary.routeFollowingPerformed == false
    let noPhysics = snapshot?.summary.physicsPerformed == false
    let noMutation = snapshot?.summary.mutationPerformed == false
    let liveCollisionReused = !candidates.isEmpty
        && candidates.allSatisfy {
            $0.collisionSnapshot.result.source == "live_readonly_fixture_adapter"
        }
    let candidatePlans = candidates.map {
        PhysicalMovementOccupableSearchPlan(seed: $0.seed, node: $0.node)
    }
    let deterministicOrder = candidatePlans == expectedPlans
    let defaultScenarioPreserved = terrainCollisionLiveCandidateNode()
        == LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
        && expectedPlans.first?.node == terrainCollisionLiveCandidateNode()
    let successContract = snapshot?.summary.success == true
        && snapshot?.summary.occupableFound == true
        && selected?.status == .occupable
        && selectedIndex == firstOccupableIndex
        && noMovement
        && noAgent
        && noPhysical
        && noCore
        && noPathfinding
        && noRoute
        && noPhysics
        && noMutation

    let checks = [
        PhysicalMovementOccupableSearchInvariantCheck(name: "candidate_list_non_empty", passed: !candidates.isEmpty, expected: "> 0", actual: "\(candidates.count)"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "candidate_list_bounded", passed: candidates.count <= 16, expected: "<= 16", actual: "\(candidates.count)"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "candidate_order_deterministic", passed: deterministicOrder, expected: "seed/node plan order", actual: candidates.map { "\($0.seed):(\($0.node.x),\($0.node.y),\($0.node.z))" }.joined(separator: " ")),
        PhysicalMovementOccupableSearchInvariantCheck(name: "each_candidate_has_collision_snapshot", passed: candidates.count == snapshot?.summary.candidatesEvaluated, expected: "one snapshot per candidate", actual: "\(candidates.count)/\(snapshot?.summary.candidatesEvaluated ?? -1)"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "each_candidate_has_explicit_status", passed: explicitStatuses, expected: "non-empty status", actual: candidates.map(\.status.rawValue).joined(separator: ",")),
        PhysicalMovementOccupableSearchInvariantCheck(name: "each_candidate_has_explicit_reason", passed: explicitReasons, expected: "non-empty reason", actual: candidates.map(\.reason).joined(separator: ",")),
        PhysicalMovementOccupableSearchInvariantCheck(name: "selected_candidate_exists", passed: selected != nil, expected: "present", actual: selectedIndex.map(String.init) ?? "nil"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "selected_candidate_is_occupable", passed: selected?.status == .occupable, expected: "occupable", actual: selected?.status.rawValue ?? "missing"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "selected_candidate_is_first_occupable", passed: selectedIndex == firstOccupableIndex, expected: firstOccupableIndex.map(String.init) ?? "nil", actual: selectedIndex.map(String.init) ?? "nil"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "selected_candidate_coordinates_preserved", passed: coordinatesPreserved && selected?.node == snapshot?.summary.selectedNode, expected: "candidate == collision snapshot == summary", actual: selected.map { "(\($0.node.x),\($0.node.y),\($0.node.z))" } ?? "missing"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_movement_performed", passed: noMovement, expected: "false", actual: String(snapshot?.summary.movementPerformed ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_agent_displaced", passed: noAgent, expected: "false", actual: String(snapshot?.summary.agentDisplaced ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_physical_placeholder_displaced", passed: noPhysical, expected: "false", actual: String(snapshot?.summary.physicalPlaceholderDisplaced ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_core_entity_displaced", passed: noCore, expected: "false", actual: String(snapshot?.summary.coreEntityDisplaced ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_pathfinding_invoked", passed: noPathfinding, expected: "false", actual: String(snapshot?.summary.pathfindingPerformed ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_route_following", passed: noRoute, expected: "false", actual: String(snapshot?.summary.routeFollowingPerformed ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_physics_integration", passed: noPhysics, expected: "false", actual: String(snapshot?.summary.physicsPerformed ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_world_mutation", passed: noMutation, expected: "false", actual: String(snapshot?.summary.mutationPerformed ?? true)),
        PhysicalMovementOccupableSearchInvariantCheck(name: "no_terrain_mutation", passed: noMutation && candidates.allSatisfy { $0.collisionSnapshot.support.chunkStateUnchanged && $0.collisionSnapshot.feet.chunkStateUnchanged && $0.collisionSnapshot.head.chunkStateUnchanged }, expected: "false and unchanged samples", actual: "mutation=\(snapshot?.summary.mutationPerformed ?? true)"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "live_collision_readonly_reused", passed: liveCollisionReused, expected: "live_readonly_fixture_adapter", actual: candidates.map(\.collisionSnapshot.result.source).joined(separator: ",")),
        PhysicalMovementOccupableSearchInvariantCheck(name: "terrain_collision_live_default_scenario_preserved", passed: defaultScenarioPreserved, expected: "(8,64,8) default first", actual: "\(terrainCollisionLiveCandidateNode())"),
        PhysicalMovementOccupableSearchInvariantCheck(name: "success_contract_respected", passed: successContract, expected: "true", actual: String(successContract))
    ]
    let failed = checks.filter { !$0.passed }.count

    return PhysicalMovementOccupableSearchInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: PhysicalMovementOccupableSearchInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            candidatesEvaluated: candidates.count,
            occupableFound: snapshot?.summary.occupableFound ?? false,
            selectedCandidateIndex: selectedIndex
        ),
        checks: checks,
        notes: [
            "Phase 4.17B2A finds a future destination only; it applies no physical movement.",
            "Every candidate is evaluated through the live read-only collision adapter and fixture evaluator.",
            "The selected node is the first occupable candidate in a bounded deterministic list."
        ]
    )
}
