import Foundation
import PebbleAgents

private let skillHome = AgentPosition(x: 0, y: 64, z: 0)
private let skillLifecycle = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func skillAgent(
    _ ordinal: Int,
    position: AgentPosition,
    hunger: Double = 0
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(hunger: hunger, fatigue: -1, curiosity: 0, safety: 1),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "skill fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func skillLethalAgent(_ ordinal: Int, lethal: Bool) -> AgentSessionAgentState {
    let position = AgentPosition(x: ordinal, y: 64, z: 0)
    return AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: position,
        needs: AgentNeeds(
            hunger: lethal ? 1 : 0, fatigue: -1, curiosity: 0, safety: 1
        ),
        health: 100, fear: 0, homePosition: position, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "skill mortality fixture",
            startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethal ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethal ? 2 : 0
        )
    )
}

private func skillMortalitySession() -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.01,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.8,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 1,
        restRecoveryPerTick: 1, starvationGraceTicks: 2,
        starvationDamagePerTick: 100
    )
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 79, nearbyRadius: 12, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            survivalConfiguration: survival,
            socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
            cooperationConfiguration: try! AgentCooperationConfiguration(
                offerCooldownTicks: 1
            )
        ),
        agents: [
            skillLethalAgent(0, lethal: false),
            skillLethalAgent(1, lethal: false),
            skillLethalAgent(2, lethal: true),
        ],
        simulationID: try! AgentSimulationID(validating: "skill-mortality"),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: skillHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.setLifecycleEnabled(true, configuration: skillLifecycle)
    try! session.setSkillsEnabled(true)
    return session
}

private func skillBase(
    _ id: String,
    skillConfiguration: AgentSkillConfiguration = .live,
    causalMaximum: Int = 16_384,
    survival: AgentSurvivalConfiguration = .live,
    activateSkills: Bool = true
) -> AgentSimulationSession {
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 79, nearbyRadius: 12, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 128),
            campStockCapacity: 64,
            survivalConfiguration: survival,
            socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1),
            cooperationConfiguration: try! AgentCooperationConfiguration(
                offerCooldownTicks: 1
            )
        ),
        agents: [
            skillAgent(0, position: skillHome),
            skillAgent(1, position: AgentPosition(x: 1, y: 64, z: 0)),
            skillAgent(2, position: AgentPosition(x: 0, y: 64, z: 1)),
        ],
        simulationID: try! AgentSimulationID(validating: id),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximum)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: skillHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.setLifecycleEnabled(true, configuration: skillLifecycle)
    if activateSkills {
        try! session.setSkillsEnabled(true, configuration: skillConfiguration)
    }
    return session
}

private func skillInteraction(
    _ session: inout AgentSimulationSession,
    agentID: String,
    resource: AgentResourceKind,
    index: Int,
    recorder: inout AgentReplayRecorder?
) {
    let outcome = AgentInteractionOutcome(
        interactionId: "skill-harvest-\(agentID)-\(resource.rawValue)-\(index)",
        agentId: agentID, tick: session.tick,
        target: AgentPosition(x: 20 + index, y: 64, z: index),
        resource: resource, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: resource, quantity: 1),
        reason: "verified bounded material success"
    )
    if recorder != nil {
        _ = try! recorder!.apply(.interactionOutcome(outcome), to: &session)
    } else {
        try! session.applyInteractionOutcome(outcome)
    }
}

@discardableResult
private func skillDelivery(
    _ session: inout AgentSimulationSession,
    agentID: String,
    id: String,
    recorder: inout AgentReplayRecorder?
) -> AgentDeliveryOutcome {
    let intent = AgentDeliveryIntent(
        deliveryId: id, agentId: agentID, tick: session.tick,
        position: session.snapshot().agents.first { $0.id == agentID }!.position
    )
    var preview = session
    let outcome = try! preview.deliverResources(intent)
    if recorder != nil {
        _ = try! recorder!.apply(.deliveryOutcome(outcome), to: &session)
    } else {
        try! session.applyDeliveryOutcome(outcome)
    }
    return outcome
}

private func skillProject(_ id: String) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id, builderAgentId: "agent_0",
        origin: AgentPosition(x: 2, y: 64, z: -1), createdAtTick: 0,
        previousHomePosition: skillHome,
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func skillStoneObservation() -> AgentResourceObservation {
    AgentResourceObservation(
        resource: .stone, target: AgentPosition(x: 2, y: 64, z: 0),
        direction: .east, distanceManhattan: 2, quantityAvailable: 1,
        source: .naturalWorld, expectedBlockFingerprint: 790
    )
}

private func skillMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) throws -> AgentSessionCheckpoint {
    var root = try JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutationBytes = try JSONSerialization.data(
        withJSONObject: durable, options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try AgentCheckpointCodec.encode(mutatedState)
    let canonical = try JSONSerialization.jsonObject(with: durableBytes) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root, options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func skillRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        let mutated = try skillMutatedCheckpoint(checkpoint, mutate: mutate)
        _ = try AgentSimulationSession.restoring(mutated)
        return false
    } catch {
        return true
    }
}

private func skillMutateFirstCausalEvent(
    _ durable: inout [String: Any],
    pointer: String,
    mutate: (inout [String: Any]) -> Void
) {
    let skills = durable["skillState"] as! [String: Any]
    let records = skills["retainedPracticeRecords"] as! [[String: Any]]
    let eventID = records[0][pointer] as! [String: Any]
    let sequence = eventID["sequence"] as! Int
    var ledger = durable["causalLedger"] as! [String: Any]
    let dropped = ledger["droppedEventCount"] as! Int
    var events = ledger["events"] as! [[String: Any]]
    mutate(&events[sequence - dropped - 1])
    ledger["events"] = events
    durable["causalLedger"] = ledger
}

private func skillTrainMaterialHandling(
    _ session: inout AgentSimulationSession,
    agentID: String,
    deliveries: Int,
    recorder: inout AgentReplayRecorder?
) {
    for index in 0..<deliveries {
        skillInteraction(
            &session, agentID: agentID, resource: .foodRaw,
            index: 100 + index, recorder: &recorder
        )
        _ = skillDelivery(
            &session, agentID: agentID,
            id: "skill-delivery-\(agentID)-\(index)", recorder: &recorder
        )
    }
}

func runPebbleAgentsSkillSmoke() {
    section("pebble agents practice-based skills and task matching")

    let live = AgentSkillConfiguration.live
    check("skills live bounds", live.maximumProfiles == 512
        && live.maximumRetainedPracticeRecords == 1024
        && live.maximumPracticeRecordsPerAgent == 128
        && live.maximumPracticeCreditsPerTick == 32
        && live.maximumPracticeUnitsPerCredit == 4)
    check("skills configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentSkillConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    check("skills configuration rejects zero profiles",
          (try? AgentSkillConfiguration(maximumProfiles: 0)) == nil)
    check("skills configuration rejects inverted record bounds", (try?
        AgentSkillConfiguration(
            maximumRetainedPracticeRecords: 2,
            maximumPracticeRecordsPerAgent: 3
        )) == nil)
    check("skills V1 domains exact", AgentSkillDomain.allCases == [
        .foraging, .materialHandling, .construction, .caregiving,
    ])
    check("skills levels are derived", [0, 1, 2, 3, 5, 6].map {
        AgentSkillLevel(practiceUnits: $0)
    } == [.untrained, .novice, .novice, .practiced, .practiced, .skilled])
    let newbornPolicy = AgentStageCapabilityPolicy.policy(for: .newborn)
    check("skills newborn cannot source autonomous practice",
          !newbornPolicy.permits(.harvest) && !newbornPolicy.permits(.build)
            && !newbornPolicy.permits(.deliver)
            && !newbornPolicy.permits(.cooperateAsWorker)
            && !newbornPolicy.permits(.reproduce)
            && !newbornPolicy.permits(.voluntaryMigration)
            && !newbornPolicy.permits(.selfConsumeCarriedFood))
    let juvenilePolicy = AgentStageCapabilityPolicy.policy(for: .juvenile)
    check("skills juvenile remains barred from adult material practice",
          juvenilePolicy.permits(.perceive) && juvenilePolicy.permits(.returnHome)
            && juvenilePolicy.permits(.selfConsumeCarriedFood)
            && !juvenilePolicy.permits(.harvest) && !juvenilePolicy.permits(.build)
            && !juvenilePolicy.permits(.deliver)
            && !juvenilePolicy.permits(.cooperateAsWorker)
            && !juvenilePolicy.permits(.reproduce))

    var noPopulation = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 79, memoryPolicy: .bounded(maxEntries: 8)
        ),
        agents: [skillAgent(0, position: skillHome)],
        simulationID: try! AgentSimulationID(validating: "skill-no-population"),
        causalLedgerPolicy: .bounded(maxEvents: 64)
    )
    let noPopulationBytes = try! noPopulation.durableStateBytes()
    check("skills activation without population atomic", {
        do { try noPopulation.setSkillsEnabled(true); return false }
        catch AgentSessionError.skill(.populationRequired) {
            return (try! noPopulation.durableStateBytes()) == noPopulationBytes
        } catch { return false }
    }())
    var noLifecycle = skillBase("skill-no-lifecycle", activateSkills: false)
    noLifecycle = try! AgentSimulationSession(
        configuration: noLifecycle.configuration,
        agents: noLifecycle.snapshot().agents.map { snapshot in
            skillAgent(Int(snapshot.id.split(separator: "_").last!)!, position: snapshot.position)
        },
        simulationID: try! AgentSimulationID(validating: "skill-no-lifecycle-2"),
        causalLedgerPolicy: .bounded(maxEvents: 128)
    )
    try! noLifecycle.initializePopulationRegistry(
        settlementAnchor: skillHome,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3), configuration: .live
    )
    check("skills activation without lifecycle refused", {
        do { try noLifecycle.setSkillsEnabled(true); return false }
        catch AgentSessionError.skill(.lifecycleRequired) { return true }
        catch { return false }
    }())

    var empty = skillBase("skill-empty")
    check("skills explicit activation promotes schema v10",
          empty.durableState().schemaVersion == 10)
    check("skills activation grants no retroactive credit",
          empty.skillSnapshot().profiles.isEmpty
            && empty.skillSnapshot().totalPracticeCreditCount == 0)
    check("skills cannot be disabled after activation", {
        do { try empty.setSkillsEnabled(false); return false }
        catch AgentSessionError.skill(.unsafeDisable) { return true }
        catch { return false }
    }())

    let forageHabitat = AgentEcologyHabitatObservation(
        worldTick: 0, candidateIndex: 0,
        habitatPosition: AgentPosition(x: 1, y: 63, z: 1),
        foragePosition: AgentPosition(x: 1, y: 64, z: 1),
        habitatFingerprint: 791, distanceFromSettlement: 2,
        directionIndex: 0, worldReadCount: 4
    )
    try! empty.initializeLocalEcology(observations: [forageHabitat])
    let patch = empty.localEcologySnapshot().patches[0]
    let preForageUnits = empty.practiceUnits(
        agentID: AgentID(rawValue: "agent_2")!, domain: .foraging
    )
    let forage = try! empty.applyForageIntents([AgentForageIntent(
        forageID: "skill-real-forage", patchID: patch.patchID,
        agentID: AgentID(rawValue: "agent_2")!, tick: empty.tick,
        target: patch.foragePosition, observedAtTick: empty.tick,
        expectedHabitatFingerprint: patch.habitatFingerprint
    )], habitatValidations: [forageHabitat])
    check("skills real ecological forage succeeds", forage.first?.status == .succeeded)
    check("skills real forage credits one unit", empty.practiceUnits(
        agentID: AgentID(rawValue: "agent_2")!, domain: .foraging
    ) == preForageUnits + 1)
    let failedForageBytes = try! empty.durableStateBytes()
    let failedForage = try! empty.applyForageIntents([AgentForageIntent(
        forageID: "skill-depleted-forage", patchID: patch.patchID,
        agentID: AgentID(rawValue: "agent_2")!, tick: empty.tick,
        target: patch.foragePosition, observedAtTick: empty.tick,
        expectedHabitatFingerprint: patch.habitatFingerprint
    )], habitatValidations: [forageHabitat])
    check("skills failed forage grants zero practice",
          failedForage.first?.status == .depleted
            && empty.practiceUnits(
                agentID: AgentID(rawValue: "agent_2")!, domain: .foraging
            ) == preForageUnits + 1
            && (try! empty.durableStateBytes()) != failedForageBytes)

    var recorder: AgentReplayRecorder? = nil
    skillTrainMaterialHandling(
        &empty, agentID: "agent_2", deliveries: 3, recorder: &recorder
    )
    let agent2 = AgentID(rawValue: "agent_2")!
    let agent1 = AgentID(rawValue: "agent_1")!
    check("skills real deliveries credit material handling",
          empty.practiceUnits(agentID: agent2, domain: .materialHandling) == 3)
    check("skills different histories diverge", empty.practiceUnits(
        agentID: agent1, domain: .materialHandling
    ) == 0 && empty.skillLevel(agentID: agent2, domain: .materialHandling) == .practiced)
    let intentOnlyUnits = empty.practiceUnits(agentID: agent2, domain: .materialHandling)
    _ = try? empty.prevalidateDelivery(AgentDeliveryIntent(
        deliveryId: "skill-intent-only", agentId: "agent_2", tick: empty.tick,
        position: empty.state(for: "agent_2").position
    ))
    check("skills intent and dry-run grant zero practice", empty.practiceUnits(
        agentID: agent2, domain: .materialHandling
    ) == intentOnlyUnits)

    let duplicateOutcome = AgentDeliveryOutcome(
        deliveryId: "skill-delivery-agent_2-2", agentId: "agent_2", tick: empty.tick,
        status: .succeeded,
        transferred: [AgentResourceAmount(resource: .stone, quantity: 1)],
        reason: "duplicate source"
    )
    let duplicateBytes = try! empty.durableStateBytes()
    check("skills duplicate source operation refused atomically", {
        do { try empty.applyDeliveryOutcome(duplicateOutcome); return false }
        catch AgentSessionError.duplicateDelivery {
            return (try! empty.durableStateBytes()) == duplicateBytes
        } catch { return false }
    }())

    for index in 0..<6 {
        skillInteraction(
            &empty, agentID: "agent_0", resource: .wood,
            index: 600 + index, recorder: &recorder
        )
    }
    _ = skillDelivery(
        &empty, agentID: "agent_0", id: "skill-construction-wood",
        recorder: &recorder
    )
    for index in 0..<3 {
        skillInteraction(
            &empty, agentID: "agent_0", resource: .stone,
            index: 700 + index, recorder: &recorder
        )
    }
    _ = skillDelivery(
        &empty, agentID: "agent_0", id: "skill-construction-stone",
        recorder: &recorder
    )
    try! empty.createConstructionProject(skillProject("skill-practice-project"))
    try! empty.setBuildAutoEnabled(true)
    _ = try! empty.fundConstructionProject(
        fundingId: "skill-funding", builderAgentId: "agent_0", fundingTick: empty.tick
    )
    let constructionBefore = empty.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .construction
    )
    let project = empty.snapshot().constructionProject!
    try! empty.applyExternalUpdate(AgentExternalUpdate(
        agentId: "agent_0", position: project.nextWorkPosition!
    ))
    let placement = AgentPlacementIntent(
        placementId: "skill-placement-0", projectId: project.projectId,
        builderAgentId: "agent_0", tick: empty.tick,
        cellIndex: project.nextCell!.index, target: project.nextTarget!,
        workPosition: project.nextWorkPosition!, resource: project.nextCell!.resource
    )
    try! empty.prevalidatePlacement(placement)
    check("skills construction dry-run grants zero practice", empty.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .construction
    ) == constructionBefore)
    let failedPlacementBytes = try! empty.durableStateBytes()
    check("skills failed construction grants zero and rolls back", {
        do {
            try empty.applyPlacementOutcome(AgentPlacementOutcome(
                placementId: placement.placementId, projectId: placement.projectId,
                builderAgentId: placement.builderAgentId, tick: placement.tick,
                cellIndex: placement.cellIndex, target: placement.target,
                resource: placement.resource, status: .blocked,
                reason: "controlled World refusal"
            ))
            return false
        } catch {
            return (try! empty.durableStateBytes()) == failedPlacementBytes
        }
    }())
    try! empty.applyPlacementOutcome(AgentPlacementOutcome(
        placementId: placement.placementId, projectId: placement.projectId,
        builderAgentId: placement.builderAgentId, tick: placement.tick,
        cellIndex: placement.cellIndex, target: placement.target,
        resource: placement.resource, status: .succeeded,
        reason: "verified physical placement"
    ))
    check("skills published construction credits builder", empty.practiceUnits(
        agentID: AgentID(rawValue: "agent_0")!, domain: .construction
    ) == constructionBefore + 1)

    var matching = skillBase("skill-matching")
    var nilRecorder: AgentReplayRecorder? = nil
    skillTrainMaterialHandling(
        &matching, agentID: "agent_2", deliveries: 3, recorder: &nilRecorder
    )
    try! matching.setSocialEnabled(true)
    try! matching.setPhysicalEnabled(true)
    try! matching.createConstructionProject(skillProject("skill-matching-project"))
    try! matching.setBuildAutoEnabled(true)
    try! matching.setCooperationEnabled(true)
    _ = try! matching.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0", socialResourceObservations: [skillStoneObservation()]
    )])
    _ = try! matching.advanceTick()
    guard let matchedTask = matching.cooperationSnapshot().tasks.first else {
        let states = matching.snapshot().agents.map {
            "\($0.id):\($0.currentGoal.kind.rawValue):\($0.needs.hunger):\($0.needs.fatigue)"
        }.joined(separator: ",")
        fatalError(
            "missing skill matching task facts=\(matching.socialSnapshot().facts.count) "
                + "demand=\(String(describing: matching.uncommittedConstructionDemand())) "
                + "states=\(states)"
        )
    }
    check("skills task matching selects more practiced candidate",
          matchedTask.helperID == agent2)
    let matchingReason = matching.causalLedgerSnapshot().events.last(where: {
        $0.kind == .sharedTaskCreated
    }).flatMap { event -> String? in
        guard case let .cooperationTask(
            _, _, _, _, _, _, _, _, reason
        ) = event.payload else { return nil }
        return reason
    }
    check("skills task matching decision records skill rank",
          matchingReason?.contains("skill=materialHandling:3/practiced") == true)
    check("skills do not grant task acceptance practice", matching.practiceUnits(
        agentID: agent2, domain: .materialHandling
    ) == 3)

    let capacityConfiguration = try! AgentSkillConfiguration(
        maximumProfiles: 1,
        maximumRetainedPracticeRecords: 8,
        maximumPracticeRecordsPerAgent: 8,
        maximumPracticeCreditsPerTick: 8
    )
    var capacity = skillBase(
        "skill-profile-capacity", skillConfiguration: capacityConfiguration
    )
    skillInteraction(
        &capacity, agentID: "agent_1", resource: .wood, index: 500,
        recorder: &nilRecorder
    )
    _ = skillDelivery(
        &capacity, agentID: "agent_1", id: "skill-capacity-first",
        recorder: &nilRecorder
    )
    skillInteraction(
        &capacity, agentID: "agent_2", resource: .stone, index: 501,
        recorder: &nilRecorder
    )
    let capacityBefore = try! capacity.durableStateBytes()
    check("skills profile capacity late failure rolls back source and credit", {
        do {
            _ = try capacity.deliverResources(AgentDeliveryIntent(
                deliveryId: "skill-capacity-second", agentId: "agent_2",
                tick: capacity.tick, position: capacity.state(for: "agent_2").position
            ))
            return false
        } catch AgentSessionError.skill(.profileCapacityReached) {
            return (try! capacity.durableStateBytes()) == capacityBefore
        } catch { return false }
    }())

    let perTickConfiguration = try! AgentSkillConfiguration(
        maximumProfiles: 8,
        maximumRetainedPracticeRecords: 8,
        maximumPracticeRecordsPerAgent: 8,
        maximumPracticeCreditsPerTick: 1
    )
    var perTick = skillBase("skill-per-tick", skillConfiguration: perTickConfiguration)
    skillInteraction(
        &perTick, agentID: "agent_1", resource: .wood, index: 510,
        recorder: &nilRecorder
    )
    _ = skillDelivery(
        &perTick, agentID: "agent_1", id: "skill-per-tick-first",
        recorder: &nilRecorder
    )
    skillInteraction(
        &perTick, agentID: "agent_1", resource: .stone, index: 511,
        recorder: &nilRecorder
    )
    let perTickBefore = try! perTick.durableStateBytes()
    check("skills credits per tick overflow rolls back", {
        do {
            _ = try perTick.deliverResources(AgentDeliveryIntent(
                deliveryId: "skill-per-tick-second", agentId: "agent_1",
                tick: perTick.tick, position: perTick.state(for: "agent_1").position
            ))
            return false
        } catch AgentSessionError.skill(.creditsPerTickReached) {
            return (try! perTick.durableStateBytes()) == perTickBefore
        } catch { return false }
    }())

    let boundedConfiguration = try! AgentSkillConfiguration(
        maximumProfiles: 8,
        maximumRetainedPracticeRecords: 2,
        maximumPracticeRecordsPerAgent: 2,
        maximumPracticeCreditsPerTick: 8
    )
    var bounded = skillBase("skill-bounded", skillConfiguration: boundedConfiguration)
    skillTrainMaterialHandling(
        &bounded, agentID: "agent_2", deliveries: 3, recorder: &nilRecorder
    )
    check("skills detailed history evicts deterministically",
          bounded.skillSnapshot().retainedPracticeRecords.count == 2
            && bounded.skillSnapshot().evictionCounts.practiceRecords == 1)
    check("skills eviction never lowers cumulative mastery", bounded.practiceUnits(
        agentID: agent2, domain: .materialHandling
    ) == 3 && bounded.skillLevel(agentID: agent2, domain: .materialHandling) == .practiced)

    let checkpoint = try! matching.makeCheckpoint()
    let checkpointBytes = try! AgentCheckpointCodec.encode(checkpoint)
    let restored = try! AgentSimulationSession.restoring(checkpoint)
    let matchingBytes = try! matching.durableStateBytes()
    check("skills v10 checkpoint and restart exact", checkpoint.schemaVersion == 10
        && (try! restored.durableStateBytes()) == matchingBytes)
    check("skills v10 checkpoint bytes stable", checkpointBytes
        == (try! AgentCheckpointCodec.encode(try! matching.makeCheckpoint())))
    check("skills restore rejects duplicate profile", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var profiles = skills["profiles"] as! [[String: Any]]
        profiles.append(profiles[0])
        skills["profiles"] = profiles
        $0["skillState"] = skills
    })
    check("skills restore rejects incoherent totals", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        skills["totalPracticeUnits"] = 999
        $0["skillState"] = skills
    })
    check("skills restore rejects duplicate practice source", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var records = skills["retainedPracticeRecords"] as! [[String: Any]]
        records.append(records[0])
        skills["retainedPracticeRecords"] = records
        skills["totalPracticeCreditCount"] = records.count
        $0["skillState"] = skills
    })
    check("skills restore rejects foreign practice event", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var records = skills["retainedPracticeRecords"] as! [[String: Any]]
        var eventID = records[0]["skillPracticeEventID"] as! [String: Any]
        eventID["simulationID"] = "skill-foreign-simulation"
        records[0]["skillPracticeEventID"] = eventID
        skills["retainedPracticeRecords"] = records
        $0["skillState"] = skills
    })
    check("skills restore rejects zero practice units", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var records = skills["retainedPracticeRecords"] as! [[String: Any]]
        records[0]["practiceUnits"] = 0
        skills["retainedPracticeRecords"] = records
        $0["skillState"] = skills
    })
    check("skills restore rejects wrong retained source kind", skillRestoreRefused(checkpoint) {
        skillMutateFirstCausalEvent(&$0, pointer: "sourceSuccessEventID") {
            $0["kind"] = "perception"
        }
    })
    check("skills restore rejects wrong retained source actor", skillRestoreRefused(checkpoint) {
        skillMutateFirstCausalEvent(&$0, pointer: "sourceSuccessEventID") {
            $0["actorID"] = "agent_1"
        }
    })
    check("skills restore rejects wrong retained source subject", skillRestoreRefused(checkpoint) {
        skillMutateFirstCausalEvent(&$0, pointer: "sourceSuccessEventID") {
            $0["subjectID"] = "agent_1"
        }
    })
    check("skills restore rejects failed retained source", skillRestoreRefused(checkpoint) {
        skillMutateFirstCausalEvent(&$0, pointer: "sourceSuccessEventID") { event in
            var payload = event["payload"] as! [String: Any]
            var operation = payload["operation"] as! [String: Any]
            operation["status"] = "failed"
            payload["operation"] = operation
            event["payload"] = payload
        }
    })
    check("skills restore rejects wrong retained practice kind", skillRestoreRefused(checkpoint) {
        skillMutateFirstCausalEvent(&$0, pointer: "skillPracticeEventID") {
            $0["kind"] = "featureToggle"
        }
    })
    check("skills restore rejects foreign initialized event", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var eventID = skills["initializedEventID"] as! [String: Any]
        eventID["simulationID"] = "skill-foreign-simulation"
        skills["initializedEventID"] = eventID
        $0["skillState"] = skills
    })
    check("skills restore rejects absent last skill event", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var eventID = skills["lastSkillEventID"] as! [String: Any]
        eventID["sequence"] = 999_999
        skills["lastSkillEventID"] = eventID
        $0["skillState"] = skills
    })
    check("skills restore rejects unknown profile agent", skillRestoreRefused(checkpoint) {
        var skills = $0["skillState"] as! [String: Any]
        var profiles = skills["profiles"] as! [[String: Any]]
        profiles[0]["agentID"] = "agent_999"
        skills["profiles"] = profiles
        $0["skillState"] = skills
    })
    check("skills unknown checkpoint version refused", skillRestoreRefused(checkpoint) {
        $0["schemaVersion"] = 999
    })

    var evictedCausality = skillBase(
        "skill-evicted-causality", causalMaximum: 64
    )
    skillTrainMaterialHandling(
        &evictedCausality, agentID: "agent_2", deliveries: 1,
        recorder: &nilRecorder
    )
    for _ in 0..<30 { _ = try! evictedCausality.advanceTick() }
    let evictedCheckpoint = try! evictedCausality.makeCheckpoint()
    let evictedRecord = evictedCausality.retainedPracticeHistory().first!
    let droppedSequence = evictedCausality.causalLedgerSnapshot().summary.droppedEventCount
    check("skills restore accepts causality proven before retained frontier",
          droppedSequence > 0
            && evictedRecord.sourceSuccessEventID.sequence.rawValue <= droppedSequence
            && (try? AgentSimulationSession.restoring(evictedCheckpoint)) != nil)

    let base = skillBase("skill-replay", activateSkills: false)
    let baseCheckpoint = try! base.makeCheckpoint()
    var direct = base
    var replayRecorder = try! AgentReplayRecorder(
        checkpoint: baseCheckpoint, session: direct
    )
    _ = try! replayRecorder.apply(
        .setSkillsEnabled(true, configuration: .live), to: &direct
    )
    var optionalRecorder: AgentReplayRecorder? = replayRecorder
    skillTrainMaterialHandling(
        &direct, agentID: "agent_2", deliveries: 3,
        recorder: &optionalRecorder
    )
    replayRecorder = optionalRecorder!
    let journal = try! replayRecorder.journal(
        named: AgentCheckpointName(rawValue: "skill-smoke")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: baseCheckpoint, journal: journal
    ).session
    check("skills replay reproduces causes rather than addXP",
          !journal.records.contains { $0.operation.kind.rawValue.contains("practice") })
    let directBytes = try! direct.durableStateBytes()
    check("skills direct and replay bytes exact",
          (try! replayed.durableStateBytes()) == directBytes)
    check("skills direct and replay causal sequence exact",
          replayed.causalLedgerSnapshot() == direct.causalLedgerSnapshot())

    let gateOff = skillBase("skill-gate-off", activateSkills: false)
    check("skills gate off remains schema v6", gateOff.durableState().schemaVersion == 6)
    check("skills gate off omits durable state", !(String(
        data: try! gateOff.durableStateBytes(), encoding: .utf8
    )!).contains("skillState"))
    check("skills gate off emits no skill events", !gateOff.causalLedgerSnapshot().events
        .contains { $0.kind == .skillsInitialized || $0.kind == .skillPracticeCredited })

    var migrantSession = skillBase("skill-migrant")
    let migrationReception = AgentPosition(x: 0, y: 64, z: 3)
    let migrationEntry = AgentPosition(x: 4, y: 64, z: 3)
    let migration = try! migrantSession.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0, candidateIndex: 0,
            entryPosition: migrationEntry,
            receptionPosition: migrationReception,
            route: [
                migrationEntry,
                AgentPosition(x: 3, y: 64, z: 3),
                AgentPosition(x: 2, y: 64, z: 3),
                AgentPosition(x: 1, y: 64, z: 3),
                migrationReception,
            ],
            entryChunkReady: true, entrySafe: true, entryUnoccupied: true,
            receptionChunkReady: true, receptionSafe: true,
            receptionUnoccupied: true
        )
    )
    check("skills admitted migrant starts without invented practice",
          migration.migrantID.rawValue == "agent_3"
            && migrantSession.skillProfile(for: migration.migrantID) == nil
            && AgentSkillDomain.allCases.allSatisfy {
                migrantSession.practiceUnits(agentID: migration.migrantID, domain: $0) == 0
            })

    var mortality = skillMortalitySession()
    skillTrainMaterialHandling(
        &mortality, agentID: "agent_2", deliveries: 3,
        recorder: &nilRecorder
    )
    mortality.setSurvivalEnabled(true)
    try! mortality.setMortalityEnabled(true)
    _ = try! mortality.advanceTick()
    check("skills death preserves historical mastery",
          !mortality.snapshot().agents.contains { $0.id == "agent_2" }
            && mortality.skillProfile(for: agent2) != nil
            && mortality.practiceUnits(
                agentID: agent2, domain: .materialHandling
            ) == 3)
    let mortalityCheckpoint = try! mortality.makeCheckpoint()
    check("skills dead profile survives checkpoint restore",
          (try? AgentSimulationSession.restoring(mortalityCheckpoint))?.practiceUnits(
            agentID: agent2, domain: .materialHandling
          ) == 3)
    try! mortality.setSocialEnabled(true)
    try! mortality.setPhysicalEnabled(true)
    try! mortality.createConstructionProject(skillProject("skill-dead-exclusion"))
    try! mortality.setBuildAutoEnabled(true)
    try! mortality.setCooperationEnabled(true)
    _ = try! mortality.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0", socialResourceObservations: [skillStoneObservation()]
    )])
    _ = try! mortality.advanceTick()
    check("skills dead practiced agent is excluded from matching",
          mortality.cooperationSnapshot().tasks.first?.helperID.rawValue == "agent_1")

    let practiceEvents = direct.causalLedgerSnapshot().events.filter {
        $0.kind == .skillPracticeCredited
    }
    check("skills practice events causally follow material success",
          practiceEvents.count == 3 && practiceEvents.allSatisfy { event in
              event.causes.count == 1 && event.causes[0].sequence < event.sequence
          })
    check("skills profiles and history order stable",
          direct.skillSnapshot().profiles.map(\.agentID)
            == direct.skillSnapshot().profiles.map(\.agentID).sorted()
            && direct.retainedPracticeHistory().map(\.skillPracticeEventID)
                == direct.retainedPracticeHistory().map(\.skillPracticeEventID).sorted())
}
