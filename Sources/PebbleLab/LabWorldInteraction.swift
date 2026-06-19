import PebbleCore

struct LabWorldInteractionTarget: Encodable {
    let x: Int
    let y: Int
    let z: Int
}

struct LabWorldInteractionChunk: Encodable {
    let cx: Int
    let cz: Int
    let loaded: Bool
    let ready: Bool
}

struct LabWorldInteractionSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let relation: String
    let agentPosition: LabAgentPosition
    let coreEntityPosition: LabAgentPosition
    let divergence: Int
    let target: LabWorldInteractionTarget
    let chunk: LabWorldInteractionChunk
    let cell: Int?
    let blockId: Int?
    let meta: Int?
    let blockName: String?
    let chunkStateUnchanged: Bool
    let success: Bool
}

struct LabWorldInteractionObservation: Encodable {
    let agentId: String
    let physicalId: String
    let coreEntityId: Int
    let relation: String
    let agentPosition: LabAgentPosition
    let coreEntityPosition: LabAgentPosition
    let divergence: Int
    let target: LabWorldInteractionTarget
    let chunk: LabWorldInteractionChunk
    let cell: Int?
    let blockId: Int?
    let meta: Int?
    let blockName: String?
    let chunkStateUnchanged: Bool
    let success: Bool

    init(snapshot: LabWorldInteractionSnapshot) {
        agentId = snapshot.agentId
        physicalId = snapshot.physicalId
        coreEntityId = snapshot.coreEntityId
        relation = snapshot.relation
        agentPosition = snapshot.agentPosition
        coreEntityPosition = snapshot.coreEntityPosition
        divergence = snapshot.divergence
        target = snapshot.target
        chunk = snapshot.chunk
        cell = snapshot.cell
        blockId = snapshot.blockId
        meta = snapshot.meta
        blockName = snapshot.blockName
        chunkStateUnchanged = snapshot.chunkStateUnchanged
        success = snapshot.success
    }
}

struct LabWorldInteractionMultiSummary: Encodable {
    let agents: Int
    let observations: Int
    let loadedObservations: Int
    let readyObservations: Int
    let uniqueChunks: Int
    let distinctBlockIds: Int
    let success: Bool
}

struct LabWorldInteractionMultiSnapshot: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let observations: [LabWorldInteractionObservation]
    let summary: LabWorldInteractionMultiSummary
}

struct WorldObservationInvariantReport: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: WorldObservationInvariantSummary
    let checks: [WorldObservationInvariantCheck]
    let notes: [String]
}

struct WorldObservationInvariantSummary: Encodable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let observations: Int
    let linkedObservations: Int
    let loadedObservations: Int
    let readyObservations: Int
    let successfulObservations: Int
    let zeroDivergenceObservations: Int
    let unchangedChunkObservations: Int
    let validBlockObservations: Int
    let uniqueChunks: Int
    let distinctBlockIds: Int
}

struct WorldObservationInvariantCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

struct LabTerrainScanCell: Encodable {
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

struct LabTerrainScanSummary: Encodable {
    let cellsPlanned: Int
    let cellsObserved: Int
    let loadedCells: Int
    let readyCells: Int
    let distinctBlockIds: Int
    let uniqueChunks: Int
    let chunkStateUnchanged: Bool
    let success: Bool
}

struct LabTerrainScanSnapshot: Encodable {
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
    let origin: LabWorldInteractionTarget
    let radius: Int
    let relation: String
    let order: String
    let cells: [LabTerrainScanCell]
    let summary: LabTerrainScanSummary
}

struct TerrainScanInvariantReport: Encodable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: TerrainScanInvariantSummary
    let checks: [TerrainScanInvariantCheck]
    let notes: [String]
}

struct TerrainScanInvariantSummary: Encodable {
    let checksPassed: Int
    let checksFailed: Int
    let agents: Int
    let placeholders: Int
    let coreEntities: Int
    let radius: Int
    let cellsPlanned: Int
    let cellsObserved: Int
    let loadedCells: Int
    let readyCells: Int
    let distinctBlockIds: Int
    let uniqueChunks: Int
}

struct TerrainScanInvariantCheck: Encodable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

func observeBlockBelow(
    world: World,
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    agent: LabAgent,
    handle: LabPhysicalAgentHandle,
    coreLink: LabCoreAgentLink
) -> LabWorldInteractionSnapshot {
    let target = LabWorldInteractionTarget(
        x: agent.position.x,
        y: agent.position.y - 1,
        z: agent.position.z
    )
    let cx = floorDiv(target.x, CHUNK_W)
    let cz = floorDiv(target.z, CHUNK_W)
    let loaded = world.isLoadedAt(target.x, target.z)
    let ready = world.isChunkReady(cx, cz)
    let chunk = world.getChunk(cx, cz)
    let modifiedBefore = chunk?.modified
    let versionBefore = chunk?.version
    let dirtyBefore = chunk?.dirty

    let cell = loaded && ready ? world.getBlock(target.x, target.y, target.z) : nil
    let blockId = cell.map { $0 >> 4 }
    let meta = cell.map { $0 & 15 }
    let validBlockId = blockId.map { $0 >= 0 && $0 < blockDefs.count } ?? false
    let blockName = blockId.map { id in
        validBlockId ? blockDefs[id].name : "block_\(id)"
    }
    let chunkStateUnchanged = modifiedBefore == chunk?.modified
        && versionBefore == chunk?.version
        && dirtyBefore == chunk?.dirty
    let linksMatch = handle.agentId == agent.id
        && coreLink.agentId == agent.id
        && handle.physicalId == coreLink.physicalId

    return LabWorldInteractionSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: coreLink.coreEntityId,
        relation: "below",
        agentPosition: agent.position,
        coreEntityPosition: coreLink.coreEntityPosition,
        divergence: coreLink.divergence,
        target: target,
        chunk: LabWorldInteractionChunk(cx: cx, cz: cz, loaded: loaded, ready: ready),
        cell: cell,
        blockId: blockId,
        meta: meta,
        blockName: blockName,
        chunkStateUnchanged: chunkStateUnchanged,
        success: linksMatch
            && coreLink.divergence == 0
            && loaded
            && ready
            && validBlockId
            && chunkStateUnchanged
    )
}

func makeWorldInteractionMultiSnapshot(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    snapshots: [LabWorldInteractionSnapshot],
    agents: Int,
    placeholders: Int,
    coreEntities: Int
) -> LabWorldInteractionMultiSnapshot {
    let ordered = snapshots.sorted { $0.agentId < $1.agentId }
    let loadedObservations = ordered.filter { $0.chunk.loaded }.count
    let readyObservations = ordered.filter { $0.chunk.ready }.count
    let uniqueChunks = Set(ordered.map { "\($0.chunk.cx),\($0.chunk.cz)" }).count
    let distinctBlockIds = Set(ordered.compactMap(\.blockId)).count
    let success = agents == 3
        && placeholders == 3
        && coreEntities == 3
        && ordered.count == 3
        && loadedObservations == 3
        && readyObservations == 3
        && ordered.allSatisfy {
            $0.success && $0.divergence == 0 && $0.chunkStateUnchanged
        }

    return LabWorldInteractionMultiSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        observations: ordered.map(LabWorldInteractionObservation.init),
        summary: LabWorldInteractionMultiSummary(
            agents: agents,
            observations: ordered.count,
            loadedObservations: loadedObservations,
            readyObservations: readyObservations,
            uniqueChunks: uniqueChunks,
            distinctBlockIds: distinctBlockIds,
            success: success
        )
    )
}

func makeWorldObservationInvariantReport(
    snapshot: LabWorldInteractionMultiSnapshot
) -> WorldObservationInvariantReport {
    let observations = snapshot.observations
    let uniqueAgentIds = Set(observations.map(\.agentId)).count
    let uniquePhysicalIds = Set(observations.map(\.physicalId)).count
    let uniqueCoreEntityIds = Set(observations.map(\.coreEntityId)).count
    let linkedObservations = observations.filter {
        !$0.agentId.isEmpty && !$0.physicalId.isEmpty && $0.coreEntityId > 0
    }.count
    let loadedObservations = observations.filter { $0.chunk.loaded }.count
    let readyObservations = observations.filter { $0.chunk.ready }.count
    let successfulObservations = observations.filter(\.success).count
    let zeroDivergenceObservations = observations.filter { $0.divergence == 0 }.count
    let unchangedChunkObservations = observations.filter(\.chunkStateUnchanged).count
    let validBlockObservations = observations.filter { observation in
        guard let cell = observation.cell,
              let blockId = observation.blockId,
              let meta = observation.meta,
              let blockName = observation.blockName,
              blockId >= 0,
              blockId < blockDefs.count,
              (0...15).contains(meta) else {
            return false
        }
        return cell == ((blockId << 4) | meta) && blockDefs[blockId].name == blockName
    }.count
    let belowObservations = observations.filter { $0.relation == "below" }.count
    let distinctBlockIds = Set(observations.compactMap(\.blockId)).count
    let linksAreUnique = uniqueAgentIds == observations.count
        && uniquePhysicalIds == observations.count
        && uniqueCoreEntityIds == observations.count
    let diversityAccounted = distinctBlockIds >= 1
        && distinctBlockIds == snapshot.summary.distinctBlockIds

    let checks = [
        WorldObservationInvariantCheck(
            name: "agent_count",
            passed: snapshot.summary.agents == 3 && uniqueAgentIds == 3,
            expected: "3",
            actual: "\(snapshot.summary.agents)"
        ),
        WorldObservationInvariantCheck(
            name: "observation_count",
            passed: observations.count == 3 && linkedObservations == 3 && linksAreUnique,
            expected: "3",
            actual: "\(observations.count)"
        ),
        WorldObservationInvariantCheck(
            name: "all_observations_loaded",
            passed: loadedObservations == 3,
            expected: "3",
            actual: "\(loadedObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_observations_ready",
            passed: readyObservations == 3,
            expected: "3",
            actual: "\(readyObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_observations_successful",
            passed: successfulObservations == 3,
            expected: "3",
            actual: "\(successfulObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_divergences_zero",
            passed: zeroDivergenceObservations == 3,
            expected: "3",
            actual: "\(zeroDivergenceObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_chunks_unchanged",
            passed: unchangedChunkObservations == 3,
            expected: "3",
            actual: "\(unchangedChunkObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_blocks_valid",
            passed: validBlockObservations == 3,
            expected: "3",
            actual: "\(validBlockObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "all_relations_below",
            passed: belowObservations == 3,
            expected: "3",
            actual: "\(belowObservations)"
        ),
        WorldObservationInvariantCheck(
            name: "block_id_diversity_accounted",
            passed: diversityAccounted,
            expected: ">= 1",
            actual: "\(distinctBlockIds)"
        )
    ]
    let checksFailed = checks.filter { !$0.passed }.count

    return WorldObservationInvariantReport(
        scenario: snapshot.scenario,
        seed: snapshot.seed,
        ticksCompleted: snapshot.ticksCompleted,
        success: checksFailed == 0,
        summary: WorldObservationInvariantSummary(
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed,
            agents: snapshot.summary.agents,
            observations: observations.count,
            linkedObservations: linkedObservations,
            loadedObservations: loadedObservations,
            readyObservations: readyObservations,
            successfulObservations: successfulObservations,
            zeroDivergenceObservations: zeroDivergenceObservations,
            unchangedChunkObservations: unchangedChunkObservations,
            validBlockObservations: validBlockObservations,
            uniqueChunks: snapshot.summary.uniqueChunks,
            distinctBlockIds: distinctBlockIds
        ),
        checks: checks,
        notes: [
            "This report validates read-only multi-agent world observation.",
            "It does not prove terrain scanning, pathfinding, collision, mining, construction, inventory, or mutation safety."
        ]
    )
}

func scanTerrainAroundBelow(
    world: World,
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int,
    agent: LabAgent,
    handle: LabPhysicalAgentHandle,
    coreLink: LabCoreAgentLink
) -> LabTerrainScanSnapshot {
    let radius = 1
    let origin = LabWorldInteractionTarget(
        x: agent.position.x,
        y: agent.position.y - 1,
        z: agent.position.z
    )
    var cells: [LabTerrainScanCell] = []

    for dz in -radius...radius {
        for dx in -radius...radius {
            let x = origin.x + dx
            let y = origin.y
            let z = origin.z + dz
            let cx = floorDiv(x, CHUNK_W)
            let cz = floorDiv(z, CHUNK_W)
            let loaded = world.isLoadedAt(x, z)
            let ready = world.isChunkReady(cx, cz)
            let chunk = world.getChunk(cx, cz)
            let modifiedBefore = chunk?.modified
            let versionBefore = chunk?.version
            let dirtyBefore = chunk?.dirty

            let cell = loaded && ready ? world.getBlock(x, y, z) : nil
            let blockId = cell.map { $0 >> 4 }
            let meta = cell.map { $0 & 15 }
            let validBlockId = blockId.map { $0 >= 0 && $0 < blockDefs.count } ?? false
            let blockName = validBlockId ? blockId.map { blockDefs[$0].name } : nil
            let chunkStateUnchanged = modifiedBefore == chunk?.modified
                && versionBefore == chunk?.version
                && dirtyBefore == chunk?.dirty

            cells.append(LabTerrainScanCell(
                dx: dx,
                dz: dz,
                x: x,
                y: y,
                z: z,
                chunk: LabWorldInteractionChunk(
                    cx: cx,
                    cz: cz,
                    loaded: loaded,
                    ready: ready
                ),
                cell: cell,
                blockId: blockId,
                meta: meta,
                blockName: blockName,
                chunkStateUnchanged: chunkStateUnchanged,
                success: loaded && ready && validBlockId && chunkStateUnchanged
            ))
        }
    }

    let cellsObserved = cells.filter { $0.cell != nil }.count
    let loadedCells = cells.filter { $0.chunk.loaded }.count
    let readyCells = cells.filter { $0.chunk.ready }.count
    let distinctBlockIds = Set(cells.compactMap(\.blockId)).count
    let uniqueChunks = Set(cells.map { "\($0.chunk.cx),\($0.chunk.cz)" }).count
    let chunkStateUnchanged = cells.allSatisfy(\.chunkStateUnchanged)
    let linksMatch = handle.agentId == agent.id
        && coreLink.agentId == agent.id
        && handle.physicalId == coreLink.physicalId
    let success = linksMatch
        && coreLink.divergence == 0
        && cells.count == 9
        && cellsObserved == 9
        && loadedCells == 9
        && readyCells == 9
        && distinctBlockIds > 0
        && chunkStateUnchanged
        && cells.allSatisfy(\.success)

    return LabTerrainScanSnapshot(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        agentId: agent.id,
        physicalId: handle.physicalId,
        coreEntityId: coreLink.coreEntityId,
        agentPosition: agent.position,
        coreEntityPosition: coreLink.coreEntityPosition,
        divergence: coreLink.divergence,
        linksCoherent: linksMatch,
        origin: origin,
        radius: radius,
        relation: "around_below",
        order: "dz_then_dx",
        cells: cells,
        summary: LabTerrainScanSummary(
            cellsPlanned: 9,
            cellsObserved: cellsObserved,
            loadedCells: loadedCells,
            readyCells: readyCells,
            distinctBlockIds: distinctBlockIds,
            uniqueChunks: uniqueChunks,
            chunkStateUnchanged: chunkStateUnchanged,
            success: success
        )
    )
}

func makeTerrainScanInvariantReport(
    snapshot: LabTerrainScanSnapshot,
    agents: Int,
    placeholders: Int,
    coreEntities: Int
) -> TerrainScanInvariantReport {
    let expectedOffsets = [
        (-1, -1), (0, -1), (1, -1),
        (-1, 0), (0, 0), (1, 0),
        (-1, 1), (0, 1), (1, 1)
    ]
    let actualOffsets = snapshot.cells.map { ($0.dx, $0.dz) }
    let offsetsOrdered = zip(actualOffsets, expectedOffsets).allSatisfy { actual, expected in
        actual.0 == expected.0 && actual.1 == expected.1
    } && actualOffsets.count == expectedOffsets.count
    let uniqueTargets = Set(snapshot.cells.map { "\($0.x),\($0.y),\($0.z)" }).count
    let loadedAndReadyCells = snapshot.cells.filter {
        $0.cell != nil && $0.chunk.loaded && $0.chunk.ready
    }.count
    let unchangedCells = snapshot.cells.filter(\.chunkStateUnchanged).count
    let distinctBlockIds = Set(snapshot.cells.compactMap(\.blockId)).count
    let validPackedCells = snapshot.cells.filter { scanCell in
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
        TerrainScanInvariantCheck(
            name: "agent_exists",
            passed: agents == 1 && !snapshot.agentId.isEmpty,
            expected: "1",
            actual: "\(agents)"
        ),
        TerrainScanInvariantCheck(
            name: "physical_core_links_coherent",
            passed: linksCoherent,
            expected: "one coherent link",
            actual: "agents=\(agents), placeholders=\(placeholders), coreEntities=\(coreEntities)"
        ),
        TerrainScanInvariantCheck(
            name: "abstract_core_divergence_zero",
            passed: snapshot.divergence == 0,
            expected: "0",
            actual: "\(snapshot.divergence)"
        ),
        TerrainScanInvariantCheck(
            name: "radius_equals_one",
            passed: snapshot.radius == 1,
            expected: "1",
            actual: "\(snapshot.radius)"
        ),
        TerrainScanInvariantCheck(
            name: "relation_around_below",
            passed: snapshot.relation == "around_below",
            expected: "around_below",
            actual: snapshot.relation
        ),
        TerrainScanInvariantCheck(
            name: "order_dz_then_dx",
            passed: snapshot.order == "dz_then_dx",
            expected: "dz_then_dx",
            actual: snapshot.order
        ),
        TerrainScanInvariantCheck(
            name: "cells_planned_equals_nine",
            passed: snapshot.summary.cellsPlanned == 9,
            expected: "9",
            actual: "\(snapshot.summary.cellsPlanned)"
        ),
        TerrainScanInvariantCheck(
            name: "cells_observed_equals_nine",
            passed: snapshot.summary.cellsObserved == 9,
            expected: "9",
            actual: "\(snapshot.summary.cellsObserved)"
        ),
        TerrainScanInvariantCheck(
            name: "all_decoded_cells_loaded_ready",
            passed: loadedAndReadyCells == 9,
            expected: "9",
            actual: "\(loadedAndReadyCells)"
        ),
        TerrainScanInvariantCheck(
            name: "all_chunks_unchanged",
            passed: unchangedCells == 9 && snapshot.summary.chunkStateUnchanged,
            expected: "9",
            actual: "\(unchangedCells)"
        ),
        TerrainScanInvariantCheck(
            name: "offsets_deterministic_dz_then_dx",
            passed: offsetsOrdered,
            expected: "9 ordered offsets",
            actual: "\(actualOffsets.count) ordered offsets"
        ),
        TerrainScanInvariantCheck(
            name: "target_coordinates_unique",
            passed: uniqueTargets == 9,
            expected: "9 unique",
            actual: "\(uniqueTargets) unique"
        ),
        TerrainScanInvariantCheck(
            name: "distinct_block_ids_accounted",
            passed: distinctBlockIds > 0
                && distinctBlockIds == snapshot.summary.distinctBlockIds,
            expected: ">= 1 and matches summary",
            actual: "\(distinctBlockIds)"
        ),
        TerrainScanInvariantCheck(
            name: "all_packed_cells_valid",
            passed: validPackedCells == 9,
            expected: "9",
            actual: "\(validPackedCells)"
        ),
        TerrainScanInvariantCheck(
            name: "no_mutation_path_used",
            passed: true,
            expected: "guarded World.getBlock only",
            actual: "code-review invariant"
        )
    ]

    if snapshot.scenario == "terrain_scan_edge_smoke" {
        checks.append(TerrainScanInvariantCheck(
            name: "edge_scan_crosses_chunk_boundary",
            passed: snapshot.summary.uniqueChunks > 1,
            expected: "> 1",
            actual: "\(snapshot.summary.uniqueChunks)"
        ))
        checks.append(TerrainScanInvariantCheck(
            name: "edge_scan_expected_unique_chunks",
            passed: snapshot.summary.uniqueChunks == 4,
            expected: "4",
            actual: "\(snapshot.summary.uniqueChunks)"
        ))
    }
    let checksFailed = checks.filter { !$0.passed }.count

    return TerrainScanInvariantReport(
        scenario: snapshot.scenario,
        seed: snapshot.seed,
        ticksCompleted: snapshot.ticksCompleted,
        success: checksFailed == 0 && snapshot.summary.success,
        summary: TerrainScanInvariantSummary(
            checksPassed: checks.count - checksFailed,
            checksFailed: checksFailed,
            agents: agents,
            placeholders: placeholders,
            coreEntities: coreEntities,
            radius: snapshot.radius,
            cellsPlanned: snapshot.summary.cellsPlanned,
            cellsObserved: snapshot.summary.cellsObserved,
            loadedCells: snapshot.summary.loadedCells,
            readyCells: snapshot.summary.readyCells,
            distinctBlockIds: snapshot.summary.distinctBlockIds,
            uniqueChunks: snapshot.summary.uniqueChunks
        ),
        checks: checks,
        notes: [
            "This report validates the bounded read-only terrain scan smoke.",
            "The no-mutation check is a code-review contract; the runtime checks also require unchanged chunk state.",
            "It does not prove pathfinding, collision, traversability, mining, construction, or multi-agent scanning."
        ]
    )
}
