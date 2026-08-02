import Foundation
import PebbleAgents

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
    return session
}

private func historicalObservationBase(
    _ id: String,
    lethalAgentIndices: Set<Int>,
    mortalityConfiguration: AgentMortalityConfiguration = .live,
    causalMaximumEvents: Int = 8_192
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
    return session
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

private func resignedEcologicalObservation(
    _ source: AgentEcologicalObservation,
    observerID: AgentID? = nil,
    observedAtSimulationTick: Int? = nil,
    calendar: AgentCivilCalendarConfiguration = .live
) -> AgentEcologicalObservation {
    let observedTick = observedAtSimulationTick
        ?? source.observedAtSimulationTick
    return AgentEcologicalObservation(
        observerID: observerID ?? source.observerID,
        origin: source.origin,
        worldContextKey: source.worldContextKey,
        dimensionKey: source.dimensionKey,
        observedAtSimulationTick: observedTick,
        physicalWorldTick: source.physicalWorldTick,
        civilDate: calendar.date(atSimulationTick: observedTick)!,
        biome: source.biome,
        water: source.water,
        soils: source.soils,
        crops: source.crops,
        plants: source.plants,
        animals: source.animals,
        fishing: source.fishing,
        weather: source.weather,
        physicalTime: source.physicalTime,
        diagnostics: source.diagnostics,
        expiresAtSimulationTick: observedTick
            + max(0, source.expiresAtSimulationTick
                - source.observedAtSimulationTick)
    )
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

func runPebbleAgentsEcologicalObservationSmoke() {
    section("pebble agents ecological observation and civil calendar")

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
        try! value.setEcologicalObservationEnabled(true)
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
    try! session.setEcologicalObservationEnabled(true)
    check("activation is v12 and creates no retroactive observation",
          session.durableState().schemaVersion == 12
            && session.ecologicalObservationSnapshot().observations.isEmpty
            && session.causalLedgerSnapshot().summary.latestSequence == causalBefore + 1)

    let first = normalizedObservation(session)
    let firstSequence = session.causalLedgerSnapshot().summary.latestSequence
    let record = try! session.recordEcologicalObservation(first)
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
    check("ecological observation v12 checkpoint is byte exact",
          checkpoint.schemaVersion == 12
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes())
            && restored.ecologicalObservationSnapshot() == session.ecologicalObservationSnapshot())

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
    try! bounded.setEcologicalObservationEnabled(true, configuration: boundedConfiguration)
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_0"))
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_1"))
    try! bounded.recordEcologicalObservation(normalizedObservation(bounded, observer: "agent_0", cropStage: 7))
    check("retention is globally and per-agent bounded deterministically",
          bounded.ecologicalObservationSnapshot().observations.count == 2
            && bounded.ecologicalObservationSnapshot().evictionCounts.observations == 1
            && bounded.ecologicalObservations(for: AgentID(rawValue: "agent_0")!).first?
                .observation.crops.first?.growthStage == 7)

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
    check("causal actor corruption is rejected after full resign",
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
    check("causal subject corruption is rejected after full resign",
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
    check("causal origin corruption is rejected after full resign",
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
    check("causal payload digest corruption is rejected after full resign",
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
    try! registeredLater.setEcologicalObservationEnabled(true)
    _ = try! registeredLater.recordEcologicalObservation(
        normalizedObservation(registeredLater, observer: "agent_0")
    )
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
    try! childRegisteredLater.setEcologicalObservationEnabled(true)
    _ = try! childRegisteredLater.recordEcologicalObservation(
        normalizedObservation(childRegisteredLater, observer: "agent_0")
    )
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
    _ = try! evictedCausal.advanceTick()
    while evictedCausal.causalLedgerSnapshot().summary.droppedEventCount
            < evictedCausalRecord.causalEventID.sequence.rawValue {
        _ = try! evictedCausal.advanceTick()
    }
    let evictedCausalCheckpoint = try! evictedCausal.makeCheckpoint()
    check("honest causal eviction retains exact death-based observer proof", {
        guard !evictedCausal.causalLedgerSnapshot().events.contains(where: {
            $0.eventID == evictedCausalRecord.causalEventID
        }), let restored = try? AgentSimulationSession.restoring(
            evictedCausalCheckpoint
        ) else { return false }
        return (try? restored.durableStateBytes())
            == (try? evictedCausal.durableStateBytes())
            && (try? restored.historicalEcologicalObservationValidations()
                .first?.classification)
                == .deceasedAfterObservationRetained
    }())

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
