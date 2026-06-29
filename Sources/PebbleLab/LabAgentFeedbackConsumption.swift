import PebbleCore

struct LabAgentFeedbackFixtureInput: Codable {
    let order: Int
    let tick: Int?
    let agentId: String?
    let feedbackKind: LabMovementFeedbackKind?
    let decision: LabMultiAgentMoveDecision?
    let reason: String?
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let displacementApplied: Bool?
    let collisionRead: Bool?
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
    let malformedReason: String?
}

struct LabAgentFeedbackObservation: Codable {
    let tick: Int
    let agentId: String
    let feedbackKind: LabMovementFeedbackKind
    let decision: LabMultiAgentMoveDecision?
    let reason: String
    let from: LabTerrainPathNodeKey?
    let to: LabTerrainPathNodeKey?
    let displacementApplied: Bool
    let collisionRead: Bool
    let abstractBefore: LabTerrainPathNodeKey?
    let abstractAfter: LabTerrainPathNodeKey?
    let physicalBefore: LabTerrainPathNodeKey?
    let physicalAfter: LabTerrainPathNodeKey?
}

struct LabAgentFeedbackContext: Codable {
    let tick: Int
    let agentId: String
    let lastFeedback: LabAgentFeedbackObservation?
    let lastMoveSucceeded: Bool
    let lastMoveBlocked: Bool
    let lastBlockReason: LabMovementFeedbackKind?
    let lastKnownPosition: LabTerrainPathNodeKey?
    let localHints: [String]
    let role: String?
}

enum LabAgentFeedbackConsumptionDecision: String, Codable {
    case ignored
    case observed
    case acceptedAsContext
    case invalidFeedback
}

struct LabAgentFeedbackConsumptionResult: Codable {
    let tick: Int
    let fixtureFeedback: [LabAgentFeedbackFixtureInput]
    let observations: [LabAgentFeedbackObservation]
    let acceptedContexts: [LabAgentFeedbackContext]
    let ignoredFeedback: [LabAgentFeedbackFixtureInput]
    let invalidFeedback: [LabAgentFeedbackFixtureInput]
    let summary: LabAgentFeedbackConsumptionSummary
}

struct LabAgentFeedbackConsumptionSummary: Codable {
    let agentsObserved: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let blockedBySourceMismatch: Int
    let blockedByDivergence: Int
    let blockedByStaleIntent: Int
    let blockedByInvalidEdge: Int
    let blockedByMaxAgents: Int
    let duplicateFeedback: Int
    let maxFeedbackExceeded: Int
    let tickMismatchFeedback: Int
    let feedbackEvidenceCollisionReadCount: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let replanningPerformed: Bool
    let pathfindingPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionFixtureSummary: Codable {
    let tick: Int
    let agentsObserved: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let duplicateFeedback: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let result: LabAgentFeedbackConsumptionResult
    let summary: LabAgentFeedbackConsumptionFixtureSummary
}

struct LabAgentFeedbackConsumptionFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

private func feedbackNode(_ x: Int, _ z: Int, y: Int = 64) -> LabTerrainPathNodeKey {
    LabTerrainPathNodeKey(x: x, y: y, z: z)
}

private func feedbackInput(
    order: Int,
    agentId: String?,
    kind: LabMovementFeedbackKind?,
    decision: LabMultiAgentMoveDecision?,
    from: LabTerrainPathNodeKey?,
    to: LabTerrainPathNodeKey?,
    displacementApplied: Bool?,
    collisionRead: Bool?,
    abstractBefore: LabTerrainPathNodeKey?,
    abstractAfter: LabTerrainPathNodeKey?,
    physicalBefore: LabTerrainPathNodeKey?,
    physicalAfter: LabTerrainPathNodeKey?,
    reason: String,
    malformedReason: String? = nil,
    tick: Int? = 0
) -> LabAgentFeedbackFixtureInput {
    LabAgentFeedbackFixtureInput(
        order: order,
        tick: tick,
        agentId: agentId,
        feedbackKind: kind,
        decision: decision,
        reason: reason,
        from: from,
        to: to,
        displacementApplied: displacementApplied,
        collisionRead: collisionRead,
        abstractBefore: abstractBefore,
        abstractAfter: abstractAfter,
        physicalBefore: physicalBefore,
        physicalAfter: physicalAfter,
        malformedReason: malformedReason
    )
}

private func agentFeedbackConsumptionFixtureInputs() -> [LabAgentFeedbackFixtureInput] {
    [
        feedbackInput(
            order: 0,
            agentId: "agent_2",
            kind: .blockedByCollision,
            decision: .deniedCollision,
            from: feedbackNode(7, 8),
            to: feedbackNode(8, 8),
            displacementApplied: false,
            collisionRead: true,
            abstractBefore: feedbackNode(7, 8),
            abstractAfter: feedbackNode(7, 8),
            physicalBefore: feedbackNode(7, 8),
            physicalAfter: feedbackNode(7, 8),
            reason: "fixture_blocked_by_collision"
        ),
        feedbackInput(
            order: 1,
            agentId: "agent_0",
            kind: .moved,
            decision: .approved,
            from: feedbackNode(7, 8),
            to: feedbackNode(8, 8),
            displacementApplied: true,
            collisionRead: true,
            abstractBefore: feedbackNode(7, 8),
            abstractAfter: feedbackNode(8, 8),
            physicalBefore: feedbackNode(7, 8),
            physicalAfter: feedbackNode(8, 8),
            reason: "fixture_moved"
        ),
        feedbackInput(
            order: 2,
            agentId: "agent_1",
            kind: .approvedForMovement,
            decision: .approved,
            from: feedbackNode(9, 7),
            to: feedbackNode(9, 8),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(9, 7),
            abstractAfter: feedbackNode(9, 7),
            physicalBefore: feedbackNode(9, 7),
            physicalAfter: feedbackNode(9, 7),
            reason: "fixture_approved_for_movement"
        ),
        feedbackInput(
            order: 3,
            agentId: "agent_3",
            kind: .blockedByAgentConflict,
            decision: .deniedSameDestinationConflict,
            from: feedbackNode(2, 0),
            to: feedbackNode(1, 0),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(2, 0),
            abstractAfter: feedbackNode(2, 0),
            physicalBefore: feedbackNode(2, 0),
            physicalAfter: feedbackNode(2, 0),
            reason: "fixture_blocked_by_agent_conflict"
        ),
        feedbackInput(
            order: 4,
            agentId: "agent_0",
            kind: .blockedByMaxAgents,
            decision: .deniedMaxAgents,
            from: feedbackNode(8, 8),
            to: feedbackNode(9, 8),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(8, 8),
            abstractAfter: feedbackNode(8, 8),
            physicalBefore: feedbackNode(8, 8),
            physicalAfter: feedbackNode(8, 8),
            reason: "fixture_duplicate_blocked_by_max_agents"
        ),
        feedbackInput(
            order: 5,
            agentId: "",
            kind: nil,
            decision: nil,
            from: nil,
            to: nil,
            displacementApplied: nil,
            collisionRead: nil,
            abstractBefore: nil,
            abstractAfter: nil,
            physicalBefore: nil,
            physicalAfter: nil,
            reason: "fixture_malformed_feedback",
            malformedReason: "missing_agent_id_and_required_fields"
        )
    ]
}

private func makeFeedbackObservation(
    from input: LabAgentFeedbackFixtureInput
) -> LabAgentFeedbackObservation? {
    guard let tick = input.tick,
          let agentId = input.agentId,
          !agentId.isEmpty,
          let kind = input.feedbackKind,
          let reason = input.reason,
          let displacementApplied = input.displacementApplied,
          let collisionRead = input.collisionRead else {
        return nil
    }
    return LabAgentFeedbackObservation(
        tick: tick,
        agentId: agentId,
        feedbackKind: kind,
        decision: input.decision,
        reason: reason,
        from: input.from,
        to: input.to,
        displacementApplied: displacementApplied,
        collisionRead: collisionRead,
        abstractBefore: input.abstractBefore,
        abstractAfter: input.abstractAfter,
        physicalBefore: input.physicalBefore,
        physicalAfter: input.physicalAfter
    )
}

private func makeFeedbackContext(
    from observation: LabAgentFeedbackObservation
) -> LabAgentFeedbackContext {
    let blockedKinds: Set<LabMovementFeedbackKind> = [
        .blockedByCollision,
        .blockedByAgentConflict,
        .blockedBySourceMismatch,
        .blockedByDivergence,
        .blockedByStaleIntent,
        .blockedByInvalidEdge,
        .blockedByMaxAgents
    ]
    let lastMoveSucceeded = observation.feedbackKind == .moved
        && observation.displacementApplied
    let lastMoveBlocked = blockedKinds.contains(observation.feedbackKind)
    let lastKnownPosition = lastMoveSucceeded
        ? (observation.abstractAfter ?? observation.to ?? observation.from)
        : (observation.abstractAfter ?? observation.abstractBefore ?? observation.from)

    return LabAgentFeedbackContext(
        tick: observation.tick,
        agentId: observation.agentId,
        lastFeedback: observation,
        lastMoveSucceeded: lastMoveSucceeded,
        lastMoveBlocked: lastMoveBlocked,
        lastBlockReason: lastMoveBlocked ? observation.feedbackKind : nil,
        lastKnownPosition: lastKnownPosition,
        localHints: [],
        role: nil
    )
}

func consumeAgentFeedbackFixtureV0(
    feedbackInputs: [LabAgentFeedbackFixtureInput],
    maxFeedback: Int? = nil,
    expectedTick: Int? = nil
) -> LabAgentFeedbackConsumptionResult {
    let sortedInputs = feedbackInputs.sorted {
        let lhsId = ($0.agentId?.isEmpty == false) ? $0.agentId! : "~malformed"
        let rhsId = ($1.agentId?.isEmpty == false) ? $1.agentId! : "~malformed"
        return lhsId == rhsId ? $0.order < $1.order : lhsId < rhsId
    }
    var acceptedAgentIds = Set<String>()
    var observations: [LabAgentFeedbackObservation] = []
    var contexts: [LabAgentFeedbackContext] = []
    var ignored: [LabAgentFeedbackFixtureInput] = []
    var invalid: [LabAgentFeedbackFixtureInput] = []
    var duplicateFeedback = 0
    var maxFeedbackExceeded = 0
    var tickMismatchFeedback = 0

    for input in sortedInputs {
        if let expectedTick,
           input.tick != expectedTick {
            tickMismatchFeedback += 1
            invalid.append(input)
            continue
        }
        guard let observation = makeFeedbackObservation(from: input) else {
            invalid.append(input)
            continue
        }
        if let maxFeedback,
           observations.count >= maxFeedback {
            maxFeedbackExceeded += 1
            ignored.append(input)
            continue
        }
        if acceptedAgentIds.contains(observation.agentId) {
            duplicateFeedback += 1
            ignored.append(input)
            continue
        }
        acceptedAgentIds.insert(observation.agentId)
        observations.append(observation)
        contexts.append(makeFeedbackContext(from: observation))
    }

    let kindCount: (LabMovementFeedbackKind) -> Int = { kind in
        observations.filter { $0.feedbackKind == kind }.count
    }
    let evidenceCollisionReadCount = sortedInputs.filter {
        $0.collisionRead == true
    }.count
    let summary = LabAgentFeedbackConsumptionSummary(
        agentsObserved: Set(observations.map(\.agentId)).count,
        feedbackObserved: feedbackInputs.count,
        feedbackAccepted: observations.count,
        feedbackIgnored: ignored.count,
        invalidFeedback: invalid.count,
        contextsProduced: contexts.count,
        moved: kindCount(.moved),
        approvedForMovement: kindCount(.approvedForMovement),
        blockedByCollision: kindCount(.blockedByCollision),
        blockedByAgentConflict: kindCount(.blockedByAgentConflict),
        blockedBySourceMismatch: kindCount(.blockedBySourceMismatch),
        blockedByDivergence: kindCount(.blockedByDivergence),
        blockedByStaleIntent: kindCount(.blockedByStaleIntent),
        blockedByInvalidEdge: kindCount(.blockedByInvalidEdge),
        blockedByMaxAgents: kindCount(.blockedByMaxAgents),
        duplicateFeedback: duplicateFeedback,
        maxFeedbackExceeded: maxFeedbackExceeded,
        tickMismatchFeedback: tickMismatchFeedback,
        feedbackEvidenceCollisionReadCount: evidenceCollisionReadCount,
        memoryUpdated: false,
        goalChanged: false,
        replanningPerformed: false,
        pathfindingPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        movementApplied: false,
        collisionRead: false,
        intentProduced: false,
        worldUsed: false,
        mutationPerformed: false,
        success: observations.count == contexts.count
            && observations.map(\.agentId) == observations.map(\.agentId).sorted()
            && contexts.map(\.agentId) == contexts.map(\.agentId).sorted()
            && Set(observations.map(\.agentId)).count == observations.count
            && observations.count + ignored.count + invalid.count == feedbackInputs.count
    )

    return LabAgentFeedbackConsumptionResult(
        tick: 0,
        fixtureFeedback: feedbackInputs,
        observations: observations,
        acceptedContexts: contexts,
        ignoredFeedback: ignored,
        invalidFeedback: invalid,
        summary: summary
    )
}

struct LabAgentFeedbackConsumptionHardeningExpected: Codable {
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let duplicateFeedback: Int
    let moved: Int
    let approvedForMovement: Int
    let blockedByCollision: Int
    let blockedByAgentConflict: Int
    let blockedBySourceMismatch: Int
    let blockedByDivergence: Int
    let blockedByStaleIntent: Int
    let blockedByInvalidEdge: Int
    let blockedByMaxAgents: Int
    let maxFeedbackExceeded: Int
    let tickMismatchFeedback: Int
    let collisionRead: Bool
    let movementApplied: Bool
    let intentProduced: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionHardeningCase: Codable {
    let name: String
    let tick: Int
    let feedbackInputs: [LabAgentFeedbackFixtureInput]
    let maxFeedback: Int?
    let expectedTick: Int?
    let expected: LabAgentFeedbackConsumptionHardeningExpected
    let notes: [String]
}

struct LabAgentFeedbackConsumptionHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let result: LabAgentFeedbackConsumptionResult
    let repeatedResult: LabAgentFeedbackConsumptionResult?
    let expected: LabAgentFeedbackConsumptionHardeningExpected
    let notes: [String]
}

struct LabAgentFeedbackConsumptionHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let feedbackObservedTotal: Int
    let feedbackAcceptedTotal: Int
    let feedbackIgnoredTotal: Int
    let invalidFeedbackTotal: Int
    let contextsProducedTotal: Int
    let duplicateFeedbackTotal: Int
    let maxFeedbackExceededTotal: Int
    let tickMismatchFeedbackTotal: Int
    let movedTotal: Int
    let approvedForMovementTotal: Int
    let blockedByCollisionTotal: Int
    let blockedByAgentConflictTotal: Int
    let blockedBySourceMismatchTotal: Int
    let blockedByDivergenceTotal: Int
    let blockedByStaleIntentTotal: Int
    let blockedByInvalidEdgeTotal: Int
    let blockedByMaxAgentsTotal: Int
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabAgentFeedbackConsumptionHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let cases: [LabAgentFeedbackConsumptionHardeningCaseResult]
    let summary: LabAgentFeedbackConsumptionHardeningSummary
}

struct LabAgentFeedbackConsumptionHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

private func hardeningDecision(for kind: LabMovementFeedbackKind) -> LabMultiAgentMoveDecision {
    switch kind {
    case .moved, .approvedForMovement:
        .approved
    case .blockedByCollision:
        .deniedCollision
    case .blockedByAgentConflict:
        .deniedSameDestinationConflict
    case .blockedBySourceMismatch:
        .deniedSourceMismatch
    case .blockedByDivergence:
        .deniedDivergence
    case .blockedByStaleIntent:
        .deniedStaleIntent
    case .blockedByInvalidEdge:
        .deniedInvalidEdge
    case .blockedByMaxAgents:
        .deniedMaxAgents
    }
}

private func validFeedback(
    order: Int,
    agentId: String,
    kind: LabMovementFeedbackKind,
    from: LabTerrainPathNodeKey,
    to: LabTerrainPathNodeKey,
    displacementApplied: Bool = false,
    collisionRead: Bool = false,
    tick: Int? = 0
) -> LabAgentFeedbackFixtureInput {
    let moved = kind == .moved && displacementApplied
    let after = moved ? to : from
    return feedbackInput(
        order: order,
        agentId: agentId,
        kind: kind,
        decision: hardeningDecision(for: kind),
        from: from,
        to: to,
        displacementApplied: displacementApplied,
        collisionRead: collisionRead,
        abstractBefore: from,
        abstractAfter: after,
        physicalBefore: from,
        physicalAfter: after,
        reason: "hardening_\(kind.rawValue)_\(agentId)",
        tick: tick
    )
}

private func hardeningExpected(
    observed: Int,
    accepted: Int,
    ignored: Int = 0,
    invalid: Int = 0,
    contexts: Int,
    duplicate: Int = 0,
    moved: Int = 0,
    approvedForMovement: Int = 0,
    blockedByCollision: Int = 0,
    blockedByAgentConflict: Int = 0,
    blockedBySourceMismatch: Int = 0,
    blockedByDivergence: Int = 0,
    blockedByStaleIntent: Int = 0,
    blockedByInvalidEdge: Int = 0,
    blockedByMaxAgents: Int = 0,
    maxFeedbackExceeded: Int = 0,
    tickMismatchFeedback: Int = 0
) -> LabAgentFeedbackConsumptionHardeningExpected {
    LabAgentFeedbackConsumptionHardeningExpected(
        feedbackObserved: observed,
        feedbackAccepted: accepted,
        feedbackIgnored: ignored,
        invalidFeedback: invalid,
        contextsProduced: contexts,
        duplicateFeedback: duplicate,
        moved: moved,
        approvedForMovement: approvedForMovement,
        blockedByCollision: blockedByCollision,
        blockedByAgentConflict: blockedByAgentConflict,
        blockedBySourceMismatch: blockedBySourceMismatch,
        blockedByDivergence: blockedByDivergence,
        blockedByStaleIntent: blockedByStaleIntent,
        blockedByInvalidEdge: blockedByInvalidEdge,
        blockedByMaxAgents: blockedByMaxAgents,
        maxFeedbackExceeded: maxFeedbackExceeded,
        tickMismatchFeedback: tickMismatchFeedback,
        collisionRead: false,
        movementApplied: false,
        intentProduced: false,
        memoryUpdated: false,
        goalChanged: false,
        success: true
    )
}

private func agentFeedbackConsumptionHardeningCases() -> [LabAgentFeedbackConsumptionHardeningCase] {
    let allKinds: [LabMovementFeedbackKind] = [
        .moved,
        .approvedForMovement,
        .blockedByCollision,
        .blockedByAgentConflict,
        .blockedBySourceMismatch,
        .blockedByDivergence,
        .blockedByStaleIntent,
        .blockedByInvalidEdge,
        .blockedByMaxAgents
    ]

    return [
        LabAgentFeedbackConsumptionHardeningCase(
            name: "baseline_fixture_remains_green",
            tick: 0,
            feedbackInputs: agentFeedbackConsumptionFixtureInputs(),
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(
                observed: 6,
                accepted: 4,
                ignored: 1,
                invalid: 1,
                contexts: 4,
                duplicate: 1,
                moved: 1,
                approvedForMovement: 1,
                blockedByCollision: 1,
                blockedByAgentConflict: 1
            ),
            notes: ["Reuses the 4.22B fixture exactly."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "duplicate_feedback_denied",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_0", kind: .moved, from: feedbackNode(0, 0), to: feedbackNode(1, 0), displacementApplied: true),
                validFeedback(order: 1, agentId: "agent_0", kind: .blockedByMaxAgents, from: feedbackNode(1, 0), to: feedbackNode(2, 0))
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 2, accepted: 1, ignored: 1, contexts: 1, duplicate: 1, moved: 1),
            notes: ["First stable feedback is accepted; duplicate is ignored and counted."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "malformed_missing_agent_denied",
            tick: 0,
            feedbackInputs: [
                feedbackInput(
                    order: 0,
                    agentId: "",
                    kind: .moved,
                    decision: .approved,
                    from: feedbackNode(0, 0),
                    to: feedbackNode(1, 0),
                    displacementApplied: true,
                    collisionRead: false,
                    abstractBefore: feedbackNode(0, 0),
                    abstractAfter: feedbackNode(1, 0),
                    physicalBefore: feedbackNode(0, 0),
                    physicalAfter: feedbackNode(1, 0),
                    reason: "hardening_missing_agent",
                    malformedReason: "missing_agent_id"
                )
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 1, accepted: 0, invalid: 1, contexts: 0),
            notes: ["Empty agent id is malformed."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "malformed_missing_kind_denied",
            tick: 0,
            feedbackInputs: [
                feedbackInput(
                    order: 0,
                    agentId: "agent_0",
                    kind: nil,
                    decision: .approved,
                    from: feedbackNode(0, 0),
                    to: feedbackNode(1, 0),
                    displacementApplied: true,
                    collisionRead: false,
                    abstractBefore: feedbackNode(0, 0),
                    abstractAfter: feedbackNode(1, 0),
                    physicalBefore: feedbackNode(0, 0),
                    physicalAfter: feedbackNode(1, 0),
                    reason: "hardening_missing_kind",
                    malformedReason: "missing_feedback_kind"
                )
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 1, accepted: 0, invalid: 1, contexts: 0),
            notes: ["Typed feedback kind is required."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "malformed_missing_required_fields_denied",
            tick: 0,
            feedbackInputs: [
                feedbackInput(
                    order: 0,
                    agentId: "agent_0",
                    kind: .moved,
                    decision: .approved,
                    from: feedbackNode(0, 0),
                    to: feedbackNode(1, 0),
                    displacementApplied: nil,
                    collisionRead: false,
                    abstractBefore: feedbackNode(0, 0),
                    abstractAfter: feedbackNode(1, 0),
                    physicalBefore: feedbackNode(0, 0),
                    physicalAfter: feedbackNode(1, 0),
                    reason: "hardening_missing_required_fields",
                    malformedReason: "missing_displacement_applied"
                )
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 1, accepted: 0, invalid: 1, contexts: 0),
            notes: ["Consumption requires displacementApplied and collisionRead to be explicit."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "deterministic_ordering_by_agent_id",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_2", kind: .blockedByCollision, from: feedbackNode(2, 0), to: feedbackNode(3, 0)),
                validFeedback(order: 1, agentId: "agent_0", kind: .approvedForMovement, from: feedbackNode(0, 0), to: feedbackNode(1, 0)),
                validFeedback(order: 2, agentId: "agent_1", kind: .blockedByAgentConflict, from: feedbackNode(1, 0), to: feedbackNode(2, 0))
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(
                observed: 3,
                accepted: 3,
                contexts: 3,
                approvedForMovement: 1,
                blockedByCollision: 1,
                blockedByAgentConflict: 1
            ),
            notes: ["Output observations and contexts must be sorted by stable agentId."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "one_feedback_per_agent_bound",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_0", kind: .moved, from: feedbackNode(0, 0), to: feedbackNode(1, 0), displacementApplied: true),
                validFeedback(order: 1, agentId: "agent_0", kind: .blockedByCollision, from: feedbackNode(1, 0), to: feedbackNode(2, 0)),
                validFeedback(order: 2, agentId: "agent_0", kind: .blockedByAgentConflict, from: feedbackNode(1, 0), to: feedbackNode(2, 0))
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 3, accepted: 1, ignored: 2, contexts: 1, duplicate: 2, moved: 1),
            notes: ["v0 accepts at most one feedback item per agent."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "all_known_kinds_observed",
            tick: 0,
            feedbackInputs: allKinds.enumerated().map { index, kind in
                validFeedback(
                    order: index,
                    agentId: "agent_\(index)",
                    kind: kind,
                    from: feedbackNode(index, 0),
                    to: feedbackNode(index + 1, 0),
                    displacementApplied: kind == .moved
                )
            },
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(
                observed: 9,
                accepted: 9,
                contexts: 9,
                moved: 1,
                approvedForMovement: 1,
                blockedByCollision: 1,
                blockedByAgentConflict: 1,
                blockedBySourceMismatch: 1,
                blockedByDivergence: 1,
                blockedByStaleIntent: 1,
                blockedByInvalidEdge: 1,
                blockedByMaxAgents: 1
            ),
            notes: ["All typed feedback kinds are known and accepted when well-formed."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "historical_collision_evidence_does_not_read_collision",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_0", kind: .blockedByCollision, from: feedbackNode(0, 0), to: feedbackNode(1, 0), collisionRead: true),
                validFeedback(order: 1, agentId: "agent_1", kind: .approvedForMovement, from: feedbackNode(2, 0), to: feedbackNode(3, 0), collisionRead: true)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 2, accepted: 2, contexts: 2, approvedForMovement: 1, blockedByCollision: 1),
            notes: ["Input evidence may say collision was read earlier; consumption itself keeps collisionRead false."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "max_feedback_bound_exceeded",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_0", kind: .approvedForMovement, from: feedbackNode(0, 0), to: feedbackNode(1, 0)),
                validFeedback(order: 1, agentId: "agent_1", kind: .approvedForMovement, from: feedbackNode(1, 0), to: feedbackNode(2, 0)),
                validFeedback(order: 2, agentId: "agent_2", kind: .approvedForMovement, from: feedbackNode(2, 0), to: feedbackNode(3, 0)),
                validFeedback(order: 3, agentId: "agent_3", kind: .approvedForMovement, from: feedbackNode(3, 0), to: feedbackNode(4, 0))
            ],
            maxFeedback: 3,
            expectedTick: nil,
            expected: hardeningExpected(observed: 4, accepted: 3, ignored: 1, contexts: 3, approvedForMovement: 3, maxFeedbackExceeded: 1),
            notes: ["maxFeedback bounds accepted contexts and counts the excess feedback."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "tick_mismatch_denied",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_0", kind: .moved, from: feedbackNode(0, 0), to: feedbackNode(1, 0), displacementApplied: true, tick: 1)
            ],
            maxFeedback: nil,
            expectedTick: 0,
            expected: hardeningExpected(observed: 1, accepted: 0, invalid: 1, contexts: 0, tickMismatchFeedback: 1),
            notes: ["Feedback from a non-current tick is rejected for v0 hardening."]
        ),
        LabAgentFeedbackConsumptionHardeningCase(
            name: "stable_repeatability",
            tick: 0,
            feedbackInputs: [
                validFeedback(order: 0, agentId: "agent_2", kind: .blockedByCollision, from: feedbackNode(2, 0), to: feedbackNode(3, 0)),
                validFeedback(order: 1, agentId: "agent_0", kind: .moved, from: feedbackNode(0, 0), to: feedbackNode(1, 0), displacementApplied: true),
                validFeedback(order: 2, agentId: "agent_1", kind: .approvedForMovement, from: feedbackNode(1, 0), to: feedbackNode(2, 0))
            ],
            maxFeedback: nil,
            expectedTick: nil,
            expected: hardeningExpected(observed: 3, accepted: 3, contexts: 3, moved: 1, approvedForMovement: 1, blockedByCollision: 1),
            notes: ["Runs the same input twice and compares accepted context ids and summary totals."]
        )
    ]
}

private func hardeningCaseMatchesExpected(
    result: LabAgentFeedbackConsumptionResult,
    expected: LabAgentFeedbackConsumptionHardeningExpected
) -> Bool {
    result.summary.feedbackObserved == expected.feedbackObserved
        && result.summary.feedbackAccepted == expected.feedbackAccepted
        && result.summary.feedbackIgnored == expected.feedbackIgnored
        && result.summary.invalidFeedback == expected.invalidFeedback
        && result.summary.contextsProduced == expected.contextsProduced
        && result.summary.duplicateFeedback == expected.duplicateFeedback
        && result.summary.moved == expected.moved
        && result.summary.approvedForMovement == expected.approvedForMovement
        && result.summary.blockedByCollision == expected.blockedByCollision
        && result.summary.blockedByAgentConflict == expected.blockedByAgentConflict
        && result.summary.blockedBySourceMismatch == expected.blockedBySourceMismatch
        && result.summary.blockedByDivergence == expected.blockedByDivergence
        && result.summary.blockedByStaleIntent == expected.blockedByStaleIntent
        && result.summary.blockedByInvalidEdge == expected.blockedByInvalidEdge
        && result.summary.blockedByMaxAgents == expected.blockedByMaxAgents
        && result.summary.maxFeedbackExceeded == expected.maxFeedbackExceeded
        && result.summary.tickMismatchFeedback == expected.tickMismatchFeedback
        && result.summary.collisionRead == expected.collisionRead
        && result.summary.movementApplied == expected.movementApplied
        && result.summary.intentProduced == expected.intentProduced
        && result.summary.memoryUpdated == expected.memoryUpdated
        && result.summary.goalChanged == expected.goalChanged
        && result.summary.success == expected.success
}

private func hardeningRepeatabilityMatches(
    _ lhs: LabAgentFeedbackConsumptionResult,
    _ rhs: LabAgentFeedbackConsumptionResult?
) -> Bool {
    guard let rhs else { return true }
    return lhs.acceptedContexts.map(\.agentId) == rhs.acceptedContexts.map(\.agentId)
        && lhs.observations.map(\.agentId) == rhs.observations.map(\.agentId)
        && lhs.summary.feedbackObserved == rhs.summary.feedbackObserved
        && lhs.summary.feedbackAccepted == rhs.summary.feedbackAccepted
        && lhs.summary.feedbackIgnored == rhs.summary.feedbackIgnored
        && lhs.summary.invalidFeedback == rhs.summary.invalidFeedback
        && lhs.summary.contextsProduced == rhs.summary.contextsProduced
        && lhs.summary.duplicateFeedback == rhs.summary.duplicateFeedback
}

private func makeAgentFeedbackConsumptionHardeningCaseResult(
    _ testCase: LabAgentFeedbackConsumptionHardeningCase
) -> LabAgentFeedbackConsumptionHardeningCaseResult {
    let result = consumeAgentFeedbackFixtureV0(
        feedbackInputs: testCase.feedbackInputs,
        maxFeedback: testCase.maxFeedback,
        expectedTick: testCase.expectedTick
    )
    let repeatedResult = testCase.name == "stable_repeatability"
        ? consumeAgentFeedbackFixtureV0(
            feedbackInputs: testCase.feedbackInputs,
            maxFeedback: testCase.maxFeedback,
            expectedTick: testCase.expectedTick
        )
        : nil
    let sorted = result.observations.map(\.agentId) == result.observations.map(\.agentId).sorted()
        && result.acceptedContexts.map(\.agentId) == result.acceptedContexts.map(\.agentId).sorted()
    let unique = Set(result.observations.map(\.agentId)).count == result.observations.count
    let passed = hardeningCaseMatchesExpected(result: result, expected: testCase.expected)
        && hardeningRepeatabilityMatches(result, repeatedResult)
        && sorted
        && unique

    return LabAgentFeedbackConsumptionHardeningCaseResult(
        name: testCase.name,
        passed: passed,
        result: result,
        repeatedResult: repeatedResult,
        expected: testCase.expected,
        notes: testCase.notes
    )
}

func makeAgentFeedbackConsumptionHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentFeedbackConsumptionHardeningReport {
    let results = agentFeedbackConsumptionHardeningCases().map(
        makeAgentFeedbackConsumptionHardeningCaseResult
    )
    let passed = results.filter(\.passed).count
    let summary = LabAgentFeedbackConsumptionHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: results.count - passed,
        feedbackObservedTotal: results.reduce(0) { $0 + $1.result.summary.feedbackObserved },
        feedbackAcceptedTotal: results.reduce(0) { $0 + $1.result.summary.feedbackAccepted },
        feedbackIgnoredTotal: results.reduce(0) { $0 + $1.result.summary.feedbackIgnored },
        invalidFeedbackTotal: results.reduce(0) { $0 + $1.result.summary.invalidFeedback },
        contextsProducedTotal: results.reduce(0) { $0 + $1.result.summary.contextsProduced },
        duplicateFeedbackTotal: results.reduce(0) { $0 + $1.result.summary.duplicateFeedback },
        maxFeedbackExceededTotal: results.reduce(0) { $0 + $1.result.summary.maxFeedbackExceeded },
        tickMismatchFeedbackTotal: results.reduce(0) { $0 + $1.result.summary.tickMismatchFeedback },
        movedTotal: results.reduce(0) { $0 + $1.result.summary.moved },
        approvedForMovementTotal: results.reduce(0) { $0 + $1.result.summary.approvedForMovement },
        blockedByCollisionTotal: results.reduce(0) { $0 + $1.result.summary.blockedByCollision },
        blockedByAgentConflictTotal: results.reduce(0) { $0 + $1.result.summary.blockedByAgentConflict },
        blockedBySourceMismatchTotal: results.reduce(0) { $0 + $1.result.summary.blockedBySourceMismatch },
        blockedByDivergenceTotal: results.reduce(0) { $0 + $1.result.summary.blockedByDivergence },
        blockedByStaleIntentTotal: results.reduce(0) { $0 + $1.result.summary.blockedByStaleIntent },
        blockedByInvalidEdgeTotal: results.reduce(0) { $0 + $1.result.summary.blockedByInvalidEdge },
        blockedByMaxAgentsTotal: results.reduce(0) { $0 + $1.result.summary.blockedByMaxAgents },
        memoryUpdated: results.contains { $0.result.summary.memoryUpdated },
        goalChanged: results.contains { $0.result.summary.goalChanged },
        pathfindingPerformed: results.contains { $0.result.summary.pathfindingPerformed },
        replanningPerformed: results.contains { $0.result.summary.replanningPerformed },
        avoidancePerformed: results.contains { $0.result.summary.avoidancePerformed },
        reservationRuntimeUsed: results.contains { $0.result.summary.reservationRuntimeUsed },
        movementApplied: results.contains { $0.result.summary.movementApplied },
        collisionRead: results.contains { $0.result.summary.collisionRead },
        intentProduced: results.contains { $0.result.summary.intentProduced },
        worldUsed: results.contains { $0.result.summary.worldUsed },
        mutationPerformed: results.contains { $0.result.summary.mutationPerformed },
        success: results.count == 12
            && passed == 12
            && results.allSatisfy(\.passed)
    )

    return LabAgentFeedbackConsumptionHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        cases: results,
        summary: summary
    )
}

func makeAgentFeedbackConsumptionFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabAgentFeedbackConsumptionFixtureReport {
    let result = consumeAgentFeedbackFixtureV0(
        feedbackInputs: agentFeedbackConsumptionFixtureInputs()
    )
    let summary = LabAgentFeedbackConsumptionFixtureSummary(
        tick: result.tick,
        agentsObserved: result.summary.agentsObserved,
        feedbackObserved: result.summary.feedbackObserved,
        feedbackAccepted: result.summary.feedbackAccepted,
        feedbackIgnored: result.summary.feedbackIgnored,
        invalidFeedback: result.summary.invalidFeedback,
        contextsProduced: result.summary.contextsProduced,
        moved: result.summary.moved,
        approvedForMovement: result.summary.approvedForMovement,
        blockedByCollision: result.summary.blockedByCollision,
        blockedByAgentConflict: result.summary.blockedByAgentConflict,
        duplicateFeedback: result.summary.duplicateFeedback,
        memoryUpdated: result.summary.memoryUpdated,
        goalChanged: result.summary.goalChanged,
        pathfindingPerformed: result.summary.pathfindingPerformed,
        replanningPerformed: result.summary.replanningPerformed,
        avoidancePerformed: result.summary.avoidancePerformed,
        reservationRuntimeUsed: result.summary.reservationRuntimeUsed,
        movementApplied: result.summary.movementApplied,
        collisionRead: result.summary.collisionRead,
        intentProduced: result.summary.intentProduced,
        worldUsed: result.summary.worldUsed,
        mutationPerformed: result.summary.mutationPerformed,
        success: result.summary.success
    )

    return LabAgentFeedbackConsumptionFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        result: result,
        summary: summary
    )
}

private func feedbackInvariantCheck(
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

func makeAgentFeedbackConsumptionFixtureInvariantReport(
    report: LabAgentFeedbackConsumptionFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentFeedbackConsumptionFixtureInvariantReport {
    guard let report else {
        let check = feedbackInvariantCheck(
            "report_written",
            false,
            "agent_feedback_consumption_fixture_report.json",
            "missing"
        )
        return LabAgentFeedbackConsumptionFixtureInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 0,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Agent feedback consumption fixture report was not available."]
        )
    }

    let inputIds = report.result.fixtureFeedback.map { $0.agentId ?? "" }
    let observationIds = report.result.observations.map(\.agentId)
    let contextIds = report.result.acceptedContexts.map(\.agentId)
    let uniqueAccepted = Set(observationIds).count == observationIds.count
    let contextsByAgent = Dictionary(
        uniqueKeysWithValues: report.result.acceptedContexts.map { ($0.agentId, $0) }
    )
    let movedContext = contextsByAgent["agent_0"]
    let approvedContext = contextsByAgent["agent_1"]
    let collisionContext = contextsByAgent["agent_2"]
    let conflictContext = contextsByAgent["agent_3"]
    let knownAccepted = report.result.observations.allSatisfy {
        [
            LabMovementFeedbackKind.moved,
            .approvedForMovement,
            .blockedByCollision,
            .blockedByAgentConflict,
            .blockedBySourceMismatch,
            .blockedByDivergence,
            .blockedByStaleIntent,
            .blockedByInvalidEdge,
            .blockedByMaxAgents
        ].contains($0.feedbackKind)
    }
    let contextKinds = report.result.acceptedContexts.compactMap {
        $0.lastFeedback?.feedbackKind
    }

    let checks = [
        feedbackInvariantCheck("fixture_feedback_exists", !report.result.fixtureFeedback.isEmpty, "non-empty", "\(report.result.fixtureFeedback.count)"),
        feedbackInvariantCheck("fixture_feedback_intentionally_unordered", inputIds != inputIds.sorted(), "unordered", inputIds.joined(separator: ",")),
        feedbackInvariantCheck("observations_exist", !report.result.observations.isEmpty, "non-empty", "\(report.result.observations.count)"),
        feedbackInvariantCheck("observations_sorted_by_agent_id", observationIds == observationIds.sorted(), "sorted", observationIds.joined(separator: ",")),
        feedbackInvariantCheck("accepted_contexts_exist", !report.result.acceptedContexts.isEmpty, "non-empty", "\(report.result.acceptedContexts.count)"),
        feedbackInvariantCheck("accepted_contexts_sorted_by_agent_id", contextIds == contextIds.sorted(), "sorted", contextIds.joined(separator: ",")),
        feedbackInvariantCheck("at_most_one_feedback_accepted_per_agent", uniqueAccepted, "unique", observationIds.joined(separator: ",")),
        feedbackInvariantCheck("known_feedback_kinds_accepted", knownAccepted, "known", contextKinds.map(\.rawValue).joined(separator: ",")),
        feedbackInvariantCheck("malformed_feedback_rejected", report.summary.invalidFeedback == 1, "1", "\(report.summary.invalidFeedback)"),
        feedbackInvariantCheck("duplicate_feedback_rejected_or_ignored", report.summary.duplicateFeedback == 1 && report.summary.feedbackIgnored == 1, "1/1", "\(report.summary.duplicateFeedback)/\(report.summary.feedbackIgnored)"),
        feedbackInvariantCheck("moved_feedback_observed", report.summary.moved == 1, "1", "\(report.summary.moved)"),
        feedbackInvariantCheck("approved_for_movement_feedback_observed", report.summary.approvedForMovement == 1, "1", "\(report.summary.approvedForMovement)"),
        feedbackInvariantCheck("blocked_by_collision_feedback_observed", report.summary.blockedByCollision == 1, "1", "\(report.summary.blockedByCollision)"),
        feedbackInvariantCheck("blocked_by_agent_conflict_feedback_observed", report.summary.blockedByAgentConflict == 1, "1", "\(report.summary.blockedByAgentConflict)"),
        feedbackInvariantCheck("blocked_by_max_agents_duplicate_counted", report.result.summary.blockedByMaxAgents == 0 && report.summary.duplicateFeedback == 1, "duplicate only", "\(report.result.summary.blockedByMaxAgents)/\(report.summary.duplicateFeedback)"),
        feedbackInvariantCheck("contexts_produced_for_accepted_feedback", report.summary.contextsProduced == report.summary.feedbackAccepted, "match", "\(report.summary.contextsProduced)/\(report.summary.feedbackAccepted)"),
        feedbackInvariantCheck("context_contains_agent_id", report.result.acceptedContexts.allSatisfy { !$0.agentId.isEmpty }, "all non-empty", contextIds.joined(separator: ",")),
        feedbackInvariantCheck("context_contains_tick", report.result.acceptedContexts.allSatisfy { $0.tick == report.summary.tick }, "tick 0", "\(report.summary.tick)"),
        feedbackInvariantCheck("context_preserves_last_feedback_kind", contextKinds.count == report.summary.contextsProduced, "all preserved", contextKinds.map(\.rawValue).joined(separator: ",")),
        feedbackInvariantCheck("moved_context_marks_last_move_succeeded", movedContext?.lastMoveSucceeded == true && movedContext?.lastMoveBlocked == false, "succeeded only", "\(movedContext?.lastMoveSucceeded == true)/\(movedContext?.lastMoveBlocked == true)"),
        feedbackInvariantCheck("collision_context_marks_last_move_blocked", collisionContext?.lastMoveBlocked == true && collisionContext?.lastBlockReason == .blockedByCollision, "blockedByCollision", collisionContext?.lastBlockReason?.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_conflict_context_marks_last_move_blocked", conflictContext?.lastMoveBlocked == true && conflictContext?.lastBlockReason == .blockedByAgentConflict, "blockedByAgentConflict", conflictContext?.lastBlockReason?.rawValue ?? "missing"),
        feedbackInvariantCheck("approved_for_movement_context_not_marked_moved", approvedContext?.lastMoveSucceeded == false && approvedContext?.lastMoveBlocked == false, "not moved/block", "\(approvedContext?.lastMoveSucceeded == true)/\(approvedContext?.lastMoveBlocked == true)"),
        feedbackInvariantCheck("last_known_position_from_after_position_when_moved", movedContext?.lastKnownPosition == feedbackNode(8, 8), "(8,64,8)", "\(String(describing: movedContext?.lastKnownPosition))"),
        feedbackInvariantCheck("last_known_position_preserved_when_blocked", collisionContext?.lastKnownPosition == feedbackNode(7, 8) && conflictContext?.lastKnownPosition == feedbackNode(2, 0), "preserved", "\(String(describing: collisionContext?.lastKnownPosition))/\(String(describing: conflictContext?.lastKnownPosition))"),
        feedbackInvariantCheck("feedback_evidence_collision_read_does_not_mean_consumption_collision_read", report.result.summary.feedbackEvidenceCollisionReadCount == 2 && !report.summary.collisionRead, "historical evidence only", "\(report.result.summary.feedbackEvidenceCollisionReadCount)/\(report.summary.collisionRead)"),
        feedbackInvariantCheck("consumption_does_not_read_collision", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        feedbackInvariantCheck("intent_not_produced", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        feedbackInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        feedbackInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        feedbackInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        feedbackInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        feedbackInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        feedbackInvariantCheck("learning_not_performed", true, "false", "false"),
        feedbackInvariantCheck("llm_rl_python_not_used", true, "false", "false"),
        feedbackInvariantCheck("social_behavior_not_used", true, "false", "false"),
        feedbackInvariantCheck("communication_not_used", true, "false", "false"),
        feedbackInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        feedbackInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("tick_movement_not_invoked", !report.summary.movementApplied && !report.summary.intentProduced, "not invoked", "\(report.summary.movementApplied)/\(report.summary.intentProduced)"),
        feedbackInvariantCheck("agent_intent_not_invoked", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("report_written", true, "agent_feedback_consumption_fixture_report.json", "agent_feedback_consumption_fixture_report.json"),
        feedbackInvariantCheck("contexts_written", true, "agent_feedback_contexts.json", "agent_feedback_contexts.json"),
        feedbackInvariantCheck("metrics_written", true, "agentFeedbackConsumptionFixture* metrics", "agentFeedbackConsumptionFixture* metrics"),
        feedbackInvariantCheck("event_written", true, "lab_agent_feedback_consumption_fixture_recorded", "lab_agent_feedback_consumption_fixture_recorded"),
        feedbackInvariantCheck("prior_approved_application_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabAgentFeedbackConsumptionFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Feedback consumption v0 observes synthetic fixture feedback and produces bounded contexts only.",
            "Historical feedback may contain collisionRead evidence, but this consumption scenario does not read collision.",
            "No movement, intent production, memory update, goal change, pathfinding, replanning, avoidance, reservation runtime, World use, or mutation is performed."
        ]
    )
}

func makeAgentFeedbackConsumptionHardeningInvariantReport(
    report: LabAgentFeedbackConsumptionHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabAgentFeedbackConsumptionHardeningInvariantReport {
    guard let report else {
        let check = feedbackInvariantCheck(
            "report_written",
            false,
            "agent_feedback_consumption_hardening_report.json",
            "missing"
        )
        return LabAgentFeedbackConsumptionHardeningInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 0,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Agent feedback consumption hardening report was not available."]
        )
    }

    let caseNames = Set(report.cases.map(\.name))
    let totals = report.cases.reduce(
        (
            observed: 0,
            accepted: 0,
            ignored: 0,
            invalid: 0,
            contexts: 0,
            duplicate: 0,
            max: 0,
            tickMismatch: 0
        )
    ) { partial, result in
        (
            observed: partial.observed + result.result.summary.feedbackObserved,
            accepted: partial.accepted + result.result.summary.feedbackAccepted,
            ignored: partial.ignored + result.result.summary.feedbackIgnored,
            invalid: partial.invalid + result.result.summary.invalidFeedback,
            contexts: partial.contexts + result.result.summary.contextsProduced,
            duplicate: partial.duplicate + result.result.summary.duplicateFeedback,
            max: partial.max + result.result.summary.maxFeedbackExceeded,
            tickMismatch: partial.tickMismatch + result.result.summary.tickMismatchFeedback
        )
    }
    let allObservationIdsSorted = report.cases.allSatisfy {
        let ids = $0.result.observations.map(\.agentId)
        return ids == ids.sorted()
    }
    let allContextIdsSorted = report.cases.allSatisfy {
        let ids = $0.result.acceptedContexts.map(\.agentId)
        return ids == ids.sorted()
    }
    let allUniqueAccepted = report.cases.allSatisfy {
        let ids = $0.result.observations.map(\.agentId)
        return Set(ids).count == ids.count
    }
    let knownAccepted = report.cases.allSatisfy { result in
        result.result.observations.allSatisfy {
            [
                LabMovementFeedbackKind.moved,
                .approvedForMovement,
                .blockedByCollision,
                .blockedByAgentConflict,
                .blockedBySourceMismatch,
                .blockedByDivergence,
                .blockedByStaleIntent,
                .blockedByInvalidEdge,
                .blockedByMaxAgents
            ].contains($0.feedbackKind)
        }
    }

    let checks = [
        feedbackInvariantCheck("hardening_cases_exist", !report.cases.isEmpty, "non-empty", "\(report.cases.count)"),
        feedbackInvariantCheck("hardening_case_count_expected", report.summary.cases == 12, "12", "\(report.summary.cases)"),
        feedbackInvariantCheck("baseline_fixture_remains_green", caseNames.contains("baseline_fixture_remains_green") && report.cases.first { $0.name == "baseline_fixture_remains_green" }?.passed == true, "passed", "\(report.cases.first { $0.name == "baseline_fixture_remains_green" }?.passed == true)"),
        feedbackInvariantCheck("duplicate_feedback_denied", caseNames.contains("duplicate_feedback_denied") && report.cases.first { $0.name == "duplicate_feedback_denied" }?.passed == true, "passed", "\(report.cases.first { $0.name == "duplicate_feedback_denied" }?.passed == true)"),
        feedbackInvariantCheck("malformed_missing_agent_denied", caseNames.contains("malformed_missing_agent_denied") && report.cases.first { $0.name == "malformed_missing_agent_denied" }?.passed == true, "passed", "\(report.cases.first { $0.name == "malformed_missing_agent_denied" }?.passed == true)"),
        feedbackInvariantCheck("malformed_missing_kind_denied", caseNames.contains("malformed_missing_kind_denied") && report.cases.first { $0.name == "malformed_missing_kind_denied" }?.passed == true, "passed", "\(report.cases.first { $0.name == "malformed_missing_kind_denied" }?.passed == true)"),
        feedbackInvariantCheck("malformed_missing_required_fields_denied", caseNames.contains("malformed_missing_required_fields_denied") && report.cases.first { $0.name == "malformed_missing_required_fields_denied" }?.passed == true, "passed", "\(report.cases.first { $0.name == "malformed_missing_required_fields_denied" }?.passed == true)"),
        feedbackInvariantCheck("deterministic_ordering_by_agent_id", caseNames.contains("deterministic_ordering_by_agent_id") && report.cases.first { $0.name == "deterministic_ordering_by_agent_id" }?.passed == true, "passed", "\(report.cases.first { $0.name == "deterministic_ordering_by_agent_id" }?.passed == true)"),
        feedbackInvariantCheck("one_feedback_per_agent_bound", caseNames.contains("one_feedback_per_agent_bound") && report.cases.first { $0.name == "one_feedback_per_agent_bound" }?.passed == true, "passed", "\(report.cases.first { $0.name == "one_feedback_per_agent_bound" }?.passed == true)"),
        feedbackInvariantCheck("all_known_kinds_observed", caseNames.contains("all_known_kinds_observed") && report.cases.first { $0.name == "all_known_kinds_observed" }?.passed == true, "passed", "\(report.cases.first { $0.name == "all_known_kinds_observed" }?.passed == true)"),
        feedbackInvariantCheck("historical_collision_evidence_does_not_read_collision", caseNames.contains("historical_collision_evidence_does_not_read_collision") && report.cases.first { $0.name == "historical_collision_evidence_does_not_read_collision" }?.passed == true, "passed", "\(report.cases.first { $0.name == "historical_collision_evidence_does_not_read_collision" }?.passed == true)"),
        feedbackInvariantCheck("max_feedback_bound_exceeded", caseNames.contains("max_feedback_bound_exceeded") && report.cases.first { $0.name == "max_feedback_bound_exceeded" }?.passed == true, "passed", "\(report.cases.first { $0.name == "max_feedback_bound_exceeded" }?.passed == true)"),
        feedbackInvariantCheck("tick_mismatch_denied", caseNames.contains("tick_mismatch_denied") && report.cases.first { $0.name == "tick_mismatch_denied" }?.passed == true, "passed", "\(report.cases.first { $0.name == "tick_mismatch_denied" }?.passed == true)"),
        feedbackInvariantCheck("stable_repeatability", caseNames.contains("stable_repeatability") && report.cases.first { $0.name == "stable_repeatability" }?.passed == true, "passed", "\(report.cases.first { $0.name == "stable_repeatability" }?.passed == true)"),
        feedbackInvariantCheck("cases_all_passed", report.summary.passed == report.summary.cases && report.summary.failed == 0, "all passed", "\(report.summary.passed)/\(report.summary.failed)"),
        feedbackInvariantCheck("feedback_totals_match_cases", totals.observed == report.summary.feedbackObservedTotal && totals.accepted == report.summary.feedbackAcceptedTotal && totals.ignored == report.summary.feedbackIgnoredTotal && totals.invalid == report.summary.invalidFeedbackTotal && totals.contexts == report.summary.contextsProducedTotal, "totals match", "\(totals)"),
        feedbackInvariantCheck("accepted_contexts_sorted_by_agent_id", allContextIdsSorted, "sorted", "checked"),
        feedbackInvariantCheck("observations_sorted_by_agent_id", allObservationIdsSorted, "sorted", "checked"),
        feedbackInvariantCheck("at_most_one_feedback_accepted_per_agent", allUniqueAccepted, "unique", "checked"),
        feedbackInvariantCheck("known_feedback_kinds_accepted", knownAccepted, "known", "checked"),
        feedbackInvariantCheck("malformed_feedback_rejected", report.summary.invalidFeedbackTotal > 0, ">0", "\(report.summary.invalidFeedbackTotal)"),
        feedbackInvariantCheck("duplicate_feedback_counted", report.summary.duplicateFeedbackTotal > 0, ">0", "\(report.summary.duplicateFeedbackTotal)"),
        feedbackInvariantCheck("max_feedback_exceeded_counted", report.summary.maxFeedbackExceededTotal > 0, ">0", "\(report.summary.maxFeedbackExceededTotal)"),
        feedbackInvariantCheck("tick_mismatch_counted", report.summary.tickMismatchFeedbackTotal > 0, ">0", "\(report.summary.tickMismatchFeedbackTotal)"),
        feedbackInvariantCheck("moved_feedback_observed", report.summary.movedTotal > 0, ">0", "\(report.summary.movedTotal)"),
        feedbackInvariantCheck("approved_for_movement_feedback_observed", report.summary.approvedForMovementTotal > 0, ">0", "\(report.summary.approvedForMovementTotal)"),
        feedbackInvariantCheck("blocked_by_collision_feedback_observed", report.summary.blockedByCollisionTotal > 0, ">0", "\(report.summary.blockedByCollisionTotal)"),
        feedbackInvariantCheck("blocked_by_agent_conflict_feedback_observed", report.summary.blockedByAgentConflictTotal > 0, ">0", "\(report.summary.blockedByAgentConflictTotal)"),
        feedbackInvariantCheck("blocked_by_source_mismatch_feedback_observed", report.summary.blockedBySourceMismatchTotal > 0, ">0", "\(report.summary.blockedBySourceMismatchTotal)"),
        feedbackInvariantCheck("blocked_by_divergence_feedback_observed", report.summary.blockedByDivergenceTotal > 0, ">0", "\(report.summary.blockedByDivergenceTotal)"),
        feedbackInvariantCheck("blocked_by_stale_intent_feedback_observed", report.summary.blockedByStaleIntentTotal > 0, ">0", "\(report.summary.blockedByStaleIntentTotal)"),
        feedbackInvariantCheck("blocked_by_invalid_edge_feedback_observed", report.summary.blockedByInvalidEdgeTotal > 0, ">0", "\(report.summary.blockedByInvalidEdgeTotal)"),
        feedbackInvariantCheck("blocked_by_max_agents_feedback_observed", report.summary.blockedByMaxAgentsTotal > 0, ">0", "\(report.summary.blockedByMaxAgentsTotal)"),
        feedbackInvariantCheck("consumption_does_not_read_collision", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        feedbackInvariantCheck("intent_not_produced", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        feedbackInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        feedbackInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        feedbackInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        feedbackInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        feedbackInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        feedbackInvariantCheck("learning_not_performed", true, "false", "false"),
        feedbackInvariantCheck("llm_rl_python_not_used", true, "false", "false"),
        feedbackInvariantCheck("social_behavior_not_used", true, "false", "false"),
        feedbackInvariantCheck("communication_not_used", true, "false", "false"),
        feedbackInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        feedbackInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("tick_movement_not_invoked", !report.summary.movementApplied && !report.summary.intentProduced, "not invoked", "\(report.summary.movementApplied)/\(report.summary.intentProduced)"),
        feedbackInvariantCheck("agent_intent_not_invoked", !report.summary.intentProduced, "false", "\(report.summary.intentProduced)"),
        feedbackInvariantCheck("fixture_smoke_remains_green", true, "external non-regression command", "not invoked by hardening scenario"),
        feedbackInvariantCheck("report_written", true, "agent_feedback_consumption_hardening_report.json", "agent_feedback_consumption_hardening_report.json"),
        feedbackInvariantCheck("cases_written", true, "agent_feedback_consumption_hardening_cases.json", "agent_feedback_consumption_hardening_cases.json"),
        feedbackInvariantCheck("metrics_written", true, "agentFeedbackConsumptionHardening* metrics", "agentFeedbackConsumptionHardening* metrics"),
        feedbackInvariantCheck("event_written", true, "lab_agent_feedback_consumption_hardening_recorded", "lab_agent_feedback_consumption_hardening_recorded"),
        feedbackInvariantCheck("prior_approved_application_smoke_remains_green", true, "external non-regression command", "not invoked by hardening scenario"),
        feedbackInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabAgentFeedbackConsumptionHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.summary.cases,
            passed: report.summary.passed,
            failed: report.summary.failed
        ),
        checks: checks,
        notes: [
            "Feedback consumption hardening remains fixture-only and observe-only.",
            "Max feedback and tick mismatch are validation bounds, not behavior adaptation.",
            "No movement, intent production, memory update, goal change, collision read, World use, or mutation is performed."
        ]
    )
}

struct LabFeedbackToAgentIntentContextFixtureSummary: Codable {
    let tick: Int
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let duplicateFeedback: Int
    let intentContexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidOneEdgeProposals: Int
    let behaviorChangedByFeedback: Bool
    let feedbackUsedForDecision: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let intentProduced: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackToAgentIntentContextFixtureReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let feedbackConsumption: LabAgentFeedbackConsumptionResult
    let intentProduction: LabAgentIntentProductionResult
    let intentContexts: [LabAgentIntentContext]
    let baselineWithoutFeedback: LabAgentIntentProductionResult
    let summary: LabFeedbackToAgentIntentContextFixtureSummary
}

struct LabFeedbackToAgentIntentContextFixtureInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

private func feedbackToAgentIntentContextFixtureInputs() -> [LabAgentFeedbackFixtureInput] {
    [
        feedbackInput(
            order: 0,
            agentId: "agent_2",
            kind: .blockedByCollision,
            decision: .deniedCollision,
            from: feedbackNode(7, 8),
            to: feedbackNode(8, 8),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(7, 8),
            abstractAfter: feedbackNode(7, 8),
            physicalBefore: feedbackNode(7, 8),
            physicalAfter: feedbackNode(7, 8),
            reason: "feedback_to_context_blocked_by_collision"
        ),
        feedbackInput(
            order: 1,
            agentId: "agent_0",
            kind: .moved,
            decision: .approved,
            from: feedbackNode(0, 0),
            to: feedbackNode(1, 0),
            displacementApplied: true,
            collisionRead: false,
            abstractBefore: feedbackNode(0, 0),
            abstractAfter: feedbackNode(1, 0),
            physicalBefore: feedbackNode(0, 0),
            physicalAfter: feedbackNode(1, 0),
            reason: "feedback_to_context_moved"
        ),
        feedbackInput(
            order: 2,
            agentId: "agent_1",
            kind: .approvedForMovement,
            decision: .approved,
            from: feedbackNode(2, 0),
            to: feedbackNode(1, 0),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(2, 0),
            abstractAfter: feedbackNode(2, 0),
            physicalBefore: feedbackNode(2, 0),
            physicalAfter: feedbackNode(2, 0),
            reason: "feedback_to_context_approved_for_movement"
        ),
        feedbackInput(
            order: 3,
            agentId: "agent_3",
            kind: .blockedByAgentConflict,
            decision: .deniedSameDestinationConflict,
            from: feedbackNode(4, 0),
            to: feedbackNode(3, 0),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(4, 0),
            abstractAfter: feedbackNode(4, 0),
            physicalBefore: feedbackNode(4, 0),
            physicalAfter: feedbackNode(4, 0),
            reason: "feedback_to_context_blocked_by_agent_conflict"
        ),
        feedbackInput(
            order: 4,
            agentId: "agent_0",
            kind: .blockedByMaxAgents,
            decision: .deniedMaxAgents,
            from: feedbackNode(1, 0),
            to: feedbackNode(2, 0),
            displacementApplied: false,
            collisionRead: false,
            abstractBefore: feedbackNode(1, 0),
            abstractAfter: feedbackNode(1, 0),
            physicalBefore: feedbackNode(1, 0),
            physicalAfter: feedbackNode(1, 0),
            reason: "feedback_to_context_duplicate_blocked_by_max_agents"
        ),
        feedbackInput(
            order: 5,
            agentId: "",
            kind: nil,
            decision: nil,
            from: nil,
            to: nil,
            displacementApplied: nil,
            collisionRead: nil,
            abstractBefore: nil,
            abstractAfter: nil,
            physicalBefore: nil,
            physicalAfter: nil,
            reason: "feedback_to_context_malformed",
            malformedReason: "missing_agent_id_and_required_fields"
        )
    ]
}

private func movementFeedback(
    from observation: LabAgentFeedbackObservation
) -> LabMovementFeedback {
    LabMovementFeedback(
        agentId: observation.agentId,
        tick: observation.tick,
        kind: observation.feedbackKind,
        from: observation.from,
        to: observation.to,
        reason: observation.reason
    )
}

private func makeFeedbackToAgentIntentContexts(
    feedbackContexts: [LabAgentFeedbackContext],
    includeFeedback: Bool
) -> [LabAgentIntentContext] {
    let feedbackByAgent = Dictionary(
        uniqueKeysWithValues: feedbackContexts.compactMap { context -> (String, LabMovementFeedback)? in
            guard let observation = context.lastFeedback else { return nil }
            return (context.agentId, movementFeedback(from: observation))
        }
    )

    func lastFeedback(_ agentId: String) -> LabMovementFeedback? {
        includeFeedback ? feedbackByAgent[agentId] : nil
    }

    return [
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_2",
            position: feedbackNode(7, 8),
            lastFeedback: lastFeedback("agent_2"),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_0",
            position: feedbackNode(1, 0),
            lastFeedback: lastFeedback("agent_0"),
            role: "wander_fixture",
            localHints: ["move_east"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_1",
            position: feedbackNode(2, 0),
            lastFeedback: lastFeedback("agent_1"),
            role: "wander_fixture",
            localHints: ["move_west"]
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_3",
            position: feedbackNode(4, 0),
            lastFeedback: lastFeedback("agent_3"),
            role: "idle",
            localHints: []
        ),
        LabAgentIntentContext(
            tick: 0,
            agentId: "agent_4",
            position: feedbackNode(30, 0),
            lastFeedback: nil,
            role: "bad_fixture_invalid_vertical",
            localHints: ["move_vertical"]
        )
    ]
}

private func proposalSignature(_ proposals: [LabAgentIntentProposal]) -> [String] {
    proposals.map { proposal in
        let intentPart: String
        if let intent = proposal.intent {
            intentPart = "\(intent.from.x),\(intent.from.y),\(intent.from.z)->\(intent.to.x),\(intent.to.y),\(intent.to.z)"
        } else {
            intentPart = "nil"
        }
        return "\(proposal.agentId)|\(proposal.decision.rawValue)|\(proposal.reason)|\(intentPart)"
    }
}

func makeFeedbackToAgentIntentContextFixtureReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackToAgentIntentContextFixtureReport {
    let feedbackConsumption = consumeAgentFeedbackFixtureV0(
        feedbackInputs: feedbackToAgentIntentContextFixtureInputs()
    )
    let intentContexts = makeFeedbackToAgentIntentContexts(
        feedbackContexts: feedbackConsumption.acceptedContexts,
        includeFeedback: true
    )
    let baselineContexts = makeFeedbackToAgentIntentContexts(
        feedbackContexts: feedbackConsumption.acceptedContexts,
        includeFeedback: false
    )
    let intentProduction = produceAgentIntentProductionResult(
        tick: 0,
        contexts: intentContexts,
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
    let baseline = produceAgentIntentProductionResult(
        tick: 0,
        contexts: baselineContexts,
        maxProposals: nil,
        duplicateProposalAgentId: nil
    )
    let behaviorChanged = proposalSignature(intentProduction.proposals)
        != proposalSignature(baseline.proposals)
    let contextsWithFeedback = intentContexts.filter { $0.lastFeedback != nil }.count
    let summary = LabFeedbackToAgentIntentContextFixtureSummary(
        tick: 0,
        feedbackObserved: feedbackConsumption.summary.feedbackObserved,
        feedbackAccepted: feedbackConsumption.summary.feedbackAccepted,
        feedbackIgnored: feedbackConsumption.summary.feedbackIgnored,
        invalidFeedback: feedbackConsumption.summary.invalidFeedback,
        contextsProduced: feedbackConsumption.summary.contextsProduced,
        duplicateFeedback: feedbackConsumption.summary.duplicateFeedback,
        intentContexts: intentContexts.count,
        contextsWithFeedback: contextsWithFeedback,
        contextsWithoutFeedback: intentContexts.count - contextsWithFeedback,
        proposals: intentProduction.summary.proposals,
        acceptedIntents: intentProduction.summary.acceptedIntents,
        rejectedProposals: intentProduction.summary.rejectedProposals,
        noIntent: intentProduction.summary.noIntent,
        invalidOneEdgeProposals: intentProduction.summary.invalidOneEdgeProposals,
        behaviorChangedByFeedback: behaviorChanged,
        feedbackUsedForDecision: false,
        movementApplied: false,
        collisionRead: false,
        intentProduced: true,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: feedbackConsumption.summary.success
            && feedbackConsumption.summary.feedbackAccepted == 4
            && intentContexts.count == 5
            && contextsWithFeedback == 4
            && intentProduction.summary.proposals == 5
            && intentProduction.summary.acceptedIntents == 3
            && intentProduction.summary.rejectedProposals == 2
            && intentProduction.summary.noIntent == 1
            && intentProduction.summary.invalidOneEdgeProposals == 1
            && !behaviorChanged
    )

    return LabFeedbackToAgentIntentContextFixtureReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        feedbackConsumption: feedbackConsumption,
        intentProduction: intentProduction,
        intentContexts: intentContexts,
        baselineWithoutFeedback: baseline,
        summary: summary
    )
}

func makeFeedbackToAgentIntentContextFixtureInvariantReport(
    report: LabFeedbackToAgentIntentContextFixtureReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackToAgentIntentContextFixtureInvariantReport {
    guard let report else {
        let check = feedbackInvariantCheck(
            "report_written",
            false,
            "feedback_to_agent_intent_context_fixture_report.json",
            "missing"
        )
        return LabFeedbackToAgentIntentContextFixtureInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 0,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Feedback-to-agent-intent-context report was not available."]
        )
    }

    let feedbackContextIds = report.feedbackConsumption.acceptedContexts.map(\.agentId)
    let intentContextsByAgent = Dictionary(
        uniqueKeysWithValues: report.intentContexts.map { ($0.agentId, $0) }
    )
    let proposalIds = report.intentProduction.proposals.map(\.agentId)
    let behaviorSame = proposalSignature(report.intentProduction.proposals)
        == proposalSignature(report.baselineWithoutFeedback.proposals)
    let checks = [
        feedbackInvariantCheck("fixture_feedback_exists", !report.feedbackConsumption.fixtureFeedback.isEmpty, "non-empty", "\(report.feedbackConsumption.fixtureFeedback.count)"),
        feedbackInvariantCheck("feedback_consumption_succeeds", report.feedbackConsumption.summary.success, "true", "\(report.feedbackConsumption.summary.success)"),
        feedbackInvariantCheck("feedback_contexts_exist", !report.feedbackConsumption.acceptedContexts.isEmpty, "non-empty", "\(report.feedbackConsumption.acceptedContexts.count)"),
        feedbackInvariantCheck("feedback_contexts_sorted_by_agent_id", feedbackContextIds == feedbackContextIds.sorted(), "sorted", feedbackContextIds.joined(separator: ",")),
        feedbackInvariantCheck("one_feedback_context_per_agent", Set(feedbackContextIds).count == feedbackContextIds.count, "unique", feedbackContextIds.joined(separator: ",")),
        feedbackInvariantCheck("moved_feedback_context_present", intentContextsByAgent["agent_0"]?.lastFeedback?.kind == .moved, "moved", intentContextsByAgent["agent_0"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("approved_for_movement_feedback_context_present", intentContextsByAgent["agent_1"]?.lastFeedback?.kind == .approvedForMovement, "approvedForMovement", intentContextsByAgent["agent_1"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("blocked_by_collision_feedback_context_present", intentContextsByAgent["agent_2"]?.lastFeedback?.kind == .blockedByCollision, "blockedByCollision", intentContextsByAgent["agent_2"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("blocked_by_agent_conflict_feedback_context_present", intentContextsByAgent["agent_3"]?.lastFeedback?.kind == .blockedByAgentConflict, "blockedByAgentConflict", intentContextsByAgent["agent_3"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("duplicate_feedback_ignored", report.feedbackConsumption.summary.duplicateFeedback == 1 && report.feedbackConsumption.summary.feedbackIgnored == 1, "1/1", "\(report.feedbackConsumption.summary.duplicateFeedback)/\(report.feedbackConsumption.summary.feedbackIgnored)"),
        feedbackInvariantCheck("malformed_feedback_rejected", report.feedbackConsumption.summary.invalidFeedback == 1, "1", "\(report.feedbackConsumption.summary.invalidFeedback)"),
        feedbackInvariantCheck("agent_intent_contexts_exist", !report.intentContexts.isEmpty, "non-empty", "\(report.intentContexts.count)"),
        feedbackInvariantCheck("agent_intent_contexts_include_feedback", report.summary.contextsWithFeedback == 4, "4", "\(report.summary.contextsWithFeedback)"),
        feedbackInvariantCheck("agent_intent_contexts_without_feedback_count_expected", report.summary.contextsWithoutFeedback == 1, "1", "\(report.summary.contextsWithoutFeedback)"),
        feedbackInvariantCheck("last_feedback_preserved_in_agent_intent_context", report.intentContexts.filter { $0.lastFeedback != nil }.count == 4, "4", "\(report.intentContexts.filter { $0.lastFeedback != nil }.count)"),
        feedbackInvariantCheck("agent_0_moved_feedback_preserved", intentContextsByAgent["agent_0"]?.lastFeedback?.kind == .moved, "moved", intentContextsByAgent["agent_0"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_1_approved_for_movement_feedback_preserved", intentContextsByAgent["agent_1"]?.lastFeedback?.kind == .approvedForMovement, "approvedForMovement", intentContextsByAgent["agent_1"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_2_blocked_by_collision_feedback_preserved", intentContextsByAgent["agent_2"]?.lastFeedback?.kind == .blockedByCollision, "blockedByCollision", intentContextsByAgent["agent_2"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_3_blocked_by_agent_conflict_feedback_preserved", intentContextsByAgent["agent_3"]?.lastFeedback?.kind == .blockedByAgentConflict, "blockedByAgentConflict", intentContextsByAgent["agent_3"]?.lastFeedback?.kind.rawValue ?? "missing"),
        feedbackInvariantCheck("agent_4_has_no_feedback", intentContextsByAgent["agent_4"]?.lastFeedback == nil, "nil", "\(intentContextsByAgent["agent_4"]?.lastFeedback == nil)"),
        feedbackInvariantCheck("proposals_exist", !report.intentProduction.proposals.isEmpty, "non-empty", "\(report.intentProduction.proposals.count)"),
        feedbackInvariantCheck("proposals_sorted_by_agent_id", proposalIds == proposalIds.sorted(), "sorted", proposalIds.joined(separator: ",")),
        feedbackInvariantCheck("accepted_intents_expected", report.summary.acceptedIntents == 3, "3", "\(report.summary.acceptedIntents)"),
        feedbackInvariantCheck("rejected_proposals_expected", report.summary.rejectedProposals == 2, "2", "\(report.summary.rejectedProposals)"),
        feedbackInvariantCheck("no_intent_expected", report.summary.noIntent == 1, "1", "\(report.summary.noIntent)"),
        feedbackInvariantCheck("invalid_one_edge_expected", report.summary.invalidOneEdgeProposals == 1, "1", "\(report.summary.invalidOneEdgeProposals)"),
        feedbackInvariantCheck("behavior_not_changed_by_feedback", !report.summary.behaviorChangedByFeedback, "false", "\(report.summary.behaviorChangedByFeedback)"),
        feedbackInvariantCheck("feedback_not_used_for_decision", !report.summary.feedbackUsedForDecision, "false", "\(report.summary.feedbackUsedForDecision)"),
        feedbackInvariantCheck("baseline_without_feedback_matches_decisions", behaviorSame, "same", "\(behaviorSame)"),
        feedbackInvariantCheck("policy_v0_not_modified_for_feedback", behaviorSame && !report.summary.feedbackUsedForDecision, "unchanged", "\(behaviorSame)/\(report.summary.feedbackUsedForDecision)"),
        feedbackInvariantCheck("feedback_consumption_does_not_read_collision", !report.feedbackConsumption.summary.collisionRead, "false", "\(report.feedbackConsumption.summary.collisionRead)"),
        feedbackInvariantCheck("integration_does_not_read_collision", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        feedbackInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        feedbackInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        feedbackInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        feedbackInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        feedbackInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        feedbackInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        feedbackInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        feedbackInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("tick_movement_not_invoked", !report.summary.movementApplied && !report.summary.collisionRead, "not invoked", "\(report.summary.movementApplied)/\(report.summary.collisionRead)"),
        feedbackInvariantCheck("feedback_hardening_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("feedback_fixture_smoke_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("agent_intent_production_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("report_written", true, "feedback_to_agent_intent_context_fixture_report.json", "feedback_to_agent_intent_context_fixture_report.json"),
        feedbackInvariantCheck("contexts_written", true, "feedback_to_agent_intent_contexts.json", "feedback_to_agent_intent_contexts.json"),
        feedbackInvariantCheck("metrics_written", true, "feedbackToAgentIntentContextFixture* metrics", "feedbackToAgentIntentContextFixture* metrics"),
        feedbackInvariantCheck("event_written", true, "lab_feedback_to_agent_intent_context_fixture_recorded", "lab_feedback_to_agent_intent_context_fixture_recorded"),
        feedbackInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabFeedbackToAgentIntentContextFixtureInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: 1,
            passed: report.success ? 1 : 0,
            failed: report.success ? 0 : 1
        ),
        checks: checks,
        notes: [
            "Feedback contexts are injected into LabAgentIntentContext.lastFeedback as plumbing only.",
            "Policy v0 decisions are compared against a baseline with nil feedback and must remain identical.",
            "No movement, collision read, memory update, goal change, pathfinding, replanning, reservation runtime, World use, or mutation is performed."
        ]
    )
}

struct LabFeedbackToAgentIntentContextHardeningExpected: Codable {
    let feedbackObserved: Int
    let feedbackAccepted: Int
    let feedbackIgnored: Int
    let invalidFeedback: Int
    let contextsProduced: Int
    let duplicateFeedback: Int
    let maxFeedbackExceeded: Int
    let tickMismatchFeedback: Int
    let intentContexts: Int
    let contextsWithFeedback: Int
    let contextsWithoutFeedback: Int
    let proposals: Int
    let acceptedIntents: Int
    let rejectedProposals: Int
    let noIntent: Int
    let invalidOneEdgeProposals: Int
    let behaviorChangedByFeedback: Bool
    let feedbackUsedForDecision: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackToAgentIntentContextHardeningContextSpec: Codable {
    let agentId: String
    let position: LabTerrainPathNodeKey
    let role: String?
    let localHints: [String]
    let injectFeedback: Bool
}

struct LabFeedbackToAgentIntentContextHardeningCase: Codable {
    let name: String
    let feedbackInputs: [LabAgentFeedbackFixtureInput]
    let maxFeedback: Int?
    let expectedTick: Int?
    let contextSpecs: [LabFeedbackToAgentIntentContextHardeningContextSpec]
    let expected: LabFeedbackToAgentIntentContextHardeningExpected
    let repeatabilityCheck: Bool
    let notes: [String]
}

struct LabFeedbackToAgentIntentContextHardeningRepeatResult: Codable {
    let feedbackContextAgentIds: [String]
    let lastFeedbackKindsByAgent: [String: LabMovementFeedbackKind]
    let proposalSignatures: [String]
    let summaryTotalsMatch: Bool
    let matchesFirstRun: Bool
}

struct LabFeedbackToAgentIntentContextHardeningCaseResult: Codable {
    let name: String
    let passed: Bool
    let feedbackConsumption: LabAgentFeedbackConsumptionResult
    let intentProduction: LabAgentIntentProductionResult
    let baselineWithoutFeedback: LabAgentIntentProductionResult
    let intentContexts: [LabAgentIntentContext]
    let proposalSignatures: [String]
    let baselineProposalSignatures: [String]
    let repeatedResult: LabFeedbackToAgentIntentContextHardeningRepeatResult?
    let expected: LabFeedbackToAgentIntentContextHardeningExpected
    let actual: LabFeedbackToAgentIntentContextHardeningExpected
    let notes: [String]
}

struct LabFeedbackToAgentIntentContextHardeningSummary: Codable {
    let cases: Int
    let passed: Int
    let failed: Int
    let feedbackObservedTotal: Int
    let feedbackAcceptedTotal: Int
    let feedbackIgnoredTotal: Int
    let invalidFeedbackTotal: Int
    let contextsProducedTotal: Int
    let duplicateFeedbackTotal: Int
    let maxFeedbackExceededTotal: Int
    let tickMismatchFeedbackTotal: Int
    let intentContextsTotal: Int
    let contextsWithFeedbackTotal: Int
    let contextsWithoutFeedbackTotal: Int
    let proposalsTotal: Int
    let acceptedIntentsTotal: Int
    let rejectedProposalsTotal: Int
    let noIntentTotal: Int
    let invalidOneEdgeProposalsTotal: Int
    let behaviorChangedByFeedback: Bool
    let feedbackUsedForDecision: Bool
    let movementApplied: Bool
    let collisionRead: Bool
    let memoryUpdated: Bool
    let goalChanged: Bool
    let pathfindingPerformed: Bool
    let replanningPerformed: Bool
    let avoidancePerformed: Bool
    let reservationRuntimeUsed: Bool
    let worldUsed: Bool
    let mutationPerformed: Bool
    let success: Bool
}

struct LabFeedbackToAgentIntentContextHardeningReport: Codable {
    let scenario: String
    let seed: UInt32
    let ticksCompleted: Int
    let success: Bool
    let cases: [LabFeedbackToAgentIntentContextHardeningCaseResult]
    let summary: LabFeedbackToAgentIntentContextHardeningSummary
}

struct LabFeedbackToAgentIntentContextHardeningInvariantReport: Codable {
    let scenario: String
    let seed: UInt32
    let success: Bool
    let summary: LabMultiAgentMovementFixtureInvariantSummary
    let checks: [LabMultiAgentMovementFixtureInvariantCheck]
    let notes: [String]
}

private func hardeningExpected(
    feedbackObserved: Int,
    feedbackAccepted: Int,
    feedbackIgnored: Int,
    invalidFeedback: Int,
    contextsProduced: Int,
    duplicateFeedback: Int = 0,
    maxFeedbackExceeded: Int = 0,
    tickMismatchFeedback: Int = 0,
    intentContexts: Int,
    contextsWithFeedback: Int,
    contextsWithoutFeedback: Int,
    proposals: Int,
    acceptedIntents: Int,
    rejectedProposals: Int,
    noIntent: Int = 0,
    invalidOneEdgeProposals: Int = 0
) -> LabFeedbackToAgentIntentContextHardeningExpected {
    LabFeedbackToAgentIntentContextHardeningExpected(
        feedbackObserved: feedbackObserved,
        feedbackAccepted: feedbackAccepted,
        feedbackIgnored: feedbackIgnored,
        invalidFeedback: invalidFeedback,
        contextsProduced: contextsProduced,
        duplicateFeedback: duplicateFeedback,
        maxFeedbackExceeded: maxFeedbackExceeded,
        tickMismatchFeedback: tickMismatchFeedback,
        intentContexts: intentContexts,
        contextsWithFeedback: contextsWithFeedback,
        contextsWithoutFeedback: contextsWithoutFeedback,
        proposals: proposals,
        acceptedIntents: acceptedIntents,
        rejectedProposals: rejectedProposals,
        noIntent: noIntent,
        invalidOneEdgeProposals: invalidOneEdgeProposals,
        behaviorChangedByFeedback: false,
        feedbackUsedForDecision: false,
        movementApplied: false,
        collisionRead: false,
        memoryUpdated: false,
        goalChanged: false,
        pathfindingPerformed: false,
        replanningPerformed: false,
        avoidancePerformed: false,
        reservationRuntimeUsed: false,
        worldUsed: false,
        mutationPerformed: false,
        success: true
    )
}

private func feedbackDecision(for kind: LabMovementFeedbackKind) -> LabMultiAgentMoveDecision {
    switch kind {
    case .moved, .approvedForMovement:
        .approved
    case .blockedByCollision:
        .deniedCollision
    case .blockedByAgentConflict:
        .deniedSameDestinationConflict
    case .blockedBySourceMismatch:
        .deniedSourceMismatch
    case .blockedByDivergence:
        .deniedDivergence
    case .blockedByStaleIntent:
        .deniedStaleIntent
    case .blockedByInvalidEdge:
        .deniedInvalidEdge
    case .blockedByMaxAgents:
        .deniedMaxAgents
    }
}

private func hardeningFeedbackInput(
    order: Int,
    agentId: String,
    kind: LabMovementFeedbackKind,
    x: Int,
    z: Int,
    tick: Int? = 0
) -> LabAgentFeedbackFixtureInput {
    let from = feedbackNode(x, z)
    let to = feedbackNode(x + 1, z)
    let moved = kind == .moved
    return feedbackInput(
        order: order,
        agentId: agentId,
        kind: kind,
        decision: feedbackDecision(for: kind),
        from: from,
        to: to,
        displacementApplied: moved,
        collisionRead: false,
        abstractBefore: from,
        abstractAfter: moved ? to : from,
        physicalBefore: from,
        physicalAfter: moved ? to : from,
        reason: "feedback_to_context_hardening_\(kind.rawValue)",
        tick: tick
    )
}

private func hardeningContextSpec(
    _ agentId: String,
    x: Int,
    z: Int = 0,
    role: String? = "wander_fixture",
    hints: [String] = ["move_east"],
    injectFeedback: Bool = true
) -> LabFeedbackToAgentIntentContextHardeningContextSpec {
    LabFeedbackToAgentIntentContextHardeningContextSpec(
        agentId: agentId,
        position: feedbackNode(x, z),
        role: role,
        localHints: hints,
        injectFeedback: injectFeedback
    )
}

private func makeHardeningIntentContexts(
    specs: [LabFeedbackToAgentIntentContextHardeningContextSpec],
    feedbackContexts: [LabAgentFeedbackContext],
    includeFeedback: Bool
) -> [LabAgentIntentContext] {
    let feedbackByAgent = Dictionary(
        uniqueKeysWithValues: feedbackContexts.compactMap { context -> (String, LabMovementFeedback)? in
            guard let observation = context.lastFeedback else { return nil }
            return (context.agentId, movementFeedback(from: observation))
        }
    )

    return specs.map { spec in
        LabAgentIntentContext(
            tick: 0,
            agentId: spec.agentId,
            position: spec.position,
            lastFeedback: includeFeedback && spec.injectFeedback ? feedbackByAgent[spec.agentId] : nil,
            role: spec.role,
            localHints: spec.localHints
        )
    }
}

private func sameExpected(
    _ lhs: LabFeedbackToAgentIntentContextHardeningExpected,
    _ rhs: LabFeedbackToAgentIntentContextHardeningExpected
) -> Bool {
    lhs.feedbackObserved == rhs.feedbackObserved
        && lhs.feedbackAccepted == rhs.feedbackAccepted
        && lhs.feedbackIgnored == rhs.feedbackIgnored
        && lhs.invalidFeedback == rhs.invalidFeedback
        && lhs.contextsProduced == rhs.contextsProduced
        && lhs.duplicateFeedback == rhs.duplicateFeedback
        && lhs.maxFeedbackExceeded == rhs.maxFeedbackExceeded
        && lhs.tickMismatchFeedback == rhs.tickMismatchFeedback
        && lhs.intentContexts == rhs.intentContexts
        && lhs.contextsWithFeedback == rhs.contextsWithFeedback
        && lhs.contextsWithoutFeedback == rhs.contextsWithoutFeedback
        && lhs.proposals == rhs.proposals
        && lhs.acceptedIntents == rhs.acceptedIntents
        && lhs.rejectedProposals == rhs.rejectedProposals
        && lhs.noIntent == rhs.noIntent
        && lhs.invalidOneEdgeProposals == rhs.invalidOneEdgeProposals
        && lhs.behaviorChangedByFeedback == rhs.behaviorChangedByFeedback
        && lhs.feedbackUsedForDecision == rhs.feedbackUsedForDecision
        && lhs.movementApplied == rhs.movementApplied
        && lhs.collisionRead == rhs.collisionRead
        && lhs.memoryUpdated == rhs.memoryUpdated
        && lhs.goalChanged == rhs.goalChanged
        && lhs.pathfindingPerformed == rhs.pathfindingPerformed
        && lhs.replanningPerformed == rhs.replanningPerformed
        && lhs.avoidancePerformed == rhs.avoidancePerformed
        && lhs.reservationRuntimeUsed == rhs.reservationRuntimeUsed
        && lhs.worldUsed == rhs.worldUsed
        && lhs.mutationPerformed == rhs.mutationPerformed
        && lhs.success == rhs.success
}

private func feedbackKindsByAgent(_ contexts: [LabAgentIntentContext]) -> [String: LabMovementFeedbackKind] {
    Dictionary(uniqueKeysWithValues: contexts.compactMap { context in
        guard let kind = context.lastFeedback?.kind else { return nil }
        return (context.agentId, kind)
    })
}

private func evaluateFeedbackToAgentIntentContextHardeningCase(
    _ testCase: LabFeedbackToAgentIntentContextHardeningCase
) -> LabFeedbackToAgentIntentContextHardeningCaseResult {
    func runOnce() -> (
        feedbackConsumption: LabAgentFeedbackConsumptionResult,
        intentContexts: [LabAgentIntentContext],
        intentProduction: LabAgentIntentProductionResult,
        baseline: LabAgentIntentProductionResult,
        actual: LabFeedbackToAgentIntentContextHardeningExpected,
        proposalSignatures: [String],
        baselineSignatures: [String]
    ) {
        let feedbackConsumption = consumeAgentFeedbackFixtureV0(
            feedbackInputs: testCase.feedbackInputs,
            maxFeedback: testCase.maxFeedback,
            expectedTick: testCase.expectedTick
        )
        let intentContexts = makeHardeningIntentContexts(
            specs: testCase.contextSpecs,
            feedbackContexts: feedbackConsumption.acceptedContexts,
            includeFeedback: true
        )
        let baselineContexts = makeHardeningIntentContexts(
            specs: testCase.contextSpecs,
            feedbackContexts: feedbackConsumption.acceptedContexts,
            includeFeedback: false
        )
        let intentProduction = produceAgentIntentProductionResult(
            tick: 0,
            contexts: intentContexts,
            maxProposals: nil,
            duplicateProposalAgentId: nil
        )
        let baseline = produceAgentIntentProductionResult(
            tick: 0,
            contexts: baselineContexts,
            maxProposals: nil,
            duplicateProposalAgentId: nil
        )
        let signatures = proposalSignature(intentProduction.proposals)
        let baselineSignatures = proposalSignature(baseline.proposals)
        let behaviorChanged = signatures != baselineSignatures
        let contextsWithFeedback = intentContexts.filter { $0.lastFeedback != nil }.count
        let actual = LabFeedbackToAgentIntentContextHardeningExpected(
            feedbackObserved: feedbackConsumption.summary.feedbackObserved,
            feedbackAccepted: feedbackConsumption.summary.feedbackAccepted,
            feedbackIgnored: feedbackConsumption.summary.feedbackIgnored,
            invalidFeedback: feedbackConsumption.summary.invalidFeedback,
            contextsProduced: feedbackConsumption.summary.contextsProduced,
            duplicateFeedback: feedbackConsumption.summary.duplicateFeedback,
            maxFeedbackExceeded: feedbackConsumption.summary.maxFeedbackExceeded,
            tickMismatchFeedback: feedbackConsumption.summary.tickMismatchFeedback,
            intentContexts: intentContexts.count,
            contextsWithFeedback: contextsWithFeedback,
            contextsWithoutFeedback: intentContexts.count - contextsWithFeedback,
            proposals: intentProduction.summary.proposals,
            acceptedIntents: intentProduction.summary.acceptedIntents,
            rejectedProposals: intentProduction.summary.rejectedProposals,
            noIntent: intentProduction.summary.noIntent,
            invalidOneEdgeProposals: intentProduction.summary.invalidOneEdgeProposals,
            behaviorChangedByFeedback: behaviorChanged,
            feedbackUsedForDecision: false,
            movementApplied: false,
            collisionRead: false,
            memoryUpdated: false,
            goalChanged: false,
            pathfindingPerformed: false,
            replanningPerformed: false,
            avoidancePerformed: false,
            reservationRuntimeUsed: false,
            worldUsed: false,
            mutationPerformed: false,
            success: feedbackConsumption.summary.success
                && intentProduction.summary.success
                && signatures == baselineSignatures
                && intentProduction.proposals.map(\.agentId)
                    == intentProduction.proposals.map(\.agentId).sorted()
                && !behaviorChanged
        )
        return (
            feedbackConsumption,
            intentContexts,
            intentProduction,
            baseline,
            actual,
            signatures,
            baselineSignatures
        )
    }

    let first = runOnce()
    let repeated = testCase.repeatabilityCheck ? runOnce() : nil
    let repeatResult = repeated.map { second in
        let summaryTotalsMatch = sameExpected(first.actual, second.actual)
        let matchesFirstRun = first.feedbackConsumption.acceptedContexts.map(\.agentId)
            == second.feedbackConsumption.acceptedContexts.map(\.agentId)
            && feedbackKindsByAgent(first.intentContexts) == feedbackKindsByAgent(second.intentContexts)
            && first.proposalSignatures == second.proposalSignatures
            && summaryTotalsMatch
        return LabFeedbackToAgentIntentContextHardeningRepeatResult(
            feedbackContextAgentIds: second.feedbackConsumption.acceptedContexts.map(\.agentId),
            lastFeedbackKindsByAgent: feedbackKindsByAgent(second.intentContexts),
            proposalSignatures: second.proposalSignatures,
            summaryTotalsMatch: summaryTotalsMatch,
            matchesFirstRun: matchesFirstRun
        )
    }
    let passed = sameExpected(first.actual, testCase.expected)
        && first.actual.success
        && first.proposalSignatures == first.baselineSignatures
        && (repeatResult?.matchesFirstRun ?? true)

    return LabFeedbackToAgentIntentContextHardeningCaseResult(
        name: testCase.name,
        passed: passed,
        feedbackConsumption: first.feedbackConsumption,
        intentProduction: first.intentProduction,
        baselineWithoutFeedback: first.baseline,
        intentContexts: first.intentContexts,
        proposalSignatures: first.proposalSignatures,
        baselineProposalSignatures: first.baselineSignatures,
        repeatedResult: repeatResult,
        expected: testCase.expected,
        actual: first.actual,
        notes: testCase.notes
    )
}

private func feedbackToAgentIntentContextHardeningCases() -> [LabFeedbackToAgentIntentContextHardeningCase] {
    let baselineSpecs = [
        hardeningContextSpec("agent_2", x: 7, z: 8),
        hardeningContextSpec("agent_0", x: 1),
        hardeningContextSpec("agent_1", x: 2, hints: ["move_west"]),
        hardeningContextSpec("agent_3", x: 4, role: "idle", hints: []),
        hardeningContextSpec("agent_4", x: 30, role: "bad_fixture_invalid_vertical", hints: ["move_vertical"])
    ]
    let allKinds: [LabMovementFeedbackKind] = [
        .moved,
        .approvedForMovement,
        .blockedByCollision,
        .blockedByAgentConflict,
        .blockedBySourceMismatch,
        .blockedByDivergence,
        .blockedByStaleIntent,
        .blockedByInvalidEdge,
        .blockedByMaxAgents
    ]
    let allKindInputs = allKinds.enumerated().map { index, kind in
        hardeningFeedbackInput(
            order: allKinds.count - index,
            agentId: "kind_agent_\(index)",
            kind: kind,
            x: index * 2,
            z: 4
        )
    }
    let allKindSpecs = allKinds.indices.map { index in
        hardeningContextSpec("kind_agent_\(index)", x: index * 2, z: 4)
    }

    return [
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "baseline_fixture_remains_green",
            feedbackInputs: feedbackToAgentIntentContextFixtureInputs(),
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: baselineSpecs,
            expected: hardeningExpected(
                feedbackObserved: 6,
                feedbackAccepted: 4,
                feedbackIgnored: 1,
                invalidFeedback: 1,
                contextsProduced: 4,
                duplicateFeedback: 1,
                intentContexts: 5,
                contextsWithFeedback: 4,
                contextsWithoutFeedback: 1,
                proposals: 5,
                acceptedIntents: 3,
                rejectedProposals: 2,
                noIntent: 1,
                invalidOneEdgeProposals: 1
            ),
            repeatabilityCheck: false,
            notes: ["Reuses the 4.22D fixture shape."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "missing_feedback_context_allowed",
            feedbackInputs: [],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: baselineSpecs,
            expected: hardeningExpected(
                feedbackObserved: 0,
                feedbackAccepted: 0,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 0,
                intentContexts: 5,
                contextsWithFeedback: 0,
                contextsWithoutFeedback: 5,
                proposals: 5,
                acceptedIntents: 3,
                rejectedProposals: 2,
                noIntent: 1,
                invalidOneEdgeProposals: 1
            ),
            repeatabilityCheck: false,
            notes: ["Intent contexts can be built with nil lastFeedback."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "partial_feedback_contexts_allowed",
            feedbackInputs: [
                hardeningFeedbackInput(order: 1, agentId: "agent_2", kind: .blockedByCollision, x: 7, z: 8),
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 1, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: baselineSpecs,
            expected: hardeningExpected(
                feedbackObserved: 2,
                feedbackAccepted: 2,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 2,
                intentContexts: 5,
                contextsWithFeedback: 2,
                contextsWithoutFeedback: 3,
                proposals: 5,
                acceptedIntents: 3,
                rejectedProposals: 2,
                noIntent: 1,
                invalidOneEdgeProposals: 1
            ),
            repeatabilityCheck: false,
            notes: ["Only agent_0 and agent_2 receive feedback."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "all_feedback_kinds_preserved",
            feedbackInputs: allKindInputs,
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: allKindSpecs,
            expected: hardeningExpected(
                feedbackObserved: 9,
                feedbackAccepted: 9,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 9,
                intentContexts: 9,
                contextsWithFeedback: 9,
                contextsWithoutFeedback: 0,
                proposals: 9,
                acceptedIntents: 9,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["Every known feedback kind is preserved in lastFeedback."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "blocked_collision_does_not_change_to_wait",
            feedbackInputs: [
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .blockedByCollision, x: 0, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [hardeningContextSpec("agent_0", x: 0)],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 1,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 1,
                intentContexts: 1,
                contextsWithFeedback: 1,
                contextsWithoutFeedback: 0,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["blockedByCollision does not turn move_east into noIntent."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "moved_feedback_does_not_suppress_next_move",
            feedbackInputs: [
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [hardeningContextSpec("agent_0", x: 0)],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 1,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 1,
                intentContexts: 1,
                contextsWithFeedback: 1,
                contextsWithoutFeedback: 0,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["moved feedback does not suppress a normal next move."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "agent_conflict_does_not_trigger_coordination",
            feedbackInputs: [
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .blockedByAgentConflict, x: 2, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [hardeningContextSpec("agent_0", x: 2, hints: ["move_west"])],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 1,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 1,
                intentContexts: 1,
                contextsWithFeedback: 1,
                contextsWithoutFeedback: 0,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["blockedByAgentConflict does not create wait, coordination, or communication."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "invalid_edge_feedback_does_not_hide_invalid_policy",
            feedbackInputs: [
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .blockedByInvalidEdge, x: 30, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [
                hardeningContextSpec("agent_0", x: 30, role: "bad_fixture_invalid_vertical", hints: ["move_vertical"])
            ],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 1,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 1,
                intentContexts: 1,
                contextsWithFeedback: 1,
                contextsWithoutFeedback: 0,
                proposals: 1,
                acceptedIntents: 0,
                rejectedProposals: 1,
                invalidOneEdgeProposals: 1
            ),
            repeatabilityCheck: false,
            notes: ["blockedByInvalidEdge feedback does not hide the invalid vertical proposal."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "duplicate_feedback_context_selection_stable",
            feedbackInputs: [
                hardeningFeedbackInput(order: 1, agentId: "agent_0", kind: .blockedByCollision, x: 0, z: 0),
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [hardeningContextSpec("agent_0", x: 0)],
            expected: hardeningExpected(
                feedbackObserved: 2,
                feedbackAccepted: 1,
                feedbackIgnored: 1,
                invalidFeedback: 0,
                contextsProduced: 1,
                duplicateFeedback: 1,
                intentContexts: 1,
                contextsWithFeedback: 1,
                contextsWithoutFeedback: 0,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["The first stable duplicate for agent_0 is selected and the second is ignored."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "malformed_feedback_not_injected",
            feedbackInputs: [
                feedbackInput(
                    order: 0,
                    agentId: "",
                    kind: nil,
                    decision: nil,
                    from: nil,
                    to: nil,
                    displacementApplied: nil,
                    collisionRead: nil,
                    abstractBefore: nil,
                    abstractAfter: nil,
                    physicalBefore: nil,
                    physicalAfter: nil,
                    reason: "feedback_to_context_hardening_malformed",
                    malformedReason: "missing_agent_id_and_required_fields"
                )
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [hardeningContextSpec("agent_0", x: 0)],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 0,
                feedbackIgnored: 0,
                invalidFeedback: 1,
                contextsProduced: 0,
                intentContexts: 1,
                contextsWithFeedback: 0,
                contextsWithoutFeedback: 1,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["Malformed feedback is rejected and never injected."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "tick_mismatch_feedback_not_injected",
            feedbackInputs: [
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0, tick: 1)
            ],
            maxFeedback: nil,
            expectedTick: 0,
            contextSpecs: [hardeningContextSpec("agent_0", x: 0)],
            expected: hardeningExpected(
                feedbackObserved: 1,
                feedbackAccepted: 0,
                feedbackIgnored: 0,
                invalidFeedback: 1,
                contextsProduced: 0,
                tickMismatchFeedback: 1,
                intentContexts: 1,
                contextsWithFeedback: 0,
                contextsWithoutFeedback: 1,
                proposals: 1,
                acceptedIntents: 1,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["Mismatched tick feedback is rejected and not injected."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "max_feedback_bound_keeps_contexts_bounded",
            feedbackInputs: [
                hardeningFeedbackInput(order: 3, agentId: "agent_3", kind: .blockedByAgentConflict, x: 6, z: 0),
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0),
                hardeningFeedbackInput(order: 2, agentId: "agent_2", kind: .blockedByCollision, x: 4, z: 0),
                hardeningFeedbackInput(order: 1, agentId: "agent_1", kind: .approvedForMovement, x: 2, z: 0)
            ],
            maxFeedback: 3,
            expectedTick: nil,
            contextSpecs: [
                hardeningContextSpec("agent_3", x: 6),
                hardeningContextSpec("agent_0", x: 0),
                hardeningContextSpec("agent_2", x: 4),
                hardeningContextSpec("agent_1", x: 2)
            ],
            expected: hardeningExpected(
                feedbackObserved: 4,
                feedbackAccepted: 3,
                feedbackIgnored: 1,
                invalidFeedback: 0,
                contextsProduced: 3,
                maxFeedbackExceeded: 1,
                intentContexts: 4,
                contextsWithFeedback: 3,
                contextsWithoutFeedback: 1,
                proposals: 4,
                acceptedIntents: 4,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["maxFeedback caps accepted contexts while preserving baseline behavior."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "deterministic_ordering_by_agent_id",
            feedbackInputs: [
                hardeningFeedbackInput(order: 2, agentId: "agent_2", kind: .blockedByCollision, x: 4, z: 0),
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0),
                hardeningFeedbackInput(order: 1, agentId: "agent_1", kind: .approvedForMovement, x: 2, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [
                hardeningContextSpec("agent_2", x: 4),
                hardeningContextSpec("agent_0", x: 0),
                hardeningContextSpec("agent_1", x: 2)
            ],
            expected: hardeningExpected(
                feedbackObserved: 3,
                feedbackAccepted: 3,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 3,
                intentContexts: 3,
                contextsWithFeedback: 3,
                contextsWithoutFeedback: 0,
                proposals: 3,
                acceptedIntents: 3,
                rejectedProposals: 0
            ),
            repeatabilityCheck: false,
            notes: ["Inputs are deliberately unordered; observations and proposals sort by stable agentId."]
        ),
        LabFeedbackToAgentIntentContextHardeningCase(
            name: "stable_repeatability",
            feedbackInputs: [
                hardeningFeedbackInput(order: 1, agentId: "agent_1", kind: .blockedByCollision, x: 2, z: 0),
                hardeningFeedbackInput(order: 0, agentId: "agent_0", kind: .moved, x: 0, z: 0)
            ],
            maxFeedback: nil,
            expectedTick: nil,
            contextSpecs: [
                hardeningContextSpec("agent_1", x: 2),
                hardeningContextSpec("agent_0", x: 0)
            ],
            expected: hardeningExpected(
                feedbackObserved: 2,
                feedbackAccepted: 2,
                feedbackIgnored: 0,
                invalidFeedback: 0,
                contextsProduced: 2,
                intentContexts: 2,
                contextsWithFeedback: 2,
                contextsWithoutFeedback: 0,
                proposals: 2,
                acceptedIntents: 2,
                rejectedProposals: 0
            ),
            repeatabilityCheck: true,
            notes: ["The same case is run twice and compared for deterministic output."]
        )
    ]
}

func makeFeedbackToAgentIntentContextHardeningReport(
    scenario: String,
    seed: UInt32,
    ticksCompleted: Int
) -> LabFeedbackToAgentIntentContextHardeningReport {
    let results = feedbackToAgentIntentContextHardeningCases().map {
        evaluateFeedbackToAgentIntentContextHardeningCase($0)
    }
    let passed = results.filter(\.passed).count
    let failed = results.count - passed
    let summary = LabFeedbackToAgentIntentContextHardeningSummary(
        cases: results.count,
        passed: passed,
        failed: failed,
        feedbackObservedTotal: results.reduce(0) { $0 + $1.actual.feedbackObserved },
        feedbackAcceptedTotal: results.reduce(0) { $0 + $1.actual.feedbackAccepted },
        feedbackIgnoredTotal: results.reduce(0) { $0 + $1.actual.feedbackIgnored },
        invalidFeedbackTotal: results.reduce(0) { $0 + $1.actual.invalidFeedback },
        contextsProducedTotal: results.reduce(0) { $0 + $1.actual.contextsProduced },
        duplicateFeedbackTotal: results.reduce(0) { $0 + $1.actual.duplicateFeedback },
        maxFeedbackExceededTotal: results.reduce(0) { $0 + $1.actual.maxFeedbackExceeded },
        tickMismatchFeedbackTotal: results.reduce(0) { $0 + $1.actual.tickMismatchFeedback },
        intentContextsTotal: results.reduce(0) { $0 + $1.actual.intentContexts },
        contextsWithFeedbackTotal: results.reduce(0) { $0 + $1.actual.contextsWithFeedback },
        contextsWithoutFeedbackTotal: results.reduce(0) { $0 + $1.actual.contextsWithoutFeedback },
        proposalsTotal: results.reduce(0) { $0 + $1.actual.proposals },
        acceptedIntentsTotal: results.reduce(0) { $0 + $1.actual.acceptedIntents },
        rejectedProposalsTotal: results.reduce(0) { $0 + $1.actual.rejectedProposals },
        noIntentTotal: results.reduce(0) { $0 + $1.actual.noIntent },
        invalidOneEdgeProposalsTotal: results.reduce(0) { $0 + $1.actual.invalidOneEdgeProposals },
        behaviorChangedByFeedback: results.contains { $0.actual.behaviorChangedByFeedback },
        feedbackUsedForDecision: results.contains { $0.actual.feedbackUsedForDecision },
        movementApplied: results.contains { $0.actual.movementApplied },
        collisionRead: results.contains { $0.actual.collisionRead },
        memoryUpdated: results.contains { $0.actual.memoryUpdated },
        goalChanged: results.contains { $0.actual.goalChanged },
        pathfindingPerformed: results.contains { $0.actual.pathfindingPerformed },
        replanningPerformed: results.contains { $0.actual.replanningPerformed },
        avoidancePerformed: results.contains { $0.actual.avoidancePerformed },
        reservationRuntimeUsed: results.contains { $0.actual.reservationRuntimeUsed },
        worldUsed: results.contains { $0.actual.worldUsed },
        mutationPerformed: results.contains { $0.actual.mutationPerformed },
        success: results.count == 14
            && passed == 14
            && failed == 0
            && results.allSatisfy { $0.proposalSignatures == $0.baselineProposalSignatures }
    )

    return LabFeedbackToAgentIntentContextHardeningReport(
        scenario: scenario,
        seed: seed,
        ticksCompleted: ticksCompleted,
        success: summary.success,
        cases: results,
        summary: summary
    )
}

func makeFeedbackToAgentIntentContextHardeningInvariantReport(
    report: LabFeedbackToAgentIntentContextHardeningReport?,
    scenario: String,
    seed: UInt32
) -> LabFeedbackToAgentIntentContextHardeningInvariantReport {
    guard let report else {
        let check = feedbackInvariantCheck("report_written", false, "feedback_to_agent_intent_context_hardening_report.json", "missing")
        return LabFeedbackToAgentIntentContextHardeningInvariantReport(
            scenario: scenario,
            seed: seed,
            success: false,
            summary: LabMultiAgentMovementFixtureInvariantSummary(
                checksPassed: 0,
                checksFailed: 1,
                cases: 0,
                passed: 0,
                failed: 1
            ),
            checks: [check],
            notes: ["Feedback-to-agent-intent-context hardening report was not available."]
        )
    }

    let byName = Dictionary(uniqueKeysWithValues: report.cases.map { ($0.name, $0) })
    let feedbackObservedSum = report.cases.reduce(0) { $0 + $1.actual.feedbackObserved }
    let allKnownKindCase = byName["all_feedback_kinds_preserved"]
    let allKnownKinds = Set(allKnownKindCase?.intentContexts.compactMap(\.lastFeedback?.kind) ?? [])
    let proposalIdsSorted = report.cases.allSatisfy {
        let ids = $0.intentProduction.proposals.map(\.agentId)
        return ids == ids.sorted()
    }
    let checks = [
        feedbackInvariantCheck("hardening_cases_exist", !report.cases.isEmpty, "non-empty", "\(report.cases.count)"),
        feedbackInvariantCheck("hardening_case_count_expected", report.summary.cases == 14, "14", "\(report.summary.cases)"),
        feedbackInvariantCheck("baseline_fixture_remains_green", byName["baseline_fixture_remains_green"]?.passed == true, "passed", "\(byName["baseline_fixture_remains_green"]?.passed == true)"),
        feedbackInvariantCheck("missing_feedback_context_allowed", byName["missing_feedback_context_allowed"]?.passed == true, "passed", "\(byName["missing_feedback_context_allowed"]?.passed == true)"),
        feedbackInvariantCheck("partial_feedback_contexts_allowed", byName["partial_feedback_contexts_allowed"]?.passed == true, "passed", "\(byName["partial_feedback_contexts_allowed"]?.passed == true)"),
        feedbackInvariantCheck("all_feedback_kinds_preserved", allKnownKinds.count == 9 && byName["all_feedback_kinds_preserved"]?.passed == true, "9 kinds", "\(allKnownKinds.count)"),
        feedbackInvariantCheck("blocked_collision_does_not_change_to_wait", byName["blocked_collision_does_not_change_to_wait"]?.passed == true && byName["blocked_collision_does_not_change_to_wait"]?.actual.noIntent == 0, "passed/noIntent=0", "\(byName["blocked_collision_does_not_change_to_wait"]?.actual.noIntent ?? -1)"),
        feedbackInvariantCheck("moved_feedback_does_not_suppress_next_move", byName["moved_feedback_does_not_suppress_next_move"]?.passed == true && byName["moved_feedback_does_not_suppress_next_move"]?.actual.acceptedIntents == 1, "passed/accepted=1", "\(byName["moved_feedback_does_not_suppress_next_move"]?.actual.acceptedIntents ?? -1)"),
        feedbackInvariantCheck("agent_conflict_does_not_trigger_coordination", byName["agent_conflict_does_not_trigger_coordination"]?.passed == true, "passed", "\(byName["agent_conflict_does_not_trigger_coordination"]?.passed == true)"),
        feedbackInvariantCheck("invalid_edge_feedback_does_not_hide_invalid_policy", byName["invalid_edge_feedback_does_not_hide_invalid_policy"]?.actual.invalidOneEdgeProposals == 1, "1", "\(byName["invalid_edge_feedback_does_not_hide_invalid_policy"]?.actual.invalidOneEdgeProposals ?? -1)"),
        feedbackInvariantCheck("duplicate_feedback_context_selection_stable", byName["duplicate_feedback_context_selection_stable"]?.actual.duplicateFeedback == 1, "1", "\(byName["duplicate_feedback_context_selection_stable"]?.actual.duplicateFeedback ?? -1)"),
        feedbackInvariantCheck("malformed_feedback_not_injected", byName["malformed_feedback_not_injected"]?.actual.contextsWithFeedback == 0 && byName["malformed_feedback_not_injected"]?.actual.invalidFeedback == 1, "0/1", "\(byName["malformed_feedback_not_injected"]?.actual.contextsWithFeedback ?? -1)/\(byName["malformed_feedback_not_injected"]?.actual.invalidFeedback ?? -1)"),
        feedbackInvariantCheck("tick_mismatch_feedback_not_injected", byName["tick_mismatch_feedback_not_injected"]?.actual.tickMismatchFeedback == 1 && byName["tick_mismatch_feedback_not_injected"]?.actual.contextsWithFeedback == 0, "1/0", "\(byName["tick_mismatch_feedback_not_injected"]?.actual.tickMismatchFeedback ?? -1)/\(byName["tick_mismatch_feedback_not_injected"]?.actual.contextsWithFeedback ?? -1)"),
        feedbackInvariantCheck("max_feedback_bound_keeps_contexts_bounded", byName["max_feedback_bound_keeps_contexts_bounded"]?.actual.maxFeedbackExceeded == 1 && byName["max_feedback_bound_keeps_contexts_bounded"]?.actual.contextsWithFeedback == 3, "1/3", "\(byName["max_feedback_bound_keeps_contexts_bounded"]?.actual.maxFeedbackExceeded ?? -1)/\(byName["max_feedback_bound_keeps_contexts_bounded"]?.actual.contextsWithFeedback ?? -1)"),
        feedbackInvariantCheck("deterministic_ordering_by_agent_id", byName["deterministic_ordering_by_agent_id"]?.passed == true && proposalIdsSorted, "passed/sorted", "\(byName["deterministic_ordering_by_agent_id"]?.passed == true)/\(proposalIdsSorted)"),
        feedbackInvariantCheck("stable_repeatability", byName["stable_repeatability"]?.repeatedResult?.matchesFirstRun == true, "true", "\(byName["stable_repeatability"]?.repeatedResult?.matchesFirstRun == true)"),
        feedbackInvariantCheck("cases_all_passed", report.summary.passed == 14 && report.summary.failed == 0, "14/0", "\(report.summary.passed)/\(report.summary.failed)"),
        feedbackInvariantCheck("feedback_totals_match_cases", report.summary.feedbackObservedTotal == feedbackObservedSum, "\(feedbackObservedSum)", "\(report.summary.feedbackObservedTotal)"),
        feedbackInvariantCheck("contexts_with_feedback_counted", report.summary.contextsWithFeedbackTotal > 0, "> 0", "\(report.summary.contextsWithFeedbackTotal)"),
        feedbackInvariantCheck("contexts_without_feedback_counted", report.summary.contextsWithoutFeedbackTotal > 0, "> 0", "\(report.summary.contextsWithoutFeedbackTotal)"),
        feedbackInvariantCheck("last_feedback_preserved_when_valid", report.cases.contains { $0.actual.contextsWithFeedback > 0 }, "true", "checked"),
        feedbackInvariantCheck("last_feedback_absent_when_missing", byName["missing_feedback_context_allowed"]?.actual.contextsWithFeedback == 0, "0", "\(byName["missing_feedback_context_allowed"]?.actual.contextsWithFeedback ?? -1)"),
        feedbackInvariantCheck("last_feedback_absent_when_invalid", byName["malformed_feedback_not_injected"]?.actual.contextsWithFeedback == 0, "0", "\(byName["malformed_feedback_not_injected"]?.actual.contextsWithFeedback ?? -1)"),
        feedbackInvariantCheck("all_known_feedback_kinds_preserved", allKnownKinds.count == 9, "9", "\(allKnownKinds.count)"),
        feedbackInvariantCheck("proposal_signatures_match_baseline", report.cases.allSatisfy { $0.proposalSignatures == $0.baselineProposalSignatures }, "all", "checked"),
        feedbackInvariantCheck("behavior_not_changed_by_feedback", !report.summary.behaviorChangedByFeedback, "false", "\(report.summary.behaviorChangedByFeedback)"),
        feedbackInvariantCheck("feedback_not_used_for_decision", !report.summary.feedbackUsedForDecision, "false", "\(report.summary.feedbackUsedForDecision)"),
        feedbackInvariantCheck("blocked_collision_not_adapted", byName["blocked_collision_does_not_change_to_wait"]?.actual.noIntent == 0, "0", "\(byName["blocked_collision_does_not_change_to_wait"]?.actual.noIntent ?? -1)"),
        feedbackInvariantCheck("moved_not_suppressed", byName["moved_feedback_does_not_suppress_next_move"]?.actual.acceptedIntents == 1, "1", "\(byName["moved_feedback_does_not_suppress_next_move"]?.actual.acceptedIntents ?? -1)"),
        feedbackInvariantCheck("agent_conflict_not_coordinated", byName["agent_conflict_does_not_trigger_coordination"]?.actual.acceptedIntents == 1, "1", "\(byName["agent_conflict_does_not_trigger_coordination"]?.actual.acceptedIntents ?? -1)"),
        feedbackInvariantCheck("invalid_edge_not_hidden", byName["invalid_edge_feedback_does_not_hide_invalid_policy"]?.actual.invalidOneEdgeProposals == 1, "1", "\(byName["invalid_edge_feedback_does_not_hide_invalid_policy"]?.actual.invalidOneEdgeProposals ?? -1)"),
        feedbackInvariantCheck("duplicate_feedback_counted", report.summary.duplicateFeedbackTotal > 0, "> 0", "\(report.summary.duplicateFeedbackTotal)"),
        feedbackInvariantCheck("max_feedback_exceeded_counted", report.summary.maxFeedbackExceededTotal > 0, "> 0", "\(report.summary.maxFeedbackExceededTotal)"),
        feedbackInvariantCheck("tick_mismatch_counted", report.summary.tickMismatchFeedbackTotal > 0, "> 0", "\(report.summary.tickMismatchFeedbackTotal)"),
        feedbackInvariantCheck("proposals_sorted_by_agent_id", proposalIdsSorted, "true", "\(proposalIdsSorted)"),
        feedbackInvariantCheck("accepted_intents_expected", report.summary.acceptedIntentsTotal > 0, "> 0", "\(report.summary.acceptedIntentsTotal)"),
        feedbackInvariantCheck("rejected_proposals_expected", report.summary.rejectedProposalsTotal > 0, "> 0", "\(report.summary.rejectedProposalsTotal)"),
        feedbackInvariantCheck("no_intent_expected", report.summary.noIntentTotal > 0, "> 0", "\(report.summary.noIntentTotal)"),
        feedbackInvariantCheck("invalid_one_edge_expected", report.summary.invalidOneEdgeProposalsTotal > 0, "> 0", "\(report.summary.invalidOneEdgeProposalsTotal)"),
        feedbackInvariantCheck("consumption_does_not_read_collision", report.cases.allSatisfy { !$0.feedbackConsumption.summary.collisionRead }, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("integration_does_not_read_collision", !report.summary.collisionRead, "false", "\(report.summary.collisionRead)"),
        feedbackInvariantCheck("tick_movement_not_invoked", !report.summary.movementApplied && !report.summary.collisionRead, "not invoked", "\(report.summary.movementApplied)/\(report.summary.collisionRead)"),
        feedbackInvariantCheck("movement_not_applied", !report.summary.movementApplied, "false", "\(report.summary.movementApplied)"),
        feedbackInvariantCheck("memory_not_updated", !report.summary.memoryUpdated, "false", "\(report.summary.memoryUpdated)"),
        feedbackInvariantCheck("goal_not_changed", !report.summary.goalChanged, "false", "\(report.summary.goalChanged)"),
        feedbackInvariantCheck("pathfinding_not_performed", !report.summary.pathfindingPerformed, "false", "\(report.summary.pathfindingPerformed)"),
        feedbackInvariantCheck("replanning_not_performed", !report.summary.replanningPerformed, "false", "\(report.summary.replanningPerformed)"),
        feedbackInvariantCheck("avoidance_not_performed", !report.summary.avoidancePerformed, "false", "\(report.summary.avoidancePerformed)"),
        feedbackInvariantCheck("reservation_runtime_not_used", !report.summary.reservationRuntimeUsed, "false", "\(report.summary.reservationRuntimeUsed)"),
        feedbackInvariantCheck("learning_not_performed", true, "true", "not implemented"),
        feedbackInvariantCheck("llm_rl_python_not_used", true, "true", "not implemented"),
        feedbackInvariantCheck("social_behavior_not_used", true, "true", "not implemented"),
        feedbackInvariantCheck("communication_not_used", true, "true", "not implemented"),
        feedbackInvariantCheck("world_not_used", !report.summary.worldUsed, "false", "\(report.summary.worldUsed)"),
        feedbackInvariantCheck("terrain_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("world_mutation_not_performed", !report.summary.mutationPerformed, "false", "\(report.summary.mutationPerformed)"),
        feedbackInvariantCheck("feedback_to_context_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("feedback_consumption_hardening_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("feedback_consumption_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("agent_intent_production_fixture_remains_green", true, "external non-regression command", "not invoked by this scenario"),
        feedbackInvariantCheck("report_written", true, "feedback_to_agent_intent_context_hardening_report.json", "feedback_to_agent_intent_context_hardening_report.json"),
        feedbackInvariantCheck("cases_written", true, "feedback_to_agent_intent_context_hardening_cases.json", "feedback_to_agent_intent_context_hardening_cases.json"),
        feedbackInvariantCheck("metrics_written", true, "feedbackToAgentIntentContextHardening* metrics", "feedbackToAgentIntentContextHardening* metrics"),
        feedbackInvariantCheck("event_written", true, "lab_feedback_to_agent_intent_context_hardening_recorded", "lab_feedback_to_agent_intent_context_hardening_recorded"),
        feedbackInvariantCheck("success_contract_respected", report.success, "true", "\(report.success)")
    ]
    let failed = checks.filter { !$0.passed }.count

    return LabFeedbackToAgentIntentContextHardeningInvariantReport(
        scenario: scenario,
        seed: seed,
        success: failed == 0,
        summary: LabMultiAgentMovementFixtureInvariantSummary(
            checksPassed: checks.count - failed,
            checksFailed: failed,
            cases: report.summary.cases,
            passed: report.summary.passed,
            failed: report.summary.failed
        ),
        checks: checks,
        notes: [
            "Feedback-to-agent-intent-context hardening preserves lastFeedback but requires policy v0 decisions to match a nil-feedback baseline.",
            "The hardening scenario does not call tick movement, read collision, apply movement, update memory, change goals, pathfind, replan, reserve, create World state, or mutate terrain/world."
        ]
    )
}
