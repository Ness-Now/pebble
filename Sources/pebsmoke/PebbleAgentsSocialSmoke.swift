import Foundation
import PebbleAgents

private func socialSmokeState(
    _ id: String,
    x: Int,
    fear: Int = 0,
    health: Int = 100,
    fatigue: Double = 0
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: fatigue, curiosity: 0, safety: 1),
        health: health,
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

private func socialSmokeSession(
    id: String,
    configuration: AgentSocialConfiguration = .live,
    agents: [AgentSessionAgentState]? = nil
) -> AgentSimulationSession {
    let sessionConfiguration = try! AgentSessionConfiguration(
        seed: 42,
        nearbyRadius: 8,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 4,
        memoryPolicy: .bounded(maxEntries: 64),
        socialConfiguration: configuration
    )
    var session = try! AgentSimulationSession(
        configuration: sessionConfiguration,
        agents: agents ?? [
            socialSmokeState("agent_1", x: 0),
            socialSmokeState("agent_2", x: 1),
            socialSmokeState("agent_3", x: 8),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 2048)
    )
    try! session.setSocialEnabled(true)
    return session
}

private func socialSmokeObservation(
    fingerprint: Int,
    targetX: Int = 2,
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

private func socialSmokePerception(
    fingerprint: Int,
    targetX: Int = 2,
    resource: AgentResourceKind = .wood
) -> AgentPerceptionInput {
    AgentPerceptionInput(
        agentId: "agent_1",
        socialResourceObservations: [socialSmokeObservation(
            fingerprint: fingerprint,
            targetX: targetX,
            resource: resource
        )]
    )
}

@discardableResult
private func socialSmokeDirectMessage(
    session: inout AgentSimulationSession,
    fingerprint: Int,
    targetX: Int = 2,
    resource: AgentResourceKind = .wood
) -> AgentSocialBelief {
    let messageCountBefore = session.socialSnapshot().messages.count
    _ = try! session.advanceTick(perceptions: [socialSmokePerception(
        fingerprint: fingerprint,
        targetX: targetX,
        resource: resource
    )])
    for _ in 0..<4 {
        _ = try! session.advanceTick()
        if session.socialSnapshot().messages.count > messageCountBefore { break }
    }
    let snapshot = session.socialSnapshot()
    let newest = snapshot.beliefs.max {
        if $0.receivedAtTick != $1.receivedAtTick { return $0.receivedAtTick < $1.receivedAtTick }
        return $0.beliefID < $1.beliefID
    }!
    precondition(snapshot.messages.count > messageCountBefore)
    return newest
}

@discardableResult
private func socialSmokeVerify(
    session: inout AgentSimulationSession,
    belief: AgentSocialBelief,
    fingerprint: Int?,
    resource: AgentResourceKind?,
    chunkReady: Bool = true
) -> AgentSocialVerificationResult {
    let result = try! session.advanceTick()
    let action = result.agents.first { $0.agentId == belief.ownerID.rawValue }?.action
    precondition(
        action?.name == "verify_information",
        "expected verify_information at tick \(session.tick), got \(action?.name ?? "none") goal \(result.agents.first { $0.agentId == belief.ownerID.rawValue }?.snapshot.currentGoal.kind.rawValue ?? "none") belief \(belief.beliefID.rawValue) status \(session.socialSnapshot().beliefs.first { $0.beliefID == belief.beliefID }?.status.rawValue ?? "missing")"
    )
    return try! session.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: belief.beliefID,
        verifierID: belief.ownerID,
        position: belief.fact.position,
        chunkReady: chunkReady,
        observedBlockFingerprint: fingerprint,
        observedResource: resource
    ))
}

private func socialSmokeTrustSeries(
    confirmations: Bool,
    count: Int
) -> AgentSimulationSession {
    let configuration = try! AgentSocialConfiguration(
        minimumTrustToVerify: -100,
        claimLifetimeTicks: 12,
        messageLifetimeTicks: 8,
        maximumFactsPerAgent: 8,
        maximumBeliefsPerAgent: 8,
        maximumTrustRelations: 8,
        maximumRetainedMessages: 32,
        shareCooldownTicks: 1
    )
    var session = socialSmokeSession(
        id: "social-trust-series-\(confirmations ? "up" : "down")",
        configuration: configuration,
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    for index in 0..<count {
        let expected = 1_000 + index
        let belief = socialSmokeDirectMessage(session: &session, fingerprint: expected)
        _ = socialSmokeVerify(
            session: &session,
            belief: belief,
            fingerprint: confirmations ? expected : expected + 10_000,
            resource: confirmations ? .wood : .stone
        )
    }
    return session
}

func runPebbleAgentsSocialSmoke() {
    section("pebble agents grounded social information and directed trust")

    check("social fact ID rejects empty", AgentSocialFactID(rawValue: "") == nil)
    check("social message ID rejects whitespace", AgentSocialMessageID(rawValue: "bad id") == nil)
    check("social belief ID rejects overlong payload", AgentSocialBeliefID(rawValue: String(repeating: "a", count: 513)) == nil)
    check("social relation ID comparison is lexical", [
        AgentTrustRelationID(rawValue: "trust-b")!,
        AgentTrustRelationID(rawValue: "trust-a")!,
    ].sorted().map(\.rawValue) == ["trust-a", "trust-b"])
    let socialIDs = [
        AgentSocialFactID(rawValue: "fact-a")!.rawValue,
        AgentSocialMessageID(rawValue: "message-a")!.rawValue,
        AgentSocialBeliefID(rawValue: "belief-a")!.rawValue,
        AgentTrustRelationID(rawValue: "trust-a")!.rawValue,
    ]
    check("social identifiers remain explicitly bounded", socialIDs.allSatisfy { $0.count < 64 })

    let defaults = AgentSocialConfiguration.live
    check("social configuration fixes local communication radius", defaults.communicationRadius == 8)
    check("social configuration fixes verification trust threshold", defaults.minimumTrustToVerify == -20)
    check("social configuration fixes directed trust deltas", defaults.confirmedTrustDelta == 10 && defaults.contradictedTrustDelta == -15)
    check("social configuration fixes trust clamps", defaults.minimumTrust == -100 && defaults.maximumTrust == 100)
    check("social configuration bounds every retained collection", defaults.maximumFactsPerAgent == 8 && defaults.maximumBeliefsPerAgent == 8 && defaults.maximumTrustRelations == 32 && defaults.maximumRetainedMessages == 32)
    check("social configuration uses finite lifetimes and cooldown", defaults.claimLifetimeTicks == 12 && defaults.messageLifetimeTicks == 8 && defaults.shareCooldownTicks == 8)
    check("social configuration rejects zero lifetime", (try? AgentSocialConfiguration(claimLifetimeTicks: 0)) == nil)
    check("social configuration rejects inverted trust bounds", (try? AgentSocialConfiguration(minimumTrust: 1, maximumTrust: 0)) == nil)
    check("social configuration preserves Codable round trip", (try? JSONDecoder().decode(
        AgentSocialConfiguration.self,
        from: JSONEncoder().encode(defaults)
    )) == defaults)

    let noLedgerConfiguration = try! AgentSessionConfiguration(
        seed: 1, memoryPolicy: .bounded(maxEntries: 4)
    )
    var noLedger = try! AgentSimulationSession(
        configuration: noLedgerConfiguration,
        agents: [socialSmokeState("agent_1", x: 0)]
    )
    var ledgerRequired = false
    do { try noLedger.setSocialEnabled(true) }
    catch AgentSessionError.social(.causalLedgerRequired) { ledgerRequired = true }
    catch {}
    check("social activation requires causal grounding ledger", ledgerRequired && !noLedger.socialEnabled)

    var confirmation = socialSmokeSession(id: "social-confirmation")
    let baseline = confirmation.snapshot()
    let confirmBelief = socialSmokeDirectMessage(session: &confirmation, fingerprint: 1_520)
    let received = confirmation.socialSnapshot()
    check("direct natural wood observation grounds one fact", received.facts.count == 1 && received.facts[0].resource == .wood && received.facts[0].source == .naturalWorld)
    check("grounded fact retains exact fingerprint and stable key", received.facts[0].expectedBlockFingerprint == 1_520 && received.facts[0].stableKey.contains("naturalWorld:wood"))
    check("directed message has one distinct recipient", received.messages.count == 1 && received.messages[0].senderID.rawValue == "agent_1" && received.messages[0].recipientID.rawValue == "agent_2")
    check("nearest eligible recipient wins deterministic selection", received.beliefs.count == 1 && received.beliefs[0].ownerID.rawValue == "agent_2")
    check("third agent remains outside the directed delivery", !received.messages.contains { $0.recipientID.rawValue == "agent_3" })
    check("received claim remains distinct unverified belief", confirmBelief.status == .unverified && confirmBelief.reason.contains("World not yet checked"))
    check("social observation creates no material target", confirmation.snapshot().agents.allSatisfy { $0.activeResourceTarget == nil && $0.resourceReservation == nil })
    check("social message is exploitable only on following tick", confirmation.snapshot().agents.first { $0.id == "agent_2" }?.currentGoal.kind != .verifySocialInformation)
    let confirmationResult = socialSmokeVerify(
        session: &confirmation,
        belief: confirmBelief,
        fingerprint: 1_520,
        resource: .wood
    )
    let confirmed = confirmation.socialSnapshot()
    check("matching read-only fingerprint confirms belief", confirmationResult == .confirmed && confirmed.beliefs[0].status == .confirmed)
    check("confirmation changes recipient-to-sender trust by ten", confirmation.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == 10)
    check("directed trust does not imply reverse trust", confirmation.trustScore(sourceAgentId: "agent_1", targetAgentId: "agent_2") == 0)
    check("social vertical preserves inventories and camp stock", confirmation.snapshot().agents.map(\.resourceInventory) == baseline.agents.map(\.resourceInventory) && confirmation.snapshot().campStock == baseline.campStock)
    check("social vertical preserves conservation and construction", confirmation.snapshot().conservation == baseline.conservation && confirmation.snapshot().constructionProject == nil)

    var contradiction = socialSmokeSession(
        id: "social-contradiction",
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    let contradictedBelief = socialSmokeDirectMessage(session: &contradiction, fingerprint: 48)
    let contradictionResult = socialSmokeVerify(
        session: &contradiction,
        belief: contradictedBelief,
        fingerprint: 0,
        resource: nil
    )
    check("mismatching loaded cell contradicts belief", contradictionResult == .contradicted && contradiction.socialSnapshot().beliefs[0].status == .contradicted)
    check("contradiction changes recipient-to-sender trust by fifteen", contradiction.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -15)

    var inconclusive = socialSmokeSession(
        id: "social-inconclusive",
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    let inconclusiveBelief = socialSmokeDirectMessage(session: &inconclusive, fingerprint: 48)
    let inconclusiveResult = socialSmokeVerify(
        session: &inconclusive,
        belief: inconclusiveBelief,
        fingerprint: nil,
        resource: nil,
        chunkReady: false
    )
    check("unavailable chunk leaves belief unverified", inconclusiveResult == .inconclusive && inconclusive.socialSnapshot().beliefs[0].status == .unverified)
    check("inconclusive verification changes no trust", inconclusive.trustSnapshot().relations.isEmpty)

    let shortLived = try! AgentSocialConfiguration(
        claimLifetimeTicks: 4,
        messageLifetimeTicks: 1,
        maximumFactsPerAgent: 4,
        maximumBeliefsPerAgent: 4,
        maximumTrustRelations: 4,
        maximumRetainedMessages: 4,
        shareCooldownTicks: 1
    )
    var expiration = socialSmokeSession(
        id: "social-expiration",
        configuration: shortLived,
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    _ = socialSmokeDirectMessage(session: &expiration, fingerprint: 48, targetX: 5)
    _ = try! expiration.advanceTick()
    _ = try! expiration.advanceTick()
    check("unverified belief expires deterministically", expiration.socialSnapshot().beliefs[0].status == .expired)
    check("belief expiration changes no trust", expiration.trustSnapshot().relations.isEmpty)

    let clampedHigh = socialSmokeTrustSeries(confirmations: true, count: 11)
    let clampedLow = socialSmokeTrustSeries(confirmations: false, count: 8)
    check("directed trust clamps at positive bound", clampedHigh.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == 100)
    check("directed trust clamps at negative bound", clampedLow.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -100)

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
    var threshold = socialSmokeSession(
        id: "social-threshold",
        configuration: thresholdConfiguration,
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    for fingerprint in [100, 101] {
        let belief = socialSmokeDirectMessage(session: &threshold, fingerprint: fingerprint)
        _ = socialSmokeVerify(
            session: &threshold,
            belief: belief,
            fingerprint: 0,
            resource: nil
        )
    }
    let messagesBeforeThresholdRefusal = threshold.socialSnapshot().messages.count
    _ = try! threshold.advanceTick(perceptions: [socialSmokePerception(fingerprint: 102)])
    _ = try! threshold.advanceTick()
    check("trust below threshold blocks new directed message", threshold.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == -30 && threshold.socialSnapshot().messages.count == messagesBeforeThresholdRefusal)

    let sequenceBeforeForwarding = confirmation.causalLedgerSnapshot().summary.latestSequence
    var forwardingRejected = false
    do {
        try confirmation.attemptToForwardSocialBelief(
            beliefID: confirmBelief.beliefID,
            by: "agent_2",
            to: "agent_3"
        )
    } catch AgentSessionError.social(.forwardingProhibited) { forwardingRejected = true }
    catch {}
    check("received belief cannot be forwarded", forwardingRejected)
    check("forwarding refusal creates no causal success", confirmation.causalLedgerSnapshot().summary.latestSequence == sequenceBeforeForwarding)

    var urgent = socialSmokeSession(
        id: "social-urgent",
        configuration: try! AgentSocialConfiguration(
            claimLifetimeTicks: 64,
            messageLifetimeTicks: 48,
            maximumFactsPerAgent: 4,
            maximumBeliefsPerAgent: 4,
            maximumTrustRelations: 4,
            maximumRetainedMessages: 4,
            shareCooldownTicks: 8
        ),
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)]
    )
    _ = socialSmokeDirectMessage(session: &urgent, fingerprint: 1_520, targetX: 5)
    urgent.setSurvivalEnabled(true)
    var urgentResult: AgentSessionTickResult?
    for _ in 0..<9 { urgentResult = try! urgent.advanceTick() }
    let urgentAgent = urgentResult?.agents.first { $0.agentId == "agent_2" }
    check("survival urgency preempts active social verification", urgentAgent?.snapshot.currentGoal.kind == .satisfyHunger && urgentAgent?.action.name != "verify_information")
    check("preempted social belief remains unverified", urgent.socialSnapshot().beliefs[0].status == .unverified)

    let socialKinds = Set(confirmation.causalLedgerSnapshot().events.map(\.kind))
    check("causal ledger distinguishes complete social chain", [
        AgentCausalEventKind.resourceFactGrounded,
        .socialMessageSent,
        .socialMessageReceived,
        .socialBeliefChanged,
        .socialVerification,
        .trustChanged,
    ].allSatisfy { socialKinds.contains($0) })
    check("every social causal reference is prior and same simulation", confirmation.causalLedgerSnapshot().events.filter { $0.kind == .resourceFactGrounded || $0.kind == .socialMessageSent || $0.kind == .socialMessageReceived || $0.kind == .socialBeliefChanged || $0.kind == .socialVerification || $0.kind == .trustChanged }.allSatisfy { event in
        event.causes.allSatisfy { $0.simulationID == event.simulationID && $0.sequence < event.sequence }
    })
    check("social snapshot preserves Codable round trip", (try? JSONDecoder().decode(
        AgentSocialSnapshot.self,
        from: JSONEncoder().encode(confirmation.socialSnapshot())
    )) == confirmation.socialSnapshot())

    let permutationConfig = AgentSocialConfiguration.live
    let permutationStates = [
        socialSmokeState("agent_1", x: 0),
        socialSmokeState("agent_2", x: 1),
        socialSmokeState("agent_3", x: 8),
    ]
    var permutationA = socialSmokeSession(
        id: "social-permutation",
        configuration: permutationConfig,
        agents: permutationStates
    )
    var permutationB = socialSmokeSession(
        id: "social-permutation",
        configuration: permutationConfig,
        agents: Array(permutationStates.reversed())
    )
    let sender = socialSmokePerception(fingerprint: 1_520)
    let empty2 = AgentPerceptionInput(agentId: "agent_2")
    let empty3 = AgentPerceptionInput(agentId: "agent_3")
    _ = try! permutationA.advanceTick(perceptions: [sender, empty2, empty3])
    _ = try! permutationB.advanceTick(perceptions: [empty3, empty2, sender])
    _ = try! permutationA.advanceTick(perceptions: [empty3, empty2, sender])
    _ = try! permutationB.advanceTick(perceptions: [sender, empty2, empty3])
    check("agent and perception permutations preserve social snapshot", permutationA.socialSnapshot() == permutationB.socialSnapshot())
    check("agent and perception permutations preserve causal ledger", permutationA.causalLedgerSnapshot() == permutationB.causalLedgerSnapshot())
    check("agent and perception permutations preserve social digest", permutationA.socialSummary().digest == permutationB.socialSummary().digest)

    var disabled = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 42,
            resourceObservationRadius: 8,
            memoryPolicy: .bounded(maxEntries: 8)
        ),
        agents: [socialSmokeState("agent_1", x: 0), socialSmokeState("agent_2", x: 1)],
        simulationID: try! AgentSimulationID(validating: "social-disabled"),
        causalLedgerPolicy: .bounded(maxEvents: 32)
    )
    let disabledLedgerBefore = disabled.causalLedgerSnapshot().summary.latestSequence
    _ = try! disabled.advanceTick(perceptions: [socialSmokePerception(fingerprint: 1_520)])
    check("disabled social gate derives no state", disabled.socialSnapshot().facts.isEmpty && disabled.socialSnapshot().messages.isEmpty && disabled.socialSnapshot().beliefs.isEmpty && disabled.trustSnapshot().relations.isEmpty)
    check("disabled social gate emits no social causal event", disabled.socialSnapshot().socialCausalEventCount == 0 && disabled.causalLedgerSnapshot().summary.latestSequence == disabledLedgerBefore + 7)
}
