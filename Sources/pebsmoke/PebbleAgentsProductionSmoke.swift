import PebbleAgents

private func productionSmokeAgent() -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_0", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0.8, fatigue: 0, curiosity: 0.2, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "missing useful tool", startedAtTick: 0,
            urgency: 70
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func productionIdentity(
    _ item: String,
    damage: Int = 0
) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: item, damage: damage, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
}

private func productionStack(
    _ item: String,
    _ count: Int,
    damage: Int = 0
) -> AgentMaterialStackSnapshot {
    AgentMaterialStackSnapshot(
        identity: productionIdentity(item, damage: damage), count: count
    )
}

private func productionSmokeSession(
    _ id: String = "civ34-production"
) -> AgentSimulationSession {
    try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 134, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [productionSmokeAgent()],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 2048)
    )
}

func runPebbleAgentsProductionSmoke() {
    section("CIV-34 production cognition, persistence and replay")

    var session = productionSmokeSession()
    let base = try! session.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(checkpoint: base, session: session)
    _ = try! recorder.apply(
        .setProductionEnabled(true, configuration: .live), to: &session
    )
    let needID = AgentProductionNeedID(rawValue: "need:agent_0:stone_pickaxe")!
    _ = try! recorder.apply(.raiseProductionNeed(
        needID: needID,
        actorID: AgentID(rawValue: "agent_0")!,
        reason: .missingUsefulTool,
        desiredOutputItemKey: "stone_pickaxe",
        quantity: 1,
        priority: 84
    ), to: &session)
    check("production state enables without material conversion",
          session.productionEnabled
            && session.productionSnapshot().records.isEmpty)
    check("missing-tool need remains explicit and active",
          session.productionSnapshot().needs.first?.status == .active
            && session.productionSnapshot().needs.first?.reason
                == .missingUsefulTool)

    let opportunityID = AgentProductionOpportunityID(
        rawValue: "production:agent_0:stone_pickaxe:t0:plan"
    )!
    let observation = AgentProductionOpportunityObservation(
        opportunityID: opportunityID,
        needID: needID,
        actorID: AgentID(rawValue: "agent_0")!,
        recipeID: "craft:stone_pickaxe",
        workshopPosition: AgentPosition(x: 1, y: 64, z: 0),
        workshopBlockKey: "crafting_table",
        sourceLocationID: "agent:probe-agent_0",
        sourceCustodyFingerprint: "before:cobblestone=3:stick=2",
        planFingerprint: "plan-stone-pickaxe",
        inputs: [productionStack("cobblestone", 3), productionStack("stick", 2)],
        output: productionStack("stone_pickaxe", 1),
        observedAtTick: 0,
        expiresAtTick: 2
    )
    _ = try! recorder.apply(.recordProductionOpportunity(observation), to: &session)
    check("physical observation creates bounded current opportunity",
          session.productionSnapshot().opportunities.count == 1)

    let stale = AgentVerifiedProductionOutcome(
        operationID: "produce:stale",
        opportunityID: opportunityID,
        actorID: AgentID(rawValue: "agent_0")!,
        recipeID: observation.recipeID,
        workshopPosition: observation.workshopPosition,
        workshopBlockKey: observation.workshopBlockKey,
        sourceLocationID: observation.sourceLocationID,
        sourceCustodyFingerprintBefore: "externally-changed",
        sourceCustodyFingerprintAfter: "after",
        planFingerprint: observation.planFingerprint,
        inputsConsumed: observation.inputs,
        outputProduced: observation.output,
        physicalReceiptID: "produce:stale",
        completedAtTick: 0
    )
    let beforeStale = try! session.durableStateBytes()
    check("stale physical source is refused",
          (try? session.recordVerifiedProduction(stale)) == nil)
    check("stale refusal publishes no cognition mutation",
          (try! session.durableStateBytes()) == beforeStale)

    let success = AgentVerifiedProductionOutcome(
        operationID: "produce:agent_0:stone_pickaxe:t0",
        opportunityID: opportunityID,
        actorID: AgentID(rawValue: "agent_0")!,
        recipeID: observation.recipeID,
        workshopPosition: observation.workshopPosition,
        workshopBlockKey: observation.workshopBlockKey,
        sourceLocationID: observation.sourceLocationID,
        sourceCustodyFingerprintBefore: observation.sourceCustodyFingerprint,
        sourceCustodyFingerprintAfter: "after:stone_pickaxe=1",
        planFingerprint: observation.planFingerprint,
        inputsConsumed: observation.inputs,
        outputProduced: observation.output,
        physicalReceiptID: "produce:agent_0:stone_pickaxe:t0",
        completedAtTick: 0
    )
    _ = try! recorder.apply(.recordVerifiedProduction(success), to: &session)
    let produced = session.productionSnapshot()
    check("verified production fulfills the causal need",
          produced.needs.first?.status == .fulfilled
            && produced.needs.first?.fulfilledByOperationID == success.operationID)
    check("verified production retains exact recipe, workshop, inputs and output",
          produced.records.first?.recipeID == success.recipeID
            && produced.records.first?.workshopPosition == success.workshopPosition
            && produced.records.first?.inputsConsumed == success.inputsConsumed
            && produced.records.first?.outputProduced == success.outputProduced)
    check("successful production consumes the current opportunity",
          produced.opportunities.isEmpty)
    check("production success is causally auditable",
          session.causalLedgerSnapshot().events.contains {
              $0.kind == .productionCompleted
                && $0.origin == .productionTransition
                && $0.operationID?.rawValue == success.operationID
          })
    let beforeDuplicate = try! session.durableStateBytes()
    check("duplicate production operation is refused",
          (try? session.recordVerifiedProduction(success)) == nil)
    check("duplicate refusal creates no output or causal credit",
          (try! session.durableStateBytes()) == beforeDuplicate
            && session.productionSnapshot().totalProductionCount == 1)

    let used = AgentProducedGoodUseOutcome(
        operationID: "use:agent_0:stone_pickaxe:t0",
        productionOperationID: success.operationID,
        actorID: success.actorID,
        physicalReceiptID: "use:agent_0:stone_pickaxe:t0",
        identityBefore: productionStack("stone_pickaxe", 1, damage: 0),
        identityAfter: productionStack("stone_pickaxe", 1, damage: 1),
        physicalEffect: "stone block broken and drop acquired",
        completedAtTick: 0
    )
    _ = try! recorder.apply(.recordProducedGoodUse(used), to: &session)
    check("same produced tool identity records real durability evolution",
          session.productionSnapshot().useRecords.first?.outcome.identityAfter
            .identity.damage == 1)
    check("produced-good use cites original production receipt",
          session.productionSnapshot().useRecords.first?.outcome
            .productionOperationID == success.operationID)

    try! session.setAutonomousActivityEnabled(true)
    _ = try! session.selectAutonomousActivities([
        AgentAutonomousActivityCandidate(
            candidateID: "production-choice",
            actorID: success.actorID,
            domain: .production,
            actionKey: "craft:bread",
            stableReference: "second-recipe",
            target: AgentPosition(x: 1, y: 64, z: 0),
            materialFingerprint: "bread-plan",
            source: .need,
            priorityBand: 8,
            urgency: 90,
            distance: 1,
            observedAtTick: 0
        ),
    ])
    check("normal autonomous arbitration selects production domain",
          session.activeAutonomousActivity(for: success.actorID)?
            .candidate.domain == .production)
    check("production maps to reusable crafting skill domain",
          AgentAutonomousActivityDomain.production.skillDomain == .crafting)

    let checkpoint = try! session.makeCheckpoint()
    check("production checkpoint advances exact schema 31",
          checkpoint.schemaVersion == AgentCheckpointSchema.productionVersion
            && AgentCheckpointSchema.productionVersion == 31)
    let bytes = try! AgentCheckpointCodec.encode(checkpoint)
    let decoded = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: bytes
    )
    let restored = try! AgentSimulationSession.restoring(decoded)
    check("production checkpoint restores exact durable bytes",
          (try! restored.durableStateBytes())
            == (try! session.durableStateBytes()))
    check("production checkpoint retains produced tool continuity",
          restored.productionSnapshot().records.first?.operationID
            == success.operationID
            && restored.productionSnapshot().useRecords.count == 1)

    let world = try! AgentObserverWorldBinding(
        worldID: "civ34-world", storageIdentity: "memory:civ34",
        seed: 134, dimension: 0, observedWorldTick: 0
    )
    let stateBeforeObserver = try! session.durableStateBytes()
    let observer = session.observerSnapshot(worldBinding: world)
    check("Observer schema 8 exposes structured production facts",
          observer.header.schemaVersion == 8
            && observer.production?.records.first?.operationID
                == success.operationID)
    check("Observer production projection is read-only",
          (try! session.durableStateBytes()) == stateBeforeObserver)

    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "production-replay")!
    )
    check("production replay uses exact schema 31",
          journal.manifest.schemaVersion == AgentReplaySchema.productionVersion
            && AgentReplaySchema.productionVersion == 31)
    check("production replay records typed causal operations",
          journal.records.map(\.operationKind) == [
              .productionFeature, .productionNeed, .productionOpportunity,
              .productionOutcome, .producedGoodUse,
          ])
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: base, journal: journal
    )
    check("production replay verifies exact continuation",
          replayed.report.verified
            && replayed.report.finalSemanticDigest
                == (try! recorderSessionDigest(journal: journal, base: base)))
    check("production replay retains need to output to use causality",
          replayed.session.productionSnapshot().records.count == 1
            && replayed.session.productionSnapshot().useRecords.count == 1)
}

private func recorderSessionDigest(
    journal: AgentReplayJournal,
    base: AgentSessionCheckpoint
) throws -> AgentCheckpointDigest {
    try AgentSessionReplayer.replay(checkpoint: base, journal: journal)
        .report.finalSemanticDigest
}
