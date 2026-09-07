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

private struct WritingCorrection04Fixture: Codable {
    let worldID: String
    let original: AgentPosition
    let allocation: AgentPosition
    let materialID: Int
    let burnedMaterialID: Int
    let externalLines: [String]
}

private enum WritingProofError: Error { case failed(String) }

extension PebbleAgentController {
    func runWritingProof(
        phase: String,
        world: World,
        player: Player,
        game: GameCore?
    ) -> PebbleAgentCommandResult {
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
        let correction04URL = directory.appendingPathComponent("writing-correction04.json")
        let adapter = PebbleAgentWritingAdapter()
        func require(_ condition: Bool, _ label: String) throws {
            guard condition else { throw WritingProofError.failed(label) }
            trace("CIV45_LIVE check=\(label) result=PASS")
        }
        func inspect(_ artifact: AgentWrittenArtifact, _ actor: LabCoreAgentEntity) throws {
            try adapter.inspect(
                plan: artifact.plan,
                actor: actor,
                world: world,
                worldID: worldID,
                tick: current.tick
            )
        }
        func practice(
            _ artifact: AgentWrittenArtifact,
            teacher: LabCoreAgentEntity,
            learner: LabCoreAgentEntity
        ) throws {
            try adapter.practice(
                artifact: artifact,
                teacher: teacher,
                learner: learner,
                world: world,
                worldID: worldID,
                session: current,
                commit: { committed in
                    current = committed
                    self.session = committed
                }
            )
        }
        do {
            if phase == "correction04-restart" {
                guard let game,
                      let fixtureBytes = try? Data(contentsOf: correction04URL),
                      let fixture = try? AgentCheckpointCodec.decode(
                        WritingCorrection04Fixture.self,
                        from: fixtureBytes
                      ), fixture.worldID == worldID else {
                    throw WritingProofError.failed("Correction_04_restart_fixture")
                }
                let residentOriginal = world.getBlockEntity(
                    fixture.original.x,
                    fixture.original.y,
                    fixture.original.z
                )
                let residentAllocation = try world.inspectSignInscription(
                    at: fixture.allocation.x,
                    fixture.allocation.y,
                    fixture.allocation.z
                )
                let durable = game.db.getChunk(
                    worldID,
                    world.dim.rawValue,
                    floorDiv(fixture.original.x, CHUNK_W),
                    floorDiv(fixture.original.z, CHUNK_W)
                )
                let durableOriginal = durable?.blockEntities?.first(where: {
                    $0.x == fixture.original.x
                        && $0.y == fixture.original.y
                        && $0.z == fixture.original.z
                })
                let durableAllocation = durable?.blockEntities?.first(where: {
                    $0.x == fixture.allocation.x
                        && $0.y == fixture.allocation.y
                        && $0.z == fixture.allocation.z
                })?.signInscription
                try require(
                    residentOriginal?.signInscription == nil
                        && residentOriginal?.lines == fixture.externalLines
                        && residentAllocation.materialID == fixture.materialID
                        && durableOriginal?.signInscription == nil
                        && durableOriginal?.lines == fixture.externalLines
                        && durableAllocation?.materialID == fixture.materialID,
                    "c04_separate_process_resident_equals_durable"
                )
                try require(
                    game.worldRec?.nextEntityId ?? 0 > fixture.burnedMaterialID
                        && peekNextEntityId() > fixture.burnedMaterialID
                        && game.db.lastSignInscriptionIndexLoadMetrics.indexedChunkRows > 0
                        && game.db.lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads == 0
                        && game.db.lastSignInscriptionIndexLoadMetrics.decodedVoxelCells == 0,
                    "c04_separate_process_identity_and_compact_index"
                )
                try require(
                    current.writingState?.artifacts.isEmpty != false,
                    "c04_separate_process_has_no_accepted_cognition"
                )
                trace(
                    "CIV45_C04_RESTART process=2 resident=durable originalGhost=NO "
                        + "allocation=\(fixture.materialID) burned=\(fixture.burnedMaterialID) "
                        + "worldNext=\(game.worldRec?.nextEntityId ?? -1) "
                        + "liveNext=\(peekNextEntityId()) compactIndexRows="
                        + "\(game.db.lastSignInscriptionIndexLoadMetrics.indexedChunkRows) "
                        + "cognitiveMutation=ZERO status=PASS"
                )
                return success("CIV-45 Correction 04 separate-process restart passed.")
            }
            if phase == "write" || phase == "correction04" {
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
                if phase == "correction04" {
                    guard let game else { throw WritingProofError.failed("missing_GameCore") }
                    game.saveAndFlush(synchronous: true)
                    world.getChunkAt(sign.x, sign.z)!.modified = true

                    let captureAttempted = DispatchSemaphore(value: 0)
                    let prepared = DispatchSemaphore(value: 0)
                    let saveReturned = DispatchSemaphore(value: 0)
                    let saveCommitted = DispatchSemaphore(value: 0)
                    let eventLock = NSLock()
                    var events: [String] = []
                    var preparedObservedFinalPhysicalState = false
                    game.testingSignInscriptionPersistenceCaptureHook = {
                        eventLock.lock()
                        events.append("capture-attempt")
                        eventLock.unlock()
                        captureAttempted.signal()
                    }
                    game.db.testingSignInscriptionPersistenceHook = { boundary in
                        if boundary == .prepared {
                            eventLock.lock()
                            events.append("prepared-after-rollback")
                            preparedObservedFinalPhysicalState =
                                peekNextEntityId() == plan.materialID
                                && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil
                            eventLock.unlock()
                            prepared.signal()
                        }
                        if boundary == .authorityAdvanced {
                            eventLock.lock()
                            events.append("committed-after-rollback")
                            eventLock.unlock()
                            saveCommitted.signal()
                        }
                        return true
                    }
                    do {
                        _ = try adapter.inscribe(
                            plan: plan,
                            actor: author,
                            world: world,
                            worldID: worldID,
                            session: current,
                            publication: { _, _ in
                                DispatchQueue.global().async {
                                    game.saveAndFlush(synchronous: false)
                                    saveReturned.signal()
                                }
                                guard captureAttempted.wait(timeout: .now() + 10) == .success else {
                                    throw WritingProofError.failed("capture_attempt_not_reached")
                                }
                                eventLock.lock()
                                events.append("cognitive-refusal")
                                eventLock.unlock()
                                throw PebbleAgentWritingAdapterError.injected
                            },
                            commit: { _ in }
                        )
                        throw WritingProofError.failed("injected_mutation_unexpectedly_passed")
                    } catch PebbleAgentWritingAdapterError.injected { }
                    guard saveReturned.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("save_call_did_not_return")
                    }
                    guard prepared.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("post_rollback_snapshot_not_prepared")
                    }
                    guard saveCommitted.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("post_rollback_snapshot_did_not_commit")
                    }
                    game.testingSignInscriptionPersistenceCaptureHook = nil
                    game.db.testingSignInscriptionPersistenceHook = nil
                    let durable = game.db.getChunk(
                        worldID,
                        world.dim.rawValue,
                        floorDiv(sign.x, CHUNK_W),
                        floorDiv(sign.z, CHUNK_W)
                    )
                    let durableInscription = durable?.blockEntities?.first(where: {
                        $0.x == sign.x && $0.y == sign.y && $0.z == sign.z
                    })?.signInscription
                    let durableWorldNext = game.db.getWorld(worldID)?.nextEntityId
                    try require(
                        try current.durableStateBytes() == before
                            && current.writingState?.artifacts.isEmpty == true
                            && current.writingState?.nextArtifactOrdinal == 1,
                        "c04_no_cognition_or_writing_ordinal"
                    )
                    eventLock.lock()
                    let capturedEvents = events
                    let preparedWasFinal = preparedObservedFinalPhysicalState
                    eventLock.unlock()
                    try require(
                        peekNextEntityId() == plan.materialID
                            && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil
                            && durableInscription == nil
                            && durableWorldNext == plan.materialID
                            && preparedWasFinal
                            && capturedEvents == [
                                "capture-attempt",
                                "cognitive-refusal",
                                "prepared-after-rollback",
                                "committed-after-rollback",
                            ],
                        "c04_capture_serializes_after_exact_rollback"
                    )
                    guard let reuse = sites.first(where: { $0 != sign && $0 != source }) else {
                        throw WritingProofError.failed("reuse_site_unavailable")
                    }
                    world.setBlock(
                        reuse.x,
                        reuse.y,
                        reuse.z,
                        Int(bid("oak_sign")) << 4
                    )
                    world.setBlockEntity(makeSignBE(reuse.x, reuse.y, reuse.z))
                    let reused = try SignInscription(
                        artifactID: plan.artifactID,
                        materialID: plan.materialID,
                        contentDigest: plan.contentDigest,
                        worldID: worldID,
                        dimension: world.dim.rawValue,
                        x: reuse.x,
                        y: reuse.y,
                        z: reuse.z,
                        lines: plan.lines
                    )
                    try world.inscribeSign(reused)
                    try require(
                        peekNextEntityId() == plan.materialID + 1
                            && world.getBlockEntity(reuse.x, reuse.y, reuse.z)?.signInscription == reused
                            && durableInscription == nil,
                        "c04_immediate_allocation_reuses_only_uncaptured_X"
                    )
                    game.saveAndFlush(synchronous: true)

                    let restarted = GameCore()
                    restarted.loadWorld(worldID)
                    guard restarted.hasWorld(), let persisted = restarted.db.getChunk(
                        worldID,
                        world.dim.rawValue,
                        floorDiv(sign.x, CHUNK_W),
                        floorDiv(sign.z, CHUNK_W)
                    ), let blocks = persisted.blocks, let biomes = persisted.biomes else {
                        throw WritingProofError.failed("fresh_GameCore_reload_unavailable")
                    }
                    let loadedChunk = Chunk(
                        cx: persisted.cx,
                        cz: persisted.cz,
                        minY: DIMS[persisted.dim].minY,
                        height: DIMS[persisted.dim].height
                    )
                    loadedChunk.blocks = blocks
                    loadedChunk.biomes = biomes
                    restarted.world.setChunk(loadedChunk)
                    for blockEntity in persisted.blockEntities ?? [] {
                        restarted.world.setBlockEntity(blockEntity)
                    }
                    let restartedOriginal = try? restarted.world.inspectSignInscription(
                        at: sign.x, sign.y, sign.z
                    )
                    let restartedAllocation = try restarted.world.inspectSignInscription(
                        at: reuse.x, reuse.y, reuse.z
                    )
                    try require(
                        restartedOriginal == nil
                            && restartedAllocation == reused
                            && restarted.worldRec?.nextEntityId == plan.materialID + 1
                            && restarted.db.lastSignInscriptionIndexLoadMetrics.indexedChunkRows > 0
                            && restarted.db.lastSignInscriptionIndexLoadMetrics.migratedChunkPayloads == 0
                            && restarted.db.lastSignInscriptionIndexLoadMetrics.decodedVoxelCells == 0,
                        "c04_restart_has_no_ghost_and_one_legitimate_X"
                    )

                    let abortPlan = try current.prepareWriting(
                        authorID: authorID,
                        propositionID: proposition,
                        materialID: peekNextEntityId(),
                        dimension: String(world.dim.rawValue),
                        cell: sign,
                        assertion: .deliberateCounterAssertion(.resource(kind: .stone, fingerprint: nil))
                    )
                    world.getChunkAt(sign.x, sign.z)!.modified = true
                    let abortCaptureAttempted = DispatchSemaphore(value: 0)
                    let abortPrepared = DispatchSemaphore(value: 0)
                    let abortFailed = DispatchSemaphore(value: 0)
                    let abortSaveReturned = DispatchSemaphore(value: 0)
                    var abortPreparedWasBlank = false
                    game.testingSignInscriptionSaveRecoveryHook = { recoveredRecords in
                        let recovered = recoveredRecords.contains(where: {
                            $0.worldId == worldID
                                && $0.dim == world.dim.rawValue
                                && $0.cx == floorDiv(sign.x, CHUNK_W)
                                && $0.cz == floorDiv(sign.z, CHUNK_W)
                        }) && world.getChunkAt(sign.x, sign.z)?.modified == true
                        self.trace(
                            "CIV45_C04_DIRTY failedPreparedSnapshot=blank "
                                + "retryDirty=\(recovered ? "YES" : "NO") "
                                + "result=\(recovered ? "PASS" : "FAIL")"
                        )
                        game.testingSignInscriptionSaveRecoveryHook = nil
                    }
                    game.testingSignInscriptionPersistenceCaptureHook = {
                        abortCaptureAttempted.signal()
                    }
                    game.db.testingSignInscriptionPersistenceHook = { boundary in
                        if boundary == .prepared {
                            abortPreparedWasBlank =
                                peekNextEntityId() == abortPlan.materialID
                                && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil
                            abortPrepared.signal()
                            return false
                        }
                        if boundary == .failed { abortFailed.signal() }
                        return true
                    }
                    do {
                        _ = try adapter.inscribe(
                            plan: abortPlan,
                            actor: author,
                            world: world,
                            worldID: worldID,
                            session: current,
                            publication: { _, _ in
                                DispatchQueue.global().async {
                                    game.saveAndFlush(synchronous: true)
                                    abortSaveReturned.signal()
                                }
                                guard abortCaptureAttempted.wait(timeout: .now() + 10) == .success else {
                                    throw WritingProofError.failed("abort_capture_attempt_not_reached")
                                }
                                throw PebbleAgentWritingAdapterError.injected
                            },
                            commit: { _ in }
                        )
                        throw WritingProofError.failed("abort_injected_mutation_unexpectedly_passed")
                    } catch PebbleAgentWritingAdapterError.injected { }
                    guard abortPrepared.wait(timeout: .now() + 10) == .success,
                          abortFailed.wait(timeout: .now() + 10) == .success,
                          abortSaveReturned.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("aborted_save_did_not_finish")
                    }
                    game.testingSignInscriptionPersistenceCaptureHook = nil
                    game.db.testingSignInscriptionPersistenceHook = nil
                    let afterAbort = game.db.getChunk(
                        worldID,
                        world.dim.rawValue,
                        floorDiv(sign.x, CHUNK_W),
                        floorDiv(sign.z, CHUNK_W)
                    )
                    let afterAbortOriginal = afterAbort?.blockEntities?.first(where: {
                        $0.x == sign.x && $0.y == sign.y && $0.z == sign.z
                    })?.signInscription
                    try require(
                        abortPreparedWasBlank
                            && peekNextEntityId() == abortPlan.materialID
                            && afterAbortOriginal == nil
                            && (try current.durableStateBytes()) == before,
                        "c04_aborted_post_rollback_snapshot_stays_blank"
                    )

                    let externalLines = ["external", "edit", "wins", "here"]
                    let externalCaptureAttempted = DispatchSemaphore(value: 0)
                    let externalPrepared = DispatchSemaphore(value: 0)
                    let externalCommitted = DispatchSemaphore(value: 0)
                    let externalSaveReturned = DispatchSemaphore(value: 0)
                    var externalPreparedWasFinal = false
                    game.testingSignInscriptionPersistenceCaptureHook = {
                        externalCaptureAttempted.signal()
                    }
                    game.db.testingSignInscriptionPersistenceHook = { boundary in
                        if boundary == .prepared {
                            externalPreparedWasFinal =
                                peekNextEntityId() == abortPlan.materialID + 1
                                && world.getBlockEntity(sign.x, sign.y, sign.z)?.lines == externalLines
                                && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil
                            externalPrepared.signal()
                        }
                        if boundary == .authorityAdvanced { externalCommitted.signal() }
                        return true
                    }
                    do {
                        _ = try adapter.inscribe(
                            plan: abortPlan,
                            actor: author,
                            world: world,
                            worldID: worldID,
                            session: current,
                            publication: { _, _ in
                                DispatchQueue.global().async {
                                    game.saveAndFlush(synchronous: false)
                                    externalSaveReturned.signal()
                                }
                                guard externalCaptureAttempted.wait(timeout: .now() + 10) == .success else {
                                    throw WritingProofError.failed("external_capture_attempt_not_reached")
                                }
                                world.getBlockEntity(sign.x, sign.y, sign.z)!.lines = externalLines
                                throw PebbleAgentWritingAdapterError.injected
                            },
                            commit: { _ in }
                        )
                        throw WritingProofError.failed("external_edit_unexpectedly_passed")
                    } catch PebbleAgentWritingAdapterError.rollbackUnverified { }
                    guard externalSaveReturned.wait(timeout: .now() + 10) == .success,
                          externalPrepared.wait(timeout: .now() + 10) == .success,
                          externalCommitted.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("external_snapshot_did_not_commit")
                    }
                    game.testingSignInscriptionPersistenceCaptureHook = nil
                    game.db.testingSignInscriptionPersistenceHook = nil
                    try require(
                        externalPreparedWasFinal
                            && world.getBlockEntity(sign.x, sign.y, sign.z)?.lines == externalLines
                            && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil
                            && peekNextEntityId() == abortPlan.materialID + 1
                            && (try current.durableStateBytes()) == before,
                        "c04_external_edit_capture_preserved_and_identity_burned"
                    )

                    let olderPrepared = DispatchSemaphore(value: 0)
                    let continueOlder = DispatchSemaphore(value: 0)
                    let newerPrepared = DispatchSemaphore(value: 0)
                    let orderedCommits = DispatchSemaphore(value: 0)
                    let queueHookLock = NSLock()
                    var preparedOrdinal = 0
                    var commitOrdinal = 0
                    game.db.testingSignInscriptionPersistenceHook = { boundary in
                        if boundary == .prepared {
                            queueHookLock.lock()
                            preparedOrdinal += 1
                            let ordinal = preparedOrdinal
                            queueHookLock.unlock()
                            if ordinal == 1 {
                                olderPrepared.signal()
                                return continueOlder.wait(timeout: .now() + 10) == .success
                            }
                            if ordinal == 2 { newerPrepared.signal() }
                        }
                        if boundary == .authorityAdvanced {
                            queueHookLock.lock()
                            commitOrdinal += 1
                            let finished = commitOrdinal == 2
                            queueHookLock.unlock()
                            if finished { orderedCommits.signal() }
                        }
                        return true
                    }
                    world.getBlockEntity(sign.x, sign.y, sign.z)!.lines = [
                        "older", "queued", "snapshot", "first",
                    ]
                    world.getChunkAt(sign.x, sign.z)!.modified = true
                    game.saveAndFlush(synchronous: false)
                    guard olderPrepared.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("older_snapshot_not_prepared")
                    }
                    world.getBlockEntity(sign.x, sign.y, sign.z)!.lines = externalLines
                    world.getChunkAt(sign.x, sign.z)!.modified = true
                    game.saveAndFlush(synchronous: false)
                    continueOlder.signal()
                    guard newerPrepared.wait(timeout: .now() + 10) == .success,
                          orderedCommits.wait(timeout: .now() + 10) == .success else {
                        throw WritingProofError.failed("ordered_snapshots_did_not_commit")
                    }
                    game.db.testingSignInscriptionPersistenceHook = nil
                    let orderedDurable = game.db.getChunk(
                        worldID,
                        world.dim.rawValue,
                        floorDiv(sign.x, CHUNK_W),
                        floorDiv(sign.z, CHUNK_W)
                    )
                    try require(
                        orderedDurable?.blockEntities?.first(where: {
                            $0.x == sign.x && $0.y == sign.y && $0.z == sign.z
                        })?.lines == externalLines,
                        "c04_newer_queued_snapshot_wins_durably"
                    )

                    let finalRestart = GameCore()
                    finalRestart.loadWorld(worldID)
                    guard finalRestart.hasWorld(), let finalPersisted = finalRestart.db.getChunk(
                        worldID,
                        world.dim.rawValue,
                        floorDiv(sign.x, CHUNK_W),
                        floorDiv(sign.z, CHUNK_W)
                    ), let finalBlocks = finalPersisted.blocks,
                          let finalBiomes = finalPersisted.biomes else {
                        throw WritingProofError.failed("final_fresh_GameCore_reload_unavailable")
                    }
                    let finalChunk = Chunk(
                        cx: finalPersisted.cx,
                        cz: finalPersisted.cz,
                        minY: DIMS[finalPersisted.dim].minY,
                        height: DIMS[finalPersisted.dim].height
                    )
                    finalChunk.blocks = finalBlocks
                    finalChunk.biomes = finalBiomes
                    finalRestart.world.setChunk(finalChunk)
                    for blockEntity in finalPersisted.blockEntities ?? [] {
                        finalRestart.world.setBlockEntity(blockEntity)
                    }
                    try require(
                        (try? finalRestart.world.inspectSignInscription(
                            at: sign.x, sign.y, sign.z
                        )) == nil
                            && finalRestart.world.getBlockEntity(sign.x, sign.y, sign.z)?.lines == externalLines
                            && finalRestart.worldRec?.nextEntityId == abortPlan.materialID + 1
                            && (try finalRestart.world.inspectSignInscription(
                                at: reuse.x, reuse.y, reuse.z
                            )) == reused,
                        "c04_final_restart_converges_without_ghost_or_external_overwrite"
                    )
                    try AgentCheckpointCodec.encode(WritingCorrection04Fixture(
                        worldID: worldID,
                        original: sign,
                        allocation: reuse,
                        materialID: reused.materialID,
                        burnedMaterialID: abortPlan.materialID,
                        externalLines: externalLines
                    )).write(to: correction04URL, options: .atomic)
                    trace("CIV45_C04 ordering=\(capturedEvents.joined(separator: ",")) candidate=\(plan.materialID) preparedCandidate=NO immediateAllocation=\(reused.materialID) restartGhost=NO abortPreparedCandidate=NO abortDirty=YES externalCapture=final-only externalIdentity=\(abortPlan.materialID) externalIdentityBurned=YES compactIndexRows=\(finalRestart.db.lastSignInscriptionIndexLoadMetrics.indexedChunkRows) cognitiveMutation=ZERO status=PASS")
                    return success("CIV-45 Correction 04 capture, rollback, abort, reload and external-mutation regressions passed.")
                }
                do {
                    _ = try adapter.inscribe(plan: plan, actor: author, world: world, worldID: worldID,
                        session: current, failAfterMutation: true, commit: { committed in
                            current = committed
                            self.session = committed
                        })
                    throw WritingProofError.failed("injected_mutation_unexpectedly_passed")
                } catch PebbleAgentWritingAdapterError.injected { }
                try require(try current.durableStateBytes() == before
                    && peekNextEntityId() == plan.materialID
                    && world.getBlockEntity(sign.x, sign.y, sign.z)?.lines == ["", "", "", ""]
                    && world.getBlockEntity(sign.x, sign.y, sign.z)?.signInscription == nil,
                    "late_failure_exact_rollback")
                let artifact = try adapter.inscribe(plan: plan, actor: author, world: world,
                    worldID: worldID, session: current, commit: { committed in
                        current = committed
                        self.session = committed
                    })
                try require(peekNextEntityId() == plan.materialID + 1, "Core_physical_identity_consumed_once")
                if let remote = probesByAgentId["agent_2"] {
                    do {
                        try adapter.inspect(plan: plan, actor: remote, world: world,
                            worldID: worldID, tick: current.tick)
                        throw WritingProofError.failed("remote_material_access_accepted")
                    } catch PebbleAgentWritingAdapterError.unavailable { }
                    trace("CIV45_LIVE check=remote_material_access_refused result=PASS")
                }
                do {
                    try adapter.inspect(plan: plan, actor: reader, world: world,
                        worldID: "incompatible-world", tick: current.tick)
                    throw WritingProofError.failed("foreign_world_access_accepted")
                } catch PebbleAgentWritingAdapterError.unavailable { }
                trace("CIV45_LIVE check=foreign_world_access_refused result=PASS")
                try require(world.getBlock(source.x, source.y, source.z) == fingerprint,
                            "false_inscription_world_unchanged")
                do {
                    _ = try adapter.read(artifact: artifact, actor: reader, world: world,
                        worldID: worldID, session: current, commit: { committed in
                            current = committed
                            self.session = committed
                        })
                    throw WritingProofError.failed("unlearned_reader_accepted")
                } catch AgentWritingError.unavailable { }
                try require(!current.canUseWritingNotation(readerID), "oral_only_reader_refused")
                try practice(artifact, teacher: author, learner: reader)
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
                try inspect(artifact, reader)
                let loadedSignBytes = try AgentCheckpointCodec.encode(world.inspectSignInscription(
                    at: fixture.sign.x, fixture.sign.y, fixture.sign.z))
                try require(try loadedSignBytes == Data(contentsOf: directory.appendingPathComponent("written-sign.json")),
                            "separate_process_Core_sign_bytes_exact")
                try loadedSignBytes.write(to: directory.appendingPathComponent("reloaded-sign.json"), options: .atomic)
                try require(!current.canUseWritingNotation(readerID), "partial_literacy_survives_restart")
                try require(world.getBlock(fixture.source.x, fixture.source.y, fixture.source.z) == Int(bid("oak_log")) << 4,
                            "saved_world_still_wood")
                _ = try current.advanceTick(perceptions: [])
                try practice(artifact, teacher: author, learner: reader)
                try require(current.canUseWritingNotation(readerID), "second_local_lesson_learns")
                let reading = try adapter.read(artifact: artifact, actor: reader, world: world,
                    worldID: worldID, session: current, commit: { committed in
                        current = committed
                        self.session = committed
                    })
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
            do { try inspect(artifact, reader); throw WritingProofError.failed("edit_resurrected_identity") }
            catch SignInscriptionError.unavailable { }
            try require(be.signInscription == nil, "normal_edit_invalidates_identity")
            world.setBlock(cell.x, cell.y, cell.z, 0)
            world.setBlock(cell.x, cell.y, cell.z, Int(bid("oak_sign")) << 4)
            world.setBlockEntity(makeSignBE(cell.x, cell.y, cell.z))
            world.getBlockEntity(cell.x, cell.y, cell.z)!.lines = artifact.plan.lines
            let before = try current.durableStateBytes()
            do {
                _ = try adapter.read(artifact: artifact, actor: reader, world: world,
                    worldID: worldID, session: current, commit: { committed in
                        current = committed
                        self.session = committed
                    })
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
