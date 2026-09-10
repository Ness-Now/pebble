import PebbleAgents
import PebbleCore

enum PebbleAgentArchiveAdapterError: Error {
    case unavailable(String)
}

/// CIV-46's live physical-to-civilization boundary. The adapter owns no
/// catalogue, content, cognition or World state. It publishes an opaque
/// candidate session only while Core proves that every required CIV-45
/// inscription is still current and globally unique.
struct PebbleAgentArchiveAdapter {
    private let writing = PebbleAgentWritingAdapter()

    func createCollection(
        operationID: String,
        kind: AgentArchiveCollectionKind,
        catalogueArtifact: AgentWrittenArtifact,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        publication: ((
            inout AgentSimulationSession,
            AgentWritingPhysicalReceipt
        ) throws -> AgentArchiveCollection)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws -> AgentArchiveCollection {
        let access = try writing.observeCurrent(
            artifact: catalogueArtifact,
            actor: actor,
            world: world,
            worldID: worldID,
            tick: session.tick
        )
        return try world.withValidatedSignInscriptionAuthorities([
            access.observation
        ]) {
            var candidate = session
            let collection = try publication?(&candidate, access.receipt)
                ?? candidate.createArchiveCollection(
                    operationID: operationID,
                    kind: kind,
                    catalogueArtifactID: catalogueArtifact.artifactID,
                    curatorID: access.receipt.actorID,
                    catalogueReceipt: access.receipt
                )
            guard candidate.archiveState?.collections.contains(collection) == true else {
                throw PebbleAgentArchiveAdapterError.unavailable(
                    "collection publication"
                )
            }
            commit(candidate)
            return collection
        }
    }

    func catalogueManuscript(
        operationID: String,
        collection: AgentArchiveCollection,
        catalogueArtifact: AgentWrittenArtifact,
        artifact: AgentWrittenArtifact,
        relationship: AgentArchiveRelationship,
        parentArtifact: AgentWrittenArtifact?,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        publication: ((
            inout AgentSimulationSession,
            AgentWritingPhysicalReceipt,
            AgentWritingPhysicalReceipt,
            AgentWritingPhysicalReceipt?
        ) throws -> AgentArchiveManuscript)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws -> AgentArchiveManuscript {
        guard collection.catalogueArtifactID == catalogueArtifact.artifactID,
              (relationship.parentID == nil
                ? parentArtifact == nil : parentArtifact != nil) else {
            throw PebbleAgentArchiveAdapterError.unavailable(
                "collection or lineage artifacts"
            )
        }
        let catalogueAccess = try writing.observeCurrent(
            artifact: catalogueArtifact,
            actor: actor,
            world: world,
            worldID: worldID,
            tick: session.tick
        )
        let artifactAccess = try writing.observeCurrent(
            artifact: artifact,
            actor: actor,
            world: world,
            worldID: worldID,
            tick: session.tick
        )
        let parentAccess = try parentArtifact.map {
            try writing.observeCurrent(
                artifact: $0,
                actor: actor,
                world: world,
                worldID: worldID,
                tick: session.tick
            )
        }
        let observations = [
            catalogueAccess.observation,
            artifactAccess.observation,
            parentAccess?.observation
        ].compactMap { $0 }
        return try world.withValidatedSignInscriptionAuthorities(observations) {
            var candidate = session
            let manuscript = try publication?(
                &candidate,
                catalogueAccess.receipt,
                artifactAccess.receipt,
                parentAccess?.receipt
            ) ?? candidate.catalogueArchiveManuscript(
                operationID: operationID,
                collectionID: collection.collectionID,
                artifactID: artifact.artifactID,
                relationship: relationship,
                cataloguerID: artifactAccess.receipt.actorID,
                catalogueReceipt: catalogueAccess.receipt,
                artifactReceipt: artifactAccess.receipt,
                parentReceipt: parentAccess?.receipt
            )
            guard candidate.archiveState?.manuscripts.contains(manuscript) == true else {
                throw PebbleAgentArchiveAdapterError.unavailable(
                    "manuscript publication"
                )
            }
            commit(candidate)
            return manuscript
        }
    }

    func search(
        index: AgentArchiveIndex,
        collection: AgentArchiveCollection,
        catalogueArtifact: AgentWrittenArtifact,
        query: AgentArchiveSearchQuery,
        limit: Int? = nil,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession
    ) throws -> AgentArchiveSearchResult {
        guard collection.catalogueArtifactID == catalogueArtifact.artifactID else {
            throw PebbleAgentArchiveAdapterError.unavailable(
                "collection catalogue mark"
            )
        }
        let access = try writing.observeCurrent(
            artifact: catalogueArtifact,
            actor: actor,
            world: world,
            worldID: worldID,
            tick: session.tick
        )
        return try world.withValidatedSignInscriptionAuthorities([
            access.observation
        ]) {
            try session.searchArchive(
                index,
                collectionID: collection.collectionID,
                query: query,
                requesterID: access.receipt.actorID,
                catalogueReceipt: access.receipt,
                limit: limit
            )
        }
    }

    func retrieve(
        operationID: String,
        selection: AgentArchiveSelection,
        artifact: AgentWrittenArtifact,
        actor: LabCoreAgentEntity,
        world: World,
        worldID: String,
        session: AgentSimulationSession,
        publication: ((
            inout AgentSimulationSession,
            AgentWritingPhysicalReceipt
        ) throws -> AgentArchiveRetrievalResult)? = nil,
        commit: (AgentSimulationSession) -> Void
    ) throws -> AgentArchiveRetrievalResult {
        guard selection.artifactID == artifact.artifactID else {
            throw PebbleAgentArchiveAdapterError.unavailable(
                "retrieval selection"
            )
        }
        let access = try writing.observeCurrent(
            artifact: artifact,
            actor: actor,
            world: world,
            worldID: worldID,
            tick: session.tick
        )
        return try world.withValidatedSignInscriptionAuthorities([
            access.observation
        ]) {
            var candidate = session
            let result = try publication?(&candidate, access.receipt)
                ?? candidate.retrieveArchiveManuscript(
                    operationID: operationID,
                    selection: selection,
                    readerID: access.receipt.actorID,
                    receipt: access.receipt
                )
            guard candidate.archiveState?.retrievals.contains(
                    result.archiveRecord
                  ) == true,
                  candidate.writingState?.readings.contains(
                    result.writingReading
                  ) == true else {
                throw PebbleAgentArchiveAdapterError.unavailable(
                    "retrieval publication"
                )
            }
            commit(candidate)
            return result
        }
    }
}
