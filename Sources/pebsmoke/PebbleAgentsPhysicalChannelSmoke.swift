import Foundation
import PebbleAgents

private func physicalSmokeState(_ id: String, x: Int) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: -1, curiosity: 0, safety: 1),
        health: 100,
        fear: 0,
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

private func physicalSmokeSession(
    id: String,
    physicalConfiguration: AgentPhysicalChannelConfiguration = .live
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 4,
        memoryPolicy: .bounded(maxEntries: 64),
        socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
        physicalChannelConfiguration: physicalConfiguration
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            physicalSmokeState("agent_0", x: 3),
            physicalSmokeState("agent_1", x: 0),
            physicalSmokeState("agent_2", x: 1),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setSocialEnabled(true)
    try! session.setPhysicalEnabled(true)
    return session
}

private func physicalSmokeEmit(
    _ session: inout AgentSimulationSession,
    fingerprint: Int = 46
) -> AgentPhysicalSignal {
    let factObservation = AgentResourceObservation(
        resource: .wood,
        target: AgentPosition(x: 2, y: 64, z: 0),
        direction: .east,
        distanceManhattan: 2,
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_1",
        socialResourceObservations: [factObservation]
    )])
    _ = try! session.advanceTick()
    return session.physicalChannelSnapshot().signals.last!
}

private func physicalSmokeObservation(
    signal: AgentPhysicalSignal,
    observer: String = "agent_2",
    tick: Int,
    sound: Int = 95,
    gesture: Int = 95,
    occlusions: Int = 0,
    lineOfSight: Bool = true,
    chunksReady: Bool = true
) -> AgentPhysicalSignalObservation {
    AgentPhysicalSignalObservation(
        signalID: signal.signalID,
        observerID: AgentID(rawValue: observer)!,
        distanceManhattan: observer == "agent_0" ? 3 : 1,
        soundClarity: sound,
        gestureClarity: gesture,
        opaqueOcclusionCount: occlusions,
        lineOfSight: lineOfSight,
        chunksReady: chunksReady,
        observedAtTick: tick
    )
}

func runPebbleAgentsPhysicalChannelSmoke() {
    section("pebble agents local physical channel")

    let defaults = AgentPhysicalChannelConfiguration.live
    check("physical configuration fixes sound radius", defaults.soundRadius == 12)
    check("physical configuration fixes gesture radius", defaults.gestureRadius == 8)
    check("physical configuration fixes lifetime", defaults.signalLifetimeTicks == 3)
    check("physical configuration bounds pending signals", defaults.maximumPendingSignals == 32)
    check("physical configuration bounds perceptions", defaults.maximumRetainedPerceptions == 64)
    check("physical configuration bounds occlusion samples", defaults.maximumOcclusionSamples == 24)
    check("physical configuration uses ordered thresholds", defaults.ambiguousThreshold == 40 && defaults.exactThreshold == 70)
    check("physical configuration rejects zero radius", (try? AgentPhysicalChannelConfiguration(soundRadius: 0)) == nil)
    check("physical configuration rejects zero lifetime", (try? AgentPhysicalChannelConfiguration(signalLifetimeTicks: 0)) == nil)
    check("physical configuration rejects zero capacity", (try? AgentPhysicalChannelConfiguration(maximumPendingSignals: 0)) == nil)
    check("physical configuration rejects inverted thresholds", (try? AgentPhysicalChannelConfiguration(exactThreshold: 40, ambiguousThreshold: 70)) == nil)
    check("physical configuration preserves Codable round trip", (try? JSONDecoder().decode(
        AgentPhysicalChannelConfiguration.self,
        from: JSONEncoder().encode(defaults)
    )) == defaults)
    check("sound clarity is monotonic with distance", defaults.soundClarity(distanceManhattan: 1, opaqueOcclusionCount: 0) > defaults.soundClarity(distanceManhattan: 2, opaqueOcclusionCount: 0))
    check("sound clarity is monotonic with occlusion", defaults.soundClarity(distanceManhattan: 1, opaqueOcclusionCount: 0) > defaults.soundClarity(distanceManhattan: 1, opaqueOcclusionCount: 1))
    check("sound outside radius is missed", defaults.soundClarity(distanceManhattan: 13, opaqueOcclusionCount: 0) == 0)
    check("gesture requires line of sight", defaults.gestureClarity(distanceManhattan: 1, lineOfSight: false) == 0)
    check("gesture outside radius is missed", defaults.gestureClarity(distanceManhattan: 9, lineOfSight: true) == 0)
    check("physical signal ID rejects empty", AgentPhysicalSignalID(rawValue: "") == nil)
    check("physical signal ID comparison is lexical", [AgentPhysicalSignalID(rawValue: "signal-b")!, AgentPhysicalSignalID(rawValue: "signal-a")!].sorted().map(\.rawValue) == ["signal-a", "signal-b"])

    let noLedgerConfiguration = try! AgentSessionConfiguration(
        seed: 46, memoryPolicy: .bounded(maxEntries: 4)
    )
    var noLedger = try! AgentSimulationSession(
        configuration: noLedgerConfiguration,
        agents: [physicalSmokeState("agent_1", x: 0)]
    )
    var ledgerRequired = false
    do { try noLedger.setPhysicalEnabled(true) }
    catch AgentSessionError.physical(.causalLedgerRequired) { ledgerRequired = true }
    catch {}
    check("physical channel requires causal ledger", ledgerRequired)

    var socialRequiredSession = try! AgentSimulationSession(
        configuration: noLedgerConfiguration,
        agents: [physicalSmokeState("agent_1", x: 0)],
        causalLedgerPolicy: .bounded(maxEvents: 16)
    )
    var socialRequired = false
    do { try socialRequiredSession.setPhysicalEnabled(true) }
    catch AgentSessionError.physical(.socialRequired) { socialRequired = true }
    catch {}
    check("physical channel requires social domain", socialRequired)

    var exact = physicalSmokeSession(id: "physical-exact")
    let exactSignal = physicalSmokeEmit(&exact)
    let emissionTick = exact.tick
    check("physical signal emitted at tick N", exactSignal.emittedAtTick == emissionTick)
    check("physical signal carries exactly sound and gesture", exactSignal.modalities == [.attentionSound, .pointingGesture])
    check("physical signal sender is direct observer", exactSignal.senderID.rawValue == "agent_1")
    check("physical signal has one intended recipient", exactSignal.intendedRecipientID.rawValue == "agent_2")
    check("physical signal ID is canonical", exactSignal.signalID.rawValue.hasPrefix("signal-") && exactSignal.signalID.rawValue.count == 23)
    check("physical presentation is emitted once", exact.claimPhysicalPresentationRequests().count == 1 && exact.claimPhysicalPresentationRequests().isEmpty)
    _ = try! exact.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: exactSignal, tick: emissionTick + 1
    )])
    let exactPhysical = exact.physicalChannelSnapshot()
    let exactSocial = exact.socialSnapshot()
    check("exact perception occurs at tick N plus one", exactPhysical.perceptions.last?.observedAtTick == emissionTick + 1)
    check("exact perception decodes", exactPhysical.perceptions.last?.outcome == .exact && exactPhysical.perceptions.last?.decodedEventID != nil)
    check("exact perception creates one existing social message", exactSocial.messages.count == 1)
    check("exact perception creates one existing social belief", exactSocial.beliefs.count == 1)
    let exactMessageCount = exactSocial.messages.count
    _ = try! exact.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: exactSignal, tick: exact.tick + 1
    )])
    check("duplicate terminal perception creates no second message", exact.socialSnapshot().messages.count == exactMessageCount)
    let belief = exact.socialSnapshot().beliefs.first!
    let verificationTick = exact.tick + 1
    let verificationResult = try! exact.advanceTick().agents.first { $0.agentId == "agent_2" }
    check("belief becomes actionable only after perception tick", verificationTick == exact.tick && verificationResult?.action.name == "verify_information")
    let trustBefore = exact.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1")
    let verified = try! exact.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: belief.beliefID,
        verifierID: belief.ownerID,
        position: belief.fact.position,
        chunkReady: true,
        observedBlockFingerprint: belief.fact.expectedBlockFingerprint,
        observedResource: belief.fact.resource
    ))
    check("physical chain reuses CIV-03 verification", verified == .confirmed)
    check("physical chain reuses CIV-03 directed trust", trustBefore == 0 && exact.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == 10)

    var ambiguous = physicalSmokeSession(id: "physical-ambiguous")
    let ambiguousSignal = physicalSmokeEmit(&ambiguous)
    _ = try! ambiguous.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: ambiguousSignal, tick: ambiguous.tick + 1, sound: 60, gesture: 60
    )])
    check("ambiguous perception is retained", ambiguous.physicalChannelSnapshot().perceptions.last?.outcome == .ambiguous)
    check("ambiguous perception creates no message", ambiguous.socialSnapshot().messages.isEmpty)
    check("ambiguous perception changes no trust", ambiguous.trustSnapshot().relations.isEmpty)

    var occluded = physicalSmokeSession(id: "physical-occluded")
    let occludedSignal = physicalSmokeEmit(&occluded)
    _ = try! occluded.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: occludedSignal, tick: occluded.tick + 1,
        sound: 75, gesture: 0, occlusions: 1, lineOfSight: false
    )])
    check("occluded gesture produces missed perception", occluded.physicalChannelSnapshot().perceptions.last?.outcome == .missed)
    check("sound alone creates no message", occluded.socialSnapshot().messages.isEmpty)

    var weakSound = physicalSmokeSession(id: "physical-weak-sound")
    let weakSignal = physicalSmokeEmit(&weakSound)
    _ = try! weakSound.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: weakSignal, tick: weakSound.tick + 1, sound: 20, gesture: 95
    )])
    check("weak sound produces missed perception", weakSound.physicalChannelSnapshot().perceptions.last?.outcome == .missed)
    check("gesture alone creates no message", weakSound.socialSnapshot().messages.isEmpty)

    var retry = physicalSmokeSession(id: "physical-retry")
    let retrySignal = physicalSmokeEmit(&retry)
    _ = try! retry.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: retrySignal, tick: retry.tick + 1,
        sound: 0, gesture: 0, lineOfSight: false, chunksReady: false
    )])
    check("unavailable chunks are inconclusive", retry.physicalChannelSnapshot().perceptions.last?.outcome == .inconclusive)
    check("inconclusive perception creates no message", retry.socialSnapshot().messages.isEmpty)
    _ = try! retry.advanceTick(physicalObservations: [physicalSmokeObservation(
        signal: retrySignal, tick: retry.tick + 1
    )])
    check("inconclusive signal can be retried before expiry", retry.socialSnapshot().messages.count == 1, "status \(retry.physicalChannelSnapshot().signals.last?.status.rawValue ?? "none") tick \(retry.tick)")

    var expired = physicalSmokeSession(id: "physical-expired")
    let expiredSignal = physicalSmokeEmit(&expired)
    for _ in 0..<5 { _ = try! expired.advanceTick() }
    let expiredStatus = expired.physicalChannelSnapshot().signals.first {
        $0.signalID == expiredSignal.signalID
    }?.status
    check("unperceived signal expires deterministically", expiredStatus == .expired, "status \(expiredStatus?.rawValue ?? "none") tick \(expired.tick) expiry \(expiredSignal.expiresAtTick)")
    check("expired signal creates no message or trust", expired.socialSnapshot().messages.isEmpty && expired.trustSnapshot().relations.isEmpty)

    var bystander = physicalSmokeSession(id: "physical-bystander")
    let bystanderSignal = physicalSmokeEmit(&bystander)
    _ = try! bystander.advanceTick(physicalObservations: Array([
        physicalSmokeObservation(signal: bystanderSignal, observer: "agent_2", tick: bystander.tick + 1),
        physicalSmokeObservation(signal: bystanderSignal, observer: "agent_0", tick: bystander.tick + 1),
    ].reversed()))
    let bystanderPerception = bystander.physicalChannelSnapshot().perceptions.first {
        $0.observerID.rawValue == "agent_0"
    }
    check("bystander detects physical activity", bystanderPerception?.outcome == .ambiguous && bystanderPerception?.isIntendedRecipient == false)
    check("bystander receives no belief", !bystander.socialSnapshot().beliefs.contains { $0.ownerID.rawValue == "agent_0" })
    check("bystander changes no trust", bystander.trustScore(sourceAgentId: "agent_0", targetAgentId: "agent_1") == 0)

    var duplicate = physicalSmokeSession(id: "physical-duplicate")
    let duplicateSignal = physicalSmokeEmit(&duplicate)
    let duplicateObservation = physicalSmokeObservation(signal: duplicateSignal, tick: duplicate.tick + 1)
    var duplicateRejected = false
    do { _ = try duplicate.advanceTick(physicalObservations: [duplicateObservation, duplicateObservation]) }
    catch AgentSessionError.physical(.duplicateObservation) { duplicateRejected = true }
    catch {}
    check("duplicate observation in one tick is refused", duplicateRejected)

    let tiny = try! AgentPhysicalChannelConfiguration(
        maximumPendingSignals: 2,
        maximumRetainedPerceptions: 2
    )
    var bounded = physicalSmokeSession(id: "physical-bounded", physicalConfiguration: tiny)
    let boundedSignal = physicalSmokeEmit(&bounded)
    _ = try! bounded.advanceTick(physicalObservations: [
        physicalSmokeObservation(signal: boundedSignal, observer: "agent_0", tick: bounded.tick + 1, sound: 0, gesture: 0, lineOfSight: false, chunksReady: false),
        physicalSmokeObservation(signal: boundedSignal, observer: "agent_1", tick: bounded.tick + 1, sound: 0, gesture: 0, lineOfSight: false, chunksReady: false),
        physicalSmokeObservation(signal: boundedSignal, observer: "agent_2", tick: bounded.tick + 1, sound: 0, gesture: 0, lineOfSight: false, chunksReady: false),
    ])
    check("physical perceptions are bounded", bounded.physicalChannelSnapshot().perceptions.count == 2)
    check("physical eviction count is exposed", bounded.physicalChannelSnapshot().evictionCounts.perceptions == 1)

    let causalKinds = Set(exact.causalLedgerSnapshot().events.map(\.kind))
    check("physical causal chain contains emission perception decode", [.physicalSignalEmitted, .physicalSignalPerceived, .physicalSignalDecoded].allSatisfy(causalKinds.contains))
    check("physical causal causes are prior", exact.causalLedgerSnapshot().events.allSatisfy { event in event.causes.allSatisfy { $0.sequence < event.sequence } })
    check("non-exact perceptions have no decoded event", [ambiguous, occluded, weakSound, expired].flatMap { $0.physicalChannelSnapshot().perceptions }.allSatisfy { $0.decodedEventID == nil })

    var repeatA = physicalSmokeSession(id: "physical-repeat")
    let repeatASignal = physicalSmokeEmit(&repeatA)
    _ = try! repeatA.advanceTick(physicalObservations: [physicalSmokeObservation(signal: repeatASignal, tick: repeatA.tick + 1)])
    var repeatB = physicalSmokeSession(id: "physical-repeat")
    let repeatBSignal = physicalSmokeEmit(&repeatB)
    _ = try! repeatB.advanceTick(physicalObservations: [physicalSmokeObservation(signal: repeatBSignal, tick: repeatB.tick + 1)])
    check("physical digest is repeatable", repeatA.physicalChannelSnapshot() == repeatB.physicalChannelSnapshot())
    check("physical ledger is repeatable", repeatA.causalLedgerSnapshot() == repeatB.causalLedgerSnapshot())

    var gateOff = physicalSmokeSession(id: "physical-off")
    try! gateOff.setPhysicalEnabled(false)
    _ = try! gateOff.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_1",
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 46
        )]
    )])
    _ = try! gateOff.advanceTick()
    check("physical off preserves direct CIV-03 delivery", gateOff.socialSnapshot().messages.count == 1)
    check("physical off emits no physical signal", gateOff.physicalChannelSnapshot().signals.isEmpty)

    var autoOff = physicalSmokeSession(id: "physical-social-off")
    try! autoOff.setSocialEnabled(false)
    check("social off disables physical automatically", !autoOff.physicalEnabled)
}
