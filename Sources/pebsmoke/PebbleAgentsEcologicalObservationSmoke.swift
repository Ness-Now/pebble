import Foundation
import PebbleAgents

private let observationOrigin = AgentPosition(x: 0, y: 64, z: 0)

private func observationAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "ecological observation fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func observationBase(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(observationAgent),
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 8_192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: observationOrigin,
        receptionPosition: observationOrigin
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
}
