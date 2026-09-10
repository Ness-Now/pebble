import Foundation
import PebbleAgents

private struct C09RawPopulationConfiguration: Codable {
    var maximumActivePopulation: Int
    var maximumMigrationRecords: Int
    var maximumConcurrentMigrations: Int
    var maximumMigrationDistance: Int
    var maximumEntryCandidates: Int
    var maximumRouteLength: Int
    var maximumMigrationTicks: Int
    var maximumMigrationReplans: Int
    var arrivalDistance: Int

    init(_ configuration: AgentPopulationConfiguration) {
        maximumActivePopulation = configuration.maximumActivePopulation
        maximumMigrationRecords = configuration.maximumMigrationRecords
        maximumConcurrentMigrations = configuration.maximumConcurrentMigrations
        maximumMigrationDistance = configuration.maximumMigrationDistance
        maximumEntryCandidates = configuration.maximumEntryCandidates
        maximumRouteLength = configuration.maximumRouteLength
        maximumMigrationTicks = configuration.maximumMigrationTicks
        maximumMigrationReplans = configuration.maximumMigrationReplans
        arrivalDistance = configuration.arrivalDistance
    }

    func validated() throws -> AgentPopulationConfiguration {
        try AgentPopulationConfiguration(
            maximumActivePopulation: maximumActivePopulation,
            maximumMigrationRecords: maximumMigrationRecords,
            maximumConcurrentMigrations: maximumConcurrentMigrations,
            maximumMigrationDistance: maximumMigrationDistance,
            maximumEntryCandidates: maximumEntryCandidates,
            maximumRouteLength: maximumRouteLength,
            maximumMigrationTicks: maximumMigrationTicks,
            maximumMigrationReplans: maximumMigrationReplans,
            arrivalDistance: arrivalDistance
        )
    }
}

private func c09Agent(_ id: String, ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(
        x: ordinal < 3 ? ordinal * 2 : 20 + (ordinal % 16),
        y: 64,
        z: ordinal < 3 ? 0 : 12 + (ordinal / 16)
    )
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
        health: 100,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "C09 population bound proof",
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
        totalDistanceReducedTowardHome: 0
    )
}

private func c09BaseSession(id: String) throws -> AgentSimulationSession {
    try AgentSimulationSession(
        configuration: AgentSessionConfiguration(
            seed: 46,
            nearbyRadius: 8,
            resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [
            c09Agent("agent_0", ordinal: 0),
            c09Agent("agent_1", ordinal: 1),
            c09Agent("agent_2", ordinal: 2),
        ],
        simulationID: AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
}

private func c09Session(
    id: String,
    configuration: AgentPopulationConfiguration
) throws -> AgentSimulationSession {
    var session = try c09BaseSession(id: id)
    try session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: configuration
    )
    return session
}

private struct C09InvalidCheckpointFixture {
    let bytes: Data
    let durableDigest: AgentCheckpointDigest
    let checkpointID: String
}

private func c09InvalidCheckpointFixture(
    from checkpoint: AgentSessionCheckpoint,
    maximumActivePopulation: Int
) throws -> C09InvalidCheckpointFixture {
    let checkpointBytes = try AgentCheckpointCodec.encode(checkpoint)
    let validMaximum = checkpoint.durableState.populationRegistry?
        .configuration.maximumActivePopulation ?? -1
    let validDurableBytes = try AgentCheckpointCodec.encode(checkpoint.durableState)
    guard var durableText = String(data: validDurableBytes, encoding: .utf8) else {
        preconditionFailure("C09 durable state is not UTF-8 JSON")
    }
    let maximumNeedle = "\"maximumActivePopulation\":\(validMaximum)"
    let capacityNeedle = "\"capacity\":\(validMaximum)"
    precondition(durableText.components(separatedBy: maximumNeedle).count == 2)
    precondition(durableText.components(separatedBy: capacityNeedle).count == 2)
    durableText = durableText.replacingOccurrences(
        of: maximumNeedle,
        with: "\"maximumActivePopulation\":\(maximumActivePopulation)"
    )
    durableText = durableText.replacingOccurrences(
        of: capacityNeedle,
        with: "\"capacity\":\(maximumActivePopulation)"
    )
    let durableBytes = Data(durableText.utf8)
    guard var root = try JSONSerialization.jsonObject(with: checkpointBytes)
        as? [String: Any],
        let durableState = try JSONSerialization.jsonObject(with: durableBytes)
            as? [String: Any],
        let simulationID = root["simulationID"] as? String,
        let tick = root["tick"] as? Int
    else {
        preconditionFailure("C09 checkpoint JSON shape changed")
    }
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    let checkpointID = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    root["durableState"] = durableState
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = checkpointID
    let options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
    return C09InvalidCheckpointFixture(
        bytes: try JSONSerialization.data(withJSONObject: root, options: options),
        durableDigest: digest,
        checkpointID: checkpointID
    )
}

private func c09PopulationOperation(
    configuration: AgentPopulationConfiguration
) -> AgentReplayOperation {
    .setPopulationEnabled(
        true,
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: configuration
    )
}

private func c09ReplayRecord(
    session: AgentSimulationSession,
    operation: AgentReplayOperation
) throws -> (record: AgentReplayRecord, result: AgentSimulationSession) {
    var result = session
    let before = result.causalLedgerSnapshot().summary
    let preDigest = try result.durableStateDigest()
    _ = try result.applyReplayOperation(operation)
    let after = result.causalLedgerSnapshot().summary
    return (
        AgentReplayRecord(
            schemaVersion: AgentReplaySchema.currentVersion,
            simulationID: session.simulationID,
            recordSequence: AgentReplayRecordSequence(rawValue: 1)!,
            operation: operation,
            expectedTickBefore: session.tick,
            preStateSemanticDigest: preDigest,
            postStateSemanticDigest: try result.durableStateDigest(),
            causalSequenceBefore: before.latestSequence,
            causalSequenceAfter: after.latestSequence,
            causalDigestAfter: after.digest
        ),
        result
    )
}

private func c09MigrationObservation() -> AgentMigrationWorldObservation {
    let entry = AgentPosition(x: 4, y: 64, z: 3)
    let reception = AgentPosition(x: 0, y: 64, z: 3)
    return AgentMigrationWorldObservation(
        worldTick: 0,
        candidateIndex: 0,
        entryPosition: entry,
        receptionPosition: reception,
        route: [
            entry,
            AgentPosition(x: 3, y: 64, z: 3),
            AgentPosition(x: 2, y: 64, z: 3),
            AgentPosition(x: 1, y: 64, z: 3),
            reception,
        ],
        entryChunkReady: true,
        entrySafe: true,
        entryUnoccupied: true,
        receptionChunkReady: true,
        receptionSafe: true,
        receptionUnoccupied: true
    )
}

func runPebbleAgentsPopulationConfigurationCorrection09Smoke() {
    section("CIV-45 Correction 09 persisted population validation")

    let exactLiveEncoding = "{\"arrivalDistance\":0,\"maximumActivePopulation\":8,\"maximumConcurrentMigrations\":1,\"maximumEntryCandidates\":16,\"maximumMigrationDistance\":24,\"maximumMigrationRecords\":16,\"maximumMigrationReplans\":3,\"maximumMigrationTicks\":64,\"maximumRouteLength\":32}"
    let liveBytes = try! AgentCheckpointCodec.encode(AgentPopulationConfiguration.live)
    check(
        "configuration encoding schema unchanged",
        String(data: liveBytes, encoding: .utf8) == exactLiveEncoding
    )

    let boundary = try! AgentPopulationConfiguration(
        maximumActivePopulation: 512,
        maximumMigrationRecords: 64,
        maximumConcurrentMigrations: 1,
        maximumMigrationDistance: 64,
        maximumEntryCandidates: 16,
        maximumRouteLength: 32,
        maximumMigrationTicks: 256,
        maximumMigrationReplans: 3,
        arrivalDistance: 0
    )
    let minimums = try! AgentPopulationConfiguration(
        maximumActivePopulation: 3,
        maximumMigrationRecords: 1,
        maximumConcurrentMigrations: 1,
        maximumMigrationDistance: 1,
        maximumEntryCandidates: 1,
        maximumRouteLength: 1,
        maximumMigrationTicks: 1,
        maximumMigrationReplans: 0,
        arrivalDistance: 0
    )
    for (name, configuration) in [
        ("live", AgentPopulationConfiguration.live),
        ("minimum", minimums),
        ("hard boundary 512", boundary),
    ] {
        let bytes = try! AgentCheckpointCodec.encode(configuration)
        let decoded = try! AgentCheckpointCodec.decode(
            AgentPopulationConfiguration.self,
            from: bytes
        )
        check("\(name) configuration round-trip equal", decoded == configuration)
        check(
            "\(name) configuration round-trip bytes exact",
            try! AgentCheckpointCodec.encode(decoded) == bytes
        )
    }

    let invalidCases: [(
        name: String,
        keyPath: WritableKeyPath<C09RawPopulationConfiguration, Int>,
        value: Int
    )] = [
        ("active population below", \.maximumActivePopulation, 2),
        ("active population above", \.maximumActivePopulation, 513),
        ("migration records below", \.maximumMigrationRecords, 0),
        ("migration records above", \.maximumMigrationRecords, 65),
        ("concurrency below", \.maximumConcurrentMigrations, 0),
        ("concurrency above", \.maximumConcurrentMigrations, 2),
        ("migration distance below", \.maximumMigrationDistance, 0),
        ("migration distance above", \.maximumMigrationDistance, 65),
        ("entry candidates below", \.maximumEntryCandidates, 0),
        ("entry candidates above", \.maximumEntryCandidates, 17),
        ("route length below", \.maximumRouteLength, 0),
        ("route length above", \.maximumRouteLength, 33),
        ("migration ticks below", \.maximumMigrationTicks, 0),
        ("migration ticks above", \.maximumMigrationTicks, 257),
        ("migration replans below", \.maximumMigrationReplans, -1),
        ("migration replans above", \.maximumMigrationReplans, 4),
        ("arrival distance below", \.arrivalDistance, -1),
        ("arrival distance above", \.arrivalDistance, 1),
    ]
    for invalidCase in invalidCases {
        var raw = C09RawPopulationConfiguration(.live)
        raw[keyPath: invalidCase.keyPath] = invalidCase.value
        let bytes = try! AgentCheckpointCodec.encode(raw)
        let apiAccepted = (try? raw.validated()) != nil
        let decodeAccepted = (try? AgentCheckpointCodec.decode(
            AgentPopulationConfiguration.self,
            from: bytes
        )) != nil
        check(
            "decoded \(invalidCase.name) matches initializer rejection",
            !apiAccepted && decodeAccepted == apiAccepted
        )
    }

    var aboveRaw = C09RawPopulationConfiguration(.live)
    aboveRaw.maximumActivePopulation = 513
    do {
        _ = try AgentCheckpointCodec.decode(
            AgentPopulationConfiguration.self,
            from: AgentCheckpointCodec.encode(aboveRaw)
        )
        check("decode 513 reports deterministic validation error", false)
    } catch DecodingError.dataCorrupted(let context) {
        check(
            "decode 513 reports deterministic validation error",
            context.debugDescription
                == "invalid population configuration: active population"
        )
    } catch {
        check(
            "decode 513 reports deterministic validation error",
            false,
            "unexpected \(error)"
        )
    }

    do {
        let source = try c09Session(
            id: "civ45-c09-checkpoint-513",
            configuration: boundary
        )
        let sourceBytes = try source.durableStateBytes()
        let validCheckpoint = try source.makeCheckpoint()
        let fixture = try c09InvalidCheckpointFixture(
            from: validCheckpoint,
            maximumActivePopulation: 513
        )
        let root = try JSONSerialization.jsonObject(with: fixture.bytes)
            as! [String: Any]
        let durable = root["durableState"] as! [String: Any]
        let population = durable["populationRegistry"] as! [String: Any]
        let rawConfiguration = population["configuration"] as! [String: Any]
        let settlement = population["settlement"] as! [String: Any]
        check(
            "checkpoint 513 outer identity and digest self-consistent",
            root["semanticDigest"] as? String == fixture.durableDigest.rawValue
                && root["checkpointID"] as? String == fixture.checkpointID
        )
        check(
            "checkpoint 513 uses matching settlement capacity",
            rawConfiguration["maximumActivePopulation"] as? Int == 513
                && settlement["capacity"] as? Int == 513
        )
        let validCheckpointBytes = try AgentCheckpointCodec.encode(validCheckpoint)
        let validManifest = try AgentCheckpointManifest(
            name: AgentCheckpointName(rawValue: "c09-checkpoint-513")!,
            checkpoint: validCheckpoint,
            storageDigest: AgentCheckpointDigest.sha256(validCheckpointBytes),
            byteLength: validCheckpointBytes.count,
            restartSafe: true,
            restartSafetyReason: "C09 headless population fixture",
            worldBinding: AgentCheckpointWorldBinding(
                worldID: "c09-world",
                storageIdentity: "c09-storage",
                seed: 46,
                dimension: 0,
                anchor: AgentPosition(x: 0, y: 64, z: 0),
                simulationID: validCheckpoint.simulationID,
                checkpointTick: validCheckpoint.tick,
                cells: []
            ),
            orchestration: AgentCheckpointLiveOrchestration(
                cognitiveHz: 2,
                wasPaused: false,
                movementEnabled: true,
                autoInteractionEnabled: true,
                economyAutoEnabled: false
            )
        )
        var manifestRoot = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(validManifest)
        ) as! [String: Any]
        manifestRoot["checkpointID"] = fixture.checkpointID
        manifestRoot["semanticDigest"] = fixture.durableDigest.rawValue
        manifestRoot["storageDigest"] = AgentCheckpointDigest.sha256(
            fixture.bytes
        ).rawValue
        manifestRoot["byteLength"] = fixture.bytes.count
        let persistedManifest = try AgentCheckpointCodec.decode(
            AgentCheckpointManifest.self,
            from: JSONSerialization.data(
                withJSONObject: manifestRoot,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
        try persistedManifest.validateIntegrityDigest()
        check(
            "checkpoint 513 storage manifest is byte-consistent",
            persistedManifest.checkpointID.rawValue == fixture.checkpointID
                && persistedManifest.semanticDigest == fixture.durableDigest
                && persistedManifest.storageDigest
                    == AgentCheckpointDigest.sha256(fixture.bytes)
                && persistedManifest.byteLength == fixture.bytes.count
        )

        var current = source
        var candidatePublished = false
        var physicalMutationCount = 0
        var rejected = false
        do {
            let decoded = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self,
                from: fixture.bytes
            )
            let candidate = try AgentSimulationSession.restoring(decoded)
            candidatePublished = true
            physicalMutationCount += 1
            current = candidate
        } catch DecodingError.dataCorrupted {
            rejected = true
        }
        check("checkpoint restore 513 rejected", rejected)
        check("checkpoint restore publishes no candidate", !candidatePublished)
        check("checkpoint restore performs zero physical mutation", physicalMutationCount == 0)
        check(
            "checkpoint restore leaves current session byte-exact",
            try current.durableStateBytes() == sourceBytes
        )
        check(
            "checkpoint restore does not clamp or fall back",
            current.durableState().populationRegistry?.configuration == boundary
        )

        let decodedValid = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: AgentCheckpointCodec.encode(validCheckpoint)
        )
        let validReport = try AgentSimulationSession.validate(decodedValid)
        let restoredValid = try AgentSimulationSession.restoring(decodedValid)
        check(
            "checkpoint boundary 512 validates and restores",
            validReport.valid
                && restoredValid.durableState().populationRegistry?
                    .configuration.maximumActivePopulation == 512
        )
        check(
            "earliest population checkpoint schema remains compatible",
            validCheckpoint.schemaVersion == AgentCheckpointSchema.populationVersion
        )
    } catch {
        check("checkpoint 513 rejection proof completes", false, "unexpected \(error)")
    }

    do {
        let replayBase = try c09BaseSession(id: "civ45-c09-replay-513")
        let checkpoint = try replayBase.makeCheckpoint()
        let operation = c09PopulationOperation(configuration: boundary)
        let built = try c09ReplayRecord(session: replayBase, operation: operation)
        let validOperations = try AgentReplayCodec.encodeRecords([built.record])
        let manifest = AgentReplayJournalManifest(
            schemaVersion: AgentReplaySchema.currentVersion,
            name: AgentCheckpointName(rawValue: "c09-valid-512")!,
            baseCheckpointID: checkpoint.checkpointID,
            baseCheckpointDigest: checkpoint.semanticDigest,
            simulationID: checkpoint.simulationID,
            initialTick: checkpoint.tick.rawValue,
            recordCount: 1,
            droppedRecordCount: 0,
            replayable: true,
            nonReplayableReason: nil,
            operationsStorageDigest: AgentCheckpointDigest.sha256(validOperations),
            operationsByteLength: validOperations.count
        )
        let replayed = try AgentSessionReplayer.replay(
            checkpoint: checkpoint,
            journal: AgentReplayJournal(
                manifest: manifest,
                records: [built.record]
            )
        )
        let replayedBytes = try replayed.session.durableStateBytes()
        let expectedReplayBytes = try built.result.durableStateBytes()
        check(
            "replay boundary 512 validates and restores",
            replayed.report.verified
                && replayed.session.durableState().populationRegistry?
                    .configuration.maximumActivePopulation == 512
                && replayedBytes == expectedReplayBytes
        )

        var invalidText = String(data: validOperations, encoding: .utf8)!
        let needle = "\"maximumActivePopulation\":512"
        precondition(invalidText.components(separatedBy: needle).count == 2)
        invalidText = invalidText.replacingOccurrences(
            of: needle,
            with: "\"maximumActivePopulation\":513"
        )
        let invalidOperations = Data(invalidText.utf8)
        let invalidDigest = AgentCheckpointDigest.sha256(invalidOperations)
        let invalidManifest = AgentReplayJournalManifest(
            schemaVersion: AgentReplaySchema.currentVersion,
            name: AgentCheckpointName(rawValue: "c09-invalid-513")!,
            baseCheckpointID: checkpoint.checkpointID,
            baseCheckpointDigest: checkpoint.semanticDigest,
            simulationID: checkpoint.simulationID,
            initialTick: checkpoint.tick.rawValue,
            recordCount: 1,
            droppedRecordCount: 0,
            replayable: true,
            nonReplayableReason: nil,
            operationsStorageDigest: invalidDigest,
            operationsByteLength: invalidOperations.count
        )
        check(
            "replay 513 persisted envelope is self-consistent",
            invalidManifest.operationsStorageDigest
                == AgentCheckpointDigest.sha256(invalidOperations)
                && invalidManifest.operationsByteLength == invalidOperations.count
        )
        check(
            "replay 513 rejected before application",
            (try? AgentReplayCodec.decodeRecords(invalidOperations)) == nil
        )
    } catch {
        check("replay 513 rejection proof completes", false, "unexpected \(error)")
    }

    do {
        var full = try c09Session(
            id: "civ45-c09-admission-boundary",
            configuration: boundary
        )
        let additions = (3..<512).map { ordinal in
            AgentScaledResidentAdmission(
                state: c09Agent("agent_\(ordinal)", ordinal: ordinal),
                settlementID: .main
            )
        }
        try full.initializePopulationScaling(
            additionalSettlements: [AgentPopulationSettlement(
                settlementID: AgentSettlementID(rawValue: "settlement-spare")!,
                anchor: AgentPosition(x: 64, y: 64, z: 64),
                receptionPosition: AgentPosition(x: 64, y: 64, z: 67),
                capacity: 1,
                residentIDs: [],
                inTransitIDs: []
            )],
            additionalResidents: additions,
            configuration: try AgentPopulationScaleConfiguration(
                maximumSettlements: 2,
                maximumLiveAgents: 128,
                maximumNearAgents: 256,
                nearMaintenanceCadence: 4,
                dormantMaintenanceCadence: 16,
                rotationIntervalTicks: 8,
                maximumFidelityTransitionHistory: 1_024,
                maximumSettlementMigrationHistory: 64,
                maximumConcurrentSettlementMigrations: 1,
                maximumSettlementMigrationRouteLength: 32
            )
        )
        let before = try full.durableStateBytes()
        let beforeIDs = full.expectedActiveAgentIDs()
        var refused = false
        do {
            _ = try full.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: c09MigrationObservation()
            )
        } catch AgentSessionError.population(.admission(.populationFull)) {
            refused = true
        }
        let after = try full.durableStateBytes()
        check(
            "hard boundary contains exactly 512 members",
            full.populationSnapshot().members.count == 512
                && beforeIDs.count == 512
        )
        check("normal admission refuses the 513th member", refused)
        check(
            "refused 513th admission creates no identity or mutation",
            full.expectedActiveAgentIDs() == beforeIDs
                && after == before
        )
    } catch {
        check("hard admission boundary proof completes", false, "unexpected \(error)")
    }
}
