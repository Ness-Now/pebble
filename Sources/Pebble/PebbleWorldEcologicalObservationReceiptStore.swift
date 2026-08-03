import Foundation
import PebbleAgents
import PebbleCore

enum PebbleWorldEcologicalObservationReceiptError: Error,
    CustomStringConvertible {
    case databaseUnavailable
    case invalidWorldIdentity
    case capacityReached
    case duplicateReceipt(String)
    case missingReceipt(String)
    case invalidReceipt(String)
    case rollbackFailed(String)

    var description: String {
        switch self {
        case .databaseUnavailable:
            return "World-side receipt database unavailable"
        case .invalidWorldIdentity:
            return "World-side receipt identity invalid"
        case .capacityReached:
            return "World-side receipt capacity reached"
        case let .duplicateReceipt(id):
            return "duplicate World-side receipt \(id)"
        case let .missingReceipt(id):
            return "missing World-side receipt \(id)"
        case let .invalidReceipt(id):
            return "invalid World-side receipt \(id)"
        case let .rollbackFailed(id):
            return "World-side receipt rollback failed \(id)"
        }
    }
}

/// Immutable evidence emitted by Pebble from a real World scan and stored in
/// `SaveDB.world_receipts`, outside the Agent checkpoint bundle.
struct PebbleEcologicalObservationReceipt: Codable, Equatable {
    static let currentVersion = 1
    static let kind = "pebble.ecological-observation.v1"

    let version: Int
    let receiptID: AgentPhysicalObservationReceiptID
    let operationID: String
    let observerID: AgentID
    let worldID: String
    let storageIdentity: String
    let dimension: Int
    let dimensionKey: String
    let physicalWorldTick: Int
    let simulationID: AgentSimulationID
    let simulationTick: Int
    let origin: AgentPosition
    let observation: AgentEcologicalObservation
    let resultCount: Int
    let worldReadCount: Int
    let createdByPhysicalSensor: Bool
    let receiptDigest: AgentCheckpointDigest

    init(
        observation: AgentEcologicalObservation,
        worldID: String,
        storageIdentity: String,
        dimension: Int,
        simulationID: AgentSimulationID,
        ordinal: UInt64
    ) {
        let identitySource = [
            "world-ecological-receipt-id-v1", worldID, storageIdentity,
            String(dimension), simulationID.rawValue, String(ordinal),
            String(observation.observedAtSimulationTick), observation.digest,
        ].joined(separator: "|")
        let identityDigest = AgentCheckpointDigest.sha256(
            Data(identitySource.utf8)
        )
        let receiptID = AgentPhysicalObservationReceiptID(
            rawValue: "eco-\(identityDigest.rawValue.prefix(40))"
        )!
        let evidence = AgentEcologicalPhysicalReceiptEvidence(
            receiptID: receiptID,
            operationID: receiptID.rawValue,
            observerID: observation.observerID,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            dimensionKey: observation.dimensionKey,
            physicalWorldTick: observation.physicalWorldTick,
            simulationID: simulationID,
            simulationTick: observation.observedAtSimulationTick,
            origin: observation.origin,
            observation: observation,
            resultCount: observation.diagnostics.resultsEmitted,
            worldReadCount: observation.diagnostics.worldReads
        )
        version = Self.currentVersion
        self.receiptID = receiptID
        operationID = receiptID.rawValue
        observerID = observation.observerID
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.dimension = dimension
        dimensionKey = observation.dimensionKey
        physicalWorldTick = observation.physicalWorldTick
        self.simulationID = simulationID
        simulationTick = observation.observedAtSimulationTick
        origin = observation.origin
        self.observation = observation
        resultCount = observation.diagnostics.resultsEmitted
        worldReadCount = observation.diagnostics.worldReads
        createdByPhysicalSensor = true
        receiptDigest = evidence.receiptDigest
    }

    var evidence: AgentEcologicalPhysicalReceiptEvidence {
        AgentEcologicalPhysicalReceiptEvidence(
            version: version,
            receiptID: receiptID,
            operationID: operationID,
            observerID: observerID,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            dimensionKey: dimensionKey,
            physicalWorldTick: physicalWorldTick,
            simulationID: simulationID,
            simulationTick: simulationTick,
            origin: origin,
            observation: observation,
            resultCount: resultCount,
            worldReadCount: worldReadCount,
            receiptDigest: receiptDigest
        )
    }

    var isValid: Bool {
        version == Self.currentVersion
            && operationID == receiptID.rawValue
            && createdByPhysicalSensor
            && physicalWorldTick >= 0
            && simulationTick >= 0
            && observation.hasValidDigest()
            && observation.observerID == observerID
            && observation.origin == origin
            && observation.dimensionKey == dimensionKey
            && observation.physicalWorldTick == physicalWorldTick
            && observation.observedAtSimulationTick == simulationTick
            && observation.diagnostics.resultsEmitted == resultCount
            && observation.diagnostics.worldReads == worldReadCount
            && evidence.hasValidDigest
    }
}

struct PebbleWorldEcologicalObservationReceiptStore {
    static let maximumReceiptsPerWorld = 73_728

    let database: SaveDB
    let worldID: String
    let storageIdentity: String
    let maximumReceipts: Int

    init(
        database: SaveDB,
        worldID: String,
        storageIdentity: String,
        maximumReceipts: Int = maximumReceiptsPerWorld
    ) throws {
        guard (1...240).contains(worldID.count),
              storageIdentity == "sqlite-world:\(worldID)",
              (1...Self.maximumReceiptsPerWorld).contains(maximumReceipts)
        else {
            throw PebbleWorldEcologicalObservationReceiptError
                .invalidWorldIdentity
        }
        self.database = database
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.maximumReceipts = maximumReceipts
    }

    func makeReceipt(
        observation: AgentEcologicalObservation,
        simulationID: AgentSimulationID,
        dimension: Int,
        ordinal: UInt64
    ) -> PebbleEcologicalObservationReceipt {
        PebbleEcologicalObservationReceipt(
            observation: observation,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID,
            ordinal: ordinal
        )
    }

    func insert(_ receipt: PebbleEcologicalObservationReceipt) throws {
        guard receipt.isValid,
              receipt.worldID == worldID,
              receipt.storageIdentity == storageIdentity else {
            throw PebbleWorldEcologicalObservationReceiptError.invalidReceipt(
                receipt.receiptID.rawValue
            )
        }
        let rows = database.listWorldReceipts(
            worldID: worldID,
            kind: PebbleEcologicalObservationReceipt.kind
        )
        guard rows.count < maximumReceipts else {
            throw PebbleWorldEcologicalObservationReceiptError.capacityReached
        }
        let bytes = try JSONEncoder.sorted.encode(receipt)
        guard database.putWorldReceiptIfAbsent(
            worldID: worldID,
            kind: PebbleEcologicalObservationReceipt.kind,
            receiptID: receipt.receiptID.rawValue,
            data: bytes
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .duplicateReceipt(receipt.receiptID.rawValue)
        }
    }

    func receipt(
        _ receiptID: AgentPhysicalObservationReceiptID
    ) throws -> PebbleEcologicalObservationReceipt {
        guard let bytes = database.getWorldReceipt(
            worldID: worldID,
            kind: PebbleEcologicalObservationReceipt.kind,
            receiptID: receiptID.rawValue
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .missingReceipt(receiptID.rawValue)
        }
        guard let receipt = try? JSONDecoder().decode(
            PebbleEcologicalObservationReceipt.self, from: bytes
        ), receipt.receiptID == receiptID, receipt.worldID == worldID,
           receipt.storageIdentity == storageIdentity, receipt.isValid,
           (try? JSONEncoder.sorted.encode(receipt)) == bytes else {
            throw PebbleWorldEcologicalObservationReceiptError
                .invalidReceipt(receiptID.rawValue)
        }
        return receipt
    }

    func evidence(
        for receiptIDs: [AgentPhysicalObservationReceiptID]
    ) throws -> [AgentEcologicalPhysicalReceiptEvidence] {
        guard receiptIDs.count == Set(receiptIDs).count else {
            throw PebbleWorldEcologicalObservationReceiptError
                .duplicateReceipt("requested")
        }
        return try receiptIDs.sorted().map { try receipt($0).evidence }
    }

    func remove(
        _ receiptID: AgentPhysicalObservationReceiptID
    ) throws -> PebbleEcologicalObservationReceipt {
        let prior = try receipt(receiptID)
        guard database.deleteWorldReceipt(
            worldID: worldID,
            kind: PebbleEcologicalObservationReceipt.kind,
            receiptID: receiptID.rawValue
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .rollbackFailed(receiptID.rawValue)
        }
        return prior
    }

    func restore(_ receipt: PebbleEcologicalObservationReceipt) throws {
        guard database.putWorldReceiptIfAbsent(
            worldID: worldID,
            kind: PebbleEcologicalObservationReceipt.kind,
            receiptID: receipt.receiptID.rawValue,
            data: try JSONEncoder.sorted.encode(receipt)
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .rollbackFailed(receipt.receiptID.rawValue)
        }
    }
}

struct PebbleAgriculturalActionReceipt: Codable, Equatable {
    static let currentVersion = 1
    static let kind = "pebble.agriculture-action.v1"

    let version: Int
    let receiptID: AgentAgriculturalActionID
    let operationID: String
    let worldID: String
    let storageIdentity: String
    let dimension: Int
    let simulationID: AgentSimulationID
    let outcome: AgentAgriculturalActionOutcome
    let createdByPhysicalExecutor: Bool
    let receiptDigest: AgentCheckpointDigest

    init(
        outcome: AgentAgriculturalActionOutcome,
        worldID: String,
        storageIdentity: String,
        dimension: Int,
        simulationID: AgentSimulationID
    ) {
        let evidence = AgentAgriculturalPhysicalReceiptEvidence(
            receiptID: outcome.actionID,
            operationID: outcome.actionID.rawValue,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID,
            outcome: outcome
        )
        version = Self.currentVersion
        receiptID = outcome.actionID
        operationID = outcome.actionID.rawValue
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.dimension = dimension
        self.simulationID = simulationID
        self.outcome = outcome
        createdByPhysicalExecutor = true
        receiptDigest = evidence.receiptDigest
    }

    var evidence: AgentAgriculturalPhysicalReceiptEvidence {
        AgentAgriculturalPhysicalReceiptEvidence(
            version: version,
            receiptID: receiptID,
            operationID: operationID,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID,
            outcome: outcome,
            receiptDigest: receiptDigest
        )
    }

    var isValid: Bool {
        version == Self.currentVersion
            && operationID == receiptID.rawValue
            && createdByPhysicalExecutor
            && outcome.actionID == receiptID
            && evidence.hasValidDigest
    }
}

struct PebbleWorldAgriculturalActionReceiptStore {
    static let maximumReceiptsPerWorld = 18_432

    let database: SaveDB
    let worldID: String
    let storageIdentity: String
    let maximumReceipts: Int

    init(
        database: SaveDB,
        worldID: String,
        storageIdentity: String,
        maximumReceipts: Int = maximumReceiptsPerWorld
    ) throws {
        guard (1...240).contains(worldID.count),
              storageIdentity == "sqlite-world:\(worldID)",
              (1...Self.maximumReceiptsPerWorld).contains(maximumReceipts)
        else {
            throw PebbleWorldEcologicalObservationReceiptError
                .invalidWorldIdentity
        }
        self.database = database
        self.worldID = worldID
        self.storageIdentity = storageIdentity
        self.maximumReceipts = maximumReceipts
    }

    func makeReceipt(
        outcome: AgentAgriculturalActionOutcome,
        simulationID: AgentSimulationID,
        dimension: Int
    ) -> PebbleAgriculturalActionReceipt {
        PebbleAgriculturalActionReceipt(
            outcome: outcome,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension,
            simulationID: simulationID
        )
    }

    func insert(_ receipt: PebbleAgriculturalActionReceipt) throws {
        guard receipt.isValid,
              receipt.worldID == worldID,
              receipt.storageIdentity == storageIdentity else {
            throw PebbleWorldEcologicalObservationReceiptError.invalidReceipt(
                receipt.receiptID.rawValue
            )
        }
        let rows = database.listWorldReceipts(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind
        )
        guard rows.count < maximumReceipts else {
            throw PebbleWorldEcologicalObservationReceiptError.capacityReached
        }
        guard database.putWorldReceiptIfAbsent(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind,
            receiptID: receipt.receiptID.rawValue,
            data: try JSONEncoder.sorted.encode(receipt)
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .duplicateReceipt(receipt.receiptID.rawValue)
        }
    }

    func receipt(
        _ receiptID: AgentAgriculturalActionID
    ) throws -> PebbleAgriculturalActionReceipt {
        guard let bytes = database.getWorldReceipt(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind,
            receiptID: receiptID.rawValue
        ), let receipt = try? JSONDecoder().decode(
            PebbleAgriculturalActionReceipt.self,
            from: bytes
        ), receipt.receiptID == receiptID,
           receipt.worldID == worldID,
           receipt.storageIdentity == storageIdentity,
           receipt.isValid,
           (try? JSONEncoder.sorted.encode(receipt)) == bytes else {
            throw PebbleWorldEcologicalObservationReceiptError
                .invalidReceipt(receiptID.rawValue)
        }
        return receipt
    }

    func evidence(
        for receiptIDs: [AgentAgriculturalActionID]
    ) throws -> [AgentAgriculturalPhysicalReceiptEvidence] {
        guard receiptIDs.count == Set(receiptIDs).count else {
            throw PebbleWorldEcologicalObservationReceiptError
                .duplicateReceipt("agriculture-requested")
        }
        return try receiptIDs.sorted().map { try receipt($0).evidence }
    }

    func remove(
        _ receiptID: AgentAgriculturalActionID
    ) throws -> PebbleAgriculturalActionReceipt {
        let prior = try receipt(receiptID)
        guard database.deleteWorldReceipt(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind,
            receiptID: receiptID.rawValue
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .rollbackFailed(receiptID.rawValue)
        }
        return prior
    }

    func restore(_ receipt: PebbleAgriculturalActionReceipt) throws {
        guard database.putWorldReceiptIfAbsent(
            worldID: worldID,
            kind: PebbleAgriculturalActionReceipt.kind,
            receiptID: receipt.receiptID.rawValue,
            data: try JSONEncoder.sorted.encode(receipt)
        ) else {
            throw PebbleWorldEcologicalObservationReceiptError
                .rollbackFailed(receipt.receiptID.rawValue)
        }
    }
}

struct PebbleWorldEcologicalObservationReceiptTransaction {
    private(set) var inserted: [PebbleEcologicalObservationReceipt] = []
    private(set) var removed: [PebbleEcologicalObservationReceipt] = []
    private(set) var insertedAgriculturalActions:
        [PebbleAgriculturalActionReceipt] = []
    private(set) var removedAgriculturalActions:
        [PebbleAgriculturalActionReceipt] = []
    private(set) var committed = false

    /// Ecological receipts created by the still-open candidate tick. A
    /// retained World receipt is intentionally absent from this projection:
    /// persistence proves history, while transaction membership grants the
    /// bounded authority used by automatic live reconciliation.
    var stagedEcologicalReceiptIDs:
        Set<AgentPhysicalObservationReceiptID> {
        Set(inserted.map(\.receiptID))
    }

    mutating func recordInsertion(
        _ receipt: PebbleEcologicalObservationReceipt
    ) {
        inserted.append(receipt)
    }

    mutating func recordRemoval(
        _ receipt: PebbleEcologicalObservationReceipt
    ) {
        if let insertedIndex = inserted.firstIndex(where: {
            $0.receiptID == receipt.receiptID
        }) {
            inserted.remove(at: insertedIndex)
        } else {
            removed.append(receipt)
        }
    }

    mutating func recordInsertion(
        _ receipt: PebbleAgriculturalActionReceipt
    ) {
        insertedAgriculturalActions.append(receipt)
    }

    mutating func recordRemoval(
        _ receipt: PebbleAgriculturalActionReceipt
    ) {
        if let insertedIndex = insertedAgriculturalActions.firstIndex(where: {
            $0.receiptID == receipt.receiptID
        }) {
            insertedAgriculturalActions.remove(at: insertedIndex)
        } else {
            removedAgriculturalActions.append(receipt)
        }
    }

    mutating func commit() {
        committed = true
    }
}

extension PebbleAgentController {
    func worldEcologicalObservationReceiptStore() throws
        -> PebbleWorldEcologicalObservationReceiptStore {
        guard let database = worldSideReceiptDatabase,
              let worldID = persistenceWorldID else {
            throw PebbleWorldEcologicalObservationReceiptError
                .databaseUnavailable
        }
        return try PebbleWorldEcologicalObservationReceiptStore(
            database: database,
            worldID: worldID,
            storageIdentity: "sqlite-world:\(worldID)"
        )
    }

    func worldAgriculturalActionReceiptStore() throws
        -> PebbleWorldAgriculturalActionReceiptStore {
        guard let database = worldSideReceiptDatabase,
              let worldID = persistenceWorldID else {
            throw PebbleWorldEcologicalObservationReceiptError
                .databaseUnavailable
        }
        return try PebbleWorldAgriculturalActionReceiptStore(
            database: database,
            worldID: worldID,
            storageIdentity: "sqlite-world:\(worldID)"
        )
    }

    func rollbackWorldEcologicalObservationReceipts(
        _ transaction: PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        guard !transaction.committed else { return }
        if !transaction.inserted.isEmpty || !transaction.removed.isEmpty {
            let store = try worldEcologicalObservationReceiptStore()
            for receipt in transaction.inserted.reversed() {
                _ = try store.remove(receipt.receiptID)
            }
            for receipt in transaction.removed.reversed() {
                try store.restore(receipt)
            }
        }
        if !transaction.insertedAgriculturalActions.isEmpty
            || !transaction.removedAgriculturalActions.isEmpty {
            let store = try worldAgriculturalActionReceiptStore()
            for receipt in transaction.insertedAgriculturalActions.reversed() {
                _ = try store.remove(receipt.receiptID)
            }
            for receipt in transaction.removedAgriculturalActions.reversed() {
                try store.restore(receipt)
            }
        }
    }

    func requiredWorldEcologicalObservationReceiptIDs(
        for session: AgentSimulationSession
    ) -> Set<AgentPhysicalObservationReceiptID> {
        Set(
            session.ecologicalObservationSnapshot().observations
                .compactMap(\.physicalObservationReceiptID)
                + session.agricultureSnapshot().plots.compactMap(
                    \.sourceObservationReceiptID
                )
                + session.agricultureSnapshot().plots.compactMap {
                    $0.renewalEvidence?.sourceObservationReceiptID
                }
        )
    }

    func causalWorldEcologicalObservationReceiptIDs(
        for session: AgentSimulationSession
    ) -> Set<AgentPhysicalObservationReceiptID> {
        var required: Set<AgentPhysicalObservationReceiptID> = []
        for event in session.causalLedgerSnapshot().events
        where event.kind == .ecologicalObservationRecorded
            && event.origin == .ecologicalObservationTransition {
            if case let .ecologicalObservation(
                _, _, _, physicalReceiptID, _, _, _, _, _
            ) = event.payload,
               let physicalReceiptID,
               let receiptID = AgentPhysicalObservationReceiptID(
                    rawValue: physicalReceiptID
               ) {
                required.insert(receiptID)
            }
        }
        return required
    }

    func reconcileWorldEcologicalObservationReceiptRetention(
        for candidate: AgentSimulationSession,
        transaction: inout PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        let store = try worldEcologicalObservationReceiptStore()
        var protected = requiredWorldEcologicalObservationReceiptIDs(
            for: candidate
        )
        protected.formUnion(
            causalWorldEcologicalObservationReceiptIDs(for: candidate)
        )
        if let worldID = persistenceWorldID {
            let persistence = try PebbleAgentPersistenceStore(worldID: worldID)
            for name in try persistence.checkpointNames() {
                guard let checkpoint = try? persistence.loadCheckpoint(
                    name: name
                ), let restored = try? AgentSimulationSession.restoring(
                    checkpoint.checkpoint
                ) else {
                    // An unloadable bundle cannot authorize retention or load.
                    continue
                }
                protected.formUnion(
                    requiredWorldEcologicalObservationReceiptIDs(for: restored)
                )
            }
        }
        _ = try store.evidence(for: protected.sorted())
        for row in store.database.listWorldReceipts(
            worldID: store.worldID,
            kind: PebbleEcologicalObservationReceipt.kind
        ) {
            guard let receiptID = AgentPhysicalObservationReceiptID(
                rawValue: row.receiptID
            ) else {
                throw PebbleWorldEcologicalObservationReceiptError
                    .invalidReceipt(row.receiptID)
            }
            guard !protected.contains(receiptID) else { continue }
            let removed = try store.remove(receiptID)
            transaction.recordRemoval(removed)
        }
    }

    func requiredWorldAgriculturalActionReceiptIDs(
        for session: AgentSimulationSession
    ) -> Set<AgentAgriculturalActionID> {
        Set(session.agricultureSnapshot().retainedActions.map(
            \.outcome.actionID
        ))
    }

    func causalWorldAgriculturalActionReceiptIDs(
        for session: AgentSimulationSession
    ) -> Set<AgentAgriculturalActionID> {
        var required: Set<AgentAgriculturalActionID> = []
        for event in session.causalLedgerSnapshot().events
        where event.origin == .agricultureTransition {
            if let rawValue = event.operationID?.rawValue,
               let receiptID = AgentAgriculturalActionID(rawValue: rawValue) {
                required.insert(receiptID)
            }
        }
        return required
    }

    func reconcileWorldAgriculturalActionReceiptRetention(
        for candidate: AgentSimulationSession,
        transaction: inout PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        let store = try worldAgriculturalActionReceiptStore()
        var protected = requiredWorldAgriculturalActionReceiptIDs(
            for: candidate
        )
        protected.formUnion(
            causalWorldAgriculturalActionReceiptIDs(for: candidate)
        )
        if let published = session {
            protected.formUnion(
                requiredWorldAgriculturalActionReceiptIDs(for: published)
            )
        }
        if let worldID = persistenceWorldID {
            let persistence = try PebbleAgentPersistenceStore(worldID: worldID)
            for name in try persistence.checkpointNames() {
                guard let checkpoint = try? persistence.loadCheckpoint(
                    name: name
                ), let restored = try? AgentSimulationSession.restoring(
                    checkpoint.checkpoint
                ) else { continue }
                protected.formUnion(
                    requiredWorldAgriculturalActionReceiptIDs(for: restored)
                )
            }
        }
        _ = try store.evidence(for: protected.sorted())
        for row in store.database.listWorldReceipts(
            worldID: store.worldID,
            kind: PebbleAgriculturalActionReceipt.kind
        ) {
            guard let receiptID = AgentAgriculturalActionID(
                rawValue: row.receiptID
            ) else {
                throw PebbleWorldEcologicalObservationReceiptError
                    .invalidReceipt(row.receiptID)
            }
            guard !protected.contains(receiptID) else { continue }
            transaction.recordRemoval(try store.remove(receiptID))
        }
    }

    func validateWorldEcologicalObservationReceipts(
        for session: AgentSimulationSession,
        dimension: Int
    ) throws {
        let ids = (session.ecologicalObservationSnapshot().observations)
            .compactMap(\.physicalObservationReceiptID)
            + session.agricultureSnapshot().plots.compactMap(
                \.sourceObservationReceiptID
            )
            + session.agricultureSnapshot().plots.compactMap {
                $0.renewalEvidence?.sourceObservationReceiptID
            }
        let uniqueIDs = Set(ids).sorted()
        let store = try worldEcologicalObservationReceiptStore()
        try session.validateIndependentEcologicalObservationReceipts(
            store.evidence(for: uniqueIDs),
            worldID: store.worldID,
            storageIdentity: store.storageIdentity,
            dimension: dimension
        )
        let actionIDs = requiredWorldAgriculturalActionReceiptIDs(
            for: session
        ).sorted()
        let actionStore = try worldAgriculturalActionReceiptStore()
        try session.validateIndependentAgriculturalActionReceipts(
            actionStore.evidence(for: actionIDs),
            worldID: actionStore.worldID,
            storageIdentity: actionStore.storageIdentity,
            dimension: dimension
        )
    }

    func publishVerifiedAgriculturalAction(
        _ outcome: AgentAgriculturalActionOutcome,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> AgentAgriculturalActionRecord {
        var cleanup = PebbleWorldEcologicalObservationReceiptTransaction()
        try reconcileWorldAgriculturalActionReceiptRetention(
            for: session,
            transaction: &cleanup
        )
        cleanup.commit()

        let store = try worldAgriculturalActionReceiptStore()
        let receipt = store.makeReceipt(
            outcome: outcome,
            simulationID: session.simulationID,
            dimension: world.dim.rawValue
        )
        try store.insert(receipt)
        trace(
            "agriculture World receipt id=\(receipt.receiptID.rawValue) "
                + "kind=\(receipt.outcome.kind.rawValue) "
                + "actor=\(receipt.outcome.actorID.rawValue) "
                + "plot=\(receipt.outcome.plotID.rawValue) "
                + "world=\(receipt.worldID) storage=\(receipt.storageIdentity) "
                + "dimension=\(receipt.dimension) "
                + "simulation=\(receipt.simulationID.rawValue) "
                + "receiptDigest=\(receipt.receiptDigest.rawValue) "
                + "authority=independent_world_side"
        )
        var candidate = session
        var candidateRecorder = recorder
        do {
            let record: AgentAgriculturalActionRecord
            if try applyRecordedOperationIfActive(
                .recordAgriculturalAction(outcome),
                session: &candidate,
                recorder: &candidateRecorder
            ) != nil {
                guard let restored = candidate.agricultureSnapshot()
                    .retainedActions.last(where: {
                        $0.outcome.actionID == outcome.actionID
                    }) else {
                    throw ControllerError.agricultureBoundary(
                        "agriculture replay publication missing"
                    )
                }
                record = restored
            } else {
                record = try candidate.recordAgriculturalActionSuccess(outcome)
            }
            let actionIDs = requiredWorldAgriculturalActionReceiptIDs(
                for: candidate
            ).sorted()
            try candidate.validateIndependentAgriculturalActionReceipts(
                store.evidence(for: actionIDs),
                worldID: store.worldID,
                storageIdentity: store.storageIdentity,
                dimension: world.dim.rawValue
            )
            session = candidate
            recorder = candidateRecorder
            return record
        } catch {
            _ = try store.remove(receipt.receiptID)
            throw error
        }
    }

    func publishVerifiedAgriculturalAction(
        _ outcome: AgentAgriculturalActionOutcome,
        world: World,
        session: inout AgentSimulationSession
    ) throws -> AgentAgriculturalActionRecord {
        var recorder: AgentReplayRecorder?
        return try publishVerifiedAgriculturalAction(
            outcome,
            world: world,
            session: &session,
            recorder: &recorder
        )
    }
}

private extension JSONEncoder {
    static var sorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
