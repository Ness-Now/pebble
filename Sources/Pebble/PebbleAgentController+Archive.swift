import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleArchive(
        _ arguments: [String],
        world: World
    ) -> PebbleAgentCommandResult {
        guard environment["PEBBLELAB_APP_AGENTS_ARCHIVE"] == "1",
              environment["PEBBLELAB_APP_AGENTS_WRITING"] == "1",
              activeWorld === world,
              var current = session,
              let worldID = persistenceWorldID,
              isPaused,
              !movementEnabled else {
            return failure(
                "Archives require their explicit gate, CIV-45, an active "
                    + "paused World session and movement off."
            )
        }
        let adapter = PebbleAgentArchiveAdapter()
        var commandRecorder = replayRecorder
        func recorded(_ operation: AgentReplayOperation) throws -> Bool {
            try applyRecordedOperationIfActive(
                operation,
                session: &current,
                recorder: &commandRecorder
            ) != nil
        }
        func artifact(_ id: String) throws -> AgentWrittenArtifact {
            guard let artifact = current.writingState?.artifacts.first(where: {
                $0.artifactID == id
            }) else {
                throw AgentArchiveError.unavailable("CIV-45 artifact")
            }
            return artifact
        }
        func collection(_ raw: String) throws -> AgentArchiveCollection {
            guard let id = AgentArchiveCollectionID(rawValue: raw),
                  let collection = current.archiveState?.collections.first(where: {
                    $0.collectionID == id
                  }) else {
                throw AgentArchiveError.unavailable("archive collection")
            }
            return collection
        }
        do {
            switch arguments.first {
            case "on" where arguments.count == 1:
                guard current.writingState?.enabled == true else {
                    throw AgentArchiveError.unavailable("CIV-45 writing")
                }
                if try !recorded(.setArchiveEnabled(
                    enabled: true,
                    worldID: worldID,
                    configuration: .live
                )) {
                    try current.setArchiveEnabled(true, worldID: worldID)
                }
            case "off" where arguments.count == 1:
                if try !recorded(.setArchiveEnabled(
                    enabled: false,
                    worldID: worldID,
                    configuration: current.archiveState?.configuration ?? .live
                )) {
                    try current.setArchiveEnabled(
                        false,
                        worldID: worldID,
                        configuration: current.archiveState?.configuration ?? .live
                    )
                }
            case "create" where arguments.count == 5:
                let operationID = arguments[1]
                let curator = arguments[2]
                guard let actor = probesByAgentId[curator],
                      let kind = AgentArchiveCollectionKind(
                        rawValue: arguments[3]
                      ) else {
                    throw AgentArchiveError.invalidState(
                        "collection actor or kind"
                    )
                }
                let marker = try artifact(arguments[4])
                _ = try adapter.createCollection(
                    operationID: operationID,
                    kind: kind,
                    catalogueArtifact: marker,
                    actor: actor,
                    world: world,
                    worldID: worldID,
                    session: current,
                    publication: { candidate, receipt in
                        let operation = AgentReplayOperation.createArchiveCollection(
                            operationID: operationID,
                            kind: kind,
                            catalogueArtifactID: marker.artifactID,
                            curatorID: receipt.actorID,
                            catalogueReceipt: receipt
                        )
                        if try self.applyRecordedOperationIfActive(
                            operation,
                            session: &candidate,
                            recorder: &commandRecorder
                        ) != nil {
                            return candidate.archiveState!.collections.first {
                                $0.operationID == operationID
                            }!
                        }
                        return try candidate.createArchiveCollection(
                            operationID: operationID,
                            kind: kind,
                            catalogueArtifactID: marker.artifactID,
                            curatorID: receipt.actorID,
                            catalogueReceipt: receipt
                        )
                    },
                    commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    }
                )
            case "catalogue" where arguments.count == 6
                    || arguments.count == 7:
                let operationID = arguments[1]
                let cataloguer = arguments[2]
                let scope = try collection(arguments[3])
                let item = try artifact(arguments[4])
                guard let actor = probesByAgentId[cataloguer],
                      let marker = try? artifact(scope.catalogueArtifactID) else {
                    throw AgentArchiveError.unavailable(
                        "cataloguer or catalogue mark"
                    )
                }
                let relationship: AgentArchiveRelationship
                let parentArtifact: AgentWrittenArtifact?
                if arguments[5] == "source", arguments.count == 6 {
                    relationship = .source
                    parentArtifact = nil
                } else {
                    guard arguments.count == 7,
                          let parentID = AgentArchiveManuscriptID(
                            rawValue: arguments[6]
                          ),
                          let parent = current.archiveState?.manuscripts.first(
                            where: { $0.manuscriptID == parentID }
                          ) else {
                        throw AgentArchiveError.invalidState(
                            "lineage relationship"
                        )
                    }
                    if arguments[5] == "facsimile" {
                        relationship = .facsimile(parent: parentID)
                    } else if arguments[5] == "revision" {
                        relationship = .revision(parent: parentID)
                    } else {
                        throw AgentArchiveError.invalidState(
                            "lineage relationship"
                        )
                    }
                    parentArtifact = try artifact(parent.artifactID)
                }
                _ = try adapter.catalogueManuscript(
                    operationID: operationID,
                    collection: scope,
                    catalogueArtifact: marker,
                    artifact: item,
                    relationship: relationship,
                    parentArtifact: parentArtifact,
                    actor: actor,
                    world: world,
                    worldID: worldID,
                    session: current,
                    publication: {
                        candidate, catalogueReceipt, artifactReceipt,
                        parentReceipt in
                        let operation = AgentReplayOperation
                            .catalogueArchiveManuscript(
                                operationID: operationID,
                                collectionID: scope.collectionID,
                                artifactID: item.artifactID,
                                relationship: relationship,
                                cataloguerID: artifactReceipt.actorID,
                                catalogueReceipt: catalogueReceipt,
                                artifactReceipt: artifactReceipt,
                                parentReceipt: parentReceipt
                            )
                        if try self.applyRecordedOperationIfActive(
                            operation,
                            session: &candidate,
                            recorder: &commandRecorder
                        ) != nil {
                            return candidate.archiveState!.manuscripts.first {
                                $0.operationID == operationID
                            }!
                        }
                        return try candidate.catalogueArchiveManuscript(
                            operationID: operationID,
                            collectionID: scope.collectionID,
                            artifactID: item.artifactID,
                            relationship: relationship,
                            cataloguerID: artifactReceipt.actorID,
                            catalogueReceipt: catalogueReceipt,
                            artifactReceipt: artifactReceipt,
                            parentReceipt: parentReceipt
                        )
                    },
                    commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    }
                )
            case "search" where arguments.count == 5
                    || arguments.count == 6:
                let requester = arguments[1]
                let scope = try collection(arguments[2])
                guard let actor = probesByAgentId[requester] else {
                    throw AgentArchiveError.unavailable("archive requester")
                }
                let query = try archiveQuery(
                    kind: arguments[3],
                    value: arguments[4]
                )
                let limit = arguments.count == 6 ? Int(arguments[5]) : nil
                let marker = try artifact(scope.catalogueArtifactID)
                let result = try adapter.search(
                    index: current.rebuildArchiveIndex(),
                    collection: scope,
                    catalogueArtifact: marker,
                    query: query,
                    limit: limit,
                    actor: actor,
                    world: world,
                    worldID: worldID,
                    session: current
                )
                for hit in result.hits {
                    trace(
                        "archive hit manuscript=\(hit.entry.manuscriptID.rawValue) "
                            + "artifact=\(hit.entry.artifactID) "
                            + "generation=\(hit.entry.generation) "
                            + "relationship=\(hit.entry.relationship)"
                    )
                }
                trace(
                    "archive search matches=\(result.totalMatches) "
                        + "returned=\(result.hits.count) "
                        + "scanned=\(result.metrics.postingEntriesVisited) "
                        + "global=\(result.metrics.globalRecordsScanned)"
                )
            case "retrieve" where arguments.count == 5:
                let operationID = arguments[1]
                let reader = arguments[2]
                let scope = try collection(arguments[3])
                let item = try artifact(arguments[4])
                guard let actor = probesByAgentId[reader] else {
                    throw AgentArchiveError.unavailable("archive reader")
                }
                let marker = try artifact(scope.catalogueArtifactID)
                let index = try current.rebuildArchiveIndex()
                let search = try adapter.search(
                    index: index,
                    collection: scope,
                    catalogueArtifact: marker,
                    query: .artifact(item.artifactID),
                    actor: actor,
                    world: world,
                    worldID: worldID,
                    session: current
                )
                guard let selection = search.hits.first?.selection else {
                    throw AgentArchiveError.unavailable("catalogued artifact")
                }
                _ = try adapter.retrieve(
                    operationID: operationID,
                    selection: selection,
                    artifact: item,
                    actor: actor,
                    world: world,
                    worldID: worldID,
                    session: current,
                    publication: { candidate, receipt in
                        let operation = AgentReplayOperation
                            .retrieveArchiveManuscript(
                                operationID: operationID,
                                selection: selection,
                                readerID: receipt.actorID,
                                receipt: receipt
                            )
                        if try self.applyRecordedOperationIfActive(
                            operation,
                            session: &candidate,
                            recorder: &commandRecorder
                        ) != nil {
                            let record = candidate.archiveState!.retrievals.first {
                                $0.operationID == operationID
                            }!
                            let reading = candidate.writingState!.readings.first {
                                $0.readingID == record.writingReadingID
                            }!
                            return AgentArchiveRetrievalResult(
                                archiveRecord: record,
                                writingReading: reading
                            )
                        }
                        return try candidate.retrieveArchiveManuscript(
                            operationID: operationID,
                            selection: selection,
                            readerID: receipt.actorID,
                            receipt: receipt
                        )
                    },
                    commit: { committed in
                        current = committed
                        self.session = committed
                        self.replayRecorder = commandRecorder
                    }
                )
            case "status" where arguments.count == 1:
                let snapshot = current.archiveSnapshot()
                trace(
                    "archive enabled=\(snapshot.enabled ? 1 : 0) "
                        + "collections=\(snapshot.collections.count) "
                        + "manuscripts=\(snapshot.manuscripts.count) "
                        + "retrievals=\(snapshot.retrievals.count) "
                        + "revision=\(snapshot.indexRevision) "
                        + "source=\(snapshot.indexSourceDigest)"
                )
            case "proof" where arguments.count == 2:
                guard commandRecorder == nil else {
                    throw AgentArchiveError.unavailable(
                        "proof while recording"
                    )
                }
                return runArchiveProof(
                    phase: arguments[1],
                    world: world
                )
            default:
                return failure(
                    "Usage: /lab archive on|off|status|proof <write|read>|"
                        + "create <operation> "
                        + "<curator> <manuscriptRegister|archive|library> "
                        + "<catalogue-artifact>|catalogue <operation> "
                        + "<cataloguer> <collection> <artifact> source|"
                        + "catalogue <operation> <cataloguer> "
                        + "<collection> <artifact> <facsimile|revision> "
                        + "<parent-manuscript>|search <requester> "
                        + "<collection> <kind> <value> [limit]|retrieve "
                        + "<operation> <reader> <collection> <artifact>"
                )
            }
            session = current
            replayRecorder = commandRecorder
            return success(
                "Archive operation accepted; index metadata remains derived "
                    + "and physical access remains locally verified."
            )
        } catch {
            trace("archive refused reason=\(error)")
            return failure("Archive refused: \(error)")
        }
    }

    private func archiveQuery(
        kind: String,
        value: String
    ) throws -> AgentArchiveSearchQuery {
        switch kind {
        case "collection":
            guard let id = AgentArchiveCollectionID(rawValue: value) else {
                throw AgentArchiveError.invalidState("collection query")
            }
            return .collection(id)
        case "artifact": return .artifact(value)
        case "lineage": return .lineageRoot(value)
        case "author":
            guard let id = AgentID(rawValue: value) else {
                throw AgentArchiveError.invalidState("author query")
            }
            return .author(id)
        case "proposition":
            guard let id = AgentKnowledgePropositionID(rawValue: value) else {
                throw AgentArchiveError.invalidState("proposition query")
            }
            return .proposition(id)
        case "question": return .question(value)
        case "relationship": return .relationship(value)
        default: throw AgentArchiveError.invalidState("archive query")
        }
    }
}
