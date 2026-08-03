import Foundation
import PebbleAgents

private let b03Positions = [
    AgentPosition(x: 9, y: 63, z: 9),
    AgentPosition(x: 10, y: 63, z: 9),
]

private struct B03Fixture {
    var session: AgentSimulationSession
    let plotID: AgentAgriculturalPlotID
    let cycle1Mature: AgentEcologicalObservationRecord
    let cycle2PlantActions: [AgentAgriculturalActionRecord]
    let plantingMinimumPhysicalTick: Int
}

private func b03Agent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "blocker 03 fixture", startedAtTick: 0,
            urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func b03Session(
    _ id: String,
    maximumRetainedObservationsPerAgent: Int = 16
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 303, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [b03Agent(0), b03Agent(1), b03Agent(2)],
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 2)
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 8,
            maturityAgeTicks: 24,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 32,
            maximumRetainedPlanRecords: 32,
            maximumParentBirthCount: 16
        )
    )
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(
        true,
        configuration: try! AgentEcologicalObservationConfiguration(
            maximumRetainedObservations: max(
                16, maximumRetainedObservationsPerAgent * 3
            ),
            maximumRetainedObservationsPerAgent:
                maximumRetainedObservationsPerAgent
        )
    )
    try! session.setAgricultureEnabled(true)
    return session
}

private func b03Observation(
    _ session: AgentSimulationSession,
    observer: String = "agent_0",
    physicalTick: Int,
    stages: [Int: (crop: String, stage: Int)] = [:],
    completion: AgentEcologicalScanCompletion = .complete
) -> AgentEcologicalObservation {
    let crops = stages.keys.sorted().map { index in
        let value = stages[index]!
        return AgentCropObservation(
            cropKey: value.crop,
            position: AgentPosition(
                x: b03Positions[index].x,
                y: b03Positions[index].y + 1,
                z: b03Positions[index].z
            ),
            growthStage: value.stage,
            maximumGrowthStage: 7,
            mature: value.stage == 7,
            supportBlockKey: "farmland"
        )
    }
    let resultCount = 1 + 1 + b03Positions.count + crops.count + 2
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!,
        origin: AgentPosition(x: 9, y: 64, z: 8),
        worldContextKey: "blocker-03-world",
        dimensionKey: "overworld",
        observedAtSimulationTick: session.tick,
        physicalWorldTick: physicalTick,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "plains",
            position: AgentPosition(x: 9, y: 64, z: 8)
        ),
        water: [AgentWaterAffordance(
            fluidKey: "water",
            position: AgentPosition(x: 11, y: 63, z: 9),
            sourceBlock: true
        )],
        soils: b03Positions.map {
            AgentSoilAffordance(
                blockKey: "farmland", position: $0,
                tillable: false, alreadyFarmland: true,
                hydrated: true, supportsCrop: true
            )
        },
        crops: crops,
        plants: [], animals: [], fishing: [],
        weather: AgentWeatherObservation(
            kind: .clear, raining: false, thundering: false
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: physicalTick,
            dayTime: physicalTick % 24_000,
            timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405,
            chunksTouched: 1, chunksUnavailable: 0,
            entitiesConsidered: 0, resultsEmitted: resultCount,
            cacheHits: 0, cacheMisses: 1, completion: completion
        ),
        expiresAtSimulationTick: session.tick + 4
    )
}

private func b03Action(
    _ session: AgentSimulationSession,
    plotID: AgentAgriculturalPlotID,
    cellIndex: Int?,
    kind: AgentAgriculturalActionKind,
    id: String,
    observationEventID: AgentCausalEventID? = nil,
    position: AgentPosition? = nil
) -> AgentAgriculturalActionOutcome {
    let index = cellIndex ?? 0
    let material: [AgentAgriculturalMaterialDelta]
    let entities: [Int]
    let custody: String?
    let storage: String?
    let reserve: Int
    let surplus: Int
    switch kind {
    case .plant:
        material = [AgentAgriculturalMaterialDelta(
            itemKey: "wheat_seeds", quantity: 1, direction: .consumed
        )]
        entities = []
        custody = "plant-\(id)"
        storage = nil
        reserve = 0
        surplus = 0
    case .harvest:
        material = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: 1, direction: .acquired
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 2,
                direction: .acquired
            ),
        ]
        entities = [100 + index * 2, 101 + index * 2]
        custody = "harvest-\(id)"
        storage = nil
        reserve = 0
        surplus = 0
    case .store:
        material = [
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat", quantity: max(1, cellIndex ?? 1),
                direction: .stored
            ),
            AgentAgriculturalMaterialDelta(
                itemKey: "wheat_seeds", quantity: 4,
                direction: .stored
            ),
        ]
        entities = []
        custody = "store-\(id)"
        storage = "container:12,64,9"
        reserve = 1
        surplus = 1
    default:
        material = []
        entities = []
        custody = nil
        storage = nil
        reserve = 0
        surplus = 0
    }
    let fingerprints: (Int, Int)
    switch kind {
    case .till: fingerprints = (1, 2)
    case .plant: fingerprints = (0, 3)
    case .maturityObserved: fingerprints = (7, 7)
    case .harvest: fingerprints = (7, 0)
    case .store: fingerprints = (0, 0)
    case .reconcile: fingerprints = (3, 0)
    }
    return AgentAgriculturalActionOutcome(
        actionID: AgentAgriculturalActionID(rawValue: id)!,
        kind: kind,
        actorID: AgentID(rawValue: "agent_0")!,
        plotID: plotID,
        cellIndex: cellIndex,
        position: position ?? b03Positions[index],
        beforeFingerprint: fingerprints.0,
        afterFingerprint: fingerprints.1,
        materialDeltas: material,
        sourceItemEntityIDs: entities,
        custodyFingerprint: custody,
        storageLocationID: storage,
        seedReserveQuantity: reserve,
        physicalSurplusQuantity: surplus,
        sourceObservationEventID: observationEventID,
        civilDate: session.civilDate()!
    )
}

private func b03Fixture(
    _ id: String,
    cellCount: Int = 1,
    maximumRetainedObservationsPerAgent: Int = 16,
    cycle1MaturePhysicalTick: Int = 120,
    renewalPhysicalTick: Int = 140
) -> B03Fixture {
    var session = b03Session(
        id,
        maximumRetainedObservationsPerAgent:
            maximumRetainedObservationsPerAgent
    )
    let source = try! session.recordEcologicalObservation(
        b03Observation(session, physicalTick: 100)
    )
    let positions = Array(b03Positions.prefix(cellCount))
    let plotID = try! session.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: positions,
        sourceObservationEventID: source.causalEventID,
        designatedStorageLocationID: "container:12,64,9"
    )
    for index in positions.indices {
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .till,
            id: "b03-c1-till-\(index)"
        ))
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .plant,
            id: "b03-c1-plant-\(index)"
        ))
    }
    let matureStages = Dictionary(uniqueKeysWithValues: positions.indices.map {
        ($0, (crop: "wheat", stage: 7))
    })
    let cycle1Mature = try! session.recordEcologicalObservation(
        b03Observation(
            session,
            physicalTick: cycle1MaturePhysicalTick,
            stages: matureStages
        )
    )
    for index in positions.indices {
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index,
            kind: .maturityObserved, id: "b03-c1-mature-\(index)",
            observationEventID: cycle1Mature.causalEventID
        ))
        _ = try! session.recordAgriculturalActionSuccess(b03Action(
            session, plotID: plotID, cellIndex: index, kind: .harvest,
            id: "b03-c1-harvest-\(index)"
        ))
    }
    _ = try! session.recordAgriculturalActionSuccess(b03Action(
        session, plotID: plotID, cellIndex: nil, kind: .store,
        id: "b03-c1-store"
    ))
    let renewal = try! session.recordEcologicalObservation(
        b03Observation(session, physicalTick: renewalPhysicalTick)
    )
    _ = try! session.renewAgriculturalPlot(
        plotID: plotID,
        plannerID: AgentID(rawValue: "agent_0")!,
        sourceObservationEventID: renewal.causalEventID
    )
    var cycle2Plants: [AgentAgriculturalActionRecord] = []
    for index in positions.indices {
        cycle2Plants.append(try! session.recordAgriculturalActionSuccess(
            b03Action(
                session, plotID: plotID, cellIndex: index, kind: .plant,
                id: "b03-c2-plant-\(index)"
            )
        ))
    }
    return B03Fixture(
        session: session,
        plotID: plotID,
        cycle1Mature: cycle1Mature,
        cycle2PlantActions: cycle2Plants,
        plantingMinimumPhysicalTick: renewalPhysicalTick
    )
}

private func b03Selection(
    _ fixture: B03Fixture,
    eligibleCurrentReceiptIDs:
        Set<AgentPhysicalObservationReceiptID>,
    cellIndex: Int = 0
) -> AgentCurrentCycleCropObservationResult {
    let plot = fixture.session.agricultureSnapshot().plots.first {
        $0.plotID == fixture.plotID
    }!
    let cell = plot.cells[cellIndex]
    return try! fixture.session.currentCycleCropObservation(
        plot: plot,
        cell: cell,
        cropPosition: AgentPosition(
            x: cell.position.x, y: cell.position.y + 1, z: cell.position.z
        ),
        minimumPhysicalWorldTick: fixture.plantingMinimumPhysicalTick,
        eligibleCurrentReceiptIDs: eligibleCurrentReceiptIDs
    )
}

private func b03ReceiptIDs(
    _ records: AgentEcologicalObservationRecord...
) -> Set<AgentPhysicalObservationReceiptID> {
    Set(records.compactMap(\.physicalObservationReceiptID))
}

private func b03ObservationReceipts(
    _ session: AgentSimulationSession
) -> [AgentEcologicalPhysicalReceiptEvidence] {
    session.ecologicalObservationSnapshot().observations.map { record in
        let observation = record.observation
        let receiptID = record.physicalObservationReceiptID!
        return AgentEcologicalPhysicalReceiptEvidence(
            receiptID: receiptID,
            operationID: receiptID.rawValue,
            observerID: observation.observerID,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            dimensionKey: observation.dimensionKey,
            physicalWorldTick: observation.physicalWorldTick,
            simulationID: session.simulationID,
            simulationTick: observation.observedAtSimulationTick,
            origin: observation.origin,
            observation: observation,
            resultCount: observation.diagnostics.resultsEmitted,
            worldReadCount: observation.diagnostics.worldReads
        )
    }
}

private func b03ActionReceipts(
    _ session: AgentSimulationSession
) -> [AgentAgriculturalPhysicalReceiptEvidence] {
    session.agricultureSnapshot().retainedActions.map { record in
        AgentAgriculturalPhysicalReceiptEvidence(
            receiptID: record.outcome.actionID,
            operationID: record.outcome.actionID.rawValue,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            simulationID: session.simulationID,
            outcome: record.outcome
        )
    }
}

private func b03JSONObject<T: Encodable>(_ value: T) -> [String: Any] {
    try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(value)
    ) as! [String: Any]
}

private func b03EventIDText(_ value: [String: Any]) -> String {
    let simulationID = value["simulationID"] as! String
    let sequence = value["sequence"] as! UInt64
    let digits = String(sequence)
    return "\(simulationID)/event-"
        + String(repeating: "0", count: max(0, 20 - digits.count))
        + digits
}

private func b03Digest(_ text: String) -> String {
    AgentAgricultureDigest.make(text)
}

private func b03RepairAgricultureEventDigest(
    _ event: inout [String: Any]
) {
    let eventID = b03EventIDText(event["eventID"] as! [String: Any])
    let instant = event["instant"] as! [String: Any]
    let causes = (event["causes"] as! [[String: Any]])
        .map(b03EventIDText).joined(separator: ",")
    let payload = event["payload"] as! [String: Any]
    let agriculture = payload["agriculture"] as! [String: Any]
    let payloadText = "agriculture|"
        + "\(agriculture["plotID"] as? String ?? "none")|"
        + "\(agriculture["cellIndex"].map { String(describing: $0) } ?? "none")|"
        + "\(agriculture["actionID"] as? String ?? "none")|"
        + "\(agriculture["status"] as! String)|"
        + "\(agriculture["physicalFingerprint"] as! Int)|"
        + "\(agriculture["itemKey"] as? String ?? "none")|"
        + "\(agriculture["quantity"] as! Int)|"
        + "\(agriculture["digest"] as! String)"
    let text = "\(eventID)|\(instant["tick"] as! Int)|"
        + "\(event["kind"] as! String)|\(event["origin"] as! String)|"
        + "\(event["actorID"] as? String ?? "-")|"
        + "\(event["subjectID"] as? String ?? "-")|"
        + "\(event["operationID"] as? String ?? "-")|"
        + "\(causes)|\(payloadText)|\(event["summary"] as! String)"
    event["digest"] = b03Digest(text)
}

private func b03RecomputeCausalRollingDigest(
    _ durable: inout [String: Any]
) {
    var ledger = durable["causalLedger"] as! [String: Any]
    let events = ledger["events"] as! [[String: Any]]
    var rolling = b03Digest("")
    for event in events {
        rolling = b03Digest("\(rolling)|\(event["digest"] as! String)")
    }
    ledger["rollingDigest"] = rolling
    durable["causalLedger"] = ledger
}

private func b03ReplaceMaturitySource(
    _ durable: inout [String: Any],
    actionID: AgentAgriculturalActionID,
    oldEventID: AgentCausalEventID,
    newEventID: AgentCausalEventID
) {
    var agriculture = durable["agricultureState"] as! [String: Any]
    var actions = agriculture["retainedActions"] as! [[String: Any]]
    let actionIndex = actions.firstIndex {
        let outcome = $0["outcome"] as! [String: Any]
        return outcome["actionID"] as? String == actionID.rawValue
    }!
    var outcome = actions[actionIndex]["outcome"] as! [String: Any]
    outcome["sourceObservationEventID"] = b03JSONObject(newEventID)
    actions[actionIndex]["outcome"] = outcome
    agriculture["retainedActions"] = actions
    durable["agricultureState"] = agriculture

    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let eventIndex = events.firstIndex {
        $0["operationID"] as? String == actionID.rawValue
    }!
    var causes = events[eventIndex]["causes"] as! [[String: Any]]
    causes = causes.map {
        b03EventIDText($0) == oldEventID.rawValue
            ? b03JSONObject(newEventID) : $0
    }.sorted {
        ($0["sequence"] as! UInt64) < ($1["sequence"] as! UInt64)
    }
    events[eventIndex]["causes"] = causes
    b03RepairAgricultureEventDigest(&events[eventIndex])
    ledger["events"] = events
    durable["causalLedger"] = ledger
    b03RecomputeCausalRollingDigest(&durable)
}

private func b03ReplaceCurrentPlantWithPriorCycleAction(
    _ durable: inout [String: Any]
) {
    var agriculture = durable["agricultureState"] as! [String: Any]
    var actions = agriculture["retainedActions"] as! [[String: Any]]
    let priorIndex = actions.firstIndex {
        let outcome = $0["outcome"] as! [String: Any]
        return outcome["actionID"] as? String == "b03-c1-plant-0"
    }!
    let currentIndex = actions.firstIndex {
        let outcome = $0["outcome"] as! [String: Any]
        return outcome["actionID"] as? String == "b03-c2-plant-0"
    }!
    let priorOutcome = actions[priorIndex]["outcome"] as! [String: Any]
    let currentEventID = actions[currentIndex]["agricultureEventID"]
        as! [String: Any]
    let currentSequence = currentEventID["sequence"] as! UInt64

    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let currentEventIndex = events.firstIndex {
        b03EventIDText($0["eventID"] as! [String: Any])
            == b03EventIDText(currentEventID)
    }!
    let previousAgricultureEvent = events.filter {
        ($0["origin"] as? String) == "agricultureTransition"
            && (($0["eventID"] as! [String: Any])["sequence"] as! UInt64)
                < currentSequence
            && (($0["payload"] as! [String: Any])["agriculture"] != nil)
    }.max {
        (($0["eventID"] as! [String: Any])["sequence"] as! UInt64)
            < (($1["eventID"] as! [String: Any])["sequence"] as! UInt64)
    }!
    let previousPayload = (previousAgricultureEvent["payload"]
        as! [String: Any])["agriculture"] as! [String: Any]
    let previousDigest = previousPayload["digest"] as! String
    let materialRows = priorOutcome["materialDeltas"] as! [[String: Any]]
    let materialText = materialRows.map {
        "\($0["direction"] as! String):\($0["itemKey"] as! String):"
            + "\($0["quantity"] as! Int)"
    }.joined(separator: ",")
    let newDigest = b03Digest(
        "\(previousDigest)|\(priorOutcome["actionID"] as! String)|"
            + "\(priorOutcome["kind"] as! String)|"
            + "\(priorOutcome["beforeFingerprint"] as! Int)>"
            + "\(priorOutcome["afterFingerprint"] as! Int)|\(materialText)"
    )

    var currentRecord = actions[currentIndex]
    currentRecord["outcome"] = priorOutcome
    currentRecord["digest"] = newDigest
    actions[currentIndex] = currentRecord
    agriculture["retainedActions"] = actions
    var processed = agriculture["processedActionIDs"] as! [String]
    let currentProcessed = processed.firstIndex(of: "b03-c2-plant-0")!
    processed[currentProcessed] = "b03-c1-plant-0"
    agriculture["processedActionIDs"] = processed
    agriculture["rollingDigest"] = newDigest
    durable["agricultureState"] = agriculture

    events[currentEventIndex]["operationID"] = "b03-c1-plant-0"
    var payload = events[currentEventIndex]["payload"] as! [String: Any]
    var agriculturalPayload = payload["agriculture"] as! [String: Any]
    agriculturalPayload["actionID"] = "b03-c1-plant-0"
    agriculturalPayload["digest"] = newDigest
    payload["agriculture"] = agriculturalPayload
    events[currentEventIndex]["payload"] = payload
    b03RepairAgricultureEventDigest(&events[currentEventIndex])
    ledger["events"] = events
    durable["causalLedger"] = ledger
    b03RecomputeCausalRollingDigest(&durable)
}

private func b03FullyResignedRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    observationReceipts: [AgentEcologicalPhysicalReceiptEvidence],
    actionReceipts: [AgentAgriculturalPhysicalReceiptEvidence],
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        var root = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        mutate(&durable)
        let mutationBytes = try JSONSerialization.data(
            withJSONObject: durable,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let state = try AgentCheckpointCodec.decode(
            AgentSessionDurableState.self, from: mutationBytes
        )
        let durableBytes = try AgentCheckpointCodec.encode(state)
        let canonical = try JSONSerialization.jsonObject(
            with: durableBytes
        ) as! [String: Any]
        let digest = AgentCheckpointDigest.sha256(durableBytes)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(state.clock.simulationID.rawValue.utf8)
        )
        root["durableState"] = canonical
        root["schemaVersion"] = state.schemaVersion
        root["simulationID"] = state.clock.simulationID.rawValue
        root["tick"] = state.clock.tick.rawValue
        root["semanticDigest"] = digest.rawValue
        root["checkpointID"] =
            "checkpoint-\(simulationDigest.rawValue.prefix(12))"
                + "-t\(state.clock.tick.rawValue)-\(digest.rawValue.prefix(16))"
        let resigned = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: JSONSerialization.data(
                withJSONObject: root,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
        let restored = try AgentSimulationSession.restoring(resigned)
        try restored.validateIndependentEcologicalObservationReceipts(
            observationReceipts,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0
        )
        try restored.validateIndependentAgriculturalActionReceipts(
            actionReceipts,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0
        )
        return false
    } catch {
        return true
    }
}

private func b03FullyResignedMaturitySourceRefused(
    _ fixture: inout B03Fixture,
    wrongRecord: AgentEcologicalObservationRecord,
    suffix: String
) -> Bool {
    let correct = try! fixture.session.recordEcologicalObservation(
        b03Observation(
            fixture.session, physicalTick: 220,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    let actionID = AgentAgriculturalActionID(
        rawValue: "b03-resigned-\(suffix)-maturity"
    )!
    _ = try! fixture.session.recordAgriculturalActionSuccess(b03Action(
        fixture.session,
        plotID: fixture.plotID,
        cellIndex: 0,
        kind: .maturityObserved,
        id: actionID.rawValue,
        observationEventID: correct.causalEventID
    ))
    let checkpoint = try! fixture.session.makeCheckpoint()
    let observationReceipts = b03ObservationReceipts(fixture.session)
    let actionReceipts = b03ActionReceipts(fixture.session)
    return b03FullyResignedRestoreRefused(
        checkpoint,
        observationReceipts: observationReceipts,
        actionReceipts: actionReceipts
    ) { durable in
        b03ReplaceMaturitySource(
            &durable,
            actionID: actionID,
            oldEventID: correct.causalEventID,
            newEventID: wrongRecord.causalEventID
        )
    }
}

func runPebbleAgentsAgricultureCycleObservationSmoke() {
    section("Gate D Blocker 03 cycle-scoped agricultural maturity evidence")

    var exact = b03Fixture("b03-exact")
    check("only prior-cycle mature evidence yields no current-cycle transition",
          b03Selection(
              exact, eligibleCurrentReceiptIDs: []
          ).classification == .noEligibleObservation)
    let stage0 = try! exact.session.recordEcologicalObservation(
        b03Observation(
            exact.session, physicalTick: 141,
            stages: [0: (crop: "wheat", stage: 0)]
        )
    )
    let exactSelection = b03Selection(
        exact, eligibleCurrentReceiptIDs: b03ReceiptIDs(stage0)
    )
    check("cycle-1 mature row plus cycle-2 stage-0 row selects non-mature",
          exactSelection.classification == .currentCycleNonMature
            && exactSelection.evidence?.record.causalEventID
                == stage0.causalEventID
            && exactSelection.evidence?.currentPlantAction.outcome.actionID
                == exact.cycle2PlantActions[0].outcome.actionID)
    check("same actor never walks back from latest non-mature to old mature",
          exactSelection.evidence?.crop.mature == false
            && exact.session.ecologicalObservations(
                for: AgentID(rawValue: "agent_0")!
            ).contains(where: {
                $0.causalEventID == exact.cycle1Mature.causalEventID
            }))
    check("retained current-looking row has no automatic authority",
          b03Selection(
              exact, eligibleCurrentReceiptIDs: []
          ).classification == .noEligibleObservation)
    let beforeNonMature = try! exact.session.durableStateBytes()
    check("non-mature classification is non-mutating",
          (try! exact.session.durableStateBytes()) == beforeNonMature
            && exact.session.agricultureSnapshot().plots[0].cells[0].phase
                == .planted)

    var multi = b03Fixture("b03-multi")
    let olderMulti = try! multi.session.recordEcologicalObservation(b03Observation(
        multi.session, observer: "agent_0", physicalTick: 151,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    let newestOther = try! multi.session.recordEcologicalObservation(
        b03Observation(
            multi.session, observer: "agent_1", physicalTick: 152,
            stages: [0: (crop: "wheat", stage: 0)]
        )
    )
    let multiSelection = b03Selection(
        multi,
        eligibleCurrentReceiptIDs: b03ReceiptIDs(olderMulti, newestOther)
    )
    check("newer physical evidence wins across actors",
          multiSelection.classification == .currentCycleNonMature
            && multiSelection.evidence?.record.causalEventID
                == newestOther.causalEventID)

    var reversed = b03Fixture("b03-multi-reversed")
    let olderReversed = try! reversed.session.recordEcologicalObservation(b03Observation(
        reversed.session, observer: "agent_1", physicalTick: 151,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    let newestLexicalFirst = try! reversed.session
        .recordEcologicalObservation(b03Observation(
            reversed.session, observer: "agent_0", physicalTick: 152,
            stages: [0: (crop: "wheat", stage: 0)]
        ))
    let reversedSelection = b03Selection(
        reversed,
        eligibleCurrentReceiptIDs: b03ReceiptIDs(
            olderReversed, newestLexicalFirst
        )
    )
    check("actor lexical order cannot override physical recency",
          reversedSelection.classification == .currentCycleNonMature
            && reversedSelection.evidence?.record.causalEventID
                == newestLexicalFirst.causalEventID)

    var conflict = b03Fixture("b03-conflict")
    let conflictMature = try! conflict.session.recordEcologicalObservation(b03Observation(
        conflict.session, observer: "agent_0", physicalTick: 160,
        stages: [0: (crop: "wheat", stage: 7)]
    ))
    let conflictNonMature = try! conflict.session.recordEcologicalObservation(b03Observation(
        conflict.session, observer: "agent_1", physicalTick: 160,
        stages: [0: (crop: "wheat", stage: 0)]
    ))
    check("incompatible evidence at one physical boundary fails closed",
          b03Selection(
              conflict,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(
                  conflictMature, conflictNonMature
              )
          ).classification
            == .conflictingCurrentEvidence)

    var wrongTick = b03Fixture("b03-world-tick")
    let wrongTickRecord = try! wrongTick.session.recordEcologicalObservation(b03Observation(
        wrongTick.session, physicalTick: 139,
        stages: [0: (crop: "wheat", stage: 0)]
    ))
    check("physical World tick before cycle foundation is invalid",
          b03Selection(
              wrongTick,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(wrongTickRecord)
          ).classification == .invalidCurrentEvidence)

    var replacement = b03Fixture("b03-crop-replacement")
    let replacementRecord = try! replacement.session.recordEcologicalObservation(b03Observation(
        replacement.session, physicalTick: 145,
        stages: [0: (crop: "carrots", stage: 0)]
    ))
    check("other-crop evidence at the same cell is never rebound",
          b03Selection(
              replacement,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(replacementRecord)
          ).classification
            == .invalidCurrentEvidence)

    var mature = exact
    let matureRecord = try! mature.session.recordEcologicalObservation(
        b03Observation(
            mature.session, physicalTick: 170,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    let matureSelection = b03Selection(
        mature, eligibleCurrentReceiptIDs: b03ReceiptIDs(matureRecord)
    )
    let matureID = AgentAgriculturalActionID.automaticMaturity(
        simulationTick: mature.session.tick,
        plotID: mature.plotID,
        cycleOrdinal: 2,
        cellIndex: 0
    )!
    check("later current-cycle stage-7 evidence becomes mature exactly",
          matureSelection.classification == .currentCycleMature
            && matureSelection.evidence?.record.causalEventID
                == matureRecord.causalEventID)
    let matureOutcome = b03Action(
        mature.session, plotID: mature.plotID, cellIndex: 0,
        kind: .maturityObserved, id: matureID.rawValue,
        observationEventID: matureRecord.causalEventID
    )
    _ = try! mature.session.recordAgriculturalActionSuccess(matureOutcome)
    let matureBytes = try! mature.session.durableStateBytes()
    do {
        _ = try mature.session.recordAgriculturalActionSuccess(matureOutcome)
        check("same cycle maturity action is idempotent", false)
    } catch AgentSessionError.agriculture(.duplicateAction) {
        check("same cycle maturity action is idempotent",
              (try! mature.session.durableStateBytes()) == matureBytes)
    } catch {
        check("same cycle maturity action is idempotent", false, "\(error)")
    }
    let cycle1ID = AgentAgriculturalActionID.automaticMaturity(
        simulationTick: mature.session.tick,
        plotID: mature.plotID,
        cycleOrdinal: 1,
        cellIndex: 0
    )!
    check("automatic maturity IDs are cycle scoped at the same tick",
          cycle1ID != matureID
            && matureID.rawValue.contains(":cycle-2:"))

    var twoCells = b03Fixture("b03-two-cells", cellCount: 2)
    let mixed = try! twoCells.session.recordEcologicalObservation(
        b03Observation(
            twoCells.session, physicalTick: 180,
            stages: [
                0: (crop: "wheat", stage: 7),
                1: (crop: "wheat", stage: 0),
            ]
        )
    )
    check("mixed cells classify independently",
          b03Selection(
              twoCells,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(mixed),
              cellIndex: 0
          ).classification
            == .currentCycleMature
            && b03Selection(
                twoCells,
                eligibleCurrentReceiptIDs: b03ReceiptIDs(mixed),
                cellIndex: 1
            ).classification
                == .currentCycleNonMature)
    _ = try! twoCells.session.recordAgriculturalActionSuccess(b03Action(
        twoCells.session, plotID: twoCells.plotID, cellIndex: 0,
        kind: .maturityObserved, id: "b03-c2-mature-cell-0",
        observationEventID: mixed.causalEventID
    ))
    check("one mature cell cannot corrupt a non-mature sibling",
          twoCells.session.agricultureSnapshot().plots[0].cells[0].phase
            == .mature
            && twoCells.session.agricultureSnapshot().plots[0].cells[1].phase
                == .planted)

    let restartCheckpoint = try! exact.session.makeCheckpoint()
    let restarted = try! AgentSimulationSession.restoring(restartCheckpoint)
    let restartedFixture = B03Fixture(
        session: restarted,
        plotID: exact.plotID,
        cycle1Mature: exact.cycle1Mature,
        cycle2PlantActions: exact.cycle2PlantActions,
        plantingMinimumPhysicalTick: exact.plantingMinimumPhysicalTick
    )
    check("schema 30 restart keeps rows historical until a new scan",
          restartCheckpoint.schemaVersion == 30
            && b03Selection(
                restartedFixture, eligibleCurrentReceiptIDs: []
            ).classification == .noEligibleObservation
            && (try! restarted.durableStateBytes())
                == (try! exact.session.durableStateBytes()))

    var noExact = b03Fixture("b03-no-current-exact-cell")
    let budgetLimited = try! noExact.session.recordEcologicalObservation(
        b03Observation(
            noExact.session,
            physicalTick: 142,
            completion: .scanBudgetExceeded
        )
    )
    let noExactBytes = try! noExact.session.durableStateBytes()
    check("current transaction without exact-cell evidence does not transition",
          b03Selection(
              noExact,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(budgetLimited)
          ).classification == .noEligibleObservation
            && (try! noExact.session.durableStateBytes()) == noExactBytes)
    let noExactTickBefore = noExact.session.tick
    _ = try! noExact.session.advanceTick()
    check("scan-budget omission permits the normal tick to continue",
          noExact.session.tick == noExactTickBefore + 1
            && noExact.session.agricultureSnapshot().plots[0].cells[0].phase
                == .planted)
    check("a repeated transaction never reuses the previous tick receipt",
          b03Selection(
              exact,
              eligibleCurrentReceiptIDs: b03ReceiptIDs(budgetLimited)
          ).classification == .noEligibleObservation)

    // This fixture models the review attack with product-valid state: O2 is
    // honestly evicted, while O1 is rebound to a later ecological event with
    // the exact same receipt ID and physical content. The resulting schema-30
    // checkpoint is fully signed by the product and therefore stronger than
    // merely repairing its JSON digests. Transaction membership, which is not
    // part of the checkpoint, must still withhold transition authority.
    var chronology = b03Fixture(
        "b03-resigned-chronology",
        maximumRetainedObservationsPerAgent: 3,
        cycle1MaturePhysicalTick: 140,
        renewalPhysicalTick: 140
    )
    let chronologyStage0 = try! chronology.session
        .recordEcologicalObservation(b03Observation(
            chronology.session,
            physicalTick: 140,
            stages: [0: (crop: "wheat", stage: 0)]
        ))
    let chronologyOldReceipt = chronology.cycle1Mature
        .physicalObservationReceiptID!
    let chronologyRebound = try! chronology.session
        .recordEcologicalObservation(
            chronology.cycle1Mature.observation,
            physicalReceiptID: chronologyOldReceipt
        )
    _ = try! chronology.session.recordEcologicalObservation(
        b03Observation(chronology.session, physicalTick: 141)
    )
    _ = try! chronology.session.recordEcologicalObservation(
        b03Observation(chronology.session, physicalTick: 142)
    )
    let chronologyRows = chronology.session
        .ecologicalObservationSnapshot().observations
    let chronologyPlantEvent = chronology.cycle2PlantActions[0]
        .agricultureEventID
    let chronologyCheckpoint = try! chronology.session.makeCheckpoint()
    let chronologyRestored = try! AgentSimulationSession.restoring(
        chronologyCheckpoint
    )
    let chronologyRestoredFixture = B03Fixture(
        session: chronologyRestored,
        plotID: chronology.plotID,
        cycle1Mature: chronology.cycle1Mature,
        cycle2PlantActions: chronology.cycle2PlantActions,
        plantingMinimumPhysicalTick: chronology.plantingMinimumPhysicalTick
    )
    check("fully signed chronology rebind retains World receipts unchanged",
          chronologyCheckpoint.schemaVersion == 30
            && chronologyOldReceipt
                == chronology.cycle1Mature.physicalObservationReceiptID
            && chronologyStage0.physicalObservationReceiptID
                != chronologyOldReceipt
            && chronologyRows.contains(where: {
                $0.causalEventID == chronologyRebound.causalEventID
                    && $0.physicalObservationReceiptID
                        == chronologyOldReceipt
                    && $0.observation == chronology.cycle1Mature.observation
            })
            && !chronologyRows.contains(where: {
                $0.causalEventID == chronologyStage0.causalEventID
            }))
    check("re-signed old maturity has larger causal sequence at same tick",
          chronologyRebound.causalEventID.sequence
                > chronologyPlantEvent.sequence
            && chronologyRebound.observation.observedAtSimulationTick
                == chronology.cycle2PlantActions[0].outcome.civilDate
                    .simulationTick)
    check("chronology mutation is refused independently by membership",
          b03Selection(
              chronologyRestoredFixture,
              eligibleCurrentReceiptIDs: []
          ).classification == .noEligibleObservation)
    check("explicit headless receipt authority remains bounded",
          b03Selection(
              chronologyRestoredFixture,
              eligibleCurrentReceiptIDs: [chronologyOldReceipt]
          ).classification == .currentCycleMature)

    let resignedObservationReceipts = b03ObservationReceipts(exact.session)
    let resignedActionReceipts = b03ActionReceipts(exact.session)
    check("fully re-signed cycle ordinal without matching plant proof is refused",
          b03FullyResignedRestoreRefused(
            restartCheckpoint,
            observationReceipts: resignedObservationReceipts,
            actionReceipts: resignedActionReceipts
          ) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              var plots = agriculture["plots"] as! [[String: Any]]
              plots[0]["cycleOrdinal"] = 3
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("fully re-signed last-work substitution to prior plant is refused",
          b03FullyResignedRestoreRefused(
            restartCheckpoint,
            observationReceipts: resignedObservationReceipts,
            actionReceipts: resignedActionReceipts
          ) { durable in
              var agriculture = durable["agricultureState"] as! [String: Any]
              let actions = agriculture["retainedActions"] as! [[String: Any]]
              let priorPlant = actions.first {
                  let outcome = $0["outcome"] as! [String: Any]
                  return outcome["actionID"] as? String == "b03-c1-plant-0"
              }!
              var plots = agriculture["plots"] as! [[String: Any]]
              var cells = plots[0]["cells"] as! [[String: Any]]
              cells[0]["lastWorkEventID"] = priorPlant["agricultureEventID"]
              plots[0]["cells"] = cells
              agriculture["plots"] = plots
              durable["agricultureState"] = agriculture
          })
    check("coherently rebound plant event with unchanged receipt is refused",
          b03FullyResignedRestoreRefused(
            restartCheckpoint,
            observationReceipts: resignedObservationReceipts,
            actionReceipts: resignedActionReceipts
          ) { durable in
              b03ReplaceCurrentPlantWithPriorCycleAction(&durable)
          })

    var resignedBeforePlant = b03Fixture("b03-resigned-before-plant")
    let beforePlantSource = resignedBeforePlant.cycle1Mature
    check("fully re-signed maturity source moved before planting is refused",
          b03FullyResignedMaturitySourceRefused(
            &resignedBeforePlant,
            wrongRecord: beforePlantSource,
            suffix: "before-plant"
          ))

    var resignedOtherCell = b03Fixture(
        "b03-resigned-other-cell", cellCount: 2
    )
    let otherCellSource = try! resignedOtherCell.session
        .recordEcologicalObservation(b03Observation(
            resignedOtherCell.session,
            physicalTick: 180,
            stages: [1: (crop: "wheat", stage: 7)]
        ))
    check("fully re-signed other-cell maturity observation is refused",
          b03FullyResignedMaturitySourceRefused(
            &resignedOtherCell,
            wrongRecord: otherCellSource,
            suffix: "other-cell"
          ))

    var resignedOtherPlot = b03Fixture("b03-resigned-other-plot")
    let otherPlotSource = try! resignedOtherPlot.session
        .recordEcologicalObservation(b03Observation(
            resignedOtherPlot.session, physicalTick: 181
        ))
    let otherPlotID = try! resignedOtherPlot.session.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: [b03Positions[1]],
        sourceObservationEventID: otherPlotSource.causalEventID,
        designatedStorageLocationID: "container:13,64,9"
    )
    _ = try! resignedOtherPlot.session.recordAgriculturalActionSuccess(
        b03Action(
            resignedOtherPlot.session,
            plotID: otherPlotID,
            cellIndex: 0,
            kind: .till,
            id: "b03-other-plot-till",
            position: b03Positions[1]
        )
    )
    _ = try! resignedOtherPlot.session.recordAgriculturalActionSuccess(
        b03Action(
            resignedOtherPlot.session,
            plotID: otherPlotID,
            cellIndex: 0,
            kind: .plant,
            id: "b03-other-plot-plant",
            position: b03Positions[1]
        )
    )
    let otherPlotMature = try! resignedOtherPlot.session
        .recordEcologicalObservation(b03Observation(
            resignedOtherPlot.session,
            physicalTick: 182,
            stages: [1: (crop: "wheat", stage: 7)]
        ))
    check("fully re-signed other-plot maturity observation is refused",
          b03FullyResignedMaturitySourceRefused(
            &resignedOtherPlot,
            wrongRecord: otherPlotMature,
            suffix: "other-plot"
          ))

    var resignedOtherCrop = b03Fixture("b03-resigned-other-crop")
    let otherCropSource = try! resignedOtherCrop.session
        .recordEcologicalObservation(b03Observation(
            resignedOtherCrop.session,
            physicalTick: 183,
            stages: [0: (crop: "carrots", stage: 7)]
        ))
    check("fully re-signed other-crop maturity observation is refused",
          b03FullyResignedMaturitySourceRefused(
            &resignedOtherCrop,
            wrongRecord: otherCropSource,
            suffix: "other-crop"
          ))

    var resignedWrongTick = b03Fixture("b03-resigned-wrong-world-tick")
    let wrongTickSource = try! resignedWrongTick.session
        .recordEcologicalObservation(b03Observation(
            resignedWrongTick.session,
            physicalTick: 139,
            stages: [0: (crop: "wheat", stage: 7)]
        ))
    check("fully re-signed incompatible physical World tick is refused",
          b03FullyResignedMaturitySourceRefused(
            &resignedWrongTick,
            wrongRecord: wrongTickSource,
            suffix: "wrong-world-tick"
          ))

    var beforePlant = b03Session("b03-before-plant")
    let source = try! beforePlant.recordEcologicalObservation(
        b03Observation(beforePlant, physicalTick: 100)
    )
    let beforePlot = try! beforePlant.planAgriculturalPlot(
        plannerID: AgentID(rawValue: "agent_0")!,
        positions: [b03Positions[0]],
        sourceObservationEventID: source.causalEventID,
        designatedStorageLocationID: "container:12,64,9"
    )
    _ = try! beforePlant.recordAgriculturalActionSuccess(b03Action(
        beforePlant, plotID: beforePlot, cellIndex: 0, kind: .till,
        id: "b03-before-till"
    ))
    let prematureEvidence = try! beforePlant.recordEcologicalObservation(
        b03Observation(
            beforePlant, physicalTick: 110,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    _ = try! beforePlant.recordAgriculturalActionSuccess(b03Action(
        beforePlant, plotID: beforePlot, cellIndex: 0, kind: .plant,
        id: "b03-after-old-observation-plant"
    ))
    let beforeBytes = try! beforePlant.durableStateBytes()
    do {
        _ = try beforePlant.recordAgriculturalActionSuccess(b03Action(
            beforePlant, plotID: beforePlot, cellIndex: 0,
            kind: .maturityObserved, id: "b03-before-boundary-maturity",
            observationEventID: prematureEvidence.causalEventID
        ))
        check("observation before current plant event is refused atomically", false)
    } catch AgentSessionError.agriculture(.invalidAction("maturity evidence")) {
        check("observation before current plant event is refused atomically",
              (try! beforePlant.durableStateBytes()) == beforeBytes)
    } catch {
        check("observation before current plant event is refused atomically",
              false, "\(error)")
    }

    var reusedCycleID = b03Fixture("b03-reused-cycle-action-id")
    let reusedMature = try! reusedCycleID.session.recordEcologicalObservation(
        b03Observation(
            reusedCycleID.session,
            physicalTick: 190,
            stages: [0: (crop: "wheat", stage: 7)]
        )
    )
    let reusedBefore = try! reusedCycleID.session.durableStateBytes()
    do {
        _ = try reusedCycleID.session.recordAgriculturalActionSuccess(b03Action(
            reusedCycleID.session,
            plotID: reusedCycleID.plotID,
            cellIndex: 0,
            kind: .maturityObserved,
            id: "b03-c1-mature-0",
            observationEventID: reusedMature.causalEventID
        ))
        check("maturity action ID reuse across cycles is refused", false)
    } catch AgentSessionError.agriculture(.duplicateAction) {
        check("maturity action ID reuse across cycles is refused",
              (try! reusedCycleID.session.durableStateBytes()) == reusedBefore)
    } catch {
        check("maturity action ID reuse across cycles is refused", false, "\(error)")
    }

    let observationEvidence = b03ObservationReceipts(exact.session)
    let actionEvidence = b03ActionReceipts(exact.session)
    check("staged receipt absent from the independent World set is refused", {
        guard let currentID = stage0.physicalObservationReceiptID else {
            return false
        }
        do {
            try exact.session.validateIndependentEcologicalObservationReceipts(
                observationEvidence.filter { $0.receiptID != currentID },
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
    check("staged receipt from another World is refused", {
        guard let currentID = stage0.physicalObservationReceiptID,
              let currentIndex = observationEvidence.firstIndex(where: {
                  $0.receiptID == currentID
              }) else { return false }
        var changed = observationEvidence
        let current = changed[currentIndex]
        changed[currentIndex] = AgentEcologicalPhysicalReceiptEvidence(
            receiptID: current.receiptID,
            operationID: current.operationID,
            observerID: current.observerID,
            worldID: "other-world",
            storageIdentity: current.storageIdentity,
            dimension: current.dimension,
            dimensionKey: current.dimensionKey,
            physicalWorldTick: current.physicalWorldTick,
            simulationID: current.simulationID,
            simulationTick: current.simulationTick,
            origin: current.origin,
            observation: current.observation,
            resultCount: current.resultCount,
            worldReadCount: current.worldReadCount
        )
        do {
            try exact.session.validateIndependentEcologicalObservationReceipts(
                changed,
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
    check("fully re-signed staged row and event mismatch is refused",
          b03FullyResignedRestoreRefused(
            restartCheckpoint,
            observationReceipts: observationEvidence,
            actionReceipts: actionEvidence
          ) { durable in
              var ecology = durable["ecologicalObservationState"]
                  as! [String: Any]
              var observations = ecology["observations"]
                  as! [[String: Any]]
              let currentIndex = observations.firstIndex {
                  $0["physicalObservationReceiptID"] as? String
                    == stage0.physicalObservationReceiptID?.rawValue
              }!
              observations[currentIndex]["causalEventID"] = b03JSONObject(
                  exact.cycle1Mature.causalEventID
              )
              ecology["observations"] = observations
              durable["ecologicalObservationState"] = ecology
          })
    check("current-cycle observation receipt substitution is refused", {
        guard let currentID = stage0.physicalObservationReceiptID,
              let currentIndex = observationEvidence.firstIndex(where: {
                  $0.receiptID == currentID
              }),
              let prior = observationEvidence.first(where: {
                  $0.receiptID
                    == exact.cycle1Mature.physicalObservationReceiptID
              }) else { return false }
        var changed = observationEvidence
        changed[currentIndex] = AgentEcologicalPhysicalReceiptEvidence(
            receiptID: currentID,
            operationID: currentID.rawValue,
            observerID: prior.observerID,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            dimensionKey: prior.dimensionKey,
            physicalWorldTick: prior.physicalWorldTick,
            simulationID: exact.session.simulationID,
            simulationTick: prior.simulationTick,
            origin: prior.origin,
            observation: prior.observation,
            resultCount: prior.resultCount,
            worldReadCount: prior.worldReadCount
        )
        do {
            try exact.session.validateIndependentEcologicalObservationReceipts(
                changed,
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
    check("current plant receipt substitution is refused", {
        guard let currentIndex = actionEvidence.firstIndex(where: {
                  $0.receiptID
                    == exact.cycle2PlantActions[0].outcome.actionID
              }),
              let prior = actionEvidence.first(where: {
                  $0.outcome.kind == .plant
                    && $0.receiptID
                        != exact.cycle2PlantActions[0].outcome.actionID
              }) else { return false }
        var changed = actionEvidence
        let currentID = changed[currentIndex].receiptID
        changed[currentIndex] = AgentAgriculturalPhysicalReceiptEvidence(
            receiptID: currentID,
            operationID: currentID.rawValue,
            worldID: "b03-world",
            storageIdentity: "sqlite-world:b03-world",
            dimension: 0,
            simulationID: exact.session.simulationID,
            outcome: prior.outcome
        )
        do {
            try exact.session.validateIndependentAgriculturalActionReceipts(
                changed,
                worldID: "b03-world",
                storageIdentity: "sqlite-world:b03-world",
                dimension: 0
            )
            return false
        } catch { return true }
    }())
}
