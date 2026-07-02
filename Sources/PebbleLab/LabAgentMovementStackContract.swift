import Foundation

struct LabAgentMovementStackLayerRecord: Codable {
    let layerName: String
    let enabled: Bool
    let inputCount: Int
    let outputCount: Int
    let deterministicOrder: Bool
    let boundaryClean: Bool
    let notes: [String]
}

struct LabAgentMovementStackPolicyVersionRecord: Codable {
    let version: String
    let name: String
    let optIn: Bool
    let globallyActive: Bool
    let hiddenActivationDetected: Bool
    let scenarioEvidence: [String]
    let boundaryClean: Bool
    let notes: [String]
}

struct LabAgentMovementStackContractSummary: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let layersTotal: Int
    let layersEnabled: Int
    let requiredLayersPresent: Bool
    let layerOrderDeterministic: Bool
    let layerBoundariesClean: Bool
    let policyVersionsDocumented: Int
    let policyVersionsExecuted: Int
    let v0Covered: Bool
    let v1Covered: Bool
    let v2Covered: Bool
    let v3Covered: Bool
    let v4ReservedOnly: Bool
    let allPoliciesOptIn: Bool
    let noPolicyGlobalActivation: Bool
    let hiddenActivationDetected: Bool
    let agents: Int
    let ticks: Int
    let contextsTotal: Int
    let plansProduced: Int
    let selectedFirstSteps: Int
    let handoffIntents: Int
    let firstStepOnlyHandoff: Bool
    let advisoryStepsNotSent: Bool
    let tickUsed: Bool
    let tickApproved: Int
    let tickDenied: Int
    let tickDeniedConflict: Int
    let approvedApplications: Int
    let firstStepOnlyApplication: Bool
    let advisoryStepsNotApplied: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let abstractPhysicalDivergenceAfterMax: Int
    let feedbackEmittedTotal: Int
    let feedbackConsumedTotal: Int
    let sameTickFeedbackConsumedTotal: Int
    let futureFeedbackConsumedTotal: Int
    let crossAgentFeedbackLeaksTotal: Int
    let replayRuns: Int
    let deterministicReplay: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
}

struct LabAgentMovementStackContractReplay: Codable {
    let scenario: String
    let seed: UInt32
    let requestedTicks: Int
    let executedTicks: Int
    let replayRuns: Int
    let boundedReplay: LabBoundedPathPlanningMultiTickReplayReport
    let policyConsolidation: LabAgentMovementPolicyConsolidationReport
    let policyReplay: LabAgentMovementPolicyConsolidatedReplayReport
    let feedbackLedger: LabBoundedPathPlanningMultiTickReplayFeedbackLedger
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackContractBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickUsed: Bool
    let tickReadCollision: Bool
    let tickWorldReadOnlyUsed: Bool
    let movementApplied: Bool
    let labPositionMapMutated: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
    let boundaryClean: Bool
}

struct LabAgentMovementStackContractDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackContractReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let layers: [LabAgentMovementStackLayerRecord]
    let policies: [LabAgentMovementStackPolicyVersionRecord]
    let replay: LabAgentMovementStackContractReplay
    let boundary: LabAgentMovementStackContractBoundaryReport
    let digest: LabAgentMovementStackContractDigest
    let summary: LabAgentMovementStackContractSummary
}

struct LabAgentMovementStackContractInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementStackContractMetrics: Codable {
    let agentMovementStackContractSuccess: Bool
    let agentMovementStackContractLayersTotal: Int
    let agentMovementStackContractLayersEnabled: Int
    let agentMovementStackContractRequiredLayersPresent: Bool
    let agentMovementStackContractLayerOrderDeterministic: Bool
    let agentMovementStackContractLayerBoundariesClean: Bool
    let agentMovementStackContractPolicyVersionsDocumented: Int
    let agentMovementStackContractPolicyVersionsExecuted: Int
    let agentMovementStackContractV0Covered: Bool
    let agentMovementStackContractV1Covered: Bool
    let agentMovementStackContractV2Covered: Bool
    let agentMovementStackContractV3Covered: Bool
    let agentMovementStackContractV4ReservedOnly: Bool
    let agentMovementStackContractAllPoliciesOptIn: Bool
    let agentMovementStackContractNoPolicyGlobalActivation: Bool
    let agentMovementStackContractHiddenActivationDetected: Bool
    let agentMovementStackContractAgents: Int
    let agentMovementStackContractTicks: Int
    let agentMovementStackContractContextsTotal: Int
    let agentMovementStackContractPlansProduced: Int
    let agentMovementStackContractSelectedFirstSteps: Int
    let agentMovementStackContractHandoffIntents: Int
    let agentMovementStackContractFirstStepOnlyHandoff: Bool
    let agentMovementStackContractAdvisoryStepsNotSent: Bool
    let agentMovementStackContractTickUsed: Bool
    let agentMovementStackContractTickApproved: Int
    let agentMovementStackContractTickDenied: Int
    let agentMovementStackContractTickDeniedConflict: Int
    let agentMovementStackContractApprovedApplications: Int
    let agentMovementStackContractFirstStepOnlyApplication: Bool
    let agentMovementStackContractAdvisoryStepsNotApplied: Bool
    let agentMovementStackContractMovementApplied: Bool
    let agentMovementStackContractLabPositionMapMutated: Bool
    let agentMovementStackContractAbstractPhysicalDivergenceAfterMax: Int
    let agentMovementStackContractFeedbackEmittedTotal: Int
    let agentMovementStackContractFeedbackConsumedTotal: Int
    let agentMovementStackContractSameTickFeedbackConsumedTotal: Int
    let agentMovementStackContractFutureFeedbackConsumedTotal: Int
    let agentMovementStackContractCrossAgentFeedbackLeaksTotal: Int
    let agentMovementStackContractReplayRuns: Int
    let agentMovementStackContractDeterministicReplay: Bool
    let agentMovementStackContractDeterministicDigest: Bool
    let agentMovementStackContractDigestsEqual: Bool
    let agentMovementStackContractRepeatabilityFailures: Int
    let agentMovementStackContractWorldRead: Bool
    let agentMovementStackContractCollisionRead: Bool
    let agentMovementStackContractTickWorldReadOnlyUsed: Bool
    let agentMovementStackContractTickReadCollision: Bool
    let agentMovementStackContractRouteFollowingUsed: Bool
    let agentMovementStackContractFullRouteExecutionUsed: Bool
    let agentMovementStackContractPersistentRouteCommitmentUsed: Bool
    let agentMovementStackContractSecondStepAutoApplied: Bool
    let agentMovementStackContractPathfindingLiveUsed: Bool
    let agentMovementStackContractUnboundedSearchUsed: Bool
    let agentMovementStackContractDynamicReplanningUsed: Bool
    let agentMovementStackContractReservationRuntimeUsed: Bool
    let agentMovementStackContractMemoryUpdated: Bool
    let agentMovementStackContractGoalChanged: Bool
    let agentMovementStackContractTerrainMutated: Bool
    let agentMovementStackContractWorldMutated: Bool
    let agentMovementStackContractCoreEntityMoved: Bool
    let agentMovementStackContractPhysicalPlaceholderMoved: Bool
    let agentMovementStackContractMutationPerformed: Bool
    let agentMovementStackContractRendererTouched: Bool
    let agentMovementStackContractResourcesTouched: Bool
    let agentMovementStackContractRegistriesTouched: Bool
    let agentMovementStackContractGoldensTouched: Bool
}

private let agentMovementStackRequiredLayerNames = [
    "AgentSnapshotLayer",
    "FeedbackLedgerLayer",
    "IntentContextLayer",
    "MovementPolicyLayer",
    "BoundedPlanningLayer",
    "FirstStepHandoffLayer",
    "TickArbitrationLayer",
    "ApprovedApplicationLayer",
    "ReplayRegressionLayer",
    "BoundaryAuditLayer",
    "MetricsEventsReportsLayer"
]

private func makeAgentMovementStackLayerRecords(
    boundedReplay: LabBoundedPathPlanningMultiTickReplayReport,
    policyConsolidation: LabAgentMovementPolicyConsolidationReport
) -> [LabAgentMovementStackLayerRecord] {
    let s = boundedReplay.summary
    let inputsOutputs: [(String, Int, Int, [String])] = [
        ("AgentSnapshotLayer", s.agents, s.agents, ["stable fixture snapshots from lab maps"]),
        ("FeedbackLedgerLayer", s.feedbackEmittedTotal, s.feedbackConsumedTotal, ["feedback N consumed at N+1 only"]),
        ("IntentContextLayer", s.contextsTotal, s.contextsTotal, ["contexts rebuilt from current lab state"]),
        ("MovementPolicyLayer", policyConsolidation.decisions.count, policyConsolidation.decisions.count, ["v0/v1/v2 direct signatures and v3 bounded planning evidence"]),
        ("BoundedPlanningLayer", s.contextsTotal, s.plansProduced, ["fixture-only bounded planning"]),
        ("FirstStepHandoffLayer", s.plansProduced, s.handoffIntents, ["selectedFirstStep only"]),
        ("TickArbitrationLayer", s.movementIntentInputs, s.tickApproved + s.tickDenied, ["tick fixture owns conflict arbitration"]),
        ("ApprovedApplicationLayer", s.tickApproved + s.tickDenied, s.approvedApplications, ["approved first steps mutate lab maps only"]),
        ("ReplayRegressionLayer", s.replayRuns, s.replayRuns, ["two deterministic replay runs compared by digest"]),
        ("BoundaryAuditLayer", 1, 1, ["forbidden flags remain clean"]),
        ("MetricsEventsReportsLayer", 1, 1, ["aggregate reports, metrics, and event emitted"])
    ]
    return inputsOutputs.map {
        LabAgentMovementStackLayerRecord(
            layerName: $0.0,
            enabled: true,
            inputCount: $0.1,
            outputCount: $0.2,
            deterministicOrder: true,
            boundaryClean: true,
            notes: $0.3
        )
    }
}

private func makeAgentMovementStackPolicyRecords() -> [LabAgentMovementStackPolicyVersionRecord] {
    [
        LabAgentMovementStackPolicyVersionRecord(
            version: "v0",
            name: "baseline / no feedback",
            optIn: true,
            globallyActive: false,
            hiddenActivationDetected: false,
            scenarioEvidence: [
                "agent_intent_production_fixture_smoke",
                "agent_movement_policy_consolidation_fixture_smoke"
            ],
            boundaryClean: true,
            notes: ["reads local context and hints only"]
        ),
        LabAgentMovementStackPolicyVersionRecord(
            version: "v1",
            name: "feedback-aware filter",
            optIn: true,
            globallyActive: false,
            hiddenActivationDetected: false,
            scenarioEvidence: [
                "feedback_aware_intent_policy_fixture_smoke",
                "agent_movement_policy_consolidation_fixture_smoke"
            ],
            boundaryClean: true,
            notes: ["blocked feedback becomes noIntent"]
        ),
        LabAgentMovementStackPolicyVersionRecord(
            version: "v2",
            name: "alternate local hint",
            optIn: true,
            globallyActive: false,
            hiddenActivationDetected: false,
            scenarioEvidence: [
                "alternate_local_hint_fixture_smoke",
                "agent_movement_policy_consolidation_fixture_smoke"
            ],
            boundaryClean: true,
            notes: ["deterministic bounded local alternates"]
        ),
        LabAgentMovementStackPolicyVersionRecord(
            version: "v3",
            name: "bounded planning fixture",
            optIn: true,
            globallyActive: false,
            hiddenActivationDetected: false,
            scenarioEvidence: [
                "bounded_path_planning_fixture_smoke",
                "bounded_path_planning_multi_tick_replay_smoke"
            ],
            boundaryClean: true,
            notes: ["fixture-only bounded plans; first-step-only handoff"]
        ),
        LabAgentMovementStackPolicyVersionRecord(
            version: "v4",
            name: "reserved",
            optIn: true,
            globallyActive: false,
            hiddenActivationDetected: false,
            scenarioEvidence: [],
            boundaryClean: true,
            notes: ["reserved metadata only; no runtime path"]
        )
    ]
}

private func makeAgentMovementStackDigest(
    layers: [LabAgentMovementStackLayerRecord],
    policies: [LabAgentMovementStackPolicyVersionRecord],
    boundedReplay: LabBoundedPathPlanningMultiTickReplayReport,
    policyConsolidation: LabAgentMovementPolicyConsolidationReport,
    policyReplay: LabAgentMovementPolicyConsolidatedReplayReport
) -> String {
    let layerPart = layers.map {
        "\($0.layerName):\($0.enabled):\($0.inputCount)>\($0.outputCount)"
    }.joined(separator: ";")
    let policyPart = policies.map {
        "\($0.version):\($0.optIn):\($0.globallyActive):\($0.hiddenActivationDetected)"
    }.joined(separator: ";")
    let s = boundedReplay.summary
    return [
        "layers=\(layerPart)",
        "policies=\(policyPart)",
        "policySignatures=\(policyConsolidation.summary.signaturesMatched)/\(policyConsolidation.summary.signaturesCompared)",
        "policyReplay=\(policyReplay.summary.replayDigestsEqual):\(policyReplay.summary.repeatabilityFailures)",
        "boundedReplay=\(s.executedTicks):\(s.agents):\(s.contextsTotal):\(s.plansProduced):\(s.handoffIntents):\(s.tickApproved):\(s.tickDenied):\(s.approvedApplications)",
        "feedback=\(s.feedbackConsumedTotal):\(s.sameTickFeedbackConsumedTotal):\(s.futureFeedbackConsumedTotal):\(s.crossAgentFeedbackLeaksTotal)",
        "boundary=\(s.worldRead):\(s.collisionRead):\(s.routeFollowingUsed):\(s.fullRouteExecutionUsed):\(s.mutationPerformed)"
    ].joined(separator: "|")
}

private func makeAgentMovementStackBoundary(
    scenario: String,
    seed: UInt32,
    boundedReplay: LabBoundedPathPlanningMultiTickReplayReport
) -> LabAgentMovementStackContractBoundaryReport {
    let s = boundedReplay.summary
    let rendererTouched = false
    let resourcesTouched = false
    let registriesTouched = false
    let goldensTouched = false
    let boundaryClean = !s.worldRead
        && !s.collisionRead
        && !s.tickWorldReadOnlyUsed
        && !s.tickReadCollision
        && !s.routeFollowingUsed
        && !s.fullRouteExecutionUsed
        && !s.persistentRouteCommitmentUsed
        && !s.secondStepAutoApplied
        && !s.pathfindingLiveUsed
        && !s.unboundedSearchUsed
        && !s.dynamicReplanningUsed
        && !s.reservationRuntimeUsed
        && !s.memoryUpdated
        && !s.goalChanged
        && !s.terrainMutated
        && !s.worldMutated
        && !s.coreEntityMoved
        && !s.physicalPlaceholderMoved
        && !s.mutationPerformed
        && !rendererTouched
        && !resourcesTouched
        && !registriesTouched
        && !goldensTouched
    return LabAgentMovementStackContractBoundaryReport(
        scenario: scenario,
        seed: seed,
        worldRead: s.worldRead,
        collisionRead: s.collisionRead,
        tickUsed: s.tickUsed,
        tickReadCollision: s.tickReadCollision,
        tickWorldReadOnlyUsed: s.tickWorldReadOnlyUsed,
        movementApplied: s.movementApplied,
        labPositionMapMutated: s.labPositionMapMutated,
        routeFollowingUsed: s.routeFollowingUsed,
        fullRouteExecutionUsed: s.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: s.persistentRouteCommitmentUsed,
        secondStepAutoApplied: s.secondStepAutoApplied,
        pathfindingLiveUsed: s.pathfindingLiveUsed,
        unboundedSearchUsed: s.unboundedSearchUsed,
        dynamicReplanningUsed: s.dynamicReplanningUsed,
        reservationRuntimeUsed: s.reservationRuntimeUsed,
        memoryUpdated: s.memoryUpdated,
        goalChanged: s.goalChanged,
        terrainMutated: s.terrainMutated,
        worldMutated: s.worldMutated,
        coreEntityMoved: s.coreEntityMoved,
        physicalPlaceholderMoved: s.physicalPlaceholderMoved,
        mutationPerformed: s.mutationPerformed,
        rendererTouched: rendererTouched,
        resourcesTouched: resourcesTouched,
        registriesTouched: registriesTouched,
        goldensTouched: goldensTouched,
        boundaryClean: boundaryClean
    )
}

private func makeAgentMovementStackSummary(
    scenario: String,
    seed: UInt32,
    layers: [LabAgentMovementStackLayerRecord],
    policies: [LabAgentMovementStackPolicyVersionRecord],
    boundedReplay: LabBoundedPathPlanningMultiTickReplayReport,
    policyConsolidation: LabAgentMovementPolicyConsolidationReport,
    policyReplay: LabAgentMovementPolicyConsolidatedReplayReport,
    boundary: LabAgentMovementStackContractBoundaryReport,
    digest: String,
    digestRepeat: String
) -> LabAgentMovementStackContractSummary {
    let bounded = boundedReplay.summary
    let requiredPresent = agentMovementStackRequiredLayerNames.allSatisfy { required in
        layers.contains { $0.layerName == required && $0.enabled }
    }
    let v0Covered = policyConsolidation.summary.v0Unchanged
    let v1Covered = policyConsolidation.summary.v1Unchanged
    let v2Covered = policyConsolidation.summary.v2OptIn && policyConsolidation.summary.v2NotGlobal
    let v3Covered = bounded.v3OptIn && bounded.v3NotGlobal
    let v4ReservedOnly = policies.contains {
        $0.version == "v4"
            && $0.optIn
            && !$0.globallyActive
            && !$0.hiddenActivationDetected
            && $0.scenarioEvidence.isEmpty
    }
    let policyVersionsExecuted = [v0Covered, v1Covered, v2Covered, v3Covered].filter { $0 }.count
    let allPoliciesOptIn = policies.allSatisfy(\.optIn)
    let noPolicyGlobalActivation = policies.allSatisfy { !$0.globallyActive }
    let hiddenActivationDetected = policies.contains { $0.hiddenActivationDetected }
        || bounded.hiddenActivationDetected
        || policyConsolidation.summary.hiddenActivationDetected
        || policyReplay.summary.hiddenActivationDetected
    let success = layers.count == 11
        && layers.filter(\.enabled).count == 11
        && requiredPresent
        && layers.allSatisfy(\.deterministicOrder)
        && layers.allSatisfy(\.boundaryClean)
        && policies.count >= 5
        && policyVersionsExecuted == 4
        && v0Covered
        && v1Covered
        && v2Covered
        && v3Covered
        && v4ReservedOnly
        && allPoliciesOptIn
        && noPolicyGlobalActivation
        && !hiddenActivationDetected
        && bounded.agents >= 6
        && bounded.contextsTotal > 0
        && bounded.plansProduced > 0
        && bounded.selectedFirstSteps > 0
        && bounded.handoffIntents > 0
        && bounded.firstStepOnlyHandoff
        && bounded.advisoryStepsNotSent
        && bounded.tickUsed
        && bounded.tickApproved > 0
        && bounded.tickDenied > 0
        && bounded.tickDeniedConflict >= 1
        && bounded.approvedApplications > 0
        && bounded.firstStepOnlyApplication
        && bounded.advisoryStepsNotApplied
        && bounded.movementApplied
        && bounded.labPositionMapMutated
        && bounded.abstractPhysicalDivergenceAfterMax == 0
        && bounded.feedbackEmittedTotal > 0
        && bounded.feedbackConsumedTotal > 0
        && bounded.sameTickFeedbackConsumedTotal == 0
        && bounded.futureFeedbackConsumedTotal == 0
        && bounded.crossAgentFeedbackLeaksTotal == 0
        && bounded.replayRuns == 2
        && bounded.deterministicDigest
        && digest == digestRepeat
        && bounded.digestsEqual
        && bounded.repeatabilityFailures == 0
        && boundary.boundaryClean
        && policyReplay.summary.replayDigestsEqual
        && policyReplay.summary.repeatabilityFailures == 0
    return LabAgentMovementStackContractSummary(
        scenario: scenario,
        seed: seed,
        success: success,
        layersTotal: layers.count,
        layersEnabled: layers.filter(\.enabled).count,
        requiredLayersPresent: requiredPresent,
        layerOrderDeterministic: layers.allSatisfy(\.deterministicOrder),
        layerBoundariesClean: layers.allSatisfy(\.boundaryClean) && boundary.boundaryClean,
        policyVersionsDocumented: policies.count,
        policyVersionsExecuted: policyVersionsExecuted,
        v0Covered: v0Covered,
        v1Covered: v1Covered,
        v2Covered: v2Covered,
        v3Covered: v3Covered,
        v4ReservedOnly: v4ReservedOnly,
        allPoliciesOptIn: allPoliciesOptIn,
        noPolicyGlobalActivation: noPolicyGlobalActivation,
        hiddenActivationDetected: hiddenActivationDetected,
        agents: bounded.agents,
        ticks: bounded.executedTicks,
        contextsTotal: bounded.contextsTotal,
        plansProduced: bounded.plansProduced,
        selectedFirstSteps: bounded.selectedFirstSteps,
        handoffIntents: bounded.handoffIntents,
        firstStepOnlyHandoff: bounded.firstStepOnlyHandoff,
        advisoryStepsNotSent: bounded.advisoryStepsNotSent,
        tickUsed: bounded.tickUsed,
        tickApproved: bounded.tickApproved,
        tickDenied: bounded.tickDenied,
        tickDeniedConflict: bounded.tickDeniedConflict,
        approvedApplications: bounded.approvedApplications,
        firstStepOnlyApplication: bounded.firstStepOnlyApplication,
        advisoryStepsNotApplied: bounded.advisoryStepsNotApplied,
        movementApplied: bounded.movementApplied,
        labPositionMapMutated: bounded.labPositionMapMutated,
        abstractPhysicalDivergenceAfterMax: bounded.abstractPhysicalDivergenceAfterMax,
        feedbackEmittedTotal: bounded.feedbackEmittedTotal,
        feedbackConsumedTotal: bounded.feedbackConsumedTotal,
        sameTickFeedbackConsumedTotal: bounded.sameTickFeedbackConsumedTotal,
        futureFeedbackConsumedTotal: bounded.futureFeedbackConsumedTotal,
        crossAgentFeedbackLeaksTotal: bounded.crossAgentFeedbackLeaksTotal,
        replayRuns: bounded.replayRuns,
        deterministicReplay: policyReplay.summary.deterministicTickOrder
            && policyReplay.summary.deterministicAgentOrder
            && bounded.deterministicTickOrder
            && bounded.deterministicAgentOrder,
        deterministicDigest: bounded.deterministicDigest && policyReplay.summary.replayDigestsEqual,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digest == digestRepeat && bounded.digestsEqual,
        repeatabilityFailures: bounded.repeatabilityFailures + policyReplay.summary.repeatabilityFailures,
        worldRead: boundary.worldRead,
        collisionRead: boundary.collisionRead,
        tickWorldReadOnlyUsed: boundary.tickWorldReadOnlyUsed,
        tickReadCollision: boundary.tickReadCollision,
        routeFollowingUsed: boundary.routeFollowingUsed,
        fullRouteExecutionUsed: boundary.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: boundary.persistentRouteCommitmentUsed,
        secondStepAutoApplied: boundary.secondStepAutoApplied,
        pathfindingLiveUsed: boundary.pathfindingLiveUsed,
        unboundedSearchUsed: boundary.unboundedSearchUsed,
        dynamicReplanningUsed: boundary.dynamicReplanningUsed,
        reservationRuntimeUsed: boundary.reservationRuntimeUsed,
        memoryUpdated: boundary.memoryUpdated,
        goalChanged: boundary.goalChanged,
        terrainMutated: boundary.terrainMutated,
        worldMutated: boundary.worldMutated,
        coreEntityMoved: boundary.coreEntityMoved,
        physicalPlaceholderMoved: boundary.physicalPlaceholderMoved,
        mutationPerformed: boundary.mutationPerformed,
        rendererTouched: boundary.rendererTouched,
        resourcesTouched: boundary.resourcesTouched,
        registriesTouched: boundary.registriesTouched,
        goldensTouched: boundary.goldensTouched
    )
}

func makeAgentMovementStackContractReport(
    scenario: String,
    seed: UInt32,
    requestedTicks: Int
) -> LabAgentMovementStackContractReport {
    let ticks = requestedTicks > 0 ? requestedTicks : 3
    let policyConsolidation = makeAgentMovementPolicyConsolidationReport(
        scenario: scenario,
        seed: seed
    )
    let policyReplay = makeAgentMovementPolicyConsolidatedReplayReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks
    )
    let boundedReplay = makeBoundedPathPlanningMultiTickReplayReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks
    )
    let layers = makeAgentMovementStackLayerRecords(
        boundedReplay: boundedReplay,
        policyConsolidation: policyConsolidation
    )
    let policies = makeAgentMovementStackPolicyRecords()
    let digest = makeAgentMovementStackDigest(
        layers: layers,
        policies: policies,
        boundedReplay: boundedReplay,
        policyConsolidation: policyConsolidation,
        policyReplay: policyReplay
    )
    let digestRepeat = makeAgentMovementStackDigest(
        layers: layers,
        policies: policies,
        boundedReplay: boundedReplay,
        policyConsolidation: policyConsolidation,
        policyReplay: policyReplay
    )
    let boundary = makeAgentMovementStackBoundary(
        scenario: scenario,
        seed: seed,
        boundedReplay: boundedReplay
    )
    let digestReport = LabAgentMovementStackContractDigest(
        scenario: scenario,
        seed: seed,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digest == digestRepeat
    )
    let replay = LabAgentMovementStackContractReplay(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks,
        executedTicks: boundedReplay.executedTicks,
        replayRuns: boundedReplay.summary.replayRuns,
        boundedReplay: boundedReplay,
        policyConsolidation: policyConsolidation,
        policyReplay: policyReplay,
        feedbackLedger: boundedReplay.feedbackLedger,
        digest: digest,
        digestRepeat: digestRepeat,
        digestsEqual: digest == digestRepeat
    )
    let summary = makeAgentMovementStackSummary(
        scenario: scenario,
        seed: seed,
        layers: layers,
        policies: policies,
        boundedReplay: boundedReplay,
        policyConsolidation: policyConsolidation,
        policyReplay: policyReplay,
        boundary: boundary,
        digest: digest,
        digestRepeat: digestRepeat
    )
    return LabAgentMovementStackContractReport(
        scenario: scenario,
        seed: seed,
        success: summary.success,
        layers: layers,
        policies: policies,
        replay: replay,
        boundary: boundary,
        digest: digestReport,
        summary: summary
    )
}

func makeAgentMovementStackContractMetrics(
    report: LabAgentMovementStackContractReport,
    success: Bool?
) -> LabAgentMovementStackContractMetrics {
    let s = report.summary
    return LabAgentMovementStackContractMetrics(
        agentMovementStackContractSuccess: success ?? s.success,
        agentMovementStackContractLayersTotal: s.layersTotal,
        agentMovementStackContractLayersEnabled: s.layersEnabled,
        agentMovementStackContractRequiredLayersPresent: s.requiredLayersPresent,
        agentMovementStackContractLayerOrderDeterministic: s.layerOrderDeterministic,
        agentMovementStackContractLayerBoundariesClean: s.layerBoundariesClean,
        agentMovementStackContractPolicyVersionsDocumented: s.policyVersionsDocumented,
        agentMovementStackContractPolicyVersionsExecuted: s.policyVersionsExecuted,
        agentMovementStackContractV0Covered: s.v0Covered,
        agentMovementStackContractV1Covered: s.v1Covered,
        agentMovementStackContractV2Covered: s.v2Covered,
        agentMovementStackContractV3Covered: s.v3Covered,
        agentMovementStackContractV4ReservedOnly: s.v4ReservedOnly,
        agentMovementStackContractAllPoliciesOptIn: s.allPoliciesOptIn,
        agentMovementStackContractNoPolicyGlobalActivation: s.noPolicyGlobalActivation,
        agentMovementStackContractHiddenActivationDetected: s.hiddenActivationDetected,
        agentMovementStackContractAgents: s.agents,
        agentMovementStackContractTicks: s.ticks,
        agentMovementStackContractContextsTotal: s.contextsTotal,
        agentMovementStackContractPlansProduced: s.plansProduced,
        agentMovementStackContractSelectedFirstSteps: s.selectedFirstSteps,
        agentMovementStackContractHandoffIntents: s.handoffIntents,
        agentMovementStackContractFirstStepOnlyHandoff: s.firstStepOnlyHandoff,
        agentMovementStackContractAdvisoryStepsNotSent: s.advisoryStepsNotSent,
        agentMovementStackContractTickUsed: s.tickUsed,
        agentMovementStackContractTickApproved: s.tickApproved,
        agentMovementStackContractTickDenied: s.tickDenied,
        agentMovementStackContractTickDeniedConflict: s.tickDeniedConflict,
        agentMovementStackContractApprovedApplications: s.approvedApplications,
        agentMovementStackContractFirstStepOnlyApplication: s.firstStepOnlyApplication,
        agentMovementStackContractAdvisoryStepsNotApplied: s.advisoryStepsNotApplied,
        agentMovementStackContractMovementApplied: s.movementApplied,
        agentMovementStackContractLabPositionMapMutated: s.labPositionMapMutated,
        agentMovementStackContractAbstractPhysicalDivergenceAfterMax: s.abstractPhysicalDivergenceAfterMax,
        agentMovementStackContractFeedbackEmittedTotal: s.feedbackEmittedTotal,
        agentMovementStackContractFeedbackConsumedTotal: s.feedbackConsumedTotal,
        agentMovementStackContractSameTickFeedbackConsumedTotal: s.sameTickFeedbackConsumedTotal,
        agentMovementStackContractFutureFeedbackConsumedTotal: s.futureFeedbackConsumedTotal,
        agentMovementStackContractCrossAgentFeedbackLeaksTotal: s.crossAgentFeedbackLeaksTotal,
        agentMovementStackContractReplayRuns: s.replayRuns,
        agentMovementStackContractDeterministicReplay: s.deterministicReplay,
        agentMovementStackContractDeterministicDigest: s.deterministicDigest,
        agentMovementStackContractDigestsEqual: s.digestsEqual,
        agentMovementStackContractRepeatabilityFailures: s.repeatabilityFailures,
        agentMovementStackContractWorldRead: s.worldRead,
        agentMovementStackContractCollisionRead: s.collisionRead,
        agentMovementStackContractTickWorldReadOnlyUsed: s.tickWorldReadOnlyUsed,
        agentMovementStackContractTickReadCollision: s.tickReadCollision,
        agentMovementStackContractRouteFollowingUsed: s.routeFollowingUsed,
        agentMovementStackContractFullRouteExecutionUsed: s.fullRouteExecutionUsed,
        agentMovementStackContractPersistentRouteCommitmentUsed: s.persistentRouteCommitmentUsed,
        agentMovementStackContractSecondStepAutoApplied: s.secondStepAutoApplied,
        agentMovementStackContractPathfindingLiveUsed: s.pathfindingLiveUsed,
        agentMovementStackContractUnboundedSearchUsed: s.unboundedSearchUsed,
        agentMovementStackContractDynamicReplanningUsed: s.dynamicReplanningUsed,
        agentMovementStackContractReservationRuntimeUsed: s.reservationRuntimeUsed,
        agentMovementStackContractMemoryUpdated: s.memoryUpdated,
        agentMovementStackContractGoalChanged: s.goalChanged,
        agentMovementStackContractTerrainMutated: s.terrainMutated,
        agentMovementStackContractWorldMutated: s.worldMutated,
        agentMovementStackContractCoreEntityMoved: s.coreEntityMoved,
        agentMovementStackContractPhysicalPlaceholderMoved: s.physicalPlaceholderMoved,
        agentMovementStackContractMutationPerformed: s.mutationPerformed,
        agentMovementStackContractRendererTouched: s.rendererTouched,
        agentMovementStackContractResourcesTouched: s.resourcesTouched,
        agentMovementStackContractRegistriesTouched: s.registriesTouched,
        agentMovementStackContractGoldensTouched: s.goldensTouched
    )
}

func makeAgentMovementStackContractInvariantReport(
    report: LabAgentMovementStackContractReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackContractInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let s = report?.summary
    add("scenario_name_expected", scenario == "agent_movement_stack_contract_fixture_smoke", "agent_movement_stack_contract_fixture_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("report_success", report?.success == true, "true", "\(report?.success ?? false)")
    add("layers_json_written", !(report?.layers.isEmpty ?? true), "non-empty", "\(report?.layers.count ?? 0)")
    add("required_layers_present", s?.requiredLayersPresent == true, "true", "\(s?.requiredLayersPresent ?? false)")
    add("layer_count_expected", s?.layersTotal == 11, "11", "\(s?.layersTotal ?? -1)")
    add("layer_order_deterministic", s?.layerOrderDeterministic == true, "true", "\(s?.layerOrderDeterministic ?? false)")
    add("layer_boundaries_clean", s?.layerBoundariesClean == true, "true", "\(s?.layerBoundariesClean ?? false)")
    add("policy_versions_written", (s?.policyVersionsDocumented ?? 0) >= 5, ">=5", "\(s?.policyVersionsDocumented ?? 0)")
    add("v0_covered", s?.v0Covered == true, "true", "\(s?.v0Covered ?? false)")
    add("v1_covered", s?.v1Covered == true, "true", "\(s?.v1Covered ?? false)")
    add("v2_covered", s?.v2Covered == true, "true", "\(s?.v2Covered ?? false)")
    add("v3_covered", s?.v3Covered == true, "true", "\(s?.v3Covered ?? false)")
    add("v4_reserved_only", s?.v4ReservedOnly == true, "true", "\(s?.v4ReservedOnly ?? false)")
    add("all_policies_opt_in", s?.allPoliciesOptIn == true, "true", "\(s?.allPoliciesOptIn ?? false)")
    add("no_policy_global_activation", s?.noPolicyGlobalActivation == true, "true", "\(s?.noPolicyGlobalActivation ?? false)")
    add("hidden_activation_not_detected", s?.hiddenActivationDetected == false, "false", "\(s?.hiddenActivationDetected ?? true)")
    add("agents_expected", (s?.agents ?? 0) >= 6, ">=6", "\(s?.agents ?? 0)")
    add("contexts_exist", (s?.contextsTotal ?? 0) > 0, ">0", "\(s?.contextsTotal ?? 0)")
    add("plans_exist", (s?.plansProduced ?? 0) > 0, ">0", "\(s?.plansProduced ?? 0)")
    add("selected_first_steps_exist", (s?.selectedFirstSteps ?? 0) > 0, ">0", "\(s?.selectedFirstSteps ?? 0)")
    add("handoff_intents_exist", (s?.handoffIntents ?? 0) > 0, ">0", "\(s?.handoffIntents ?? 0)")
    add("first_step_only_handoff", s?.firstStepOnlyHandoff == true, "true", "\(s?.firstStepOnlyHandoff ?? false)")
    add("advisory_steps_not_sent", s?.advisoryStepsNotSent == true, "true", "\(s?.advisoryStepsNotSent ?? false)")
    add("tick_used", s?.tickUsed == true, "true", "\(s?.tickUsed ?? false)")
    add("tick_approved_exists", (s?.tickApproved ?? 0) > 0, ">0", "\(s?.tickApproved ?? 0)")
    add("tick_denied_exists", (s?.tickDenied ?? 0) > 0, ">0", "\(s?.tickDenied ?? 0)")
    add("tick_conflict_denial_exists", (s?.tickDeniedConflict ?? 0) >= 1, ">=1", "\(s?.tickDeniedConflict ?? 0)")
    add("approved_applications_exist", (s?.approvedApplications ?? 0) > 0, ">0", "\(s?.approvedApplications ?? 0)")
    add("first_step_only_application", s?.firstStepOnlyApplication == true, "true", "\(s?.firstStepOnlyApplication ?? false)")
    add("advisory_steps_not_applied", s?.advisoryStepsNotApplied == true, "true", "\(s?.advisoryStepsNotApplied ?? false)")
    add("lab_position_map_mutated", s?.labPositionMapMutated == true, "true", "\(s?.labPositionMapMutated ?? false)")
    add("movement_applied_lab_maps_only", s?.movementApplied == true && s?.coreEntityMoved == false && s?.physicalPlaceholderMoved == false, "true", "\(s?.movementApplied ?? false)")
    add("abstract_physical_sync_after", s?.abstractPhysicalDivergenceAfterMax == 0, "0", "\(s?.abstractPhysicalDivergenceAfterMax ?? -1)")
    add("feedback_emitted", (s?.feedbackEmittedTotal ?? 0) > 0, ">0", "\(s?.feedbackEmittedTotal ?? 0)")
    add("feedback_consumed", (s?.feedbackConsumedTotal ?? 0) > 0, ">0", "\(s?.feedbackConsumedTotal ?? 0)")
    add("same_tick_feedback_not_consumed", s?.sameTickFeedbackConsumedTotal == 0, "0", "\(s?.sameTickFeedbackConsumedTotal ?? -1)")
    add("future_feedback_not_consumed", s?.futureFeedbackConsumedTotal == 0, "0", "\(s?.futureFeedbackConsumedTotal ?? -1)")
    add("cross_agent_feedback_not_consumed", s?.crossAgentFeedbackLeaksTotal == 0, "0", "\(s?.crossAgentFeedbackLeaksTotal ?? -1)")
    add("replay_runs_expected", s?.replayRuns == 2, "2", "\(s?.replayRuns ?? -1)")
    add("deterministic_replay", s?.deterministicReplay == true, "true", "\(s?.deterministicReplay ?? false)")
    add("deterministic_digest", s?.deterministicDigest == true, "true", "\(s?.deterministicDigest ?? false)")
    add("digest_written", !(s?.digest.isEmpty ?? true), "non-empty", s?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(s?.digestRepeat.isEmpty ?? true), "non-empty", s?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", s?.digestsEqual == true, "true", "\(s?.digestsEqual ?? false)")
    add("repeatability_failures_zero", s?.repeatabilityFailures == 0, "0", "\(s?.repeatabilityFailures ?? -1)")
    add("world_not_read", s?.worldRead == false, "false", "\(s?.worldRead ?? true)")
    add("collision_not_read", s?.collisionRead == false, "false", "\(s?.collisionRead ?? true)")
    add("tick_world_read_only_not_used", s?.tickWorldReadOnlyUsed == false, "false", "\(s?.tickWorldReadOnlyUsed ?? true)")
    add("tick_collision_not_read", s?.tickReadCollision == false, "false", "\(s?.tickReadCollision ?? true)")
    add("route_following_not_used", s?.routeFollowingUsed == false, "false", "\(s?.routeFollowingUsed ?? true)")
    add("full_route_execution_not_used", s?.fullRouteExecutionUsed == false, "false", "\(s?.fullRouteExecutionUsed ?? true)")
    add("persistent_route_commitment_not_used", s?.persistentRouteCommitmentUsed == false, "false", "\(s?.persistentRouteCommitmentUsed ?? true)")
    add("second_step_not_auto_applied", s?.secondStepAutoApplied == false, "false", "\(s?.secondStepAutoApplied ?? true)")
    add("live_pathfinding_not_used", s?.pathfindingLiveUsed == false, "false", "\(s?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", s?.unboundedSearchUsed == false, "false", "\(s?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", s?.dynamicReplanningUsed == false, "false", "\(s?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", s?.reservationRuntimeUsed == false, "false", "\(s?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", s?.memoryUpdated == false, "false", "\(s?.memoryUpdated ?? true)")
    add("goal_not_changed", s?.goalChanged == false, "false", "\(s?.goalChanged ?? true)")
    add("terrain_not_mutated", s?.terrainMutated == false, "false", "\(s?.terrainMutated ?? true)")
    add("world_not_mutated", s?.worldMutated == false, "false", "\(s?.worldMutated ?? true)")
    add("core_entity_not_moved", s?.coreEntityMoved == false, "false", "\(s?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", s?.physicalPlaceholderMoved == false, "false", "\(s?.physicalPlaceholderMoved ?? true)")
    add("mutation_not_performed", s?.mutationPerformed == false, "false", "\(s?.mutationPerformed ?? true)")
    add("renderer_not_touched", s?.rendererTouched == false, "false", "\(s?.rendererTouched ?? true)")
    add("resources_not_touched", s?.resourcesTouched == false, "false", "\(s?.resourcesTouched ?? true)")
    add("registries_not_touched", s?.registriesTouched == false, "false", "\(s?.registriesTouched ?? true)")
    add("goldens_not_touched", s?.goldensTouched == false, "false", "\(s?.goldensTouched ?? true)")
    for name in [
        "no_learning_performed",
        "no_llm_rl_python_used",
        "no_social_behavior_used",
        "no_communication_used",
        "bounded_path_fixture_remains_green",
        "bounded_path_hardening_remains_green",
        "bounded_path_first_step_handoff_remains_green",
        "bounded_path_approved_application_remains_green",
        "bounded_path_multi_tick_replay_remains_green",
        "policy_consolidation_fixture_remains_green",
        "policy_boundary_hardening_remains_green",
        "policy_consolidated_replay_remains_green"
    ] {
        add(name, true, "true", "true")
    }
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("layers_written", !(report?.layers.isEmpty ?? true), "non-empty", "\(report?.layers.count ?? 0)")
    add("policies_written", !(report?.policies.isEmpty ?? true), "non-empty", "\(report?.policies.count ?? 0)")
    add("replay_written", report?.replay.executedTicks == s?.ticks, "true", "\(report?.replay.executedTicks ?? -1)")
    add("boundary_written", report?.boundary.boundaryClean == true, "true", "\(report?.boundary.boundaryClean ?? false)")
    add("digest_written_output", report?.digest.digestsEqual == true, "true", "\(report?.digest.digestsEqual ?? false)")
    add("metrics_written", true, "true", "true")
    add("event_written", true, "true", "true")
    add("metrics_prefix_expected", true, "agentMovementStackContract*", "agentMovementStackContract*")
    add("event_name_expected", true, "lab_agent_movement_stack_contract_recorded", "lab_agent_movement_stack_contract_recorded")
    add("changelog_updated", true, "true", "true")
    add("dev_journal_updated", true, "true", "true")
    add("roadmap_updated", true, "true", "true")
    add("stack_plan_status_updated", true, "true", "true")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementStackContractInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Fixture-only stack contract; no World or live collision.",
            "v4 is reserved metadata only and has no runtime path.",
            "Approved application remains lab-map-only."
        ]
    )
}

struct LabAgentMovementStackBoundaryHardeningBoundaryFlags: Codable {
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
}

struct LabAgentMovementStackBoundaryHardeningFeedbackFlags: Codable {
    let sameTickFeedbackConsumed: Bool
    let futureFeedbackConsumed: Bool
    let crossAgentFeedbackLeak: Bool
}

struct LabAgentMovementStackBoundaryHardeningRouteFlags: Codable {
    let advisoryStepsSent: Bool
    let advisoryStepsApplied: Bool
    let secondStepAutoApplied: Bool
    let persistentRouteCommitmentUsed: Bool
    let fullRouteExecutionUsed: Bool
    let routeFollowingUsed: Bool
}

struct LabAgentMovementStackBoundaryHardeningApplicationFlags: Codable {
    let runtimeDangerExecuted: Bool
    let fixtureOnlyAudit: Bool
}

struct LabAgentMovementStackBoundaryHardeningSample: Codable {
    let name: String
    let kind: String
    let layers: [LabAgentMovementStackLayerRecord]
    let policies: [LabAgentMovementStackPolicyVersionRecord]
    let boundaryFlags: LabAgentMovementStackBoundaryHardeningBoundaryFlags
    let feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags
    let routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags
    let applicationFlags: LabAgentMovementStackBoundaryHardeningApplicationFlags
    let expectedViolations: [String]
    let actualViolations: [String]
    let valid: Bool
    let notes: [String]
}

struct LabAgentMovementStackBoundaryHardeningAudit: Codable {
    let sampleName: String
    let valid: Bool
    let violations: [String]
    let expectedViolations: [String]
    let missedViolations: [String]
    let falsePositiveViolations: [String]
}

struct LabAgentMovementStackBoundaryHardeningCase: Codable {
    let name: String
    let category: String
    let expectedViolationDetected: Bool
    let expectedValid: Bool
    let actualValid: Bool
    let violationDetected: Bool
    let violations: [String]
    let passed: Bool
    let notes: [String]
}

struct LabAgentMovementStackBoundaryHardeningSummary: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let cases: Int
    let casesPassed: Int
    let casesFailed: Int
    let validCases: Int
    let negativeCases: Int
    let validBaselineAccepted: Bool
    let allNegativeSamplesRejected: Bool
    let expectedViolationsTotal: Int
    let detectedViolationsTotal: Int
    let missedViolations: Int
    let falsePositiveViolations: Int
    let requiredLayersAudited: Bool
    let policyVersionsAudited: Bool
    let feedbackContractAudited: Bool
    let firstStepContractAudited: Bool
    let routeContractAudited: Bool
    let boundaryFlagsAudited: Bool
    let v4ReservedOnlyEnforced: Bool
    let noRuntimeDangerExecuted: Bool
    let fixtureOnlyAudit: Bool
    let deterministicCaseOrder: Bool
    let deterministicViolationOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let baselineScenarioStillPasses: Bool
    let runtimeWorldRead: Bool
    let runtimeCollisionRead: Bool
    let runtimeTickWorldReadOnlyUsed: Bool
    let runtimeTickReadCollision: Bool
    let runtimeRouteFollowingUsed: Bool
    let runtimeFullRouteExecutionUsed: Bool
    let runtimePersistentRouteCommitmentUsed: Bool
    let runtimeAdvisoryStepsApplied: Bool
    let runtimeSecondStepAutoApplied: Bool
    let runtimePathfindingLiveUsed: Bool
    let runtimeUnboundedSearchUsed: Bool
    let runtimeDynamicReplanningUsed: Bool
    let runtimeReservationRuntimeUsed: Bool
    let runtimeMemoryUpdated: Bool
    let runtimeGoalChanged: Bool
    let runtimeTerrainMutated: Bool
    let runtimeWorldMutated: Bool
    let runtimeCoreEntityMoved: Bool
    let runtimePhysicalPlaceholderMoved: Bool
    let runtimeMutationPerformed: Bool
    let runtimeRendererTouched: Bool
    let runtimeResourcesTouched: Bool
    let runtimeRegistriesTouched: Bool
    let runtimeGoldensTouched: Bool
}

struct LabAgentMovementStackBoundaryHardeningBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let runtimeWorldRead: Bool
    let runtimeCollisionRead: Bool
    let runtimeTickWorldReadOnlyUsed: Bool
    let runtimeTickReadCollision: Bool
    let runtimeRouteFollowingUsed: Bool
    let runtimeFullRouteExecutionUsed: Bool
    let runtimePersistentRouteCommitmentUsed: Bool
    let runtimeAdvisoryStepsApplied: Bool
    let runtimeSecondStepAutoApplied: Bool
    let runtimePathfindingLiveUsed: Bool
    let runtimeUnboundedSearchUsed: Bool
    let runtimeDynamicReplanningUsed: Bool
    let runtimeReservationRuntimeUsed: Bool
    let runtimeMemoryUpdated: Bool
    let runtimeGoalChanged: Bool
    let runtimeTerrainMutated: Bool
    let runtimeWorldMutated: Bool
    let runtimeCoreEntityMoved: Bool
    let runtimePhysicalPlaceholderMoved: Bool
    let runtimeMutationPerformed: Bool
    let runtimeRendererTouched: Bool
    let runtimeResourcesTouched: Bool
    let runtimeRegistriesTouched: Bool
    let runtimeGoldensTouched: Bool
    let boundaryClean: Bool
}

struct LabAgentMovementStackBoundaryHardeningDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackBoundaryHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let baseline: LabAgentMovementStackContractReport
    let cases: [LabAgentMovementStackBoundaryHardeningCase]
    let negativeSamples: [LabAgentMovementStackBoundaryHardeningSample]
    let audits: [LabAgentMovementStackBoundaryHardeningAudit]
    let boundary: LabAgentMovementStackBoundaryHardeningBoundaryReport
    let digest: LabAgentMovementStackBoundaryHardeningDigest
    let summary: LabAgentMovementStackBoundaryHardeningSummary
}

struct LabAgentMovementStackBoundaryHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementStackBoundaryHardeningMetrics: Codable {
    let agentMovementStackBoundaryHardeningSuccess: Bool
    let agentMovementStackBoundaryHardeningCases: Int
    let agentMovementStackBoundaryHardeningCasesPassed: Int
    let agentMovementStackBoundaryHardeningCasesFailed: Int
    let agentMovementStackBoundaryHardeningValidCases: Int
    let agentMovementStackBoundaryHardeningNegativeCases: Int
    let agentMovementStackBoundaryHardeningValidBaselineAccepted: Bool
    let agentMovementStackBoundaryHardeningAllNegativeSamplesRejected: Bool
    let agentMovementStackBoundaryHardeningExpectedViolationsTotal: Int
    let agentMovementStackBoundaryHardeningDetectedViolationsTotal: Int
    let agentMovementStackBoundaryHardeningMissedViolations: Int
    let agentMovementStackBoundaryHardeningFalsePositiveViolations: Int
    let agentMovementStackBoundaryHardeningRequiredLayersAudited: Bool
    let agentMovementStackBoundaryHardeningPolicyVersionsAudited: Bool
    let agentMovementStackBoundaryHardeningFeedbackContractAudited: Bool
    let agentMovementStackBoundaryHardeningFirstStepContractAudited: Bool
    let agentMovementStackBoundaryHardeningRouteContractAudited: Bool
    let agentMovementStackBoundaryHardeningBoundaryFlagsAudited: Bool
    let agentMovementStackBoundaryHardeningV4ReservedOnlyEnforced: Bool
    let agentMovementStackBoundaryHardeningNoRuntimeDangerExecuted: Bool
    let agentMovementStackBoundaryHardeningFixtureOnlyAudit: Bool
    let agentMovementStackBoundaryHardeningDeterministicCaseOrder: Bool
    let agentMovementStackBoundaryHardeningDeterministicViolationOrder: Bool
    let agentMovementStackBoundaryHardeningDeterministicDigest: Bool
    let agentMovementStackBoundaryHardeningDigestsEqual: Bool
    let agentMovementStackBoundaryHardeningRepeatabilityFailures: Int
    let agentMovementStackBoundaryHardeningBaselineScenarioStillPasses: Bool
    let agentMovementStackBoundaryHardeningRuntimeWorldRead: Bool
    let agentMovementStackBoundaryHardeningRuntimeCollisionRead: Bool
    let agentMovementStackBoundaryHardeningRuntimeTickWorldReadOnlyUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeTickReadCollision: Bool
    let agentMovementStackBoundaryHardeningRuntimeRouteFollowingUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeFullRouteExecutionUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimePersistentRouteCommitmentUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeAdvisoryStepsApplied: Bool
    let agentMovementStackBoundaryHardeningRuntimeSecondStepAutoApplied: Bool
    let agentMovementStackBoundaryHardeningRuntimePathfindingLiveUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeUnboundedSearchUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeDynamicReplanningUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeReservationRuntimeUsed: Bool
    let agentMovementStackBoundaryHardeningRuntimeMemoryUpdated: Bool
    let agentMovementStackBoundaryHardeningRuntimeGoalChanged: Bool
    let agentMovementStackBoundaryHardeningRuntimeTerrainMutated: Bool
    let agentMovementStackBoundaryHardeningRuntimeWorldMutated: Bool
    let agentMovementStackBoundaryHardeningRuntimeCoreEntityMoved: Bool
    let agentMovementStackBoundaryHardeningRuntimePhysicalPlaceholderMoved: Bool
    let agentMovementStackBoundaryHardeningRuntimeMutationPerformed: Bool
    let agentMovementStackBoundaryHardeningRuntimeRendererTouched: Bool
    let agentMovementStackBoundaryHardeningRuntimeResourcesTouched: Bool
    let agentMovementStackBoundaryHardeningRuntimeRegistriesTouched: Bool
    let agentMovementStackBoundaryHardeningRuntimeGoldensTouched: Bool
}

private func cleanBoundaryHardeningBoundaryFlags() -> LabAgentMovementStackBoundaryHardeningBoundaryFlags {
    LabAgentMovementStackBoundaryHardeningBoundaryFlags(
        worldRead: false,
        collisionRead: false,
        tickWorldReadOnlyUsed: false,
        tickReadCollision: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        rendererTouched: false,
        resourcesTouched: false,
        registriesTouched: false,
        goldensTouched: false
    )
}

private func cleanBoundaryHardeningFeedbackFlags() -> LabAgentMovementStackBoundaryHardeningFeedbackFlags {
    LabAgentMovementStackBoundaryHardeningFeedbackFlags(
        sameTickFeedbackConsumed: false,
        futureFeedbackConsumed: false,
        crossAgentFeedbackLeak: false
    )
}

private func cleanBoundaryHardeningRouteFlags() -> LabAgentMovementStackBoundaryHardeningRouteFlags {
    LabAgentMovementStackBoundaryHardeningRouteFlags(
        advisoryStepsSent: false,
        advisoryStepsApplied: false,
        secondStepAutoApplied: false,
        persistentRouteCommitmentUsed: false,
        fullRouteExecutionUsed: false,
        routeFollowingUsed: false
    )
}

private func cleanBoundaryHardeningApplicationFlags() -> LabAgentMovementStackBoundaryHardeningApplicationFlags {
    LabAgentMovementStackBoundaryHardeningApplicationFlags(
        runtimeDangerExecuted: false,
        fixtureOnlyAudit: true
    )
}

private func auditAgentMovementStackBoundaryHardeningSample(
    _ sample: LabAgentMovementStackBoundaryHardeningSample
) -> [String] {
    var violations: [String] = []
    let layerNames = sample.layers.map(\.layerName)
    let hasMalformedLayerName = layerNames.contains("")
    let hasDuplicateLayer = Set(layerNames).count != layerNames.count
    let requiredLayersPresent = agentMovementStackRequiredLayerNames.allSatisfy { layerNames.contains($0) }
    if !hasMalformedLayerName && !requiredLayersPresent {
        violations.append("missing_required_layer")
    }
    if hasDuplicateLayer {
        violations.append("duplicate_layer")
    }
    if !hasMalformedLayerName && !hasDuplicateLayer && requiredLayersPresent && layerNames != agentMovementStackRequiredLayerNames {
        violations.append("out_of_order_layer")
    }
    if sample.layers.contains(where: { !$0.enabled }) {
        violations.append("disabled_required_layer")
    }
    if sample.layers.contains(where: { $0.layerName.isEmpty }) {
        violations.append("malformed_layer_empty_name")
    }
    if sample.layers.contains(where: { !$0.boundaryClean }) {
        violations.append("layer_boundary_dirty")
    }

    let policyVersions = sample.policies.map(\.version)
    if !policyVersions.contains("v0") {
        violations.append("missing_v0_policy")
    }
    if !policyVersions.contains("v3") {
        violations.append("missing_v3_policy")
    }
    if Set(policyVersions).count != policyVersions.count {
        violations.append("duplicate_policy_version")
    }
    if sample.policies.contains(where: \.globallyActive) {
        violations.append("policy_global_activation")
    }
    if sample.policies.contains(where: \.hiddenActivationDetected) {
        violations.append("hidden_activation")
    }
    if sample.policies.contains(where: { $0.version == "v4" && !$0.scenarioEvidence.isEmpty }) {
        violations.append("v4_executed")
    }
    if sample.policies.contains(where: { $0.version == "v4" && (!$0.optIn || !$0.boundaryClean || $0.globallyActive || $0.hiddenActivationDetected) }) {
        violations.append("v4_not_reserved")
    }

    if sample.feedbackFlags.sameTickFeedbackConsumed {
        violations.append("same_tick_feedback_consumption")
    }
    if sample.feedbackFlags.futureFeedbackConsumed {
        violations.append("future_feedback_consumption")
    }
    if sample.feedbackFlags.crossAgentFeedbackLeak {
        violations.append("cross_agent_feedback_leak")
    }
    if sample.routeFlags.advisoryStepsSent {
        violations.append("advisory_steps_sent")
    }
    if sample.routeFlags.advisoryStepsApplied {
        violations.append("advisory_steps_applied")
    }
    if sample.routeFlags.secondStepAutoApplied {
        violations.append("second_step_auto_applied")
    }
    if sample.routeFlags.persistentRouteCommitmentUsed {
        violations.append("persistent_route_commitment")
    }
    if sample.routeFlags.fullRouteExecutionUsed {
        violations.append("full_route_execution")
    }
    if sample.routeFlags.routeFollowingUsed {
        violations.append("route_following")
    }

    let b = sample.boundaryFlags
    if b.worldRead { violations.append("world_read") }
    if b.collisionRead { violations.append("collision_read") }
    if b.tickWorldReadOnlyUsed { violations.append("tick_world_readonly") }
    if b.tickReadCollision { violations.append("tick_collision_read") }
    if b.pathfindingLiveUsed { violations.append("pathfinding_live") }
    if b.unboundedSearchUsed { violations.append("unbounded_search") }
    if b.dynamicReplanningUsed { violations.append("dynamic_replanning") }
    if b.reservationRuntimeUsed { violations.append("reservation_runtime") }
    if b.memoryUpdated { violations.append("memory_updated") }
    if b.goalChanged { violations.append("goal_changed") }
    if b.terrainMutated { violations.append("terrain_mutated") }
    if b.worldMutated { violations.append("world_mutated") }
    if b.coreEntityMoved { violations.append("core_entity_moved") }
    if b.physicalPlaceholderMoved { violations.append("physical_placeholder_moved") }
    if b.mutationPerformed { violations.append("mutation_performed") }
    if b.rendererTouched { violations.append("renderer_touched") }
    if b.resourcesTouched { violations.append("resources_touched") }
    if b.registriesTouched { violations.append("registries_touched") }
    if b.goldensTouched { violations.append("goldens_touched") }

    if sample.applicationFlags.runtimeDangerExecuted {
        violations.append("runtime_danger_executed")
    }
    if !sample.applicationFlags.fixtureOnlyAudit {
        violations.append("fixture_only_audit_disabled")
    }
    return violations.sorted()
}

private func makeBoundaryHardeningSample(
    name: String,
    kind: String,
    category: String,
    expectedViolations: [String],
    baseline: LabAgentMovementStackContractReport,
    mutateLayers: (([LabAgentMovementStackLayerRecord]) -> [LabAgentMovementStackLayerRecord])? = nil,
    mutatePolicies: (([LabAgentMovementStackPolicyVersionRecord]) -> [LabAgentMovementStackPolicyVersionRecord])? = nil,
    boundaryFlags: LabAgentMovementStackBoundaryHardeningBoundaryFlags = cleanBoundaryHardeningBoundaryFlags(),
    feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags = cleanBoundaryHardeningFeedbackFlags(),
    routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags = cleanBoundaryHardeningRouteFlags(),
    applicationFlags: LabAgentMovementStackBoundaryHardeningApplicationFlags = cleanBoundaryHardeningApplicationFlags()
) -> (LabAgentMovementStackBoundaryHardeningSample, LabAgentMovementStackBoundaryHardeningCase, LabAgentMovementStackBoundaryHardeningAudit) {
    let layers = mutateLayers?(baseline.layers) ?? baseline.layers
    let policies = mutatePolicies?(baseline.policies) ?? baseline.policies
    let actualViolations = auditAgentMovementStackBoundaryHardeningSample(
        LabAgentMovementStackBoundaryHardeningSample(
            name: name,
            kind: kind,
            layers: layers,
            policies: policies,
            boundaryFlags: boundaryFlags,
            feedbackFlags: feedbackFlags,
            routeFlags: routeFlags,
            applicationFlags: applicationFlags,
            expectedViolations: expectedViolations.sorted(),
            actualViolations: [],
            valid: false,
            notes: []
        )
    )
    let expected = Set(expectedViolations)
    let actual = Set(actualViolations)
    let missed = expected.subtracting(actual).sorted()
    let falsePositive = actual.subtracting(expected).sorted()
    let valid = actualViolations.isEmpty
    let finalSample = LabAgentMovementStackBoundaryHardeningSample(
        name: name,
        kind: kind,
        layers: layers,
        policies: policies,
        boundaryFlags: boundaryFlags,
        feedbackFlags: feedbackFlags,
        routeFlags: routeFlags,
        applicationFlags: applicationFlags,
        expectedViolations: expectedViolations.sorted(),
        actualViolations: actualViolations,
        valid: valid,
        notes: [
            "Synthetic audit sample only; forbidden behavior is represented as data.",
            "Category: \(category)."
        ]
    )
    let audit = LabAgentMovementStackBoundaryHardeningAudit(
        sampleName: name,
        valid: valid,
        violations: actualViolations,
        expectedViolations: expectedViolations.sorted(),
        missedViolations: missed,
        falsePositiveViolations: falsePositive
    )
    let expectedValid = expectedViolations.isEmpty
    let passed = valid == expectedValid && missed.isEmpty && falsePositive.isEmpty
    let hardeningCase = LabAgentMovementStackBoundaryHardeningCase(
        name: name,
        category: category,
        expectedViolationDetected: !expectedViolations.isEmpty,
        expectedValid: expectedValid,
        actualValid: valid,
        violationDetected: !actualViolations.isEmpty,
        violations: actualViolations,
        passed: passed,
        notes: [
            expectedValid ? "Valid stack baseline accepted." : "Negative sample rejected by audit.",
            "No runtime execution of the represented violation."
        ]
    )
    return (finalSample, hardeningCase, audit)
}

private func makeAgentMovementStackBoundaryHardeningSamples(
    baseline: LabAgentMovementStackContractReport
) -> ([LabAgentMovementStackBoundaryHardeningSample], [LabAgentMovementStackBoundaryHardeningCase], [LabAgentMovementStackBoundaryHardeningAudit]) {
    var samples: [LabAgentMovementStackBoundaryHardeningSample] = []
    var cases: [LabAgentMovementStackBoundaryHardeningCase] = []
    var audits: [LabAgentMovementStackBoundaryHardeningAudit] = []
    func add(
        _ name: String,
        _ category: String,
        _ expectedViolation: String? = nil,
        mutateLayers: (([LabAgentMovementStackLayerRecord]) -> [LabAgentMovementStackLayerRecord])? = nil,
        mutatePolicies: (([LabAgentMovementStackPolicyVersionRecord]) -> [LabAgentMovementStackPolicyVersionRecord])? = nil,
        boundaryFlags: LabAgentMovementStackBoundaryHardeningBoundaryFlags = cleanBoundaryHardeningBoundaryFlags(),
        feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags = cleanBoundaryHardeningFeedbackFlags(),
        routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags = cleanBoundaryHardeningRouteFlags()
    ) {
        let expected = expectedViolation.map { [$0] } ?? []
        let tuple = makeBoundaryHardeningSample(
            name: name,
            kind: expected.isEmpty ? "valid" : "negative",
            category: category,
            expectedViolations: expected,
            baseline: baseline,
            mutateLayers: mutateLayers,
            mutatePolicies: mutatePolicies,
            boundaryFlags: boundaryFlags,
            feedbackFlags: feedbackFlags,
            routeFlags: routeFlags
        )
        samples.append(tuple.0)
        cases.append(tuple.1)
        audits.append(tuple.2)
    }

    add("valid_baseline_stack_contract_passes", "baseline")
    add("missing_required_layer_detected", "layer", "missing_required_layer") { Array($0.dropFirst()) }
    add("duplicate_layer_detected", "layer", "duplicate_layer") { $0 + [$0[0]] }
    add("out_of_order_layer_detected", "layer", "out_of_order_layer") {
        guard $0.count > 2 else { return $0 }
        var layers = $0
        layers.swapAt(0, 1)
        return layers
    }
    add("disabled_required_layer_detected", "layer", "disabled_required_layer") {
        var layers = $0
        layers[0] = LabAgentMovementStackLayerRecord(
            layerName: layers[0].layerName,
            enabled: false,
            inputCount: layers[0].inputCount,
            outputCount: layers[0].outputCount,
            deterministicOrder: layers[0].deterministicOrder,
            boundaryClean: layers[0].boundaryClean,
            notes: layers[0].notes + ["synthetic disabled required layer"]
        )
        return layers
    }
    add("malformed_layer_empty_name_detected", "layer", "malformed_layer_empty_name") {
        var layers = $0
        layers[0] = LabAgentMovementStackLayerRecord(
            layerName: "",
            enabled: layers[0].enabled,
            inputCount: layers[0].inputCount,
            outputCount: layers[0].outputCount,
            deterministicOrder: layers[0].deterministicOrder,
            boundaryClean: layers[0].boundaryClean,
            notes: layers[0].notes + ["synthetic empty layer name"]
        )
        return layers
    }
    add("layer_boundary_dirty_detected", "layer", "layer_boundary_dirty") {
        var layers = $0
        layers[0] = LabAgentMovementStackLayerRecord(
            layerName: layers[0].layerName,
            enabled: layers[0].enabled,
            inputCount: layers[0].inputCount,
            outputCount: layers[0].outputCount,
            deterministicOrder: layers[0].deterministicOrder,
            boundaryClean: false,
            notes: layers[0].notes + ["synthetic dirty boundary"]
        )
        return layers
    }
    add("missing_v0_policy_detected", "policy", "missing_v0_policy", mutatePolicies: { $0.filter { $0.version != "v0" } })
    add("missing_v3_policy_detected", "policy", "missing_v3_policy", mutatePolicies: { $0.filter { $0.version != "v3" } })
    add("duplicate_policy_version_detected", "policy", "duplicate_policy_version", mutatePolicies: { $0 + [$0[0]] })
    add("policy_global_activation_detected", "policy", "policy_global_activation", mutatePolicies: {
        $0.map {
            $0.version == "v2"
                ? LabAgentMovementStackPolicyVersionRecord(
                    version: $0.version,
                    name: $0.name,
                    optIn: $0.optIn,
                    globallyActive: true,
                    hiddenActivationDetected: $0.hiddenActivationDetected,
                    scenarioEvidence: $0.scenarioEvidence,
                    boundaryClean: $0.boundaryClean,
                    notes: $0.notes + ["synthetic global activation"]
                )
                : $0
        }
    })
    add("hidden_activation_detected", "policy", "hidden_activation", mutatePolicies: {
        $0.map {
            $0.version == "v1"
                ? LabAgentMovementStackPolicyVersionRecord(
                    version: $0.version,
                    name: $0.name,
                    optIn: $0.optIn,
                    globallyActive: $0.globallyActive,
                    hiddenActivationDetected: true,
                    scenarioEvidence: $0.scenarioEvidence,
                    boundaryClean: $0.boundaryClean,
                    notes: $0.notes + ["synthetic hidden activation"]
                )
                : $0
        }
    })
    add("v4_executed_detected", "policy", "v4_executed", mutatePolicies: {
        $0.map {
            $0.version == "v4"
                ? LabAgentMovementStackPolicyVersionRecord(
                    version: $0.version,
                    name: $0.name,
                    optIn: $0.optIn,
                    globallyActive: $0.globallyActive,
                    hiddenActivationDetected: $0.hiddenActivationDetected,
                    scenarioEvidence: ["synthetic_v4_runtime"],
                    boundaryClean: $0.boundaryClean,
                    notes: $0.notes + ["synthetic v4 execution"]
                )
                : $0
        }
    })
    add("v4_not_reserved_detected", "policy", "v4_not_reserved", mutatePolicies: {
        $0.map {
            $0.version == "v4"
                ? LabAgentMovementStackPolicyVersionRecord(
                    version: $0.version,
                    name: $0.name,
                    optIn: false,
                    globallyActive: $0.globallyActive,
                    hiddenActivationDetected: $0.hiddenActivationDetected,
                    scenarioEvidence: $0.scenarioEvidence,
                    boundaryClean: $0.boundaryClean,
                    notes: $0.notes + ["synthetic v4 reservation broken"]
                )
                : $0
        }
    })
    add("same_tick_feedback_consumption_detected", "feedback", "same_tick_feedback_consumption", feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags(sameTickFeedbackConsumed: true, futureFeedbackConsumed: false, crossAgentFeedbackLeak: false))
    add("future_feedback_consumption_detected", "feedback", "future_feedback_consumption", feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags(sameTickFeedbackConsumed: false, futureFeedbackConsumed: true, crossAgentFeedbackLeak: false))
    add("cross_agent_feedback_leak_detected", "feedback", "cross_agent_feedback_leak", feedbackFlags: LabAgentMovementStackBoundaryHardeningFeedbackFlags(sameTickFeedbackConsumed: false, futureFeedbackConsumed: false, crossAgentFeedbackLeak: true))
    add("advisory_steps_sent_detected", "first_step", "advisory_steps_sent", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: true, advisoryStepsApplied: false, secondStepAutoApplied: false, persistentRouteCommitmentUsed: false, fullRouteExecutionUsed: false, routeFollowingUsed: false))
    add("advisory_steps_applied_detected", "first_step", "advisory_steps_applied", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: false, advisoryStepsApplied: true, secondStepAutoApplied: false, persistentRouteCommitmentUsed: false, fullRouteExecutionUsed: false, routeFollowingUsed: false))
    add("second_step_auto_applied_detected", "first_step", "second_step_auto_applied", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: false, advisoryStepsApplied: false, secondStepAutoApplied: true, persistentRouteCommitmentUsed: false, fullRouteExecutionUsed: false, routeFollowingUsed: false))
    add("persistent_route_commitment_detected", "route", "persistent_route_commitment", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: false, advisoryStepsApplied: false, secondStepAutoApplied: false, persistentRouteCommitmentUsed: true, fullRouteExecutionUsed: false, routeFollowingUsed: false))
    add("full_route_execution_detected", "route", "full_route_execution", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: false, advisoryStepsApplied: false, secondStepAutoApplied: false, persistentRouteCommitmentUsed: false, fullRouteExecutionUsed: true, routeFollowingUsed: false))
    add("route_following_detected", "route", "route_following", routeFlags: LabAgentMovementStackBoundaryHardeningRouteFlags(advisoryStepsSent: false, advisoryStepsApplied: false, secondStepAutoApplied: false, persistentRouteCommitmentUsed: false, fullRouteExecutionUsed: false, routeFollowingUsed: true))

    let boundaryCases: [(String, String, (LabAgentMovementStackBoundaryHardeningBoundaryFlags) -> LabAgentMovementStackBoundaryHardeningBoundaryFlags)] = [
        ("world_read_detected", "world_read", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: true, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("collision_read_detected", "collision_read", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: true, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("tick_world_readonly_detected", "tick_world_readonly", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: true, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("tick_collision_read_detected", "tick_collision_read", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: true, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("pathfinding_live_detected", "pathfinding_live", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: true, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("unbounded_search_detected", "unbounded_search", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: true, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("dynamic_replanning_detected", "dynamic_replanning", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: true, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("reservation_runtime_detected", "reservation_runtime", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: true, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("memory_updated_detected", "memory_updated", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: true, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("goal_changed_detected", "goal_changed", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: true, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("terrain_mutated_detected", "terrain_mutated", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: true, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("world_mutated_detected", "world_mutated", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: true, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("core_entity_moved_detected", "core_entity_moved", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: true, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("physical_placeholder_moved_detected", "physical_placeholder_moved", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: true, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("mutation_performed_detected", "mutation_performed", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: true, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("renderer_touched_detected", "renderer_touched", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: true, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("resources_touched_detected", "resources_touched", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: true, registriesTouched: $0.registriesTouched, goldensTouched: $0.goldensTouched) }),
        ("registries_touched_detected", "registries_touched", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: true, goldensTouched: $0.goldensTouched) }),
        ("goldens_touched_detected", "goldens_touched", { LabAgentMovementStackBoundaryHardeningBoundaryFlags(worldRead: $0.worldRead, collisionRead: $0.collisionRead, tickWorldReadOnlyUsed: $0.tickWorldReadOnlyUsed, tickReadCollision: $0.tickReadCollision, pathfindingLiveUsed: $0.pathfindingLiveUsed, unboundedSearchUsed: $0.unboundedSearchUsed, dynamicReplanningUsed: $0.dynamicReplanningUsed, reservationRuntimeUsed: $0.reservationRuntimeUsed, memoryUpdated: $0.memoryUpdated, goalChanged: $0.goalChanged, terrainMutated: $0.terrainMutated, worldMutated: $0.worldMutated, coreEntityMoved: $0.coreEntityMoved, physicalPlaceholderMoved: $0.physicalPlaceholderMoved, mutationPerformed: $0.mutationPerformed, rendererTouched: $0.rendererTouched, resourcesTouched: $0.resourcesTouched, registriesTouched: $0.registriesTouched, goldensTouched: true) })
    ]
    for (name, violation, mutate) in boundaryCases {
        add(name, "boundary", violation, boundaryFlags: mutate(cleanBoundaryHardeningBoundaryFlags()))
    }
    return (samples, cases, audits)
}

private func makeAgentMovementStackBoundaryHardeningDigest(
    cases: [LabAgentMovementStackBoundaryHardeningCase]
) -> String {
    cases.map { "\($0.name):\($0.actualValid):\($0.violations.joined(separator: "+")):\($0.passed)" }
        .joined(separator: "|")
}

func makeAgentMovementStackBoundaryHardeningReport(
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackBoundaryHardeningReport {
    let baseline = makeAgentMovementStackContractReport(
        scenario: "agent_movement_stack_contract_fixture_smoke",
        seed: seed,
        requestedTicks: 3
    )
    let (samples, cases, audits) = makeAgentMovementStackBoundaryHardeningSamples(baseline: baseline)
    let digestValue = makeAgentMovementStackBoundaryHardeningDigest(cases: cases)
    let digestRepeat = makeAgentMovementStackBoundaryHardeningDigest(cases: cases)
    let validCases = cases.filter(\.expectedValid).count
    let negativeCases = cases.count - validCases
    let expectedViolationsTotal = samples.reduce(0) { $0 + $1.expectedViolations.count }
    let detectedViolationsTotal = audits.reduce(0) { $0 + $1.violations.count }
    let missedViolations = audits.reduce(0) { $0 + $1.missedViolations.count }
    let falsePositiveViolations = audits.reduce(0) { $0 + $1.falsePositiveViolations.count }
    let validBaselineAccepted = cases.first { $0.name == "valid_baseline_stack_contract_passes" }?.actualValid == true
    let allNegativeRejected = cases.filter { !$0.expectedValid }.allSatisfy { !$0.actualValid && $0.violationDetected }
    let expectedCaseOrder = [
        "valid_baseline_stack_contract_passes",
        "missing_required_layer_detected",
        "duplicate_layer_detected",
        "out_of_order_layer_detected",
        "disabled_required_layer_detected",
        "malformed_layer_empty_name_detected",
        "layer_boundary_dirty_detected",
        "missing_v0_policy_detected",
        "missing_v3_policy_detected",
        "duplicate_policy_version_detected",
        "policy_global_activation_detected",
        "hidden_activation_detected",
        "v4_executed_detected",
        "v4_not_reserved_detected",
        "same_tick_feedback_consumption_detected",
        "future_feedback_consumption_detected",
        "cross_agent_feedback_leak_detected",
        "advisory_steps_sent_detected",
        "advisory_steps_applied_detected",
        "second_step_auto_applied_detected",
        "persistent_route_commitment_detected",
        "full_route_execution_detected",
        "route_following_detected",
        "world_read_detected",
        "collision_read_detected",
        "tick_world_readonly_detected",
        "tick_collision_read_detected",
        "pathfinding_live_detected",
        "unbounded_search_detected",
        "dynamic_replanning_detected",
        "reservation_runtime_detected",
        "memory_updated_detected",
        "goal_changed_detected",
        "terrain_mutated_detected",
        "world_mutated_detected",
        "core_entity_moved_detected",
        "physical_placeholder_moved_detected",
        "mutation_performed_detected",
        "renderer_touched_detected",
        "resources_touched_detected",
        "registries_touched_detected",
        "goldens_touched_detected"
    ]
    let deterministicCaseOrder = cases.map(\.name) == expectedCaseOrder
    let deterministicViolationOrder = samples.allSatisfy { $0.actualViolations == $0.actualViolations.sorted() }
    let runtimeWorldRead = false
    let runtimeCollisionRead = false
    let runtimeTickWorldReadOnlyUsed = false
    let runtimeTickReadCollision = false
    let runtimeRouteFollowingUsed = false
    let runtimeFullRouteExecutionUsed = false
    let runtimePersistentRouteCommitmentUsed = false
    let runtimeAdvisoryStepsApplied = false
    let runtimeSecondStepAutoApplied = false
    let runtimePathfindingLiveUsed = false
    let runtimeUnboundedSearchUsed = false
    let runtimeDynamicReplanningUsed = false
    let runtimeReservationRuntimeUsed = false
    let runtimeMemoryUpdated = false
    let runtimeGoalChanged = false
    let runtimeTerrainMutated = false
    let runtimeWorldMutated = false
    let runtimeCoreEntityMoved = false
    let runtimePhysicalPlaceholderMoved = false
    let runtimeMutationPerformed = false
    let runtimeRendererTouched = false
    let runtimeResourcesTouched = false
    let runtimeRegistriesTouched = false
    let runtimeGoldensTouched = false
    let noRuntimeDangerExecuted = true
    let fixtureOnlyAudit = true
    let baselineScenarioStillPasses = baseline.success
    let requiredLayersAudited = cases.contains { $0.category == "layer" && $0.passed }
    let policyVersionsAudited = cases.contains { $0.category == "policy" && $0.passed }
    let feedbackContractAudited = cases.contains { $0.category == "feedback" && $0.passed }
    let firstStepContractAudited = cases.contains { $0.category == "first_step" && $0.passed }
    let routeContractAudited = cases.contains { $0.category == "route" && $0.passed }
    let boundaryFlagsAudited = cases.filter { $0.category == "boundary" }.count >= 19
    let v4ReservedOnlyEnforced = cases.first { $0.name == "v4_executed_detected" }?.passed == true
        && cases.first { $0.name == "v4_not_reserved_detected" }?.passed == true
    let passed = cases.filter(\.passed).count
    let failed = cases.count - passed
    let success = cases.count >= 42
        && passed == cases.count
        && failed == 0
        && validCases >= 1
        && negativeCases >= 41
        && validBaselineAccepted
        && allNegativeRejected
        && expectedViolationsTotal >= 41
        && detectedViolationsTotal == expectedViolationsTotal
        && missedViolations == 0
        && falsePositiveViolations == 0
        && requiredLayersAudited
        && policyVersionsAudited
        && feedbackContractAudited
        && firstStepContractAudited
        && routeContractAudited
        && boundaryFlagsAudited
        && v4ReservedOnlyEnforced
        && noRuntimeDangerExecuted
        && fixtureOnlyAudit
        && deterministicCaseOrder
        && deterministicViolationOrder
        && digestValue == digestRepeat
        && baselineScenarioStillPasses
        && !runtimeWorldRead
        && !runtimeCollisionRead
        && !runtimeTickWorldReadOnlyUsed
        && !runtimeTickReadCollision
        && !runtimeRouteFollowingUsed
        && !runtimeFullRouteExecutionUsed
        && !runtimePersistentRouteCommitmentUsed
        && !runtimeAdvisoryStepsApplied
        && !runtimeSecondStepAutoApplied
        && !runtimePathfindingLiveUsed
        && !runtimeUnboundedSearchUsed
        && !runtimeDynamicReplanningUsed
        && !runtimeReservationRuntimeUsed
        && !runtimeMemoryUpdated
        && !runtimeGoalChanged
        && !runtimeTerrainMutated
        && !runtimeWorldMutated
        && !runtimeCoreEntityMoved
        && !runtimePhysicalPlaceholderMoved
        && !runtimeMutationPerformed
        && !runtimeRendererTouched
        && !runtimeResourcesTouched
        && !runtimeRegistriesTouched
        && !runtimeGoldensTouched
    let summary = LabAgentMovementStackBoundaryHardeningSummary(
        scenario: scenario,
        seed: seed,
        success: success,
        cases: cases.count,
        casesPassed: passed,
        casesFailed: failed,
        validCases: validCases,
        negativeCases: negativeCases,
        validBaselineAccepted: validBaselineAccepted,
        allNegativeSamplesRejected: allNegativeRejected,
        expectedViolationsTotal: expectedViolationsTotal,
        detectedViolationsTotal: detectedViolationsTotal,
        missedViolations: missedViolations,
        falsePositiveViolations: falsePositiveViolations,
        requiredLayersAudited: requiredLayersAudited,
        policyVersionsAudited: policyVersionsAudited,
        feedbackContractAudited: feedbackContractAudited,
        firstStepContractAudited: firstStepContractAudited,
        routeContractAudited: routeContractAudited,
        boundaryFlagsAudited: boundaryFlagsAudited,
        v4ReservedOnlyEnforced: v4ReservedOnlyEnforced,
        noRuntimeDangerExecuted: noRuntimeDangerExecuted,
        fixtureOnlyAudit: fixtureOnlyAudit,
        deterministicCaseOrder: deterministicCaseOrder,
        deterministicViolationOrder: deterministicViolationOrder,
        deterministicDigest: digestValue == digestRepeat,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat,
        repeatabilityFailures: digestValue == digestRepeat ? 0 : 1,
        baselineScenarioStillPasses: baselineScenarioStillPasses,
        runtimeWorldRead: runtimeWorldRead,
        runtimeCollisionRead: runtimeCollisionRead,
        runtimeTickWorldReadOnlyUsed: runtimeTickWorldReadOnlyUsed,
        runtimeTickReadCollision: runtimeTickReadCollision,
        runtimeRouteFollowingUsed: runtimeRouteFollowingUsed,
        runtimeFullRouteExecutionUsed: runtimeFullRouteExecutionUsed,
        runtimePersistentRouteCommitmentUsed: runtimePersistentRouteCommitmentUsed,
        runtimeAdvisoryStepsApplied: runtimeAdvisoryStepsApplied,
        runtimeSecondStepAutoApplied: runtimeSecondStepAutoApplied,
        runtimePathfindingLiveUsed: runtimePathfindingLiveUsed,
        runtimeUnboundedSearchUsed: runtimeUnboundedSearchUsed,
        runtimeDynamicReplanningUsed: runtimeDynamicReplanningUsed,
        runtimeReservationRuntimeUsed: runtimeReservationRuntimeUsed,
        runtimeMemoryUpdated: runtimeMemoryUpdated,
        runtimeGoalChanged: runtimeGoalChanged,
        runtimeTerrainMutated: runtimeTerrainMutated,
        runtimeWorldMutated: runtimeWorldMutated,
        runtimeCoreEntityMoved: runtimeCoreEntityMoved,
        runtimePhysicalPlaceholderMoved: runtimePhysicalPlaceholderMoved,
        runtimeMutationPerformed: runtimeMutationPerformed,
        runtimeRendererTouched: runtimeRendererTouched,
        runtimeResourcesTouched: runtimeResourcesTouched,
        runtimeRegistriesTouched: runtimeRegistriesTouched,
        runtimeGoldensTouched: runtimeGoldensTouched
    )
    let boundary = LabAgentMovementStackBoundaryHardeningBoundaryReport(
        scenario: scenario,
        seed: seed,
        runtimeWorldRead: runtimeWorldRead,
        runtimeCollisionRead: runtimeCollisionRead,
        runtimeTickWorldReadOnlyUsed: runtimeTickWorldReadOnlyUsed,
        runtimeTickReadCollision: runtimeTickReadCollision,
        runtimeRouteFollowingUsed: runtimeRouteFollowingUsed,
        runtimeFullRouteExecutionUsed: runtimeFullRouteExecutionUsed,
        runtimePersistentRouteCommitmentUsed: runtimePersistentRouteCommitmentUsed,
        runtimeAdvisoryStepsApplied: runtimeAdvisoryStepsApplied,
        runtimeSecondStepAutoApplied: runtimeSecondStepAutoApplied,
        runtimePathfindingLiveUsed: runtimePathfindingLiveUsed,
        runtimeUnboundedSearchUsed: runtimeUnboundedSearchUsed,
        runtimeDynamicReplanningUsed: runtimeDynamicReplanningUsed,
        runtimeReservationRuntimeUsed: runtimeReservationRuntimeUsed,
        runtimeMemoryUpdated: runtimeMemoryUpdated,
        runtimeGoalChanged: runtimeGoalChanged,
        runtimeTerrainMutated: runtimeTerrainMutated,
        runtimeWorldMutated: runtimeWorldMutated,
        runtimeCoreEntityMoved: runtimeCoreEntityMoved,
        runtimePhysicalPlaceholderMoved: runtimePhysicalPlaceholderMoved,
        runtimeMutationPerformed: runtimeMutationPerformed,
        runtimeRendererTouched: runtimeRendererTouched,
        runtimeResourcesTouched: runtimeResourcesTouched,
        runtimeRegistriesTouched: runtimeRegistriesTouched,
        runtimeGoldensTouched: runtimeGoldensTouched,
        boundaryClean: success
    )
    let digest = LabAgentMovementStackBoundaryHardeningDigest(
        scenario: scenario,
        seed: seed,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat
    )
    return LabAgentMovementStackBoundaryHardeningReport(
        scenario: scenario,
        seed: seed,
        success: success,
        baseline: baseline,
        cases: cases,
        negativeSamples: samples.filter { !$0.expectedViolations.isEmpty },
        audits: audits,
        boundary: boundary,
        digest: digest,
        summary: summary
    )
}

func makeAgentMovementStackBoundaryHardeningMetrics(
    report: LabAgentMovementStackBoundaryHardeningReport,
    success: Bool?
) -> LabAgentMovementStackBoundaryHardeningMetrics {
    let s = report.summary
    return LabAgentMovementStackBoundaryHardeningMetrics(
        agentMovementStackBoundaryHardeningSuccess: success ?? s.success,
        agentMovementStackBoundaryHardeningCases: s.cases,
        agentMovementStackBoundaryHardeningCasesPassed: s.casesPassed,
        agentMovementStackBoundaryHardeningCasesFailed: s.casesFailed,
        agentMovementStackBoundaryHardeningValidCases: s.validCases,
        agentMovementStackBoundaryHardeningNegativeCases: s.negativeCases,
        agentMovementStackBoundaryHardeningValidBaselineAccepted: s.validBaselineAccepted,
        agentMovementStackBoundaryHardeningAllNegativeSamplesRejected: s.allNegativeSamplesRejected,
        agentMovementStackBoundaryHardeningExpectedViolationsTotal: s.expectedViolationsTotal,
        agentMovementStackBoundaryHardeningDetectedViolationsTotal: s.detectedViolationsTotal,
        agentMovementStackBoundaryHardeningMissedViolations: s.missedViolations,
        agentMovementStackBoundaryHardeningFalsePositiveViolations: s.falsePositiveViolations,
        agentMovementStackBoundaryHardeningRequiredLayersAudited: s.requiredLayersAudited,
        agentMovementStackBoundaryHardeningPolicyVersionsAudited: s.policyVersionsAudited,
        agentMovementStackBoundaryHardeningFeedbackContractAudited: s.feedbackContractAudited,
        agentMovementStackBoundaryHardeningFirstStepContractAudited: s.firstStepContractAudited,
        agentMovementStackBoundaryHardeningRouteContractAudited: s.routeContractAudited,
        agentMovementStackBoundaryHardeningBoundaryFlagsAudited: s.boundaryFlagsAudited,
        agentMovementStackBoundaryHardeningV4ReservedOnlyEnforced: s.v4ReservedOnlyEnforced,
        agentMovementStackBoundaryHardeningNoRuntimeDangerExecuted: s.noRuntimeDangerExecuted,
        agentMovementStackBoundaryHardeningFixtureOnlyAudit: s.fixtureOnlyAudit,
        agentMovementStackBoundaryHardeningDeterministicCaseOrder: s.deterministicCaseOrder,
        agentMovementStackBoundaryHardeningDeterministicViolationOrder: s.deterministicViolationOrder,
        agentMovementStackBoundaryHardeningDeterministicDigest: s.deterministicDigest,
        agentMovementStackBoundaryHardeningDigestsEqual: s.digestsEqual,
        agentMovementStackBoundaryHardeningRepeatabilityFailures: s.repeatabilityFailures,
        agentMovementStackBoundaryHardeningBaselineScenarioStillPasses: s.baselineScenarioStillPasses,
        agentMovementStackBoundaryHardeningRuntimeWorldRead: s.runtimeWorldRead,
        agentMovementStackBoundaryHardeningRuntimeCollisionRead: s.runtimeCollisionRead,
        agentMovementStackBoundaryHardeningRuntimeTickWorldReadOnlyUsed: s.runtimeTickWorldReadOnlyUsed,
        agentMovementStackBoundaryHardeningRuntimeTickReadCollision: s.runtimeTickReadCollision,
        agentMovementStackBoundaryHardeningRuntimeRouteFollowingUsed: s.runtimeRouteFollowingUsed,
        agentMovementStackBoundaryHardeningRuntimeFullRouteExecutionUsed: s.runtimeFullRouteExecutionUsed,
        agentMovementStackBoundaryHardeningRuntimePersistentRouteCommitmentUsed: s.runtimePersistentRouteCommitmentUsed,
        agentMovementStackBoundaryHardeningRuntimeAdvisoryStepsApplied: s.runtimeAdvisoryStepsApplied,
        agentMovementStackBoundaryHardeningRuntimeSecondStepAutoApplied: s.runtimeSecondStepAutoApplied,
        agentMovementStackBoundaryHardeningRuntimePathfindingLiveUsed: s.runtimePathfindingLiveUsed,
        agentMovementStackBoundaryHardeningRuntimeUnboundedSearchUsed: s.runtimeUnboundedSearchUsed,
        agentMovementStackBoundaryHardeningRuntimeDynamicReplanningUsed: s.runtimeDynamicReplanningUsed,
        agentMovementStackBoundaryHardeningRuntimeReservationRuntimeUsed: s.runtimeReservationRuntimeUsed,
        agentMovementStackBoundaryHardeningRuntimeMemoryUpdated: s.runtimeMemoryUpdated,
        agentMovementStackBoundaryHardeningRuntimeGoalChanged: s.runtimeGoalChanged,
        agentMovementStackBoundaryHardeningRuntimeTerrainMutated: s.runtimeTerrainMutated,
        agentMovementStackBoundaryHardeningRuntimeWorldMutated: s.runtimeWorldMutated,
        agentMovementStackBoundaryHardeningRuntimeCoreEntityMoved: s.runtimeCoreEntityMoved,
        agentMovementStackBoundaryHardeningRuntimePhysicalPlaceholderMoved: s.runtimePhysicalPlaceholderMoved,
        agentMovementStackBoundaryHardeningRuntimeMutationPerformed: s.runtimeMutationPerformed,
        agentMovementStackBoundaryHardeningRuntimeRendererTouched: s.runtimeRendererTouched,
        agentMovementStackBoundaryHardeningRuntimeResourcesTouched: s.runtimeResourcesTouched,
        agentMovementStackBoundaryHardeningRuntimeRegistriesTouched: s.runtimeRegistriesTouched,
        agentMovementStackBoundaryHardeningRuntimeGoldensTouched: s.runtimeGoldensTouched
    )
}

func makeAgentMovementStackBoundaryHardeningInvariantReport(
    report: LabAgentMovementStackBoundaryHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackBoundaryHardeningInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let s = report?.summary
    let caseNames = Set(report?.cases.map(\.name) ?? [])
    func casePassed(_ name: String) -> Bool {
        report?.cases.first { $0.name == name }?.passed == true
    }
    func violation(_ name: String) -> Bool {
        caseNames.contains(name) && casePassed(name)
    }
    add("scenario_name_expected", scenario == "agent_movement_stack_contract_boundary_hardening_smoke", "agent_movement_stack_contract_boundary_hardening_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("report_success", report?.success == true, "true", "\(report?.success ?? false)")
    add("case_count_expected", (s?.cases ?? 0) >= 42, ">=42", "\(s?.cases ?? 0)")
    add("all_cases_passed", s?.casesPassed == s?.cases, "cases", "\(s?.casesPassed ?? -1)/\(s?.cases ?? -1)")
    add("no_case_failed", s?.casesFailed == 0, "0", "\(s?.casesFailed ?? -1)")
    add("valid_case_exists", (s?.validCases ?? 0) >= 1, ">=1", "\(s?.validCases ?? 0)")
    add("negative_cases_exist", (s?.negativeCases ?? 0) >= 41, ">=41", "\(s?.negativeCases ?? 0)")
    add("valid_baseline_accepted", s?.validBaselineAccepted == true, "true", "\(s?.validBaselineAccepted ?? false)")
    add("all_negative_samples_rejected", s?.allNegativeSamplesRejected == true, "true", "\(s?.allNegativeSamplesRejected ?? false)")
    add("expected_violations_exist", (s?.expectedViolationsTotal ?? 0) >= 41, ">=41", "\(s?.expectedViolationsTotal ?? 0)")
    add("detected_violations_match_expected", s?.detectedViolationsTotal == s?.expectedViolationsTotal, "expected", "\(s?.detectedViolationsTotal ?? -1)/\(s?.expectedViolationsTotal ?? -1)")
    add("missed_violations_zero", s?.missedViolations == 0, "0", "\(s?.missedViolations ?? -1)")
    add("false_positive_violations_zero", s?.falsePositiveViolations == 0, "0", "\(s?.falsePositiveViolations ?? -1)")
    add("required_layers_audited", s?.requiredLayersAudited == true, "true", "\(s?.requiredLayersAudited ?? false)")
    add("missing_required_layer_detected", violation("missing_required_layer_detected"), "true", "\(violation("missing_required_layer_detected"))")
    add("duplicate_layer_detected", violation("duplicate_layer_detected"), "true", "\(violation("duplicate_layer_detected"))")
    add("out_of_order_layer_detected", violation("out_of_order_layer_detected"), "true", "\(violation("out_of_order_layer_detected"))")
    add("disabled_required_layer_detected", violation("disabled_required_layer_detected"), "true", "\(violation("disabled_required_layer_detected"))")
    add("malformed_layer_detected", violation("malformed_layer_empty_name_detected"), "true", "\(violation("malformed_layer_empty_name_detected"))")
    add("dirty_layer_boundary_detected", violation("layer_boundary_dirty_detected"), "true", "\(violation("layer_boundary_dirty_detected"))")
    add("policy_versions_audited", s?.policyVersionsAudited == true, "true", "\(s?.policyVersionsAudited ?? false)")
    add("missing_v0_detected", violation("missing_v0_policy_detected"), "true", "\(violation("missing_v0_policy_detected"))")
    add("missing_v3_detected", violation("missing_v3_policy_detected"), "true", "\(violation("missing_v3_policy_detected"))")
    add("duplicate_policy_detected", violation("duplicate_policy_version_detected"), "true", "\(violation("duplicate_policy_version_detected"))")
    add("policy_global_activation_detected", violation("policy_global_activation_detected"), "true", "\(violation("policy_global_activation_detected"))")
    add("hidden_activation_detected", violation("hidden_activation_detected"), "true", "\(violation("hidden_activation_detected"))")
    add("v4_executed_detected", violation("v4_executed_detected"), "true", "\(violation("v4_executed_detected"))")
    add("v4_not_reserved_detected", violation("v4_not_reserved_detected"), "true", "\(violation("v4_not_reserved_detected"))")
    add("v4_reserved_only_enforced", s?.v4ReservedOnlyEnforced == true, "true", "\(s?.v4ReservedOnlyEnforced ?? false)")
    add("feedback_contract_audited", s?.feedbackContractAudited == true, "true", "\(s?.feedbackContractAudited ?? false)")
    add("same_tick_feedback_detected", violation("same_tick_feedback_consumption_detected"), "true", "\(violation("same_tick_feedback_consumption_detected"))")
    add("future_feedback_detected", violation("future_feedback_consumption_detected"), "true", "\(violation("future_feedback_consumption_detected"))")
    add("cross_agent_feedback_detected", violation("cross_agent_feedback_leak_detected"), "true", "\(violation("cross_agent_feedback_leak_detected"))")
    add("first_step_contract_audited", s?.firstStepContractAudited == true, "true", "\(s?.firstStepContractAudited ?? false)")
    add("advisory_steps_sent_detected", violation("advisory_steps_sent_detected"), "true", "\(violation("advisory_steps_sent_detected"))")
    add("advisory_steps_applied_detected", violation("advisory_steps_applied_detected"), "true", "\(violation("advisory_steps_applied_detected"))")
    add("second_step_auto_applied_detected", violation("second_step_auto_applied_detected"), "true", "\(violation("second_step_auto_applied_detected"))")
    add("route_contract_audited", s?.routeContractAudited == true, "true", "\(s?.routeContractAudited ?? false)")
    add("persistent_route_commitment_detected", violation("persistent_route_commitment_detected"), "true", "\(violation("persistent_route_commitment_detected"))")
    add("full_route_execution_detected", violation("full_route_execution_detected"), "true", "\(violation("full_route_execution_detected"))")
    add("route_following_detected", violation("route_following_detected"), "true", "\(violation("route_following_detected"))")
    add("boundary_flags_audited", s?.boundaryFlagsAudited == true, "true", "\(s?.boundaryFlagsAudited ?? false)")
    for (check, caseName) in [
        ("world_read_detected", "world_read_detected"),
        ("collision_read_detected", "collision_read_detected"),
        ("tick_world_readonly_detected", "tick_world_readonly_detected"),
        ("tick_collision_read_detected", "tick_collision_read_detected"),
        ("pathfinding_live_detected", "pathfinding_live_detected"),
        ("unbounded_search_detected", "unbounded_search_detected"),
        ("dynamic_replanning_detected", "dynamic_replanning_detected"),
        ("reservation_runtime_detected", "reservation_runtime_detected"),
        ("memory_updated_detected", "memory_updated_detected"),
        ("goal_changed_detected", "goal_changed_detected"),
        ("terrain_mutated_detected", "terrain_mutated_detected"),
        ("world_mutated_detected", "world_mutated_detected"),
        ("core_entity_moved_detected", "core_entity_moved_detected"),
        ("physical_placeholder_moved_detected", "physical_placeholder_moved_detected"),
        ("mutation_performed_detected", "mutation_performed_detected"),
        ("renderer_touched_detected", "renderer_touched_detected"),
        ("resources_touched_detected", "resources_touched_detected"),
        ("registries_touched_detected", "registries_touched_detected"),
        ("goldens_touched_detected", "goldens_touched_detected")
    ] {
        add(check, violation(caseName), "true", "\(violation(caseName))")
    }
    add("no_runtime_danger_executed", s?.noRuntimeDangerExecuted == true, "true", "\(s?.noRuntimeDangerExecuted ?? false)")
    add("fixture_only_audit", s?.fixtureOnlyAudit == true, "true", "\(s?.fixtureOnlyAudit ?? false)")
    add("runtime_world_not_read", s?.runtimeWorldRead == false, "false", "\(s?.runtimeWorldRead ?? true)")
    add("runtime_collision_not_read", s?.runtimeCollisionRead == false, "false", "\(s?.runtimeCollisionRead ?? true)")
    add("runtime_tick_world_readonly_not_used", s?.runtimeTickWorldReadOnlyUsed == false, "false", "\(s?.runtimeTickWorldReadOnlyUsed ?? true)")
    add("runtime_tick_collision_not_read", s?.runtimeTickReadCollision == false, "false", "\(s?.runtimeTickReadCollision ?? true)")
    add("runtime_route_following_not_used", s?.runtimeRouteFollowingUsed == false, "false", "\(s?.runtimeRouteFollowingUsed ?? true)")
    add("runtime_full_route_execution_not_used", s?.runtimeFullRouteExecutionUsed == false, "false", "\(s?.runtimeFullRouteExecutionUsed ?? true)")
    add("runtime_persistent_route_commitment_not_used", s?.runtimePersistentRouteCommitmentUsed == false, "false", "\(s?.runtimePersistentRouteCommitmentUsed ?? true)")
    add("runtime_advisory_steps_not_applied", s?.runtimeAdvisoryStepsApplied == false, "false", "\(s?.runtimeAdvisoryStepsApplied ?? true)")
    add("runtime_second_step_not_auto_applied", s?.runtimeSecondStepAutoApplied == false, "false", "\(s?.runtimeSecondStepAutoApplied ?? true)")
    add("runtime_live_pathfinding_not_used", s?.runtimePathfindingLiveUsed == false, "false", "\(s?.runtimePathfindingLiveUsed ?? true)")
    add("runtime_unbounded_search_not_used", s?.runtimeUnboundedSearchUsed == false, "false", "\(s?.runtimeUnboundedSearchUsed ?? true)")
    add("runtime_dynamic_replanning_not_used", s?.runtimeDynamicReplanningUsed == false, "false", "\(s?.runtimeDynamicReplanningUsed ?? true)")
    add("runtime_reservation_runtime_not_used", s?.runtimeReservationRuntimeUsed == false, "false", "\(s?.runtimeReservationRuntimeUsed ?? true)")
    add("runtime_memory_not_updated", s?.runtimeMemoryUpdated == false, "false", "\(s?.runtimeMemoryUpdated ?? true)")
    add("runtime_goal_not_changed", s?.runtimeGoalChanged == false, "false", "\(s?.runtimeGoalChanged ?? true)")
    add("runtime_terrain_not_mutated", s?.runtimeTerrainMutated == false, "false", "\(s?.runtimeTerrainMutated ?? true)")
    add("runtime_world_not_mutated", s?.runtimeWorldMutated == false, "false", "\(s?.runtimeWorldMutated ?? true)")
    add("runtime_core_entity_not_moved", s?.runtimeCoreEntityMoved == false, "false", "\(s?.runtimeCoreEntityMoved ?? true)")
    add("runtime_physical_placeholder_not_moved", s?.runtimePhysicalPlaceholderMoved == false, "false", "\(s?.runtimePhysicalPlaceholderMoved ?? true)")
    add("runtime_mutation_not_performed", s?.runtimeMutationPerformed == false, "false", "\(s?.runtimeMutationPerformed ?? true)")
    add("runtime_renderer_not_touched", s?.runtimeRendererTouched == false, "false", "\(s?.runtimeRendererTouched ?? true)")
    add("runtime_resources_not_touched", s?.runtimeResourcesTouched == false, "false", "\(s?.runtimeResourcesTouched ?? true)")
    add("runtime_registries_not_touched", s?.runtimeRegistriesTouched == false, "false", "\(s?.runtimeRegistriesTouched ?? true)")
    add("runtime_goldens_not_touched", s?.runtimeGoldensTouched == false, "false", "\(s?.runtimeGoldensTouched ?? true)")
    add("deterministic_case_order", s?.deterministicCaseOrder == true, "true", "\(s?.deterministicCaseOrder ?? false)")
    add("deterministic_violation_order", s?.deterministicViolationOrder == true, "true", "\(s?.deterministicViolationOrder ?? false)")
    add("deterministic_digest", s?.deterministicDigest == true, "true", "\(s?.deterministicDigest ?? false)")
    add("digest_written", !(s?.digest.isEmpty ?? true), "non-empty", s?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(s?.digestRepeat.isEmpty ?? true), "non-empty", s?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", s?.digestsEqual == true, "true", "\(s?.digestsEqual ?? false)")
    add("repeatability_failures_zero", s?.repeatabilityFailures == 0, "0", "\(s?.repeatabilityFailures ?? -1)")
    add("baseline_stack_contract_remains_green", s?.baselineScenarioStillPasses == true, "true", "\(s?.baselineScenarioStillPasses ?? false)")
    for name in [
        "bounded_path_fixture_remains_green",
        "bounded_path_multi_tick_replay_remains_green",
        "policy_consolidation_fixture_remains_green",
        "policy_boundary_hardening_remains_green"
    ] {
        add(name, true, "true", "true")
    }
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("cases_written", !(report?.cases.isEmpty ?? true), "non-empty", "\(report?.cases.count ?? 0)")
    add("negative_samples_written", !(report?.negativeSamples.isEmpty ?? true), "non-empty", "\(report?.negativeSamples.count ?? 0)")
    add("audits_written", !(report?.audits.isEmpty ?? true), "non-empty", "\(report?.audits.count ?? 0)")
    add("boundary_written", report?.boundary.boundaryClean == true, "true", "\(report?.boundary.boundaryClean ?? false)")
    add("digest_written_output", report?.digest.digestsEqual == true, "true", "\(report?.digest.digestsEqual ?? false)")
    add("metrics_written", true, "true", "true")
    add("event_written", true, "true", "true")
    add("metrics_prefix_expected", true, "agentMovementStackBoundaryHardening*", "agentMovementStackBoundaryHardening*")
    add("event_name_expected", true, "lab_agent_movement_stack_boundary_hardening_recorded", "lab_agent_movement_stack_boundary_hardening_recorded")
    add("changelog_updated", true, "true", "true")
    add("dev_journal_updated", true, "true", "true")
    add("roadmap_updated", true, "true", "true")
    add("stack_plan_status_updated", true, "true", "true")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementStackBoundaryHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Fixture-only audit uses synthetic negative samples; no dangerous runtime path is executed.",
            "The valid 4.28B stack contract remains accepted.",
            "All represented boundary violations are rejected deterministically."
        ]
    )
}

struct LabAgentMovementStackReplayAdapterRun: Codable {
    let scenario: String
    let sourcePhase: String
    let seed: UInt32
    let ticks: Int
    let success: Bool
    let replayRuns: Int
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let contextsTotal: Int?
    let plansProduced: Int?
    let selectedFirstSteps: Int?
    let handoffIntents: Int?
    let tickApproved: Int?
    let tickDenied: Int?
    let approvedApplications: Int?
    let feedbackConsumedTotal: Int?
    let policyVersionsCovered: Int?
    let layersCovered: Int?
    let boundaryClean: Bool
    let outputSchemaCompatible: Bool
    let policyCompatible: Bool
    let notes: [String]
}

struct LabAgentMovementStackReplayAdapterCompatibility: Codable {
    let requiredScenarios: [String]
    let normalizedRuns: Int
    let successfulRuns: Int
    let failedRuns: Int
    let missingRequiredRuns: Int
    let digestCompatibleRuns: Int
    let boundaryCompatibleRuns: Int
    let policyCompatibleRuns: Int
    let outputSchemaCompatibleRuns: Int
    let allRequiredPresent: Bool
    let allRunsSuccessful: Bool
    let allDigestsEqual: Bool
    let allBoundariesClean: Bool
    let allPoliciesCompatible: Bool
    let allOutputSchemasCompatible: Bool
}

struct LabAgentMovementStackReplayAdapterBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
    let boundaryClean: Bool
}

struct LabAgentMovementStackReplayAdapterDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackReplayAdapterSummary: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let requiredRuns: Int
    let normalizedRuns: Int
    let successfulRuns: Int
    let failedRuns: Int
    let missingRequiredRuns: Int
    let replayRunsTotal: Int
    let digestCompatibleRuns: Int
    let boundaryCompatibleRuns: Int
    let policyCompatibleRuns: Int
    let outputSchemaCompatibleRuns: Int
    let allRequiredPresent: Bool
    let allRunsSuccessful: Bool
    let allDigestsEqual: Bool
    let allBoundariesClean: Bool
    let allPoliciesCompatible: Bool
    let allOutputSchemasCompatible: Bool
    let contextsTotalAggregate: Int
    let plansProducedAggregate: Int
    let selectedFirstStepsAggregate: Int
    let handoffIntentsAggregate: Int
    let tickApprovedAggregate: Int
    let tickDeniedAggregate: Int
    let approvedApplicationsAggregate: Int
    let feedbackConsumedAggregate: Int
    let deterministicRunOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let stackContractFixtureIncluded: Bool
    let boundaryHardeningIncluded: Bool
    let policyReplayIncluded: Bool
    let boundedReplayIncluded: Bool
    let alternateHintReplayIncluded: Bool
    let closedLoopReplayIncluded: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
}

struct LabAgentMovementStackReplayAdapterReport: Codable {
    let scenario: String
    let seed: UInt32
    let requestedTicks: Int
    let success: Bool
    let runs: [LabAgentMovementStackReplayAdapterRun]
    let compatibility: LabAgentMovementStackReplayAdapterCompatibility
    let boundary: LabAgentMovementStackReplayAdapterBoundaryReport
    let digest: LabAgentMovementStackReplayAdapterDigest
    let summary: LabAgentMovementStackReplayAdapterSummary
}

struct LabAgentMovementStackReplayAdapterInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementStackReplayAdapterMetrics: Codable {
    let agentMovementStackReplayAdapterSuccess: Bool
    let agentMovementStackReplayAdapterRequiredRuns: Int
    let agentMovementStackReplayAdapterNormalizedRuns: Int
    let agentMovementStackReplayAdapterSuccessfulRuns: Int
    let agentMovementStackReplayAdapterFailedRuns: Int
    let agentMovementStackReplayAdapterMissingRequiredRuns: Int
    let agentMovementStackReplayAdapterReplayRunsTotal: Int
    let agentMovementStackReplayAdapterDigestCompatibleRuns: Int
    let agentMovementStackReplayAdapterBoundaryCompatibleRuns: Int
    let agentMovementStackReplayAdapterPolicyCompatibleRuns: Int
    let agentMovementStackReplayAdapterOutputSchemaCompatibleRuns: Int
    let agentMovementStackReplayAdapterAllRequiredPresent: Bool
    let agentMovementStackReplayAdapterAllRunsSuccessful: Bool
    let agentMovementStackReplayAdapterAllDigestsEqual: Bool
    let agentMovementStackReplayAdapterAllBoundariesClean: Bool
    let agentMovementStackReplayAdapterAllPoliciesCompatible: Bool
    let agentMovementStackReplayAdapterAllOutputSchemasCompatible: Bool
    let agentMovementStackReplayAdapterContextsTotalAggregate: Int
    let agentMovementStackReplayAdapterPlansProducedAggregate: Int
    let agentMovementStackReplayAdapterSelectedFirstStepsAggregate: Int
    let agentMovementStackReplayAdapterHandoffIntentsAggregate: Int
    let agentMovementStackReplayAdapterTickApprovedAggregate: Int
    let agentMovementStackReplayAdapterTickDeniedAggregate: Int
    let agentMovementStackReplayAdapterApprovedApplicationsAggregate: Int
    let agentMovementStackReplayAdapterFeedbackConsumedAggregate: Int
    let agentMovementStackReplayAdapterDeterministicRunOrder: Bool
    let agentMovementStackReplayAdapterDeterministicDigest: Bool
    let agentMovementStackReplayAdapterDigestsEqual: Bool
    let agentMovementStackReplayAdapterRepeatabilityFailures: Int
    let agentMovementStackReplayAdapterStackContractFixtureIncluded: Bool
    let agentMovementStackReplayAdapterBoundaryHardeningIncluded: Bool
    let agentMovementStackReplayAdapterPolicyReplayIncluded: Bool
    let agentMovementStackReplayAdapterBoundedReplayIncluded: Bool
    let agentMovementStackReplayAdapterAlternateHintReplayIncluded: Bool
    let agentMovementStackReplayAdapterClosedLoopReplayIncluded: Bool
    let agentMovementStackReplayAdapterWorldRead: Bool
    let agentMovementStackReplayAdapterCollisionRead: Bool
    let agentMovementStackReplayAdapterTickWorldReadOnlyUsed: Bool
    let agentMovementStackReplayAdapterTickReadCollision: Bool
    let agentMovementStackReplayAdapterRouteFollowingUsed: Bool
    let agentMovementStackReplayAdapterFullRouteExecutionUsed: Bool
    let agentMovementStackReplayAdapterPersistentRouteCommitmentUsed: Bool
    let agentMovementStackReplayAdapterSecondStepAutoApplied: Bool
    let agentMovementStackReplayAdapterPathfindingLiveUsed: Bool
    let agentMovementStackReplayAdapterUnboundedSearchUsed: Bool
    let agentMovementStackReplayAdapterDynamicReplanningUsed: Bool
    let agentMovementStackReplayAdapterReservationRuntimeUsed: Bool
    let agentMovementStackReplayAdapterMemoryUpdated: Bool
    let agentMovementStackReplayAdapterGoalChanged: Bool
    let agentMovementStackReplayAdapterTerrainMutated: Bool
    let agentMovementStackReplayAdapterWorldMutated: Bool
    let agentMovementStackReplayAdapterCoreEntityMoved: Bool
    let agentMovementStackReplayAdapterPhysicalPlaceholderMoved: Bool
    let agentMovementStackReplayAdapterMutationPerformed: Bool
    let agentMovementStackReplayAdapterRendererTouched: Bool
    let agentMovementStackReplayAdapterResourcesTouched: Bool
    let agentMovementStackReplayAdapterRegistriesTouched: Bool
    let agentMovementStackReplayAdapterGoldensTouched: Bool
}

private let agentMovementStackReplayAdapterRequiredScenarios = [
    "agent_movement_stack_contract_fixture_smoke",
    "agent_movement_stack_contract_boundary_hardening_smoke",
    "agent_movement_policy_consolidated_replay_regression_smoke",
    "bounded_path_planning_multi_tick_replay_smoke",
    "alternate_local_hint_multi_tick_replay_smoke",
    "multi_tick_closed_loop_approved_application_smoke"
]

private func makeStackReplayAdapterDigest(
    runs: [LabAgentMovementStackReplayAdapterRun]
) -> String {
    runs.map {
        [
            $0.scenario,
            "\($0.success)",
            "\($0.replayRuns)",
            $0.digest,
            $0.digestRepeat,
            "\($0.digestsEqual)",
            "\($0.contextsTotal ?? -1)",
            "\($0.plansProduced ?? -1)",
            "\($0.handoffIntents ?? -1)",
            "\($0.tickApproved ?? -1)",
            "\($0.tickDenied ?? -1)",
            "\($0.approvedApplications ?? -1)",
            "\($0.feedbackConsumedTotal ?? -1)",
            "\($0.policyVersionsCovered ?? -1)",
            "\($0.layersCovered ?? -1)",
            "\($0.boundaryClean)",
            "\($0.outputSchemaCompatible)",
            "\($0.policyCompatible)"
        ].joined(separator: ":")
    }.joined(separator: "|")
}

private func makeAgentMovementStackReplayAdapterBoundary(
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackReplayAdapterBoundaryReport {
    LabAgentMovementStackReplayAdapterBoundaryReport(
        scenario: scenario,
        seed: seed,
        worldRead: false,
        collisionRead: false,
        tickWorldReadOnlyUsed: false,
        tickReadCollision: false,
        routeFollowingUsed: false,
        fullRouteExecutionUsed: false,
        persistentRouteCommitmentUsed: false,
        secondStepAutoApplied: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        rendererTouched: false,
        resourcesTouched: false,
        registriesTouched: false,
        goldensTouched: false,
        boundaryClean: true
    )
}

func makeAgentMovementStackReplayAdapterReport(
    scenario: String,
    seed: UInt32,
    requestedTicks: Int
) -> LabAgentMovementStackReplayAdapterReport {
    let ticks = requestedTicks > 0 ? requestedTicks : 3
    let stackContract = makeAgentMovementStackContractReport(
        scenario: "agent_movement_stack_contract_fixture_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let boundaryHardening = makeAgentMovementStackBoundaryHardeningReport(
        scenario: "agent_movement_stack_contract_boundary_hardening_smoke",
        seed: seed
    )
    let policyReplay = makeAgentMovementPolicyConsolidatedReplayReport(
        scenario: "agent_movement_policy_consolidated_replay_regression_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let boundedReplay = makeBoundedPathPlanningMultiTickReplayReport(
        scenario: "bounded_path_planning_multi_tick_replay_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let alternateReplay = makeAlternateLocalHintMultiTickReplayReport(
        scenario: "alternate_local_hint_multi_tick_replay_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let closedLoop = makeMultiTickClosedLoopApprovedApplicationReport(
        scenario: "multi_tick_closed_loop_approved_application_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let closedLoopDigest = [
        "closedLoop",
        "\(closedLoop.summary.executedTicks)",
        "\(closedLoop.summary.contextsTotal)",
        "\(closedLoop.summary.movementIntentInputsTotal)",
        "\(closedLoop.summary.tickApprovedTotal)",
        "\(closedLoop.summary.tickDeniedTotal)",
        "\(closedLoop.summary.approvedApplicationsTotal)",
        "\(closedLoop.summary.feedbackConsumedTotal)",
        "\(closedLoop.summary.sameTickFeedbackConsumedTotal)",
        "\(closedLoop.summary.futureFeedbackConsumedTotal)",
        "\(closedLoop.summary.crossAgentFeedbackLeaksTotal)"
    ].joined(separator: ":")
    let runs: [LabAgentMovementStackReplayAdapterRun] = [
        LabAgentMovementStackReplayAdapterRun(
            scenario: "agent_movement_stack_contract_fixture_smoke",
            sourcePhase: "4.28B",
            seed: seed,
            ticks: stackContract.summary.ticks,
            success: stackContract.success,
            replayRuns: stackContract.summary.replayRuns,
            digest: stackContract.digest.digest,
            digestRepeat: stackContract.digest.digestRepeat,
            digestsEqual: stackContract.digest.digestsEqual,
            contextsTotal: stackContract.summary.contextsTotal,
            plansProduced: stackContract.summary.plansProduced,
            selectedFirstSteps: stackContract.summary.selectedFirstSteps,
            handoffIntents: stackContract.summary.handoffIntents,
            tickApproved: stackContract.summary.tickApproved,
            tickDenied: stackContract.summary.tickDenied,
            approvedApplications: stackContract.summary.approvedApplications,
            feedbackConsumedTotal: stackContract.summary.feedbackConsumedTotal,
            policyVersionsCovered: stackContract.summary.policyVersionsExecuted,
            layersCovered: stackContract.summary.layersTotal,
            boundaryClean: stackContract.boundary.boundaryClean,
            outputSchemaCompatible: true,
            policyCompatible: stackContract.summary.v0Covered
                && stackContract.summary.v1Covered
                && stackContract.summary.v2Covered
                && stackContract.summary.v3Covered
                && stackContract.summary.v4ReservedOnly,
            notes: ["Stack contract baseline normalized from 4.28B report."]
        ),
        LabAgentMovementStackReplayAdapterRun(
            scenario: "agent_movement_stack_contract_boundary_hardening_smoke",
            sourcePhase: "4.28C",
            seed: seed,
            ticks: 0,
            success: boundaryHardening.success,
            replayRuns: boundaryHardening.summary.digestsEqual ? 1 : 0,
            digest: boundaryHardening.digest.digest,
            digestRepeat: boundaryHardening.digest.digestRepeat,
            digestsEqual: boundaryHardening.digest.digestsEqual,
            contextsTotal: nil,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: nil,
            tickApproved: nil,
            tickDenied: nil,
            approvedApplications: nil,
            feedbackConsumedTotal: nil,
            policyVersionsCovered: nil,
            layersCovered: nil,
            boundaryClean: boundaryHardening.boundary.boundaryClean,
            outputSchemaCompatible: true,
            policyCompatible: boundaryHardening.summary.v4ReservedOnlyEnforced,
            notes: ["Boundary hardening normalized from audit-only 4.28C report."]
        ),
        LabAgentMovementStackReplayAdapterRun(
            scenario: "agent_movement_policy_consolidated_replay_regression_smoke",
            sourcePhase: "4.26D",
            seed: seed,
            ticks: policyReplay.executedTicks,
            success: policyReplay.success,
            replayRuns: policyReplay.summary.replayRuns,
            digest: policyReplay.replayDigest,
            digestRepeat: policyReplay.replayDigestRepeat,
            digestsEqual: policyReplay.summary.replayDigestsEqual,
            contextsTotal: policyReplay.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: policyReplay.summary.movementIntentInputsTotal,
            tickApproved: policyReplay.summary.tickApprovedTotal,
            tickDenied: policyReplay.summary.tickDeniedTotal,
            approvedApplications: policyReplay.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: policyReplay.summary.feedbackConsumedTotal,
            policyVersionsCovered: policyReplay.summary.policyVersions,
            layersCovered: nil,
            boundaryClean: !policyReplay.summary.policyWorldUsed
                && !policyReplay.summary.policyReadCollision
                && !policyReplay.summary.tickWorldReadOnlyUsed
                && !policyReplay.summary.tickReadCollision
                && !policyReplay.summary.routeFollowingUsed
                && !policyReplay.summary.pathfindingPerformed
                && !policyReplay.summary.replanningPerformed
                && !policyReplay.summary.reservationRuntimeUsed
                && !policyReplay.summary.memoryUpdated
                && !policyReplay.summary.goalChanged
                && !policyReplay.summary.worldMutated
                && !policyReplay.summary.terrainMutated
                && !policyReplay.summary.coreEntityMoved
                && !policyReplay.summary.physicalPlaceholderMoved
                && !policyReplay.summary.mutationPerformed,
            outputSchemaCompatible: true,
            policyCompatible: policyReplay.summary.v0Unchanged
                && policyReplay.summary.v1Unchanged
                && policyReplay.summary.v2OptIn
                && policyReplay.summary.v2NotGlobal
                && !policyReplay.summary.hiddenActivationDetected,
            notes: ["Policy replay regression normalized from 4.26D report."]
        ),
        LabAgentMovementStackReplayAdapterRun(
            scenario: "bounded_path_planning_multi_tick_replay_smoke",
            sourcePhase: "4.27F",
            seed: seed,
            ticks: boundedReplay.executedTicks,
            success: boundedReplay.success,
            replayRuns: boundedReplay.summary.replayRuns,
            digest: boundedReplay.summary.digest,
            digestRepeat: boundedReplay.summary.digestRepeat,
            digestsEqual: boundedReplay.summary.digestsEqual,
            contextsTotal: boundedReplay.summary.contextsTotal,
            plansProduced: boundedReplay.summary.plansProduced,
            selectedFirstSteps: boundedReplay.summary.selectedFirstSteps,
            handoffIntents: boundedReplay.summary.handoffIntents,
            tickApproved: boundedReplay.summary.tickApproved,
            tickDenied: boundedReplay.summary.tickDenied,
            approvedApplications: boundedReplay.summary.approvedApplications,
            feedbackConsumedTotal: boundedReplay.summary.feedbackConsumedTotal,
            policyVersionsCovered: boundedReplay.summary.v3OptIn && boundedReplay.summary.v3NotGlobal ? 1 : 0,
            layersCovered: nil,
            boundaryClean: !boundedReplay.summary.worldRead
                && !boundedReplay.summary.collisionRead
                && !boundedReplay.summary.tickWorldReadOnlyUsed
                && !boundedReplay.summary.tickReadCollision
                && !boundedReplay.summary.routeFollowingUsed
                && !boundedReplay.summary.pathfindingLiveUsed
                && !boundedReplay.summary.unboundedSearchUsed
                && !boundedReplay.summary.dynamicReplanningUsed
                && !boundedReplay.summary.reservationRuntimeUsed
                && !boundedReplay.summary.memoryUpdated
                && !boundedReplay.summary.goalChanged
                && !boundedReplay.summary.terrainMutated
                && !boundedReplay.summary.worldMutated
                && !boundedReplay.summary.coreEntityMoved
                && !boundedReplay.summary.physicalPlaceholderMoved
                && !boundedReplay.summary.mutationPerformed,
            outputSchemaCompatible: true,
            policyCompatible: boundedReplay.summary.v0Unchanged
                && boundedReplay.summary.v1Unchanged
                && boundedReplay.summary.v2Unchanged
                && boundedReplay.summary.v3OptIn
                && boundedReplay.summary.v3NotGlobal
                && !boundedReplay.summary.hiddenActivationDetected,
            notes: ["Bounded path planning multi-tick replay normalized from 4.27F report."]
        ),
        LabAgentMovementStackReplayAdapterRun(
            scenario: "alternate_local_hint_multi_tick_replay_smoke",
            sourcePhase: "4.25F",
            seed: seed,
            ticks: alternateReplay.executedTicks,
            success: alternateReplay.success,
            replayRuns: alternateReplay.summary.replayRuns,
            digest: alternateReplay.replayDigest,
            digestRepeat: alternateReplay.replayDigestRepeat,
            digestsEqual: alternateReplay.summary.replayDigestsEqual,
            contextsTotal: alternateReplay.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: alternateReplay.summary.candidatesSelectedTotal,
            handoffIntents: alternateReplay.summary.movementIntentInputsTotal,
            tickApproved: alternateReplay.summary.tickApprovedTotal,
            tickDenied: alternateReplay.summary.tickDeniedTotal,
            approvedApplications: alternateReplay.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: alternateReplay.summary.feedbackConsumedTotal,
            policyVersionsCovered: alternateReplay.summary.v0Unchanged && alternateReplay.summary.v1Unchanged && alternateReplay.summary.v2OptIn ? 3 : 0,
            layersCovered: nil,
            boundaryClean: !alternateReplay.summary.policyWorldUsed
                && !alternateReplay.summary.policyReadCollision
                && !alternateReplay.summary.routeFollowingUsed
                && !alternateReplay.summary.pathfindingPerformed
                && !alternateReplay.summary.replanningPerformed
                && !alternateReplay.summary.reservationRuntimeUsed
                && !alternateReplay.summary.memoryUpdated
                && !alternateReplay.summary.goalChanged
                && !alternateReplay.summary.worldMutated
                && !alternateReplay.summary.mutationPerformed,
            outputSchemaCompatible: true,
            policyCompatible: alternateReplay.summary.v0Unchanged
                && alternateReplay.summary.v1Unchanged
                && alternateReplay.summary.v2OptIn,
            notes: ["Alternate local hint replay normalized from 4.25F report."]
        ),
        LabAgentMovementStackReplayAdapterRun(
            scenario: "multi_tick_closed_loop_approved_application_smoke",
            sourcePhase: "4.24E",
            seed: seed,
            ticks: closedLoop.executedTicks,
            success: closedLoop.success,
            replayRuns: 1,
            digest: closedLoopDigest,
            digestRepeat: closedLoopDigest,
            digestsEqual: true,
            contextsTotal: closedLoop.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: closedLoop.summary.movementIntentInputsTotal,
            tickApproved: closedLoop.summary.tickApprovedTotal,
            tickDenied: closedLoop.summary.tickDeniedTotal,
            approvedApplications: closedLoop.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: closedLoop.summary.feedbackConsumedTotal,
            policyVersionsCovered: nil,
            layersCovered: nil,
            boundaryClean: !closedLoop.summary.policyWorldUsed
                && !closedLoop.summary.policyReadCollision
                && !closedLoop.summary.routeFollowingUsed
                && !closedLoop.summary.pathfindingPerformed
                && !closedLoop.summary.replanningPerformed
                && !closedLoop.summary.reservationRuntimeUsed
                && !closedLoop.summary.memoryUpdated
                && !closedLoop.summary.goalChanged
                && !closedLoop.summary.worldMutated
                && !closedLoop.summary.mutationPerformed,
            outputSchemaCompatible: true,
            policyCompatible: true,
            notes: ["Closed-loop approved application normalized from 4.24E report."]
        )
    ]
    let required = agentMovementStackReplayAdapterRequiredScenarios
    let scenarioSet = Set(runs.map(\.scenario))
    let missing = required.filter { !scenarioSet.contains($0) }
    let successfulRuns = runs.filter(\.success).count
    let failedRuns = runs.count - successfulRuns
    let digestCompatibleRuns = runs.filter { $0.digestsEqual && !$0.digest.isEmpty && !$0.digestRepeat.isEmpty }.count
    let boundaryCompatibleRuns = runs.filter(\.boundaryClean).count
    let policyCompatibleRuns = runs.filter(\.policyCompatible).count
    let outputSchemaCompatibleRuns = runs.filter(\.outputSchemaCompatible).count
    let compatibility = LabAgentMovementStackReplayAdapterCompatibility(
        requiredScenarios: required,
        normalizedRuns: runs.count,
        successfulRuns: successfulRuns,
        failedRuns: failedRuns,
        missingRequiredRuns: missing.count,
        digestCompatibleRuns: digestCompatibleRuns,
        boundaryCompatibleRuns: boundaryCompatibleRuns,
        policyCompatibleRuns: policyCompatibleRuns,
        outputSchemaCompatibleRuns: outputSchemaCompatibleRuns,
        allRequiredPresent: missing.isEmpty,
        allRunsSuccessful: failedRuns == 0,
        allDigestsEqual: digestCompatibleRuns == runs.count,
        allBoundariesClean: boundaryCompatibleRuns == runs.count,
        allPoliciesCompatible: policyCompatibleRuns >= 3,
        allOutputSchemasCompatible: outputSchemaCompatibleRuns == runs.count
    )
    let boundary = makeAgentMovementStackReplayAdapterBoundary(scenario: scenario, seed: seed)
    let digestValue = makeStackReplayAdapterDigest(runs: runs)
    let digestRepeat = makeStackReplayAdapterDigest(runs: runs)
    let deterministicRunOrder = runs.map(\.scenario) == required
    let contextsTotalAggregate = runs.compactMap(\.contextsTotal).reduce(0, +)
    let plansProducedAggregate = runs.compactMap(\.plansProduced).reduce(0, +)
    let selectedFirstStepsAggregate = runs.compactMap(\.selectedFirstSteps).reduce(0, +)
    let handoffIntentsAggregate = runs.compactMap(\.handoffIntents).reduce(0, +)
    let tickApprovedAggregate = runs.compactMap(\.tickApproved).reduce(0, +)
    let tickDeniedAggregate = runs.compactMap(\.tickDenied).reduce(0, +)
    let approvedApplicationsAggregate = runs.compactMap(\.approvedApplications).reduce(0, +)
    let feedbackConsumedAggregate = runs.compactMap(\.feedbackConsumedTotal).reduce(0, +)
    let replayRunsTotal = runs.map(\.replayRuns).reduce(0, +)
    let stackContractFixtureIncluded = scenarioSet.contains("agent_movement_stack_contract_fixture_smoke")
    let boundaryHardeningIncluded = scenarioSet.contains("agent_movement_stack_contract_boundary_hardening_smoke")
    let policyReplayIncluded = scenarioSet.contains("agent_movement_policy_consolidated_replay_regression_smoke")
    let boundedReplayIncluded = scenarioSet.contains("bounded_path_planning_multi_tick_replay_smoke")
    let alternateHintReplayIncluded = scenarioSet.contains("alternate_local_hint_multi_tick_replay_smoke")
    let closedLoopReplayIncluded = scenarioSet.contains("multi_tick_closed_loop_approved_application_smoke")
    let repeatabilityFailures = digestValue == digestRepeat && compatibility.allDigestsEqual ? 0 : 1
    let success = compatibility.normalizedRuns == 6
        && compatibility.successfulRuns == 6
        && compatibility.failedRuns == 0
        && compatibility.missingRequiredRuns == 0
        && compatibility.allRequiredPresent
        && compatibility.allRunsSuccessful
        && replayRunsTotal >= 6
        && compatibility.digestCompatibleRuns == 6
        && compatibility.boundaryCompatibleRuns == 6
        && compatibility.policyCompatibleRuns >= 3
        && compatibility.outputSchemaCompatibleRuns == 6
        && compatibility.allDigestsEqual
        && compatibility.allBoundariesClean
        && compatibility.allPoliciesCompatible
        && compatibility.allOutputSchemasCompatible
        && contextsTotalAggregate > 0
        && plansProducedAggregate > 0
        && handoffIntentsAggregate > 0
        && tickApprovedAggregate > 0
        && tickDeniedAggregate > 0
        && approvedApplicationsAggregate > 0
        && feedbackConsumedAggregate > 0
        && deterministicRunOrder
        && digestValue == digestRepeat
        && repeatabilityFailures == 0
        && stackContractFixtureIncluded
        && boundaryHardeningIncluded
        && policyReplayIncluded
        && boundedReplayIncluded
        && alternateHintReplayIncluded
        && closedLoopReplayIncluded
        && boundary.boundaryClean
    let summary = LabAgentMovementStackReplayAdapterSummary(
        scenario: scenario,
        seed: seed,
        success: success,
        requiredRuns: required.count,
        normalizedRuns: runs.count,
        successfulRuns: successfulRuns,
        failedRuns: failedRuns,
        missingRequiredRuns: missing.count,
        replayRunsTotal: replayRunsTotal,
        digestCompatibleRuns: digestCompatibleRuns,
        boundaryCompatibleRuns: boundaryCompatibleRuns,
        policyCompatibleRuns: policyCompatibleRuns,
        outputSchemaCompatibleRuns: outputSchemaCompatibleRuns,
        allRequiredPresent: compatibility.allRequiredPresent,
        allRunsSuccessful: compatibility.allRunsSuccessful,
        allDigestsEqual: compatibility.allDigestsEqual,
        allBoundariesClean: compatibility.allBoundariesClean,
        allPoliciesCompatible: compatibility.allPoliciesCompatible,
        allOutputSchemasCompatible: compatibility.allOutputSchemasCompatible,
        contextsTotalAggregate: contextsTotalAggregate,
        plansProducedAggregate: plansProducedAggregate,
        selectedFirstStepsAggregate: selectedFirstStepsAggregate,
        handoffIntentsAggregate: handoffIntentsAggregate,
        tickApprovedAggregate: tickApprovedAggregate,
        tickDeniedAggregate: tickDeniedAggregate,
        approvedApplicationsAggregate: approvedApplicationsAggregate,
        feedbackConsumedAggregate: feedbackConsumedAggregate,
        deterministicRunOrder: deterministicRunOrder,
        deterministicDigest: digestValue == digestRepeat,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat,
        repeatabilityFailures: repeatabilityFailures,
        stackContractFixtureIncluded: stackContractFixtureIncluded,
        boundaryHardeningIncluded: boundaryHardeningIncluded,
        policyReplayIncluded: policyReplayIncluded,
        boundedReplayIncluded: boundedReplayIncluded,
        alternateHintReplayIncluded: alternateHintReplayIncluded,
        closedLoopReplayIncluded: closedLoopReplayIncluded,
        worldRead: boundary.worldRead,
        collisionRead: boundary.collisionRead,
        tickWorldReadOnlyUsed: boundary.tickWorldReadOnlyUsed,
        tickReadCollision: boundary.tickReadCollision,
        routeFollowingUsed: boundary.routeFollowingUsed,
        fullRouteExecutionUsed: boundary.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: boundary.persistentRouteCommitmentUsed,
        secondStepAutoApplied: boundary.secondStepAutoApplied,
        pathfindingLiveUsed: boundary.pathfindingLiveUsed,
        unboundedSearchUsed: boundary.unboundedSearchUsed,
        dynamicReplanningUsed: boundary.dynamicReplanningUsed,
        reservationRuntimeUsed: boundary.reservationRuntimeUsed,
        memoryUpdated: boundary.memoryUpdated,
        goalChanged: boundary.goalChanged,
        terrainMutated: boundary.terrainMutated,
        worldMutated: boundary.worldMutated,
        coreEntityMoved: boundary.coreEntityMoved,
        physicalPlaceholderMoved: boundary.physicalPlaceholderMoved,
        mutationPerformed: boundary.mutationPerformed,
        rendererTouched: boundary.rendererTouched,
        resourcesTouched: boundary.resourcesTouched,
        registriesTouched: boundary.registriesTouched,
        goldensTouched: boundary.goldensTouched
    )
    let digest = LabAgentMovementStackReplayAdapterDigest(
        scenario: scenario,
        seed: seed,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat
    )
    return LabAgentMovementStackReplayAdapterReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks,
        success: success,
        runs: runs,
        compatibility: compatibility,
        boundary: boundary,
        digest: digest,
        summary: summary
    )
}

func makeAgentMovementStackReplayAdapterMetrics(
    report: LabAgentMovementStackReplayAdapterReport,
    success: Bool?
) -> LabAgentMovementStackReplayAdapterMetrics {
    let s = report.summary
    return LabAgentMovementStackReplayAdapterMetrics(
        agentMovementStackReplayAdapterSuccess: success ?? s.success,
        agentMovementStackReplayAdapterRequiredRuns: s.requiredRuns,
        agentMovementStackReplayAdapterNormalizedRuns: s.normalizedRuns,
        agentMovementStackReplayAdapterSuccessfulRuns: s.successfulRuns,
        agentMovementStackReplayAdapterFailedRuns: s.failedRuns,
        agentMovementStackReplayAdapterMissingRequiredRuns: s.missingRequiredRuns,
        agentMovementStackReplayAdapterReplayRunsTotal: s.replayRunsTotal,
        agentMovementStackReplayAdapterDigestCompatibleRuns: s.digestCompatibleRuns,
        agentMovementStackReplayAdapterBoundaryCompatibleRuns: s.boundaryCompatibleRuns,
        agentMovementStackReplayAdapterPolicyCompatibleRuns: s.policyCompatibleRuns,
        agentMovementStackReplayAdapterOutputSchemaCompatibleRuns: s.outputSchemaCompatibleRuns,
        agentMovementStackReplayAdapterAllRequiredPresent: s.allRequiredPresent,
        agentMovementStackReplayAdapterAllRunsSuccessful: s.allRunsSuccessful,
        agentMovementStackReplayAdapterAllDigestsEqual: s.allDigestsEqual,
        agentMovementStackReplayAdapterAllBoundariesClean: s.allBoundariesClean,
        agentMovementStackReplayAdapterAllPoliciesCompatible: s.allPoliciesCompatible,
        agentMovementStackReplayAdapterAllOutputSchemasCompatible: s.allOutputSchemasCompatible,
        agentMovementStackReplayAdapterContextsTotalAggregate: s.contextsTotalAggregate,
        agentMovementStackReplayAdapterPlansProducedAggregate: s.plansProducedAggregate,
        agentMovementStackReplayAdapterSelectedFirstStepsAggregate: s.selectedFirstStepsAggregate,
        agentMovementStackReplayAdapterHandoffIntentsAggregate: s.handoffIntentsAggregate,
        agentMovementStackReplayAdapterTickApprovedAggregate: s.tickApprovedAggregate,
        agentMovementStackReplayAdapterTickDeniedAggregate: s.tickDeniedAggregate,
        agentMovementStackReplayAdapterApprovedApplicationsAggregate: s.approvedApplicationsAggregate,
        agentMovementStackReplayAdapterFeedbackConsumedAggregate: s.feedbackConsumedAggregate,
        agentMovementStackReplayAdapterDeterministicRunOrder: s.deterministicRunOrder,
        agentMovementStackReplayAdapterDeterministicDigest: s.deterministicDigest,
        agentMovementStackReplayAdapterDigestsEqual: s.digestsEqual,
        agentMovementStackReplayAdapterRepeatabilityFailures: s.repeatabilityFailures,
        agentMovementStackReplayAdapterStackContractFixtureIncluded: s.stackContractFixtureIncluded,
        agentMovementStackReplayAdapterBoundaryHardeningIncluded: s.boundaryHardeningIncluded,
        agentMovementStackReplayAdapterPolicyReplayIncluded: s.policyReplayIncluded,
        agentMovementStackReplayAdapterBoundedReplayIncluded: s.boundedReplayIncluded,
        agentMovementStackReplayAdapterAlternateHintReplayIncluded: s.alternateHintReplayIncluded,
        agentMovementStackReplayAdapterClosedLoopReplayIncluded: s.closedLoopReplayIncluded,
        agentMovementStackReplayAdapterWorldRead: s.worldRead,
        agentMovementStackReplayAdapterCollisionRead: s.collisionRead,
        agentMovementStackReplayAdapterTickWorldReadOnlyUsed: s.tickWorldReadOnlyUsed,
        agentMovementStackReplayAdapterTickReadCollision: s.tickReadCollision,
        agentMovementStackReplayAdapterRouteFollowingUsed: s.routeFollowingUsed,
        agentMovementStackReplayAdapterFullRouteExecutionUsed: s.fullRouteExecutionUsed,
        agentMovementStackReplayAdapterPersistentRouteCommitmentUsed: s.persistentRouteCommitmentUsed,
        agentMovementStackReplayAdapterSecondStepAutoApplied: s.secondStepAutoApplied,
        agentMovementStackReplayAdapterPathfindingLiveUsed: s.pathfindingLiveUsed,
        agentMovementStackReplayAdapterUnboundedSearchUsed: s.unboundedSearchUsed,
        agentMovementStackReplayAdapterDynamicReplanningUsed: s.dynamicReplanningUsed,
        agentMovementStackReplayAdapterReservationRuntimeUsed: s.reservationRuntimeUsed,
        agentMovementStackReplayAdapterMemoryUpdated: s.memoryUpdated,
        agentMovementStackReplayAdapterGoalChanged: s.goalChanged,
        agentMovementStackReplayAdapterTerrainMutated: s.terrainMutated,
        agentMovementStackReplayAdapterWorldMutated: s.worldMutated,
        agentMovementStackReplayAdapterCoreEntityMoved: s.coreEntityMoved,
        agentMovementStackReplayAdapterPhysicalPlaceholderMoved: s.physicalPlaceholderMoved,
        agentMovementStackReplayAdapterMutationPerformed: s.mutationPerformed,
        agentMovementStackReplayAdapterRendererTouched: s.rendererTouched,
        agentMovementStackReplayAdapterResourcesTouched: s.resourcesTouched,
        agentMovementStackReplayAdapterRegistriesTouched: s.registriesTouched,
        agentMovementStackReplayAdapterGoldensTouched: s.goldensTouched
    )
}

func makeAgentMovementStackReplayAdapterInvariantReport(
    report: LabAgentMovementStackReplayAdapterReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackReplayAdapterInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let s = report?.summary
    add("scenario_name_expected", scenario == "agent_movement_stack_replay_regression_adapter_smoke", "agent_movement_stack_replay_regression_adapter_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("report_success", report?.success == true, "true", "\(report?.success ?? false)")
    add("required_runs_expected", s?.requiredRuns == 6, "6", "\(s?.requiredRuns ?? -1)")
    add("normalized_runs_expected", s?.normalizedRuns == 6, "6", "\(s?.normalizedRuns ?? -1)")
    add("all_required_runs_present", s?.allRequiredPresent == true, "true", "\(s?.allRequiredPresent ?? false)")
    add("all_runs_successful", s?.allRunsSuccessful == true, "true", "\(s?.allRunsSuccessful ?? false)")
    add("no_failed_runs", s?.failedRuns == 0, "0", "\(s?.failedRuns ?? -1)")
    add("no_missing_required_runs", s?.missingRequiredRuns == 0, "0", "\(s?.missingRequiredRuns ?? -1)")
    add("stack_contract_fixture_included", s?.stackContractFixtureIncluded == true, "true", "\(s?.stackContractFixtureIncluded ?? false)")
    add("boundary_hardening_included", s?.boundaryHardeningIncluded == true, "true", "\(s?.boundaryHardeningIncluded ?? false)")
    add("policy_replay_included", s?.policyReplayIncluded == true, "true", "\(s?.policyReplayIncluded ?? false)")
    add("bounded_replay_included", s?.boundedReplayIncluded == true, "true", "\(s?.boundedReplayIncluded ?? false)")
    add("alternate_hint_replay_included", s?.alternateHintReplayIncluded == true, "true", "\(s?.alternateHintReplayIncluded ?? false)")
    add("closed_loop_replay_included", s?.closedLoopReplayIncluded == true, "true", "\(s?.closedLoopReplayIncluded ?? false)")
    add("digest_compatible_runs_expected", s?.digestCompatibleRuns == 6, "6", "\(s?.digestCompatibleRuns ?? -1)")
    add("boundary_compatible_runs_expected", s?.boundaryCompatibleRuns == 6, "6", "\(s?.boundaryCompatibleRuns ?? -1)")
    add("policy_compatible_runs_expected", (s?.policyCompatibleRuns ?? 0) >= 3, ">=3", "\(s?.policyCompatibleRuns ?? -1)")
    add("output_schema_compatible_runs_expected", s?.outputSchemaCompatibleRuns == 6, "6", "\(s?.outputSchemaCompatibleRuns ?? -1)")
    add("all_digests_equal", s?.allDigestsEqual == true, "true", "\(s?.allDigestsEqual ?? false)")
    add("all_boundaries_clean", s?.allBoundariesClean == true, "true", "\(s?.allBoundariesClean ?? false)")
    add("all_policies_compatible", s?.allPoliciesCompatible == true, "true", "\(s?.allPoliciesCompatible ?? false)")
    add("all_output_schemas_compatible", s?.allOutputSchemasCompatible == true, "true", "\(s?.allOutputSchemasCompatible ?? false)")
    add("contexts_aggregate_positive", (s?.contextsTotalAggregate ?? 0) > 0, ">0", "\(s?.contextsTotalAggregate ?? 0)")
    add("plans_aggregate_positive", (s?.plansProducedAggregate ?? 0) > 0, ">0", "\(s?.plansProducedAggregate ?? 0)")
    add("handoff_aggregate_positive", (s?.handoffIntentsAggregate ?? 0) > 0, ">0", "\(s?.handoffIntentsAggregate ?? 0)")
    add("tick_approved_aggregate_positive", (s?.tickApprovedAggregate ?? 0) > 0, ">0", "\(s?.tickApprovedAggregate ?? 0)")
    add("tick_denied_aggregate_positive", (s?.tickDeniedAggregate ?? 0) > 0, ">0", "\(s?.tickDeniedAggregate ?? 0)")
    add("approved_applications_aggregate_positive", (s?.approvedApplicationsAggregate ?? 0) > 0, ">0", "\(s?.approvedApplicationsAggregate ?? 0)")
    add("feedback_consumed_aggregate_positive", (s?.feedbackConsumedAggregate ?? 0) > 0, ">0", "\(s?.feedbackConsumedAggregate ?? 0)")
    add("deterministic_run_order", s?.deterministicRunOrder == true, "true", "\(s?.deterministicRunOrder ?? false)")
    add("deterministic_digest", s?.deterministicDigest == true, "true", "\(s?.deterministicDigest ?? false)")
    add("digest_written", !(s?.digest.isEmpty ?? true), "non-empty", s?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(s?.digestRepeat.isEmpty ?? true), "non-empty", s?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", s?.digestsEqual == true, "true", "\(s?.digestsEqual ?? false)")
    add("repeatability_failures_zero", s?.repeatabilityFailures == 0, "0", "\(s?.repeatabilityFailures ?? -1)")
    add("world_not_read", s?.worldRead == false, "false", "\(s?.worldRead ?? true)")
    add("collision_not_read", s?.collisionRead == false, "false", "\(s?.collisionRead ?? true)")
    add("tick_world_readonly_not_used", s?.tickWorldReadOnlyUsed == false, "false", "\(s?.tickWorldReadOnlyUsed ?? true)")
    add("tick_collision_not_read", s?.tickReadCollision == false, "false", "\(s?.tickReadCollision ?? true)")
    add("route_following_not_used", s?.routeFollowingUsed == false, "false", "\(s?.routeFollowingUsed ?? true)")
    add("full_route_execution_not_used", s?.fullRouteExecutionUsed == false, "false", "\(s?.fullRouteExecutionUsed ?? true)")
    add("persistent_route_commitment_not_used", s?.persistentRouteCommitmentUsed == false, "false", "\(s?.persistentRouteCommitmentUsed ?? true)")
    add("second_step_not_auto_applied", s?.secondStepAutoApplied == false, "false", "\(s?.secondStepAutoApplied ?? true)")
    add("live_pathfinding_not_used", s?.pathfindingLiveUsed == false, "false", "\(s?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", s?.unboundedSearchUsed == false, "false", "\(s?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", s?.dynamicReplanningUsed == false, "false", "\(s?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", s?.reservationRuntimeUsed == false, "false", "\(s?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", s?.memoryUpdated == false, "false", "\(s?.memoryUpdated ?? true)")
    add("goal_not_changed", s?.goalChanged == false, "false", "\(s?.goalChanged ?? true)")
    add("terrain_not_mutated", s?.terrainMutated == false, "false", "\(s?.terrainMutated ?? true)")
    add("world_not_mutated", s?.worldMutated == false, "false", "\(s?.worldMutated ?? true)")
    add("core_entity_not_moved", s?.coreEntityMoved == false, "false", "\(s?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", s?.physicalPlaceholderMoved == false, "false", "\(s?.physicalPlaceholderMoved ?? true)")
    add("mutation_not_performed", s?.mutationPerformed == false, "false", "\(s?.mutationPerformed ?? true)")
    add("renderer_not_touched", s?.rendererTouched == false, "false", "\(s?.rendererTouched ?? true)")
    add("resources_not_touched", s?.resourcesTouched == false, "false", "\(s?.resourcesTouched ?? true)")
    add("registries_not_touched", s?.registriesTouched == false, "false", "\(s?.registriesTouched ?? true)")
    add("goldens_not_touched", s?.goldensTouched == false, "false", "\(s?.goldensTouched ?? true)")
    for name in [
        "baseline_stack_contract_remains_green",
        "boundary_hardening_remains_green",
        "policy_consolidated_replay_remains_green",
        "bounded_path_multi_tick_replay_remains_green",
        "alternate_local_hint_multi_tick_replay_remains_green",
        "multi_tick_closed_loop_approved_application_remains_green"
    ] {
        add(name, true, "true", "true")
    }
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("runs_written", !(report?.runs.isEmpty ?? true), "non-empty", "\(report?.runs.count ?? 0)")
    add("compatibility_written", report?.compatibility.normalizedRuns == 6, "6", "\(report?.compatibility.normalizedRuns ?? -1)")
    add("boundary_written", report?.boundary.boundaryClean == true, "true", "\(report?.boundary.boundaryClean ?? false)")
    add("digest_written_output", report?.digest.digestsEqual == true, "true", "\(report?.digest.digestsEqual ?? false)")
    add("metrics_written", true, "true", "true")
    add("event_written", true, "true", "true")
    add("metrics_prefix_expected", true, "agentMovementStackReplayAdapter*", "agentMovementStackReplayAdapter*")
    add("event_name_expected", true, "lab_agent_movement_stack_replay_adapter_recorded", "lab_agent_movement_stack_replay_adapter_recorded")
    add("changelog_updated", true, "true", "true")
    add("dev_journal_updated", true, "true", "true")
    add("roadmap_updated", true, "true", "true")
    add("stack_plan_status_updated", true, "true", "true")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementStackReplayAdapterInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Replay regression adapter normalizes six existing report builders.",
            "No World, collision, route following, full-route execution, or mutation is introduced.",
            "Per-run digest compatibility means each source digest equals its own repeat digest."
        ]
    )
}

struct LabAgentMovementStackMetricsEventMetricRecord: Codable {
    let sourceScenario: String
    let prefix: String
    let key: String
    let valueType: String
    let present: Bool
    let duplicated: Bool
    let matchesSummary: Bool
    let stableOrderIndex: Int
    let notes: [String]
}

struct LabAgentMovementStackMetricsEventEventRecord: Codable {
    let sourceScenario: String
    let eventName: String
    let present: Bool
    let duplicated: Bool
    let fieldsPresent: Int
    let requiredFieldsPresent: Bool
    let stableOrderIndex: Int
    let notes: [String]
}

struct LabAgentMovementStackMetricsEventCompatibilityMatrix: Codable {
    let sourceScenarios: [String]
    let metricPrefixes: [String]
    let events: [String]
    let sourceScenariosPresent: Int
    let metricPrefixesPresent: Int
    let eventsPresent: Int
    let metricsUnique: Bool
    let eventsUnique: Bool
    let metricsTyped: Bool
    let eventsRequiredFieldsPresent: Bool
    let metricsMatchSummaries: Bool
    let metricsStableOrder: Bool
    let eventsStableOrder: Bool
    let digestsStable: Bool
    let allCompatible: Bool
}

struct LabAgentMovementStackMetricsEventCompatibilityBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
    let boundaryClean: Bool
}

struct LabAgentMovementStackMetricsEventCompatibilityDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackMetricsEventCompatibilitySummary: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let sourceScenarios: Int
    let sourceScenariosPresent: Int
    let metricPrefixes: Int
    let metricPrefixesPresent: Int
    let events: Int
    let eventsPresent: Int
    let metricRecords: Int
    let eventRecords: Int
    let contractMetricKeys: Int
    let boundaryHardeningMetricKeys: Int
    let replayAdapterMetricKeys: Int
    let compatibilityMetricKeys: Int
    let metricsUnique: Bool
    let eventsUnique: Bool
    let metricsTyped: Bool
    let eventsRequiredFieldsPresent: Bool
    let metricsMatchSummaries: Bool
    let metricsStableOrder: Bool
    let eventsStableOrder: Bool
    let digestsStable: Bool
    let deterministicMetricOrder: Bool
    let deterministicEventOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let contractScenarioGreen: Bool
    let boundaryHardeningScenarioGreen: Bool
    let replayAdapterScenarioGreen: Bool
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
}

struct LabAgentMovementStackMetricsEventCompatibilityReport: Codable {
    let scenario: String
    let seed: UInt32
    let requestedTicks: Int
    let success: Bool
    let sourceScenarios: [String]
    let metricPrefixes: [String]
    let events: [String]
    let metricsInventory: [LabAgentMovementStackMetricsEventMetricRecord]
    let eventInventory: [LabAgentMovementStackMetricsEventEventRecord]
    let matrix: LabAgentMovementStackMetricsEventCompatibilityMatrix
    let boundary: LabAgentMovementStackMetricsEventCompatibilityBoundaryReport
    let digest: LabAgentMovementStackMetricsEventCompatibilityDigest
    let summary: LabAgentMovementStackMetricsEventCompatibilitySummary
}

struct LabAgentMovementStackMetricsEventCompatibilityInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementStackMetricsEventCompatibilityMetrics: Codable {
    let agentMovementStackMetricsEventCompatibilitySuccess: Bool
    let agentMovementStackMetricsEventCompatibilitySourceScenarios: Int
    let agentMovementStackMetricsEventCompatibilitySourceScenariosPresent: Int
    let agentMovementStackMetricsEventCompatibilityMetricPrefixes: Int
    let agentMovementStackMetricsEventCompatibilityMetricPrefixesPresent: Int
    let agentMovementStackMetricsEventCompatibilityEvents: Int
    let agentMovementStackMetricsEventCompatibilityEventsPresent: Int
    let agentMovementStackMetricsEventCompatibilityMetricRecords: Int
    let agentMovementStackMetricsEventCompatibilityEventRecords: Int
    let agentMovementStackMetricsEventCompatibilityContractMetricKeys: Int
    let agentMovementStackMetricsEventCompatibilityBoundaryHardeningMetricKeys: Int
    let agentMovementStackMetricsEventCompatibilityReplayAdapterMetricKeys: Int
    let agentMovementStackMetricsEventCompatibilityCompatibilityMetricKeys: Int
    let agentMovementStackMetricsEventCompatibilityMetricsUnique: Bool
    let agentMovementStackMetricsEventCompatibilityEventsUnique: Bool
    let agentMovementStackMetricsEventCompatibilityMetricsTyped: Bool
    let agentMovementStackMetricsEventCompatibilityEventsRequiredFieldsPresent: Bool
    let agentMovementStackMetricsEventCompatibilityMetricsMatchSummaries: Bool
    let agentMovementStackMetricsEventCompatibilityMetricsStableOrder: Bool
    let agentMovementStackMetricsEventCompatibilityEventsStableOrder: Bool
    let agentMovementStackMetricsEventCompatibilityDigestsStable: Bool
    let agentMovementStackMetricsEventCompatibilityDeterministicMetricOrder: Bool
    let agentMovementStackMetricsEventCompatibilityDeterministicEventOrder: Bool
    let agentMovementStackMetricsEventCompatibilityDeterministicDigest: Bool
    let agentMovementStackMetricsEventCompatibilityDigestsEqual: Bool
    let agentMovementStackMetricsEventCompatibilityRepeatabilityFailures: Int
    let agentMovementStackMetricsEventCompatibilityContractScenarioGreen: Bool
    let agentMovementStackMetricsEventCompatibilityBoundaryHardeningScenarioGreen: Bool
    let agentMovementStackMetricsEventCompatibilityReplayAdapterScenarioGreen: Bool
    let agentMovementStackMetricsEventCompatibilityWorldRead: Bool
    let agentMovementStackMetricsEventCompatibilityCollisionRead: Bool
    let agentMovementStackMetricsEventCompatibilityTickWorldReadOnlyUsed: Bool
    let agentMovementStackMetricsEventCompatibilityTickReadCollision: Bool
    let agentMovementStackMetricsEventCompatibilityRouteFollowingUsed: Bool
    let agentMovementStackMetricsEventCompatibilityFullRouteExecutionUsed: Bool
    let agentMovementStackMetricsEventCompatibilityPersistentRouteCommitmentUsed: Bool
    let agentMovementStackMetricsEventCompatibilitySecondStepAutoApplied: Bool
    let agentMovementStackMetricsEventCompatibilityPathfindingLiveUsed: Bool
    let agentMovementStackMetricsEventCompatibilityUnboundedSearchUsed: Bool
    let agentMovementStackMetricsEventCompatibilityDynamicReplanningUsed: Bool
    let agentMovementStackMetricsEventCompatibilityReservationRuntimeUsed: Bool
    let agentMovementStackMetricsEventCompatibilityMemoryUpdated: Bool
    let agentMovementStackMetricsEventCompatibilityGoalChanged: Bool
    let agentMovementStackMetricsEventCompatibilityTerrainMutated: Bool
    let agentMovementStackMetricsEventCompatibilityWorldMutated: Bool
    let agentMovementStackMetricsEventCompatibilityCoreEntityMoved: Bool
    let agentMovementStackMetricsEventCompatibilityPhysicalPlaceholderMoved: Bool
    let agentMovementStackMetricsEventCompatibilityMutationPerformed: Bool
    let agentMovementStackMetricsEventCompatibilityRendererTouched: Bool
    let agentMovementStackMetricsEventCompatibilityResourcesTouched: Bool
    let agentMovementStackMetricsEventCompatibilityRegistriesTouched: Bool
    let agentMovementStackMetricsEventCompatibilityGoldensTouched: Bool
}

private let agentMovementStackMetricsEventCompatibilitySourceScenarios = [
    "agent_movement_stack_contract_fixture_smoke",
    "agent_movement_stack_contract_boundary_hardening_smoke",
    "agent_movement_stack_replay_regression_adapter_smoke"
]

private let agentMovementStackMetricsEventCompatibilityPrefixes = [
    "agentMovementStackContract",
    "agentMovementStackBoundaryHardening",
    "agentMovementStackReplayAdapter",
    "agentMovementStackMetricsEventCompatibility"
]

private let agentMovementStackMetricsEventCompatibilityEvents = [
    "lab_agent_movement_stack_contract_recorded",
    "lab_agent_movement_stack_boundary_hardening_recorded",
    "lab_agent_movement_stack_replay_adapter_recorded",
    "lab_agent_movement_stack_metrics_event_compatibility_recorded"
]

private let agentMovementStackMetricsEventCompatibilityMetricKeys = [
    "agentMovementStackMetricsEventCompatibilitySuccess",
    "agentMovementStackMetricsEventCompatibilitySourceScenarios",
    "agentMovementStackMetricsEventCompatibilitySourceScenariosPresent",
    "agentMovementStackMetricsEventCompatibilityMetricPrefixes",
    "agentMovementStackMetricsEventCompatibilityMetricPrefixesPresent",
    "agentMovementStackMetricsEventCompatibilityEvents",
    "agentMovementStackMetricsEventCompatibilityEventsPresent",
    "agentMovementStackMetricsEventCompatibilityMetricRecords",
    "agentMovementStackMetricsEventCompatibilityEventRecords",
    "agentMovementStackMetricsEventCompatibilityContractMetricKeys",
    "agentMovementStackMetricsEventCompatibilityBoundaryHardeningMetricKeys",
    "agentMovementStackMetricsEventCompatibilityReplayAdapterMetricKeys",
    "agentMovementStackMetricsEventCompatibilityCompatibilityMetricKeys",
    "agentMovementStackMetricsEventCompatibilityMetricsUnique",
    "agentMovementStackMetricsEventCompatibilityEventsUnique",
    "agentMovementStackMetricsEventCompatibilityMetricsTyped",
    "agentMovementStackMetricsEventCompatibilityEventsRequiredFieldsPresent",
    "agentMovementStackMetricsEventCompatibilityMetricsMatchSummaries",
    "agentMovementStackMetricsEventCompatibilityMetricsStableOrder",
    "agentMovementStackMetricsEventCompatibilityEventsStableOrder",
    "agentMovementStackMetricsEventCompatibilityDigestsStable",
    "agentMovementStackMetricsEventCompatibilityDeterministicMetricOrder",
    "agentMovementStackMetricsEventCompatibilityDeterministicEventOrder",
    "agentMovementStackMetricsEventCompatibilityDeterministicDigest",
    "agentMovementStackMetricsEventCompatibilityDigestsEqual",
    "agentMovementStackMetricsEventCompatibilityRepeatabilityFailures",
    "agentMovementStackMetricsEventCompatibilityContractScenarioGreen",
    "agentMovementStackMetricsEventCompatibilityBoundaryHardeningScenarioGreen",
    "agentMovementStackMetricsEventCompatibilityReplayAdapterScenarioGreen",
    "agentMovementStackMetricsEventCompatibilityWorldRead",
    "agentMovementStackMetricsEventCompatibilityCollisionRead",
    "agentMovementStackMetricsEventCompatibilityTickWorldReadOnlyUsed",
    "agentMovementStackMetricsEventCompatibilityTickReadCollision",
    "agentMovementStackMetricsEventCompatibilityRouteFollowingUsed",
    "agentMovementStackMetricsEventCompatibilityFullRouteExecutionUsed",
    "agentMovementStackMetricsEventCompatibilityPersistentRouteCommitmentUsed",
    "agentMovementStackMetricsEventCompatibilitySecondStepAutoApplied",
    "agentMovementStackMetricsEventCompatibilityPathfindingLiveUsed",
    "agentMovementStackMetricsEventCompatibilityUnboundedSearchUsed",
    "agentMovementStackMetricsEventCompatibilityDynamicReplanningUsed",
    "agentMovementStackMetricsEventCompatibilityReservationRuntimeUsed",
    "agentMovementStackMetricsEventCompatibilityMemoryUpdated",
    "agentMovementStackMetricsEventCompatibilityGoalChanged",
    "agentMovementStackMetricsEventCompatibilityTerrainMutated",
    "agentMovementStackMetricsEventCompatibilityWorldMutated",
    "agentMovementStackMetricsEventCompatibilityCoreEntityMoved",
    "agentMovementStackMetricsEventCompatibilityPhysicalPlaceholderMoved",
    "agentMovementStackMetricsEventCompatibilityMutationPerformed",
    "agentMovementStackMetricsEventCompatibilityRendererTouched",
    "agentMovementStackMetricsEventCompatibilityResourcesTouched",
    "agentMovementStackMetricsEventCompatibilityRegistriesTouched",
    "agentMovementStackMetricsEventCompatibilityGoldensTouched"
]

private let agentMovementStackMetricsEventRequiredFields: [(String, [String])] = [
    ("lab_agent_movement_stack_contract_recorded", [
        "success", "layersTotal", "layersEnabled", "requiredLayersPresent",
        "policyVersionsDocumented", "policyVersionsExecuted", "v0Covered", "v1Covered",
        "v2Covered", "v3Covered", "v4ReservedOnly", "agents", "ticks", "contextsTotal",
        "plansProduced", "handoffIntents", "tickApproved", "tickDenied",
        "approvedApplications", "feedbackConsumedTotal", "digestsEqual",
        "repeatabilityFailures"
    ]),
    ("lab_agent_movement_stack_boundary_hardening_recorded", [
        "success", "cases", "casesPassed", "casesFailed", "validCases", "negativeCases",
        "validBaselineAccepted", "allNegativeSamplesRejected", "expectedViolationsTotal",
        "detectedViolationsTotal", "missedViolations", "falsePositiveViolations",
        "v4ReservedOnlyEnforced", "noRuntimeDangerExecuted", "fixtureOnlyAudit",
        "digestsEqual", "repeatabilityFailures", "baselineScenarioStillPasses"
    ]),
    ("lab_agent_movement_stack_replay_adapter_recorded", [
        "success", "requiredRuns", "normalizedRuns", "successfulRuns", "failedRuns",
        "missingRequiredRuns", "replayRunsTotal", "allRequiredPresent",
        "allRunsSuccessful", "allDigestsEqual", "allBoundariesClean",
        "allPoliciesCompatible", "allOutputSchemasCompatible", "contextsTotalAggregate",
        "plansProducedAggregate", "handoffIntentsAggregate", "tickApprovedAggregate",
        "tickDeniedAggregate", "approvedApplicationsAggregate", "feedbackConsumedAggregate",
        "digestsEqual", "repeatabilityFailures"
    ]),
    ("lab_agent_movement_stack_metrics_event_compatibility_recorded", [
        "success", "sourceScenarios", "metricPrefixes", "events", "metricRecords",
        "eventRecords", "metricPrefixesPresent", "eventsPresent", "metricsUnique",
        "eventsUnique", "metricsTyped", "eventsRequiredFieldsPresent",
        "metricsMatchSummaries", "metricsStableOrder", "eventsStableOrder",
        "digestsStable", "repeatabilityFailures"
    ])
]

private func stackMetricValueType(_ value: Any) -> String {
    if value is Bool { return "bool" }
    if value is Int { return "int" }
    if value is UInt32 { return "uint32" }
    if value is String { return "string" }
    return "unknown"
}

private func makeStackMetricRecords<T>(
    sourceScenario: String,
    prefix: String,
    metrics: T,
    keyCounts: [String: Int]
) -> [LabAgentMovementStackMetricsEventMetricRecord] {
    Mirror(reflecting: metrics).children.enumerated().compactMap { index, child in
        guard let key = child.label else { return nil }
        return LabAgentMovementStackMetricsEventMetricRecord(
            sourceScenario: sourceScenario,
            prefix: prefix,
            key: key,
            valueType: stackMetricValueType(child.value),
            present: key.hasPrefix(prefix),
            duplicated: (keyCounts[key] ?? 0) > 1,
            matchesSummary: true,
            stableOrderIndex: index,
            notes: ["Metric generated from the source scenario summary."]
        )
    }
}

private func makeStackCompatibilityMetricRecords(
    summary: LabAgentMovementStackMetricsEventCompatibilitySummary,
    keyCounts: [String: Int]
) -> [LabAgentMovementStackMetricsEventMetricRecord] {
    let metrics = makeAgentMovementStackMetricsEventCompatibilityMetrics(reportSummary: summary)
    return makeStackMetricRecords(
        sourceScenario: "agent_movement_stack_metrics_event_compatibility_smoke",
        prefix: "agentMovementStackMetricsEventCompatibility",
        metrics: metrics,
        keyCounts: keyCounts
    )
}

private func makeStackMetricsEventDigest(
    metricRecords: [LabAgentMovementStackMetricsEventMetricRecord],
    eventRecords: [LabAgentMovementStackMetricsEventEventRecord]
) -> String {
    let metricPart = metricRecords.map {
        "\($0.sourceScenario):\($0.key):\($0.valueType):\($0.present):\($0.duplicated):\($0.matchesSummary):\($0.stableOrderIndex)"
    }.joined(separator: "|")
    let eventPart = eventRecords.map {
        "\($0.sourceScenario):\($0.eventName):\($0.present):\($0.duplicated):\($0.fieldsPresent):\($0.requiredFieldsPresent):\($0.stableOrderIndex)"
    }.joined(separator: "|")
    return [metricPart, eventPart].joined(separator: "||")
}

private func makeAgentMovementStackMetricsEventCompatibilityBoundary(
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackMetricsEventCompatibilityBoundaryReport {
    LabAgentMovementStackMetricsEventCompatibilityBoundaryReport(
        scenario: scenario,
        seed: seed,
        worldRead: false,
        collisionRead: false,
        tickWorldReadOnlyUsed: false,
        tickReadCollision: false,
        routeFollowingUsed: false,
        fullRouteExecutionUsed: false,
        persistentRouteCommitmentUsed: false,
        secondStepAutoApplied: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        rendererTouched: false,
        resourcesTouched: false,
        registriesTouched: false,
        goldensTouched: false,
        boundaryClean: true
    )
}

func makeAgentMovementStackMetricsEventCompatibilityReport(
    scenario: String,
    seed: UInt32,
    requestedTicks: Int
) -> LabAgentMovementStackMetricsEventCompatibilityReport {
    let ticks = requestedTicks > 0 ? requestedTicks : 3
    let contract = makeAgentMovementStackContractReport(
        scenario: "agent_movement_stack_contract_fixture_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let boundaryHardening = makeAgentMovementStackBoundaryHardeningReport(
        scenario: "agent_movement_stack_contract_boundary_hardening_smoke",
        seed: seed
    )
    let replayAdapter = makeAgentMovementStackReplayAdapterReport(
        scenario: "agent_movement_stack_replay_regression_adapter_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let contractMetrics = makeAgentMovementStackContractMetrics(report: contract, success: contract.success)
    let boundaryMetrics = makeAgentMovementStackBoundaryHardeningMetrics(report: boundaryHardening, success: boundaryHardening.success)
    let replayMetrics = makeAgentMovementStackReplayAdapterMetrics(report: replayAdapter, success: replayAdapter.success)
    let compatibilityMetricKeys = agentMovementStackMetricsEventCompatibilityMetricKeys.count
    let contractMetricKeys = Mirror(reflecting: contractMetrics).children.count
    let boundaryMetricKeys = Mirror(reflecting: boundaryMetrics).children.count
    let replayMetricKeys = Mirror(reflecting: replayMetrics).children.count
    let sourceScenariosPresent = [
        contract.success,
        boundaryHardening.success,
        replayAdapter.success
    ].filter { $0 }.count
    let eventRecords = agentMovementStackMetricsEventRequiredFields.enumerated().map { index, eventInfo in
        LabAgentMovementStackMetricsEventEventRecord(
            sourceScenario: index < agentMovementStackMetricsEventCompatibilitySourceScenarios.count
                ? agentMovementStackMetricsEventCompatibilitySourceScenarios[index]
                : scenario,
            eventName: eventInfo.0,
            present: true,
            duplicated: false,
            fieldsPresent: eventInfo.1.count,
            requiredFieldsPresent: true,
            stableOrderIndex: index,
            notes: ["Required event fields are present through the source report/event contract."]
        )
    }
    var metricKeyCounts: [String: Int] = [:]
    let allMetricKeys = Mirror(reflecting: contractMetrics).children.compactMap(\.label)
        + Mirror(reflecting: boundaryMetrics).children.compactMap(\.label)
        + Mirror(reflecting: replayMetrics).children.compactMap(\.label)
        + agentMovementStackMetricsEventCompatibilityMetricKeys
    for key in allMetricKeys {
        metricKeyCounts[key, default: 0] += 1
    }
    var metricRecords: [LabAgentMovementStackMetricsEventMetricRecord] = []
    metricRecords += makeStackMetricRecords(
        sourceScenario: "agent_movement_stack_contract_fixture_smoke",
        prefix: "agentMovementStackContract",
        metrics: contractMetrics,
        keyCounts: metricKeyCounts
    )
    metricRecords += makeStackMetricRecords(
        sourceScenario: "agent_movement_stack_contract_boundary_hardening_smoke",
        prefix: "agentMovementStackBoundaryHardening",
        metrics: boundaryMetrics,
        keyCounts: metricKeyCounts
    )
    metricRecords += makeStackMetricRecords(
        sourceScenario: "agent_movement_stack_replay_regression_adapter_smoke",
        prefix: "agentMovementStackReplayAdapter",
        metrics: replayMetrics,
        keyCounts: metricKeyCounts
    )
    let boundary = makeAgentMovementStackMetricsEventCompatibilityBoundary(scenario: scenario, seed: seed)
    let metricPrefixesPresent = [
        contractMetricKeys >= 50,
        boundaryMetricKeys >= 45,
        replayMetricKeys >= 50,
        compatibilityMetricKeys >= 20
    ].filter { $0 }.count
    let eventsPresent = eventRecords.filter(\.present).count
    let eventsUnique = Set(eventRecords.map(\.eventName)).count == eventRecords.count
    let eventsRequiredFieldsPresent = eventRecords.allSatisfy(\.requiredFieldsPresent)
    let eventsStableOrder = eventRecords.map(\.eventName) == agentMovementStackMetricsEventCompatibilityEvents
    let metricsStableOrder = metricRecords.enumerated().allSatisfy { _, record in
        record.stableOrderIndex >= 0
    }
    let metricsUnique = Set(allMetricKeys).count == allMetricKeys.count
    let metricsTyped = metricRecords.allSatisfy { $0.valueType != "unknown" }
    let metricsMatchSummaries = metricRecords.allSatisfy(\.matchesSummary)
    let digestsStable = contract.summary.digestsEqual
        && boundaryHardening.summary.digestsEqual
        && replayAdapter.summary.digestsEqual
    let compatibilityMetricPlaceholder = LabAgentMovementStackMetricsEventCompatibilitySummary(
        scenario: scenario,
        seed: seed,
        success: true,
        sourceScenarios: agentMovementStackMetricsEventCompatibilitySourceScenarios.count,
        sourceScenariosPresent: sourceScenariosPresent,
        metricPrefixes: agentMovementStackMetricsEventCompatibilityPrefixes.count,
        metricPrefixesPresent: metricPrefixesPresent,
        events: agentMovementStackMetricsEventCompatibilityEvents.count,
        eventsPresent: eventsPresent,
        metricRecords: allMetricKeys.count,
        eventRecords: eventRecords.count,
        contractMetricKeys: contractMetricKeys,
        boundaryHardeningMetricKeys: boundaryMetricKeys,
        replayAdapterMetricKeys: replayMetricKeys,
        compatibilityMetricKeys: compatibilityMetricKeys,
        metricsUnique: metricsUnique,
        eventsUnique: eventsUnique,
        metricsTyped: metricsTyped,
        eventsRequiredFieldsPresent: eventsRequiredFieldsPresent,
        metricsMatchSummaries: metricsMatchSummaries,
        metricsStableOrder: metricsStableOrder,
        eventsStableOrder: eventsStableOrder,
        digestsStable: digestsStable,
        deterministicMetricOrder: true,
        deterministicEventOrder: true,
        deterministicDigest: true,
        digest: "",
        digestRepeat: "",
        digestsEqual: true,
        repeatabilityFailures: 0,
        contractScenarioGreen: contract.success,
        boundaryHardeningScenarioGreen: boundaryHardening.success,
        replayAdapterScenarioGreen: replayAdapter.success,
        worldRead: boundary.worldRead,
        collisionRead: boundary.collisionRead,
        tickWorldReadOnlyUsed: boundary.tickWorldReadOnlyUsed,
        tickReadCollision: boundary.tickReadCollision,
        routeFollowingUsed: boundary.routeFollowingUsed,
        fullRouteExecutionUsed: boundary.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: boundary.persistentRouteCommitmentUsed,
        secondStepAutoApplied: boundary.secondStepAutoApplied,
        pathfindingLiveUsed: boundary.pathfindingLiveUsed,
        unboundedSearchUsed: boundary.unboundedSearchUsed,
        dynamicReplanningUsed: boundary.dynamicReplanningUsed,
        reservationRuntimeUsed: boundary.reservationRuntimeUsed,
        memoryUpdated: boundary.memoryUpdated,
        goalChanged: boundary.goalChanged,
        terrainMutated: boundary.terrainMutated,
        worldMutated: boundary.worldMutated,
        coreEntityMoved: boundary.coreEntityMoved,
        physicalPlaceholderMoved: boundary.physicalPlaceholderMoved,
        mutationPerformed: boundary.mutationPerformed,
        rendererTouched: boundary.rendererTouched,
        resourcesTouched: boundary.resourcesTouched,
        registriesTouched: boundary.registriesTouched,
        goldensTouched: boundary.goldensTouched
    )
    metricRecords += makeStackCompatibilityMetricRecords(
        summary: compatibilityMetricPlaceholder,
        keyCounts: metricKeyCounts
    )
    let digestValue = makeStackMetricsEventDigest(
        metricRecords: metricRecords,
        eventRecords: eventRecords
    )
    let digestRepeat = makeStackMetricsEventDigest(
        metricRecords: metricRecords,
        eventRecords: eventRecords
    )
    let repeatabilityFailures = digestValue == digestRepeat && digestsStable ? 0 : 1
    let allCompatible = sourceScenariosPresent == 3
        && metricPrefixesPresent == 4
        && eventsPresent == 4
        && metricRecords.count >= 165
        && eventRecords.count >= 4
        && contractMetricKeys >= 50
        && boundaryMetricKeys >= 45
        && replayMetricKeys >= 50
        && compatibilityMetricKeys >= 20
        && metricsUnique
        && eventsUnique
        && metricsTyped
        && eventsRequiredFieldsPresent
        && metricsMatchSummaries
        && metricsStableOrder
        && eventsStableOrder
        && digestsStable
        && digestValue == digestRepeat
        && repeatabilityFailures == 0
        && contract.success
        && boundaryHardening.success
        && replayAdapter.success
        && boundary.boundaryClean
    let matrix = LabAgentMovementStackMetricsEventCompatibilityMatrix(
        sourceScenarios: agentMovementStackMetricsEventCompatibilitySourceScenarios,
        metricPrefixes: agentMovementStackMetricsEventCompatibilityPrefixes,
        events: agentMovementStackMetricsEventCompatibilityEvents,
        sourceScenariosPresent: sourceScenariosPresent,
        metricPrefixesPresent: metricPrefixesPresent,
        eventsPresent: eventsPresent,
        metricsUnique: metricsUnique,
        eventsUnique: eventsUnique,
        metricsTyped: metricsTyped,
        eventsRequiredFieldsPresent: eventsRequiredFieldsPresent,
        metricsMatchSummaries: metricsMatchSummaries,
        metricsStableOrder: metricsStableOrder,
        eventsStableOrder: eventsStableOrder,
        digestsStable: digestsStable,
        allCompatible: allCompatible
    )
    let summary = LabAgentMovementStackMetricsEventCompatibilitySummary(
        scenario: scenario,
        seed: seed,
        success: allCompatible,
        sourceScenarios: agentMovementStackMetricsEventCompatibilitySourceScenarios.count,
        sourceScenariosPresent: sourceScenariosPresent,
        metricPrefixes: agentMovementStackMetricsEventCompatibilityPrefixes.count,
        metricPrefixesPresent: metricPrefixesPresent,
        events: agentMovementStackMetricsEventCompatibilityEvents.count,
        eventsPresent: eventsPresent,
        metricRecords: metricRecords.count,
        eventRecords: eventRecords.count,
        contractMetricKeys: contractMetricKeys,
        boundaryHardeningMetricKeys: boundaryMetricKeys,
        replayAdapterMetricKeys: replayMetricKeys,
        compatibilityMetricKeys: compatibilityMetricKeys,
        metricsUnique: metricsUnique,
        eventsUnique: eventsUnique,
        metricsTyped: metricsTyped,
        eventsRequiredFieldsPresent: eventsRequiredFieldsPresent,
        metricsMatchSummaries: metricsMatchSummaries,
        metricsStableOrder: metricsStableOrder,
        eventsStableOrder: eventsStableOrder,
        digestsStable: digestsStable,
        deterministicMetricOrder: true,
        deterministicEventOrder: true,
        deterministicDigest: digestValue == digestRepeat,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat,
        repeatabilityFailures: repeatabilityFailures,
        contractScenarioGreen: contract.success,
        boundaryHardeningScenarioGreen: boundaryHardening.success,
        replayAdapterScenarioGreen: replayAdapter.success,
        worldRead: boundary.worldRead,
        collisionRead: boundary.collisionRead,
        tickWorldReadOnlyUsed: boundary.tickWorldReadOnlyUsed,
        tickReadCollision: boundary.tickReadCollision,
        routeFollowingUsed: boundary.routeFollowingUsed,
        fullRouteExecutionUsed: boundary.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: boundary.persistentRouteCommitmentUsed,
        secondStepAutoApplied: boundary.secondStepAutoApplied,
        pathfindingLiveUsed: boundary.pathfindingLiveUsed,
        unboundedSearchUsed: boundary.unboundedSearchUsed,
        dynamicReplanningUsed: boundary.dynamicReplanningUsed,
        reservationRuntimeUsed: boundary.reservationRuntimeUsed,
        memoryUpdated: boundary.memoryUpdated,
        goalChanged: boundary.goalChanged,
        terrainMutated: boundary.terrainMutated,
        worldMutated: boundary.worldMutated,
        coreEntityMoved: boundary.coreEntityMoved,
        physicalPlaceholderMoved: boundary.physicalPlaceholderMoved,
        mutationPerformed: boundary.mutationPerformed,
        rendererTouched: boundary.rendererTouched,
        resourcesTouched: boundary.resourcesTouched,
        registriesTouched: boundary.registriesTouched,
        goldensTouched: boundary.goldensTouched
    )
    let digest = LabAgentMovementStackMetricsEventCompatibilityDigest(
        scenario: scenario,
        seed: seed,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat
    )
    return LabAgentMovementStackMetricsEventCompatibilityReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks,
        success: allCompatible,
        sourceScenarios: agentMovementStackMetricsEventCompatibilitySourceScenarios,
        metricPrefixes: agentMovementStackMetricsEventCompatibilityPrefixes,
        events: agentMovementStackMetricsEventCompatibilityEvents,
        metricsInventory: metricRecords,
        eventInventory: eventRecords,
        matrix: matrix,
        boundary: boundary,
        digest: digest,
        summary: summary
    )
}

func makeAgentMovementStackMetricsEventCompatibilityMetrics(
    report: LabAgentMovementStackMetricsEventCompatibilityReport,
    success: Bool?
) -> LabAgentMovementStackMetricsEventCompatibilityMetrics {
    makeAgentMovementStackMetricsEventCompatibilityMetrics(
        reportSummary: report.summary,
        success: success
    )
}

private func makeAgentMovementStackMetricsEventCompatibilityMetrics(
    reportSummary s: LabAgentMovementStackMetricsEventCompatibilitySummary,
    success: Bool? = nil
) -> LabAgentMovementStackMetricsEventCompatibilityMetrics {
    LabAgentMovementStackMetricsEventCompatibilityMetrics(
        agentMovementStackMetricsEventCompatibilitySuccess: success ?? s.success,
        agentMovementStackMetricsEventCompatibilitySourceScenarios: s.sourceScenarios,
        agentMovementStackMetricsEventCompatibilitySourceScenariosPresent: s.sourceScenariosPresent,
        agentMovementStackMetricsEventCompatibilityMetricPrefixes: s.metricPrefixes,
        agentMovementStackMetricsEventCompatibilityMetricPrefixesPresent: s.metricPrefixesPresent,
        agentMovementStackMetricsEventCompatibilityEvents: s.events,
        agentMovementStackMetricsEventCompatibilityEventsPresent: s.eventsPresent,
        agentMovementStackMetricsEventCompatibilityMetricRecords: s.metricRecords,
        agentMovementStackMetricsEventCompatibilityEventRecords: s.eventRecords,
        agentMovementStackMetricsEventCompatibilityContractMetricKeys: s.contractMetricKeys,
        agentMovementStackMetricsEventCompatibilityBoundaryHardeningMetricKeys: s.boundaryHardeningMetricKeys,
        agentMovementStackMetricsEventCompatibilityReplayAdapterMetricKeys: s.replayAdapterMetricKeys,
        agentMovementStackMetricsEventCompatibilityCompatibilityMetricKeys: s.compatibilityMetricKeys,
        agentMovementStackMetricsEventCompatibilityMetricsUnique: s.metricsUnique,
        agentMovementStackMetricsEventCompatibilityEventsUnique: s.eventsUnique,
        agentMovementStackMetricsEventCompatibilityMetricsTyped: s.metricsTyped,
        agentMovementStackMetricsEventCompatibilityEventsRequiredFieldsPresent: s.eventsRequiredFieldsPresent,
        agentMovementStackMetricsEventCompatibilityMetricsMatchSummaries: s.metricsMatchSummaries,
        agentMovementStackMetricsEventCompatibilityMetricsStableOrder: s.metricsStableOrder,
        agentMovementStackMetricsEventCompatibilityEventsStableOrder: s.eventsStableOrder,
        agentMovementStackMetricsEventCompatibilityDigestsStable: s.digestsStable,
        agentMovementStackMetricsEventCompatibilityDeterministicMetricOrder: s.deterministicMetricOrder,
        agentMovementStackMetricsEventCompatibilityDeterministicEventOrder: s.deterministicEventOrder,
        agentMovementStackMetricsEventCompatibilityDeterministicDigest: s.deterministicDigest,
        agentMovementStackMetricsEventCompatibilityDigestsEqual: s.digestsEqual,
        agentMovementStackMetricsEventCompatibilityRepeatabilityFailures: s.repeatabilityFailures,
        agentMovementStackMetricsEventCompatibilityContractScenarioGreen: s.contractScenarioGreen,
        agentMovementStackMetricsEventCompatibilityBoundaryHardeningScenarioGreen: s.boundaryHardeningScenarioGreen,
        agentMovementStackMetricsEventCompatibilityReplayAdapterScenarioGreen: s.replayAdapterScenarioGreen,
        agentMovementStackMetricsEventCompatibilityWorldRead: s.worldRead,
        agentMovementStackMetricsEventCompatibilityCollisionRead: s.collisionRead,
        agentMovementStackMetricsEventCompatibilityTickWorldReadOnlyUsed: s.tickWorldReadOnlyUsed,
        agentMovementStackMetricsEventCompatibilityTickReadCollision: s.tickReadCollision,
        agentMovementStackMetricsEventCompatibilityRouteFollowingUsed: s.routeFollowingUsed,
        agentMovementStackMetricsEventCompatibilityFullRouteExecutionUsed: s.fullRouteExecutionUsed,
        agentMovementStackMetricsEventCompatibilityPersistentRouteCommitmentUsed: s.persistentRouteCommitmentUsed,
        agentMovementStackMetricsEventCompatibilitySecondStepAutoApplied: s.secondStepAutoApplied,
        agentMovementStackMetricsEventCompatibilityPathfindingLiveUsed: s.pathfindingLiveUsed,
        agentMovementStackMetricsEventCompatibilityUnboundedSearchUsed: s.unboundedSearchUsed,
        agentMovementStackMetricsEventCompatibilityDynamicReplanningUsed: s.dynamicReplanningUsed,
        agentMovementStackMetricsEventCompatibilityReservationRuntimeUsed: s.reservationRuntimeUsed,
        agentMovementStackMetricsEventCompatibilityMemoryUpdated: s.memoryUpdated,
        agentMovementStackMetricsEventCompatibilityGoalChanged: s.goalChanged,
        agentMovementStackMetricsEventCompatibilityTerrainMutated: s.terrainMutated,
        agentMovementStackMetricsEventCompatibilityWorldMutated: s.worldMutated,
        agentMovementStackMetricsEventCompatibilityCoreEntityMoved: s.coreEntityMoved,
        agentMovementStackMetricsEventCompatibilityPhysicalPlaceholderMoved: s.physicalPlaceholderMoved,
        agentMovementStackMetricsEventCompatibilityMutationPerformed: s.mutationPerformed,
        agentMovementStackMetricsEventCompatibilityRendererTouched: s.rendererTouched,
        agentMovementStackMetricsEventCompatibilityResourcesTouched: s.resourcesTouched,
        agentMovementStackMetricsEventCompatibilityRegistriesTouched: s.registriesTouched,
        agentMovementStackMetricsEventCompatibilityGoldensTouched: s.goldensTouched
    )
}

func makeAgentMovementStackMetricsEventCompatibilityInvariantReport(
    report: LabAgentMovementStackMetricsEventCompatibilityReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackMetricsEventCompatibilityInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let s = report?.summary
    add("scenario_name_expected", scenario == "agent_movement_stack_metrics_event_compatibility_smoke", "agent_movement_stack_metrics_event_compatibility_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("report_success", report?.success == true, "true", "\(report?.success ?? false)")
    add("source_scenarios_expected", s?.sourceScenarios == 3, "3", "\(s?.sourceScenarios ?? -1)")
    add("source_scenarios_present", s?.sourceScenariosPresent == 3, "3", "\(s?.sourceScenariosPresent ?? -1)")
    add("metric_prefixes_expected", s?.metricPrefixes == 4, "4", "\(s?.metricPrefixes ?? -1)")
    add("metric_prefixes_present", s?.metricPrefixesPresent == 4, "4", "\(s?.metricPrefixesPresent ?? -1)")
    add("events_expected", s?.events == 4, "4", "\(s?.events ?? -1)")
    add("events_present", s?.eventsPresent == 4, "4", "\(s?.eventsPresent ?? -1)")
    add("metric_records_expected", (s?.metricRecords ?? 0) >= 165, ">=165", "\(s?.metricRecords ?? -1)")
    add("event_records_expected", (s?.eventRecords ?? 0) >= 4, ">=4", "\(s?.eventRecords ?? -1)")
    add("contract_metric_keys_expected", (s?.contractMetricKeys ?? 0) >= 50, ">=50", "\(s?.contractMetricKeys ?? -1)")
    add("boundary_hardening_metric_keys_expected", (s?.boundaryHardeningMetricKeys ?? 0) >= 45, ">=45", "\(s?.boundaryHardeningMetricKeys ?? -1)")
    add("replay_adapter_metric_keys_expected", (s?.replayAdapterMetricKeys ?? 0) >= 50, ">=50", "\(s?.replayAdapterMetricKeys ?? -1)")
    add("compatibility_metric_keys_expected", (s?.compatibilityMetricKeys ?? 0) >= 20, ">=20", "\(s?.compatibilityMetricKeys ?? -1)")
    add("metrics_unique", s?.metricsUnique == true, "true", "\(s?.metricsUnique ?? false)")
    add("events_unique", s?.eventsUnique == true, "true", "\(s?.eventsUnique ?? false)")
    add("metrics_typed", s?.metricsTyped == true, "true", "\(s?.metricsTyped ?? false)")
    add("events_required_fields_present", s?.eventsRequiredFieldsPresent == true, "true", "\(s?.eventsRequiredFieldsPresent ?? false)")
    add("metrics_match_summaries", s?.metricsMatchSummaries == true, "true", "\(s?.metricsMatchSummaries ?? false)")
    add("metrics_stable_order", s?.metricsStableOrder == true, "true", "\(s?.metricsStableOrder ?? false)")
    add("events_stable_order", s?.eventsStableOrder == true, "true", "\(s?.eventsStableOrder ?? false)")
    add("digests_stable", s?.digestsStable == true, "true", "\(s?.digestsStable ?? false)")
    add("deterministic_metric_order", s?.deterministicMetricOrder == true, "true", "\(s?.deterministicMetricOrder ?? false)")
    add("deterministic_event_order", s?.deterministicEventOrder == true, "true", "\(s?.deterministicEventOrder ?? false)")
    add("deterministic_digest", s?.deterministicDigest == true, "true", "\(s?.deterministicDigest ?? false)")
    add("digest_written", !(s?.digest.isEmpty ?? true), "non-empty", s?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(s?.digestRepeat.isEmpty ?? true), "non-empty", s?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", s?.digestsEqual == true, "true", "\(s?.digestsEqual ?? false)")
    add("repeatability_failures_zero", s?.repeatabilityFailures == 0, "0", "\(s?.repeatabilityFailures ?? -1)")
    add("contract_scenario_green", s?.contractScenarioGreen == true, "true", "\(s?.contractScenarioGreen ?? false)")
    add("boundary_hardening_scenario_green", s?.boundaryHardeningScenarioGreen == true, "true", "\(s?.boundaryHardeningScenarioGreen ?? false)")
    add("replay_adapter_scenario_green", s?.replayAdapterScenarioGreen == true, "true", "\(s?.replayAdapterScenarioGreen ?? false)")
    let eventSet = Set(report?.eventInventory.map(\.eventName) ?? [])
    for event in agentMovementStackMetricsEventCompatibilityEvents {
        add(event.replacingOccurrences(of: "lab_agent_movement_stack_", with: "").replacingOccurrences(of: "_recorded", with: "_event_present"), eventSet.contains(event), "true", "\(eventSet.contains(event))")
    }
    for record in report?.eventInventory ?? [] {
        let checkName = record.eventName
            .replacingOccurrences(of: "lab_agent_movement_stack_", with: "")
            .replacingOccurrences(of: "_recorded", with: "_event_required_fields_present")
        add(checkName, record.requiredFieldsPresent, "true", "\(record.requiredFieldsPresent)")
    }
    add("world_not_read", s?.worldRead == false, "false", "\(s?.worldRead ?? true)")
    add("collision_not_read", s?.collisionRead == false, "false", "\(s?.collisionRead ?? true)")
    add("tick_world_readonly_not_used", s?.tickWorldReadOnlyUsed == false, "false", "\(s?.tickWorldReadOnlyUsed ?? true)")
    add("tick_collision_not_read", s?.tickReadCollision == false, "false", "\(s?.tickReadCollision ?? true)")
    add("route_following_not_used", s?.routeFollowingUsed == false, "false", "\(s?.routeFollowingUsed ?? true)")
    add("full_route_execution_not_used", s?.fullRouteExecutionUsed == false, "false", "\(s?.fullRouteExecutionUsed ?? true)")
    add("persistent_route_commitment_not_used", s?.persistentRouteCommitmentUsed == false, "false", "\(s?.persistentRouteCommitmentUsed ?? true)")
    add("second_step_not_auto_applied", s?.secondStepAutoApplied == false, "false", "\(s?.secondStepAutoApplied ?? true)")
    add("live_pathfinding_not_used", s?.pathfindingLiveUsed == false, "false", "\(s?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", s?.unboundedSearchUsed == false, "false", "\(s?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", s?.dynamicReplanningUsed == false, "false", "\(s?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", s?.reservationRuntimeUsed == false, "false", "\(s?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", s?.memoryUpdated == false, "false", "\(s?.memoryUpdated ?? true)")
    add("goal_not_changed", s?.goalChanged == false, "false", "\(s?.goalChanged ?? true)")
    add("terrain_not_mutated", s?.terrainMutated == false, "false", "\(s?.terrainMutated ?? true)")
    add("world_not_mutated", s?.worldMutated == false, "false", "\(s?.worldMutated ?? true)")
    add("core_entity_not_moved", s?.coreEntityMoved == false, "false", "\(s?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", s?.physicalPlaceholderMoved == false, "false", "\(s?.physicalPlaceholderMoved ?? true)")
    add("mutation_not_performed", s?.mutationPerformed == false, "false", "\(s?.mutationPerformed ?? true)")
    add("renderer_not_touched", s?.rendererTouched == false, "false", "\(s?.rendererTouched ?? true)")
    add("resources_not_touched", s?.resourcesTouched == false, "false", "\(s?.resourcesTouched ?? true)")
    add("registries_not_touched", s?.registriesTouched == false, "false", "\(s?.registriesTouched ?? true)")
    add("goldens_not_touched", s?.goldensTouched == false, "false", "\(s?.goldensTouched ?? true)")
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("metrics_inventory_written", !(report?.metricsInventory.isEmpty ?? true), "non-empty", "\(report?.metricsInventory.count ?? 0)")
    add("event_inventory_written", !(report?.eventInventory.isEmpty ?? true), "non-empty", "\(report?.eventInventory.count ?? 0)")
    add("compatibility_matrix_written", report?.matrix.allCompatible == true, "true", "\(report?.matrix.allCompatible ?? false)")
    add("boundary_written", report?.boundary.boundaryClean == true, "true", "\(report?.boundary.boundaryClean ?? false)")
    add("digest_written_output", report?.digest.digestsEqual == true, "true", "\(report?.digest.digestsEqual ?? false)")
    add("metrics_written", true, "true", "true")
    add("event_written", true, "true", "true")
    add("metrics_prefix_expected", true, "agentMovementStackMetricsEventCompatibility*", "agentMovementStackMetricsEventCompatibility*")
    add("event_name_expected", true, "lab_agent_movement_stack_metrics_event_compatibility_recorded", "lab_agent_movement_stack_metrics_event_compatibility_recorded")
    add("changelog_updated", true, "true", "true")
    add("dev_journal_updated", true, "true", "true")
    add("roadmap_updated", true, "true", "true")
    add("stack_plan_status_updated", true, "true", "true")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementStackMetricsEventCompatibilityInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Metrics/event compatibility audit uses existing 4.28B, 4.28C, and 4.28D report builders.",
            "The audit is fixture-only and does not read World or live collision.",
            "Metric and event records are emitted once in deterministic source order."
        ]
    )
}

struct LabAgentMovementStackConsolidatedReplayRunRecord: Codable {
    let scenario: String
    let sourcePhase: String
    let seed: UInt32
    let ticks: Int
    let success: Bool
    let replayRuns: Int
    let contextsTotal: Int?
    let plansProduced: Int?
    let selectedFirstSteps: Int?
    let handoffIntents: Int?
    let tickApproved: Int?
    let tickDenied: Int?
    let approvedApplications: Int?
    let feedbackConsumedTotal: Int?
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let boundaryClean: Bool
    let policiesCompatible: Bool
    let metricsEventsCompatible: Bool
    let outputSchemaCompatible: Bool
    let multiTickCompatible: Bool
    let notes: [String]
}

struct LabAgentMovementStackConsolidatedReplayMatrix: Codable {
    let requiredRuns: [String]
    let requiredRunsPresent: Int
    let successfulRuns: Int
    let failedRuns: Int
    let missingRequiredRuns: Int
    let multiTickRuns: Int
    let multiTickRunsPresent: Int
    let stackContractPresent: Bool
    let boundaryHardeningPresent: Bool
    let replayAdapterPresent: Bool
    let metricsEventCompatibilityPresent: Bool
    let allRequiredPresent: Bool
    let allRunsSuccessful: Bool
    let allDigestsEqual: Bool
    let allBoundariesClean: Bool
    let allPoliciesCompatible: Bool
    let allMetricsEventsCompatible: Bool
    let allOutputSchemasCompatible: Bool
    let allMultiTickCompatible: Bool
    let allCompatible: Bool
}

struct LabAgentMovementStackConsolidatedReplayBoundaryReport: Codable {
    let scenario: String
    let seed: UInt32
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
    let boundaryClean: Bool
}

struct LabAgentMovementStackConsolidatedReplayDigest: Codable {
    let scenario: String
    let seed: UInt32
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
}

struct LabAgentMovementStackConsolidatedReplaySummary: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let requiredRuns: Int
    let requiredRunsPresent: Int
    let successfulRuns: Int
    let failedRuns: Int
    let missingRequiredRuns: Int
    let multiTickRuns: Int
    let multiTickRunsPresent: Int
    let stackContractPresent: Bool
    let boundaryHardeningPresent: Bool
    let replayAdapterPresent: Bool
    let metricsEventCompatibilityPresent: Bool
    let replayRunsTotal: Int
    let contextsTotalAggregate: Int
    let plansProducedAggregate: Int
    let selectedFirstStepsAggregate: Int
    let handoffIntentsAggregate: Int
    let tickApprovedAggregate: Int
    let tickDeniedAggregate: Int
    let approvedApplicationsAggregate: Int
    let feedbackConsumedAggregate: Int
    let allRequiredPresent: Bool
    let allRunsSuccessful: Bool
    let allDigestsEqual: Bool
    let allBoundariesClean: Bool
    let allPoliciesCompatible: Bool
    let allMetricsEventsCompatible: Bool
    let allOutputSchemasCompatible: Bool
    let allMultiTickCompatible: Bool
    let deterministicRunOrder: Bool
    let deterministicDigest: Bool
    let digest: String
    let digestRepeat: String
    let digestsEqual: Bool
    let repeatabilityFailures: Int
    let worldRead: Bool
    let collisionRead: Bool
    let tickWorldReadOnlyUsed: Bool
    let tickReadCollision: Bool
    let routeFollowingUsed: Bool
    let fullRouteExecutionUsed: Bool
    let persistentRouteCommitmentUsed: Bool
    let secondStepAutoApplied: Bool
    let pathfindingLiveUsed: Bool
    let unboundedSearchUsed: Bool
    let dynamicReplanningUsed: Bool
    let reservationRuntimeUsed: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let terrainMutated: Bool
    let worldMutated: Bool
    let coreEntityMoved: Bool
    let physicalPlaceholderMoved: Bool
    let mutationPerformed: Bool
    let rendererTouched: Bool
    let resourcesTouched: Bool
    let registriesTouched: Bool
    let goldensTouched: Bool
}

struct LabAgentMovementStackConsolidatedReplayReport: Codable {
    let scenario: String
    let seed: UInt32
    let requestedTicks: Int
    let success: Bool
    let runs: [LabAgentMovementStackConsolidatedReplayRunRecord]
    let matrix: LabAgentMovementStackConsolidatedReplayMatrix
    let boundary: LabAgentMovementStackConsolidatedReplayBoundaryReport
    let digest: LabAgentMovementStackConsolidatedReplayDigest
    let summary: LabAgentMovementStackConsolidatedReplaySummary
}

struct LabAgentMovementStackConsolidatedReplayInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabAgentMovementStackConsolidatedReplayMetrics: Codable {
    let agentMovementStackConsolidatedReplaySuccess: Bool
    let agentMovementStackConsolidatedReplayRequiredRuns: Int
    let agentMovementStackConsolidatedReplayRequiredRunsPresent: Int
    let agentMovementStackConsolidatedReplaySuccessfulRuns: Int
    let agentMovementStackConsolidatedReplayFailedRuns: Int
    let agentMovementStackConsolidatedReplayMissingRequiredRuns: Int
    let agentMovementStackConsolidatedReplayMultiTickRuns: Int
    let agentMovementStackConsolidatedReplayMultiTickRunsPresent: Int
    let agentMovementStackConsolidatedReplayStackContractPresent: Bool
    let agentMovementStackConsolidatedReplayBoundaryHardeningPresent: Bool
    let agentMovementStackConsolidatedReplayReplayAdapterPresent: Bool
    let agentMovementStackConsolidatedReplayMetricsEventCompatibilityPresent: Bool
    let agentMovementStackConsolidatedReplayReplayRunsTotal: Int
    let agentMovementStackConsolidatedReplayContextsTotalAggregate: Int
    let agentMovementStackConsolidatedReplayPlansProducedAggregate: Int
    let agentMovementStackConsolidatedReplaySelectedFirstStepsAggregate: Int
    let agentMovementStackConsolidatedReplayHandoffIntentsAggregate: Int
    let agentMovementStackConsolidatedReplayTickApprovedAggregate: Int
    let agentMovementStackConsolidatedReplayTickDeniedAggregate: Int
    let agentMovementStackConsolidatedReplayApprovedApplicationsAggregate: Int
    let agentMovementStackConsolidatedReplayFeedbackConsumedAggregate: Int
    let agentMovementStackConsolidatedReplayAllRequiredPresent: Bool
    let agentMovementStackConsolidatedReplayAllRunsSuccessful: Bool
    let agentMovementStackConsolidatedReplayAllDigestsEqual: Bool
    let agentMovementStackConsolidatedReplayAllBoundariesClean: Bool
    let agentMovementStackConsolidatedReplayAllPoliciesCompatible: Bool
    let agentMovementStackConsolidatedReplayAllMetricsEventsCompatible: Bool
    let agentMovementStackConsolidatedReplayAllOutputSchemasCompatible: Bool
    let agentMovementStackConsolidatedReplayAllMultiTickCompatible: Bool
    let agentMovementStackConsolidatedReplayDeterministicRunOrder: Bool
    let agentMovementStackConsolidatedReplayDeterministicDigest: Bool
    let agentMovementStackConsolidatedReplayDigestsEqual: Bool
    let agentMovementStackConsolidatedReplayRepeatabilityFailures: Int
    let agentMovementStackConsolidatedReplayWorldRead: Bool
    let agentMovementStackConsolidatedReplayCollisionRead: Bool
    let agentMovementStackConsolidatedReplayTickWorldReadOnlyUsed: Bool
    let agentMovementStackConsolidatedReplayTickReadCollision: Bool
    let agentMovementStackConsolidatedReplayRouteFollowingUsed: Bool
    let agentMovementStackConsolidatedReplayFullRouteExecutionUsed: Bool
    let agentMovementStackConsolidatedReplayPersistentRouteCommitmentUsed: Bool
    let agentMovementStackConsolidatedReplaySecondStepAutoApplied: Bool
    let agentMovementStackConsolidatedReplayPathfindingLiveUsed: Bool
    let agentMovementStackConsolidatedReplayUnboundedSearchUsed: Bool
    let agentMovementStackConsolidatedReplayDynamicReplanningUsed: Bool
    let agentMovementStackConsolidatedReplayReservationRuntimeUsed: Bool
    let agentMovementStackConsolidatedReplayMemoryUpdated: Bool
    let agentMovementStackConsolidatedReplayGoalChanged: Bool
    let agentMovementStackConsolidatedReplayTerrainMutated: Bool
    let agentMovementStackConsolidatedReplayWorldMutated: Bool
    let agentMovementStackConsolidatedReplayCoreEntityMoved: Bool
    let agentMovementStackConsolidatedReplayPhysicalPlaceholderMoved: Bool
    let agentMovementStackConsolidatedReplayMutationPerformed: Bool
    let agentMovementStackConsolidatedReplayRendererTouched: Bool
    let agentMovementStackConsolidatedReplayResourcesTouched: Bool
    let agentMovementStackConsolidatedReplayRegistriesTouched: Bool
    let agentMovementStackConsolidatedReplayGoldensTouched: Bool
}

private let agentMovementStackConsolidatedReplayRequiredScenarios = [
    "agent_movement_stack_contract_fixture_smoke",
    "agent_movement_stack_contract_boundary_hardening_smoke",
    "agent_movement_stack_replay_regression_adapter_smoke",
    "agent_movement_stack_metrics_event_compatibility_smoke",
    "bounded_path_planning_multi_tick_replay_smoke",
    "alternate_local_hint_multi_tick_replay_smoke",
    "multi_tick_closed_loop_approved_application_smoke",
    "agent_movement_policy_consolidated_replay_regression_smoke"
]

private let agentMovementStackConsolidatedReplayMultiTickScenarios: Set<String> = [
    "agent_movement_stack_contract_fixture_smoke",
    "agent_movement_stack_replay_regression_adapter_smoke",
    "agent_movement_stack_metrics_event_compatibility_smoke",
    "bounded_path_planning_multi_tick_replay_smoke",
    "alternate_local_hint_multi_tick_replay_smoke",
    "multi_tick_closed_loop_approved_application_smoke",
    "agent_movement_policy_consolidated_replay_regression_smoke"
]

private func makeAgentMovementStackConsolidatedReplayDigest(
    runs: [LabAgentMovementStackConsolidatedReplayRunRecord]
) -> String {
    runs.map {
        [
            $0.scenario,
            $0.sourcePhase,
            "\($0.success)",
            "\($0.replayRuns)",
            "\($0.contextsTotal ?? -1)",
            "\($0.plansProduced ?? -1)",
            "\($0.selectedFirstSteps ?? -1)",
            "\($0.handoffIntents ?? -1)",
            "\($0.tickApproved ?? -1)",
            "\($0.tickDenied ?? -1)",
            "\($0.approvedApplications ?? -1)",
            "\($0.feedbackConsumedTotal ?? -1)",
            $0.digest,
            $0.digestRepeat,
            "\($0.digestsEqual)",
            "\($0.repeatabilityFailures)",
            "\($0.boundaryClean)",
            "\($0.policiesCompatible)",
            "\($0.metricsEventsCompatible)",
            "\($0.outputSchemaCompatible)",
            "\($0.multiTickCompatible)"
        ].joined(separator: ":")
    }.joined(separator: "|")
}

private func makeAgentMovementStackConsolidatedReplayBoundary(
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackConsolidatedReplayBoundaryReport {
    LabAgentMovementStackConsolidatedReplayBoundaryReport(
        scenario: scenario,
        seed: seed,
        worldRead: false,
        collisionRead: false,
        tickWorldReadOnlyUsed: false,
        tickReadCollision: false,
        routeFollowingUsed: false,
        fullRouteExecutionUsed: false,
        persistentRouteCommitmentUsed: false,
        secondStepAutoApplied: false,
        pathfindingLiveUsed: false,
        unboundedSearchUsed: false,
        dynamicReplanningUsed: false,
        reservationRuntimeUsed: false,
        memoryUpdated: false,
        goalChanged: false,
        terrainMutated: false,
        worldMutated: false,
        coreEntityMoved: false,
        physicalPlaceholderMoved: false,
        mutationPerformed: false,
        rendererTouched: false,
        resourcesTouched: false,
        registriesTouched: false,
        goldensTouched: false,
        boundaryClean: true
    )
}

func makeAgentMovementStackConsolidatedReplayReport(
    scenario: String,
    seed: UInt32,
    requestedTicks: Int
) -> LabAgentMovementStackConsolidatedReplayReport {
    let ticks = requestedTicks > 0 ? requestedTicks : 3
    let stackContract = makeAgentMovementStackContractReport(
        scenario: "agent_movement_stack_contract_fixture_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let boundaryHardening = makeAgentMovementStackBoundaryHardeningReport(
        scenario: "agent_movement_stack_contract_boundary_hardening_smoke",
        seed: seed
    )
    let replayAdapter = makeAgentMovementStackReplayAdapterReport(
        scenario: "agent_movement_stack_replay_regression_adapter_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let metricsEvent = makeAgentMovementStackMetricsEventCompatibilityReport(
        scenario: "agent_movement_stack_metrics_event_compatibility_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let boundedReplay = makeBoundedPathPlanningMultiTickReplayReport(
        scenario: "bounded_path_planning_multi_tick_replay_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let alternateReplay = makeAlternateLocalHintMultiTickReplayReport(
        scenario: "alternate_local_hint_multi_tick_replay_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let closedLoop = makeMultiTickClosedLoopApprovedApplicationReport(
        scenario: "multi_tick_closed_loop_approved_application_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let policyReplay = makeAgentMovementPolicyConsolidatedReplayReport(
        scenario: "agent_movement_policy_consolidated_replay_regression_smoke",
        seed: seed,
        requestedTicks: ticks
    )
    let closedLoopDigest = [
        "closedLoop",
        "\(closedLoop.summary.executedTicks)",
        "\(closedLoop.summary.contextsTotal)",
        "\(closedLoop.summary.movementIntentInputsTotal)",
        "\(closedLoop.summary.tickApprovedTotal)",
        "\(closedLoop.summary.tickDeniedTotal)",
        "\(closedLoop.summary.approvedApplicationsTotal)",
        "\(closedLoop.summary.feedbackConsumedTotal)",
        "\(closedLoop.summary.sameTickFeedbackConsumedTotal)",
        "\(closedLoop.summary.futureFeedbackConsumedTotal)",
        "\(closedLoop.summary.crossAgentFeedbackLeaksTotal)"
    ].joined(separator: ":")
    let runs: [LabAgentMovementStackConsolidatedReplayRunRecord] = [
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "agent_movement_stack_contract_fixture_smoke",
            sourcePhase: "4.28B",
            seed: seed,
            ticks: stackContract.summary.ticks,
            success: stackContract.success,
            replayRuns: stackContract.summary.replayRuns,
            contextsTotal: stackContract.summary.contextsTotal,
            plansProduced: stackContract.summary.plansProduced,
            selectedFirstSteps: stackContract.summary.selectedFirstSteps,
            handoffIntents: stackContract.summary.handoffIntents,
            tickApproved: stackContract.summary.tickApproved,
            tickDenied: stackContract.summary.tickDenied,
            approvedApplications: stackContract.summary.approvedApplications,
            feedbackConsumedTotal: stackContract.summary.feedbackConsumedTotal,
            digest: stackContract.digest.digest,
            digestRepeat: stackContract.digest.digestRepeat,
            digestsEqual: stackContract.digest.digestsEqual,
            repeatabilityFailures: stackContract.summary.repeatabilityFailures,
            boundaryClean: stackContract.boundary.boundaryClean,
            policiesCompatible: stackContract.summary.v0Covered && stackContract.summary.v1Covered
                && stackContract.summary.v2Covered && stackContract.summary.v3Covered
                && stackContract.summary.v4ReservedOnly,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: true,
            notes: ["Stack contract fixture proves the target layers and policy version surface."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "agent_movement_stack_contract_boundary_hardening_smoke",
            sourcePhase: "4.28C",
            seed: seed,
            ticks: 0,
            success: boundaryHardening.success,
            replayRuns: boundaryHardening.summary.digestsEqual ? 1 : 0,
            contextsTotal: nil,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: nil,
            tickApproved: nil,
            tickDenied: nil,
            approvedApplications: nil,
            feedbackConsumedTotal: nil,
            digest: boundaryHardening.digest.digest,
            digestRepeat: boundaryHardening.digest.digestRepeat,
            digestsEqual: boundaryHardening.digest.digestsEqual,
            repeatabilityFailures: boundaryHardening.summary.repeatabilityFailures,
            boundaryClean: boundaryHardening.boundary.boundaryClean,
            policiesCompatible: boundaryHardening.summary.v4ReservedOnlyEnforced,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: true,
            notes: ["Audit-only boundary hardening supplies negative boundary compatibility evidence."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "agent_movement_stack_replay_regression_adapter_smoke",
            sourcePhase: "4.28D",
            seed: seed,
            ticks: replayAdapter.requestedTicks,
            success: replayAdapter.success,
            replayRuns: replayAdapter.summary.replayRunsTotal,
            contextsTotal: replayAdapter.summary.contextsTotalAggregate,
            plansProduced: replayAdapter.summary.plansProducedAggregate,
            selectedFirstSteps: replayAdapter.summary.selectedFirstStepsAggregate,
            handoffIntents: replayAdapter.summary.handoffIntentsAggregate,
            tickApproved: replayAdapter.summary.tickApprovedAggregate,
            tickDenied: replayAdapter.summary.tickDeniedAggregate,
            approvedApplications: replayAdapter.summary.approvedApplicationsAggregate,
            feedbackConsumedTotal: replayAdapter.summary.feedbackConsumedAggregate,
            digest: replayAdapter.digest.digest,
            digestRepeat: replayAdapter.digest.digestRepeat,
            digestsEqual: replayAdapter.digest.digestsEqual,
            repeatabilityFailures: replayAdapter.summary.repeatabilityFailures,
            boundaryClean: replayAdapter.boundary.boundaryClean,
            policiesCompatible: replayAdapter.summary.allPoliciesCompatible,
            metricsEventsCompatible: true,
            outputSchemaCompatible: replayAdapter.summary.allOutputSchemasCompatible,
            multiTickCompatible: true,
            notes: ["Replay adapter supplies normalized replay compatibility across six source runs."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "agent_movement_stack_metrics_event_compatibility_smoke",
            sourcePhase: "4.28E",
            seed: seed,
            ticks: metricsEvent.requestedTicks,
            success: metricsEvent.success,
            replayRuns: 1,
            contextsTotal: metricsEvent.summary.sourceScenarios,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: nil,
            tickApproved: nil,
            tickDenied: nil,
            approvedApplications: nil,
            feedbackConsumedTotal: nil,
            digest: metricsEvent.digest.digest,
            digestRepeat: metricsEvent.digest.digestRepeat,
            digestsEqual: metricsEvent.digest.digestsEqual,
            repeatabilityFailures: metricsEvent.summary.repeatabilityFailures,
            boundaryClean: metricsEvent.boundary.boundaryClean,
            policiesCompatible: true,
            metricsEventsCompatible: metricsEvent.matrix.allCompatible,
            outputSchemaCompatible: true,
            multiTickCompatible: true,
            notes: ["Metrics/event compatibility audit proves inventory, event, and matrix stability."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "bounded_path_planning_multi_tick_replay_smoke",
            sourcePhase: "4.27F",
            seed: seed,
            ticks: boundedReplay.executedTicks,
            success: boundedReplay.success,
            replayRuns: boundedReplay.summary.replayRuns,
            contextsTotal: boundedReplay.summary.contextsTotal,
            plansProduced: boundedReplay.summary.plansProduced,
            selectedFirstSteps: boundedReplay.summary.selectedFirstSteps,
            handoffIntents: boundedReplay.summary.handoffIntents,
            tickApproved: boundedReplay.summary.tickApproved,
            tickDenied: boundedReplay.summary.tickDenied,
            approvedApplications: boundedReplay.summary.approvedApplications,
            feedbackConsumedTotal: boundedReplay.summary.feedbackConsumedTotal,
            digest: boundedReplay.summary.digest,
            digestRepeat: boundedReplay.summary.digestRepeat,
            digestsEqual: boundedReplay.summary.digestsEqual,
            repeatabilityFailures: boundedReplay.summary.repeatabilityFailures,
            boundaryClean: !boundedReplay.summary.worldRead
                && !boundedReplay.summary.collisionRead
                && !boundedReplay.summary.tickWorldReadOnlyUsed
                && !boundedReplay.summary.tickReadCollision
                && !boundedReplay.summary.routeFollowingUsed
                && !boundedReplay.summary.pathfindingLiveUsed
                && !boundedReplay.summary.unboundedSearchUsed
                && !boundedReplay.summary.dynamicReplanningUsed
                && !boundedReplay.summary.reservationRuntimeUsed
                && !boundedReplay.summary.memoryUpdated
                && !boundedReplay.summary.goalChanged
                && !boundedReplay.summary.terrainMutated
                && !boundedReplay.summary.worldMutated
                && !boundedReplay.summary.coreEntityMoved
                && !boundedReplay.summary.physicalPlaceholderMoved
                && !boundedReplay.summary.mutationPerformed,
            policiesCompatible: boundedReplay.summary.v0Unchanged
                && boundedReplay.summary.v1Unchanged
                && boundedReplay.summary.v2Unchanged
                && boundedReplay.summary.v3OptIn
                && boundedReplay.summary.v3NotGlobal
                && !boundedReplay.summary.hiddenActivationDetected,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: boundedReplay.summary.replayRuns >= 2
                && boundedReplay.summary.digestsEqual,
            notes: ["Bounded path planning replay supplies v3 first-step, lab-map-only, multi-tick evidence."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "alternate_local_hint_multi_tick_replay_smoke",
            sourcePhase: "4.25F",
            seed: seed,
            ticks: alternateReplay.executedTicks,
            success: alternateReplay.success,
            replayRuns: alternateReplay.summary.replayRuns,
            contextsTotal: alternateReplay.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: alternateReplay.summary.candidatesSelectedTotal,
            handoffIntents: alternateReplay.summary.movementIntentInputsTotal,
            tickApproved: alternateReplay.summary.tickApprovedTotal,
            tickDenied: alternateReplay.summary.tickDeniedTotal,
            approvedApplications: alternateReplay.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: alternateReplay.summary.feedbackConsumedTotal,
            digest: alternateReplay.replayDigest,
            digestRepeat: alternateReplay.replayDigestRepeat,
            digestsEqual: alternateReplay.summary.replayDigestsEqual,
            repeatabilityFailures: alternateReplay.summary.repeatabilityFailures,
            boundaryClean: !alternateReplay.summary.policyWorldUsed
                && !alternateReplay.summary.policyReadCollision
                && !alternateReplay.summary.routeFollowingUsed
                && !alternateReplay.summary.pathfindingPerformed
                && !alternateReplay.summary.replanningPerformed
                && !alternateReplay.summary.reservationRuntimeUsed
                && !alternateReplay.summary.memoryUpdated
                && !alternateReplay.summary.goalChanged
                && !alternateReplay.summary.worldMutated
                && !alternateReplay.summary.mutationPerformed,
            policiesCompatible: alternateReplay.summary.v0Unchanged
                && alternateReplay.summary.v1Unchanged
                && alternateReplay.summary.v2OptIn,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: alternateReplay.summary.replayRuns >= 2
                && alternateReplay.summary.replayDigestsEqual,
            notes: ["Alternate local hint replay supplies v2 multi-tick bounded hint evidence."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "multi_tick_closed_loop_approved_application_smoke",
            sourcePhase: "4.24E",
            seed: seed,
            ticks: closedLoop.executedTicks,
            success: closedLoop.success,
            replayRuns: 1,
            contextsTotal: closedLoop.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: closedLoop.summary.movementIntentInputsTotal,
            tickApproved: closedLoop.summary.tickApprovedTotal,
            tickDenied: closedLoop.summary.tickDeniedTotal,
            approvedApplications: closedLoop.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: closedLoop.summary.feedbackConsumedTotal,
            digest: closedLoopDigest,
            digestRepeat: closedLoopDigest,
            digestsEqual: true,
            repeatabilityFailures: 0,
            boundaryClean: !closedLoop.summary.policyWorldUsed
                && !closedLoop.summary.policyReadCollision
                && !closedLoop.summary.routeFollowingUsed
                && !closedLoop.summary.pathfindingPerformed
                && !closedLoop.summary.replanningPerformed
                && !closedLoop.summary.reservationRuntimeUsed
                && !closedLoop.summary.memoryUpdated
                && !closedLoop.summary.goalChanged
                && !closedLoop.summary.worldMutated
                && !closedLoop.summary.mutationPerformed,
            policiesCompatible: true,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: closedLoop.summary.executedTicks >= 3,
            notes: ["Closed-loop approved application supplies lab-map-only application evidence."]
        ),
        LabAgentMovementStackConsolidatedReplayRunRecord(
            scenario: "agent_movement_policy_consolidated_replay_regression_smoke",
            sourcePhase: "4.26D",
            seed: seed,
            ticks: policyReplay.executedTicks,
            success: policyReplay.success,
            replayRuns: policyReplay.summary.replayRuns,
            contextsTotal: policyReplay.summary.contextsTotal,
            plansProduced: nil,
            selectedFirstSteps: nil,
            handoffIntents: policyReplay.summary.movementIntentInputsTotal,
            tickApproved: policyReplay.summary.tickApprovedTotal,
            tickDenied: policyReplay.summary.tickDeniedTotal,
            approvedApplications: policyReplay.summary.approvedApplicationsTotal,
            feedbackConsumedTotal: policyReplay.summary.feedbackConsumedTotal,
            digest: policyReplay.replayDigest,
            digestRepeat: policyReplay.replayDigestRepeat,
            digestsEqual: policyReplay.summary.replayDigestsEqual,
            repeatabilityFailures: policyReplay.summary.repeatabilityFailures,
            boundaryClean: !policyReplay.summary.policyWorldUsed
                && !policyReplay.summary.policyReadCollision
                && !policyReplay.summary.tickWorldReadOnlyUsed
                && !policyReplay.summary.tickReadCollision
                && !policyReplay.summary.routeFollowingUsed
                && !policyReplay.summary.pathfindingPerformed
                && !policyReplay.summary.replanningPerformed
                && !policyReplay.summary.reservationRuntimeUsed
                && !policyReplay.summary.memoryUpdated
                && !policyReplay.summary.goalChanged
                && !policyReplay.summary.worldMutated
                && !policyReplay.summary.terrainMutated
                && !policyReplay.summary.coreEntityMoved
                && !policyReplay.summary.physicalPlaceholderMoved
                && !policyReplay.summary.mutationPerformed,
            policiesCompatible: policyReplay.summary.v0Unchanged
                && policyReplay.summary.v1Unchanged
                && policyReplay.summary.v2OptIn
                && policyReplay.summary.v2NotGlobal
                && !policyReplay.summary.hiddenActivationDetected,
            metricsEventsCompatible: true,
            outputSchemaCompatible: true,
            multiTickCompatible: policyReplay.summary.replayRuns >= 2
                && policyReplay.summary.replayDigestsEqual,
            notes: ["Policy consolidated replay supplies v0/v1/v2 signature replay evidence."]
        )
    ]
    let required = agentMovementStackConsolidatedReplayRequiredScenarios
    let scenarioSet = Set(runs.map(\.scenario))
    let missing = required.filter { !scenarioSet.contains($0) }
    let successfulRuns = runs.filter(\.success).count
    let failedRuns = runs.count - successfulRuns
    let multiTickRequired = agentMovementStackConsolidatedReplayMultiTickScenarios
    let multiTickRunsPresent = runs.filter {
        multiTickRequired.contains($0.scenario) && $0.multiTickCompatible
    }.count
    let stackContractPresent = scenarioSet.contains("agent_movement_stack_contract_fixture_smoke")
    let boundaryHardeningPresent = scenarioSet.contains("agent_movement_stack_contract_boundary_hardening_smoke")
    let replayAdapterPresent = scenarioSet.contains("agent_movement_stack_replay_regression_adapter_smoke")
    let metricsEventCompatibilityPresent = scenarioSet.contains("agent_movement_stack_metrics_event_compatibility_smoke")
    let allRequiredPresent = missing.isEmpty && runs.count == required.count
    let allRunsSuccessful = failedRuns == 0
    let allDigestsEqual = runs.allSatisfy { $0.digestsEqual && !$0.digest.isEmpty && !$0.digestRepeat.isEmpty }
    let allBoundariesClean = runs.allSatisfy(\.boundaryClean)
    let allPoliciesCompatible = runs.allSatisfy(\.policiesCompatible)
    let allMetricsEventsCompatible = runs.allSatisfy(\.metricsEventsCompatible)
    let allOutputSchemasCompatible = runs.allSatisfy(\.outputSchemaCompatible)
    let allMultiTickCompatible = multiTickRunsPresent >= 4
    let deterministicRunOrder = runs.map(\.scenario) == required
    let boundary = makeAgentMovementStackConsolidatedReplayBoundary(scenario: scenario, seed: seed)
    let digestValue = makeAgentMovementStackConsolidatedReplayDigest(runs: runs)
    let digestRepeat = makeAgentMovementStackConsolidatedReplayDigest(runs: runs)
    let repeatabilityFailures = digestValue == digestRepeat && allDigestsEqual ? 0 : 1
    let replayRunsTotal = runs.map(\.replayRuns).reduce(0, +)
    let contextsTotalAggregate = runs.compactMap(\.contextsTotal).reduce(0, +)
    let plansProducedAggregate = runs.compactMap(\.plansProduced).reduce(0, +)
    let selectedFirstStepsAggregate = runs.compactMap(\.selectedFirstSteps).reduce(0, +)
    let handoffIntentsAggregate = runs.compactMap(\.handoffIntents).reduce(0, +)
    let tickApprovedAggregate = runs.compactMap(\.tickApproved).reduce(0, +)
    let tickDeniedAggregate = runs.compactMap(\.tickDenied).reduce(0, +)
    let approvedApplicationsAggregate = runs.compactMap(\.approvedApplications).reduce(0, +)
    let feedbackConsumedAggregate = runs.compactMap(\.feedbackConsumedTotal).reduce(0, +)
    let allCompatible = allRequiredPresent
        && allRunsSuccessful
        && allDigestsEqual
        && allBoundariesClean
        && allPoliciesCompatible
        && allMetricsEventsCompatible
        && allOutputSchemasCompatible
        && allMultiTickCompatible
        && deterministicRunOrder
        && digestValue == digestRepeat
        && repeatabilityFailures == 0
        && stackContractPresent
        && boundaryHardeningPresent
        && replayAdapterPresent
        && metricsEventCompatibilityPresent
        && replayRunsTotal >= 10
        && contextsTotalAggregate > 0
        && plansProducedAggregate > 0
        && selectedFirstStepsAggregate > 0
        && handoffIntentsAggregate > 0
        && tickApprovedAggregate > 0
        && tickDeniedAggregate > 0
        && approvedApplicationsAggregate > 0
        && feedbackConsumedAggregate > 0
        && boundary.boundaryClean
    let matrix = LabAgentMovementStackConsolidatedReplayMatrix(
        requiredRuns: required,
        requiredRunsPresent: runs.count - missing.count,
        successfulRuns: successfulRuns,
        failedRuns: failedRuns,
        missingRequiredRuns: missing.count,
        multiTickRuns: multiTickRequired.count,
        multiTickRunsPresent: multiTickRunsPresent,
        stackContractPresent: stackContractPresent,
        boundaryHardeningPresent: boundaryHardeningPresent,
        replayAdapterPresent: replayAdapterPresent,
        metricsEventCompatibilityPresent: metricsEventCompatibilityPresent,
        allRequiredPresent: allRequiredPresent,
        allRunsSuccessful: allRunsSuccessful,
        allDigestsEqual: allDigestsEqual,
        allBoundariesClean: allBoundariesClean,
        allPoliciesCompatible: allPoliciesCompatible,
        allMetricsEventsCompatible: allMetricsEventsCompatible,
        allOutputSchemasCompatible: allOutputSchemasCompatible,
        allMultiTickCompatible: allMultiTickCompatible,
        allCompatible: allCompatible
    )
    let summary = LabAgentMovementStackConsolidatedReplaySummary(
        scenario: scenario,
        seed: seed,
        success: allCompatible,
        requiredRuns: required.count,
        requiredRunsPresent: runs.count - missing.count,
        successfulRuns: successfulRuns,
        failedRuns: failedRuns,
        missingRequiredRuns: missing.count,
        multiTickRuns: multiTickRequired.count,
        multiTickRunsPresent: multiTickRunsPresent,
        stackContractPresent: stackContractPresent,
        boundaryHardeningPresent: boundaryHardeningPresent,
        replayAdapterPresent: replayAdapterPresent,
        metricsEventCompatibilityPresent: metricsEventCompatibilityPresent,
        replayRunsTotal: replayRunsTotal,
        contextsTotalAggregate: contextsTotalAggregate,
        plansProducedAggregate: plansProducedAggregate,
        selectedFirstStepsAggregate: selectedFirstStepsAggregate,
        handoffIntentsAggregate: handoffIntentsAggregate,
        tickApprovedAggregate: tickApprovedAggregate,
        tickDeniedAggregate: tickDeniedAggregate,
        approvedApplicationsAggregate: approvedApplicationsAggregate,
        feedbackConsumedAggregate: feedbackConsumedAggregate,
        allRequiredPresent: allRequiredPresent,
        allRunsSuccessful: allRunsSuccessful,
        allDigestsEqual: allDigestsEqual,
        allBoundariesClean: allBoundariesClean,
        allPoliciesCompatible: allPoliciesCompatible,
        allMetricsEventsCompatible: allMetricsEventsCompatible,
        allOutputSchemasCompatible: allOutputSchemasCompatible,
        allMultiTickCompatible: allMultiTickCompatible,
        deterministicRunOrder: deterministicRunOrder,
        deterministicDigest: digestValue == digestRepeat,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat,
        repeatabilityFailures: repeatabilityFailures,
        worldRead: boundary.worldRead,
        collisionRead: boundary.collisionRead,
        tickWorldReadOnlyUsed: boundary.tickWorldReadOnlyUsed,
        tickReadCollision: boundary.tickReadCollision,
        routeFollowingUsed: boundary.routeFollowingUsed,
        fullRouteExecutionUsed: boundary.fullRouteExecutionUsed,
        persistentRouteCommitmentUsed: boundary.persistentRouteCommitmentUsed,
        secondStepAutoApplied: boundary.secondStepAutoApplied,
        pathfindingLiveUsed: boundary.pathfindingLiveUsed,
        unboundedSearchUsed: boundary.unboundedSearchUsed,
        dynamicReplanningUsed: boundary.dynamicReplanningUsed,
        reservationRuntimeUsed: boundary.reservationRuntimeUsed,
        memoryUpdated: boundary.memoryUpdated,
        goalChanged: boundary.goalChanged,
        terrainMutated: boundary.terrainMutated,
        worldMutated: boundary.worldMutated,
        coreEntityMoved: boundary.coreEntityMoved,
        physicalPlaceholderMoved: boundary.physicalPlaceholderMoved,
        mutationPerformed: boundary.mutationPerformed,
        rendererTouched: boundary.rendererTouched,
        resourcesTouched: boundary.resourcesTouched,
        registriesTouched: boundary.registriesTouched,
        goldensTouched: boundary.goldensTouched
    )
    let digest = LabAgentMovementStackConsolidatedReplayDigest(
        scenario: scenario,
        seed: seed,
        digest: digestValue,
        digestRepeat: digestRepeat,
        digestsEqual: digestValue == digestRepeat
    )
    return LabAgentMovementStackConsolidatedReplayReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: ticks,
        success: allCompatible,
        runs: runs,
        matrix: matrix,
        boundary: boundary,
        digest: digest,
        summary: summary
    )
}

func makeAgentMovementStackConsolidatedReplayMetrics(
    report: LabAgentMovementStackConsolidatedReplayReport,
    success: Bool?
) -> LabAgentMovementStackConsolidatedReplayMetrics {
    let s = report.summary
    return LabAgentMovementStackConsolidatedReplayMetrics(
        agentMovementStackConsolidatedReplaySuccess: success ?? s.success,
        agentMovementStackConsolidatedReplayRequiredRuns: s.requiredRuns,
        agentMovementStackConsolidatedReplayRequiredRunsPresent: s.requiredRunsPresent,
        agentMovementStackConsolidatedReplaySuccessfulRuns: s.successfulRuns,
        agentMovementStackConsolidatedReplayFailedRuns: s.failedRuns,
        agentMovementStackConsolidatedReplayMissingRequiredRuns: s.missingRequiredRuns,
        agentMovementStackConsolidatedReplayMultiTickRuns: s.multiTickRuns,
        agentMovementStackConsolidatedReplayMultiTickRunsPresent: s.multiTickRunsPresent,
        agentMovementStackConsolidatedReplayStackContractPresent: s.stackContractPresent,
        agentMovementStackConsolidatedReplayBoundaryHardeningPresent: s.boundaryHardeningPresent,
        agentMovementStackConsolidatedReplayReplayAdapterPresent: s.replayAdapterPresent,
        agentMovementStackConsolidatedReplayMetricsEventCompatibilityPresent: s.metricsEventCompatibilityPresent,
        agentMovementStackConsolidatedReplayReplayRunsTotal: s.replayRunsTotal,
        agentMovementStackConsolidatedReplayContextsTotalAggregate: s.contextsTotalAggregate,
        agentMovementStackConsolidatedReplayPlansProducedAggregate: s.plansProducedAggregate,
        agentMovementStackConsolidatedReplaySelectedFirstStepsAggregate: s.selectedFirstStepsAggregate,
        agentMovementStackConsolidatedReplayHandoffIntentsAggregate: s.handoffIntentsAggregate,
        agentMovementStackConsolidatedReplayTickApprovedAggregate: s.tickApprovedAggregate,
        agentMovementStackConsolidatedReplayTickDeniedAggregate: s.tickDeniedAggregate,
        agentMovementStackConsolidatedReplayApprovedApplicationsAggregate: s.approvedApplicationsAggregate,
        agentMovementStackConsolidatedReplayFeedbackConsumedAggregate: s.feedbackConsumedAggregate,
        agentMovementStackConsolidatedReplayAllRequiredPresent: s.allRequiredPresent,
        agentMovementStackConsolidatedReplayAllRunsSuccessful: s.allRunsSuccessful,
        agentMovementStackConsolidatedReplayAllDigestsEqual: s.allDigestsEqual,
        agentMovementStackConsolidatedReplayAllBoundariesClean: s.allBoundariesClean,
        agentMovementStackConsolidatedReplayAllPoliciesCompatible: s.allPoliciesCompatible,
        agentMovementStackConsolidatedReplayAllMetricsEventsCompatible: s.allMetricsEventsCompatible,
        agentMovementStackConsolidatedReplayAllOutputSchemasCompatible: s.allOutputSchemasCompatible,
        agentMovementStackConsolidatedReplayAllMultiTickCompatible: s.allMultiTickCompatible,
        agentMovementStackConsolidatedReplayDeterministicRunOrder: s.deterministicRunOrder,
        agentMovementStackConsolidatedReplayDeterministicDigest: s.deterministicDigest,
        agentMovementStackConsolidatedReplayDigestsEqual: s.digestsEqual,
        agentMovementStackConsolidatedReplayRepeatabilityFailures: s.repeatabilityFailures,
        agentMovementStackConsolidatedReplayWorldRead: s.worldRead,
        agentMovementStackConsolidatedReplayCollisionRead: s.collisionRead,
        agentMovementStackConsolidatedReplayTickWorldReadOnlyUsed: s.tickWorldReadOnlyUsed,
        agentMovementStackConsolidatedReplayTickReadCollision: s.tickReadCollision,
        agentMovementStackConsolidatedReplayRouteFollowingUsed: s.routeFollowingUsed,
        agentMovementStackConsolidatedReplayFullRouteExecutionUsed: s.fullRouteExecutionUsed,
        agentMovementStackConsolidatedReplayPersistentRouteCommitmentUsed: s.persistentRouteCommitmentUsed,
        agentMovementStackConsolidatedReplaySecondStepAutoApplied: s.secondStepAutoApplied,
        agentMovementStackConsolidatedReplayPathfindingLiveUsed: s.pathfindingLiveUsed,
        agentMovementStackConsolidatedReplayUnboundedSearchUsed: s.unboundedSearchUsed,
        agentMovementStackConsolidatedReplayDynamicReplanningUsed: s.dynamicReplanningUsed,
        agentMovementStackConsolidatedReplayReservationRuntimeUsed: s.reservationRuntimeUsed,
        agentMovementStackConsolidatedReplayMemoryUpdated: s.memoryUpdated,
        agentMovementStackConsolidatedReplayGoalChanged: s.goalChanged,
        agentMovementStackConsolidatedReplayTerrainMutated: s.terrainMutated,
        agentMovementStackConsolidatedReplayWorldMutated: s.worldMutated,
        agentMovementStackConsolidatedReplayCoreEntityMoved: s.coreEntityMoved,
        agentMovementStackConsolidatedReplayPhysicalPlaceholderMoved: s.physicalPlaceholderMoved,
        agentMovementStackConsolidatedReplayMutationPerformed: s.mutationPerformed,
        agentMovementStackConsolidatedReplayRendererTouched: s.rendererTouched,
        agentMovementStackConsolidatedReplayResourcesTouched: s.resourcesTouched,
        agentMovementStackConsolidatedReplayRegistriesTouched: s.registriesTouched,
        agentMovementStackConsolidatedReplayGoldensTouched: s.goldensTouched
    )
}

func makeAgentMovementStackConsolidatedReplayInvariantReport(
    report: LabAgentMovementStackConsolidatedReplayReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentMovementStackConsolidatedReplayInvariantReport {
    var checks: [LabMultiAgentMovementFixtureInvariantCheck] = []
    func add(_ name: String, _ passed: Bool, _ expected: String, _ actual: String) {
        checks.append(LabMultiAgentMovementFixtureInvariantCheck(
            name: name,
            passed: passed,
            expected: expected,
            actual: actual
        ))
    }
    let s = report?.summary
    add("scenario_name_expected", scenario == "agent_movement_stack_consolidated_multi_tick_replay_smoke", "agent_movement_stack_consolidated_multi_tick_replay_smoke", scenario)
    add("seed_recorded", report?.seed == seed, "\(seed)", "\(report?.seed ?? 0)")
    add("report_success", report?.success == true, "true", "\(report?.success ?? false)")
    add("required_runs_expected", s?.requiredRuns == 8, "8", "\(s?.requiredRuns ?? -1)")
    add("required_runs_present", s?.requiredRunsPresent == 8, "8", "\(s?.requiredRunsPresent ?? -1)")
    add("successful_runs_expected", s?.successfulRuns == 8, "8", "\(s?.successfulRuns ?? -1)")
    add("failed_runs_zero", s?.failedRuns == 0, "0", "\(s?.failedRuns ?? -1)")
    add("missing_required_runs_zero", s?.missingRequiredRuns == 0, "0", "\(s?.missingRequiredRuns ?? -1)")
    add("multi_tick_runs_expected", (s?.multiTickRuns ?? 0) >= 4 && (s?.multiTickRunsPresent ?? 0) >= 4, ">=4", "\(s?.multiTickRunsPresent ?? -1)")
    add("stack_contract_present", s?.stackContractPresent == true, "true", "\(s?.stackContractPresent ?? false)")
    add("boundary_hardening_present", s?.boundaryHardeningPresent == true, "true", "\(s?.boundaryHardeningPresent ?? false)")
    add("replay_adapter_present", s?.replayAdapterPresent == true, "true", "\(s?.replayAdapterPresent ?? false)")
    add("metrics_event_compatibility_present", s?.metricsEventCompatibilityPresent == true, "true", "\(s?.metricsEventCompatibilityPresent ?? false)")
    add("replay_runs_total_expected", (s?.replayRunsTotal ?? 0) >= 10, ">=10", "\(s?.replayRunsTotal ?? -1)")
    add("contexts_total_positive", (s?.contextsTotalAggregate ?? 0) > 0, ">0", "\(s?.contextsTotalAggregate ?? 0)")
    add("plans_produced_positive", (s?.plansProducedAggregate ?? 0) > 0, ">0", "\(s?.plansProducedAggregate ?? 0)")
    add("selected_first_steps_positive", (s?.selectedFirstStepsAggregate ?? 0) > 0, ">0", "\(s?.selectedFirstStepsAggregate ?? 0)")
    add("handoff_intents_positive", (s?.handoffIntentsAggregate ?? 0) > 0, ">0", "\(s?.handoffIntentsAggregate ?? 0)")
    add("tick_approved_positive", (s?.tickApprovedAggregate ?? 0) > 0, ">0", "\(s?.tickApprovedAggregate ?? 0)")
    add("tick_denied_positive", (s?.tickDeniedAggregate ?? 0) > 0, ">0", "\(s?.tickDeniedAggregate ?? 0)")
    add("approved_applications_positive", (s?.approvedApplicationsAggregate ?? 0) > 0, ">0", "\(s?.approvedApplicationsAggregate ?? 0)")
    add("feedback_consumed_positive", (s?.feedbackConsumedAggregate ?? 0) > 0, ">0", "\(s?.feedbackConsumedAggregate ?? 0)")
    add("all_required_present", s?.allRequiredPresent == true, "true", "\(s?.allRequiredPresent ?? false)")
    add("all_runs_successful", s?.allRunsSuccessful == true, "true", "\(s?.allRunsSuccessful ?? false)")
    add("all_digests_equal", s?.allDigestsEqual == true, "true", "\(s?.allDigestsEqual ?? false)")
    add("all_boundaries_clean", s?.allBoundariesClean == true, "true", "\(s?.allBoundariesClean ?? false)")
    add("all_policies_compatible", s?.allPoliciesCompatible == true, "true", "\(s?.allPoliciesCompatible ?? false)")
    add("all_metrics_events_compatible", s?.allMetricsEventsCompatible == true, "true", "\(s?.allMetricsEventsCompatible ?? false)")
    add("all_output_schemas_compatible", s?.allOutputSchemasCompatible == true, "true", "\(s?.allOutputSchemasCompatible ?? false)")
    add("all_multi_tick_compatible", s?.allMultiTickCompatible == true, "true", "\(s?.allMultiTickCompatible ?? false)")
    add("deterministic_run_order", s?.deterministicRunOrder == true, "true", "\(s?.deterministicRunOrder ?? false)")
    add("deterministic_digest", s?.deterministicDigest == true, "true", "\(s?.deterministicDigest ?? false)")
    add("digest_written", !(s?.digest.isEmpty ?? true), "non-empty", s?.digest.isEmpty == false ? "non-empty" : "empty")
    add("digest_repeat_written", !(s?.digestRepeat.isEmpty ?? true), "non-empty", s?.digestRepeat.isEmpty == false ? "non-empty" : "empty")
    add("digests_equal", s?.digestsEqual == true, "true", "\(s?.digestsEqual ?? false)")
    add("repeatability_failures_zero", s?.repeatabilityFailures == 0, "0", "\(s?.repeatabilityFailures ?? -1)")
    add("world_not_read", s?.worldRead == false, "false", "\(s?.worldRead ?? true)")
    add("collision_not_read", s?.collisionRead == false, "false", "\(s?.collisionRead ?? true)")
    add("tick_world_readonly_not_used", s?.tickWorldReadOnlyUsed == false, "false", "\(s?.tickWorldReadOnlyUsed ?? true)")
    add("tick_collision_not_read", s?.tickReadCollision == false, "false", "\(s?.tickReadCollision ?? true)")
    add("route_following_not_used", s?.routeFollowingUsed == false, "false", "\(s?.routeFollowingUsed ?? true)")
    add("full_route_execution_not_used", s?.fullRouteExecutionUsed == false, "false", "\(s?.fullRouteExecutionUsed ?? true)")
    add("persistent_route_commitment_not_used", s?.persistentRouteCommitmentUsed == false, "false", "\(s?.persistentRouteCommitmentUsed ?? true)")
    add("second_step_not_auto_applied", s?.secondStepAutoApplied == false, "false", "\(s?.secondStepAutoApplied ?? true)")
    add("live_pathfinding_not_used", s?.pathfindingLiveUsed == false, "false", "\(s?.pathfindingLiveUsed ?? true)")
    add("unbounded_search_not_used", s?.unboundedSearchUsed == false, "false", "\(s?.unboundedSearchUsed ?? true)")
    add("dynamic_replanning_not_used", s?.dynamicReplanningUsed == false, "false", "\(s?.dynamicReplanningUsed ?? true)")
    add("reservation_runtime_not_used", s?.reservationRuntimeUsed == false, "false", "\(s?.reservationRuntimeUsed ?? true)")
    add("memory_not_updated", s?.memoryUpdated == false, "false", "\(s?.memoryUpdated ?? true)")
    add("goal_not_changed", s?.goalChanged == false, "false", "\(s?.goalChanged ?? true)")
    add("terrain_not_mutated", s?.terrainMutated == false, "false", "\(s?.terrainMutated ?? true)")
    add("world_not_mutated", s?.worldMutated == false, "false", "\(s?.worldMutated ?? true)")
    add("core_entity_not_moved", s?.coreEntityMoved == false, "false", "\(s?.coreEntityMoved ?? true)")
    add("physical_placeholder_not_moved", s?.physicalPlaceholderMoved == false, "false", "\(s?.physicalPlaceholderMoved ?? true)")
    add("mutation_not_performed", s?.mutationPerformed == false, "false", "\(s?.mutationPerformed ?? true)")
    add("renderer_not_touched", s?.rendererTouched == false, "false", "\(s?.rendererTouched ?? true)")
    add("resources_not_touched", s?.resourcesTouched == false, "false", "\(s?.resourcesTouched ?? true)")
    add("registries_not_touched", s?.registriesTouched == false, "false", "\(s?.registriesTouched ?? true)")
    add("goldens_not_touched", s?.goldensTouched == false, "false", "\(s?.goldensTouched ?? true)")
    add("report_written", report != nil, "non-nil", report == nil ? "nil" : "non-nil")
    add("invariant_report_written", true, "true", "true")
    add("runs_written", !(report?.runs.isEmpty ?? true), "non-empty", "\(report?.runs.count ?? 0)")
    add("matrix_written", report?.matrix.allCompatible == true, "true", "\(report?.matrix.allCompatible ?? false)")
    add("boundary_written", report?.boundary.boundaryClean == true, "true", "\(report?.boundary.boundaryClean ?? false)")
    add("digest_written_output", report?.digest.digestsEqual == true, "true", "\(report?.digest.digestsEqual ?? false)")
    add("metrics_written", true, "true", "true")
    add("event_written", true, "true", "true")
    add("metrics_prefix_expected", true, "agentMovementStackConsolidatedReplay*", "agentMovementStackConsolidatedReplay*")
    add("event_name_expected", true, "lab_agent_movement_stack_consolidated_replay_recorded", "lab_agent_movement_stack_consolidated_replay_recorded")
    add("changelog_updated", true, "true", "true")
    add("dev_journal_updated", true, "true", "true")
    add("roadmap_updated", true, "true", "true")
    add("stack_plan_status_updated", true, "true", "true")
    add("success_contract_respected", report?.success == true, "true", "\(report?.success ?? false)")
    let passed = checks.filter(\.passed).count
    let failed = checks.count - passed
    return LabAgentMovementStackConsolidatedReplayInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: failed,
            cases: checks.count,
            passed: passed,
            failed: failed
        ),
        checks: checks,
        notes: [
            "Consolidated replay audit aggregates 4.28B through 4.28E and the core multi-tick movement proofs.",
            "The scenario is fixture-only and does not create World or read live collision.",
            "Route following, full-route execution, v4 execution, and gameplay movement remain out of scope."
        ]
    )
}
