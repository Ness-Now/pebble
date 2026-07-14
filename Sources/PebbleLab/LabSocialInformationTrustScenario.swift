import Foundation
import PebbleAgents

private struct SocialScenarioCheck: Encodable, Equatable {
    let name: String
    let passed: Bool
}

private struct SocialScenarioInvariantReport: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [SocialScenarioCheck]
}

private struct SocialScenarioSummary: Encodable, Equatable {
    let schemaVersion = 1
    let senderID: String
    let recipientID: String
    let excludedAgentID: String
    let resource: String
    let position: AgentPosition
    let fingerprint: Int
    let factEventID: String
    let messageID: String
    let beliefID: String
    let verificationEventID: String
    let route: [AgentPosition]
    let confirmationTrustBefore: Int
    let confirmationTrustAfter: Int
    let contradictionTrustBefore: Int
    let contradictionTrustAfter: Int
    let expiredBeliefCount: Int
    let thresholdTrust: Int
    let forwardingRejected: Bool
    let urgentGoal: String
    let materialStateUnchanged: Bool
}

private struct SocialScenarioDigestReport: Encodable, Equatable {
    let schemaVersion = 1
    let socialDigest: String
    let causalDigest: String
    let repeatedSocialDigest: String
    let repeatedCausalDigest: String
    let permutationSocialDigest: String
    let deterministic: Bool
}

private struct SocialScenarioRun {
    var session: AgentSimulationSession
    let baseline: AgentSessionSnapshot
    let route: [AgentPosition]
    let result: AgentSocialVerificationResult
}

private func socialScenarioState(
    id: String,
    x: Int,
    fear: Int = 0
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0, safety: 1),
        health: 100,
        fear: fear,
        homePosition: position,
        nearbyAgents: [],
        currentGoal: AgentGoal(kind: .idle, reason: "initial", startedAtTick: 0, urgency: 0),
        lastAction: nil,
        lastActionEffect: nil,
        memory: [],
        tickCreated: 0,
        ticksAlive: 0,
        observationCount: 0,
        nearbyObservationCount: 0,
        goalSelectionCount: 0,
        goalChangeCount: 0,
        actionCount: 0,
        actionEffectCount: 0,
        movementCount: 0,
        totalManhattanDistanceMoved: 0,
        returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func socialScenarioSession(
    simulationID: String,
    seed: UInt32,
    socialConfiguration: AgentSocialConfiguration = .live,
    survivalConfiguration: AgentSurvivalConfiguration = .live,
    reversedAgents: Bool = false,
    includeThirdAgent: Bool = true
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 6,
        memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: survivalConfiguration,
        socialConfiguration: socialConfiguration
    )
    var states = [
        socialScenarioState(id: "agent_1", x: 0),
        socialScenarioState(id: "agent_2", x: 1),
    ]
    if includeThirdAgent { states.append(socialScenarioState(id: "agent_3", x: 8)) }
    if reversedAgents { states.reverse() }
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: states,
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    session.setSurvivalEnabled(true)
    try! session.setSocialEnabled(true)
    return session
}

private func socialScenarioObservation(
    fingerprint: Int,
    targetX: Int,
    resource: AgentResourceKind = .wood
) -> AgentResourceObservation {
    AgentResourceObservation(
        resource: resource,
        target: AgentPosition(x: targetX, y: 64, z: 0),
        direction: .east,
        distanceManhattan: targetX,
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
}

private func socialScenarioPerceptions(
    fingerprint: Int,
    targetX: Int,
    resource: AgentResourceKind = .wood,
    reversed: Bool = false,
    includeThirdAgent: Bool = true
) -> [AgentPerceptionInput] {
    var inputs = [
        AgentPerceptionInput(
            agentId: "agent_1",
            socialResourceObservations: [socialScenarioObservation(
                fingerprint: fingerprint,
                targetX: targetX,
                resource: resource
            )]
        ),
        AgentPerceptionInput(agentId: "agent_2"),
    ]
    if includeThirdAgent { inputs.append(AgentPerceptionInput(agentId: "agent_3")) }
    return reversed ? Array(inputs.reversed()) : inputs
}

private func socialScenarioDirectMessage(
    session: inout AgentSimulationSession,
    fingerprint: Int,
    targetX: Int,
    resource: AgentResourceKind = .wood,
    reversedPerceptions: Bool = false,
    includeThirdAgent: Bool = true
) -> AgentSocialBelief {
    let initialMessageCount = session.socialSnapshot().messages.count
    _ = try! session.advanceTick(perceptions: socialScenarioPerceptions(
        fingerprint: fingerprint,
        targetX: targetX,
        resource: resource,
        reversed: reversedPerceptions,
        includeThirdAgent: includeThirdAgent
    ))
    for _ in 0..<4 {
        _ = try! session.advanceTick()
        if session.socialSnapshot().messages.count > initialMessageCount { break }
    }
    let beliefs = session.socialSnapshot().beliefs
    guard session.socialSnapshot().messages.count > initialMessageCount,
          let newest = beliefs.max(by: {
              if $0.receivedAtTick != $1.receivedAtTick {
                  return $0.receivedAtTick < $1.receivedAtTick
              }
              return $0.beliefID < $1.beliefID
          }) else {
        fail("social scenario did not deliver the expected directed message")
    }
    return newest
}

private func socialScenarioNavigationObservation(
    origin: AgentPosition,
    target: AgentPosition,
    worldTick: Int
) -> AgentNavigationObservation {
    let cells = (-7...9).map { x in
        AgentNavigationCell(
            position: AgentPosition(x: x, y: 64, z: 0),
            status: x == 0 || x == 8 ? .blocked : .traversable
        )
    }
    return AgentNavigationObservation(
        worldTick: worldTick,
        origin: origin,
        target: target,
        radius: AgentNavigationObservation.maximumRadius,
        cells: cells
    )
}

private func socialScenarioWorldObservation(
    position: AgentPosition,
    worldTick: Int
) -> AgentWorldObservation {
    let center = AgentWorldColumnObservation(
        position: position,
        chunkReady: true,
        surfaceY: position.y,
        height: position.y,
        blockBelow: 1,
        blockAtFeet: 0,
        blockAtHead: 0,
        groundPresent: true,
        feetClear: true,
        headClear: true
    )
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        AgentWorldNeighborObservation(
            direction: direction,
            column: AgentWorldColumnObservation(
                position: AgentPosition(
                    x: position.x + direction.dx,
                    y: position.y,
                    z: position.z + direction.dz
                ),
                chunkReady: true,
                surfaceY: position.y,
                height: position.y,
                blockBelow: 1,
                blockAtFeet: 0,
                blockAtHead: 0,
                groundPresent: true,
                feetClear: true,
                headClear: true
            ),
            stepDelta: 0,
            traversable: true,
            dangerousDrop: false
        )
    }
    return try! AgentWorldObservation(
        worldTick: worldTick,
        position: position,
        center: center,
        neighbors: neighbors,
        biomeId: nil,
        biomeName: nil,
        combinedLight: nil,
        skyLight: nil,
        blockLight: nil,
        dayTime: worldTick,
        raining: false,
        thundering: false
    )
}

private func socialScenarioMaterialSignature(_ snapshot: AgentSessionSnapshot) -> String {
    let inventory = snapshot.agents.map { agent in
        AgentResourceKind.allCases.map {
            "\(agent.id):\($0.rawValue):\(agent.resourceInventory.count(of: $0))"
        }.joined(separator: ",")
    }.joined(separator: ";")
    return "\(inventory)|stock=\(snapshot.campStock.totalCount)|reservations=\(snapshot.resourceReservations.count)|harvested=\(snapshot.conservation.harvestedTotal)|construction=\(snapshot.constructionProject?.projectId ?? "none")"
}

private func runSocialConfirmation(
    seed: UInt32,
    simulationID: String,
    reversedInputs: Bool = false
) -> SocialScenarioRun {
    var session = socialScenarioSession(
        simulationID: simulationID,
        seed: seed,
        reversedAgents: reversedInputs
    )
    let baseline = session.snapshot()
    let belief = socialScenarioDirectMessage(
        session: &session,
        fingerprint: 1_520,
        targetX: 5,
        reversedPerceptions: reversedInputs
    )
    var route: [AgentPosition] = [
        session.snapshot().agents.first { $0.id == "agent_2" }!.position,
    ]
    var verificationResult: AgentSocialVerificationResult?
    for _ in 0..<8 {
        guard let request = session.pendingSocialVerificationRequest(for: "agent_2"),
              let recipient = session.snapshot().agents.first(where: { $0.id == "agent_2" }) else {
            fail("social confirmation lost its pending verification request")
        }
        let perception = AgentPerceptionInput(
            agentId: "agent_2",
            worldObservation: socialScenarioWorldObservation(
                position: recipient.position,
                worldTick: session.tick + 1
            ),
            navigationObservation: socialScenarioNavigationObservation(
                origin: recipient.position,
                target: request.position,
                worldTick: session.tick + 1
            )
        )
        let result = try! session.advanceTick(perceptions: [perception])
        let recipientResult = result.agents.first { $0.agentId == "agent_2" }!
        if recipientResult.action.name == "verify_information" {
            verificationResult = try! session.applySocialVerification(
                AgentSocialVerificationObservation(
                    beliefID: belief.beliefID,
                    verifierID: belief.ownerID,
                    position: belief.fact.position,
                    chunkReady: true,
                    observedBlockFingerprint: belief.fact.expectedBlockFingerprint,
                    observedResource: belief.fact.resource
                )
            )
            break
        }
        let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
        try! session.applyMovementOutcomes(outcomes)
        route.append(session.snapshot().agents.first { $0.id == "agent_2" }!.position)
    }
    guard let verificationResult else { fail("social confirmation did not reach read-only verification") }
    return SocialScenarioRun(
        session: session,
        baseline: baseline,
        route: route,
        result: verificationResult
    )
}

private func socialScenarioAdjacentVerification(
    session: inout AgentSimulationSession,
    belief: AgentSocialBelief,
    observedFingerprint: Int?,
    observedResource: AgentResourceKind?,
    chunkReady: Bool = true
) -> AgentSocialVerificationResult {
    for _ in 0..<3 {
        let result = try! session.advanceTick()
        if result.agents.first(where: { $0.agentId == belief.ownerID.rawValue })?.action.name
            == "verify_information" {
            return try! session.applySocialVerification(AgentSocialVerificationObservation(
                beliefID: belief.beliefID,
                verifierID: belief.ownerID,
                position: belief.fact.position,
                chunkReady: chunkReady,
                observedBlockFingerprint: observedFingerprint,
                observedResource: observedResource
            ))
        }
    }
    let owner = session.snapshot().agents.first { $0.id == belief.ownerID.rawValue }!
    let currentBelief = session.socialSnapshot().beliefs.first { $0.beliefID == belief.beliefID }
    let actionName = owner.lastAction?.name ?? "none"
    let beliefStatus = currentBelief?.status.rawValue ?? "missing"
    let trust = session.trustScore(
        sourceAgentId: belief.ownerID.rawValue,
        targetAgentId: belief.senderID.rawValue
    )
    fail("adjacent social verification action was not selected tick=\(session.tick) goal=\(owner.currentGoal.kind.rawValue) action=\(actionName) belief=\(beliefStatus) trust=\(trust)")
}

private func socialScenarioTrustSeries(
    seed: UInt32,
    confirmations: Bool,
    count: Int
) -> AgentSimulationSession {
    let slowSurvival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.001,
        fatiguePerTick: 0.001,
        hungryThreshold: 0.80,
        criticalHungerThreshold: 0.95,
        hungerRecoveryThreshold: 0.20,
        fatigueThreshold: 0.80,
        fatigueRecoveryThreshold: 0.20,
        foodNutrition: 1.0,
        restRecoveryPerTick: 1.0,
        starvationGraceTicks: 2,
        starvationDamagePerTick: 10
    )
    let socialConfiguration = try! AgentSocialConfiguration(
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 12,
        messageLifetimeTicks: 8,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 8,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    var session = socialScenarioSession(
        simulationID: "social-clamp-\(confirmations ? "high" : "low")-\(seed)",
        seed: seed,
        socialConfiguration: socialConfiguration,
        survivalConfiguration: slowSurvival,
        includeThirdAgent: false
    )
    for index in 0..<count {
        let expected = 2_000 + index
        let belief = socialScenarioDirectMessage(
            session: &session,
            fingerprint: expected,
            targetX: 2,
            includeThirdAgent: false
        )
        _ = socialScenarioAdjacentVerification(
            session: &session,
            belief: belief,
            observedFingerprint: confirmations ? expected : 0,
            observedResource: confirmations ? .wood : nil
        )
    }
    return session
}

func runSocialInformationTrustSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("social_information_trust_smoke requires an explicit --out directory")
    }
    let confirmation = runSocialConfirmation(
        seed: options.seed,
        simulationID: "social-confirmation-\(options.seed)"
    )
    let confirmationSnapshot = confirmation.session.socialSnapshot()
    let confirmedBelief = confirmationSnapshot.beliefs.first { $0.status == .confirmed }!
    let mainFact = confirmedBelief.fact
    let mainMessage = confirmationSnapshot.messages.first { $0.messageID == confirmedBelief.messageID }!
    let mainTrust = confirmationSnapshot.trustRelations.first {
        $0.sourceID.rawValue == "agent_2" && $0.targetID.rawValue == "agent_1"
    }!
    let mainLedger = confirmation.session.causalLedgerSnapshot()

    var contradiction = socialScenarioSession(
        simulationID: "social-contradiction-\(options.seed)",
        seed: options.seed,
        includeThirdAgent: false
    )
    let contradictionBaseline = contradiction.snapshot()
    let contradictionBelief = socialScenarioDirectMessage(
        session: &contradiction,
        fingerprint: 48,
        targetX: 2,
        resource: .stone,
        includeThirdAgent: false
    )
    let contradictionResult = socialScenarioAdjacentVerification(
        session: &contradiction,
        belief: contradictionBelief,
        observedFingerprint: 0,
        observedResource: nil
    )

    let shortLived = try! AgentSocialConfiguration(
        claimLifetimeTicks: 4,
        messageLifetimeTicks: 1,
        maximumFactsPerAgent: 4,
        maximumBeliefsPerAgent: 4,
        maximumTrustRelations: 4,
        maximumRetainedMessages: 4,
        shareCooldownTicks: 1
    )
    var expiration = socialScenarioSession(
        simulationID: "social-expiration-\(options.seed)",
        seed: options.seed,
        socialConfiguration: shortLived,
        includeThirdAgent: false
    )
    _ = socialScenarioDirectMessage(
        session: &expiration,
        fingerprint: 1_520,
        targetX: 5,
        includeThirdAgent: false
    )
    _ = try! expiration.advanceTick()
    _ = try! expiration.advanceTick()

    let thresholdConfiguration = try! AgentSocialConfiguration(
        minimumTrustToVerify: -20,
        claimLifetimeTicks: 12,
        messageLifetimeTicks: 8,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 8,
        maximumRetainedMessages: 16,
        shareCooldownTicks: 1
    )
    var threshold = socialScenarioSession(
        simulationID: "social-threshold-\(options.seed)",
        seed: options.seed,
        socialConfiguration: thresholdConfiguration,
        includeThirdAgent: false
    )
    for fingerprint in [100, 101] {
        let belief = socialScenarioDirectMessage(
            session: &threshold,
            fingerprint: fingerprint,
            targetX: 2,
            includeThirdAgent: false
        )
        _ = socialScenarioAdjacentVerification(
            session: &threshold,
            belief: belief,
            observedFingerprint: 0,
            observedResource: nil
        )
    }
    let thresholdMessageCount = threshold.socialSnapshot().messages.count
    _ = try! threshold.advanceTick(perceptions: socialScenarioPerceptions(
        fingerprint: 102,
        targetX: 2,
        includeThirdAgent: false
    ))
    for _ in 0..<3 { _ = try! threshold.advanceTick() }

    let forwardingSequence = confirmation.session.causalLedgerSnapshot().summary.latestSequence
    var forwardingSession = confirmation.session
    var forwardingRejected = false
    do {
        try forwardingSession.attemptToForwardSocialBelief(
            beliefID: confirmedBelief.beliefID,
            by: "agent_2",
            to: "agent_3"
        )
    } catch AgentSessionError.social(.forwardingProhibited) {
        forwardingRejected = true
    } catch {}

    let urgencyConfiguration = try! AgentSocialConfiguration(
        claimLifetimeTicks: 64,
        messageLifetimeTicks: 48,
        maximumFactsPerAgent: 4,
        maximumBeliefsPerAgent: 4,
        maximumTrustRelations: 4,
        maximumRetainedMessages: 4,
        shareCooldownTicks: 8
    )
    var urgency = socialScenarioSession(
        simulationID: "social-urgency-\(options.seed)",
        seed: options.seed,
        socialConfiguration: urgencyConfiguration,
        includeThirdAgent: false
    )
    _ = socialScenarioDirectMessage(
        session: &urgency,
        fingerprint: 1_520,
        targetX: 5,
        includeThirdAgent: false
    )
    urgency.setSurvivalEnabled(true)
    var urgentGoal = AgentGoalKind.idle
    for _ in 0..<9 {
        let result = try! urgency.advanceTick()
        urgentGoal = result.agents.first { $0.agentId == "agent_2" }!.snapshot.currentGoal.kind
    }

    let highClamp = socialScenarioTrustSeries(
        seed: options.seed,
        confirmations: true,
        count: 11
    )
    let lowClamp = socialScenarioTrustSeries(
        seed: options.seed,
        confirmations: false,
        count: 8
    )
    let repeatRun = runSocialConfirmation(
        seed: options.seed,
        simulationID: "social-confirmation-\(options.seed)"
    )
    let permutationRun = runSocialConfirmation(
        seed: options.seed,
        simulationID: "social-confirmation-\(options.seed)",
        reversedInputs: true
    )

    let socialEvents = mainLedger.events.filter {
        switch $0.kind {
        case .resourceFactGrounded, .socialMessageSent, .socialMessageReceived,
             .socialBeliefChanged, .socialVerification, .trustChanged:
            return true
        default:
            return false
        }
    }
    let causalKinds = Set(socialEvents.map(\.kind))
    let mainMaterialUnchanged = socialScenarioMaterialSignature(confirmation.baseline)
        == socialScenarioMaterialSignature(confirmation.session.snapshot())
    let contradictionMaterialUnchanged = socialScenarioMaterialSignature(contradictionBaseline)
        == socialScenarioMaterialSignature(contradiction.snapshot())
    let allFacts = confirmationSnapshot.facts
        + contradiction.socialSnapshot().facts
        + expiration.socialSnapshot().facts
        + threshold.socialSnapshot().facts
    let allMessages = confirmationSnapshot.messages
        + contradiction.socialSnapshot().messages
        + expiration.socialSnapshot().messages
        + threshold.socialSnapshot().messages
    let allBeliefs = confirmationSnapshot.beliefs
        + contradiction.socialSnapshot().beliefs
        + expiration.socialSnapshot().beliefs
        + threshold.socialSnapshot().beliefs
    let allTrust = confirmationSnapshot.trustRelations
        + contradiction.socialSnapshot().trustRelations
        + threshold.socialSnapshot().trustRelations
    let duplicateKeys = allMessages.map {
        "\($0.senderID.rawValue)|\($0.recipientID.rawValue)|\($0.fact.factID.rawValue)|\($0.fact.directObservationEventID.rawValue)"
    }
    let deterministic = confirmation.session.socialSnapshot() == repeatRun.session.socialSnapshot()
        && mainLedger == repeatRun.session.causalLedgerSnapshot()
        && confirmation.session.socialSnapshot() == permutationRun.session.socialSnapshot()
        && mainLedger == permutationRun.session.causalLedgerSnapshot()
    let checks = [
        SocialScenarioCheck(name: "first_hand_facts_only", passed: allFacts.allSatisfy { $0.observerID.rawValue == "agent_1" }),
        SocialScenarioCheck(name: "wood_stone_only", passed: allFacts.allSatisfy { $0.resource == .wood || $0.resource == .stone }),
        SocialScenarioCheck(name: "direct_provenance_valid", passed: allFacts.allSatisfy { $0.source == .naturalWorld && !$0.directObservationEventID.rawValue.isEmpty }),
        SocialScenarioCheck(name: "sender_differs_from_recipient", passed: allMessages.allSatisfy { $0.senderID != $0.recipientID }),
        SocialScenarioCheck(name: "communication_radius_respected", passed: mainMessage.senderID.rawValue == "agent_1" && mainMessage.recipientID.rawValue == "agent_2"),
        SocialScenarioCheck(name: "single_recipient_third_excluded", passed: !confirmationSnapshot.messages.contains { $0.recipientID.rawValue == "agent_3" }),
        SocialScenarioCheck(name: "no_forwarding", passed: forwardingRejected && forwardingSession.socialSnapshot().messages == confirmationSnapshot.messages),
        SocialScenarioCheck(name: "no_duplicate_message", passed: Set(duplicateKeys).count == duplicateKeys.count),
        SocialScenarioCheck(name: "expiration_zero_delta", passed: expiration.socialSnapshot().beliefs.contains { $0.status == .expired } && expiration.trustSnapshot().relations.isEmpty),
        SocialScenarioCheck(name: "collections_bounded", passed: confirmationSnapshot.facts.count <= 24 && allMessages.count <= 64 && allBeliefs.count <= 64),
        SocialScenarioCheck(name: "confirmation_plus_ten", passed: confirmation.result == .confirmed && mainTrust.score == 10),
        SocialScenarioCheck(name: "contradiction_minus_fifteen", passed: contradictionResult == .contradicted && contradiction.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -15),
        SocialScenarioCheck(name: "trust_clamp_high", passed: highClamp.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == 100),
        SocialScenarioCheck(name: "trust_clamp_low", passed: lowClamp.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -100),
        SocialScenarioCheck(name: "trust_directed", passed: confirmation.session.trustScore(sourceAgentId: "agent_1", targetAgentId: "agent_2") == 0),
        SocialScenarioCheck(name: "threshold_blocks_delivery", passed: threshold.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -30 && threshold.socialSnapshot().messages.count == thresholdMessageCount),
        SocialScenarioCheck(name: "complete_cause_chain", passed: [AgentCausalEventKind.resourceFactGrounded, .socialMessageSent, .socialMessageReceived, .socialBeliefChanged, .socialVerification, .trustChanged].allSatisfy { causalKinds.contains($0) }),
        SocialScenarioCheck(name: "causes_are_prior", passed: socialEvents.allSatisfy { event in event.causes.allSatisfy { $0.simulationID == event.simulationID && $0.sequence < event.sequence } }),
        SocialScenarioCheck(name: "world_material_state_unchanged", passed: mainMaterialUnchanged && contradictionMaterialUnchanged),
        SocialScenarioCheck(name: "inventories_unchanged", passed: confirmation.session.snapshot().agents.allSatisfy { $0.resourceInventory.isEmpty }),
        SocialScenarioCheck(name: "no_resource_reservation", passed: confirmation.session.snapshot().resourceReservations.isEmpty && confirmation.session.snapshot().agents.allSatisfy { $0.resourceReservation == nil }),
        SocialScenarioCheck(name: "bounded_social_navigation", passed: confirmation.route.count > 1 && confirmation.route.count <= AgentBoundedRoutePlanner.maximumRouteSteps),
        SocialScenarioCheck(name: "urgency_preempts_social", passed: urgentGoal == .satisfyHunger && urgency.socialSnapshot().beliefs.contains { $0.status == .unverified }),
        SocialScenarioCheck(name: "forwarding_refusal_has_no_event", passed: forwardingSession.causalLedgerSnapshot().summary.latestSequence == forwardingSequence),
        SocialScenarioCheck(name: "input_permutation_equivalent", passed: confirmation.session.socialSnapshot() == permutationRun.session.socialSnapshot()),
        SocialScenarioCheck(name: "ledger_permutation_equivalent", passed: mainLedger == permutationRun.session.causalLedgerSnapshot()),
        SocialScenarioCheck(name: "digest_repeatable", passed: deterministic),
    ]
    let report = SocialScenarioInvariantReport(
        scenario: "social_information_trust_smoke",
        seed: options.seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    guard report.success else {
        fail("social_information_trust_smoke invariant failure: \(checks.filter { !$0.passed }.map(\.name).joined(separator: ","))")
    }

    let summary = SocialScenarioSummary(
        senderID: "agent_1",
        recipientID: "agent_2",
        excludedAgentID: "agent_3",
        resource: mainFact.resource.rawValue,
        position: mainFact.position,
        fingerprint: mainFact.expectedBlockFingerprint,
        factEventID: mainFact.directObservationEventID.rawValue,
        messageID: mainMessage.messageID.rawValue,
        beliefID: confirmedBelief.beliefID.rawValue,
        verificationEventID: confirmedBelief.verificationEventID!.rawValue,
        route: confirmation.route,
        confirmationTrustBefore: 0,
        confirmationTrustAfter: mainTrust.score,
        contradictionTrustBefore: 0,
        contradictionTrustAfter: contradiction.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1"),
        expiredBeliefCount: expiration.socialSummary().expiredBeliefCount,
        thresholdTrust: threshold.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1"),
        forwardingRejected: forwardingRejected,
        urgentGoal: urgentGoal.rawValue,
        materialStateUnchanged: mainMaterialUnchanged && contradictionMaterialUnchanged
    )
    let digest = SocialScenarioDigestReport(
        socialDigest: confirmation.session.socialSummary().digest,
        causalDigest: mainLedger.summary.digest,
        repeatedSocialDigest: repeatRun.session.socialSummary().digest,
        repeatedCausalDigest: repeatRun.session.causalLedgerSnapshot().summary.digest,
        permutationSocialDigest: permutationRun.session.socialSummary().digest,
        deterministic: deterministic
    )
    let directory = URL(fileURLWithPath: outPath, isDirectory: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writeSocialScenarioJSON(allFacts, name: "social_facts.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(allMessages, name: "social_messages.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(allBeliefs, name: "social_beliefs.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(allTrust, name: "social_trust.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(socialEvents, name: "social_causal_chain.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(summary, name: "social_summary.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(digest, name: "social_digest.json", directory: directory, encoder: encoder)
        try writeSocialScenarioJSON(report, name: "social_invariant_report.json", directory: directory, encoder: encoder)
    } catch {
        fail("failed to write social scenario outputs to \(outPath): \(error)")
    }
    print("social_information_trust_smoke PASS facts=\(allFacts.count) messages=\(allMessages.count) beliefs=\(allBeliefs.count) trust=\(allTrust.count) digest=\(digest.socialDigest)")
    exit(0)
}

private func writeSocialScenarioJSON<T: Encodable>(
    _ value: T,
    name: String,
    directory: URL,
    encoder: JSONEncoder
) throws {
    let data = try encoder.encode(value)
    try (data + Data([0x0A])).write(
        to: directory.appendingPathComponent(name),
        options: .atomic
    )
}
