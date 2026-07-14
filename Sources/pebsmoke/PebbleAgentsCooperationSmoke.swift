import Foundation
import PebbleAgents

private let cooperationHome = AgentPosition(x: 0, y: 64, z: 0)
private let cooperationOrigin = AgentPosition(x: 2, y: 64, z: 1)

private func cooperationSmokeState(
    _ id: String,
    x: Int,
    fear: Int = 0
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: 0, fatigue: -1, curiosity: 0, safety: 1),
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

private func cooperationProject(_ id: String = "cooperation-shelter") -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id,
        builderAgentId: "builder",
        origin: cooperationOrigin,
        createdAtTick: 0,
        previousHomePosition: cooperationHome,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func cooperationSmokeSession(
    id: String,
    cooperationConfiguration: AgentCooperationConfiguration = .live,
    enableCooperation: Bool = true,
    agents: [AgentSessionAgentState]? = nil
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        campStockCapacity: 32,
        socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
        cooperationConfiguration: cooperationConfiguration
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: agents ?? [
            cooperationSmokeState("builder", x: 0),
            cooperationSmokeState("helper", x: 1),
            cooperationSmokeState("excluded", x: 3, fear: 80),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.setSocialEnabled(true)
    try! session.setPhysicalEnabled(true)
    try! session.createConstructionProject(cooperationProject(id + "-project"))
    try! session.setBuildAutoEnabled(true)
    if enableCooperation {
        try! session.setCooperationEnabled(true)
    }
    return session
}

private func cooperationSignaledSession(
    id: String,
    configuration: AgentCooperationConfiguration = .live
) -> (AgentSimulationSession, AgentPhysicalSignal) {
    var session = cooperationSmokeSession(id: id, cooperationConfiguration: configuration)
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [cooperationStoneObservation()]
    )])
    _ = try! session.advanceTick()
    return (session, session.physicalChannelSnapshot().signals.last!)
}

private func cooperationStoneObservation(
    x: Int = 2,
    observerX: Int = 0,
    fingerprint: Int = 460
) -> AgentResourceObservation {
    AgentResourceObservation(
        resource: .stone,
        target: AgentPosition(x: x, y: 64, z: 0),
        direction: .east,
        distanceManhattan: abs(x - observerX),
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
}

private func cooperationExactObservation(
    signal: AgentPhysicalSignal,
    observer: String = "helper",
    tick: Int
) -> AgentPhysicalSignalObservation {
    AgentPhysicalSignalObservation(
        signalID: signal.signalID,
        observerID: AgentID(rawValue: observer)!,
        distanceManhattan: observer == "helper" ? 1 : 3,
        soundClarity: 95,
        gestureClarity: 95,
        opaqueOcclusionCount: 0,
        lineOfSight: true,
        chunksReady: true,
        observedAtTick: tick
    )
}

private func prepareAcceptedCooperationSession(
    id: String,
    configuration: AgentCooperationConfiguration = .live
) -> (AgentSimulationSession, AgentSharedTask, AgentPhysicalSignal) {
    var session = cooperationSmokeSession(id: id, cooperationConfiguration: configuration)
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [cooperationStoneObservation()]
    )])
    let proposal = try! session.advanceTick()
    precondition(proposal.agents.first { $0.agentId == "builder" }?.action.name == "share_information")
    let signal = session.physicalChannelSnapshot().signals.last!
    _ = try! session.advanceTick(physicalObservations: [
        cooperationExactObservation(signal: signal, tick: session.tick + 1),
        cooperationExactObservation(signal: signal, observer: "excluded", tick: session.tick + 1),
    ])
    let acceptance = try! session.advanceTick()
    precondition(acceptance.agents.first { $0.agentId == "helper" }?.action.name == "accept_task")
    return (session, session.cooperationSnapshot().tasks[0], signal)
}

private func cooperationHarvest(
    session: inout AgentSimulationSession,
    agent: String,
    resource: AgentResourceKind,
    index: Int
) {
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "cooperation-harvest-\(agent)-\(resource.rawValue)-\(index)",
        agentId: agent,
        tick: session.tick,
        target: AgentPosition(x: 2, y: 64, z: index),
        resource: resource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "cooperation real natural material fixture"
    ))
}

private func cooperationDeliver(
    session: inout AgentSimulationSession,
    agent: String,
    id: String
) -> AgentDeliveryOutcome {
    try! session.deliverResources(AgentDeliveryIntent(
        deliveryId: id,
        agentId: agent,
        tick: session.tick,
        position: session.snapshot().agents.first { $0.id == agent }!.position
    ))
}

func runPebbleAgentsCooperationSmoke() {
    section("pebble agents shared tasks and cooperation")

    let defaults = AgentCooperationConfiguration.live
    check("cooperation defaults bound tasks", defaults.maximumTasks == 16)
    check("cooperation defaults bound offers", defaults.maximumOffers == 16)
    check("cooperation defaults bound relations", defaults.maximumRelations == 32)
    check("cooperation defaults bound quantity", defaults.maximumTaskQuantity == 3)
    check("cooperation defaults bound offer lifetime", defaults.offerLifetimeTicks == 6)
    check("cooperation defaults bound accepted lifetime", defaults.acceptedTaskLifetimeTicks == 64)
    check("cooperation defaults bound cooldown", defaults.offerCooldownTicks == 8)
    check("cooperation defaults accept neutral trust", defaults.minimumTrustToAccept == 0)
    check("cooperation defaults distinguish reliability deltas", defaults.completionReliabilityDelta == 10 && defaults.failureReliabilityDelta == -10)
    check("cooperation defaults clamp reliability", defaults.minimumReliability == -100 && defaults.maximumReliability == 100)
    check("cooperation rejects zero task capacity", (try? AgentCooperationConfiguration(maximumTasks: 0)) == nil)
    check("cooperation rejects zero offer capacity", (try? AgentCooperationConfiguration(maximumOffers: 0)) == nil)
    check("cooperation rejects zero relation capacity", (try? AgentCooperationConfiguration(maximumRelations: 0)) == nil)
    check("cooperation rejects quantity zero", (try? AgentCooperationConfiguration(maximumTaskQuantity: 0)) == nil)
    check("cooperation rejects quantity above three", (try? AgentCooperationConfiguration(maximumTaskQuantity: 4)) == nil)
    check("cooperation rejects zero offer lifetime", (try? AgentCooperationConfiguration(offerLifetimeTicks: 0)) == nil)
    check("cooperation rejects zero accepted lifetime", (try? AgentCooperationConfiguration(acceptedTaskLifetimeTicks: 0)) == nil)
    check("cooperation rejects zero cooldown", (try? AgentCooperationConfiguration(offerCooldownTicks: 0)) == nil)
    check("cooperation rejects inverted reliability bounds", (try? AgentCooperationConfiguration(minimumReliability: 1, maximumReliability: 0)) == nil)
    check("cooperation rejects zero success delta", (try? AgentCooperationConfiguration(completionReliabilityDelta: 0)) == nil)
    check("cooperation rejects positive failure delta", (try? AgentCooperationConfiguration(failureReliabilityDelta: 1)) == nil)
    check("cooperation configuration preserves Codable", (try? JSONDecoder().decode(
        AgentCooperationConfiguration.self,
        from: JSONEncoder().encode(defaults)
    )) == defaults)
    check("cooperation task ID rejects empty", AgentSharedTaskID(rawValue: "") == nil)
    check("cooperation task ID order is lexical", [AgentSharedTaskID(rawValue: "task-b")!, AgentSharedTaskID(rawValue: "task-a")!].sorted().map(\.rawValue) == ["task-a", "task-b"])
    check("cooperation relation ID rejects empty", AgentCooperationRelationID(rawValue: "") == nil)
    check("cooperation V1 has one task kind", AgentSharedTaskKind.allCases == [.deliverConstructionMaterial])

    var dependency = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(seed: 46, memoryPolicy: .bounded(maxEntries: 8)),
        agents: [cooperationSmokeState("builder", x: 0)]
    )
    check("cooperation requires causal ledger", {
        do { try dependency.setCooperationEnabled(true); return false }
        catch AgentSessionError.cooperation(.causalLedgerRequired) { return true }
        catch { return false }
    }())
    var dependencies = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 8)
        ),
        agents: [
            cooperationSmokeState("builder", x: 0),
            cooperationSmokeState("helper", x: 1),
        ],
        simulationID: try! AgentSimulationID(validating: "cooperation-dependencies"),
        causalLedgerPolicy: .bounded(maxEvents: 256)
    )
    check("cooperation requires social domain", {
        do { try dependencies.setCooperationEnabled(true); return false }
        catch AgentSessionError.cooperation(.socialRequired) { return true }
        catch { return false }
    }())
    try! dependencies.setSocialEnabled(true)
    check("cooperation requires physical domain", {
        do { try dependencies.setCooperationEnabled(true); return false }
        catch AgentSessionError.cooperation(.physicalRequired) { return true }
        catch { return false }
    }())
    try! dependencies.setPhysicalEnabled(true)
    check("cooperation requires construction project", {
        do { try dependencies.setCooperationEnabled(true); return false }
        catch AgentSessionError.cooperation(.constructionProjectRequired) { return true }
        catch { return false }
    }())
    var gateOff = cooperationSmokeSession(id: "cooperation-gate-off", enableCooperation: false)
    let gateOffBefore = gateOff.snapshot()
    _ = try! gateOff.advanceTick()
    check("cooperation remains disabled by default", !gateOff.cooperationSummary().enabled)
    check("cooperation gate off creates no task", gateOff.cooperationSnapshot().tasks.isEmpty)
    check("cooperation gate off preserves construction authority", gateOffBefore.constructionProject?.builderAgentId == gateOff.snapshot().constructionProject?.builderAgentId)

    var exact = cooperationSmokeSession(id: "cooperation-exact")
    _ = try! exact.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [cooperationStoneObservation()]
    )])
    let directFact = exact.socialSnapshot().facts.first!
    check("cooperation source is direct builder fact", directFact.observerID.rawValue == "builder" && directFact.source == .naturalWorld)
    let proposalTick = try! exact.advanceTick()
    let proposalTask = exact.cooperationSnapshot().tasks.first!
    let proposalSignal = exact.physicalChannelSnapshot().signals.last!
    check("cooperation proposal uses builder issuer", proposalTask.issuerID.rawValue == "builder")
    check("cooperation proposal names distinct helper", proposalTask.helperID.rawValue == "helper")
    check("cooperation proposal excludes urgent third agent", proposalTask.helperID.rawValue != "excluded")
    check("cooperation proposal selects stone first", proposalTask.resource == .stone)
    check("cooperation proposal quantity is three", proposalTask.requestedQuantity == 3)
    check("cooperation proposal uses unique task kind", proposalTask.kind == .deliverConstructionMaterial)
    check("cooperation proposal points at active project", proposalTask.projectID == exact.snapshot().constructionProject?.projectId)
    check("cooperation proposal carries direct fact", proposalTask.sourceFactID == directFact.factID)
    check("cooperation proposal emits existing share action", proposalTick.agents.first { $0.agentId == "builder" }?.action.name == "share_information")
    check("cooperation offer reuses physical signal", proposalSignal.cooperationOffer?.taskID == proposalTask.taskID)
    check("cooperation offer signal names exact helper", proposalSignal.cooperationOffer?.intendedHelperID.rawValue == "helper")
    check("cooperation offer signal carries one envelope", proposalSignal.cooperationOffer?.quantity == 3)
    check("cooperation offer becomes signaled", exact.cooperationSnapshot().tasks.first?.status == .signaled)
    let reserved = exact.uncommittedConstructionDemand()!
    check("cooperation draft commitment removes assigned stone", !reserved.missing.contains { $0.resource == .stone })
    check("cooperation builder retains six uncommitted wood", reserved.missing.first { $0.resource == .wood }?.quantity == 6)

    _ = try! exact.advanceTick(physicalObservations: [
        cooperationExactObservation(signal: proposalSignal, tick: exact.tick + 1),
        cooperationExactObservation(signal: proposalSignal, observer: "excluded", tick: exact.tick + 1),
    ])
    let offered = exact.cooperationSnapshot()
    check("cooperation exact helper perception offers task", offered.tasks.first?.status == .offered)
    check("cooperation exact helper receives one offer", offered.offers.count == 1 && offered.offers.first?.helperID.rawValue == "helper")
    check("cooperation bystander receives no offer", exact.cooperationSnapshot(for: AgentID(rawValue: "excluded")!).offers.isEmpty)
    check("cooperation acceptance is not same-tick coercion", offered.tasks.first?.acceptedAtTick == nil)
    let acceptanceTick = try! exact.advanceTick()
    check("cooperation helper accepts on later tick", acceptanceTick.agents.first { $0.agentId == "helper" }?.action.name == "accept_task")
    check("cooperation accepted task records tick", exact.cooperationSnapshot().tasks.first?.acceptedAtTick == exact.tick)
    check("cooperation informational trust stays distinct", exact.trustScore(sourceAgentId: "helper", targetAgentId: "builder") == 0)
    check("cooperation reliability starts neutral", exact.cooperationSnapshot().relations.isEmpty)
    check("cooperation helper sees its own task", exact.cooperationSnapshot(for: AgentID(rawValue: "helper")!).tasks.count == 1)

    var ambiguous = cooperationSmokeSession(id: "cooperation-ambiguous")
    _ = try! ambiguous.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder", socialResourceObservations: [cooperationStoneObservation()]
    )])
    _ = try! ambiguous.advanceTick()
    let ambiguousSignal = ambiguous.physicalChannelSnapshot().signals.last!
    _ = try! ambiguous.advanceTick(physicalObservations: [AgentPhysicalSignalObservation(
        signalID: ambiguousSignal.signalID,
        observerID: AgentID(rawValue: "helper")!,
        distanceManhattan: 1,
        soundClarity: 60,
        gestureClarity: 60,
        opaqueOcclusionCount: 0,
        lineOfSight: true,
        chunksReady: true,
        observedAtTick: ambiguous.tick + 1
    )])
    check("cooperation ambiguous perception creates no offer", ambiguous.cooperationSnapshot().offers.isEmpty)
    check("cooperation ambiguous perception creates no acceptance", ambiguous.cooperationSnapshot().tasks.first?.status == .signaled)

    var missed = cooperationSignaledSession(id: "cooperation-missed").0
    let missedSignal = missed.physicalChannelSnapshot().signals.last!
    _ = try! missed.advanceTick(physicalObservations: [AgentPhysicalSignalObservation(
        signalID: missedSignal.signalID,
        observerID: AgentID(rawValue: "helper")!,
        distanceManhattan: 12,
        soundClarity: 0,
        gestureClarity: 0,
        opaqueOcclusionCount: 1,
        lineOfSight: false,
        chunksReady: true,
        observedAtTick: missed.tick + 1
    )])
    check("cooperation missed perception creates no offer", missed.cooperationSnapshot().offers.isEmpty)

    var inconclusive = cooperationSignaledSession(id: "cooperation-inconclusive").0
    let inconclusiveSignal = inconclusive.physicalChannelSnapshot().signals.last!
    _ = try! inconclusive.advanceTick(physicalObservations: [AgentPhysicalSignalObservation(
        signalID: inconclusiveSignal.signalID,
        observerID: AgentID(rawValue: "helper")!,
        distanceManhattan: 1,
        soundClarity: 95,
        gestureClarity: 95,
        opaqueOcclusionCount: 0,
        lineOfSight: true,
        chunksReady: false,
        observedAtTick: inconclusive.tick + 1
    )])
    check("cooperation inconclusive perception creates no offer", inconclusive.cooperationSnapshot().offers.isEmpty)

    let expiringConfiguration = try! AgentCooperationConfiguration(
        offerLifetimeTicks: 1,
        acceptedTaskLifetimeTicks: 64,
        offerCooldownTicks: 1
    )
    var expiring = cooperationSignaledSession(
        id: "cooperation-offer-expiry",
        configuration: expiringConfiguration
    ).0
    _ = try! expiring.advanceTick()
    _ = try! expiring.advanceTick()
    check("cooperation unaccepted offer expires deterministically", expiring.cooperationSnapshot().tasks.first?.status == .expired)
    check("cooperation expiry releases demand commitment", expiring.uncommittedConstructionDemand()?.missing.first { $0.resource == .stone }?.quantity == 3)
    check("cooperation expiry changes no reliability", expiring.cooperationSnapshot().relations.isEmpty)

    var forwarded = cooperationSmokeSession(id: "cooperation-forwarding", enableCooperation: false)
    try! forwarded.setPhysicalEnabled(false)
    _ = try! forwarded.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        socialResourceObservations: [cooperationStoneObservation(observerX: 1)]
    )])
    _ = try! forwarded.advanceTick()
    check("cooperation received belief exists only as recipient knowledge", forwarded.socialSnapshot().beliefs.contains { $0.ownerID.rawValue == "builder" })
    try! forwarded.setPhysicalEnabled(true)
    try! forwarded.setCooperationEnabled(true)
    _ = try! forwarded.advanceTick()
    check("cooperation received belief cannot source task offer", forwarded.cooperationSnapshot().tasks.isEmpty)

    let orderedAgents = [
        cooperationSmokeState("builder", x: 0),
        cooperationSmokeState("helper", x: 1),
        cooperationSmokeState("excluded", x: 3, fear: 80),
    ]
    var ordered = cooperationSmokeSession(
        id: "cooperation-order-permutation",
        agents: orderedAgents
    )
    var permuted = cooperationSmokeSession(
        id: "cooperation-order-permutation",
        agents: Array(orderedAgents.reversed())
    )
    let orderedPerceptions = [
        AgentPerceptionInput(
            agentId: "builder",
            socialResourceObservations: [cooperationStoneObservation()]
        ),
        AgentPerceptionInput(agentId: "helper"),
        AgentPerceptionInput(agentId: "excluded"),
    ]
    _ = try! ordered.advanceTick(perceptions: orderedPerceptions)
    _ = try! permuted.advanceTick(perceptions: Array(orderedPerceptions.reversed()))
    _ = try! ordered.advanceTick()
    _ = try! permuted.advanceTick()
    let orderedSignal = ordered.physicalChannelSnapshot().signals.last!
    let permutedSignal = permuted.physicalChannelSnapshot().signals.last!
    let orderedPhysical = [
        cooperationExactObservation(signal: orderedSignal, observer: "helper", tick: ordered.tick + 1),
        cooperationExactObservation(signal: orderedSignal, observer: "excluded", tick: ordered.tick + 1),
    ]
    let permutedPhysical = [
        cooperationExactObservation(signal: permutedSignal, observer: "excluded", tick: permuted.tick + 1),
        cooperationExactObservation(signal: permutedSignal, observer: "helper", tick: permuted.tick + 1),
    ]
    _ = try! ordered.advanceTick(physicalObservations: orderedPhysical)
    _ = try! permuted.advanceTick(physicalObservations: permutedPhysical)
    _ = try! ordered.advanceTick()
    _ = try! permuted.advanceTick()
    check("cooperation agent permutation preserves task IDs", ordered.cooperationSnapshot().tasks.map(\.taskID) == permuted.cooperationSnapshot().tasks.map(\.taskID))
    check("cooperation observation permutation preserves snapshot", ordered.cooperationSnapshot() == permuted.cooperationSnapshot())
    check("cooperation permutations preserve causal ledger", ordered.causalLedgerSnapshot() == permuted.causalLedgerSnapshot())

    let refusalConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        campStockCapacity: 32,
        socialConfiguration: try! AgentSocialConfiguration(
            minimumTrustToVerify: -20,
            shareCooldownTicks: 1
        )
    )
    var refusal = try! AgentSimulationSession(
        configuration: refusalConfiguration,
        agents: [
            cooperationSmokeState("builder", x: 0),
            cooperationSmokeState("helper", x: 1),
            cooperationSmokeState("excluded", x: 3, fear: 80),
        ],
        simulationID: try! AgentSimulationID(validating: "cooperation-trust-refusal"),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! refusal.setSocialEnabled(true)
    _ = try! refusal.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 2, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 460
        )]
    )])
    _ = try! refusal.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [cooperationStoneObservation(x: 3, fingerprint: 461)]
    )])
    let contradicted = refusal.socialSnapshot().beliefs.first!
    try! refusal.createConstructionProject(cooperationProject("cooperation-trust-project"))
    try! refusal.setBuildAutoEnabled(true)
    try! refusal.setPhysicalEnabled(true)
    try! refusal.setCooperationEnabled(true)
    _ = try! refusal.advanceTick()
    let refusalSignal = refusal.physicalChannelSnapshot().signals.last!
    let verificationAndOffer = try! refusal.advanceTick(physicalObservations: [
        cooperationExactObservation(signal: refusalSignal, tick: refusal.tick + 1),
    ])
    check("cooperation trust fixture keeps prior belief verification active", verificationAndOffer.agents.first { $0.agentId == "helper" }?.action.name == "verify_information")
    _ = try! refusal.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: contradicted.beliefID,
        verifierID: contradicted.ownerID,
        position: contradicted.fact.position,
        chunkReady: true,
        observedBlockFingerprint: 0,
        observedResource: nil
    ))
    check("cooperation informational contradiction lowers helper trust", refusal.trustScore(sourceAgentId: "helper", targetAgentId: "builder") == -15)
    let refusalDecision = try! refusal.advanceTick()
    check(
        "cooperation negative trust produces explicit decline",
        refusalDecision.agents.first { $0.agentId == "helper" }?.action.name == "decline_task",
        "action=\(refusalDecision.agents.first { $0.agentId == "helper" }?.action.name ?? "none") trust=\(refusal.trustScore(sourceAgentId: "helper", targetAgentId: "builder")) task=\(refusal.cooperationSnapshot().tasks.last?.status.rawValue ?? "none")"
    )
    check(
        "cooperation decline is terminal without reliability penalty",
        refusal.cooperationSnapshot().tasks.last?.status == .declined
            && refusal.cooperationSnapshot().relations.isEmpty,
        "task=\(refusal.cooperationSnapshot().tasks.last?.status.rawValue ?? "none") offers=\(refusal.cooperationSnapshot().offers.count) relations=\(refusal.cooperationSnapshot().relations.count)"
    )

    var canonical = prepareAcceptedCooperationSession(id: "cooperation-canonical").0
    let acceptedTaskID = canonical.cooperationSnapshot().tasks.first!.taskID
    let startTick = try! canonical.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationStoneObservation(x: 2, observerX: 1, fingerprint: 501)]
    )])
    check("cooperation active helper selects assigned resource", startTick.agents.first { $0.agentId == "helper" }?.action.name == "harvest_block")
    check("cooperation accepted task becomes active on material action", canonical.activeSharedTask(for: "helper")?.status == .active)
    cooperationHarvest(session: &canonical, agent: "helper", resource: .stone, index: 0)
    check("cooperation harvest enters real helper inventory", canonical.snapshot().agents.first { $0.id == "helper" }?.resourceInventory.count(of: .stone) == 1)
    check("cooperation harvest alone credits no progress", canonical.cooperationSnapshot().tasks.first?.contributedQuantity == 0)
    let blockedBefore = canonical.cooperationSnapshot().tasks.first!.contributedQuantity
    try! canonical.applyDeliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "cooperation-blocked",
        agentId: "helper",
        tick: canonical.tick,
        status: .blocked,
        transferred: [],
        reason: "controlled blocked delivery"
    ))
    check("cooperation blocked delivery credits no progress", canonical.cooperationSnapshot().tasks.first?.contributedQuantity == blockedBefore)
    let firstDelivery = cooperationDeliver(session: &canonical, agent: "helper", id: "cooperation-partial-1")
    check("cooperation partial delivery transfers real stone", firstDelivery.transferred == [AgentResourceAmount(resource: .stone, quantity: 1)])
    check("cooperation partial delivery advances one of three", canonical.cooperationSnapshot().tasks.first?.contributedQuantity == 1 && canonical.cooperationSnapshot().tasks.first?.status == .active)
    check("cooperation camp contains partial material", canonical.snapshot().campStock.count(of: .stone) == 1)
    cooperationHarvest(session: &canonical, agent: "helper", resource: .stone, index: 1)
    cooperationHarvest(session: &canonical, agent: "helper", resource: .stone, index: 2)
    let finalHelperDelivery = cooperationDeliver(session: &canonical, agent: "helper", id: "cooperation-partial-2")
    check("cooperation final helper delivery transfers two stone", finalHelperDelivery.transferred == [AgentResourceAmount(resource: .stone, quantity: 2)])
    let completedTask = canonical.cooperationSnapshot().tasks.first!
    check("cooperation exact delivered quantity completes task", completedTask.contributedQuantity == 3 && completedTask.status == .completed)
    check("cooperation completed task identity is stable", completedTask.taskID == acceptedTaskID)
    let relation = canonical.cooperationSnapshot().relations.first!
    check("cooperation completion creates directed reliability", relation.issuerID.rawValue == "builder" && relation.helperID.rawValue == "helper")
    check("cooperation completion increases reliability by ten", relation.reliabilityScore == 10 && relation.completedTaskCount == 1)
    check("cooperation reliability does not mutate trust", canonical.trustScore(sourceAgentId: "helper", targetAgentId: "builder") == 0)
    check("cooperation duplicate delivery is refused", {
        do { try canonical.applyDeliveryOutcome(finalHelperDelivery); return false }
        catch AgentSessionError.duplicateDelivery { return true }
        catch { return false }
    }())
    check("cooperation duplicate delivery cannot over-credit", canonical.cooperationSnapshot().tasks.first?.contributedQuantity == 3)

    var wrongResource = prepareAcceptedCooperationSession(id: "cooperation-wrong-resource").0
    _ = try! wrongResource.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationStoneObservation(x: 2, observerX: 1, fingerprint: 601)]
    )])
    cooperationHarvest(session: &wrongResource, agent: "helper", resource: .wood, index: 0)
    let wrongDelivery = cooperationDeliver(
        session: &wrongResource,
        agent: "helper",
        id: "cooperation-wrong-resource-delivery"
    )
    check("cooperation wrong resource delivery remains materially valid", wrongDelivery.transferred == [AgentResourceAmount(resource: .wood, quantity: 1)] && wrongResource.snapshot().campStock.count(of: .wood) == 1)
    check("cooperation wrong resource delivery credits no task progress", wrongResource.cooperationSnapshot().tasks.first?.contributedQuantity == 0)

    var deliveryOrderA = prepareAcceptedCooperationSession(
        id: "cooperation-delivery-order"
    ).0
    var deliveryOrderB = prepareAcceptedCooperationSession(
        id: "cooperation-delivery-order"
    ).0
    let deliveryStartPerception = [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationStoneObservation(x: 2, observerX: 1, fingerprint: 602)]
    )]
    _ = try! deliveryOrderA.advanceTick(perceptions: deliveryStartPerception)
    _ = try! deliveryOrderB.advanceTick(perceptions: deliveryStartPerception)
    for resource in [AgentResourceKind.wood, .stone] {
        cooperationHarvest(session: &deliveryOrderA, agent: "helper", resource: resource, index: resource == .wood ? 0 : 1)
        cooperationHarvest(session: &deliveryOrderB, agent: "helper", resource: resource, index: resource == .wood ? 0 : 1)
    }
    let canonicalAmounts = deliveryOrderA.snapshot().agents.first {
        $0.id == "helper"
    }!.resourceInventory.amounts
    try! deliveryOrderA.applyDeliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "cooperation-delivery-order-outcome",
        agentId: "helper",
        tick: deliveryOrderA.tick,
        status: .succeeded,
        transferred: canonicalAmounts,
        reason: "normalized material order"
    ))
    try! deliveryOrderB.applyDeliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "cooperation-delivery-order-outcome",
        agentId: "helper",
        tick: deliveryOrderB.tick,
        status: .succeeded,
        transferred: Array(canonicalAmounts.reversed()),
        reason: "normalized material order"
    ))
    check("cooperation delivery amount order normalizes identically", deliveryOrderA.snapshot().campStock == deliveryOrderB.snapshot().campStock)
    check("cooperation delivery amount order preserves task state", deliveryOrderA.cooperationSnapshot() == deliveryOrderB.cooperationSnapshot())
    check("cooperation delivery amount order preserves ledger", deliveryOrderA.causalLedgerSnapshot() == deliveryOrderB.causalLedgerSnapshot())

    var superseded = prepareAcceptedCooperationSession(id: "cooperation-superseded").0
    for index in 0..<3 {
        cooperationHarvest(session: &superseded, agent: "builder", resource: .stone, index: index)
    }
    _ = cooperationDeliver(session: &superseded, agent: "builder", id: "cooperation-external-stone")
    _ = try! superseded.advanceTick()
    check("cooperation task supersedes when real demand disappears", superseded.cooperationSnapshot().tasks.first?.status == .superseded)
    check("cooperation superseded task changes no reliability", superseded.cooperationSnapshot().relations.isEmpty)

    let shortLifetime = try! AgentCooperationConfiguration(
        offerLifetimeTicks: 6,
        acceptedTaskLifetimeTicks: 1,
        offerCooldownTicks: 1
    )
    var failed = prepareAcceptedCooperationSession(
        id: "cooperation-accepted-failure",
        configuration: shortLifetime
    ).0
    _ = try! failed.advanceTick()
    let failureTick = try! failed.advanceTick()
    check("cooperation accepted lifetime failure is terminal", failed.cooperationSnapshot().tasks.first?.status == .failed)
    check("cooperation accepted failure reduces reliability by ten", failed.cooperationSnapshot().relations.first?.reliabilityScore == -10 && failed.cooperationSnapshot().relations.first?.failedAcceptedTaskCount == 1)
    check("cooperation terminal tick releases helper before action selection", failureTick.agents.first { $0.agentId == "helper" }?.snapshot.currentGoal.kind != .fulfillSharedTask)
    check("cooperation terminal tick preserves movement contract", {
        do {
            var candidate = failed
            try candidate.applyMovementOutcomes(AgentMovementCoordinator.resolve(snapshot: failed.snapshot()))
            return true
        } catch { return false }
    }())

    let clampedSuccessConfiguration = try! AgentCooperationConfiguration(
        completionReliabilityDelta: 200,
        failureReliabilityDelta: -200
    )
    var clampedSuccess = prepareAcceptedCooperationSession(
        id: "cooperation-reliability-positive-clamp",
        configuration: clampedSuccessConfiguration
    ).0
    _ = try! clampedSuccess.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationStoneObservation(x: 2, observerX: 1, fingerprint: 701)]
    )])
    for index in 0..<3 {
        cooperationHarvest(session: &clampedSuccess, agent: "helper", resource: .stone, index: index)
    }
    _ = cooperationDeliver(session: &clampedSuccess, agent: "helper", id: "cooperation-clamped-success")
    check("cooperation reliability clamps at positive bound", clampedSuccess.cooperationSnapshot().relations.first?.reliabilityScore == 100)

    let clampedFailureConfiguration = try! AgentCooperationConfiguration(
        offerLifetimeTicks: 6,
        acceptedTaskLifetimeTicks: 1,
        offerCooldownTicks: 1,
        completionReliabilityDelta: 200,
        failureReliabilityDelta: -200
    )
    var clampedFailure = prepareAcceptedCooperationSession(
        id: "cooperation-reliability-negative-clamp",
        configuration: clampedFailureConfiguration
    ).0
    _ = try! clampedFailure.advanceTick()
    _ = try! clampedFailure.advanceTick()
    check("cooperation reliability clamps at negative bound", clampedFailure.cooperationSnapshot().relations.first?.reliabilityScore == -100)

    let evictionConfiguration = try! AgentCooperationConfiguration(
        maximumTasks: 1,
        maximumOffers: 1,
        maximumRelations: 1,
        offerLifetimeTicks: 1,
        acceptedTaskLifetimeTicks: 2,
        offerCooldownTicks: 1
    )
    var eviction = cooperationSignaledSession(
        id: "cooperation-terminal-eviction",
        configuration: evictionConfiguration
    ).0
    for _ in 0..<12 { _ = try! eviction.advanceTick() }
    check("cooperation task history stays bounded", eviction.cooperationSnapshot().tasks.count == 1)
    check("cooperation task eviction removes terminal entries only", eviction.cooperationSnapshot().evictionCounts.tasks > 0 && eviction.cooperationSnapshot().tasks.allSatisfy { !$0.status.isTerminal || eviction.cooperationSnapshot().tasks.count == 1 })

    for index in 0..<6 {
        cooperationHarvest(session: &canonical, agent: "builder", resource: .wood, index: index)
    }
    let builderDelivery = cooperationDeliver(session: &canonical, agent: "builder", id: "cooperation-builder-wood")
    check("cooperation builder contributes exactly six wood", builderDelivery.transferred == [AgentResourceAmount(resource: .wood, quantity: 6)])
    check("cooperation stock reaches exact shelter cost", canonical.snapshot().campStock.count(of: .wood) == 6 && canonical.snapshot().campStock.count(of: .stone) == 3)
    check("cooperation helper cannot fund builder project", {
        do {
            _ = try canonical.fundConstructionProject(
                fundingId: "cooperation-helper-fund",
                builderAgentId: "helper",
                fundingTick: canonical.tick
            )
            return false
        } catch AgentSessionError.invalidConstructionFunding { return true }
        catch { return false }
    }())
    _ = try! canonical.advanceTick()
    let funding = try! canonical.fundConstructionProject(
        fundingId: "cooperation-builder-fund",
        builderAgentId: "builder",
        fundingTick: canonical.tick
    )
    check("cooperation builder remains sole funding authority", funding.status == .funded)
    check("cooperation funding consumes real shared stock", canonical.snapshot().campStock.totalCount == 0 && canonical.snapshot().conservation.constructionEscrowTotal == 9)
    check("cooperation funding causally follows completed task", canonical.causalLedgerSnapshot().events.contains(where: { event in
        event.kind == .constructionFunding && event.causes.contains(completedTask.terminalEventID!)
    }))

    for index in 0..<9 {
        let project = canonical.snapshot().constructionProject!
        let cell = project.nextCell!
        let target = project.nextTarget!
        let work = project.nextWorkPosition!
        try! canonical.applyExternalUpdate(AgentExternalUpdate(agentId: "builder", position: work))
        let intent = AgentPlacementIntent(
            placementId: "cooperation-place-\(index)",
            projectId: project.projectId,
            builderAgentId: "builder",
            tick: canonical.tick,
            cellIndex: cell.index,
            target: target,
            workPosition: work,
            resource: cell.resource
        )
        try! canonical.prevalidatePlacement(intent)
        try! canonical.applyPlacementOutcome(AgentPlacementOutcome(
            placementId: intent.placementId,
            projectId: intent.projectId,
            builderAgentId: intent.builderAgentId,
            tick: intent.tick,
            cellIndex: intent.cellIndex,
            target: intent.target,
            resource: intent.resource,
            status: .succeeded,
            reason: "cooperation ordered placement verified"
        ))
        if index < 8 { _ = try! canonical.advanceTick() }
    }
    check("cooperation builder places all nine cells", canonical.snapshot().constructionProject?.placedCellIndices.count == 9)
    try! canonical.completeConstructionProject(
        projectId: canonical.snapshot().constructionProject!.projectId,
        completionTick: canonical.tick
    )
    check("cooperation shared project completes through existing authority", canonical.snapshot().constructionProject?.status == .completed)
    check("cooperation completion moves only builder home", canonical.snapshot().agents.first { $0.id == "builder" }?.homePosition == cooperationProject().restPosition)
    check("cooperation helper home remains unchanged", canonical.snapshot().agents.first { $0.id == "helper" }?.homePosition == AgentPosition(x: 1, y: 64, z: 0))
    check("cooperation full material conservation is exact", canonical.snapshot().conservation.harvestedTotal == 9 && canonical.snapshot().conservation.constructedTotal == 9 && canonical.snapshot().conservation.balanced)
    let chainKinds = Set(canonical.causalLedgerSnapshot().events.map(\.kind))
    check("cooperation causal chain records creation", chainKinds.contains(.sharedTaskCreated))
    check("cooperation causal chain records signal", chainKinds.contains(.sharedTaskSignaled))
    check("cooperation causal chain records offer", chainKinds.contains(.sharedTaskOffered))
    check("cooperation causal chain records acceptance", chainKinds.contains(.sharedTaskAccepted))
    check("cooperation causal chain records progress", chainKinds.contains(.sharedTaskProgress))
    check("cooperation causal chain records completion", chainKinds.contains(.sharedTaskCompleted))
    check("cooperation causal chain records reliability", chainKinds.contains(.cooperationReliabilityChanged))
    check("cooperation snapshot digest is repeatable", canonical.cooperationSnapshot().digest == canonical.cooperationSnapshot().digest)
    check("cooperation ledger digest is repeatable", canonical.causalLedgerSnapshot().summary.digest == canonical.causalLedgerSnapshot().summary.digest)

    var cancellation = prepareAcceptedCooperationSession(id: "cooperation-cancel").0
    let inventoryBeforeOff = cancellation.snapshot().agents.first { $0.id == "helper" }!.resourceInventory
    try! cancellation.setCooperationEnabled(false)
    check("cooperation off cancels active commitment without penalty", cancellation.cooperationSnapshot().tasks.first?.status == .cancelled && cancellation.cooperationSnapshot().relations.isEmpty)
    check("cooperation off preserves inventory", cancellation.snapshot().agents.first { $0.id == "helper" }!.resourceInventory == inventoryBeforeOff)
    check("cooperation off releases demand commitment", cancellation.uncommittedConstructionDemand()?.missing.first { $0.resource == .stone }?.quantity == 3)

    var clear = prepareAcceptedCooperationSession(id: "cooperation-clear").0
    let trustBeforeClear = clear.trustSnapshot()
    let physicalBeforeClear = clear.physicalChannelSnapshot()
    try! clear.clearCooperationState()
    check("cooperation clear removes only task domain", clear.cooperationSnapshot().tasks.isEmpty && clear.cooperationSnapshot().offers.isEmpty && clear.cooperationSnapshot().relations.isEmpty)
    check("cooperation clear preserves informational trust", clear.trustSnapshot() == trustBeforeClear)
    check("cooperation clear preserves physical history", clear.physicalChannelSnapshot().signals == physicalBeforeClear.signals)
    check("cooperation clear records causal history", clear.causalLedgerSnapshot().events.contains { $0.kind == .cooperationStateCleared })
}
