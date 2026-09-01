import Foundation
import PebbleAgents

private let gateFB05Main = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB05East = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB05EastID = AgentSettlementID(rawValue: "settlement-east")!

private func gateFB05Agent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0,
        homePosition: ordinal < 2 ? gateFB05Main : position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 05 fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [],
        tickCreated: 0, ticksAlive: 0, observationCount: 0,
        nearbyObservationCount: 0, goalSelectionCount: 0,
        goalChangeCount: 0, actionCount: 0, actionEffectCount: 0,
        movementCount: 0, totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0, totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFB05ScaleConfiguration()
    -> AgentPopulationScaleConfiguration
{
    try! AgentPopulationScaleConfiguration(
        maximumSettlements: 2,
        maximumLiveAgents: 3,
        maximumNearAgents: 1,
        nearMaintenanceCadence: 2,
        dormantMaintenanceCadence: 8,
        rotationIntervalTicks: 4,
        maximumFidelityTransitionHistory: 16,
        maximumSettlementMigrationHistory: 4,
        maximumConcurrentSettlementMigrations: 1,
        maximumSettlementMigrationRouteLength: 16
    )
}

private func gateFB05EnableScale(
    _ session: inout AgentSimulationSession
) throws {
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB05EastID,
            anchor: gateFB05East,
            receptionPosition: gateFB05East,
            capacity: 2,
            residentIDs: [],
            inTransitIDs: []
        )],
        configuration: gateFB05ScaleConfiguration()
    )
}

private func gateFB05Session(
    _ simulationID: String,
    familyEnabled: Bool,
    scaleEnabled: Bool
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 605, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128)
        ),
        agents: (0..<3).map(gateFB05Agent),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB05Main,
        receptionPosition: gateFB05Main,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 5,
            maximumMigrationRecords: 16
        )
    )
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    if familyEnabled {
        try! session.setFamilyV1Enabled(true)
    }
    if scaleEnabled {
        try! gateFB05EnableScale(&session)
    }
    return session
}

private func gateFB05Receipt(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actorID: AgentID,
    counterpartyID: AgentID
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues:
        session.snapshot().agents.map {
            (AgentID(rawValue: $0.id)!, $0)
        }
    )
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actorID, counterpartyID: counterpartyID,
        observedTick: session.tick,
        actorPosition: states[actorID]!.position,
        counterpartyPosition: states[counterpartyID]!.position,
        communicationVerified: true
    )
}

private func gateFB05CofoundedSession(
    _ simulationID: String
) -> AgentSimulationSession {
    var session = gateFB05Session(
        simulationID, familyEnabled: true, scaleEnabled: false
    )
    let first = AgentID(rawValue: "agent_0")!
    let second = AgentID(rawValue: "agent_1")!
    let proposal = try! session.proposeUnion(gateFB05Receipt(
        session,
        id: "\(simulationID)-proposal",
        kind: .unionProposal,
        actorID: first,
        counterpartyID: second
    ))
    _ = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFB05Receipt(
            session,
            id: "\(simulationID)-acceptance",
            kind: .unionAcceptance,
            actorID: second,
            counterpartyID: first
        )
    )
    _ = try! session.coFoundHouse(
        founderIDs: [first, second],
        receipts: [
            gateFB05Receipt(
                session,
                id: "\(simulationID)-cofound-a",
                kind: .houseCoFoundation,
                actorID: first,
                counterpartyID: second
            ),
            gateFB05Receipt(
                session,
                id: "\(simulationID)-cofound-b",
                kind: .houseCoFoundation,
                actorID: second,
                counterpartyID: first
            ),
        ]
    )
    return session
}

private func gateFB05JoinedSession(
    _ simulationID: String
) -> AgentSimulationSession {
    var session = gateFB05Session(
        simulationID, familyEnabled: true, scaleEnabled: false
    )
    let founder = AgentID(rawValue: "agent_0")!
    let joining = AgentID(rawValue: "agent_1")!
    let proposal = try! session.proposeUnion(gateFB05Receipt(
        session,
        id: "\(simulationID)-grounding-proposal",
        kind: .unionProposal,
        actorID: founder,
        counterpartyID: joining
    ))
    _ = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFB05Receipt(
            session,
            id: "\(simulationID)-grounding-acceptance",
            kind: .unionAcceptance,
            actorID: joining,
            counterpartyID: founder
        )
    )
    let house = try! session.foundHouse(
        founderID: founder,
        operationID: "\(simulationID)-house-foundation"
    )
    try! session.joinHouse(
        house.houseID,
        request: gateFB05Receipt(
            session,
            id: "\(simulationID)-join-request",
            kind: .houseJoinRequest,
            actorID: joining,
            counterpartyID: founder
        ),
        acceptance: gateFB05Receipt(
            session,
            id: "\(simulationID)-join-acceptance",
            kind: .houseJoinAcceptance,
            actorID: founder,
            counterpartyID: joining
        )
    )
    return session
}

private func gateFB05MutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutationBytes = try! JSONSerialization.data(
        withJSONObject: durable,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let state = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(state)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(
        Data(simulationID.utf8)
    )
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] =
        "checkpoint-\(simulationDigest.rawValue.prefix(12))"
        + "-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func gateFB05WithoutCofoundingProof(
    _ checkpoint: AgentSessionCheckpoint,
    schemaVersion: Int
) -> AgentSessionCheckpoint {
    gateFB05MutatedCheckpoint(checkpoint) { durable in
        durable["schemaVersion"] = schemaVersion
        var family = durable["familyState"] as! [String: Any]
        var houses = family["houses"] as! [[String: Any]]
        houses[0].removeValue(forKey: "cofoundingInteractionProofs")
        family["houses"] = houses
        durable["familyState"] = family
    }
}

private func gateFB05WithoutJoinConsent(
    _ checkpoint: AgentSessionCheckpoint,
    schemaVersion: Int
) -> AgentSessionCheckpoint {
    gateFB05MutatedCheckpoint(checkpoint) { durable in
        durable["schemaVersion"] = schemaVersion
        var family = durable["familyState"] as! [String: Any]
        var periods = family["houseMembershipPeriods"] as! [[String: Any]]
        let index = periods.firstIndex {
            ($0["basis"] as? String) == "explicitAdultJoin"
        }!
        periods[index].removeValue(forKey: "explicitJoinConsent")
        family["houseMembershipPeriods"] = periods
        durable["familyState"] = family
    }
}

private func gateFB05RejectsFamilyState(
    _ checkpoint: AgentSessionCheckpoint,
    detail: String
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return false
    } catch AgentFamilyError.invalidState(let actual) {
        return actual == detail
    } catch {
        return false
    }
}

private func gateFB05Route(
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

private func gateFB05Perception(
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
            worldTick: session.tick + 1,
            position: state.position,
            center: column(state.position),
            neighbors: neighbors,
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

private func gateFB05CompleteMigration(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) throws {
    while let migration = session.populationScaleSnapshot()
        .settlementMigrations.first(where: {
            $0.agentID == agentID && $0.status == .inTransit
        })
    {
        _ = try session.advanceTick(perceptions: [
            gateFB05Perception(session: session, migration: migration),
        ])
        let outcomes = AgentMovementCoordinator.resolve(
            snapshot: session.snapshot()
        )
        try session.applyVerifiedPhysicalMovements(outcomes.map {
            AgentVerifiedPhysicalMovement(
                kind: .navigationStep, outcome: $0
            )
        })
    }
}

private func gateFB05DuplicateCount<T: Hashable>(_ values: [T]) -> Int {
    values.count - Set(values).count
}

private func gateFB05ObserverBinding(
    _ session: AgentSimulationSession
) -> AgentObserverWorldBinding {
    try! AgentObserverWorldBinding(
        worldID: "gate-f-blocker-05-world",
        storageIdentity: "memory:gate-f-blocker-05",
        seed: 605, dimension: 0,
        observedWorldTick: session.tick
    )
}

private func gateFB05GateECarrier(
    _ simulationID: String,
    schemaVersion: Int
) -> AgentSimulationSession {
    var session = gateFB05Session(
        simulationID, familyEnabled: true, scaleEnabled: false
    )
    if schemaVersion == AgentCheckpointSchema.productionVersion {
        try! session.setProductionEnabled(true)
    } else {
        try! session.setMaterialRightsEnabled(true)
        try! session.setProductionEnabled(true)
        switch schemaVersion {
        case AgentCheckpointSchema.barterVersion:
            try! session.setBarterEnabled(true)
        case AgentCheckpointSchema.contractVersion:
            try! session.setContractsEnabled(true)
        case AgentCheckpointSchema.marketVersion:
            try! session.setMarketEnabled(true)
        default:
            preconditionFailure("unsupported Gate E carrier schema")
        }
    }
    return session
}

func runPebbleAgentsGateFBlocker05Smoke() {
    section("Gate F Blocker 05 Family x schema-35 validation")

    var familyControl = gateFB05Session(
        "gate-f-b05-family-control",
        familyEnabled: true,
        scaleEnabled: false
    )
    _ = try! familyControl.advanceTick()
    let familyControlBytes = try! familyControl.durableStateBytes()
    let familyControlCheckpoint = try! familyControl.makeCheckpoint()
    let familyControlRestored = try! AgentSimulationSession.restoring(
        familyControlCheckpoint
    )
    check("Family without scale remains exact schema 26",
          familyControlCheckpoint.schemaVersion
            == AgentCheckpointSchema.durableHouseConsentVersion
            && (try! familyControlRestored.durableStateBytes())
                == familyControlBytes)

    var scaleControl = gateFB05Session(
        "gate-f-b05-scale-control",
        familyEnabled: false,
        scaleEnabled: true
    )
    _ = try! scaleControl.advanceTick()
    let scaleControlBytes = try! scaleControl.durableStateBytes()
    let scaleControlCheckpoint = try! scaleControl.makeCheckpoint()
    let scaleControlRestored = try! AgentSimulationSession.restoring(
        scaleControlCheckpoint
    )
    check("scale without Family remains exact schema 35",
          scaleControlCheckpoint.schemaVersion
            == AgentCheckpointSchema.populationScaleVersion
            && (try! scaleControlRestored.durableStateBytes())
                == scaleControlBytes)

    var minimizedA = gateFB05Session(
        "gate-f-b05-minimized",
        familyEnabled: true,
        scaleEnabled: true
    )
    var minimizedB = gateFB05Session(
        "gate-f-b05-minimized",
        familyEnabled: true,
        scaleEnabled: true
    )
    _ = try! minimizedA.advanceTick()
    _ = try! minimizedB.advanceTick()
    let minimizedBytes = try! minimizedA.durableStateBytes()
    let minimizedCheckpointA = try! minimizedA.makeCheckpoint()
    let minimizedCheckpointB = try! minimizedB.makeCheckpoint()
    let minimizedRestored = try! AgentSimulationSession.restoring(
        minimizedCheckpointA
    )
    check("historical Evaluation 05 minimized fixture restores schema 35",
          minimizedCheckpointA.schemaVersion
            == AgentCheckpointSchema.populationScaleVersion
            && minimizedRestored.familyV1Enabled
            && minimizedRestored.populationScaleSnapshot().enabled)
    check("schema 35 restored durable state is byte exact",
          (try! minimizedRestored.durableStateBytes()) == minimizedBytes)
    check("Family plus scale is deterministic across equivalent sessions",
          (try! minimizedA.durableStateBytes())
            == (try! minimizedB.durableStateBytes())
            && minimizedCheckpointA.semanticDigest
                == minimizedCheckpointB.semanticDigest)
    let beforeObserver = try! minimizedA.durableStateBytes()
    let observer = minimizedA.observerSnapshot(
        worldBinding: gateFB05ObserverBinding(minimizedA)
    )
    check("Observer schema 13 remains read-only for Family plus scale",
          observer.header.schemaVersion == 13
            && (try! minimizedA.durableStateBytes()) == beforeObserver)

    let beforeContinuation = minimizedRestored.familySnapshot()
    var continued = minimizedRestored
    _ = try! continued.advanceTick()
    let continuedCheckpoint = try! continued.makeCheckpoint()
    let continuedRestored = try! AgentSimulationSession.restoring(
        continuedCheckpoint
    )
    check("schema 35 restore continues and re-checkpoints exactly",
          continued.tick == minimizedRestored.tick + 1
            && continued.familySnapshot() == beforeContinuation
            && continuedCheckpoint.schemaVersion == 35
            && (try! continuedRestored.durableStateBytes())
                == (try! continued.durableStateBytes()))

    let strictVersions = [
        AgentCheckpointSchema.durableHouseConsentVersion,
        AgentCheckpointSchema.legacyEstateVersion,
        AgentCheckpointSchema.estateVersion,
        AgentCheckpointSchema.renewableSubsistenceVersion,
        AgentCheckpointSchema.independentEcologicalReceiptVersion,
        AgentCheckpointSchema.productionVersion,
        AgentCheckpointSchema.barterVersion,
        AgentCheckpointSchema.contractVersion,
        AgentCheckpointSchema.marketVersion,
        AgentCheckpointSchema.populationScaleVersion,
        AgentCheckpointSchema.knowledgeVersion,
        AgentCheckpointSchema.languageVersion,
    ]
    check("Family compatibility policy preserves schema 25 legacy semantics",
          AgentCheckpointSchema.familyValidationSemantics(for: 25)
            == .legacyCausalProofFallback)
    check("Family compatibility policy explicitly covers strict schemas 26-37",
          strictVersions.allSatisfy {
              AgentCheckpointSchema.familyValidationSemantics(for: $0)
                == .strictDurableConsent
          })
    check("Family compatibility policy rejects unsupported schema integers",
          AgentCheckpointSchema.familyValidationSemantics(for: 24) == nil
            && AgentCheckpointSchema.familyValidationSemantics(for: 38) == nil)

    let cofounded = gateFB05CofoundedSession(
        "gate-f-b05-family-compatibility"
    )
    let modernCheckpoint = try! cofounded.makeCheckpoint()
    let modernRestored = try! AgentSimulationSession.restoring(
        modernCheckpoint
    )
    check("schema 26 strict durable co-founding proof restores exactly",
          modernCheckpoint.schemaVersion == 26
            && (try! modernRestored.durableStateBytes())
                == (try! cofounded.durableStateBytes()))

    var estateCarrier = gateFB05Session(
        "gate-f-b05-estate-carrier",
        familyEnabled: true,
        scaleEnabled: false
    )
    try! estateCarrier.setMaterialRightsEnabled(true)
    try! estateCarrier.setMortalityEnabled(
        true, configuration: .embodiedLive
    )
    try! estateCarrier.setEstatesEnabled(true)
    let estateCarrierCheckpoint = try! estateCarrier.makeCheckpoint()
    let estateCarrierRestored = try! AgentSimulationSession.restoring(
        estateCarrierCheckpoint
    )
    check("Estate schema 28 carries strict Family state byte-exact",
          estateCarrierCheckpoint.schemaVersion == 28
            && (try! estateCarrierRestored.durableStateBytes())
                == (try! estateCarrier.durableStateBytes()))

    let gateESchemas = [
        AgentCheckpointSchema.productionVersion,
        AgentCheckpointSchema.barterVersion,
        AgentCheckpointSchema.contractVersion,
        AgentCheckpointSchema.marketVersion,
    ]
    let gateECarriersExact = gateESchemas.allSatisfy { version in
        let carrier = gateFB05GateECarrier(
            "gate-f-b05-gate-e-\(version)", schemaVersion: version
        )
        guard let checkpoint = try? carrier.makeCheckpoint(),
              checkpoint.schemaVersion == version,
              let restored = try? AgentSimulationSession.restoring(
                  checkpoint
              ) else {
            return false
        }
        return (try? restored.durableStateBytes())
            == (try? carrier.durableStateBytes())
    }
    check("Gate E schemas 31-34 carry strict Family state byte-exact",
          gateECarriersExact)

    let strictMissingProof = gateFB05WithoutCofoundingProof(
        modernCheckpoint, schemaVersion: 26
    )
    check("schema 26 refuses missing durable co-founding proof",
          gateFB05RejectsFamilyState(
              strictMissingProof, detail: "co-founding consent proof"
          ))

    let legacyCheckpoint = gateFB05WithoutCofoundingProof(
        modernCheckpoint, schemaVersion: 25
    )
    var legacyRestored = try! AgentSimulationSession.restoring(
        legacyCheckpoint
    )
    let legacyBytes = try! legacyRestored.durableStateBytes()
    _ = try! legacyRestored.advanceTick()
    check("legitimate schema 25 retained-cause fallback restores and continues",
          legacyCheckpoint.schemaVersion == 25
            && legacyRestored.tick == 1
            && legacyRestored.familySnapshot().houses.count == 1)

    var legacyPromotion = try! AgentSimulationSession.restoring(
        legacyCheckpoint
    )
    let beforePromotion = try! legacyPromotion.durableStateBytes()
    let strictPromotionRefused: Bool
    do {
        try gateFB05EnableScale(&legacyPromotion)
        strictPromotionRefused = false
    } catch AgentSessionError.family(.invalidState(let detail)) {
        strictPromotionRefused = detail == "co-founding consent proof"
    } catch {
        strictPromotionRefused = false
    }
    check("live validation uses promoted effective schema 35 semantics",
          strictPromotionRefused
            && (try! legacyPromotion.durableStateBytes()) == beforePromotion
            && !legacyPromotion.populationScaleSnapshot().enabled)
    check("legacy continuation does not rewrite retained schema 25 bytes",
          legacyBytes
            == (try! AgentSimulationSession.restoring(
                legacyCheckpoint
            ).durableStateBytes()))

    let joined = gateFB05JoinedSession(
        "gate-f-b05-join-compatibility"
    )
    let joinedCheckpoint = try! joined.makeCheckpoint()
    let joinedLegacyCheckpoint = gateFB05WithoutJoinConsent(
        joinedCheckpoint, schemaVersion: 25
    )
    check("schema 25 retained-cause adult-join fallback remains legitimate",
          joinedCheckpoint.schemaVersion == 26
            && (try? AgentSimulationSession.restoring(
                joinedLegacyCheckpoint
            )) != nil)
    let joinedModernMissingConsent = gateFB05WithoutJoinConsent(
        joinedCheckpoint, schemaVersion: 26
    )
    check("schema 26 refuses missing durable adult-join consent",
          gateFB05RejectsFamilyState(
              joinedModernMissingConsent,
              detail: "explicit house join consent"
          ))

    var joinedScale = joined
    try! gateFB05EnableScale(&joinedScale)
    let joinedScaleCheckpoint = try! joinedScale.makeCheckpoint()
    let joinedSchema35MissingConsent = gateFB05WithoutJoinConsent(
        joinedScaleCheckpoint, schemaVersion: 35
    )
    check("schema 35 refuses missing durable adult-join consent",
          joinedScaleCheckpoint.schemaVersion == 35
            && gateFB05RejectsFamilyState(
                joinedSchema35MissingConsent,
                detail: "explicit house join consent"
            ))

    var strictScale = cofounded
    try! gateFB05EnableScale(&strictScale)
    let strictScaleBytes = try! strictScale.durableStateBytes()
    let strictScaleCheckpoint = try! strictScale.makeCheckpoint()
    let strictScaleRestored = try! AgentSimulationSession.restoring(
        strictScaleCheckpoint
    )
    check("valid strict Family proof composes with schema 35",
          strictScaleCheckpoint.schemaVersion == 35
            && (try! strictScaleRestored.durableStateBytes())
                == strictScaleBytes)
    let schema35MissingProof = gateFB05WithoutCofoundingProof(
        strictScaleCheckpoint, schemaVersion: 35
    )
    check("schema 35 refuses missing durable co-founding proof",
          gateFB05RejectsFamilyState(
              schema35MissingProof,
              detail: "co-founding consent proof"
          ))

    let malformedSchema35 = gateFB05MutatedCheckpoint(
        minimizedCheckpointA
    ) { durable in
        var family = durable["familyState"] as! [String: Any]
        family["nextHouseOrdinal"] = 99
        durable["familyState"] = family
    }
    check("malformed schema 35 Family counters remain rejected",
          gateFB05RejectsFamilyState(
              malformedSchema35,
              detail: "bounds, ordering or counters"
          ))

    let unsupportedSchema = gateFB05MutatedCheckpoint(
        minimizedCheckpointA
    ) { durable in
        durable["schemaVersion"] = 36
    }
    let unsupportedRejected: Bool
    do {
        _ = try AgentSimulationSession.restoring(unsupportedSchema)
        unsupportedRejected = false
    } catch AgentCheckpointError.unsupportedSchema(let version) {
        unsupportedRejected = version == 36
    } catch {
        unsupportedRejected = false
    }
    check("unsupported future schema rejects at checkpoint boundary",
          unsupportedRejected)

    let migrantID = AgentID(rawValue: "agent_0")!
    var migrated = gateFB05Session(
        "gate-f-b05-secondary-resident",
        familyEnabled: true,
        scaleEnabled: true
    )
    _ = try! migrated.beginSettlementMigration(
        agentID: migrantID,
        destinationSettlementID: gateFB05EastID,
        verifiedRoute: gateFB05Route(
            from: try! migrated.state(for: migrantID).position,
            to: gateFB05East
        )
    )
    try! gateFB05CompleteMigration(&migrated, agentID: migrantID)
    let migratedBytes = try! migrated.durableStateBytes()
    let migratedCheckpoint = try! migrated.makeCheckpoint()
    var migratedRestored = try! AgentSimulationSession.restoring(
        migratedCheckpoint
    )
    let migratedPopulation = migratedRestored.populationSnapshot()
    let migratedScale = migratedRestored.populationScaleSnapshot()
    let migratedHouseholds = migratedRestored.householdSnapshot()
    check("secondary-settlement Family aggregate restores coherent authority",
          migratedCheckpoint.schemaVersion == 35
            && (try! migratedRestored.durableStateBytes()) == migratedBytes
            && migratedPopulation.members.first {
                $0.agentID == migrantID
            }?.settlementID == gateFB05EastID
            && migratedRestored.lifecycleSnapshot().members.first {
                $0.agentID == migrantID
            }?.settlementID == gateFB05EastID
            && (try! migratedRestored.household(
                for: migrantID
            )?.settlementID) == gateFB05EastID
            && (try! migratedRestored.state(
                for: migrantID
            )).homePosition == gateFB05East
            && migratedScale.fidelityRecords.filter {
                $0.agentID == migrantID
            }.count == 1)
    check("secondary-settlement current authorities remain singular",
          gateFB05DuplicateCount(
              migratedRestored.snapshot().agents.map(\.id)
          ) == 0
            && gateFB05DuplicateCount(
                migratedPopulation.members.map(\.agentID)
            ) == 0
            && gateFB05DuplicateCount(
                migratedScale.fidelityRecords.map(\.agentID)
            ) == 0
            && gateFB05DuplicateCount(
                migratedHouseholds.currentMemberships.map(\.agentID)
            ) == 0
            && gateFB05DuplicateCount(
                migratedPopulation.settlements.flatMap(\.residentIDs)
            ) == 0)
    let arrivalCount = migratedScale.settlementMigrations.filter {
        $0.agentID == migrantID && $0.status == .arrived
    }.count
    let familyBeforeTick = migratedRestored.familySnapshot()
    _ = try! migratedRestored.advanceTick()
    check("migrated Family continuation replays no arrival or family effect",
          migratedRestored.populationScaleSnapshot().settlementMigrations
            .filter {
                $0.agentID == migrantID && $0.status == .arrived
            }.count == arrivalCount
            && migratedRestored.familySnapshot() == familyBeforeTick)

    print("GATE_F_BLOCKER_05_PASS"
        + " checkpointSchema=35 observerSchema=13"
        + " compatibility=25:legacy,26-37:strict"
        + " minimizedDigest=\(minimizedCheckpointA.semanticDigest.rawValue)"
        + " migratedDigest=\(migratedCheckpoint.semanticDigest.rawValue)"
        + " duplicateAuthority=0 restartDuplicateEffects=0")
}
