import Foundation
import PebbleAgents

private let gateFE12A3Owner = AgentID(rawValue: "agent_0")!
private let gateFE12A3Partner = AgentID(rawValue: "agent_1")!
private let gateFE12A3User = AgentID(rawValue: "agent_2")!
private let gateFE12A3East = AgentSettlementID(rawValue: "settlement-east")!
private let gateFE12A3EastPosition = AgentPosition(x: 6, y: 64, z: 0)
private let gateFE12A3Identity = AgentMaterialIdentitySnapshot(
    itemKey: "iron_pickaxe", damage: 0, enchantments: [], label: nil,
    canonicalDataJSON: "{}"
)
private let gateFE12A3Asset = AgentMaterialAssetID(
    rawValue: "asset:gate-f-e12:attack-03:pickaxe"
)!
private let gateFE12A3Claim = AgentMaterialClaimID(
    rawValue: "claim:gate-f-e12:attack-03:owner"
)!
private let gateFE12A3Permission = AgentMaterialPermissionID(
    rawValue: "permission:gate-f-e12:attack-03:tool"
)!

private let gateFE12A3Habitats: [AgentEcologyHabitatObservation] = (0..<3).map {
    ordinal in
    let forage = AgentPosition(x: 1, y: 64, z: ordinal * 2)
    return AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: ordinal,
        habitatPosition: AgentPosition(x: forage.x, y: 63, z: forage.z),
        foragePosition: forage, habitatFingerprint: 123_100 + ordinal,
        distanceFromSettlement: abs(forage.x) + abs(forage.z),
        directionIndex: ordinal, worldReadCount: 4
    )
}

private func gateFE12A3Founder(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: 0, y: 64, z: ordinal * 2)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: ordinal == 0 ? 0.3 : 0, fatigue: 0,
            curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Evaluation 12 Attack 03",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress()
    )
}

private func gateFE12A3Interaction(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actor: AgentID,
    counterparty: AgentID
) -> AgentFamilyInteractionReceipt {
    let states = Dictionary(uniqueKeysWithValues: session.snapshot().agents.map {
        (AgentID(rawValue: $0.id)!, $0)
    })
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind, actorID: actor,
        counterpartyID: counterparty, observedTick: session.tick,
        actorPosition: states[actor]!.position,
        counterpartyPosition: states[counterparty]!.position,
        communicationVerified: true
    )
}

private func gateFE12A3Session(_ simulationID: String) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.3, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 1,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 1_232, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map(gateFE12A3Founder),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 6),
        configuration: try! AgentPopulationConfiguration(
            maximumActivePopulation: 7, maximumMigrationRecords: 16
        )
    )
    try! session.initializeLocalEcology(
        observations: gateFE12A3Habitats,
        configuration: try! AgentLocalEcologyConfiguration(
            maximumPatches: 3, maximumHabitatCandidates: 3,
            observationRadius: 8, patchCapacity: 4, initialYield: 4,
            regenerationIntervalTicks: 2, regenerationQuantity: 4,
            maximumForageIntentsPerTick: 8, maximumForageHistory: 64,
            maximumPressureFrames: 32, maximumHabitatReadsPerScan: 32
        )
    )
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A3Habitats
    )
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFE12A3East, anchor: gateFE12A3EastPosition,
            receptionPosition: gateFE12A3EastPosition,
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

    let proposal = try! session.proposeUnion(gateFE12A3Interaction(
        session, id: "e12-a3-union-proposal", kind: .unionProposal,
        actor: gateFE12A3Owner, counterparty: gateFE12A3Partner
    ))
    _ = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFE12A3Interaction(
            session, id: "e12-a3-union-accept", kind: .unionAcceptance,
            actor: gateFE12A3Partner, counterparty: gateFE12A3Owner
        )
    )
    let holder = AgentMaterialHolderObservation(
        holder: .agent(gateFE12A3Owner),
        materialIdentity: gateFE12A3Identity, quantity: 1,
        custodyFingerprint: "e12-a3-owner-pickaxe",
        physicalReceiptID: "e12-a3-register-receipt",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "e12-a3-register",
        asset: AgentMaterialAssetReference(
            assetID: gateFE12A3Asset,
            materialIdentity: gateFE12A3Identity, quantity: 1
        ),
        observation: holder
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "e12-a3-claim", assetID: gateFE12A3Asset,
        claimID: gateFE12A3Claim, claimantID: gateFE12A3Owner,
        basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "e12-a3-own", assetID: gateFE12A3Asset,
        claimID: gateFE12A3Claim,
        recognizingAgentIDs: [gateFE12A3Owner, gateFE12A3Partner, gateFE12A3User]
    ))
    _ = try! session.beginSettlementMigration(
        agentID: gateFE12A3Owner,
        destinationSettlementID: gateFE12A3East,
        verifiedRoute: (0...6).map {
            AgentPosition(x: $0, y: 64, z: 0)
        }
    )
    return session
}

private func gateFE12A3Perception(
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
    return AgentPerceptionInput(
        agentId: migration.agentID.rawValue,
        worldObservation: try! AgentWorldObservation(
            worldTick: session.tick + 1, position: state.position,
            center: column(state.position),
            neighbors: AgentCardinalDirection.allCases.map { direction in
                let target = AgentPosition(
                    x: state.position.x + direction.dx,
                    y: state.position.y,
                    z: state.position.z + direction.dz
                )
                return AgentWorldNeighborObservation(
                    direction: direction, column: column(target), stepDelta: 0,
                    traversable: true, dangerousDrop: false
                )
            },
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

private func gateFE12A3Advance(_ session: inout AgentSimulationSession) {
    if let migration = session.populationScaleSnapshot().settlementMigrations
        .first(where: { $0.status == .inTransit }) {
        _ = try! session.advanceTick(perceptions: [
            gateFE12A3Perception(session: session, migration: migration),
        ])
        if session.populationScaleSnapshot().settlementMigrations.contains(
            where: { $0.status == .inTransit }
        ) {
            let outcomes = AgentMovementCoordinator.resolve(
                snapshot: session.snapshot()
            )
            try! session.applyVerifiedPhysicalMovements(outcomes.map {
                AgentVerifiedPhysicalMovement(kind: .navigationStep, outcome: $0)
            })
        }
    } else {
        _ = try! session.advanceTick()
    }
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: gateFE12A3Habitats
    )
}

private func gateFE12A3FeedSurvivors(_ session: inout AgentSimulationSession) {
    for ordinal in 1...2 {
        let id = AgentID(rawValue: "agent_\(ordinal)")!
        let habitat = gateFE12A3Habitats[ordinal]
        let outcome = try! session.applyForageIntents([
            AgentForageIntent(
                forageID: "e12-a3-feed-agent_\(ordinal)-t\(session.tick)",
                patchID: habitat.patchID, agentID: id, tick: session.tick,
                target: habitat.foragePosition, observedAtTick: session.tick,
                expectedHabitatFingerprint: habitat.habitatFingerprint
            ),
        ], habitatValidations: gateFE12A3Habitats).first!
        precondition(outcome.status == .succeeded)
        let consumed = try! session.consumeFood(AgentConsumptionIntent(
            consumptionId: "e12-a3-consume-agent_\(ordinal)-t\(session.tick)",
            agentId: id.rawValue, tick: session.tick,
            resource: .foodRaw, quantity: 1
        ))
        precondition(consumed.status == .succeeded)
    }
}

private func gateFE12A3Event(
    _ session: AgentSimulationSession,
    operationID: String
) -> UInt64 {
    session.materialRightsSnapshot().recentTransitions.first {
        $0.operationID == operationID
    }!.eventID!.sequence.rawValue
}

private struct GateFE12A3Causal: Codable, Equatable {
    let unionActivation: UInt64
    let registration: UInt64
    let claim: UInt64
    let ownership: UInt64
    let migrationStart: UInt64
    let useGrant: UInt64?
    let mortalityPending: UInt64?
    let useRevoke: UInt64?
    let materialExit: UInt64?
    let migrationFailure: UInt64?
    let estatePlan: UInt64?
    let deathFinal: UInt64?
    let estateSettlement: UInt64?
}

private struct GateFE12A3Report: Codable, Equatable {
    let phase: String
    let tick: Int
    let checkpointSchema: Int
    let observerSchema: Int
    let checkpointSHA256: String
    let durableSHA256: String
    let causal: GateFE12A3Causal
    let migrationStatus: String
    let ownerResidentCount: Int
    let ownerTransitCount: Int
    let assetHolder: String
    let assetOwner: String?
    let permissionCount: Int
    let claimCount: Int
    let deathCount: Int
    let estateCount: Int
    let estateStatus: String?
    let assetEstateStatus: String?
    let nextMigrationOrdinal: UInt64
    let duplicateSettlementMutationCount: Int
    let replayedDeaths: Int
    let replayedEstates: Int
    let observerMutationCount: Int
    let assertions: [String: Bool]
}

private func gateFE12A3Report(
    phase: String,
    session: inout AgentSimulationSession,
    causal: GateFE12A3Causal,
    expectedStage: String,
    duplicateSettlementMutationCount: Int = 0,
    replayedDeaths: Int = 0,
    replayedEstates: Int = 0,
    observerSchema: Int = 13,
    observerMutationCount: Int = 0
) -> GateFE12A3Report {
    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let durableBytes = try! session.durableStateBytes()
    let registry = session.durableState().populationRegistry!
    let scale = registry.scaleState!
    let migration = scale.settlementMigrations.first!
    let rights = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == gateFE12A3Asset
    }!
    let estate = session.estateSnapshot().estates.first
    let ownerResident = registry.settlements.filter {
        $0.residentIDs.contains(gateFE12A3Owner)
    }.count
    let ownerTransit = registry.settlements.filter {
        $0.inTransitIDs.contains(gateFE12A3Owner)
    }.count
    let holderText = rights.lastVerifiedHolder.holder.stableText
    var assertions: [String: Bool] = [
        "checkpoint_schema_35": checkpoint.schemaVersion == 35,
        "one_migration_identity": scale.nextSettlementMigrationOrdinal == 2
            && scale.settlementMigrations.count == 1,
        "single_current_settlement_authority": ownerResident + ownerTransit
            <= 1,
        "rights_record_singular": session.materialRightsSnapshot().records.filter {
            $0.asset.assetID == gateFE12A3Asset
        }.count == 1,
        "observer_read_only": observerMutationCount == 0,
        "zero_replay": replayedDeaths == 0 && replayedEstates == 0,
        "causal_origin_before_migration": causal.registration < causal.claim
            && causal.claim < causal.ownership
            && causal.ownership < causal.migrationStart,
    ]
    if expectedStage == "writer" {
        assertions["writer_in_transit_owner_exact"] = migration.status == .inTransit
            && ownerResident == 0 && ownerTransit == 1
            && holderText == "agent:agent_0"
            && rights.recognizedOwnership?.ownerID == gateFE12A3Owner
            && estate == nil
    } else if expectedStage == "settled" {
        assertions["in_transit_grant_then_pending_revoke"] =
            causal.migrationStart < (causal.useGrant ?? 0)
                && (causal.useGrant ?? UInt64.max)
                    < (causal.mortalityPending ?? 0)
                && (causal.mortalityPending ?? UInt64.max)
                    < (causal.useRevoke ?? 0)
        assertions["terminal_physical_and_estate_chain"] =
            (causal.useRevoke ?? UInt64.max) < (causal.materialExit ?? 0)
                && (causal.materialExit ?? UInt64.max)
                    < (causal.migrationFailure ?? 0)
                && (causal.migrationFailure ?? UInt64.max)
                    < (causal.deathFinal ?? 0)
                && (causal.deathFinal ?? UInt64.max)
                    < (causal.estateSettlement ?? 0)
        assertions["settled_material_truth_exact"] = migration.status == .failed
            && migration.failure == .memberDied && ownerResident == 0
            && ownerTransit == 0 && holderText == "agent:agent_1"
            && rights.recognizedOwnership?.ownerID == gateFE12A3Partner
            && rights.permissions.isEmpty && rights.claims.count == 1
            && rights.claims.first?.basis == .received
            && estate?.status == .settled
            && estate?.assets.first?.status == .transferred
            && duplicateSettlementMutationCount == 0
    }
    return GateFE12A3Report(
        phase: phase, tick: session.tick,
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observerSchema,
        checkpointSHA256: AgentCheckpointDigest.sha256(checkpointBytes).rawValue,
        durableSHA256: AgentCheckpointDigest.sha256(durableBytes).rawValue,
        causal: causal, migrationStatus: migration.status.rawValue,
        ownerResidentCount: ownerResident, ownerTransitCount: ownerTransit,
        assetHolder: holderText,
        assetOwner: rights.recognizedOwnership?.ownerID.rawValue,
        permissionCount: rights.permissions.count, claimCount: rights.claims.count,
        deathCount: session.mortalitySnapshot().totalDeathCount,
        estateCount: session.estateSnapshot().totalEstateCount,
        estateStatus: estate?.status.rawValue,
        assetEstateStatus: estate?.assets.first?.status.rawValue,
        nextMigrationOrdinal: scale.nextSettlementMigrationOrdinal,
        duplicateSettlementMutationCount: duplicateSettlementMutationCount,
        replayedDeaths: replayedDeaths, replayedEstates: replayedEstates,
        observerMutationCount: observerMutationCount, assertions: assertions
    )
}

private func gateFE12A3InitialCausal(
    _ session: AgentSimulationSession
) -> GateFE12A3Causal {
    let union = session.familySnapshot().unions.first!
    let migration = session.populationScaleSnapshot().settlementMigrations.first!
    return GateFE12A3Causal(
        unionActivation: union.activationEventID.sequence.rawValue,
        registration: gateFE12A3Event(session, operationID: "e12-a3-register"),
        claim: gateFE12A3Event(session, operationID: "e12-a3-claim"),
        ownership: gateFE12A3Event(session, operationID: "e12-a3-own"),
        migrationStart: migration.startedEventID.sequence.rawValue,
        useGrant: nil, mortalityPending: nil, useRevoke: nil,
        materialExit: nil, migrationFailure: nil, estatePlan: nil,
        deathFinal: nil, estateSettlement: nil
    )
}

private func gateFE12A3Write<T: Encodable>(_ value: T, to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try! encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFE12A3FreshIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment["PEBBLELAB_GATE_F_E12_A3_PHASE"] else {
        return false
    }
    guard ["write-migrating", "restore-settle", "restore-verify"].contains(phase),
          let output = environment["PEBBLELAB_GATE_F_E12_A3_OUT"] else {
        preconditionFailure("invalid Evaluation 12 Attack 03 environment")
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let initialCheckpoint = root.appendingPathComponent("migrating_checkpoint_v35.json")
    let initialDurable = root.appendingPathComponent("migrating_durable_state.json")
    let finalCheckpoint = root.appendingPathComponent("settled_checkpoint_v35.json")
    let finalDurable = root.appendingPathComponent("settled_durable_state.json")
    let writerReport = root.appendingPathComponent("process_1_report.json")
    let readerReport = root.appendingPathComponent("process_2_report.json")

    if phase == "write-migrating" {
        var session = gateFE12A3Session("gate-f-e12-a3-fresh")
        let causal = gateFE12A3InitialCausal(session)
        let report = gateFE12A3Report(
            phase: phase, session: &session, causal: causal,
            expectedStage: "writer"
        )
        let checkpointBytes = try! AgentCheckpointCodec.encode(session.makeCheckpoint())
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: initialCheckpoint, options: .atomic)
        try! durableBytes.write(to: initialDurable, options: .atomic)
        gateFE12A3Write(report, to: writerReport)
        check("Attack 03 writer checkpoints migrating economic owner",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    if phase == "restore-settle" {
        let checkpointBytes = try! Data(contentsOf: initialCheckpoint)
        let durableBytes = try! Data(contentsOf: initialDurable)
        let previous = try! JSONDecoder().decode(
            GateFE12A3Report.self, from: Data(contentsOf: writerReport)
        )
        let checkpoint = try! AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: checkpointBytes
        )
        var session = try! AgentSimulationSession.restoring(checkpoint)
        let restoredDurable = try! session.durableStateBytes()
        let observerBefore = try! session.durableStateBytes()
        let observer = session.observerSnapshot(
            worldBinding: try! AgentObserverWorldBinding(
                worldID: "gate-f-e12-a3-world",
                storageIdentity: "memory:gate-f-e12-a3", seed: 1_232,
                dimension: 0, observedWorldTick: session.tick
            )
        )
        let observerMutations = (try! session.durableStateBytes())
            == observerBefore ? 0 : 1
        _ = try! session.applyMaterialRightsOperation(.grantUse(
            operationID: "e12-a3-intransit-grant",
            assetID: gateFE12A3Asset, permissionID: gateFE12A3Permission,
            grantorID: gateFE12A3Owner, userID: gateFE12A3User,
            allowedUses: [.toolUse], expiresAtTick: nil
        ))
        let grant = gateFE12A3Event(session, operationID: "e12-a3-intransit-grant")
        var iterations = 0
        while session.pendingMortalityTransitions().isEmpty && iterations < 8 {
            gateFE12A3Advance(&session)
            if session.tick == 2 {
                gateFE12A3FeedSurvivors(&session)
            }
            iterations += 1
        }
        let pending = session.pendingMortalityTransitions().first {
            $0.agentID == gateFE12A3Owner
        }!
        _ = try! session.applyMaterialRightsOperation(.revokeUse(
            operationID: "e12-a3-pending-revoke",
            assetID: gateFE12A3Asset, permissionID: gateFE12A3Permission,
            actorID: gateFE12A3Owner
        ))
        let revoke = gateFE12A3Event(session, operationID: "e12-a3-pending-revoke")
        let source = session.materialRightsSnapshot().records.first {
            $0.asset.assetID == gateFE12A3Asset
        }!.lastVerifiedHolder
        let mortalityReceipt = "e12-a3-mortality-receipt"
        let destination = AgentMaterialHolderObservation(
            holder: .container("0,64,0"),
            materialIdentity: gateFE12A3Identity, quantity: 1,
            custodyFingerprint: "e12-a3-container-after-exit",
            physicalReceiptID: mortalityReceipt,
            observedAtTick: session.tick
        )
        _ = try! session.applyMaterialRightsOperation(.mortalityPhysicalExit(
            AgentMaterialMortalityExitOutcome(
                operationID: "e12-a3-material-exit", assetID: gateFE12A3Asset,
                terminalAgentID: gateFE12A3Owner,
                sourceObservation: source, destinationObservation: destination,
                physicalReceiptID: mortalityReceipt
            )
        ))
        let materialExit = gateFE12A3Event(
            session, operationID: "e12-a3-material-exit"
        )
        _ = try! session.applyMortalityPhysicalCustodyOutcome(
            AgentMortalityPhysicalCustodyOutcome(
                operationID: "e12-a3-custody", terminalAgentID: gateFE12A3Owner,
                kind: .transferred, physicalReceiptID: mortalityReceipt,
                destinationHolderID: "container:0,64,0", stackCount: 1,
                itemCount: 1,
                physicalAssets: [AgentMaterialStackSnapshot(
                    identity: gateFE12A3Identity, count: 1
                )],
                verifiedAtTick: session.tick
            )
        )
        let death = try! session.finalizePendingMortality(for: gateFE12A3Owner)
        let migration = session.populationScaleSnapshot().settlementMigrations.first!
        var estate = session.estateSnapshot().estates.first!
        let nomination = estate.administrations.last {
            $0.status == .nominated
        }!
        _ = try! session.acceptEstateAdministration(
            estateID: estate.estateID,
            administratorID: nomination.administratorID,
            operationID: "e12-a3-administrator-acceptance"
        )
        estate = session.estateSnapshot().estates.first!
        let entry = estate.assets.first!
        let administration = estate.administrations.last {
            $0.status == .active
        }!
        let settlementOperation = "e12-a3-estate-settlement"
        let settlement = AgentEstatePhysicalSettlementOutcome(
            operationID: settlementOperation, estateID: estate.estateID,
            entryID: entry.entryID,
            administratorID: administration.administratorID,
            beneficiaryID: entry.assignedBeneficiaryID!,
            intendedCustodianID: entry.intendedCustodianID,
            sourceObservation: session.materialRightsSnapshot().records.first {
                $0.asset.assetID == gateFE12A3Asset
            }!.lastVerifiedHolder,
            destinationObservation: AgentMaterialHolderObservation(
                holder: .agent(gateFE12A3Partner),
                materialIdentity: gateFE12A3Identity, quantity: 1,
                custodyFingerprint: "e12-a3-partner-after-settlement",
                physicalReceiptID: settlementOperation,
                observedAtTick: session.tick
            ),
            sourceFingerprintAfterTransfer: "e12-a3-container-after-settlement",
            destinationFingerprintBeforeTransfer: "e12-a3-partner-before-settlement",
            physicalReceiptID: settlementOperation
        )
        _ = try! session.applyEstatePhysicalSettlement(settlement)
        let settlementEvent = session.estateSnapshot().estates.first!.assets.first!
            .settlementEventID!.sequence.rawValue
        let afterSettlement = try! session.durableStateBytes()
        var duplicateMutations = 0
        do {
            _ = try session.applyEstatePhysicalSettlement(settlement)
            if try! session.durableStateBytes() != afterSettlement {
                duplicateMutations = 1
            }
        } catch {
            if try! session.durableStateBytes() != afterSettlement {
                duplicateMutations = 1
            }
        }
        let causal = GateFE12A3Causal(
            unionActivation: previous.causal.unionActivation,
            registration: previous.causal.registration,
            claim: previous.causal.claim, ownership: previous.causal.ownership,
            migrationStart: previous.causal.migrationStart,
            useGrant: grant, mortalityPending: pending.pendingEventID.sequence.rawValue,
            useRevoke: revoke, materialExit: materialExit,
            migrationFailure: migration.failureEventID?.sequence.rawValue,
            estatePlan: estate.successorPlanProof?.successorPlanEventID.sequence.rawValue,
            deathFinal: death.deathEventID.sequence.rawValue,
            estateSettlement: settlementEvent
        )
        var report = gateFE12A3Report(
            phase: phase, session: &session, causal: causal,
            expectedStage: "settled",
            duplicateSettlementMutationCount: duplicateMutations,
            observerSchema: observer.header.schemaVersion,
            observerMutationCount: observerMutations
        )
        var assertions = report.assertions
        assertions["initial_checkpoint_reencodes_exactly"] =
            (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
        assertions["initial_durable_restores_exactly"] = restoredDurable == durableBytes
        assertions["observer_schema_13"] = observer.header.schemaVersion == 13
        report = GateFE12A3Report(
            phase: report.phase, tick: report.tick,
            checkpointSchema: report.checkpointSchema,
            observerSchema: report.observerSchema,
            checkpointSHA256: report.checkpointSHA256,
            durableSHA256: report.durableSHA256, causal: report.causal,
            migrationStatus: report.migrationStatus,
            ownerResidentCount: report.ownerResidentCount,
            ownerTransitCount: report.ownerTransitCount,
            assetHolder: report.assetHolder, assetOwner: report.assetOwner,
            permissionCount: report.permissionCount, claimCount: report.claimCount,
            deathCount: report.deathCount, estateCount: report.estateCount,
            estateStatus: report.estateStatus,
            assetEstateStatus: report.assetEstateStatus,
            nextMigrationOrdinal: report.nextMigrationOrdinal,
            duplicateSettlementMutationCount: report.duplicateSettlementMutationCount,
            replayedDeaths: report.replayedDeaths,
            replayedEstates: report.replayedEstates,
            observerMutationCount: report.observerMutationCount,
            assertions: assertions
        )
        let finalCheckpointBytes = try! AgentCheckpointCodec.encode(session.makeCheckpoint())
        let finalDurableBytes = try! session.durableStateBytes()
        try! finalCheckpointBytes.write(to: finalCheckpoint, options: .atomic)
        try! finalDurableBytes.write(to: finalDurable, options: .atomic)
        gateFE12A3Write(report, to: readerReport)
        check("Attack 03 fresh restore settles migrated material claim exactly once",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: finalCheckpoint)
    let durableBytes = try! Data(contentsOf: finalDurable)
    let previous = try! JSONDecoder().decode(
        GateFE12A3Report.self, from: Data(contentsOf: readerReport)
    )
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurable = try! session.durableStateBytes()
    let deathsBefore = session.mortalitySnapshot().totalDeathCount
    let estatesBefore = session.estateSnapshot().totalEstateCount
    gateFE12A3Advance(&session)
    var report = gateFE12A3Report(
        phase: phase, session: &session, causal: previous.causal,
        expectedStage: "settled",
        duplicateSettlementMutationCount: previous.duplicateSettlementMutationCount,
        replayedDeaths: session.mortalitySnapshot().totalDeathCount - deathsBefore,
        replayedEstates: session.estateSnapshot().totalEstateCount - estatesBefore
    )
    var assertions = report.assertions
    assertions["settled_checkpoint_reencodes_exactly"] =
        (try? AgentCheckpointCodec.encode(checkpoint)) == checkpointBytes
    assertions["settled_durable_restores_exactly"] = restoredDurable == durableBytes
    report = GateFE12A3Report(
        phase: report.phase, tick: report.tick,
        checkpointSchema: report.checkpointSchema,
        observerSchema: report.observerSchema,
        checkpointSHA256: report.checkpointSHA256,
        durableSHA256: report.durableSHA256, causal: report.causal,
        migrationStatus: report.migrationStatus,
        ownerResidentCount: report.ownerResidentCount,
        ownerTransitCount: report.ownerTransitCount,
        assetHolder: report.assetHolder, assetOwner: report.assetOwner,
        permissionCount: report.permissionCount, claimCount: report.claimCount,
        deathCount: report.deathCount, estateCount: report.estateCount,
        estateStatus: report.estateStatus,
        assetEstateStatus: report.assetEstateStatus,
        nextMigrationOrdinal: report.nextMigrationOrdinal,
        duplicateSettlementMutationCount: report.duplicateSettlementMutationCount,
        replayedDeaths: report.replayedDeaths,
        replayedEstates: report.replayedEstates,
        observerMutationCount: report.observerMutationCount,
        assertions: assertions
    )
    gateFE12A3Write(report, to: root.appendingPathComponent("process_3_report.json"))
    check("Attack 03 final restore preserves settled economic and physical truth",
          report.assertions.values.allSatisfy { $0 })
    return true
}

func runPebbleAgentsGateFEvaluation12Attack03Smoke() {
    if gateFE12A3FreshIfRequested() { return }
    var session = gateFE12A3Session("gate-f-e12-a3-focused")
    let causal = gateFE12A3InitialCausal(session)
    let report = gateFE12A3Report(
        phase: "focused", session: &session, causal: causal,
        expectedStage: "writer"
    )
    section("Gate F Evaluation 12 Attack 03 — Gate E migration restart")
    for key in report.assertions.keys.sorted() {
        check("Attack 03 \(key)", report.assertions[key]!)
    }
    print(
        "GATE_F_E12_ATTACK_03_CAUSAL union=\(causal.unionActivation) "
            + "register=\(causal.registration) claim=\(causal.claim) "
            + "owner=\(causal.ownership) migration=\(causal.migrationStart)"
    )
    print(
        "GATE_F_E12_ATTACK_03_AUTHORITY tick=\(report.tick) migration="
            + "\(report.migrationStatus) resident=\(report.ownerResidentCount) "
            + "transit=\(report.ownerTransitCount) holder=\(report.assetHolder) "
            + "owner=\(report.assetOwner ?? "none")"
    )
    print(
        "GATE_F_E12_ATTACK_03_DIGEST checkpoint=\(report.checkpointSHA256) "
            + "durable=\(report.durableSHA256) schema="
            + "\(report.checkpointSchema) observer=\(report.observerSchema)"
    )
}
