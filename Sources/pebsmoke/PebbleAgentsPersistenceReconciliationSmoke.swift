import Foundation
import PebbleAgents

private let reconciliationAssetID = AgentMaterialAssetID(
    rawValue: "asset:civ27:iron-pickaxe"
)!

private func reconciliationAgent(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id, state: "idle", position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "CIV-27 fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func reconciliationIdentity(damage: Int = 0)
    -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: "iron_pickaxe",
        damage: damage,
        enchantments: [],
        label: "CIV-27 durable tool",
        canonicalDataJSON: "{}"
    )
}

private func reconciliationObservation(
    holder: AgentMaterialPhysicalHolder,
    fingerprint: String,
    receipt: String,
    damage: Int = 0,
    tick: Int = 0
) -> AgentMaterialHolderObservation {
    AgentMaterialHolderObservation(
        holder: holder,
        materialIdentity: reconciliationIdentity(damage: damage),
        quantity: 1,
        custodyFingerprint: fingerprint,
        physicalReceiptID: receipt,
        observedAtTick: tick
    )
}

private func reconciliationSession(
    _ id: String = "civ27-persistence-reconciliation"
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [
            reconciliationAgent("agent_0", x: 0),
            reconciliationAgent("agent_1", x: 1),
            reconciliationAgent("agent_2", x: 2),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setMaterialRightsEnabled(true)
    let saved = reconciliationObservation(
        holder: .container("12,64,-4"),
        fingerprint: #"{"locationID":"container:12,64,-4","slots":["pickaxe"]}"#,
        receipt: "save:container-a"
    )
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "civ27:register",
        asset: AgentMaterialAssetReference(
            assetID: reconciliationAssetID,
            materialIdentity: reconciliationIdentity(),
            quantity: 1
        ),
        observation: saved
    ))
    let claim = AgentMaterialClaimID(rawValue: "claim:civ27:owner")!
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ27:claim",
        assetID: reconciliationAssetID,
        claimID: claim,
        claimantID: AgentID(rawValue: "agent_0")!,
        basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "civ27:recognize",
        assetID: reconciliationAssetID,
        claimID: claim,
        recognizingAgentIDs: [
            AgentID(rawValue: "agent_0")!,
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ]
    ))
    _ = try! session.applyMaterialRightsOperation(.grantUse(
        operationID: "civ27:permission",
        assetID: reconciliationAssetID,
        permissionID: AgentMaterialPermissionID(rawValue: "permission:civ27:borrower")!,
        grantorID: AgentID(rawValue: "agent_0")!,
        userID: AgentID(rawValue: "agent_1")!,
        allowedUses: [.toolUse],
        expiresAtTick: nil
    ))
    try! session.setAutonomousActivityEnabled(true)
    _ = try! session.selectAutonomousActivities([
        AgentAutonomousActivityCandidate(
            candidateID: "civ27-durable-activity",
            actorID: AgentID(rawValue: "agent_1")!,
            domain: .construction,
            actionKey: "toolUse",
            stableReference: "container:12,64,-4",
            target: AgentPosition(x: 12, y: 64, z: -4),
            materialFingerprint: "iron_pickaxe:0",
            source: .commitment,
            priorityBand: 20,
            urgency: 60,
            distance: 1,
            observedAtTick: 0
        ),
    ])
    try! session.setPersistenceReconciliationEnabled(true)
    return session
}

private let reconciliationWorld = AgentPersistenceWorldIdentity(
    worldID: "world-civ27",
    storageIdentity: "sqlite-world:world-civ27",
    seed: 46,
    dimension: 0
)

private func reconciliationBinding(
    session: AgentSimulationSession,
    checkpoint: AgentSessionCheckpoint,
    candidateHolders: [AgentMaterialPhysicalHolder] = [
        .container("12,64,-4"),
        .container("13,64,-4"),
    ]
) -> AgentPersistenceReconciliationBinding {
    let record = session.materialRightsSnapshot().records[0]
    return AgentPersistenceReconciliationBinding(
        world: reconciliationWorld,
        checkpointID: checkpoint.checkpointID,
        simulationID: checkpoint.simulationID,
        checkpointTick: checkpoint.tick,
        causalSequence: session.causalLedgerSnapshot().summary.latestSequence,
        assets: [
            AgentPersistenceAssetExpectation(
                asset: record.asset,
                savedObservation: record.lastVerifiedHolder,
                candidateHolders: candidateHolders
            ),
        ]
    )
}

private func reconciliationRequest(
    runID: String,
    binding: AgentPersistenceReconciliationBinding,
    observations: [AgentMaterialHolderObservation],
    policy: AgentPersistenceInterruptedActivityPolicy = .revalidateThenResume,
    world: AgentPersistenceWorldIdentity = reconciliationWorld
) -> AgentPersistenceReconciliationRequest {
    AgentPersistenceReconciliationRequest(
        runID: runID,
        binding: binding,
        restoredWorld: world,
        observedWorldTick: 1200,
        assetObservations: [
            AgentPersistenceAssetObservationSet(
                assetID: reconciliationAssetID,
                observations: observations
            ),
        ],
        activityResolutions: [
            AgentPersistenceActivityResolution(
                activityID: "activity:1:agent_1:civ27-durable-activity",
                actorID: AgentID(rawValue: "agent_1")!,
                policy: policy,
                reason: policy.keepsActivityActive
                    ? "agents, target, tool, and permission revalidated"
                    : "physical precondition no longer valid"
            ),
        ]
    )
}

private func reconciliationRestoreRefused(
    _ session: inout AgentSimulationSession,
    request: AgentPersistenceReconciliationRequest,
    expected: AgentPersistenceReconciliationError
) -> Bool {
    let before = try! session.durableStateDigest()
    do {
        _ = try session.applyPersistenceReconciliation(request)
        return false
    } catch AgentSessionError.persistenceReconciliation(let error) {
        return error == expected && (try! session.durableStateDigest()) == before
    } catch {
        return false
    }
}

func runPebbleAgentsPersistenceReconciliationSmoke() {
    section("CIV-27 durable World/civilization reconciliation")

    let source = reconciliationSession()
    let checkpoint = try! source.makeCheckpoint()
    let bytesA = try! AgentCheckpointCodec.encode(checkpoint)
    let bytesB = try! AgentCheckpointCodec.encode(try! source.makeCheckpoint())
    let binding = reconciliationBinding(session: source, checkpoint: checkpoint)
    check("CIV-27 checkpoint schema v20 is deterministic",
          checkpoint.schemaVersion == 20 && bytesA == bytesB)

    var nominal = try! AgentSimulationSession.restoring(checkpoint)
    let sequenceBefore = nominal.causalLedgerSnapshot().summary.latestSequence
    let matched = reconciliationObservation(
        holder: .container("12,64,-4"),
        fingerprint: #"{"locationID":"container:12,64,-4","slots":["pickaxe"]}"#,
        receipt: "restore:container-a"
    )
    let nominalRequest = reconciliationRequest(
        runID: "restore:nominal", binding: binding, observations: [matched]
    )
    let nominalReport = try! nominal.applyPersistenceReconciliation(nominalRequest)
    let nominalRights = nominal.materialRightsSnapshot().records[0]
    check("nominal restart preserves three civilization identities",
          nominal.identitySnapshot().agentIDs.map(\.rawValue).sorted()
            == ["agent_0", "agent_1", "agent_2"])
    check("nominal physical asset is matched without duplication",
          nominalReport.status == .applied
            && nominalReport.run.assetResults.map(\.outcome) == [.matched]
            && nominalReport.run.duplicationCount == 0
            && nominalRights.lastVerifiedHolder.physicalReceiptID
                == "restore:container-a")
    check("claims custody ownership and permission survive reconciliation",
          nominalRights.claims.map(\.claimantID.rawValue) == ["agent_0"]
            && nominalRights.recognizedOwnership?.ownerID.rawValue == "agent_0"
            && nominalRights.permissions.map(\.userID.rawValue) == ["agent_1"])
    check("interrupted activity is explicitly revalidated before resume",
          nominalReport.run.activityResults.map(\.policy) == [.revalidateThenResume]
            && nominal.autonomousActivitySnapshot().activeActivities.count == 1)
    check("reconciliation corrections extend rather than repeat causality",
          nominalReport.run.causalSequenceBefore == sequenceBefore
            && nominalReport.run.causalSequenceAfter > sequenceBefore)
    let afterNominal = try! nominal.durableStateDigest()
    let duplicate = try! nominal.applyPersistenceReconciliation(nominalRequest)
    check("reapplying one restoration is idempotent",
          duplicate.status == .duplicate
            && duplicate.run == nominalReport.run
            && (try! nominal.durableStateDigest()) == afterNominal)
    let nominalTick = nominal.tick
    let nominalSequence = nominal.causalLedgerSnapshot().summary.latestSequence
    _ = try! nominal.advanceTick()
    check("simulation clock and causal sequence continue after restart",
          nominal.tick == nominalTick + 1
            && nominal.causalLedgerSnapshot().summary.latestSequence > nominalSequence)

    var moved = try! AgentSimulationSession.restoring(checkpoint)
    let movedObservation = reconciliationObservation(
        holder: .container("13,64,-4"),
        fingerprint: #"{"locationID":"container:13,64,-4","slots":["pickaxe"]}"#,
        receipt: "restore:container-b",
        damage: 1
    )
    let movedReport = try! moved.applyPersistenceReconciliation(
        reconciliationRequest(
            runID: "restore:moved", binding: binding, observations: [movedObservation]
        )
    )
    let movedRights = moved.materialRightsSnapshot().records[0]
    check("changed physical holder replaces only the physical projection",
          movedReport.run.assetResults.map(\.outcome) == [.changedButReconcilable]
            && movedRights.lastVerifiedHolder.holder == .container("13,64,-4")
            && movedRights.lastVerifiedHolder.materialIdentity.damage == 1
            && movedRights.recognizedOwnership?.ownerID.rawValue == "agent_0"
            && movedRights.claims.map(\.claimantID.rawValue) == ["agent_0"])

    var missing = try! AgentSimulationSession.restoring(checkpoint)
    let missingReport = try! missing.applyPersistenceReconciliation(
        reconciliationRequest(
            runID: "restore:missing", binding: binding, observations: [],
            policy: .replan
        )
    )
    let missingRights = missing.materialRightsSnapshot().records[0]
    let staleUse = missing.evaluateMaterialUse(AgentMaterialUseRequest(
        requestID: "missing:stale-use",
        assetID: reconciliationAssetID,
        actorID: AgentID(rawValue: "agent_1")!,
        use: .toolUse,
        verifiedHolder: missingRights.lastVerifiedHolder
    ))
    check("missing asset is not administratively recreated",
          missingReport.run.assetResults.map(\.outcome) == [.missing]
            && missingReport.run.assetResults[0].observation == nil
            && missingRights.recognizedOwnership?.ownerID.rawValue == "agent_0"
            && missingRights.claims.count == 1)
    check("missing physical asset blocks stale use and replans activity",
          staleUse.verdict == .denied
            && staleUse.reason == .physicalAssetUnresolved
            && missing.autonomousActivitySnapshot().activeActivities.isEmpty
            && missing.autonomousActivitySnapshot().recentRecords.last?
                .outcome.lifecycle == .interrupted)

    var conflicting = try! AgentSimulationSession.restoring(checkpoint)
    let conflictRequest = reconciliationRequest(
        runID: "restore:conflict",
        binding: binding,
        observations: [matched, movedObservation]
    )
    check("multiple physical holders are refused atomically",
          reconciliationRestoreRefused(
            &conflicting,
            request: conflictRequest,
            expected: .duplicatedOrConflictingAsset(reconciliationAssetID)
          ))

    var ambiguous = try! AgentSimulationSession.restoring(checkpoint)
    let secondSameHolder = reconciliationObservation(
        holder: .container("12,64,-4"),
        fingerprint: "second-compatible-stack",
        receipt: "restore:container-a:slot-2"
    )
    check("ambiguous same-holder stacks are refused atomically",
          reconciliationRestoreRefused(
            &ambiguous,
            request: reconciliationRequest(
                runID: "restore:ambiguous",
                binding: binding,
                observations: [matched, secondSameHolder]
            ),
            expected: .ambiguousAsset(reconciliationAssetID)
          ))

    var overBound = try! AgentSimulationSession.restoring(checkpoint)
    let tooManyObservations = (0...8).map { index in
        reconciliationObservation(
            holder: .container("12,64,-4"),
            fingerprint: "over-bound-\(index)",
            receipt: "restore:over-bound:\(index)"
        )
    }
    check("physical observation scans are bounded and atomic",
          reconciliationRestoreRefused(
            &overBound,
            request: reconciliationRequest(
                runID: "restore:over-bound",
                binding: binding,
                observations: tooManyObservations
            ),
            expected: .invalidRequest("physical observation bound")
          ))

    var wrongWorld = try! AgentSimulationSession.restoring(checkpoint)
    let foreignWorld = AgentPersistenceWorldIdentity(
        worldID: "foreign-world",
        storageIdentity: reconciliationWorld.storageIdentity,
        seed: reconciliationWorld.seed,
        dimension: reconciliationWorld.dimension
    )
    check("wrong World is refused before session publication",
          reconciliationRestoreRefused(
            &wrongWorld,
            request: reconciliationRequest(
                runID: "restore:wrong-world",
                binding: binding,
                observations: [matched],
                world: foreignWorld
            ),
            expected: .worldMismatch("identity, storage, seed, or dimension")
          ))

    var invalid = try! AgentSimulationSession.restoring(checkpoint)
    let invalidObservation = AgentMaterialHolderObservation(
        holder: .container("12,64,-4"),
        materialIdentity: AgentMaterialIdentitySnapshot(
            itemKey: "diamond_pickaxe", damage: 0, enchantments: [],
            label: nil, canonicalDataJSON: "{}"
        ),
        quantity: 1,
        custodyFingerprint: "wrong-item",
        physicalReceiptID: "restore:wrong-item",
        observedAtTick: 0
    )
    check("incompatible physical identity is refused atomically",
          reconciliationRestoreRefused(
            &invalid,
            request: reconciliationRequest(
                runID: "restore:invalid",
                binding: binding,
                observations: [invalidObservation]
            ),
            expected: .invalidObservation(reconciliationAssetID)
          ))

    let corruptedData = Data(
        String(data: bytesA, encoding: .utf8)!
            .replacingOccurrences(
                of: #""schemaVersion":20"#,
                with: #""schemaVersion":999"#,
                options: [],
                range: nil
            ).utf8
    )
    check("incompatible checkpoint schema is rejected cleanly", {
        do {
            let corrupted = try AgentCheckpointCodec.decode(
                AgentSessionCheckpoint.self, from: corruptedData
            )
            _ = try AgentSimulationSession.restoring(corrupted)
            return false
        } catch AgentCheckpointError.unsupportedSchema(999) {
            return true
        } catch {
            return false
        }
    }())

    let reconciledCheckpoint = try! nominal.makeCheckpoint()
    var replaySession = try! AgentSimulationSession.restoring(reconciledCheckpoint)
    var recorder = try! AgentReplayRecorder(
        checkpoint: reconciledCheckpoint, session: replaySession
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &replaySession
    )
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "civ27-post-reconcile")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: reconciledCheckpoint,
        journal: journal
    )
    check("schema v20 checkpoint and post-restart replay remain exact",
          journal.manifest.schemaVersion == 20
            && replayed.report.verified
            && replayed.report.finalSemanticDigest
                == (try! replaySession.durableStateDigest()))
}
