import Foundation
import PebbleAgents

private struct CooperationContributionReport: Encodable, Equatable {
    let schemaVersion = 1
    let helperStoneHarvested: Int
    let helperStoneDelivered: Int
    let helperWoodHarvested: Int
    let helperWoodDelivered: Int
    let builderWoodHarvested: Int
    let builderWoodDelivered: Int
    let builderStoneHarvested: Int
    let builderStoneDelivered: Int
    let campBeforeHelperDelivery: [AgentResourceAmount]
    let campAfterHelperDelivery: [AgentResourceAmount]
    let campBeforeFunding: [AgentResourceAmount]
    let escrowAfterFunding: [AgentResourceAmount]
    let constructedAfterCompletion: [AgentResourceAmount]
    let conservation: AgentResourceConservationSnapshot
}

private struct CooperationNegativeCase: Encodable, Equatable {
    let name: String
    let taskStatus: String?
    let contributedQuantity: Int
    let reliability: Int
    let offerCount: Int
    let accepted: Bool
    let passed: Bool
}

private struct CooperationScenarioSummary: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let projectID: String
    let taskID: String
    let builderID: String
    let helperID: String
    let excludedID: String
    let sourceFactID: String
    let signalID: String
    let requestedResource: String
    let requestedQuantity: Int
    let contributedQuantity: Int
    let finalTaskStatus: String
    let finalReliability: Int
    let fundingTick: Int
    let placementTicks: [Int]
    let completionTick: Int
    let finalHome: AgentPosition
    let negativeCases: [CooperationNegativeCase]
}

private struct CooperationScenarioDigest: Encodable, Equatable {
    let schemaVersion = 1
    let cooperationDigest: String
    let socialDigest: String
    let physicalDigest: String
    let causalDigest: String
    let repeatedCooperationDigest: String
    let repeatedCausalDigest: String
    let deterministic: Bool
}

private struct CooperationScenarioCheck: Encodable, Equatable {
    let name: String
    let passed: Bool
}

private struct CooperationScenarioInvariantReport: Encodable, Equatable {
    let schemaVersion = 1
    let scenario: String
    let seed: UInt32
    let success: Bool
    let checks: [CooperationScenarioCheck]
}

private struct CooperationScenarioRun {
    var session: AgentSimulationSession
    let task: AgentSharedTask
    let factID: AgentSocialFactID
    let signalID: AgentPhysicalSignalID
    let campBeforeHelperDelivery: [AgentResourceAmount]
    let campAfterHelperDelivery: [AgentResourceAmount]
    let campBeforeFunding: [AgentResourceAmount]
    let escrowAfterFunding: [AgentResourceAmount]
    let fundingTick: Int
    let placementTicks: [Int]
    let completionTick: Int
}

private let cooperationScenarioHome = AgentPosition(x: 0, y: 64, z: 0)
private let cooperationScenarioOrigin = AgentPosition(x: 2, y: 64, z: 1)

private func cooperationScenarioState(
    _ id: String,
    x: Int,
    fear: Int = 0,
    hunger: Double = 0
) -> AgentSessionAgentState {
    let position = AgentPosition(x: x, y: 64, z: 0)
    return AgentSessionAgentState(
        id: id,
        state: "idle",
        position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: -1, curiosity: 0, safety: 1),
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

private func cooperationScenarioProject(_ id: String) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id,
        builderAgentId: "builder",
        origin: cooperationScenarioOrigin,
        createdAtTick: 0,
        previousHomePosition: cooperationScenarioHome,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func cooperationScenarioSession(
    seed: UInt32,
    id: String,
    cooperationConfiguration: AgentCooperationConfiguration = .live,
    helperHunger: Double = 0,
    cooperationEnabled: Bool = true
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: seed,
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
        agents: [
            cooperationScenarioState("builder", x: 0),
            cooperationScenarioState("helper", x: 1, hunger: helperHunger),
            cooperationScenarioState("excluded", x: 3, fear: 80),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.setSocialEnabled(true)
    try! session.setPhysicalEnabled(true)
    try! session.createConstructionProject(cooperationScenarioProject("shared-shelter-\(seed)"))
    try! session.setBuildAutoEnabled(true)
    if cooperationEnabled { try! session.setCooperationEnabled(true) }
    return session
}

private func cooperationScenarioObservation(
    observerX: Int = 0,
    fingerprint: Int = 460
) -> AgentResourceObservation {
    AgentResourceObservation(
        resource: .stone,
        target: AgentPosition(x: 2, y: 64, z: 0),
        direction: .east,
        distanceManhattan: abs(2 - observerX),
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
}

private func cooperationScenarioPhysicalObservation(
    _ signal: AgentPhysicalSignal,
    observer: String,
    tick: Int,
    exact: Bool
) -> AgentPhysicalSignalObservation {
    AgentPhysicalSignalObservation(
        signalID: signal.signalID,
        observerID: AgentID(rawValue: observer)!,
        distanceManhattan: observer == "helper" ? 1 : 3,
        soundClarity: exact ? 95 : 60,
        gestureClarity: exact ? 95 : 60,
        opaqueOcclusionCount: 0,
        lineOfSight: true,
        chunksReady: true,
        observedAtTick: tick
    )
}

private func cooperationScenarioOffered(
    seed: UInt32,
    id: String,
    configuration: AgentCooperationConfiguration = .live,
    helperHunger: Double = 0,
    exact: Bool = true
) -> (AgentSimulationSession, AgentPhysicalSignal) {
    var session = cooperationScenarioSession(
        seed: seed,
        id: id,
        cooperationConfiguration: configuration,
        helperHunger: helperHunger
    )
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [cooperationScenarioObservation()]
    )])
    _ = try! session.advanceTick()
    let signal = session.physicalChannelSnapshot().signals.last!
    _ = try! session.advanceTick(physicalObservations: [
        cooperationScenarioPhysicalObservation(
            signal, observer: "helper", tick: session.tick + 1, exact: exact
        ),
        cooperationScenarioPhysicalObservation(
            signal, observer: "excluded", tick: session.tick + 1, exact: false
        ),
    ])
    return (session, signal)
}

private func cooperationScenarioAccepted(
    seed: UInt32,
    id: String,
    configuration: AgentCooperationConfiguration = .live
) -> AgentSimulationSession {
    var offered = cooperationScenarioOffered(
        seed: seed, id: id, configuration: configuration
    ).0
    _ = try! offered.advanceTick()
    return offered
}

private func cooperationScenarioHarvest(
    _ resource: AgentResourceKind,
    agent: String,
    index: Int,
    session: inout AgentSimulationSession
) {
    try! session.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "shared-harvest-\(agent)-\(resource.rawValue)-\(index)",
        agentId: agent,
        tick: session.tick,
        target: AgentPosition(x: 2, y: 64, z: index),
        resource: resource,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "shared-task real material fixture"
    ))
}

@discardableResult
private func cooperationScenarioDeliver(
    _ id: String,
    agent: String,
    session: inout AgentSimulationSession
) -> AgentDeliveryOutcome {
    let actor = session.snapshot().agents.first { $0.id == agent }!
    return try! session.deliverResources(AgentDeliveryIntent(
        deliveryId: id,
        agentId: agent,
        tick: session.tick,
        position: actor.position
    ))
}

private func runCooperationCanonical(seed: UInt32, id: String) -> CooperationScenarioRun {
    var session = cooperationScenarioAccepted(seed: seed, id: id)
    let initialTask = session.cooperationSnapshot().tasks.first!
    let factID = initialTask.sourceFactID
    let signalID = initialTask.physicalSignalID!
    _ = try! session.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationScenarioObservation(observerX: 1, fingerprint: 501)]
    )])
    for index in 0..<3 {
        cooperationScenarioHarvest(.stone, agent: "helper", index: index, session: &session)
    }
    let campBeforeHelperDelivery = session.snapshot().campStock.amounts
    cooperationScenarioDeliver("shared-helper-delivery", agent: "helper", session: &session)
    let campAfterHelperDelivery = session.snapshot().campStock.amounts
    for index in 0..<6 {
        cooperationScenarioHarvest(.wood, agent: "builder", index: index, session: &session)
    }
    cooperationScenarioDeliver("shared-builder-delivery", agent: "builder", session: &session)
    let campBeforeFunding = session.snapshot().campStock.amounts
    _ = try! session.advanceTick()
    let fundingTick = session.tick
    _ = try! session.fundConstructionProject(
        fundingId: "shared-builder-funding",
        builderAgentId: "builder",
        fundingTick: fundingTick
    )
    let escrowAfterFunding = session.snapshot().constructionProject!.materialEscrow.amounts
    var placementTicks: [Int] = []
    for index in 0..<9 {
        let project = session.snapshot().constructionProject!
        let cell = project.nextCell!
        let target = project.nextTarget!
        let work = project.nextWorkPosition!
        try! session.applyExternalUpdate(AgentExternalUpdate(agentId: "builder", position: work))
        let intent = AgentPlacementIntent(
            placementId: "shared-placement-\(index)",
            projectId: project.projectId,
            builderAgentId: "builder",
            tick: session.tick,
            cellIndex: cell.index,
            target: target,
            workPosition: work,
            resource: cell.resource
        )
        try! session.prevalidatePlacement(intent)
        try! session.applyPlacementOutcome(AgentPlacementOutcome(
            placementId: intent.placementId,
            projectId: intent.projectId,
            builderAgentId: intent.builderAgentId,
            tick: intent.tick,
            cellIndex: intent.cellIndex,
            target: intent.target,
            resource: intent.resource,
            status: .succeeded,
            reason: "shared-task ordered placement verified"
        ))
        placementTicks.append(session.tick)
        if index < 8 { _ = try! session.advanceTick() }
    }
    let completionTick = session.tick
    try! session.completeConstructionProject(
        projectId: session.snapshot().constructionProject!.projectId,
        completionTick: completionTick
    )
    return CooperationScenarioRun(
        session: session,
        task: session.cooperationSnapshot().tasks.first!,
        factID: factID,
        signalID: signalID,
        campBeforeHelperDelivery: campBeforeHelperDelivery,
        campAfterHelperDelivery: campAfterHelperDelivery,
        campBeforeFunding: campBeforeFunding,
        escrowAfterFunding: escrowAfterFunding,
        fundingTick: fundingTick,
        placementTicks: placementTicks,
        completionTick: completionTick
    )
}

private func cooperationNegativeCases(seed: UInt32) -> [CooperationNegativeCase] {
    var ambiguous = cooperationScenarioOffered(
        seed: seed, id: "cooperation-ambiguous-\(seed)", exact: false
    ).0
    _ = try! ambiguous.advanceTick()
    let ambiguousSnapshot = ambiguous.cooperationSnapshot()

    var wrong = cooperationScenarioAccepted(seed: seed, id: "cooperation-wrong-\(seed)")
    _ = try! wrong.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "helper",
        resourceObservations: [cooperationScenarioObservation(observerX: 1, fingerprint: 601)]
    )])
    cooperationScenarioHarvest(.wood, agent: "helper", index: 0, session: &wrong)
    try! wrong.applyDeliveryOutcome(AgentDeliveryOutcome(
        deliveryId: "shared-blocked-delivery",
        agentId: "helper",
        tick: wrong.tick,
        status: .blocked,
        transferred: [],
        reason: "controlled blocked delivery"
    ))
    cooperationScenarioDeliver("shared-wrong-delivery", agent: "helper", session: &wrong)
    let wrongSnapshot = wrong.cooperationSnapshot()

    var superseded = cooperationScenarioAccepted(
        seed: seed, id: "cooperation-superseded-\(seed)"
    )
    for index in 0..<3 {
        cooperationScenarioHarvest(.stone, agent: "builder", index: index, session: &superseded)
    }
    cooperationScenarioDeliver("shared-external-stone", agent: "builder", session: &superseded)
    _ = try! superseded.advanceTick()
    let supersededSnapshot = superseded.cooperationSnapshot()

    let short = try! AgentCooperationConfiguration(
        offerLifetimeTicks: 6,
        acceptedTaskLifetimeTicks: 1,
        offerCooldownTicks: 1
    )
    var failed = cooperationScenarioAccepted(
        seed: seed,
        id: "cooperation-failed-\(seed)",
        configuration: short
    )
    _ = try! failed.advanceTick()
    _ = try! failed.advanceTick()
    let failedSnapshot = failed.cooperationSnapshot()

    var urgent = cooperationScenarioOffered(
        seed: seed,
        id: "cooperation-urgent-\(seed)",
        helperHunger: 0.54
    ).0
    urgent.setSurvivalEnabled(true)
    let urgentTick = try! urgent.advanceTick()
    let urgentSnapshot = urgent.cooperationSnapshot()

    let trustConfiguration = try! AgentSessionConfiguration(
        seed: seed,
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
    var trustRefusal = try! AgentSimulationSession(
        configuration: trustConfiguration,
        agents: [
            cooperationScenarioState("builder", x: 0),
            cooperationScenarioState("helper", x: 1),
            cooperationScenarioState("excluded", x: 3, fear: 80),
        ],
        simulationID: try! AgentSimulationID(validating: "cooperation-trust-refusal-\(seed)"),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! trustRefusal.setSocialEnabled(true)
    _ = try! trustRefusal.advanceTick(perceptions: [AgentPerceptionInput(
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
    _ = try! trustRefusal.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "builder",
        socialResourceObservations: [AgentResourceObservation(
            resource: .stone,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: .east,
            distanceManhattan: 3,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 461
        )]
    )])
    let priorBelief = trustRefusal.socialSnapshot().beliefs.first!
    try! trustRefusal.createConstructionProject(
        cooperationScenarioProject("shared-trust-project-\(seed)")
    )
    try! trustRefusal.setBuildAutoEnabled(true)
    try! trustRefusal.setPhysicalEnabled(true)
    try! trustRefusal.setCooperationEnabled(true)
    _ = try! trustRefusal.advanceTick()
    let trustSignal = trustRefusal.physicalChannelSnapshot().signals.last!
    _ = try! trustRefusal.advanceTick(physicalObservations: [
        cooperationScenarioPhysicalObservation(
            trustSignal,
            observer: "helper",
            tick: trustRefusal.tick + 1,
            exact: true
        ),
    ])
    _ = try! trustRefusal.applySocialVerification(AgentSocialVerificationObservation(
        beliefID: priorBelief.beliefID,
        verifierID: priorBelief.ownerID,
        position: priorBelief.fact.position,
        chunkReady: true,
        observedBlockFingerprint: 0,
        observedResource: nil
    ))
    _ = try! trustRefusal.advanceTick()
    let trustSnapshot = trustRefusal.cooperationSnapshot()

    return [
        CooperationNegativeCase(
            name: "physical_ambiguous",
            taskStatus: ambiguousSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: ambiguousSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: 0,
            offerCount: ambiguousSnapshot.offers.count,
            accepted: ambiguousSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: ambiguousSnapshot.offers.isEmpty
                && ambiguousSnapshot.tasks.first?.acceptedAtTick == nil
        ),
        CooperationNegativeCase(
            name: "wrong_resource_and_blocked_delivery",
            taskStatus: wrongSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: wrongSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: 0,
            offerCount: wrongSnapshot.offers.count,
            accepted: wrongSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: wrongSnapshot.tasks.first?.contributedQuantity == 0
                && wrong.snapshot().campStock.count(of: .wood) == 1
        ),
        CooperationNegativeCase(
            name: "superseded_without_penalty",
            taskStatus: supersededSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: supersededSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: supersededSnapshot.relations.first?.reliabilityScore ?? 0,
            offerCount: supersededSnapshot.offers.count,
            accepted: supersededSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: supersededSnapshot.tasks.first?.status == .superseded
                && supersededSnapshot.relations.isEmpty
        ),
        CooperationNegativeCase(
            name: "accepted_lifetime_failure",
            taskStatus: failedSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: failedSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: failedSnapshot.relations.first?.reliabilityScore ?? 0,
            offerCount: failedSnapshot.offers.count,
            accepted: failedSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: failedSnapshot.tasks.first?.status == .failed
                && failedSnapshot.relations.first?.reliabilityScore == -10
        ),
        CooperationNegativeCase(
            name: "survival_urgency_preempts_acceptance",
            taskStatus: urgentSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: urgentSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: urgentSnapshot.relations.first?.reliabilityScore ?? 0,
            offerCount: urgentSnapshot.offers.count,
            accepted: urgentSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: urgentSnapshot.tasks.first?.acceptedAtTick == nil
                && urgentTick.agents.first { $0.agentId == "helper" }?.snapshot.currentGoal.kind
                    == .satisfyHunger
        ),
        CooperationNegativeCase(
            name: "negative_informational_trust_declines",
            taskStatus: trustSnapshot.tasks.first?.status.rawValue,
            contributedQuantity: trustSnapshot.tasks.first?.contributedQuantity ?? 0,
            reliability: trustSnapshot.relations.first?.reliabilityScore ?? 0,
            offerCount: trustSnapshot.offers.count,
            accepted: trustSnapshot.tasks.first?.acceptedAtTick != nil,
            passed: trustRefusal.trustScore(
                sourceAgentId: "helper", targetAgentId: "builder"
            ) == -15
                && trustSnapshot.tasks.first?.status == .declined
                && trustSnapshot.relations.isEmpty
        ),
    ]
}

func runSharedTasksCooperationSmoke(_ options: Options) -> Never {
    guard let outPath = options.outPath else {
        fail("shared_tasks_cooperation_smoke requires an explicit --out directory")
    }
    let seed = options.seed
    let run = runCooperationCanonical(seed: seed, id: "cooperation-canonical-\(seed)")
    let repeated = runCooperationCanonical(seed: seed, id: "cooperation-canonical-\(seed)")
    let negatives = cooperationNegativeCases(seed: seed)
    let snapshot = run.session.snapshot()
    let cooperation = run.session.cooperationSnapshot()
    let relation = cooperation.relations.first!
    let project = snapshot.constructionProject!
    let causal = run.session.causalLedgerSnapshot()
    let cooperationKinds: Set<AgentCausalEventKind> = [
        .sharedTaskCreated, .sharedTaskSignaled, .sharedTaskOffered,
        .sharedTaskAccepted, .sharedTaskStarted, .sharedTaskProgress,
        .sharedTaskCompleted, .cooperationReliabilityChanged,
        .constructionFunding, .constructionPlacement, .constructionCompletion,
    ]
    let chain = causal.events.filter { cooperationKinds.contains($0.kind) }
    let deterministic = run.session.snapshot() == repeated.session.snapshot()
        && run.session.cooperationSnapshot() == repeated.session.cooperationSnapshot()
        && causal == repeated.session.causalLedgerSnapshot()
    var checks: [CooperationScenarioCheck] = []
    func add(_ name: String, _ passed: Bool) {
        checks.append(CooperationScenarioCheck(name: name, passed: passed))
    }
    add("builder_unique", run.task.issuerID.rawValue == "builder")
    add("helper_distinct", run.task.helperID.rawValue == "helper" && run.task.helperID != run.task.issuerID)
    add("task_kind_unique", AgentSharedTaskKind.allCases == [.deliverConstructionMaterial])
    add("project_valid", run.task.projectID == project.projectId)
    add("source_fact_direct", run.session.socialSnapshot().facts.contains {
        $0.factID == run.factID && $0.observerID == run.task.issuerID
    })
    add("physical_exact_required", run.session.physicalChannelSnapshot().perceptions.contains {
        $0.signalID == run.signalID && $0.observerID == run.task.helperID && $0.outcome == .exact
    })
    add("ambiguous_insufficient", negatives.first { $0.name == "physical_ambiguous" }?.passed == true)
    add("acceptance_voluntary_next_tick", run.task.acceptedAtTick.map { $0 > run.task.createdAtTick } == true)
    add("one_active_task_per_helper", cooperation.tasks.filter {
        $0.helperID == run.task.helperID && !$0.status.isTerminal
    }.count <= 1)
    add("demand_commitment_bounded", run.task.requestedQuantity == 3)
    add("no_double_commitment", cooperation.tasks.filter { $0.projectID == project.projectId }.count == 1)
    add("correct_resource_only", run.task.resource == .stone && run.task.contributedQuantity == 3)
    add("actual_delivery_only", run.campBeforeHelperDelivery.isEmpty && run.campAfterHelperDelivery == [AgentResourceAmount(resource: .stone, quantity: 3)])
    add("completion_exact", run.task.status == .completed && run.task.remainingQuantity == 0)
    add("reliability_distinct_from_trust", relation.reliabilityScore == 10 && run.session.trustScore(sourceAgentId: "helper", targetAgentId: "builder") == 0)
    add("helper_funding_absent", causal.events.filter { $0.kind == .constructionFunding }.allSatisfy { $0.actorID?.rawValue == "builder" })
    add("helper_placement_absent", causal.events.filter { $0.kind == .constructionPlacement }.allSatisfy { $0.actorID?.rawValue == "builder" })
    add("conservation_exact", snapshot.conservation.balanced && snapshot.conservation.harvestedTotal == 9 && snapshot.conservation.constructedTotal == 9)
    add("causal_chain_complete", cooperationKinds.allSatisfy { kind in chain.contains { $0.kind == kind } })
    add("causes_prior", chain.allSatisfy { event in event.causes.allSatisfy { $0.sequence < event.sequence } })
    add("collections_bounded", cooperation.tasks.count <= cooperation.configuration.maximumTasks && cooperation.offers.count <= cooperation.configuration.maximumOffers && cooperation.relations.count <= cooperation.configuration.maximumRelations)
    add("negative_cases", negatives.allSatisfy(\.passed))
    add("permutations_stable", deterministic)
    add("digest_repeatable", deterministic)
    let report = CooperationScenarioInvariantReport(
        scenario: "shared_tasks_cooperation_smoke",
        seed: seed,
        success: checks.allSatisfy(\.passed),
        checks: checks
    )
    guard report.success else {
        fail("shared_tasks_cooperation_smoke invariant failure: \(checks.filter { !$0.passed }.map(\.name).joined(separator: ","))")
    }
    let summary = CooperationScenarioSummary(
        scenario: "shared_tasks_cooperation_smoke",
        seed: seed,
        projectID: project.projectId,
        taskID: run.task.taskID.rawValue,
        builderID: run.task.issuerID.rawValue,
        helperID: run.task.helperID.rawValue,
        excludedID: "excluded",
        sourceFactID: run.factID.rawValue,
        signalID: run.signalID.rawValue,
        requestedResource: run.task.resource.rawValue,
        requestedQuantity: run.task.requestedQuantity,
        contributedQuantity: run.task.contributedQuantity,
        finalTaskStatus: run.task.status.rawValue,
        finalReliability: relation.reliabilityScore,
        fundingTick: run.fundingTick,
        placementTicks: run.placementTicks,
        completionTick: run.completionTick,
        finalHome: snapshot.agents.first { $0.id == "builder" }!.homePosition,
        negativeCases: negatives
    )
    let contributions = CooperationContributionReport(
        helperStoneHarvested: 3,
        helperStoneDelivered: 3,
        helperWoodHarvested: 0,
        helperWoodDelivered: 0,
        builderWoodHarvested: 6,
        builderWoodDelivered: 6,
        builderStoneHarvested: 0,
        builderStoneDelivered: 0,
        campBeforeHelperDelivery: run.campBeforeHelperDelivery,
        campAfterHelperDelivery: run.campAfterHelperDelivery,
        campBeforeFunding: run.campBeforeFunding,
        escrowAfterFunding: run.escrowAfterFunding,
        constructedAfterCompletion: project.placedMaterialTotals.amounts,
        conservation: snapshot.conservation
    )
    let digest = CooperationScenarioDigest(
        cooperationDigest: run.session.cooperationSummary().digest,
        socialDigest: run.session.socialSummary().digest,
        physicalDigest: run.session.physicalChannelSummary().digest,
        causalDigest: causal.summary.digest,
        repeatedCooperationDigest: repeated.session.cooperationSummary().digest,
        repeatedCausalDigest: repeated.session.causalLedgerSnapshot().summary.digest,
        deterministic: deterministic
    )
    let directory = URL(fileURLWithPath: outPath, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writeJSON(cooperation.tasks, to: directory.appendingPathComponent("cooperation_tasks.json"))
        try writeJSON(cooperation.offers, to: directory.appendingPathComponent("cooperation_offers.json"))
        try writeJSON(cooperation.relations, to: directory.appendingPathComponent("cooperation_relations.json"))
        try writeJSON(contributions, to: directory.appendingPathComponent("cooperation_contributions.json"))
        try writeJSON(chain, to: directory.appendingPathComponent("cooperation_causal_chain.json"))
        try writeJSON(summary, to: directory.appendingPathComponent("cooperation_summary.json"))
        try writeJSON(digest, to: directory.appendingPathComponent("cooperation_digest.json"))
        try writeJSON(report, to: directory.appendingPathComponent("cooperation_invariant_report.json"))
    } catch {
        fail("failed to write cooperation scenario outputs to \(outPath): \(error)")
    }
    print("shared_tasks_cooperation_smoke PASS task=\(run.task.taskID.rawValue) contributed=\(run.task.contributedQuantity) reliability=\(relation.reliabilityScore) digest=\(digest.cooperationDigest)")
    exit(0)
}
