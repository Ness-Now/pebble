import Foundation
import PebbleAgents
import PebbleCore

enum PebbleAgentWritingAdapterError: Error {
    case unavailable(String)
    case rollbackUnverified
    case injected
}

private struct PebbleAgentWritingPhysicalAccess {
    let actorID: AgentID
    let actorPosition: AgentPosition
}

/// Owns the entire physical inscription transaction and the physical-to-
/// cognitive publication boundary. It owns no cognition and has no object
/// registry. Core validates only current material authority and holds that
/// authority while an opaque candidate session is committed by Pebble.
struct PebbleAgentWritingAdapter {
    func inscribe(
        plan: AgentWritingPlan,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        failAfterMutation: Bool = false,
        publication: ((inout AgentSimulationSession, AgentWritingPhysicalReceipt) throws -> AgentWrittenArtifact)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws -> AgentWrittenArtifact {
        let access = try physicalAccess(actor, plan: plan, world: world, worldID: worldID)
        guard try session.prepareWriting(
            authorID: plan.authorID,
            propositionID: plan.sourcePropositionID,
            materialID: plan.materialID,
            dimension: plan.dimension,
            cell: plan.cell,
            assertion: plan.assertion
        ) == plan, actor.labAgentId == plan.authorID.rawValue else {
            throw PebbleAgentWritingAdapterError.unavailable("plan/World/actor")
        }

        let (x, y, z) = (plan.cell.x, plan.cell.y, plan.cell.z)
        guard let blockEntity = world.getBlockEntity(x, y, z),
              let chunk = world.getChunkAt(x, z) else {
            throw PebbleAgentWritingAdapterError.unavailable("blank support missing")
        }
        let before = try bytes(blockEntity)
        let modifiedBefore = chunk.modified
        let blockBefore = world.getBlock(x, y, z)
        let identityBefore = peekNextEntityId()
        guard plan.materialID == identityBefore else {
            throw PebbleAgentWritingAdapterError.unavailable("stale physical identity reservation")
        }
        let stamp = try SignInscription(
            artifactID: plan.artifactID,
            materialID: plan.materialID,
            contentDigest: plan.contentDigest,
            worldID: worldID,
            dimension: world.dim.rawValue,
            x: x,
            y: y,
            z: z,
            lines: plan.lines
        )

        var inscribed = false
        do {
            try world.inscribeSign(stamp)
            inscribed = true
            return try withCurrentReceipt(
                plan: plan,
                access: access,
                world: world,
                worldID: worldID,
                tick: session.tick
            ) { receipt in
                do {
                    if failAfterMutation { throw PebbleAgentWritingAdapterError.injected }
                    var candidate = session
                    let accepted: AgentWrittenArtifact
                    if let publication {
                        accepted = try publication(&candidate, receipt)
                    } else {
                        accepted = try candidate.acceptWriting(plan, receipt: receipt)
                    }
                    guard candidate.writingState?.artifacts.last == accepted,
                          accepted.plan == plan,
                          accepted.physicalReceipt == receipt,
                          try world.inspectSignInscription(at: x, y, z) == stamp,
                          world.getBlock(x, y, z) == blockBefore else {
                        throw PebbleAgentWritingAdapterError.unavailable("publication verification")
                    }

                    // This callback is the publication point. It is the final
                    // throwing-free step and still runs under Core authority.
                    commit(candidate)
                    return accepted
                } catch {
                    // Publication did not occur. This catch still runs under
                    // Core's recursive authority lock, so exact rollback and
                    // identity release cannot race an index advancement.
                    do {
                        try world.rollbackSignInscription(stamp)
                        chunk.modified = modifiedBefore
                        inscribed = false
                        guard peekNextEntityId() == identityBefore,
                              let restored = world.getBlockEntity(x, y, z),
                              try bytes(restored) == before,
                              world.getBlock(x, y, z) == blockBefore else {
                            throw PebbleAgentWritingAdapterError.rollbackUnverified
                        }
                    } catch {
                        throw PebbleAgentWritingAdapterError.rollbackUnverified
                    }
                    throw error
                }
            }
        } catch {
            guard inscribed else { throw error }
            // Authority could not be established (for example, an external
            // replacement). Never overwrite such later physical state.
            guard world.getBlock(x, y, z) == blockBefore,
                  world.getBlockEntity(x, y, z)?.signInscription == stamp,
                  world.getBlockEntity(x, y, z)?.lines == stamp.lines else {
                throw PebbleAgentWritingAdapterError.rollbackUnverified
            }
            do {
                // The candidate may already have crossed a save boundary.
                // Restore its exact material state but burn the identity.
                try world.abandonSignInscription(stamp)
                guard peekNextEntityId() == identityBefore + 1,
                      let restored = world.getBlockEntity(x, y, z),
                      try bytes(restored) == before else {
                    throw PebbleAgentWritingAdapterError.rollbackUnverified
                }
            } catch {
                throw PebbleAgentWritingAdapterError.rollbackUnverified
            }
            throw error
        }
    }

    func inspect(
        plan: AgentWritingPlan,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        tick: Int
    ) throws {
        let access = try physicalAccess(actor, plan: plan, world: world, worldID: worldID)
        try withCurrentReceipt(
            plan: plan,
            access: access,
            world: world,
            worldID: worldID,
            tick: tick
        ) { _ in () }
    }

    func read(
        artifact: AgentWrittenArtifact,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        publication: ((inout AgentSimulationSession, AgentWritingPhysicalReceipt) throws -> AgentWritingReading)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws -> AgentWritingReading {
        let plan = artifact.plan
        let access = try physicalAccess(actor, plan: plan, world: world, worldID: worldID)
        return try withCurrentReceipt(
            plan: plan,
            access: access,
            world: world,
            worldID: worldID,
            tick: session.tick
        ) { receipt in
            var candidate = session
            let reading: AgentWritingReading
            if let publication {
                reading = try publication(&candidate, receipt)
            } else {
                reading = try candidate.readWriting(
                    artifactID: artifact.artifactID,
                    readerID: receipt.actorID,
                    receipt: receipt
                )
            }
            guard candidate.writingState?.readings.last == reading else {
                throw PebbleAgentWritingAdapterError.unavailable("reading publication")
            }
            commit(candidate)
            return reading
        }
    }

    func practice(
        artifact: AgentWrittenArtifact,
        teacher: LabCoreAgentEntity,
        learner: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        publication: ((inout AgentSimulationSession, AgentWritingPhysicalReceipt, AgentWritingPhysicalReceipt) throws -> Void)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws {
        let plan = artifact.plan
        let teacherAccess = try physicalAccess(teacher, plan: plan, world: world, worldID: worldID)
        let learnerAccess = try physicalAccess(learner, plan: plan, world: world, worldID: worldID)
        try world.withCurrentSignInscriptionAuthority(at: plan.cell.x, plan.cell.y, plan.cell.z) { stamp in
            try require(stamp, matches: plan, worldID: worldID)
            let teacherReceipt = try receipt(
                stamp: stamp, access: teacherAccess, world: world, tick: session.tick
            )
            let learnerReceipt = try receipt(
                stamp: stamp, access: learnerAccess, world: world, tick: session.tick
            )
            var candidate = session
            if let publication {
                try publication(&candidate, teacherReceipt, learnerReceipt)
            } else {
                try candidate.practiceWritingNotation(
                    artifactID: artifact.artifactID,
                    teacherID: teacherReceipt.actorID,
                    learnerID: learnerReceipt.actorID,
                    teacherReceipt: teacherReceipt,
                    learnerReceipt: learnerReceipt
                )
            }
            commit(candidate)
        }
    }

    private func withCurrentReceipt<T>(
        plan: AgentWritingPlan,
        access: PebbleAgentWritingPhysicalAccess,
        world: World,
        worldID: String,
        tick: Int,
        _ body: (AgentWritingPhysicalReceipt) throws -> T
    ) throws -> T {
        try world.withCurrentSignInscriptionAuthority(at: plan.cell.x, plan.cell.y, plan.cell.z) { stamp in
            try require(stamp, matches: plan, worldID: worldID)
            return try body(try receipt(stamp: stamp, access: access, world: world, tick: tick))
        }
    }

    private func require(
        _ stamp: SignInscription,
        matches plan: AgentWritingPlan,
        worldID: String
    ) throws {
        guard stamp.worldID == worldID,
              stamp.artifactID == plan.artifactID,
              stamp.materialID == plan.materialID,
              stamp.contentDigest == plan.contentDigest,
              stamp.lines == plan.lines else {
            throw PebbleAgentWritingAdapterError.unavailable("replaced or edited material inscription")
        }
    }

    private func receipt(
        stamp: SignInscription,
        access: PebbleAgentWritingPhysicalAccess,
        world: World,
        tick: Int
    ) throws -> AgentWritingPhysicalReceipt {
        let blockID = world.getBlock(stamp.x, stamp.y, stamp.z) >> 4
        guard blockDefs.indices.contains(blockID) else {
            throw PebbleAgentWritingAdapterError.unavailable("physical block")
        }
        return AgentWritingPhysicalReceipt(
            worldID: stamp.worldID,
            dimension: String(stamp.dimension),
            cell: AgentPosition(x: stamp.x, y: stamp.y, z: stamp.z),
            blockKey: blockDefs[blockID].name,
            artifactID: stamp.artifactID,
            materialID: stamp.materialID,
            contentDigest: stamp.contentDigest,
            lines: stamp.lines,
            actorID: access.actorID,
            actorPosition: access.actorPosition,
            observedAtTick: tick
        )
    }

    private func physicalAccess(
        _ actor: LabCoreAgentEntity,
        plan: AgentWritingPlan,
        world: World,
        worldID: String
    ) throws -> PebbleAgentWritingPhysicalAccess {
        guard worldID == plan.worldID,
              plan.dimension == String(world.dim.rawValue) else {
            throw PebbleAgentWritingAdapterError.unavailable("different World")
        }
        let position = try actorPosition(actor, world: world)
        try local(position, to: plan.cell, world: world)
        return PebbleAgentWritingPhysicalAccess(
            actorID: AgentID(rawValue: actor.labAgentId)!,
            actorPosition: position
        )
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
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }
}
