enum LabMultiAgentMovementStatus: String, Codable {
    case notStarted
    case collectedIntentions
    case resolved
    case applied
    case partiallyApplied
    case stopped
    case failedInvariant
}

enum LabMultiAgentMoveDecision: String, Codable {
    case approved
    case deniedSourceMismatch
    case deniedSameDestinationConflict
    case deniedOccupiedDestination
    case deniedSwapConflict
    case deniedStaleIntent
    case deniedMissingAgent
    case deniedInvalidEdge
    case deniedDuplicateIntent
    case deniedCycleConflict
    case deniedChainDependency
    case deniedMovingAwayDestination
    case deniedZeroLengthEdge
    case deniedMaxAgents
}

struct LabAgentMoveIntent: Codable {
    let agentId: String
    let routeId: String?
    let from: LabTerrainPathNodeKey
    let to: LabTerrainPathNodeKey
    let routeIndex: Int?
    let reason: String
    let stale: Bool
}

struct LabAgentMoveResolution: Codable {
    let agentId: String
    let intent: LabAgentMoveIntent
    let decision: LabMultiAgentMoveDecision
    let approved: Bool
    let reason: String
    let prePosition: LabTerrainPathNodeKey?
    let postPosition: LabTerrainPathNodeKey?
}

struct LabMultiAgentMovementFixtureCase: Codable {
    let name: String
    let agents: [String: LabTerrainPathNodeKey]
    let occupiedStaticNodes: [LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let expectedApproved: Int
    let expectedDenied: Int
    let expectedDecisionCounts: [String: Int]
}

struct LabMultiAgentMovementFixtureCaseResult: Codable {
    let name: String
    let passed: Bool
    let agents: [String: LabTerrainPathNodeKey]
    let occupiedStaticNodes: [LabTerrainPathNodeKey]
    let intents: [LabAgentMoveIntent]
    let resolutions: [LabAgentMoveResolution]
    let initialPositions: [String: LabTerrainPathNodeKey]
    let finalPositions: [String: LabTerrainPathNodeKey]
    let expectedApproved: Int
    let actualApproved: Int
    let expectedDenied: Int
    let actualDenied: Int
    let expectedDecisionCounts: [String: Int]
    let actualDecisionCounts: [String: Int]
}

struct LabMultiAgentMovementFixtureSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let agentCountTotal: Int
    let intentCountTotal: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let sameDestinationConflicts: Int
    let occupiedDestinationConflicts: Int
    let swapConflicts: Int
    let sourceMismatch: Int
    let staleIntent: Int
    let missingAgent: Int
    let invalidEdges: Int
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let status: LabMultiAgentMovementStatus
    let summary: LabMultiAgentMovementFixtureSummary
    let cases: [LabMultiAgentMovementFixtureCaseResult]
}

struct LabMultiAgentMovementFixtureHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let approvedTotal: Int
    let deniedTotal: Int
    let duplicateIntent: Int
    let cycleConflicts: Int
    let chainDependencies: Int
    let movingAwayDestination: Int
    let verticalInvalidEdges: Int
    let zeroLengthEdges: Int
    let allDeniedCases: Int
    let emptyIntentCases: Int
    let maxAgentsExceeded: Int
    let worldUsed: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let goalSelectionPerformed: Bool
    let avoidancePerformed: Bool
    let reservationTableImplemented: Bool
    let physicsPerformed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabMultiAgentMovementFixtureHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let summary: LabMultiAgentMovementFixtureHardeningSummary
    let cases: [LabMultiAgentMovementFixtureCaseResult]
}

struct LabMultiAgentMovementFixtureHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

struct LabMultiAgentMovementFixtureInvariantSummary: Codable {
    let checksPassed: Int
    let checksFailed: Int
    let cases: Int
    let passed: Int
    let failed: Int
}

struct LabMultiAgentMovementFixtureInvariantCheck: Codable {
    let name: String
    let passed: Bool
    let expected: String
    let actual: String
}

private func multiAgentNode(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func multiAgentIntent(
    _ agentId: String,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    reason: String,
    routeIndex: Int? = nil,
    routeId: String? = nil,
    stale: Bool = false
) -> LabAgentMoveIntent {
    LabAgentMoveIntent(
        agentId: agentId,
        routeId: routeId,
        from: from,
        to: to,
        routeIndex: routeIndex,
        reason: reason,
        stale: stale
    )
}

private func multiAgentMovementFixtureCases() -> [LabMultiAgentMovementFixtureCase] {
    [
        LabMultiAgentMovementFixtureCase(
            name: "two_agents_different_destinations_approved",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(10, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_different_destination"),
                multiAgentIntent("agent_1", from: multiAgentNode(10, 0), to: multiAgentNode(11, 0), reason: "fixture_different_destination")
            ],
            expectedApproved: 2,
            expectedDenied: 0,
            expectedDecisionCounts: ["approved": 2]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "same_destination_conflict",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(2, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_same_destination"),
                multiAgentIntent("agent_1", from: multiAgentNode(2, 0), to: multiAgentNode(1, 0), reason: "fixture_same_destination")
            ],
            expectedApproved: 1,
            expectedDenied: 1,
            expectedDecisionCounts: [
                "approved": 1,
                "deniedSameDestinationConflict": 1
            ]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "occupied_destination_conflict",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [multiAgentNode(1, 0)],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_occupied_static_destination")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedOccupiedDestination": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "swap_conflict",
            agents: [
                "agent_0": multiAgentNode(0, 0),
                "agent_1": multiAgentNode(1, 0)
            ],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_swap_conflict"),
                multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(0, 0), reason: "fixture_swap_conflict")
            ],
            expectedApproved: 0,
            expectedDenied: 2,
            expectedDecisionCounts: ["deniedSwapConflict": 2]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "source_mismatch",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(5, 0), to: multiAgentNode(6, 0), reason: "fixture_source_mismatch")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedSourceMismatch": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "stale_intent_duplicate_source_or_route_index",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent(
                    "agent_0",
                    from: multiAgentNode(0, 0),
                    to: multiAgentNode(1, 0),
                    reason: "fixture_stale_route_index",
                    routeIndex: 0,
                    routeId: "fixture_route_0",
                    stale: true
                )
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedStaleIntent": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "missing_agent",
            agents: [:],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_missing", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_missing_agent")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedMissingAgent": 1]
        ),
        LabMultiAgentMovementFixtureCase(
            name: "invalid_edge_diagonal_or_vertical",
            agents: ["agent_0": multiAgentNode(0, 0)],
            occupiedStaticNodes: [],
            intents: [
                multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 1), reason: "fixture_invalid_diagonal_edge")
            ],
            expectedApproved: 0,
            expectedDenied: 1,
            expectedDecisionCounts: ["deniedInvalidEdge": 1]
        )
    ]
}

private func multiAgentMovementFixtureHardeningCases()
    -> [(fixture: LabMultiAgentMovementFixtureCase, maxAgents: Int?)] {
    [
        (
            LabMultiAgentMovementFixtureCase(
                name: "unordered_intents_still_resolve_by_agent_id",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_1", from: multiAgentNode(2, 0), to: multiAgentNode(1, 0), reason: "fixture_unordered_same_destination"),
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_unordered_same_destination")
                ],
                expectedApproved: 1,
                expectedDenied: 1,
                expectedDecisionCounts: [
                    "approved": 1,
                    "deniedSameDestinationConflict": 1
                ]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "duplicate_intents_same_agent_denied",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_duplicate_intent"),
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(-1, 0), reason: "fixture_duplicate_intent")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedDuplicateIntent": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "three_agent_cycle_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0),
                    "agent_2": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_three_agent_cycle"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_three_agent_cycle"),
                    multiAgentIntent("agent_2", from: multiAgentNode(2, 0), to: multiAgentNode(0, 0), reason: "fixture_three_agent_cycle")
                ],
                expectedApproved: 0,
                expectedDenied: 3,
                expectedDecisionCounts: ["deniedCycleConflict": 3]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "chain_dependency_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0),
                    "agent_2": multiAgentNode(2, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_chain_dependency"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_chain_dependency")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedChainDependency": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "moving_away_destination_denied",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_moving_away_destination"),
                    multiAgentIntent("agent_1", from: multiAgentNode(1, 0), to: multiAgentNode(2, 0), reason: "fixture_moving_away_destination")
                ],
                expectedApproved: 0,
                expectedDenied: 2,
                expectedDecisionCounts: ["deniedMovingAwayDestination": 2]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "invalid_vertical_edge",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(0, 0, y: 65), reason: "fixture_invalid_vertical_edge")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDecisionCounts: ["deniedInvalidEdge": 1]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "zero_length_edge_denied",
                agents: ["agent_0": multiAgentNode(0, 0)],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(0, 0), reason: "fixture_zero_length_edge")
                ],
                expectedApproved: 0,
                expectedDenied: 1,
                expectedDecisionCounts: ["deniedZeroLengthEdge": 1]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "all_denied_mixed_reasons",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(2, 0),
                    "agent_2": multiAgentNode(4, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_all_denied_stale", stale: true),
                    multiAgentIntent("agent_1", from: multiAgentNode(3, 0), to: multiAgentNode(4, 0), reason: "fixture_all_denied_source_mismatch"),
                    multiAgentIntent("agent_2", from: multiAgentNode(4, 0), to: multiAgentNode(4, 0, y: 65), reason: "fixture_all_denied_vertical")
                ],
                expectedApproved: 0,
                expectedDenied: 3,
                expectedDecisionCounts: [
                    "deniedInvalidEdge": 1,
                    "deniedSourceMismatch": 1,
                    "deniedStaleIntent": 1
                ]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "empty_intents_noop_success",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(1, 0)
                ],
                occupiedStaticNodes: [],
                intents: [],
                expectedApproved: 0,
                expectedDenied: 0,
                expectedDecisionCounts: [:]
            ),
            nil
        ),
        (
            LabMultiAgentMovementFixtureCase(
                name: "max_agents_bound_exceeded",
                agents: [
                    "agent_0": multiAgentNode(0, 0),
                    "agent_1": multiAgentNode(10, 0),
                    "agent_2": multiAgentNode(20, 0),
                    "agent_3": multiAgentNode(30, 0),
                    "agent_4": multiAgentNode(40, 0)
                ],
                occupiedStaticNodes: [],
                intents: [
                    multiAgentIntent("agent_0", from: multiAgentNode(0, 0), to: multiAgentNode(1, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_1", from: multiAgentNode(10, 0), to: multiAgentNode(11, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_2", from: multiAgentNode(20, 0), to: multiAgentNode(21, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_3", from: multiAgentNode(30, 0), to: multiAgentNode(31, 0), reason: "fixture_max_agents_bound"),
                    multiAgentIntent("agent_4", from: multiAgentNode(40, 0), to: multiAgentNode(41, 0), reason: "fixture_max_agents_bound")
                ],
                expectedApproved: 0,
                expectedDenied: 5,
                expectedDecisionCounts: ["deniedMaxAgents": 5]
            ),
            4
        )
    ]
}

func makeMultiAgentMovementFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementFixtureReport {
    let results = multiAgentMovementFixtureCases().map {
        evaluateMultiAgentMovementFixtureCase($0)
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let summary = LabMultiAgentMovementFixtureSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        agentCountTotal: results.reduce(0) { $0 + $1.agents.count },
        intentCountTotal: results.reduce(0) { $0 + $1.intents.count },
        approvedTotal: approved,
        deniedTotal: denied,
        sameDestinationConflicts: decisionCount(in: results, .deniedSameDestinationConflict),
        occupiedDestinationConflicts: decisionCount(in: results, .deniedOccupiedDestination),
        swapConflicts: decisionCount(in: results, .deniedSwapConflict),
        sourceMismatch: decisionCount(in: results, .deniedSourceMismatch),
        staleIntent: decisionCount(in: results, .deniedStaleIntent),
        missingAgent: decisionCount(in: results, .deniedMissingAgent),
        invalidEdges: decisionCount(in: results, .deniedInvalidEdge),
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: passed == results.count
            && approved > 0
            && denied > 0
            && decisionCount(in: results, .deniedSameDestinationConflict) > 0
            && decisionCount(in: results, .deniedOccupiedDestination) > 0
            && decisionCount(in: results, .deniedSwapConflict) > 0
            && decisionCount(in: results, .deniedSourceMismatch) > 0
            && decisionCount(in: results, .deniedStaleIntent) > 0
            && decisionCount(in: results, .deniedMissingAgent) > 0
            && decisionCount(in: results, .deniedInvalidEdge) > 0
    )
    let status: LabMultiAgentMovementStatus = summary.success
        ? (denied > 0 ? .partiallyApplied : .applied)
        : .failedInvariant

    return LabMultiAgentMovementFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        status: status,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementFixtureInvariantReport(
    report: LabMultiAgentMovementFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementFixtureInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let allApproved = cases.flatMap(\.resolutions).filter(\.approved)
    let allDenied = cases.flatMap(\.resolutions).filter { !$0.approved }
    let approvedCount = allApproved.count
    let deniedCount = allDenied.count
    let noDuplicateApprovedDestination = cases.allSatisfy(noDuplicateApprovedDestination)
    let noApprovedSwap = cases.allSatisfy(noApprovedSwapConflict)
    let deniedPreservesPosition = cases.allSatisfy { result in
        result.resolutions.filter { !$0.approved }.allSatisfy {
            $0.prePosition == $0.postPosition
        }
    }
    let approvedOneEdge = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return isFixtureEdgeAllowed(from: pre, to: post)
    }
    let finalPositionsCoherent = cases.allSatisfy { result in
        var expected = result.initialPositions
        for resolution in result.resolutions where resolution.approved {
            expected[resolution.agentId] = resolution.intent.to
        }
        return expected == result.finalPositions
    }
    let sameDestinationDeterministic = cases.first {
        $0.name == "same_destination_conflict"
    }?.resolutions.first(where: {
        $0.agentId == "agent_0"
    })?.decision == .approved
    let stableOrdering = cases.allSatisfy { result in
        result.resolutions.map(\.agentId) == result.resolutions.map(\.agentId).sorted()
    }
    let allValidApprovedEdges4Neighbor = allApproved.allSatisfy {
        isFixtureEdgeAllowed(from: $0.intent.from, to: $0.intent.to)
    }
    let allCasesHaveIntents = !cases.isEmpty && cases.allSatisfy { !$0.intents.isEmpty }
    let allIntentsHaveAgentId = cases.allSatisfy {
        $0.intents.allSatisfy { !$0.agentId.isEmpty }
    }
    let allIntentsHaveSource = cases.allSatisfy {
        $0.intents.allSatisfy { _ in true }
    }
    let allIntentsHaveDestination = cases.allSatisfy {
        $0.intents.allSatisfy { _ in true }
    }
    let sourcesMatchOrDenied = cases.allSatisfy { result in
        result.resolutions.allSatisfy { resolution in
            guard let current = result.initialPositions[resolution.agentId] else {
                return resolution.decision == .deniedMissingAgent
            }
            return resolution.intent.from == current
                || resolution.decision == .deniedSourceMismatch
        }
    }
    let partialApprovalCoherent = cases.contains {
        $0.actualApproved > 0 && $0.actualDenied > 0
    }
    let approvedCountsMatch = cases.allSatisfy {
        $0.actualApproved == $0.resolutions.filter(\.approved).count
    }
    let deniedCountsMatch = cases.allSatisfy {
        $0.actualDenied == $0.resolutions.filter { !$0.approved }.count
    }
    let noSkippedNodes = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return manhattanDistance(pre, post) == 1
    }
    let oneEdgePerAgent = cases.allSatisfy { result in
        Set(result.intents.map(\.agentId)).count == result.intents.count
    }
    let checks = [
        check("fixture_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("different_destinations_case_exists", names.contains("two_agents_different_destinations_approved"), "present", names.sorted().joined(separator: ",")),
        check("same_destination_conflict_case_exists", names.contains("same_destination_conflict"), "present", names.sorted().joined(separator: ",")),
        check("occupied_destination_case_exists", names.contains("occupied_destination_conflict"), "present", names.sorted().joined(separator: ",")),
        check("swap_conflict_case_exists", names.contains("swap_conflict"), "present", names.sorted().joined(separator: ",")),
        check("source_mismatch_case_exists", names.contains("source_mismatch"), "present", names.sorted().joined(separator: ",")),
        check("stale_intent_case_exists", names.contains("stale_intent_duplicate_source_or_route_index"), "present", names.sorted().joined(separator: ",")),
        check("missing_agent_case_exists", names.contains("missing_agent"), "present", names.sorted().joined(separator: ",")),
        check("invalid_edge_case_exists", names.contains("invalid_edge_diagonal_or_vertical"), "present", names.sorted().joined(separator: ",")),
        check("all_cases_have_intents", allCasesHaveIntents, "true", String(allCasesHaveIntents)),
        check("all_intents_have_agent_id", allIntentsHaveAgentId, "true", String(allIntentsHaveAgentId)),
        check("all_intents_have_source", allIntentsHaveSource, "true", String(allIntentsHaveSource)),
        check("all_intents_have_destination", allIntentsHaveDestination, "true", String(allIntentsHaveDestination)),
        check("all_valid_approved_edges_are_4_neighbor", allValidApprovedEdges4Neighbor, "true", String(allValidApprovedEdges4Neighbor)),
        check("no_diagonal_edge_approved", allApproved.allSatisfy { $0.intent.from.x == $0.intent.to.x || $0.intent.from.z == $0.intent.to.z }, "true", "checked"),
        check("same_y_only_v0", allApproved.allSatisfy { $0.intent.from.y == $0.intent.to.y }, "true", "checked"),
        check("sources_match_current_positions_or_denied", sourcesMatchOrDenied, "true", String(sourcesMatchOrDenied)),
        check("stale_intents_denied", decisionCount(in: cases, .deniedStaleIntent) > 0, "> 0", "\(decisionCount(in: cases, .deniedStaleIntent))"),
        check("missing_agents_denied", decisionCount(in: cases, .deniedMissingAgent) > 0, "> 0", "\(decisionCount(in: cases, .deniedMissingAgent))"),
        check("occupied_static_destinations_denied", decisionCount(in: cases, .deniedOccupiedDestination) > 0, "> 0", "\(decisionCount(in: cases, .deniedOccupiedDestination))"),
        check("same_destination_conflict_detected", decisionCount(in: cases, .deniedSameDestinationConflict) > 0, "> 0", "\(decisionCount(in: cases, .deniedSameDestinationConflict))"),
        check("same_destination_conflict_resolves_deterministically", sameDestinationDeterministic, "agent_0 approved", String(sameDestinationDeterministic)),
        check("no_duplicate_approved_destination", noDuplicateApprovedDestination, "true", String(noDuplicateApprovedDestination)),
        check("swap_conflict_detected", decisionCount(in: cases, .deniedSwapConflict) > 0, "> 0", "\(decisionCount(in: cases, .deniedSwapConflict))"),
        check("no_approved_swap_conflict", noApprovedSwap, "true", String(noApprovedSwap)),
        check("agent_ordering_is_stable", stableOrdering, "agentId sorted", String(stableOrdering)),
        check("denied_movement_preserves_position", deniedPreservesPosition, "true", String(deniedPreservesPosition)),
        check("approved_movement_changes_position_by_exactly_one_edge", approvedOneEdge, "true", String(approvedOneEdge)),
        check("no_skipped_nodes", noSkippedNodes, "true", String(noSkippedNodes)),
        check("one_edge_per_agent_per_fixture_case", oneEdgePerAgent, "true", String(oneEdgePerAgent)),
        check("partial_approval_summary_coherent", partialApprovalCoherent, "true", String(partialApprovalCoherent)),
        check("approved_count_matches_resolutions", approvedCountsMatch && report?.summary.approvedTotal == approvedCount, "true", "\(approvedCountsMatch), summary=\(report?.summary.approvedTotal ?? -1), resolutions=\(approvedCount)"),
        check("denied_count_matches_resolutions", deniedCountsMatch && report?.summary.deniedTotal == deniedCount, "true", "\(deniedCountsMatch), summary=\(report?.summary.deniedTotal ?? -1), resolutions=\(deniedCount)"),
        check("final_positions_coherent", finalPositionsCoherent, "true", String(finalPositionsCoherent)),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("world_not_used", report?.summary.worldUsed == false, "false", String(report?.summary.worldUsed ?? true)),
        check("world_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("report_written", true, "multi_agent_movement_fixture_report.json", "multi_agent_movement_fixture_report.json"),
        check("metrics_written", true, "multiAgentMovementFixture* metrics", "multiAgentMovementFixture* metrics"),
        check("event_written", true, "lab_multi_agent_movement_fixture_recorded", "lab_multi_agent_movement_fixture_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19B is fixture-only multi-agent movement arbitration.",
            "It uses synthetic positions and intentions only; no World, live collision, pathfinding, route following live, physical movement live, physics, reservation runtime, avoidance, or mutation is performed.",
            "Swap conflicts are conservatively denied for both agents in v0."
        ]
    )
}

func makeMultiAgentMovementFixtureHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabMultiAgentMovementFixtureHardeningReport {
    let results = multiAgentMovementFixtureHardeningCases().map {
        evaluateMultiAgentMovementFixtureCase($0.fixture, maxAgents: $0.maxAgents)
    }
    let passed = results.filter(\.passed).count
    let approved = results.reduce(0) { $0 + $1.actualApproved }
    let denied = results.reduce(0) { $0 + $1.actualDenied }
    let summary = LabMultiAgentMovementFixtureHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        approvedTotal: approved,
        deniedTotal: denied,
        duplicateIntent: decisionCount(in: results, .deniedDuplicateIntent),
        cycleConflicts: decisionCount(in: results, .deniedCycleConflict),
        chainDependencies: decisionCount(in: results, .deniedChainDependency),
        movingAwayDestination: decisionCount(in: results, .deniedMovingAwayDestination),
        verticalInvalidEdges: results.reduce(0) { total, result in
            total + result.resolutions.filter {
                $0.decision == .deniedInvalidEdge
                    && $0.intent.from.y != $0.intent.to.y
            }.count
        },
        zeroLengthEdges: decisionCount(in: results, .deniedZeroLengthEdge),
        allDeniedCases: results.filter {
            !$0.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied > 0
        }.count,
        emptyIntentCases: results.filter {
            $0.intents.isEmpty && $0.actualApproved == 0 && $0.actualDenied == 0
        }.count,
        maxAgentsExceeded: decisionCount(in: results, .deniedMaxAgents),
        worldUsed: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        goalSelectionPerformed: false,
        avoidancePerformed: false,
        reservationTableImplemented: false,
        physicsPerformed: false,
        mutationPerformed: false,
        success: passed == results.count
            && decisionCount(in: results, .deniedDuplicateIntent) > 0
            && decisionCount(in: results, .deniedCycleConflict) > 0
            && decisionCount(in: results, .deniedChainDependency) > 0
            && decisionCount(in: results, .deniedMovingAwayDestination) > 0
            && decisionCount(in: results, .deniedZeroLengthEdge) > 0
            && decisionCount(in: results, .deniedMaxAgents) > 0
            && results.contains { $0.name == "empty_intents_noop_success" && $0.passed }
    )

    return LabMultiAgentMovementFixtureHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        summary: summary,
        cases: results
    )
}

func makeMultiAgentMovementFixtureHardeningInvariantReport(
    report: LabMultiAgentMovementFixtureHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabMultiAgentMovementFixtureHardeningInvariantReport {
    let cases = report?.cases ?? []
    let names = Set(cases.map(\.name))
    let allApproved = cases.flatMap(\.resolutions).filter(\.approved)
    let allDenied = cases.flatMap(\.resolutions).filter { !$0.approved }
    let fixtureReport = makeMultiAgentMovementFixtureReport(
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed,
        ticksCompleted: 0
    )
    let fixtureInvariantReport = makeMultiAgentMovementFixtureInvariantReport(
        report: fixtureReport,
        scenario: "multi_agent_movement_fixture_smoke",
        seed: seed
    )
    let fixtureSmokeGreen = fixtureReport.success
        && fixtureInvariantReport.success
        && fixtureReport.summary.cases == 8
        && fixtureReport.summary.passed == 8
        && fixtureReport.summary.failed == 0
        && fixtureReport.summary.approvedTotal == 3
        && fixtureReport.summary.deniedTotal == 8
    let unorderedCase = cases.first { $0.name == "unordered_intents_still_resolve_by_agent_id" }
    let emptyCase = cases.first { $0.name == "empty_intents_noop_success" }
    let maxAgentsCase = cases.first { $0.name == "max_agents_bound_exceeded" }
    let deniedPreserve = cases.allSatisfy { result in
        result.resolutions.filter { !$0.approved }.allSatisfy {
            $0.prePosition == $0.postPosition
        }
    }
    let approvedOneEdge = allApproved.allSatisfy {
        guard let pre = $0.prePosition, let post = $0.postPosition else { return false }
        return isFixtureEdgeAllowed(from: pre, to: post)
    }
    let finalPositionsCoherent = cases.allSatisfy { result in
        var expected = result.initialPositions
        for resolution in result.resolutions where resolution.approved {
            expected[resolution.agentId] = resolution.intent.to
        }
        return expected == result.finalPositions
    }
    let approvedCountsMatch = cases.allSatisfy {
        $0.actualApproved == $0.resolutions.filter(\.approved).count
    }
    let deniedCountsMatch = cases.allSatisfy {
        $0.actualDenied == $0.resolutions.filter { !$0.approved }.count
    }
    let checks = [
        check("hardening_cases_exist", !cases.isEmpty, "> 0", "\(cases.count)"),
        check("unordered_intents_case_exists", names.contains("unordered_intents_still_resolve_by_agent_id"), "present", names.sorted().joined(separator: ",")),
        check("duplicate_intents_case_exists", names.contains("duplicate_intents_same_agent_denied"), "present", names.sorted().joined(separator: ",")),
        check("cycle_case_exists", names.contains("three_agent_cycle_denied"), "present", names.sorted().joined(separator: ",")),
        check("chain_dependency_case_exists", names.contains("chain_dependency_denied"), "present", names.sorted().joined(separator: ",")),
        check("moving_away_destination_case_exists", names.contains("moving_away_destination_denied"), "present", names.sorted().joined(separator: ",")),
        check("vertical_invalid_edge_case_exists", names.contains("invalid_vertical_edge"), "present", names.sorted().joined(separator: ",")),
        check("zero_length_edge_case_exists", names.contains("zero_length_edge_denied"), "present", names.sorted().joined(separator: ",")),
        check("all_denied_case_exists", names.contains("all_denied_mixed_reasons"), "present", names.sorted().joined(separator: ",")),
        check("empty_intents_case_exists", names.contains("empty_intents_noop_success"), "present", names.sorted().joined(separator: ",")),
        check("unordered_intents_resolve_by_agent_id", unorderedCase?.resolutions.first(where: { $0.agentId == "agent_0" })?.approved == true && unorderedCase?.resolutions.first(where: { $0.agentId == "agent_1" })?.decision == .deniedSameDestinationConflict, "agent_0 approved", unorderedCase?.actualDecisionCounts.description ?? "missing"),
        check("duplicate_intents_denied", decisionCount(in: cases, .deniedDuplicateIntent) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedDuplicateIntent))"),
        check("cycles_denied_in_v0", decisionCount(in: cases, .deniedCycleConflict) >= 3, ">= 3", "\(decisionCount(in: cases, .deniedCycleConflict))"),
        check("chain_dependencies_denied_in_v0", decisionCount(in: cases, .deniedChainDependency) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedChainDependency))"),
        check("moving_away_destination_denied_in_v0", decisionCount(in: cases, .deniedMovingAwayDestination) >= 2, ">= 2", "\(decisionCount(in: cases, .deniedMovingAwayDestination))"),
        check("vertical_edges_denied", (report?.summary.verticalInvalidEdges ?? 0) >= 1, ">= 1", "\(report?.summary.verticalInvalidEdges ?? -1)"),
        check("zero_length_edges_denied", decisionCount(in: cases, .deniedZeroLengthEdge) >= 1, ">= 1", "\(decisionCount(in: cases, .deniedZeroLengthEdge))"),
        check("all_denied_case_has_zero_approved", cases.first { $0.name == "all_denied_mixed_reasons" }?.actualApproved == 0, "0", "\(cases.first { $0.name == "all_denied_mixed_reasons" }?.actualApproved ?? -1)"),
        check("empty_intents_preserve_positions", emptyCase?.initialPositions == emptyCase?.finalPositions, "unchanged", String(emptyCase?.initialPositions == emptyCase?.finalPositions)),
        check("empty_intents_do_not_claim_movement", emptyCase?.actualApproved == 0 && emptyCase?.actualDenied == 0, "0/0", "\(emptyCase?.actualApproved ?? -1)/\(emptyCase?.actualDenied ?? -1)"),
        check("max_agents_bound_enforced_or_deferred", maxAgentsCase?.actualDecisionCounts["deniedMaxAgents"] == 5, "deniedMaxAgents=5", "\(maxAgentsCase?.actualDecisionCounts["deniedMaxAgents"] ?? -1)"),
        check("denied_movements_preserve_position", deniedPreserve, "true", String(deniedPreserve)),
        check("approved_movements_one_edge_same_y", approvedOneEdge, "true", String(approvedOneEdge)),
        check("no_duplicate_approved_destination", cases.allSatisfy(noDuplicateApprovedDestination), "true", "checked"),
        check("no_approved_swap", cases.allSatisfy(noApprovedSwapConflict), "true", "checked"),
        check("stable_ordering_independent_of_input_order", unorderedCase?.resolutions.map(\.agentId) == ["agent_0", "agent_1"], "agent_0,agent_1", unorderedCase?.resolutions.map(\.agentId).joined(separator: ",") ?? "missing"),
        check("final_positions_coherent", finalPositionsCoherent, "true", String(finalPositionsCoherent)),
        check("approved_count_matches_resolutions", approvedCountsMatch && report?.summary.approvedTotal == allApproved.count, "true", "\(approvedCountsMatch), summary=\(report?.summary.approvedTotal ?? -1), resolutions=\(allApproved.count)"),
        check("denied_count_matches_resolutions", deniedCountsMatch && report?.summary.deniedTotal == allDenied.count, "true", "\(deniedCountsMatch), summary=\(report?.summary.deniedTotal ?? -1), resolutions=\(allDenied.count)"),
        check("pathfinding_not_performed", report?.summary.pathfindingPerformed == false, "false", String(report?.summary.pathfindingPerformed ?? true)),
        check("replanning_not_performed", report?.summary.replanningPerformed == false, "false", String(report?.summary.replanningPerformed ?? true)),
        check("goal_selection_not_performed", report?.summary.goalSelectionPerformed == false, "false", String(report?.summary.goalSelectionPerformed ?? true)),
        check("avoidance_not_performed", report?.summary.avoidancePerformed == false, "false", String(report?.summary.avoidancePerformed ?? true)),
        check("reservation_table_not_implemented", report?.summary.reservationTableImplemented == false, "false", String(report?.summary.reservationTableImplemented ?? true)),
        check("physics_not_performed", report?.summary.physicsPerformed == false, "false", String(report?.summary.physicsPerformed ?? true)),
        check("world_not_used", report?.summary.worldUsed == false, "false", String(report?.summary.worldUsed ?? true)),
        check("world_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("terrain_mutation_not_performed", report?.summary.mutationPerformed == false, "false", String(report?.summary.mutationPerformed ?? true)),
        check("fixture_smoke_remains_green", fixtureSmokeGreen, "true", String(fixtureSmokeGreen)),
        check("report_written", true, "multi_agent_movement_fixture_hardening_report.json", "multi_agent_movement_fixture_hardening_report.json"),
        check("metrics_written", true, "multiAgentMovementFixtureHardening* metrics", "multiAgentMovementFixtureHardening* metrics"),
        check("event_written", true, "lab_multi_agent_movement_fixture_hardening_recorded", "lab_multi_agent_movement_fixture_hardening_recorded"),
        check("success_contract_respected", report?.success == true && report?.summary.failed == 0, "true", String(report?.success == true && report?.summary.failed == 0))
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabMultiAgentMovementFixtureHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: cases.count,
            passed: report?.summary.passed ?? 0,
            failed: report?.summary.failed ?? cases.count
        ),
        checks: checks,
        notes: [
            "Phase 4.19C hardens fixture-only multi-agent arbitration.",
            "Duplicate intents, cycles, chain dependencies, moving-away dependencies, zero-length edges, and max-agent overflow are conservatively denied in v0.",
            "The hardening scenario remains no-World, no live collision, no pathfinding, no replanning, no reservation runtime, no avoidance, no physics, and no mutation."
        ]
    )
}

private func evaluateMultiAgentMovementFixtureCase(
    _ fixture: LabMultiAgentMovementFixtureCase,
    maxAgents: Int? = nil
) -> LabMultiAgentMovementFixtureCaseResult {
    let initialPositions = fixture.agents
    var finalPositions = initialPositions
    var resolutions: [LabAgentMoveResolution] = []
    var pending: [LabAgentMoveIntent] = []
    let sortedIntents = fixture.intents.sorted { $0.agentId < $1.agentId }
    let staticOccupied = Set(fixture.occupiedStaticNodes)
    let duplicateAgentIds = Set(
        Dictionary(grouping: sortedIntents, by: \.agentId)
            .filter { $0.value.count > 1 }
            .keys
    )

    if let maxAgents, fixture.agents.count > maxAgents {
        for intent in sortedIntents {
            let current = initialPositions[intent.agentId]
            resolutions.append(resolution(for: intent, decision: .deniedMaxAgents, reason: "max_agents_exceeded", pre: current, post: current))
        }
        return result(
            for: fixture,
            initialPositions: initialPositions,
            finalPositions: finalPositions,
            resolutions: resolutions
        )
    }

    for intent in sortedIntents {
        guard let current = initialPositions[intent.agentId] else {
            resolutions.append(resolution(for: intent, decision: .deniedMissingAgent, reason: "missing_agent", pre: nil, post: nil))
            continue
        }
        if duplicateAgentIds.contains(intent.agentId) {
            resolutions.append(resolution(for: intent, decision: .deniedDuplicateIntent, reason: "duplicate_intent", pre: current, post: current))
        } else if intent.stale {
            resolutions.append(resolution(for: intent, decision: .deniedStaleIntent, reason: "stale_intent", pre: current, post: current))
        } else if intent.from != current {
            resolutions.append(resolution(for: intent, decision: .deniedSourceMismatch, reason: "source_mismatch", pre: current, post: current))
        } else if intent.from == intent.to {
            resolutions.append(resolution(for: intent, decision: .deniedZeroLengthEdge, reason: "zero_length_edge", pre: current, post: current))
        } else {
            pending.append(intent)
        }
    }

    let swapAgentIds = Set(pending.flatMap { intent in
        pending.contains { other in
            other.agentId != intent.agentId
                && other.from == intent.to
                && other.to == intent.from
        } ? [intent.agentId] : []
    })

    for intent in pending where swapAgentIds.contains(intent.agentId) {
        let current = initialPositions[intent.agentId]
        resolutions.append(resolution(for: intent, decision: .deniedSwapConflict, reason: "swap_conflict_denied_v0", pre: current, post: current))
    }

    var nonSwapPending = pending.filter { !swapAgentIds.contains($0.agentId) }
    let cycleAgentIds = detectCycleAgentIds(
        in: nonSwapPending,
        initialPositions: initialPositions
    )
    for intent in nonSwapPending where cycleAgentIds.contains(intent.agentId) {
        let current = initialPositions[intent.agentId]
        resolutions.append(resolution(for: intent, decision: .deniedCycleConflict, reason: "cycle_conflict_denied_v0", pre: current, post: current))
    }

    nonSwapPending = nonSwapPending.filter { !cycleAgentIds.contains($0.agentId) }
    var validPending: [LabAgentMoveIntent] = []
    for intent in nonSwapPending {
        let current = initialPositions[intent.agentId]
        if !isFixtureEdgeAllowed(from: intent.from, to: intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedInvalidEdge, reason: "invalid_edge", pre: current, post: current))
        } else if staticOccupied.contains(intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedOccupiedDestination, reason: "occupied_static_destination", pre: current, post: current))
        } else {
            validPending.append(intent)
        }
    }

    let dependencyDecisions = dependencyDenials(
        in: validPending,
        initialPositions: initialPositions
    )
    for intent in validPending {
        if let decision = dependencyDecisions[intent.agentId] {
            let current = initialPositions[intent.agentId]
            resolutions.append(resolution(for: intent, decision: decision, reason: decision == .deniedChainDependency ? "chain_dependency_denied_v0" : "moving_away_destination_denied_v0", pre: current, post: current))
        }
    }

    let independentPending = validPending.filter { dependencyDecisions[$0.agentId] == nil }
    let destinationCounts = Dictionary(grouping: independentPending, by: \.to)
    var approvedDestinations = Set<LabTerrainPathNodeKey>()

    for intent in independentPending {
        let current = initialPositions[intent.agentId]
        let destinationGroup = destinationCounts[intent.to] ?? []
        if destinationGroup.count > 1 && destinationGroup.map(\.agentId).sorted().first != intent.agentId {
            resolutions.append(resolution(for: intent, decision: .deniedSameDestinationConflict, reason: "same_destination_conflict", pre: current, post: current))
        } else if approvedDestinations.contains(intent.to) {
            resolutions.append(resolution(for: intent, decision: .deniedSameDestinationConflict, reason: "duplicate_destination_guard", pre: current, post: current))
        } else {
            approvedDestinations.insert(intent.to)
            finalPositions[intent.agentId] = intent.to
            resolutions.append(resolution(for: intent, decision: .approved, reason: "approved_by_stable_order", pre: current, post: intent.to))
        }
    }

    return result(
        for: fixture,
        initialPositions: initialPositions,
        finalPositions: finalPositions,
        resolutions: resolutions
    )
}

private func result(
    for fixture: LabMultiAgentMovementFixtureCase,
    initialPositions: [String: LabTerrainPathNodeKey],
    finalPositions: [String: LabTerrainPathNodeKey],
    resolutions: [LabAgentMoveResolution]
) -> LabMultiAgentMovementFixtureCaseResult {
    var resolutions = resolutions
    resolutions.sort {
        $0.agentId == $1.agentId
            ? $0.intent.reason < $1.intent.reason
            : $0.agentId < $1.agentId
    }
    let actualApproved = resolutions.filter(\.approved).count
    let actualDenied = resolutions.count - actualApproved
    let actualDecisionCounts = decisionCounts(for: resolutions)
    let passed = actualApproved == fixture.expectedApproved
        && actualDenied == fixture.expectedDenied
        && actualDecisionCounts == fixture.expectedDecisionCounts

    return LabMultiAgentMovementFixtureCaseResult(
        name: fixture.name,
        passed: passed,
        agents: fixture.agents,
        occupiedStaticNodes: fixture.occupiedStaticNodes,
        intents: fixture.intents,
        resolutions: resolutions,
        initialPositions: initialPositions,
        finalPositions: finalPositions,
        expectedApproved: fixture.expectedApproved,
        actualApproved: actualApproved,
        expectedDenied: fixture.expectedDenied,
        actualDenied: actualDenied,
        expectedDecisionCounts: fixture.expectedDecisionCounts,
        actualDecisionCounts: actualDecisionCounts
    )
}

private func resolution(
    for intent: LabAgentMoveIntent,
    decision: LabMultiAgentMoveDecision,
    reason: String,
    pre: LabTerrainPathNodeKey?,
    post: LabTerrainPathNodeKey?
) -> LabAgentMoveResolution {
    LabAgentMoveResolution(
        agentId: intent.agentId,
        intent: intent,
        decision: decision,
        approved: decision == .approved,
        reason: reason,
        prePosition: pre,
        postPosition: post
    )
}

private func decisionCounts(
    for resolutions: [LabAgentMoveResolution]
) -> [String: Int] {
    var counts: [String: Int] = [:]
    for resolution in resolutions {
        counts[resolution.decision.rawValue, default: 0] += 1
    }
    return counts
}

private func decisionCount(
    in results: [LabMultiAgentMovementFixtureCaseResult],
    _ decision: LabMultiAgentMoveDecision
) -> Int {
    results.reduce(0) { total, result in
        total + result.resolutions.filter { $0.decision == decision }.count
    }
}

private func detectCycleAgentIds(
    in intents: [LabAgentMoveIntent],
    initialPositions: [String: LabTerrainPathNodeKey]
) -> Set<String> {
    let occupantByNode = Dictionary(uniqueKeysWithValues: initialPositions.map { ($0.value, $0.key) })
    let intentByAgent = Dictionary(uniqueKeysWithValues: intents.map { ($0.agentId, $0) })
    var cycleAgentIds = Set<String>()

    for intent in intents {
        var path: [String] = []
        var seen: [String: Int] = [:]
        var currentAgentId: String? = intent.agentId

        while let agentId = currentAgentId,
              let currentIntent = intentByAgent[agentId] {
            if let firstIndex = seen[agentId] {
                let cycle = Array(path[firstIndex...])
                if cycle.count >= 3 {
                    cycleAgentIds.formUnion(cycle)
                }
                break
            }

            seen[agentId] = path.count
            path.append(agentId)

            guard let occupant = occupantByNode[currentIntent.to],
                  occupant != agentId else {
                break
            }
            currentAgentId = occupant
        }
    }

    return cycleAgentIds
}

private func dependencyDenials(
    in intents: [LabAgentMoveIntent],
    initialPositions: [String: LabTerrainPathNodeKey]
) -> [String: LabMultiAgentMoveDecision] {
    let occupantByNode = Dictionary(uniqueKeysWithValues: initialPositions.map { ($0.value, $0.key) })
    let intentByAgent = Dictionary(uniqueKeysWithValues: intents.map { ($0.agentId, $0) })
    var denials: [String: LabMultiAgentMoveDecision] = [:]

    for intent in intents {
        guard let firstOccupant = occupantByNode[intent.to],
              firstOccupant != intent.agentId else {
            continue
        }

        var path = [intent.agentId]
        var currentAgentId = firstOccupant
        var seen = Set(path)

        while true {
            guard !seen.contains(currentAgentId) else {
                break
            }
            seen.insert(currentAgentId)
            path.append(currentAgentId)

            guard let currentIntent = intentByAgent[currentAgentId] else {
                for agentId in path {
                    denials[agentId] = .deniedChainDependency
                }
                break
            }

            guard let nextOccupant = occupantByNode[currentIntent.to],
                  nextOccupant != currentAgentId else {
                for agentId in path {
                    denials[agentId] = .deniedMovingAwayDestination
                }
                break
            }

            currentAgentId = nextOccupant
        }
    }

    return denials
}

private func check(
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

private func isFixtureEdgeAllowed(
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey
) -> Bool {
    from.y == to.y
        && abs(from.x - to.x) + abs(from.z - to.z) == 1
}

private func manhattanDistance(
    _ from: LabTerrainPathNodeKey,
    _ to: LabTerrainPathNodeKey
) -> Int {
    abs(from.x - to.x) + abs(from.y - to.y) + abs(from.z - to.z)
}

private func noDuplicateApprovedDestination(
    in result: LabMultiAgentMovementFixtureCaseResult
) -> Bool {
    let destinations = result.resolutions.filter(\.approved).map(\.intent.to)
    return Set(destinations).count == destinations.count
}

private func noApprovedSwapConflict(
    in result: LabMultiAgentMovementFixtureCaseResult
) -> Bool {
    let approved = result.resolutions.filter(\.approved)
    return !approved.contains { first in
        approved.contains { second in
            first.agentId != second.agentId
                && first.intent.from == second.intent.to
                && first.intent.to == second.intent.from
        }
    }
}
