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
