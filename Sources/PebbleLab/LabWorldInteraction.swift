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
