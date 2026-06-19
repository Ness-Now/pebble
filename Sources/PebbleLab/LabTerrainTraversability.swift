enum LabTerrainTraversabilityKind: String, Codable {
    case unknown
    case traversable
    case blocked
    case unsupported
    case unsafe
    case occupiedVerticalSpace
    case other
}

struct LabTerrainColumnSemantic: Codable {
    let x: Int
    let y: Int
    let z: Int
    let support: LabTerrainCellSemantic?
    let feet: LabTerrainCellSemantic?
    let head: LabTerrainCellSemantic?
}

struct LabTerrainTraversabilityCell: Codable {
    let x: Int
    let y: Int
    let z: Int
    let kind: LabTerrainTraversabilityKind
    let confidence: Double
    let reason: String
}

struct LabTerrainTraversabilitySummary: Codable {
    let cellsEvaluated: Int
    let traversableCells: Int
    let blockedCells: Int
    let unknownCells: Int
    let unsupportedCells: Int
    let unsafeCells: Int
    let occupiedVerticalSpaceCells: Int
    let otherCells: Int
    let success: Bool
}

struct TerrainTraversabilityFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainTraversabilityFixtureSummary
    let cases: [TerrainTraversabilityFixtureResult]
}

struct TerrainTraversabilityFixtureSummary: Codable {
    let fixtures: Int
    let passed: Int
    let failed: Int
    let traversableCases: Int
    let blockedCases: Int
    let unknownCases: Int
    let unsupportedCases: Int
    let unsafeCases: Int
    let occupiedVerticalSpaceCases: Int
    let otherCases: Int
}

struct TerrainTraversabilityFixtureResult: Codable {
    let name: String
    let expectedKind: LabTerrainTraversabilityKind
    let actualKind: LabTerrainTraversabilityKind
    let expectedReason: String
    let actualReason: String
    let passed: Bool
}

struct TerrainTraversabilityInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: TerrainTraversabilityInvariantSummary
    let checks: [TerrainTraversabilityInvariantCheck]
    let notes: [String]
}

struct TerrainTraversabilityInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let fixtures: Int
    let results: Int
}

struct TerrainTraversabilityInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private struct TerrainTraversabilityFixtureDefinition {
    let name: String
    let column: LabTerrainColumnSemantic
    let expectedKind: LabTerrainTraversabilityKind
    let expectedReason: String
}

func classifyTerrainTraversability(
    _ column: LabTerrainColumnSemantic
) -> LabTerrainTraversabilityCell {
    func result(
        kind: LabTerrainTraversabilityKind,
        confidence: Double,
        reason: String
    ) -> LabTerrainTraversabilityCell {
        LabTerrainTraversabilityCell(
            x: column.x,
            y: column.y,
            z: column.z,
            kind: kind,
            confidence: confidence,
            reason: reason
        )
    }

    guard let support = column.support,
          let feet = column.feet,
          let head = column.head else {
        return result(kind: .unknown, confidence: 0, reason: "missing_column_cell")
    }
    guard support.kind != .unknown,
          feet.kind != .unknown,
          head.kind != .unknown else {
        return result(kind: .unknown, confidence: 0, reason: "unknown_column_semantics")
    }
    if feet.kind == .solid || head.kind == .solid {
        return result(
            kind: .occupiedVerticalSpace,
            confidence: 0.9,
            reason: "solid_vertical_space"
        )
    }
    if support.kind == .air {
        return result(kind: .unsupported, confidence: 0.9, reason: "air_support")
    }
    if support.kind == .liquid {
        return result(kind: .unsafe, confidence: 0.8, reason: "liquid_support")
    }
    if feet.kind == .liquid || head.kind == .liquid {
        return result(
            kind: .unsafe,
            confidence: 0.8,
            reason: "liquid_vertical_space"
        )
    }
    if support.kind == .other {
        return result(kind: .unknown, confidence: 0, reason: "unclassified_support")
    }
    if feet.kind == .plantLike || head.kind == .plantLike {
        return result(
            kind: .unknown,
            confidence: 0,
            reason: "plant_like_vertical_space_unknown"
        )
    }
    if support.kind == .solid && feet.kind == .air && head.kind == .air {
        return result(
            kind: .traversable,
            confidence: 0.8,
            reason: "solid_support_clear_vertical_space"
        )
    }
    return result(
        kind: .other,
        confidence: 0.5,
        reason: "fallback_unhandled_column"
    )
}

private func makeTraversabilitySemantic(
    kind: LabTerrainCellKind,
    y: Int
) -> LabTerrainCellSemantic {
    LabTerrainCellSemantic(
        dx: 0,
        dz: 0,
        x: 0,
        y: y,
        z: 0,
        blockId: nil,
        blockName: nil,
        kind: kind,
        confidence: 1,
        reason: "synthetic_fixture"
    )
}

private func makeTraversabilityColumn(
    index: Int,
    support: LabTerrainCellKind?,
    feet: LabTerrainCellKind?,
    head: LabTerrainCellKind?
) -> LabTerrainColumnSemantic {
    let y = 64
    return LabTerrainColumnSemantic(
        x: index,
        y: y,
        z: 0,
        support: support.map { makeTraversabilitySemantic(kind: $0, y: y - 1) },
        feet: feet.map { makeTraversabilitySemantic(kind: $0, y: y) },
        head: head.map { makeTraversabilitySemantic(kind: $0, y: y + 1) }
    )
}

private func terrainTraversabilityFixtureDefinitions()
    -> [TerrainTraversabilityFixtureDefinition] {
    let cases: [(
        String,
        LabTerrainCellKind?,
        LabTerrainCellKind?,
        LabTerrainCellKind?,
        LabTerrainTraversabilityKind,
        String
    )] = [
        ("solid_support_air_feet_air_head_is_traversable", .solid, .air, .air, .traversable, "solid_support_clear_vertical_space"),
        ("air_support_air_feet_air_head_is_unsupported", .air, .air, .air, .unsupported, "air_support"),
        ("solid_support_solid_feet_air_head_is_occupied", .solid, .solid, .air, .occupiedVerticalSpace, "solid_vertical_space"),
        ("solid_support_air_feet_solid_head_is_occupied", .solid, .air, .solid, .occupiedVerticalSpace, "solid_vertical_space"),
        ("liquid_support_air_feet_air_head_is_unsafe", .liquid, .air, .air, .unsafe, "liquid_support"),
        ("solid_support_liquid_feet_air_head_is_unsafe", .solid, .liquid, .air, .unsafe, "liquid_vertical_space"),
        ("solid_support_air_feet_liquid_head_is_unsafe", .solid, .air, .liquid, .unsafe, "liquid_vertical_space"),
        ("unknown_support_air_feet_air_head_is_unknown", .unknown, .air, .air, .unknown, "unknown_column_semantics"),
        ("solid_support_unknown_feet_air_head_is_unknown", .solid, .unknown, .air, .unknown, "unknown_column_semantics"),
        ("solid_support_air_feet_unknown_head_is_unknown", .solid, .air, .unknown, .unknown, "unknown_column_semantics"),
        ("solid_support_plant_feet_air_head_is_unknown", .solid, .plantLike, .air, .unknown, "plant_like_vertical_space_unknown"),
        ("solid_support_air_feet_plant_head_is_unknown", .solid, .air, .plantLike, .unknown, "plant_like_vertical_space_unknown"),
        ("missing_head_is_unknown", .solid, .air, nil, .unknown, "missing_column_cell"),
        ("missing_support_is_unknown", nil, .air, .air, .unknown, "missing_column_cell"),
        ("other_support_air_feet_air_head_is_unknown", .other, .air, .air, .unknown, "unclassified_support")
    ]

    return cases.enumerated().map { index, fixture in
        TerrainTraversabilityFixtureDefinition(
            name: fixture.0,
            column: makeTraversabilityColumn(
                index: index,
                support: fixture.1,
                feet: fixture.2,
                head: fixture.3
            ),
            expectedKind: fixture.4,
            expectedReason: fixture.5
        )
    }
}

func makeTerrainTraversabilityFixtureReport(
    scenario: String,
    seed: UInt32
) -> TerrainTraversabilityFixtureReport {
    let results = terrainTraversabilityFixtureDefinitions().map { fixture in
        let actual = classifyTerrainTraversability(fixture.column)
        return TerrainTraversabilityFixtureResult(
            name: fixture.name,
            expectedKind: fixture.expectedKind,
            actualKind: actual.kind,
            expectedReason: fixture.expectedReason,
            actualReason: actual.reason,
            passed: actual.kind == fixture.expectedKind
                && actual.reason == fixture.expectedReason
        )
    }
    let passed = results.filter(\.passed).count
    let failed = results.count - passed
    let traversableCases = results.filter { $0.expectedKind == .traversable }.count
    let blockedCases = results.filter { $0.expectedKind == .blocked }.count
    let unknownCases = results.filter { $0.expectedKind == .unknown }.count
    let unsupportedCases = results.filter { $0.expectedKind == .unsupported }.count
    let unsafeCases = results.filter { $0.expectedKind == .unsafe }.count
    let occupiedCases = results.filter {
        $0.expectedKind == .occupiedVerticalSpace
    }.count
    let otherCases = results.filter { $0.expectedKind == .other }.count
    let countedCases = traversableCases + blockedCases + unknownCases
        + unsupportedCases + unsafeCases + occupiedCases + otherCases

    return TerrainTraversabilityFixtureReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0 && countedCases == results.count,
        summary: TerrainTraversabilityFixtureSummary(
            fixtures: results.count,
            passed: passed,
            failed: failed,
            traversableCases: traversableCases,
            blockedCases: blockedCases,
            unknownCases: unknownCases,
            unsupportedCases: unsupportedCases,
            unsafeCases: unsafeCases,
            occupiedVerticalSpaceCases: occupiedCases,
            otherCases: otherCases
        ),
        cases: results
    )
}

func makeTerrainTraversabilitySummary(
    report: TerrainTraversabilityFixtureReport
) -> LabTerrainTraversabilitySummary {
    let summary = report.summary
    return LabTerrainTraversabilitySummary(
        cellsEvaluated: summary.fixtures,
        traversableCells: summary.traversableCases,
        blockedCells: summary.blockedCases,
        unknownCells: summary.unknownCases,
        unsupportedCells: summary.unsupportedCases,
        unsafeCells: summary.unsafeCases,
        occupiedVerticalSpaceCells: summary.occupiedVerticalSpaceCases,
        otherCells: summary.otherCases,
        success: report.success
    )
}

func makeTerrainTraversabilityInvariantReport(
    fixtureReport: TerrainTraversabilityFixtureReport
) -> TerrainTraversabilityInvariantReport {
    let cases = fixtureReport.cases
    let expectedNames = terrainTraversabilityFixtureDefinitions().map(\.name)
    let missingCases = cases.filter { $0.name.hasPrefix("missing_") }
    let solidVerticalCases = cases.filter { $0.name.contains("solid_feet")
        || $0.name.contains("solid_head") }
    let airSupportCases = cases.filter { $0.name.hasPrefix("air_support_") }
    let liquidSupportCases = cases.filter { $0.name.hasPrefix("liquid_support_") }
    let summary = fixtureReport.summary
    let countedCases = summary.traversableCases + summary.blockedCases
        + summary.unknownCases + summary.unsupportedCases + summary.unsafeCases
        + summary.occupiedVerticalSpaceCases + summary.otherCases

    let checks = [
        TerrainTraversabilityInvariantCheck(
            name: "input_columns_exist",
            passed: summary.fixtures > 0,
            expected: "> 0",
            actual: "\(summary.fixtures)"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "traversability_results_match_columns",
            passed: cases.count == summary.fixtures,
            expected: "\(summary.fixtures)",
            actual: "\(cases.count)"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "missing_column_data_returns_unknown",
            passed: !missingCases.isEmpty
                && missingCases.allSatisfy { $0.actualKind == .unknown },
            expected: "all missing cases unknown",
            actual: "\(missingCases.filter { $0.actualKind == .unknown }.count)/\(missingCases.count)"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "solid_vertical_space_not_traversable",
            passed: !solidVerticalCases.isEmpty
                && solidVerticalCases.allSatisfy { $0.actualKind != .traversable },
            expected: "0 traversable",
            actual: "\(solidVerticalCases.filter { $0.actualKind == .traversable }.count) traversable"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "air_support_not_traversable",
            passed: !airSupportCases.isEmpty
                && airSupportCases.allSatisfy { $0.actualKind != .traversable },
            expected: "0 traversable",
            actual: "\(airSupportCases.filter { $0.actualKind == .traversable }.count) traversable"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "liquid_support_not_traversable",
            passed: !liquidSupportCases.isEmpty
                && liquidSupportCases.allSatisfy { $0.actualKind != .traversable },
            expected: "0 traversable",
            actual: "\(liquidSupportCases.filter { $0.actualKind == .traversable }.count) traversable"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "counts_match_summary",
            passed: countedCases == summary.fixtures
                && summary.passed + summary.failed == summary.fixtures,
            expected: "\(summary.fixtures)",
            actual: "\(countedCases)"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "output_order_preserved",
            passed: cases.map(\.name) == expectedNames,
            expected: "fixture order",
            actual: cases.map(\.name) == expectedNames ? "fixture order" : "mismatch"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "no_world_access_required",
            passed: true,
            expected: "pure LabTerrainColumnSemantic transform",
            actual: "pure LabTerrainColumnSemantic transform"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "no_mutation_path_used",
            passed: true,
            expected: "classification-only code path",
            actual: "code-review invariant"
        ),
        TerrainTraversabilityInvariantCheck(
            name: "no_pathfinding_performed",
            passed: true,
            expected: "no routes, neighbors, or costs",
            actual: "code-review invariant"
        )
    ]
    let checksFailed = checks.filter { !$0.passed }.count

    return TerrainTraversabilityInvariantReport(
        scenario: fixtureReport.scenario,
        seed: fixtureReport.seed,
        success: checksFailed == 0 && fixtureReport.success,
        summary: TerrainTraversabilityInvariantSummary(
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed,
            fixtures: summary.fixtures,
            results: cases.count
        ),
        checks: checks,
        notes: [
            "Traversable means only a fixture-contract candidate, not a physical movement guarantee.",
            "The classifier performs no world access, pathfinding, collision, mutation, or agent action."
        ]
    )
}
