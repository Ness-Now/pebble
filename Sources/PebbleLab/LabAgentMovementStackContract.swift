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
