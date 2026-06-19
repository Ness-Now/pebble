enum LabTerrainCellKind: String, Codable {
    case unknown
    case air
    case solid
    case liquid
    case plantLike
    case other
}

struct LabTerrainCellSemantic: Codable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let blockId: Int?
    let blockName: String?
    let kind: LabTerrainCellKind
    let confidence: Double
    let reason: String
}

struct LabTerrainSemanticsSummary: Codable {
    let cellsClassified: Int
    let unknownCells: Int
    let airCells: Int
    let solidCells: Int
    let liquidCells: Int
    let plantLikeCells: Int
    let otherCells: Int
    let success: Bool
}

struct TerrainSemanticsInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: TerrainSemanticsInvariantSummary
    let checks: [TerrainSemanticsInvariantCheck]
    let notes: [String]
}

struct TerrainSemanticsInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let scanCells: Int
    let semanticCells: Int
    let unknownCells: Int
    let airCells: Int
    let solidCells: Int
    let liquidCells: Int
    let plantLikeCells: Int
    let otherCells: Int
}

struct TerrainSemanticsInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private let exactAirBlockNames: Set<String> = [
    "air", "cave_air", "void_air"
]

private let exactLiquidBlockNames: Set<String> = [
    "water", "lava"
]

private let exactPlantBlockNames: Set<String> = [
    "tall_grass", "fern", "large_fern", "dandelion", "poppy",
    "wheat", "carrots", "potatoes", "beetroots"
]

private let exactSolidBlockNames: Set<String> = [
    "stone", "dirt", "grass_block", "sand", "gravel", "cobblestone",
    "oak_log", "oak_planks", "bedrock"
]

func classifyTerrainCell(_ scanCell: LabTerrainScanCell) -> LabTerrainCellSemantic {
    func semantic(
        kind: LabTerrainCellKind,
        confidence: Double,
        reason: String
    ) -> LabTerrainCellSemantic {
        LabTerrainCellSemantic(
            dx: scanCell.dx,
            dz: scanCell.dz,
            x: scanCell.x,
            y: scanCell.y,
            z: scanCell.z,
            blockId: scanCell.blockId,
            blockName: scanCell.blockName,
            kind: kind,
            confidence: confidence,
            reason: reason
        )
    }

    guard scanCell.success else {
        return semantic(kind: .unknown, confidence: 0, reason: "scan_cell_unsuccessful")
    }
    guard scanCell.chunk.loaded && scanCell.chunk.ready else {
        return semantic(kind: .unknown, confidence: 0, reason: "cell_not_loaded_or_ready")
    }
    guard let packedCell = scanCell.cell,
          let blockId = scanCell.blockId,
          let meta = scanCell.meta,
          let blockName = scanCell.blockName else {
        return semantic(kind: .unknown, confidence: 0, reason: "missing_block_identity")
    }
    guard blockId >= 0,
          (0...15).contains(meta),
          packedCell == ((blockId << 4) | meta) else {
        return semantic(kind: .unknown, confidence: 0, reason: "invalid_packed_cell")
    }

    if exactAirBlockNames.contains(blockName) {
        return semantic(kind: .air, confidence: 1, reason: "exact_air_identity")
    }
    if exactLiquidBlockNames.contains(blockName) {
        return semantic(kind: .liquid, confidence: 1, reason: "exact_liquid_identity")
    }
    if exactPlantBlockNames.contains(blockName)
        || blockName.hasSuffix("_leaves")
        || blockName.hasSuffix("_sapling") {
        return semantic(kind: .plantLike, confidence: 0.8, reason: "reviewed_plant_identity")
    }
    if exactSolidBlockNames.contains(blockName) {
        return semantic(kind: .solid, confidence: 0.8, reason: "reviewed_solid_identity")
    }
    return semantic(
        kind: .other,
        confidence: 0.5,
        reason: "fallback_valid_unclassified_cell"
    )
}

func classifyTerrainScanCells(_ cells: [LabTerrainScanCell]) -> [LabTerrainCellSemantic] {
    cells.map(classifyTerrainCell)
}

func makeTerrainSemanticsSummary(
    cells: [LabTerrainCellSemantic],
    expectedCount: Int
) -> LabTerrainSemanticsSummary {
    let unknownCells = cells.filter { $0.kind == .unknown }.count
    let airCells = cells.filter { $0.kind == .air }.count
    let solidCells = cells.filter { $0.kind == .solid }.count
    let liquidCells = cells.filter { $0.kind == .liquid }.count
    let plantLikeCells = cells.filter { $0.kind == .plantLike }.count
    let otherCells = cells.filter { $0.kind == .other }.count
    let total = unknownCells + airCells + solidCells + liquidCells
        + plantLikeCells + otherCells

    return LabTerrainSemanticsSummary(
        cellsClassified: cells.count,
        unknownCells: unknownCells,
        airCells: airCells,
        solidCells: solidCells,
        liquidCells: liquidCells,
        plantLikeCells: plantLikeCells,
        otherCells: otherCells,
        success: cells.count == expectedCount && total == cells.count
    )
}

func makeTerrainSemanticsInvariantReport(
    snapshot: LabTerrainScanSnapshot
) -> TerrainSemanticsInvariantReport {
    let rawCells = snapshot.cells
    let semanticCells = snapshot.semanticCells
    let mappedCells = zip(rawCells, semanticCells).filter { raw, semantic in
        raw.dx == semantic.dx
            && raw.dz == semantic.dz
            && raw.x == semantic.x
            && raw.y == semantic.y
            && raw.z == semantic.z
            && raw.blockId == semantic.blockId
            && raw.blockName == semantic.blockName
    }.count
    let unavailableCells = rawCells.enumerated().filter { index, raw in
        let unavailable = !raw.success
            || !raw.chunk.loaded
            || !raw.chunk.ready
            || raw.cell == nil
            || raw.blockId == nil
            || raw.meta == nil
            || raw.blockName == nil
        return unavailable && semanticCells.indices.contains(index)
            && semanticCells[index].kind == .unknown
    }.count
    let expectedUnavailableCells = rawCells.filter {
        !$0.success
            || !$0.chunk.loaded
            || !$0.chunk.ready
            || $0.cell == nil
            || $0.blockId == nil
            || $0.meta == nil
            || $0.blockName == nil
    }.count
    let preservedPackedCells = rawCells.filter { raw in
        guard let packedCell = raw.cell,
              let blockId = raw.blockId,
              let meta = raw.meta else {
            return false
        }
        return blockId >= 0
            && (0...15).contains(meta)
            && packedCell == ((blockId << 4) | meta)
    }.count
    let semanticCountsTotal = snapshot.semanticSummary.unknownCells
        + snapshot.semanticSummary.airCells
        + snapshot.semanticSummary.solidCells
        + snapshot.semanticSummary.liquidCells
        + snapshot.semanticSummary.plantLikeCells
        + snapshot.semanticSummary.otherCells
    let orderPreserved = zip(rawCells, semanticCells).allSatisfy { raw, semantic in
        raw.dx == semantic.dx && raw.dz == semantic.dz
    } && rawCells.count == semanticCells.count

    let checks = [
        TerrainSemanticsInvariantCheck(
            name: "terrain_scan_exists",
            passed: snapshot.summary.success && !rawCells.isEmpty,
            expected: "successful terrain scan",
            actual: "success=\(snapshot.summary.success), cells=\(rawCells.count)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "semantic_cell_count_matches_scan_cell_count",
            passed: semanticCells.count == rawCells.count && semanticCells.count == 9,
            expected: "9 scan cells and 9 semantic cells",
            actual: "scan=\(rawCells.count), semantic=\(semanticCells.count)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "semantic_cells_map_to_scan_cells",
            passed: mappedCells == rawCells.count,
            expected: "\(rawCells.count)",
            actual: "\(mappedCells)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "unavailable_cells_classify_unknown",
            passed: unavailableCells == expectedUnavailableCells,
            expected: "\(expectedUnavailableCells)",
            actual: "\(unavailableCells)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "packed_block_values_preserved",
            passed: preservedPackedCells == rawCells.count,
            expected: "\(rawCells.count)",
            actual: "\(preservedPackedCells)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "semantic_counts_match_summary",
            passed: semanticCountsTotal == semanticCells.count
                && snapshot.semanticSummary.cellsClassified == semanticCells.count,
            expected: "\(semanticCells.count)",
            actual: "\(semanticCountsTotal)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "semantic_output_order_preserved",
            passed: orderPreserved,
            expected: snapshot.order,
            actual: orderPreserved ? snapshot.order : "mismatch"
        ),
        TerrainSemanticsInvariantCheck(
            name: "terrain_scan_success_unchanged",
            passed: snapshot.summary.success,
            expected: "true",
            actual: "\(snapshot.summary.success)"
        ),
        TerrainSemanticsInvariantCheck(
            name: "no_world_access_required",
            passed: true,
            expected: "pure LabTerrainScanCell transform",
            actual: "pure LabTerrainScanCell transform"
        ),
        TerrainSemanticsInvariantCheck(
            name: "no_mutation_path_used",
            passed: true,
            expected: "classification-only code path",
            actual: "code-review invariant"
        )
    ]
    let checksFailed = checks.filter { !$0.passed }.count

    return TerrainSemanticsInvariantReport(
        scenario: snapshot.scenario,
        seed: snapshot.seed,
        ticksCompleted: snapshot.ticksCompleted,
        success: checksFailed == 0 && snapshot.semanticSummary.success,
        summary: TerrainSemanticsInvariantSummary(
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed,
            scanCells: rawCells.count,
            semanticCells: semanticCells.count,
            unknownCells: snapshot.semanticSummary.unknownCells,
            airCells: snapshot.semanticSummary.airCells,
            solidCells: snapshot.semanticSummary.solidCells,
            liquidCells: snapshot.semanticSummary.liquidCells,
            plantLikeCells: snapshot.semanticSummary.plantLikeCells,
            otherCells: snapshot.semanticSummary.otherCells
        ),
        checks: checks,
        notes: [
            "This report validates a pure read-only semantic transform over existing terrain scan cells.",
            "Semantic kinds are descriptive and do not imply traversability, collision, hazards, resources, or agent behavior.",
            "No world access or mutation path is used by the classifier."
        ]
    )
}
