import Foundation
@_spi(Testing) import PebbleAgents

private let observationOrigin = AgentPosition(x: 0, y: 64, z: 0)

private func observationAgent(
    _ index: Int,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0, curiosity: 0, safety: 1
        ),
        health: lethalNextTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "ecological observation fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: lethalNextTick ? AgentSurvivalProgress(
            status: .starving,
            consecutiveCriticalHungerTicks: 2
        ) : nil
    )
}

private func observationBase(
    _ id: String,
    receptionPosition: AgentPosition = observationOrigin
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map { observationAgent($0) },
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 8_192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: observationOrigin,
        receptionPosition: receptionPosition
    )
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.populationVersion
    )
    return session
}

private func historicalObservationBase(
    _ id: String,
    lethalAgentIndices: Set<Int>,
    mortalityConfiguration: AgentMortalityConfiguration = .live,
    causalMaximumEvents: Int = 8_192,
    preRegistrationCausalEvents: Int = 0
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map {
            observationAgent(
                $0, lethalNextTick: lethalAgentIndices.contains($0)
            )
        },
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    for index in 0..<preRegistrationCausalEvents {
        session.setEconomyEnabled(index.isMultiple(of: 2))
    }
    try! session.initializePopulationRegistry(
        settlementAnchor: observationOrigin,
        receptionPosition: observationOrigin
    )
    try! session.setEcologicalObservationEnabled(
        true,
        configuration: try! AgentEcologicalObservationConfiguration(
            maximumScansPerSimulationTick: 8,
            maximumRetainedObservations: 16,
            maximumRetainedObservationsPerAgent: 8
        )
    )
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(
        true, configuration: mortalityConfiguration
    )
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
    return session
}

private func ecologicalObservationEnable(
    _ session: inout AgentSimulationSession,
    configuration: AgentEcologicalObservationConfiguration = .live
) throws {
    try session.setEcologicalObservationEnabled(true, configuration: configuration)
    try session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.ecologicalObservationVersion
    )
}

private func ecologicalObservationUseIndependentReceiptSchema(
    _ session: inout AgentSimulationSession
) {
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
}

private func normalizedObservation(
    _ session: AgentSimulationSession,
    observer: String = "agent_0",
    physicalWorldTick: Int = 120,
    cropStage: Int = 3,
    weather: AgentWeatherKind = .clear,
    includePlant: Bool = true,
    cacheHit: Bool = false
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    let date = configuration.calendar.date(atSimulationTick: session.tick)!
    let plant = includePlant ? [AgentPlantObservation(
        plantKey: "oak_sapling", position: AgentPosition(x: -1, y: 64, z: 0),
        renewability: .conditional
    )] : []
    let resultCount = 8 + plant.count
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!, origin: observationOrigin,
        worldContextKey: "world-seed-46", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick,
        physicalWorldTick: physicalWorldTick, civilDate: date,
        biome: AgentBiomeObservation(biomeKey: "plains", position: observationOrigin),
        water: [AgentWaterAffordance(
            fluidKey: "water", position: AgentPosition(x: 2, y: 63, z: 0),
            sourceBlock: true
        )],
        soils: [AgentSoilAffordance(
            blockKey: "dirt", position: AgentPosition(x: 1, y: 63, z: 0),
            tillable: true, alreadyFarmland: false, hydrated: nil,
            supportsCrop: true
        )],
        crops: [AgentCropObservation(
            cropKey: "wheat", position: AgentPosition(x: 1, y: 64, z: 1),
            growthStage: cropStage, maximumGrowthStage: 7,
            mature: cropStage == 7, supportBlockKey: "farmland"
        )],
        plants: plant,
        animals: [AgentAnimalObservation(
            speciesKey: "cow", position: AgentPosition(x: 3, y: 64, z: 0),
            count: 1, lifeStage: .adult, breedableAffordanceObservable: false
        )],
        fishing: [AgentFishingAffordance(
            position: AgentPosition(x: 2, y: 63, z: 0),
            waterKey: "water", candidate: true
        )],
        weather: AgentWeatherObservation(
            kind: weather, raining: weather != .clear,
            thundering: weather == .thunder
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: physicalWorldTick, dayTime: physicalWorldTick % 24_000,
            timeOfDay: .day, daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405,
            worldReads: cacheHit ? 0 : 405, chunksTouched: 1,
            chunksUnavailable: 0, entitiesConsidered: 1,
            resultsEmitted: resultCount, cacheHits: cacheHit ? 1 : 0,
            cacheMisses: cacheHit ? 0 : 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func ecologicalPhysicalReceiptEvidence(
    _ record: AgentEcologicalObservationRecord,
    worldID: String = "world-seed-46",
    storageIdentity: String = "sqlite-world:world-seed-46",
    dimension: Int = 0,
    receiptID: AgentPhysicalObservationReceiptID? = nil,
    observation: AgentEcologicalObservation? = nil,
    receiptDigest: AgentCheckpointDigest? = nil
) -> AgentEcologicalPhysicalReceiptEvidence {
    let observation = observation ?? record.observation
    let receiptID = receiptID ?? record.physicalObservationReceiptID!
    return AgentEcologicalPhysicalReceiptEvidence(
        receiptID: receiptID,
        operationID: receiptID.rawValue,
        observerID: observation.observerID,
        worldID: worldID,
        storageIdentity: storageIdentity,
        dimension: dimension,
        dimensionKey: observation.dimensionKey,
        physicalWorldTick: observation.physicalWorldTick,
        simulationID: record.causalEventID.simulationID,
        simulationTick: observation.observedAtSimulationTick,
        origin: observation.origin,
        observation: observation,
        resultCount: observation.diagnostics.resultsEmitted,
        worldReadCount: observation.diagnostics.worldReads,
        receiptDigest: receiptDigest
    )
}

private func resignedEcologicalObservation(
    _ source: AgentEcologicalObservation,
    observerID: AgentID? = nil,
    observedAtSimulationTick: Int? = nil,
    origin: AgentPosition? = nil,
    worldContextKey: String? = nil,
    dimensionKey: String? = nil,
    physicalWorldTick: Int? = nil,
    biome: AgentBiomeObservation? = nil,
    water: [AgentWaterAffordance]? = nil,
    soils: [AgentSoilAffordance]? = nil,
    crops: [AgentCropObservation]? = nil,
    plants: [AgentPlantObservation]? = nil,
    animals: [AgentAnimalObservation]? = nil,
    weather: AgentWeatherObservation? = nil,
    physicalTime: AgentPhysicalWorldTimeObservation? = nil,
    calendar: AgentCivilCalendarConfiguration = .live
) -> AgentEcologicalObservation {
    let observedTick = observedAtSimulationTick
        ?? source.observedAtSimulationTick
    return AgentEcologicalObservation(
        observerID: observerID ?? source.observerID,
        origin: origin ?? source.origin,
        worldContextKey: worldContextKey ?? source.worldContextKey,
        dimensionKey: dimensionKey ?? source.dimensionKey,
        observedAtSimulationTick: observedTick,
        physicalWorldTick: physicalWorldTick ?? source.physicalWorldTick,
        civilDate: calendar.date(atSimulationTick: observedTick)!,
        biome: biome ?? source.biome,
        water: water ?? source.water,
        soils: soils ?? source.soils,
        crops: crops ?? source.crops,
        plants: plants ?? source.plants,
        animals: animals ?? source.animals,
        fishing: source.fishing,
        weather: weather ?? source.weather,
        physicalTime: physicalTime ?? source.physicalTime,
        diagnostics: source.diagnostics,
        expiresAtSimulationTick: observedTick
            + max(0, source.expiresAtSimulationTick
                - source.observedAtSimulationTick)
    )
}

private func ecologicalReinsertEvictedRecord(
    _ durable: inout [String: Any],
    record: AgentEcologicalObservationRecord,
    replacement: AgentEcologicalObservation? = nil
) {
    var state = durable["ecologicalObservationState"] as! [String: Any]
    var records = state["observations"] as! [[String: Any]]
    var encoded = ecologicalJSONObject(record)
    if let replacement {
        encoded["observation"] = ecologicalJSONObject(replacement)
    }
    records.append(encoded)
    records.sort { ($0["sequence"] as! Int) < ($1["sequence"] as! Int) }
    state["observations"] = records
    var evictions = state["evictionCounts"] as! [String: Any]
    evictions["observations"] = (evictions["observations"] as! Int) - 1
    state["evictionCounts"] = evictions
    durable["ecologicalObservationState"] = state
}

private func ecologicalJSONObject<T: Encodable>(_ value: T) -> [String: Any] {
    try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(value)
    ) as! [String: Any]
}

private func ecologicalEventIDText(_ value: [String: Any]) -> String {
    let simulationID = value["simulationID"] as! String
    let sequence = value["sequence"] as! UInt64
    let digits = String(sequence)
    return "\(simulationID)/event-"
        + String(repeating: "0", count: max(0, 20 - digits.count))
        + digits
}

private func ecologicalCausalDigest(_ text: String) -> String {
    var value: UInt64 = 14_695_981_039_346_656_037
    for byte in text.utf8 {
        value ^= UInt64(byte)
        value &*= 1_099_511_628_211
    }
    let digits = String(value, radix: 16, uppercase: false)
    return String(repeating: "0", count: max(0, 16 - digits.count))
        + digits
}

private func ecologicalRepairEventDigest(_ event: inout [String: Any]) {
    let eventID = ecologicalEventIDText(
        event["eventID"] as! [String: Any]
    )
    let instant = event["instant"] as! [String: Any]
    let causes = (event["causes"] as! [[String: Any]])
        .map(ecologicalEventIDText).joined(separator: ",")
    let payload = event["payload"] as! [String: Any]
    let ecological = payload["ecologicalObservation"] as! [String: Any]
    let payloadText = "ecologicalObservation|"
        + "\(ecological["observerID"] as? String ?? "none")|"
        + "\(ecological["worldContextKey"] as? String ?? "none")|"
        + "\(ecological["dimensionKey"] as? String ?? "none")|"
        + "\(ecological["physicalReceiptID"] as? String ?? "none")|"
        + "\(ecological["resultCount"] as! Int)|"
        + "\(ecological["worldReads"] as! Int)|"
        + "\((ecological["truncated"] as! Bool) ? 1 : 0)|"
        + "\(ecological["status"] as! String)|"
        + "\(ecological["digest"] as! String)"
    let text = "\(eventID)|\(instant["tick"] as! Int)|"
        + "\(event["kind"] as! String)|\(event["origin"] as! String)|"
        + "\(event["actorID"] as? String ?? "-")|"
        + "\(event["subjectID"] as? String ?? "-")|"
        + "\(event["operationID"] as? String ?? "-")|"
        + "\(causes)|\(payloadText)|\(event["summary"] as! String)"
    event["digest"] = ecologicalCausalDigest(text)
}

private func ecologicalRecomputeCausalRollingDigest(
    _ durable: inout [String: Any]
) {
    var ledger = durable["causalLedger"] as! [String: Any]
    let events = ledger["events"] as! [[String: Any]]
    var rolling = ecologicalCausalDigest("")
    for event in events {
        rolling = ecologicalCausalDigest(
            "\(rolling)|\(event["digest"] as! String)"
        )
    }
    ledger["rollingDigest"] = rolling
    durable["causalLedger"] = ledger
}

private func ecologicalMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    schemaVersion: Int? = nil,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    if let schemaVersion { durable["schemaVersion"] = schemaVersion }
    mutate(&durable)
    let mutationBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let state = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(state)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(simulationID.utf8)
    )
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))"
            + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func ecologicalRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    schemaVersion: Int? = nil,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            ecologicalMutatedCheckpoint(
                checkpoint,
                schemaVersion: schemaVersion,
                mutate: mutate
            )
        )
        return false
    } catch {
        return true
    }
}

private func ecologicalReplaceRecordObserver(
    _ durable: inout [String: Any],
    recordIndex: Int,
    observerID: AgentID,
    observedAtSimulationTick: Int? = nil,
    eventMutation: ((inout [String: Any]) -> Void)? = nil
) {
    var state = durable["ecologicalObservationState"] as! [String: Any]
    var records = state["observations"] as! [[String: Any]]
    var record = records[recordIndex]
    let source = try! AgentCheckpointCodec.decode(
        AgentEcologicalObservation.self,
        from: JSONSerialization.data(
            withJSONObject: record["observation"] as! [String: Any],
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
    let replacement = resignedEcologicalObservation(
        source,
        observerID: observerID,
        observedAtSimulationTick: observedAtSimulationTick,
        calendar: state["configuration"].flatMap { value in
            let configuration = try? AgentCheckpointCodec.decode(
                AgentEcologicalObservationConfiguration.self,
                from: try! JSONSerialization.data(
                    withJSONObject: value,
                    options: [.sortedKeys, .withoutEscapingSlashes]
                )
            )
            return configuration?.calendar
        } ?? .live
    )
    record["observation"] = ecologicalJSONObject(replacement)
    records[recordIndex] = record
    state["observations"] = records
    durable["ecologicalObservationState"] = state

    let eventID = ecologicalEventIDText(
        record["causalEventID"] as! [String: Any]
    )
    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let eventIndex = events.firstIndex {
        ecologicalEventIDText($0["eventID"] as! [String: Any]) == eventID
    }!
    events[eventIndex]["actorID"] = observerID.rawValue
    events[eventIndex]["subjectID"] = observerID.rawValue
    if let observedAtSimulationTick {
        var instant = events[eventIndex]["instant"] as! [String: Any]
        instant["tick"] = observedAtSimulationTick
        events[eventIndex]["instant"] = instant
        events[eventIndex]["simulationTick"] = observedAtSimulationTick
    }
    var payload = events[eventIndex]["payload"] as! [String: Any]
    var ecological = payload["ecologicalObservation"] as! [String: Any]
    ecological["observerID"] = observerID.rawValue
    ecological["digest"] = replacement.digest
    payload["ecologicalObservation"] = ecological
    events[eventIndex]["payload"] = payload
    eventMutation?(&events[eventIndex])
    ecologicalRepairEventDigest(&events[eventIndex])
    ledger["events"] = events
    durable["causalLedger"] = ledger
    ecologicalRecomputeCausalRollingDigest(&durable)
}

private func ecologicalReplaceRecordAndEventObservation(
    _ durable: inout [String: Any],
    recordIndex: Int,
    replacement: AgentEcologicalObservation,
    receiptID: AgentPhysicalObservationReceiptID? = nil
) {
    var state = durable["ecologicalObservationState"] as! [String: Any]
    var records = state["observations"] as! [[String: Any]]
    var record = records[recordIndex]
    record["observation"] = ecologicalJSONObject(replacement)
    if let receiptID {
        record["physicalObservationReceiptID"] = receiptID.rawValue
    }
    records[recordIndex] = record
    state["observations"] = records
    durable["ecologicalObservationState"] = state

    let eventID = ecologicalEventIDText(
        record["causalEventID"] as! [String: Any]
    )
    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let eventIndex = events.firstIndex {
        ecologicalEventIDText($0["eventID"] as! [String: Any]) == eventID
    }!
    var instant = events[eventIndex]["instant"] as! [String: Any]
    instant["tick"] = replacement.observedAtSimulationTick
    events[eventIndex]["instant"] = instant
    events[eventIndex]["simulationTick"] = replacement.observedAtSimulationTick
    var payload = events[eventIndex]["payload"] as! [String: Any]
    var ecological = payload["ecologicalObservation"] as! [String: Any]
    ecological["observerID"] = replacement.observerID.rawValue
    ecological["worldContextKey"] = replacement.worldContextKey
    ecological["dimensionKey"] = replacement.dimensionKey
    ecological["physicalReceiptID"] = receiptID?.rawValue
        ?? record["physicalObservationReceiptID"] as! String
    ecological["resultCount"] = replacement.diagnostics.resultsEmitted
    ecological["worldReads"] = replacement.diagnostics.worldReads
    ecological["truncated"] = replacement.diagnostics.completion != .complete
    ecological["digest"] = replacement.digest
    payload["ecologicalObservation"] = ecological
    events[eventIndex]["payload"] = payload
    ecologicalRepairEventDigest(&events[eventIndex])
    ledger["events"] = events
    durable["causalLedger"] = ledger
    ecologicalRecomputeCausalRollingDigest(&durable)
}

private func ecologicalIndependentReceiptValidationRefused(
    checkpoint: AgentSessionCheckpoint,
    evidence: [AgentEcologicalPhysicalReceiptEvidence],
    worldID: String = "world-seed-46",
    storageIdentity: String = "sqlite-world:world-seed-46",
    dimension: Int = 0
) -> Bool {
    do {
        let restored = try AgentSimulationSession.restoring(checkpoint)
        try restored.validateIndependentEcologicalObservationReceipts(
            evidence,
            worldID: worldID,
            storageIdentity: storageIdentity,
            dimension: dimension
        )
        return false
    } catch {
        return true
    }
}

private func currentMembershipAuthorityBase(
    _ id: String,
    causalMaximumEvents: Int = 12,
    lethalAgentZero: Bool = false
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map {
            observationAgent(
                $0,
                lethalNextTick: lethalAgentZero && $0 == 0
            )
        },
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: causalMaximumEvents)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: observationOrigin,
        receptionPosition: observationOrigin
    )
    try! session.setEcologicalObservationEnabled(
        true,
        configuration: try! AgentEcologicalObservationConfiguration(
            maximumScansPerSimulationTick: 16,
            maximumRetainedObservations: 32,
            maximumRetainedObservationsPerAgent: 16
        )
    )
    try! session.rebasePhysiologicalTime(toWorldTick: 0)
    return session
}

@discardableResult
private func applyMembershipAuthorityPressure(
    _ session: inout AgentSimulationSession,
    limit: Int = 128
) -> Int {
    var count = 0
    while session.populationSnapshot().members.count > 0,
          session.populationRegistry?.currentMembershipAuthorityEventID == nil,
          count < limit {
        try! session.appendCausalRetentionTestEvent()
        count += 1
    }
    return count
}

private func currentMembershipAuthorityEvent(
    _ session: AgentSimulationSession
) -> AgentCausalEvent? {
    guard let id = session.populationRegistry?
        .currentMembershipAuthorityEventID else { return nil }
    return session.causalLedgerSnapshot().events.first {
        $0.eventID == id
    }
}

private func currentMembershipAuthorityRows(
    _ session: AgentSimulationSession
) -> [AgentPopulationMembershipAuthorityMember] {
    guard let event = currentMembershipAuthorityEvent(session),
          case let .populationMembershipAuthority(members, _) = event.payload
    else { return [] }
    return members
}

private func ecologicalMembershipAuthorityMembers(
    _ authority: [String: Any]
) -> [AgentPopulationMembershipAuthorityMember] {
    try! AgentCheckpointCodec.decode(
        [AgentPopulationMembershipAuthorityMember].self,
        from: JSONSerialization.data(
            withJSONObject: authority["members"]!,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func ecologicalMembershipAuthorityDigest(
    members: [AgentPopulationMembershipAuthorityMember],
    simulationID: String
) -> String {
    AgentPopulationDigest.make(
        "active-membership|simulation=\(simulationID)|"
            + members.map {
                "\($0.agentID.rawValue)|\($0.ordinal.rawValue)|"
                    + "\($0.founder ? 1 : 0)|\($0.registeredTick)|"
                    + $0.registrationEventID.rawValue
            }.joined(separator: ";")
    )
}

private func ecologicalRepairMembershipAuthorityEventDigest(
    _ event: inout [String: Any],
    resignAuthorityPayload: Bool
) {
    var payload = event["payload"] as! [String: Any]
    var authority = payload["populationMembershipAuthority"]
        as! [String: Any]
    let members = ecologicalMembershipAuthorityMembers(authority)
    let simulationID = event["simulationID"] as! String
    if resignAuthorityPayload {
        authority["digest"] = ecologicalMembershipAuthorityDigest(
            members: members,
            simulationID: simulationID
        )
    }
    payload["populationMembershipAuthority"] = authority
    event["payload"] = payload

    let eventID = ecologicalEventIDText(
        event["eventID"] as! [String: Any]
    )
    let instant = event["instant"] as! [String: Any]
    let causes = (event["causes"] as! [[String: Any]])
        .map(ecologicalEventIDText).joined(separator: ",")
    let authorityDigest = authority["digest"] as! String
    let payloadText = "populationMembershipAuthority|\(members.count)|"
        + "\(authorityDigest)|"
        + members.map {
            "\($0.agentID.rawValue)|\($0.ordinal.rawValue)|"
                + "\($0.founder ? 1 : 0)|\($0.registeredTick)|"
                + $0.registrationEventID.rawValue
        }.joined(separator: ";")
    let text = "\(eventID)|\(instant["tick"] as! Int)|"
        + "\(event["kind"] as! String)|\(event["origin"] as! String)|"
        + "\(event["actorID"] as? String ?? "-")|"
        + "\(event["subjectID"] as? String ?? "-")|"
        + "\(event["operationID"] as? String ?? "-")|"
        + "\(causes)|\(payloadText)|\(event["summary"] as! String)"
    event["digest"] = ecologicalCausalDigest(text)
}

private func ecologicalMutateCurrentMembershipAuthority(
    _ durable: inout [String: Any],
    resignAuthorityPayload: Bool = false,
    mutation: (inout [[String: Any]], [[String: Any]]) -> Void
) {
    let registry = durable["populationRegistry"] as! [String: Any]
    let authorityID = ecologicalEventIDText(
        registry["currentMembershipAuthorityEventID"]
            as! [String: Any]
    )
    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let eventIndex = events.firstIndex {
        ecologicalEventIDText($0["eventID"] as! [String: Any])
            == authorityID
    }!
    var payload = events[eventIndex]["payload"] as! [String: Any]
    var authority = payload["populationMembershipAuthority"]
        as! [String: Any]
    var members = authority["members"] as! [[String: Any]]
    mutation(&members, events)
    authority["members"] = members
    payload["populationMembershipAuthority"] = authority
    events[eventIndex]["payload"] = payload
    ecologicalRepairMembershipAuthorityEventDigest(
        &events[eventIndex],
        resignAuthorityPayload: resignAuthorityPayload
    )
    ledger["events"] = events
    durable["causalLedger"] = ledger
    ecologicalRecomputeCausalRollingDigest(&durable)
}

private func membershipAuthorityReplayBase(
    _ id: String
) -> AgentSimulationSession {
    var session = currentMembershipAuthorityBase(
        id
    )
    for index in 0..<3 {
        _ = try! session.recordEcologicalObservation(
            normalizedObservation(
                session,
                observer: "agent_\(index)",
                physicalWorldTick: 100 + index
            ),
            physicalReceiptID: AgentPhysicalObservationReceiptID(
                rawValue: "eco-membership-before-\(index)"
            )!
        )
    }
    return session
}

@inline(never)
private func runCurrentMembershipAuthorityRestoreValidationSmoke() {
    var direct = membershipAuthorityReplayBase(
        "ecological-membership-authority-restore-validation"
    )
    _ = applyMembershipAuthorityPressure(&direct)
    let checkpoint = try! direct.makeCheckpoint()
    let positiveRestored = try! AgentSimulationSession.restoring(checkpoint)
    check(
        "post-rollover pre-observation membership authority restores",
        direct.populationRegistry?.currentMembershipAuthorityEventID != nil
            && (try! positiveRestored.durableStateBytes())
                == (try! direct.durableStateBytes())
    )

    let continuation = normalizedObservation(
        direct,
        observer: "agent_0",
        physicalWorldTick: 199
    )
    let continuationReceipt = AgentPhysicalObservationReceiptID(
        rawValue: "eco-membership-pre-observation-restore"
    )!
    var restored = positiveRestored
    _ = try! direct.recordEcologicalObservation(
        continuation,
        physicalReceiptID: continuationReceipt
    )
    _ = try! restored.recordEcologicalObservation(
        continuation,
        physicalReceiptID: continuationReceipt
    )
    check(
        "post-rollover restore continuation publishes ecology byte exactly",
        (try! restored.durableStateBytes())
            == (try! direct.durableStateBytes())
    )

    check("missing current membership authority event is refused on restore", {
        ecologicalRestoreRefused(checkpoint) { durable in
            var registry = durable["populationRegistry"] as! [String: Any]
            let ledger = durable["causalLedger"] as! [String: Any]
            registry["currentMembershipAuthorityEventID"] = [
                "simulationID": (durable["clock"] as! [String: Any])[
                    "simulationID"
                ] as! String,
                "sequence": (ledger["latestSequence"] as! UInt64) + 1,
            ]
            durable["populationRegistry"] = registry
        }
    }())
    check("wrong retained current membership authority event is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            var registry = durable["populationRegistry"] as! [String: Any]
            let ledger = durable["causalLedger"] as! [String: Any]
            let events = ledger["events"] as! [[String: Any]]
            registry["currentMembershipAuthorityEventID"] = events.first {
                ($0["kind"] as! String)
                    != "populationMembershipAuthorityRetained"
            }!["eventID"]
            durable["populationRegistry"] = registry
        }
    }())
    check("membership authority missing-member payload is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            ecologicalMutateCurrentMembershipAuthority(&durable) {
                members, _ in members.removeLast()
            }
        }
    }())
    check("membership authority extra-member payload is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            ecologicalMutateCurrentMembershipAuthority(&durable) {
                members, _ in
                var extra = members.last!
                extra["agentID"] = "agent_extra"
                extra["ordinal"] = 999
                extra["founder"] = false
                members.append(extra)
            }
        }
    }())
    check("membership authority wrong original registration is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            ecologicalMutateCurrentMembershipAuthority(&durable) {
                members, events in
                members[0]["registrationEventID"] = events.first {
                    ($0["kind"] as! String)
                        != "populationMembershipAuthorityRetained"
                }!["eventID"]
            }
        }
    }())
    check("coherently re-signed forged membership authority is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            ecologicalMutateCurrentMembershipAuthority(
                &durable,
                resignAuthorityPayload: true
            ) { members, events in
                members[0]["registrationEventID"] = events.first {
                    ($0["kind"] as! String)
                        != "populationMembershipAuthorityRetained"
                }!["eventID"]
            }
        }
    }())
    check("nil membership authority after registration compaction is refused", {
        ecologicalRestoreRefused(checkpoint) { durable in
            var registry = durable["populationRegistry"] as! [String: Any]
            registry.removeValue(
                forKey: "currentMembershipAuthorityEventID"
            )
            durable["populationRegistry"] = registry
        }
    }())
}

@inline(never)
private func runCurrentMembershipAuthorityActiveAndCheckpointSmoke() {
    var session = membershipAuthorityReplayBase(
        "ecological-membership-authority-active"
    )
    let originalRegistrations = session.populationSnapshot().members.map(
        \.registrationEventID
    )
    let beforeEvictionCheckpoint = try! session.makeCheckpoint()
    let pressureCount = applyMembershipAuthorityPressure(&session)
    let authorityID = session.populationRegistry?
        .currentMembershipAuthorityEventID
    let retainedIDs = Set(session.causalLedgerSnapshot().events.map(\.eventID))
    let rows = currentMembershipAuthorityRows(session)
    check(
        "current membership authority replaces compacted founder registration",
        pressureCount < 128
            && authorityID != nil
            && retainedIDs.contains(authorityID!)
            && !retainedIDs.contains(originalRegistrations[0])
            && rows.map(\.agentID.rawValue) == [
                "agent_0", "agent_1", "agent_2",
            ]
            && session.causalLedgerSnapshot().events.count <= 12,
        "pressure=\(pressureCount) retained=\(retainedIDs.count) "
            + "authority=\(authorityID?.rawValue ?? "none")"
    )
    for index in 0..<3 {
        _ = try! session.recordEcologicalObservation(
            normalizedObservation(
                session,
                observer: "agent_\(index)",
                physicalWorldTick: 200 + index,
                cropStage: 7
            ),
            physicalReceiptID: AgentPhysicalObservationReceiptID(
                rawValue: "eco-membership-after-\(index)"
            )!
        )
    }
    let activeValidations = try! session
        .historicalEcologicalObservationValidations()
    check(
        "multiple active observers remain causally valid after registration compaction",
        activeValidations.count == session.ecologicalObservationSnapshot()
            .observations.count
            && activeValidations.suffix(3).allSatisfy {
                $0.classification == .activeAtObservation
            }
    )

    let authorityCheckpoint = try! session.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(
        authorityCheckpoint
    )
    let directReceipt = AgentPhysicalObservationReceiptID(
        rawValue: "eco-membership-checkpoint-continuation"
    )!
    let continuation = normalizedObservation(
        session,
        observer: "agent_0",
        physicalWorldTick: 300
    )
    _ = try! session.recordEcologicalObservation(
        continuation,
        physicalReceiptID: directReceipt
    )
    _ = try! restored.recordEcologicalObservation(
        continuation,
        physicalReceiptID: directReceipt
    )
    check(
        "membership authority checkpoint continuation is byte exact",
        beforeEvictionCheckpoint.schemaVersion
            == AgentCheckpointSchema.pathReadinessLivenessVersion
            && authorityCheckpoint.schemaVersion
                == AgentCheckpointSchema.pathReadinessLivenessVersion
            && (try! session.durableStateBytes())
                == (try! restored.durableStateBytes())
    )
}

@inline(never)
private func runCurrentMembershipAuthorityReplaySmoke() {
    let beforeEvictionCheckpoint = try! membershipAuthorityReplayBase(
        "ecological-membership-authority-replay"
    ).makeCheckpoint()
    var replayed = try! AgentSimulationSession.restoring(
        beforeEvictionCheckpoint
    )
    var recorder = try! AgentReplayRecorder(
        checkpoint: beforeEvictionCheckpoint,
        session: replayed
    )
    var replayPressure = 0
    while replayed.populationRegistry?
            .currentMembershipAuthorityEventID == nil,
          replayPressure < 128 {
        _ = try! recorder.apply(
            .setEconomyEnabled(replayPressure.isMultiple(of: 2)),
            to: &replayed
        )
        replayPressure += 1
    }
    for index in 0..<3 {
        let observation = normalizedObservation(
            replayed,
            observer: "agent_\(index)",
            physicalWorldTick: 400 + index
        )
        _ = try! recorder.apply(
            .recordEcologicalObservationWithPhysicalReceipt(
                observation,
                physicalReceiptID: AgentPhysicalObservationReceiptID(
                    rawValue: "eco-membership-replay-\(index)"
                )!
            ),
            to: &replayed
        )
    }
    let journal = try! recorder.journal(
        named: AgentCheckpointName(
            rawValue: "ecological-membership-authority-replay"
        )!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: beforeEvictionCheckpoint,
        journal: journal
    )
    check(
        "membership authority transition replays byte exactly",
        replay.report.verified
            && (try! replay.session.durableStateBytes())
                == (try! replayed.durableStateBytes())
            && replay.session.populationRegistry?
                .currentMembershipAuthorityEventID
                == replayed.populationRegistry?
                    .currentMembershipAuthorityEventID
    )
}

@inline(never)
private func runCurrentMembershipAuthorityDynamicSmoke() {
    var dynamic = currentMembershipAuthorityBase(
        "ecological-membership-authority-dynamic",
        causalMaximumEvents: 16
    )
    _ = applyMembershipAuthorityPressure(&dynamic)
    let authorityBeforeMigration = dynamic.populationRegistry?
        .currentMembershipAuthorityEventID
    let entry = AgentPosition(x: 0, y: 64, z: -2)
    let mid = AgentPosition(x: 0, y: 64, z: -1)
    let migration = try! dynamic.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: entry,
            receptionPosition: observationOrigin,
            route: [entry, mid, observationOrigin],
            entryChunkReady: true,
            entrySafe: true,
            entryUnoccupied: true,
            receptionChunkReady: true,
            receptionSafe: true,
            receptionUnoccupied: true
        )
    )
    var dynamicPressure = 0
    while dynamic.causalLedgerSnapshot().events.contains(where: {
        $0.eventID == dynamic.populationSnapshot().members.first(where: {
            $0.agentID == migration.migrantID
        })!.registrationEventID
    }), dynamicPressure < 128 {
        try! dynamic.appendCausalRetentionTestEvent()
        dynamicPressure += 1
    }
    _ = try! dynamic.recordEcologicalObservation(
        normalizedObservation(
            dynamic,
            observer: migration.migrantID.rawValue,
            physicalWorldTick: 500
        ),
        physicalReceiptID: AgentPhysicalObservationReceiptID(
            rawValue: "eco-membership-dynamic"
        )!
    )
    check(
        "dynamic member is covered after its original registration compacts",
        dynamicPressure < 128
            && dynamic.populationRegistry?
                .currentMembershipAuthorityEventID
                != authorityBeforeMigration
            && currentMembershipAuthorityRows(dynamic).contains {
                $0.agentID == migration.migrantID
            }
            && (try! dynamic.historicalEcologicalObservationValidations())
                .last?.observerID == migration.migrantID
    )
}

@inline(never)
private func runCurrentMembershipAuthorityDynamicMortalitySmoke() {
    let acceleratedSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 1,
        fatiguePerTick: 0.06,
        hungryThreshold: 0.40,
        criticalHungerThreshold: 0.80,
        hungerRecoveryThreshold: 0.15,
        fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.20,
        foodNutrition: 1,
        restRecoveryPerTick: 1,
        starvationGraceTicks: 1,
        starvationDamagePerTick: 100
    )
    var dynamic = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: acceleratedSurvival
        ),
        agents: (0..<3).map { observationAgent($0) },
        simulationID: AgentSimulationID(
            rawValue: "ecological-membership-dynamic-mortality"
        )!,
        causalLedgerPolicy: .bounded(maxEvents: 512)
    )
    try! dynamic.initializePopulationRegistry(
        settlementAnchor: observationOrigin,
        receptionPosition: observationOrigin
    )
    try! dynamic.setEcologicalObservationEnabled(
        true,
        configuration: try! AgentEcologicalObservationConfiguration(
            maximumScansPerSimulationTick: 16,
            maximumRetainedObservations: 32,
            maximumRetainedObservationsPerAgent: 16
        )
    )
    try! dynamic.rebasePhysiologicalTime(toWorldTick: 0)
    dynamic.setSurvivalEnabled(true)
    try! dynamic.setMortalityEnabled(true)
    _ = applyMembershipAuthorityPressure(&dynamic)

    let entry = AgentPosition(x: 0, y: 64, z: -2)
    let mid = AgentPosition(x: 0, y: 64, z: -1)
    let migration = try! dynamic.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: entry,
            receptionPosition: observationOrigin,
            route: [entry, mid, observationOrigin]
        )
    )
    let migrantRegistration = dynamic.populationSnapshot().members.first {
        $0.agentID == migration.migrantID
    }!.registrationEventID
    var registrationPressure = 0
    while dynamic.causalLedgerSnapshot().events.contains(where: {
        $0.eventID == migrantRegistration
    }), registrationPressure < 2_048 {
        try! dynamic.appendCausalRetentionTestEvent()
        registrationPressure += 1
    }
    let priorEcologicalAuthority = dynamic.ecologicalObservationState?
        .initializedEventID
    var ecologicalPressure = 0
    while dynamic.ecologicalObservationState?.initializedEventID
            == priorEcologicalAuthority,
          ecologicalPressure < 2_048 {
        try! dynamic.appendCausalRetentionTestEvent()
        ecologicalPressure += 1
    }
    let observation = try! dynamic.recordEcologicalObservation(
        normalizedObservation(
            dynamic,
            observer: migration.migrantID.rawValue,
            physicalWorldTick: 700
        ),
        physicalReceiptID: AgentPhysicalObservationReceiptID(
            rawValue: "eco-membership-dynamic-before-death"
        )!
    )
    try! dynamic.advancePhysiologicalTime(toWorldTick: 1_200)
    _ = try! dynamic.advanceTick()
    try! dynamic.advancePhysiologicalTime(toWorldTick: 2_400)
    _ = try! dynamic.advanceTick()
    let death = dynamic.mortalitySnapshot().records.first {
        $0.agentID == migration.migrantID
    }
    let validation = try! dynamic.historicalEcologicalObservationValidations()
        .first { $0.sequence == observation.sequence }
    check(
        "dynamic member mortality retains pre-death ecology after registration compaction",
        registrationPressure < 2_048
            && ecologicalPressure < 2_048
            && !dynamic.causalLedgerSnapshot().events.contains {
                $0.eventID == migrantRegistration
            }
            && death?.membershipAuthorityEventID != nil
            && validation?.classification == .deceasedAfterObservationRetained
            && dynamic.populationRegistry?
                .currentMembershipAuthorityEventID == nil
            && dynamic.snapshot().agents.isEmpty
            && dynamic.mortalitySnapshot().records.count == 4,
        "registrationPressure=\(registrationPressure) "
            + "ecologicalPressure=\(ecologicalPressure) "
            + "death=\(death != nil) validation="
            + "\(String(describing: validation?.classification))"
    )
    var historicalPressure = 0
    while dynamic.ecologicalObservationSnapshot().observations.contains(
        where: { $0.sequence == observation.sequence }
    ), historicalPressure < 2_048 {
        try! dynamic.appendCausalRetentionTestEvent()
        historicalPressure += 1
    }
    check(
        "dynamic deceased ecology is later evicted within the bounded ledger",
        historicalPressure < 2_048
            && !dynamic.ecologicalObservationSnapshot().observations.contains(
                where: { $0.sequence == observation.sequence }
            )
            && dynamic.causalLedgerSnapshot().events.count <= 512,
        "pressure=\(historicalPressure) retained="
            + "\(dynamic.causalLedgerSnapshot().events.count)"
    )
}

@inline(never)
private func runCurrentMembershipAuthorityFaultSmoke() {
    var faultBase = currentMembershipAuthorityBase(
        "ecological-membership-authority-fault",
        causalMaximumEvents: 12
    )
    _ = try! faultBase.recordEcologicalObservation(
        normalizedObservation(faultBase, observer: "agent_0"),
        physicalReceiptID: AgentPhysicalObservationReceiptID(
            rawValue: "eco-membership-fault"
        )!
    )
    var faultPressure = 0
    while faultBase.populationRegistry?
            .currentMembershipAuthorityEventID == nil,
          faultBase.causalLedgerSnapshot().events.first?.kind
            != .populationMemberRegistered,
          faultPressure < 128 {
        try! faultBase.appendCausalRetentionTestEvent()
        faultPressure += 1
    }
    let membershipFaults: [AgentCausalRetentionFaultPoint] = [
        .afterFirstEcologicalRowEviction,
        .afterEcologicalEvictionCounterUpdate,
        .beforePopulationMembershipAuthorityPublication,
        .afterPopulationMembershipAuthorityCausalAppend,
        .afterCausalCompaction,
        .afterPopulationMembershipAuthorityPublication,
        .afterEcologicalValidation,
    ]
    let faultsRollback = faultPressure < 128
        && membershipFaults.allSatisfy { fault in
            var candidate = faultBase
            let before = try! candidate.durableStateBytes()
            do {
                try candidate.appendCausalRetentionTestEvent(
                    failingAt: fault
                )
                return false
            } catch AgentSessionError.ecologicalObservation(
                .invalidState("injected causal retention fault \(fault.rawValue)")
            ) {
                return (try! candidate.durableStateBytes()) == before
            } catch {
                return false
            }
        }
    check(
        "membership authority retention faults roll back byte exactly",
        faultsRollback,
        "ready=\(faultPressure < 128) pressure=\(faultPressure)"
    )
}

private struct MembershipAuthorityMortalityFixture {
    var session: AgentSimulationSession
    let observationSequence: UInt64
    let ecologicalAuthorityPressure: Int
}

@inline(never)
private func membershipAuthorityMortalityFixture(
    _ simulationID: String
) -> MembershipAuthorityMortalityFixture {
    var session = currentMembershipAuthorityBase(
        simulationID,
        causalMaximumEvents: 32,
        lethalAgentZero: true
    )
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(true)
    _ = applyMembershipAuthorityPressure(&session)
    let initialEcologicalAuthority = session.ecologicalObservationState?
        .initializedEventID
    var ecologicalAuthorityPressure = 0
    while session.ecologicalObservationState?.initializedEventID
            == initialEcologicalAuthority,
          ecologicalAuthorityPressure < 128 {
        try! session.appendCausalRetentionTestEvent()
        ecologicalAuthorityPressure += 1
    }
    let observation = try! session.recordEcologicalObservation(
        normalizedObservation(
            session,
            observer: "agent_0",
            physicalWorldTick: 600
        ),
        physicalReceiptID: AgentPhysicalObservationReceiptID(
            rawValue: "eco-membership-before-death"
        )!
    )
    _ = try! session.recordEcologicalObservation(
        normalizedObservation(
            session,
            observer: "agent_1",
            physicalWorldTick: 601
        ),
        physicalReceiptID: AgentPhysicalObservationReceiptID(
            rawValue: "eco-membership-survivor-before-death"
        )!
    )
    return MembershipAuthorityMortalityFixture(
        session: session,
        observationSequence: observation.sequence,
        ecologicalAuthorityPressure: ecologicalAuthorityPressure
    )
}

@inline(never)
private func runCurrentMembershipAuthorityMortalityFaultSmoke() {
    let faults: [AgentCausalRetentionFaultPoint] = [
        .afterMortalityStateBeforeMembershipAuthorityRefresh,
        .beforePopulationMembershipAuthorityPublication,
        .afterPopulationMembershipAuthorityCausalAppend,
        .afterMembershipEcologicalDependencyCalculation,
        .afterFirstEcologicalRowEviction,
        .afterEcologicalEvictionCounterUpdate,
        .afterCausalCompaction,
        .afterPopulationMembershipAuthorityPublication,
        .afterMortalityMembershipValidationBeforePublication,
    ]
    let rollbackExact = faults.allSatisfy { fault in
        var fixture = membershipAuthorityMortalityFixture(
            "ecological-membership-mortality-fault-\(fault.rawValue)"
        )
        try! fixture.session.advancePhysiologicalTime(toWorldTick: 1_200)
        let before = try! fixture.session.durableStateBytes()
        do {
            _ = try fixture.session.advanceTick(
                failingCausalRetentionAt: fault
            )
            return false
        } catch AgentSessionError.ecologicalObservation(
            .invalidState("injected causal retention fault \(fault.rawValue)")
        ) {
            return (try! fixture.session.durableStateBytes()) == before
        } catch {
            return false
        }
    }
    check(
        "mortality membership transition fault seams roll back byte exactly",
        rollbackExact,
        "faults=\(faults.map(\.rawValue))"
    )
}

@inline(never)
private func runCurrentMembershipAuthorityMortalityTransitionSmoke() {
    var fixture = membershipAuthorityMortalityFixture(
        "ecological-membership-authority-mortality"
    )
    try! fixture.session.advancePhysiologicalTime(toWorldTick: 1_200)
    _ = try! fixture.session.advanceTick()
    let death = fixture.session.mortalitySnapshot().records.first {
        $0.agentID.rawValue == "agent_0"
    }
    let deathValidation = try! fixture.session
        .historicalEcologicalObservationValidations().first {
            $0.sequence == fixture.observationSequence
        }
    let survivorAuthorityRows = currentMembershipAuthorityRows(fixture.session)
    let afterDeathCheckpoint = try! fixture.session.makeCheckpoint()
    let restoredAfterDeath = try! AgentSimulationSession.restoring(
        afterDeathCheckpoint
    )
    let retainedMembershipAuthorityCount = fixture.session
        .causalLedgerSnapshot().events.filter {
            $0.kind == .populationMembershipAuthorityRetained
        }.count
    check(
        "mortality preserves compacted membership authority without resurrection",
        fixture.ecologicalAuthorityPressure < 128
            && death != nil
            && death?.membershipAuthorityEventID != nil
            && deathValidation?.classification
                == .deceasedAfterObservationRetained
            && survivorAuthorityRows.map(\.agentID.rawValue) == [
                "agent_1", "agent_2",
            ]
            && !fixture.session.snapshot().agents.contains {
                $0.id == "agent_0"
            }
            && !fixture.session.populationSnapshot().members.contains {
                $0.agentID.rawValue == "agent_0"
            }
            && (try! restoredAfterDeath.durableStateBytes())
                == (try! fixture.session.durableStateBytes()),
        "death=\(death != nil) validation="
            + "\(String(describing: deathValidation?.classification)) "
            + "rows=\(survivorAuthorityRows.map(\.agentID.rawValue))"
    )
    check(
        "small-ledger membership authority refresh remains bounded count=\(retainedMembershipAuthorityCount)",
        retainedMembershipAuthorityCount >= 1
            && retainedMembershipAuthorityCount <= 3
            && fixture.session.causalLedgerSnapshot().events.count <= 32
    )
}

@inline(never)
private func runCurrentMembershipAuthorityMortalityReplaySmoke() {
    var fixture = membershipAuthorityMortalityFixture(
        "ecological-membership-mortality-replay"
    )
    let beforeDeathCheckpoint = try! fixture.session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: beforeDeathCheckpoint,
        session: fixture.session
    )
    _ = try! recorder.apply(
        .advanceTick(
            physiologicalWorldTick: 1_200,
            perceptions: [],
            physicalObservations: []
        ),
        to: &fixture.session
    )
    let deathValidation = try! fixture.session
        .historicalEcologicalObservationValidations().first {
            $0.sequence == fixture.observationSequence
        }
    var laterPressure = 0
    while fixture.session.ecologicalObservationSnapshot().observations.contains(
        where: { $0.sequence == fixture.observationSequence }
    ), laterPressure < 128 {
        _ = try! recorder.apply(
            .setEconomyEnabled(laterPressure.isMultiple(of: 2)),
            to: &fixture.session
        )
        laterPressure += 1
    }
    let journal = try! recorder.journal(
        named: AgentCheckpointName(
            rawValue: "ecological-membership-mortality-replay"
        )!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: beforeDeathCheckpoint,
        journal: journal
    )
    let afterEvictionCheckpoint = try! fixture.session.makeCheckpoint()
    let restoredAfterEviction = try! AgentSimulationSession.restoring(
        afterEvictionCheckpoint
    )
    check(
        "deceased ecological history evicts before its captured authority leaves",
        deathValidation?.classification == .deceasedAfterObservationRetained
            && laterPressure < 128
            && !fixture.session.ecologicalObservationSnapshot().observations.contains(
                where: { $0.sequence == fixture.observationSequence }
            )
            && fixture.session.causalLedgerSnapshot().events.count <= 32
            && replay.report.verified
            && (try! replay.session.durableStateBytes())
                == (try! fixture.session.durableStateBytes())
            && (try! restoredAfterEviction.durableStateBytes())
                == (try! fixture.session.durableStateBytes()),
        "pressure=\(laterPressure) retained="
            + "\(fixture.session.causalLedgerSnapshot().events.count)"
    )
}

@inline(never)
private func runCurrentMembershipAuthorityRetentionSmoke() {
    runCurrentMembershipAuthorityRestoreValidationSmoke()
    runCurrentMembershipAuthorityActiveAndCheckpointSmoke()
    runCurrentMembershipAuthorityReplaySmoke()
    runCurrentMembershipAuthorityDynamicSmoke()
    runCurrentMembershipAuthorityDynamicMortalitySmoke()
    runCurrentMembershipAuthorityFaultSmoke()
    runCurrentMembershipAuthorityMortalityFaultSmoke()
    runCurrentMembershipAuthorityMortalityTransitionSmoke()
    runCurrentMembershipAuthorityMortalityReplaySmoke()
}

func runPebbleAgentsEcologicalObservationSmoke() {
    section("pebble agents ecological observation and civil calendar")

    runCurrentMembershipAuthorityRetentionSmoke()

    let calendar = AgentCivilCalendarConfiguration.live
    check("civil calendar default day", calendar.date(atSimulationTick: 0)
        == AgentCivilDate(
            day: 1, season: .spring, year: 1, dayOfYear: 1,
            absoluteDay: 0, simulationTick: 0
        ))
    check("civil calendar day boundary",
          calendar.date(atSimulationTick: 23)?.day == 1
            && calendar.date(atSimulationTick: 24)?.day == 2)
    check("civil calendar season boundary",
          calendar.date(atSimulationTick: 24 * 30 - 1)?.season == .spring
            && calendar.date(atSimulationTick: 24 * 30)?.season == .summer)
    check("civil calendar year boundary",
          calendar.date(atSimulationTick: 24 * 120)?.year == 2
            && calendar.date(atSimulationTick: 24 * 120)?.season == .spring)
    check("civil calendar large tick is deterministic without overflow", {
        let first = calendar.date(atSimulationTick: Int.max)
        let second = calendar.date(atSimulationTick: Int.max)
        return first != nil && first == second
            && first?.simulationTick == Int.max
            && first?.year ?? 0 > 1
    }())
    check("civil calendar is render cadence independent", {
        let sparseRenderSamples = [0, 1_440, 2_880]
        let denseRenderSamples = Array(stride(from: 0, through: 2_880, by: 12))
        return calendar.date(atSimulationTick: sparseRenderSamples.last!)
            == calendar.date(atSimulationTick: denseRenderSamples.last!)
    }())
    check("physical World time cannot alter civil date", {
        var value = observationBase("calendar-clock-separation")
        try! ecologicalObservationEnable(&value)
        let first = normalizedObservation(value, physicalWorldTick: 100)
        let second = normalizedObservation(value, physicalWorldTick: 23_900)
        return first.civilDate == second.civilDate
            && first.physicalTime != second.physicalTime
    }())

    check("activation requires population and is atomic", {
        var value = try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 46, memoryPolicy: .bounded(maxEntries: 128)
            ),
            agents: [observationAgent(0)],
            simulationID: AgentSimulationID(rawValue: "observation-no-population")!,
            causalLedgerPolicy: .bounded(maxEvents: 128)
        )
        let before = try! value.durableStateBytes()
        do {
            try value.setEcologicalObservationEnabled(true)
            return false
        } catch AgentSessionError.ecologicalObservation(.populationRequired) {
            return !value.ecologicalObservationEnabled
                && (try! value.durableStateBytes()) == before
        } catch { return false }
    }())

    var session = observationBase("ecological-observation-contract")
    let materialBefore = (0..<3).map {
        try! session.state(for: AgentID(rawValue: "agent_\($0)")!).resourceInventory
    }
    let campBefore = session.campStock
    let causalBefore = session.causalLedgerSnapshot().summary.latestSequence
    try! ecologicalObservationEnable(&session)
    check("activation is v12 and creates no retroactive observation",
          session.durableState().schemaVersion == 12
            && session.ecologicalObservationSnapshot().observations.isEmpty
            && session.causalLedgerSnapshot().summary.latestSequence == causalBefore + 1)

    let first = normalizedObservation(session)
    let firstSequence = session.causalLedgerSnapshot().summary.latestSequence
    let record = try! session.recordEcologicalObservation(first)
    ecologicalObservationUseIndependentReceiptSchema(&session)
    check("one aggregate observation emits one causal event",
          record.sequence == 1
            && session.causalLedgerSnapshot().summary.latestSequence == firstSequence + 1)
    check("observation is observer-local",
          session.ecologicalObservations(for: AgentID(rawValue: "agent_0")!).count == 1
            && session.ecologicalObservations(for: AgentID(rawValue: "agent_1")!).isEmpty)
    check("normalized affordance queries read latest fresh observation",
          session.nearestObservedWater(for: AgentID(rawValue: "agent_0")!).first?.fluidKey == "water"
            && session.observedTillableSoils(for: AgentID(rawValue: "agent_0")!).count == 1
            && session.observedCrops(for: AgentID(rawValue: "agent_0")!).first?.growthStage == 3
            && session.observedAnimals(for: AgentID(rawValue: "agent_0")!).first?.speciesKey == "cow"
            && session.observedFishingCandidates(for: AgentID(rawValue: "agent_0")!).count == 1)
    check("normalized observation does not mutate coarse materials",
          materialBefore == (0..<3).map {
              try! session.state(for: AgentID(rawValue: "agent_\($0)")!).resourceInventory
          } && campBefore == session.campStock
            && session.localEcologySnapshot().enabled == false)

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("ecological observation schema 30 checkpoint is byte exact",
          checkpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes())
            && restored.ecologicalObservationSnapshot() == session.ecologicalObservationSnapshot())
    let independentReceipt = ecologicalPhysicalReceiptEvidence(record)
    check("exact independent World-side receipt validates schema 30", {
        do {
            try restored.validateIndependentEcologicalObservationReceipts(
                [independentReceipt],
                worldID: "world-seed-46",
                storageIdentity: "sqlite-world:world-seed-46",
                dimension: 0
            )
            return true
        } catch {
            return false
        }
    }())
    let changedWorldTick = first.physicalWorldTick + 77
    let coherentPhysicalChange = resignedEcologicalObservation(
        first,
        origin: AgentPosition(x: 9, y: 70, z: 9),
        physicalWorldTick: changedWorldTick,
        biome: AgentBiomeObservation(
            biomeKey: "desert",
            position: AgentPosition(x: 9, y: 70, z: 9)
        ),
        soils: [AgentSoilAffordance(
            blockKey: "sand",
            position: AgentPosition(x: 10, y: 69, z: 9),
            tillable: false,
            alreadyFarmland: false,
            hydrated: false,
            supportsCrop: false
        )],
        crops: [AgentCropObservation(
            cropKey: "carrots",
            position: AgentPosition(x: 10, y: 70, z: 10),
            growthStage: 5,
            maximumGrowthStage: 7,
            mature: false,
            supportBlockKey: "farmland"
        )],
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: changedWorldTick,
            dayTime: changedWorldTick % 24_000,
            timeOfDay: .day,
            daylightCycleEnabled: true
        )
    )
    let coherentPhysicalCheckpoint = ecologicalMutatedCheckpoint(
        checkpoint
    ) { durable in
        ecologicalReplaceRecordAndEventObservation(
            &durable,
            recordIndex: 0,
            replacement: coherentPhysicalChange
        )
    }
    check("coherent row and event mutation remains internally consistent", {
        (try? AgentSimulationSession.restoring(coherentPhysicalCheckpoint))
            != nil
    }())
    check("independent World-side receipt rejects coherent physical change",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: coherentPhysicalCheckpoint,
            evidence: [independentReceipt]
          ))
    let coherentContextChange = resignedEcologicalObservation(
        first,
        worldContextKey: "other-world-context",
        dimensionKey: "the_nether"
    )
    let coherentContextCheckpoint = ecologicalMutatedCheckpoint(
        checkpoint
    ) { durable in
        ecologicalReplaceRecordAndEventObservation(
            &durable,
            recordIndex: 0,
            replacement: coherentContextChange
        )
    }
    check("independent World-side receipt rejects coherent context change",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: coherentContextCheckpoint,
            evidence: [independentReceipt]
          ))
    let replacementReceiptID = AgentPhysicalObservationReceiptID(
        rawValue: "eco-other-valid-receipt"
    )!
    let receiptSubstitutionCheckpoint = ecologicalMutatedCheckpoint(
        checkpoint
    ) { durable in
        ecologicalReplaceRecordAndEventObservation(
            &durable,
            recordIndex: 0,
            replacement: first,
            receiptID: replacementReceiptID
        )
    }
    check("independent World-side receipt rejects receipt substitution",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: receiptSubstitutionCheckpoint,
            evidence: [independentReceipt]
          ))
    check("missing independent World-side receipt is refused",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: checkpoint,
            evidence: []
          ))
    check("duplicate independent World-side receipt is refused",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: checkpoint,
            evidence: [independentReceipt, independentReceipt]
          ))
    let wrongWorldReceipt = ecologicalPhysicalReceiptEvidence(
        record,
        worldID: "other-world",
        storageIdentity: "sqlite-world:other-world"
    )
    check("independent receipt from another World is refused",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: checkpoint,
            evidence: [wrongWorldReceipt]
          ))
    let invalidReceiptDigest = ecologicalPhysicalReceiptEvidence(
        record,
        receiptDigest: AgentCheckpointDigest.sha256(Data("changed".utf8))
    )
    check("invalid independent receipt digest is refused",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: checkpoint,
            evidence: [invalidReceiptDigest]
          ))
    check("schema 29 retained observation without independent proof is refused",
          ecologicalRestoreRefused(
            checkpoint,
            schemaVersion: AgentCheckpointSchema.renewableSubsistenceVersion
          ) { _ in })

    var replayed = observationBase("ecological-observation-replay")
    let replayBase = try! replayed.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replayed)
    _ = try! recorder.apply(
        .setEcologicalObservationEnabled(true, configuration: .live), to: &replayed
    )
    _ = try! recorder.apply(
        .recordEcologicalObservation(normalizedObservation(replayed)), to: &replayed
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "ecological-observation-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("ecological observation replay from v2 base is byte exact",
          replay.report.verified && replay.report.schemaVersion == 12
            && replayBase.schemaVersion == 2
            && (try! replay.session.durableStateBytes()) == (try! replayed.durableStateBytes()))

    for _ in 0...AgentEcologicalObservationConfiguration.live.dynamicFreshnessTicks {
        _ = try! session.advanceTick()
    }
    check("expired dynamic observation cannot drive fresh queries",
          session.ecologicalObservations(for: AgentID(rawValue: "agent_0")!).isEmpty
            && session.ecologicalObservationSnapshot().staleCount == 1
            && session.nearestObservedWater(for: AgentID(rawValue: "agent_0")!).isEmpty)

    let boundedConfiguration = try! AgentEcologicalObservationConfiguration(
        maximumScansPerSimulationTick: 8,
        maximumRetainedObservations: 2,
        maximumRetainedObservationsPerAgent: 1
    )
    var bounded = observationBase("ecological-observation-bounded")
    try! ecologicalObservationEnable(&bounded, configuration: boundedConfiguration)
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_0"))
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_1"))
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_0", cropStage: 7))
    check("retention is globally and per-agent bounded deterministically",
          bounded.ecologicalObservationSnapshot().observations.count == 2
            && bounded.ecologicalObservationSnapshot().evictionCounts.observations == 1
            && bounded.ecologicalObservations(for: AgentID(rawValue: "agent_0")!).first?
                .observation.crops.first?.growthStage == 7)

    var selectivePressure = historicalObservationBase(
        "ecological-observation-selective-causal-pressure",
        lethalAgentIndices: [],
        causalMaximumEvents: 32,
        preRegistrationCausalEvents: 20
    )
    let selectiveFirst = try! selectivePressure.recordEcologicalObservation(
        normalizedObservation(selectivePressure, observer: "agent_0")
    )
    let selectiveSecond = try! selectivePressure.recordEcologicalObservation(
        normalizedObservation(
            selectivePressure, observer: "agent_0", cropStage: 7
        )
    )
    let selectiveUnaffected = try! selectivePressure
        .recordEcologicalObservation(
            normalizedObservation(
                selectivePressure, observer: "agent_1", physicalWorldTick: 121
            )
        )
    let selectiveTotal = selectivePressure.ecologicalObservationSnapshot()
        .totalObservationCount
    var selectiveToggle = true
    while selectivePressure.ecologicalObservationSnapshot().observations
            .contains(where: { $0.sequence == selectiveFirst.sequence }) {
        selectivePressure.setNaturalResourcesEnabled(selectiveToggle)
        selectiveToggle.toggle()
    }
    let selectiveAfter = selectivePressure.ecologicalObservationSnapshot()
    check("causal pressure evicts only rows whose exact authority leaves",
          !selectiveAfter.observations.contains(where: {
              $0.sequence == selectiveFirst.sequence
                  || $0.sequence == selectiveSecond.sequence
          })
            && selectiveAfter.observations.contains(where: {
                $0 == selectiveUnaffected
            })
            && selectiveAfter.totalObservationCount == selectiveTotal
            && selectiveAfter.evictionCounts.observations == 2,
          "retained=\(selectiveAfter.observations.map { $0.sequence }) "
            + "evicted=\(selectiveAfter.evictionCounts.observations)")

    var causalFaultBase = historicalObservationBase(
        "ecological-observation-causal-fault-rollback",
        lethalAgentIndices: [],
        causalMaximumEvents: 16
    )
    let causalFaultRecord = try! causalFaultBase.recordEcologicalObservation(
        normalizedObservation(causalFaultBase, observer: "agent_0")
    )
    let causalFaultEvent = causalFaultBase.causalLedgerSnapshot().events
        .first { $0.eventID == causalFaultRecord.causalEventID }!
    let causalFaultRegistration = causalFaultBase.populationSnapshot().members
        .first { $0.agentID.rawValue == "agent_0" }!.registrationEventID
    let causalFaultRequired = Set(
        [causalFaultRecord.causalEventID, causalFaultRegistration]
            + causalFaultEvent.causes
    )
    var causalFaultPressure = 0
    while causalFaultPressure < 64,
          let first = causalFaultBase.causalLedgerSnapshot().events.first,
          !causalFaultRequired.contains(first.eventID) {
        try! causalFaultBase.appendCausalRetentionTestEvent()
        causalFaultPressure += 1
    }
    let causalFaultReady = causalFaultBase
        .ecologicalObservationSnapshot().observations.contains {
            $0.sequence == causalFaultRecord.sequence
        }
        && causalFaultBase.causalLedgerSnapshot().events.first.map {
            causalFaultRequired.contains($0.eventID)
        } == true
    let historicalEcologicalFaults = AgentCausalRetentionFaultPoint.allCases
        .filter {
            ![
                .afterMortalityStateBeforeMembershipAuthorityRefresh,
                .afterMortalityMembershipValidationBeforePublication,
                .beforePopulationMembershipAuthorityPublication,
                .afterPopulationMembershipAuthorityCausalAppend,
                .afterPopulationMembershipAuthorityPublication,
                .afterMembershipEcologicalDependencyCalculation,
            ].contains($0)
        }
    let causalFaultRollback = causalFaultReady
        && historicalEcologicalFaults.allSatisfy { fault in
            var candidate = causalFaultBase
            let before = try! candidate.durableStateBytes()
            do {
                try candidate.appendCausalRetentionTestEvent(failingAt: fault)
                return false
            } catch AgentSessionError.ecologicalObservation(
                .invalidState("injected causal retention fault \(fault.rawValue)")
            ) {
                return (try! candidate.durableStateBytes()) == before
            } catch {
                return false
            }
        }
    check("causal retention injected failures roll back byte exactly",
          causalFaultRollback,
          "ready=\(causalFaultReady) pressure=\(causalFaultPressure)")

    var deceasedObserver = historicalObservationBase(
        "ecological-observation-deceased-retained",
        lethalAgentIndices: [0]
    )
    let deceasedRecord = try! deceasedObserver.recordEcologicalObservation(
        normalizedObservation(deceasedObserver, observer: "agent_0")
    )
    let observationBeforeDeath = deceasedObserver
        .ecologicalObservationSnapshot().observations
    _ = try! deceasedObserver.advanceTick()
    let retainedDeath = deceasedObserver.mortalitySnapshot().records.first {
        $0.agentID.rawValue == "agent_0"
    }
    let deceasedClassifications = try! deceasedObserver
        .historicalEcologicalObservationValidations()
    check("dead observer retained death authority preserves observation",
          retainedDeath != nil
            && retainedDeath!.registrationEventID.sequence
                < deceasedRecord.causalEventID.sequence
            && deceasedRecord.causalEventID.sequence
                < retainedDeath!.deathEventID.sequence
            && deceasedRecord.observation.observedAtSimulationTick
                <= retainedDeath!.deathTick
            && deceasedObserver.ecologicalObservationSnapshot().observations
                == observationBeforeDeath
            && deceasedClassifications == [
                AgentHistoricalEcologicalObservationValidation(
                    sequence: deceasedRecord.sequence,
                    observerID: deceasedRecord.observation.observerID,
                    classification: .deceasedAfterObservationRetained
                ),
            ])
    check("dead observer personal observation grants no active affordance",
          deceasedObserver.ecologicalObservations(
              for: AgentID(rawValue: "agent_0")!, freshOnly: false
          ).isEmpty
            && deceasedObserver.nearestObservedWater(
                for: AgentID(rawValue: "agent_0")!
            ).isEmpty)
    let deceasedCheckpoint = try! deceasedObserver.makeCheckpoint()
    let deceasedReceipt = ecologicalPhysicalReceiptEvidence(deceasedRecord)
    check("deceased historical observer retains exact independent receipt", {
        do {
            let restored = try AgentSimulationSession.restoring(
                deceasedCheckpoint
            )
            try restored.validateIndependentEcologicalObservationReceipts(
                [deceasedReceipt],
                worldID: "world-seed-46",
                storageIdentity: "sqlite-world:world-seed-46",
                dimension: 0
            )
            return true
        } catch {
            return false
        }
    }())
    let deceasedRestored = try! AgentSimulationSession.restoring(
        deceasedCheckpoint
    )
    check("dead observer checkpoint restart is byte exact",
          (try! deceasedRestored.durableStateBytes())
            == (try! deceasedObserver.durableStateBytes())
            && deceasedRestored.ecologicalObservationSnapshot()
                == deceasedObserver.ecologicalObservationSnapshot()
            && deceasedRestored.mortalitySnapshot()
                == deceasedObserver.mortalitySnapshot())
    let resignedDeceasedCheckpoint = ecologicalMutatedCheckpoint(
        deceasedCheckpoint
    ) { _ in }
    check("checkpoint accepts exact retained-death observer evidence", {
        guard let restored = try? AgentSimulationSession.restoring(
            resignedDeceasedCheckpoint
        ) else { return false }
        return restored.ecologicalObservationSnapshot()
            == deceasedObserver.ecologicalObservationSnapshot()
    }())

    var deceasedAgriculturalObserver = historicalObservationBase(
        "ecological-observation-deceased-agriculture",
        lethalAgentIndices: [0]
    )
    try! deceasedAgriculturalObserver.setLifecycleEnabled(true)
    try! deceasedAgriculturalObserver.setSkillsEnabled(true)
    try! deceasedAgriculturalObserver.setAgricultureEnabled(true)
    let agriculturalObservation = try! deceasedAgriculturalObserver
        .recordEcologicalObservation(
            normalizedObservation(
                deceasedAgriculturalObserver, observer: "agent_0"
            )
        )
    _ = try! deceasedAgriculturalObserver.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: [AgentPosition(x: 1, y: 63, z: 0)],
        sourceObservationEventID: agriculturalObservation.causalEventID,
        designatedStorageLocationID: "container:4,64,0"
    )
    _ = try! deceasedAgriculturalObserver.advanceTick()
    let historicalAgricultureCheckpoint = try! deceasedAgriculturalObserver
        .makeCheckpoint()
    let historicalAgricultureRestore = try! AgentSimulationSession.restoring(
        historicalAgricultureCheckpoint
    )
    check("dead ecological observer remains an exact historical plot planner",
          historicalAgricultureRestore.agricultureSnapshot()
            == deceasedAgriculturalObserver.agricultureSnapshot()
            && historicalAgricultureRestore.mortalitySnapshot().records
                .contains(where: { $0.agentID.rawValue == "agent_0" })
            && historicalAgricultureRestore.ecologicalObservationSnapshot()
                == deceasedAgriculturalObserver.ecologicalObservationSnapshot())
    let sameTickCheckpoint = ecologicalMutatedCheckpoint(
        deceasedCheckpoint
    ) { durable in
        ecologicalReplaceRecordObserver(
            &durable,
            recordIndex: 0,
            observerID: AgentID(rawValue: "agent_0")!,
            observedAtSimulationTick: retainedDeath!.deathTick
        )
    }
    check("same-tick observation before death event is valid", {
        guard let restored = try? AgentSimulationSession.restoring(
            sameTickCheckpoint
        ), let validation = try? restored
            .historicalEcologicalObservationValidations().first else {
            return false
        }
        return validation.classification
            == .deceasedAfterObservationRetained
    }())
    check("unknown historical observer is rejected after full resign",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_99")!
              )
          })
    check("causal actor mutation is rejected after full re-signing",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_0")!
              ) { event in
                  event["actorID"] = "agent_1"
              }
          })
    check("causal subject mutation is rejected after full re-signing",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_0")!
              ) { event in
                  event["subjectID"] = "agent_1"
              }
          })
    check("causal origin mutation is rejected after full re-signing",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_0")!
              ) { event in
                  event["origin"] = "mortalityTransition"
              }
          })
    check("causal payload digest mutation is rejected after full re-signing",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_0")!
              ) { event in
                  var payload = event["payload"] as! [String: Any]
                  var ecological = payload["ecologicalObservation"]
                      as! [String: Any]
                  ecological["digest"] = "0000000000000000"
                  payload["ecologicalObservation"] = ecological
                  event["payload"] = payload
              }
          })
    check("active observer replacement without matching causal actor is rejected",
          ecologicalRestoreRefused(
              deceasedCheckpoint
          ) { durable in
              var state = durable["ecologicalObservationState"]
                  as! [String: Any]
              var records = state["observations"] as! [[String: Any]]
              var record = records[0]
              let source = try! AgentCheckpointCodec.decode(
                  AgentEcologicalObservation.self,
                  from: JSONSerialization.data(
                      withJSONObject: record["observation"]
                          as! [String: Any],
                      options: [.sortedKeys, .withoutEscapingSlashes]
                  )
              )
              record["observation"] = ecologicalJSONObject(
                  resignedEcologicalObservation(
                      source,
                      observerID: AgentID(rawValue: "agent_1")!
                  )
              )
              records[0] = record
              state["observations"] = records
              durable["ecologicalObservationState"] = state
          })
    check("wrong registration authority is rejected after full resign",
          ecologicalRestoreRefused(deceasedCheckpoint) { durable in
              var mortality = durable["mortalityState"] as! [String: Any]
              var records = mortality["records"] as! [[String: Any]]
              let ecological = durable["ecologicalObservationState"]
                  as! [String: Any]
              records[0]["registrationEventID"] =
                  ecological["initializedEventID"]
              mortality["records"] = records
              durable["mortalityState"] = mortality
          })
    check("wrong death authority is rejected after full resign",
          ecologicalRestoreRefused(deceasedCheckpoint) { durable in
              var mortality = durable["mortalityState"] as! [String: Any]
              var records = mortality["records"] as! [[String: Any]]
              let ledger = durable["causalLedger"] as! [String: Any]
              let events = ledger["events"] as! [[String: Any]]
              let wrong = events.last!
              records[0]["deathEventID"] = wrong["eventID"]
              mortality["records"] = records
              durable["mortalityState"] = mortality
          })
    check("wrong causal tick is rejected after full resign",
          ecologicalRestoreRefused(deceasedCheckpoint) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: AgentID(rawValue: "agent_0")!
              ) { event in
                  var instant = event["instant"] as! [String: Any]
                  instant["tick"] = retainedDeath!.deathTick
                  event["instant"] = instant
                  event["simulationTick"] = retainedDeath!.deathTick
              }
          })

    var registeredLater = observationBase(
        "ecological-observation-registered-later",
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! ecologicalObservationEnable(&registeredLater)
    _ = try! registeredLater.recordEcologicalObservation(
        normalizedObservation(registeredLater, observer: "agent_0")
    )
    ecologicalObservationUseIndependentReceiptSchema(&registeredLater)
    let migrationRoute = [
        AgentPosition(x: 4, y: 64, z: 3),
        AgentPosition(x: 3, y: 64, z: 3),
        AgentPosition(x: 2, y: 64, z: 3),
        AgentPosition(x: 1, y: 64, z: 3),
        AgentPosition(x: 0, y: 64, z: 3),
    ]
    let laterMigrant = try! registeredLater.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: registeredLater.tick,
            candidateIndex: 0,
            entryPosition: migrationRoute[0],
            receptionPosition: migrationRoute.last!,
            route: migrationRoute
        )
    )
    let registeredLaterCheckpoint = try! registeredLater.makeCheckpoint()
    check("observer registered after observation is rejected after full resign",
          ecologicalRestoreRefused(
              registeredLaterCheckpoint
          ) { durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: laterMigrant.migrantID
              )
          })

    let birthHabitat = AgentEcologyHabitatObservation(
        worldTick: 0,
        candidateIndex: 0,
        habitatPosition: AgentPosition(x: 3, y: 63, z: 0),
        foragePosition: AgentPosition(x: 3, y: 64, z: 0),
        habitatFingerprint: 528,
        distanceFromSettlement: 3,
        directionIndex: 0,
        worldReadCount: 4
    )
    var childRegisteredLater = observationBase(
        "ecological-observation-child-registered-later"
    )
    try! ecologicalObservationEnable(&childRegisteredLater)
    _ = try! childRegisteredLater.recordEcologicalObservation(
        normalizedObservation(childRegisteredLater, observer: "agent_0")
    )
    ecologicalObservationUseIndependentReceiptSchema(&childRegisteredLater)
    try! childRegisteredLater.initializeLocalEcology(
        observations: [birthHabitat]
    )
    _ = try! childRegisteredLater.applyLocalEcologyEndOfTick(
        habitatValidations: [birthHabitat]
    )
    try! childRegisteredLater.setLifecycleEnabled(true)
    try! childRegisteredLater.setReproductionEnabled(true)
    while childRegisteredLater.tick < 4 {
        _ = try! childRegisteredLater.advanceTick()
    }
    let laterBirthPlan = childRegisteredLater.pendingBirthSitePlan()!
    let laterBirth = try! childRegisteredLater.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: laterBirthPlan.planID,
            observedTick: childRegisteredLater.tick,
            position: AgentPosition(x: 0, y: 64, z: 4),
            candidateIndex: 0,
            worldFingerprint: 9_001
        )
    )!
    let childRegisteredLaterCheckpoint = try! childRegisteredLater
        .makeCheckpoint()
    check("child born after observation cannot be rewritten as observer",
          ecologicalRestoreRefused(childRegisteredLaterCheckpoint) {
              durable in
              ecologicalReplaceRecordObserver(
                  &durable,
                  recordIndex: 0,
                  observerID: laterBirth.newbornID
              )
          })

    var postDeathObservation = historicalObservationBase(
        "ecological-observation-after-death-order",
        lethalAgentIndices: [0]
    )
    let beforeDeathRecord = try! postDeathObservation
        .recordEcologicalObservation(
            normalizedObservation(postDeathObservation, observer: "agent_0")
        )
    _ = try! postDeathObservation.advanceTick()
    let afterDeathRecord = try! postDeathObservation
        .recordEcologicalObservation(
            normalizedObservation(
                postDeathObservation,
                observer: "agent_1",
                physicalWorldTick: 121
            )
        )
    let postDeathCheckpoint = try! postDeathObservation.makeCheckpoint()
    check("observation causally after death is rejected after full resign",
          ecologicalRestoreRefused(postDeathCheckpoint) { durable in
              var state = durable["ecologicalObservationState"]
                  as! [String: Any]
              var records = state["observations"] as! [[String: Any]]
              var first = records[0]
              let source = try! AgentCheckpointCodec.decode(
                  AgentEcologicalObservation.self,
                  from: JSONSerialization.data(
                      withJSONObject: first["observation"]
                          as! [String: Any],
                      options: [.sortedKeys, .withoutEscapingSlashes]
                  )
              )
              let replacement = resignedEcologicalObservation(
                  source,
                  observerID: AgentID(rawValue: "agent_0")!,
                  observedAtSimulationTick: postDeathObservation.tick
              )
              first["observation"] = ecologicalJSONObject(replacement)
              first["causalEventID"] = ecologicalJSONObject(
                  afterDeathRecord.causalEventID
              )
              records = [first]
              state["observations"] = records
              var evictions = state["evictionCounts"] as! [String: Any]
              evictions["observations"] =
                  (evictions["observations"] as! Int) + 1
              state["evictionCounts"] = evictions
              durable["ecologicalObservationState"] = state

              var ledger = durable["causalLedger"] as! [String: Any]
              var events = ledger["events"] as! [[String: Any]]
              let index = events.firstIndex {
                  ecologicalEventIDText(
                      $0["eventID"] as! [String: Any]
                  ) == afterDeathRecord.causalEventID.rawValue
              }!
              events[index]["actorID"] = "agent_0"
              events[index]["subjectID"] = "agent_0"
              var payload = events[index]["payload"] as! [String: Any]
              var ecological = payload["ecologicalObservation"]
                  as! [String: Any]
              ecological["observerID"] = "agent_0"
              ecological["digest"] = replacement.digest
              payload["ecologicalObservation"] = ecological
              events[index]["payload"] = payload
              ecologicalRepairEventDigest(&events[index])
              ledger["events"] = events
              durable["causalLedger"] = ledger
              ecologicalRecomputeCausalRollingDigest(&durable)
          })
    check("post-death adversarial fixture has strict event ordering",
          beforeDeathRecord.causalEventID.sequence
            < postDeathObservation.mortalitySnapshot().records[0]
                .deathEventID.sequence
            && postDeathObservation.mortalitySnapshot().records[0]
                .deathEventID.sequence
                < afterDeathRecord.causalEventID.sequence)

    let compactingMortality = try! AgentMortalityConfiguration(
        maximumRetainedDeathRecords: 1,
        maximumCompactedDeathSummaries: 8,
        maximumExitFrames: 8
    )
    var compactedObservers = historicalObservationBase(
        "ecological-observation-coordinated-compaction",
        lethalAgentIndices: [0, 1],
        mortalityConfiguration: compactingMortality
    )
    try! compactedObservers.recordEcologicalObservation(
        normalizedObservation(compactedObservers, observer: "agent_0")
    )
    try! compactedObservers.recordEcologicalObservation(
        normalizedObservation(
            compactedObservers, observer: "agent_0", cropStage: 7
        )
    )
    try! compactedObservers.recordEcologicalObservation(
        normalizedObservation(compactedObservers, observer: "agent_1")
    )
    try! compactedObservers.recordEcologicalObservation(
        normalizedObservation(compactedObservers, observer: "agent_2")
    )
    let compactedRecordsBeforeDeath = compactedObservers
        .ecologicalObservationSnapshot().observations
    _ = try! compactedObservers.advanceTick()
    let compactedEcology = compactedObservers
        .ecologicalObservationSnapshot()
    let compactedMortality = compactedObservers.mortalitySnapshot()
    check("mortality compaction evicts only dependent observation rows",
          compactedMortality.records.map(\.agentID.rawValue) == ["agent_1"]
            && compactedMortality.compactedDeathSummaries?.map(
                \.agentID.rawValue
            ) == ["agent_0"]
            && compactedMortality.evictionCounts.deathRecords == 1
            && compactedEcology.observations.map {
                $0.observation.observerID.rawValue
            } == ["agent_1", "agent_2"]
            && compactedEcology.evictionCounts.observations == 2
            && compactedEcology.totalObservationCount == 4)
    check("coordinated compaction checkpoint restart remains exact", {
        do {
            let checkpoint = try compactedObservers.makeCheckpoint()
            let restored = try AgentSimulationSession.restoring(checkpoint)
            return try restored.durableStateBytes()
                == compactedObservers.durableStateBytes()
        } catch {
            print("    coordinated compaction diagnostic: \(error)")
            return false
        }
    }())
    let compactedCheckpoint = try! compactedObservers.makeCheckpoint()
    let compactedAgentZeroRecord = compactedRecordsBeforeDeath.first!
    check("checkpoint rejects observation backed only by compacted death summary",
          ecologicalRestoreRefused(
              compactedCheckpoint
          ) { durable in
              var state = durable["ecologicalObservationState"]
                  as! [String: Any]
              var records = state["observations"] as! [[String: Any]]
              records.insert(
                  ecologicalJSONObject(compactedAgentZeroRecord), at: 0
              )
              state["observations"] = records
              var evictions = state["evictionCounts"] as! [String: Any]
              evictions["observations"] =
                  (evictions["observations"] as! Int) - 1
              state["evictionCounts"] = evictions
              durable["ecologicalObservationState"] = state
          })

    let overflowMortality = try! AgentMortalityConfiguration(
        maximumRetainedDeathRecords: 1,
        maximumCompactedDeathSummaries: 1,
        maximumExitFrames: 8
    )
    var proofCapacity = historicalObservationBase(
        "ecological-observation-compaction-capacity",
        lethalAgentIndices: [0, 1, 2],
        mortalityConfiguration: overflowMortality
    )
    try! proofCapacity.recordEcologicalObservation(
        normalizedObservation(proofCapacity, observer: "agent_0")
    )
    let beforeCapacityRefusal = try! proofCapacity.durableStateBytes()
    let capacityRefused: Bool
    do {
        _ = try proofCapacity.advanceTick()
        capacityRefused = false
    } catch AgentSessionError.mortality(
        .invalidState("compacted death evidence capacity")
    ) {
        capacityRefused = true
    } catch {
        capacityRefused = false
    }
    check("historical evidence capacity refusal loses no observation",
          capacityRefused
            && (try! proofCapacity.durableStateBytes())
                == beforeCapacityRefusal
            && proofCapacity.ecologicalObservationSnapshot()
                .observations.count == 1
            && proofCapacity.ecologicalObservationSnapshot()
                .evictionCounts.observations == 0
            && proofCapacity.mortalitySnapshot().records.isEmpty)

    var evictedCausal = historicalObservationBase(
        "ecological-observation-honest-causal-eviction",
        lethalAgentIndices: [0],
        causalMaximumEvents: 16
    )
    let evictedCausalRecord = try! evictedCausal
        .recordEcologicalObservation(
            normalizedObservation(evictedCausal, observer: "agent_0")
        )
    let causalPressureTotal = evictedCausal
        .ecologicalObservationSnapshot().totalObservationCount
    let causalPressureEvictions = evictedCausal
        .ecologicalObservationSnapshot().evictionCounts.observations
    _ = try! evictedCausal.advanceTick()
    var droppedAuthority = historicalObservationBase(
        "ecological-observation-dropped-authority",
        lethalAgentIndices: [0],
        causalMaximumEvents: 32,
        preRegistrationCausalEvents: 20
    )
    let droppedAuthorityRecord = try! droppedAuthority
        .recordEcologicalObservation(
            normalizedObservation(droppedAuthority, observer: "agent_0")
        )
    _ = try! droppedAuthority.advanceTick()
    while droppedAuthority.causalLedgerSnapshot().summary.droppedEventCount == 0 {
        _ = try! droppedAuthority.advanceTick()
    }
    let authorityPrefix = droppedAuthority
        .causalLedgerSnapshot().summary.droppedEventCount
    let authorityCheckpoint = try! droppedAuthority.makeCheckpoint()
    let authorityReceipt = ecologicalPhysicalReceiptEvidence(
        droppedAuthorityRecord
    )
    let droppedCoherentChange = resignedEcologicalObservation(
        droppedAuthorityRecord.observation,
        biome: AgentBiomeObservation(
            biomeKey: "taiga",
            position: droppedAuthorityRecord.observation.origin
        ),
        soils: [AgentSoilAffordance(
            blockKey: "podzol",
            position: AgentPosition(x: 1, y: 63, z: 0),
            tillable: true,
            alreadyFarmland: false,
            hydrated: nil,
            supportsCrop: true
        )]
    )
    let droppedCoherentCheckpoint = ecologicalMutatedCheckpoint(
        authorityCheckpoint
    ) { durable in
        ecologicalReplaceRecordAndEventObservation(
            &durable,
            recordIndex: 0,
            replacement: droppedCoherentChange
        )
    }
    check("coherent mutation with dropped causal prefix is internally consistent", {
        (try? AgentSimulationSession.restoring(droppedCoherentCheckpoint))
            != nil
    }())
    check("independent receipt rejects coherent mutation with dropped prefix",
          ecologicalIndependentReceiptValidationRefused(
            checkpoint: droppedCoherentCheckpoint,
            evidence: [authorityReceipt]
          ))
    let arbitraryDroppedEvent = ecologicalJSONObject(
        AgentCausalEventID(
            simulationID: droppedAuthority.simulationID,
            sequence: AgentCausalSequence(rawValue: max(1, authorityPrefix))!
        )
    )
    check("dropped causal prefix exists while death-backed row remains",
          authorityPrefix > 0
            && droppedAuthority.ecologicalObservationSnapshot()
                .observations.contains(where: {
                    $0.sequence == droppedAuthorityRecord.sequence
                }))
    check("dropped-prefix registration ID is not historical authority",
          ecologicalRestoreRefused(authorityCheckpoint) { durable in
              var mortality = durable["mortalityState"] as! [String: Any]
              var records = mortality["records"] as! [[String: Any]]
              records[0]["registrationEventID"] = arbitraryDroppedEvent
              mortality["records"] = records
              durable["mortalityState"] = mortality
          })
    check("dropped-prefix death ID is not historical authority",
          ecologicalRestoreRefused(authorityCheckpoint) { durable in
              var mortality = durable["mortalityState"] as! [String: Any]
              var records = mortality["records"] as! [[String: Any]]
              records[0]["deathEventID"] = arbitraryDroppedEvent
              mortality["records"] = records
              durable["mortalityState"] = mortality
          })
    while evictedCausal.ecologicalObservationSnapshot().observations
            .contains(where: { $0.sequence == evictedCausalRecord.sequence }) {
        _ = try! evictedCausal.advanceTick()
    }
    while evictedCausal.causalLedgerSnapshot().summary.droppedEventCount
            < evictedCausalRecord.causalEventID.sequence.rawValue {
        _ = try! evictedCausal.advanceTick()
    }
    let evictedCausalCheckpoint = try! evictedCausal.makeCheckpoint()
    check("causal pressure evicts dependent ecological row before event",
          !evictedCausal.causalLedgerSnapshot().events.contains(where: {
                $0.eventID == evictedCausalRecord.causalEventID
            })
            && evictedCausal.ecologicalObservationSnapshot()
                .totalObservationCount == causalPressureTotal
            && evictedCausal.ecologicalObservationSnapshot()
                .evictionCounts.observations == causalPressureEvictions + 1
            && evictedCausal.ecologicalObservationSnapshot()
                .observations.isEmpty)
    check("causal-pressure checkpoint restart remains exact", {
        guard let restored = try? AgentSimulationSession.restoring(
            evictedCausalCheckpoint
        ) else { return false }
        return (try? restored.durableStateBytes())
            == (try? evictedCausal.durableStateBytes())
    }())
    check("missing ecological event cannot be repaired by reintroducing row",
          ecologicalRestoreRefused(evictedCausalCheckpoint) { durable in
              ecologicalReinsertEvictedRecord(
                  &durable, record: evictedCausalRecord
              )
          })
    let evictedSource = evictedCausalRecord.observation
    let physicalCorruption = resignedEcologicalObservation(
        evictedSource,
        origin: AgentPosition(x: 9, y: 70, z: 9),
        physicalWorldTick: evictedSource.physicalWorldTick + 77,
        biome: AgentBiomeObservation(
            biomeKey: "desert", position: AgentPosition(x: 9, y: 70, z: 9)
        ),
        water: [],
        soils: [],
        crops: [],
        plants: [],
        animals: [],
        weather: AgentWeatherObservation(
            kind: .rain, raining: true, thundering: false
        )
    )
    check("fully re-signed physical mutation after event eviction is rejected",
          ecologicalRestoreRefused(evictedCausalCheckpoint) { durable in
              ecologicalReinsertEvictedRecord(
                  &durable,
                  record: evictedCausalRecord,
                  replacement: physicalCorruption
              )
          })
    let contextCorruption = resignedEcologicalObservation(
        evictedSource,
        worldContextKey: "other-world-context",
        dimensionKey: "the_nether"
    )
    check("fully re-signed context mutation after event eviction is rejected",
          ecologicalRestoreRefused(evictedCausalCheckpoint) { durable in
              ecologicalReinsertEvictedRecord(
                  &durable,
                  record: evictedCausalRecord,
                  replacement: contextCorruption
              )
          })
    let tickCorruption = resignedEcologicalObservation(
        evictedSource,
        observedAtSimulationTick: evictedCausal
            .mortalitySnapshot().records[0].deathTick
    )
    check("fully re-signed tick mutation after event eviction is rejected",
          ecologicalRestoreRefused(evictedCausalCheckpoint) { durable in
              ecologicalReinsertEvictedRecord(
                  &durable,
                  record: evictedCausalRecord,
                  replacement: tickCorruption
              )
          })
    let observerCorruption = resignedEcologicalObservation(
        evictedSource,
        observerID: AgentID(rawValue: "agent_1")!
    )
    check("fully re-signed observer mutation after event eviction is rejected",
          ecologicalRestoreRefused(evictedCausalCheckpoint) { durable in
              ecologicalReinsertEvictedRecord(
                  &durable,
                  record: evictedCausalRecord,
                  replacement: observerCorruption
              )
          })

    check("historical validation and read-only projection mutate nothing", {
        let before = try! deceasedObserver.durableStateBytes()
        _ = deceasedObserver.ecologicalObservationSnapshot()
        _ = try! deceasedObserver
            .historicalEcologicalObservationValidations()
        let after = try! deceasedObserver.durableStateBytes()
        return before == after
    }())
    check("repeated historical observer restart is byte exact", {
        guard let first = try? AgentSimulationSession.restoring(
            deceasedCheckpoint
        ), let secondCheckpoint = try? first.makeCheckpoint(),
              let second = try? AgentSimulationSession.restoring(
                  secondCheckpoint
              ) else { return false }
        return (try? second.durableStateBytes())
            == (try? deceasedObserver.durableStateBytes())
            && second.ecologicalObservationSnapshot().observations.count == 1
    }())

    var compactedReplay = historicalObservationBase(
        "ecological-observation-compaction-replay",
        lethalAgentIndices: [0, 1],
        mortalityConfiguration: compactingMortality
    )
    let compactedReplayBase = try! compactedReplay.makeCheckpoint()
    var compactedRecorder = try! AgentReplayRecorder(
        checkpoint: compactedReplayBase,
        session: compactedReplay
    )
    for observer in ["agent_0", "agent_0", "agent_1", "agent_2"] {
        _ = try! compactedRecorder.apply(
            .recordEcologicalObservation(
                normalizedObservation(compactedReplay, observer: observer)
            ),
            to: &compactedReplay
        )
    }
    _ = try! compactedRecorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &compactedReplay
    )
    let compactedJournal = try! compactedRecorder.journal(
        named: AgentCheckpointName(
            rawValue: "ecological-observation-compaction-replay"
        )!
    )
    let compactedReplayed = try! AgentSessionReplayer.replay(
        checkpoint: compactedReplayBase,
        journal: compactedJournal
    )
    check("coordinated observation and death compaction replay is byte exact",
          compactedReplayed.report.verified
            && (try! compactedReplayed.session.durableStateBytes())
                == (try! compactedReplay.durableStateBytes())
            && compactedReplayed.session
                .ecologicalObservationSnapshot().evictionCounts.observations
                == 2)
}
