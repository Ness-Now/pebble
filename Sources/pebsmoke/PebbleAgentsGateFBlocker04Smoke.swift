import Foundation
import PebbleAgents

private let gateFB04EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB04Main = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB04East = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB04Habitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 60_404, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private func gateFB04Agent(
    _ ordinal: Int,
    sharedOrigin: Bool,
    lethal: Bool = false,
    protectedFromOneFullHungerTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    let home = sharedOrigin && ordinal < 2 ? gateFB04Main : position
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethal ? 1 : (protectedFromOneFullHungerTick ? -1 : 0),
            fatigue: 0,
            curiosity: 0.1, safety: 1
        ),
        health: lethal ? 10 : 100, fear: 0,
        homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 04 fixture",
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
            status: lethal ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethal ? 2 : 0
        )
    )
}

private func gateFB04Route(
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

private func gateFB04DetourRoute(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    var route = [from]
    var current = AgentPosition(x: from.x, y: from.y, z: from.z + 1)
    route.append(current)
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

private func gateFB04Session(
    _ id: String,
    sharedOrigin: Bool,
    householdConfiguration: AgentHouseholdConfiguration = .live,
    reproduction: Bool = false,
    dependentCare: Bool = false,
    childhood: Bool = false,
    lethalAgent0: Bool = false,
    lethalAgentOrdinal: Int? = nil,
    maximumLiveAgents: Int = 3,
    maximumNearAgents: Int = 1,
    rotationIntervalTicks: Int = 4,
    founderOrder: [Int] = [0, 1, 2]
) -> AgentSimulationSession {
    let lethalOrdinal = lethalAgent0 ? 0 : lethalAgentOrdinal
    let live = AgentSurvivalConfiguration.live
    let survival = lethalOrdinal != nil
        ? try! AgentSurvivalConfiguration(
            hungerPerTick: 1,
            fatiguePerTick: live.fatiguePerTick,
            hungryThreshold: live.hungryThreshold,
            criticalHungerThreshold: live.criticalHungerThreshold,
            hungerRecoveryThreshold: live.hungerRecoveryThreshold,
            fatigueThreshold: live.fatigueThreshold,
            fatigueRecoveryThreshold: live.fatigueRecoveryThreshold,
            foodNutrition: live.foodNutrition,
            restRecoveryPerTick: live.restRecoveryPerTick,
            starvationGraceTicks: 0,
            starvationDamagePerTick: 100
        ) : live
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 604, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: founderOrder.map {
            gateFB04Agent(
                $0, sharedOrigin: sharedOrigin,
                lethal: lethalOrdinal == $0,
                protectedFromOneFullHungerTick:
                    lethalOrdinal != nil && lethalOrdinal != $0
            )
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB04Main,
        receptionPosition: gateFB04Main,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 6,
            maximumMigrationRecords: 16
        )
    )
    if reproduction || dependentCare {
        try! session.initializeLocalEcology(observations: [gateFB04Habitat])
        _ = try! session.applyLocalEcologyEndOfTick(
            habitatValidations: [gateFB04Habitat]
        )
    }
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(
        true, configuration: householdConfiguration
    )
    if dependentCare {
        session.setSurvivalEnabled(true)
        try! session.setDependentCareEnabled(true)
        if childhood { try! session.setChildhoodV2Enabled(true) }
    }
    if reproduction { try! session.setReproductionEnabled(true) }
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB04EastID,
            anchor: gateFB04East,
            receptionPosition: gateFB04East,
            capacity: 4,
            residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: maximumLiveAgents,
            maximumNearAgents: maximumNearAgents,
            nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8,
            rotationIntervalTicks: rotationIntervalTicks,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB04Perception(
    session: AgentSimulationSession,
    migration: AgentSettlementMigrationRecord
) -> AgentPerceptionInput {
    let state = try! session.state(for: migration.agentID)
    func column(_ position: AgentPosition) -> AgentWorldColumnObservation {
        AgentWorldColumnObservation(
            position: position, chunkReady: true, surfaceY: position.y,
            height: position.y, blockBelow: 1, blockAtFeet: 0,
            blockAtHead: 0, groundPresent: true, feetClear: true,
            headClear: true
        )
    }
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let target = AgentPosition(
            x: state.position.x + direction.dx,
            y: state.position.y,
            z: state.position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction, column: column(target), stepDelta: 0,
            traversable: true, dangerousDrop: false
        )
    }
    return AgentPerceptionInput(
        agentId: migration.agentID.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: column(state.position), neighbors: neighbors,
            biomeId: 1, biomeName: "plains", combinedLight: 15,
            skyLight: 15, blockLight: 0, dayTime: 6_000,
            raining: false, thundering: false
        ),
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1,
            origin: state.position, target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func gateFB04Begin(
    _ session: inout AgentSimulationSession,
    agentID: AgentID = AgentID(rawValue: "agent_0")!
) throws -> AgentSettlementMigrationRecord {
    let state = try session.state(for: agentID)
    return try session.beginSettlementMigration(
        agentID: agentID,
        destinationSettlementID: gateFB04EastID,
        verifiedRoute: gateFB04Route(from: state.position, to: gateFB04East)
    )
}

@discardableResult
private func gateFB04AdvanceMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID = AgentID(rawValue: "agent_0")!
) throws -> AgentMovementOutcome {
    let migration = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }!
    _ = try session.advanceTick(perceptions: [
        gateFB04Perception(session: session, migration: migration),
    ])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    let migrant = outcomes.first { $0.agentId == agentID.rawValue }!
    try session.applyVerifiedPhysicalMovements(outcomes.map {
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
    })
    return migrant
}

private func gateFB04CompleteMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID = AgentID(rawValue: "agent_0")!
) throws {
    let count = session.populationScaleSnapshot().settlementMigrations.first {
        $0.agentID == agentID && $0.status == .inTransit
    }!.route.count
    for _ in 1..<count {
        _ = try gateFB04AdvanceMigration(&session, agentID: agentID)
    }
}

private func gateFB04ObserverBinding(
    _ session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-04-world",
        storageIdentity: "memory:gate-f-blocker-04",
        seed: 604, dimension: 0, observedWorldTick: session.tick
    )
}

private func gateFB04DuplicateCount<T: Hashable>(_ values: [T]) -> Int {
    values.count - Set(values).count
}

private func gateFB04MutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) throws -> AgentSessionCheckpoint {
    var root = try JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let provisionalBytes = try JSONSerialization.data(
        withJSONObject: durable, options: [.sortedKeys]
    )
    let provisional = try AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: provisionalBytes
    )
    let durableBytes = try AgentCheckpointCodec.encode(provisional)
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let canonical = try JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    )
}

func runPebbleAgentsGateFBlocker04Smoke() {
    section("Gate F Blocker 04 settlement migration household authority")
    let agent0 = AgentID(rawValue: "agent_0")!

    var historical = gateFB04Session(
        "gate-f-b04-historical", sharedOrigin: true,
        reproduction: true, maximumLiveAgents: 3
    )
    let originHousehold = try! historical.household(for: agent0)!
    let originMembers = try! historical.members(of: originHousehold.householdID)
    let initialOrdinal = historical.householdSnapshot().nextHouseholdOrdinal
    _ = try! gateFB04Begin(&historical)
    let inFlightCheckpoint = try! historical.makeCheckpoint()
    let inFlightBytes = try! historical.durableStateBytes()
    let inFlightRestored = try! AgentSimulationSession.restoring(inFlightCheckpoint)
    check("Gate F B04 historical fixture has multi-member origin household",
          originHousehold.settlementID == .main
            && originMembers == [agent0, AgentID(rawValue: "agent_1")!])
    check("Gate F B04 in-flight checkpoint schema 35 restores exact",
          inFlightCheckpoint.schemaVersion == 35
            && (try! inFlightRestored.durableStateBytes()) == inFlightBytes)
    check("Gate F B04 in-flight household authority remains at origin",
          try! historical.household(for: agent0)?.householdID
            == originHousehold.householdID
            && (try! historical.household(for: agent0)?.settlementID) == .main
            && (try! historical.state(for: agent0)).homePosition
                == originHousehold.residenceAnchor)
    check("Gate F B04 in-flight destination claim is singular",
          historical.populationScaleSnapshot().settlementMigrations.filter {
              $0.agentID == agent0 && $0.status == .inTransit
          }.count == 1
            && historical.populationSnapshot().settlements.first {
                $0.settlementID == gateFB04EastID
            }?.residentIDs.isEmpty == true)
    try! gateFB04CompleteMigration(&historical)
    let destinationHousehold = try! historical.household(for: agent0)!
    let arrivalMembership = try! historical.currentMembership(of: agent0)!
    let history = try! historical.membershipHistory(of: agent0)
    let population = historical.populationSnapshot()
    let lifecycle = historical.lifecycleSnapshot()
    let scale = historical.populationScaleSnapshot()
    let arrival = scale.settlementMigrations.first { $0.agentID == agent0 }!
    let ledger = historical.causalLedgerSnapshot().events
    let createdEvent = ledger.first {
        $0.eventID == destinationHousehold.createdEventID
    }
    let joinedEvent = ledger.first { $0.eventID == history.last?.joinedEventID }
    check("Gate F B04 arrival transitions current household to destination",
          destinationHousehold.householdID != originHousehold.householdID
            && destinationHousehold.settlementID == gateFB04EastID
            && destinationHousehold.residenceAnchor == gateFB04East
            && arrivalMembership.joinedReason == .settlementMigration
            && (try! historical.members(of: destinationHousehold.householdID))
                == [agent0])
    check("Gate F B04 multi-member origin household remains coherent",
          try! historical.members(of: originHousehold.householdID)
            == [AgentID(rawValue: "agent_1")!]
            && historical.householdSnapshot().households.first {
                $0.householdID == originHousehold.householdID
            }?.status == .active)
    check("Gate F B04 membership history is one closed plus one current",
          history.count == 2
            && history.filter { $0.leftTick == nil }.count == 1
            && history.first?.leftReason == .settlementMigration
            && history.last?.joinedReason == .settlementMigration
            && historical.householdSnapshot().nextHouseholdOrdinal
                == initialOrdinal! + 1)
    check("Gate F B04 household transition is caused by verified arrival",
          arrival.status == .arrived
            && createdEvent?.causes.contains(arrival.arrivedEventID!) == true
            && joinedEvent?.causes.contains(arrival.arrivedEventID!) == true)
    check("Gate F B04 population lifecycle household settlement exact",
          population.members.first { $0.agentID == agent0 }?.settlementID
            == gateFB04EastID
            && lifecycle.members.first { $0.agentID == agent0 }?.settlementID
                == gateFB04EastID
            && destinationHousehold.settlementID == gateFB04EastID
            && population.settlements.first {
                $0.settlementID == gateFB04EastID
            }?.residentIDs == [agent0])
    check("Gate F B04 arrival consumes claim into one resident exactly once",
          scale.settlementMigrations.filter {
              $0.agentID == agent0 && $0.status == .inTransit
          }.isEmpty
            && scale.settlementMigrations.filter {
                $0.agentID == agent0 && $0.status == .arrived
            }.count == 1)
    check("Gate F B04 fidelity identity remains singular",
          scale.fidelityRecords.filter { $0.agentID == agent0 }.count == 1
            && Set(scale.fidelityRecords.map(\.agentID))
                == Set(population.members.map(\.agentID)))

    let postArrivalCheckpoint = try! historical.makeCheckpoint()
    let postArrivalBytes = try! historical.durableStateBytes()
    var postArrivalRestored = try! AgentSimulationSession.restoring(
        postArrivalCheckpoint
    )
    _ = try! postArrivalRestored.advanceTick()
    check("Gate F B04 post-arrival schema 35 restore exact and next tick succeeds",
          postArrivalCheckpoint.schemaVersion == 35
            && (try! AgentSimulationSession.restoring(postArrivalCheckpoint)
                .durableStateBytes()) == postArrivalBytes
            && postArrivalRestored.tick == historical.tick + 1)

    let observerBefore = try! historical.durableStateBytes()
    let observer = historical.observerSnapshot(
        worldBinding: gateFB04ObserverBinding(historical)
    )
    let observedAgent0 = observer.individuals.first { $0.agentID == agent0 }
    check("Gate F B04 Observer schema 13 exposes destination residence",
          observer.header.schemaVersion == 13
            && observedAgent0?.populationContext?.settlementID == gateFB04EastID
            && observedAgent0?.household.householdID
                == destinationHousehold.householdID
            && observedAgent0?.household.residenceAnchor == gateFB04East)
    check("Gate F B04 Observer remains read-only",
          (try! historical.durableStateBytes()) == observerBefore)

    while historical.pendingBirthSitePlan() == nil {
        _ = try! historical.advanceTick()
    }
    let plan = historical.pendingBirthSitePlan()!
    while historical.tick < plan.dueTick { _ = try! historical.advanceTick() }
    let birth = try! historical.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: plan.planID, observedTick: historical.tick,
            position: AgentPosition(x: 3, y: 64, z: 1),
            candidateIndex: 0, worldFingerprint: 60_404
        )
    )!
    let childHousehold = try! historical.household(for: birth.newbornID)!
    check("Gate F B04 birth after migration uses actual parent settlement authority",
          childHousehold.settlementID == .main
            && historical.populationSnapshot().members.first {
                $0.agentID == birth.newbornID
            }?.settlementID == .main
            && childHousehold.householdID != destinationHousehold.householdID)

    var singleton = gateFB04Session(
        "gate-f-b04-singleton", sharedOrigin: false,
        maximumLiveAgents: 1, maximumNearAgents: 1
    )
    let singletonSource = try! singleton.household(for: agent0)!
    _ = try! gateFB04Begin(&singleton)
    try! gateFB04CompleteMigration(&singleton)
    let singletonDestination = try! singleton.household(for: agent0)!
    check("Gate F B04 singleton origin dissolves exactly once",
          singleton.householdSnapshot().households.first {
              $0.householdID == singletonSource.householdID
          }?.status == .dissolved
            && singleton.householdSnapshot().households.filter {
                $0.householdID == singletonSource.householdID
                    && $0.status == .dissolved
            }.count == 1
            && singletonDestination.settlementID == gateFB04EastID)
    check("Gate F B04 singleton exact active bound permits net-zero replacement",
          singleton.householdSnapshot().households.filter {
              $0.status == .active
          }.count == 3)
    while singleton.tick < 8 { _ = try! singleton.advanceTick() }
    let postReleaseFidelity = singleton.populationScaleSnapshot()
    check("Gate F B04 terminal arrival releases LIVE pin for later rotation",
          singleton.fidelity(for: agent0) != .live
            && postReleaseFidelity.fidelityTransitions.contains {
                $0.agentID == agent0 && $0.cause == .scheduledRotation
            }
            && gateFB04DuplicateCount(
                postReleaseFidelity.fidelityTransitions.map(\.ordinal)
            ) == 0)

    let exactActiveConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 4,
        maximumMembershipPeriods: 8,
        maximumActiveHouseholds: 3
    )
    var exactActive = gateFB04Session(
        "gate-f-b04-exact-active", sharedOrigin: false,
        householdConfiguration: exactActiveConfig
    )
    check("Gate F B04 exact active-household bound succeeds", {
        do { _ = try gateFB04Begin(&exactActive); return true } catch { return false }
    }())

    let activeRefusalConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 4,
        maximumMembershipPeriods: 8,
        maximumActiveHouseholds: 2
    )
    var activeRefusal = gateFB04Session(
        "gate-f-b04-active-refusal", sharedOrigin: true,
        householdConfiguration: activeRefusalConfig
    )
    let activeRefusalBytes = try! activeRefusal.durableStateBytes()
    check("Gate F B04 active-household N+1 refuses atomically", {
        do { _ = try gateFB04Begin(&activeRefusal); return false }
        catch AgentSessionError.household(.activeHouseholdCapacityReached) {
            return (try! activeRefusal.durableStateBytes()) == activeRefusalBytes
        } catch { return false }
    }())

    let historyRefusalConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 2,
        maximumMembershipPeriods: 8,
        maximumActiveHouseholds: 2
    )
    var historyRefusal = gateFB04Session(
        "gate-f-b04-history-refusal", sharedOrigin: true,
        householdConfiguration: historyRefusalConfig
    )
    let historyRefusalBytes = try! historyRefusal.durableStateBytes()
    check("Gate F B04 historical-household N+1 refuses atomically", {
        do { _ = try gateFB04Begin(&historyRefusal); return false }
        catch AgentSessionError.household(.householdCapacityReached) {
            return (try! historyRefusal.durableStateBytes()) == historyRefusalBytes
        } catch { return false }
    }())

    let membershipRefusalConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 4,
        maximumMembershipPeriods: 3,
        maximumActiveHouseholds: 3
    )
    var membershipRefusal = gateFB04Session(
        "gate-f-b04-membership-refusal", sharedOrigin: false,
        householdConfiguration: membershipRefusalConfig
    )
    let membershipRefusalBytes = try! membershipRefusal.durableStateBytes()
    check("Gate F B04 membership-period N+1 refuses atomically", {
        do { _ = try gateFB04Begin(&membershipRefusal); return false }
        catch AgentSessionError.household(.membershipPeriodCapacityReached) {
            return (try! membershipRefusal.durableStateBytes())
                == membershipRefusalBytes
        } catch { return false }
    }())

    let transitionRefusalConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 4,
        maximumMembershipPeriods: 8,
        maximumActiveHouseholds: 3,
        maximumHouseholdTransitionsPerTick: 3
    )
    var transitionRefusal = gateFB04Session(
        "gate-f-b04-transition-retry", sharedOrigin: false,
        householdConfiguration: transitionRefusalConfig
    )
    let transitionRefusalBytes = try! transitionRefusal.durableStateBytes()
    var transitionRefused = false
    do { _ = try gateFB04Begin(&transitionRefusal) }
    catch AgentSessionError.household(.transitionCapacityReached) {
        transitionRefused = (try! transitionRefusal.durableStateBytes())
            == transitionRefusalBytes
    } catch {}
    _ = try! transitionRefusal.advanceTick()
    let transitionRetry = try? gateFB04Begin(&transitionRefusal)
    check("Gate F B04 transition-bound refusal is atomic then retryable",
          transitionRefused && transitionRetry != nil
            && transitionRefusal.populationScaleSnapshot()
                .settlementMigrations.count == 1)

    let arrivalBoundaryConfig = try! AgentHouseholdConfiguration(
        maximumHistoricalHouseholds: 8,
        maximumMembershipPeriods: 16,
        maximumActiveHouseholds: 4,
        maximumHouseholdTransitionsPerTick: 3
    )
    var arrivalBoundary = gateFB04Session(
        "gate-f-b04-arrival-boundary", sharedOrigin: false,
        householdConfiguration: arrivalBoundaryConfig
    )
    _ = try! arrivalBoundary.advanceTick()
    _ = try! gateFB04Begin(&arrivalBoundary)
    let arrivalRouteCount = arrivalBoundary.populationScaleSnapshot()
        .settlementMigrations.first { $0.agentID == agent0 }!.route.count
    for _ in 1..<(arrivalRouteCount - 1) {
        _ = try! gateFB04AdvanceMigration(&arrivalBoundary)
    }
    let arrivalMigration = arrivalBoundary.populationScaleSnapshot()
        .settlementMigrations.first { $0.agentID == agent0 }!
    _ = try! arrivalBoundary.advanceTick(perceptions: [
        gateFB04Perception(
            session: arrivalBoundary, migration: arrivalMigration
        ),
    ])
    _ = try! arrivalBoundary.formHousehold(
        memberIDs: [
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ],
        residenceAnchor: AgentPosition(x: 3, y: 64, z: 0)
    )
    _ = try! arrivalBoundary.createSingletonHousehold(
        for: AgentID(rawValue: "agent_1")!,
        residenceAnchor: AgentPosition(x: 2, y: 64, z: 0),
        reason: .formedHousehold
    )
    let arrivalOutcomes = AgentMovementCoordinator.resolve(
        snapshot: arrivalBoundary.snapshot()
    )
    let lateRefusalBytes = try! arrivalBoundary.durableStateBytes()
    var lateRefused = false
    do {
        try arrivalBoundary.applyVerifiedPhysicalMovements(
            arrivalOutcomes.map {
                AgentVerifiedPhysicalMovement(
                    kind: .navigationStep, outcome: $0
                )
            }
        )
    } catch AgentSessionError.household(.transitionCapacityReached) {
        lateRefused = (try! arrivalBoundary.durableStateBytes())
            == lateRefusalBytes
    } catch {}
    let claimStillActive = arrivalBoundary.populationScaleSnapshot()
        .settlementMigrations.first { $0.agentID == agent0 }?.status
        == .inTransit
    _ = try! gateFB04AdvanceMigration(&arrivalBoundary)
    check("Gate F B04 late arrival-bound refusal preserves exact candidate",
          lateRefused && claimStillActive
            && arrivalBoundary.populationSnapshot().members.first {
                $0.agentID == agent0
            }?.settlementID == gateFB04EastID)

    var releasedCapacity = gateFB04Session(
        "gate-f-b04-active-release", sharedOrigin: true,
        householdConfiguration: activeRefusalConfig,
        lethalAgentOrdinal: 2
    )
    let beforeReleaseBytes = try! releasedCapacity.durableStateBytes()
    var beforeReleaseRefused = false
    do { _ = try gateFB04Begin(&releasedCapacity) }
    catch AgentSessionError.household(.activeHouseholdCapacityReached) {
        beforeReleaseRefused = (try! releasedCapacity.durableStateBytes())
            == beforeReleaseBytes
    } catch {}
    releasedCapacity.setSurvivalEnabled(true)
    try! releasedCapacity.setMortalityEnabled(true)
    _ = try! releasedCapacity.advanceTick()
    let afterRelease = try? gateFB04Begin(&releasedCapacity)
    check("Gate F B04 real social-capacity release enables one retry",
          beforeReleaseRefused && afterRelease != nil
            && releasedCapacity.householdSnapshot().households.filter {
                $0.status == .active
            }.count == 1
            && releasedCapacity.populationScaleSnapshot()
                .settlementMigrations.count == 1)

    var deterministicA = gateFB04Session(
        "gate-f-b04-deterministic", sharedOrigin: true,
        founderOrder: [0, 1, 2]
    )
    var deterministicB = gateFB04Session(
        "gate-f-b04-deterministic", sharedOrigin: true,
        founderOrder: [2, 0, 1]
    )
    _ = try! gateFB04Begin(&deterministicA)
    _ = try! gateFB04Begin(&deterministicB)
    try! gateFB04CompleteMigration(&deterministicA)
    try! gateFB04CompleteMigration(&deterministicB)
    check("Gate F B04 caller order deterministic bytes exact",
          (try! deterministicA.durableStateBytes())
            == (try! deterministicB.durableStateBytes()))

    var care = gateFB04Session(
        "gate-f-b04-care", sharedOrigin: true,
        reproduction: true, dependentCare: true, childhood: true,
        maximumLiveAgents: 4
    )
    while care.pendingBirthSitePlan() == nil { _ = try! care.advanceTick() }
    let carePlan = care.pendingBirthSitePlan()!
    while care.tick < carePlan.dueTick { _ = try! care.advanceTick() }
    let careBirth = try! care.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: carePlan.planID, observedTick: care.tick,
            position: AgentPosition(x: 1, y: 64, z: 0),
            candidateIndex: 0, worldFingerprint: 60_405
        )
    )!
    let careAssignment = care.dependentCareSnapshot().assignments.first {
        $0.dependentID == careBirth.newbornID && $0.status == .active
    }!
    let caregiverBytes = try! care.durableStateBytes()
    var caregiverRefused = false
    do { _ = try gateFB04Begin(&care, agentID: careAssignment.caregiverID) }
    catch AgentSessionError.dependentCare(.invalidState(
        "settlement migration requires unsupported care relocation"
    )) {
        caregiverRefused = (try! care.durableStateBytes()) == caregiverBytes
    } catch {}
    let newbornBytes = try! care.durableStateBytes()
    var newbornRefused = false
    do { _ = try gateFB04Begin(&care, agentID: careBirth.newbornID) }
    catch AgentSessionError.dependentCare(.capabilityDenied(
        careBirth.newbornID, .voluntaryMigration
    )) {
        newbornRefused = (try! care.durableStateBytes()) == newbornBytes
    } catch {}
    check("Gate F B04 active caregiver relocation fails before movement",
          caregiverRefused)
    check("Gate F B04 newborn voluntary migration fails before movement",
          newbornRefused)
    check("Gate F B04 care and guardianship authority remain unchanged on refusal",
          care.dependentCareSnapshot().assignments.filter {
              $0.status == .active && $0.dependentID == careBirth.newbornID
          }.count == 1
            && care.childhoodSnapshot().guardianships.filter {
                $0.status == .active && $0.dependentID == careBirth.newbornID
            }.count == 1)
    let agent2 = AgentID(rawValue: "agent_2")!
    let agent2State = try! care.state(for: agent2)
    _ = try! care.beginSettlementMigration(
        agentID: agent2,
        destinationSettlementID: gateFB04EastID,
        verifiedRoute: gateFB04DetourRoute(
            from: agent2State.position, to: gateFB04East
        )
    )
    try! gateFB04CompleteMigration(&care, agentID: agent2)
    check("Gate F B04 birth then unrelated adult migration remains coherent",
          (try! care.household(for: agent2)?.settlementID) == gateFB04EastID
            && (try! care.household(for: careBirth.newbornID)?.settlementID)
                == .main
            && Set(care.populationSnapshot().members.map(\.agentID))
                == Set(care.populationScaleSnapshot().fidelityRecords.map(\.agentID)))

    var plannedParent = gateFB04Session(
        "gate-f-b04-planned-parent", sharedOrigin: true,
        reproduction: true, maximumLiveAgents: 3
    )
    while plannedParent.pendingBirthSitePlan() == nil {
        _ = try! plannedParent.advanceTick()
    }
    let parentPlan = plannedParent.pendingBirthSitePlan()!
    precondition(parentPlan.progenitorIDs.contains(agent0))
    _ = try! gateFB04Begin(&plannedParent)
    try! gateFB04CompleteMigration(&plannedParent)
    let refusedBirth = try! plannedParent.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: parentPlan.planID, observedTick: plannedParent.tick,
            position: AgentPosition(x: 3, y: 64, z: 1),
            candidateIndex: 0, worldFingerprint: 60_406
        )
    )
    check("Gate F B04 migrated planned parent birth fails closed explicitly",
          refusedBirth == nil
            && plannedParent.lifecycleSnapshot().plans.first {
                $0.planID == parentPlan.planID
            }?.reason == .parentUnavailable
            && plannedParent.populationSnapshot().members.count == 3)

    var arrivedDeath = gateFB04Session(
        "gate-f-b04-arrived-death", sharedOrigin: false,
        lethalAgent0: true
    )
    _ = try! gateFB04Begin(&arrivedDeath)
    try! gateFB04CompleteMigration(&arrivedDeath)
    let deathHouseholdID = try! arrivedDeath.household(for: agent0)!.householdID
    arrivedDeath.setSurvivalEnabled(true)
    try! arrivedDeath.setMortalityEnabled(true)
    _ = try! arrivedDeath.advanceTick()
    let arrivedDeathCheckpoint = try! arrivedDeath.makeCheckpoint()
    check("Gate F B04 post-arrival mortality closes destination authority",
          !arrivedDeath.populationSnapshot().members.contains {
              $0.agentID == agent0
          }
            && !arrivedDeath.populationScaleSnapshot().fidelityRecords.contains {
                $0.agentID == agent0
            }
            && arrivedDeath.householdSnapshot().currentMemberships.first {
                $0.agentID == agent0
            } == nil
            && arrivedDeath.householdSnapshot().households.first {
                $0.householdID == deathHouseholdID
            }?.status == .dissolved)
    check("Gate F B04 post-arrival mortality schema 35 restores exact",
          arrivedDeathCheckpoint.schemaVersion == 35
            && (try! AgentSimulationSession.restoring(arrivedDeathCheckpoint)
                .durableStateBytes()) == (try! arrivedDeath.durableStateBytes()))

    var originRemainderDeath = gateFB04Session(
        "gate-f-b04-origin-remainder-death", sharedOrigin: true,
        lethalAgentOrdinal: 1
    )
    let remainderOrigin = try! originRemainderDeath.household(for: agent0)!
        .householdID
    _ = try! gateFB04Begin(&originRemainderDeath)
    try! gateFB04CompleteMigration(&originRemainderDeath)
    originRemainderDeath.setSurvivalEnabled(true)
    try! originRemainderDeath.setMortalityEnabled(true)
    _ = try! originRemainderDeath.advanceTick()
    check("Gate F B04 last origin household member death dissolves history once",
          originRemainderDeath.householdSnapshot().households.filter {
              $0.householdID == remainderOrigin && $0.status == .dissolved
          }.count == 1
            && (try! originRemainderDeath.household(for: agent0)?.settlementID)
                == gateFB04EastID)

    var inFlightDeath = gateFB04Session(
        "gate-f-b04-inflight-death", sharedOrigin: false,
        lethalAgent0: true
    )
    let inFlightDeathSource = try! inFlightDeath.household(for: agent0)!.householdID
    _ = try! gateFB04Begin(&inFlightDeath)
    inFlightDeath.setSurvivalEnabled(true)
    try! inFlightDeath.setMortalityEnabled(true)
    _ = try! inFlightDeath.advanceTick()
    check("Gate F B04 in-flight death terminates claim without destination household",
          inFlightDeath.populationScaleSnapshot().settlementMigrations.first {
              $0.agentID == agent0
          }?.status == .failed
            && inFlightDeath.householdSnapshot().households.first {
                $0.householdID == inFlightDeathSource
            }?.status == .dissolved
            && !inFlightDeath.householdSnapshot().households.contains {
                $0.settlementID == gateFB04EastID
            })

    let malformed = try! gateFB04MutatedCheckpoint(postArrivalCheckpoint) {
        durable in
        var household = durable["householdState"] as! [String: Any]
        var records = household["households"] as! [[String: Any]]
        let destinationIndex = records.firstIndex {
            ($0["householdID"] as? String)
                == destinationHousehold.householdID.rawValue
        }!
        records[destinationIndex]["settlementID"] = AgentSettlementID.main.rawValue
        household["households"] = records
        durable["householdState"] = household
    }
    check("Gate F B04 malformed cross-settlement household restore rejected", {
        do { _ = try AgentSimulationSession.restoring(malformed); return false }
        catch AgentCheckpointError.invalidBound("household") { return true }
        catch { return false }
    }())

    let finalPopulation = historical.populationSnapshot()
    let finalHouseholds = historical.householdSnapshot()
    let finalScale = historical.populationScaleSnapshot()
    check("Gate F B04 final identity and membership singularity",
          gateFB04DuplicateCount(historical.snapshot().agents.map(\.id)) == 0
            && gateFB04DuplicateCount(finalPopulation.members.map(\.agentID)) == 0
            && gateFB04DuplicateCount(finalScale.fidelityRecords.map(\.agentID)) == 0
            && gateFB04DuplicateCount(finalHouseholds.currentMemberships.map(\.agentID)) == 0
            && Set(finalHouseholds.currentMemberships.map(\.agentID))
                == Set(finalPopulation.members.map(\.agentID)))
    check("Gate F B04 no duplicate arrivals births or migration authority",
          finalScale.settlementMigrations.filter {
              $0.agentID == agent0 && $0.status == .arrived
          }.count == 1
            && historical.lifecycleSnapshot().births.filter {
                $0.newbornID == birth.newbornID
            }.count == 1
            && finalPopulation.settlements.flatMap(\.residentIDs)
                .filter { $0 == agent0 }.count == 1)
}
