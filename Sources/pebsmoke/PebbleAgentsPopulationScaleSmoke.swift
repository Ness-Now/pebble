import Foundation
import PebbleAgents

private let civ39EastID = AgentSettlementID(rawValue: "settlement-east")!
private let civ39MainReception = AgentPosition(x: 0, y: 64, z: -2)
private let civ39EastReception = AgentPosition(x: 0, y: 64, z: 4)
private let civ39MigrationRoute = (0...4).map {
    AgentPosition(x: 0, y: 64, z: $0)
}

private func civ39Agent(_ id: String, ordinal: Int) -> AgentSessionAgentState {
    let position: AgentPosition
    if ordinal < 3 {
        position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    } else {
        position = AgentPosition(
            x: 20 + (ordinal % 8) * 2,
            y: 64,
            z: 12 + (ordinal / 8) * 2
        )
    }
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-39 scale fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil,
        memory: ordinal == 0 ? [AgentMemoryEntry(
            tick: 0, type: "durable_identity_context",
            summary: "founder retained across fidelity", importance: 90
        )] : [],
        tickCreated: 0, ticksAlive: ordinal,
        observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0,
        actionCount: 0, actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func civ39ScaleConfiguration(
    maximumLiveAgents: Int = 4,
    maximumNearAgents: Int = 8
) -> AgentPopulationScaleConfiguration {
    try! AgentPopulationScaleConfiguration(
        maximumSettlements: 4,
        maximumLiveAgents: maximumLiveAgents,
        maximumNearAgents: maximumNearAgents,
        nearMaintenanceCadence: 2,
        dormantMaintenanceCadence: 8,
        rotationIntervalTicks: 4,
        maximumFidelityTransitionHistory: 24,
        maximumSettlementMigrationHistory: 4,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 16
    )
}

private func civ39RegisterEconomicAsset(
    in session: inout AgentSimulationSession
) {
    let owner = AgentID(rawValue: "agent_0")!
    let assetID = AgentMaterialAssetID(rawValue: "civ39:asset:founder-tool")!
    let identity = AgentMaterialIdentitySnapshot(
        itemKey: "iron_pickaxe", damage: 0, enchantments: [], label: nil,
        canonicalDataJSON: "{}"
    )
    try! session.setMaterialRightsEnabled(true)
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "civ39:rights:register",
        asset: AgentMaterialAssetReference(
            assetID: assetID, materialIdentity: identity, quantity: 1
        ),
        observation: AgentMaterialHolderObservation(
            holder: .agent(owner), materialIdentity: identity, quantity: 1,
            custodyFingerprint: "civ39-agent0-tool",
            physicalReceiptID: "civ39-register-receipt", observedAtTick: 0
        )
    ))
    let claimID = AgentMaterialClaimID(rawValue: "civ39:claim:founder-tool")!
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ39:rights:claim", assetID: assetID,
        claimID: claimID, claimantID: owner, basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "civ39:rights:recognize", assetID: assetID,
        claimID: claimID,
        recognizingAgentIDs: [
            owner, AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ]
    ))
}

private func civ39Session(
    id: String,
    population: Int = 24,
    scaleConfiguration: AgentPopulationScaleConfiguration
        = civ39ScaleConfiguration(),
    economicAsset: Bool = false
) -> AgentSimulationSession {
    precondition((3...128).contains(population))
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 139, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            civ39Agent("agent_0", ordinal: 0),
            civ39Agent("agent_1", ordinal: 1),
            civ39Agent("agent_2", ordinal: 2),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: civ39MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: population,
            maximumMigrationRecords: 16
        )
    )
    if economicAsset { civ39RegisterEconomicAsset(in: &session) }
    let admissions = (3..<population).map { ordinal in
        AgentScaledResidentAdmission(
            state: civ39Agent(
                String(format: "agent_%03d", ordinal), ordinal: ordinal
            ),
            settlementID: ordinal.isMultiple(of: 2) ? .main : civ39EastID
        )
    }
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: civ39EastID,
            anchor: AgentPosition(x: 24, y: 64, z: 16),
            receptionPosition: civ39EastReception,
            capacity: population,
            residentIDs: [], inTransitIDs: []
        )],
        additionalResidents: admissions,
        configuration: scaleConfiguration
    )
    return session
}

private func civ39NavigationPerception(
    session: AgentSimulationSession,
    agentID: String = "agent_0"
) -> AgentPerceptionInput {
    let state = try! session.state(for: AgentID(rawValue: agentID)!)
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
    let world = try! AgentWorldObservation(
        worldTick: session.tick + 1, position: state.position,
        center: column(state.position), neighbors: neighbors,
        biomeId: 1, biomeName: "plains", combinedLight: 15,
        skyLight: 15, blockLight: 0, dayTime: 6_000,
        raining: false, thundering: false
    )
    return AgentPerceptionInput(
        agentId: agentID,
        worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: session.tick + 1,
            origin: state.position,
            target: civ39EastReception,
            radius: 8,
            cells: civ39MigrationRoute.map {
                AgentNavigationCell(position: $0, status: .traversable)
            }
        )
    )
}

@discardableResult
private func civ39AdvanceMigration(
    _ session: inout AgentSimulationSession
) throws -> AgentMovementOutcome {
    _ = try session.advanceTick(perceptions: [
        civ39NavigationPerception(session: session),
    ])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    let migrant = outcomes.first { $0.agentId == "agent_0" }!
    try session.applyMovementOutcomes(outcomes)
    return migrant
}

private func civ39ObserverBinding(tick: Int) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "civ39-smoke-world",
        storageIdentity: "memory:civ39-smoke",
        seed: 139, dimension: 0, observedWorldTick: tick
    )
}

func runPebbleAgentsPopulationScaleSmoke() {
    section("CIV-39 multi-settlement population scaling and fidelity tiers")

    check("CIV-39 checkpoint schema 35",
          AgentCheckpointSchema.populationScaleVersion == 35)
    check("CIV-39 population upper bound permits measured scale",
          (try? AgentPopulationConfiguration(
              maximumActivePopulation: 128
          ))?.maximumActivePopulation == 128)
    check("CIV-39 invalid one-settlement fidelity refused", {
        (try? AgentPopulationScaleConfiguration(maximumSettlements: 1)) == nil
    }())
    check("CIV-39 unbounded concurrency refused", {
        (try? AgentPopulationScaleConfiguration(
            maximumConcurrentSettlementMigrations: 2
        )) == nil
    }())

    var session = civ39Session(
        id: "civ39-primary", economicAsset: true
    )
    let population = session.populationSnapshot()
    let scale = session.populationScaleSnapshot()
    let allSettlementIDs = population.settlements.map(\.settlementID)
    let membershipIDs = population.settlements.flatMap {
        $0.residentIDs + $0.inTransitIDs
    }
    check("CIV-39 two settlements coexist",
          allSettlementIDs == [.main, civ39EastID].sorted())
    check("CIV-39 twenty-four real inhabitants", population.members.count == 24
        && session.snapshot().agents.count == 24)
    check("CIV-39 membership has one authoritative occurrence",
          membershipIDs.count == 24 && Set(membershipIDs).count == 24)
    check("CIV-39 all fidelity tiers populated",
          scale.liveCount == 4 && scale.nearCount == 8
            && scale.dormantCount == 12)
    check("CIV-39 tier records reference exact inhabitants",
          Set(scale.fidelityRecords.map(\.agentID))
            == Set(population.members.map(\.agentID)))
    check("CIV-39 one durable record per identity",
          Set(session.identitySnapshot().agentIDs).count == 24)
    check("CIV-39 initial transition history bounded",
          scale.fidelityTransitions.count == 24
            && scale.evictedFidelityTransitionCount == 0)

    let observerBeforeBytes = try! session.durableStateBytes()
    let observerA = session.observerSnapshot(
        worldBinding: civ39ObserverBinding(tick: session.tick)
    )
    let observerB = session.observerSnapshot(
        worldBinding: civ39ObserverBinding(tick: session.tick)
    )
    let observerAfterBytes = try! session.durableStateBytes()
    check("CIV-39 Observer schema 12", observerA.header.schemaVersion == 12)
    check("CIV-39 Observer exposes settlements and tier totals",
          observerA.populationScale?.settlements.count == 2
            && observerA.populationScale?.liveCount == 4
            && observerA.individuals.count == 24)
    check("CIV-39 Observer individual stable ID context",
          observerA.individuals.first {
              $0.agentID.rawValue == "agent_0"
          }?.populationContext?.settlementID == .main)
    check("CIV-39 Observer deterministic and non-authoritative",
          observerA == observerB
            && observerAfterBytes == observerBeforeBytes)

    let preRotationRecords = Dictionary(uniqueKeysWithValues:
        scale.fidelityRecords.map { ($0.agentID, $0.fidelity) }
    )
    var fourthTickResults: AgentSessionTickResult?
    for _ in 0..<4 { fourthTickResults = try! session.advanceTick() }
    let rotated = session.populationScaleSnapshot()
    let postRotationRecords = Dictionary(uniqueKeysWithValues:
        rotated.fidelityRecords.map { ($0.agentID, $0.fidelity) }
    )
    check("CIV-39 full cognition bounded to LIVE",
          fourthTickResults?.agents.count == 4
            && fourthTickResults?.agents.allSatisfy(\.cognitionPerformed) == true)
    check("CIV-39 deterministic tier window rotates",
          preRotationRecords != postRotationRecords
            && rotated.liveCount == 4 && rotated.nearCount == 8
            && rotated.dormantCount == 12)
    check("CIV-39 lower tiers skip full cognition",
          rotated.workCounters.liveCognitionExecutions == 16
            && rotated.workCounters.skippedFullCognitionExecutions == 80
            && rotated.workCounters.nearMaintenanceExecutions == 16
            && rotated.workCounters.dormantMaintenanceExecutions == 0)
    check("CIV-39 transition compaction bounded",
          rotated.fidelityTransitions.count <= 24
            && rotated.evictedFidelityTransitionCount > 0)
    check("CIV-39 durable memory survives tier change",
          try! session.state(for: AgentID(rawValue: "agent_0")!)
            .memory.contains { $0.type == "durable_identity_context" })
    check("CIV-39 economic asset singular across tier change",
          session.materialRightsSnapshot().records.count == 1
            && session.materialRightsSnapshot().records[0]
                .recognizedOwnership?.ownerID.rawValue == "agent_0"
            && session.materialRightsSnapshot().records[0]
                .lastVerifiedHolder.holder
                == .agent(AgentID(rawValue: "agent_0")!))

    var deterministicA = civ39Session(id: "civ39-deterministic")
    var deterministicB = civ39Session(id: "civ39-deterministic")
    for _ in 0..<12 {
        _ = try! deterministicA.advanceTick()
        _ = try! deterministicB.advanceTick()
    }
    check("CIV-39 deterministic state bytes",
          try! deterministicA.durableStateBytes()
            == deterministicB.durableStateBytes())
    check("CIV-39 deterministic tier digest",
          deterministicA.populationScaleSnapshot().digest
            == deterministicB.populationScaleSnapshot().digest)
    check("CIV-39 transition history remains bounded under churn",
          deterministicA.populationScaleSnapshot().fidelityTransitions.count
            == 24
            && deterministicA.populationScaleSnapshot()
                .evictedFidelityTransitionCount > 24)

    var migration = civ39Session(
        id: "civ39-migration", economicAsset: true
    )
    try! migration.setLifecycleEnabled(true)
    let lifecycleAtScale = migration.lifecycleSnapshot()
    check("CIV-39 Gate D lifecycle enrolls scaled population",
          lifecycleAtScale.members.count == 24
            && Set(lifecycleAtScale.members.map(\.agentID)).count == 24)
    check("CIV-39 heterogeneous lifecycle origins retained",
          Set(lifecycleAtScale.members.map(\.origin))
            == Set([.bootstrapResident, .importedMigrant]))
    let migrationRecord = try! migration.beginSettlementMigration(
        agentID: AgentID(rawValue: "agent_0")!,
        destinationSettlementID: civ39EastID,
        verifiedRoute: civ39MigrationRoute
    )
    let retainedMigrationGoal = AgentCognitiveTransitions.selectGoal(
        AgentGoalSelectionInput(
            tick: migration.tick + 1, health: 100, fear: 100,
            needs: AgentNeeds(
                hunger: 0, fatigue: 0, curiosity: 0, safety: 0
            ),
            hasNearbyAgents: false,
            isMigrating: true,
            currentGoalKind: .seekSafety
        )
    )
    check("CIV-39 active migration route cannot be displaced by ordinary safety goal",
          retainedMigrationGoal?.goal.kind == .migrateToSettlement)
    let mid = migration.populationSnapshot()
    check("CIV-39 migration starts without settlement teleport",
          migrationRecord.status == .inTransit
            && mid.members.first { $0.agentID.rawValue == "agent_0" }?
                .settlementID == .main
            && mid.settlements.first { $0.settlementID == .main }?
                .inTransitIDs == [AgentID(rawValue: "agent_0")!])
    let midCheckpoint = try! migration.makeCheckpoint()
    let midBytes = try! AgentCheckpointCodec.encode(midCheckpoint)
    check("CIV-39 schema 35 checkpoint selected",
          midCheckpoint.schemaVersion == 35)
    check("CIV-39 checkpoint carries one agent state",
          String(data: midBytes, encoding: .utf8)?
            .components(separatedBy: "\"agentID\":\"agent_0\"").count ?? 0
            >= 2)

    var restoredA = try! AgentSimulationSession.restoring(midCheckpoint)
    var restoredB = try! AgentSimulationSession.restoring(midCheckpoint)
    let restoredInitialBytes = try! restoredA.durableStateBytes()
    let migrationInitialBytes = try! migration.durableStateBytes()
    check("CIV-39 fresh restore exact before continuation",
          restoredInitialBytes == migrationInitialBytes)
    var moveStatuses: [AgentMovementStatus] = []
    var moveReasons: [String] = []
    for _ in 0..<4 {
        let outcome = try! civ39AdvanceMigration(&restoredA)
        moveStatuses.append(outcome.status)
        moveReasons.append(outcome.resolutionReason)
        _ = try! civ39AdvanceMigration(&restoredB)
    }
    let arrivedPopulation = restoredA.populationSnapshot()
    let arrivedScale = restoredA.populationScaleSnapshot()
    let arrivedMember = arrivedPopulation.members.first {
        $0.agentID.rawValue == "agent_0"
    }!
    let arrivedEast = arrivedPopulation.settlements.first {
        $0.settlementID == civ39EastID
    }!
    let arrivedPosition = try! restoredA.state(
        for: AgentID(rawValue: "agent_0")!
    ).position
    check("CIV-39 embodied migration moves one exact step per tick",
          moveStatuses == [.moved, .moved, .moved, .moved],
          "statuses=\(moveStatuses.map(\.rawValue)) position="
            + "\(arrivedPosition) reasons=\(moveReasons)")
    check("CIV-39 destination becomes current only after arrival",
          arrivedMember.settlementID == civ39EastID
            && arrivedMember.status == .resident
            && arrivedEast.residentIDs.filter {
                $0.rawValue == "agent_0"
            }.count == 1,
          "member=\(arrivedMember.settlementID.rawValue)/"
            + "\(arrivedMember.status.rawValue) east=\(arrivedEast.residentIDs)")
    check("CIV-39 source current authority removed",
          arrivedPopulation.settlements.first {
              $0.settlementID == .main
          }!.residentIDs.allSatisfy { $0.rawValue != "agent_0" }
            && arrivedPopulation.settlements.first {
                $0.settlementID == .main
            }!.inTransitIDs.allSatisfy { $0.rawValue != "agent_0" },
          "main=\(arrivedPopulation.settlements.first { $0.settlementID == .main }!)")
    check("CIV-39 migration terminal record singular",
          arrivedScale.settlementMigrations.count == 1
            && arrivedScale.settlementMigrations[0].status == .arrived,
          "migrations=\(arrivedScale.settlementMigrations)")
    check("CIV-39 Gate D lifecycle follows explicit arrival",
          restoredA.lifecycleSnapshot().members.first {
              $0.agentID.rawValue == "agent_0"
          }?.settlementID == civ39EastID
            && restoredA.lifecycleSnapshot().members.count == 24)
    check("CIV-39 restart continuation idempotent",
          try! restoredA.durableStateBytes()
            == restoredB.durableStateBytes())
    check("CIV-39 material continuity through settlement move",
          restoredA.materialRightsSnapshot().records.count == 1
            && restoredA.materialRightsSnapshot().records[0]
                .recognizedOwnership?.ownerID.rawValue == "agent_0"
            && restoredA.materialRightsSnapshot().records[0]
                .lastVerifiedHolder.physicalReceiptID
                == "civ39-register-receipt")
    check("CIV-39 no material created by migration",
          restoredA.conservationSnapshot().harvestedTotal == 0
            && restoredA.conservationSnapshot().constructedTotal == 0)
    check("CIV-39 post-arrival checkpoint restore exact", {
        guard let checkpoint = try? restoredA.makeCheckpoint(),
              let again = try? AgentSimulationSession.restoring(checkpoint)
        else { return false }
        return (try? again.durableStateBytes())
            == (try? restoredA.durableStateBytes())
    }())

    var replannedMigration = civ39Session(id: "civ39-replanned-migration")
    let detourRoute = [
        AgentPosition(x: 0, y: 64, z: 0),
        AgentPosition(x: 1, y: 64, z: 0),
        AgentPosition(x: 1, y: 64, z: 1),
        AgentPosition(x: 1, y: 64, z: 2),
        AgentPosition(x: 1, y: 64, z: 3),
        AgentPosition(x: 1, y: 64, z: 4),
        civ39EastReception,
    ]
    _ = try! replannedMigration.beginSettlementMigration(
        agentID: AgentID(rawValue: "agent_0")!,
        destinationSettlementID: civ39EastID,
        verifiedRoute: detourRoute
    )
    for _ in 0..<4 { _ = try! civ39AdvanceMigration(&replannedMigration) }
    let replannedRecord = replannedMigration.populationScaleSnapshot()
        .settlementMigrations[0]
    check("CIV-39 verified physical arrival survives a shorter replan",
          replannedRecord.status == .arrived
            && replannedRecord.routeCursor == detourRoute.count - 1
            && replannedMigration.currentSettlementID(
                for: AgentID(rawValue: "agent_0")!
            ) == civ39EastID)

    var invalid = civ39Session(id: "civ39-invalid")
    let nearID = invalid.populationScaleSnapshot().fidelityRecords.first {
        $0.fidelity == .near
    }!.agentID
    let invalidBefore = try! invalid.durableStateBytes()
    do {
        _ = try invalid.beginSettlementMigration(
            agentID: nearID, destinationSettlementID: civ39EastID,
            verifiedRoute: civ39MigrationRoute
        )
        check("CIV-39 NEAR physical migration refused", false)
    } catch AgentSessionError.population(.admission(.migrationAlreadyActive)) {
        check("CIV-39 NEAR physical migration refused", true)
    } catch {
        check("CIV-39 NEAR physical migration refused", false,
              "unexpected \(error)")
    }
    check("CIV-39 refused lower-tier mutation atomic",
          try! invalid.durableStateBytes() == invalidBefore)
    do {
        _ = try invalid.beginSettlementMigration(
            agentID: AgentID(rawValue: "agent_0")!,
            destinationSettlementID: civ39EastID,
            verifiedRoute: [civ39MigrationRoute[0], civ39MigrationRoute[4]]
        )
        check("CIV-39 teleport route refused", false)
    } catch AgentSessionError.population(.admission(.routeUnavailable)) {
        check("CIV-39 teleport route refused", true)
    } catch {
        check("CIV-39 teleport route refused", false, "unexpected \(error)")
    }
    check("CIV-39 invalid route atomic",
          try! invalid.durableStateBytes() == invalidBefore)

    var duplicateSettlement = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 139, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            civ39Agent("agent_0", ordinal: 0),
            civ39Agent("agent_1", ordinal: 1),
            civ39Agent("agent_2", ordinal: 2),
        ],
        simulationID: try! AgentSimulationID(
            validating: "civ39-duplicate-settlement"
        ),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! duplicateSettlement.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: civ39MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 24
        )
    )
    let duplicateBefore = try! duplicateSettlement.durableStateBytes()
    do {
        try duplicateSettlement.initializePopulationScaling(
            additionalSettlements: [
                AgentPopulationSettlement(
                    settlementID: civ39EastID,
                    anchor: civ39EastReception,
                    receptionPosition: civ39EastReception,
                    capacity: 24, residentIDs: [], inTransitIDs: []
                ),
                AgentPopulationSettlement(
                    settlementID: civ39EastID,
                    anchor: AgentPosition(x: 1, y: 64, z: 4),
                    receptionPosition: AgentPosition(x: 1, y: 64, z: 5),
                    capacity: 24, residentIDs: [], inTransitIDs: []
                ),
            ]
        )
        check("CIV-39 duplicate settlement refused", false)
    } catch AgentSessionError.population(.invalidConfiguration(
        "additional settlements"
    )) {
        check("CIV-39 duplicate settlement refused", true)
    } catch {
        check("CIV-39 duplicate settlement refused", false,
              "unexpected \(error)")
    }
    check("CIV-39 duplicate settlement refusal atomic",
          try! duplicateSettlement.durableStateBytes() == duplicateBefore)

    let oldSchema = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 139, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [civ39Agent("legacy", ordinal: 0)],
        simulationID: try! AgentSimulationID(validating: "civ39-schema-off"),
        causalLedgerPolicy: .bounded(maxEvents: 128)
    )
    let oldBytes = try! oldSchema.durableStateBytes()
    check("CIV-39 feature-off checkpoint remains schema 1",
          try! oldSchema.makeCheckpoint().schemaVersion == 1)
    check("CIV-39 feature-off bytes omit scale fields",
          !String(data: oldBytes, encoding: .utf8)!
            .contains("scaleState"))
}
