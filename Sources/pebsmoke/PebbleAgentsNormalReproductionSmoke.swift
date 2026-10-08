import Foundation
@_spi(Testing) import PebbleAgents

private func normalReproductionFixture() throws -> AgentSimulationSession {
    let spec = try AgentFounderSpecification(count: 2)
    let agents = spec.agentIDs.enumerated().map { offset, id in
        let p = AgentPosition(x: offset * 2, y: 64, z: 0)
        return AgentSessionAgentState(id: id, state: "idle", position: p,
            needs: AgentNeeds(hunger: 0.3, fatigue: 0, curiosity: 0.2, safety: 1),
            health: 100, fear: 0, homePosition: p, nearbyAgents: [],
            currentGoal: AgentGoal(kind: .idle, reason: "boundary fixture", startedAtTick: 0, urgency: 0),
            lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
            ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
            goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
            actionEffectCount: 0, movementCount: 0, totalManhattanDistanceMoved: 0,
            returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0)
    }
    var session = try AgentSimulationSession(configuration: AgentSessionConfiguration(seed: 14, memoryPolicy: .bounded(maxEntries: 128)),
        agents: agents, simulationID: AgentSimulationID(validating: "i09-boundary"),
        causalLedgerPolicy: .bounded(maxEvents: 8192))
    try session.initializeFounderAuthorities(specification: spec,
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: -2, y: 64, z: 0))
    try session.setPhysicalFoodSurvivalEnabled(true)
    return session
}

/// Unit boundary DTOs only. The decisive native birth is qualified separately
/// in a natural Core World with no supplied meal, site, pair or birth.
private func boundaryMeal(_ session: AgentSimulationSession, _ id: AgentID)
    throws -> AgentValidatedPhysicalFoodConsumptionOutcome {
    let intent = try session.nextPhysicalFoodConsumptionIntent(for: id)
    let hunger = try session.state(for: id.rawValue).needs.hunger
    return AgentValidatedPhysicalFoodConsumptionOutcome(consumptionID: intent.consumptionID,
        consumptionSequence: intent.consumptionSequence, agentID: id, tick: session.tick,
        canonicalMaterialName: "sweet_berries", quantityConsumed: 1, coreHungerPoints: 2,
        coreSaturation: 0.4, normalizedHungerReduction: 0.1, status: .succeeded,
        physicalReceiptID: intent.consumptionID, sourceKind: .agentCarriedInventory,
        sourceSlot: 0, hungerBefore: hunger, hungerAfter: max(0, hunger - 0.1))
}

private func alteredState(_ session: AgentSimulationSession,
    _ edit: (inout [String: Any]) -> Void) throws -> AgentSessionCheckpoint {
    var json = try JSONSerialization.jsonObject(with: session.durableStateBytes()) as! [String: Any]
    edit(&json)
    let state = try AgentCheckpointCodec.decode(AgentSessionDurableState.self,
        from: JSONSerialization.data(withJSONObject: json, options: .sortedKeys))
    let bytes = try AgentCheckpointCodec.encode(state)
    let digest = AgentCheckpointDigest.sha256(bytes)
    var envelope = try JSONSerialization.jsonObject(with: AgentCheckpointCodec.encode(session.makeCheckpoint())) as! [String: Any]
    let simulationDigest = AgentCheckpointDigest.sha256(Data(session.simulationID.rawValue.utf8))
    envelope["durableState"] = try JSONSerialization.jsonObject(with: bytes)
    envelope["schemaVersion"] = state.schemaVersion
    envelope["semanticDigest"] = digest.rawValue
    envelope["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(session.tick)-\(digest.rawValue.prefix(16))"
    return try AgentCheckpointCodec.decode(AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: envelope, options: .sortedKeys))
}

func runPebbleAgentsNormalReproductionSmoke() {
    print("\n--- I09 normal physical reproductive prerequisites ---")
    do {
        var session = try normalReproductionFixture()
        let legacy = session
        try session.initializeNormalPhysicalReproduction()
        check("I09 fresh initialization is explicit schema 46",
              try session.makeCheckpoint().schemaVersion == 46 && session.reproductionEnabled)
        check("I09 physical census is unavailable", session.reproductionSnapshot().accessibleFood == nil
              && session.reproductionSnapshot().pressure == nil)
        check("I09 no meals cannot become eligible", session.reproductionSnapshot().eligiblePairs.isEmpty)
        let id0 = AgentID(rawValue: "agent_0")!, id1 = AgentID(rawValue: "agent_1")!
        try session.applyValidatedPhysicalFoodConsumption(boundaryMeal(session, id0))
        check("I09 one nourished parent is insufficient", session.reproductionSnapshot().eligiblePairs.isEmpty)
        try session.applyValidatedPhysicalFoodConsumption(boundaryMeal(session, id1))
        check("I09 two supported parents choose stable canonical pair",
              session.reproductionSnapshot().eligiblePairs == [[id0, id1]])
        let normalBase = try session.makeCheckpoint()
        var normalRecorder = try AgentReplayRecorder(checkpoint: normalBase, session: session)
        for _ in 0..<2 {
            _ = try normalRecorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &session)
        }
        let plan = session.lifecycleSnapshot().plans.first!
        check("I09 accepted plan pins exact physical receipt identities",
              plan.physicalSubsistenceEvidence?.meals.map(\.agentID) == [id0, id1]
                && plan.pressureAtPlanning == nil)
        let checkpoint = try session.makeCheckpoint()
        let normalJournal = try normalRecorder.journal(named: AgentCheckpointName(rawValue: "i09-normal")!)
        let normalReplay = try AgentSessionReplayer.replay(checkpoint: normalBase, journal: normalJournal)
        let normalDigest = try session.durableStateDigest()
        check("I09 schema 46 replay reconstructs exact accepted plan and causes",
              normalJournal.manifest.schemaVersion == 46
                && normalReplay.session.lifecycleSnapshot().plans == session.lifecycleSnapshot().plans
                && normalReplay.report.finalSemanticDigest == normalDigest)
        var restored = try AgentSimulationSession.restoring(checkpoint)
        check("I09 pending plan restore is byte exact", try restored.durableStateBytes() == session.durableStateBytes())
        for _ in 0..<2 { _ = try session.advanceTick(); _ = try restored.advanceTick() }
        check("I09 due plan continuation does not reroll", try restored.durableStateBytes() == session.durableStateBytes()
            && restored.pendingBirthSitePlan()?.planID == plan.planID)
        for schema in [44, 45] {
            var historical = try AgentSimulationSession.restoring(alteredState(legacy) { $0["schemaVersion"] = schema })
            let bytes = try historical.durableStateBytes()
            let cp = try historical.makeCheckpoint()
            let loaded = try AgentSimulationSession.restoring(cp)
            let loadedBytes = try loaded.durableStateBytes()
            check("I09 schema \(schema) retains exact historical bytes and disabled activation",
                  cp.schemaVersion == schema && !loaded.normalPhysicalReproductionEnabled
                    && !loaded.reproductionEnabled && loadedBytes == bytes)
            try historical.setReproductionEnabled(true)
            try historical.applyValidatedPhysicalFoodConsumption(boundaryMeal(historical, id0))
            try historical.applyValidatedPhysicalFoodConsumption(boundaryMeal(historical, id1))
            let base = try historical.makeCheckpoint()
            var recorder = try AgentReplayRecorder(checkpoint: base, session: historical)
            _ = try recorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &historical)
            _ = try recorder.apply(.advanceTick(perceptions: [], physicalObservations: []), to: &historical)
            check("I09 schema \(schema) meals do not replace historical ecology prerequisites",
                  historical.lifecycleSnapshot().plans.isEmpty)
            let replay = try AgentSessionReplayer.replay(checkpoint: base, journal: recorder.journal(named: AgentCheckpointName(rawValue: "i09-legacy")!))
            check("I09 schema \(schema) legacy replay remains exact", try replay.report.finalSemanticDigest == historical.durableStateDigest())
            do {
                _ = try AgentSimulationSession.restoring(alteredState(session) { $0["schemaVersion"] = schema })
                check("I09 new semantics cannot masquerade as schema \(schema)", false)
            } catch { check("I09 new semantics cannot masquerade as schema \(schema)", true) }
        }
        do {
            _ = try AgentSimulationSession.restoring(alteredState(session) { root in
                var life = root["lifecycleState"] as! [String: Any]
                var plans = life["plans"] as! [[String: Any]]
                plans[0].removeValue(forKey: "physicalSubsistenceEvidence")
                life["plans"] = plans; root["lifecycleState"] = life
            })
            check("I09 missing pinned prerequisites refuse before publication", false)
        } catch { check("I09 missing pinned prerequisites refuse before publication", true) }
        let before = try session.durableStateBytes()
        do {
            try session.setPhysicalFoodSurvivalEnabled(false)
            check("I09 cannot remove the physical prerequisite owner", false)
        } catch { check("I09 owner removal refuses atomically", try session.durableStateBytes() == before) }
    } catch { check("I09 normal reproduction boundary suite", false, "\(error)") }
}
