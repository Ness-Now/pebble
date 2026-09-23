import Foundation
@_spi(Testing) import PebbleAgents
import PebbleCore

private let archiveAuthor = AgentID(rawValue: "agent_0")!
private let archiveReader = AgentID(rawValue: "agent_1")!
private let archiveObserver = AgentID(rawValue: "agent_2")!

private func archiveAgent(_ id: AgentID, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id.rawValue,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: -10, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "CIV-46 fixture",
            startedAtTick: 0,
            urgency: 0
        ),
        lastAction: nil,
        lastActionEffect: nil,
        memory: [],
        tickCreated: 0,
        ticksAlive: 0,
        observationCount: 0,
        nearbyObservationCount: 0,
        goalSelectionCount: 0,
        goalChangeCount: 0,
        actionCount: 0,
        actionEffectCount: 0,
        movementCount: 0,
        totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: nil
    )
}

private func archiveSession() throws -> (AgentSimulationSession, AgentKnowledgePropositionID) {
    var session = try AgentSimulationSession(
        configuration: try AgentSessionConfiguration(
            seed: 46,
            nearbyRadius: 16,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            archiveAgent(archiveAuthor, x: 0),
            archiveAgent(archiveReader, x: 2),
            archiveAgent(archiveObserver, x: 2)
        ],
        simulationID: try AgentSimulationID(validating: "civ46-archive"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    try session.setSocialEnabled(true)
    try session.setKnowledgeGraphEnabled(true)
    _ = try session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: archiveAuthor.rawValue,
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 3,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: Int(bid("oak_log")) << 4
        )]
    )])
    let proposition = session.knowledgeSnapshot().beliefs.first {
        $0.ownerID == archiveAuthor
    }!.propositionID
    try session.setLanguageEnabled(true)
    let senses = AgentLanguagePack.frenchReference.entries.map(\.senseID)
    for agent in [archiveAuthor, archiveReader, archiveObserver] {
        try session.seedLanguagePrior(for: agent, senseIDs: senses)
    }
    try session.setWritingEnabled(
        true,
        worldID: "civ46-world",
        configuration: try AgentWritingConfiguration(
            maximumArtifacts: 8,
            maximumReadings: 8,
            maximumLiteracyRecords: 8
        )
    )
    for agent in [archiveAuthor, archiveReader, archiveObserver] {
        try session.seedWritingEducationalPrior(for: agent)
    }
    return (session, proposition)
}

private func archiveWorld() -> World {
    let world = World(dim: .overworld, seed: 46)
    world.setChunk(Chunk(cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H))
    world.setChunk(Chunk(cx: 0, cz: -1, minY: GEN_MIN_Y, height: WORLD_H))
    for cell in [
        AgentPosition(x: 1, y: 64, z: 0),
        AgentPosition(x: 1, y: 64, z: 1),
        AgentPosition(x: 1, y: 64, z: -1),
        AgentPosition(x: 2, y: 64, z: 0)
    ] {
        world.setBlock(cell.x, cell.y - 1, cell.z, Int(bid("stone")) << 4, SET_SILENT)
        world.setBlock(cell.x, cell.y, cell.z, Int(bid("oak_sign")) << 4, SET_SILENT)
        world.setBlockEntity(makeSignBE(cell.x, cell.y, cell.z))
    }
    world.setBlock(3, 64, 0, Int(bid("oak_log")) << 4, SET_SILENT)
    return world
}

private func archiveReceipt(
    _ plan: AgentWritingPlan,
    actorID: AgentID,
    tick: Int,
    world: World
) throws -> AgentWritingPhysicalReceipt {
    let stamp = try world.inspectSignInscription(
        at: plan.cell.x,
        plan.cell.y,
        plan.cell.z
    )
    guard stamp.artifactID == plan.artifactID,
          stamp.materialID == plan.materialID,
          stamp.contentDigest == plan.contentDigest,
          stamp.lines == plan.lines else {
        throw AgentArchiveError.unavailable("physical inscription mismatch")
    }
    let actorX = actorID == archiveAuthor ? 0 : 2
    return AgentWritingPhysicalReceipt(
        worldID: plan.worldID,
        dimension: plan.dimension,
        cell: plan.cell,
        blockKey: "oak_sign",
        artifactID: plan.artifactID,
        materialID: plan.materialID,
        contentDigest: plan.contentDigest,
        lines: plan.lines,
        actorID: actorID,
        actorPosition: AgentPosition(x: actorX, y: 64, z: 0),
        observedAtTick: tick
    )
}

private func archiveInscribe(
    session: inout AgentSimulationSession,
    propositionID: AgentKnowledgePropositionID,
    cell: AgentPosition,
    assertion: AgentWritingAssertion,
    world: World
) throws -> AgentWrittenArtifact {
    let plan = try session.prepareWriting(
        authorID: archiveAuthor,
        propositionID: propositionID,
        materialID: peekNextEntityId(),
        dimension: "0",
        cell: cell,
        assertion: assertion
    )
    let stamp = try SignInscription(
        artifactID: plan.artifactID,
        materialID: plan.materialID,
        contentDigest: plan.contentDigest,
        worldID: plan.worldID,
        dimension: 0,
        x: cell.x,
        y: cell.y,
        z: cell.z,
        lines: plan.lines
    )
    try world.inscribeSign(stamp)
    return try session.acceptWriting(
        plan,
        receipt: archiveReceipt(
            plan,
            actorID: archiveAuthor,
            tick: session.tick,
            world: world
        )
    )
}

private func archiveRefusal(
    _ name: String,
    session: AgentSimulationSession,
    operation: (inout AgentSimulationSession) throws -> Void
) {
    var candidate = session
    let before = try! candidate.durableStateBytes()
    do {
        try operation(&candidate)
        check(name, false, "unexpected success")
    } catch {
        check(name, true, "\(error)")
    }
    check(name + " is atomic", try! candidate.durableStateBytes() == before)
}

private func archiveResignedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutateDurable: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutateDurable(&durable)
    let mutatedBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self,
        from: mutatedBytes
    )
    let canonicalBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: canonicalBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(canonicalBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))"
        + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func archiveRestoreRefuses(
    _ name: String,
    checkpoint: AgentSessionCheckpoint,
    mutation: (inout [String: Any]) -> Void
) {
    let hostile = archiveResignedCheckpoint(checkpoint, mutateDurable: mutation)
    do {
        _ = try AgentSimulationSession.restoring(hostile)
        check(name, false, "accepted re-signed malformed state")
    } catch {
        check(name, true, "\(error)")
    }
}

func runPebbleAgentsArchiveSmoke() {
    let originalPhysicalCounter = peekNextEntityId()
    defer { resetEntityIds(originalPhysicalCounter) }
    section("CIV-46 manuscripts, archives and bounded retrieval")

    do {
        var (session, propositionID) = try archiveSession()
        let world = archiveWorld()
        let anchor = try archiveInscribe(
            session: &session,
            propositionID: propositionID,
            cell: AgentPosition(x: 1, y: 64, z: 0),
            assertion: .deliberateCounterAssertion(
                .resource(kind: .stone, fingerprint: nil)
            ),
            world: world
        )
        let source = try archiveInscribe(
            session: &session,
            propositionID: propositionID,
            cell: AgentPosition(x: 1, y: 64, z: 1),
            assertion: .beliefReport,
            world: world
        )
        let facsimile = try archiveInscribe(
            session: &session,
            propositionID: propositionID,
            cell: AgentPosition(x: 1, y: 64, z: -1),
            assertion: .beliefReport,
            world: world
        )
        let revision = try archiveInscribe(
            session: &session,
            propositionID: propositionID,
            cell: AgentPosition(x: 2, y: 64, z: 0),
            assertion: .deliberateCounterAssertion(
                .resource(kind: .stone, fingerprint: nil)
            ),
            world: world
        )
        check("four CIV-45 carriers have distinct material identities",
              Set([anchor, source, facsimile, revision].map {
                  $0.plan.materialID
              }).count == 4)
        check("facsimile content matches without identity collapse",
              source.plan.assertedProposition == facsimile.plan.assertedProposition
                && source.plan.lines == facsimile.plan.lines
                && source.artifactID != facsimile.artifactID)
        check("revision preserves question while changing assertion",
              facsimile.plan.assertedProposition.questionKey
                == revision.plan.assertedProposition.questionKey
                && facsimile.plan.assertedProposition
                    != revision.plan.assertedProposition)

        let knowledgeBeforeArchive = session.knowledgeSnapshot()
        let writingBeforeArchive = session.writingState
        let worldEncoder = JSONEncoder()
        worldEncoder.outputFormatting = [.sortedKeys]
        let physicalBeforeArchive = try worldEncoder.encode([
            world.getBlockEntity(1, 64, 0)!,
            world.getBlockEntity(1, 64, 1)!,
            world.getBlockEntity(1, 64, -1)!,
            world.getBlockEntity(2, 64, 0)!
        ])
        try session.setArchiveEnabled(
            true,
            worldID: "civ46-world",
            configuration: try AgentArchiveConfiguration(
                maximumCollections: 1,
                maximumManuscripts: 3,
                maximumRetrievals: 2,
                maximumSearchResults: 2
            )
        )
        try session.useLegacyCognitivePhysiologyReplayFixture(
            schemaVersion: AgentCheckpointSchema.archiveVersion
        )
        let anchorReceipt = try archiveReceipt(
            anchor.plan,
            actorID: archiveAuthor,
            tick: session.tick,
            world: world
        )
        let collection = try session.createArchiveCollection(
            operationID: "civ46-create-library",
            kind: .library,
            catalogueArtifactID: anchor.artifactID,
            curatorID: archiveAuthor,
            catalogueReceipt: anchorReceipt
        )
        let original = try session.catalogueArchiveManuscript(
            operationID: "civ46-catalogue-source",
            collectionID: collection.collectionID,
            artifactID: source.artifactID,
            relationship: .source,
            cataloguerID: archiveAuthor,
            catalogueReceipt: anchorReceipt,
            artifactReceipt: try archiveReceipt(
                source.plan,
                actorID: archiveAuthor,
                tick: session.tick,
                world: world
            )
        )
        let copy = try session.catalogueArchiveManuscript(
            operationID: "civ46-catalogue-copy",
            collectionID: collection.collectionID,
            artifactID: facsimile.artifactID,
            relationship: .facsimile(parent: original.manuscriptID),
            cataloguerID: archiveAuthor,
            catalogueReceipt: anchorReceipt,
            artifactReceipt: try archiveReceipt(
                facsimile.plan,
                actorID: archiveAuthor,
                tick: session.tick,
                world: world
            ),
            parentReceipt: try archiveReceipt(
                source.plan,
                actorID: archiveAuthor,
                tick: session.tick,
                world: world
            )
        )
        let staleIndex = try session.rebuildArchiveIndex()
        let sourceBeforeRevision = session.archiveState!.manuscripts[0]
        let revised = try session.catalogueArchiveManuscript(
            operationID: "civ46-catalogue-revision",
            collectionID: collection.collectionID,
            artifactID: revision.artifactID,
            relationship: .revision(parent: copy.manuscriptID),
            cataloguerID: archiveAuthor,
            catalogueReceipt: anchorReceipt,
            artifactReceipt: try archiveReceipt(
                revision.plan,
                actorID: archiveAuthor,
                tick: session.tick,
                world: world
            ),
            parentReceipt: try archiveReceipt(
                facsimile.plan,
                actorID: archiveAuthor,
                tick: session.tick,
                world: world
            )
        )
        check("copy and revision append lineage without rewriting source",
              session.archiveState!.manuscripts[0] == sourceBeforeRevision
                && revised.rootArtifactID == source.artifactID
                && revised.generation == 2)
        check("archive operations do not mutate CIV-41 epistemic state",
              session.knowledgeSnapshot() == knowledgeBeforeArchive)
        check("archive operations do not mutate CIV-45 artifact history",
              session.writingState == writingBeforeArchive)
        let physicalAfterArchive = try worldEncoder.encode([
            world.getBlockEntity(1, 64, 0)!,
            world.getBlockEntity(1, 64, 1)!,
            world.getBlockEntity(1, 64, -1)!,
            world.getBlockEntity(2, 64, 0)!
        ])
        check("archive publication does not mutate World carriers",
              physicalAfterArchive == physicalBeforeArchive)

        archiveRefusal("stale derived index is refused", session: session) {
            _ = try $0.searchArchive(
                staleIndex,
                collectionID: collection.collectionID,
                query: .collection(collection.collectionID),
                requesterID: archiveAuthor,
                catalogueReceipt: anchorReceipt
            )
        }
        let index = try session.rebuildArchiveIndex()
        archiveRefusal("oversized search input is structurally refused", session: session) {
            _ = try $0.searchArchive(
                index,
                collectionID: collection.collectionID,
                query: .question(String(repeating: "q", count: 10_000)),
                requesterID: archiveAuthor,
                catalogueReceipt: anchorReceipt
            )
        }
        check("index rebuild visits bounded authoritative sources",
              index.metrics.writingArtifactsVisited == 4
                && index.metrics.collectionsVisited == 1
                && index.metrics.manuscriptsVisited == 3
                && index.metrics.postingsEmitted <= index.metrics.maximumPossiblePostings)
        let lineage = try session.searchArchive(
            index,
            collectionID: collection.collectionID,
            query: .lineageRoot(source.artifactID),
            requesterID: archiveAuthor,
            catalogueReceipt: anchorReceipt
        )
        check("bounded lineage search is ordered and truncated",
              lineage.totalMatches == 3 && lineage.hits.count == 2
                && lineage.truncated
                && lineage.hits.map(\.entry.generation) == [0, 1])
        check("lookup scans no global archive history",
              lineage.metrics.globalRecordsScanned == 0
                && lineage.metrics.postingEntriesVisited == 3
                && lineage.metrics.postingEntriesVisited
                    <= lineage.metrics.maximumPostingEntriesVisited)
        let byQuestion = try session.searchArchive(
            index,
            collectionID: collection.collectionID,
            query: .question(source.plan.assertedProposition.questionKey),
            requesterID: archiveAuthor,
            catalogueReceipt: anchorReceipt,
            limit: 2
        )
        check("semantic discovery indexes identity without returning content",
              byQuestion.totalMatches == 3
                && byQuestion.hits.allSatisfy {
                    $0.entry.rootArtifactID == source.artifactID
                })

        let replayBase = try session.makeCheckpoint()
        let replayBaseBytes = try AgentCheckpointCodec.encode(replayBase)
        check("CIV-46 checkpoint advances to schema 41",
              replayBase.schemaVersion == 41)
        let restoredBase = try AgentSimulationSession.restoring(replayBase)
        check("archive checkpoint reload is byte exact",
              try AgentCheckpointCodec.encode(restoredBase.makeCheckpoint())
                == replayBaseBytes)
        check("derived index rebuild is deterministic after reload",
              try restoredBase.rebuildArchiveIndex() == index)

        let facsimileSearch = try session.searchArchive(
            index,
            collectionID: collection.collectionID,
            query: .artifact(facsimile.artifactID),
            requesterID: archiveAuthor,
            catalogueReceipt: anchorReceipt
        )
        let selection = facsimileSearch.hits.first!.selection
        let operation = AgentReplayOperation.retrieveArchiveManuscript(
            operationID: "civ46-retrieve-copy",
            selection: selection,
            readerID: archiveReader,
            receipt: try archiveReceipt(
                facsimile.plan,
                actorID: archiveReader,
                tick: session.tick,
                world: world
            )
        )
        var recorder = try AgentReplayRecorder(
            checkpoint: replayBase,
            session: session
        )
        let evidenceBeforeRetrieval = session.knowledgeSnapshot().evidence
        _ = try recorder.apply(operation, to: &session)
        let retrieval = session.archiveState!.retrievals.last!
        check("archive retrieval delegates the claim and belief to CIV-41",
              session.knowledgeSnapshot().claims.contains {
                  $0.writtenSource?.artifactID == facsimile.artifactID
                    && $0.recipientID == archiveReader
              }
                && session.knowledgeSnapshot().beliefs.contains {
                    $0.ownerID == archiveReader
                        && $0.propositionID
                            == facsimile.plan.assertedProposition.propositionID
                })
        check("archive retrieval creates no evidence or World truth",
              session.knowledgeSnapshot().evidence == evidenceBeforeRetrieval
                && world.getBlock(3, 64, 0) == Int(bid("oak_log")) << 4)
        let afterRetrieval = try session.durableStateBytes()
        _ = try session.retrieveArchiveManuscript(
            operationID: "civ46-retrieve-copy",
            selection: selection,
            readerID: archiveReader,
            receipt: try archiveReceipt(
                facsimile.plan,
                actorID: archiveReader,
                tick: session.tick,
                world: world
            )
        )
        check("same logical retrieval is idempotent",
              try session.durableStateBytes() == afterRetrieval
                && session.archiveState!.retrievals == [retrieval])
        let journal = try recorder.journal(
            named: AgentCheckpointName(rawValue: "civ46-replay")!
        )
        check("CIV-46 replay envelope advances to schema 41",
              journal.manifest.schemaVersion == 41)
        let replay = try AgentSessionReplayer.replay(
            checkpoint: replayBase,
            journal: journal
        )
        check("retrieval replay is deterministic and exact",
              try replay.session.durableStateBytes()
                == session.durableStateBytes())

        let archiveBytes = try JSONSerialization.data(
            withJSONObject: (try JSONSerialization.jsonObject(
                with: session.durableStateBytes()
            ) as! [String: Any])["archiveState"]!,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let archiveText = String(decoding: archiveBytes, as: UTF8.self)
        check("durable archive sources contain no index postings or text lines",
              !archiveText.contains("postings")
                && !archiveText.contains("lines")
                && !archiveText.contains("assertedProposition"))

        archiveRefusal("manuscript capacity refuses without partial state", session: session) {
            _ = try $0.catalogueArchiveManuscript(
                operationID: "civ46-over-capacity",
                collectionID: collection.collectionID,
                artifactID: anchor.artifactID,
                relationship: .source,
                cataloguerID: archiveAuthor,
                catalogueReceipt: anchorReceipt,
                artifactReceipt: anchorReceipt
            )
        }
        archiveRefusal("operation identity substitution is refused", session: session) {
            _ = try $0.createArchiveCollection(
                operationID: "civ46-create-library",
                kind: .archive,
                catalogueArtifactID: source.artifactID,
                curatorID: archiveAuthor,
                catalogueReceipt: try archiveReceipt(
                    source.plan,
                    actorID: archiveAuthor,
                    tick: $0.tick,
                    world: world
                )
            )
        }

        for iteration in 0..<96 {
            do {
                _ = try session.advanceTick(perceptions: [])
            } catch {
                throw AgentArchiveError.invalidState(
                    "compaction iteration \(iteration): \(String(reflecting: error))"
                )
            }
        }
        let compactedCheckpoint = try session.makeCheckpoint()
        let compacted = try AgentSimulationSession.restoring(compactedCheckpoint)
        check("causal compaction preserves archive continuity",
              compacted.archiveState?.manuscripts == session.archiveState?.manuscripts
                && (compacted.archiveState?.boundary?.eventID.sequence.rawValue ?? 0)
                    > compacted.causalLedgerSnapshot().summary.droppedEventCount)
        let compactedIndex = try compacted.rebuildArchiveIndex()
        check("index source stays stable across retrieval and causal compaction",
              compactedIndex.sourceRevision == index.sourceRevision
                && compactedIndex.sourceDigest == index.sourceDigest)

        let hostileBase = compactedCheckpoint
        archiveRestoreRefuses(
            "re-signed derived source digest substitution is refused",
            checkpoint: hostileBase
        ) { durable in
            var archive = durable["archiveState"] as! [String: Any]
            archive["indexSourceDigest"] = String(repeating: "0", count: 64)
            durable["archiveState"] = archive
        }
        archiveRestoreRefuses(
            "schema 41 without archive authority is refused",
            checkpoint: hostileBase
        ) { durable in
            durable.removeValue(forKey: "archiveState")
        }
        archiveRestoreRefuses(
            "archive refuses disabled material writing authority",
            checkpoint: hostileBase
        ) { durable in
            var writing = durable["writingState"] as! [String: Any]
            writing["enabled"] = false
            durable["writingState"] = writing
        }

        let lossSession = compacted
        let lossKnowledge = lossSession.knowledgeSnapshot()
        world.setBlock(
            source.plan.cell.x,
            source.plan.cell.y,
            source.plan.cell.z,
            0,
            SET_SILENT
        )
        check("loss removes current source material authority",
              (try? world.inspectSignInscription(
                at: source.plan.cell.x,
                source.plan.cell.y,
                source.plan.cell.z
              )) == nil)
        let lossSearch = try lossSession.searchArchive(
            compactedIndex,
            collectionID: collection.collectionID,
            query: .lineageRoot(source.artifactID),
            requesterID: archiveAuthor,
            catalogueReceipt: try archiveReceipt(
                anchor.plan,
                actorID: archiveAuthor,
                tick: lossSession.tick,
                world: world
            )
        )
        check("non-authoritative index keeps discovery metadata after loss",
              lossSearch.totalMatches == 3)
        check("source loss does not mutate cognition",
              lossSession.knowledgeSnapshot() == lossKnowledge)

        world.setBlock(
            facsimile.plan.cell.x,
            facsimile.plan.cell.y,
            facsimile.plan.cell.z,
            0,
            SET_SILENT
        )
        let observerBefore = try lossSession.durableStateBytes()
        let observerBeliefsBefore = lossSession.knowledgeSnapshot().beliefs.filter {
            $0.ownerID == archiveObserver
        }
        let readingsBefore = lossSession.writingState?.readings ?? []
        var currentCopyReceipt: AgentWritingPhysicalReceipt?
        currentCopyReceipt = try? archiveReceipt(
            facsimile.plan,
            actorID: archiveObserver,
            tick: lossSession.tick,
            world: world
        )
        check("loss of every wood copy removes retrievable material content",
              currentCopyReceipt == nil
                && (try? world.inspectSignInscription(
                    at: source.plan.cell.x,
                    source.plan.cell.y,
                    source.plan.cell.z
                )) == nil)
        check("index alone cannot publish a reading or belief",
              try lossSession.durableStateBytes() == observerBefore
                && lossSession.knowledgeSnapshot().beliefs.filter {
                    $0.ownerID == archiveObserver
                } == observerBeliefsBefore
                && lossSession.writingState?.readings == readingsBefore)
    } catch {
        check(
            "CIV-46 archive scenario completes",
            false,
            String(reflecting: error)
        )
    }
}
