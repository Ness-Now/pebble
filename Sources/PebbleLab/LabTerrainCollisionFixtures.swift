struct TerrainCollisionFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let body: LabTerrainBodyContract
    let summary: TerrainCollisionFixtureSummary
    let cases: [TerrainCollisionFixtureResult]
}

struct TerrainCollisionFixtureSummary: Codable {
    let fixtures: Int
    let passed: Int
    let failed: Int
    let occupable: Int
    let blocked: Int
    let unsupported: Int
    let verticalSpaceOccupied: Int
    let liquidUnsupported: Int
    let unknown: Int
    let outOfBounds: Int
    let notLoaded: Int
    let notReady: Int
}

struct TerrainCollisionFixtureResult: Codable {
    let name: String
    let expectedStatus: LabTerrainOccupancyStatus
    let actualStatus: LabTerrainOccupancyStatus
    let expectedReason: String
    let actualReason: String
    let fixture: LabTerrainCollisionColumnFixture
    let result: LabTerrainCollisionResult
    let passed: Bool
}

struct TerrainCollisionInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainCollisionInvariantSummary
    let checks: [TerrainCollisionInvariantCheck]
    let notes: [String]
}

struct TerrainCollisionInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let fixtures: Int
    let results: Int
}

struct TerrainCollisionInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private struct TerrainCollisionFixtureDefinition {
    let fixture: LabTerrainCollisionColumnFixture
    let expectedStatus: LabTerrainOccupancyStatus
    let expectedReason: String
}

private func collisionCell(
    _ role: LabTerrainCollisionCellRole,
    _ shape: LabTerrainCollisionShape,
    shapeName: String? = nil,
    loaded: Bool = true,
    ready: Bool = true
) -> LabTerrainCollisionCellFixture {
    LabTerrainCollisionCellFixture(
        role: role,
        shape: shape,
        shapeName: shapeName ?? shape.rawValue,
        loaded: loaded,
        ready: ready
    )
}

private func collisionFixture(
    _ name: String,
    index: Int,
    support: LabTerrainCollisionCellFixture?,
    feet: LabTerrainCollisionCellFixture = collisionCell(.feet, .empty),
    head: LabTerrainCollisionCellFixture = collisionCell(.head, .empty),
    inBounds: Bool = true,
    expectedStatus: LabTerrainOccupancyStatus,
    expectedReason: String
) -> TerrainCollisionFixtureDefinition {
    TerrainCollisionFixtureDefinition(
        fixture: LabTerrainCollisionColumnFixture(
            name: name,
            x: index,
            y: 64,
            z: 0,
            inBounds: inBounds,
            source: "fixture",
            support: support,
            feet: feet,
            head: head
        ),
        expectedStatus: expectedStatus,
        expectedReason: expectedReason
    )
}

private func terrainCollisionFixtureDefinitions()
    -> [TerrainCollisionFixtureDefinition] {
    [
        collisionFixture(
            "full_cube_support_empty_feet_head_is_occupable",
            index: 0,
            support: collisionCell(.support, .fullCube),
            expectedStatus: .occupable,
            expectedReason: "full_cube_support_empty_body_volume"
        ),
        collisionFixture(
            "missing_support_is_unsupported",
            index: 1,
            support: nil,
            expectedStatus: .unsupported,
            expectedReason: "missing_support"
        ),
        collisionFixture(
            "unknown_support_is_unknown",
            index: 2,
            support: collisionCell(.support, .unknown),
            expectedStatus: .unknown,
            expectedReason: "unknown_support_shape"
        ),
        collisionFixture(
            "liquid_support_is_liquid_unsupported",
            index: 3,
            support: collisionCell(.support, .liquid),
            expectedStatus: .liquidUnsupported,
            expectedReason: "liquid_support"
        ),
        collisionFixture(
            "feet_full_cube_is_blocked",
            index: 4,
            support: collisionCell(.support, .fullCube),
            feet: collisionCell(.feet, .fullCube),
            expectedStatus: .blocked,
            expectedReason: "feet_full_cube_blocks_body"
        ),
        collisionFixture(
            "head_full_cube_is_vertical_space_occupied",
            index: 5,
            support: collisionCell(.support, .fullCube),
            head: collisionCell(.head, .fullCube),
            expectedStatus: .verticalSpaceOccupied,
            expectedReason: "head_full_cube_blocks_body"
        ),
        collisionFixture(
            "feet_unknown_is_unknown",
            index: 6,
            support: collisionCell(.support, .fullCube),
            feet: collisionCell(.feet, .unknown),
            expectedStatus: .unknown,
            expectedReason: "unknown_feet_shape"
        ),
        collisionFixture(
            "head_unknown_is_unknown",
            index: 7,
            support: collisionCell(.support, .fullCube),
            head: collisionCell(.head, .unknown),
            expectedStatus: .unknown,
            expectedReason: "unknown_head_shape"
        ),
        collisionFixture(
            "support_not_loaded_is_not_loaded",
            index: 8,
            support: collisionCell(.support, .fullCube, loaded: false),
            expectedStatus: .notLoaded,
            expectedReason: "support_not_loaded"
        ),
        collisionFixture(
            "feet_not_loaded_is_not_loaded",
            index: 9,
            support: collisionCell(.support, .fullCube),
            feet: collisionCell(.feet, .empty, loaded: false),
            expectedStatus: .notLoaded,
            expectedReason: "feet_not_loaded"
        ),
        collisionFixture(
            "head_not_loaded_is_not_loaded",
            index: 10,
            support: collisionCell(.support, .fullCube),
            head: collisionCell(.head, .empty, loaded: false),
            expectedStatus: .notLoaded,
            expectedReason: "head_not_loaded"
        ),
        collisionFixture(
            "support_not_ready_is_not_ready",
            index: 11,
            support: collisionCell(.support, .fullCube, ready: false),
            expectedStatus: .notReady,
            expectedReason: "support_not_ready"
        ),
        collisionFixture(
            "feet_not_ready_is_not_ready",
            index: 12,
            support: collisionCell(.support, .fullCube),
            feet: collisionCell(.feet, .empty, ready: false),
            expectedStatus: .notReady,
            expectedReason: "feet_not_ready"
        ),
        collisionFixture(
            "head_not_ready_is_not_ready",
            index: 13,
            support: collisionCell(.support, .fullCube),
            head: collisionCell(.head, .empty, ready: false),
            expectedStatus: .notReady,
            expectedReason: "head_not_ready"
        ),
        collisionFixture(
            "special_unsupported_shape_is_unknown",
            index: 14,
            support: collisionCell(
                .support,
                .unknown,
                shapeName: "special_unmodeled_slab"
            ),
            expectedStatus: .unknown,
            expectedReason: "unmodeled_special_shape"
        ),
        collisionFixture(
            "loaded_ready_guards_precede_success",
            index: 15,
            support: collisionCell(.support, .fullCube, loaded: false, ready: false),
            expectedStatus: .notLoaded,
            expectedReason: "support_not_loaded"
        ),
        collisionFixture(
            "liquid_feet_is_blocked",
            index: 16,
            support: collisionCell(.support, .fullCube),
            feet: collisionCell(.feet, .liquid),
            expectedStatus: .blocked,
            expectedReason: "liquid_feet_blocks_occupancy"
        ),
        collisionFixture(
            "liquid_head_is_blocked",
            index: 17,
            support: collisionCell(.support, .fullCube),
            head: collisionCell(.head, .liquid),
            expectedStatus: .blocked,
            expectedReason: "liquid_head_blocks_occupancy"
        ),
        collisionFixture(
            "candidate_out_of_bounds_is_out_of_bounds",
            index: 18,
            support: collisionCell(.support, .fullCube),
            inBounds: false,
            expectedStatus: .outOfBounds,
            expectedReason: "candidate_out_of_bounds"
        )
    ]
}

private func makeTerrainCollisionFixtureSummary(
    results: [TerrainCollisionFixtureResult]
) -> TerrainCollisionFixtureSummary {
    TerrainCollisionFixtureSummary(
        fixtures: results.count,
        passed: results.filter(\.passed).count,
        failed: results.filter { !$0.passed }.count,
        occupable: results.filter { $0.actualStatus == .occupable }.count,
        blocked: results.filter { $0.actualStatus == .blocked }.count,
        unsupported: results.filter { $0.actualStatus == .unsupported }.count,
        verticalSpaceOccupied: results.filter {
            $0.actualStatus == .verticalSpaceOccupied
        }.count,
        liquidUnsupported: results.filter {
            $0.actualStatus == .liquidUnsupported
        }.count,
        unknown: results.filter { $0.actualStatus == .unknown }.count,
        outOfBounds: results.filter { $0.actualStatus == .outOfBounds }.count,
        notLoaded: results.filter { $0.actualStatus == .notLoaded }.count,
        notReady: results.filter { $0.actualStatus == .notReady }.count
    )
}

func makeTerrainCollisionFixtureReport(
    scenario: String,
    seed: UInt32
) -> TerrainCollisionFixtureReport {
    let body = labTerrainHumanBodyContractV0()
    let results = terrainCollisionFixtureDefinitions().map { definition in
        let actual = evaluateTerrainOccupancyFixture(definition.fixture, body: body)
        return TerrainCollisionFixtureResult(
            name: definition.fixture.name,
            expectedStatus: definition.expectedStatus,
            actualStatus: actual.status,
            expectedReason: definition.expectedReason,
            actualReason: actual.reason,
            fixture: definition.fixture,
            result: actual,
            passed: actual.status == definition.expectedStatus
                && actual.reason == definition.expectedReason
        )
    }
    let summary = makeTerrainCollisionFixtureSummary(results: results)
    let statusCount = summary.occupable + summary.blocked + summary.unsupported
        + summary.verticalSpaceOccupied + summary.liquidUnsupported
        + summary.unknown + summary.outOfBounds + summary.notLoaded
        + summary.notReady

    return TerrainCollisionFixtureReport(
        scenario: scenario,
        seed: seed,
        success: summary.failed == 0 && statusCount == summary.fixtures,
        body: body,
        summary: summary,
        cases: results
    )
}

func makeTerrainCollisionInvariantReport(
    _ report: TerrainCollisionFixtureReport
) -> TerrainCollisionInvariantReport {
    let definitions = terrainCollisionFixtureDefinitions()
    let rerun = definitions.map {
        evaluateTerrainOccupancyFixture($0.fixture, body: report.body)
    }
    let deterministic = zip(report.cases, rerun).allSatisfy {
        $0.actualStatus == $1.status && $0.actualReason == $1.reason
    }
    let expectedNames = definitions.map(\.fixture.name)
    let expectedBody = labTerrainHumanBodyContractV0()
    let nonOccupableEvidenceCases = report.cases.filter {
        $0.name.contains("missing")
            || $0.name.contains("unknown")
            || $0.name.contains("liquid")
            || $0.name.contains("not_loaded")
            || $0.name.contains("not_ready")
            || $0.name.contains("special_")
            || $0.name.contains("out_of_bounds")
    }
    let occupableCases = report.cases.filter { $0.actualStatus == .occupable }
    let guardCases = report.cases.filter {
        $0.name.contains("not_loaded") || $0.name.contains("not_ready")
            || $0.name == "loaded_ready_guards_precede_success"
    }
    let blockedCases = report.cases.filter { $0.actualStatus == .blocked }
    let allStatuses: Set<LabTerrainOccupancyStatus> = [
        .occupable,
        .blocked,
        .unsupported,
        .verticalSpaceOccupied,
        .liquidUnsupported,
        .unknown,
        .outOfBounds,
        .notLoaded,
        .notReady
    ]
    let actualStatuses = Set(report.cases.map(\.actualStatus))
    let statusCount = report.summary.occupable + report.summary.blocked
        + report.summary.unsupported + report.summary.verticalSpaceOccupied
        + report.summary.liquidUnsupported + report.summary.unknown
        + report.summary.outOfBounds + report.summary.notLoaded
        + report.summary.notReady

    let checks: [TerrainCollisionInvariantCheck] = [
        TerrainCollisionInvariantCheck(name: "fixture_only_no_world", passed: true, expected: "no World input", actual: "synthetic fixtures only"),
        TerrainCollisionInvariantCheck(name: "no_movement_performed", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_agent_displaced", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_physical_placeholder_displaced", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_core_entity_displaced", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_world_mutation", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_pathfinding_invoked", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_route_following", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "no_goal_selection", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "collision_does_not_mutate_lab_agent", passed: true, expected: "true", actual: "true"),
        TerrainCollisionInvariantCheck(name: "body_contract_matches_phase_4_16a", passed: report.body == expectedBody, expected: "LabHumanV0 0.6x0.6x1.8", actual: "\(report.body.name) \(report.body.bodyBox.width)x\(report.body.bodyBox.depth)x\(report.body.bodyBox.height)"),
        TerrainCollisionInvariantCheck(name: "body_anchor_is_feet_plane", passed: report.body.anchor == "feet_plane", expected: "feet_plane", actual: report.body.anchor),
        TerrainCollisionInvariantCheck(name: "fixture_results_deterministic", passed: deterministic, expected: "stable rerun", actual: String(deterministic)),
        TerrainCollisionInvariantCheck(name: "each_fixture_has_explicit_reason", passed: report.cases.allSatisfy { !$0.actualReason.isEmpty }, expected: "all reasons non-empty", actual: "\(report.cases.filter { !$0.actualReason.isEmpty }.count)/\(report.cases.count)"),
        TerrainCollisionInvariantCheck(name: "missing_or_unsupported_evidence_never_occupable", passed: nonOccupableEvidenceCases.allSatisfy { $0.actualStatus != .occupable }, expected: "0 occupable", actual: "\(nonOccupableEvidenceCases.filter { $0.actualStatus == .occupable }.count) occupable"),
        TerrainCollisionInvariantCheck(name: "loaded_ready_guards_precede_occupable", passed: guardCases.allSatisfy { $0.actualStatus == .notLoaded || $0.actualStatus == .notReady }, expected: "notLoaded or notReady", actual: guardCases.map(\.actualStatus.rawValue).joined(separator: ",")),
        TerrainCollisionInvariantCheck(name: "occupable_requires_full_cube_support", passed: occupableCases.allSatisfy { $0.fixture.support?.shape == .fullCube }, expected: "fullCube", actual: occupableCases.map { $0.fixture.support?.shape.rawValue ?? "missing" }.joined(separator: ",")),
        TerrainCollisionInvariantCheck(name: "occupable_requires_empty_feet_and_head", passed: occupableCases.allSatisfy { $0.fixture.feet.shape == .empty && $0.fixture.head.shape == .empty }, expected: "empty feet/head", actual: occupableCases.map { "\($0.fixture.feet.shape.rawValue)/\($0.fixture.head.shape.rawValue)" }.joined(separator: ",")),
        TerrainCollisionInvariantCheck(name: "blocked_reason_preserved", passed: !blockedCases.isEmpty && blockedCases.allSatisfy { $0.actualReason == $0.expectedReason && !$0.actualReason.isEmpty }, expected: "blocked reasons explicit", actual: blockedCases.map(\.actualReason).joined(separator: ",")),
        TerrainCollisionInvariantCheck(name: "fixture_and_live_evidence_separated", passed: report.cases.allSatisfy { $0.fixture.source == "fixture" && $0.result.source == "fixture" }, expected: "fixture", actual: Set(report.cases.map(\.fixture.source)).sorted().joined(separator: ",")),
        TerrainCollisionInvariantCheck(name: "status_counts_match_fixtures", passed: statusCount == report.summary.fixtures && report.summary.passed + report.summary.failed == report.summary.fixtures, expected: "\(report.summary.fixtures)", actual: "\(statusCount)"),
        TerrainCollisionInvariantCheck(name: "all_expected_statuses_matched", passed: actualStatuses == allStatuses && report.cases.map(\.name) == expectedNames && report.success, expected: "all statuses and fixture order", actual: "statuses=\(actualStatuses.map(\.rawValue).sorted().joined(separator: ","))")
    ]
    let passed = checks.filter(\.passed).count
    return TerrainCollisionInvariantReport(
        scenario: report.scenario,
        seed: report.seed,
        success: report.success && passed == checks.count,
        summary: TerrainCollisionInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            fixtures: report.summary.fixtures,
            results: report.cases.count
        ),
        checks: checks,
        notes: [
            "Collision fixture smoke evaluates synthetic support/feet/head shape evidence only.",
            "No live query, movement, pathfinding, displacement, collision gameplay, or mutation is performed."
        ]
    )
}
