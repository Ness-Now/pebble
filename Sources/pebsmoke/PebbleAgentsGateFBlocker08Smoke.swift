import Foundation
import PebbleAgents

private let gateFB08AgentIDs = (0..<3).map {
    AgentID(rawValue: "agent_\($0)")!
}
private let gateFB08Main = AgentPosition(x: 0, y: 64, z: 0)
private let gateFB08East = AgentPosition(x: 0, y: 64, z: 4)
private let gateFB08EastID = AgentSettlementID(
    rawValue: "settlement-east"
)!
private let gateFB08Identity = AgentMaterialIdentitySnapshot(
    itemKey: "iron_pickaxe", damage: 0, enchantments: [], label: nil,
    canonicalDataJSON: "{}"
)
private let gateFB08AssetID = AgentMaterialAssetID(
    rawValue: "asset:gate-f-b08:iron-pickaxe"
)!
private let gateFB08ClaimID = AgentMaterialClaimID(
    rawValue: "claim:gate-f-b08:owner"
)!

private func gateFB08Agent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal * 2, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: ordinal == 0 ? 0.89 : 0,
            fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "Gate F Blocker 08 fixture",
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

private func gateFB08ScaleConfiguration()
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

private func gateFB08EnableScale(
    _ session: inout AgentSimulationSession
) throws {
    try session.initializePopulationScaling(
        additionalSettlements: [AgentPopulationSettlement(
            settlementID: gateFB08EastID,
            anchor: gateFB08East,
            receptionPosition: gateFB08East,
            capacity: 3,
            residentIDs: [],
            inTransitIDs: []
        )],
        configuration: gateFB08ScaleConfiguration()
    )
}

private func gateFB08BaseSession(
    _ simulationID: String
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.001, fatiguePerTick: 0.001,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.9,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 4,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 608, nearbyRadius: 8, resourceObservationRadius: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: (0..<3).map(gateFB08Agent),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 65_536)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: gateFB08Main,
        receptionPosition: gateFB08Main,
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
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)
    try! session.setMortalityEnabled(
        true, configuration: .embodiedLive
    )
    return session
}

private func gateFB08Interaction(
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

private func gateFB08AddUnionAndAsset(
    _ session: inout AgentSimulationSession,
    prefix: String
) {
    let first = gateFB08AgentIDs[0]
    let second = gateFB08AgentIDs[1]
    let household = try! session.currentMembership(of: first)!.householdID
    try! session.moveMembers(memberIDs: [second], to: household)
    let proposal = try! session.proposeUnion(gateFB08Interaction(
        session, id: "\(prefix)-proposal", kind: .unionProposal,
        actorID: first, counterpartyID: second
    ))
    _ = try! session.acceptUnion(
        proposalID: proposal.proposalID,
        receipt: gateFB08Interaction(
            session, id: "\(prefix)-acceptance", kind: .unionAcceptance,
            actorID: second, counterpartyID: first
        )
    )
    let holder = AgentMaterialHolderObservation(
        holder: .agent(first), materialIdentity: gateFB08Identity,
        quantity: 1, custodyFingerprint: "\(prefix)-agent0-tool",
        physicalReceiptID: "\(prefix)-physical-register",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "\(prefix)-rights-register",
        asset: AgentMaterialAssetReference(
            assetID: gateFB08AssetID,
            materialIdentity: gateFB08Identity, quantity: 1
        ),
        observation: holder
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "\(prefix)-owner-claim",
        assetID: gateFB08AssetID, claimID: gateFB08ClaimID,
        claimantID: first, basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "\(prefix)-owner-recognition",
        assetID: gateFB08AssetID, claimID: gateFB08ClaimID,
        recognizingAgentIDs: gateFB08AgentIDs
    ))
}

private func gateFB08FinalizeDeath(
    _ session: inout AgentSimulationSession
) -> (AgentMortalityRecord, AgentEstateRecord) {
    while session.pendingMortalityTransitions().isEmpty {
        _ = try! session.advanceTick()
    }
    let pending = session.pendingMortalityTransitions().first!
    let receipt = "\(session.simulationID.rawValue)-exit-"
        + "\(pending.agentID.rawValue)-t\(session.tick)"
    let rights = session.materialRightsSnapshot().records.filter {
        $0.lastVerifiedHolder.holder == .agent(pending.agentID)
    }
    for record in rights {
        let destination = AgentMaterialHolderObservation(
            holder: .container("0,64,0"),
            materialIdentity: record.asset.materialIdentity,
            quantity: record.asset.quantity,
            custodyFingerprint: "\(receipt)-container",
            physicalReceiptID: receipt, observedAtTick: session.tick
        )
        _ = try! session.applyMaterialRightsOperation(
            .mortalityPhysicalExit(AgentMaterialMortalityExitOutcome(
                operationID: "\(receipt)-\(record.asset.assetID.rawValue)",
                assetID: record.asset.assetID,
                terminalAgentID: pending.agentID,
                sourceObservation: record.lastVerifiedHolder,
                destinationObservation: destination,
                physicalReceiptID: receipt
            ))
        )
    }
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "\(receipt)-custody",
            terminalAgentID: pending.agentID,
            kind: rights.isEmpty ? .verifiedEmpty : .transferred,
            physicalReceiptID: receipt,
            destinationHolderID: rights.isEmpty ? nil : "container:0,64,0",
            stackCount: rights.count,
            itemCount: rights.reduce(0) { $0 + $1.asset.quantity },
            physicalAssets: rights.map {
                AgentMaterialStackSnapshot(
                    identity: $0.asset.materialIdentity,
                    count: $0.asset.quantity
                )
            },
            verifiedAtTick: session.tick
        )
    )
    let death = try! session.finalizePendingMortality(for: pending.agentID)
    return (death, session.estateSnapshot().estates.first {
        $0.deathID == death.deathID
    }!)
}

private func gateFB08ExactRestore(
    _ session: AgentSimulationSession
) -> AgentSimulationSession? {
    do {
        let checkpoint = try session.makeCheckpoint()
        let bytes = try AgentCheckpointCodec.encode(checkpoint)
        let decoded = try AgentCheckpointCodec.decode(
            AgentSessionCheckpoint.self, from: bytes
        )
        let restored = try AgentSimulationSession.restoring(decoded)
        guard try AgentCheckpointCodec.encode(restored.makeCheckpoint())
                == bytes else {
            return nil
        }
        return restored
    } catch {
        return nil
    }
}

private struct GateFB08FreshReport: Codable, Equatable {
    let schemaVersion: Int
    let fixture: String
    let phase: String
    let checkpointSchema: Int
    let observerSchema: Int
    let tick: Int
    let checkpointBytes: Int
    let durableBytes: Int
    let semanticDigest: String
    let estateDigest: String
    let estateCount: Int
    let deathCount: Int
    let successorProofCount: Int
    let replayedEstates: Int
    let replayedDeaths: Int
    let duplicateCurrentAuthority: Int
    let observerMutationCount: Int
    let physicalLossCount: Int
    let physicalDuplicationCount: Int
    let syntheticMaterialCount: Int
    let assertions: [String: Bool]
}

private func gateFB08CurrentAuthorityIsSingular(
    _ session: AgentSimulationSession
) -> Bool {
    let durable = session.durableState()
    guard let population = durable.populationRegistry,
          let scale = population.scaleState else { return false }
    let identityIDs = session.identitySnapshot().agentIDs
    let populationIDs = population.members.map(\.agentID)
    let fidelityIDs = scale.fidelityRecords.map(\.agentID)
    return identityIDs.count == Set(identityIDs).count
        && populationIDs.count == Set(populationIDs).count
        && fidelityIDs.count == Set(fidelityIDs).count
        && Set(identityIDs) == Set(populationIDs)
        && Set(identityIDs) == Set(fidelityIDs)
}

private func gateFB08FreshFixture(
    _ fixture: String
) -> AgentSimulationSession {
    var session = gateFB08BaseSession("gate-f-b08-fresh-\(fixture)")
    if fixture == "nonempty" {
        gateFB08AddUnionAndAsset(
            &session, prefix: "gate-f-b08-fresh-nonempty"
        )
    }
    try! session.setEstatesEnabled(true)
    try! gateFB08EnableScale(&session)
    if fixture == "nonempty" {
        _ = gateFB08FinalizeDeath(&session)
    }
    return session
}

private func gateFB08WriteJSON<T: Encodable>(
    _ value: T, to url: URL
) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [
        .prettyPrinted, .sortedKeys, .withoutEscapingSlashes,
    ]
    try encoder.encode(value).write(to: url, options: .atomic)
}

private func gateFB08FreshProcessIfRequested() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard let phase = environment[
        "PEBBLELAB_GATE_F_BLOCKER_08_FRESH_PHASE"
    ] else { return false }
    guard let fixture = environment[
        "PEBBLELAB_GATE_F_BLOCKER_08_FIXTURE"
    ], ["empty", "nonempty"].contains(fixture),
          let output = environment[
              "PEBBLELAB_GATE_F_BLOCKER_08_OUT"
          ], ["write", "restore"].contains(phase) else {
        preconditionFailure(
            "invalid Gate F Blocker 08 fresh-process environment"
        )
    }
    let root = URL(fileURLWithPath: output, isDirectory: true)
    try! FileManager.default.createDirectory(
        at: root, withIntermediateDirectories: true
    )
    let checkpointURL = root.appendingPathComponent(
        "checkpoint_v35.json"
    )
    let durableURL = root.appendingPathComponent("durable_state.json")
    if phase == "write" {
        let session = gateFB08FreshFixture(fixture)
        let checkpoint = try! session.makeCheckpoint()
        let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
        let durableBytes = try! session.durableStateBytes()
        try! checkpointBytes.write(to: checkpointURL, options: .atomic)
        try! durableBytes.write(to: durableURL, options: .atomic)
        let estates = session.estateSnapshot()
        let mortality = session.mortalitySnapshot()
        let expected = fixture == "nonempty" ? 1 : 0
        let report = GateFB08FreshReport(
            schemaVersion: 1, fixture: fixture,
            phase: "write-checkpoint-exit",
            checkpointSchema: checkpoint.schemaVersion,
            observerSchema: 13, tick: session.tick,
            checkpointBytes: checkpointBytes.count,
            durableBytes: durableBytes.count,
            semanticDigest: checkpoint.semanticDigest.rawValue,
            estateDigest: estates.digest,
            estateCount: estates.totalEstateCount,
            deathCount: mortality.totalDeathCount,
            successorProofCount: estates.estates.compactMap(
                \.successorPlanProof
            ).count,
            replayedEstates: 0, replayedDeaths: 0,
            duplicateCurrentAuthority:
                gateFB08CurrentAuthorityIsSingular(session) ? 0 : 1,
            observerMutationCount: 0,
            physicalLossCount: 0, physicalDuplicationCount: 0,
            syntheticMaterialCount: 0,
            assertions: [
                "checkpoint_schema_35": checkpoint.schemaVersion == 35,
                "estate_count_exact": estates.totalEstateCount == expected,
                "death_count_exact": mortality.totalDeathCount == expected,
                "strict_successor_proof_exact":
                    estates.estates.compactMap(\.successorPlanProof).count
                        == expected,
                "singular_current_authority":
                    gateFB08CurrentAuthorityIsSingular(session),
            ]
        )
        try! gateFB08WriteJSON(
            report, to: root.appendingPathComponent(
                "process_1_report.json"
            )
        )
        check("fresh \(fixture) process 1 writes schema-35 fixture",
              report.assertions.values.allSatisfy { $0 })
        return true
    }

    let checkpointBytes = try! Data(contentsOf: checkpointURL)
    let savedDurableBytes = try! Data(contentsOf: durableURL)
    let checkpoint = try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self, from: checkpointBytes
    )
    var session = try! AgentSimulationSession.restoring(checkpoint)
    let restoredDurableBytes = try! session.durableStateBytes()
    let estatesBefore = session.estateSnapshot()
    let mortalityBefore = session.mortalitySnapshot()
    let observerBytesBefore = try! session.durableStateBytes()
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b08-fresh-world",
            storageIdentity: "memory:gate-f-b08-fresh", seed: 608,
            dimension: 0, observedWorldTick: session.tick
        )
    )
    let observerMutations = (try! session.durableStateBytes())
        == observerBytesBefore ? 0 : 1
    _ = try! session.advanceTick()
    let continued = try! session.makeCheckpoint()
    let replayedEstates = session.estateSnapshot().totalEstateCount
        - estatesBefore.totalEstateCount
    let replayedDeaths = session.mortalitySnapshot().totalDeathCount
        - mortalityBefore.totalDeathCount
    let expected = fixture == "nonempty" ? 1 : 0
    let report = GateFB08FreshReport(
        schemaVersion: 1, fixture: fixture,
        phase: "fresh-restore-continuation",
        checkpointSchema: checkpoint.schemaVersion,
        observerSchema: observer.header.schemaVersion,
        tick: session.tick,
        checkpointBytes: checkpointBytes.count,
        durableBytes: restoredDurableBytes.count,
        semanticDigest: checkpoint.semanticDigest.rawValue,
        estateDigest: estatesBefore.digest,
        estateCount: estatesBefore.totalEstateCount,
        deathCount: mortalityBefore.totalDeathCount,
        successorProofCount: estatesBefore.estates.compactMap(
            \.successorPlanProof
        ).count,
        replayedEstates: replayedEstates,
        replayedDeaths: replayedDeaths,
        duplicateCurrentAuthority:
            gateFB08CurrentAuthorityIsSingular(session) ? 0 : 1,
        observerMutationCount: observerMutations,
        physicalLossCount: 0, physicalDuplicationCount: 0,
        syntheticMaterialCount: 0,
        assertions: [
            "checkpoint_bytes_exact":
                (try? AgentCheckpointCodec.encode(checkpoint))
                    == checkpointBytes,
            "durable_bytes_exact":
                restoredDurableBytes == savedDurableBytes,
            "checkpoint_schema_35": checkpoint.schemaVersion == 35,
            "observer_schema_13": observer.header.schemaVersion == 13,
            "observer_read_only": observerMutations == 0,
            "estate_count_exact": estatesBefore.totalEstateCount == expected,
            "death_count_exact": mortalityBefore.totalDeathCount == expected,
            "strict_successor_proof_exact":
                estatesBefore.estates.compactMap(\.successorPlanProof).count
                    == expected,
            "continuation_schema_35": continued.schemaVersion == 35,
            "zero_replayed_estates": replayedEstates == 0,
            "zero_replayed_deaths": replayedDeaths == 0,
            "singular_current_authority":
                gateFB08CurrentAuthorityIsSingular(session),
        ]
    )
    try! gateFB08WriteJSON(
        report, to: root.appendingPathComponent("process_2_report.json")
    )
    check("fresh \(fixture) process 2 restores and continues exactly",
          report.assertions.values.allSatisfy { $0 })
    return true
}

private func gateFB08RollingDigest(
    _ authority: AgentEstateState
) -> String {
    let estates = authority.estates.sorted {
        $0.estateID < $1.estateID
    }.map { estate in
        let administrations = estate.administrations.map {
            "\($0.administratorID.rawValue):\($0.basis.rawValue):"
                + "\($0.status.rawValue):"
                + "\($0.acceptanceOperationID ?? "none")"
        }.joined(separator: ",")
        let beneficiaries = estate.beneficiaries.map {
            "\($0.agentID.rawValue):\($0.basis.rawValue):"
                + "\($0.allocationCount)"
        }.joined(separator: ",")
        let assets = estate.assets.map {
            let base = "\($0.entryID.rawValue):"
                + "\($0.materialRightsAssetID?.rawValue ?? "none"):"
                + "\($0.quantity):\($0.status.rawValue):"
                + "\($0.blockReason?.rawValue ?? "none"):"
                + "\($0.settlementReceiptID ?? "none")"
            if let eventID = $0.custodyRevalidationEventID {
                return base + ":custody:"
                    + "\($0.custodyRevalidatedAtTick ?? -1):"
                    + eventID.rawValue + ":"
                    + "\($0.intendedCustodianID?.rawValue ?? "none")"
            }
            return base
        }.joined(separator: ",")
        let prefix = "\(estate.estateID.rawValue)|"
            + "\(estate.deathID.rawValue)|\(estate.status.rawValue)|"
        if let proof = estate.successorPlanProof {
            return prefix + "\(proof.version):\(proof.planDigest):"
                + "\(proof.successorPlanEventID.rawValue)|"
                + "\(administrations)|\(beneficiaries)|\(assets)"
        }
        return prefix + "\(administrations)|\(beneficiaries)|\(assets)"
    }.joined(separator: ";")
    let text = "\(authority.activationTick)|"
        + "\(authority.activationDeathCount)|\(authority.totalEstateCount)|"
        + "\(authority.totalSettlementCount)|"
        + "\(authority.evictionCounts.settledEstates)|\(estates)|"
        + "\(authority.processedOperationIDs.joined(separator: ","))"
    return AgentMortalityDigest.make("estate-v1|\(text)")
}

private func gateFB08MutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    if var estateJSON = durable["estateState"] as? [String: Any] {
        let bytes = try! JSONSerialization.data(
            withJSONObject: estateJSON,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let estate = try! AgentCheckpointCodec.decode(
            AgentEstateState.self, from: bytes
        )
        estateJSON["rollingDigest"] = gateFB08RollingDigest(estate)
        durable["estateState"] = estateJSON
    }
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

private func gateFB08RestoreError(
    _ checkpoint: AgentSessionCheckpoint
) -> String? {
    do {
        _ = try AgentSimulationSession.restoring(checkpoint)
        return nil
    } catch {
        return String(describing: error)
    }
}

func runPebbleAgentsGateFBlocker08Smoke() {
    section("Gate F Blocker 08 Estate schema-35 validation composition")
    if gateFB08FreshProcessIfRequested() { return }

    check("Estate schema 27 preserves legacy validation semantics",
          AgentCheckpointSchema.estateValidationSemantics(for: 27)
            == .legacySuccessorPlanRevalidation)
    check("Estate schemas 28 through 35 use strict validation semantics",
          (28...35).allSatisfy {
              AgentCheckpointSchema.estateValidationSemantics(for: $0)
                == .strictDurableSuccessorPlan
          })
    check("unsupported future Estate schema remains rejected",
          AgentCheckpointSchema.estateValidationSemantics(for: 36) == nil
            && !AgentCheckpointSchema.supports(36))

    var estateOnly = gateFB08BaseSession("gate-f-b08-estate-only")
    try! estateOnly.setEstatesEnabled(true)
    let estateOnlyCheckpoint = try! estateOnly.makeCheckpoint()
    let estateOnlyDigest = estateOnlyCheckpoint.semanticDigest.rawValue
    let estateOnlyRestored = gateFB08ExactRestore(estateOnly)
    check("Evaluation 08 Estate-only control emits schema 28",
          estateOnlyCheckpoint.schemaVersion == 28)
    check("Evaluation 08 Estate-only schema-28 control restores byte-exactly",
          estateOnlyRestored != nil)

    var estateFirst = gateFB08BaseSession("gate-f-b08-estate-first")
    try! estateFirst.setEstatesEnabled(true)
    let estateBeforeScale = estateFirst.estateSnapshot()
    try! gateFB08EnableScale(&estateFirst)
    let estateFirstCheckpoint = try! estateFirst.makeCheckpoint()
    let estateScaleDigest = estateFirstCheckpoint.semanticDigest.rawValue
    check("Estate-first scale-second live composition preserves Estate authority",
          estateFirst.estateSnapshot() == estateBeforeScale)
    check("Estate-first scale-second emits effective schema 35",
          estateFirstCheckpoint.schemaVersion == 35)
    check("Evaluation 08 Estate-plus-scale schema-35 trajectory restores exactly",
          gateFB08ExactRestore(estateFirst) != nil)
    print("  Gate F Blocker 08 deterministic digests:"
        + " control=\(estateOnlyDigest)"
        + " estate_scale=\(estateScaleDigest)")
    let authority = estateFirst.durableState()
    let authorityIDs = Set(estateFirst.identitySnapshot().agentIDs)
    let populationIDs = Set(
        authority.populationRegistry!.members.map(\.agentID)
    )
    let fidelityIDs = Set(
        authority.populationRegistry!.scaleState!.fidelityRecords.map(\.agentID)
    )
    check("schema-35 current population and fidelity authority is singular",
          authorityIDs == populationIDs
            && authorityIDs == fidelityIDs
            && authorityIDs.count == 3)
    let observerBytesBefore = try! estateFirst.durableStateBytes()
    let observer = estateFirst.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "gate-f-b08-world",
            storageIdentity: "memory:gate-f-b08", seed: 608,
            dimension: 0, observedWorldTick: estateFirst.tick
        )
    )
    check("schema-35 Observer remains schema 13 and read-only",
          observer.header.schemaVersion == 13
            && (try! estateFirst.durableStateBytes())
                == observerBytesBefore)

    var scaleFirst = gateFB08BaseSession("gate-f-b08-scale-first")
    try! gateFB08EnableScale(&scaleFirst)
    let durableBeforeEstate = try! scaleFirst.durableStateBytes()
    try! scaleFirst.setEstatesEnabled(true)
    check("scale-first Estate-second live composition is supported",
          scaleFirst.estateSnapshot().enabled
            && (try! scaleFirst.makeCheckpoint()).schemaVersion == 35)
    check("scale-first Estate-second preserves pre-existing authority",
          scaleFirst.durableState().populationRegistry?.scaleState != nil
            && (try! scaleFirst.durableStateBytes()) != durableBeforeEstate)
    check("scale-first Estate-second schema-35 checkpoint restores exactly",
          gateFB08ExactRestore(scaleFirst) != nil)

    var nonEmpty = gateFB08BaseSession("gate-f-b08-nonempty")
    gateFB08AddUnionAndAsset(&nonEmpty, prefix: "gate-f-b08-nonempty")
    try! gateFB08EnableScale(&nonEmpty)
    try! nonEmpty.setEstatesEnabled(true)
    let (death, estate) = gateFB08FinalizeDeath(&nonEmpty)
    let nonEmptyCheckpoint = try! nonEmpty.makeCheckpoint()
    let nonEmptyRestored = gateFB08ExactRestore(nonEmpty)
    check("schema-35 non-empty Estate opens exactly once",
          nonEmptyCheckpoint.schemaVersion == 35
            && nonEmpty.estateSnapshot().totalEstateCount == 1
            && nonEmpty.mortalitySnapshot().totalDeathCount == 1
            && estate.deathID == death.deathID
            && estate.successorPlanProof != nil)
    check("schema-35 non-empty Estate beneficiary list is exact",
          estate.beneficiaries.map(\.agentID) == [gateFB08AgentIDs[1]])
    check("schema-35 non-empty Estate restores exact authority",
          nonEmptyRestored?.estateSnapshot() == nonEmpty.estateSnapshot()
            && nonEmptyRestored?.mortalitySnapshot()
                == nonEmpty.mortalitySnapshot())
    if var continued = nonEmptyRestored {
        _ = try! continued.advanceTick()
        check("post-restore continuation does not replay death or Estate effects",
              continued.estateSnapshot().totalEstateCount == 1
                && continued.mortalitySnapshot().totalDeathCount == 1
                && continued.estateSnapshot().estates.count == 1)
    } else {
        check("post-restore continuation does not replay death or Estate effects",
              false)
    }

    let malformedMissingProof = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        estates[0].removeValue(forKey: "successorPlanProof")
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("schema 35 rejects missing strict successor-plan proof",
          gateFB08RestoreError(malformedMissingProof)?.contains(
              "successor plan proof"
          ) == true)

    let malformedProofIdentity = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        proof["estateID"] = "estate-gate-f-b08-wrong"
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("schema 35 rejects malformed successor-plan identity",
          gateFB08RestoreError(malformedProofIdentity) != nil)

    let malformedDeathLink = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        var proof = estates[0]["successorPlanProof"] as! [String: Any]
        proof["deathID"] = "death-gate-f-b08-wrong"
        estates[0]["successorPlanProof"] = proof
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("schema 35 rejects wrong successor-plan death linkage",
          gateFB08RestoreError(malformedDeathLink) != nil)

    let malformedBeneficiaries = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        estates[0]["beneficiaries"] = []
        authority["estates"] = estates
        durable["estateState"] = authority
    }
    check("schema 35 rejects wrong beneficiary list",
          gateFB08RestoreError(malformedBeneficiaries) != nil)

    let duplicateEstate = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var authority = durable["estateState"] as! [String: Any]
        var estates = authority["estates"] as! [[String: Any]]
        estates.append(estates[0])
        authority["estates"] = estates
        authority["totalEstateCount"] = 2
        durable["estateState"] = authority
    }
    check("schema 35 rejects duplicate Estate identity",
          gateFB08RestoreError(duplicateEstate) != nil)

    let malformedMortalityHistory = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        var mortality = durable["mortalityState"] as! [String: Any]
        mortality["historicalEvidenceVersion"] = 0
        durable["mortalityState"] = mortality
    }
    check("schema 35 rejects malformed mortality historical evidence",
          gateFB08RestoreError(malformedMortalityHistory) != nil)

    let unsupportedFuture = gateFB08MutatedCheckpoint(
        nonEmptyCheckpoint
    ) { durable in
        durable["schemaVersion"] = 36
    }
    check("full checkpoint restore rejects unsupported future schema",
          gateFB08RestoreError(unsupportedFuture) != nil)

    var legacySource = gateFB08BaseSession("gate-f-b08-legacy-source")
    gateFB08AddUnionAndAsset(
        &legacySource, prefix: "gate-f-b08-legacy-source"
    )
    try! legacySource.setEstatesEnabled(true)
    _ = gateFB08FinalizeDeath(&legacySource)
    let legacyCheckpoint = estateSchema27Checkpoint(
        try! legacySource.makeCheckpoint(), preserveExactCausalProof: true
    )
    let legacyError = gateFB08RestoreError(legacyCheckpoint)
    let legacy = try? AgentSimulationSession.restoring(legacyCheckpoint)
    check("schema-27 checkpoint preserves intended legacy Estate restore"
            + " (\(legacyError ?? "none"))",
          legacyCheckpoint.schemaVersion == 27 && legacy != nil)
    if var legacyPromotion = legacy {
        let before = try! legacyPromotion.durableStateBytes()
        let estateBefore = legacyPromotion.estateSnapshot()
        let refused: Bool
        let refusalDetail: String
        do {
            try gateFB08EnableScale(&legacyPromotion)
            refused = false
            refusalDetail = "none"
        } catch AgentSessionError.estate(.invalidState(
            "strict schema requires successor plan proof"
        )) {
            refused = true
            refusalDetail = "successor plan proof"
        } catch {
            refused = true
            refusalDetail = String(describing: error)
        }
        check("legacy Estate promotion to effective schema 35 is refused"
                + " (\(refusalDetail))", refused)
        check("failed scale promotion is byte-exactly atomic",
              (try! legacyPromotion.durableStateBytes()) == before
                && legacyPromotion.estateSnapshot() == estateBefore
                && legacyPromotion.durableState().populationRegistry?
                    .scaleState == nil)
    } else {
        check("legacy Estate promotion to effective schema 35 is refused",
              false)
        check("failed scale promotion is byte-exactly atomic", false)
    }

    var scaleActivationRefusal = gateFB08BaseSession(
        "gate-f-b08-estate-activation-refusal"
    )
    try! gateFB08EnableScale(&scaleActivationRefusal)
    let beforeActivationRefusal = try! scaleActivationRefusal
        .durableStateBytes()
    let invalidConfiguration = try! AgentEstateConfiguration(
        maximumRetainedEstates: 33,
        maximumOpenEstates: 32,
        maximumAssetsPerEstate: 16,
        maximumObligationsPerEstate: 16,
        maximumBeneficiariesPerEstate: 32,
        maximumAdministrationsPerEstate: 16,
        maximumSettlementAttemptsPerAsset: 16,
        maximumProcessedOperationIDs: 512,
        maximumTransitionsPerTick: 128
    )
    let activationRefused: Bool
    do {
        try scaleActivationRefusal.setEstatesEnabled(
            true, configuration: invalidConfiguration
        )
        activationRefused = false
    } catch AgentSessionError.estate(.invalidConfiguration) {
        activationRefused = true
    } catch {
        activationRefused = false
    }
    check("Estate activation refusal after scale is byte-exactly atomic",
          activationRefused
            && (try! scaleActivationRefusal.durableStateBytes())
                == beforeActivationRefusal
            && !scaleActivationRefusal.estatesEnabled)
}
