import Foundation
@_spi(Testing) import PebbleAgents

private let wildOrigin = AgentPosition(x: 0, y: 64, z: 0)
private let wildLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8, maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1, reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1, maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32, maximumParentBirthCount: 16
)

private func wildAgent(_ index: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: index, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(index)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.5, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "wild subsistence fixture", startedAtTick: 0, urgency: 0),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func historicalActorSession(
    _ id: String, survivors: Set<Int>, retainedDeaths: Int = 32
) -> AgentSimulationSession {
    let agents = (0..<24).map { index in
        let position = AgentPosition(x: index, y: 64, z: 0)
        let lethal = !survivors.contains(index)
        return AgentSessionAgentState(
            id: "agent_\(index)", state: "idle", position: position,
            needs: AgentNeeds(hunger: lethal ? 1 : 0, fatigue: 0, curiosity: 0, safety: 1),
            health: lethal ? 10 : 100, fear: 0, homePosition: position, nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "retained identity fixture", startedAtTick: 0, urgency: 0),
            lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
            ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
            goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
            actionEffectCount: 0, movementCount: 0, totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
            survivalProgress: AgentSurvivalProgress(
                status: lethal ? .starving : .stable,
                consecutiveCriticalHungerTicks: lethal ? 2 : 0
            )
        )
    }
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 14, memoryPolicy: .bounded(maxEntries: 128)),
        agents: agents, simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: wildOrigin, receptionPosition: wildOrigin,
        configuration: try! AgentPopulationConfiguration(maximumActivePopulation: 30)
    )
    try! session.setLifecycleEnabled(true, configuration: wildLifecycle)
    try! session.setKinshipEnabled(true)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    try! session.setAutonomousActivityEnabled(true)
    try! session.setMortalityEnabled(true, configuration: try! AgentMortalityConfiguration(
        maximumDeathsPerTick: 30, maximumRetainedDeathRecords: retainedDeaths
    ))
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
    return session
}

private func historicalActivityCandidate(_ index: Int, actor: Int = 16) -> AgentAutonomousActivityCandidate {
    AgentAutonomousActivityCandidate(
        candidateID: "historical-\(actor)-\(index)", actorID: AgentID(rawValue: "agent_\(actor)")!,
        domain: .wildGathering, actionKey: "wildGathering", stableReference: "retained-\(index)",
        target: AgentPosition(x: index, y: 64, z: 0),
        logicalTargetKey: "plant-\(index)", materialFingerprint: "ripe-\(index)",
        source: .opportunity, priorityBand: 30, urgency: 70, distance: 1, observedAtTick: 0
    )
}

/// Re-sign the envelope after attacks; no outer-checksum-only rejection counts.
private func retainedIdentityAttackRefused(
    _ checkpoint: AgentSessionCheckpoint, mutate: (inout [String: Any]) -> Void
) -> Bool {
    var root = try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(checkpoint)) as! [String: Any]
    var state = root["durableState"] as! [String: Any]
    mutate(&state)
    let decoded = try! AgentCheckpointCodec.decode(AgentSessionDurableState.self,
        from: JSONSerialization.data(withJSONObject: state))
    let bytes = try! AgentCheckpointCodec.encode(decoded)
    let digest = AgentCheckpointDigest.sha256(bytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(decoded.clock.simulationID.rawValue.utf8))
    root["durableState"] = try! JSONSerialization.jsonObject(with: bytes)
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(decoded.clock.tick.rawValue)-\(digest.rawValue.prefix(16))"
    let attacked = try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: root))
    do { _ = try AgentSimulationSession.restoring(attacked); return false }
    catch { return (error as? AgentCheckpointError) != .semanticDigestMismatch }
}

func runPebbleAgentsRetainedHistoricalIdentitySmoke() {
    section("finalized mortality and authenticated retained actor history")
    let actor = AgentID(rawValue: "agent_16")!
    let survivor = AgentID(rawValue: "agent_18")!
    var session = historicalActorSession("historical-actor-seed14", survivors: [9, 18])
    _ = try! session.recordEcologicalObservation(wildObservation(session, observer: actor.rawValue))
    let context = AgentSubsistenceDecisionContext(actorID: actor,
        fishingRodAvailable: false, huntingWeaponAvailable: false, agricultureAvailable: false)
    let completed = try! session.selectWildSubsistenceOpportunity(context)
    let record = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: completed, suffix: "historical-founder", item: "sweet_berries"
    ))
    let selected = try! session.selectWildSubsistenceOpportunity(context)
    for index in 0..<4 {
        let activity = try! session.selectAutonomousActivities([historicalActivityCandidate(index)])[0]
        _ = try! session.recordAutonomousActivityOutcome(AgentAutonomousActivityOutcome(
            activityID: activity.activityID, actorID: actor, lifecycle: .blocked,
            completedAtTick: session.tick, reason: "navigationReplanLimit"
        ))
    }
    let active = try! session.selectAutonomousActivities([historicalActivityCandidate(5)])[0]
    let survivorActive = try! session.selectAutonomousActivities([
        historicalActivityCandidate(5), historicalActivityCandidate(7, actor: 18)
    ]).first { $0.candidate.actorID == survivor }!
    let preDeath = try! session.makeCheckpoint()
    let retainedBefore = session.wildSubsistenceSnapshot().retainedOutcomes
    let cooldownsBefore = session.autonomousActivitySnapshot().cooldowns
    _ = try! session.advanceTick()
    check("seed14 boundary finalizes 22 founders through mortality with exact survivors",
        session.mortalitySnapshot().totalDeathCount == 22
            && session.expectedActiveAgentIDs() == [AgentID(rawValue: "agent_9")!, survivor].sorted())
    check("founder material success remains exact retained evidence after death",
        session.wildSubsistenceSnapshot().retainedOutcomes == retainedBefore
            && retainedBefore[0] == record)
    check("death interrupts selected subsistence without inventing an outcome",
        session.wildSubsistenceSnapshot().opportunities.first { $0.opportunityID == selected.opportunityID }?.status == .interrupted
            && !session.wildSubsistenceSnapshot().opportunities.contains { $0.actorID == actor && !$0.status.isTerminal })
    check("dead autonomous executor is interrupted and four cooldowns are retained exactly",
        session.activeAutonomousActivity(for: actor) == nil
            && session.autonomousActivitySnapshot().cooldowns == cooldownsBefore
            && session.autonomousActivitySnapshot().recentRecords.last?.outcome.lifecycle == .interrupted)
    check("unrelated living autonomous activity remains exact across finalization",
        session.activeAutonomousActivity(for: survivor) == survivorActive)
    let checkpoint = try? session.makeCheckpoint()
    check("seed14 native checkpoint capture admits legitimate history", checkpoint != nil)
    guard let checkpoint else { return }
    let decoded = try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
        from: AgentCheckpointCodec.encode(checkpoint))
    var restored = try! AgentSimulationSession.restoring(decoded)
    check("fresh codec restore preserves exact bytes and schema without migration",
        (try! restored.durableStateBytes()) == (try! session.durableStateBytes())
            && decoded.schemaVersion == preDeath.schemaVersion)
    check("finalized founder cannot select wild work", {
        do { _ = try restored.selectWildSubsistenceOpportunity(context); return false }
        catch { return true }
    }())
    check("finalized founder cannot select autonomous execution", {
        do { _ = try restored.selectAutonomousActivities([historicalActivityCandidate(6)]); return false }
        catch { return true }
    }())
    _ = try! restored.recordEcologicalObservation(wildObservation(restored, observer: survivor.rawValue))
    let survivingSelection = try? restored.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(actorID: survivor, fishingRodAvailable: false,
            huntingWeaponAvailable: false, agricultureAvailable: false))
    check("living survivor continues ordinary wild selection and checkpoint validation",
        survivingSelection?.actorID == survivor && survivingSelection?.strategy == .wildGathering
            && restored.activeAutonomousActivity(for: survivor) == survivorActive
            && (try? restored.makeCheckpoint()) != nil)

    for forged in ["unknown_actor", "agent_29"] {
        check("forged retained wild actor \(forged) refuses", retainedIdentityAttackRefused(checkpoint) { state in
            var wild = state["wildSubsistenceState"] as! [String: Any]
            var opportunities = wild["opportunities"] as! [[String: Any]]
            opportunities[0]["actorID"] = forged
            wild["opportunities"] = opportunities; state["wildSubsistenceState"] = wild
        })
        check("forged cooldown actor \(forged) refuses", retainedIdentityAttackRefused(checkpoint) { state in
            var autonomy = state["autonomousActivityState"] as! [String: Any]
            var cooldowns = autonomy["cooldowns"] as! [[String: Any]]
            cooldowns[0]["actorID"] = forged
            autonomy["cooldowns"] = cooldowns; state["autonomousActivityState"] = autonomy
        })
    }
    check("active wild opportunity for finalized actor refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var wild = state["wildSubsistenceState"] as! [String: Any]
        var opportunities = wild["opportunities"] as! [[String: Any]]
        opportunities[0]["status"] = "selected"
        wild["opportunities"] = opportunities; state["wildSubsistenceState"] = wild
    })
    check("active autonomous executor for finalized actor refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var autonomy = state["autonomousActivityState"] as! [String: Any]
        autonomy["activeActivities"] = [try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(active))]
        state["autonomousActivityState"] = autonomy
    })
    check("future wild causal reference refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var wild = state["wildSubsistenceState"] as! [String: Any]
        var opportunities = wild["opportunities"] as! [[String: Any]]
        var event = opportunities[0]["selectedEventID"] as! [String: Any]
        event["sequence"] = session.causalLedgerSnapshot().summary.latestSequence + 1
        opportunities[0]["selectedEventID"] = event
        wild["opportunities"] = opportunities; state["wildSubsistenceState"] = wild
    })
    check("wild event after finalized death refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var wild = state["wildSubsistenceState"] as! [String: Any]
        var opportunities = wild["opportunities"] as! [[String: Any]]
        opportunities[0]["selectedEventID"] = try! JSONSerialization.jsonObject(with:
            AgentCheckpointCodec.encode(session.mortalitySnapshot().records.first { $0.agentID == actor }!.deathEventID))
        wild["opportunities"] = opportunities; state["wildSubsistenceState"] = wild
    })
    check("post-death cooldown creation refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var autonomy = state["autonomousActivityState"] as! [String: Any]
        var cooldowns = autonomy["cooldowns"] as! [[String: Any]]
        cooldowns[0]["untilTick"] = 10_000
        autonomy["cooldowns"] = cooldowns; state["autonomousActivityState"] = autonomy
    })
    check("retained wild uniqueness still refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var wild = state["wildSubsistenceState"] as! [String: Any]
        var opportunities = wild["opportunities"] as! [[String: Any]]
        opportunities.append(opportunities[0])
        wild["opportunities"] = opportunities; state["wildSubsistenceState"] = wild
    })
    check("cooldown numerical bound still refuses", retainedIdentityAttackRefused(checkpoint) { state in
        var autonomy = state["autonomousActivityState"] as! [String: Any]
        let cooldown = (autonomy["cooldowns"] as! [[String: Any]])[0]
        autonomy["cooldowns"] = Array(repeating: cooldown, count: 257)
        state["autonomousActivityState"] = autonomy
    })

    for retainedDeaths in [32, 1] {
        var extinct = historicalActorSession("historical-actor-extinct-\(retainedDeaths)", survivors: [], retainedDeaths: retainedDeaths)
        // The legacy v30 fixture predates empty-population restore support.
        // Exercise the native current format using authoritative World time.
        try! extinct.rebasePhysiologicalTime(toWorldTick: 0)
        try! extinct.advancePhysiologicalTime(toWorldTick: 1_200)
        _ = try! extinct.recordEcologicalObservation(wildObservation(extinct, observer: actor.rawValue))
        let extinctOpportunity = try! extinct.selectWildSubsistenceOpportunity(context)
        let extinctRecord = try! extinct.recordWildSubsistenceOutcome(wildOutcome(
            extinct, opportunity: extinctOpportunity, suffix: "extinct-founder", item: "sweet_berries"
        ))
        for index in 0..<4 {
            let activity = try! extinct.selectAutonomousActivities([historicalActivityCandidate(index)])[0]
            _ = try! extinct.recordAutonomousActivityOutcome(AgentAutonomousActivityOutcome(
                activityID: activity.activityID, actorID: actor, lifecycle: .blocked,
                completedAtTick: 0, reason: "navigationReplanLimit"))
        }
        _ = try! extinct.advanceTick()
        check("wild terminal history survives full or compacted mortality authority (retention \(retainedDeaths))",
            extinct.wildSubsistenceSnapshot().retainedOutcomes == [extinctRecord]
                && !extinct.wildSubsistenceSnapshot().opportunities.contains { !$0.status.isTerminal })
        let saved = try? extinct.makeCheckpoint()
        check("seed101 extinction with four retained cooldowns captures (death retention \(retainedDeaths))",
            extinct.expectedActiveAgentIDs().isEmpty && extinct.mortalitySnapshot().totalDeathCount == 24
                && extinct.autonomousActivitySnapshot().activeActivities.isEmpty
                && extinct.autonomousActivitySnapshot().cooldowns.count == 4 && saved != nil)
        var restoredBytes: Data?
        if let saved {
            do {
                restoredBytes = try AgentSimulationSession.restoring(
                    AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
                        from: AgentCheckpointCodec.encode(saved))).durableStateBytes()
            } catch {
                print("EXTINCT_IDENTITY_RESTORE_REFUSAL retention=\(retainedDeaths) \(error)")
            }
        }
        check("extinct decode and restore is exact (death retention \(retainedDeaths))",
            restoredBytes == (try? extinct.durableStateBytes()))
    }
}

private func wildBase(_ id: String) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 46, memoryPolicy: .bounded(maxEntries: 128)),
        agents: (0..<3).map(wildAgent),
        simulationID: AgentSimulationID(rawValue: id)!,
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(settlementAnchor: wildOrigin, receptionPosition: wildOrigin)
    try! session.setLifecycleEnabled(true, configuration: wildLifecycle)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.useLegacyCognitivePhysiologyReplayFixture(
        schemaVersion: AgentCheckpointSchema.independentEcologicalReceiptVersion
    )
    return session
}

private func wildObservation(
    _ session: AgentSimulationSession,
    observer: String = "agent_0",
    fishing: Bool = true,
    hunting: Bool = true,
    gathering: Bool = true
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    let origin = AgentPosition(x: observer == "agent_0" ? 0 : 1, y: 64, z: 0)
    let plants = gathering ? [AgentPlantObservation(
        plantKey: "sweet_berry_bush", position: AgentPosition(x: 1, y: 64, z: 0),
        renewability: .knownRenewable
    )] : []
    let animals = hunting ? [AgentAnimalObservation(
        speciesKey: "chicken", position: AgentPosition(x: 2, y: 64, z: 0),
        count: 1, lifeStage: .adult, breedableAffordanceObservable: false
    )] : []
    let fishingValues = fishing ? [AgentFishingAffordance(
        position: AgentPosition(x: 1, y: 63, z: 0), waterKey: "water", candidate: true
    )] : []
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observer)!, origin: origin,
        worldContextKey: "world-seed-46", dimensionKey: "overworld",
        observedAtSimulationTick: session.tick, physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(biomeKey: "plains", position: origin),
        water: fishingValues.map { AgentWaterAffordance(fluidKey: "water", position: $0.position, sourceBlock: true) },
        soils: [], crops: [], plants: plants, animals: animals, fishing: fishingValues,
        weather: AgentWeatherObservation(kind: .clear, raining: false, thundering: false),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120, dayTime: 120, timeOfDay: .day, daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: 4, cellsConsidered: 405, worldReads: 405, chunksTouched: 1,
            chunksUnavailable: 0, entitiesConsidered: animals.count,
            resultsEmitted: 3 + fishingValues.count + plants.count
                + animals.count + fishingValues.count,
            cacheHits: 0, cacheMisses: 1, completion: .complete
        ),
        expiresAtSimulationTick: session.tick + configuration.dynamicFreshnessTicks
    )
}

private func wildMaterial(_ key: String, count: Int = 1) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: AgentMaterialIdentitySnapshot(
            itemKey: key, damage: 0, enchantments: [], label: nil, canonicalDataJSON: "{}"
        ),
        count: count
    )
}

private func wildOutcome(
    _ session: AgentSimulationSession,
    opportunity: AgentSubsistenceOpportunity,
    suffix: String,
    status: AgentSubsistenceOutcomeStatus = .succeeded,
    item: String = "cod"
) -> AgentSubsistenceOutcome {
    AgentSubsistenceOutcome(
        attemptID: AgentSubsistenceAttemptID(rawValue: "wild-attempt-\(suffix)")!,
        opportunityID: opportunity.opportunityID, actorID: opportunity.actorID,
        strategy: opportunity.strategy, targetKey: opportunity.targetKey,
        targetPosition: opportunity.lastObservedPosition,
        sourceObservationEventID: opportunity.sourceObservationEventID,
        status: status,
        physicalCausalIDs: status == .succeeded ? [100 + suffix.count] : [],
        acquiredItems: status == .succeeded ? [wildMaterial(item)] : [],
        custodyFingerprint: status == .succeeded ? "agent-after-\(suffix)" : nil,
        attribution: status == .succeeded ? "core-physical-\(suffix)" : nil,
        completedAtTick: session.tick
    )
}

func runPebbleAgentsWildSubsistenceSmoke() {
    section("PebbleAgents bounded wild subsistence")

    check(
        "wild source viability shares the canonical gatherable plant policy",
        AgentWildSubsistenceMaterialPolicy.isGatherablePlant(
            "sweet_berry_bush"
        ) && AgentWildSubsistenceMaterialPolicy.isGatherablePlant("pumpkin")
    )
    check(
        "locally observed non-gatherable flora is not an executable source",
        !AgentWildSubsistenceMaterialPolicy.isGatherablePlant("dandelion")
            && !AgentWildSubsistenceMaterialPolicy.isGatherablePlant("oak_sapling")
    )
    check("WildSubsistence gate is default off", !wildBase("wild-off").wildSubsistenceEnabled)
    check("activation dependencies are atomic", {
        var noObservation = try! AgentSimulationSession(
            configuration: try! AgentSessionConfiguration(
                seed: 46, memoryPolicy: .bounded(maxEntries: 128)
            ),
            agents: (0..<3).map(wildAgent), simulationID: AgentSimulationID(rawValue: "wild-deps")!,
            causalLedgerPolicy: .bounded(maxEvents: 2048)
        )
        try! noObservation.initializePopulationRegistry(settlementAnchor: wildOrigin, receptionPosition: wildOrigin)
        try! noObservation.setLifecycleEnabled(true, configuration: wildLifecycle)
        try! noObservation.setSkillsEnabled(true)
        let before = try! noObservation.durableStateBytes()
        do {
            try noObservation.setWildSubsistenceEnabled(true)
            return false
        } catch AgentSessionError.wildSubsistence(.ecologicalObservationRequired) {
            return !noObservation.wildSubsistenceEnabled && (try! noObservation.durableStateBytes()) == before
        } catch { return false }
    }())

    var session = wildBase("wild-contract")
    _ = try! session.recordEcologicalObservation(wildObservation(session))
    try! session.setAgricultureEnabled(true)
    let v13 = try! session.makeCheckpoint()
    let v13Restored = try! AgentSimulationSession.restoring(v13)
    check("schema 30 loads with no retroactive wild history",
          v13.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && !v13Restored.wildSubsistenceEnabled
            && (try! v13Restored.durableStateBytes()) == (try! session.durableStateBytes()))
    let coarseBefore = session.snapshot()
    try! session.setWildSubsistenceEnabled(true)
    check("schema 30 activation starts empty and agriculture is not an activation dependency",
          session.durableState().schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && session.wildSubsistenceSnapshot().opportunities.isEmpty
            && session.wildSubsistenceSnapshot().retainedOutcomes.isEmpty)

    let actor0 = AgentID(rawValue: "agent_0")!
    let noRod = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 50
    ))
    check("equipment ablation removes fishing and hunting",
          noRod.map(\.strategy) == [.wildGathering])
    let multi = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: true, huntingWeaponAvailable: true,
        agricultureAvailable: true, subsistencePressure: 50
    ))
    check("fresh local evidence makes four distinct strategies comparable",
          Set(multi.map(\.strategy)) == Set(AgentSubsistenceStrategy.allCases))
    check("deterministic local scoring selects a cause-backed strategy",
          multi.first?.strategy == .agriculture && multi.first?.reason.contains("managed plot") == true)

    let fishContext = AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: true, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 80
    )
    let fishing = try! session.selectWildSubsistenceOpportunity(fishContext)
    let observationPractice = session.practiceUnits(agentID: actor0, domain: .fishing)
    check("selection/casting intent grants zero practice", observationPractice == 0 && fishing.strategy == .fishing)
    let fishRecord = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: fishing, suffix: "fish", item: "cod"
    ))
    check("real acquired fishing result grants exactly one fishing practice",
          fishRecord.skillPracticeEventID != nil
            && session.practiceUnits(agentID: actor0, domain: .fishing) == observationPractice + 1)
    let duplicateBytes = try! session.durableStateBytes()
    do {
        _ = try session.recordWildSubsistenceOutcome(wildOutcome(
            session, opportunity: fishing, suffix: "fish", item: "cod"
        ))
        check("duplicate fishing result is idempotent", false)
    } catch AgentSessionError.wildSubsistence(.duplicateAttempt) {
        check("duplicate fishing result is idempotent", (try! session.durableStateBytes()) == duplicateBytes)
    } catch { check("duplicate fishing result is idempotent", false, "\(error)") }

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: true, gathering: false))
    let hunt = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: true,
        agricultureAvailable: false, subsistencePressure: 60
    ))
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: hunt, suffix: "hunt", item: "chicken"
    ))
    check("attributed material hunt grants exactly one hunting practice",
          hunt.strategy == .hunting && session.practiceUnits(agentID: actor0, domain: .hunting) == 1)

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: false, gathering: true))
    let gather = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false, subsistencePressure: 60
    ))
    let forageBefore = session.practiceUnits(agentID: actor0, domain: .foraging)
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: gather, suffix: "gather", item: "sweet_berries"
    ))
    check("physical wild gather reuses foraging and grants one practice",
          gather.strategy == .wildGathering
            && session.practiceUnits(agentID: actor0, domain: .foraging) == forageBefore + 1)

    _ = try! session.recordEcologicalObservation(wildObservation(session, fishing: false, hunting: true, gathering: false))
    let failedHunt = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: true,
        agricultureAvailable: false
    ))
    let huntPractice = session.practiceUnits(agentID: actor0, domain: .hunting)
    _ = try! session.recordWildSubsistenceOutcome(wildOutcome(
        session, opportunity: failedHunt, suffix: "failed-hunt", status: .failed
    ))
    check("failed physical hunt grants zero practice",
          session.practiceUnits(agentID: actor0, domain: .hunting) == huntPractice)

    _ = try! session.recordEcologicalObservation(wildObservation(
        session, fishing: false, hunting: false, gathering: true
    ))
    _ = try! session.recordEcologicalObservation(wildObservation(
        session, observer: "agent_1", fishing: false, hunting: false, gathering: true
    ))
    let actor1 = AgentID(rawValue: "agent_1")!
    let reservedBy0 = try! session.selectWildSubsistenceOpportunity(AgentSubsistenceDecisionContext(
        actorID: actor0, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false
    ))
    let actor1Choices = try! session.eligibleSubsistenceStrategies(AgentSubsistenceDecisionContext(
        actorID: actor1, fishingRodAvailable: false, huntingWeaponAvailable: false,
        agricultureAvailable: false
    ))
    check("one-shot wild target reservation prevents duplicate claims",
          reservedBy0.strategy == .wildGathering && actor1Choices.allSatisfy { $0.strategy != .wildGathering })

    var teaching = wildBase("wild-teaching")
    try! teaching.setWildSubsistenceEnabled(true)
    var latestTeacherSuccess: AgentCausalEventID?
    for index in 0..<3 {
        _ = try! teaching.recordEcologicalObservation(wildObservation(
            teaching, fishing: true, hunting: false, gathering: false
        ))
        let opportunity = try! teaching.selectWildSubsistenceOpportunity(
            AgentSubsistenceDecisionContext(
                actorID: actor0, fishingRodAvailable: true,
                huntingWeaponAvailable: false, agricultureAvailable: false
            )
        )
        let record = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
            teaching, opportunity: opportunity, suffix: "teacher-fish-\(index)", item: "cod"
        ))
        latestTeacherSuccess = record.subsistenceEventID
    }
    try! teaching.setTeachingEnabled(true)
    let engagement = try! teaching.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "wild-fishing-apprenticeship", studentID: actor1,
            domain: .fishing, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(teacherID: actor0, accepts: true)],
            requestedAtTick: teaching.tick
        )
    )!
    _ = try! teaching.advanceTick()
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, fishing: true, hunting: false, gathering: false
    ))
    let demonstratedFishing = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor0, fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false
        )
    )
    latestTeacherSuccess = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: demonstratedFishing,
        suffix: "teacher-fish-demonstrated", item: "cod"
    )).subsistenceEventID
    let teacherPosition = try! teaching.state(for: actor0).position
    let studentPosition = try! teaching.state(for: actor1).position
    let distance = abs(teacherPosition.x - studentPosition.x)
        + abs(teacherPosition.y - studentPosition.y)
        + abs(teacherPosition.z - studentPosition.z)
    let physical = teaching.configuration.physicalChannelConfiguration
    let studentBeforeExposure = teaching.practiceUnits(agentID: actor1, domain: .fishing)
    _ = try! teaching.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: engagement.apprenticeshipID,
        teacherID: actor0, studentID: actor1, domain: .fishing,
        sourceSuccessEventID: latestTeacherSuccess!,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: teaching.tick
    ))
    check("fishing Teaching exposure grants zero free skill",
          teaching.practiceUnits(agentID: actor1, domain: .fishing) == studentBeforeExposure)
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, observer: "agent_1", fishing: true, hunting: false, gathering: false
    ))
    let studentFishing = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor1, fishingRodAvailable: true,
            huntingWeaponAvailable: false, agricultureAvailable: false
        )
    )
    _ = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: studentFishing, suffix: "student-fish", item: "cod"
    ))
    check("student own material fishing success grants exactly one practice",
          teaching.practiceUnits(agentID: actor1, domain: .fishing) == studentBeforeExposure + 1)

    var latestHuntSuccess: AgentCausalEventID?
    for index in 0..<3 {
        _ = try! teaching.recordEcologicalObservation(wildObservation(
            teaching, fishing: false, hunting: true, gathering: false
        ))
        let opportunity = try! teaching.selectWildSubsistenceOpportunity(
            AgentSubsistenceDecisionContext(
                actorID: actor0, fishingRodAvailable: false,
                huntingWeaponAvailable: true, agricultureAvailable: false
            )
        )
        let record = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
            teaching, opportunity: opportunity, suffix: "teacher-hunt-\(index)", item: "chicken"
        ))
        latestHuntSuccess = record.subsistenceEventID
    }
    let huntingEngagement = try! teaching.selectMentorAndStartApprenticeship(
        AgentMentorSelectionRequest(
            requestID: "wild-hunting-apprenticeship", studentID: actor1,
            domain: .hunting, studentAccepts: true,
            candidates: [AgentMentorCandidateConsent(teacherID: actor0, accepts: true)],
            requestedAtTick: teaching.tick
        )
    )!
    _ = try! teaching.advanceTick()
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, fishing: false, hunting: true, gathering: false
    ))
    let demonstratedHunting = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor0, fishingRodAvailable: false,
            huntingWeaponAvailable: true, agricultureAvailable: false
        )
    )
    latestHuntSuccess = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: demonstratedHunting,
        suffix: "teacher-hunt-demonstrated", item: "chicken"
    )).subsistenceEventID
    let studentHuntingBeforeExposure = teaching.practiceUnits(agentID: actor1, domain: .hunting)
    _ = try! teaching.recordTeachingDemonstration(AgentTeachingObservation(
        apprenticeshipID: huntingEngagement.apprenticeshipID,
        teacherID: actor0, studentID: actor1, domain: .hunting,
        sourceSuccessEventID: latestHuntSuccess!,
        teacherPosition: teacherPosition, studentPosition: studentPosition,
        distanceManhattan: distance,
        soundClarity: physical.soundClarity(
            distanceManhattan: distance, opaqueOcclusionCount: 0
        ),
        gestureClarity: physical.gestureClarity(
            distanceManhattan: distance, lineOfSight: true
        ),
        opaqueOcclusionCount: 0, lineOfSight: true, chunksReady: true,
        observedAtTick: teaching.tick
    ))
    check("hunting Teaching exposure grants zero free skill",
          teaching.practiceUnits(agentID: actor1, domain: .hunting)
            == studentHuntingBeforeExposure)
    _ = try! teaching.recordEcologicalObservation(wildObservation(
        teaching, observer: "agent_1", fishing: false, hunting: true, gathering: false
    ))
    let studentHunting = try! teaching.selectWildSubsistenceOpportunity(
        AgentSubsistenceDecisionContext(
            actorID: actor1, fishingRodAvailable: false,
            huntingWeaponAvailable: true, agricultureAvailable: false
        )
    )
    _ = try! teaching.recordWildSubsistenceOutcome(wildOutcome(
        teaching, opportunity: studentHunting, suffix: "student-hunt", item: "chicken"
    ))
    check("student own attributed hunt grants exactly one practice",
          teaching.practiceUnits(agentID: actor1, domain: .hunting)
            == studentHuntingBeforeExposure + 1)

    check("live wild outcomes create zero coarse inventory credit",
          session.snapshot().campStock == coarseBefore.campStock
            && session.snapshot().agents.map(\.resourceInventory)
                == coarseBefore.agents.map(\.resourceInventory)
            && !session.localEcologyEnabled)
    check("completed outcomes are bounded non-spendable history",
          session.wildSubsistenceSnapshot().retainedOutcomes.count == 4
            && session.wildSubsistenceSnapshot().retainedOutcomes.allSatisfy {
                $0.outcome.acquiredItems.isEmpty || $0.outcome.custodyFingerprint != nil
            })

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("schema 30 completed history checkpoint is byte exact",
          checkpoint.schemaVersion
            == AgentCheckpointSchema.independentEcologicalReceiptVersion
            && (try! restored.durableStateBytes()) == (try! session.durableStateBytes()))
    let encodedCheckpoint = try! AgentCheckpointCodec.encode(checkpoint)
    let decodedCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: encodedCheckpoint
    )
    let decodedReport = try! AgentSimulationSession.validate(decodedCheckpoint)
    let decodedRestored = try! AgentSimulationSession.restoring(decodedCheckpoint)
    check("multi-strategy wild success counts survive checkpoint codec byte exactly",
          decodedReport.valid
            && decodedRestored.wildSubsistenceSnapshot().successfulCounts
                == session.wildSubsistenceSnapshot().successfulCounts
            && (try! decodedRestored.durableStateBytes())
                == (try! session.durableStateBytes()))

    var replayed = try! AgentSimulationSession.restoring(v13)
    var recorder = try! AgentReplayRecorder(checkpoint: v13, session: replayed)
    _ = try! recorder.apply(.setWildSubsistenceEnabled(true, configuration: .live), to: &replayed)
    _ = try! recorder.apply(.selectWildSubsistenceOpportunity(fishContext), to: &replayed)
    let replayOpportunity = replayed.wildSubsistenceSnapshot().opportunities.last!
    _ = try! recorder.apply(.recordWildSubsistenceOutcome(wildOutcome(
        replayed, opportunity: replayOpportunity, suffix: "replay-fish", item: "cod"
    )), to: &replayed)
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "wild-replay")!)
    let replay = try! AgentSessionReplayer.replay(checkpoint: v13, journal: journal)
    check("schema 30 replay reproduces wild state, causal ledger, skills, and digest",
          replay.report.verified
            && replay.report.schemaVersion
                == AgentReplaySchema.independentEcologicalReceiptVersion
            && (try! replay.session.durableStateBytes()) == (try! replayed.durableStateBytes())
            && replay.session.wildSubsistenceSnapshot().digest == replayed.wildSubsistenceSnapshot().digest)
}
