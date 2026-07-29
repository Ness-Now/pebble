import Foundation
import PebbleAgents

private func homeostasisAgent(
    _ id: String,
    hunger: Double = 0,
    fatigue: Double = 0,
    health: Int = 100
) -> AgentSessionAgentState {
    let ordinal = Int(id.suffix(1)) ?? 0
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(
            hunger: hunger,
            fatigue: fatigue,
            curiosity: 0.2,
            safety: 1
        ),
        health: health,
        fear: 0,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle,
            reason: "initial homeostasis fixture",
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
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private let homeostasisStableSurvival = try! AgentSurvivalConfiguration(
    hungerPerTick: 0.001,
    fatiguePerTick: 0.001,
    hungryThreshold: 0.4,
    criticalHungerThreshold: 0.8,
    hungerRecoveryThreshold: 0.15,
    fatigueThreshold: 0.65,
    fatigueRecoveryThreshold: 0.2,
    foodNutrition: 1,
    restRecoveryPerTick: 1,
    starvationGraceTicks: 0,
    starvationDamagePerTick: 100
)

private let homeostasisFastSurvival = try! AgentSurvivalConfiguration(
    hungerPerTick: 0.1,
    fatiguePerTick: 0.1,
    hungryThreshold: 0.4,
    criticalHungerThreshold: 0.8,
    hungerRecoveryThreshold: 0.15,
    fatigueThreshold: 0.65,
    fatigueRecoveryThreshold: 0.2,
    foodNutrition: 1,
    restRecoveryPerTick: 1,
    starvationGraceTicks: 0,
    starvationDamagePerTick: 100
)

private func homeostasisSession(
    _ simulationID: String,
    agents: [AgentSessionAgentState],
    survival: AgentSurvivalConfiguration,
    homeostasis: AgentHomeostasisConfiguration
) -> AgentSimulationSession {
    var completeAgents = agents
    let existing = Set(completeAgents.map(\.id))
    for ordinal in 0..<3 where !existing.contains("agent_\(ordinal)") {
        completeAgents.append(homeostasisAgent("agent_\(ordinal)"))
    }
    completeAgents.sort { $0.agentID < $1.agentID }
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 91,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: completeAgents,
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setMortalityEnabled(true)
    try! session.setLifecycleEnabled(true)
    try! session.setHomeostasisEnabled(true, configuration: homeostasis)
    return session
}

private func consumePhysicalFood(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) {
    if !session.physicalFoodSurvivalEnabled {
        try! session.setPhysicalFoodSurvivalEnabled(true)
    }
    let actor = try! session.state(for: agentID)
    guard actor.needs.hunger > 0 else { return }
    let intent = try! session.nextPhysicalFoodConsumptionIntent(for: agentID)
    let outcome = AgentValidatedPhysicalFoodConsumptionOutcome(
        consumptionID: intent.consumptionID,
        consumptionSequence: intent.consumptionSequence,
        agentID: agentID,
        tick: session.tick,
        canonicalMaterialName: "bread",
        quantityConsumed: 1,
        coreHungerPoints: 20,
        coreSaturation: 6,
        normalizedHungerReduction: 1,
        status: .succeeded,
        physicalReceiptID: intent.consumptionID,
        sourceKind: .agentCarriedInventory,
        sourceSlot: 0,
        hungerBefore: actor.needs.hunger,
        hungerAfter: 0
    )
    try! session.applyValidatedPhysicalFoodConsumption(outcome)
}

func runPebbleAgentsHomeostasisHealthSmoke() {
    section("PebbleAgents homeostasis, health, aging, and mortality V2")

    check("homeostasis configuration rejects unbounded profiles", {
        do {
            _ = try AgentHomeostasisConfiguration(maximumProfiles: 513)
            return false
        } catch AgentHomeostasisError.invalidConfiguration("profiles") {
            return true
        } catch {
            return false
        }
    }())

    let stableConfig = try! AgentHomeostasisConfiguration(
        ageVulnerabilityStartTicks: 9
    )
    var stable = homeostasisSession(
        "civ29-stable",
        agents: [homeostasisAgent("agent_0")],
        survival: homeostasisStableSurvival,
        homeostasis: stableConfig
    )
    let stableInitial = stable.homeostasisSnapshot()
    for _ in 0..<4 { _ = try! stable.advanceTick() }
    let stableProfile = stable.homeostasisSnapshot().profiles[0]
    check("stable needs preserve physiological function",
          stableProfile.vitalStatus == .alive
            && stableProfile.condition == .stable
            && (try! stable.state(for: "agent_0")).health == 100)
    check("monotone age crosses a natural later-life boundary",
          stableProfile.ageTicks > stableInitial.profiles[0].ageTicks
            && stableProfile.ageBand == .laterLife
            && stableProfile.ageVulnerabilityBasisPoints > 0
            && stable.snapshot().agents[0].actionCount > 0)

    var laterLife = homeostasisSession(
        "civ29-later-life-resilience",
        agents: [homeostasisAgent("agent_0")],
        survival: homeostasisStableSurvival,
        homeostasis: stableConfig
    )
    for _ in 0..<8 { _ = try! laterLife.advanceTick() }
    var primeLife = homeostasisSession(
        "civ29-prime-life-resilience",
        agents: [homeostasisAgent("agent_0")],
        survival: homeostasisStableSurvival,
        homeostasis: stableConfig
    )
    _ = try! primeLife.advanceTick()
    let laterProfile = laterLife.homeostasisSnapshot().profiles[0]
    let primeProfile = primeLife.homeostasisSnapshot().profiles[0]
    check("later life lowers bounded recovery capacity without predestined death",
          laterProfile.ageTicks > primeProfile.ageTicks
            && laterProfile.ageVulnerabilityBasisPoints
                > primeProfile.ageVulnerabilityBasisPoints
            && laterProfile.recoveryCapacityBasisPoints
                < primeProfile.recoveryCapacityBasisPoints
            && laterProfile.vitalStatus == .alive
            && primeProfile.vitalStatus == .alive)

    let boundedConfig = try! AgentHomeostasisConfiguration(
        maximumEpisodesPerProfile: 2,
        maximumRetainedTransitions: 2,
        ageVulnerabilityStartTicks: 1_000,
        baseHealthDamagePerTick: 25
    )
    var declining = homeostasisSession(
        "civ29-decline",
        agents: [
            homeostasisAgent(
                "agent_0", hunger: 0.9, fatigue: 0.9
            ),
        ],
        survival: homeostasisFastSurvival,
        homeostasis: boundedConfig
    )
    let terminalAssetID = AgentMaterialAssetID(
        rawValue: "asset:civ29:historical-claim"
    )!
    let terminalClaimID = AgentMaterialClaimID(
        rawValue: "claim:civ29:agent_0"
    )!
    let terminalIdentity = AgentMaterialIdentitySnapshot(
        itemKey: "iron_pickaxe",
        damage: 0,
        enchantments: [],
        label: nil,
        canonicalDataJSON: "{}"
    )
    try! declining.setMaterialRightsEnabled(true)
    _ = try! declining.applyMaterialRightsOperation(.register(
        operationID: "civ29-terminal-asset",
        asset: AgentMaterialAssetReference(
            assetID: terminalAssetID,
            materialIdentity: terminalIdentity,
            quantity: 1
        ),
        observation: AgentMaterialHolderObservation(
            holder: .container("civ29-test-container"),
            materialIdentity: terminalIdentity,
            quantity: 1,
            custodyFingerprint: "civ29-container:iron_pickaxe:1",
            physicalReceiptID: "civ29-terminal-asset-receipt",
            observedAtTick: declining.tick
        )
    ))
    _ = try! declining.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ29-terminal-claim",
        assetID: terminalAssetID,
        claimID: terminalClaimID,
        claimantID: AgentID(rawValue: "agent_0")!,
        basis: .produced
    ))
    _ = try! declining.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "civ29-terminal-owner",
        assetID: terminalAssetID,
        claimID: terminalClaimID,
        recognizingAgentIDs: [
            AgentID(rawValue: "agent_0")!,
            AgentID(rawValue: "agent_1")!,
        ]
    ))
    try! declining.setAutonomousActivityEnabled(true)
    _ = try! declining.selectAutonomousActivities([
        AgentAutonomousActivityCandidate(
            candidateID: "civ29-active-before-incapacity",
            actorID: AgentID(rawValue: "agent_0")!,
            domain: .materialHandling,
            actionKey: "toolUse",
            stableReference: "asset:civ29:test",
            source: .opportunity,
            priorityBand: 50,
            urgency: 60,
            distance: 0,
            observedAtTick: declining.tick
        ),
    ])
    var sawImpairment = false
    var sawIncapacity = false
    for _ in 0..<12
        where !declining.mortalitySnapshot().records.contains(where: {
            $0.agentID.rawValue == "agent_0"
        }) {
        _ = try! declining.advanceTick()
        if let profile = declining.homeostasisSnapshot().profiles.first {
            sawImpairment = sawImpairment
                || profile.condition == .impaired
                || profile.condition == .critical
            sawIncapacity = sawIncapacity
                || profile.vitalStatus == .incapacitated
        }
    }
    let death = declining.mortalitySnapshot().records.last
    check("deprivation progresses through limitation before causal death",
          sawImpairment && sawIncapacity
            && death?.cause == .compoundedHomeostaticFailure
            && death?.finalVitalStatus == .dead
            && death?.finalHomeostasis?.condition == .dead)
    check("death is unique and removes all active physiology",
          declining.mortalitySnapshot().totalDeathCount == 1
            && declining.snapshot().agentCount == 2
            && declining.homeostasisSnapshot().profiles.count == 2
            && declining.homeostasisProfile(
                for: AgentID(rawValue: "agent_0")!
            ) == nil)
    check("incapacity or death interrupts autonomous activity",
          declining.autonomousActivitySnapshot().activeActivities.isEmpty
            && declining.autonomousActivitySnapshot().recentRecords.contains {
                $0.outcome.lifecycle == .interrupted
                    && $0.outcome.reason.contains("physiological")
            })
    let sequenceAtDeath = declining.causalLedgerSnapshot().summary.latestSequence
    _ = try! declining.advanceTick()
    check("dead agent performs no post-death action or aging",
          declining.causalLedgerSnapshot().events.allSatisfy {
              !($0.sequence.rawValue > sequenceAtDeath
                  && $0.actorID?.rawValue == "agent_0"
                  && $0.kind == .actionSelected)
          }
            && declining.mortalitySnapshot().records.last?.demographicAgeTicks
                == death?.demographicAgeTicks)
    let postDeathRights = declining.materialRightsSnapshot().records[0]
    let postDeathCheckpoint = try! declining.makeCheckpoint()
    let postDeathRestored = try! AgentSimulationSession.restoring(
        postDeathCheckpoint
    )
    check("death preserves historical claims without granting dead agency",
          postDeathRights.claims.map(\.claimantID.rawValue) == ["agent_0"]
            && postDeathRights.recognizedOwnership?.ownerID.rawValue
                == "agent_0"
            && postDeathRestored.materialRightsSnapshot().records
                == declining.materialRightsSnapshot().records
            && {
                do {
                    _ = try declining.applyMaterialRightsOperation(.withdrawClaim(
                        operationID: "civ29-dead-withdrawal",
                        assetID: terminalAssetID,
                        claimID: terminalClaimID,
                        actorID: AgentID(rawValue: "agent_0")!
                    ))
                    return false
                } catch AgentSessionError.materialRights(
                    .unknownAgent(let agentID)
                ) {
                    return agentID.rawValue == "agent_0"
                } catch {
                    return false
                }
            }())
    check("homeostasis transition history is bounded with explicit eviction",
          declining.homeostasisSnapshot().recentTransitions.count <= 2
            && declining.homeostasisSnapshot().transitionEvictionCount > 0
            && declining.homeostasisSnapshot().totalTransitionCount
                == declining.homeostasisSnapshot().recentTransitions.count
                    + declining.homeostasisSnapshot().transitionEvictionCount)

    let recoveryConfig = try! AgentHomeostasisConfiguration(
        ageVulnerabilityStartTicks: 1_000,
        baseHealthDamagePerTick: 12,
        healthRecoveryPerTick: 5
    )
    var recovering = homeostasisSession(
        "civ29-recovery",
        agents: [
            homeostasisAgent(
                "agent_0", hunger: 0.9, fatigue: 0.9
            ),
        ],
        survival: homeostasisFastSurvival,
        homeostasis: recoveryConfig
    )
    for _ in 0..<3 { _ = try! recovering.advanceTick() }
    let damagedHealth = try! recovering.state(for: "agent_0").health
    var lowestHealth = damagedHealth
    for _ in 0..<8 {
        consumePhysicalFood(
            &recovering,
            agentID: AgentID(rawValue: "agent_0")!
        )
        _ = try! recovering.advanceTick()
        let health = try! recovering.state(for: "agent_0").health
        lowestHealth = min(lowestHealth, health)
    }
    let recoveredProfile = recovering.homeostasisSnapshot().profiles[0]
    let finalRecoveryHealth = try! recovering.state(for: "agent_0").health
    check("verified food and actual rest produce bounded recovery",
          damagedHealth < 100
            && lowestHealth < damagedHealth
            && finalRecoveryHealth > lowestHealth
            && recoveredProfile.recentEpisodes.contains {
                $0.endedAtTick != nil
                    && $0.lastUpdatedTick == $0.endedAtTick
                    && $0.trend == .recovering
            })
    check("recovery does not create health ex nihilo beyond the reserve bound",
          (1...100).contains(try! recovering.state(for: "agent_0").health)
            && recovering.physicalFoodSurvivalSnapshot()?
                .totalConsumedQuantity ?? 0 > 0)

    var persisted = recovering
    let checkpoint = try! persisted.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    check("homeostasis checkpoint schema 21 is byte exact",
          checkpoint.schemaVersion == AgentCheckpointSchema.homeostasisVersion
            && (try! restored.durableStateBytes())
                == (try! persisted.durableStateBytes()))
    _ = try! persisted.advanceTick()
    var restarted = restored
    _ = try! restarted.advanceTick()
    check("mid-recovery restart preserves deterministic continuation",
          (try! restarted.durableStateBytes())
            == (try! persisted.durableStateBytes()))

    var replayBase = homeostasisSession(
        "civ29-replay-base",
        agents: [homeostasisAgent("agent_0")],
        survival: homeostasisStableSurvival,
        homeostasis: stableConfig
    )
    // A v21 checkpoint already contains the full feature state. Its replay
    // continuation must remain byte-identical without a feature reactivation.
    let replayCheckpoint = try! replayBase.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayCheckpoint,
        session: replayBase
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &replayBase
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ29-homeostasis")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: replayCheckpoint,
        journal: journal
    )
    check("homeostasis replay schema 21 is deterministic",
          journal.manifest.schemaVersion == AgentReplaySchema.homeostasisVersion
            && replay.report.verified
            && (try! replay.session.durableStateBytes())
                == (try! replayBase.durableStateBytes()))

    let world = try! AgentObserverWorldBinding(
        worldID: "world-civ29",
        storageIdentity: "sqlite-world:world-civ29",
        seed: 91,
        dimension: 0,
        observedWorldTick: 200
    )
    let observerBefore = try! recovering.durableStateBytes()
    let observerA = recovering.observerSnapshot(worldBinding: world)
    let observerB = recovering.observerSnapshot(worldBinding: world)
    check("Observer V2 exposes authoritative physiology and age",
          observerA.header.schemaVersion == 2
            && observerA.individuals[0].physiology?.ageTicks
                == recovering.homeostasisSnapshot().profiles[0].ageTicks
            && observerA.individuals[0].physiology?.condition
                == recovering.homeostasisSnapshot().profiles[0].condition)
    check("Observer physiology is deterministic and read-only",
          observerA == observerB
            && observerBefore == (try! recovering.durableStateBytes()))
    let deathObserver = declining.observerSnapshot(worldBinding: world)
    check("Observer preserves a causal mortality projection",
          deathObserver.recentDeaths.count == 1
            && deathObserver.recentDeaths[0].cause
                == .compoundedHomeostaticFailure
            && deathObserver.globalChronicle.contains {
                $0.kind == .agentDeathFinalized
            })

    var malformedObject = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var malformedDurable = malformedObject["durableState"] as! [String: Any]
    var malformedHomeostasis =
        malformedDurable["homeostasisState"] as! [String: Any]
    var malformedProfiles =
        malformedHomeostasis["profiles"] as! [[String: Any]]
    malformedProfiles[0]["energyReserveBasisPoints"] = 20_000
    malformedHomeostasis["profiles"] = malformedProfiles
    malformedDurable["homeostasisState"] = malformedHomeostasis
    malformedObject["durableState"] = malformedDurable
    let malformedData = try! JSONSerialization.data(
        withJSONObject: malformedObject,
        options: [.sortedKeys]
    )
    let malformedCheckpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: malformedData
    )
    check("corrupt physiology checkpoint is refused without publication", {
        do {
            _ = try AgentSimulationSession.restoring(malformedCheckpoint)
            return false
        } catch {
            return (try! recovering.durableStateBytes()) == observerBefore
        }
    }())
}
