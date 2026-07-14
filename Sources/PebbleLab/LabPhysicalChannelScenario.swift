import Foundation
import PebbleAgents

private struct PhysicalScenarioCaseSummary: Encodable, Equatable {
    let name: String
    let signalID: String?
    let outcome: String?
    let messages: Int
    let beliefs: Int
    let trust: Int
    let signalStatus: String?
}

private struct PhysicalScenarioSummary: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let senderID: String
    let recipientID: String
    let bystanderID: String
    let resource: String
    let cases: [PhysicalScenarioCaseSummary]
    let exactSignalID: String
    let exactFactID: String
    let exactMessageID: String
    let exactBeliefID: String
    let exactVerificationEventID: String
    let exactTrustBefore: Int
    let exactTrustAfter: Int
    let materialStateUnchanged: Bool
}

private struct PhysicalScenarioDigest: Encodable, Equatable {
    let schemaVersion = 1
    let physicalDigest: String
    let socialDigest: String
    let causalDigest: String
    let repeatedPhysicalDigest: String
    let repeatedSocialDigest: String
    let repeatedCausalDigest: String
    let deterministic: Bool
}

private struct PhysicalScenarioCheck: Encodable, Equatable {
    let name: String
    let passed: Bool
}

private struct PhysicalScenarioInvariantReport: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [PhysicalScenarioCheck]
}

private struct PhysicalScenarioRun {
    var session: AgentSimulationSession
    let baseline: AgentSessionSnapshot
    let signal: AgentPhysicalSignal
}

private func physicalScenarioState(_ id: String, x: Int) -> AgentSessionAgentState {
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

private func physicalScenarioSession(
    id: String,
    seed: UInt32,
    physicalEnabled: Bool = true
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 6,
        memoryPolicy: .bounded(maxEntries: 64),
        socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
        physicalChannelConfiguration: .live
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            physicalScenarioState("agent_0", x: 3),
            physicalScenarioState("agent_1", x: 0),
            physicalScenarioState("agent_2", x: 1),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.setSocialEnabled(true)
    if physicalEnabled { try! session.setPhysicalEnabled(true) }
    return session
}

private func physicalScenarioEmit(
    id: String,
    seed: UInt32,
    fingerprint: Int = 46
) -> PhysicalScenarioRun {
    var session = physicalScenarioSession(id: id, seed: seed)
    let baseline = session.snapshot()
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_1",
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: fingerprint
        )]
    )])
    for _ in 0..<3 where session.physicalChannelSnapshot().signals.isEmpty {
        _ = try! session.advanceTick()
    }
    return PhysicalScenarioRun(
        session: session,
        baseline: baseline,
        signal: session.physicalChannelSnapshot().signals.first!
    )
}

private func physicalScenarioObservation(
    _ run: PhysicalScenarioRun,
    observer: String = "agent_2",
    sound: Int,
    gesture: Int,
    occlusions: Int = 0,
    lineOfSight: Bool = true,
    chunksReady: Bool = true
) -> AgentPhysicalSignalObservation {
    AgentPhysicalSignalObservation(
        signalID: run.signal.signalID,
        observerID: AgentID(rawValue: observer)!,
        distanceManhattan: observer == "agent_0" ? 3 : 1,
        soundClarity: sound,
        gestureClarity: gesture,
        opaqueOcclusionCount: occlusions,
        lineOfSight: lineOfSight,
        chunksReady: chunksReady,
        observedAtTick: run.session.tick + 1
    )
}

private func physicalScenarioCaseSummary(
    _ name: String,
    _ session: AgentSimulationSession,
    signalID: AgentPhysicalSignalID?
) -> PhysicalScenarioCaseSummary {
    let physical = session.physicalChannelSnapshot()
    let social = session.socialSnapshot()
    let perception = signalID.flatMap { id in
        physical.perceptions.last { $0.signalID == id && $0.observerID.rawValue == "agent_2" }
    }
    let signal = signalID.flatMap { id in physical.signals.first { $0.signalID == id } }
    return PhysicalScenarioCaseSummary(
        name: name,
        signalID: signalID?.rawValue,
        outcome: perception?.outcome.rawValue,
        messages: social.messages.count,
        beliefs: social.beliefs.count,
        trust: session.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1"),
        signalStatus: signal?.status.rawValue
    )
}

private func physicalMaterialSignature(_ snapshot: AgentSessionSnapshot) -> String {
    let inventories = snapshot.agents.map {
        "\($0.id):\($0.resourceInventory.totalCount)"
    }.joined(separator: ",")
    return "\(inventories)|stock=\(snapshot.campStock.totalCount)|reservations=\(snapshot.resourceReservations.count)|construction=\(snapshot.constructionProject?.projectId ?? "none")|balanced=\(snapshot.conservation.balanced ? 1 : 0)"
}

private func runPhysicalExact(seed: UInt32, id: String) -> PhysicalScenarioRun {
    var run = physicalScenarioEmit(id: id, seed: seed)
    _ = run.session.claimPhysicalPresentationRequests()
    let bystander = physicalScenarioObservation(
        run, observer: "agent_0", sound: 85, gesture: 85
    )
    let intended = physicalScenarioObservation(run, sound: 95, gesture: 95)
    _ = try! run.session.advanceTick(physicalObservations: Array([intended, bystander].reversed()))
    let belief = run.session.socialSnapshot().beliefs.first!
    let decision = try! run.session.advanceTick()
    precondition(decision.agents.first { $0.agentId == "agent_2" }?.action.name == "verify_information")
    _ = try! run.session.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: belief.beliefID,
        verifierID: belief.ownerID,
        position: belief.fact.position,
        chunkReady: true,
        observedBlockFingerprint: belief.fact.expectedBlockFingerprint,
        observedResource: belief.fact.resource
    ))
    return run
}

func runPhysicalChannelSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("physical_channel_smoke requires an explicit --out directory")
    }
    let seed = options.seed
    let exact = runPhysicalExact(seed: seed, id: "physical-exact-\(seed)")
    let repeated = runPhysicalExact(seed: seed, id: "physical-exact-\(seed)")

    var occluded = physicalScenarioEmit(id: "physical-occluded-\(seed)", seed: seed)
    _ = try! occluded.session.advanceTick(physicalObservations: [physicalScenarioObservation(
        occluded, sound: 75, gesture: 0, occlusions: 1, lineOfSight: false
    )])
    var weak = physicalScenarioEmit(id: "physical-weak-\(seed)", seed: seed)
    _ = try! weak.session.advanceTick(physicalObservations: [physicalScenarioObservation(
        weak, sound: 20, gesture: 95
    )])
    var ambiguous = physicalScenarioEmit(id: "physical-ambiguous-\(seed)", seed: seed)
    _ = try! ambiguous.session.advanceTick(physicalObservations: [physicalScenarioObservation(
        ambiguous, sound: 60, gesture: 60
    )])
    var retry = physicalScenarioEmit(id: "physical-retry-\(seed)", seed: seed)
    _ = try! retry.session.advanceTick(physicalObservations: [physicalScenarioObservation(
        retry, sound: 0, gesture: 0, lineOfSight: false, chunksReady: false
    )])
    _ = try! retry.session.advanceTick(physicalObservations: [physicalScenarioObservation(
        retry, sound: 90, gesture: 90
    )])
    var expiration = physicalScenarioEmit(id: "physical-expiration-\(seed)", seed: seed)
    while expiration.session.tick <= expiration.signal.expiresAtTick {
        _ = try! expiration.session.advanceTick()
    }

    var gateOff = physicalScenarioSession(
        id: "physical-off-\(seed)", seed: seed, physicalEnabled: false
    )
    let offBaseline = gateOff.snapshot()
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
    for _ in 0..<3 where gateOff.socialSnapshot().messages.isEmpty {
        _ = try! gateOff.advanceTick()
    }

    let exactPhysical = exact.session.physicalChannelSnapshot()
    let exactSocial = exact.session.socialSnapshot()
    let exactBelief = exactSocial.beliefs.first!
    let exactMessage = exactSocial.messages.first!
    let exactPerception = exactPhysical.perceptions.first {
        $0.isIntendedRecipient && $0.outcome == .exact
    }!
    let bystanderPerception = exactPhysical.perceptions.first {
        $0.observerID.rawValue == "agent_0"
    }!
    let exactEvents = exact.session.causalLedgerSnapshot().events.filter {
        switch $0.kind {
        case .resourceFactGrounded, .physicalSignalEmitted, .physicalSignalPerceived,
             .physicalSignalDecoded, .socialMessageSent, .socialMessageReceived,
             .socialBeliefChanged, .socialVerification, .trustChanged:
            return true
        default:
            return false
        }
    }
    let cases = [
        physicalScenarioCaseSummary("exact", exact.session, signalID: exact.signal.signalID),
        physicalScenarioCaseSummary("occluded", occluded.session, signalID: occluded.signal.signalID),
        physicalScenarioCaseSummary("weak_sound", weak.session, signalID: weak.signal.signalID),
        physicalScenarioCaseSummary("ambiguous", ambiguous.session, signalID: ambiguous.signal.signalID),
        physicalScenarioCaseSummary("inconclusive_retry", retry.session, signalID: retry.signal.signalID),
        physicalScenarioCaseSummary("expiration", expiration.session, signalID: expiration.signal.signalID),
        physicalScenarioCaseSummary("gate_off", gateOff, signalID: nil),
    ]
    let materialUnchanged = physicalMaterialSignature(exact.baseline)
        == physicalMaterialSignature(exact.session.snapshot())
        && physicalMaterialSignature(occluded.baseline)
            == physicalMaterialSignature(occluded.session.snapshot())
        && physicalMaterialSignature(offBaseline) == physicalMaterialSignature(gateOff.snapshot())
    let deterministic = exactPhysical == repeated.session.physicalChannelSnapshot()
        && exactSocial == repeated.session.socialSnapshot()
        && exact.session.causalLedgerSnapshot() == repeated.session.causalLedgerSnapshot()
    var checks: [PhysicalScenarioCheck] = []
    func add(_ name: String, _ passed: Bool) {
        checks.append(PhysicalScenarioCheck(name: name, passed: passed))
    }
    add("ids_unique", Set(exactPhysical.signals.map(\.signalID)).count == exactPhysical.signals.count)
    add("order_deterministic", deterministic)
    add("collections_bounded", exactPhysical.signals.count <= 32 && exactPhysical.perceptions.count <= 64)
    add("direct_fact_provenance", exact.signal.senderID == exactBelief.fact.observerID && exact.signal.directObservationEventID == exactBelief.fact.directObservationEventID)
    add("single_intended_recipient", exact.signal.intendedRecipientID.rawValue == "agent_2")
    add("sound_alone_insufficient", weak.session.socialSnapshot().messages.isEmpty)
    add("gesture_alone_insufficient", occluded.session.socialSnapshot().messages.isEmpty)
    add("exact_creates_message", exactPerception.outcome == .exact && exactSocial.messages.count == 1)
    add("ambiguous_creates_no_message", ambiguous.session.socialSnapshot().messages.isEmpty)
    add("missed_creates_no_message", occluded.session.socialSnapshot().messages.isEmpty && weak.session.socialSnapshot().messages.isEmpty)
    add("inconclusive_before_retry_creates_no_trust", retry.session.trustSnapshot().relations.isEmpty)
    add("retry_decodes_before_expiry", retry.session.socialSnapshot().messages.count == 1)
    add("bystander_without_belief", bystanderPerception.outcome == .ambiguous && !exactSocial.beliefs.contains { $0.ownerID.rawValue == "agent_0" })
    add("expiration_without_message", expiration.session.physicalChannelSnapshot().signals.first?.status == .expired && expiration.session.socialSnapshot().messages.isEmpty)
    add("forwarding_absent", exactSocial.messages.allSatisfy { $0.senderID.rawValue == "agent_1" })
    let requiredKinds: [AgentCausalEventKind] = [
        .physicalSignalEmitted, .physicalSignalPerceived, .physicalSignalDecoded,
        .socialMessageReceived, .socialVerification, .trustChanged,
    ]
    add("causal_chain_complete", requiredKinds.allSatisfy { kind in exactEvents.contains { $0.kind == kind } })
    add("causes_prior", exactEvents.allSatisfy { event in event.causes.allSatisfy { $0.sequence < event.sequence } })
    add("material_unchanged", materialUnchanged)
    add("inventories_unchanged", exact.session.snapshot().agents.allSatisfy { $0.resourceInventory.isEmpty })
    add("stock_unchanged", exact.session.snapshot().campStock.totalCount == 0)
    add("trust_only_after_verification", exactBelief.status == .confirmed && exact.session.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1") == 10)
    add("gate_off_compatibility", gateOff.socialSnapshot().messages.count == 1 && gateOff.physicalChannelSnapshot().signals.isEmpty)
    add("digest_stable", deterministic)
    let report = PhysicalScenarioInvariantReport(
        scenario: "physical_channel_smoke",
        seed: seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    guard report.success else {
        fail("physical_channel_smoke invariant failure: \(checks.filter { !$0.passed }.map(\.name).joined(separator: ","))")
    }
    let summary = PhysicalScenarioSummary(
        scenario: "physical_channel_smoke",
        seed: seed,
        senderID: "agent_1",
        recipientID: "agent_2",
        bystanderID: "agent_0",
        resource: exact.signal.resource.rawValue,
        cases: cases,
        exactSignalID: exact.signal.signalID.rawValue,
        exactFactID: exact.signal.factID.rawValue,
        exactMessageID: exactMessage.messageID.rawValue,
        exactBeliefID: exactBelief.beliefID.rawValue,
        exactVerificationEventID: exactBelief.verificationEventID!.rawValue,
        exactTrustBefore: 0,
        exactTrustAfter: exact.session.trustScore(sourceAgentId: "agent_2", targetAgentId: "agent_1"),
        materialStateUnchanged: materialUnchanged
    )
    let digest = PhysicalScenarioDigest(
        physicalDigest: exact.session.physicalChannelSummary().digest,
        socialDigest: exact.session.socialSummary().digest,
        causalDigest: exact.session.causalLedgerSnapshot().summary.digest,
        repeatedPhysicalDigest: repeated.session.physicalChannelSummary().digest,
        repeatedSocialDigest: repeated.session.socialSummary().digest,
        repeatedCausalDigest: repeated.session.causalLedgerSnapshot().summary.digest,
        deterministic: deterministic
    )
    let signals = [exact, occluded, weak, ambiguous, retry, expiration]
        .flatMap { $0.session.physicalChannelSnapshot().signals }
    let perceptions = [exact, occluded, weak, ambiguous, retry, expiration]
        .flatMap { $0.session.physicalChannelSnapshot().perceptions }
    let presentations = [exact, occluded, weak, ambiguous, retry, expiration]
        .flatMap { $0.session.physicalChannelSnapshot().presentations }
    let directory = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writeJSON(signals, to: directory.appendingPathComponent("physical_signals.json"))
        try writeJSON(perceptions, to: directory.appendingPathComponent("physical_perceptions.json"))
        try writeJSON(presentations, to: directory.appendingPathComponent("physical_presentations.json"))
        try writeJSON(exactEvents, to: directory.appendingPathComponent("physical_social_chain.json"))
        try writeJSON(summary, to: directory.appendingPathComponent("physical_summary.json"))
        try writeJSON(digest, to: directory.appendingPathComponent("physical_digest.json"))
        try writeJSON(report, to: directory.appendingPathComponent("physical_invariant_report.json"))
    } catch {
        fail("failed to write physical scenario outputs to \(outPath): \(error)")
    }
    print("physical_channel_smoke PASS signals=\(signals.count) perceptions=\(perceptions.count) trust=\(summary.exactTrustAfter) digest=\(digest.physicalDigest)")
    exit(0)
}
