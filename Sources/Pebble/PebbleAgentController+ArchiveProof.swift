import Foundation
import PebbleAgents
import PebbleCore

private struct ArchiveWritingFixture: Codable {
    let worldID: String
    let sign: AgentPosition
    let source: AgentPosition
    let signOriginal: Int
    let sourceOriginal: Int
}

private enum ArchiveProofError: Error {
    case failed(String)
}

extension PebbleAgentController {
    func runArchiveProof(
        phase: String,
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
              environment["PEBBLELAB_APP_AGENTS_ARCHIVE"] == "1",
              environment["PEBBLELAB_APP_AGENTS_WRITING"] == "1",
              let root = environment["PEBBLELAB_CIV46_PROOF_DIR"],
              let worldID = persistenceWorldID,
              var current = session,
              let author = probesByAgentId["agent_0"],
              let reader = probesByAgentId["agent_1"],
              let readerID = AgentID(rawValue: reader.labAgentId),
              isPaused,
              !movementEnabled else {
            return failure(
                "CIV-46 proof requires its isolated World gates and a live "
                    + "paused author."
            )
        }
        let directory = URL(fileURLWithPath: root, isDirectory: true)
        let fixtureURL = directory.appendingPathComponent(
            "writing-fixture.json"
        )
        let checkpointURL = directory.appendingPathComponent(
            "archive-checkpoint.json"
        )
        let retrievedCheckpointURL = directory.appendingPathComponent(
            "archive-retrieved-checkpoint.json"
        )
        let adapter = PebbleAgentArchiveAdapter()
        func require(_ condition: Bool, _ label: String) throws {
            guard condition else { throw ArchiveProofError.failed(label) }
            trace("CIV46_LIVE check=\(label) result=PASS")
        }
        do {
            let fixture = try AgentCheckpointCodec.decode(
                ArchiveWritingFixture.self,
                from: Data(contentsOf: fixtureURL)
            )
            try require(fixture.worldID == worldID, "same_real_world")
            if phase == "write" {
                guard let artifact = current.writingState?.artifacts.first,
                      artifact.plan.cell == fixture.sign else {
                    throw ArchiveProofError.failed("CIV45_material_source")
                }
                try current.setArchiveEnabled(true, worldID: worldID)
                let collection = try adapter.createCollection(
                    operationID: "civ46-live-library",
                    kind: .library,
                    catalogueArtifact: artifact,
                    actor: author,
                    world: world,
                    worldID: worldID,
                    session: current,
                    commit: { committed in current = committed }
                )
                let manuscript = try adapter.catalogueManuscript(
                    operationID: "civ46-live-source",
                    collection: collection,
                    catalogueArtifact: artifact,
                    artifact: artifact,
                    relationship: .source,
                    parentArtifact: nil,
                    actor: author,
                    world: world,
                    worldID: worldID,
                    session: current,
                    commit: { committed in current = committed }
                )
                let index = try current.rebuildArchiveIndex()
                let result = try adapter.search(
                    index: index,
                    collection: collection,
                    catalogueArtifact: artifact,
                    query: .artifact(artifact.artifactID),
                    actor: author,
                    world: world,
                    worldID: worldID,
                    session: current
                )
                try require(
                    result.hits.first?.entry.manuscriptID
                        == manuscript.manuscriptID,
                    "current_material_catalogue_search"
                )
                let checkpoint = try current.makeCheckpoint()
                try require(
                    checkpoint.schemaVersion
                        == AgentCheckpointSchema.archiveVersion,
                    "schema_41_checkpoint"
                )
                try AgentCheckpointCodec.encode(checkpoint).write(
                    to: checkpointURL,
                    options: .atomic
                )
                session = current
                trace(
                    "CIV46_LIVE phase=write collection="
                        + "\(collection.collectionID.rawValue) manuscript="
                        + "\(manuscript.manuscriptID.rawValue) artifact="
                        + "\(artifact.artifactID) schema=41 status=PASS"
                )
                return success(
                    "CIV-46 physical catalogue checkpoint saved for restart."
                )
            }
            guard phase == "read" else {
                throw ArchiveProofError.failed("unknown_phase")
            }
            let checkpointBytes = try Data(contentsOf: checkpointURL)
            let checkpoint = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self,
                from: checkpointBytes
            )
            current = try AgentSimulationSession.restoring(checkpoint)
            try require(
                try AgentCheckpointCodec.encode(current.makeCheckpoint())
                    == checkpointBytes,
                "fresh_process_archive_checkpoint_exact"
            )
            for agent in current.snapshot().agents {
                guard let probe = probesByAgentId[agent.id] else {
                    throw ArchiveProofError.failed("restored_probe_missing")
                }
                try require(
                    Int(floor(probe.x)) == agent.position.x
                        && Int(floor(probe.y)) == agent.position.y
                        && Int(floor(probe.z)) == agent.position.z,
                    "restored_probe_position_\(agent.id)"
                )
            }
            guard let artifact = current.writingState?.artifacts.first,
                  let collection = current.archiveState?.collections.first else {
                throw ArchiveProofError.failed("restored_archive_sources")
            }
            _ = try current.advanceTick(perceptions: [])
            try PebbleAgentWritingAdapter().practice(
                artifact: artifact,
                teacher: author,
                learner: reader,
                world: world,
                worldID: worldID,
                session: current,
                commit: { committed in current = committed }
            )
            try require(
                current.canUseWritingNotation(readerID),
                "restart_completes_CIV45_literacy"
            )
            let index = try current.rebuildArchiveIndex()
            let search = try adapter.search(
                index: index,
                collection: collection,
                catalogueArtifact: artifact,
                query: .artifact(artifact.artifactID),
                actor: reader,
                world: world,
                worldID: worldID,
                session: current
            )
            guard let selection = search.hits.first?.selection else {
                throw ArchiveProofError.failed("restarted_search")
            }
            let evidenceBefore = current.knowledgeSnapshot().evidence
            let truthBefore = world.getBlock(
                fixture.source.x,
                fixture.source.y,
                fixture.source.z
            )
            _ = try adapter.retrieve(
                operationID: "civ46-live-retrieve",
                selection: selection,
                artifact: artifact,
                actor: reader,
                world: world,
                worldID: worldID,
                session: current,
                commit: { committed in current = committed }
            )
            try require(
                current.archiveState?.retrievals.count == 1
                    && current.writingState?.readings.count == 1,
                "retrieval_delegates_to_CIV45"
            )
            try require(
                current.knowledgeSnapshot().evidence == evidenceBefore
                    && world.getBlock(
                        fixture.source.x,
                        fixture.source.y,
                        fixture.source.z
                    ) == truthBefore,
                "no_epistemic_evidence_or_World_truth_mutation"
            )
            let afterRetrieval = try current.durableStateBytes()
            _ = try adapter.retrieve(
                operationID: "civ46-live-retrieve",
                selection: selection,
                artifact: artifact,
                actor: reader,
                world: world,
                worldID: worldID,
                session: current,
                commit: { committed in current = committed }
            )
            try require(
                try current.durableStateBytes() == afterRetrieval,
                "retrieval_retry_idempotent"
            )
            try AgentCheckpointCodec.encode(current.makeCheckpoint()).write(
                to: retrievedCheckpointURL,
                options: .atomic
            )

            let beforeLoss = try current.durableStateBytes()
            world.setBlock(
                fixture.sign.x,
                fixture.sign.y,
                fixture.sign.z,
                0
            )
            do {
                _ = try adapter.search(
                    index: index,
                    collection: collection,
                    catalogueArtifact: artifact,
                    query: .artifact(artifact.artifactID),
                    actor: reader,
                    world: world,
                    worldID: worldID,
                    session: current
                )
                throw ArchiveProofError.failed("lost_catalogue_search_passed")
            } catch SignInscriptionError.unavailable { }
            do {
                _ = try adapter.retrieve(
                    operationID: "civ46-live-after-loss",
                    selection: selection,
                    artifact: artifact,
                    actor: reader,
                    world: world,
                    worldID: worldID,
                    session: current,
                    commit: { _ in
                        preconditionFailure("lost source publication")
                    }
                )
                throw ArchiveProofError.failed("lost_source_retrieval_passed")
            } catch SignInscriptionError.unavailable { }
            try require(
                try current.durableStateBytes() == beforeLoss
                    && search.hits.count == 1,
                "loss_refuses_access_without_index_resurrection"
            )
            let archiveBytes = try AgentCheckpointCodec.encode(
                current.archiveState!
            )
            let archiveText = String(decoding: archiveBytes, as: UTF8.self)
            try require(
                !archiveText.contains("lines")
                    && !archiveText.contains("assertedProposition")
                    && !archiveText.contains("postings"),
                "durable_archive_contains_metadata_not_content_or_index"
            )

            world.setBlock(
                fixture.sign.x,
                fixture.sign.y,
                fixture.sign.z,
                fixture.signOriginal
            )
            world.setBlock(
                fixture.source.x,
                fixture.source.y,
                fixture.source.z,
                fixture.sourceOriginal
            )
            try require(
                world.getBlock(
                    fixture.sign.x,
                    fixture.sign.y,
                    fixture.sign.z
                ) == fixture.signOriginal
                    && world.getBlockEntity(
                        fixture.sign.x,
                        fixture.sign.y,
                        fixture.sign.z
                    ) == nil
                    && world.getBlock(
                        fixture.source.x,
                        fixture.source.y,
                        fixture.source.z
                    ) == fixture.sourceOriginal,
                "fixture_cleanup_exact"
            )
            session = current
            trace(
                "CIV46_LIVE phase=read matches=\(search.totalMatches) "
                    + "retrievals=1 loss=REFUSED index=METADATA_ONLY "
                    + "cleanup=verified status=PASS"
            )
            return success(
                "CIV-46 restart, retrieval, loss and cleanup passed."
            )
        } catch {
            trace("CIV46_LIVE phase=\(phase) status=FAIL reason=\(error)")
            return failure("CIV-46 proof failed: \(error)")
        }
    }
}
