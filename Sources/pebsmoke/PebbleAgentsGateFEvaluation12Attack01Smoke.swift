import Foundation
import PebbleAgents

private let gateFE12A1Origin = AgentPosition(x: 0, y: 64, z: 0)
private let gateFE12A1MainReception = AgentPosition(x: 0, y: 64, z: 2)
private let gateFE12A1East = AgentPosition(x: 8, y: 64, z: 0)
private let gateFE12A1EastID = AgentSettlementID(rawValue: "settlement-east")!
private let gateFE12A1Decedent = AgentID(rawValue: "agent_3")!
private let gateFE12A1PrePlanSibling = AgentID(rawValue: "agent_4")!
private let gateFE12A1RefusedNewborn = AgentID(rawValue: "agent_5")!
private let gateFE12A1Migrant = AgentID(rawValue: "agent_2")!
private let gateFE12A1MaterialIdentity = AgentMaterialIdentitySnapshot(
    itemKey: "iron_pickaxe", damage: 0, enchantments: [], label: nil,
    canonicalDataJSON: "{}"
)
private let gateFE12A1AssetID = AgentMaterialAssetID(
    rawValue: "asset:gate-f-e12:attack-01:iron-pickaxe"
)!
private let gateFE12A1ClaimID = AgentMaterialClaimID(
    rawValue: "claim:gate-f-e12:attack-01:owner"
)!

private let gateFE12A1ForagePositions = [
    AgentPosition(x: 1, y: 64, z: 0),
    AgentPosition(x: 3, y: 64, z: 0),
    AgentPosition(x: 5, y: 64, z: 0),
    AgentPosition(x: 6, y: 64, z: 1),
    AgentPosition(x: 0, y: 64, z: 1),
    AgentPosition(x: 0, y: 64, z: -1),
    AgentPosition(x: 2, y: 64, z: 1),
    AgentPosition(x: 2, y: 64, z: -1),
]
private let gateFE12A1Habitats = gateFE12A1ForagePositions.enumerated().map {
    ordinal, forage in
    AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: forage.x, y: 63, z: forage.z),
        foragePosition: forage,
        habitatFingerprint: 120_100 + ordinal,
        distanceFromSettlement: abs(forage.x) + abs(forage.z),
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFE12A1Founder(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Evaluation 12 Attack 01",
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

private func gateFE12A1Interaction(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actorID: AgentID,
    counterpartyID: AgentID
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues: session.snapshot().agents.map {
        (AgentID(rawValue: $0.id)!, $0)
    })
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actorID, counterpartyID: counterpartyID,
        observedTick: session.tick,
        actorPosition: states[actorID]!.position,
        counterpartyPosition: states[counterpartyID]!.position,
        communicationVerified: true
    )
}

private func gateFE12A1Session(_ simulationID: String) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.3, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 4,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1_212, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map(gateFE12A1Founder),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFE12A1Origin,
        receptionPosition: gateFE12A1MainReception,
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 7,
            maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: gateFE12A1Habitats,
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: 8, maximumHabitatCandidates: 8,
            observationRadius: 8, patchCapacity: 4, initialYield: 4,
            regenerationIntervalTicks: 2, regenerationQuantity: 4,
            maximumForageIntentsPerTick: 8, maximumForageHistory: 128,
            maximumPressureFrames: 32, maximumHabitatReadsPerScan: 64
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A1Habitats
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1, maturityAgeTicks: 16,
            reproductionEvaluationIntervalTicks: 1,
            reproductionPlanDelayTicks: 1,
            reproductionCooldownTicks: 1,
            maximumRetainedBirthRecords: 64,
            maximumRetainedPlanRecords: 64,
            maximumParentBirthCount: 16
        )
    )
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFE12A1EastID,
            anchor: gateFE12A1East,
            receptionPosition: gateFE12A1East,
            capacity: 4, residentIDs: [], inTransitIDs: []
        )],
        configuration: try! AgentPopulationScaleConfiguration(
            maximumSettlements: 2, maximumLiveAgents: 7,
            maximumNearAgents: 3, nearMaintenanceCadence: 2,
            dormantMaintenanceCadence: 8, rotationIntervalTicks: 4,
            maximumFidelityTransitionHistory: 32,
            maximumSettlementMigrationHistory: 8,
            maximumConcurrentSettlementMigrations: 1,
            maximumSettlementMigrationRouteLength: 16
        )
    )
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(true, configuration: .embodiedLive)
    try! session.setEstatesEnabled(true)
    try! session.setReproductionEnabled(true)

    let first = AgentID(rawValue: "agent_0")!
    let second = AgentID(rawValue: "agent_1")!
    let household = try! session.currentMembership(of: first)!.householdID
    try! session.moveMembers(memberIDs: [second], to: household)
    let proposal = try! session.proposeUnion(gateFE12A1Interaction(
        session, id: "e12-a1-union-proposal", kind: .unionProposal,
        actorID: first, counterpartyID: second
    ))
    _ = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFE12A1Interaction(
            session, id: "e12-a1-union-accept", kind: .unionAcceptance,
            actorID: second, counterpartyID: first
        )
    )
    _ = try! session.foundLineage(
        rootPersonID: first, actorID: first,
        operationID: "e12-a1-lineage-agent-0"
    )
    _ = try! session.foundLineage(
        rootPersonID: second, actorID: second,
        operationID: "e12-a1-lineage-agent-1"
    )
    _ = try! session.coFoundHouse(
        founderIDs: [first, second],
        receipts: [
            gateFE12A1Interaction(
                session, id: "e12-a1-cofound-a", kind: .houseCoFoundation,
                actorID: first, counterpartyID: second
            ),
            gateFE12A1Interaction(
                session, id: "e12-a1-cofound-b", kind: .houseCoFoundation,
                actorID: second, counterpartyID: first
            ),
        ]
    )
    let holder = AgentMaterialHolderObservation(
        holder: .agent(first), materialIdentity: gateFE12A1MaterialIdentity,
        quantity: 1, custodyFingerprint: "e12-a1-agent-0-tool",
        physicalReceiptID: "e12-a1-tool-register-physical",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "e12-a1-rights-register",
        asset: AgentMaterialAssetReference(
            assetID: gateFE12A1AssetID,
            materialIdentity: gateFE12A1MaterialIdentity, quantity: 1
        ),
        observation: holder
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "e12-a1-rights-claim", assetID: gateFE12A1AssetID,
        claimID: gateFE12A1ClaimID, claimantID: first, basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "e12-a1-rights-recognize",
        assetID: gateFE12A1AssetID, claimID: gateFE12A1ClaimID,
        recognizingAgentIDs: [first, second, AgentID(rawValue: "agent_2")!]
    ))
    return session
}

private func gateFE12A1Forage(
    _ session: inout AgentSimulationSession,
    ordinal: Int,
    quantity: Int,
    habitatOrdinal: Int? = nil
) {
    let id = AgentID(rawValue: "agent_\(ordinal)")!
    let selectedHabitatOrdinal = habitatOrdinal ?? ordinal
    let habitat = gateFE12A1Habitats[selectedHabitatOrdinal]
    let purpose = habitatOrdinal == nil ? "" : "-journey"
    let intents = (0..<quantity).map { item in
        AgentForageIntent(
            forageID: "e12-a1-forage-\(id.rawValue)\(purpose)-t"
                + "\(session.tick)-\(item)",
            patchID: habitat.patchID, agentID: id, tick: session.tick,
            target: habitat.foragePosition, observedAtTick: session.tick,
            expectedHabitatFingerprint: habitat.habitatFingerprint
        )
    }
    let outcomes = try! session.applyForageIntents(
        intents, habitatValidations: gateFE12A1Habitats
    )
    precondition(outcomes.count == quantity)
    precondition(
        outcomes.allSatisfy { $0.status == .succeeded },
        "forage agent=\(id.rawValue) tick=\(session.tick) outcomes=\(outcomes)"
    )
}

private func gateFE12A1Consume(
    _ session: inout AgentSimulationSession,
    ordinal: Int
) {
    _ = try! session.consumeFood(AgentConsumptionIntent(
        consumptionId: "e12-a1-feed-agent_\(ordinal)-t\(session.tick)",
        agentId: "agent_\(ordinal)", tick: session.tick,
        resource: .foodRaw, quantity: 1
    ))
}

private func gateFE12A1FeedAdults(_ session: inout AgentSimulationSession) {
    guard [1, 3, 5, 7, 9].contains(session.tick) else { return }
    if session.tick == 1 {
        for ordinal in 0...2 {
            gateFE12A1Forage(&session, ordinal: ordinal, quantity: 4)
        }
    }
    if session.tick == 9 {
        for ordinal in 0...1 {
            gateFE12A1Forage(&session, ordinal: ordinal, quantity: 4)
        }
    }
    for ordinal in (session.tick == 9 ? 0...1 : 0...2) {
        gateFE12A1Consume(&session, ordinal: ordinal)
    }
}

private func gateFE12A1Birth(
    _ session: inout AgentSimulationSession,
    fingerprint: Int
) -> AgentBirthRecord {
    let plan = session.pendingBirthSitePlan()!
    let record = try! session.applyBirthSiteObservation(AgentBirthSiteObservation(
        planID: plan.planID, observedTick: session.tick,
        position: AgentPosition(x: 1, y: 64, z: 1),
        candidateIndex: 0, worldFingerprint: fingerprint
    ))
    precondition(
        record != nil,
        "birth cancelled tick=\(session.tick) fingerprint=\(fingerprint) "
            + "plan=\(plan) reproduction=\(session.reproductionSnapshot())"
    )
    return record!
}

private func gateFE12A1ProvideChildFood(
    _ session: inout AgentSimulationSession,
    caregiverID: AgentID,
    dependentID: AgentID
) -> UInt64 {
    guard let engagement = session.dependentCareSnapshot().activeEngagements.first(where: {
        $0.caregiverID == caregiverID && $0.dependentID == dependentID
            && $0.kind == .provideFood
    }) else {
        fatalError(
            "missing public nourishment engagement caregiver=\(caregiverID.rawValue) "
                + "dependent=\(dependentID.rawValue) tick=\(session.tick)"
        )
    }
    let ordinal: Int
    switch caregiverID.rawValue {
    case "agent_0": ordinal = 0
    case "agent_1": ordinal = 1
    default: fatalError("unexpected caregiver \(caregiverID.rawValue)")
    }
    gateFE12A1Forage(&session, ordinal: ordinal, quantity: 1)
    let result = try! session.provideDependentNourishment(AgentCareProvisionIntent(
        provisionID: "e12-a1-care-food-\(dependentID.rawValue)-t\(session.tick)",
        needID: engagement.needID, caregiverID: caregiverID,
        dependentID: dependentID, tick: session.tick
    ))
    precondition(result.succeeded && result.consumedByDependent == 1)
    return session.durableState().dependentCareState!.lastCareEventID.sequence.rawValue
}

@discardableResult
private func gateFE12A1ResolveEmptyCustody(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) -> AgentMortalityPhysicalCustodyResolution {
    try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "e12-a1-empty-custody-\(agentID.rawValue)-t\(session.tick)",
            terminalAgentID: agentID, kind: .verifiedEmpty,
            physicalReceiptID: "e12-a1-empty-exit-\(agentID.rawValue)-t\(session.tick)",
            destinationHolderID: nil, stackCount: 0, itemCount: 0,
            physicalAssets: [], verifiedAtTick: session.tick
        )
    )
}

private func gateFE12A1ProofDigest(
    _ proof: AgentEstateSuccessorPlanProof
) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return AgentCheckpointDigest.sha256(try! encoder.encode(proof)).rawValue
}

private func gateFE12A1CurrentAuthoritySingular(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    guard let population = durable.populationRegistry,
          let scale = population.scaleState,
          let lifecycle = durable.lifecycleState,
          let household = durable.householdState else { return false }
    return durable.agents.allSatisfy { state in
        let id = state.agentID
        let settlementOwners = population.settlements.reduce(0) { count, settlement in
            count + (settlement.residentIDs.contains(id) ? 1 : 0)
                + (settlement.inTransitIDs.contains(id) ? 1 : 0)
        }
        return population.members.filter { $0.agentID == id }.count == 1
            && lifecycle.members.filter { $0.agentID == id }.count == 1
            && scale.fidelityRecords.filter { $0.agentID == id }.count == 1
            && household.membershipPeriods.filter {
                $0.agentID == id && $0.leftTick == nil
            }.count == 1
            && settlementOwners == 1
            && scale.settlementMigrations.filter {
                $0.agentID == id && $0.status == .inTransit
            }.count <= 1
    }
}

private func gateFE12A1DeadAuthorityAbsent(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    guard let population = durable.populationRegistry,
          let scale = population.scaleState,
          let household = durable.householdState,
          let care = durable.dependentCareState else { return false }
    return !durable.agents.contains { $0.agentID == gateFE12A1Decedent }
        && !population.members.contains { $0.agentID == gateFE12A1Decedent }
        && !population.settlements.contains {
            $0.residentIDs.contains(gateFE12A1Decedent)
                || $0.inTransitIDs.contains(gateFE12A1Decedent)
        }
        && !scale.fidelityRecords.contains { $0.agentID == gateFE12A1Decedent }
        && !scale.settlementMigrations.contains {
            $0.agentID == gateFE12A1Decedent && $0.status == .inTransit
        }
        && !household.membershipPeriods.contains {
            $0.agentID == gateFE12A1Decedent && $0.leftTick == nil
        }
        && !care.assignments.contains {
            $0.status == .active
                && ($0.dependentID == gateFE12A1Decedent
                    || $0.caregiverID == gateFE12A1Decedent)
        }
        && !(care.childhoodV2?.guardianships.contains {
            $0.status == .active
                && ($0.dependentID == gateFE12A1Decedent
                    || $0.guardianID == gateFE12A1Decedent)
        } ?? true)
}

private struct GateFE12A1CausalEvidence: Codable, Equatable {
    let unionActivation: UInt64
    let familyHouseFoundation: UInt64
    let firstBirth: UInt64
    let firstParentage: UInt64
    let prePlanSiblingBirth: UInt64
    let prePlanSiblingParentage: UInt64
    let prePlanGuardianStart: UInt64
    let outboundMigrationStart: UInt64
    let outboundMigrationArrival: UInt64
    let returnMigrationStart: UInt64
    let mortalityPending: UInt64
    let estatePlan: UInt64
    let deathFinal: UInt64
    let postPlanCareProvision: UInt64
    let postPlanGuardianStart: UInt64
    let postPlanBirthAttemptPlan: UInt64
    let postPlanBirthRefusal: UInt64
    let postPlanJourneyProvision: UInt64
    let returnMigrationArrival: UInt64?
}

private struct GateFE12A1IdentityEvidence: Codable, Equatable {
    let nextPopulationOrdinal: Int
    let nextFidelityOrdinal: UInt64
    let nextMigrationOrdinal: UInt64
    let nextHouseholdOrdinal: Int
    let householdMembershipPeriods: Int
    let nextUnionOrdinal: Int
    let nextLineageOrdinal: Int
    let nextFamilyHouseOrdinal: Int
    let guardianHistoryCount: Int
    let deathCount: Int
    let estateCount: Int
    let materialRecordCount: Int
    let materialTransitionCount: Int
}

private struct GateFE12A1Report: Codable, Equatable {
    let schemaVersion: Int
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointBytes: Int
    let durableBytes: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let successorProofSHA256: String
    let ledgerMaximumEvents: Int
    let retainedEventCount: Int
    let droppedEventCount: UInt64
    let sensitiveEventBodiesRetained: Int
    let historicalPrePlanSiblingRows: Int
    let historicalPostPlanSiblingRows: Int
    let guardianAtPlan: String?
    let currentGuardian: String?
    let currentPrePlanSiblingRelation: String
    let currentPostPlanSiblingRelation: String
    let activeMigrationCount: Int
    let completedMigrationCount: Int
    let replayedBirths: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let causal: GateFE12A1CausalEvidence
    let identities: GateFE12A1IdentityEvidence
    let assertions: [String: Bool]
}

private struct GateFE12A1Fixture {
    var session: AgentSimulationSession
    let proof: AgentEstateSuccessorPlanProof
    let causal: GateFE12A1CausalEvidence
}

private func gateFE12A1MigrationRoute(
    from: AgentPosition,
    to: AgentPosition
) -> [AgentPosition] {
    var route = [from]
    var cursor = from
    while cursor.z != to.z {
        cursor = AgentPosition(
            x: cursor.x, y: cursor.y,
            z: cursor.z + (cursor.z < to.z ? 1 : -1)
        )
        route.append(cursor)
    }
    while cursor.x != to.x {
        cursor = AgentPosition(
            x: cursor.x + (cursor.x < to.x ? 1 : -1),
            y: cursor.y, z: cursor.z
        )
        route.append(cursor)
    }
    return route
}

private func gateFE12A1MigrationPerception(
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

private func gateFE12A1Advance(_ session: inout AgentSimulationSession) {
    guard let migration = session.populationScaleSnapshot().settlementMigrations
        .first(where: { $0.status == .inTransit }) else {
        _ = try! session.advanceTick()
        _ = try! session.applyLocalEcologyEndOfTick(
            habitatValidations: gateFE12A1Habitats
        )
        return
    }
    _ = try! session.advanceTick(perceptions: [
        gateFE12A1MigrationPerception(session: session, migration: migration),
    ])
    let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
    try! session.applyVerifiedPhysicalMovements(outcomes.map {
        AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
    })
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A1Habitats
    )
}

private func gateFE12A1BuildFixture(_ simulationID: String) -> GateFE12A1Fixture {
    var session = gateFE12A1Session(simulationID)
    while session.pendingBirthSitePlan() == nil {
        gateFE12A1Advance(&session)
        gateFE12A1FeedAdults(&session)
    }
    let firstBirth = gateFE12A1Birth(&session, fingerprint: 120_201)
    precondition(firstBirth.newbornID == gateFE12A1Decedent)

    let outbound = try! session.beginSettlementMigration(
        agentID: gateFE12A1Migrant,
        destinationSettlementID: gateFE12A1EastID,
        verifiedRoute: gateFE12A1MigrationRoute(
            from: try! session.state(for: gateFE12A1Migrant).position,
            to: gateFE12A1East
        )
    )

    while session.tick < 4 {
        gateFE12A1Advance(&session)
        gateFE12A1FeedAdults(&session)
    }
    let secondBirth = gateFE12A1Birth(&session, fingerprint: 120_202)
    precondition(secondBirth.newbornID == gateFE12A1PrePlanSibling)

    while session.populationScaleSnapshot().settlementMigrations.first(where: {
        $0.migrationID == outbound.migrationID
    })?.status != .arrived && session.tick < 8 {
        gateFE12A1Advance(&session)
        gateFE12A1FeedAdults(&session)
    }
    let outboundAfter = session.populationScaleSnapshot().settlementMigrations.first {
        $0.migrationID == outbound.migrationID
    }!
    precondition(
        outboundAfter.status == .arrived,
        "outbound status=\(outboundAfter.status) tick=\(session.tick) "
            + "cursor=\(outboundAfter.routeCursor) state="
            + "\(try! session.state(for: gateFE12A1Migrant))"
    )
    let returnMigration = try! session.beginSettlementMigration(
        agentID: gateFE12A1Migrant,
        destinationSettlementID: session.populationSnapshot().settlement!.settlementID,
        verifiedRoute: gateFE12A1MigrationRoute(
            from: try! session.state(for: gateFE12A1Migrant).position,
            to: gateFE12A1MainReception
        )
    )

    while !session.pendingMortalityTransitions().contains(where: {
        $0.agentID == gateFE12A1Decedent
    }) && session.tick < 11 {
        gateFE12A1Advance(&session)
        gateFE12A1FeedAdults(&session)
    }
    let pending = session.pendingMortalityTransitions().first {
        $0.agentID == gateFE12A1Decedent
    }!
    let prePlanGuardian = try! session.currentGuardian(
        for: gateFE12A1PrePlanSibling
    )!
    _ = gateFE12A1ResolveEmptyCustody(
        &session, agentID: gateFE12A1Decedent
    )
    let death = try! session.finalizePendingMortality(
        for: gateFE12A1Decedent
    )
    let estate = session.estateSnapshot().estates.first {
        $0.decedentID == gateFE12A1Decedent
    }!
    let proof = estate.successorPlanProof!
    let postPlanCareProvision = gateFE12A1ProvideChildFood(
        &session, caregiverID: prePlanGuardian.guardianID,
        dependentID: gateFE12A1PrePlanSibling
    )
    let replacementGuardian = [
        AgentID(rawValue: "agent_0")!, AgentID(rawValue: "agent_1")!,
    ].first { $0 != prePlanGuardian.guardianID }!
    try! session.reassignGuardian(
        dependentID: gateFE12A1PrePlanSibling,
        to: replacementGuardian
    )
    let postPlanGuardian = try! session.currentGuardian(
        for: gateFE12A1PrePlanSibling
    )!
    let refusedPlan = session.pendingBirthSitePlan()!
    let populationOrdinalBeforeRefusal = session.populationSnapshot()
        .nextPopulationOrdinal!
    let refusedBirth = try! session.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: refusedPlan.planID, observedTick: session.tick,
            position: AgentPosition(x: 1, y: 64, z: 4),
            candidateIndex: 0, worldFingerprint: 120_203
        )
    )
    precondition(refusedBirth == nil)
    precondition(
        session.populationSnapshot().nextPopulationOrdinal
            == populationOrdinalBeforeRefusal
    )
    let refusedPlanAfter = session.lifecycleSnapshot().plans.first {
        $0.planID == refusedPlan.planID
    }!
    precondition(refusedPlanAfter.terminalEventID != nil)

    gateFE12A1Forage(
        &session, ordinal: 2, quantity: 4, habitatOrdinal: 3
    )
    gateFE12A1Consume(&session, ordinal: 2)
    let provisionedMigrant = try! session.state(for: gateFE12A1Migrant)
    precondition(
        provisionedMigrant.resourceInventory.count(of: .foodRaw) == 3
            && provisionedMigrant.needs.hunger < 0.01
    )
    let postPlanJourneyProvision = session.causalLedgerSnapshot().summary
        .latestSequence

    let firstParentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == gateFE12A1Decedent
    }!
    let secondParentage = session.kinshipSnapshot().parentageRecords.first {
        $0.childID == gateFE12A1PrePlanSibling
    }!
    let union = session.familySnapshot().unions.first!
    let familyHouse = session.familySnapshot().houses.first!
    let latestSensitiveSequence = [
        proof.successorPlanEventID.sequence.rawValue,
        postPlanCareProvision,
        refusedPlanAfter.terminalEventID!.sequence.rawValue,
        postPlanJourneyProvision,
        postPlanGuardian.startedEventID.sequence.rawValue,
        returnMigration.startedEventID.sequence.rawValue,
    ].max()!
    while session.causalLedgerSnapshot().summary.droppedEventCount
            < latestSensitiveSequence {
        try! session.setReproductionEnabled(!session.reproductionEnabled)
    }
    if session.reproductionEnabled {
        try! session.setReproductionEnabled(false)
    }
    let causal = GateFE12A1CausalEvidence(
        unionActivation: union.activationEventID.sequence.rawValue,
        familyHouseFoundation: familyHouse.foundationEventID.sequence.rawValue,
        firstBirth: firstBirth.populationBornEventID.sequence.rawValue,
        firstParentage: firstParentage.recordedEventID.sequence.rawValue,
        prePlanSiblingBirth: secondBirth.populationBornEventID.sequence.rawValue,
        prePlanSiblingParentage: secondParentage.recordedEventID.sequence.rawValue,
        prePlanGuardianStart: prePlanGuardian.startedEventID.sequence.rawValue,
        outboundMigrationStart: outbound.startedEventID.sequence.rawValue,
        outboundMigrationArrival: outboundAfter.arrivedEventID!.sequence.rawValue,
        returnMigrationStart: returnMigration.startedEventID.sequence.rawValue,
        mortalityPending: pending.pendingEventID.sequence.rawValue,
        estatePlan: proof.successorPlanEventID.sequence.rawValue,
        deathFinal: death.deathEventID.sequence.rawValue,
        postPlanCareProvision: postPlanCareProvision,
        postPlanGuardianStart: postPlanGuardian.startedEventID.sequence.rawValue,
        postPlanBirthAttemptPlan: refusedPlan.createdEventID.sequence.rawValue,
        postPlanBirthRefusal:
            refusedPlanAfter.terminalEventID!.sequence.rawValue,
        postPlanJourneyProvision: postPlanJourneyProvision,
        returnMigrationArrival: nil
    )
    return GateFE12A1Fixture(session: session, proof: proof, causal: causal)
}

private func gateFE12A1Identities(
    _ session: AgentSimulationSession
) -> GateFE12A1IdentityEvidence {
    let durable = session.durableState()
    let population = durable.populationRegistry!
    let scale = population.scaleState!
    let household = durable.householdState!
    let family = durable.familyState!
    let care = durable.dependentCareState!
    let mortality = durable.mortalityState!
    let estate = durable.estateState!
    let rights = durable.materialRightsState!
    return GateFE12A1IdentityEvidence(
        nextPopulationOrdinal: population.nextPopulationOrdinal.rawValue,
        nextFidelityOrdinal: scale.nextFidelityTransitionOrdinal,
        nextMigrationOrdinal: scale.nextSettlementMigrationOrdinal,
        nextHouseholdOrdinal: household.nextHouseholdOrdinal.rawValue,
        householdMembershipPeriods: household.membershipPeriods.count,
        nextUnionOrdinal: family.nextUnionOrdinal,
        nextLineageOrdinal: family.nextLineageOrdinal,
        nextFamilyHouseOrdinal: family.nextHouseOrdinal,
        guardianHistoryCount: care.childhoodV2!.guardianships.count,
        deathCount: mortality.totalDeathCount,
        estateCount: estate.totalEstateCount,
        materialRecordCount: rights.records.count,
        materialTransitionCount: rights.recentTransitions.count
    )
}

private func gateFE12A1Report(
    phase: String,
    session: inout AgentSimulationSession,
    expectedProofDigest: String,
    causal: GateFE12A1CausalEvidence,
    replayedBirths: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0,
    observerMutationCount: Int = 0
) -> GateFE12A1Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let estate = session.estateSnapshot().estates.first {
        $0.decedentID == gateFE12A1Decedent
    }!
    let proof = estate.successorPlanProof!
    let proofDigest = gateFE12A1ProofDigest(proof)
    let ledger = session.causalLedgerSnapshot()
    let sensitiveSequences: Set<UInt64> = [
        causal.unionActivation, causal.familyHouseFoundation,
        causal.firstBirth, causal.firstParentage,
        causal.prePlanSiblingBirth, causal.prePlanSiblingParentage,
        causal.prePlanGuardianStart, causal.outboundMigrationStart,
        causal.outboundMigrationArrival, causal.returnMigrationStart,
        causal.mortalityPending, causal.estatePlan, causal.deathFinal,
        causal.postPlanCareProvision,
        causal.postPlanGuardianStart, causal.postPlanBirthAttemptPlan,
        causal.postPlanBirthRefusal, causal.postPlanJourneyProvision,
    ]
    let retainedSensitive = ledger.events.filter {
        sensitiveSequences.contains($0.eventID.sequence.rawValue)
    }.count
    let prePlanRows = proof.eligibilityRows.filter {
        $0.agentID == gateFE12A1PrePlanSibling
    }
    let postPlanRows = proof.eligibilityRows.filter {
        $0.agentID == gateFE12A1RefusedNewborn
    }
    let currentGuardian = try! session.currentGuardian(
        for: gateFE12A1PrePlanSibling
    )
    let migrations = session.populationScaleSnapshot().settlementMigrations
    let identities = gateFE12A1Identities(session)
    let birthIDs = session.lifecycleSnapshot().births.map(\.birthID)
    let newbornIDs = session.lifecycleSnapshot().births.map(\.newbornID)
    let migrationIDs = migrations.map(\.migrationID)
    let assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "successor_proof_v2": proof.version == 2,
        "proof_digest_immutable": proofDigest == expectedProofDigest,
        "pre_plan_relation_retained": prePlanRows.count == 1
            && causal.prePlanSiblingParentage < causal.estatePlan,
        "post_plan_birth_refuses_without_retroactivity": postPlanRows.isEmpty
            && causal.estatePlan < causal.postPlanBirthRefusal,
        "current_pre_plan_full_sibling": session.siblingRelation(
            between: gateFE12A1Decedent,
            and: gateFE12A1PrePlanSibling
        ) == .fullSibling,
        "refused_newborn_has_no_current_relation": session.siblingRelation(
            between: gateFE12A1Decedent,
            and: gateFE12A1RefusedNewborn
        ) == .unknownPerson(gateFE12A1RefusedNewborn),
        "guardian_at_plan_retained": prePlanRows.first?.guardianIDAtPlan != nil
            && prePlanRows.first?.guardianIDAtPlan?.rawValue
                != currentGuardian?.guardianID.rawValue
            && causal.prePlanGuardianStart < causal.estatePlan
            && causal.estatePlan < causal.postPlanGuardianStart,
        "post_plan_care_is_causal_and_material": causal.estatePlan
            < causal.postPlanCareProvision
            && causal.postPlanCareProvision < causal.postPlanGuardianStart,
        "migration_spans_plan_and_restart": causal.returnMigrationStart
            < causal.estatePlan
            && causal.postPlanBirthRefusal < causal.postPlanJourneyProvision,
        "sensitive_event_bodies_compacted": retainedSensitive == 0,
        "bounded_causal_ledger": ledger.events.count <= 32
            && ledger.summary.droppedEventCount > 0,
        "singular_current_authority": gateFE12A1CurrentAuthoritySingular(session),
        "dead_current_authority_absent": gateFE12A1DeadAuthorityAbsent(session),
        "birth_identity_unique": Set(birthIDs).count == birthIDs.count
            && Set(newbornIDs).count == newbornIDs.count
            && newbornIDs == [
                gateFE12A1Decedent, gateFE12A1PrePlanSibling,
            ],
        "migration_identity_unique": Set(migrationIDs).count == migrationIDs.count
            && identities.nextMigrationOrdinal == 3,
        "identity_ordinals_monotonic": identities.nextPopulationOrdinal == 5
            && identities.nextUnionOrdinal == 2
            && identities.nextLineageOrdinal == 3
            && identities.nextFamilyHouseOrdinal == 2,
        "death_estate_exactly_once": identities.deathCount == 1
            && identities.estateCount == 1,
        "material_rights_current_and_singular": identities.materialRecordCount == 1,
        "zero_replay": replayedBirths == 0
            && replayedDeaths == 0 && replayedEstates == 0,
        "observer_read_only": observerMutationCount == 0,
    ]
    return GateFE12A1Report(
        schemaVersion: 1, phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion, observerSchema: 13,
        checkpointBytes: checkpointBytes.count,
        durableBytes: durableBytes.count,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        successorProofSHA256: proofDigest,
        ledgerMaximumEvents: 32, retainedEventCount: ledger.events.count,
        droppedEventCount: ledger.summary.droppedEventCount,
        sensitiveEventBodiesRetained: retainedSensitive,
        historicalPrePlanSiblingRows: prePlanRows.count,
        historicalPostPlanSiblingRows: postPlanRows.count,
        guardianAtPlan: prePlanRows.first?.guardianIDAtPlan?.rawValue,
        currentGuardian: currentGuardian?.guardianID.rawValue,
        currentPrePlanSiblingRelation: "fullSibling",
        currentPostPlanSiblingRelation: "notBorn",
        activeMigrationCount: migrations.filter { $0.status == .inTransit }.count,
        completedMigrationCount: migrations.filter { $0.status == .arrived }.count,
        replayedBirths: replayedBirths, replayedDeaths: replayedDeaths,
        replayedEstates: replayedEstates,
        observerMutationCount: observerMutationCount,
        causal: causal, identities: identities, assertions: assertions
    )
}

private func gateFE12A1WriteJSON<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [
        .prettyPrinted, .sortedKeys, .withoutEscapingSlashes,
    ]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

// Evaluation 12 Attack 05 continues the already-supported composed public
// trajectory from Attack 01 into a later multigeneration family history. This
// bridge exposes no product internals: it only packages the independent
// pebsmoke fixture and its public care/ecology continuation helpers.
func gateFE12A5BuildSeed(_ simulationID: String) -> GateFE12A5Seed {
    let fixture = gateFE12A1BuildFixture(simulationID)
    return GateFE12A5Seed(
        session: fixture.session,
        successorProofSHA256: gateFE12A1ProofDigest(fixture.proof),
        seedCausal: [
            "firstBirth": fixture.causal.firstBirth,
            "fullSiblingBirth": fixture.causal.prePlanSiblingBirth,
            "migrationOut": fixture.causal.outboundMigrationStart,
            "migrationReturn": fixture.causal.returnMigrationStart,
            "mortalityPending": fixture.causal.mortalityPending,
            "estatePlan": fixture.causal.estatePlan,
            "death": fixture.causal.deathFinal,
        ]
    )
}

func gateFE12A5AdvanceSupported(_ session: inout AgentSimulationSession) {
    gateFE12A1Advance(&session)
    let activeIDs = Set(session.expectedActiveAgentIDs())
    let engagements = session.dependentCareSnapshot().activeEngagements
        .filter { $0.kind == .provideFood }
        .sorted {
            ($0.caregiverID, $0.dependentID, $0.engagementID)
                < ($1.caregiverID, $1.dependentID, $1.engagementID)
        }
    let caregiverIDs = Set(engagements.map(\.caregiverID))
    let provisionerIDs = activeIDs.union(caregiverIDs).sorted()
    for caregiverID in provisionerIDs {
        guard let ordinal = Int(
            caregiverID.rawValue.split(separator: "_").last ?? ""
        ), ordinal < gateFE12A1Habitats.count else { continue }
        let state = try! session.state(for: caregiverID)
        let available = state.resourceInventory.count(of: .foodRaw)
        let inTransit = session.populationScaleSnapshot().settlementMigrations
            .contains {
                $0.agentID == caregiverID && $0.status == .inTransit
            }
        // The seed already provisions the public return journey. Match the
        // owning restore-arrive fixture: consume carried food while available,
        // but do not invent an off-route forage opportunity mid-migration.
        let adultConsumption = ordinal <= 2 && state.needs.hunger >= 0.25
            && (!inTransit || available > 0) ? 1 : 0
        let careCount = engagements.filter {
            $0.caregiverID == caregiverID
        }.count
        let required = adultConsumption + careCount
        if required > available {
            let needed = required - available
            let patches = session.localEcologySnapshot().patches
            let adjacentHabitatOrdinal = gateFE12A1Habitats.firstIndex {
                let habitat = $0
                return abs(habitat.foragePosition.x - state.position.x)
                    + abs(habitat.foragePosition.y - state.position.y)
                    + abs(habitat.foragePosition.z - state.position.z) == 1
                    && patches.contains {
                        $0.habitatFingerprint == habitat.habitatFingerprint
                            && $0.status == .available
                            && $0.currentYield >= needed
                    }
            }
            precondition(
                adjacentHabitatOrdinal != nil,
                "Attack 05 has no public adjacent forage yield for "
                    + "\(caregiverID.rawValue) at \(state.position) "
                    + "needed=\(needed) patches=\(patches)"
            )
            gateFE12A1Forage(
                &session, ordinal: ordinal, quantity: needed,
                habitatOrdinal: adjacentHabitatOrdinal!
            )
        }
        if adultConsumption == 1 {
            gateFE12A1Consume(&session, ordinal: ordinal)
        }
        for engagement in engagements where engagement.caregiverID == caregiverID {
            do {
                let result = try session.provideDependentNourishment(
                    AgentCareProvisionIntent(
                        provisionID: "e12-a5-care-\(engagement.dependentID.rawValue)"
                            + "-t\(session.tick)",
                        needID: engagement.needID,
                        caregiverID: caregiverID,
                        dependentID: engagement.dependentID,
                        tick: session.tick
                    )
                )
                precondition(result.succeeded && result.consumedByDependent == 1)
            } catch {
                let dependent = try! session.state(for: engagement.dependentID)
                preconditionFailure(
                    "Attack 05 public care failed tick=\(session.tick) "
                        + "caregiver=\(caregiverID.rawValue)@\(state.position) "
                        + "dependent=\(engagement.dependentID.rawValue)"
                        + "@\(dependent.position) error=\(error)"
                )
            }
        }
    }
}

private func gateFE12A1FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A1_PHASE"] else {
        return false
    }
    guard ["write-compacted", "restore-arrive", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A1_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 01 fresh-process environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let initialCheckpointURL = root.appendingPathComponent(
        "compacted_checkpoint_v35.json"
    )
    let initialDurableURL = root.appendingPathComponent(
        "compacted_durable_state.json"
    )
    let finalCheckpointURL = root.appendingPathComponent(
        "continued_checkpoint_v35.json"
    )
    let finalDurableURL = root.appendingPathComponent(
        "continued_durable_state.json"
    )
    let writerReportURL = root.appendingPathComponent("process_1_report.json")
    let readerReportURL = root.appendingPathComponent("process_2_report.json")

    if phase == "write-compacted" {
        var fixture = gateFE12A1BuildFixture("gate-f-e12-a1-fresh")
        let proofDigest = gateFE12A1ProofDigest(fixture.proof)
        let report = gateFE12A1Report(
            phase: phase, session: &fixture.session,
            expectedProofDigest: proofDigest, causal: fixture.causal
        )
        let checkpointBytes = try! AgentCheckpointCodec.encode(
            fixture.session.makeCheckpoint()
        )
        let durableBytes = try! fixture.session.durableStateBytes()
        try! checkpointBytes.write(to: initialCheckpointURL, options: .atomic)
        try! durableBytes.write(to: initialDurableURL, options: .atomic)
        gateFE12A1WriteJSON(report, to: writerReportURL)
        check("Attack 01 writer compacts composed schema-35 history",
              report.assertions.values.allSatisfy { $0 }
                && report.activeMigrationCount == 1)
        return true
    }

    if phase == "restore-arrive" {
        let checkpointBytes = try! Data(contentsOf: initialCheckpointURL)
        let durableBytes = try! Data(contentsOf: initialDurableURL)
        let previous = try! JSONDecoder().decode(
            GateFE12A1Report.self, from: Data(contentsOf: writerReportURL)
        )
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredDurable = try! session.durableStateBytes()
        let birthsBefore = session.lifecycleSnapshot().totalBirthCount
        let deathsBefore = session.mortalitySnapshot().totalDeathCount
        let estatesBefore = session.estateSnapshot().totalEstateCount
        let observerBytes = try! session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: try! AgentObserverWorldBinding(
                worldID: "gate-f-e12-a1-world",
                storageIdentity: "memory:gate-f-e12-a1", seed: 1_212,
                dimension: 0, observedWorldTick: session.tick
            )
        )
        let observerMutations = (try! session.durableStateBytes())
            == observerBytes ? 0 : 1
        var iterations = 0
        var postRestoreCareProvisions = 0
        while session.populationScaleSnapshot().settlementMigrations.contains(
            where: { $0.status == .inTransit }
        ) && iterations < 16 {
            let preMigration = session.populationScaleSnapshot()
                .settlementMigrations.first { $0.status == .inTransit }!
            let preActors = [0, 1, 2, 4].map { ordinal -> String in
                let state = try! session.state(
                    for: AgentID(rawValue: "agent_\(ordinal)")!
                )
                return "agent_\(ordinal):p\(state.position.x),\(state.position.z)"
                    + ":h\(state.needs.hunger):f"
                    + "\(state.resourceInventory.count(of: .foodRaw)):a"
                    + "\(state.lastAction?.name ?? "none")"
            }.joined(separator: ",")
            FileHandle.standardError.write(Data((
                "GATE_F_E12_A1_FRESH_PRE tick=\(session.tick) "
                    + "cursor=\(preMigration.routeCursor) \(preActors)\n"
            ).utf8))
            gateFE12A1Advance(&session)
            if let engagement = session.dependentCareSnapshot()
                .activeEngagements.first(where: {
                    $0.dependentID == gateFE12A1PrePlanSibling
                        && $0.kind == .provideFood
                }) {
                _ = gateFE12A1ProvideChildFood(
                    &session, caregiverID: engagement.caregiverID,
                    dependentID: gateFE12A1PrePlanSibling
                )
                postRestoreCareProvisions += 1
            }
            for ordinal in 0...2 {
                let adultID = AgentID(rawValue: "agent_\(ordinal)")!
                if try! session.state(for: adultID)
                    .resourceInventory.count(of: .foodRaw) > 0 {
                    gateFE12A1Consume(&session, ordinal: ordinal)
                }
            }
            iterations += 1
        }
        let arrival = session.populationScaleSnapshot().settlementMigrations.first {
            $0.migrationID.rawValue == "settlement-migration-00000002"
        }!.arrivedEventID!.sequence.rawValue
        let causal = GateFE12A1CausalEvidence(
            unionActivation: previous.causal.unionActivation,
            familyHouseFoundation: previous.causal.familyHouseFoundation,
            firstBirth: previous.causal.firstBirth,
            firstParentage: previous.causal.firstParentage,
            prePlanSiblingBirth: previous.causal.prePlanSiblingBirth,
            prePlanSiblingParentage: previous.causal.prePlanSiblingParentage,
            prePlanGuardianStart: previous.causal.prePlanGuardianStart,
            outboundMigrationStart: previous.causal.outboundMigrationStart,
            outboundMigrationArrival: previous.causal.outboundMigrationArrival,
            returnMigrationStart: previous.causal.returnMigrationStart,
            mortalityPending: previous.causal.mortalityPending,
            estatePlan: previous.causal.estatePlan,
            deathFinal: previous.causal.deathFinal,
            postPlanCareProvision: previous.causal.postPlanCareProvision,
            postPlanGuardianStart: previous.causal.postPlanGuardianStart,
            postPlanBirthAttemptPlan: previous.causal.postPlanBirthAttemptPlan,
            postPlanBirthRefusal: previous.causal.postPlanBirthRefusal,
            postPlanJourneyProvision: previous.causal.postPlanJourneyProvision,
            returnMigrationArrival: arrival
        )
        var report = gateFE12A1Report(
            phase: phase, session: &session,
            expectedProofDigest: previous.successorProofSHA256,
            causal: causal,
            replayedBirths: session.lifecycleSnapshot().totalBirthCount - birthsBefore,
            replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore,
            replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore,
            observerMutationCount: observerMutations
        )
        var assertions = report.assertions
        assertions["initial_checkpoint_reencodes_exactly"] =
            (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
        assertions["initial_durable_restores_exactly"] = restoredDurable == durableBytes
        assertions["observer_schema_13"] = observer.header.schemaVersion == 13
        assertions["migration_arrives_after_plan"] = causal.estatePlan < arrival
            && report.activeMigrationCount == 0
            && report.completedMigrationCount == 2
        assertions["post_restore_care_continues_materially"] =
            postRestoreCareProvisions > 0
        report = GateFE12A1Report(
            schemaVersion: report.schemaVersion, phase: report.phase,
            tick: report.tick, checkpointSchema: report.checkpointSchema,
            observerSchema: observer.header.schemaVersion,
            checkpointBytes: report.checkpointBytes,
            durableBytes: report.durableBytes,
            checkpointSHA256: report.checkpointSHA256,
            durableSHA256: report.durableSHA256,
            successorProofSHA256: report.successorProofSHA256,
            ledgerMaximumEvents: report.ledgerMaximumEvents,
            retainedEventCount: report.retainedEventCount,
            droppedEventCount: report.droppedEventCount,
            sensitiveEventBodiesRetained: report.sensitiveEventBodiesRetained,
            historicalPrePlanSiblingRows: report.historicalPrePlanSiblingRows,
            historicalPostPlanSiblingRows: report.historicalPostPlanSiblingRows,
            guardianAtPlan: report.guardianAtPlan,
            currentGuardian: report.currentGuardian,
            currentPrePlanSiblingRelation: report.currentPrePlanSiblingRelation,
            currentPostPlanSiblingRelation: report.currentPostPlanSiblingRelation,
            activeMigrationCount: report.activeMigrationCount,
            completedMigrationCount: report.completedMigrationCount,
            replayedBirths: report.replayedBirths,
            replayedDeaths: report.replayedDeaths,
            replayedEstates: report.replayedEstates,
            observerMutationCount: report.observerMutationCount,
            causal: report.causal, identities: report.identities,
            assertions: assertions
        )
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(
            session.makeCheckpoint()
        )
        let finalDurableBytes = try! session.durableStateBytes()
        try! finalCheckpointBytes.write(to: finalCheckpointURL, options: .atomic)
        try! finalDurableBytes.write(to: finalDurableURL, options: .atomic)
        gateFE12A1WriteJSON(report, to: readerReportURL)
        check("Attack 01 fresh restore preserves truth and completes migration",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: finalCheckpointURL)
    let durableBytes = try! Data(contentsOf: finalDurableURL)
    let previous = try! JSONDecoder().decode(
        GateFE12A1Report.self, from: Data(contentsOf: readerReportURL)
    )
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let birthsBefore = session.lifecycleSnapshot().totalBirthCount
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    _ = try! session.advanceTick()
    var report = gateFE12A1Report(
        phase: phase, session: &session,
        expectedProofDigest: previous.successorProofSHA256,
        causal: previous.causal,
        replayedBirths: session.lifecycleSnapshot().totalBirthCount - birthsBefore,
        replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore,
        replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore
    )
    var assertions = report.assertions
    assertions["continued_checkpoint_reencodes_exactly"] =
        (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
    assertions["continued_durable_restores_exactly"] = restoredDurable == durableBytes
    assertions["migration_does_not_replay"] = report.activeMigrationCount == 0
        && report.completedMigrationCount == 2
    report = GateFE12A1Report(
        schemaVersion: report.schemaVersion, phase: report.phase,
        tick: report.tick, checkpointSchema: report.checkpointSchema,
        observerSchema: report.observerSchema,
        checkpointBytes: report.checkpointBytes,
        durableBytes: report.durableBytes,
        checkpointSHA256: report.checkpointSHA256,
        durableSHA256: report.durableSHA256,
        successorProofSHA256: report.successorProofSHA256,
        ledgerMaximumEvents: report.ledgerMaximumEvents,
        retainedEventCount: report.retainedEventCount,
        droppedEventCount: report.droppedEventCount,
        sensitiveEventBodiesRetained: report.sensitiveEventBodiesRetained,
        historicalPrePlanSiblingRows: report.historicalPrePlanSiblingRows,
        historicalPostPlanSiblingRows: report.historicalPostPlanSiblingRows,
        guardianAtPlan: report.guardianAtPlan,
        currentGuardian: report.currentGuardian,
        currentPrePlanSiblingRelation: report.currentPrePlanSiblingRelation,
        currentPostPlanSiblingRelation: report.currentPostPlanSiblingRelation,
        activeMigrationCount: report.activeMigrationCount,
        completedMigrationCount: report.completedMigrationCount,
        replayedBirths: report.replayedBirths,
        replayedDeaths: report.replayedDeaths,
        replayedEstates: report.replayedEstates,
        observerMutationCount: report.observerMutationCount,
        causal: report.causal, identities: report.identities,
        assertions: assertions
    )
    gateFE12A1WriteJSON(
        report, to: root.appendingPathComponent("process_3_report.json")
    )
    check("Attack 01 second restore continues without replay",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack01Smoke() {
    section("Gate F Evaluation 12 Attack 01 — multi-history compaction")
    if gateFE12A1FreshProcessIfRequested() { return }
    var fixture = gateFE12A1BuildFixture("gate-f-e12-a1-focused")
    let proofDigest = gateFE12A1ProofDigest(fixture.proof)
    let report = gateFE12A1Report(
        phase: "focused", session: &fixture.session,
        expectedProofDigest: proofDigest, causal: fixture.causal
    )
    for key in report.assertions.keys.sorted() {
        check("Attack 01 \(key)", report.assertions[key] == true)
    }
    print(
        "GATE_F_E12_ATTACK_01_CAUSAL "
            + "union=\(report.causal.unionActivation) "
            + "house=\(report.causal.familyHouseFoundation) "
            + "firstBirth=\(report.causal.firstBirth) "
            + "preSibling=\(report.causal.prePlanSiblingParentage) "
            + "migrationOut=\(report.causal.outboundMigrationStart)>"
            + "\(report.causal.outboundMigrationArrival) "
            + "migrationReturn=\(report.causal.returnMigrationStart) "
            + "pending=\(report.causal.mortalityPending) "
            + "plan=\(report.causal.estatePlan) "
            + "death=\(report.causal.deathFinal) "
            + "careAfter=\(report.causal.postPlanCareProvision) "
            + "guardianAfter=\(report.causal.postPlanGuardianStart) "
            + "postBirthRefusal=\(report.causal.postPlanBirthRefusal)"
            + " journeyProvision=\(report.causal.postPlanJourneyProvision)"
    )
    print(
        "GATE_F_E12_ATTACK_01_AUTHORITY "
            + "tick=\(report.tick) activeMigration=\(report.activeMigrationCount) "
            + "preRows=\(report.historicalPrePlanSiblingRows) "
            + "postRows=\(report.historicalPostPlanSiblingRows) "
            + "guardianAtPlan=\(report.guardianAtPlan ?? "none") "
            + "currentGuardian=\(report.currentGuardian ?? "none") "
            + "deadAuthority=0 observerMutation=\(report.observerMutationCount)"
    )
    print(
        "GATE_F_E12_ATTACK_01_IDENTITY "
            + "population=\(report.identities.nextPopulationOrdinal) "
            + "fidelity=\(report.identities.nextFidelityOrdinal) "
            + "migration=\(report.identities.nextMigrationOrdinal) "
            + "household=\(report.identities.nextHouseholdOrdinal) "
            + "union=\(report.identities.nextUnionOrdinal) "
            + "lineage=\(report.identities.nextLineageOrdinal) "
            + "familyHouse=\(report.identities.nextFamilyHouseOrdinal) "
            + "death=\(report.identities.deathCount) estate=\(report.identities.estateCount)"
    )
    print(
        "GATE_F_E12_ATTACK_01_DIGEST checkpoint=\(report.checkpointSHA256) "
            + "durable=\(report.durableSHA256) proof=\(report.successorProofSHA256) "
            + "retained=\(report.retainedEventCount)/\(report.ledgerMaximumEvents) "
            + "dropped=\(report.droppedEventCount) sensitiveRetained="
            + "\(report.sensitiveEventBodiesRetained)"
    )
}
