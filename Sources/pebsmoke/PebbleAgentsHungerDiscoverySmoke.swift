import Foundation
@_spi(Testing) import PebbleAgents

private let hungerDiscoveryOrigin = AgentPosition(x: 0, y: 64, z: 0)
private let hungerDiscoveryLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 64,
    maximumRetainedPlanRecords: 64,
    maximumParentBirthCount: 16
)

private func hungerDiscoveryAgent(
    _ id: String = "agent_0",
    hunger: Double,
    goal: AgentGoalKind = .idle,
    health: Int = 100,
    position: AgentPosition = hungerDiscoveryOrigin
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0, safety: 1),
        health: health,
        fear: 0,
        homePosition: hungerDiscoveryOrigin,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: goal,
            reason: "I10 isolated owner fixture",
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

private func hungerDiscoverySession(
    _ id: String,
    hunger: Double,
    goal: AgentGoalKind = .idle,
    survival: AgentSurvivalConfiguration = .live,
    health: Int = 100,
    peers: [AgentSessionAgentState] = []
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: [hungerDiscoveryAgent(hunger: hunger, goal: goal, health: health)] + peers,
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: hungerDiscoveryOrigin,
        receptionPosition: hungerDiscoveryOrigin
    )
    try! session.setLifecycleEnabled(true, configuration: hungerDiscoveryLifecycle)
    try! session.setSkillsEnabled(true)
    try! session.setEcologicalObservationEnabled(true)
    try! session.setWildSubsistenceEnabled(true)
    session.setSurvivalEnabled(true)
    try! session.setPhysicalFoodSurvivalEnabled(true)
    try! session.setAutonomousActivityEnabled(true)
    return session
}

private func hungerDiscoveryEvidence(
    material: String = "sweet_berries",
    fingerprint: String = "source-fingerprint-stage-3"
) -> AgentObservedEdibleSourceEvidence {
    AgentObservedEdibleSourceEvidence(
        canonicalMaterialName: material,
        physicalSourceFingerprint: fingerprint
    )
}

private func hungerDiscoveryObservation(
    _ session: AgentSimulationSession,
    observerID: String = "agent_0",
    origin: AgentPosition = hungerDiscoveryOrigin,
    target: AgentPosition = AgentPosition(x: 1, y: 64, z: 0),
    evidence: AgentObservedEdibleSourceEvidence? = hungerDiscoveryEvidence(),
    completion: AgentEcologicalScanCompletion = .complete,
    expiresAtTick: Int? = nil,
    plantKey: String = "sweet_berry_bush"
) -> AgentEcologicalObservation {
    let configuration = session.ecologicalObservationSnapshot().configuration!
    return AgentEcologicalObservation(
        observerID: AgentID(rawValue: observerID)!,
        origin: origin,
        worldContextKey: "world-seed-46",
        dimensionKey: "overworld",
        observedAtSimulationTick: session.tick,
        physicalWorldTick: 120,
        civilDate: session.civilDate()!,
        biome: AgentBiomeObservation(
            biomeKey: "taiga",
            position: origin
        ),
        water: [],
        soils: [],
        crops: [],
        plants: [AgentPlantObservation(
            plantKey: plantKey,
            position: target,
            renewability: .conditional,
            edibleSourceEvidence: evidence
        )],
        animals: [],
        fishing: [],
        weather: AgentWeatherObservation(
            kind: .clear,
            raining: false,
            thundering: false
        ),
        physicalTime: AgentPhysicalWorldTimeObservation(
            worldTick: 120,
            dayTime: 120,
            timeOfDay: .day,
            daylightCycleEnabled: true
        ),
        diagnostics: AgentEcologicalScanDiagnostics(
            radius: configuration.radius,
            cellsConsidered: 405,
            worldReads: 405,
            chunksTouched: 1,
            chunksUnavailable: completion == .chunkUnavailable ? 1 : 0,
            entitiesConsidered: 0,
            resultsEmitted: 4,
            cacheHits: 0,
            cacheMisses: 1,
            completion: completion
        ),
        expiresAtSimulationTick: expiresAtTick
            ?? session.tick + configuration.dynamicFreshnessTicks
    )
}

private func hungerDiscoveryDecision(
    _ actorID: AgentID = AgentID(rawValue: "agent_0")!
) -> AgentSubsistenceDecisionContext {
    AgentSubsistenceDecisionContext(
        actorID: actorID,
        fishingRodAvailable: false,
        huntingWeaponAvailable: false,
        agricultureAvailable: false,
        maximumDistance: 16,
        subsistencePressure: 40,
        requiredEdibleMaterialName: "sweet_berries"
    )
}

private func discoveryWorld(tick: Int, food: Bool? = false, ready: Bool = true,
                            clear: Bool = true, version: Int? = 1,
                            origin: AgentPosition = hungerDiscoveryOrigin) -> AgentWorldObservation {
    func column(_ p: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(position: p, chunkReady: ready,
            surfaceY: ready ? 64 : nil, height: ready ? 63 : nil,
            blockBelow: ready ? 1 : nil, blockAtFeet: ready ? 0 : nil,
            blockAtHead: ready ? 0 : nil, groundPresent: ready,
            feetClear: clear && ready, headClear: clear && ready)
    }
    return try! AgentWorldObservation(worldTick: tick, position: origin, center: column(origin),
        neighbors: AgentCardinalDirection.allCases.map { d in
            AgentWorldNeighborObservation(direction: d,
                column: column(AgentPosition(x: origin.x + d.dx, y: origin.y, z: origin.z + d.dz)),
                stepDelta: ready ? 0 : nil, traversable: ready && clear, dangerousDrop: false)
        }, biomeId: 1, biomeName: "plains", combinedLight: 15, skyLight: 15,
        blockLight: 0, dayTime: tick, raining: false, thundering: false,
        physicalCoverageDigest: ready ? "ready" : "unavailable",
        physicalMovementAssessmentVersion: version,
        physicalFoodCustody: food.map { AgentPhysicalFoodCustodyObservation(worldTick: tick, hasEligibleFood: $0) })
}

@discardableResult
private func discoveryTick(_ session: inout AgentSimulationSession, food: Bool? = false,
                           ready: Bool = true, clear: Bool = true, version: Int? = 1) -> AgentSessionTickResult {
    try! session.advanceTick(perceptions: [AgentPerceptionInput(agentId: "agent_0",
        worldObservation: discoveryWorld(tick: session.tick + 1, food: food,
            ready: ready, clear: clear, version: version))])
}

// Isolated fixture changes go through the real codec, digest and restore
// validators. They do not supply live execution or continuation evidence.
private func discoveryMutatedSession(_ session: AgentSimulationSession,
                                     mutate: (inout [String: Any]) -> Void) -> AgentSimulationSession {
    var root = try! JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(session.makeCheckpoint())) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let state = try! AgentCheckpointCodec.decode(AgentSessionDurableState.self,
        from: JSONSerialization.data(withJSONObject: durable))
    let bytes = try! AgentCheckpointCodec.encode(state)
    let canonical = try! JSONSerialization.jsonObject(with: bytes) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let identity = clock["simulationID"] as! String
    let digest = AgentCheckpointDigest.sha256(bytes)
    root["durableState"] = canonical; root["schemaVersion"] = canonical["schemaVersion"]
    root["tick"] = clock["tick"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(AgentCheckpointDigest.sha256(Data(identity.utf8)).rawValue.prefix(12))-t\(clock["tick"] as! Int)-\(digest.rawValue.prefix(16))"
    let checkpoint = try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: root))
    return try! AgentSimulationSession.restoring(checkpoint)
}

func runPebbleAgentsHungerDiscoverySmoke() {
    section("PS01 I10 bounded hunger discovery with prospective local custody")
    var hungry = hungerDiscoverySession("i10-hungry", hunger: 0.5)
    let first = discoveryTick(&hungry)
    check("hungry empty custody selects bounded exploration", first.agents[0].action.name == "move_abstract"
        && first.agents[0].snapshot.currentGoal.reason == "bounded hunger-driven physical food discovery")
    check("first search spends exactly one durable request", first.agents[0].snapshot.lastWorldObservation?
        .hungerDiscoveryProgress?.attempts == 1)
    check("search never creates an opportunity or material", hungry.wildSubsistenceSnapshot().opportunities.isEmpty
        && hungry.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity == 0
        && first.agents[0].snapshot.resourceInventory.isEmpty)
    let checkpoint = try! hungry.makeCheckpoint()
    var restored = try! AgentSimulationSession.restoring(checkpoint)
    check("active search checkpoint restores byte exactly without schema promotion",
        (try! restored.durableStateBytes()) == (try! hungry.durableStateBytes())
        && checkpoint.schemaVersion == AgentCheckpointSchema.pathReadinessLivenessVersion)
    let resumed = discoveryTick(&restored)
    check("restart continues budget rather than refreshing", resumed.agents[0].snapshot.lastWorldObservation?
        .hungerDiscoveryProgress?.attempts == 2)
    let carried = discoveryTick(&restored, food: true)
    check("carried eligible food cancels search and requests normal consumption",
        carried.agents[0].action.name == "consume_physical_food"
        && carried.agents[0].snapshot.lastWorldObservation?.hungerDiscoveryProgress == nil)
    var absent = hungerDiscoverySession("i10-historical-input", hunger: 0.5)
    let noCustody = discoveryTick(&absent, food: nil)
    check("absence of custody evidence preserves historical hunger response",
        noCustody.agents[0].action.name == "consume_physical_food"
        && noCustody.agents[0].snapshot.lastWorldObservation?.hungerDiscoveryProgress == nil)
    var satiated = hungerDiscoverySession("i10-no-need", hunger: 0)
    let noNeed = discoveryTick(&satiated)
    check("no need adds no search memory or movement", noNeed.agents[0].action.name != "move_abstract"
        && noNeed.agents[0].snapshot.lastWorldObservation?.hungerDiscoveryProgress == nil)
    var safety = hungerDiscoverySession("i10-safety", hunger: 0.8, health: 25)
    check("legitimate safety preempts hunger search", discoveryTick(&safety).agents[0].snapshot.currentGoal.kind == .seekSafety)
    var unknown = hungerDiscoverySession("i10-unknown", hunger: 0.5)
    let unavailable = discoveryTick(&unknown, ready: false, version: nil)
    check("unavailable coverage cannot start physical search", unavailable.agents[0].action.name != "move_abstract"
        && unavailable.agents[0].snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 0)
    check("ready evidence resumes without invented progress", discoveryTick(&unknown).agents[0]
        .snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 1)
    var enclosed = hungerDiscoverySession("i10-enclosed", hunger: 0.5)
    for _ in 0..<100 { _ = discoveryTick(&enclosed, clear: false) }
    check("no legal movement remains stationary and bounded", enclosed.snapshot().agents[0]
        .lastWorldObservation?.hungerDiscoveryProgress?.attempts == 0)
    var bounded = hungerDiscoverySession("i10-budget", hunger: 0.5)
    var requests = 0, cooldowns = 0
    for _ in 0..<100 {
        let result = discoveryTick(&bounded)
        if result.agents[0].action.name == "move_abstract" { requests += 1 }
        if result.agents[0].snapshot.lastWorldObservation?.hungerDiscoveryProgress?.cooldownUntilTick != nil { cooldowns += 1 }
    }
    check("one continuous need has exactly 24 search requests", requests == AgentHungerDiscoveryProgress.maximumAttempts)
    check("bursts yield through durable cooldown", cooldowns >= 16)
    check("elapsed time cannot replenish exhausted search", bounded.snapshot().agents[0]
        .lastWorldObservation?.hungerDiscoveryProgress?.attempts == 24)
    let exhaustedCheckpoint = try! bounded.makeCheckpoint()
    var exhaustedRestart = try! AgentSimulationSession.restoring(exhaustedCheckpoint)
    _ = discoveryTick(&exhaustedRestart)
    check("exhaustion survives save restart", exhaustedRestart.snapshot().agents[0]
        .lastWorldObservation?.hungerDiscoveryProgress?.attempts == 24)
    var failedSearch = hungerDiscoverySession("i10-physical-refusals", hunger: 0.5)
    var failedRequests = 0
    for _ in 0..<80 {
        let result = discoveryTick(&failedSearch)
        let row = result.agents[0]
        if row.action.name == "move_abstract" {
            failedRequests += 1
            let action = row.action
            let direction = AgentCardinalDirection.allCases.first { $0.dx == action.dx && $0.dz == action.dz }
            try! failedSearch.applyMovementOutcomes([AgentMovementOutcome(agentId: "agent_0",
                tick: failedSearch.tick, status: .blocked, fromPosition: hungerDiscoveryOrigin,
                toPosition: hungerDiscoveryOrigin, requestedDirection: direction,
                requestedDX: action.dx ?? 0, requestedDY: 0, requestedDZ: action.dz ?? 0,
                appliedDX: 0, appliedDY: 0, appliedDZ: 0, goalKind: row.snapshot.currentGoal.kind,
                actionReason: action.reason, resolutionReason: "isolated exact-center refusal",
                worldTickObserved: failedSearch.tick, distanceFromHomeBefore: 0,
                distanceFromHomeAfter: 0, distanceReducedTowardHome: 0)])
        }
    }
    check("physical refusals stop after four attempts across cooldowns", failedRequests == 4
        && failedSearch.snapshot().agents[0].lastWorldObservation?.hungerDiscoveryProgress?.failures == 4)
    check("failed search preserves physical position and material totals", failedSearch.snapshot().agents[0].position == hungerDiscoveryOrigin
        && failedSearch.physicalFoodSurvivalSnapshot()?.totalConsumedQuantity == 0
        && failedSearch.wildSubsistenceSnapshot().totalAttemptCount == 0)
    var failedRestart = try! AgentSimulationSession.restoring(failedSearch.makeCheckpoint())
    check("failed search restart cannot replenish refused work", discoveryTick(&failedRestart).agents[0].action.name != "move_abstract"
        && failedRestart.snapshot().agents[0].lastWorldObservation?.hungerDiscoveryProgress?.failures == 4)
    var replayed = hungerDiscoverySession("i10-replay", hunger: 0.5)
    let replayBase = try! replayed.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: replayBase, session: replayed)
    for _ in 0..<40 {
        _ = try! recorder.apply(.advanceTick(perceptions: [AgentPerceptionInput(agentId: "agent_0",
            worldObservation: discoveryWorld(tick: replayed.tick + 1))], physicalObservations: []), to: &replayed)
    }
    let journal = try! recorder.journal(named: AgentCheckpointName(rawValue: "i10-discovery")!)
    let verification = try! AgentSessionReplayer.replay(checkpoint: replayBase, journal: journal)
    check("existing replay operation retains prospective discovery exactly", verification.report.verified
        && (try! verification.session.durableStateBytes()) == (try! replayed.durableStateBytes())
        && journal.manifest.schemaVersion == replayBase.schemaVersion)

    var recovered = discoveryMutatedSession(hungry) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        var needs = agents[0]["needs"] as! [String: Any]
        needs["hunger"] = 0.0; agents[0]["needs"] = needs; durable["agents"] = agents
    }
    check("hunger recovery cancels durable search", discoveryTick(&recovered).agents[0]
        .snapshot.lastWorldObservation?.hungerDiscoveryProgress == nil)
    var interrupted = discoveryMutatedSession(hungry) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        agents[0]["health"] = 25; durable["agents"] = agents
    }
    let interruption = discoveryTick(&interrupted).agents[0]
    check("safety preempts an active search without replenishing budget", interruption.snapshot.currentGoal.kind == .seekSafety
        && interruption.snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 1)
    var dead = discoveryMutatedSession(hungry) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        agents[0]["health"] = 0; durable["agents"] = agents
    }
    let deadRow = discoveryTick(&dead).agents[0]
    check("nonliving actor receives no search request", deadRow.action.name != "move_abstract"
        && deadRow.snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 1)
    var disabled = hungerDiscoverySession("i10-disabled", hunger: 0.5)
    try! disabled.setAutonomousActivityEnabled(false)
    let disabledRow = discoveryTick(&disabled).agents[0]
    check("absent feature prerequisite adds no exploration or activity", disabledRow.action.name == "consume_physical_food"
        && disabledRow.snapshot.lastWorldObservation?.hungerDiscoveryProgress == nil
        && disabled.autonomousActivitySnapshot().activeActivities.isEmpty)
    var peers: [AgentSessionAgentState] = []
    for (index, direction) in AgentCardinalDirection.allCases.enumerated() {
        let peer = hungerDiscoveryAgent("agent_\(index + 1)", hunger: 0,
            position: AgentPosition(x: direction.dx, y: 64, z: direction.dz))
        peers.append(peer)
    }
    var occupied = hungerDiscoverySession("i10-occupied", hunger: 0.5, peers: peers)
    for _ in 0..<100 { _ = discoveryTick(&occupied) }
    let occupancyProgress = occupied.snapshot().agents.first { $0.id == "agent_0" }!.lastWorldObservation?.hungerDiscoveryProgress
    check("peer occupancy admits no physical step", occupancyProgress?.attempts == 0)
    check("elapsed ticks cannot refresh an identical occupancy refusal", occupancyProgress?.failures == 1
        && occupancyProgress?.refusedContexts.count == 1)
    var boundary = hungerDiscoverySession("i10-home-boundary", hunger: 0.5)
    let boundaryPosition = AgentPosition(x: 8, y: 64, z: 0)
    try! boundary.applyExternalUpdate(AgentExternalUpdate(agentId: "agent_0", position: boundaryPosition))
    let boundaryRow = try! boundary.advanceTick(perceptions: [AgentPerceptionInput(agentId: "agent_0",
        worldObservation: discoveryWorld(tick: 1, origin: boundaryPosition))]).agents[0]
    check("hunger discovery preserves the ordinary home boundary", boundaryRow.action.dx == -1
        && boundaryRow.action.dz == 0)
    var missing = hungry
    let gap = try! missing.advanceTick().agents[0]
    check("cached perception cannot authorize another search attempt", gap.action.name != "move_abstract"
        && gap.snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 1)

    var care = careBase("i10-care-preemption")
    try! care.setDependentCareEnabled(true)
    try! care.setReproductionEnabled(true)
    try! care.useLegacyCognitivePhysiologyReplayFixture(schemaVersion: AgentCheckpointSchema.dependentCareVersion)
    var careRecorder = try! AgentReplayRecorder(checkpoint: care.makeCheckpoint(), session: care)
    _ = careBirth(&careRecorder, &care, position: AgentPosition(x: 0, y: 64, z: 2), candidateIndex: 0)
    // Give the existing, genuinely admitted caregiver hunger in this isolated
    // fixture; careBase's abstract meal otherwise left it at 0.1.
    care = discoveryMutatedSession(care) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        var needs = agents[0]["needs"] as! [String: Any]
        needs["hunger"] = 0.5; agents[0]["needs"] = needs; durable["agents"] = agents
    }
    try! care.rebasePhysiologicalTime(toWorldTick: 0)
    try! care.setSkillsEnabled(true)
    try! care.setEcologicalObservationEnabled(true)
    try! care.setWildSubsistenceEnabled(true)
    try! care.setPhysicalFoodSurvivalEnabled(true)
    try! care.setAutonomousActivityEnabled(true)
    var carePreempted = false
    for index in 1...8 {
        let previousAttempts = Dictionary(uniqueKeysWithValues: care.snapshot().agents.map {
            ($0.id, $0.lastWorldObservation?.hungerDiscoveryProgress?.attempts ?? 0)
        })
        let inputs = care.snapshot().agents.map { agent in
            AgentPerceptionInput(agentId: agent.id,
                worldObservation: discoveryWorld(tick: index * 5, origin: agent.position))
        }
        try! care.advancePhysiologicalTime(toWorldTick: index * 5)
        let result = try! care.advanceTick(perceptions: inputs)
        carePreempted = carePreempted || result.agents.contains { row in
            row.snapshot.currentGoal.kind == .provideDependentCare
                && row.snapshot.needs.hunger >= 0.4
                && (row.snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts ?? 0) == previousAttempts[row.agentId]
                && row.action.name != "move_abstract"
        }
    }
    check("genuine hungry caregiver keeps normal care authority before search", carePreempted)

    let largeClock = discoveryMutatedSession(failedSearch) { durable in
        var clock = durable["clock"] as! [String: Any]
        clock["tick"] = Int.max; durable["clock"] = clock
    }
    check("checkpoint validation handles a bounded old cooldown without clock overflow",
        largeClock.tick == Int.max
            && largeClock.snapshot().agents[0].lastWorldObservation?.hungerDiscoveryProgress?.failures == 4)

    var fresh = hungry
    _ = try! fresh.recordEcologicalObservation(hungerDiscoveryObservation(fresh))
    let sourceEvent = fresh.ecologicalObservations(for: AgentID(rawValue: "agent_0")!).first!.causalEventID
    let freshRow = discoveryTick(&fresh).agents[0]
    check("fresh eligible local food prevents search", freshRow.action.name == "consume_physical_food")
    check("fresh discovery suspends the active search without another request",
        freshRow.snapshot.lastWorldObservation?.hungerDiscoveryProgress?.attempts == 1)
    let opportunity = try! fresh.selectWildSubsistenceOpportunity(hungerDiscoveryDecision())
    check("ordinary subsistence retains exact source observation", opportunity.sourceObservationEventID == sourceEvent)
    _ = try! fresh.selectAutonomousActivities([AgentAutonomousActivityCandidate(
        candidateID: "i10-ordinary-food", actorID: opportunity.actorID, domain: .wildGathering,
        actionKey: "wildGathering", stableReference: opportunity.opportunityID.rawValue,
        target: opportunity.lastObservedPosition, source: .need, priorityBand: 100,
        urgency: 83, distance: 1, observedAtTick: fresh.tick)])
    check("normal wild activity takes cognition over", discoveryTick(&fresh).agents[0].snapshot.currentGoal.kind == .civilizationActivity)
    var invalid = hungerDiscoverySession("i10-invalid-source", hunger: 0.5)
    _ = try! invalid.recordEcologicalObservation(hungerDiscoveryObservation(invalid, evidence: nil))
    check("unqualified plant evidence cannot suppress discovery", discoveryTick(&invalid).agents[0].action.name == "move_abstract")
    var stale = hungerDiscoverySession("i10-stale-source", hunger: 0.5)
    _ = try! stale.recordEcologicalObservation(hungerDiscoveryObservation(stale, expiresAtTick: stale.tick))
    check("stale edible evidence cannot suppress discovery", discoveryTick(&stale).agents[0].action.name == "move_abstract")
    do {
        let bytes = try JSONEncoder().encode(hungry.snapshot().agents[0].lastWorldObservation!)
        let decoded = try JSONDecoder().decode(AgentWorldObservation.self, from: bytes)
        check("versioned local evidence codec retains search budget", decoded.hungerDiscoveryProgress?.attempts == 1)
        var object = try JSONSerialization.jsonObject(with: bytes) as! [String: Any]
        var progress = object["hungerDiscoveryProgress"] as! [String: Any]
        progress["attempts"] = 25; object["hungerDiscoveryProgress"] = progress
        check("codec rejects overbudget history", (try? JSONDecoder().decode(AgentWorldObservation.self,
            from: JSONSerialization.data(withJSONObject: object))) == nil)
        progress["attempts"] = 1; progress["version"] = 2; object["hungerDiscoveryProgress"] = progress
        check("codec rejects unknown search semantics", (try? JSONDecoder().decode(AgentWorldObservation.self,
            from: JSONSerialization.data(withJSONObject: object))) == nil)
    } catch { check("local evidence codec", false) }
}
