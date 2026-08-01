import Foundation
import PebbleAgents

private let renewableAgentID = AgentID(rawValue: "agent_0")!
private let renewableSoil = AgentPosition(x: 1, y: 63, z: 0)

private func renewableAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.6, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "renewable fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func renewableSession(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: [renewableAgent(0), renewableAgent(1), renewableAgent(2)],
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 4_096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 2)
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 8, maturityAgeTicks: 24,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1, reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 16,
            maximumRetainedPlanRecords: 16, maximumParentBirthCount: 8
        )
    )
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setAgricultureEnabled(
        true,
        configuration: try! AgentAgricultureConfiguration(
            maximumPlots: 2, maximumCellsPerPlot: 1,
            minimumCellsPerPlot: 1, maximumReservations: 2,
            reservationLifetimeTicks: 4, maximumRetainedActions: 32,
            maximumRetainedSurplusRecords: 8,
            maximumProcessedActionIDs: 64
        )
    )
    session.setSurvivalEnabled(true)
    try! session.setPhysicalFoodSurvivalEnabled(true)
    return session
}

private func renewableObservation(
    _ session: AgentSimulationSession,
    farmland: Bool,
    mature: Bool = false
) -> AgentEcologicalObservation {
    let crop = AgentCropObservation(
        cropKey: AgentAgriculturalCrop.carrots.rawValue,
        position: AgentPosition(x: renewableSoil.x, y: 64, z: renewableSoil.z),
        growthStage: mature ? 7 : 0, maximumGrowthStage: 7,
        mature: mature, supportBlockKey: "farmland"
    )
    return AgentEcologicalObservation(
        observerID: renewableAgentID,
        origin: AgentPosition(x: 0, y: 64, z: 0),
        worldContextKey: "renewable-world", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 100,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "plains", position: AgentPosition(x: 0, y: 64, z: 0)
        ),
        water: [AgentWaterAffordance(
            fluidKey: "water", position: AgentPosition(x: 2, y: 63, z: 0),
            sourceBlock: true
        )],
        soils: [AgentSoilAffordance(
            blockKey: farmland ? "farmland" : "dirt", position: renewableSoil,
            tillable: !farmland, alreadyFarmland: farmland,
            hydrated: farmland ? true : nil, supportsCrop: true
        )],
        crops: mature ? [crop] : [], plants: [], animals: [], fishing: [],
        weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 100, dayTime: 100, timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405,
            chunksTouched: 1, chunksUnavailable: 0, entitiesConsidered: 0,
            resultsEmitted: mature ? 6 : 5, cacheHits: 0, cacheMisses: 1,
            completion: .complete
        ),
        expiresAtSimulationTick: session.tick + 4
    )
}

private func renewableAction(
    _ session: AgentSimulationSession,
    plotID: AgentAgriculturalPlotID,
    kind: AgentAgriculturalActionKind,
    suffix: String,
    observationEventID: AgentCausalEventID? = nil,
    storedQuantity: Int = 1
) -> AgentAgriculturalActionOutcome {
    let delta: [AgentAgriculturalMaterialDelta]
    let entities: [Int]
    let custody: String?
    let storage: String?
    let reserve: Int
    let surplus: Int
    switch kind {
    case .plant:
        delta = [AgentAgriculturalMaterialDelta(
            itemKey: "carrot", quantity: 1, direction: .consumed
        )]
        entities = []; custody = "carried-after-\(suffix)"; storage = nil
        reserve = 0; surplus = 0
    case .harvest:
        delta = [AgentAgriculturalMaterialDelta(
            itemKey: "carrot", quantity: 3, direction: .acquired
        )]
        entities = [suffix.hasPrefix("second") ? 202 : 101]
        custody = "carried-after-\(suffix)"; storage = nil
        reserve = 0; surplus = 0
    case .store:
        delta = [AgentAgriculturalMaterialDelta(
            itemKey: "carrot", quantity: storedQuantity, direction: .stored
        )]
        entities = []; custody = "container-after-\(suffix)"
        storage = "container:3,64,0"; reserve = 1; surplus = storedQuantity
    default:
        delta = []; entities = []; custody = nil; storage = nil
        reserve = 0; surplus = 0
    }
    let before: Int
    let after: Int
    switch kind {
    case .till: before = 1; after = 2
    case .plant: before = 0; after = 3
    case .maturityObserved: before = 7; after = 7
    case .harvest: before = 7; after = 0
    case .store: before = 0; after = 0
    case .reconcile: before = 3; after = 0
    }
    return AgentAgriculturalActionOutcome(
        actionID: AgentAgriculturalActionID(rawValue: "renewable-\(suffix)")!,
        kind: kind, actorID: renewableAgentID, plotID: plotID,
        cellIndex: kind == .store ? nil : 0, position: renewableSoil,
        beforeFingerprint: before, afterFingerprint: after,
        materialDeltas: delta, sourceItemEntityIDs: entities,
        custodyFingerprint: custody, storageLocationID: storage,
        seedReserveQuantity: reserve, physicalSurplusQuantity: surplus,
        sourceObservationEventID: observationEventID,
        civilDate: session.civilDate()!
    )
}

private func applyRenewableConsumption(_ session: inout AgentSimulationSession) {
    let intent = try! session.nextPhysicalFoodConsumptionIntent(for: renewableAgentID)
    let hunger = try! session.state(for: renewableAgentID).needs.hunger
    try! session.applyValidatedPhysicalFoodConsumption(
        AgentValidatedPhysicalFoodConsumptionOutcome(
            consumptionID: intent.consumptionID,
            consumptionSequence: intent.consumptionSequence,
            agentID: renewableAgentID, tick: session.tick,
            canonicalMaterialName: "carrot", quantityConsumed: 1,
            coreHungerPoints: 3, coreSaturation: 3.6,
            normalizedHungerReduction: 0.15, status: .succeeded,
            physicalReceiptID: intent.consumptionID,
            sourceKind: .agentCarriedInventory, sourceSlot: 1,
            hungerBefore: hunger, hungerAfter: max(0, hunger - 0.15)
        )
    )
}

private func tamperedRenewableCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint? {
    do {
        var root = try JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(checkpoint)
        ) as! [String: Any]
        var durable = root["durableState"] as! [String: Any]
        mutate(&durable)
        let durableData = try JSONSerialization.data(
            withJSONObject: durable, options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let state = try AgentCheckpointCodec.decode(
            AgentSessionDurableState.self, from: durableData
        )
        let canonicalDurable = try AgentCheckpointCodec.encode(state)
        let digest = AgentCheckpointDigest.sha256(canonicalDurable)
        let simulationDigest = AgentCheckpointDigest.sha256(
            Data(state.clock.simulationID.rawValue.utf8)
        )
        let checkpointID = "checkpoint-\(simulationDigest.rawValue.prefix(12))"
            + "-t\(state.clock.tick.rawValue)-\(digest.rawValue.prefix(16))"
        root["schemaVersion"] = state.schemaVersion
        root["checkpointID"] = checkpointID
        root["simulationID"] = state.clock.simulationID.rawValue
        root["tick"] = state.clock.tick.rawValue
        root["semanticDigest"] = digest.rawValue
        root["durableState"] = try JSONSerialization.jsonObject(with: canonicalDurable)
        return try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self,
            from: JSONSerialization.data(
                withJSONObject: root, options: [.sortedKeys, .withoutEscapingSlashes]
            )
        )
    } catch {
        return nil
    }
}

func runPebbleAgentsRenewableSubsistenceSmoke() {
    section("Renewable physical subsistence provenance")

    var session = renewableSession("renewable-loop")
    let firstObservation = try! session.recordEcologicalObservation(
        renewableObservation(session, farmland: false)
    )
    let plotID = try! session.planAgriculturalPlot(
        plannerID: renewableAgentID, positions: [renewableSoil], crop: .carrots,
        sourceObservationEventID: firstObservation.causalEventID,
        designatedStorageLocationID: "container:3,64,0"
    )
    check("one-cell carrot plot is a bounded ordinary agriculture plan",
          session.agricultureSnapshot().plots[0].crop == .carrots
            && session.agricultureSnapshot().plots[0].cells.count == 1)

    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .till, suffix: "first-till"
    ))
    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .plant, suffix: "first-plant"
    ))
    let firstMaturity = try! session.recordEcologicalObservation(
        renewableObservation(session, farmland: true, mature: true)
    )
    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .maturityObserved,
        suffix: "first-maturity", observationEventID: firstMaturity.causalEventID
    ))
    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .harvest, suffix: "first-harvest"
    ))
    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .store, suffix: "first-store"
    ))
    check("first physical receipt yields food plus reproductive capacity",
          session.agricultureSnapshot().retainedActions.last(where: {
              $0.outcome.kind == .harvest
          })?.outcome.materialDeltas == [AgentAgriculturalMaterialDelta(
              itemKey: "carrot", quantity: 3, direction: .acquired
          )])

    let hungerBefore = try! session.state(for: renewableAgentID).needs.hunger
    applyRenewableConsumption(&session)
    check("real-food authority records one exact carrot nutrition receipt",
          session.physicalFoodSurvivalSnapshot()?.completedOutcomes.last?
            .canonicalMaterialName == "carrot"
            && session.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity == 1
            && (try! session.state(for: renewableAgentID)).needs.hunger
                == hungerBefore - 0.15)

    let renewalObservation = try! session.recordEcologicalObservation(
        renewableObservation(session, farmland: true)
    )
    let renewed = try! session.renewAgriculturalPlot(
        plotID: plotID, plannerID: renewableAgentID,
        sourceObservationEventID: renewalObservation.causalEventID
    )
    check("second cycle is bound to the retained first harvest receipt",
          renewed.cycleOrdinal == 2
            && renewed.renewalEvidence?.sourcePlantActionIDs
                == [AgentAgriculturalActionID(rawValue: "renewable-first-plant")!]
            && renewed.renewalEvidence?.sourceHarvestActionIDs
                == [AgentAgriculturalActionID(rawValue: "renewable-first-harvest")!]
            && renewed.renewalEvidence?.sourceOutputQuantity == 3
            && renewed.renewalEvidence?.reproductiveInputQuantity == 1)
    _ = try! session.recordAgriculturalActionSuccess(renewableAction(
        session, plotID: plotID, kind: .plant, suffix: "second-plant"
    ))
    let established = session.renewableSubsistenceEvidence().first
    check("derived proof distinguishes established from completed second cycle",
          established?.status == .secondCycleEstablished
            && established?.consumedQuantity == 1
            && established?.reservedOutputQuantity == 1
            && established?.secondInputQuantity == 1
            && established?.secondOutputQuantity == 0)

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema 29 restart preserves the non-mature second cycle exactly",
          checkpoint.schemaVersion == 29
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes())
            && restored.renewableSubsistenceEvidence() == session.renewableSubsistenceEvidence())

    check("re-signed source quantity corruption fails semantically", {
        guard let corrupt = tamperedRenewableCheckpoint(checkpoint, mutate: { durable in
            var agriculture = durable["agricultureState"] as! [String: Any]
            var plots = agriculture["plots"] as! [[String: Any]]
            var evidence = plots[0]["renewalEvidence"] as! [String: Any]
            evidence["sourceOutputQuantity"] = 4
            plots[0]["renewalEvidence"] = evidence
            agriculture["plots"] = plots
            durable["agricultureState"] = agriculture
        }) else { return false }
        do { _ = try AgentSimulationSession.restoring(corrupt); return false }
        catch AgentAgricultureError.invalidState { return true }
        catch AgentCheckpointError.invalidBound { return true }
        catch { return String(describing: error).contains("agriculture") }
    }())
    check("duplicate renewal source receipt fails closed", {
        guard let corrupt = tamperedRenewableCheckpoint(checkpoint, mutate: { durable in
            var agriculture = durable["agricultureState"] as! [String: Any]
            var plots = agriculture["plots"] as! [[String: Any]]
            var evidence = plots[0]["renewalEvidence"] as! [String: Any]
            let source = evidence["sourceHarvestActionIDs"] as! [String]
            evidence["sourceHarvestActionIDs"] = [source[0], source[0]]
            plots[0]["renewalEvidence"] = evidence
            agriculture["plots"] = plots
            durable["agricultureState"] = agriculture
        }) else { return false }
        return (try? AgentSimulationSession.restoring(corrupt)) == nil
    }())

    var replayed = restored
    var recorder = try! AgentReplayRecorder(checkpoint: checkpoint, session: replayed)
    _ = try! recorder.apply(.recordEcologicalObservation(
        renewableObservation(replayed, farmland: true, mature: true)
    ), to: &replayed)
    let secondMaturityEvent = replayed.ecologicalObservations(
        for: renewableAgentID
    ).first!.causalEventID
    _ = try! recorder.apply(.recordAgriculturalAction(renewableAction(
        replayed, plotID: plotID, kind: .maturityObserved,
        suffix: "second-maturity", observationEventID: secondMaturityEvent
    )), to: &replayed)
    _ = try! recorder.apply(.recordAgriculturalAction(renewableAction(
        replayed, plotID: plotID, kind: .harvest, suffix: "second-harvest"
    )), to: &replayed)
    _ = try! recorder.apply(.recordAgriculturalAction(renewableAction(
        replayed, plotID: plotID, kind: .store, suffix: "second-store",
        storedQuantity: 3
    )), to: &replayed)
    let completed = replayed.renewableSubsistenceEvidence().first
    check("second physical harvest derives renewable completion exactly once",
          completed?.status == .renewableCycleCompleted
            && completed?.secondHarvestActionIDs.count == 1
            && completed?.secondOutputQuantity == 3
            && replayed.agricultureSnapshot().completedCycleCount == 2)

    let binding = try! AgentObserverWorldBinding(
        worldID: "renewable-world", storageIdentity: "memory:renewable",
        seed: 46, dimension: 0, observedWorldTick: 200
    )
    let observerBefore = try! replayed.durableStateBytes()
    let observer = replayed.observerSnapshot(worldBinding: binding)
    check("Observer schema 7 exposes only the derived renewable proof",
          observer.header.schemaVersion == 7
            && observer.renewableSubsistence?.first == completed
            && (try! replayed.durableStateBytes()) == observerBefore)

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "renewable-replay")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: checkpoint, journal: journal
    )
    check("schema 29 replay is byte exact after second harvest",
          recorder.schemaVersion == 29 && replay.report.verified
            && replay.report.schemaVersion == 29
            && (try! replay.session.durableStateBytes())
                == (try! replayed.durableStateBytes()))
}
