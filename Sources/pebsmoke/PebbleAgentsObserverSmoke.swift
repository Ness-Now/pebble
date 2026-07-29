import Foundation
import PebbleAgents

private let observerWorld = try! AgentObserverWorldBinding(
    worldID: "world-civ28",
    storageIdentity: "sqlite-world:world-civ28",
    seed: 83,
    dimension: 0,
    observedWorldTick: 1200
)

private let observerAssetID = AgentMaterialAssetID(
    rawValue: "asset:civ28:shared-pickaxe"
)!

private let observerOtherAssetID = AgentMaterialAssetID(
    rawValue: "asset:civ28:unrelated-tool"
)!

private let observerPermissionID = AgentMaterialPermissionID(
    rawValue: "permission:civ28:borrower"
)!

private func observerAgent(_ ordinal: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    let nearby = (0..<3).filter { $0 != ordinal }.map {
        AgentNearbyObservation(
            id: "agent_\($0)", dx: $0 - ordinal, dy: 0, dz: 0,
            distanceManhattan: abs($0 - ordinal)
        )
    }
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: Double(ordinal) * 0.1,
            fatigue: Double(ordinal) * 0.05,
            curiosity: 0.2, safety: 1
        ),
        health: 100, fear: 0,
        homePosition: ordinal < 2
            ? AgentPosition(x: 0, y: 64, z: 0) : position,
        nearbyAgents: nearby,
        currentGoal: AgentGoal(
            kind: .idle, reason: "waiting for a bounded decision",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 1, nearbyObservationCount: nearby.count,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func observerIdentity(damage: Int = 0) -> AgentMaterialIdentitySnapshot {
    AgentMaterialIdentitySnapshot(
        itemKey: "iron_pickaxe", damage: damage, enchantments: [],
        label: "CIV-28 shared tool", canonicalDataJSON: "{}"
    )
}

private func observerHolder(
    receipt: String,
    damage: Int = 0
) -> AgentMaterialHolderObservation {
    AgentMaterialHolderObservation(
        holder: .agent(AgentID(rawValue: "agent_1")!),
        materialIdentity: observerIdentity(damage: damage),
        quantity: 1,
        custodyFingerprint: "agent_1|iron_pickaxe|\(damage)",
        physicalReceiptID: receipt,
        observedAtTick: 0
    )
}

private func observerSession() -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 83, memoryPolicy: .bounded(maxEntries: 64)
        ),
        agents: [observerAgent(0), observerAgent(1), observerAgent(2)],
        simulationID: try! AgentSimulationID(validating: "civ28-observer"),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! session.setLifecycleEnabled(true)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setSkillsEnabled(true)
    try! session.setWorkCommitmentsEnabled(true)
    try! session.setMaterialRightsEnabled(true)

    let initial = observerHolder(receipt: "civ28-register")
    _ = try! session.applyMaterialRightsOperation(.register(
        operationID: "civ28-register",
        asset: AgentMaterialAssetReference(
            assetID: observerAssetID,
            materialIdentity: initial.materialIdentity,
            quantity: 1
        ),
        observation: initial
    ))
    let claim = AgentMaterialClaimID(rawValue: "claim:civ28:producer")!
    _ = try! session.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ28-claim",
        assetID: observerAssetID,
        claimID: claim,
        claimantID: AgentID(rawValue: "agent_0")!,
        basis: .produced
    ))
    _ = try! session.applyMaterialRightsOperation(.recognizeOwnership(
        operationID: "civ28-recognize",
        assetID: observerAssetID,
        claimID: claim,
        recognizingAgentIDs: [
            AgentID(rawValue: "agent_0")!,
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ]
    ))
    _ = try! session.applyMaterialRightsOperation(.delegateCustody(
        operationID: "civ28-custody",
        assetID: observerAssetID,
        custodianID: AgentID(rawValue: "agent_1")!,
        actorID: AgentID(rawValue: "agent_0")!
    ))
    _ = try! session.applyMaterialRightsOperation(.grantUse(
        operationID: "civ28-permission",
        assetID: observerAssetID,
        permissionID: observerPermissionID,
        grantorID: AgentID(rawValue: "agent_0")!,
        userID: AgentID(rawValue: "agent_1")!,
        allowedUses: [.toolUse],
        expiresAtTick: nil
    ))
    let allowedRequest = AgentMaterialUseRequest(
        requestID: "civ28-allowed",
        assetID: observerAssetID,
        actorID: AgentID(rawValue: "agent_1")!,
        use: .toolUse,
        verifiedHolder: initial
    )
    let allowed = session.evaluateMaterialUse(allowedRequest)
    let used = observerHolder(receipt: "civ28-used", damage: 1)
    _ = try! session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "civ28-allowed",
            decision: allowed,
            status: .succeeded,
            resultingObservation: used,
            physicalReceiptID: used.physicalReceiptID
        )
    ))
    let deniedRequest = AgentMaterialUseRequest(
        requestID: "civ28-refused",
        assetID: observerAssetID,
        actorID: AgentID(rawValue: "agent_2")!,
        use: .toolUse,
        verifiedHolder: used
    )
    let denied = session.evaluateMaterialUse(deniedRequest)
    _ = try! session.applyMaterialRightsOperation(.useAttempt(
        AgentMaterialUseAttemptOutcome(
            operationID: "civ28-refused",
            decision: denied,
            status: .notAttempted,
            resultingObservation: nil,
            physicalReceiptID: nil
        )
    ))
    try! session.setAutonomousActivityEnabled(true)
    _ = try! session.selectAutonomousActivities([
        AgentAutonomousActivityCandidate(
            candidateID: "civ28-authorized-tool-use",
            actorID: AgentID(rawValue: "agent_1")!,
            domain: .construction,
            actionKey: "toolUse",
            stableReference: observerAssetID.rawValue,
            target: AgentPosition(x: 2, y: 64, z: 0),
            materialFingerprint: "iron_pickaxe:1",
            source: .commitment,
            priorityBand: 10,
            urgency: 50,
            distance: 1,
            observedAtTick: 0
        ),
    ])
    try! session.setPersistenceReconciliationEnabled(true)
    return session
}

func runPebbleAgentsObserverSmoke() {
    section("CIV-28 Observer and Chronicle V1")

    let session = observerSession()
    let digestBefore = try! session.durableStateDigest()
    let tickBefore = session.tick
    let sequenceBefore = session.causalLedgerSnapshot().summary.latestSequence
    let first = session.observerSnapshot(worldBinding: observerWorld)
    let second = session.observerSnapshot(worldBinding: observerWorld)
    check("Observer snapshot header binds one coherent session/World boundary",
          first.header.schemaVersion == 1
            && first.header.sessionIdentity == session.simulationID
            && first.header.worldBinding == observerWorld
            && first.header.asOfTick == tickBefore
            && first.header.causalSequence == sequenceBefore)
    check("same state produces identical Observer projection and generation",
          first == second
            && first.header.snapshotGeneration == second.header.snapshotGeneration)
    check("observation cannot tick, append causality, or change durable state",
          session.tick == tickBefore
            && session.causalLedgerSnapshot().summary.latestSequence == sequenceBefore
            && (try! session.durableStateDigest()) == digestBefore)

    let acting = first.individual(AgentID(rawValue: "agent_1")!)!
    check("exact permission on asset B authorizes activity on asset B",
          acting.activity.action == "toolUse"
            && acting.activity.reason.category == .acting
            && acting.activity.reason.code == .authorizedActivity
            && acting.activity.reason.targetOrDependency
                == observerAssetID.rawValue
            && acting.activity.reason.causalEventID != nil)

    var mismatchedPermission = observerSession()
    _ = try! mismatchedPermission.applyMaterialRightsOperation(.revokeUse(
        operationID: "civ28-revoke-exact-permission",
        assetID: observerAssetID,
        permissionID: observerPermissionID,
        actorID: AgentID(rawValue: "agent_0")!
    ))
    let unrelatedObservation = observerHolder(
        receipt: "civ28-unrelated-register"
    )
    _ = try! mismatchedPermission.applyMaterialRightsOperation(.register(
        operationID: "civ28-register-unrelated",
        asset: AgentMaterialAssetReference(
            assetID: observerOtherAssetID,
            materialIdentity: unrelatedObservation.materialIdentity,
            quantity: 1
        ),
        observation: unrelatedObservation
    ))
    let unrelatedClaimID = AgentMaterialClaimID(
        rawValue: "claim:civ28:unrelated"
    )!
    _ = try! mismatchedPermission.applyMaterialRightsOperation(.assertClaim(
        operationID: "civ28-claim-unrelated",
        assetID: observerOtherAssetID,
        claimID: unrelatedClaimID,
        claimantID: AgentID(rawValue: "agent_1")!,
        basis: .found
    ))
    _ = try! mismatchedPermission.applyMaterialRightsOperation(
        .recognizeOwnership(
            operationID: "civ28-recognize-unrelated",
            assetID: observerOtherAssetID,
            claimID: unrelatedClaimID,
            recognizingAgentIDs: [AgentID(rawValue: "agent_1")!]
        )
    )
    _ = try! mismatchedPermission.applyMaterialRightsOperation(.grantUse(
        operationID: "civ28-permission-unrelated",
        assetID: observerOtherAssetID,
        permissionID: AgentMaterialPermissionID(
            rawValue: "permission:civ28:unrelated"
        )!,
        grantorID: AgentID(rawValue: "agent_1")!,
        userID: AgentID(rawValue: "agent_1")!,
        allowedUses: [.toolUse],
        expiresAtTick: nil
    ))
    let mismatchedReason = mismatchedPermission.observerSnapshot(
        worldBinding: observerWorld
    ).individual(AgentID(rawValue: "agent_1")!)!.activity.reason
    check("permission on asset A cannot authorize activity on asset B",
          mismatchedReason.code == .activeActivity
            && mismatchedReason.targetOrDependency == observerAssetID.rawValue)

    let alignedAsset = acting.materialAssets.first!
    check("physical holder, social custody, owner, claim, and permission stay distinct",
          alignedAsset.physicalHolder == "agent:agent_1"
            && alignedAsset.custodianID?.rawValue == "agent_1"
            && alignedAsset.recognizedOwnerID?.rawValue == "agent_0"
            && alignedAsset.claimantIDs.map(\.rawValue) == ["agent_0"]
            && alignedAsset.authorizedUserIDs.map(\.rawValue) == ["agent_1"])
    check("household and bounded relations are authoritative projections",
          acting.household.householdID != nil
            && acting.household.memberIDs.map(\.rawValue) == ["agent_0", "agent_1"]
            && !acting.relations.isEmpty)

    let refused = first.individual(AgentID(rawValue: "agent_2")!)!
    check("refusal reason is structured and references its causal event",
          refused.activity.reason.category == .refused
            && refused.activity.reason.code == .useRefused
            && refused.activity.reason.targetOrDependency == observerAssetID.rawValue
            && refused.activity.reason.causalEventID != nil)
    let refusalEvent = first.globalChronicle.first {
        $0.eventID == refused.activity.reason.causalEventID
    }
    check("Chronicle reads the causal ledger and retains asset/result references",
          refusalEvent?.kind == .materialUseDecided
            && refusalEvent?.assetIDs == [observerAssetID]
            && refusalEvent?.result == "notAttempted"
            && refusalEvent?.detail == "denied:requesterNotPhysicalHolder")

    var actedAfterRefusal = observerSession()
    let oldRefusalEventID = actedAfterRefusal.observerSnapshot(
        worldBinding: observerWorld
    ).individual(AgentID(rawValue: "agent_2")!)!.activity.reason.causalEventID
    _ = try! actedAfterRefusal.advanceTick()
    let actedAgent = actedAfterRefusal.snapshot().agents.first {
        $0.id == "agent_2"
    }!
    let currentAfterRefusal = actedAfterRefusal.observerSnapshot(
        worldBinding: observerWorld
    ).individual(AgentID(rawValue: "agent_2")!)!
    check("a newer action replaces an older refused-use reason",
          currentAfterRefusal.activity.action == actedAgent.lastAction?.name
            && currentAfterRefusal.activity.reason.presentation
                == actedAgent.lastAction?.reason
            && currentAfterRefusal.activity.reason.code != .useRefused
            && (currentAfterRefusal.activity.reason.causalEventID?.sequence
                .rawValue ?? 0)
                > (oldRefusalEventID?.sequence.rawValue ?? 0))

    check("Chronicle order is stable and strictly newest-first",
          zip(first.globalChronicle, first.globalChronicle.dropFirst())
            .allSatisfy { $0.sequence > $1.sequence })

    let individualPage = first.individualPage(offset: 1, limit: 1)
    let filtered = first.chroniclePage(
        filter: AgentObserverChronicleFilter(
            agentID: AgentID(rawValue: "agent_2")!
        ),
        offset: 0,
        limit: 8
    )
    check("selection, pagination, and explicit filtering are pure bounded reads",
          individualPage.values.map(\.agentID.rawValue) == ["agent_1"]
            && individualPage.hasMore
            && filtered.values.contains { $0.kind == .materialUseDecided }
            && (try! session.durableStateDigest()) == digestBefore)

    let tiny = try! AgentObserverConfiguration(
        maximumAgents: 2,
        maximumRelationsPerAgent: 1,
        maximumAssetsPerAgent: 1,
        maximumChronicleEvents: 3,
        maximumEventsPerAgent: 1,
        maximumDirectCausesPerEvent: 1,
        maximumPresentationTextLength: 48
    )
    let bounded = session.observerSnapshot(
        worldBinding: observerWorld, configuration: tiny
    )
    check("all Observer collections are bounded with explicit truncation",
          bounded.individuals.count == 2
            && bounded.globalChronicle.count == 3
            && bounded.truncation.isTruncated
            && bounded.truncation.agentsOmitted == 1
            && bounded.truncation.chronicleEventsOmitted > 0
            && bounded.individuals.allSatisfy {
                $0.relations.count <= 1
                    && $0.materialAssets.count <= 1
                    && $0.recentEventIDs.count <= 1
            })

    var causalFixture = observerSession()
    _ = try! causalFixture.formHousehold(
        memberIDs: [
            AgentID(rawValue: "agent_1")!,
            AgentID(rawValue: "agent_2")!,
        ],
        residenceAnchor: AgentPosition(x: 2, y: 64, z: 0)
    )
    let multiParentSource = causalFixture.causalLedgerSnapshot().events.first {
        $0.causes.count > 1
    }
    let causalBound = try! AgentObserverConfiguration(
        maximumChronicleEvents: 1024,
        maximumDirectCausesPerEvent: 1
    )
    let causallyBounded = causalFixture.observerSnapshot(
        worldBinding: observerWorld, configuration: causalBound
    )
    let boundedMultiParent = multiParentSource.flatMap { source in
        causallyBounded.globalChronicle.first {
            $0.eventID == source.eventID
        }
    }
    check("direct causal references obey their bound with explicit truncation",
          multiParentSource != nil
            && boundedMultiParent?.causes.count == 1
            && boundedMultiParent?.directCausesOmitted
                == (multiParentSource?.causes.count ?? 1) - 1
            && causallyBounded.truncation.directCausesOmitted > 0
            && causallyBounded.truncation.isTruncated)

    check("invalid Observer bounds are rejected", {
        do {
            _ = try AgentObserverConfiguration(maximumChronicleEvents: 0)
            return false
        } catch AgentObserverError.invalidConfiguration("chronicle events") {
            do {
                _ = try AgentObserverConfiguration(
                    maximumDirectCausesPerEvent: 0
                )
                return false
            } catch AgentObserverError.invalidConfiguration(
                "direct causes per event"
            ) {
                return true
            } catch {
                return false
            }
        } catch {
            return false
        }
    }())

    let checkpoint = try! session.makeCheckpoint()
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let restoredView = restored.observerSnapshot(worldBinding: observerWorld)
    check("schema 20 restart reconstructs Observer without a second history",
          checkpoint.schemaVersion == 20
            && restoredView == first
            && restoredView.header.causalSequence == sequenceBefore
            && restored.materialRightsSnapshot().records.count == 1
            && restored.autonomousActivitySnapshot().activeActivities.count == 1)

    var reconciled = restored
    let record = reconciled.materialRightsSnapshot().records[0]
    let binding = AgentPersistenceReconciliationBinding(
        world: AgentPersistenceWorldIdentity(
            worldID: observerWorld.worldID,
            storageIdentity: observerWorld.storageIdentity,
            seed: observerWorld.seed,
            dimension: observerWorld.dimension
        ),
        checkpointID: checkpoint.checkpointID,
        simulationID: checkpoint.simulationID,
        checkpointTick: checkpoint.tick,
        causalSequence: sequenceBefore,
        assets: [
            AgentPersistenceAssetExpectation(
                asset: record.asset,
                savedObservation: record.lastVerifiedHolder,
                candidateHolders: [record.lastVerifiedHolder.holder]
            ),
        ]
    )
    let active = reconciled.autonomousActivitySnapshot().activeActivities[0]
    let report = try! reconciled.applyPersistenceReconciliation(
        AgentPersistenceReconciliationRequest(
            runID: "civ28-restart",
            binding: binding,
            restoredWorld: binding.world,
            observedWorldTick: observerWorld.observedWorldTick,
            assetObservations: [
                AgentPersistenceAssetObservationSet(
                    assetID: observerAssetID,
                    observations: [record.lastVerifiedHolder]
                ),
            ],
            activityResolutions: [
                AgentPersistenceActivityResolution(
                    activityID: active.activityID,
                    actorID: active.candidate.actorID,
                    policy: .revalidateThenResume,
                    reason: "actor, tool, permission, and target revalidated"
                ),
            ]
        )
    )
    let afterRestart = reconciled.observerSnapshot(worldBinding: observerWorld)
    let resumed = afterRestart.individual(AgentID(rawValue: "agent_1")!)!
    check("post-restart Observer explains reconciliation and causal continuity",
          report.run.duplicationCount == 0
            && resumed.activity.reason.category == .interruptedReconciled
            && resumed.activity.reason.code == .persistenceReconciled
            && resumed.activity.reason.causalEventID != nil
            && afterRestart.header.causalSequence > sequenceBefore
            && afterRestart.header.sessionIdentity == first.header.sessionIdentity
            && afterRestart.header.worldBinding == first.header.worldBinding)
    let postDigest = try! reconciled.durableStateDigest()
    _ = reconciled.observerSnapshot(worldBinding: observerWorld)
    _ = reconciled.observerSnapshot(worldBinding: observerWorld)
    check("repeated post-restart observation creates no duplicate event",
          (try! reconciled.durableStateDigest()) == postDigest
            && reconciled.causalLedgerSnapshot().summary.latestSequence
                == afterRestart.header.causalSequence)

    var continued = reconciled
    let reconciledActivity = continued.autonomousActivitySnapshot()
        .activeActivities[0]
    _ = try! continued.recordAutonomousActivityOutcome(
        AgentAutonomousActivityOutcome(
            activityID: reconciledActivity.activityID,
            actorID: reconciledActivity.candidate.actorID,
            lifecycle: .interrupted,
            completedAtTick: continued.tick,
            reason: "bounded test interruption"
        )
    )
    _ = try! continued.advanceTick()
    let continuedReason = continued.observerSnapshot(
        worldBinding: observerWorld
    ).individual(AgentID(rawValue: "agent_1")!)!.activity.reason
    check("obsolete activity and reconciliation reasons cannot mask a later action",
          continuedReason.code != .persistenceReconciled
            && continuedReason.code != .interruptedAfterRestart
            && continuedReason.code != .boundedReplan)

    check("structured reason vocabulary covers every V1 presentation state",
          Set(AgentObserverReasonCategory.allCases) == Set([
              .acting, .waiting, .blocked, .refused, .failed, .replanning,
              .interruptedReconciled, .unknownUnavailable,
          ]))
}
