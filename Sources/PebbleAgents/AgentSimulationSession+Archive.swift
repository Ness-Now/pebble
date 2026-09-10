extension AgentSimulationSession {
    public mutating func setArchiveEnabled(
        _ enabled: Bool,
        worldID: String,
        configuration: AgentArchiveConfiguration = .live
    ) throws {
        guard causalLedger.isEnabled,
              let writing = writingState, writing.enabled,
              writing.worldID == worldID,
              archiveIdentifierIsValid(worldID, maximum: 128) else {
            throw AgentArchiveError.unavailable("archive requires matching CIV-45 authority")
        }
        _ = try AgentArchiveConfiguration(
            maximumCollections: configuration.maximumCollections,
            maximumManuscripts: configuration.maximumManuscripts,
            maximumRetrievals: configuration.maximumRetrievals,
            maximumSearchResults: configuration.maximumSearchResults
        )
        if let state = archiveState {
            guard state.worldID == worldID, state.configuration == configuration else {
                throw AgentArchiveError.invalidState("immutable archive configuration")
            }
            if state.enabled == enabled { return }
        }
        var candidate = self
        var state = archiveState ?? AgentArchiveState(
            worldID: worldID,
            configuration: configuration
        )
        state.enabled = enabled
        candidate.archiveState = state
        let event = try candidate.requiredArchiveEvent(
            .archiveInitialized,
            recordID: "archive",
            detail: enabled ? "enabled" : "disabled"
        )
        try candidate.commitArchiveBoundary(causes: [event.eventID])
        try candidate.validateArchiveState()
        self = candidate
    }

    @discardableResult
    public mutating func createArchiveCollection(
        operationID: String,
        kind: AgentArchiveCollectionKind,
        catalogueArtifactID: String,
        curatorID: AgentID,
        catalogueReceipt: AgentWritingPhysicalReceipt
    ) throws -> AgentArchiveCollection {
        guard let state = archiveState, state.enabled else {
            throw AgentArchiveError.unavailable("archive disabled")
        }
        try requireArchiveOperationID(operationID)
        let collectionID = archiveCollectionID(operationID: operationID)
        if let existing = state.collections.first(where: { $0.operationID == operationID }) {
            guard existing.collectionID == collectionID,
                  existing.kind == kind,
                  existing.catalogueArtifactID == catalogueArtifactID,
                  existing.curatorID == curatorID else {
                throw AgentArchiveError.invalidState("conflicting collection replay")
            }
            return existing
        }
        try requireUnusedArchiveOperationID(operationID)
        guard state.collections.count < state.configuration.maximumCollections,
              state.indexRevision < UInt64.max,
              !state.collections.contains(where: {
                  $0.catalogueArtifactID == catalogueArtifactID
              }),
              let artifact = writingArtifact(catalogueArtifactID) else {
            throw AgentArchiveError.capacityReached("collections or catalogue mark")
        }
        try requireWritingReceipt(
            catalogueReceipt,
            plan: artifact.plan,
            actorID: curatorID
        )

        var candidate = self
        let witness = AgentArchiveMaterialWitness(catalogueReceipt)
        let event = try candidate.requiredArchiveEvent(
            .archiveCollectionCreated,
            actorID: curatorID,
            causes: [artifact.inscriptionEventID],
            recordID: collectionID.rawValue,
            detail: writingDigest([operationID, kind.rawValue, writingDigest(witness)])
        )
        let collection = AgentArchiveCollection(
            collectionID: collectionID,
            operationID: operationID,
            kind: kind,
            catalogueArtifactID: catalogueArtifactID,
            curatorID: curatorID,
            materialWitness: witness,
            createdAtTick: tick,
            creationEventID: event.eventID
        )
        candidate.archiveState!.collections.append(collection)
        try candidate.advanceArchiveIndexSource()
        try candidate.commitArchiveBoundary(causes: [event.eventID])
        try candidate.validateArchiveState()
        self = candidate
        return collection
    }

    @discardableResult
    public mutating func catalogueArchiveManuscript(
        operationID: String,
        collectionID: AgentArchiveCollectionID,
        artifactID: String,
        relationship: AgentArchiveRelationship,
        cataloguerID: AgentID,
        catalogueReceipt: AgentWritingPhysicalReceipt,
        artifactReceipt: AgentWritingPhysicalReceipt,
        parentReceipt: AgentWritingPhysicalReceipt? = nil
    ) throws -> AgentArchiveManuscript {
        guard let state = archiveState, state.enabled else {
            throw AgentArchiveError.unavailable("archive disabled")
        }
        try requireArchiveOperationID(operationID)
        let manuscriptID = archiveManuscriptID(operationID: operationID)
        if let existing = state.manuscripts.first(where: { $0.operationID == operationID }) {
            guard existing.manuscriptID == manuscriptID,
                  existing.collectionID == collectionID,
                  existing.artifactID == artifactID,
                  existing.relationship == relationship,
                  existing.cataloguerID == cataloguerID else {
                throw AgentArchiveError.invalidState("conflicting manuscript replay")
            }
            return existing
        }
        try requireUnusedArchiveOperationID(operationID)
        guard state.manuscripts.count < state.configuration.maximumManuscripts,
              state.indexRevision < UInt64.max,
              !state.manuscripts.contains(where: { $0.artifactID == artifactID }),
              let collection = state.collections.first(where: {
                  $0.collectionID == collectionID
              }),
              let catalogueArtifact = writingArtifact(collection.catalogueArtifactID),
              let artifact = writingArtifact(artifactID) else {
            throw AgentArchiveError.capacityReached("manuscripts or archive source")
        }
        try requireWritingReceipt(
            catalogueReceipt,
            plan: catalogueArtifact.plan,
            actorID: cataloguerID
        )
        try requireWritingReceipt(
            artifactReceipt,
            plan: artifact.plan,
            actorID: cataloguerID
        )
        guard catalogueReceipt.observedAtTick == artifactReceipt.observedAtTick else {
            throw AgentArchiveError.unavailable("non-atomic catalogue access")
        }

        let parent: AgentArchiveManuscript?
        let rootArtifactID: String
        let generation: Int
        switch relationship {
        case .source:
            guard parentReceipt == nil else {
                throw AgentArchiveError.invalidState("source has parent receipt")
            }
            parent = nil
            rootArtifactID = artifactID
            generation = 0
        case let .facsimile(parentID), let .revision(parentID):
            guard let found = state.manuscripts.first(where: {
                $0.manuscriptID == parentID
            }), let parentArtifact = writingArtifact(found.artifactID),
                  let parentReceipt else {
                throw AgentArchiveError.unavailable("missing manuscript parent")
            }
            try requireWritingReceipt(
                parentReceipt,
                plan: parentArtifact.plan,
                actorID: cataloguerID
            )
            guard parentReceipt.observedAtTick == artifactReceipt.observedAtTick,
                  found.generation < Int.max else {
                throw AgentArchiveError.unavailable("non-atomic or overflowing lineage")
            }
            switch relationship {
            case .facsimile:
                guard artifact.plan.assertedProposition
                        == parentArtifact.plan.assertedProposition,
                      artifact.plan.lines == parentArtifact.plan.lines else {
                    throw AgentArchiveError.invalidState("facsimile content mismatch")
                }
            case .revision:
                guard artifact.plan.assertedProposition.questionKey
                        == parentArtifact.plan.assertedProposition.questionKey,
                      artifact.plan.assertedProposition
                        != parentArtifact.plan.assertedProposition else {
                    throw AgentArchiveError.invalidState("revision continuity mismatch")
                }
            case .source:
                preconditionFailure("unreachable relationship")
            }
            parent = found
            rootArtifactID = found.rootArtifactID
            generation = found.generation + 1
        }

        var candidate = self
        let witness = AgentArchiveMaterialWitness(artifactReceipt)
        let causes = [
            collection.creationEventID,
            artifact.inscriptionEventID,
            parent?.registrationEventID
        ].compactMap { $0 }
        let event = try candidate.requiredArchiveEvent(
            .archiveManuscriptCatalogued,
            actorID: cataloguerID,
            causes: causes,
            recordID: manuscriptID.rawValue,
            detail: writingDigest([
                operationID,
                collectionID.rawValue,
                artifactID,
                relationship.indexKey,
                relationship.parentID?.rawValue ?? "none",
                writingDigest(witness)
            ])
        )
        let manuscript = AgentArchiveManuscript(
            manuscriptID: manuscriptID,
            operationID: operationID,
            collectionID: collectionID,
            artifactID: artifactID,
            relationship: relationship,
            rootArtifactID: rootArtifactID,
            generation: generation,
            cataloguerID: cataloguerID,
            materialWitness: witness,
            registeredAtTick: tick,
            registrationEventID: event.eventID
        )
        candidate.archiveState!.manuscripts.append(manuscript)
        try candidate.advanceArchiveIndexSource()
        try candidate.commitArchiveBoundary(causes: [event.eventID])
        try candidate.validateArchiveState()
        self = candidate
        return manuscript
    }

    public func rebuildArchiveIndex() throws -> AgentArchiveIndex {
        guard let state = archiveState, state.enabled,
              let writing = writingState else {
            throw AgentArchiveError.unavailable("archive disabled")
        }
        try validateArchiveState()
        let artifacts = Dictionary(uniqueKeysWithValues: writing.artifacts.map {
            ($0.artifactID, $0)
        })
        let collections = Dictionary(uniqueKeysWithValues: state.collections.map {
            ($0.collectionID, $0)
        })
        var postings: [String: [AgentArchiveIndexEntry]] = [:]
        var emitted = 0
        for manuscript in state.manuscripts {
            guard let artifact = artifacts[manuscript.artifactID],
                  collections[manuscript.collectionID] != nil else {
                throw AgentArchiveError.invalidState("unrebuildable archive index")
            }
            let entry = AgentArchiveIndexEntry(
                manuscriptID: manuscript.manuscriptID,
                collectionID: manuscript.collectionID,
                artifactID: manuscript.artifactID,
                materialID: artifact.plan.materialID,
                rootArtifactID: manuscript.rootArtifactID,
                generation: manuscript.generation,
                relationship: manuscript.relationship.indexKey,
                authorID: artifact.plan.authorID,
                dimension: artifact.plan.dimension,
                cell: artifact.plan.cell,
                registeredAtTick: manuscript.registeredAtTick
            )
            let keys = Set([
                AgentArchiveSearchQuery.collection(manuscript.collectionID).key,
                AgentArchiveSearchQuery.artifact(manuscript.artifactID).key,
                AgentArchiveSearchQuery.lineageRoot(manuscript.rootArtifactID).key,
                AgentArchiveSearchQuery.author(artifact.plan.authorID).key,
                AgentArchiveSearchQuery.proposition(
                    artifact.plan.assertedProposition.propositionID
                ).key,
                AgentArchiveSearchQuery.question(
                    artifact.plan.assertedProposition.questionKey
                ).key,
                AgentArchiveSearchQuery.relationship(
                    manuscript.relationship.indexKey
                ).key
            ]).sorted()
            for key in keys {
                postings[key, default: []].append(entry)
                emitted += 1
            }
        }
        for key in postings.keys {
            postings[key]!.sort {
                if $0.generation != $1.generation {
                    return $0.generation < $1.generation
                }
                return $0.manuscriptID < $1.manuscriptID
            }
        }
        return AgentArchiveIndex(
            sourceRevision: state.indexRevision,
            sourceDigest: state.indexSourceDigest,
            metrics: AgentArchiveIndexMetrics(
                writingArtifactsVisited: writing.artifacts.count,
                collectionsVisited: state.collections.count,
                manuscriptsVisited: state.manuscripts.count,
                postingsEmitted: emitted,
                maximumPossiblePostings: state.configuration.maximumManuscripts * 7
            ),
            postings: postings
        )
    }

    public func searchArchive(
        _ index: AgentArchiveIndex,
        collectionID: AgentArchiveCollectionID,
        query: AgentArchiveSearchQuery,
        requesterID: AgentID,
        catalogueReceipt: AgentWritingPhysicalReceipt,
        limit: Int? = nil
    ) throws -> AgentArchiveSearchResult {
        guard let state = archiveState, state.enabled,
              index.sourceRevision == state.indexRevision,
              index.sourceDigest == state.indexSourceDigest else {
            throw AgentArchiveError.unavailable("stale archive index")
        }
        let requestedLimit = limit ?? state.configuration.maximumSearchResults
        guard let queryKey = query.boundedKey,
              (1...state.configuration.maximumSearchResults).contains(requestedLimit),
              let collection = state.collections.first(where: {
                  $0.collectionID == collectionID
              }),
              let catalogueArtifact = writingArtifact(
                  collection.catalogueArtifactID
              ) else {
            throw AgentArchiveError.invalidState("bounded collection-scoped search")
        }
        try requireWritingReceipt(
            catalogueReceipt,
            plan: catalogueArtifact.plan,
            actorID: requesterID
        )
        let matches = index.postings[queryKey] ?? []
        // Every query is collection-scoped. Cross-collection results cannot
        // leak through a shared posting such as author or question.
        let scoped = matches.filter { $0.collectionID == collectionID }
        let visible = Array(scoped.prefix(requestedLimit))
        return AgentArchiveSearchResult(
            query: query,
            hits: visible.map {
                AgentArchiveSearchHit(
                    entry: $0,
                    selection: AgentArchiveSelection(entry: $0, index: index)
                )
            },
            totalMatches: scoped.count,
            truncated: scoped.count > visible.count,
            metrics: AgentArchiveSearchMetrics(
                globalRecordsScanned: 0,
                postingEntriesVisited: matches.count,
                maximumPostingEntriesVisited: state.configuration.maximumManuscripts
            )
        )
    }

    @discardableResult
    public mutating func retrieveArchiveManuscript(
        operationID: String,
        selection: AgentArchiveSelection,
        readerID: AgentID,
        receipt: AgentWritingPhysicalReceipt
    ) throws -> AgentArchiveRetrievalResult {
        guard let state = archiveState, state.enabled else {
            throw AgentArchiveError.unavailable("archive disabled")
        }
        try requireArchiveOperationID(operationID)
        if let existing = state.retrievals.first(where: {
            $0.operationID == operationID
        }) {
            guard existing.manuscriptID == selection.manuscriptID,
                  existing.collectionID == selection.collectionID,
                  existing.artifactID == selection.artifactID,
                  existing.readerID == readerID,
                  let reading = writingState?.readings.first(where: {
                      $0.readingID == existing.writingReadingID
                  }) else {
                throw AgentArchiveError.invalidState("conflicting retrieval replay")
            }
            return AgentArchiveRetrievalResult(
                archiveRecord: existing,
                writingReading: reading
            )
        }
        try requireUnusedArchiveOperationID(operationID)
        guard state.retrievals.count < state.configuration.maximumRetrievals,
              selection.indexRevision == state.indexRevision,
              selection.indexSourceDigest == state.indexSourceDigest,
              let manuscript = state.manuscripts.first(where: {
                  $0.manuscriptID == selection.manuscriptID
              }),
              manuscript.collectionID == selection.collectionID,
              manuscript.artifactID == selection.artifactID,
              let artifact = writingArtifact(manuscript.artifactID) else {
            throw AgentArchiveError.unavailable("stale or missing archive selection")
        }
        try requireWritingReceipt(receipt, plan: artifact.plan, actorID: readerID)

        var candidate = self
        let reading = try candidate.readWriting(
            artifactID: artifact.artifactID,
            readerID: readerID,
            receipt: receipt
        )
        let event = try candidate.requiredArchiveEvent(
            .archiveManuscriptRetrieved,
            actorID: readerID,
            causes: [manuscript.registrationEventID, reading.readingEventID],
            recordID: operationID,
            detail: writingDigest([
                selection.manuscriptID.rawValue,
                selection.artifactID,
                String(selection.indexRevision),
                selection.indexSourceDigest,
                reading.readingID
            ])
        )
        let archiveRecord = AgentArchiveRetrieval(
            operationID: operationID,
            manuscriptID: manuscript.manuscriptID,
            collectionID: manuscript.collectionID,
            artifactID: manuscript.artifactID,
            readerID: readerID,
            indexRevision: selection.indexRevision,
            indexSourceDigest: selection.indexSourceDigest,
            writingReadingID: reading.readingID,
            retrievedAtTick: tick,
            retrievalEventID: event.eventID
        )
        candidate.archiveState!.retrievals.append(archiveRecord)
        try candidate.commitArchiveBoundary(causes: [event.eventID])
        try candidate.validateKnowledgeGraphStateIfEnabled()
        try candidate.validateLanguageStateIfInitialized()
        try candidate.validateWritingState()
        try candidate.validateArchiveState()
        self = candidate
        return AgentArchiveRetrievalResult(
            archiveRecord: archiveRecord,
            writingReading: reading
        )
    }

    public func archiveSnapshot() -> AgentArchiveSnapshot {
        guard let state = archiveState else {
            return AgentArchiveSnapshot(
                enabled: false,
                tick: tick,
                configuration: nil,
                collections: [],
                manuscripts: [],
                retrievals: [],
                indexRevision: 0,
                indexSourceDigest: "",
                boundary: nil,
                digest: writingDigest(["archive-disabled", String(tick)])
            )
        }
        return AgentArchiveSnapshot(
            enabled: state.enabled,
            tick: tick,
            configuration: state.configuration,
            collections: state.collections,
            manuscripts: state.manuscripts,
            retrievals: state.retrievals,
            indexRevision: state.indexRevision,
            indexSourceDigest: state.indexSourceDigest,
            boundary: state.boundary,
            digest: writingDigest(state)
        )
    }

    func writingArtifact(_ artifactID: String) -> AgentWrittenArtifact? {
        writingState?.artifacts.first { $0.artifactID == artifactID }
    }

    func archiveCollectionID(operationID: String) -> AgentArchiveCollectionID {
        AgentArchiveCollectionID(
            rawValue: "collection-" + writingDigest([
                archiveState?.worldID ?? "",
                operationID
            ])
        )!
    }

    func archiveManuscriptID(operationID: String) -> AgentArchiveManuscriptID {
        AgentArchiveManuscriptID(
            rawValue: "manuscript-" + writingDigest([
                archiveState?.worldID ?? "",
                operationID
            ])
        )!
    }

    func requireArchiveOperationID(_ operationID: String) throws {
        guard archiveIdentifierIsValid(operationID, maximum: 128) else {
            throw AgentArchiveError.invalidState("operation identity")
        }
    }

    func requireUnusedArchiveOperationID(_ operationID: String) throws {
        guard let state = archiveState,
              !state.collections.contains(where: { $0.operationID == operationID }),
              !state.manuscripts.contains(where: { $0.operationID == operationID }),
              !state.retrievals.contains(where: { $0.operationID == operationID }) else {
            throw AgentArchiveError.invalidState("archive operation identity reused")
        }
    }

    mutating func advanceArchiveIndexSource() throws {
        guard archiveState!.indexRevision < UInt64.max else {
            throw AgentArchiveError.capacityReached("archive index revision")
        }
        archiveState!.indexRevision += 1
        archiveState!.indexSourceDigest = archiveIndexSourceDigest(archiveState!)
    }

    @discardableResult
    mutating func requiredArchiveEvent(
        _ kind: AgentCausalEventKind,
        actorID: AgentID? = nil,
        causes: [AgentCausalEventID] = [],
        recordID: String,
        detail: String
    ) throws -> AgentCausalEvent {
        guard let event = try recordCausalEvent(
            kind: kind,
            origin: .archiveTransition,
            actorID: actorID,
            causes: Array(Set(causes)).sorted(),
            payload: .archive(recordID: recordID, detail: detail),
            summary: "archive \(kind.rawValue)"
        ) else {
            throw AgentArchiveError.unavailable("causal ledger")
        }
        return event
    }

    mutating func commitArchiveBoundary(causes: [AgentCausalEventID]) throws {
        guard let state = archiveState else { return }
        let digest = archiveBoundaryDigest(state)
        let previous = state.boundary.map { [$0.eventID] } ?? []
        let event = try requiredArchiveEvent(
            .archiveProvenanceBoundary,
            causes: Array(Set(causes + previous)).sorted(),
            recordID: "archive",
            detail: digest
        )
        archiveState!.boundary = AgentArchiveBoundary(
            eventID: event.eventID,
            digest: digest
        )
    }

    func validateArchiveBoundary() throws {
        guard let state = archiveState else { return }
        guard let boundary = state.boundary,
              boundary.digest == archiveBoundaryDigest(state),
              let event = causalLedger.events.last(where: {
                  $0.kind == .archiveProvenanceBoundary
              }),
              event.eventID == boundary.eventID,
              event.origin == .archiveTransition,
              event.actorID == nil,
              event.payload == .archive(
                  recordID: "archive",
                  detail: boundary.digest
              ) else {
            throw AgentArchiveError.invalidState("exact latest archive boundary")
        }
    }

    func validateArchiveEvent(
        _ id: AgentCausalEventID,
        kind: AgentCausalEventKind,
        actorID: AgentID?,
        payload: AgentCausalPayload
    ) throws {
        guard id.simulationID == simulationID,
              id.sequence.rawValue > 0,
              id.sequence.rawValue <= causalLedger.latestSequence else {
            throw AgentArchiveError.invalidState("archive event reference")
        }
        if let event = causalLedger.events.first(where: { $0.eventID == id }) {
            guard event.kind == kind,
                  event.origin == .archiveTransition,
                  event.actorID == actorID,
                  event.payload == payload else {
                throw AgentArchiveError.invalidState("archive event payload")
            }
        } else if id.sequence.rawValue > causalLedger.droppedEventCount {
            throw AgentArchiveError.invalidState("impossible archive event")
        }
    }

    func validateArchiveState() throws {
        guard let state = archiveState else { return }
        try validateArchiveBoundary()
        _ = try AgentArchiveConfiguration(
            maximumCollections: state.configuration.maximumCollections,
            maximumManuscripts: state.configuration.maximumManuscripts,
            maximumRetrievals: state.configuration.maximumRetrievals,
            maximumSearchResults: state.configuration.maximumSearchResults
        )
        guard let writing = writingState,
              writing.enabled,
              writing.worldID == state.worldID,
              archiveIdentifierIsValid(state.worldID, maximum: 128),
              state.collections.count <= state.configuration.maximumCollections,
              state.manuscripts.count <= state.configuration.maximumManuscripts,
              state.retrievals.count <= state.configuration.maximumRetrievals,
              state.indexRevision >= 1,
              state.indexSourceDigest == archiveIndexSourceDigest(state),
              Set(state.collections.map(\.collectionID)).count
                  == state.collections.count,
              Set(state.manuscripts.map(\.manuscriptID)).count
                  == state.manuscripts.count,
              Set(state.manuscripts.map(\.artifactID)).count
                  == state.manuscripts.count else {
            throw AgentArchiveError.invalidState("archive bounds or source digest")
        }
        let operationIDs = state.collections.map(\.operationID)
            + state.manuscripts.map(\.operationID)
            + state.retrievals.map(\.operationID)
        guard Set(operationIDs).count == operationIDs.count,
              operationIDs.allSatisfy({ archiveIdentifierIsValid($0, maximum: 128) }) else {
            throw AgentArchiveError.invalidState("archive operation identities")
        }
        let artifacts = Dictionary(uniqueKeysWithValues: writing.artifacts.map {
            ($0.artifactID, $0)
        })
        var collections: [AgentArchiveCollectionID: AgentArchiveCollection] = [:]
        for collection in state.collections {
            guard collection.collectionID
                    == archiveCollectionID(operationID: collection.operationID),
                  collections[collection.collectionID] == nil,
                  let artifact = artifacts[collection.catalogueArtifactID],
                  collection.materialWitness.observerID == collection.curatorID,
                  collection.createdAtTick
                    == collection.materialWitness.observedAtTick,
                  archiveWitness(collection.materialWitness, matches: artifact),
                  artifact.inscriptionEventID.sequence
                    < collection.creationEventID.sequence,
                  collection.creationEventID.sequence
                    < state.boundary!.eventID.sequence else {
                throw AgentArchiveError.invalidState("collection provenance")
            }
            let detail = writingDigest([
                collection.operationID,
                collection.kind.rawValue,
                writingDigest(collection.materialWitness)
            ])
            try validateArchiveEvent(
                collection.creationEventID,
                kind: .archiveCollectionCreated,
                actorID: collection.curatorID,
                payload: .archive(
                    recordID: collection.collectionID.rawValue,
                    detail: detail
                )
            )
            collections[collection.collectionID] = collection
        }

        var manuscripts: [AgentArchiveManuscriptID: AgentArchiveManuscript] = [:]
        for manuscript in state.manuscripts {
            guard manuscript.manuscriptID
                    == archiveManuscriptID(operationID: manuscript.operationID),
                  collections[manuscript.collectionID] != nil,
                  let artifact = artifacts[manuscript.artifactID],
                  manuscript.materialWitness.observerID == manuscript.cataloguerID,
                  manuscript.registeredAtTick
                    == manuscript.materialWitness.observedAtTick,
                  archiveWitness(manuscript.materialWitness, matches: artifact),
                  artifact.inscriptionEventID.sequence
                    < manuscript.registrationEventID.sequence,
                  manuscript.registrationEventID.sequence
                    < state.boundary!.eventID.sequence else {
                throw AgentArchiveError.invalidState("manuscript provenance")
            }
            let parent = manuscript.relationship.parentID.flatMap {
                manuscripts[$0]
            }
            switch manuscript.relationship {
            case .source:
                guard manuscript.rootArtifactID == manuscript.artifactID,
                      manuscript.generation == 0 else {
                    throw AgentArchiveError.invalidState("source lineage")
                }
            case .facsimile:
                guard let parent,
                      let parentArtifact = artifacts[parent.artifactID],
                      manuscript.rootArtifactID == parent.rootArtifactID,
                      manuscript.generation == parent.generation + 1,
                      artifact.plan.assertedProposition
                        == parentArtifact.plan.assertedProposition,
                      artifact.plan.lines == parentArtifact.plan.lines,
                      parent.registrationEventID.sequence
                        < manuscript.registrationEventID.sequence else {
                    throw AgentArchiveError.invalidState("facsimile lineage")
                }
            case .revision:
                guard let parent,
                      let parentArtifact = artifacts[parent.artifactID],
                      manuscript.rootArtifactID == parent.rootArtifactID,
                      manuscript.generation == parent.generation + 1,
                      artifact.plan.assertedProposition.questionKey
                        == parentArtifact.plan.assertedProposition.questionKey,
                      artifact.plan.assertedProposition
                        != parentArtifact.plan.assertedProposition,
                      parent.registrationEventID.sequence
                        < manuscript.registrationEventID.sequence else {
                    throw AgentArchiveError.invalidState("revision lineage")
                }
            }
            let detail = writingDigest([
                manuscript.operationID,
                manuscript.collectionID.rawValue,
                manuscript.artifactID,
                manuscript.relationship.indexKey,
                manuscript.relationship.parentID?.rawValue ?? "none",
                writingDigest(manuscript.materialWitness)
            ])
            try validateArchiveEvent(
                manuscript.registrationEventID,
                kind: .archiveManuscriptCatalogued,
                actorID: manuscript.cataloguerID,
                payload: .archive(
                    recordID: manuscript.manuscriptID.rawValue,
                    detail: detail
                )
            )
            manuscripts[manuscript.manuscriptID] = manuscript
        }

        for retrieval in state.retrievals {
            guard let manuscript = manuscripts[retrieval.manuscriptID],
                  manuscript.collectionID == retrieval.collectionID,
                  manuscript.artifactID == retrieval.artifactID,
                  retrieval.indexRevision <= state.indexRevision,
                  archiveIdentifierIsValid(
                    retrieval.indexSourceDigest,
                    maximum: 64
                  ),
                  retrieval.indexSourceDigest.count == 64,
                  let reading = writing.readings.first(where: {
                      $0.readingID == retrieval.writingReadingID
                  }),
                  reading.artifactID == retrieval.artifactID,
                  reading.readerID == retrieval.readerID,
                  retrieval.retrievedAtTick
                    == reading.physicalReceipt.observedAtTick,
                  manuscript.registrationEventID.sequence
                    < retrieval.retrievalEventID.sequence,
                  reading.readingEventID.sequence
                    < retrieval.retrievalEventID.sequence,
                  retrieval.retrievalEventID.sequence
                    < state.boundary!.eventID.sequence else {
                throw AgentArchiveError.invalidState("retrieval provenance")
            }
            let detail = writingDigest([
                retrieval.manuscriptID.rawValue,
                retrieval.artifactID,
                String(retrieval.indexRevision),
                retrieval.indexSourceDigest,
                retrieval.writingReadingID
            ])
            try validateArchiveEvent(
                retrieval.retrievalEventID,
                kind: .archiveManuscriptRetrieved,
                actorID: retrieval.readerID,
                payload: .archive(
                    recordID: retrieval.operationID,
                    detail: detail
                )
            )
        }
    }

    func archiveWitness(
        _ witness: AgentArchiveMaterialWitness,
        matches artifact: AgentWrittenArtifact
    ) -> Bool {
        let receipt = artifact.physicalReceipt
        return witness.worldID == receipt.worldID
            && witness.dimension == receipt.dimension
            && witness.cell == receipt.cell
            && witness.artifactID == artifact.artifactID
            && witness.materialID == artifact.plan.materialID
            && witness.contentDigest == artifact.plan.contentDigest
            && witness.observedAtTick >= artifact.plan.preparedAtTick
            && witness.observedAtTick <= tick
    }
}
