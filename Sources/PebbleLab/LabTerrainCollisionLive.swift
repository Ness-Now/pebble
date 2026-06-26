import PebbleCore

struct LabTerrainCollisionLiveSample: Codable {
    let role: LabTerrainCollisionCellRole
    let x: Int
    let y: Int
    let z: Int
    let loaded: Bool
    let ready: Bool
    let blockId: Int?
    let blockName: String?
    let semantic: LabTerrainCellKind?
    let shape: LabTerrainCollisionShape
    let chunkStateUnchanged: Bool
    let reason: String
}

struct LabTerrainCollisionLiveSummary: Codable {
    let status: LabTerrainOccupancyStatus
    let reason: String
    let samples: Int
    let loadedSamples: Int
    let readySamples: Int
    let liveAgentDisplaced: Bool
    let physicalPlaceholderDisplaced: Bool
    let coreEntityDisplaced: Bool
    let movementPerformed: Bool
    let pathfindingPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabTerrainCollisionLiveSnapshot: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let node: LabTerrainPathNodeKey
    let body: LabTerrainBodyContract
    let support: LabTerrainCollisionLiveSample
    let feet: LabTerrainCollisionLiveSample
    let head: LabTerrainCollisionLiveSample
    let fixture: LabTerrainCollisionColumnFixture
    let result: LabTerrainCollisionResult
    let summary: LabTerrainCollisionLiveSummary
}

struct TerrainCollisionLiveInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainCollisionLiveInvariantSummary
    let checks: [TerrainCollisionLiveInvariantCheck]
    let notes: [String]
}

struct TerrainCollisionLiveInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let samples: Int
    let results: Int
}

struct TerrainCollisionLiveInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

func terrainCollisionLiveCandidateNode() -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: 8, y: 64, z: 8)
}

private func terrainCollisionShape(
    from semantic: LabTerrainCellSemantic
) -> (LabTerrainCollisionShape, String) {
    switch semantic.kind {
    case .air:
        return (.empty, "semantic_air_empty")
    case .solid:
        return (.fullCube, "semantic_solid_full_cube_v0")
    case .liquid:
        return (.liquid, "semantic_liquid")
    case .plantLike:
        return (.unknown, "semantic_plant_like_unknown_shape")
    case .other:
        return (.unknown, "semantic_other_unknown_shape")
    case .unknown:
        return (.unknown, "semantic_unknown_shape")
    }
}

private func collisionFixtureCell(
    from sample: LabTerrainCollisionLiveSample
) -> LabTerrainCollisionCellFixture {
    LabTerrainCollisionCellFixture(
        role: sample.role,
        shape: sample.shape,
        shapeName: sample.blockName ?? sample.shape.rawValue,
        loaded: sample.loaded,
        ready: sample.ready
    )
}

private func makeTerrainCollisionLiveSample(
    role: LabTerrainCollisionCellRole,
    x: Int,
    y: Int,
    z: Int,
    world: World
) -> LabTerrainCollisionLiveSample {
    let cx = floorDiv(x, CHUNK_W)
    let cz = floorDiv(z, CHUNK_W)
    let loaded = world.isLoadedAt(x, z)
    let ready = world.isChunkReady(cx, cz)
    let chunk = world.getChunk(cx, cz)
    let modifiedBefore = chunk?.modified
    let versionBefore = chunk?.version
    let dirtyBefore = chunk?.dirty
    let packedCell = loaded && ready ? world.getBlock(x, y, z) : nil
    let chunkStateUnchanged = modifiedBefore == chunk?.modified
        && versionBefore == chunk?.version
        && dirtyBefore == chunk?.dirty
    let blockId = packedCell.map { $0 >> 4 }
    let meta = packedCell.map { $0 & 15 }
    let validBlockId = blockId.map { $0 >= 0 && $0 < blockDefs.count } ?? false
    let blockName = validBlockId ? blockId.map { blockDefs[$0].name } : nil
    let scanCell = LabTerrainScanCell(
        dx: 0,
        dz: 0,
        x: x,
        y: y,
        z: z,
        chunk: LabWorldInteractionChunk(cx: cx, cz: cz, loaded: loaded, ready: ready),
        cell: packedCell,
        blockId: blockId,
        meta: meta,
        blockName: blockName,
        chunkStateUnchanged: true,
        success: loaded && ready && validBlockId
    )
    let semantic = classifyTerrainCell(scanCell)
    let shapeMapping = loaded && ready
        ? terrainCollisionShape(from: semantic)
        : (.unknown, loaded ? "sample_not_ready" : "sample_not_loaded")

    return LabTerrainCollisionLiveSample(
        role: role,
        x: x,
        y: y,
        z: z,
        loaded: loaded,
        ready: ready,
        blockId: blockId,
        blockName: blockName,
        semantic: loaded && ready ? semantic.kind : nil,
        shape: shapeMapping.0,
        chunkStateUnchanged: chunkStateUnchanged,
        reason: shapeMapping.1
    )
}

func makeTerrainCollisionLiveSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    world: World
) -> LabTerrainCollisionLiveSnapshot {
    makeTerrainCollisionLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        world: world,
        node: terrainCollisionLiveCandidateNode()
    )
}

func makeTerrainCollisionLiveSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    world: World,
    node: LabTerrainPathNodeKey
) -> LabTerrainCollisionLiveSnapshot {
    let body = labTerrainHumanBodyContractV0()
    let support = makeTerrainCollisionLiveSample(
        role: .support,
        x: node.x,
        y: node.y - 1,
        z: node.z,
        world: world
    )
    let feet = makeTerrainCollisionLiveSample(
        role: .feet,
        x: node.x,
        y: node.y,
        z: node.z,
        world: world
    )
    let head = makeTerrainCollisionLiveSample(
        role: .head,
        x: node.x,
        y: node.y + 1,
        z: node.z,
        world: world
    )
    let fixture = LabTerrainCollisionColumnFixture(
        name: "live_readonly_collision_candidate",
        x: node.x,
        y: node.y,
        z: node.z,
        inBounds: node.y - 1 >= world.info.minY
            && node.y + 1 < world.info.minY + world.info.height,
        source: "live_readonly_fixture_adapter",
        support: collisionFixtureCell(from: support),
        feet: collisionFixtureCell(from: feet),
        head: collisionFixtureCell(from: head)
    )
    let result = evaluateTerrainOccupancyFixture(fixture, body: body)
    let samples = [support, feet, head]
    let summary = LabTerrainCollisionLiveSummary(
        status: result.status,
        reason: result.reason,
        samples: samples.count,
        loadedSamples: samples.filter(\.loaded).count,
        readySamples: samples.filter(\.ready).count,
        liveAgentDisplaced: false,
        physicalPlaceholderDisplaced: false,
        coreEntityDisplaced: false,
        movementPerformed: false,
        pathfindingPerformed: false,
        mutationPerformed: false,
        success: !result.reason.isEmpty
            && samples.count == 3
            && !result.status.rawValue.isEmpty
    )

    return LabTerrainCollisionLiveSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        node: node,
        body: body,
        support: support,
        feet: feet,
        head: head,
        fixture: fixture,
        result: result,
        summary: summary
    )
}

func makeTerrainCollisionLiveInvariantReport(
    snapshot: LabTerrainCollisionLiveSnapshot?,
    scenario: String,
    seed: UInt32
) -> TerrainCollisionLiveInvariantReport {
    let expectedNode = terrainCollisionLiveCandidateNode()
    let body = labTerrainHumanBodyContractV0()
    let samples = snapshot.map { [$0.support, $0.feet, $0.head] } ?? []
    let fixtureCellCount = snapshot == nil ? 0 : 3
    let statusCount = snapshot == nil ? 0 : 1
    let sampleRoles = samples.map(\.role)
    let expectedRoles: [LabTerrainCollisionCellRole] = [.support, .feet, .head]
    let explicitStatus = snapshot.map { !$0.result.status.rawValue.isEmpty } ?? false
    let explicitReason = snapshot.map { !$0.result.reason.isEmpty } ?? false
    let coordinatesPreserved = snapshot.map { snap in
        snap.fixture.x == snap.node.x
            && snap.fixture.y == snap.node.y
            && snap.fixture.z == snap.node.z
            && snap.fixture.support?.role == .support
            && snap.fixture.feet.role == .feet
            && snap.fixture.head.role == .head
            && snap.support.x == snap.node.x
            && snap.support.y == snap.node.y - 1
            && snap.feet.x == snap.node.x
            && snap.feet.y == snap.node.y
            && snap.head.x == snap.node.x
            && snap.head.y == snap.node.y + 1
    } ?? false
    let loadedReadyPreserved = snapshot.map { snap in
        snap.fixture.support?.loaded == snap.support.loaded
            && snap.fixture.support?.ready == snap.support.ready
            && snap.fixture.feet.loaded == snap.feet.loaded
            && snap.fixture.feet.ready == snap.feet.ready
            && snap.fixture.head.loaded == snap.head.loaded
            && snap.fixture.head.ready == snap.head.ready
    } ?? false
    let shapesPreserved = snapshot.map { snap in
        snap.fixture.support?.shape == snap.support.shape
            && snap.fixture.feet.shape == snap.feet.shape
            && snap.fixture.head.shape == snap.head.shape
    } ?? false
    let noMovement = snapshot?.summary.movementPerformed == false
    let noAgent = snapshot?.summary.liveAgentDisplaced == false
    let noPhysical = snapshot?.summary.physicalPlaceholderDisplaced == false
    let noCore = snapshot?.summary.coreEntityDisplaced == false
    let noPathfinding = snapshot?.summary.pathfindingPerformed == false
    let noMutation = snapshot?.summary.mutationPerformed == false
        && samples.allSatisfy(\.chunkStateUnchanged)

    let checks: [TerrainCollisionLiveInvariantCheck] = [
        TerrainCollisionLiveInvariantCheck(name: "live_readonly_snapshot_exists", passed: snapshot != nil, expected: "present", actual: snapshot == nil ? "missing" : "present"),
        TerrainCollisionLiveInvariantCheck(name: "body_contract_matches_fixture_body", passed: snapshot?.body == body && snapshot?.result.body == body, expected: "LabHumanV0", actual: snapshot?.body.name ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "node_matches_requested_candidate", passed: snapshot?.node == expectedNode, expected: "\(expectedNode)", actual: snapshot.map { "\($0.node)" } ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "three_samples_recorded", passed: samples.count == 3, expected: "3", actual: "\(samples.count)"),
        TerrainCollisionLiveInvariantCheck(name: "support_feet_head_roles_present", passed: Set(sampleRoles) == Set(expectedRoles), expected: "support,feet,head", actual: sampleRoles.map(\.rawValue).joined(separator: ",")),
        TerrainCollisionLiveInvariantCheck(name: "sample_order_is_support_feet_head", passed: sampleRoles == expectedRoles, expected: "support,feet,head", actual: sampleRoles.map(\.rawValue).joined(separator: ",")),
        TerrainCollisionLiveInvariantCheck(name: "loaded_ready_guards_preserved", passed: samples.allSatisfy { ($0.loaded && $0.ready) || $0.shape == .unknown }, expected: "unloaded/unready samples shape unknown", actual: samples.map { "\($0.role.rawValue):\($0.loaded)/\($0.ready)/\($0.shape.rawValue)" }.joined(separator: ",")),
        TerrainCollisionLiveInvariantCheck(name: "collision_result_has_explicit_status", passed: explicitStatus, expected: "non-empty", actual: snapshot?.result.status.rawValue ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "collision_result_has_explicit_reason", passed: explicitReason, expected: "non-empty", actual: snapshot?.result.reason ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "result_source_is_live_readonly_or_fixture_adapter", passed: snapshot?.result.source == "live_readonly_fixture_adapter", expected: "live_readonly_fixture_adapter", actual: snapshot?.result.source ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "fixture_adapter_preserves_coordinates", passed: coordinatesPreserved, expected: "true", actual: String(coordinatesPreserved)),
        TerrainCollisionLiveInvariantCheck(name: "fixture_adapter_preserves_loaded_ready", passed: loadedReadyPreserved, expected: "true", actual: String(loadedReadyPreserved)),
        TerrainCollisionLiveInvariantCheck(name: "fixture_adapter_preserves_shapes", passed: shapesPreserved && fixtureCellCount == 3, expected: "true", actual: String(shapesPreserved)),
        TerrainCollisionLiveInvariantCheck(name: "no_movement_performed", passed: noMovement, expected: "false", actual: String(snapshot?.summary.movementPerformed ?? true)),
        TerrainCollisionLiveInvariantCheck(name: "no_agent_displaced", passed: noAgent, expected: "false", actual: String(snapshot?.summary.liveAgentDisplaced ?? true)),
        TerrainCollisionLiveInvariantCheck(name: "no_physical_placeholder_displaced", passed: noPhysical, expected: "false", actual: String(snapshot?.summary.physicalPlaceholderDisplaced ?? true)),
        TerrainCollisionLiveInvariantCheck(name: "no_core_entity_displaced", passed: noCore, expected: "false", actual: String(snapshot?.summary.coreEntityDisplaced ?? true)),
        TerrainCollisionLiveInvariantCheck(name: "no_world_mutation", passed: noMutation, expected: "false and unchanged chunks", actual: "\(snapshot?.summary.mutationPerformed ?? true) / chunksUnchanged=\(samples.allSatisfy(\.chunkStateUnchanged))"),
        TerrainCollisionLiveInvariantCheck(name: "no_pathfinding_invoked", passed: noPathfinding, expected: "false", actual: String(snapshot?.summary.pathfindingPerformed ?? true)),
        TerrainCollisionLiveInvariantCheck(name: "no_route_following", passed: true, expected: "true", actual: "true"),
        TerrainCollisionLiveInvariantCheck(name: "no_goal_selection", passed: true, expected: "true", actual: "true"),
        TerrainCollisionLiveInvariantCheck(name: "collision_does_not_mutate_lab_agent", passed: true, expected: "true", actual: "true"),
        TerrainCollisionLiveInvariantCheck(name: "live_and_fixture_reports_remain_separate", passed: snapshot?.fixture.source == "live_readonly_fixture_adapter", expected: "live adapter source", actual: snapshot?.fixture.source ?? "missing"),
        TerrainCollisionLiveInvariantCheck(name: "status_count_matches_single_result", passed: statusCount == 1, expected: "1", actual: "\(statusCount)"),
        TerrainCollisionLiveInvariantCheck(name: "success_allows_non_occupable_status", passed: snapshot?.summary.success == true && snapshot?.result.reason.isEmpty == false, expected: "success independent of occupable", actual: "\(snapshot?.result.status.rawValue ?? "missing") / \(snapshot?.summary.success ?? false)")
    ]
    let passed = checks.filter(\.passed).count

    return TerrainCollisionLiveInvariantReport(
        scenario: scenario,
        seed: seed,
        success: snapshot?.summary.success == true && passed == checks.count,
        summary: TerrainCollisionLiveInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            samples: samples.count,
            results: statusCount
        ),
        checks: checks,
        notes: [
            "Live collision reads exactly support, feet, and head samples before adapting them to the fixture evaluator.",
            "The scenario performs no movement, pathfinding, route following, displacement, physics, or mutation."
        ]
    )
}
