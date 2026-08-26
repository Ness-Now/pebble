import Foundation
import PebbleAgents

private let estateAgentIDs = (0..<3).map {
    AgentID(rawValue: "agent_\($0)")!
}

private func estateAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: ordinal == 0 ? 0.89 : 0,
            fatigue: 0, curiosity: 0.1, safety: 1
        ),
        health: 100, fear: 0, homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-33 estate fixture",
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

private let estateHabitat = AgentEcologyHabitatObservation(
    worldTick: 0, candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 33_033, distanceFromSettlement: 1,
    directionIndex: 0, worldReadCount: 4
)

private let estateIdentity = AgentMaterialIdentitySnapshot(
    itemKey: "iron_pickaxe", damage: 0, enchantments: [],
    label: nil, canonicalDataJSON: "{}"
)

private let estateAssetID =
    AgentMaterialAssetID(rawValue: "asset:civ33:iron_pickaxe:1")!
private let estateOwnerClaimID =
    AgentMaterialClaimID(rawValue: "claim:civ33:owner:agent_0")!
private let estateSecondIdentity = AgentMaterialIdentitySnapshot(
    itemKey: "iron_shovel", damage: 0, enchantments: [],
    label: nil, canonicalDataJSON: "{}"
)
private let estateSecondAssetID =
    AgentMaterialAssetID(rawValue: "asset:civ33:iron_shovel:2")!
private let estateSecondOwnerClaimID =
    AgentMaterialClaimID(rawValue: "claim:civ33:owner:agent_0:second")!

private func estateInteraction(
    _ session: AgentSimulationSession,
    id: String,
    kind: AgentFamilyInteractionKind,
    actor: AgentID,
    counterparty: AgentID
) -> AgentFamilyInteractionReceipt {
    let agents = Dictionary(uniqueKeysWithValues:
        session.snapshot().agents.map {
            (AgentID(rawValue: $0.id)!, $0)
        }
    )
    return AgentFamilyInteractionReceipt(
        receiptID: id, kind: kind,
        actorID: actor, counterpartyID: counterparty,
        observedTick: session.tick,
        actorPosition: agents[actor]!.position,
        counterpartyPosition: agents[counterparty]!.position,
        communicationVerified: true
    )
}

private func makeEstateSession(
    _ simulationID: String,
    includeUnionAndChild: Bool = true,
    registerAsset: Bool = true,
    thirdPartyClaim: Bool = false,
    enableEstates: Bool = true,
    mortalityConfiguration: AgentMortalityConfiguration = .embodiedLive,
    estateConfiguration: AgentEstateConfiguration = .live
) -> (AgentSimulationSession, AgentBirthRecord?) {
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
            seed: 33, nearbyRadius: 8, resourceObservationRadius: 8,
            memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival
        ),
        agents: [0, 1, 2].map(estateAgent),
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 32_768)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.initializeLocalEcology(observations: [estateHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(
        habitatValidations: [estateHabitat]
    )
    try! session.setLifecycleEnabled(
        true,
        configuration: try! AgentLifecycleConfiguration(
            newbornDurationTicks: 1, maturityAgeTicks: 20,
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
    try! session.setDependentCareEnabled(true)
    try! session.setChildhoodV2Enabled(true)
    try! session.setFamilyV1Enabled(true)
    try! session.setMaterialRightsEnabled(true)

    var birth: AgentBirthRecord?
    if includeUnionAndChild {
        let sharedHousehold = try! session.currentMembership(
            of: estateAgentIDs[0]
        )!.householdID
        try! session.moveMembers(
            memberIDs: [estateAgentIDs[1]], to: sharedHousehold
        )
        let proposal = try! session.proposeUnion(estateInteraction(
            session, id: "\(simulationID)-union-proposal",
            kind: .unionProposal, actor: estateAgentIDs[0],
            counterparty: estateAgentIDs[1]
        ))
        _ = try! session.acceptUnion(
            proposalID: proposal.proposalID,
            receipt: estateInteraction(
                session, id: "\(simulationID)-union-acceptance",
                kind: .unionAcceptance, actor: estateAgentIDs[1],
                counterparty: estateAgentIDs[0]
            )
        )
        try! session.setReproductionEnabled(true)
        while session.pendingBirthSitePlan() == nil {
            _ = try! session.advanceTick()
        }
        let plan = session.pendingBirthSitePlan()!
        while session.tick < plan.dueTick {
            _ = try! session.advanceTick()
        }
        birth = try! session.applyBirthSiteObservation(
            AgentBirthSiteObservation(
                planID: plan.planID, observedTick: session.tick,
                position: AgentPosition(x: 0, y: 64, z: 4),
                candidateIndex: 0, worldFingerprint: 33_001
            )
        )
    }

    if registerAsset {
        let observation = AgentMaterialHolderObservation(
            holder: .agent(estateAgentIDs[0]),
            materialIdentity: estateIdentity, quantity: 1,
            custodyFingerprint: "\(simulationID):agent0:pickaxe",
            physicalReceiptID: "\(simulationID):physical-register",
            observedAtTick: session.tick
        )
        _ = try! session.applyMaterialRightsOperation(.register(
            operationID: "\(simulationID):rights-register",
            asset: AgentMaterialAssetReference(
                assetID: estateAssetID,
                materialIdentity: estateIdentity, quantity: 1
            ),
            observation: observation
        ))
        _ = try! session.applyMaterialRightsOperation(.assertClaim(
            operationID: "\(simulationID):owner-claim",
            assetID: estateAssetID, claimID: estateOwnerClaimID,
            claimantID: estateAgentIDs[0], basis: .produced
        ))
        _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
            operationID: "\(simulationID):owner-recognition",
            assetID: estateAssetID, claimID: estateOwnerClaimID,
            recognizingAgentIDs: estateAgentIDs
        ))
        _ = try! session.applyMaterialRightsOperation(.grantUse(
            operationID: "\(simulationID):retained-permission",
            assetID: estateAssetID,
            permissionID: AgentMaterialPermissionID(
                rawValue: "permission:civ33:agent_2"
            )!,
            grantorID: estateAgentIDs[0], userID: estateAgentIDs[2],
            allowedUses: [.toolUse], expiresAtTick: nil
        ))
        if thirdPartyClaim {
            _ = try! session.applyMaterialRightsOperation(.assertClaim(
                operationID: "\(simulationID):third-party-claim",
                assetID: estateAssetID,
                claimID: AgentMaterialClaimID(
                    rawValue: "claim:civ33:third-party"
                )!,
                claimantID: estateAgentIDs[2], basis: .contested
            ))
        }
    }
    try! session.setMortalityEnabled(
        true, configuration: mortalityConfiguration
    )
    if enableEstates {
        try! session.setEstatesEnabled(
            true, configuration: estateConfiguration
        )
    }
    return (session, birth)
}

@discardableResult
private func finalizeEstatePhysicalDeath(
    _ session: inout AgentSimulationSession,
    physicalAssets: [AgentMaterialStackSnapshot]
) -> AgentMortalityRecord {
    while session.pendingMortalityTransitions().isEmpty {
        _ = try! session.advanceTick()
    }
    let pending = session.pendingMortalityTransitions().first!
    let receipt = "\(session.simulationID.rawValue):mortality-exit:"
        + "\(pending.agentID.rawValue):t\(session.tick)"
    let exitingRecords = session.materialRightsSnapshot().records.filter {
        $0.lastVerifiedHolder.holder == .agent(pending.agentID)
    }.sorted { $0.asset.assetID < $1.asset.assetID }
    for record in exitingRecords {
        let destination = AgentMaterialHolderObservation(
            holder: .container("0,64,0"),
            materialIdentity: record.asset.materialIdentity,
            quantity: record.asset.quantity,
            custodyFingerprint:
                "\(session.simulationID.rawValue):container:after-exit",
            physicalReceiptID: receipt, observedAtTick: session.tick
        )
        _ = try! session.applyMaterialRightsOperation(
            .mortalityPhysicalExit(AgentMaterialMortalityExitOutcome(
                operationID: "\(receipt):\(record.asset.assetID.rawValue)",
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
            operationID: "\(receipt):custody",
            terminalAgentID: pending.agentID,
            kind: physicalAssets.isEmpty ? .verifiedEmpty : .transferred,
            physicalReceiptID: receipt,
            destinationHolderID:
                physicalAssets.isEmpty ? nil : "container:0,64,0",
            stackCount: physicalAssets.count,
            itemCount: physicalAssets.reduce(0) { $0 + $1.count },
            physicalAssets: physicalAssets,
            verifiedAtTick: session.tick
        )
    )
    return try! session.finalizePendingMortality(for: pending.agentID)
}

private func finalizeEstateDeath(
    _ session: inout AgentSimulationSession,
    physicalAssets: [AgentMaterialStackSnapshot]
) -> AgentEstateRecord {
    let death = finalizeEstatePhysicalDeath(
        &session, physicalAssets: physicalAssets
    )
    return session.estateSnapshot().estates.first {
        $0.deathID == death.deathID
    }!
}

private func finalizeEmptyEstateDeathRefused(
    _ session: inout AgentSimulationSession
) -> Bool {
    while session.pendingMortalityTransitions().isEmpty {
        _ = try! session.advanceTick()
    }
    let pending = session.pendingMortalityTransitions().first!
    let receipt = "\(session.simulationID.rawValue):retention:"
        + "\(pending.agentID.rawValue):t\(session.tick)"
    _ = try! session.applyMortalityPhysicalCustodyOutcome(
        AgentMortalityPhysicalCustodyOutcome(
            operationID: "\(receipt):custody",
            terminalAgentID: pending.agentID,
            kind: .verifiedEmpty,
            physicalReceiptID: receipt,
            destinationHolderID: nil,
            stackCount: 0,
            itemCount: 0,
            physicalAssets: [],
            verifiedAtTick: session.tick
        )
    )
    let before = try! session.durableStateBytes()
    do {
        _ = try session.finalizePendingMortality(for: pending.agentID)
        return false
    } catch {
        return (try! session.durableStateBytes()) == before
            && session.pendingMortalityTransitions().contains {
                $0.agentID == pending.agentID
            }
    }
}

private func registerEstateAsset(
    _ session: inout AgentSimulationSession,
    assetID: AgentMaterialAssetID,
    claimID: AgentMaterialClaimID,
    identity: AgentMaterialIdentitySnapshot,
    ownerID: AgentID = estateAgentIDs[0],
    holderID: AgentID = estateAgentIDs[0],
    recognizingAgentIDs: [AgentID] = estateAgentIDs,
    operationPrefix: String
) {
    let observation = AgentMaterialHolderObservation(
        holder: .agent(holderID), materialIdentity: identity, quantity: 1,
        custodyFingerprint: "\(operationPrefix):holder",
        physicalReceiptID: "\(operationPrefix):physical-register",
        observedAtTick: session.tick
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "\(operationPrefix):register",
        asset: AgentMaterialAssetReference(
            assetID: assetID, materialIdentity: identity, quantity: 1
        ),
        observation: observation
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "\(operationPrefix):claim",
        assetID: assetID, claimID: claimID,
        claimantID: ownerID, basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "\(operationPrefix):recognize",
        assetID: assetID, claimID: claimID,
        recognizingAgentIDs: recognizingAgentIDs
    ))
}

private func createEstateSiblingBirth(
    _ session: inout AgentSimulationSession
) -> AgentBirthRecord {
    while session.pendingBirthSitePlan() == nil {
        _ = try! session.advanceTick()
    }
    let plan = session.pendingBirthSitePlan()!
    while session.tick < plan.dueTick {
        _ = try! session.advanceTick()
    }
    return try! session.applyBirthSiteObservation(
        AgentBirthSiteObservation(
            planID: plan.planID, observedTick: session.tick,
            position: AgentPosition(x: 1, y: 64, z: 4),
            candidateIndex: 1, worldFingerprint: 33_002
        )
    )!
}

private func estateSessionPreparingLethalAgent(
    _ session: AgentSimulationSession,
    targetID: AgentID
) -> AgentSimulationSession {
    let checkpoint = try! session.makeCheckpoint()
    let mutated = estateMutatedCheckpoint(checkpoint) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        for index in agents.indices {
            var needs = agents[index]["needs"] as! [String: Any]
            var progress = agents[index]["survivalProgress"]
                as? [String: Any] ?? [
                    "status": AgentSurvivalStatus.stable.rawValue,
                    "consecutiveCriticalHungerTicks": 0,
                    "foodConsumedCount": 0,
                    "restTicks": 0,
                    "starvationDamageTaken": 0,
                ]
            let encodedID = (agents[index]["agentID"] as? String)
                ?? ((agents[index]["agentID"] as? [String: Any])?[
                    "rawValue"
                ] as? String)
                ?? ""
            if encodedID == targetID.rawValue {
                needs["hunger"] = 1.0
                agents[index]["health"] = 100
                progress["status"] = AgentSurvivalStatus.starving.rawValue
                progress["consecutiveCriticalHungerTicks"] = 4
                progress["starvationDamageTaken"] = 0
            } else {
                needs["hunger"] = 0.0
                progress["status"] = AgentSurvivalStatus.stable.rawValue
                progress["consecutiveCriticalHungerTicks"] = 0
            }
            agents[index]["needs"] = needs
            agents[index]["survivalProgress"] = progress
        }
        durable["agents"] = agents
    }
    return try! AgentSimulationSession.restoring(mutated)
}

private func estateSessionWithHealth(
    _ session: AgentSimulationSession,
    agentID: AgentID,
    health: Int
) -> AgentSimulationSession {
    let checkpoint = try! session.makeCheckpoint()
    let mutated = estateMutatedCheckpoint(checkpoint) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        for index in agents.indices {
            let encodedID = (agents[index]["agentID"] as? String)
                ?? ((agents[index]["agentID"] as? [String: Any])?[
                    "rawValue"
                ] as? String)
                ?? ""
            if encodedID == agentID.rawValue {
                agents[index]["health"] = health
            }
        }
        durable["agents"] = agents
    }
    return try! AgentSimulationSession.restoring(mutated)
}

private func estateSessionWithStableNeeds(
    _ session: AgentSimulationSession
) -> AgentSimulationSession {
    let checkpoint = try! session.makeCheckpoint()
    let mutated = estateMutatedCheckpoint(checkpoint) { durable in
        var agents = durable["agents"] as! [[String: Any]]
        for index in agents.indices {
            var needs = agents[index]["needs"] as! [String: Any]
            needs["hunger"] = 0.0
            agents[index]["needs"] = needs
            var progress = agents[index]["survivalProgress"]
                as? [String: Any] ?? [
                    "status": AgentSurvivalStatus.stable.rawValue,
                    "consecutiveCriticalHungerTicks": 0,
                    "foodConsumedCount": 0,
                    "restTicks": 0,
                    "starvationDamageTaken": 0,
                ]
            progress["status"] = AgentSurvivalStatus.stable.rawValue
            progress["consecutiveCriticalHungerTicks"] = 0
            progress["starvationDamageTaken"] = 0
            agents[index]["survivalProgress"] = progress
        }
        durable["agents"] = agents
    }
    return try! AgentSimulationSession.restoring(mutated)
}

private func estateSettlementOutcome(
    session: AgentSimulationSession,
    estate: AgentEstateRecord,
    entry: AgentEstateAssetEntry,
    operationID: String,
    sourceFingerprintAfterTransfer: String,
    destinationFingerprintBeforeTransfer: String,
    destinationFingerprintAfterTransfer: String
) -> AgentEstatePhysicalSettlementOutcome {
    let source = session.materialRightsSnapshot().records.first {
        $0.asset.assetID == entry.materialRightsAssetID
    }!.lastVerifiedHolder
    let custodian = entry.intendedCustodianID!
    let administratorID = session.estateSnapshot().estates.first {
        $0.estateID == estate.estateID
    }!.administrations.last {
        $0.status == .active
    }!.administratorID
    return AgentEstatePhysicalSettlementOutcome(
        operationID: operationID,
        estateID: estate.estateID, entryID: entry.entryID,
        administratorID: administratorID,
        beneficiaryID: entry.assignedBeneficiaryID!,
        intendedCustodianID: custodian,
        sourceObservation: source,
        destinationObservation: AgentMaterialHolderObservation(
            holder: .agent(custodian),
            materialIdentity: entry.materialIdentity,
            quantity: entry.quantity,
            custodyFingerprint: destinationFingerprintAfterTransfer,
            physicalReceiptID: operationID,
            observedAtTick: session.tick
        ),
        sourceFingerprintAfterTransfer: sourceFingerprintAfterTransfer,
        destinationFingerprintBeforeTransfer:
            destinationFingerprintBeforeTransfer,
        physicalReceiptID: operationID
    )
}

private func estateMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    if var estateJSON = durable["estateState"] as? [String: Any] {
        let estateBytes = try! JSONSerialization.data(
            withJSONObject: estateJSON,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        let estate = try! AgentCheckpointCodec.decode(
            AgentEstateState.self, from: estateBytes
        )
        estateJSON["rollingDigest"] = estateTestRollingDigest(estate)
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

private func estateTestRollingDigest(
    _ authority: AgentEstateState
) -> String {
    let estates = authority.estates.sorted {
        $0.estateID < $1.estateID
    }.map { estate in
        let admins = estate.administrations.map {
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
                + "\(proof.successorPlanEventID.rawValue)|\(admins)|"
                + "\(beneficiaries)|\(assets)"
        }
        return prefix + "\(admins)|\(beneficiaries)|\(assets)"
    }.joined(separator: ";")
    let text = "\(authority.activationTick)|"
        + "\(authority.activationDeathCount)|\(authority.totalEstateCount)|"
        + "\(authority.totalSettlementCount)|"
        + "\(authority.evictionCounts.settledEstates)|\(estates)|"
        + "\(authority.processedOperationIDs.joined(separator: ","))"
    return AgentMortalityDigest.make("estate-v1|\(text)")
}

private func estateCausalDigest(_ text: String) -> String {
    var value: UInt64 = 14_695_981_039_346_656_037
    for byte in text.utf8 {
        value ^= UInt64(byte)
        value &*= 1_099_511_628_211
    }
    let digits = String(value, radix: 16, uppercase: false)
    return String(repeating: "0", count: max(0, 16 - digits.count))
        + digits
}

private func estateEventIDText(_ value: [String: Any]) -> String {
    let simulationID = value["simulationID"] as! String
    let sequence = value["sequence"] as! UInt64
    let digits = String(sequence)
    return "\(simulationID)/event-"
        + String(repeating: "0", count: max(0, 20 - digits.count))
        + digits
}

private func estateRepairOperationEventDigest(
    _ event: inout [String: Any]
) {
    let eventID = estateEventIDText(
        event["eventID"] as! [String: Any]
    )
    let instant = event["instant"] as! [String: Any]
    let causes = (event["causes"] as! [[String: Any]])
        .map(estateEventIDText).joined(separator: ",")
    let payload = event["payload"] as! [String: Any]
    let operation = payload["operation"] as! [String: Any]
    let payloadText =
        "operation|\(operation["status"] as! String)|"
            + "\(operation["detail"] as! String)"
    let text = "\(eventID)|\(instant["tick"] as! Int)|"
        + "\(event["kind"] as! String)|\(event["origin"] as! String)|"
        + "\(event["actorID"] as? String ?? "-")|"
        + "\(event["subjectID"] as? String ?? "-")|"
        + "\(event["operationID"] as? String ?? "-")|"
        + "\(causes)|\(payloadText)|\(event["summary"] as! String)"
    event["digest"] = estateCausalDigest(text)
}

private func estateRecomputeCausalRollingDigest(
    _ durable: inout [String: Any]
) {
    var ledger = durable["causalLedger"] as! [String: Any]
    let events = ledger["events"] as! [[String: Any]]
    var rolling = estateCausalDigest("")
    for event in events {
        rolling = estateCausalDigest(
            "\(rolling)|\(event["digest"] as! String)"
        )
    }
    ledger["rollingDigest"] = rolling
    durable["causalLedger"] = ledger
}

/// Re-signs every integrity layer affected by a deliberate successor-plan
/// mutation. Restore must still reject the result on independent semantics.
private func estateResignSuccessorPlan(
    _ durable: inout [String: Any], estateIndex: Int
) {
    var authority = durable["estateState"] as! [String: Any]
    var estates = authority["estates"] as! [[String: Any]]
    var estate = estates[estateIndex]
    var proof = estate["successorPlanProof"] as! [String: Any]
    let version = proof["version"] as! Int
    let rows = proof["eligibilityRows"] as! [[String: Any]]
    let rowsText = rows.map {
        "\($0["agentID"] as! String):\($0["tier"] as! String):"
            + "\($0["basis"] as! String):"
            + "\(($0["eligibleAtDeath"] as! Bool) ? 1 : 0):"
            + "\($0["lifeStageAtPlan"] as? String ?? "none"):"
            + "\($0["guardianIDAtPlan"] as? String ?? "none")"
    }.joined(separator: ",")
    let unionText: String
    if let union = proof["activeUnionAtDeath"] as? [String: Any] {
        unionText = "\(union["unionID"] as! String):"
            + "\(union["partnerID"] as! String):"
            + "\(union["activationTick"] as! Int):"
            + estateEventIDText(
                union["activationEventID"] as! [String: Any]
            )
    } else {
        unionText = "none"
    }
    let planText = "successor-plan-v\(version)|"
        + "\(proof["estateID"] as! String)|"
        + "\(proof["decedentID"] as! String)|"
        + "\(proof["deathID"] as! String)|"
        + "\(proof["deathBoundaryTick"] as! Int)|"
        + "\(proof["selectedTier"] as! String)|"
        + "\(rowsText)|\(unionText)"
    let planDigest = AgentMortalityDigest.make(
        "estate-v1|\(planText)"
    )
    proof["planDigest"] = planDigest
    estate["successorPlanProof"] = proof
    estates[estateIndex] = estate
    authority["estates"] = estates
    durable["estateState"] = authority

    let planEventID = estateEventIDText(
        proof["successorPlanEventID"] as! [String: Any]
    )
    var ledger = durable["causalLedger"] as! [String: Any]
    var events = ledger["events"] as! [[String: Any]]
    let eventIndex = events.firstIndex {
        estateEventIDText($0["eventID"] as! [String: Any])
            == planEventID
    }!
    var payload = events[eventIndex]["payload"] as! [String: Any]
    var operation = payload["operation"] as! [String: Any]
    operation["status"] = proof["selectedTier"] as! String
    operation["detail"] = "\(proof["estateID"] as! String)|"
        + ((estate["beneficiaries"] as! [[String: Any]]).map {
            $0["agentID"] as! String
        }.joined(separator: ","))
        + "|\(planDigest)"
    payload["operation"] = operation
    events[eventIndex]["payload"] = payload
    estateRepairOperationEventDigest(&events[eventIndex])
    ledger["events"] = events
    durable["causalLedger"] = ledger
    estateRecomputeCausalRollingDigest(&durable)
}

private func estateRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            estateMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

func estateSchema27Checkpoint(
    _ checkpoint: AgentSessionCheckpoint,
    preserveExactCausalProof: Bool
) -> AgentSessionCheckpoint {
    estateMutatedCheckpoint(checkpoint) { durable in
        durable["schemaVersion"] = AgentCheckpointSchema.legacyEstateVersion
        if var mortality = durable["mortalityState"]
            as? [String: Any] {
            mortality.removeValue(forKey: "historicalEvidenceVersion")
            mortality.removeValue(forKey: "compactedDeathSummaries")
            durable["mortalityState"] = mortality
        }
        var state = durable["estateState"] as! [String: Any]
        var estates = state["estates"] as! [[String: Any]]
        for index in estates.indices {
            estates[index].removeValue(forKey: "successorPlanProof")
        }
        state["estates"] = estates
        durable["estateState"] = state
        guard preserveExactCausalProof else { return }

        var ledger = durable["causalLedger"] as! [String: Any]
        var events = ledger["events"] as! [[String: Any]]
        for estate in estates {
            let planEventID = estateEventIDText(
                estate["successorPlanEventID"] as! [String: Any]
            )
            guard let eventIndex = events.firstIndex(where: {
                estateEventIDText(
                    $0["eventID"] as! [String: Any]
                ) == planEventID
            }) else {
                continue
            }
            events[eventIndex]["causes"] = [
                estate["openingEventID"] as! [String: Any],
            ]
            var payload = events[eventIndex]["payload"] as! [String: Any]
            var operation = payload["operation"] as! [String: Any]
            operation["detail"] = (estate["beneficiaries"]
                as! [[String: Any]]).map {
                    $0["agentID"] as! String
                }.joined(separator: ",")
            payload["operation"] = operation
            events[eventIndex]["payload"] = payload
            estateRepairOperationEventDigest(&events[eventIndex])
        }
        ledger["events"] = events
        durable["causalLedger"] = ledger
        estateRecomputeCausalRollingDigest(&durable)
    }
}

private func estateHistoricalMortalityConfiguration(
    retainedRecords: Int,
    compactedSummaries: Int = 8
) -> AgentMortalityConfiguration {
    try! AgentMortalityConfiguration(
        maximumDeathsPerTick: 1,
        maximumRetainedDeathRecords: retainedRecords,
        maximumCompactedDeathSummaries: compactedSummaries,
        maximumFinalMemoryEntries: 2,
        maximumCancelledCommitmentIDsPerDeath: 8,
        maximumExitFrames: 8,
        maximumMaterialExitsPerDeath: 4,
        requiresTerminalPhysicalCustodyVerification: true
    )
}

private func estateHistoricalEstateConfiguration(
    retainedEstates: Int
) -> AgentEstateConfiguration {
    try! AgentEstateConfiguration(
        maximumRetainedEstates: retainedEstates,
        maximumOpenEstates: retainedEstates,
        maximumAssetsPerEstate: 4,
        maximumObligationsPerEstate: 4,
        maximumBeneficiariesPerEstate: 8,
        maximumAdministrationsPerEstate: 4,
        maximumSettlementAttemptsPerAsset: 4,
        maximumProcessedOperationIDs: 64,
        maximumTransitionsPerTick: 64
    )
}

private func estateFinalizeSpecificEmptyDeath(
    _ session: inout AgentSimulationSession,
    agentID: AgentID
) -> AgentEstateRecord {
    session = estateSessionPreparingLethalAgent(
        session, targetID: agentID
    )
    return finalizeEstateDeath(&session, physicalAssets: [])
}

private func estateParentHistoryFixture(
    _ simulationID: String,
    compactParentDeath: Bool
) -> (
    session: AgentSimulationSession,
    childID: AgentID,
    childEstate: AgentEstateRecord,
    checkpoint: AgentSessionCheckpoint
) {
    let retained = compactParentDeath ? 1 : 2
    let fixture = makeEstateSession(
        simulationID,
        registerAsset: false,
        mortalityConfiguration: estateHistoricalMortalityConfiguration(
            retainedRecords: retained
        ),
        estateConfiguration: estateHistoricalEstateConfiguration(
            retainedEstates: retained
        )
    )
    var session = fixture.0
    let childID = fixture.1!.newbornID
    let compactionSiblingID = compactParentDeath
        ? createEstateSiblingBirth(&session).newbornID : nil
    let parentalUnion = session.familySnapshot().unions.first {
        $0.status == .active
            && $0.partnerIDs.contains(estateAgentIDs[0])
    }!
    try! session.endUnion(
        unionID: parentalUnion.unionID,
        reason: .unilateralSeparation,
        receipt: estateInteraction(
            session,
            id: "\(simulationID)-historical-separation",
            kind: .unionSeparation,
            actor: estateAgentIDs[0],
            counterparty: estateAgentIDs[1]
        )
    )
    for membership in try! session.currentHouseMemberships(
        of: estateAgentIDs[0]
    ) {
        try! session.leaveHouse(
            membership.houseID,
            agentID: estateAgentIDs[0],
            operationID: "\(simulationID)-leave-"
                + membership.houseID.rawValue
        )
    }
    _ = finalizeEstateDeath(&session, physicalAssets: [])
    if let compactionSiblingID {
        _ = estateFinalizeSpecificEmptyDeath(
            &session, agentID: compactionSiblingID
        )
    }
    let childEstate = estateFinalizeSpecificEmptyDeath(
        &session, agentID: childID
    )
    let checkpoint = try! session.makeCheckpoint()
    return (session, childID, childEstate, checkpoint)
}

func runPebbleAgentsEstatesInheritanceSuccessionSmoke() {
    section("CIV-33 estates, inheritance, and succession V1")

    let configuration = AgentEstateConfiguration.live
    check("estate V1 collections are explicitly bounded",
          configuration.maximumRetainedEstates == 32
            && configuration.maximumOpenEstates == 32
            && configuration.maximumAssetsPerEstate == 16
            && configuration.maximumObligationsPerEstate == 16
            && configuration.maximumBeneficiariesPerEstate == 32
            && configuration.maximumAdministrationsPerEstate == 16
            && configuration.maximumSettlementAttemptsPerAsset == 16
            && configuration.maximumProcessedOperationIDs == 512
            && configuration.maximumTransitionsPerTick == 128)
    check("estate V1 configuration is Codable",
          (try? AgentCheckpointCodec.decode(
              AgentEstateConfiguration.self,
              from: AgentCheckpointCodec.encode(configuration)
          )) == configuration)
    let lowRetentionMortality = try! AgentMortalityConfiguration(
        maximumDeathsPerTick: 1,
        maximumRetainedDeathRecords: 2,
        maximumFinalMemoryEntries: 2,
        maximumCancelledCommitmentIDsPerDeath: 8,
        maximumExitFrames: 3,
        maximumMaterialExitsPerDeath: 4,
        requiresTerminalPhysicalCustodyVerification: true
    )
    let lowRetentionEstates = try! AgentEstateConfiguration(
        maximumRetainedEstates: 2,
        maximumOpenEstates: 2,
        maximumAssetsPerEstate: 4,
        maximumObligationsPerEstate: 4,
        maximumBeneficiariesPerEstate: 8,
        maximumAdministrationsPerEstate: 4,
        maximumSettlementAttemptsPerAsset: 4,
        maximumProcessedOperationIDs: 32,
        maximumTransitionsPerTick: 32
    )

    var missingRights = makeEstateSession(
        "civ33-needs-rights", includeUnionAndChild: false,
        registerAsset: false
    ).0
    let missingRightsBytes = try! missingRights.durableStateBytes()
    check("durable estate activation cannot be disabled", {
        do {
            try missingRights.setEstatesEnabled(false)
            return false
        } catch AgentSessionError.estate(.unsafeDisable) {
            return (try! missingRights.durableStateBytes())
                == missingRightsBytes
        } catch {
            return false
        }
    }())

    var empty = makeEstateSession(
        "civ33-empty-estate", includeUnionAndChild: false,
        registerAsset: false
    ).0
    let emptyEstate = finalizeEstateDeath(&empty, physicalAssets: [])
    check("verified empty custody opens and settles exactly one empty estate",
          emptyEstate.assets.isEmpty && emptyEstate.status == .settled
            && empty.estateSnapshot().totalEstateCount == 1
            && empty.estateSnapshot().totalSettlementCount == 1
            && empty.mortalitySnapshot().totalDeathCount == 1)

    var postActivationOnly = makeEstateSession(
        "civ33-no-retroactive-estate",
        includeUnionAndChild: false,
        registerAsset: false,
        enableEstates: false
    ).0
    _ = finalizeEstatePhysicalDeath(
        &postActivationOnly, physicalAssets: []
    )
    try! postActivationOnly.setEstatesEnabled(true)
    postActivationOnly = estateSessionPreparingLethalAgent(
        postActivationOnly, targetID: estateAgentIDs[1]
    )
    _ = finalizeEstatePhysicalDeath(
        &postActivationOnly, physicalAssets: []
    )
    check("explicit activation creates no retroactive historical estate",
          postActivationOnly.mortalitySnapshot().totalDeathCount == 2
            && postActivationOnly.estateSnapshot().totalEstateCount == 1
            && postActivationOnly.estateSnapshot().estates.map(\.decedentID)
                == [estateAgentIDs[1]])

    var pinnedRetention = makeEstateSession(
        "civ33-retention-pinned",
        thirdPartyClaim: true,
        mortalityConfiguration: lowRetentionMortality,
        estateConfiguration: lowRetentionEstates
    ).0
    let pinnedA = finalizeEstateDeath(
        &pinnedRetention,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    pinnedRetention = estateSessionPreparingLethalAgent(
        pinnedRetention, targetID: estateAgentIDs[1]
    )
    let settledB = finalizeEstateDeath(
        &pinnedRetention, physicalAssets: []
    )
    pinnedRetention = estateSessionPreparingLethalAgent(
        pinnedRetention, targetID: estateAgentIDs[2]
    )
    let pinnedBefore = pinnedRetention.estateSnapshot()
    check("open or blocked oldest estate pins its mortality record",
          pinnedA.status == .blocked
            && settledB.status == .settled
            && finalizeEmptyEstateDeathRefused(&pinnedRetention)
            && pinnedRetention.estateSnapshot() == pinnedBefore
            && pinnedRetention.mortalitySnapshot().records.contains {
                $0.deathID == pinnedA.deathID
            })

    var coordinatedRetention = makeEstateSession(
        "civ33-retention-coordinated",
        registerAsset: false,
        mortalityConfiguration: lowRetentionMortality,
        estateConfiguration: lowRetentionEstates
    ).0
    registerEstateAsset(
        &coordinatedRetention,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        ownerID: estateAgentIDs[1],
        holderID: estateAgentIDs[1],
        recognizingAgentIDs: [estateAgentIDs[1], estateAgentIDs[2]],
        operationPrefix: "civ33-retention-coordinated:agent1"
    )
    let coordinatedUnion = coordinatedRetention.familySnapshot().unions[0]
    try! coordinatedRetention.endUnion(
        unionID: coordinatedUnion.unionID,
        reason: .unilateralSeparation,
        receipt: estateInteraction(
            coordinatedRetention,
            id: "civ33-retention-coordinated:separation",
            kind: .unionSeparation,
            actor: estateAgentIDs[0],
            counterparty: estateAgentIDs[1]
        )
    )
    let compactedA = finalizeEstateDeath(
        &coordinatedRetention, physicalAssets: []
    )
    coordinatedRetention = estateSessionPreparingLethalAgent(
        coordinatedRetention, targetID: estateAgentIDs[1]
    )
    let retainedB = finalizeEstateDeath(
        &coordinatedRetention,
        physicalAssets: [
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
        ]
    )
    coordinatedRetention = estateSessionPreparingLethalAgent(
        coordinatedRetention, targetID: estateAgentIDs[2]
    )
    let retainedC = finalizeEstateDeath(
        &coordinatedRetention, physicalAssets: []
    )
    let coordinatedCheckpoint = try! coordinatedRetention.makeCheckpoint()
    let coordinatedRestart = try! AgentSimulationSession.restoring(
        coordinatedCheckpoint
    )
    check("terminal estate and mortality record compact as one pair",
          compactedA.status == .settled
            && !coordinatedRetention.estateSnapshot().estates.contains {
                $0.estateID == compactedA.estateID
            }
            && coordinatedRetention.estateSnapshot().estates.map(
                \.estateID
            ).sorted() == [retainedB.estateID, retainedC.estateID].sorted()
            && coordinatedRetention.mortalitySnapshot().records.map(
                \.deathID
            ).sorted() == [retainedB.deathID, retainedC.deathID].sorted()
            && coordinatedRetention.estateSnapshot().evictionCounts
                .settledEstates == 1
            && coordinatedRetention.mortalitySnapshot().evictionCounts
                .deathRecords == 1
            && coordinatedCheckpoint.schemaVersion == 28
            && coordinatedRetention.estateSnapshot().estates.allSatisfy {
                $0.successorPlanProof != nil
            }
            && coordinatedRestart.estateSnapshot()
                == coordinatedRetention.estateSnapshot()
            && coordinatedRestart.mortalitySnapshot()
                == coordinatedRetention.mortalitySnapshot())

    let retainedParentHistory = estateParentHistoryFixture(
        "civ33-parent-retained-history", compactParentDeath: false
    )
    let retainedParentRow = retainedParentHistory.childEstate
        .successorPlanProof!.eligibilityRows.first {
            $0.agentID == estateAgentIDs[0]
                && $0.basis == .canonicalParent
        }!
    check("retained pre-boundary parent death proves exact ineligibility",
          retainedParentRow.eligibleAtDeath == false
            && retainedParentHistory.session.mortalitySnapshot().records
                .contains { $0.agentID == estateAgentIDs[0] })

    let compactedParentHistory = estateParentHistoryFixture(
        "civ33-parent-compacted-history", compactParentDeath: true
    )
    let compactedMortality = compactedParentHistory.session
        .mortalitySnapshot()
    let compactedParentSummary = compactedMortality
        .compactedDeathSummaries!.first {
            $0.agentID == estateAgentIDs[0]
        }!
    let compactedParentRow = compactedParentHistory.childEstate
        .successorPlanProof!.eligibilityRows.first {
            $0.agentID == estateAgentIDs[0]
                && $0.basis == .canonicalParent
        }!
    check("compacted pre-boundary parent death remains exact evidence",
          compactedParentRow.eligibleAtDeath == false
            && compactedParentRow.lifeStageAtPlan
                == compactedParentSummary.lifeStageAtDeath
            && compactedMortality.records.allSatisfy {
                $0.agentID != estateAgentIDs[0]
            }
            && compactedMortality.historicalEvidenceVersion == 1
            && compactedMortality.compactedDeathSummaries?.count == 2)
    let fullyResignedIntactCheckpoint = estateMutatedCheckpoint(
        compactedParentHistory.checkpoint
    ) { durable in
        estateResignSuccessorPlan(&durable, estateIndex: 0)
    }
    check("fully re-signed intact successor plan still restores",
          (try? AgentSimulationSession.restoring(
              fullyResignedIntactCheckpoint
          ))?.estateSnapshot()
            == compactedParentHistory.session.estateSnapshot())

    check("fully re-signed checkpoint cannot revive compacted parent", {
        let refused = estateRestoreRefused(
            compactedParentHistory.checkpoint
        ) { durable in
            var authority = durable["estateState"] as! [String: Any]
            var estates = authority["estates"] as! [[String: Any]]
            var proof = estates[0]["successorPlanProof"]
                as! [String: Any]
            var rows = proof["eligibilityRows"] as! [[String: Any]]
            let parentIndex = rows.firstIndex {
                $0["agentID"] as? String == estateAgentIDs[0].rawValue
            }!
            rows[parentIndex]["eligibleAtDeath"] = true
            proof["eligibilityRows"] = rows
            estates[0]["successorPlanProof"] = proof
            var beneficiaries = estates[0]["beneficiaries"]
                as! [[String: Any]]
            beneficiaries.append([
                "agentID": estateAgentIDs[0].rawValue,
                "tier": AgentEstateBeneficiaryTier.secondaryParents.rawValue,
                "basis": AgentEstateBeneficiaryBasis.canonicalParent.rawValue,
                "weight": 1,
                "lifeStageAtPlan": rows[parentIndex]["lifeStageAtPlan"]!,
                "allocationCount": 0,
            ])
            beneficiaries.sort {
                ($0["agentID"] as! String) < ($1["agentID"] as! String)
            }
            estates[0]["beneficiaries"] = beneficiaries
            authority["estates"] = estates
            durable["estateState"] = authority
            estateResignSuccessorPlan(&durable, estateIndex: 0)
        }
        return refused
    }())
    check("fully re-signed checkpoint cannot rewrite compacted stage",
          estateRestoreRefused(compactedParentHistory.checkpoint) {
              durable in
              var authority = durable["estateState"] as! [String: Any]
              var estates = authority["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              let parentIndex = rows.firstIndex {
                  $0["agentID"] as? String == estateAgentIDs[0].rawValue
              }!
              rows[parentIndex]["lifeStageAtPlan"] =
                  AgentLifeStage.juvenile.rawValue
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              authority["estates"] = estates
              durable["estateState"] = authority
              estateResignSuccessorPlan(&durable, estateIndex: 0)
          })
    check("fully re-signed checkpoint cannot add compacted guardian",
          estateRestoreRefused(compactedParentHistory.checkpoint) {
              durable in
              var authority = durable["estateState"] as! [String: Any]
              var estates = authority["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              let parentIndex = rows.firstIndex {
                  $0["agentID"] as? String == estateAgentIDs[0].rawValue
              }!
              rows[parentIndex]["guardianIDAtPlan"] =
                  estateAgentIDs[1].rawValue
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              authority["estates"] = estates
              durable["estateState"] = authority
              estateResignSuccessorPlan(&durable, estateIndex: 0)
          })

    let deadChildFixture = makeEstateSession(
        "civ33-compacted-child-history",
        registerAsset: false,
        mortalityConfiguration: estateHistoricalMortalityConfiguration(
            retainedRecords: 2
        ),
        estateConfiguration: estateHistoricalEstateConfiguration(
            retainedEstates: 2
        )
    )
    var deadChildHistory = estateSessionWithStableNeeds(
        deadChildFixture.0
    )
    let historicalChildID = deadChildFixture.1!.newbornID
    while deadChildHistory.lifecycleSnapshot().members.first(where: {
        $0.agentID == historicalChildID
    })!.currentStage != .mature {
        _ = try! deadChildHistory.advanceTick()
    }
    for membership in try! deadChildHistory.currentHouseMemberships(
        of: historicalChildID
    ) {
        try! deadChildHistory.leaveHouse(
            membership.houseID,
            agentID: historicalChildID,
            operationID: "civ33-child-leave-"
                + membership.houseID.rawValue
        )
    }
    _ = estateFinalizeSpecificEmptyDeath(
        &deadChildHistory, agentID: historicalChildID
    )
    _ = estateFinalizeSpecificEmptyDeath(
        &deadChildHistory, agentID: estateAgentIDs[2]
    )
    let parentAfterChildDeath = estateFinalizeSpecificEmptyDeath(
        &deadChildHistory, agentID: estateAgentIDs[0]
    )
    let deadChildCheckpoint = try! deadChildHistory.makeCheckpoint()
    let parentEstateJSONIndex: Int = {
        let encoded = try! JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(deadChildCheckpoint)
        ) as! [String: Any]
        let durable = encoded["durableState"] as! [String: Any]
        let authority = durable["estateState"] as! [String: Any]
        return (authority["estates"] as! [[String: Any]])
            .firstIndex {
                $0["estateID"] as? String
                    == parentAfterChildDeath.estateID.rawValue
            }!
    }()
    check("fully re-signed checkpoint cannot revive compacted child",
          deadChildHistory.mortalitySnapshot().compactedDeathSummaries?
            .contains { $0.agentID == historicalChildID } == true
            && estateRestoreRefused(deadChildCheckpoint) { durable in
                var authority = durable["estateState"]
                    as! [String: Any]
                var estates = authority["estates"]
                    as! [[String: Any]]
                var proof = estates[parentEstateJSONIndex][
                    "successorPlanProof"
                ] as! [String: Any]
                var rows = proof["eligibilityRows"]
                    as! [[String: Any]]
                let childIndex = rows.firstIndex {
                    $0["agentID"] as? String
                        == historicalChildID.rawValue
                }!
                rows[childIndex]["eligibleAtDeath"] = true
                proof["eligibilityRows"] = rows
                estates[parentEstateJSONIndex]["successorPlanProof"] =
                    proof
                var beneficiaries = estates[parentEstateJSONIndex][
                    "beneficiaries"
                ] as! [[String: Any]]
                beneficiaries.append([
                    "agentID": historicalChildID.rawValue,
                    "tier": AgentEstateBeneficiaryTier
                        .primaryPartnerAndChildren.rawValue,
                    "basis": AgentEstateBeneficiaryBasis
                        .canonicalChild.rawValue,
                    "weight": 1,
                    "lifeStageAtPlan": rows[childIndex][
                        "lifeStageAtPlan"
                    ]!,
                    "allocationCount": 0,
                ])
                beneficiaries.sort {
                    ($0["agentID"] as! String)
                        < ($1["agentID"] as! String)
                }
                estates[parentEstateJSONIndex]["beneficiaries"] =
                    beneficiaries
                authority["estates"] = estates
                durable["estateState"] = authority
                estateResignSuccessorPlan(
                    &durable, estateIndex: parentEstateJSONIndex
                )
            })

    let siblingHistoryFixture = makeEstateSession(
        "civ33-compacted-sibling-history",
        registerAsset: false,
        mortalityConfiguration: estateHistoricalMortalityConfiguration(
            retainedRecords: 2
        ),
        estateConfiguration: estateHistoricalEstateConfiguration(
            retainedEstates: 2
        )
    )
    var deadSiblingHistory = estateSessionWithStableNeeds(
        siblingHistoryFixture.0
    )
    let survivingSiblingID = siblingHistoryFixture.1!.newbornID
    let historicalSiblingID = createEstateSiblingBirth(
        &deadSiblingHistory
    ).newbornID
    while deadSiblingHistory.lifecycleSnapshot().members.first(where: {
        $0.agentID == historicalSiblingID
    })!.currentStage != .mature {
        _ = try! deadSiblingHistory.advanceTick()
    }
    for membership in try! deadSiblingHistory.currentHouseMemberships(
        of: historicalSiblingID
    ) {
        try! deadSiblingHistory.leaveHouse(
            membership.houseID,
            agentID: historicalSiblingID,
            operationID: "civ33-sibling-leave-"
                + membership.houseID.rawValue
        )
    }
    _ = estateFinalizeSpecificEmptyDeath(
        &deadSiblingHistory, agentID: historicalSiblingID
    )
    _ = estateFinalizeSpecificEmptyDeath(
        &deadSiblingHistory, agentID: estateAgentIDs[2]
    )
    let historicalSiblingEstate = estateFinalizeSpecificEmptyDeath(
        &deadSiblingHistory, agentID: survivingSiblingID
    )
    let deadSiblingCheckpoint = try! deadSiblingHistory.makeCheckpoint()
    let siblingEstateJSONIndex: Int = {
        let encoded = try! JSONSerialization.jsonObject(
            with: AgentCheckpointCodec.encode(deadSiblingCheckpoint)
        ) as! [String: Any]
        let durable = encoded["durableState"] as! [String: Any]
        let authority = durable["estateState"] as! [String: Any]
        return (authority["estates"] as! [[String: Any]])
            .firstIndex {
                $0["estateID"] as? String
                    == historicalSiblingEstate.estateID.rawValue
            }!
    }()
    check("fully re-signed checkpoint cannot revive compacted sibling",
          deadSiblingHistory.mortalitySnapshot().compactedDeathSummaries?
            .contains { $0.agentID == historicalSiblingID } == true
            && estateRestoreRefused(deadSiblingCheckpoint) { durable in
                var authority = durable["estateState"]
                    as! [String: Any]
                var estates = authority["estates"]
                    as! [[String: Any]]
                var proof = estates[siblingEstateJSONIndex][
                    "successorPlanProof"
                ] as! [String: Any]
                var rows = proof["eligibilityRows"]
                    as! [[String: Any]]
                let siblingIndex = rows.firstIndex {
                    $0["agentID"] as? String
                        == historicalSiblingID.rawValue
                }!
                rows[siblingIndex]["eligibleAtDeath"] = true
                proof["eligibilityRows"] = rows
                estates[siblingEstateJSONIndex]["successorPlanProof"] =
                    proof
                authority["estates"] = estates
                durable["estateState"] = authority
                estateResignSuccessorPlan(
                    &durable, estateIndex: siblingEstateJSONIndex
                )
            })

    var postBoundaryHistory = makeEstateSession(
        "civ33-post-boundary-death",
        registerAsset: false,
        mortalityConfiguration: estateHistoricalMortalityConfiguration(
            retainedRecords: 2
        ),
        estateConfiguration: estateHistoricalEstateConfiguration(
            retainedEstates: 2
        )
    ).0
    let postBoundaryChild = postBoundaryHistory.lifecycleSnapshot()
        .members.first { $0.origin == .localBirth }!.agentID
    let preParentDeathEstate = estateFinalizeSpecificEmptyDeath(
        &postBoundaryHistory, agentID: postBoundaryChild
    )
    _ = estateFinalizeSpecificEmptyDeath(
        &postBoundaryHistory, agentID: estateAgentIDs[0]
    )
    let postBoundaryParentRow = preParentDeathEstate.successorPlanProof!
        .eligibilityRows.first { $0.agentID == estateAgentIDs[0] }!
    let postBoundaryCheckpoint = try! postBoundaryHistory.makeCheckpoint()
    check("person dying after death boundary remains eligible",
          postBoundaryParentRow.eligibleAtDeath
            && postBoundaryHistory.mortalitySnapshot().records.first {
                $0.agentID == estateAgentIDs[0]
            }!.deathTick > preParentDeathEstate.deathTick
            && (try? AgentSimulationSession.restoring(
                postBoundaryCheckpoint
            )) != nil)

    check("compacted summary wrong identity death and tick fail closed",
          estateRestoreRefused(compactedParentHistory.checkpoint) {
              durable in
              var mortality = durable["mortalityState"]
                  as! [String: Any]
              var summaries = mortality["compactedDeathSummaries"]
                  as! [[String: Any]]
              summaries[0]["agentID"] = estateAgentIDs[1].rawValue
              mortality["compactedDeathSummaries"] = summaries
              durable["mortalityState"] = mortality
          }
            && estateRestoreRefused(compactedParentHistory.checkpoint) {
                durable in
                var mortality = durable["mortalityState"]
                    as! [String: Any]
                var summaries = mortality["compactedDeathSummaries"]
                    as! [[String: Any]]
                summaries[0]["deathID"] =
                    "death-agent_0-t999-0000000000000000"
                mortality["compactedDeathSummaries"] = summaries
                durable["mortalityState"] = mortality
            }
            && estateRestoreRefused(compactedParentHistory.checkpoint) {
                durable in
                var mortality = durable["mortalityState"]
                    as! [String: Any]
                var summaries = mortality["compactedDeathSummaries"]
                    as! [[String: Any]]
                summaries[0]["deathTick"] =
                    (summaries[0]["deathTick"] as! Int) + 1
                mortality["compactedDeathSummaries"] = summaries
                durable["mortalityState"] = mortality
            })
    check("duplicate compacted death summary fails closed",
          estateRestoreRefused(compactedParentHistory.checkpoint) {
              durable in
              var mortality = durable["mortalityState"]
                  as! [String: Any]
              var summaries = mortality["compactedDeathSummaries"]
                  as! [[String: Any]]
              var duplicate = summaries[0]
              duplicate["deathOrdinal"] = summaries.count + 1
              summaries.append(duplicate)
              mortality["compactedDeathSummaries"] = summaries
              var evictions = mortality["evictionCounts"]
                  as! [String: Any]
              evictions["deathRecords"] = summaries.count
              mortality["evictionCounts"] = evictions
              durable["mortalityState"] = mortality
          })
    check("incomplete schema 28 historical evidence fails closed",
          estateRestoreRefused(compactedParentHistory.checkpoint) {
              durable in
              var mortality = durable["mortalityState"]
                  as! [String: Any]
              mortality.removeValue(forKey: "historicalEvidenceVersion")
              mortality.removeValue(forKey: "compactedDeathSummaries")
              durable["mortalityState"] = mortality
          })

    let boundedHistoricalFixture = makeEstateSession(
        "civ33-historical-capacity",
        registerAsset: false,
        mortalityConfiguration: estateHistoricalMortalityConfiguration(
            retainedRecords: 1, compactedSummaries: 1
        ),
        estateConfiguration: estateHistoricalEstateConfiguration(
            retainedEstates: 1
        )
    )
    var boundedHistoricalEvidence = boundedHistoricalFixture.0
    let boundedChildID = boundedHistoricalFixture.1!.newbornID
    let boundedSiblingID = createEstateSiblingBirth(
        &boundedHistoricalEvidence
    ).newbornID
    let boundedUnion = boundedHistoricalEvidence.familySnapshot()
        .unions.first { $0.status == .active }!
    try! boundedHistoricalEvidence.endUnion(
        unionID: boundedUnion.unionID,
        reason: .unilateralSeparation,
        receipt: estateInteraction(
            boundedHistoricalEvidence,
            id: "civ33-historical-capacity-separation",
            kind: .unionSeparation,
            actor: estateAgentIDs[0],
            counterparty: estateAgentIDs[1]
        )
    )
    for membership in try! boundedHistoricalEvidence
        .currentHouseMemberships(of: estateAgentIDs[0]) {
        try! boundedHistoricalEvidence.leaveHouse(
            membership.houseID,
            agentID: estateAgentIDs[0],
            operationID: "civ33-capacity-leave-"
                + membership.houseID.rawValue
        )
    }
    _ = finalizeEstateDeath(
        &boundedHistoricalEvidence, physicalAssets: []
    )
    _ = estateFinalizeSpecificEmptyDeath(
        &boundedHistoricalEvidence, agentID: boundedSiblingID
    )
    boundedHistoricalEvidence = estateSessionPreparingLethalAgent(
        boundedHistoricalEvidence,
        targetID: boundedChildID
    )
    check("historical evidence capacity refuses atomically before proof loss",
          finalizeEmptyEstateDeathRefused(&boundedHistoricalEvidence)
            && boundedHistoricalEvidence.mortalitySnapshot()
                .compactedDeathSummaries?.count == 1
            && boundedHistoricalEvidence.pendingMortalityTransitions()
                .count == 1)

    var historicalReplaySession = try! AgentSimulationSession.restoring(
        compactedParentHistory.checkpoint
    )
    var historicalReplayRecorder = try! AgentReplayRecorder(
        checkpoint: compactedParentHistory.checkpoint,
        session: historicalReplaySession
    )
    _ = try! historicalReplayRecorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &historicalReplaySession
    )
    let historicalReplayJournal = try! historicalReplayRecorder.journal(
        named: AgentCheckpointName(
            rawValue: "civ33-historical-compaction-replay"
        )!
    )
    let historicalReplayed = try! AgentSessionReplayer.replay(
        checkpoint: compactedParentHistory.checkpoint,
        journal: historicalReplayJournal
    )
    check("multiple compactions checkpoint and replay remain byte exact",
          historicalReplayed.session.mortalitySnapshot()
                .compactedDeathSummaries
                == historicalReplaySession.mortalitySnapshot()
                    .compactedDeathSummaries
            && (try! historicalReplayed.session.durableStateBytes())
                == (try! historicalReplaySession.durableStateBytes()))

    let sessionAndBirth = makeEstateSession("civ33-main")
    var session = sessionAndBirth.0
    let childID = sessionAndBirth.1!.newbornID
    let familyBeforeDeath = session.familySnapshot()
    let rightsBeforeDeath = session.materialRightsSnapshot().records[0]
    let estate = finalizeEstateDeath(
        &session,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    check("physical mortality exit opens one estate after custody proof",
          estate.physicalCustodyResolution.kind == .transferred
            && estate.physicalCustodyResolution.physicalAssets
                == [AgentMaterialStackSnapshot(
                    identity: estateIdentity, count: 1
                )]
            && estate.assets.count == 1
            && estate.assets[0].mortalityExitHolderID
                == "container:0,64,0")
    let death = session.mortalitySnapshot().records.first {
        $0.deathID == estate.deathID
    }!
    let causalByID = Dictionary(uniqueKeysWithValues:
        session.causalLedgerSnapshot().events.map {
            ($0.eventID, $0)
        }
    )
    check("death causality orders physical exit estate commitments and finalization",
          causalByID[estate.openingEventID]?.causes.contains(
            estate.physicalCustodyResolution.eventID
          ) == true
            && causalByID[estate.openingEventID]?.causes.contains(
                death.lethalDamageEventID
            ) == true
            && causalByID[death.commitmentsResolvedEventID]?.causes.contains(
                estate.openingEventID
            ) == true
            && causalByID[death.populationExitEventID]?.causes.contains(
                death.commitmentsResolvedEventID
            ) == true
            && causalByID[death.deathEventID]?.causes
                == [death.populationExitEventID])
    check("active partner and canonical child form the primary tier",
          estate.beneficiaryTier == .primaryPartnerAndChildren
            && estate.beneficiaries.map(\.agentID)
                == [estateAgentIDs[1], childID].sorted()
            && Set(estate.beneficiaries.map(\.basis))
                == [.activeUnionPartnerAtDeath, .canonicalChild])
    check("schema 28 successor plan carries exact bounded eligibility proof",
          estate.successorPlanProof?.version == 2
            && estate.successorPlanProof?.selectedTier
                == .primaryPartnerAndChildren
            && estate.successorPlanProof?.eligibilityRows.filter(
                \.eligibleAtDeath
            ).map(\.agentID) == estate.beneficiaries.map(\.agentID)
            && estate.successorPlanProof?.activeUnionAtDeath?.partnerID
                == estateAgentIDs[1]
            && estate.successorPlanProof?.successorPlanEventID
                == estate.successorPlanEventID)
    check("partner remains successor while union ends by partner death",
          session.familySnapshot().unions.first?.terminationReason
            == .partnerDeath
            && estate.beneficiaries.contains {
                $0.agentID == estateAgentIDs[1]
                    && $0.basis == .activeUnionPartnerAtDeath
            })
    check("minor beneficiary retains owner/custodian distinction",
          estate.beneficiaries.first {
              $0.agentID == childID
          }?.lifeStageAtPlan != .mature
            && estate.beneficiaries.first {
                $0.agentID == childID
            }?.guardianIDAtPlan != nil,
          "\(String(describing: estate.beneficiaries.first { $0.agentID == childID }))")
    check("estate changes no lineage house or founder authority",
          session.familySnapshot().lineages == familyBeforeDeath.lineages
            && session.familySnapshot().houses == familyBeforeDeath.houses
            && session.familySnapshot().houseMembershipPeriods
                .filter { $0.agentID != estateAgentIDs[0] }
                == familyBeforeDeath.houseMembershipPeriods.filter {
                    $0.agentID != estateAgentIDs[0]
                })
    let afterExitRights = session.materialRightsSnapshot().records[0]
    check("mortality exit preserves ownership claims and granted permission",
          afterExitRights.recognizedOwnership
                == rightsBeforeDeath.recognizedOwnership
            && afterExitRights.claims == rightsBeforeDeath.claims
            && afterExitRights.permissions == rightsBeforeDeath.permissions
            && afterExitRights.lastVerifiedHolder.holder
                == .container("0,64,0"))
    check("administrator nomination is causal and requires acceptance",
          estate.administrations.count == 1
            && estate.administrations[0].administratorID
                == estateAgentIDs[1]
            && estate.administrations[0].status == .nominated
            && estate.status == .openUnadministered)

    let unacceptedCheckpoint = try! session.makeCheckpoint()
    let administration = try! session.acceptEstateAdministration(
        estateID: estate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-main:administrator-acceptance"
    )
    check("administrator explicitly accepts once",
          administration.status == .active
            && administration.acceptanceEventID != nil
            && session.estateSnapshot().estates[0].status
                == .openAdministered)
    let beforeDuplicateAcceptance = try! session.durableStateBytes()
    check("administrator acceptance cannot be reused", {
        do {
            _ = try session.acceptEstateAdministration(
                estateID: estate.estateID,
                administratorID: estateAgentIDs[1],
                operationID: "civ33-main:administrator-acceptance"
            )
            return false
        } catch {
            return (try! session.durableStateBytes())
                == beforeDuplicateAcceptance
        }
    }())

    let openCheckpoint = try! session.makeCheckpoint()
    let restoredOpen = try! AgentSimulationSession.restoring(openCheckpoint)
    check("schema 28 restores the same open estate without progress",
          openCheckpoint.schemaVersion == 28
            && restoredOpen.estateSnapshot() == session.estateSnapshot()
            && restoredOpen.materialRightsSnapshot()
                == session.materialRightsSnapshot())
    let exactSchema27Checkpoint = estateSchema27Checkpoint(
        openCheckpoint, preserveExactCausalProof: true
    )
    let exactSchema27Restore = try? AgentSimulationSession.restoring(
        exactSchema27Checkpoint
    )
    check("schema 27 remains readable only with exact retained causal proof",
          exactSchema27Checkpoint.schemaVersion == 27
            && exactSchema27Restore?.estateSnapshot().estates[0]
                .successorPlanProof == nil
            && exactSchema27Restore?.estateSnapshot().estates[0]
                .beneficiaries == session.estateSnapshot().estates[0]
                    .beneficiaries)
    let incompleteSchema27Checkpoint = estateSchema27Checkpoint(
        openCheckpoint, preserveExactCausalProof: false
    )
    check("schema 27 refuses an incomplete successor proof", {
        do {
            _ = try AgentSimulationSession.restoring(
                incompleteSchema27Checkpoint
            )
            return false
        } catch {
            return true
        }
    }())
    let observer = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "world-civ33", storageIdentity: "civ33-store",
            seed: 33, dimension: 0, observedWorldTick: session.tick
        )
    )
    check("Observer schema 6 projects estate authority read-only",
          observer.header.schemaVersion == 6
            && observer.estateAuthority?.estates.count == 1
            && observer.recentDeaths.first?.estateID == estate.estateID
            && session.estateSnapshot()
                == restoredOpen.estateSnapshot())

    let source = session.materialRightsSnapshot().records[0]
        .lastVerifiedHolder
    let settlement = AgentEstatePhysicalSettlementOutcome(
        operationID: "civ33-main:asset-settlement",
        estateID: estate.estateID,
        entryID: estate.assets[0].entryID,
        administratorID: estateAgentIDs[1],
        beneficiaryID: estate.assets[0].assignedBeneficiaryID!,
        intendedCustodianID: estate.assets[0].intendedCustodianID,
        sourceObservation: source,
        destinationObservation: AgentMaterialHolderObservation(
            holder: .agent(estateAgentIDs[1]),
            materialIdentity: estateIdentity, quantity: 1,
            custodyFingerprint: "civ33-main:agent1:after-settlement",
            physicalReceiptID: "civ33-main:asset-settlement",
            observedAtTick: session.tick
        ),
        sourceFingerprintAfterTransfer:
            "civ33-main:container:after-settlement",
        destinationFingerprintBeforeTransfer:
            "civ33-main:agent1:before-settlement",
        physicalReceiptID: "civ33-main:asset-settlement"
    )
    let mismatchedSettlement = AgentEstatePhysicalSettlementOutcome(
        operationID: "civ33-main:different-operation",
        estateID: settlement.estateID,
        entryID: settlement.entryID,
        administratorID: settlement.administratorID,
        beneficiaryID: settlement.beneficiaryID,
        intendedCustodianID: settlement.intendedCustodianID,
        sourceObservation: settlement.sourceObservation,
        destinationObservation: settlement.destinationObservation,
        sourceFingerprintAfterTransfer:
            settlement.sourceFingerprintAfterTransfer,
        destinationFingerprintBeforeTransfer:
            settlement.destinationFingerprintBeforeTransfer,
        physicalReceiptID: settlement.physicalReceiptID
    )
    let beforeMismatchedSettlement = try! session.durableStateBytes()
    let beforeMismatchedObserver = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "world-civ33", storageIdentity: "civ33-store",
            seed: 33, dimension: 0, observedWorldTick: session.tick
        )
    )
    check("settlement operation and physical receipt must match before mutation", {
        do {
            _ = try session.applyEstatePhysicalSettlement(
                mismatchedSettlement
            )
            return false
        } catch {
            return (try! session.durableStateBytes())
                    == beforeMismatchedSettlement
                && session.observerSnapshot(
                    worldBinding: beforeMismatchedObserver.header.worldBinding
                ) == beforeMismatchedObserver
        }
    }())
    _ = try! session.applyEstatePhysicalSettlement(settlement)
    let settledEstate = session.estateSnapshot().estates[0]
    let settledRights = session.materialRightsSnapshot().records[0]
    check("verified settlement updates holder custodian and owner once",
          settledEstate.assets[0].status == .transferred
            && settledEstate.status == .settled
            && settledRights.lastVerifiedHolder.holder
                == .agent(estateAgentIDs[1])
            && settledRights.custodianID == nil
            && settledRights.recognizedOwnership?.ownerID
                == estateAgentIDs[1])
    check("settlement preserves permissions and replaces only owner claim",
          settledRights.permissions == rightsBeforeDeath.permissions
            && settledRights.claims.count == 1
            && settledRights.claims[0].claimantID == estateAgentIDs[1]
            && settledRights.claims[0].basis == .received)
    let estateBeforeSettledObserver = session.estateSnapshot()
    let settledObserver = session.observerSnapshot(
        worldBinding: try! AgentObserverWorldBinding(
            worldID: "world-civ33", storageIdentity: "civ33-store",
            seed: 33, dimension: 0, observedWorldTick: session.tick
        )
    )
    check("Observer reports current holder custodian and owner without mutation",
          settledObserver.estateAuthority?.estates[0].assets[0]
                .currentOwnerID == estateAgentIDs[1]
            && settledObserver.estateAuthority?.estates[0].assets[0]
                .currentCustodianID == nil
            && settledObserver.estateAuthority?.estates[0].assets[0]
                .physicalHolder == "agent:agent_1"
            && session.estateSnapshot() == estateBeforeSettledObserver)
    check("estate and asset settlement are terminal exactly once",
          session.estateSnapshot().totalSettlementCount == 1
            && settledEstate.settledAtTick == session.tick
            && settledEstate.settledEventID != nil
            && settledEstate.administrations[0].status == .ended
            && settledEstate.administrations[0].endedReason
                == .estateSettled)
    var inheritedUse = session
    let inheritedSource = inheritedUse.materialRightsSnapshot()
        .records[0].lastVerifiedHolder
    let inheritedDecision = inheritedUse.evaluateMaterialUse(
        AgentMaterialUseRequest(
            requestID: "civ33-inherited-tool-use:decision",
            assetID: settledRights.asset.assetID,
            actorID: estateAgentIDs[1],
            use: .toolUse,
            verifiedHolder: inheritedSource
        )
    )
    let inheritedIdentity = AgentMaterialIdentitySnapshot(
        itemKey: inheritedSource.materialIdentity.itemKey,
        damage: inheritedSource.materialIdentity.damage + 1,
        enchantments: inheritedSource.materialIdentity.enchantments,
        label: inheritedSource.materialIdentity.label,
        canonicalDataJSON: inheritedSource.materialIdentity.canonicalDataJSON
    )
    let inheritedObservation = AgentMaterialHolderObservation(
        holder: inheritedSource.holder,
        materialIdentity: inheritedIdentity,
        quantity: inheritedSource.quantity,
        custodyFingerprint: "civ33-inherited-tool-use-fingerprint",
        physicalReceiptID: "civ33-inherited-tool-use",
        observedAtTick: inheritedUse.tick
    )
    _ = try! inheritedUse.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "civ33-inherited-tool-use",
            decision: inheritedDecision,
            status: .succeeded,
            resultingObservation: inheritedObservation,
            physicalReceiptID: "civ33-inherited-tool-use"
        )
    ))
    let inheritedEntry = inheritedUse.estateSnapshot().estates[0].assets[0]
    check("verified inherited use advances current estate custody only",
          inheritedDecision.verdict == .allowed
            && inheritedUse.materialRightsSnapshot().records[0]
                .lastVerifiedHolder == inheritedObservation
            && inheritedEntry.destinationObservation == inheritedObservation
            && inheritedEntry.settlementObservation
                == settledEstate.assets[0].settlementObservation
            && inheritedEntry.settlementReceiptID
                == settledEstate.assets[0].settlementReceiptID)
    let inheritedCheckpoint = try! inheritedUse.makeCheckpoint()
    check("inherited use and historical settlement restart byte-exact",
          (try! AgentSimulationSession.restoring(inheritedCheckpoint))
            .estateSnapshot() == inheritedUse.estateSnapshot())
    var repeatedlyEvolved = inheritedUse
    let secondSource = repeatedlyEvolved.materialRightsSnapshot()
        .records[0].lastVerifiedHolder
    let secondDecision = repeatedlyEvolved.evaluateMaterialUse(
        AgentMaterialUseRequest(
            requestID: "civ33-inherited-tool-use-2:decision",
            assetID: settledRights.asset.assetID,
            actorID: estateAgentIDs[1],
            use: .toolUse,
            verifiedHolder: secondSource
        )
    )
    let secondIdentity = AgentMaterialIdentitySnapshot(
        itemKey: secondSource.materialIdentity.itemKey,
        damage: secondSource.materialIdentity.damage + 1,
        enchantments: secondSource.materialIdentity.enchantments,
        label: secondSource.materialIdentity.label,
        canonicalDataJSON: secondSource.materialIdentity.canonicalDataJSON
    )
    let secondObservation = AgentMaterialHolderObservation(
        holder: secondSource.holder,
        materialIdentity: secondIdentity,
        quantity: secondSource.quantity,
        custodyFingerprint: "civ33-inherited-tool-use-2-fingerprint",
        physicalReceiptID: "civ33-inherited-tool-use-2",
        observedAtTick: repeatedlyEvolved.tick
    )
    _ = try! repeatedlyEvolved.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "civ33-inherited-tool-use-2",
            decision: secondDecision,
            status: .succeeded,
            resultingObservation: secondObservation,
            physicalReceiptID: "civ33-inherited-tool-use-2"
        )
    ))
    let repeatedlyEvolvedRecord = repeatedlyEvolved.materialRightsSnapshot()
        .records[0]
    let repeatedlyEvolvedEntry = repeatedlyEvolved.estateSnapshot()
        .estates[0].assets[0]
    check("repeated legitimate identity evolution preserves durable asset",
          secondDecision.verdict == .allowed
            && repeatedlyEvolvedRecord.asset.materialIdentity
                == settledRights.asset.materialIdentity
            && repeatedlyEvolvedRecord.lastVerifiedHolder.materialIdentity
                == secondIdentity
            && repeatedlyEvolvedEntry.settlementObservation
                == settledEstate.assets[0].settlementObservation
            && repeatedlyEvolvedEntry.settlementReceiptID
                == settledEstate.assets[0].settlementReceiptID)
    let repeatedlyEvolvedCheckpoint = try! repeatedlyEvolved.makeCheckpoint()
    check("repeated evolved identity checkpoint remains byte exact",
          (try! AgentSimulationSession.restoring(repeatedlyEvolvedCheckpoint))
            .estateSnapshot() == repeatedlyEvolved.estateSnapshot())
    let afterSettlement = try! session.durableStateBytes()
    check("settled asset refuses duplicate distribution atomically", {
        do {
            _ = try session.applyEstatePhysicalSettlement(settlement)
            return false
        } catch {
            return (try! session.durableStateBytes()) == afterSettlement
        }
    }())
    var replaySession = try! AgentSimulationSession.restoring(
        unacceptedCheckpoint
    )
    var replayRecorder = try! AgentReplayRecorder(
        checkpoint: unacceptedCheckpoint, session: replaySession
    )
    _ = try! replayRecorder.apply(
        .acceptEstateAdministration(
            estateID: estate.estateID,
            administratorID: estateAgentIDs[1],
            operationID: "civ33-main:administrator-acceptance"
        ),
        to: &replaySession
    )
    _ = try! replayRecorder.apply(
        .applyEstatePhysicalSettlement(settlement),
        to: &replaySession
    )
    let estateReplayJournal = try! replayRecorder.journal(
        named: AgentCheckpointName(rawValue: "civ33-estate-replay")!
    )
    let replayedEstate = try! AgentSessionReplayer.replay(
        checkpoint: unacceptedCheckpoint,
        journal: estateReplayJournal
    )
    check("schema 28 replay is byte-exact and non-duplicating",
          replayRecorder.schemaVersion == AgentReplaySchema.estateVersion
            && (try! replaySession.durableStateBytes())
                == (try! session.durableStateBytes())
            && (try! replayedEstate.session.durableStateBytes())
                == (try! session.durableStateBytes())
            && replayedEstate.session.estateSnapshot()
                .totalSettlementCount == 1)
    var mismatchedReplaySession = try! AgentSimulationSession.restoring(
        unacceptedCheckpoint
    )
    var mismatchedReplayRecorder = try! AgentReplayRecorder(
        checkpoint: unacceptedCheckpoint,
        session: mismatchedReplaySession
    )
    _ = try! mismatchedReplayRecorder.apply(
        .acceptEstateAdministration(
            estateID: estate.estateID,
            administratorID: estateAgentIDs[1],
            operationID: "civ33-main:administrator-acceptance"
        ),
        to: &mismatchedReplaySession
    )
    let beforeMismatchedReplay =
        try! mismatchedReplaySession.durableStateBytes()
    check("replay refuses divergent settlement operation and receipt", {
        do {
            _ = try mismatchedReplayRecorder.apply(
                .applyEstatePhysicalSettlement(mismatchedSettlement),
                to: &mismatchedReplaySession
            )
            return false
        } catch {
            return (try! mismatchedReplaySession.durableStateBytes())
                == beforeMismatchedReplay
        }
    }())

    let formerPartnerFixture = makeEstateSession(
        "civ33-former-partner", registerAsset: false
    )
    var formerPartner = formerPartnerFixture.0
    let formerChildID = formerPartnerFixture.1!.newbornID
    let formerUnion = formerPartner.familySnapshot().unions[0]
    try! formerPartner.endUnion(
        unionID: formerUnion.unionID,
        reason: .unilateralSeparation,
        receipt: estateInteraction(
            formerPartner, id: "civ33-former-partner-separation",
            kind: .unionSeparation, actor: estateAgentIDs[0],
            counterparty: estateAgentIDs[1]
        )
    )
    let formerEstate = finalizeEstateDeath(
        &formerPartner, physicalAssets: []
    )
    check("partner separated before death gains no partner succession basis",
          formerEstate.beneficiaries.map(\.agentID) == [formerChildID]
            && formerEstate.beneficiaries[0].basis == .canonicalChild
            && formerPartner.familySnapshot().unions[0].terminationReason
                == .unilateralSeparation)

    let parentFallbackFixture = makeEstateSession(
        "civ33-parent-fallback", registerAsset: false
    )
    let fallbackChildID = parentFallbackFixture.1!.newbornID
    var parentFallback = estateSessionPreparingLethalAgent(
        parentFallbackFixture.0, targetID: fallbackChildID
    )
    let parentEstate = finalizeEstateDeath(
        &parentFallback, physicalAssets: []
    )
    check("living canonical parents form the secondary fallback tier",
          parentEstate.beneficiaryTier == .secondaryParents
            && parentEstate.beneficiaries.map(\.agentID)
                == [estateAgentIDs[0], estateAgentIDs[1]]
            && parentEstate.beneficiaries.allSatisfy {
                $0.basis == .canonicalParent
            })

    let siblingFixture = makeEstateSession(
        "civ33-sibling-fallback", registerAsset: false
    )
    var siblingFallback = siblingFixture.0
    let firstSiblingID = siblingFixture.1!.newbornID
    let secondSiblingID = createEstateSiblingBirth(&siblingFallback).newbornID
    siblingFallback = estateSessionPreparingLethalAgent(
        siblingFallback, targetID: estateAgentIDs[0]
    )
    _ = finalizeEstateDeath(&siblingFallback, physicalAssets: [])
    siblingFallback = estateSessionPreparingLethalAgent(
        siblingFallback, targetID: estateAgentIDs[1]
    )
    _ = finalizeEstateDeath(&siblingFallback, physicalAssets: [])
    siblingFallback = estateSessionPreparingLethalAgent(
        siblingFallback, targetID: firstSiblingID
    )
    let siblingEstate = finalizeEstateDeath(
        &siblingFallback, physicalAssets: []
    )
    check("living canonical sibling forms the tertiary fallback tier",
          siblingEstate.beneficiaryTier == .tertiarySiblings
            && siblingEstate.beneficiaries.map(\.agentID)
                == [secondSiblingID]
            && (
                siblingEstate.beneficiaries[0].basis == .fullSibling
                    || siblingEstate.beneficiaries[0].basis == .halfSibling
            ),
          "\(siblingEstate.beneficiaryTier.rawValue):"
            + siblingEstate.beneficiaries.map {
                "\($0.agentID.rawValue)/\($0.basis.rawValue)"
            }.joined(separator: ","))

    var noSuccessor = makeEstateSession(
        "civ33-no-successor", includeUnionAndChild: false
    ).0
    let noSuccessorEstate = finalizeEstateDeath(
        &noSuccessor,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    check("no eligible successor leaves physical matter dormant and undistributed",
          noSuccessorEstate.beneficiaryTier == .none
            && noSuccessorEstate.beneficiaries.isEmpty
            && noSuccessorEstate.status == .dormantNoSuccessor
            && noSuccessorEstate.assets[0].blockReason == .noSuccessor
            && noSuccessor.materialRightsSnapshot().records[0]
                .recognizedOwnership?.ownerID == estateAgentIDs[0]
            && noSuccessor.materialRightsSnapshot().records[0]
                .lastVerifiedHolder.holder == .container("0,64,0"))

    var personalPermission = makeEstateSession(
        "civ33-personal-permission",
        includeUnionAndChild: false,
        registerAsset: false
    ).0
    registerEstateAsset(
        &personalPermission,
        assetID: estateSecondAssetID,
        claimID: AgentMaterialClaimID(
            rawValue: "claim:civ33:permission-owner"
        )!,
        identity: estateSecondIdentity,
        ownerID: estateAgentIDs[1],
        holderID: estateAgentIDs[1],
        operationPrefix: "civ33-personal-permission:other-owned"
    )
    _ = try! personalPermission.applyMaterialRightsOperation(.grantUse(
        operationID: "civ33-personal-permission:grant-to-decedent",
        assetID: estateSecondAssetID,
        permissionID: AgentMaterialPermissionID(
            rawValue: "permission:civ33:personal-decedent"
        )!,
        grantorID: estateAgentIDs[1],
        userID: estateAgentIDs[0],
        allowedUses: [.toolUse],
        expiresAtTick: nil
    ))
    let personalEstate = finalizeEstateDeath(
        &personalPermission, physicalAssets: []
    )
    let otherOwned = personalPermission.materialRightsSnapshot().records.first {
        $0.asset.assetID == estateSecondAssetID
    }!
    check("personal authorized use expires without changing another owner",
          personalEstate.assets.isEmpty
            && personalEstate.obligations.isEmpty
            && otherOwned.permissions.isEmpty
            && otherOwned.recognizedOwnership?.ownerID
                == estateAgentIDs[1]
            && otherOwned.lastVerifiedHolder.holder
                == .agent(estateAgentIDs[1]))

    var replacementFixture = makeEstateSession(
        "civ33-administrator-replacement"
    ).0
    let replacementEstate = finalizeEstateDeath(
        &replacementFixture,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    _ = try! replacementFixture.acceptEstateAdministration(
        estateID: replacementEstate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-replacement:accept-first"
    )
    let survivorHousehold = try! replacementFixture.currentMembership(
        of: estateAgentIDs[1]
    )!.householdID
    try! replacementFixture.moveMembers(
        memberIDs: [estateAgentIDs[2]], to: survivorHousehold
    )
    let beneficiariesBeforeReplacement = replacementFixture
        .estateSnapshot().estates.first {
            $0.estateID == replacementEstate.estateID
        }!.beneficiaries
    replacementFixture = estateSessionPreparingLethalAgent(
        replacementFixture, targetID: estateAgentIDs[1]
    )
    _ = finalizeEstateDeath(&replacementFixture, physicalAssets: [])
    let reassignedEstate = replacementFixture.estateSnapshot().estates.first {
        $0.estateID == replacementEstate.estateID
    }!
    check("administrator death ends assignment and nominates a bounded replacement",
          reassignedEstate.administrations.count == 2
            && reassignedEstate.administrations[0].status == .ended
            && reassignedEstate.administrations[0].endedReason == .died
            && reassignedEstate.administrations[1].status == .nominated
            && reassignedEstate.administrations[1].administratorID
                == estateAgentIDs[2]
            && reassignedEstate.beneficiaries
                == beneficiariesBeforeReplacement
            && reassignedEstate.assets[0].status == .blocked
            && reassignedEstate.assets[0].blockReason
                == .beneficiaryUnavailableForCustody
            && reassignedEstate.assets[0].intendedCustodianID
                == estateAgentIDs[1])

    var incapacitatedAdministrator = makeEstateSession(
        "civ33-administrator-incapacity"
    ).0
    incapacitatedAdministrator = estateSessionWithHealth(
        incapacitatedAdministrator,
        agentID: estateAgentIDs[1],
        health: 1
    )
    let incapacityEstate = finalizeEstateDeath(
        &incapacitatedAdministrator,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    _ = try! incapacitatedAdministrator.acceptEstateAdministration(
        estateID: incapacityEstate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-administrator-incapacity:accept"
    )
    let incapacityHousehold = try! incapacitatedAdministrator
        .currentMembership(of: estateAgentIDs[1])!.householdID
    try! incapacitatedAdministrator.moveMembers(
        memberIDs: [estateAgentIDs[2]], to: incapacityHousehold
    )
    try! incapacitatedAdministrator.setHomeostasisEnabled(
        true,
        configuration: try! AgentHomeostasisConfiguration(
            ageVulnerabilityStartTicks: 1_000,
            baseHealthDamagePerTick: 1,
            healthRecoveryPerTick: 1,
            incapacityHealthThreshold: 20
        )
    )
    _ = try! incapacitatedAdministrator.advanceTick()
    let afterIncapacity = incapacitatedAdministrator
        .estateSnapshot().estates.first {
            $0.estateID == incapacityEstate.estateID
        }!
    check("administrator incapacity ends assignment without changing successors",
          incapacitatedAdministrator.vitalStatus(for: estateAgentIDs[1])
                == .incapacitated
            && afterIncapacity.administrations.count == 2
            && afterIncapacity.administrations[0].status == .ended
            && afterIncapacity.administrations[0].endedReason
                == .incapacitated
            && afterIncapacity.administrations[1].administratorID
                == estateAgentIDs[2]
            && afterIncapacity.administrations[1].status == .nominated
            && afterIncapacity.beneficiaries
                == incapacityEstate.beneficiaries)

    var orderedAssets = makeEstateSession(
        "civ33-ordered-assets", registerAsset: false
    ).0
    registerEstateAsset(
        &orderedAssets,
        assetID: estateAssetID,
        claimID: estateOwnerClaimID,
        identity: estateIdentity,
        operationPrefix: "civ33-ordered-assets:first"
    )
    registerEstateAsset(
        &orderedAssets,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        operationPrefix: "civ33-ordered-assets:second"
    )
    var reversedAssets = makeEstateSession(
        "civ33-reversed-assets", registerAsset: false
    ).0
    registerEstateAsset(
        &reversedAssets,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        operationPrefix: "civ33-reversed-assets:second"
    )
    registerEstateAsset(
        &reversedAssets,
        assetID: estateAssetID,
        claimID: estateOwnerClaimID,
        identity: estateIdentity,
        operationPrefix: "civ33-reversed-assets:first"
    )
    let orderedEstate = finalizeEstateDeath(
        &orderedAssets,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
        ]
    )
    let reversedEstate = finalizeEstateDeath(
        &reversedAssets,
        physicalAssets: [
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    let orderedAssignments = Dictionary(uniqueKeysWithValues:
        orderedEstate.assets.compactMap { entry in
            entry.materialRightsAssetID.map {
                ($0, entry.assignedBeneficiaryID)
            }
        }
    )
    let reversedAssignments = Dictionary(uniqueKeysWithValues:
        reversedEstate.assets.compactMap { entry in
            entry.materialRightsAssetID.map {
                ($0, entry.assignedBeneficiaryID)
            }
        }
    )
    check("whole-asset allocation ignores registration and input ordering",
          orderedAssignments == reversedAssignments
            && orderedEstate.beneficiaries.map(\.agentID)
                == reversedEstate.beneficiaries.map(\.agentID))

    let custodyRetryFixture = makeEstateSession(
        "civ33-custody-retry"
    )
    var custodyRetry = custodyRetryFixture.0
    let custodyRetryChildID = custodyRetryFixture.1!.newbornID
    registerEstateAsset(
        &custodyRetry,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        operationPrefix: "civ33-custody-retry:second"
    )
    let custodyRetryEstate = finalizeEstateDeath(
        &custodyRetry,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
        ]
    )
    let childEntryBefore = custodyRetryEstate.assets.first {
        $0.assignedBeneficiaryID == custodyRetryChildID
    }!
    let childHousehold = try! custodyRetry.currentMembership(
        of: custodyRetryChildID
    )!.householdID
    try! custodyRetry.moveMembers(
        memberIDs: [estateAgentIDs[2]], to: childHousehold
    )
    try! custodyRetry.reassignGuardian(
        dependentID: custodyRetryChildID,
        to: estateAgentIDs[2]
    )
    let custodyAfterGuardianChange = custodyRetry.estateSnapshot()
        .estates.first { $0.estateID == custodyRetryEstate.estateID }!
        .assets.first { $0.entryID == childEntryBefore.entryID }!
    let custodyRetryRestart = try! AgentSimulationSession.restoring(
        custodyRetry.makeCheckpoint()
    )
    check("guardian change explicitly revalidates blocked asset custody",
          childEntryBefore.intendedCustodianID != estateAgentIDs[2]
            && custodyAfterGuardianChange.intendedCustodianID
                == estateAgentIDs[2]
            && custodyAfterGuardianChange.status == .pendingSettlement
            && custodyAfterGuardianChange.blockReason == nil
            && custodyAfterGuardianChange.custodyRevalidationEventID != nil
            && custodyAfterGuardianChange.settlementAttemptCount == 0
            && custodyRetryRestart.estateSnapshot()
                == custodyRetry.estateSnapshot())

    var multipleAssets = makeEstateSession(
        "civ33-multiple-assets"
    ).0
    registerEstateAsset(
        &multipleAssets,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        operationPrefix: "civ33-multiple-assets:second"
    )
    let multipleEstate = finalizeEstateDeath(
        &multipleAssets,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
        ]
    )
    _ = try! multipleAssets.acceptEstateAdministration(
        estateID: multipleEstate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-multiple-assets:accept"
    )
    let multipleEntries = multipleEstate.assets.filter {
        $0.status == .pendingSettlement
    }.sorted { $0.entryID < $1.entryID }
    _ = try! multipleAssets.applyEstatePhysicalSettlement(
        estateSettlementOutcome(
            session: multipleAssets,
            estate: multipleEstate,
            entry: multipleEntries[0],
            operationID: "civ33-multiple-assets:settle-first",
            sourceFingerprintAfterTransfer:
                "civ33-multiple-assets:source-after-first",
            destinationFingerprintBeforeTransfer:
                "civ33-multiple-assets:destination-before-first",
            destinationFingerprintAfterTransfer:
                "civ33-multiple-assets:destination-after-first"
        )
    )
    let partialMultipleCheckpoint = try! multipleAssets.makeCheckpoint()
    var restartedMultiple = try! AgentSimulationSession.restoring(
        partialMultipleCheckpoint
    )
    let restartedMultipleEstate = restartedMultiple.estateSnapshot()
        .estates.first { $0.estateID == multipleEstate.estateID }!
    let unresolvedMultipleEntry = restartedMultipleEstate.assets.first {
        $0.status == .pendingSettlement
    }!
    let unresolvedMultipleRights = restartedMultiple
        .materialRightsSnapshot().records.first {
            $0.asset.assetID
                == unresolvedMultipleEntry.materialRightsAssetID
        }!
    check("partial whole-asset settlement restarts at the unresolved asset",
          restartedMultipleEstate.status == .partiallySettled
            && restartedMultipleEstate.assets.filter {
                $0.status == .transferred
            }.count == 1
            && restartedMultipleEstate.assets.filter {
                $0.status == .pendingSettlement
            }.count == 1
            && unresolvedMultipleRights.lastVerifiedHolder
                .custodyFingerprint
                == "civ33-multiple-assets:source-after-first"
            && restartedMultiple.estateSnapshot().totalSettlementCount == 0)
    _ = try! restartedMultiple.applyEstatePhysicalSettlement(
        estateSettlementOutcome(
            session: restartedMultiple,
            estate: restartedMultipleEstate,
            entry: unresolvedMultipleEntry,
            operationID: "civ33-multiple-assets:settle-second",
            sourceFingerprintAfterTransfer:
                "civ33-multiple-assets:source-after-second",
            destinationFingerprintBeforeTransfer:
                "civ33-multiple-assets:destination-after-first",
            destinationFingerprintAfterTransfer:
                "civ33-multiple-assets:destination-after-second"
        )
    )
    let completedMultipleCheckpoint = try! restartedMultiple.makeCheckpoint()
    let completedMultiple = try! AgentSimulationSession.restoring(
        completedMultipleCheckpoint
    )
    let completedMultipleEstate = completedMultiple.estateSnapshot()
        .estates.first { $0.estateID == multipleEstate.estateID }!
    check("multiple physical assets settle once with refreshed endpoint proofs",
          completedMultipleEstate.status == .settled
            && completedMultipleEstate.assets.allSatisfy {
                $0.status == .transferred
                    && $0.settlementAttemptCount == 1
            }
            && completedMultiple.estateSnapshot().totalSettlementCount == 1
            && Set(completedMultipleEstate.assets.compactMap(
                \.settlementReceiptID
            )).count == 2)

    var partialBlocked = makeEstateSession(
        "civ33-partial-blocked"
    ).0
    registerEstateAsset(
        &partialBlocked,
        assetID: estateSecondAssetID,
        claimID: estateSecondOwnerClaimID,
        identity: estateSecondIdentity,
        operationPrefix: "civ33-partial-blocked:second"
    )
    _ = try! partialBlocked.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ33-partial-blocked:third-party-claim",
        assetID: estateSecondAssetID,
        claimID: AgentMaterialClaimID(
            rawValue: "claim:civ33:partial-third-party"
        )!,
        claimantID: estateAgentIDs[2],
        basis: .contested
    ))
    let partialBlockedEstate = finalizeEstateDeath(
        &partialBlocked,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 1
            ),
        ]
    )
    _ = try! partialBlocked.acceptEstateAdministration(
        estateID: partialBlockedEstate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-partial-blocked:accept"
    )
    let transferablePartialEntry = partialBlockedEstate.assets.first {
        $0.status == .pendingSettlement
    }!
    _ = try! partialBlocked.applyEstatePhysicalSettlement(
        estateSettlementOutcome(
            session: partialBlocked,
            estate: partialBlockedEstate,
            entry: transferablePartialEntry,
            operationID: "civ33-partial-blocked:settle",
            sourceFingerprintAfterTransfer:
                "civ33-partial-blocked:source-after",
            destinationFingerprintBeforeTransfer:
                "civ33-partial-blocked:destination-before",
            destinationFingerprintAfterTransfer:
                "civ33-partial-blocked:destination-after"
        )
    )
    let restartedPartialBlocked = try! AgentSimulationSession.restoring(
        partialBlocked.makeCheckpoint()
    )
    let persistedPartialBlocked = restartedPartialBlocked
        .estateSnapshot().estates.first {
            $0.estateID == partialBlockedEstate.estateID
        }!
    check("blocked second asset survives partial settlement and restart",
          persistedPartialBlocked.status == .partiallySettled
            && persistedPartialBlocked.assets.filter {
                $0.status == .transferred
            }.count == 1
            && persistedPartialBlocked.assets.filter {
                $0.status == .blocked
                    && $0.blockReason == .thirdPartyClaim
            }.count == 1
            && restartedPartialBlocked.estateSnapshot()
                .totalSettlementCount == 0)
    var partialAdministratorLoss = estateSessionWithHealth(
        partialBlocked, agentID: estateAgentIDs[1], health: 1
    )
    try! partialAdministratorLoss.setHomeostasisEnabled(
        true,
        configuration: try! AgentHomeostasisConfiguration(
            ageVulnerabilityStartTicks: 1_000,
            baseHealthDamagePerTick: 1,
            healthRecoveryPerTick: 1,
            incapacityHealthThreshold: 20
        )
    )
    _ = try! partialAdministratorLoss.advanceTick()
    let partialAfterAdministratorLoss = partialAdministratorLoss
        .estateSnapshot().estates.first {
            $0.estateID == partialBlockedEstate.estateID
        }!
    let partialLossRestart = try! AgentSimulationSession.restoring(
        partialAdministratorLoss.makeCheckpoint()
    )
    check("administrator loss preserves partially settled material truth",
          partialAfterAdministratorLoss.status == .partiallySettled
            && partialAfterAdministratorLoss.assets.contains {
                $0.status == .transferred
            }
            && partialAfterAdministratorLoss.assets.contains {
                $0.status == .blocked
                    && $0.blockReason == .thirdPartyClaim
            }
            && partialLossRestart.estateSnapshot()
                == partialAdministratorLoss.estateSnapshot())

    var unregisteredResidual = makeEstateSession(
        "civ33-unregistered-residual",
        registerAsset: false
    ).0
    let residualEstate = finalizeEstateDeath(
        &unregisteredResidual,
        physicalAssets: [
            AgentMaterialStackSnapshot(
                identity: estateSecondIdentity, count: 2
            ),
        ]
    )
    check("unregistered physical matter is conserved and blocked socially",
          residualEstate.assets.count == 1
            && residualEstate.assets[0].materialRightsAssetID == nil
            && residualEstate.assets[0].quantity == 2
            && residualEstate.assets[0].status == .blocked
            && residualEstate.assets[0].blockReason
                == .sociallyUnregistered
            && residualEstate.status == .blocked
            && unregisteredResidual.materialRightsSnapshot().records.isEmpty)

    var disputed = makeEstateSession(
        "civ33-disputed",
        thirdPartyClaim: true
    ).0
    let disputedEstate = finalizeEstateDeath(
        &disputed,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    check("third-party claim remains durable and blocks succession",
          disputedEstate.assets[0].status == .blocked
            && disputedEstate.assets[0].blockReason == .thirdPartyClaim
            && disputed.materialRightsSnapshot().records[0].claims.count == 2
            && disputedEstate.status == .blocked)
    let disputedSurvivorHousehold = try! disputed.currentMembership(
        of: estateAgentIDs[1]
    )!.householdID
    try! disputed.moveMembers(
        memberIDs: [estateAgentIDs[2]], to: disputedSurvivorHousehold
    )
    _ = try! disputed.acceptEstateAdministration(
        estateID: disputedEstate.estateID,
        administratorID: estateAgentIDs[1],
        operationID: "civ33-disputed:accept"
    )
    disputed = estateSessionWithHealth(
        disputed, agentID: estateAgentIDs[1], health: 1
    )
    try! disputed.setHomeostasisEnabled(
        true,
        configuration: try! AgentHomeostasisConfiguration(
            ageVulnerabilityStartTicks: 1_000,
            baseHealthDamagePerTick: 1,
            healthRecoveryPerTick: 1,
            incapacityHealthThreshold: 20
        )
    )
    _ = try! disputed.advanceTick()
    let blockedAfterAdministratorLoss = disputed.estateSnapshot()
        .estates.first { $0.estateID == disputedEstate.estateID }!
    let blockedLossRestart = try! AgentSimulationSession.restoring(
        disputed.makeCheckpoint()
    )
    check("administrator loss preserves blocked material truth",
          blockedAfterAdministratorLoss.status == .blocked
            && blockedAfterAdministratorLoss.assets[0].blockReason
                == .thirdPartyClaim
            && blockedAfterAdministratorLoss.administrations.last?
                .administratorID == estateAgentIDs[2]
            && blockedAfterAdministratorLoss.administrations.last?.status
                == .nominated
            && blockedLossRestart.estateSnapshot()
                == disputed.estateSnapshot())

    var dormant = makeEstateSession(
        "civ33-dormant-no-successor",
        includeUnionAndChild: false
    ).0
    let dormantEstate = finalizeEstateDeath(
        &dormant,
        physicalAssets: [
            AgentMaterialStackSnapshot(identity: estateIdentity, count: 1),
        ]
    )
    _ = try! dormant.advanceTick()
    let dormantRestart = try! AgentSimulationSession.restoring(
        dormant.makeCheckpoint()
    )
    check("dormant estate never reopens when no successor exists",
          dormantEstate.status == .dormantNoSuccessor
            && dormant.estateSnapshot().estates[0].status
                == .dormantNoSuccessor
            && dormantRestart.estateSnapshot()
                == dormant.estateSnapshot())

    let settledCheckpoint = try! session.makeCheckpoint()
    check("checkpoint refuses missing estate authority", estateRestoreRefused(
        settledCheckpoint
    ) { $0.removeValue(forKey: "estateState") })
    check("checkpoint refuses duplicate estate for one death",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              estates.append(estates[0])
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses nonpositive estate asset quantity",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var assets = estates[0]["assets"] as! [[String: Any]]
              assets[0]["quantity"] = 0
              estates[0]["assets"] = assets
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses transferred asset with stale owner",
          estateRestoreRefused(settledCheckpoint) { durable in
              var rights = durable["materialRightsState"] as! [String: Any]
              var records = rights["records"] as! [[String: Any]]
              var ownership = records[0]["recognizedOwnership"]
                  as! [String: Any]
              ownership["ownerID"] = estateAgentIDs[0].rawValue
              records[0]["recognizedOwnership"] = ownership
              rights["records"] = records
              durable["materialRightsState"] = rights
          })
    check("checkpoint refuses settled estate with blocked asset",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var assets = estates[0]["assets"] as! [[String: Any]]
              assets[0]["status"] = AgentEstateAssetStatus.blocked.rawValue
              assets[0]["blockReason"] =
                  AgentEstateAssetBlockReason.ownerConflict.rawValue
              estates[0]["assets"] = assets
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses estate bound to a different death",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              estates[0]["deathID"] =
                  "death-agent_2-t0-0000000000000001"
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses beneficiary without canonical relation",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var beneficiaries =
                  estates[0]["beneficiaries"] as! [[String: Any]]
              beneficiaries[0]["agentID"] = estateAgentIDs[2].rawValue
              estates[0]["beneficiaries"] = beneficiaries
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses a successor tier changed after planning",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              proof["selectedTier"] =
                  AgentEstateBeneficiaryTier.secondaryParents.rawValue
              estates[0]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses removing an eligible successor proof row",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              rows.removeFirst()
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses adding a plausible person to the wrong tier",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              var extra = rows[0]
              extra["agentID"] = estateAgentIDs[2].rawValue
              extra["tier"] =
                  AgentEstateBeneficiaryTier.secondaryParents.rawValue
              extra["basis"] =
                  AgentEstateBeneficiaryBasis.canonicalParent.rawValue
              rows.append(extra)
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses changed successor life stage evidence",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              let childIndex = rows.firstIndex {
                  $0["basis"] as? String
                    == AgentEstateBeneficiaryBasis.canonicalChild.rawValue
              }!
              rows[childIndex]["lifeStageAtPlan"] =
                  AgentLifeStage.mature.rawValue
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses changed successor guardian evidence",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var proof = estates[0]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              let childIndex = rows.firstIndex {
                  $0["basis"] as? String
                    == AgentEstateBeneficiaryBasis.canonicalChild.rawValue
              }!
              rows[childIndex]["guardianIDAtPlan"] =
                  estateAgentIDs[2].rawValue
              proof["eligibilityRows"] = rows
              estates[0]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("post-eviction checkpoint still rejects successor-plan corruption",
          estateRestoreRefused(coordinatedCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              let target = estates.firstIndex {
                  ($0["estateID"] as? String)
                    == retainedB.estateID.rawValue
              }!
              var proof = estates[target]["successorPlanProof"]
                  as! [String: Any]
              var rows = proof["eligibilityRows"] as! [[String: Any]]
              let eligibleIndex = rows.firstIndex {
                  $0["eligibleAtDeath"] as? Bool == true
              }!
              rows.remove(at: eligibleIndex)
              proof["eligibilityRows"] = rows
              estates[target]["successorPlanProof"] = proof
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses successor plan event from another estate",
          estateRestoreRefused(coordinatedCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              let firstEvent = estates[0]["successorPlanEventID"]!
              var proof = estates[1]["successorPlanProof"]
                  as! [String: Any]
              proof["successorPlanEventID"] = firstEvent
              estates[1]["successorPlanProof"] = proof
              estates[1]["successorPlanEventID"] = firstEvent
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses modified retained successor-plan payload",
          estateRestoreRefused(settledCheckpoint) { durable in
              var ledger = durable["causalLedger"] as! [String: Any]
              var events = ledger["events"] as! [[String: Any]]
              let index = events.firstIndex {
                  $0["kind"] as? String
                    == AgentCausalEventKind
                        .estateSuccessorPlanCreated.rawValue
              }!
              var payload = events[index]["payload"] as! [String: Any]
              var operation = payload["operation"] as! [String: Any]
              operation["detail"] = "corrupt-successor-plan"
              payload["operation"] = operation
              events[index]["payload"] = payload
              estateRepairOperationEventDigest(&events[index])
              ledger["events"] = events
              durable["causalLedger"] = ledger
              estateRecomputeCausalRollingDigest(&durable)
          })
    check("checkpoint refuses modified retained successor-plan causes",
          estateRestoreRefused(settledCheckpoint) { durable in
              var ledger = durable["causalLedger"] as! [String: Any]
              var events = ledger["events"] as! [[String: Any]]
              let index = events.firstIndex {
                  $0["kind"] as? String
                    == AgentCausalEventKind
                        .estateSuccessorPlanCreated.rawValue
              }!
              var causes = events[index]["causes"] as! [[String: Any]]
              causes.removeLast()
              events[index]["causes"] = causes
              estateRepairOperationEventDigest(&events[index])
              ledger["events"] = events
              durable["causalLedger"] = ledger
              estateRecomputeCausalRollingDigest(&durable)
          })
    check("checkpoint refuses juvenile estate administrator",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var administrations =
                  estates[0]["administrations"] as! [[String: Any]]
              administrations[0]["lifeStageAtNomination"] =
                  AgentLifeStage.juvenile.rawValue
              estates[0]["administrations"] = administrations
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses acceptance attributed to the wrong agent",
          estateRestoreRefused(settledCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var administrations =
                  estates[0]["administrations"] as! [[String: Any]]
              administrations[0]["administratorID"] =
                  estateAgentIDs[2].rawValue
              estates[0]["administrations"] = administrations
              state["estates"] = estates
              durable["estateState"] = state
          })
    check("checkpoint refuses a reused physical settlement receipt",
          estateRestoreRefused(completedMultipleCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var assets = estates[0]["assets"] as! [[String: Any]]
              let receipts = assets.compactMap {
                  $0["settlementReceiptID"] as? String
              }
              assets[1]["settlementReceiptID"] = receipts[0]
              estates[0]["assets"] = assets
              state["estates"] = estates
              durable["estateState"] = state
          })
    let multipleMinorID = multipleEstate.beneficiaries.first {
        $0.basis == .canonicalChild
    }!.agentID
    check("checkpoint refuses transforming a minor custodian into owner",
          estateRestoreRefused(completedMultipleCheckpoint) { durable in
              var rights = durable["materialRightsState"]
                  as! [String: Any]
              var records = rights["records"] as! [[String: Any]]
              for index in records.indices {
                  guard var ownership = records[index][
                    "recognizedOwnership"
                  ] as? [String: Any],
                  ownership["ownerID"] as? String
                    == multipleMinorID.rawValue else { continue }
                  ownership["ownerID"] = estateAgentIDs[1].rawValue
                  records[index]["recognizedOwnership"] = ownership
              }
              rights["records"] = records
              durable["materialRightsState"] = rights
          })
    let disputedCheckpoint = try! disputed.makeCheckpoint()
    check("checkpoint refuses deletion of a retained third-party claim",
          estateRestoreRefused(disputedCheckpoint) { durable in
              var rights = durable["materialRightsState"]
                  as! [String: Any]
              var records = rights["records"] as! [[String: Any]]
              var claims = records[0]["claims"] as! [[String: Any]]
              claims.removeAll {
                  $0["claimantID"] as? String
                    == estateAgentIDs[2].rawValue
              }
              records[0]["claims"] = claims
              rights["records"] = records
              durable["materialRightsState"] = rights
          })
    check("checkpoint refuses an unresolved asset with changed holder facts",
          estateRestoreRefused(openCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              var assets = estates[0]["assets"] as! [[String: Any]]
              var holder = assets[0]["holderAtOpening"]
                  as! [String: Any]
              holder["quantity"] = 2
              assets[0]["holderAtOpening"] = holder
              estates[0]["assets"] = assets
              state["estates"] = estates
              durable["estateState"] = state
          })
    let replacementCheckpoint = try! replacementFixture.makeCheckpoint()
    check("checkpoint refuses retaining a dead administrator as active",
          estateRestoreRefused(replacementCheckpoint) { durable in
              var state = durable["estateState"] as! [String: Any]
              var estates = state["estates"] as! [[String: Any]]
              let target = estates.firstIndex {
                  ($0["decedentID"] as? String)
                    == estateAgentIDs[0].rawValue
              }!
              var administrations =
                  estates[target]["administrations"] as! [[String: Any]]
              administrations[0]["status"] =
                  AgentEstateAdministrationStatus.active.rawValue
              administrations[0].removeValue(forKey: "endedAtTick")
              administrations[0].removeValue(forKey: "endedReason")
              administrations[0].removeValue(forKey: "endedEventID")
              estates[target]["administrations"] = administrations
              state["estates"] = estates
              durable["estateState"] = state
          })
}
