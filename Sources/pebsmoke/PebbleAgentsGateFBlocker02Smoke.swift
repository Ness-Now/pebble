import Foundation
import PebbleAgents

private let gateFB02EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFB02MainReception = AgentPosition(x: 0, y: 64, z: -2)
private let gateFB02EastReception = AgentPosition(x: 0, y: 64, z: 2)
private let gateFB02Agent0 = AgentID(rawValue: "agent_0")!
private let gateFB02Agent1 = AgentID(rawValue: "agent_1")!
private let gateFB02Agent3 = AgentID(rawValue: "agent_3")!

private func gateFB02Agent(
    _ id: String,
    ordinal: Int,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0, curiosity: 0, safety: 1
        ),
        health: lethalNextTick ? 10 : 100,
        fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 02 capacity fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func gateFB02Session(
    _ id: String,
    destinationCapacity: Int,
    destinationOccupied: Bool,
    lethalAgentID: AgentID? = nil,
    migrationHistoryLimit: Int = 8
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 402, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: (0..<3).map { ordinal in
            gateFB02Agent(
                "agent_\(ordinal)", ordinal: ordinal,
                lethalNextTick: lethalAgentID?.rawValue == "agent_\(ordinal)"
            )
        },
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: gateFB02MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 8,
            maximumMigrationRecords: 8
        )
    )
    let admissions = destinationOccupied ? [AgentScaledResidentAdmission(
        state: gateFB02Agent(
            "agent_3", ordinal: 3,
            lethalNextTick: lethalAgentID == gateFB02Agent3
        ),
        settlementID: gateFB02EastID
    )] : []
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB02EastID,
            anchor: gateFB02EastReception,
            receptionPosition: gateFB02EastReception,
            capacity: destinationCapacity,
            residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: admissions,
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2,
            maximumLiveAgents: 4, maximumNearAgents: 4,
            nearMaintenanceCadence: 2, dormantMaintenanceCadence: 8,
            rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: migrationHistoryLimit,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    return session
}

private func gateFB02Route(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    precondition(from.x == to.x && from.y == to.y)
    let direction = from.z <= to.z ? 1 : -1
    return stride(from: from.z, through: to.z, by: direction).map {
        AgentPosition(x: from.x, y: from.y, z: $0)
    }
}

private func gateFB02Agent1Route() -> [AgentPosition] {
    [
        AgentPosition(x: 2, y: 64, z: 0),
        AgentPosition(x: 1, y: 64, z: 0),
        AgentPosition(x: 0, y: 64, z: 0),
        AgentPosition(x: 0, y: 64, z: 1),
        gateFB02EastReception,
    ]
}

private func gateFB02Perception(
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
            origin: state.position,
            target: migration.route.last!, radius: 8,
            cells: migration.route.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func gateFB02AdvanceMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws -> AgentMovementOutcome {
    let migration = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }!
    _ = try session.advanceTick(perceptions: [
        gateFB02Perception(session: session, migration: migration)
    ])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    let migrant = outcomes.first { $0.agentId == agentID.rawValue }!
    try session.applyVerifiedPhysicalMovements(outcomes.map {
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
    })
    return migrant
}

private func gateFB02CompleteMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws {
    let routeCount = session.populationScaleSnapshot().settlementMigrations
        .first { $0.agentID == agentID && $0.status == .inTransit }!.route.count
    for _ in 1..<routeCount {
        _ = try gateFB02AdvanceMigration(&session, agentID: agentID)
    }
}

private func gateFB02ObserverBinding(
    _ session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-02-world",
        storageIdentity: "memory:gate-f-blocker-02",
        seed: 402, dimension: 0, observedWorldTick: session.tick
    )
}

private func gateFB02DuplicateCount<T: Hashable>(_ values: [T]) -> Int {
    values.count - Set(values).count
}

func runPebbleAgentsGateFBlocker02Smoke() {
    section("Gate F Blocker 02 migration destination capacity")

    var full = gateFB02Session(
        "gate-f-b02-full", destinationCapacity: 1,
        destinationOccupied: true, lethalAgentID: gateFB02Agent3
    )
    let fullBytes = try! full.durableStateBytes()
    let fullPopulation = full.populationSnapshot()
    let fullScale = full.populationScaleSnapshot()
    let fullEvents = full.causalLedgerSnapshot().events
    var fullRefused = false
    do {
        _ = try full.beginSettlementMigration(
            agentID: gateFB02Agent0,
            destinationSettlementID: gateFB02EastID,
            verifiedRoute: gateFB02Route(
                from: AgentPosition(x: 0, y: 64, z: 0),
                to: gateFB02EastReception
            )
        )
    } catch AgentSessionError.population(.capacityReached) {
        fullRefused = true
    } catch {}
    check("Gate F Blocker 02 full destination fails closed", fullRefused)
    check("Gate F Blocker 02 refusal leaves durable bytes unchanged",
          try! full.durableStateBytes() == fullBytes)
    check("Gate F Blocker 02 refusal leaves causal events unchanged",
          full.causalLedgerSnapshot().events == fullEvents)
    check("Gate F Blocker 02 refusal leaves settlement projections unchanged",
          full.populationSnapshot() == fullPopulation)
    check("Gate F Blocker 02 refusal leaves migration history and ordinal unchanged",
          full.populationScaleSnapshot().settlementMigrations
            == fullScale.settlementMigrations)
    check("Gate F Blocker 02 refusal leaves fidelity state unchanged",
          full.populationScaleSnapshot().fidelityRecords
            == fullScale.fidelityRecords
            && full.populationScaleSnapshot().fidelityTransitions
                == fullScale.fidelityTransitions)
    check("Gate F Blocker 02 exact-full normal checkpoint restores",
          {
              let checkpoint = try! full.makeCheckpoint()
              let restored = try? AgentSimulationSession.restoring(checkpoint)
              return checkpoint.schemaVersion == 35
                && (try? restored?.durableStateBytes()) == fullBytes
          }())

    try! full.setLifecycleEnabled(true)
    full.setSurvivalEnabled(true)
    try! full.setMortalityEnabled(true)
    _ = try! full.advanceTick()
    let afterSlotDeath = full.populationSnapshot()
    check("Gate F Blocker 02 destination death frees one real slot",
          !full.expectedActiveAgentIDs().contains(gateFB02Agent3)
            && afterSlotDeath.settlements.first {
                $0.settlementID == gateFB02EastID
            }?.residentIDs.isEmpty == true
            && full.mortalitySnapshot().records.filter {
                $0.agentID == gateFB02Agent3
            }.count == 1)
    let retry = try! full.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    check("Gate F Blocker 02 valid retry has no migration ordinal gap",
          retry.migrationID.rawValue == "settlement-migration-00000001")
    try! gateFB02CompleteMigration(&full, agentID: gateFB02Agent0)
    let retryEast = full.populationSnapshot().settlements.first {
        $0.settlementID == gateFB02EastID
    }!
    check("Gate F Blocker 02 mortality-freed slot consumed exactly once",
          retryEast.capacity == 1
            && retryEast.residentIDs == [gateFB02Agent0]
            && full.causalLedgerSnapshot().events.filter {
                $0.kind == .settlementMigrationArrived
                    && $0.actorID == gateFB02Agent0
            }.count == 1)
    let retryCheckpoint = try! full.makeCheckpoint()
    let retryRestored = try! AgentSimulationSession.restoring(retryCheckpoint)
    check("Gate F Blocker 02 exact-capacity arrival schema-35 restore exact",
          retryCheckpoint.schemaVersion == 35
            && (try! retryRestored.durableStateBytes())
                == (try! full.durableStateBytes()))

    var inFlight = gateFB02Session(
        "gate-f-b02-in-flight", destinationCapacity: 2,
        destinationOccupied: true
    )
    let accepted = try! inFlight.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    check("Gate F Blocker 02 one free slot accepts one durable claim",
          accepted.status == .inTransit
            && inFlight.populationScaleSnapshot().settlementMigrations
                .filter { $0.status == .inTransit }.count == 1)
    let competingBytes = try! inFlight.durableStateBytes()
    var competingRefused = false
    do {
        _ = try inFlight.beginSettlementMigration(
            agentID: gateFB02Agent1,
            destinationSettlementID: gateFB02EastID,
            verifiedRoute: gateFB02Agent1Route()
        )
    } catch AgentSessionError.population(.admission(.migrationAlreadyActive)) {
        competingRefused = true
    } catch {}
    check("Gate F Blocker 02 competing migration cannot consume claimed slot",
          competingRefused && (try! inFlight.durableStateBytes()) == competingBytes)
    let observerBefore = try! inFlight.durableStateBytes()
    let observer = inFlight.observerSnapshot(
        worldBinding: gateFB02ObserverBinding(inFlight)
    )
    check("Gate F Blocker 02 in-flight Observer 13 is read-only",
          observer.header.schemaVersion == 13
            && observer.populationScale?.settlementMigrations.first?.status
                == .inTransit
            && (try! inFlight.durableStateBytes()) == observerBefore)
    let inFlightCheckpoint = try! inFlight.makeCheckpoint()
    var continued = try! AgentSimulationSession.restoring(inFlightCheckpoint)
    check("Gate F Blocker 02 in-flight claim restores byte-exact",
          inFlightCheckpoint.schemaVersion == 35
            && (try! continued.durableStateBytes())
                == (try! inFlight.durableStateBytes()))
    try! gateFB02CompleteMigration(&continued, agentID: gateFB02Agent0)
    let continuedPopulation = continued.populationSnapshot()
    let continuedEast = continuedPopulation.settlements.first {
        $0.settlementID == gateFB02EastID
    }!
    let arrivalEvents = continued.causalLedgerSnapshot().events.filter {
        $0.kind == .settlementMigrationArrived
            && $0.actorID == gateFB02Agent0
    }
    check("Gate F Blocker 02 fresh continuation arrives at exact capacity",
          continuedEast.residentIDs.count == 2
            && continuedEast.residentIDs.count == continuedEast.capacity)
    check("Gate F Blocker 02 fresh continuation publishes one arrival",
          arrivalEvents.count == 1
            && continued.populationScaleSnapshot().settlementMigrations
                .filter { $0.status == .arrived }.count == 1)
    let completedCheckpoint = try! continued.makeCheckpoint()
    var completedRestored = try! AgentSimulationSession.restoring(
        completedCheckpoint
    )
    let completedBytes = try! completedRestored.durableStateBytes()
    for _ in 0..<4 { _ = try! completedRestored.advanceTick() }
    check("Gate F Blocker 02 completed arrival restore is exact before continuation",
          completedCheckpoint.schemaVersion == 35
            && completedBytes == (try! continued.durableStateBytes()))
    check("Gate F Blocker 02 completed arrival never replays",
          completedRestored.causalLedgerSnapshot().events.filter {
              $0.kind == .settlementMigrationArrived
                && $0.actorID == gateFB02Agent0
          }.count == 1)
    let completedMemberships = completedRestored.populationSnapshot()
        .settlements.flatMap { $0.residentIDs + $0.inTransitIDs }
    check("Gate F Blocker 02 arrival retains singular identity and membership",
          gateFB02DuplicateCount(completedRestored.expectedActiveAgentIDs()) == 0
            && gateFB02DuplicateCount(
                completedRestored.identitySnapshot().agentIDs
            ) == 0
            && gateFB02DuplicateCount(completedMemberships) == 0)

    var migrantDeath = gateFB02Session(
        "gate-f-b02-migrant-death", destinationCapacity: 1,
        destinationOccupied: false, lethalAgentID: gateFB02Agent0
    )
    let doomed = try! migrantDeath.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    try! migrantDeath.setLifecycleEnabled(true)
    migrantDeath.setSurvivalEnabled(true)
    try! migrantDeath.setMortalityEnabled(true)
    _ = try! migrantDeath.advanceTick()
    let deathScale = migrantDeath.populationScaleSnapshot()
    let failed = deathScale.settlementMigrations.first {
        $0.migrationID == doomed.migrationID
    }
    check("Gate F Blocker 02 active migrant death releases destination claim",
          failed?.status == .failed && failed?.failure == .memberDied
            && !migrantDeath.expectedActiveAgentIDs().contains(gateFB02Agent0)
            && migrantDeath.populationSnapshot().settlements.allSatisfy {
                !$0.residentIDs.contains(gateFB02Agent0)
                    && !$0.inTransitIDs.contains(gateFB02Agent0)
            })
    check("Gate F Blocker 02 active migrant death removes current fidelity",
          !deathScale.fidelityRecords.contains { $0.agentID == gateFB02Agent0 }
            && migrantDeath.causalLedgerSnapshot().events.filter {
                $0.kind == .settlementMigrationFailed
                    && $0.actorID == gateFB02Agent0
            }.count == 1)
    let released = try! migrantDeath.beginSettlementMigration(
        agentID: gateFB02Agent1,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Agent1Route()
    )
    try! gateFB02CompleteMigration(&migrantDeath, agentID: gateFB02Agent1)
    check("Gate F Blocker 02 terminal failure releases slot exactly once",
          released.status == .inTransit
            && migrantDeath.populationSnapshot().settlements.first {
                $0.settlementID == gateFB02EastID
            }?.residentIDs == [gateFB02Agent1])
    let deathCheckpoint = try! migrantDeath.makeCheckpoint()
    var deathRestored = try! AgentSimulationSession.restoring(deathCheckpoint)
    for _ in 0..<4 { _ = try! deathRestored.advanceTick() }
    check("Gate F Blocker 02 death/failure release restart remains terminal",
          deathCheckpoint.schemaVersion == 35
            && deathRestored.mortalitySnapshot().records.filter {
                $0.agentID == gateFB02Agent0
            }.count == 1
            && deathRestored.causalLedgerSnapshot().events.filter {
                $0.kind == .settlementMigrationArrived
                    && $0.actorID == gateFB02Agent0
            }.isEmpty)

    var compacted = gateFB02Session(
        "gate-f-b02-compaction", destinationCapacity: 2,
        destinationOccupied: true, migrationHistoryLimit: 1
    )
    _ = try! compacted.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    try! gateFB02CompleteMigration(&compacted, agentID: gateFB02Agent0)
    _ = try! compacted.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: .main,
        verifiedRoute: gateFB02Route(
            from: gateFB02EastReception, to: gateFB02MainReception
        )
    )
    try! gateFB02CompleteMigration(&compacted, agentID: gateFB02Agent0)
    let activeAtBound = try! compacted.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: gateFB02MainReception, to: gateFB02EastReception
        )
    )
    let compactedScale = compacted.populationScaleSnapshot()
    let compactedCheckpoint = try! compacted.makeCheckpoint()
    let compactedRestored = try! AgentSimulationSession.restoring(
        compactedCheckpoint
    )
    check("Gate F Blocker 02 terminal history does not retain slot authority",
          compactedScale.settlementMigrations.count == 1
            && compactedScale.settlementMigrations[0].migrationID
                == activeAtBound.migrationID
            && compactedScale.evictedSettlementMigrationCount == 2)
    check("Gate F Blocker 02 compaction never evicts active capacity authority",
          compactedCheckpoint.schemaVersion == 35
            && compactedRestored.populationScaleSnapshot()
                .settlementMigrations.first?.status == .inTransit
            && (try! compactedRestored.durableStateBytes())
                == (try! compacted.durableStateBytes()))

    var deterministicA = gateFB02Session(
        "gate-f-b02-deterministic", destinationCapacity: 2,
        destinationOccupied: true
    )
    var deterministicB = gateFB02Session(
        "gate-f-b02-deterministic", destinationCapacity: 2,
        destinationOccupied: true
    )
    _ = try! deterministicA.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    _ = try! deterministicB.beginSettlementMigration(
        agentID: gateFB02Agent0,
        destinationSettlementID: gateFB02EastID,
        verifiedRoute: gateFB02Route(
            from: AgentPosition(x: 0, y: 64, z: 0),
            to: gateFB02EastReception
        )
    )
    check("Gate F Blocker 02 capacity authority is deterministic",
          try! deterministicA.durableStateBytes()
            == deterministicB.durableStateBytes()
            && deterministicA.populationScaleSnapshot().digest
                == deterministicB.populationScaleSnapshot().digest)

    let finalDigest = AgentPopulationDigest.make(
        String(
            data: try! continued.durableStateBytes(), encoding: .utf8
        ) ?? ""
    )
    print(
        "GATE_F_BLOCKER_02_FOCUSED_PASS checkpointSchema=35 observerSchema=13 "
            + "fullDestinationRefused=1 exactCapacityResidents=2 "
            + "duplicateMemberships=0 duplicateArrivals=0 duplicateDeaths=0 "
            + "deterministicDigest=\(finalDigest)"
    )
}
