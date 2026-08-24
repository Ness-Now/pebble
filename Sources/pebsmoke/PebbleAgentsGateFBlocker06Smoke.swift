import Foundation
import PebbleAgents

private let gateFB06Agent0 = AgentID(rawValue: "agent_0")!
private let gateFB06Agent1 = AgentID(rawValue: "agent_1")!
private let gateFB06EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB06WestID = AgentSettlementID(rawValue: "settlement-west")!
private let gateFB06Main = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB06East = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB06West = AgentPosition(x: -4, y: 64, z: 4)

private func gateFB06Agent(_ ordinal: Int, mortalityPressure: Bool = false)
    -> AgentSessionAgentState
{
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    let hunger = mortalityPressure ? (ordinal == 0 ? 0.0 : -1.0) : 0.0
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: hunger, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 06 fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: .stable, consecutiveCriticalHungerTicks: 0
        )
    )
}

private func gateFB06Route(
    from: AgentPosition, to: AgentPosition
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

private func gateFB06Session(
    _ id: String,
    migrationHistory: Int = 8,
    socialDomains: Bool = true,
    mortalityPressure: Bool = false
) -> AgentSimulationSession {
    let live = AgentSurvivalConfiguration.live
    let survival = mortalityPressure
        ? try! AgentSurvivalConfiguration(
            hungerPerTick: 0.09, fatiguePerTick: live.fatiguePerTick,
            hungryThreshold: live.hungryThreshold,
            criticalHungerThreshold: live.criticalHungerThreshold,
            hungerRecoveryThreshold: live.hungerRecoveryThreshold,
            fatigueThreshold: live.fatigueThreshold,
            fatigueRecoveryThreshold: live.fatigueRecoveryThreshold,
            foodNutrition: live.foodNutrition,
            restRecoveryPerTick: live.restRecoveryPerTick,
            starvationGraceTicks: 0, starvationDamagePerTick: 100
        ) : live
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 606, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map {
            gateFB06Agent($0, mortalityPressure: mortalityPressure)
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB06Main,
        receptionPosition: gateFB06Main,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 6, maximumMigrationRecords: 16
        )
    )
    if socialDomains {
        try! session.setLifecycleEnabled(true)
        try! session.setKinshipEnabled(true)
        try! session.setHouseholdsEnabled(true)
    }
    try! session.initializePopulationScaling(
        additionalSettlements: [
            AgentPopulationSettlement(
                settlementID: gateFB06EastID, anchor: gateFB06East,
                receptionPosition: gateFB06East, capacity: 4,
                residentIDs: [], inTransitIDs: []
            ),
            AgentPopulationSettlement(
                settlementID: gateFB06WestID, anchor: gateFB06West,
                receptionPosition: gateFB06West, capacity: 4,
                residentIDs: [], inTransitIDs: []
            ),
        ],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 3, maximumLiveAgents: 3,
            maximumNearAgents: 1, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 8,
            maximumFidelityTransitionHistory: 64,
            maximumSettlementMigrationHistory: migrationHistory,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB06Perception(
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
            x: state.position.x + direction.dx, y: state.position.y,
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
            worldTick: session.tick + 1, origin: state.position,
            target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func gateFB06Begin(
    _ session: inout AgentSimulationSession,
    agentID: AgentID,
    destinationID: AgentSettlementID
) throws -> AgentSettlementMigrationRecord {
    let state = try session.state(for: agentID)
    let destination = session.populationSnapshot().settlements.first {
        $0.settlementID == destinationID
    }!
    return try session.beginSettlementMigration(
        agentID: agentID, destinationSettlementID: destinationID,
        verifiedRoute: gateFB06Route(
            from: state.position, to: destination.receptionPosition
        )
    )
}

@discardableResult
private func gateFB06Advance(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws -> AgentMovementOutcome {
    let migration = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }!
    _ = try session.advanceTick(perceptions: [
        gateFB06Perception(session: session, migration: migration),
    ])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    let migrant = outcomes.first { $0.agentId == agentID.rawValue }!
    try session.applyVerifiedPhysicalMovements(outcomes.map {
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
    })
    return migrant
}

private func gateFB06Complete(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws {
    let count = session.populationScaleSnapshot().settlementMigrations.first {
        $0.agentID == agentID && $0.status == .inTransit
    }!.route.count
    for _ in 0..<(count + 2) {
        guard session.populationScaleSnapshot().settlementMigrations.contains(
            where: { $0.agentID == agentID && $0.status == .inTransit }
        ) else { return }
        _ = try gateFB06Advance(&session, agentID: agentID)
    }
    let state = try session.state(for: agentID)
    let migration = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }
    throw AgentSessionError.population(
        .invalidMigration(
            "Gate F Blocker 06 completion bound position=\(state.position) "
                + "navigation=\(state.navigationProgress.status.rawValue) "
                + "routeCursor=\(migration?.routeCursor ?? -1)"
        )
    )
}

private func gateFB06NextOrdinal(_ session: AgentSimulationSession) -> UInt64 {
    session.durableState().populationRegistry!.scaleState!
        .nextSettlementMigrationOrdinal
}

private func gateFB06MutatedCheckpoint(
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

private func gateFB06RestoreRejects(_ checkpoint: AgentSessionCheckpoint) -> Bool {
    do { _ = try AgentSimulationSession.restoring(checkpoint); return false }
    catch { return true }
}

private func gateFB06ScaleMutation(
    _ durable: inout [String: Any],
    mutate: (inout [String: Any]) -> Void
) {
    var registry = durable["populationRegistry"] as! [String: Any]
    var scale = registry["scaleState"] as! [String: Any]
    mutate(&scale)
    registry["scaleState"] = scale
    durable["populationRegistry"] = registry
}

private func gateFB06ObserverBinding(
    _ session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-06-world",
        storageIdentity: "memory:gate-f-blocker-06",
        seed: 606, dimension: 0, observedWorldTick: session.tick
    )
}

func runPebbleAgentsGateFBlocker06Smoke() {
    section("Gate F Blocker 06 sequential migration history authority")

    var sequential = gateFB06Session("gate-f-b06-sequential")
    let initialHouseholdOrdinal = sequential.householdSnapshot()
        .nextHouseholdOrdinal!
    let migration1 = try! gateFB06Begin(
        &sequential, agentID: gateFB06Agent0, destinationID: gateFB06EastID
    )
    let migration1InFlight = try! sequential.makeCheckpoint()
    check("Gate F B06 one-migration inTransit control restores exact",
          migration1.migrationID.rawValue == "settlement-migration-00000001"
            && migration1InFlight.schemaVersion == 35
            && (try! AgentSimulationSession.restoring(migration1InFlight)
                .durableStateBytes()) == (try! sequential.durableStateBytes()))
    try! gateFB06Complete(&sequential, agentID: gateFB06Agent0)
    let migration1Checkpoint = try! sequential.makeCheckpoint()
    var afterMigration1 = try! AgentSimulationSession.restoring(
        migration1Checkpoint
    )
    check("Gate F B06 migration 1 terminal arrival restores exact",
          afterMigration1.populationScaleSnapshot().settlementMigrations
            .first?.status == .arrived
            && gateFB06NextOrdinal(afterMigration1) == 2
            && (try! afterMigration1.durableStateBytes())
                == (try! sequential.durableStateBytes()))
    _ = try! afterMigration1.advanceTick()
    let migration2 = try! gateFB06Begin(
        &afterMigration1, agentID: gateFB06Agent0,
        destinationID: .main
    )
    let beforeCheckpoint2 = try! afterMigration1.durableStateBytes()
    let migration2Checkpoint = try! afterMigration1.makeCheckpoint()
    let afterCheckpoint2 = try! afterMigration1.durableStateBytes()
    var restoredMigration2 = try! AgentSimulationSession.restoring(
        migration2Checkpoint
    )
    let scale2 = restoredMigration2.populationScaleSnapshot()
    let population2 = restoredMigration2.populationSnapshot()
    check("Gate F B06 exact Evaluation 06 second-inTransit restore passes",
          migration2.migrationID.rawValue == "settlement-migration-00000002"
            && migration2Checkpoint.schemaVersion == 35
            && beforeCheckpoint2 == afterCheckpoint2
            && (try! restoredMigration2.durableStateBytes()) == beforeCheckpoint2)
    check("Gate F B06 migration 1 remains immutable terminal history",
          scale2.settlementMigrations.count == 2
            && scale2.settlementMigrations[0].status == .arrived
            && scale2.settlementMigrations[0].destinationSettlementID
                == gateFB06EastID)
    check("Gate F B06 migration 2 is sole current inTransit authority",
          scale2.settlementMigrations.filter { $0.status == .inTransit }.count == 1
            && population2.members.first { $0.agentID == gateFB06Agent0 }?
                .settlementID == gateFB06EastID
            && population2.settlements.first {
                $0.settlementID == gateFB06EastID
            }?.inTransitIDs == [gateFB06Agent0]
            && population2.settlements.flatMap(\.residentIDs)
                .filter { $0 == gateFB06Agent0 }.isEmpty)
    check("Gate F B06 second migration owns one LIVE fidelity and one destination claim",
          scale2.fidelityRecords.filter {
              $0.agentID == gateFB06Agent0 && $0.fidelity == .live
          }.count == 1
            && population2.settlements.first { $0.settlementID == .main }!
                .residentIDs.count + 1
                <= population2.settlements.first {
                    $0.settlementID == .main
                }!.capacity
            && gateFB06NextOrdinal(restoredMigration2) == 3)
    check("Gate F B06 inTransit household authority remains singular at origin",
          (try! restoredMigration2.household(for: gateFB06Agent0))?
            .settlementID == gateFB06EastID
            && restoredMigration2.householdSnapshot().currentMemberships.filter {
                $0.agentID == gateFB06Agent0
            }.count == 1)

    try! gateFB06Complete(&restoredMigration2, agentID: gateFB06Agent0)
    let migration2ArrivalCheckpoint = try! restoredMigration2.makeCheckpoint()
    var afterMigration2 = try! AgentSimulationSession.restoring(
        migration2ArrivalCheckpoint
    )
    let arrivalsAfter2 = afterMigration2.causalLedgerSnapshot().events.filter {
        $0.kind == .settlementMigrationArrived
            && $0.actorID == gateFB06Agent0
    }.count
    check("Gate F B06 migration 2 arrival schema35 restores exact",
          (try! afterMigration2.durableStateBytes())
            == (try! restoredMigration2.durableStateBytes())
            && afterMigration2.currentSettlementID(for: gateFB06Agent0) == .main
            && afterMigration2.populationScaleSnapshot().settlementMigrations
                .filter { $0.status == .arrived }.count == 2)
    check("Gate F B06 second arrival advances household history without revival",
          (try! afterMigration2.household(for: gateFB06Agent0))?
            .settlementID == .main
            && (try! afterMigration2.household(for: gateFB06Agent0))?
                .residenceAnchor == gateFB06Main
            && (try! afterMigration2.membershipHistory(of: gateFB06Agent0))
                .count == 3
            && afterMigration2.householdSnapshot().nextHouseholdOrdinal
                == initialHouseholdOrdinal + 2)
    _ = try! afterMigration2.advanceTick()
    check("Gate F B06 post-second-restore continuation replays no arrival",
          afterMigration2.causalLedgerSnapshot().events.filter {
              $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB06Agent0
          }.count == arrivalsAfter2)

    let migration3 = try! gateFB06Begin(
        &afterMigration2, agentID: gateFB06Agent0,
        destinationID: gateFB06EastID
    )
    let migration3Checkpoint = try! afterMigration2.makeCheckpoint()
    var afterMigration3 = try! AgentSimulationSession.restoring(
        migration3Checkpoint
    )
    try! gateFB06Complete(&afterMigration3, agentID: gateFB06Agent0)
    let migration3Arrival = try! afterMigration3.makeCheckpoint()
    let migration3Restored = try! AgentSimulationSession.restoring(
        migration3Arrival
    )
    check("Gate F B06 publicly supported third migration restores and arrives",
          migration3.migrationID.rawValue == "settlement-migration-00000003"
            && gateFB06NextOrdinal(afterMigration3) == 4
            && migration3Restored.currentSettlementID(for: gateFB06Agent0)
                == gateFB06EastID
            && migration3Restored.populationScaleSnapshot().settlementMigrations
                .filter { $0.status == .arrived }.count == 3)

    var multiple = gateFB06Session("gate-f-b06-multiple-agents")
    _ = try! gateFB06Begin(
        &multiple, agentID: gateFB06Agent0, destinationID: gateFB06EastID
    )
    try! gateFB06Complete(&multiple, agentID: gateFB06Agent0)
    _ = try! gateFB06Begin(
        &multiple, agentID: gateFB06Agent1, destinationID: gateFB06WestID
    )
    let multipleCheckpoint = try! multiple.makeCheckpoint()
    var multipleRestored = try! AgentSimulationSession.restoring(
        multipleCheckpoint
    )
    check("Gate F B06 agent A history does not interfere with agent B current authority",
          multipleRestored.populationScaleSnapshot().settlementMigrations
            .filter { $0.agentID == gateFB06Agent0 && $0.status == .arrived }
            .count == 1
            && multipleRestored.populationScaleSnapshot().settlementMigrations
                .filter { $0.agentID == gateFB06Agent1 && $0.status == .inTransit }
                .count == 1)
    try! gateFB06Complete(&multipleRestored, agentID: gateFB06Agent1)
    check("Gate F B06 multiple agents arrive with singular current authority",
          multipleRestored.populationSnapshot().settlements.first {
              $0.settlementID == gateFB06EastID
          }?.residentIDs == [gateFB06Agent0]
            && multipleRestored.populationSnapshot().settlements.first {
                $0.settlementID == gateFB06WestID
            }?.residentIDs == [gateFB06Agent1]
            && Set(multipleRestored.populationScaleSnapshot().fidelityRecords
                .map(\.agentID)).count == 3)

    var compacted = gateFB06Session(
        "gate-f-b06-compaction", migrationHistory: 2
    )
    _ = try! gateFB06Begin(
        &compacted, agentID: gateFB06Agent0, destinationID: gateFB06EastID
    )
    try! gateFB06Complete(&compacted, agentID: gateFB06Agent0)
    let below = compacted.durableState().populationRegistry!.scaleState!
    check("Gate F B06 migration history below bound is exact",
          below.settlementMigrations.count == 1
            && below.evictedSettlementMigrationCount == 0
            && below.nextSettlementMigrationOrdinal == 2)
    _ = try! gateFB06Begin(
        &compacted, agentID: gateFB06Agent0, destinationID: .main
    )
    try! gateFB06Complete(&compacted, agentID: gateFB06Agent0)
    let exact = compacted.durableState().populationRegistry!.scaleState!
    check("Gate F B06 migration history exact bound is exact",
          exact.settlementMigrations.count == 2
            && exact.evictedSettlementMigrationCount == 0
            && exact.nextSettlementMigrationOrdinal == 3)
    _ = try! gateFB06Begin(
        &compacted, agentID: gateFB06Agent0, destinationID: gateFB06EastID
    )
    let over = compacted.durableState().populationRegistry!.scaleState!
    let compactedCheckpoint = try! compacted.makeCheckpoint()
    var compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    check("Gate F B06 N+1 evicts only oldest eligible terminal history",
          over.settlementMigrations.map(\.migrationID.rawValue) == [
              "settlement-migration-00000002",
              "settlement-migration-00000003",
          ]
            && over.settlementMigrations.last?.status == .inTransit
            && over.evictedSettlementMigrationCount == 1
            && over.nextSettlementMigrationOrdinal == 4)
    check("Gate F B06 retained chain accepts unavailable evicted predecessor",
          (try! compactedRestored.durableStateBytes())
            == (try! compacted.durableStateBytes()))
    try! gateFB06Complete(&compactedRestored, agentID: gateFB06Agent0)
    let compactedArrival = try! compactedRestored.makeCheckpoint()
    var compactedContinued = try! AgentSimulationSession.restoring(
        compactedArrival
    )
    _ = try! compactedContinued.advanceTick()
    check("Gate F B06 compacted restore continues with monotonic ordinal",
          gateFB06NextOrdinal(compactedContinued) == 4
            && compactedContinued.durableState().populationRegistry!.scaleState!
                .evictedSettlementMigrationCount == 1)

    let malformedChain = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        gateFB06ScaleMutation(&durable) { scale in
            var migrations = scale["settlementMigrations"] as! [[String: Any]]
            migrations[0]["destinationSettlementID"] = gateFB06WestID.rawValue
            let route = gateFB06Route(from: gateFB06Main, to: gateFB06West)
            migrations[0]["route"] = route.map {
                ["x": $0.x, "y": $0.y, "z": $0.z]
            }
            migrations[0]["routeCursor"] = route.count - 1
            scale["settlementMigrations"] = migrations
        }
    }
    check("Gate F B06 contradictory retained migration chain rejects",
          gateFB06RestoreRejects(malformedChain))

    let duplicateIdentity = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        gateFB06ScaleMutation(&durable) { scale in
            var migrations = scale["settlementMigrations"] as! [[String: Any]]
            migrations[1]["migrationID"] = migrations[0]["migrationID"]
            scale["settlementMigrations"] = migrations
        }
    }
    let reorderedIdentity = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        gateFB06ScaleMutation(&durable) { scale in
            var migrations = scale["settlementMigrations"] as! [[String: Any]]
            migrations.swapAt(0, 1)
            scale["settlementMigrations"] = migrations
        }
    }
    let wrongNextOrdinal = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        gateFB06ScaleMutation(&durable) { scale in
            scale["nextSettlementMigrationOrdinal"] = 99
        }
    }
    check("Gate F B06 duplicate reorder and next-ordinal corruption reject",
          gateFB06RestoreRejects(duplicateIdentity)
            && gateFB06RestoreRejects(reorderedIdentity)
            && gateFB06RestoreRejects(wrongNextOrdinal))

    let wrongCurrentSettlement = try! gateFB06MutatedCheckpoint(
        migration2Checkpoint
    ) { durable in
        var registry = durable["populationRegistry"] as! [String: Any]
        var members = registry["members"] as! [[String: Any]]
        let index = members.firstIndex {
            ($0["agentID"] as? String) == gateFB06Agent0.rawValue
        }!
        members[index]["settlementID"] = AgentSettlementID.main.rawValue
        registry["members"] = members
        durable["populationRegistry"] = registry
    }
    let missingTransit = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        var registry = durable["populationRegistry"] as! [String: Any]
        var settlements = registry["additionalSettlements"] as! [[String: Any]]
        let index = settlements.firstIndex {
            ($0["settlementID"] as? String) == gateFB06EastID.rawValue
        }!
        settlements[index]["inTransitIDs"] = []
        registry["additionalSettlements"] = settlements
        durable["populationRegistry"] = registry
    }
    let brokenClaim = try! gateFB06MutatedCheckpoint(migration2Checkpoint) {
        durable in
        var registry = durable["populationRegistry"] as! [String: Any]
        var main = registry["settlement"] as! [String: Any]
        main["capacity"] = (main["residentIDs"] as! [Any]).count
        registry["settlement"] = main
        durable["populationRegistry"] = registry
    }
    check("Gate F B06 malformed current inTransit authorities reject",
          gateFB06RestoreRejects(wrongCurrentSettlement)
            && gateFB06RestoreRejects(missingTransit)
            && gateFB06RestoreRejects(brokenClaim))

    var latest = gateFB06Session(
        "gate-f-b06-latest-negative", socialDomains: false
    )
    _ = try! gateFB06Begin(
        &latest, agentID: gateFB06Agent0, destinationID: gateFB06EastID
    )
    try! gateFB06Complete(&latest, agentID: gateFB06Agent0)
    let latestCheckpoint = try! latest.makeCheckpoint()
    let staleLatestArrival = try! gateFB06MutatedCheckpoint(latestCheckpoint) {
        durable in
        var registry = durable["populationRegistry"] as! [String: Any]
        var members = registry["members"] as! [[String: Any]]
        let memberIndex = members.firstIndex {
            ($0["agentID"] as? String) == gateFB06Agent0.rawValue
        }!
        members[memberIndex]["settlementID"] = AgentSettlementID.main.rawValue
        registry["members"] = members
        var main = registry["settlement"] as! [String: Any]
        var mainResidents = main["residentIDs"] as! [String]
        mainResidents.append(gateFB06Agent0.rawValue)
        main["residentIDs"] = mainResidents.sorted()
        registry["settlement"] = main
        var settlements = registry["additionalSettlements"] as! [[String: Any]]
        let eastIndex = settlements.firstIndex {
            ($0["settlementID"] as? String) == gateFB06EastID.rawValue
        }!
        settlements[eastIndex]["residentIDs"] = []
        registry["additionalSettlements"] = settlements
        durable["populationRegistry"] = registry
    }
    check("Gate F B06 latest arrived record retains strict current authority",
          gateFB06RestoreRejects(staleLatestArrival))

    var arrivedDeath = gateFB06Session(
        "gate-f-b06-arrived-death", mortalityPressure: true
    )
    arrivedDeath.setSurvivalEnabled(true)
    try! arrivedDeath.setMortalityEnabled(true)
    _ = try! gateFB06Begin(
        &arrivedDeath, agentID: gateFB06Agent0,
        destinationID: gateFB06EastID
    )
    try! gateFB06Complete(&arrivedDeath, agentID: gateFB06Agent0)
    for _ in 0..<8 where arrivedDeath.expectedActiveAgentIDs().contains(
        gateFB06Agent0
    ) { _ = try! arrivedDeath.advanceTick() }
    let arrivedDeathCheckpoint = try! arrivedDeath.makeCheckpoint()
    check("Gate F B06 death after historical arrival restores without current residence",
          !arrivedDeath.expectedActiveAgentIDs().contains(gateFB06Agent0)
            && arrivedDeath.populationScaleSnapshot().settlementMigrations
                .first?.status == .arrived
            && (try! AgentSimulationSession.restoring(arrivedDeathCheckpoint)
                .durableStateBytes()) == (try! arrivedDeath.durableStateBytes()))

    var inTransitDeath = gateFB06Session(
        "gate-f-b06-intransit-death", mortalityPressure: true
    )
    inTransitDeath.setSurvivalEnabled(true)
    try! inTransitDeath.setMortalityEnabled(true)
    _ = try! gateFB06Begin(
        &inTransitDeath, agentID: gateFB06Agent0,
        destinationID: gateFB06EastID
    )
    try! gateFB06Complete(&inTransitDeath, agentID: gateFB06Agent0)
    var secondDeathRoute = gateFB06Route(
        from: gateFB06East, to: gateFB06West
    )
    for z in stride(from: gateFB06West.z - 1, through: 0, by: -1) {
        secondDeathRoute.append(AgentPosition(x: -4, y: 64, z: z))
    }
    for x in -3...0 {
        secondDeathRoute.append(AgentPosition(x: x, y: 64, z: 0))
    }
    _ = try! inTransitDeath.beginSettlementMigration(
        agentID: gateFB06Agent0, destinationSettlementID: .main,
        verifiedRoute: secondDeathRoute
    )
    for _ in 0..<12 where inTransitDeath.expectedActiveAgentIDs().contains(
        gateFB06Agent0
    ) {
        guard let active = inTransitDeath.populationScaleSnapshot()
            .settlementMigrations.first(where: {
                $0.agentID == gateFB06Agent0 && $0.status == .inTransit
            }) else { break }
        _ = try! inTransitDeath.advanceTick(perceptions: [
            gateFB06Perception(session: inTransitDeath, migration: active),
        ])
        if inTransitDeath.expectedActiveAgentIDs().contains(gateFB06Agent0) {
            let outcomes = AgentMovementCoordinator.resolve(
                snapshot: inTransitDeath.snapshot()
            )
            try! inTransitDeath.applyVerifiedPhysicalMovements(outcomes.map {
                AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
            })
        }
    }
    let inTransitDeathCheckpoint = try! inTransitDeath.makeCheckpoint()
    let inTransitDeathScale = inTransitDeath.populationScaleSnapshot()
    check("Gate F B06 death during migration 2 closes only current migration",
          inTransitDeathScale.settlementMigrations.map(\.status)
            == [.arrived, .failed]
            && inTransitDeathScale.settlementMigrations.last?.failure
                == .memberDied
            && !inTransitDeath.populationSnapshot().settlements
                .flatMap(\.residentIDs).contains(gateFB06Agent0)
            && !inTransitDeath.populationSnapshot().settlements
                .flatMap(\.inTransitIDs).contains(gateFB06Agent0))
    check("Gate F B06 terminal member-death chain restores exact and cannot arrive",
          (try! AgentSimulationSession.restoring(inTransitDeathCheckpoint)
            .durableStateBytes()) == (try! inTransitDeath.durableStateBytes())
            && inTransitDeath.causalLedgerSnapshot().events.filter {
                $0.kind == .settlementMigrationArrived
                    && $0.actorID == gateFB06Agent0
            }.count == 1)
    let malformedFailure = try! gateFB06MutatedCheckpoint(
        inTransitDeathCheckpoint
    ) { durable in
        gateFB06ScaleMutation(&durable) { scale in
            var migrations = scale["settlementMigrations"] as! [[String: Any]]
            migrations[1].removeValue(forKey: "failureEventID")
            scale["settlementMigrations"] = migrations
        }
    }
    check("Gate F B06 malformed terminal failure remains rejected",
          gateFB06RestoreRejects(malformedFailure))

    let observerBefore = try! afterMigration3.durableStateBytes()
    let observer = afterMigration3.observerSnapshot(
        worldBinding: gateFB06ObserverBinding(afterMigration3)
    )
    check("Gate F B06 Observer schema 13 is read-only over sequential history",
          observer.header.schemaVersion == 13
            && observer.populationScale?.settlementMigrations.count == 3
            && (try! afterMigration3.durableStateBytes()) == observerBefore)

    let finalPopulation = afterMigration3.populationSnapshot()
    let finalScale = afterMigration3.populationScaleSnapshot()
    let finalHouseholds = afterMigration3.householdSnapshot()
    let finalDigest = try! afterMigration3.durableStateDigest().rawValue
    check("Gate F B06 final current authority and identity are singular",
          Set(afterMigration3.snapshot().agents.map(\.id)).count == 3
            && Set(finalPopulation.members.map(\.agentID)).count == 3
            && Set(finalScale.fidelityRecords.map(\.agentID)).count == 3
            && finalHouseholds.currentMemberships.filter {
                $0.agentID == gateFB06Agent0
            }.count == 1
            && finalPopulation.settlements.flatMap(\.residentIDs).filter {
                $0 == gateFB06Agent0
            }.count == 1
            && finalScale.settlementMigrations.filter {
                $0.status == .inTransit
            }.isEmpty)
    print("GATE_F_BLOCKER_06_PASS checkpointSchema=35 observerSchema=13 migrations=3 nextMigrationOrdinal=4 evictedCompaction=1 duplicateAuthority=0 restartDuplicateEffects=0 deterministicDigest=\(finalDigest)")
}
