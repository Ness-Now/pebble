import Foundation
import PebbleAgents
import PebbleCore

enum PebbleAgentWritingAdapterError: Error {
    case unavailable(String)
    case rollbackUnverified
    case injected
}

/// Owns the entire physical inscription transaction. It owns no cognition and
/// has no object registry. Every access samples the real local Core block entity;
/// historical civilization rows never attest current material existence.
struct PebbleAgentWritingAdapter {
    func inscribe(plan: AgentWritingPlan, actor: LabCoreAgentEntity,
        world: World, worldID: String, session: inout AgentSimulationSession,
        failAfterMutation: Bool = false,
        publication: ((inout AgentSimulationSession, AgentWritingPhysicalReceipt) throws -> AgentWrittenArtifact)? = nil
    ) throws -> AgentWrittenArtifact {
        let position = try actorPosition(actor, world: world)
        guard worldID == plan.worldID, plan.dimension == String(world.dim.rawValue),
              try session.prepareWriting(authorID: plan.authorID,
                propositionID: plan.sourcePropositionID, materialID: plan.materialID, dimension: plan.dimension,
                cell: plan.cell, assertion: plan.assertion) == plan,
              actor.labAgentId == plan.authorID.rawValue else {
            throw PebbleAgentWritingAdapterError.unavailable("plan/World/actor")
        }
        try local(position, to: plan.cell, world: world)
        let (x, y, z) = (plan.cell.x, plan.cell.y, plan.cell.z)
        guard let be = world.getBlockEntity(x, y, z), let chunk = world.getChunkAt(x, z) else {
            throw PebbleAgentWritingAdapterError.unavailable("blank support missing")
        }
        let before = try bytes(be)
        let modifiedBefore = chunk.modified
        let blockBefore = world.getBlock(x, y, z)
        let identityBefore = peekNextEntityId()
        guard plan.materialID == identityBefore else {
            throw PebbleAgentWritingAdapterError.unavailable("stale physical identity reservation")
        }
        let stamp = try SignInscription(artifactID: plan.artifactID, materialID: plan.materialID, contentDigest: plan.contentDigest,
            worldID: worldID, dimension: world.dim.rawValue, x: x, y: y, z: z, lines: plan.lines)
        var inscribed = false
        do {
            try world.inscribeSign(stamp)
            inscribed = true
            if failAfterMutation { throw PebbleAgentWritingAdapterError.injected }
            let receipt = try observe(plan: plan, actor: actor, world: world,
                                      worldID: worldID, tick: session.tick)
            var candidate = session
            let accepted: AgentWrittenArtifact
            if let publication { accepted = try publication(&candidate, receipt) }
            else { accepted = try candidate.acceptWriting(plan, receipt: receipt) }
            guard candidate.writingState?.artifacts.last == accepted,
                  accepted.plan == plan, accepted.physicalReceipt == receipt else {
                throw PebbleAgentWritingAdapterError.unavailable("publication receipt")
            }
            guard try world.inspectSignInscription(at: x, y, z) == stamp,
                  world.getBlock(x, y, z) == blockBefore else {
                throw PebbleAgentWritingAdapterError.unavailable("post-publication verification")
            }
            session = candidate
            return accepted
        } catch {
            // This synchronous operation never moves blocks, inventories or actors.
            // Verify the complete original BE and the original physical block.
            guard world.getBlock(x, y, z) == blockBefore else {
                throw PebbleAgentWritingAdapterError.rollbackUnverified
            }
            if inscribed { try world.rollbackSignInscription(stamp) }
            world.setBlockEntity(try JSONDecoder().decode(BlockEntityData.self, from: before))
            guard peekNextEntityId() == identityBefore,
                  let restored = world.getBlockEntity(x, y, z), try bytes(restored) == before else {
                throw PebbleAgentWritingAdapterError.rollbackUnverified
            }
            chunk.modified = modifiedBefore
            throw error
        }
    }

    func observe(plan: AgentWritingPlan, actor: LabCoreAgentEntity,
        world: World, worldID: String, tick: Int) throws -> AgentWritingPhysicalReceipt {
        let position = try actorPosition(actor, world: world)
        try local(position, to: plan.cell, world: world)
        guard worldID == plan.worldID, plan.dimension == String(world.dim.rawValue) else {
            throw PebbleAgentWritingAdapterError.unavailable("different World")
        }
        let stamp = try world.inspectSignInscription(at: plan.cell.x, plan.cell.y, plan.cell.z)
        guard stamp.worldID == worldID, stamp.artifactID == plan.artifactID,
              stamp.materialID == plan.materialID,
              stamp.contentDigest == plan.contentDigest, stamp.lines == plan.lines else {
            throw PebbleAgentWritingAdapterError.unavailable("replaced or edited material inscription")
        }
        return AgentWritingPhysicalReceipt(worldID: worldID, dimension: plan.dimension,
            cell: plan.cell, blockKey: blockDefs[world.getBlock(plan.cell.x, plan.cell.y, plan.cell.z) >> 4].name,
            artifactID: stamp.artifactID, materialID: stamp.materialID, contentDigest: stamp.contentDigest, lines: stamp.lines,
            actorID: AgentID(rawValue: actor.labAgentId)!, actorPosition: position, observedAtTick: tick)
    }

    func read(artifact: AgentWrittenArtifact, actor: LabCoreAgentEntity,
        world: World, worldID: String, session: inout AgentSimulationSession) throws -> AgentWritingReading {
        let receipt = try observe(plan: artifact.plan, actor: actor, world: world,
                                   worldID: worldID, tick: session.tick)
        return try session.readWriting(artifactID: artifact.artifactID,
                                       readerID: receipt.actorID, receipt: receipt)
    }

    private func actorPosition(_ actor: LabCoreAgentEntity, world: World) throws -> AgentPosition {
        guard !actor.dead, actor.world === world,
              world.entityById[actor.id] === actor,
              AgentID(rawValue: actor.labAgentId) != nil,
              [actor.x, actor.y, actor.z].allSatisfy({ $0.isFinite && abs($0) < 30_000_000 }) else {
            throw PebbleAgentWritingAdapterError.unavailable("physical actor")
        }
        return AgentPosition(x: Int(floor(actor.x)), y: Int(floor(actor.y)), z: Int(floor(actor.z)))
    }

    private func local(_ actor: AgentPosition, to cell: AgentPosition, world: World) throws {
        guard [cell.x, cell.y, cell.z].allSatisfy({ (-30_000_000...30_000_000).contains($0) }),
              abs(actor.x - cell.x) + abs(actor.y - cell.y) + abs(actor.z - cell.z) <= 2,
              let chunk = world.getChunkAt(cell.x, cell.z), chunk.inYRange(cell.y),
              world.getChunkAt(actor.x, actor.z) != nil,
              blockDefs.indices.contains(world.getBlock(cell.x, cell.y - 1, cell.z) >> 4),
              blockDefs[world.getBlock(cell.x, cell.y - 1, cell.z) >> 4].solid else {
            throw PebbleAgentWritingAdapterError.unavailable("local supported inscription")
        }
    }

    private func bytes(_ value: BlockEntityData) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
}
