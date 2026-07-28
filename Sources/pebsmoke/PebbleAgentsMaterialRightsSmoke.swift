import Foundation
import PebbleAgents

private func rightsAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "rights fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func rightsSession(
    _ id: String = "civ26-rights",
    configuration rightsConfiguration: AgentMaterialRightsConfiguration = .live
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46, memoryPolicy: .bounded(maxEntries: 128)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            rightsAgent("agent_0", x: 0),
            rightsAgent("agent_1", x: 1),
            rightsAgent("agent_2", x: 2),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setMaterialRightsEnabled(true, configuration: rightsConfiguration)
    return session
}

private let rightsAssetID = AgentMaterialAssetID(rawValue: "asset:iron_pickaxe:1")!
private let rightsClaim0 = AgentMaterialClaimID(rawValue: "claim:agent_0:1")!
private let rightsClaim2 = AgentMaterialClaimID(rawValue: "claim:agent_2:1")!
private let rightsPermission1 = AgentMaterialPermissionID(rawValue: "permission:agent_1:1")!

private func rightsIdentity(damage: Int = 0) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: "iron_pickaxe",
        damage: damage,
        enchantments: [],
        label: nil,
        canonicalDataJSON: "{}"
    )
}

private func rightsObservation(
    holder: String,
    receipt: String,
    fingerprint: String,
    damage: Int = 0
) -> AgentMaterialHolderObservation {
    AgentMaterialHolderObservation(
        holder: .agent(AgentID(rawValue: holder)!),
        materialIdentity: rightsIdentity(damage: damage),
        quantity: 1,
        custodyFingerprint: fingerprint,
        physicalReceiptID: receipt,
        observedAtTick: 0
    )
}

private func rightsBootstrap(_ session: inout AgentSimulationSession) {
    let initial = rightsObservation(
        holder: "agent_0", receipt: "receipt:register", fingerprint: "agent0:pickaxe"
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "rights:register",
        asset: AgentMaterialAssetReference(
            assetID: rightsAssetID,
            materialIdentity: rightsIdentity(),
            quantity: 1
        ),
        observation: initial
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:claim:0",
        assetID: rightsAssetID,
        claimID: rightsClaim0,
        claimantID: AgentID(rawValue: "agent_0")!,
        basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "rights:recognize:0",
        assetID: rightsAssetID,
        claimID: rightsClaim0,
        recognizingAgentIDs: [
            AgentID(rawValue: "agent_0")!,
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ]
    ))
}

private func rightsDecision(
    _ session: AgentSimulationSession,
    actor: String,
    holder: AgentMaterialHolderObservation,
    requestID: String,
    use: AgentMaterialUseKind = .transferCustody
) -> AgentMaterialUseDecision {
    session.evaluateMaterialUse(AgentMaterialUseRequest(
        requestID: requestID,
        assetID: rightsAssetID,
        actorID: AgentID(rawValue: actor)!,
        use: use,
        verifiedHolder: holder
    ))
}

func runPebbleAgentsMaterialRightsSmoke() {
    section("CIV-26 possession, custody, claims, and use rights")

    let noLedgerConfiguration = try! AgentSessionConfiguration(
        seed: 46, memoryPolicy: .bounded(maxEntries: 32)
    )
    var noLedger = try! AgentSimulationSession(
        configuration: noLedgerConfiguration,
        agents: [rightsAgent("agent_0", x: 0)]
    )
    check("rights activation requires causal ledger", {
        do {
            try noLedger.setMaterialRightsEnabled(true)
            return false
        } catch AgentSessionError.materialRights(.causalLedgerRequired) {
            return true
        } catch {
            return false
        }
    }())

    var session = rightsSession()
    rightsBootstrap(&session)
    var record = session.materialRightsSnapshot().records[0]
    let ownerObservation = record.lastVerifiedHolder
    let ownerDecision = rightsDecision(
        session, actor: "agent_0", holder: ownerObservation, requestID: "use:owner"
    )
    check("aligned physical holder and recognized owner allowed",
          ownerDecision.verdict == .allowed && ownerDecision.reason == .recognizedOwner)
    check("recognition scope remains explicit and local",
          record.recognizedOwnership?.recognizingAgentIDs.map(\.rawValue)
            == ["agent_0", "agent_1", "agent_2"])

    let borrowerObservation = rightsObservation(
        holder: "agent_1", receipt: "receipt:loan", fingerprint: "agent1:pickaxe"
    )
    _ = try! session.applyMaterialRightsOperation(.physicalTransfer(
        AgentMaterialPhysicalTransferOutcome(
            operationID: "rights:loan:transfer",
            decision: ownerDecision,
            disposition: .authorized,
            status: .succeeded,
            destinationObservation: borrowerObservation,
            physicalReceiptID: "receipt:loan"
        )
    ))
    _ = try! session.applyMaterialRightsOperation(.delegateCustody(
        operationID: "rights:loan:custody",
        assetID: rightsAssetID,
        custodianID: AgentID(rawValue: "agent_1")!,
        actorID: AgentID(rawValue: "agent_0")!
    ))
    record = session.materialRightsSnapshot().records[0]
    check("loan separates holder custodian and owner",
          record.lastVerifiedHolder.holder == .agent(AgentID(rawValue: "agent_1")!)
            && record.custodianID?.rawValue == "agent_1"
            && record.recognizedOwnership?.ownerID.rawValue == "agent_0"
            && record.claims.map(\.claimantID.rawValue) == ["agent_0"])

    let deniedBorrower = rightsDecision(
        session, actor: "agent_1", holder: borrowerObservation,
        requestID: "use:borrower:denied"
    )
    let rolesBeforeDenial = session.materialRightsSnapshot().records
    _ = try! session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "rights:borrower:denied",
            decision: deniedBorrower,
            status: .notAttempted,
            resultingObservation: nil,
            physicalReceiptID: nil
        )
    ))
    check("custody alone grants no use right",
          deniedBorrower.verdict == .denied && deniedBorrower.reason == .noUseRight)
    check("denied use invents no physical result",
          session.materialRightsSnapshot().records == rolesBeforeDenial)

    _ = try! session.applyMaterialRightsOperation(.grantUse(
        operationID: "rights:grant:borrower",
        assetID: rightsAssetID,
        permissionID: rightsPermission1,
        grantorID: AgentID(rawValue: "agent_0")!,
        userID: AgentID(rawValue: "agent_1")!,
        allowedUses: [.transferCustody, .toolUse],
        expiresAtTick: nil
    ))
    let allowedBorrower = rightsDecision(
        session, actor: "agent_1", holder: borrowerObservation,
        requestID: "use:borrower:allowed"
    )
    check("explicit bounded permission authorizes real attempt",
          allowedBorrower.verdict == .allowed
            && allowedBorrower.reason == .explicitPermission)

    let theftRequest = AgentMaterialUseRequest(
        requestID: "use:agent_2:take",
        assetID: rightsAssetID,
        actorID: AgentID(rawValue: "agent_2")!,
        use: .transferCustody,
        verifiedHolder: borrowerObservation
    )
    let theftDecision = session.evaluateMaterialUse(theftRequest)
    let thiefObservation = rightsObservation(
        holder: "agent_2", receipt: "receipt:unauthorized-take",
        fingerprint: "agent2:pickaxe"
    )
    _ = try! session.applyMaterialRightsOperation(.physicalTransfer(
        AgentMaterialPhysicalTransferOutcome(
            operationID: "rights:unauthorized:take",
            decision: theftDecision,
            disposition: .observedTransgression,
            status: .succeeded,
            destinationObservation: thiefObservation,
            physicalReceiptID: "receipt:unauthorized-take"
        )
    ))
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:claim:2",
        assetID: rightsAssetID,
        claimID: rightsClaim2,
        claimantID: AgentID(rawValue: "agent_2")!,
        basis: .contested
    ))
    record = session.materialRightsSnapshot().records[0]
    check("unauthorized take changes observed holder only",
          theftDecision.verdict == .denied
            && record.lastVerifiedHolder.holder == .agent(AgentID(rawValue: "agent_2")!)
            && record.custodianID?.rawValue == "agent_1"
            && record.recognizedOwnership?.ownerID.rawValue == "agent_0")
    check("prior and competing claims coexist as conflict",
          record.claims.map(\.claimantID.rawValue) == ["agent_0", "agent_2"]
            && record.hasConflict && session.materialRightsSnapshot().conflictCount == 1)

    let rollbackDecision = rightsDecision(
        session, actor: "agent_2", holder: thiefObservation,
        requestID: "use:thief:rollback"
    )
    let rolesBeforeRollback = session.materialRightsSnapshot().records
    let rollbackOperation = AgentMaterialRightsOperation.physicalTransfer(
        AgentMaterialPhysicalTransferOutcome(
            operationID: "rights:transfer:rollback",
            decision: rollbackDecision,
            disposition: .observedTransgression,
            status: .rolledBack,
            destinationObservation: nil,
            physicalReceiptID: "receipt:rolled-back"
        )
    )
    let rollbackApplied = try! session.applyMaterialRightsOperation(rollbackOperation)
    let rollbackDuplicate = try! session.applyMaterialRightsOperation(rollbackOperation)
    check("rolled-back transfer publishes no false roles",
          rollbackApplied.status == .applied
            && session.materialRightsSnapshot().records == rolesBeforeRollback)
    check("material operation idempotence is explicit",
          rollbackDuplicate.status == .duplicate)

    let checkpoint = try! session.makeCheckpoint()
    let checkpointBytesA = try! AgentCheckpointCodec.encode(checkpoint)
    let checkpointBytesB = try! AgentCheckpointCodec.encode(try! session.makeCheckpoint())
    let restored = try! AgentSimulationSession.restoring(
        try! AgentCheckpointCodec.decode(AgentSessionCheckpoint.self, from: checkpointBytesA)
    )
    check("rights checkpoint schema v19", checkpoint.schemaVersion == 19)
    check("rights checkpoint bytes deterministic", checkpointBytesA == checkpointBytesB)
    check("rights checkpoint restores roles exactly",
          restored.materialRightsSnapshot() == session.materialRightsSnapshot())
    check("rights checkpoint restores durable bytes exactly",
          try! restored.durableStateBytes() == session.durableStateBytes())

    var replaySession = try! AgentSimulationSession(
        configuration: noLedgerConfiguration,
        agents: [
            rightsAgent("agent_0", x: 0),
            rightsAgent("agent_1", x: 1),
            rightsAgent("agent_2", x: 2),
        ],
        simulationID: try! AgentSimulationID(validating: "civ26-rights-replay"),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    let replayBase = try! replaySession.makeCheckpoint()
    var recorder = try! AgentReplayRecorder(
        checkpoint: replayBase, session: replaySession
    )
    _ = try! recorder.apply(
        .setMaterialRightsEnabled(true, configuration: .live),
        to: &replaySession
    )
    let replayObservation = rightsObservation(
        holder: "agent_0", receipt: "receipt:replay-register",
        fingerprint: "agent0:replay"
    )
    _ = try! recorder.apply(.applyMaterialRightsOperation(.register(
        operationID: "rights:replay:register",
        asset: AgentMaterialAssetReference(
            assetID: rightsAssetID, materialIdentity: rightsIdentity(), quantity: 1
        ),
        observation: replayObservation
    )), to: &replaySession)
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ26-rights")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: replayBase, journal: journal
    )
    check("rights replay schema v19", journal.manifest.schemaVersion == 19)
    check("rights replay operations are typed",
          journal.records.map(\.operationKind)
            == [.materialRightsFeature, .materialRightsOperation])
    check("rights replay verifies exact digest", replayed.report.verified
        && replayed.report.finalSemanticDigest
            == (try! replaySession.durableStateDigest()))

    let boundedConfiguration = try! AgentMaterialRightsConfiguration(
        maximumAssets: 1,
        maximumClaimsPerAsset: 2,
        maximumPermissionsPerAsset: 1,
        maximumRecognitionWitnesses: 3,
        maximumRetainedTransitions: 3,
        maximumProcessedOperationIDs: 8
    )
    var bounded = rightsSession("civ26-rights-bounds", configuration: boundedConfiguration)
    rightsBootstrap(&bounded)
    _ = try! bounded.applyMaterialRightsOperation(.assertClaim(
        operationID: "rights:bounds:second",
        assetID: rightsAssetID,
        claimID: rightsClaim2,
        claimantID: AgentID(rawValue: "agent_2")!,
        basis: .contested
    ))
    let boundedBefore = try! bounded.durableStateDigest()
    let thirdClaim = AgentMaterialClaimID(rawValue: "claim:agent_1:third")!
    check("active claim bound refuses overflow", {
        do {
            _ = try bounded.applyMaterialRightsOperation(.assertClaim(
                operationID: "rights:bounds:third",
                assetID: rightsAssetID,
                claimID: thirdClaim,
                claimantID: AgentID(rawValue: "agent_1")!,
                basis: .contested
            ))
            return false
        } catch AgentSessionError.materialRights(.claimLimitReached) {
            return true
        } catch {
            return false
        }
    }())
    check("bound refusal is atomic", try! bounded.durableStateDigest() == boundedBefore)
    check("transition history remains bounded with eviction",
          bounded.materialRightsSnapshot().recentTransitions.count == 3
            && bounded.materialRightsSnapshot().droppedTransitionCount > 0)
}
