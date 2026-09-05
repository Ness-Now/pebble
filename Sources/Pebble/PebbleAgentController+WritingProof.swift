import Foundation
import PebbleAgents
import PebbleCore

private struct WritingProofFixture: Codable {
    let worldID: String
    let sign: AgentPosition
    let source: AgentPosition
    let signOriginal: Int
    let sourceOriginal: Int
}

private enum WritingProofError: Error { case failed(String) }

extension PebbleAgentController {
    func runWritingProof(phase: String, world: World, player: Player) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              environment["PEBBLELAB_APP_AGENTS_WRITING"] == "1",
              let root = environment["PEBBLELAB_CIV45_PROOF_DIR"],
              let worldID = persistenceWorldID, var current = session,
              let author = probesByAgentId["agent_0"], let reader = probesByAgentId["agent_1"],
              let authorID = AgentID(rawValue: author.labAgentId),
              let readerID = AgentID(rawValue: reader.labAgentId), isPaused, !movementEnabled else {
            return failure("CIV-45 proof requires its isolated World gates and two live paused actors.")
        }
        let directory = URL(fileURLWithPath: root, isDirectory: true)
        let checkpointURL = directory.appendingPathComponent("writing-checkpoint.json")
        let fixtureURL = directory.appendingPathComponent("writing-fixture.json")
        let adapter = PebbleAgentWritingAdapter()
        func require(_ condition: Bool, _ label: String) throws {
            guard condition else { throw WritingProofError.failed(label) }
            trace("CIV45_LIVE check=\(label) result=PASS")
        }
        func receipt(_ artifact: AgentWrittenArtifact, _ actor: LabCoreAgentEntity) throws -> AgentWritingPhysicalReceipt {
            try adapter.observe(plan: artifact.plan, actor: actor, world: world, worldID: worldID, tick: current.tick)
        }
        do {
            if phase == "write" {
                let a = current.snapshot().agents.first { $0.id == author.labAgentId }!.position
                let b = current.snapshot().agents.first { $0.id == reader.labAgentId }!.position
                let occupied = current.snapshot().agents.map(\.position)
                func distance(_ p: AgentPosition, _ q: AgentPosition) -> Int {
                    abs(p.x - q.x) + abs(p.y - q.y) + abs(p.z - q.z)
                }
                var sites: [AgentPosition] = []
                // Natural slopes need a bounded vertical search. The support
                // still has to be within the product's two-cell access radius.
                for dy in -2...2 { for dx in -6...6 { for dz in -6...6 {
                    let p = AgentPosition(x: a.x + dx, y: a.y + dy, z: a.z + dz)
                    if distance(a, p) <= 6, !occupied.contains(where: {
                        $0.x == p.x && $0.z == p.z && (p.y == $0.y || p.y == $0.y + 1)
                    }),
                       world.getChunkAt(p.x, p.z) != nil,
                       world.getBlock(p.x, p.y, p.z) == 0,
                       world.getBlockEntity(p.x, p.y, p.z) == nil,
                       blockDefs[world.getBlock(p.x, p.y - 1, p.z) >> 4].solid { sites.append(p) }
                } } }
                guard let sign = sites.first(where: { distance($0, a) <= 2 && distance($0, b) <= 2 }),
                      let source = sites.first(where: { $0 != sign }) else {
                    throw WritingProofError.failed("natural_local_supported_sites_unavailable")
                }
                let fixture = WritingProofFixture(worldID: worldID, sign: sign, source: source,
                    signOriginal: world.getBlock(sign.x, sign.y, sign.z),
                    sourceOriginal: world.getBlock(source.x, source.y, source.z))
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try AgentCheckpointCodec.encode(fixture).write(to: fixtureURL, options: .atomic)
                // Disclosed inputs only: blank existing Pebble support and one
                // resource block. No inscription, belief or literacy is seeded.
                let orientation = abs(sign.x - a.x) > abs(sign.z - a.z) ? 4 : 0
                world.setBlock(sign.x, sign.y, sign.z, (Int(bid("oak_sign")) << 4) | orientation)
                world.setBlockEntity(makeSignBE(sign.x, sign.y, sign.z))
                world.setBlock(source.x, source.y, source.z, Int(bid("oak_log")) << 4)
                try current.setSocialEnabled(true)
                try current.setKnowledgeGraphEnabled(true)
                let fingerprint = world.getBlock(source.x, source.y, source.z)
                try require(blockDefs[fingerprint >> 4].name == "oak_log", "real_source_sensor")
                _ = try current.advanceTick(perceptions: [AgentPerceptionInput(agentId: author.labAgentId,
                    socialResourceObservations: [AgentResourceObservation(resource: .wood, target: source,
                        direction: AgentResourcePerception.direction(observerPosition: a, target: source)!,
                        distanceManhattan: distance(a, source), quantityAvailable: 1,
                        source: .naturalWorld, expectedBlockFingerprint: fingerprint)])])
                guard let proposition = current.knowledgeSnapshot().beliefs.first(where: {
                    $0.ownerID == authorID
                })?.propositionID else { throw WritingProofError.failed("sensor_did_not_create_author_belief") }
                try current.setLanguageEnabled(true)
                let senses = AgentLanguagePack.frenchReference.entries.map(\.senseID)
                try current.seedLanguagePrior(for: authorID, senseIDs: senses)
                try current.seedLanguagePrior(for: readerID, senseIDs: senses)
                try current.setWritingEnabled(true, worldID: worldID)
                try current.seedWritingEducationalPrior(for: authorID)
                let plan = try current.prepareWriting(authorID: authorID, propositionID: proposition,
                    materialID: peekNextEntityId(), dimension: String(world.dim.rawValue), cell: sign,
                    assertion: .deliberateCounterAssertion(.resource(kind: .stone, fingerprint: nil)))
                let before = try current.durableStateBytes()
                do {
                    _ = try adapter.inscribe(plan: plan, actor: author, world: world, worldID: worldID,
                        session: &current, failAfterMutation: true)
                    throw WritingProofError.failed("injected_mutation_unexpectedly_passed")
                } catch PebbleAgentWritingAdapterError.injected { }
                try require(try current.durableStateBytes() == before
                    && peekNextEntityId() == plan.materialID
                    && world.getBlockEntity(sign.x, sign.y, sign.z)?.lines == ["", "", "", ""]
                    && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil,
                    "late_failure_exact_rollback")
                let artifact = try adapter.inscribe(plan: plan, actor: author, world: world,
                    worldID: worldID, session: &current)
                try require(peekNextEntityId() == plan.materialID + 1, "Core_physical_identity_consumed_once")
                if let remote = probesByAgentId["agent_2"] {
                    do {
                        _ = try adapter.observe(plan: plan, actor: remote, world: world, worldID: worldID, tick: current.tick)
                        throw WritingProofError.failed("remote_material_access_accepted")
                    } catch PebbleAgentWritingAdapterError.unavailable { }
                    trace("CIV45_LIVE check=remote_material_access_refused result=PASS")
                }
                do {
                    _ = try adapter.observe(plan: plan, actor: reader, world: world, worldID: "incompatible-world", tick: current.tick)
                    throw WritingProofError.failed("foreign_world_access_accepted")
                } catch PebbleAgentWritingAdapterError.unavailable { }
                trace("CIV45_LIVE check=foreign_world_access_refused result=PASS")
                try require(world.getBlock(source.x, source.y, source.z) == fingerprint,
                            "false_inscription_world_unchanged")
                do {
                    _ = try adapter.read(artifact: artifact, actor: reader, world: world,
                        worldID: worldID, session: &current)
                    throw WritingProofError.failed("unlearned_reader_accepted")
                } catch AgentWritingError.unavailable { }
                try require(!current.canUseWritingNotation(readerID), "oral_only_reader_refused")
                try current.practiceWritingNotation(artifactID: artifact.artifactID,
                    teacherID: authorID, learnerID: readerID,
                    teacherReceipt: receipt(artifact, author), learnerReceipt: receipt(artifact, reader))
                try require(!current.canUseWritingNotation(readerID), "first_local_lesson_incomplete")
                try AgentCheckpointCodec.encode(current.makeCheckpoint()).write(to: checkpointURL, options: .atomic)
                try AgentCheckpointCodec.encode(world.inspectSignInscription(at: sign.x, sign.y, sign.z))
                    .write(to: directory.appendingPathComponent("written-sign.json"), options: .atomic)
                session = current
                trace("CIV45_LIVE phase=write artifact=\(artifact.artifactID) materialID=\(plan.materialID) nextCoreIdentity=\(peekNextEntityId()) sign=\(positionText(sign)) source=\(positionText(source)) sourceBlock=oak_log assertion=stone authorBelief=wood tick=\(current.tick) schema=40 status=PASS")
                return success("CIV-45 physical inscription saved for separate-process restart.")
            }
            let fixture = try AgentCheckpointCodec.decode(WritingProofFixture.self, from: Data(contentsOf: fixtureURL))
            try require(fixture.worldID == worldID, "same_real_world")
            if phase == "camera" {
                // Move only the observer camera to a verified actor's open
                // body volume. Never reposition a civilization actor.
                let a = current.snapshot().agents.first { $0.id == author.labAgentId }!.position
                player.setPos(Double(a.x) + 0.5, Double(a.y), Double(a.z) + 0.5)
                player.vx = 0; player.vy = 0; player.vz = 0
                let dx = Double(fixture.sign.x) + 0.5 - player.x
                let dz = Double(fixture.sign.z) + 0.5 - player.z
                let dy = Double(fixture.sign.y) + 0.8 - player.eyeY()
                player.yaw = atan2(-dx, dz)
                player.pitch = atan2(-dy, (dx * dx + dz * dz).squareRoot())
                trace("CIV45_LIVE phase=camera status=PASS actorMutation=none")
                return success("CIV-45 observer looking at the physical sign.")
            }
            if phase == "read" {
                let bytes = try Data(contentsOf: checkpointURL)
                let checkpoint = try AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: bytes)
                let restored = try AgentSimulationSession.restoring(checkpoint)
                try require(try AgentCheckpointCodec.encode(restored.makeCheckpoint()) == bytes, "fresh_process_checkpoint_exact")
                for agent in restored.snapshot().agents {
                    guard let probe = probesByAgentId[agent.id] else { throw WritingProofError.failed("restored_probe_missing") }
                    try require(Int(floor(probe.x)) == agent.position.x && Int(floor(probe.y)) == agent.position.y
                        && Int(floor(probe.z)) == agent.position.z, "restored_probe_position_\(agent.id)")
                }
                current = restored
                guard let artifact = current.writingState?.artifacts.first else { throw WritingProofError.failed("missing_inscription") }
                _ = try receipt(artifact, reader)
                let loadedSignBytes = try AgentCheckpointCodec.encode(world.inspectSignInscription(
                    at: fixture.sign.x, fixture.sign.y, fixture.sign.z))
                try require(try loadedSignBytes == Data(contentsOf: directory.appendingPathComponent("written-sign.json")),
                            "separate_process_Core_sign_bytes_exact")
                try loadedSignBytes.write(to: directory.appendingPathComponent("reloaded-sign.json"), options: .atomic)
                try require(!current.canUseWritingNotation(readerID), "partial_literacy_survives_restart")
                try require(world.getBlock(fixture.source.x, fixture.source.y, fixture.source.z) == Int(bid("oak_log")) << 4,
                            "saved_world_still_wood")
                _ = try current.advanceTick(perceptions: [])
                try current.practiceWritingNotation(artifactID: artifact.artifactID,
                    teacherID: authorID, learnerID: readerID,
                    teacherReceipt: receipt(artifact, author), learnerReceipt: receipt(artifact, reader))
                try require(current.canUseWritingNotation(readerID), "second_local_lesson_learns")
                let reading = try adapter.read(artifact: artifact, actor: reader, world: world,
                    worldID: worldID, session: &current)
                try require(current.knowledgeSnapshot().claims.contains { $0.claimID == reading.claimID
                    && $0.writtenSource?.artifactID == artifact.artifactID && $0.sourceEvidenceID == nil }, "CIV41_attributed_written_claim")
                try require(current.knowledgeSnapshot().beliefs.contains { $0.ownerID == readerID
                    && $0.propositionID == artifact.plan.assertedProposition.propositionID }, "reader_false_belief")
                try require(world.getBlock(fixture.source.x, fixture.source.y, fixture.source.z) == Int(bid("oak_log")) << 4,
                            "reading_does_not_change_world_truth")
                session = current
                try AgentCheckpointCodec.encode(current.makeCheckpoint())
                    .write(to: directory.appendingPathComponent("reading-checkpoint.json"), options: .atomic)
                trace("CIV45_LIVE phase=read artifact=\(artifact.artifactID) reading=\(reading.readingID) sourceBlock=oak_log assertion=stone schema=40 status=PASS")
                return success("CIV-45 restarted local reading traversed CIV-42 and CIV-41.")
            }
            guard phase == "destroy" else { throw WritingProofError.failed("unknown_phase") }
            guard let artifact = current.writingState?.artifacts.first else { throw WritingProofError.failed("missing_inscription") }
            let cell = fixture.sign
            guard let be = world.getBlockEntity(cell.x, cell.y, cell.z) else { throw WritingProofError.failed("missing_material_sign") }
            be.lines = ["changed", "", "", ""]
            be.lines = artifact.plan.lines
            do { _ = try receipt(artifact, reader); throw WritingProofError.failed("edit_resurrected_identity") }
            catch SignInscriptionError.unavailable { }
            try require(be.signInscription == nil, "normal_edit_invalidates_identity")
            world.setBlock(cell.x, cell.y, cell.z, 0)
            world.setBlock(cell.x, cell.y, cell.z, Int(bid("oak_sign")) << 4)
            world.setBlockEntity(makeSignBE(cell.x, cell.y, cell.z))
            world.getBlockEntity(cell.x, cell.y, cell.z)!.lines = artifact.plan.lines
            let before = try current.durableStateBytes()
            do {
                _ = try adapter.read(artifact: artifact, actor: reader, world: world,
                    worldID: worldID, session: &current)
                throw WritingProofError.failed("replacement_resurrected_identity")
            } catch SignInscriptionError.unavailable { }
            try require(try current.durableStateBytes() == before, "replacement_refuses_without_cognition")
            world.setBlock(cell.x, cell.y, cell.z, fixture.signOriginal)
            world.setBlock(fixture.source.x, fixture.source.y, fixture.source.z, fixture.sourceOriginal)
            try require(world.getBlock(cell.x, cell.y, cell.z) == fixture.signOriginal
                && world.getBlockEntity(cell.x, cell.y, cell.z) == nil
                && world.getBlock(fixture.source.x, fixture.source.y, fixture.source.z) == fixture.sourceOriginal,
                "fixture_cleanup_exact")
            trace("CIV45_LIVE phase=destroy status=PASS cleanup=verified")
            return success("CIV-45 normal edit, destruction and replacement refuse old identity; fixture restored.")
        } catch {
            trace("CIV45_LIVE phase=\(phase) status=FAIL reason=\(error)")
            if let bytes = try? Data(contentsOf: fixtureURL),
               let fixture = try? AgentCheckpointCodec.decode(WritingProofFixture.self, from: bytes),
               fixture.worldID == worldID {
                world.setBlock(fixture.sign.x, fixture.sign.y, fixture.sign.z, fixture.signOriginal)
                world.setBlock(fixture.source.x, fixture.source.y, fixture.source.z, fixture.sourceOriginal)
                let clean = world.getBlock(fixture.sign.x, fixture.sign.y, fixture.sign.z) == fixture.signOriginal
                    && world.getBlockEntity(fixture.sign.x, fixture.sign.y, fixture.sign.z) == nil
                    && world.getBlock(fixture.source.x, fixture.source.y, fixture.source.z) == fixture.sourceOriginal
                trace("CIV45_LIVE failureCleanup=\(clean ? "verified" : "FAIL")")
            }
            return failure("CIV-45 proof failed: \(error)")
        }
    }
}
