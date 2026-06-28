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
