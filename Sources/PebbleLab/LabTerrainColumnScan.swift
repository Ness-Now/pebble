import PebbleCore

enum LabTerrainColumnCellRole: String, Encodable {
    case support
    case feet
    case head
}

struct LabTerrainColumnScanCell: Encodable {
    let role: LabTerrainColumnCellRole
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let chunk: LabWorldInteractionChunk
    let cell: Int?
    let blockId: Int?
    let meta: Int?
    let blockName: String?
    let chunkStateUnchanged: Bool
    let success: Bool
}

struct LabTerrainColumnScan: Encodable {
    let dx: Int
    let dz: Int
    let x: Int
    let y: Int
    let z: Int
    let support: LabTerrainColumnScanCell
    let feet: LabTerrainColumnScanCell
    let head: LabTerrainColumnScanCell
    let semanticColumn: LabTerrainColumnSemantic?
    let traversability: LabTerrainTraversabilityCell?
}

struct LabTerrainColumnScanSummary: Encodable {
    let columnsPlanned: Int
    let columnsObserved: Int
    let cellsPlanned: Int
    let cellsObserved: Int
    let loadedCells: Int
    let readyCells: Int
    let uniqueChunks: Int
    let chunkStateUnchanged: Bool
    let success: Bool
}

struct LabTerrainColumnDerivedSummary {
    let semanticCells: Int
    let traversabilityCells: Int
    let traversableCells: Int
    let unsafeCells: Int
    let unknownCells: Int
    let unsupportedCells: Int
    let occupiedVerticalSpaceCells: Int
    let success: Bool
}

struct LabTerrainColumnScanSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let agentPosition: LabAgentPosition
    let coreEntityPosition: LabAgentPosition
    let divergence: Int
    let linksCoherent: Bool
    let radius: Int
    let relation: String
    let horizontalOrder: String
    let verticalOrder: String
    let columns: [LabTerrainColumnScan]
    let summary: LabTerrainColumnScanSummary
}

struct TerrainColumnScanInvariantReport: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: TerrainColumnScanInvariantSummary
    let checks: [TerrainColumnScanInvariantCheck]
    let notes: [String]
}

struct TerrainColumnScanInvariantSummary: Encodable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let placeholders: Int
    let coreEntities: Int
    let columns: Int
    let cells: Int
}

struct TerrainColumnScanInvariantCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabTerrainColumnScanScenarioContract {
    let scenario: String
    let agentX: Int
    let agentZ: Int
    let radius: Int
    let expectedColumns: Int
    let expectedCells: Int
    let expectedUniqueChunks: Int?
    let requiresChunkBoundaryCrossing: Bool
}

func terrainColumnScanScenarioContract(
    for scenario: String
) -> LabTerrainColumnScanScenarioContract? {
    switch scenario {
    case "terrain_column_scan_smoke", "terrain_pathfinding_column_smoke":
        return LabTerrainColumnScanScenarioContract(
            scenario: scenario,
            agentX: 8,
            agentZ: 8,
            radius: 1,
            expectedColumns: 9,
            expectedCells: 27,
            expectedUniqueChunks: nil,
            requiresChunkBoundaryCrossing: false
        )
    case "terrain_column_scan_edge_smoke":
        return LabTerrainColumnScanScenarioContract(
            scenario: scenario,
            agentX: 16,
            agentZ: 16,
            radius: 1,
            expectedColumns: 9,
            expectedCells: 27,
            expectedUniqueChunks: 4,
            requiresChunkBoundaryCrossing: true
        )
    default:
        return nil
    }
}

func isTerrainColumnScanScenario(_ scenario: String) -> Bool {
    terrainColumnScanScenarioContract(for: scenario) != nil
}

private let terrainColumnRelation = "support_feet_head"
private let terrainColumnHorizontalOrder = "dz_then_dx"
private let terrainColumnVerticalOrder = "support_feet_head"

private func terrainScanCell(from cell: LabTerrainColumnScanCell) -> LabTerrainScanCell {
    LabTerrainScanCell(
        dx: cell.dx,
        dz: cell.dz,
        x: cell.x,
        y: cell.y,
        z: cell.z,
        chunk: cell.chunk,
        cell: cell.cell,
        blockId: cell.blockId,
        meta: cell.meta,
        blockName: cell.blockName,
        chunkStateUnchanged: cell.chunkStateUnchanged,
        success: cell.success
    )
}

private func cells(in column: LabTerrainColumnScan) -> [LabTerrainColumnScanCell] {
    [column.support, column.feet, column.head]
}

func scanTerrainColumns(
    world: World,
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    agent: LabAgent,
    handle: LabPhysicalAgentHandle,
    coreLink: LabCoreAgentLink,
    contract: LabTerrainColumnScanScenarioContract
) -> LabTerrainColumnScanSnapshot {
    func readCell(
        role: LabTerrainColumnCellRole,
        dx: Int,
        dz: Int,
        x: Int,
        y: Int,
        z: Int
    ) -> LabTerrainColumnScanCell {
        let cx = floorDiv(x, CHUNK_W)
        let cz = floorDiv(z, CHUNK_W)
        let loaded = world.isLoadedAt(x, z)
        let ready = world.isChunkReady(cx, cz)
        let chunk = world.getChunk(cx, cz)
        let modifiedBefore = chunk?.modified
        let versionBefore = chunk?.version
        let dirtyBefore = chunk?.dirty
        let packedCell = loaded && ready ? world.getBlock(x, y, z) : nil
        let blockId = packedCell.map { $0 >> 4 }
        let meta = packedCell.map { $0 & 15 }
        let validBlockId = blockId.map { $0 >= 0 && $0 < blockDefs.count } ?? false
        let blockName = validBlockId ? blockId.map { blockDefs[$0].name } : nil
        let chunkStateUnchanged = modifiedBefore == chunk?.modified
            && versionBefore == chunk?.version
            && dirtyBefore == chunk?.dirty

        return LabTerrainColumnScanCell(
            role: role,
            dx: dx,
            dz: dz,
            x: x,
            y: y,
            z: z,
            chunk: LabWorldInteractionChunk(cx: cx, cz: cz, loaded: loaded, ready: ready),
            cell: packedCell,
            blockId: blockId,
            meta: meta,
            blockName: blockName,
            chunkStateUnchanged: chunkStateUnchanged,
            success: loaded && ready && validBlockId && chunkStateUnchanged
        )
    }

    let baseY = agent.position.y
    var columns: [LabTerrainColumnScan] = []
    for dz in -contract.radius...contract.radius {
        for dx in -contract.radius...contract.radius {
            let x = agent.position.x + dx
            let z = agent.position.z + dz
            let support = readCell(
                role: .support, dx: dx, dz: dz, x: x, y: baseY - 1, z: z
            )
            let feet = readCell(
                role: .feet, dx: dx, dz: dz, x: x, y: baseY, z: z
            )
            let head = readCell(
                role: .head, dx: dx, dz: dz, x: x, y: baseY + 1, z: z
            )
            let semanticColumn = LabTerrainColumnSemantic(
                x: x,
                y: baseY,
                z: z,
                support: classifyTerrainCell(terrainScanCell(from: support)),
                feet: classifyTerrainCell(terrainScanCell(from: feet)),
                head: classifyTerrainCell(terrainScanCell(from: head))
            )
            columns.append(LabTerrainColumnScan(
                dx: dx,
                dz: dz,
                x: x,
                y: baseY,
                z: z,
                support: support,
                feet: feet,
                head: head,
                semanticColumn: semanticColumn,
                traversability: classifyTerrainTraversability(semanticColumn)
            ))
        }
    }

    let allCells = columns.flatMap(cells)
    let columnsObserved = columns.filter { cells(in: $0).allSatisfy { $0.cell != nil } }.count
    let cellsObserved = allCells.filter { $0.cell != nil }.count
    let loadedCells = allCells.filter { $0.chunk.loaded }.count
    let readyCells = allCells.filter { $0.chunk.ready }.count
    let uniqueChunks = Set(allCells.map { "\($0.chunk.cx),\($0.chunk.cz)" }).count
    let chunkStateUnchanged = allCells.allSatisfy(\.chunkStateUnchanged)
    let linksCoherent = handle.agentId == agent.id
        && coreLink.agentId == agent.id
        && handle.physicalId == coreLink.physicalId
    let success = linksCoherent
        && coreLink.divergence == 0
        && columns.count == contract.expectedColumns
        && columnsObserved == contract.expectedColumns
        && allCells.count == contract.expectedCells
        && cellsObserved == contract.expectedCells
        && loadedCells == contract.expectedCells
        && readyCells == contract.expectedCells
        && (contract.expectedUniqueChunks == nil
            || uniqueChunks == contract.expectedUniqueChunks)
        && chunkStateUnchanged
        && allCells.allSatisfy(\.success)

    return LabTerrainColumnScanSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: coreLink.coreEntityId,
        agentPosition: agent.position,
        coreEntityPosition: coreLink.coreEntityPosition,
        divergence: coreLink.divergence,
        linksCoherent: linksCoherent,
        radius: contract.radius,
        relation: terrainColumnRelation,
        horizontalOrder: terrainColumnHorizontalOrder,
        verticalOrder: terrainColumnVerticalOrder,
        columns: columns,
        summary: LabTerrainColumnScanSummary(
            columnsPlanned: contract.expectedColumns,
            columnsObserved: columnsObserved,
            cellsPlanned: contract.expectedCells,
            cellsObserved: cellsObserved,
            loadedCells: loadedCells,
            readyCells: readyCells,
            uniqueChunks: uniqueChunks,
            chunkStateUnchanged: chunkStateUnchanged,
            success: success
        )
    )
}

func makeTerrainColumnDerivedSummary(
    snapshot: LabTerrainColumnScanSnapshot
) -> LabTerrainColumnDerivedSummary {
    let traversability = snapshot.columns.compactMap(\.traversability)
    let semanticCells = snapshot.columns.reduce(0) { count, column in
        count + (column.semanticColumn == nil ? 0 : 3)
    }
    let kindCount: (LabTerrainTraversabilityKind) -> Int = { kind in
        traversability.filter { $0.kind == kind }.count
    }
    return LabTerrainColumnDerivedSummary(
        semanticCells: semanticCells,
        traversabilityCells: traversability.count,
        traversableCells: kindCount(.traversable),
        unsafeCells: kindCount(.unsafe),
        unknownCells: kindCount(.unknown),
        unsupportedCells: kindCount(.unsupported),
        occupiedVerticalSpaceCells: kindCount(.occupiedVerticalSpace),
        success: semanticCells == 27 && traversability.count == 9
    )
}

func makeTerrainColumnScanInvariantReport(
    snapshot: LabTerrainColumnScanSnapshot,
    agents: Int,
    placeholders: Int,
    coreEntities: Int,
    contract: LabTerrainColumnScanScenarioContract
) -> TerrainColumnScanInvariantReport {
    var expectedOffsets: [(Int, Int)] = []
    for dz in -contract.radius...contract.radius {
        for dx in -contract.radius...contract.radius {
            expectedOffsets.append((dx, dz))
        }
    }
    let actualOffsets = snapshot.columns.map { ($0.dx, $0.dz) }
    let horizontalOrderValid = actualOffsets.count == expectedOffsets.count
        && zip(actualOffsets, expectedOffsets).allSatisfy { actual, expected in
            actual.0 == expected.0 && actual.1 == expected.1
        }
    let allCells = snapshot.columns.flatMap(cells)
    let verticalOrderValid = snapshot.columns.allSatisfy {
        $0.support.role == .support && $0.feet.role == .feet && $0.head.role == .head
    }
    let loadedReadyDecoded = allCells.filter {
        $0.cell != nil && $0.chunk.loaded && $0.chunk.ready
    }.count
    let rolesComplete = snapshot.columns.filter { column in
        let roles = cells(in: column).map(\.role)
        return roles == [.support, .feet, .head]
    }.count
    let uniqueRoleTargets = Set(allCells.map { "\($0.role.rawValue),\($0.x),\($0.y),\($0.z)" }).count
    let unchangedCells = allCells.filter(\.chunkStateUnchanged).count
    let validPackedCells = allCells.filter { scanCell in
        guard let cell = scanCell.cell,
              let blockId = scanCell.blockId,
              let meta = scanCell.meta,
              let blockName = scanCell.blockName,
              blockId >= 0,
              blockId < blockDefs.count,
              (0...15).contains(meta) else {
            return false
        }
        return cell == ((blockId << 4) | meta) && blockDefs[blockId].name == blockName
    }.count
    let linksCoherent = agents == 1
        && placeholders == 1
        && coreEntities == 1
        && snapshot.linksCoherent
        && !snapshot.agentId.isEmpty
        && !snapshot.physicalId.isEmpty
        && snapshot.coreEntityId > 0

    var checks = [
        TerrainColumnScanInvariantCheck(name: "agent_exists", passed: agents == 1, expected: "1", actual: "\(agents)"),
        TerrainColumnScanInvariantCheck(name: "physical_core_links_coherent", passed: linksCoherent, expected: "one coherent link", actual: "agents=\(agents), placeholders=\(placeholders), coreEntities=\(coreEntities)"),
        TerrainColumnScanInvariantCheck(name: "abstract_core_divergence_zero", passed: snapshot.divergence == 0, expected: "0", actual: "\(snapshot.divergence)"),
        TerrainColumnScanInvariantCheck(name: "radius_equals_one", passed: snapshot.radius == contract.radius, expected: "\(contract.radius)", actual: "\(snapshot.radius)"),
        TerrainColumnScanInvariantCheck(name: "horizontal_order_dz_then_dx", passed: snapshot.horizontalOrder == terrainColumnHorizontalOrder && horizontalOrderValid, expected: terrainColumnHorizontalOrder, actual: snapshot.horizontalOrder),
        TerrainColumnScanInvariantCheck(name: "vertical_order_support_feet_head", passed: snapshot.verticalOrder == terrainColumnVerticalOrder && verticalOrderValid, expected: terrainColumnVerticalOrder, actual: snapshot.verticalOrder),
        TerrainColumnScanInvariantCheck(name: "columns_planned_equals_nine", passed: snapshot.summary.columnsPlanned == contract.expectedColumns, expected: "\(contract.expectedColumns)", actual: "\(snapshot.summary.columnsPlanned)"),
        TerrainColumnScanInvariantCheck(name: "cells_planned_equals_twenty_seven", passed: snapshot.summary.cellsPlanned == contract.expectedCells, expected: "\(contract.expectedCells)", actual: "\(snapshot.summary.cellsPlanned)"),
        TerrainColumnScanInvariantCheck(name: "cells_observed_equals_twenty_seven", passed: snapshot.summary.cellsObserved == contract.expectedCells, expected: "\(contract.expectedCells)", actual: "\(snapshot.summary.cellsObserved)"),
        TerrainColumnScanInvariantCheck(name: "all_decoded_cells_loaded_ready", passed: loadedReadyDecoded == contract.expectedCells, expected: "\(contract.expectedCells)", actual: "\(loadedReadyDecoded)"),
        TerrainColumnScanInvariantCheck(name: "all_columns_have_three_roles", passed: rolesComplete == contract.expectedColumns, expected: "\(contract.expectedColumns)", actual: "\(rolesComplete)"),
        TerrainColumnScanInvariantCheck(name: "target_coordinates_unique_per_role", passed: uniqueRoleTargets == contract.expectedCells, expected: "\(contract.expectedCells) unique", actual: "\(uniqueRoleTargets) unique"),
        TerrainColumnScanInvariantCheck(name: "all_chunks_unchanged", passed: unchangedCells == contract.expectedCells && snapshot.summary.chunkStateUnchanged, expected: "\(contract.expectedCells)", actual: "\(unchangedCells)"),
        TerrainColumnScanInvariantCheck(name: "all_packed_cells_valid", passed: validPackedCells == contract.expectedCells, expected: "\(contract.expectedCells)", actual: "\(validPackedCells)"),
        TerrainColumnScanInvariantCheck(name: "raw_scan_success_true", passed: snapshot.summary.success, expected: "true", actual: "\(snapshot.summary.success)"),
        TerrainColumnScanInvariantCheck(name: "no_mutation_path_used", passed: true, expected: "guarded World.getBlock only", actual: "code-review invariant"),
        TerrainColumnScanInvariantCheck(name: "no_pathfinding_performed", passed: true, expected: "none", actual: "code-review invariant"),
        TerrainColumnScanInvariantCheck(name: "no_agent_movement_commanded", passed: true, expected: "none", actual: "code-review invariant")
    ]
    if contract.requiresChunkBoundaryCrossing {
        checks.append(TerrainColumnScanInvariantCheck(
            name: "edge_column_scan_crosses_chunk_boundary",
            passed: snapshot.summary.uniqueChunks > 1,
            expected: "> 1",
            actual: "\(snapshot.summary.uniqueChunks)"
        ))
        if let expectedUniqueChunks = contract.expectedUniqueChunks {
            checks.append(TerrainColumnScanInvariantCheck(
                name: "edge_column_scan_expected_unique_chunks",
                passed: snapshot.summary.uniqueChunks == expectedUniqueChunks,
                expected: "\(expectedUniqueChunks)",
                actual: "\(snapshot.summary.uniqueChunks)"
            ))
        }
    }
    let checksPassed = checks.filter(\.passed).count
    let checksFailed = checks.count - checksPassed
    return TerrainColumnScanInvariantReport(
        scenario: snapshot.scenario,
        seed: snapshot.seed,
        ticksCompleted: snapshot.ticksCompleted,
        success: snapshot.summary.success && checksFailed == 0,
        summary: TerrainColumnScanInvariantSummary(
            checksPassed: checksPassed,
            checksFailed: checksFailed,
            agents: agents,
            placeholders: placeholders,
            coreEntities: coreEntities,
            columns: snapshot.columns.count,
            cells: allCells.count
        ),
        checks: checks,
        notes: [
            "This report validates a read-only support/feet/head column scan.",
            "It does not prove pathfinding, collision, movement, or mutation safety."
        ]
    )
}
