import Foundation
import PebbleAgents

private let gateFB03EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB03MainReception = AgentPosition(x: 0, y: 64, z: 3)
private let gateFB03EastReception = AgentPosition(x: 4, y: 64, z: 3)
private let gateFB03NewbornID = AgentID(rawValue: "agent_3")!
private let gateFB03Habitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 60_303, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private func gateFB03Agent(
    _ id: String,
    x: Int,
    lethalOnNextSurvivalTick: Bool = false,
    protectedFromOneFullHungerTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalOnNextSurvivalTick
                ? 1 : (protectedFromOneFullHungerTick ? -1 : 0),
            fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: lethalOnNextSurvivalTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 03 fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalOnNextSurvivalTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalOnNextSurvivalTick ? 2 : 0
        )
    )
}

private func gateFB03ScaleConfiguration(
    maximumLiveAgents: Int,
    maximumNearAgents: Int,
    rotationIntervalTicks: Int = 256,
    maximumFidelityTransitionHistory: Int = 32
) -> AgentPopulationScaleConfiguration {
    try! AgentPopulationScaleConfiguration(
        maximumSettlements: 2,
        maximumLiveAgents: maximumLiveAgents,
        maximumNearAgents: maximumNearAgents,
        nearMaintenanceCadence: 2,
        dormantMaintenanceCadence: 8,
        rotationIntervalTicks: rotationIntervalTicks,
        maximumFidelityTransitionHistory:
            maximumFidelityTransitionHistory,
        maximumSettlementMigrationHistory: 8,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 16
    )
}

private func gateFB03Session(
    id: String,
    maximumPopulation: Int = 4,
    maximumLiveAgents: Int = 4,
    maximumNearAgents: Int = 2,
    rotationIntervalTicks: Int = 256,
    maximumFidelityTransitionHistory: Int = 32,
    founderOrder: [String] = ["agent_0", "agent_1", "agent_2"],
    lethalFounder2: Bool = false,
    newbornLethalSurvival: Bool = false
) -> AgentSimulationSession {
    let liveSurvival = AgentSurvivalConfiguration.live
    let survival = newbornLethalSurvival
        ? try! AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: liveSurvival.fatiguePerTick,
            hungryThreshold: liveSurvival.hungryThreshold,
            criticalHungerThreshold: liveSurvival.criticalHungerThreshold,
            hungerRecoveryThreshold: liveSurvival.hungerRecoveryThreshold,
            fatigueThreshold: liveSurvival.fatigueThreshold,
            fatigueRecoveryThreshold: liveSurvival.fatigueRecoveryThreshold,
            foodNutrition: liveSurvival.foodNutrition,
            restRecoveryPerTick: liveSurvival.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: 100
        )
        : liveSurvival
    let xByID = ["agent_0": 0, "agent_1": 2, "agent_2": 4]
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 603, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: founderOrder.map {
            gateFB03Agent(
                $0, x: xByID[$0]!,
                lethalOnNextSurvivalTick: lethalFounder2 && $0 == "agent_2",
                protectedFromOneFullHungerTick: newbornLethalSurvival
            )
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: gateFB03MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: maximumPopulation,
            maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(observations: [gateFB03Habitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [gateFB03Habitat]
    )
    try! session.setLifecycleEnabled(true)
    try! session.setReproductionEnabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB03EastID,
            anchor: gateFB03EastReception,
            receptionPosition: gateFB03EastReception,
            capacity: maximumPopulation,
            residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: [],
        configuration: gateFB03ScaleConfiguration(
            maximumLiveAgents: maximumLiveAgents,
            maximumNearAgents: maximumNearAgents,
            rotationIntervalTicks: rotationIntervalTicks,
            maximumFidelityTransitionHistory:
                maximumFidelityTransitionHistory
        )
    )
    while session.tick < 4 { _ = try! session.advanceTick() }
    precondition(session.pendingBirthSitePlan() != nil)
    return session
}

private func gateFB03BirthObservation(
    _ session: AgentSimulationSession,
    fingerprint: Int = 60_303
) -> AgentBirthSiteObservation {
    AgentBirthSiteObservation(
        planID: session.pendingBirthSitePlan()!.planID,
        observedTick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 4),
        candidateIndex: 0,
        worldFingerprint: fingerprint
    )
}

@discardableResult
private func gateFB03Birth(
    _ session: inout AgentSimulationSession,
    fingerprint: Int = 60_303
) throws -> AgentBirthRecord {
    try session.applyBirthSiteObservation(
        gateFB03BirthObservation(session, fingerprint: fingerprint)
    )!
}

private func gateFB03MigrationObservation(
    tick: Int
) -> AgentMigrationWorldObservation {
    AgentMigrationWorldObservation(
        worldTick: tick, candidateIndex: 0,
        entryPosition: AgentPosition(x: 1, y: 64, z: 3),
        receptionPosition: gateFB03MainReception,
        route: [
            AgentPosition(x: 1, y: 64, z: 3),
            gateFB03MainReception,
        ]
    )
}

private func gateFB03SettlementRoute(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    var route = [from]
    var current = from
    while current.x != to.x {
        current = AgentPosition(
            x: current.x + (current.x < to.x ? 1 : -1),
            y: current.y, z: current.z
        )
        route.append(current)
    }
    while current.z != to.z {
        current = AgentPosition(
            x: current.x, y: current.y,
            z: current.z + (current.z < to.z ? 1 : -1)
        )
        route.append(current)
    }
    return route
}

private func gateFB03CurrentIdentitySetsEqual(
    _ session: AgentSimulationSession
) -> Bool {
    Set(session.populationSnapshot().members.map(\.agentID))
        == Set(session.populationScaleSnapshot().fidelityRecords.map(\.agentID))
}

private func gateFB03ObserverBinding(
    tick: Int
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-03-world",
        storageIdentity: "memory:gate-f-blocker-03",
        seed: 603, dimension: 0, observedWorldTick: tick
    )
}

private func gateFB03CorruptCheckpointRemovingFidelity(
    _ checkpoint: AgentSessionCheckpoint,
    agentID: AgentID
) throws -> AgentSessionCheckpoint {
    let encoded = try AgentCheckpointCodec.encode(checkpoint)
    var root = try JSONSerialization.jsonObject(with: encoded)
        as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    var population = durable["populationRegistry"] as! [String: Any]
    var scale = population["scaleState"] as! [String: Any]
    let records = scale["fidelityRecords"] as! [[String: Any]]
    scale["fidelityRecords"] = records.filter {
        ($0["agentID"] as? String) != agentID.rawValue
    }
    population["scaleState"] = scale
    durable["populationRegistry"] = population
    root["durableState"] = durable

    let provisionalData = try JSONSerialization.data(
        withJSONObject: root, options: [.sortedKeys]
    )
    let provisional = try AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: provisionalData
    )
    let durableBytes = try AgentCheckpointCodec.encode(
        provisional.durableState
    )
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(provisional.simulationID.rawValue.utf8)
    )
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-"
        + simulationDigest.rawValue.prefix(12)
        + "-t\(provisional.tick.rawValue)-"
        + digest.rawValue.prefix(16)
    let correctedData = try JSONSerialization.data(
        withJSONObject: root, options: [.sortedKeys]
    )
    return try AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: correctedData
    )
}

func runPebbleAgentsGateFBlocker03Smoke() {
    section("Gate F Blocker 03 dynamic fidelity authority")

    var historical = gateFB03Session(
        id: "gate-f-b03-historical", maximumPopulation: 4,
        maximumLiveAgents: 4
    )
    let preBirthScale = historical.populationScaleSnapshot()
    let historicalBirth = try! gateFB03Birth(&historical)
    let historicalPopulation = historical.populationSnapshot()
    let historicalScale = historical.populationScaleSnapshot()
    let historicalFidelity = historicalScale.fidelityRecords.filter {
        $0.agentID == historicalBirth.newbornID
    }
    check("Gate F B03 historical fixture reaches exact population capacity",
          historicalPopulation.members.count == 4
            && historicalPopulation.settlement?.residentIDs.count == 4
            && historicalPopulation.settlement?.capacity == 4)
    check("Gate F B03 newborn singular in state population and lifecycle",
          historical.snapshot().agents.filter {
              $0.id == historicalBirth.newbornID.rawValue
          }.count == 1
            && historicalPopulation.members.filter {
                $0.agentID == historicalBirth.newbornID
            }.count == 1
            && historical.lifecycleSnapshot().members.filter {
                $0.agentID == historicalBirth.newbornID
            }.count == 1
            && historical.lifecycleSnapshot().births.filter {
                $0.newbornID == historicalBirth.newbornID
            }.count == 1)
    check("Gate F B03 newborn receives one immediate fidelity authority",
          historicalFidelity.count == 1
            && historicalScale.fidelityRecords.count == 4)
    check("Gate F B03 active population and fidelity identity sets equal",
          gateFB03CurrentIdentitySetsEqual(historical))
    let newbornTransition = historicalScale.fidelityTransitions.last {
        $0.agentID == historicalBirth.newbornID && $0.from == nil
    }
    let fidelityEvent = newbornTransition.flatMap { transition in
        historical.causalLedgerSnapshot().events.first {
            $0.eventID == transition.eventID
        }
    }
    let finalizedEvent = historical.causalLedgerSnapshot().events.first {
        $0.eventID == historicalBirth.finalizedEventID
    }
    check("Gate F B03 fidelity transition is causal birth history",
          newbornTransition?.ordinal
            == preBirthScale.evictedFidelityTransitionCount
                + UInt64(preBirthScale.fidelityTransitions.count) + 1
            && newbornTransition?.cause == .initialPolicy
            && fidelityEvent?.causes.contains(
                historicalBirth.populationBornEventID
            ) == true
            && finalizedEvent?.causes.contains(newbornTransition!.eventID)
                == true)
    check("Gate F B03 transition record fields and scale event are coherent",
          historicalFidelity.first?.transitionCount == 1
            && historicalFidelity.first?.enteredTick == historical.tick
            && historicalFidelity.first?.lastTransitionEventID
                == newbornTransition?.eventID)
    let historicalCheckpoint = try! historical.makeCheckpoint()
    let historicalBytes = try! historical.durableStateBytes()
    let historicalRestored = try! AgentSimulationSession.restoring(
        historicalCheckpoint
    )
    check("Gate F B03 immediate post-birth schema 35 restore exact",
          historicalCheckpoint.schemaVersion == 35
            && (try! historicalRestored.durableStateBytes()) == historicalBytes
            && gateFB03CurrentIdentitySetsEqual(historicalRestored))

    var deterministicA = gateFB03Session(
        id: "gate-f-b03-deterministic", maximumPopulation: 5,
        maximumLiveAgents: 2, maximumNearAgents: 1
    )
    var deterministicB = gateFB03Session(
        id: "gate-f-b03-deterministic", maximumPopulation: 5,
        maximumLiveAgents: 2, maximumNearAgents: 1,
        founderOrder: ["agent_2", "agent_0", "agent_1"]
    )
    _ = try! gateFB03Birth(&deterministicA)
    _ = try! gateFB03Birth(&deterministicB)
    check("Gate F B03 equivalent caller order has identical durable bytes",
          (try! deterministicA.durableStateBytes())
            == (try! deterministicB.durableStateBytes()))
    check("Gate F B03 equivalent caller order has identical fidelity digest",
          deterministicA.populationScaleSnapshot().digest
            == deterministicB.populationScaleSnapshot().digest)

    var liveAvailable = gateFB03Session(
        id: "gate-f-b03-tier-live", maximumPopulation: 4,
        maximumLiveAgents: 4, maximumNearAgents: 1
    )
    let liveBirth = try! gateFB03Birth(&liveAvailable)
    check("Gate F B03 LIVE capacity available follows canonical policy",
          liveAvailable.fidelity(for: liveBirth.newbornID) == .live
            && liveAvailable.populationScaleSnapshot().liveCount == 4)

    var nearAvailable = gateFB03Session(
        id: "gate-f-b03-tier-near", maximumPopulation: 4,
        maximumLiveAgents: 3, maximumNearAgents: 1
    )
    let nearBirth = try! gateFB03Birth(&nearAvailable)
    check("Gate F B03 LIVE full NEAR available follows canonical policy",
          nearAvailable.fidelity(for: nearBirth.newbornID) == .near
            && nearAvailable.populationScaleSnapshot().liveCount == 3
            && nearAvailable.populationScaleSnapshot().nearCount == 1)

    var dormantRequired = gateFB03Session(
        id: "gate-f-b03-tier-dormant", maximumPopulation: 4,
        maximumLiveAgents: 1, maximumNearAgents: 1
    )
    let dormantBirth = try! gateFB03Birth(&dormantRequired)
    check("Gate F B03 LIVE and NEAR full creates DORMANT authority",
          dormantRequired.fidelity(for: dormantBirth.newbornID) == .dormant
            && dormantRequired.populationScaleSnapshot().liveCount == 1
            && dormantRequired.populationScaleSnapshot().nearCount == 1
            && dormantRequired.populationScaleSnapshot().dormantCount == 2)

    var compacted = gateFB03Session(
        id: "gate-f-b03-compaction", maximumPopulation: 4,
        maximumLiveAgents: 4, maximumNearAgents: 1,
        maximumFidelityTransitionHistory: 3
    )
    _ = try! gateFB03Birth(&compacted)
    let compactedScale = compacted.populationScaleSnapshot()
    check("Gate F B03 transition compaction retains every current record",
          compactedScale.fidelityTransitions.count == 3
            && compactedScale.evictedFidelityTransitionCount == 1
            && compactedScale.fidelityRecords.count == 4
            && gateFB03CurrentIdentitySetsEqual(compacted))

    var rotating = gateFB03Session(
        id: "gate-f-b03-rotation", maximumPopulation: 4,
        maximumLiveAgents: 1, maximumNearAgents: 1,
        rotationIntervalTicks: 4
    )
    let rotatingBirth = try! gateFB03Birth(&rotating)
    let immediateTier = rotating.fidelity(for: rotatingBirth.newbornID)
    while rotating.tick < 8 { _ = try! rotating.advanceTick() }
    let rotatedTier = rotating.fidelity(for: rotatingBirth.newbornID)
    let postRotationCheckpoint = try! rotating.makeCheckpoint()
    let postRotationRestored = try! AgentSimulationSession.restoring(
        postRotationCheckpoint
    )
    check("Gate F B03 newborn participates in deterministic later rotation",
          immediateTier == .dormant && rotatedTier == .near
            && rotating.populationScaleSnapshot().fidelityTransitions
                .contains {
                    $0.agentID == rotatingBirth.newbornID
                        && $0.from == .dormant && $0.to == .near
                        && $0.cause == .scheduledRotation
                })
    check("Gate F B03 post-rotation schema 35 restore exact",
          (try! postRotationRestored.durableStateBytes())
            == (try! rotating.durableStateBytes())
            && postRotationRestored.fidelity(for: rotatingBirth.newbornID)
                == rotatedTier)

    var legacy = gateFB03Session(
        id: "gate-f-b03-legacy-migration", maximumPopulation: 5,
        maximumLiveAgents: 1, maximumNearAgents: 2
    )
    let legacyRecord = try! legacy.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: gateFB03MigrationObservation(tick: legacy.tick)
    )
    let legacyScale = legacy.populationScaleSnapshot()
    let legacyCheckpoint = try! legacy.makeCheckpoint()
    let legacyRestored = try! AgentSimulationSession.restoring(legacyCheckpoint)
    check("Gate F B03 legacy imported member gets one fidelity record",
          legacyScale.fidelityRecords.filter {
              $0.agentID == legacyRecord.migrantID
          }.count == 1
            && gateFB03CurrentIdentitySetsEqual(legacy))
    check("Gate F B03 active legacy migrant pinning is authoritative",
          legacy.fidelity(for: legacyRecord.migrantID) == .live
            && legacyScale.liveCount == 1
            && legacyScale.fidelityTransitions.contains {
                $0.agentID == legacyRecord.migrantID
                    && $0.from == nil && $0.cause == .activeMigration
            })
    check("Gate F B03 legacy migration schema 35 restart exact",
          (try! legacyRestored.durableStateBytes())
            == (try! legacy.durableStateBytes())
            && legacyRestored.fidelity(for: legacyRecord.migrantID) == .live)

    var pinnedBirth = gateFB03Session(
        id: "gate-f-b03-pinned-birth", maximumPopulation: 5,
        maximumLiveAgents: 1, maximumNearAgents: 2
    )
    let pinnedMigration = try! pinnedBirth.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: gateFB03MigrationObservation(tick: pinnedBirth.tick)
    )
    let pinnedBirthRecord = try! gateFB03Birth(&pinnedBirth)
    check("Gate F B03 birth cannot steal active incoming LIVE claim",
          pinnedBirth.fidelity(for: pinnedMigration.migrantID) == .live
            && pinnedBirth.fidelity(for: pinnedBirthRecord.newbornID) != .live
            && gateFB03CurrentIdentitySetsEqual(pinnedBirth))

    var unsupported = gateFB03Session(
        id: "gate-f-b03-unsupported-pins", maximumPopulation: 5,
        maximumLiveAgents: 1, maximumNearAgents: 2
    )
    _ = try! unsupported.beginSettlementMigration(
        agentID: AgentID(rawValue: "agent_0")!,
        destinationSettlementID: gateFB03EastID,
        verifiedRoute: gateFB03SettlementRoute(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB03EastReception
        )
    )
    let unsupportedBefore = try! unsupported.durableStateBytes()
    let unsupportedRejected: Bool
    do {
        _ = try unsupported.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: gateFB03MigrationObservation(tick: unsupported.tick)
        )
        unsupportedRejected = false
    } catch AgentSessionError.population(.invalidConfiguration(let detail)) {
        unsupportedRejected = detail == "fidelity policy membership"
    } catch { unsupportedRejected = false }
    check("Gate F B03 unsupported combined fidelity pins fail closed",
          unsupportedRejected
            && unsupportedBefore == (try! unsupported.durableStateBytes()))

    var fullAfterBirth = gateFB03Session(
        id: "gate-f-b03-birth-first", maximumPopulation: 4,
        maximumLiveAgents: 4
    )
    _ = try! gateFB03Birth(&fullAfterBirth)
    let migrationRefusalBefore = try! fullAfterBirth.durableStateBytes()
    let migrationRefused: Bool
    do {
        _ = try fullAfterBirth.admitMigration(
            intent: AgentMigrationAdmissionIntent(),
            observation: gateFB03MigrationObservation(tick: fullAfterBirth.tick)
        )
        migrationRefused = false
    } catch AgentSessionError.population(.admission(.populationFull)) {
        migrationRefused = true
    } catch { migrationRefused = false }
    check("Gate F B03 birth consumes final slot before later migration",
          migrationRefused
            && migrationRefusalBefore
                == (try! fullAfterBirth.durableStateBytes()))

    var refused = gateFB03Session(
        id: "gate-f-b03-capacity-retry", maximumPopulation: 4,
        maximumLiveAgents: 4, lethalFounder2: true
    )
    var cleanRetry = gateFB03Session(
        id: "gate-f-b03-capacity-retry", maximumPopulation: 4,
        maximumLiveAgents: 4, lethalFounder2: true
    )
    for target in [0, 1] {
        if target == 0 {
            _ = try! refused.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: gateFB03MigrationObservation(tick: refused.tick)
            )
        } else {
            _ = try! cleanRetry.admitMigration(
                intent: AgentMigrationAdmissionIntent(),
                observation: gateFB03MigrationObservation(tick: cleanRetry.tick)
            )
        }
    }
    let refusalBytes = try! refused.durableStateBytes()
    let refusalPopulation = refused.populationSnapshot()
    let refusalLifecycle = refused.lifecycleSnapshot()
    let refusalScale = refused.populationScaleSnapshot()
    let refusalEvents = refused.causalLedgerSnapshot()
    let birthRefused: Bool
    do {
        _ = try gateFB03Birth(&refused)
        birthRefused = false
    } catch AgentSessionError.lifecycle(.populationFull) {
        birthRefused = true
    } catch { birthRefused = false }
    check("Gate F B03 committed full capacity rejects birth before publication",
          birthRefused)
    check("Gate F B03 rejected birth preserves bytes and all owning state",
          refusalBytes == (try! refused.durableStateBytes())
            && refusalPopulation == refused.populationSnapshot()
            && refusalLifecycle == refused.lifecycleSnapshot()
            && refusalScale == refused.populationScaleSnapshot()
            && refusalEvents == refused.causalLedgerSnapshot())
    for index in 0..<2 {
        if index == 0 {
            refused.setSurvivalEnabled(true)
            try! refused.setMortalityEnabled(true)
            _ = try! refused.advanceTick()
            _ = try! gateFB03Birth(&refused, fingerprint: 60_304)
        } else {
            cleanRetry.setSurvivalEnabled(true)
            try! cleanRetry.setMortalityEnabled(true)
            _ = try! cleanRetry.advanceTick()
            _ = try! gateFB03Birth(&cleanRetry, fingerprint: 60_304)
        }
    }
    check("Gate F B03 real death frees one slot for no-gap birth retry",
          !refused.expectedActiveAgentIDs().contains(
              AgentID(rawValue: "agent_2")!
          )
            && refused.populationSnapshot().members.count == 4
            && refused.lifecycleSnapshot().totalBirthCount == 1
            && gateFB03CurrentIdentitySetsEqual(refused))
    check("Gate F B03 rejected attempt leaves retry byte-identical to clean path",
          (try! refused.durableStateBytes())
            == (try! cleanRetry.durableStateBytes()))

    var newbornDeath = gateFB03Session(
        id: "gate-f-b03-newborn-death", maximumPopulation: 4,
        maximumLiveAgents: 4, newbornLethalSurvival: true
    )
    let deathBirth = try! gateFB03Birth(&newbornDeath)
    newbornDeath.setSurvivalEnabled(true)
    try! newbornDeath.setMortalityEnabled(true)
    _ = try! newbornDeath.advanceTick()
    let newbornDeathCheckpoint = try! newbornDeath.makeCheckpoint()
    let newbornDeathRestored = try! AgentSimulationSession.restoring(
        newbornDeathCheckpoint
    )
    check("Gate F B03 scaled-born mortality removes current fidelity once",
          newbornDeath.mortalitySnapshot().records.filter {
              $0.agentID == deathBirth.newbornID
          }.count == 1
            && !newbornDeath.populationSnapshot().members.contains {
                $0.agentID == deathBirth.newbornID
            }
            && !newbornDeath.populationScaleSnapshot().fidelityRecords
                .contains { $0.agentID == deathBirth.newbornID }
            && gateFB03CurrentIdentitySetsEqual(newbornDeath))
    check("Gate F B03 post-mortality schema 35 restore exact",
          (try! newbornDeathRestored.durableStateBytes())
            == (try! newbornDeath.durableStateBytes())
            && newbornDeathRestored.mortalitySnapshot().records.filter {
                $0.agentID == deathBirth.newbornID
            }.count == 1)

    let observerBefore = try! historical.durableStateBytes()
    let observer = historical.observerSnapshot(
        worldBinding: gateFB03ObserverBinding(tick: historical.tick)
    )
    check("Gate F B03 Observer 13 exposes newborn identity and fidelity read-only",
          observer.header.schemaVersion == 13
            && observer.individuals.first {
                $0.agentID == historicalBirth.newbornID
            }?.populationContext?.fidelity
                == historical.fidelity(for: historicalBirth.newbornID)
            && observerBefore == (try! historical.durableStateBytes()))

    let corrupt = try! gateFB03CorruptCheckpointRemovingFidelity(
        historicalCheckpoint, agentID: historicalBirth.newbornID
    )
    let corruptRejected: Bool
    do {
        _ = try AgentSimulationSession.restoring(corrupt)
        corruptRejected = false
    } catch AgentCheckpointError.invalidBound("population scale") {
        corruptRejected = true
    } catch { corruptRejected = false }
    check("Gate F B03 schema 35 still rejects missing fidelity authority",
          corruptRejected)

    let semanticDigest = try! historical.durableStateDigest()
    print("GATE_F_BLOCKER_03_PROOF"
        + " population=\(historicalPopulation.members.count)"
        + " fidelity=\(historicalScale.fidelityRecords.count)"
        + " newbornTier=\(historical.fidelity(for: gateFB03NewbornID).rawValue)"
        + " checkpointSchema=\(historicalCheckpoint.schemaVersion)"
        + " semanticDigest=\(semanticDigest.rawValue)"
        + " scaleDigest=\(historicalScale.digest)")
}
