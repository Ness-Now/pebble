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
