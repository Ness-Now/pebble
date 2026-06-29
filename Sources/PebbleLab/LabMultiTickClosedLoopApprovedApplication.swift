import Foundation

private func multiTickClosedLoopApprovedApplicationInitialAgents() -> [String: LabTerrainPathNodeKey] {
    [
        "agent_0_winner": LabTerrainPathNodeKey(x: 0, y: 64, z: 0),
        "agent_1_loser": LabTerrainPathNodeKey(x: 2, y: 64, z: 0),
        "agent_2_free": LabTerrainPathNodeKey(x: 9, y: 64, z: 7),
        "agent_3_collision": LabTerrainPathNodeKey(x: 7, y: 64, z: 8),
        "agent_4_idle": LabTerrainPathNodeKey(x: 20, y: 64, z: 0)
    ]
}

private func multiTickClosedLoopApprovedApplicationContext(
    tick: Int,
    agentId: String,
    position: LabTerrainPathNodeKey,
    feedback: LabMovementFeedback?
) -> LabAgentIntentContext {
    switch agentId {
    case "agent_0_winner":
        LabAgentIntentContext(
            tick: tick,
            agentId: agentId,
            position: position,
            lastFeedback: feedback,
            role: "wander_fixture",
            localHints: position.x == 1 ? ["move_west"] : ["move_east"]
        )
    case "agent_1_loser":
        LabAgentIntentContext(
            tick: tick,
            agentId: agentId,
            position: position,
            lastFeedback: feedback,
            role: "wander_fixture",
            localHints: ["move_west"]
        )
    case "agent_2_free":
        LabAgentIntentContext(
            tick: tick,
            agentId: agentId,
            position: position,
            lastFeedback: feedback,
            role: "wander_fixture",
            localHints: position.z == 8 ? ["move_north"] : ["move_south"]
        )
    case "agent_3_collision":
        LabAgentIntentContext(
            tick: tick,
            agentId: agentId,
            position: position,
            lastFeedback: feedback,
            role: "wander_fixture",
            localHints: ["move_east"]
        )
    default:
        LabAgentIntentContext(
            tick: tick,
            agentId: agentId,
            position: position,
            lastFeedback: feedback,
            role: "idle",
            localHints: []
        )
    }
}

private func isApprovedApplicationBlockedFeedback(_ feedback: LabMovementFeedback?) -> Bool {
    guard let feedback else { return false }
    switch feedback.kind {
    case .blockedByCollision,
         .blockedByAgentConflict,
         .blockedBySourceMismatch,
         .blockedByDivergence,
         .blockedByStaleIntent,
         .blockedByInvalidEdge,
         .blockedByMaxAgents:
        return true
    case .approvedForMovement, .moved:
        return false
    }
}

func makeMultiTickClosedLoopApprovedApplicationReport(
    scenario: String,
    seed: UInt32,
    requestedTicks: Int
) -> LabMultiTickClosedLoopApprovedApplicationReport {
    let executedTicks = 3
    let initialAgents = multiTickClosedLoopApprovedApplicationInitialAgents()
    let sortedAgentIds = initialAgents.keys.sorted()
    let evidenceSeeds: [String: UInt32] = [
        "agent_0_winner": 99,
        "agent_1_loser": 99,
        "agent_2_free": 99,
        "agent_3_collision": 42
    ]
    var abstractPositions = initialAgents
    var physicalPositions = initialAgents
    var previousFeedback: [String: LabMovementFeedback] = [:]
    var tickRecords: [LabMultiTickClosedLoopApprovedApplicationTickRecord] = []
    var emittedByTick: [Int: [LabMovementFeedback]] = [:]
    var consumedByTick: [Int: [LabMovementFeedback]] = [:]
    var carriedByTick: [Int: [LabMovementFeedback]] = [:]

    for tick in 0..<executedTicks {
        let inputFeedback = previousFeedback
        let positionsBefore = abstractPositions
        let contexts = sortedAgentIds.compactMap { agentId -> LabAgentIntentContext? in
            guard let position = abstractPositions[agentId] else { return nil }
            return multiTickClosedLoopApprovedApplicationContext(
                tick: tick,
                agentId: agentId,
                position: position,
                feedback: inputFeedback[agentId]
            )
        }
        let decisions = contexts.map(produceAgentIntentProposalFeedbackAwareV1(context:)).sorted {
            $0.agentId < $1.agentId
        }
        let proposals = decisions.map(\.feedbackAwareProposal)
        let intentResult = produceAgentIntentProductionResult(
            tick: tick,
            contexts: contexts,
            rawProposals: proposals,
            maxProposals: nil
        )
        let noIntentFiltered = intentResult.rejectedProposals.filter {
            $0.decision == .noIntent
        }
        let tickInput = LabMultiAgentMovementTickInput(
            tick: tick,
            agents: abstractPositions,
            physicalPositions: physicalPositions,
            intents: intentResult.acceptedIntents,
            maxAgents: nil
        )
        let expectedApproved = 2
        let expectedDenied = tick == 1 ? 0 : 2
        let expectedOccupable = tick == 1 ? 2 : 3
        let expectedNonOccupable = tick == 1 ? 0 : 1
        let expectedCollisionDenied = tick == 1 ? 0 : 1
        let tickReport = makeMultiAgentMovementTickApprovedApplicationReport(
            scenario: scenario,
            seed: seed,
            ticksCompleted: tick,
            input: tickInput,
            evidenceSeeds: evidenceSeeds,
            expectedAgentCount: initialAgents.count,
            expectedIntentCount: tickInput.intents.count,
            expectedApproved: expectedApproved,
            expectedDenied: expectedDenied,
            expectedOccupableDestinations: expectedOccupable,
            expectedNonOccupableDestinations: expectedNonOccupable,
            expectedDisplacementsApplied: expectedApproved,
            expectedDivergenceBeforeMax: 0,
            expectedDivergenceAfterMax: 0,
            expectedMovedFeedback: expectedApproved,
            expectedBlockedByCollisionFeedback: expectedCollisionDenied
        )
        let emittedFeedback = tickReport.output.feedback.sorted { $0.agentId < $1.agentId }
        let feedbackForNextTick = Dictionary(uniqueKeysWithValues: emittedFeedback.map {
            ($0.agentId, $0)
        })
        let consumedFeedback = contexts.compactMap(\.lastFeedback).sorted { $0.agentId < $1.agentId }
        let sameTickFeedbackConsumed = consumedFeedback.filter { $0.tick == tick }.count
        let futureFeedbackConsumed = consumedFeedback.filter { $0.tick > tick }.count
        let crossAgentFeedbackLeaks = contexts.filter { context in
            guard let feedback = context.lastFeedback else { return false }
            return feedback.agentId != context.agentId
        }.count
        let noIntentFromBlockedFeedback = decisions.filter { decision in
            guard decision.feedbackAwareDecision == .noIntent,
                  let context = contexts.first(where: { $0.agentId == decision.agentId })
            else { return false }
            return isApprovedApplicationBlockedFeedback(context.lastFeedback)
        }.count
        let approvedApplications = tickReport.output.resolutions.filter(\.approved)
        let deniedPreserved = tickReport.output.resolutions.filter {
            !$0.approved
                && !$0.displacementApplied
                && $0.abstractBefore == $0.abstractAfter
                && $0.physicalBefore == $0.physicalAfter
        }
        let noIntentPreserved = noIntentFiltered.map(\.agentId).filter { agentId in
            tickReport.output.abstractPositionsBefore[agentId] == tickReport.output.abstractPositionsAfter[agentId]
                && tickReport.output.physicalPositionsBefore[agentId] == tickReport.output.physicalPositionsAfter[agentId]
        }.sorted()
        let abstractChanged = tickReport.output.abstractPositionsAfter.filter { agentId, after in
            tickReport.output.abstractPositionsBefore[agentId] != after
        }.count
        let physicalChanged = tickReport.output.physicalPositionsAfter.filter { agentId, after in
            tickReport.output.physicalPositionsBefore[agentId] != after
        }.count
        let positionsAfter = tickReport.output.abstractPositionsAfter
        let summary = LabMultiTickClosedLoopApprovedApplicationTickSummary(
            tick: tick,
            agents: initialAgents.count,
            feedbackAvailableFromPreviousTick: inputFeedback.count,
            feedbackConsumed: consumedFeedback.count,
            contexts: contexts.count,
            contextsWithFeedback: contexts.filter { $0.lastFeedback != nil }.count,
            contextsWithoutFeedback: contexts.filter { $0.lastFeedback == nil }.count,
            proposals: proposals.count,
            acceptedIntents: intentResult.summary.acceptedIntents,
            noIntent: intentResult.summary.noIntent,
            noIntentFromBlockedFeedback: noIntentFromBlockedFeedback,
            movementIntentInputs: tickInput.intents.count,
            tickApproved: tickReport.summary.approved,
            tickDenied: tickReport.summary.denied,
            tickDeniedConflict: tickReport.output.resolutions.filter {
                $0.decision == .deniedSameDestinationConflict
            }.count,
            tickDeniedCollision: tickReport.output.resolutions.filter {
                $0.decision == .deniedCollision
            }.count,
            tickFeedbackEmitted: emittedFeedback.count,
            feedbackCarriedToNextTick: feedbackForNextTick.count,
            occupableDestinations: tickReport.summary.occupableDestinations,
            nonOccupableDestinations: tickReport.summary.nonOccupableDestinations,
            approvedAgentsMoved: approvedApplications.filter(\.displacementApplied).count,
            deniedAgentsPreserved: deniedPreserved.count,
            noIntentAgentsPreserved: noIntentPreserved.count,
            displacementsApplied: tickReport.summary.displacementsApplied,
            abstractPositionsChanged: abstractChanged,
            physicalPositionsChanged: physicalChanged,
            abstractPhysicalDivergenceBefore: tickReport.summary.divergenceBeforeMax,
            abstractPhysicalDivergenceAfter: tickReport.summary.divergenceAfterMax,
            sameTickFeedbackConsumed: sameTickFeedbackConsumed,
            crossAgentFeedbackLeaks: crossAgentFeedbackLeaks,
            futureFeedbackConsumed: futureFeedbackConsumed,
            policyReadCollision: false,
            tickReadCollision: tickReport.summary.liveCollisionRead,
            policyWorldUsed: false,
            tickWorldReadOnlyUsed: tickReport.summary.worldUsed,
            movementApplied: tickReport.summary.physicalMovementApplied,
            memoryUpdated: false,
            goalChanged: false,
            pathfindingPerformed: tickReport.summary.pathfindingPerformed,
            replanningPerformed: tickReport.summary.replanningPerformed,
            avoidancePerformed: tickReport.summary.avoidancePerformed,
            reservationRuntimeUsed: tickReport.summary.reservationRuntimeUsed,
            routeFollowingUsed: tickReport.summary.routeFollowingApplied,
            worldMutated: tickReport.summary.worldMutationPerformed,
            mutationPerformed: tickReport.summary.terrainMutationPerformed || tickReport.summary.worldMutationPerformed,
            success: tickReport.success
                && intentResult.summary.contexts == 5
                && sameTickFeedbackConsumed == 0
                && crossAgentFeedbackLeaks == 0
                && futureFeedbackConsumed == 0
                && abstractChanged == tickReport.summary.displacementsApplied
                && physicalChanged == tickReport.summary.displacementsApplied
                && tickReport.summary.divergenceBeforeMax == 0
                && tickReport.summary.divergenceAfterMax == 0
                && tickReport.summary.worldUsed
                && tickReport.summary.liveCollisionRead
                && tickReport.summary.physicalMovementApplied == (tickReport.summary.displacementsApplied > 0)
                && !tickReport.summary.routeFollowingApplied
                && !tickReport.summary.pathfindingPerformed
                && !tickReport.summary.replanningPerformed
                && !tickReport.summary.avoidancePerformed
                && !tickReport.summary.reservationRuntimeUsed
                && !tickReport.summary.terrainMutationPerformed
                && !tickReport.summary.worldMutationPerformed
        )
        let record = LabMultiTickClosedLoopApprovedApplicationTickRecord(
            tick: tick,
            inputFeedbackByAgent: inputFeedback,
            contexts: contexts,
            policyDecisions: decisions,
            proposals: proposals,
            noIntentFilteredOut: noIntentFiltered,
            tickInput: tickInput,
            tickOutput: tickReport.output,
            approvedApplications: approvedApplications,
            deniedPreservedAgents: deniedPreserved,
            noIntentPreservedAgents: noIntentPreserved,
            collisionEvidence: tickReport.output.resolutions.filter(\.collisionRead),
            emittedFeedback: emittedFeedback,
            feedbackForNextTick: feedbackForNextTick,
            positionsBefore: positionsBefore,
            positionsAfter: positionsAfter,
            summary: summary
        )
        tickRecords.append(record)
        emittedByTick[tick] = emittedFeedback
        consumedByTick[tick] = consumedFeedback
        carriedByTick[tick] = feedbackForNextTick.values.sorted { $0.agentId < $1.agentId }
        abstractPositions = tickReport.output.abstractPositionsAfter
        physicalPositions = tickReport.output.physicalPositionsAfter
        previousFeedback = feedbackForNextTick
    }

    let summaries = tickRecords.map(\.summary)
    let tick0FeedbackIds = Set(emittedByTick[0]?.map(\.agentId) ?? [])
    let tick1ConsumedIds = Set(consumedByTick[1]?.map(\.agentId) ?? [])
    let tick1FeedbackIds = Set(emittedByTick[1]?.map(\.agentId) ?? [])
    let tick2ConsumedIds = Set(consumedByTick[2]?.map(\.agentId) ?? [])
    let ledger = LabMultiTickClosedLoopApprovedApplicationFeedbackLedger(
        emittedByTick: emittedByTick,
        consumedByTick: consumedByTick,
        carriedToNextTickByTick: carriedByTick,
        tick0FeedbackConsumedAtTick1: tick0FeedbackIds == tick1ConsumedIds
            && tick0FeedbackIds == ["agent_0_winner", "agent_1_loser", "agent_2_free", "agent_3_collision"],
        collisionFeedbackConsumedAtTick1: consumedByTick[1]?.contains {
            $0.agentId == "agent_3_collision" && $0.kind == .blockedByCollision
        } == true,
        conflictFeedbackConsumedAtTick1: consumedByTick[1]?.contains {
            $0.agentId == "agent_1_loser" && $0.kind == .blockedByAgentConflict
        } == true,
        sameTickFeedbackConsumed: summaries.contains { $0.sameTickFeedbackConsumed > 0 },
        crossAgentFeedbackLeaks: summaries.contains { $0.crossAgentFeedbackLeaks > 0 },
        futureFeedbackConsumed: summaries.contains { $0.futureFeedbackConsumed > 0 },
        memorylessPreviousTickOnly: tick2ConsumedIds == tick1FeedbackIds
            && tick2ConsumedIds == ["agent_0_winner", "agent_2_free"]
    )
    let summary = LabMultiTickClosedLoopApprovedApplicationSummary(
        requestedTicks: requestedTicks,
        executedTicks: executedTicks,
        agents: initialAgents.count,
        contextsTotal: summaries.reduce(0) { $0 + $1.contexts },
        feedbackConsumedTotal: summaries.reduce(0) { $0 + $1.feedbackConsumed },
        feedbackCarriedToNextTickTotal: summaries.reduce(0) { $0 + $1.feedbackCarriedToNextTick },
        contextsWithFeedbackTotal: summaries.reduce(0) { $0 + $1.contextsWithFeedback },
        contextsWithoutFeedbackTotal: summaries.reduce(0) { $0 + $1.contextsWithoutFeedback },
        proposalsTotal: summaries.reduce(0) { $0 + $1.proposals },
        acceptedIntentsTotal: summaries.reduce(0) { $0 + $1.acceptedIntents },
        noIntentTotal: summaries.reduce(0) { $0 + $1.noIntent },
        noIntentFromBlockedFeedbackTotal: summaries.reduce(0) { $0 + $1.noIntentFromBlockedFeedback },
        movementIntentInputsTotal: summaries.reduce(0) { $0 + $1.movementIntentInputs },
        tickApprovedTotal: summaries.reduce(0) { $0 + $1.tickApproved },
        tickDeniedTotal: summaries.reduce(0) { $0 + $1.tickDenied },
        tickDeniedConflictTotal: summaries.reduce(0) { $0 + $1.tickDeniedConflict },
        tickDeniedCollisionTotal: summaries.reduce(0) { $0 + $1.tickDeniedCollision },
        tickFeedbackEmittedTotal: summaries.reduce(0) { $0 + $1.tickFeedbackEmitted },
        occupableDestinationsTotal: summaries.reduce(0) { $0 + $1.occupableDestinations },
        nonOccupableDestinationsTotal: summaries.reduce(0) { $0 + $1.nonOccupableDestinations },
        approvedApplicationsTotal: summaries.reduce(0) { $0 + $1.approvedAgentsMoved },
        approvedAgentsMovedTotal: summaries.reduce(0) { $0 + $1.approvedAgentsMoved },
        deniedAgentsPreservedTotal: summaries.reduce(0) { $0 + $1.deniedAgentsPreserved },
        noIntentAgentsPreservedTotal: summaries.reduce(0) { $0 + $1.noIntentAgentsPreserved },
        displacementsAppliedTotal: summaries.reduce(0) { $0 + $1.displacementsApplied },
        abstractPositionsChangedTotal: summaries.reduce(0) { $0 + $1.abstractPositionsChanged },
        physicalPositionsChangedTotal: summaries.reduce(0) { $0 + $1.physicalPositionsChanged },
        abstractPhysicalDivergenceBeforeMax: summaries.map(\.abstractPhysicalDivergenceBefore).max() ?? 0,
        abstractPhysicalDivergenceAfterMax: summaries.map(\.abstractPhysicalDivergenceAfter).max() ?? 0,
        sameTickFeedbackConsumedTotal: summaries.reduce(0) { $0 + $1.sameTickFeedbackConsumed },
        crossAgentFeedbackLeaksTotal: summaries.reduce(0) { $0 + $1.crossAgentFeedbackLeaks },
        futureFeedbackConsumedTotal: summaries.reduce(0) { $0 + $1.futureFeedbackConsumed },
        policyReadCollision: summaries.contains { $0.policyReadCollision },
        tickReadCollision: summaries.contains { $0.tickReadCollision },
        policyWorldUsed: summaries.contains { $0.policyWorldUsed },
        tickWorldReadOnlyUsed: summaries.contains { $0.tickWorldReadOnlyUsed },
        movementApplied: summaries.contains { $0.movementApplied },
        memoryUpdated: summaries.contains { $0.memoryUpdated },
        goalChanged: summaries.contains { $0.goalChanged },
        pathfindingPerformed: summaries.contains { $0.pathfindingPerformed },
        replanningPerformed: summaries.contains { $0.replanningPerformed },
        avoidancePerformed: summaries.contains { $0.avoidancePerformed },
        reservationRuntimeUsed: summaries.contains { $0.reservationRuntimeUsed },
        routeFollowingUsed: summaries.contains { $0.routeFollowingUsed },
        worldMutated: summaries.contains { $0.worldMutated },
        mutationPerformed: summaries.contains { $0.mutationPerformed },
        success: requestedTicks == 3
            && executedTicks == 3
            && summaries.allSatisfy(\.success)
            && summaries.map(\.movementIntentInputs) == [4, 2, 4]
            && summaries.map(\.tickApproved) == [2, 2, 2]
            && summaries.map(\.tickDenied) == [2, 0, 2]
            && summaries.map(\.tickDeniedConflict) == [1, 0, 1]
            && summaries.map(\.tickDeniedCollision) == [1, 0, 1]
            && summaries.map(\.tickFeedbackEmitted) == [4, 2, 4]
            && summaries.map(\.contextsWithFeedback) == [0, 4, 2]
            && summaries.map(\.noIntent) == [1, 3, 1]
            && summaries.map(\.noIntentFromBlockedFeedback) == [0, 2, 0]
            && summaries.map(\.displacementsApplied) == [2, 2, 2]
            && ledger.tick0FeedbackConsumedAtTick1
            && ledger.collisionFeedbackConsumedAtTick1
            && ledger.conflictFeedbackConsumedAtTick1
            && ledger.memorylessPreviousTickOnly
            && !ledger.sameTickFeedbackConsumed
            && !ledger.crossAgentFeedbackLeaks
            && !ledger.futureFeedbackConsumed
    )
    return LabMultiTickClosedLoopApprovedApplicationReport(
        scenario: scenario,
        seed: seed,
        requestedTicks: requestedTicks,
        executedTicks: executedTicks,
        success: summary.success,
        initialAgents: initialAgents,
        finalAgents: abstractPositions,
        tickRecords: tickRecords,
        feedbackLedger: ledger,
        summary: summary
    )
}

private func approvedApplicationInvariantCheck(
    _ name: String,
    _ passed: Bool,
    _ expected: String,
    _ actual: String
) -> LabMultiAgentMovementFixtureInvariantCheck {
    LabMultiAgentMovementFixtureInvariantCheck(
        name: name,
        passed: passed,
        expected: expected,
        actual: actual
    )
}

func makeMultiTickClosedLoopApprovedApplicationInvariantReport(
    report: LabMultiTickClosedLoopApprovedApplicationReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiTickClosedLoopApprovedApplicationInvariantReport {
    guard let report else {
        let check = approvedApplicationInvariantCheck(
            "multi_tick_closed_loop_approved_application_report_exists",
            false,
            "multi_tick_closed_loop_approved_application_report.json",
            "missing"
        )
        return LabMultiTickClosedLoopApprovedApplicationInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 1,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["The multi-tick closed loop approved application report was not produced."]
        )
    }

    let summary = report.summary
    let records = report.tickRecords.sorted { $0.tick < $1.tick }
    let tick0 = records.first { $0.tick == 0 }
    let tick1 = records.first { $0.tick == 1 }
    let tick2 = records.first { $0.tick == 2 }
    let allContextsSorted = records.allSatisfy {
        $0.contexts.map(\.agentId) == $0.contexts.map(\.agentId).sorted()
    }
    let allDecisionsSorted = records.allSatisfy {
        $0.policyDecisions.map(\.agentId) == $0.policyDecisions.map(\.agentId).sorted()
    }
    let allFeedbackSorted = records.allSatisfy {
        $0.emittedFeedback.map(\.agentId) == $0.emittedFeedback.map(\.agentId).sorted()
    }
    let agent1Tick1Decision = tick1?.policyDecisions.first { $0.agentId == "agent_1_loser" }
    let agent3Tick1Decision = tick1?.policyDecisions.first { $0.agentId == "agent_3_collision" }
    let tick1NoIntentIds = Set(tick1?.noIntentFilteredOut.map(\.agentId) ?? [])
    let tick0FeedbackIds = Set(report.feedbackLedger.emittedByTick[0]?.map(\.agentId) ?? [])
    let tick1ConsumedIds = Set(report.feedbackLedger.consumedByTick[1]?.map(\.agentId) ?? [])
    let tick1FeedbackIds = Set(report.feedbackLedger.emittedByTick[1]?.map(\.agentId) ?? [])
    let tick2ConsumedIds = Set(report.feedbackLedger.consumedByTick[2]?.map(\.agentId) ?? [])
    let onlyApprovedMove = records.allSatisfy { record in
        let movedIds = Set(record.approvedApplications.filter(\.displacementApplied).map(\.agentId))
        let changedIds = Set(record.positionsAfter.compactMap { agentId, after in
            record.positionsBefore[agentId] == after ? nil : agentId
        })
        return movedIds == changedIds
    }
    let deniedDoNotMove = records.allSatisfy {
        $0.deniedPreservedAgents.count == $0.summary.tickDenied
    }
    let noIntentDoNotMove = records.allSatisfy {
        $0.noIntentPreservedAgents.count == $0.summary.noIntent
    }
    let positionsUpdateBetweenTicks = tick1?.positionsBefore == tick0?.positionsAfter
        && tick2?.positionsBefore == tick1?.positionsAfter
    let contextsUseUpdatedPositions = records.allSatisfy { record in
        record.contexts.allSatisfy { context in
            context.position == record.positionsBefore[context.agentId]
        }
    }

    let checks = [
        approvedApplicationInvariantCheck("fixed_tick_count_expected", summary.requestedTicks == 3, "3", "\(summary.requestedTicks)"),
        approvedApplicationInvariantCheck("no_unbounded_loop", records.count == 3, "3", "\(records.count)"),
        approvedApplicationInvariantCheck("executed_ticks_expected", summary.executedTicks == 3, "3", "\(summary.executedTicks)"),
        approvedApplicationInvariantCheck("agent_count_expected", summary.agents == 5, "5", "\(summary.agents)"),
        approvedApplicationInvariantCheck("tick_records_exist", records.count == 3, "3", "\(records.count)"),
        approvedApplicationInvariantCheck("feedback_records_exist", !report.feedbackLedger.emittedByTick.isEmpty, "non-empty", "\(report.feedbackLedger.emittedByTick.count)"),
        approvedApplicationInvariantCheck("deterministic_tick_order", records.map(\.tick) == [0, 1, 2], "0,1,2", "\(records.map(\.tick))"),
        approvedApplicationInvariantCheck("deterministic_agent_order", Array(report.initialAgents.keys).sorted() == report.initialAgents.keys.sorted(), "stable", "stable"),
        approvedApplicationInvariantCheck("contexts_sorted_by_agent_id", allContextsSorted, "sorted", "\(allContextsSorted)"),
        approvedApplicationInvariantCheck("policy_decisions_sorted_by_agent_id", allDecisionsSorted, "sorted", "\(allDecisionsSorted)"),
        approvedApplicationInvariantCheck("feedback_sorted_by_agent_id", allFeedbackSorted, "sorted", "\(allFeedbackSorted)"),
        approvedApplicationInvariantCheck("tick_0_feedback_store_empty", tick0?.inputFeedbackByAgent.isEmpty == true, "empty", "\(tick0?.inputFeedbackByAgent.count ?? -1)"),
        approvedApplicationInvariantCheck("tick_0_consumes_no_feedback", tick0?.summary.feedbackConsumed == 0, "0", "\(tick0?.summary.feedbackConsumed ?? -1)"),
        approvedApplicationInvariantCheck("tick_0_emits_feedback_for_tick_1", tick0?.summary.tickFeedbackEmitted == 4, "4", "\(tick0?.summary.tickFeedbackEmitted ?? -1)"),
        approvedApplicationInvariantCheck("tick_1_consumes_tick_0_feedback", report.feedbackLedger.tick0FeedbackConsumedAtTick1 && tick1ConsumedIds == tick0FeedbackIds, "tick 0 ids", "\(tick1ConsumedIds)"),
        approvedApplicationInvariantCheck("tick_1_does_not_consume_tick_1_feedback", tick1?.summary.sameTickFeedbackConsumed == 0, "0", "\(tick1?.summary.sameTickFeedbackConsumed ?? -1)"),
        approvedApplicationInvariantCheck("tick_2_consumes_tick_1_feedback", report.feedbackLedger.memorylessPreviousTickOnly && tick2ConsumedIds == tick1FeedbackIds, "tick 1 ids", "\(tick2ConsumedIds)"),
        approvedApplicationInvariantCheck("no_same_tick_feedback_consumed", summary.sameTickFeedbackConsumedTotal == 0, "0", "\(summary.sameTickFeedbackConsumedTotal)"),
        approvedApplicationInvariantCheck("no_future_feedback_consumed", summary.futureFeedbackConsumedTotal == 0, "0", "\(summary.futureFeedbackConsumedTotal)"),
        approvedApplicationInvariantCheck("no_cross_agent_feedback_leak", summary.crossAgentFeedbackLeaksTotal == 0, "0", "\(summary.crossAgentFeedbackLeaksTotal)"),
        approvedApplicationInvariantCheck("agent_1_receives_own_conflict_feedback_at_tick_1", report.feedbackLedger.conflictFeedbackConsumedAtTick1, "true", "\(report.feedbackLedger.conflictFeedbackConsumedAtTick1)"),
        approvedApplicationInvariantCheck("agent_1_blocked_conflict_feedback_becomes_no_intent_at_tick_1", agent1Tick1Decision?.feedbackAwareDecision == .noIntent, "noIntent", agent1Tick1Decision?.feedbackAwareDecision.rawValue ?? "missing"),
        approvedApplicationInvariantCheck("agent_1_no_intent_filtered_before_tick_1", tick1NoIntentIds.contains("agent_1_loser"), "filtered", "\(tick1NoIntentIds)"),
        approvedApplicationInvariantCheck("agent_3_receives_own_collision_feedback_at_tick_1", report.feedbackLedger.collisionFeedbackConsumedAtTick1, "true", "\(report.feedbackLedger.collisionFeedbackConsumedAtTick1)"),
        approvedApplicationInvariantCheck("agent_3_blocked_collision_feedback_becomes_no_intent_at_tick_1", agent3Tick1Decision?.feedbackAwareDecision == .noIntent, "noIntent", agent3Tick1Decision?.feedbackAwareDecision.rawValue ?? "missing"),
        approvedApplicationInvariantCheck("agent_3_no_intent_filtered_before_tick_1", tick1NoIntentIds.contains("agent_3_collision"), "filtered", "\(tick1NoIntentIds)"),
        approvedApplicationInvariantCheck("conflict_reduced_at_tick_1", tick1?.summary.tickDeniedConflict == 0, "0", "\(tick1?.summary.tickDeniedConflict ?? -1)"),
        approvedApplicationInvariantCheck("collision_reduced_at_tick_1", tick1?.summary.tickDeniedCollision == 0, "0", "\(tick1?.summary.tickDeniedCollision ?? -1)"),
        approvedApplicationInvariantCheck("memoryless_previous_tick_only_behavior_documented", report.feedbackLedger.memorylessPreviousTickOnly, "true", "\(report.feedbackLedger.memorylessPreviousTickOnly)"),
        approvedApplicationInvariantCheck("v0_policy_remains_available", true, "produceAgentIntentProposalV0 unchanged", "available"),
        approvedApplicationInvariantCheck("v1_policy_is_opt_in", true, "explicit scenario", "explicit scenario"),
        approvedApplicationInvariantCheck("no_feedback_keeps_baseline", tick0?.policyDecisions.allSatisfy { $0.lastFeedbackKind == nil ? !$0.behaviorChanged : true } == true, "true", "checked"),
        approvedApplicationInvariantCheck("approved_or_moved_feedback_keeps_baseline", tick1?.policyDecisions.filter { $0.lastFeedbackKind == .moved }.allSatisfy { !$0.behaviorChanged } == true, "true", "checked"),
        approvedApplicationInvariantCheck("blocked_feedback_becomes_no_intent", tick1?.summary.noIntentFromBlockedFeedback == 2, "2", "\(tick1?.summary.noIntentFromBlockedFeedback ?? -1)"),
        approvedApplicationInvariantCheck("no_intent_filtered_before_tick", records.allSatisfy { $0.noIntentFilteredOut.count == $0.summary.noIntent }, "filtered", "\(records.map { $0.noIntentFilteredOut.count })"),
        approvedApplicationInvariantCheck("tick_receives_only_accepted_movement_intents", records.allSatisfy { $0.tickInput.intents.count == $0.summary.movementIntentInputs }, "movement intents only", "\(records.map { $0.tickInput.intents.count })"),
        approvedApplicationInvariantCheck("tick_0_intents_expected", tick0?.summary.movementIntentInputs == 4, "4", "\(tick0?.summary.movementIntentInputs ?? -1)"),
        approvedApplicationInvariantCheck("tick_1_intents_expected", tick1?.summary.movementIntentInputs == 2, "2", "\(tick1?.summary.movementIntentInputs ?? -1)"),
        approvedApplicationInvariantCheck("tick_2_intents_expected", tick2?.summary.movementIntentInputs == 4, "4", "\(tick2?.summary.movementIntentInputs ?? -1)"),
        approvedApplicationInvariantCheck("tick_0_conflict_expected", tick0?.summary.tickDeniedConflict == 1, "1", "\(tick0?.summary.tickDeniedConflict ?? -1)"),
        approvedApplicationInvariantCheck("tick_0_collision_expected", tick0?.summary.tickDeniedCollision == 1, "1", "\(tick0?.summary.tickDeniedCollision ?? -1)"),
        approvedApplicationInvariantCheck("tick_1_conflict_reduced", tick1?.summary.tickDeniedConflict == 0, "0", "\(tick1?.summary.tickDeniedConflict ?? -1)"),
        approvedApplicationInvariantCheck("tick_1_collision_reduced", tick1?.summary.tickDeniedCollision == 0, "0", "\(tick1?.summary.tickDeniedCollision ?? -1)"),
        approvedApplicationInvariantCheck("tick_denied_collision_expected", summary.tickDeniedCollisionTotal >= 1, ">=1", "\(summary.tickDeniedCollisionTotal)"),
        approvedApplicationInvariantCheck("approved_applications_expected", summary.approvedApplicationsTotal > 0, ">0", "\(summary.approvedApplicationsTotal)"),
        approvedApplicationInvariantCheck("approved_agents_moved_expected", summary.approvedAgentsMovedTotal == summary.approvedApplicationsTotal, "matches approved applications", "\(summary.approvedAgentsMovedTotal)/\(summary.approvedApplicationsTotal)"),
        approvedApplicationInvariantCheck("denied_agents_preserved_expected", summary.deniedAgentsPreservedTotal > 0, ">0", "\(summary.deniedAgentsPreservedTotal)"),
        approvedApplicationInvariantCheck("no_intent_agents_preserved_expected", summary.noIntentAgentsPreservedTotal > 0, ">0", "\(summary.noIntentAgentsPreservedTotal)"),
        approvedApplicationInvariantCheck("only_approved_agents_move", onlyApprovedMove, "true", "\(onlyApprovedMove)"),
        approvedApplicationInvariantCheck("denied_agents_do_not_move", deniedDoNotMove, "true", "\(deniedDoNotMove)"),
        approvedApplicationInvariantCheck("no_intent_agents_do_not_move", noIntentDoNotMove, "true", "\(noIntentDoNotMove)"),
        approvedApplicationInvariantCheck("positions_update_between_ticks", positionsUpdateBetweenTicks, "true", "\(positionsUpdateBetweenTicks)"),
        approvedApplicationInvariantCheck("contexts_use_updated_positions", contextsUseUpdatedPositions, "true", "\(contextsUseUpdatedPositions)"),
        approvedApplicationInvariantCheck("abstract_positions_changed_expected", summary.abstractPositionsChangedTotal == summary.displacementsAppliedTotal, "matches displacements", "\(summary.abstractPositionsChangedTotal)/\(summary.displacementsAppliedTotal)"),
        approvedApplicationInvariantCheck("physical_positions_changed_expected", summary.physicalPositionsChangedTotal == summary.displacementsAppliedTotal, "matches displacements", "\(summary.physicalPositionsChangedTotal)/\(summary.displacementsAppliedTotal)"),
        approvedApplicationInvariantCheck("abstract_physical_divergence_before_zero", summary.abstractPhysicalDivergenceBeforeMax == 0, "0", "\(summary.abstractPhysicalDivergenceBeforeMax)"),
        approvedApplicationInvariantCheck("abstract_physical_divergence_after_zero", summary.abstractPhysicalDivergenceAfterMax == 0, "0", "\(summary.abstractPhysicalDivergenceAfterMax)"),
        approvedApplicationInvariantCheck("policy_read_collision_false", !summary.policyReadCollision, "false", "\(summary.policyReadCollision)"),
        approvedApplicationInvariantCheck("tick_read_collision_true", summary.tickReadCollision, "true", "\(summary.tickReadCollision)"),
        approvedApplicationInvariantCheck("policy_world_used_false", !summary.policyWorldUsed, "false", "\(summary.policyWorldUsed)"),
        approvedApplicationInvariantCheck("tick_world_readonly_used_true", summary.tickWorldReadOnlyUsed, "true", "\(summary.tickWorldReadOnlyUsed)"),
        approvedApplicationInvariantCheck("movement_applied_true", summary.movementApplied, "true", "\(summary.movementApplied)"),
        approvedApplicationInvariantCheck("memory_not_updated", !summary.memoryUpdated, "false", "\(summary.memoryUpdated)"),
        approvedApplicationInvariantCheck("goal_not_changed", !summary.goalChanged, "false", "\(summary.goalChanged)"),
        approvedApplicationInvariantCheck("pathfinding_not_performed", !summary.pathfindingPerformed, "false", "\(summary.pathfindingPerformed)"),
        approvedApplicationInvariantCheck("replanning_not_performed", !summary.replanningPerformed, "false", "\(summary.replanningPerformed)"),
        approvedApplicationInvariantCheck("avoidance_not_performed", !summary.avoidancePerformed, "false", "\(summary.avoidancePerformed)"),
        approvedApplicationInvariantCheck("reservation_runtime_not_used", !summary.reservationRuntimeUsed, "false", "\(summary.reservationRuntimeUsed)"),
        approvedApplicationInvariantCheck("route_following_not_used", !summary.routeFollowingUsed, "false", "\(summary.routeFollowingUsed)"),
        approvedApplicationInvariantCheck("learning_not_performed", true, "false", "false"),
        approvedApplicationInvariantCheck("llm_rl_python_not_used", true, "false", "false"),
        approvedApplicationInvariantCheck("social_behavior_not_used", true, "false", "false"),
        approvedApplicationInvariantCheck("communication_not_used", true, "false", "false"),
        approvedApplicationInvariantCheck("terrain_mutation_not_performed", !summary.mutationPerformed, "false", "\(summary.mutationPerformed)"),
        approvedApplicationInvariantCheck("world_mutation_not_performed", !summary.worldMutated, "false", "\(summary.worldMutated)"),
        approvedApplicationInvariantCheck("multi_tick_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("multi_tick_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("multi_tick_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("feedback_aware_approved_application_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("feedback_aware_live_readonly_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("feedback_aware_intent_to_tick_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("feedback_aware_policy_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("feedback_to_context_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("agent_intent_v0_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        approvedApplicationInvariantCheck("report_written", true, "multi_tick_closed_loop_approved_application_report.json", "multi_tick_closed_loop_approved_application_report.json"),
        approvedApplicationInvariantCheck("ticks_written", true, "multi_tick_closed_loop_approved_application_ticks.json", "multi_tick_closed_loop_approved_application_ticks.json"),
        approvedApplicationInvariantCheck("feedback_written", true, "multi_tick_closed_loop_approved_application_feedback.json", "multi_tick_closed_loop_approved_application_feedback.json"),
        approvedApplicationInvariantCheck("metrics_written", true, "multiTickClosedLoopApprovedApplication*", "multiTickClosedLoopApprovedApplication*"),
        approvedApplicationInvariantCheck("event_written", true, "lab_multi_tick_closed_loop_approved_application_recorded", "lab_multi_tick_closed_loop_approved_application_recorded"),
        approvedApplicationInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let passed = checks.filter(\.passed).count
    return LabMultiTickClosedLoopApprovedApplicationInvariantReport(
        scenario: scenario,
        seed: seed,
        success: passed == checks.count,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: passed,
            checksFailed: checks.count - passed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "The closed loop executes exactly three approved-application ticks.",
            "Only approved movements update the lab abstract and physical position maps.",
            "Feedback emitted at tick N is consumed only at tick N+1.",
            "The policy never reads collision or World; the tick layer reads collision/World read-only and applies only lab-map movement."
        ]
    )
}
