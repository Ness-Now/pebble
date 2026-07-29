import Foundation
import PebbleAgents

private func mortalityAgent(
    _ id: String,
    health: Int = 100,
    lethalNextTick: Bool = false
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: id,
        state: "idle",
        position: AgentPosition(x: Int(id.suffix(1)) ?? 0, y: 64, z: 0),
        needs: AgentNeeds(
            hunger: lethalNextTick ? 1 : 0,
            fatigue: 0,
            curiosity: 0,
            safety: 1
        ),
        health: health,
        fear: 0,
        homePosition: AgentPosition(x: Int(id.suffix(1)) ?? 0, y: 64, z: 0),
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
        totalDistanceReducedTowardHome: 0,
        survivalProgress: AgentSurvivalProgress(
            status: lethalNextTick ? .starving : .stable,
            consecutiveCriticalHungerTicks: lethalNextTick ? 2 : 0
        )
    )
}

private func mortalitySession(_ simulation: String) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            mortalityAgent("agent_0", health: 10, lethalNextTick: true),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: simulation),
        causalLedgerPolicy: .bounded(maxEvents: 4096)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    try! session.setMortalityEnabled(true)
    return session
}

private let mortalityProofSurvival = try! AgentSurvivalConfiguration(
    hungerPerTick: 0.05,
    fatiguePerTick: 0.06,
    hungryThreshold: 0.40,
    criticalHungerThreshold: 0.80,
    hungerRecoveryThreshold: 0.15,
    fatigueThreshold: 0.65,
    fatigueRecoveryThreshold: 0.20,
    foodNutrition: 1.0,
    restRecoveryPerTick: 1.0,
    starvationGraceTicks: 2,
    starvationDamagePerTick: 100
)

private func mortalityPreparedSession(
    _ simulation: String,
    navigationMaxReplans: Int = 3
) -> AgentSimulationSession {
    let configuration = try! AgentSessionConfiguration(
        seed: 46,
        nearbyRadius: 12,
        resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8,
        memoryPolicy: .bounded(maxEntries: 128),
        navigationMaxReplans: navigationMaxReplans,
        navigationReplanCooldownTicks: 1,
        survivalConfiguration: mortalityProofSurvival,
        socialConfiguration: try! AgentSocialConfiguration(shareCooldownTicks: 1)
    )
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            mortalityAgent("agent_0", health: 100, lethalNextTick: true),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: simulation),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    try! session.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    return session
}

@discardableResult
private func mortalityKillPrepared(_ session: inout AgentSimulationSession) -> AgentMortalityRecord {
    session.setSurvivalEnabled(true)
    try! session.setMortalityEnabled(true)
    _ = try! session.advanceTick()
    return session.mortalitySnapshot().records.last!
}

private func mortalityResourceObservation(
    resource: AgentResourceKind,
    target: AgentPosition,
    direction: AgentCardinalDirection,
    fingerprint: Int
) -> AgentResourceObservation {
    AgentResourceObservation(
        resource: resource,
        target: target,
        direction: direction,
        distanceManhattan: abs(target.x) + abs(target.z),
        quantityAvailable: 1,
        source: .naturalWorld,
        expectedBlockFingerprint: fingerprint
    )
}

private func mortalityNavigation(
    tick: Int,
    target: AgentPosition
) -> AgentNavigationObservation {
    let cells: [AgentNavigationCell]
    if target.x != 0 {
        cells = (0...target.x).map {
            AgentNavigationCell(position: AgentPosition(x: $0, y: 64, z: 0), status: .traversable)
        }
    } else {
        cells = (0...target.z).map {
            AgentNavigationCell(position: AgentPosition(x: 0, y: 64, z: $0), status: .traversable)
        }
    }
    return AgentNavigationObservation(
        worldTick: tick,
        origin: AgentPosition(x: 0, y: 64, z: 0),
        target: target,
        radius: 8,
        cells: cells
    )
}

private func mortalityConstructionProject(_ id: String) -> AgentConstructionProject {
    try! AgentConstructionProject(
        projectId: id,
        builderAgentId: "agent_0",
        origin: AgentPosition(x: 4, y: 64, z: 4),
        createdAtTick: 0,
        previousHomePosition: AgentPosition(x: 0, y: 64, z: 0),
        originalFingerprints: AgentBlueprint.fixedLeanToV1.cells.map {
            AgentConstructionCellFingerprint(cellIndex: $0.index, originalFingerprint: 0)
        }
    )
}

private func mortalityEcologyHabitat(tick: Int = 0) -> AgentEcologyHabitatObservation {
    AgentEcologyHabitatObservation(
        worldTick: tick,
        candidateIndex: 0,
        habitatPosition: AgentPosition(x: 3, y: 63, z: 0),
        foragePosition: AgentPosition(x: 3, y: 64, z: 0),
        habitatFingerprint: 528,
        distanceFromSettlement: 3,
        directionIndex: 0,
        worldReadCount: 4
    )
}

func runPebbleAgentsMortalityPopulationExitSmoke() {
    section("pebble agents mortality and population exit")

    let live = AgentMortalityConfiguration.live
    check("mortality configuration defaults", live.maximumDeathsPerTick == 8
        && live.maximumRetainedDeathRecords == 32
        && live.maximumFinalMemoryEntries == 8
        && live.maximumCancelledCommitmentIDsPerDeath == 32
        && live.maximumExitFrames == 32)
    check("mortality rejects zero deaths per tick", {
        do {
            _ = try AgentMortalityConfiguration(maximumDeathsPerTick: 0)
            return false
        } catch AgentMortalityError.invalidConfiguration("deaths per tick") {
            return true
        } catch { return false }
    }())
    check("mortality rejects oversized death history", {
        do {
            _ = try AgentMortalityConfiguration(maximumRetainedDeathRecords: 65)
            return false
        } catch AgentMortalityError.invalidConfiguration("death records") {
            return true
        } catch { return false }
    }())
    check("mortality accepts zero final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 0
    )) != nil)
    check("mortality rejects oversized final memories", (try? AgentMortalityConfiguration(
        maximumFinalMemoryEntries: 17
    )) == nil)
    check("mortality accepts zero commitment IDs", (try? AgentMortalityConfiguration(
        maximumCancelledCommitmentIDsPerDeath: 0
    )) != nil)
    check("mortality rejects oversized exit history", (try? AgentMortalityConfiguration(
        maximumExitFrames: 65
    )) == nil)
    check("mortality configuration Codable", {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let bytes = try? encoder.encode(live),
              let decoded = try? JSONDecoder().decode(
                  AgentMortalityConfiguration.self,
                  from: bytes
              ) else { return false }
        return decoded == live
    }())
    check(
        "mortality cause V2 preserves legacy starvation and bounded physiology causes",
        AgentMortalityCause.allCases == [
            .starvation,
            .deprivation,
            .exhaustion,
            .compoundedHomeostaticFailure,
        ]
    )
    check("death ID validates canonical form", AgentDeathID(
        rawValue: "death-agent_3-t33-0123456789abcdef"
    ) != nil)
    check("death ID rejects path punctuation", AgentDeathID(rawValue: "death/agent_3") == nil)

    let historical = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 2)],
        campStock: []
    )
    check("mortality-off conservation remains exact", historical.balanced
        && historical.unrecoveredAtDeathTotal == 0)
    let terminal = AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    )
    check("mortality terminal custody conserves resources", terminal.balanced
        && terminal.unrecoveredAtDeathTotal == 2)
    check("mortality terminal custody cannot hide duplication", !AgentResourceConservationSnapshot(
        harvested: [AgentResourceAmount(resource: .wood, quantity: 2)],
        carried: [AgentResourceAmount(resource: .wood, quantity: 1)],
        campStock: [],
        unrecoveredAtDeath: [AgentResourceAmount(resource: .wood, quantity: 2)]
    ).balanced)

    var activationRefusal = mortalitySession("sim-mortality-activation-refusal")
    try! activationRefusal.setMortalityEnabled(false)
    let invalidConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 64)
    )
    var invalidSession = try! AgentSimulationSession(
        configuration: invalidConfiguration,
        agents: [
            mortalityAgent("agent_0", health: 0, lethalNextTick: true),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: "sim-mortality-invalid-health"),
        causalLedgerPolicy: .bounded(maxEvents: 128)
    )
    invalidSession.setSurvivalEnabled(true)
    try! invalidSession.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
    )
    let invalidBefore = try! invalidSession.durableStateBytes()
    check("mortality activation rejects zero health", {
        do {
            try invalidSession.setMortalityEnabled(true)
            return false
        } catch AgentSessionError.mortality(.nonLivingAgent("agent_0")) {
            return true
        } catch { return false }
    }())
    check("mortality activation refusal atomic", invalidBefore
        == (try! invalidSession.durableStateBytes()))

    var session = mortalitySession("sim-mortality-lethal")
    let preLethalState = try! session.state(for: "agent_0")
    let result = try! session.advanceTick()
    let mortality = session.mortalitySnapshot()
    let record = mortality.records.first
    let lethalEvents = session.causalLedgerSnapshot().events.filter {
        $0.actorID?.rawValue == "agent_0" && [
            AgentCausalEventKind.lethalHealthDepletion.rawValue,
            AgentCausalEventKind.mortalityResourcesRetired.rawValue,
            AgentCausalEventKind.mortalityCommitmentsResolved.rawValue,
            AgentCausalEventKind.populationMemberExited.rawValue,
            AgentCausalEventKind.agentDeathFinalized.rawValue,
        ].contains($0.kind.rawValue)
    }
    let lethalEvent = lethalEvents.first { $0.kind == .lethalHealthDepletion }
    let resourcesEvent = lethalEvents.first { $0.kind == .mortalityResourcesRetired }
    let commitmentsEvent = lethalEvents.first { $0.kind == .mortalityCommitmentsResolved }
    let exitEvent = lethalEvents.first { $0.kind == .populationMemberExited }
    let finalizedEvent = lethalEvents.first { $0.kind == .agentDeathFinalized }
    check("mortality lethal health reaches zero", record?.healthBeforeLethalDamage == 10
        && record?.finalHealth == 0)
    check("mortality starvation cause", record?.cause == .starvation)
    check("mortality death tick exact", record?.deathTick == 1)
    check("mortality removes active state", session.snapshot().agents.map(\.id)
        == ["agent_1", "agent_2"])
    check("mortality population exits three to two", session.populationSummary().memberCount == 2
        && mortality.exitFrames.first?.populationBefore == 3
        && mortality.exitFrames.first?.populationAfter == 2)
    check("mortality lethal agent has no terminal result", !result.agents.contains {
        $0.agentId == "agent_0"
    })
    check("mortality survivors retain cognition", result.agents.map(\.agentId)
        == ["agent_1", "agent_2"])
    check("mortality death record has lethal memory", record?.finalMemory.last?.type
        == "starvation_damage")
    check("mortality lethal causal order exact", record?.finalMemory.last?.tick == 1
        && record?.finalMemory.last?.type == "starvation_damage"
        && lethalEvents.map(\.kind.rawValue) == [
            AgentCausalEventKind.lethalHealthDepletion.rawValue,
            AgentCausalEventKind.mortalityResourcesRetired.rawValue,
            AgentCausalEventKind.mortalityCommitmentsResolved.rawValue,
            AgentCausalEventKind.populationMemberExited.rawValue,
            AgentCausalEventKind.agentDeathFinalized.rawValue,
        ]
        && resourcesEvent?.causes == [lethalEvent!.eventID]
        && commitmentsEvent?.causes == [lethalEvent!.eventID]
        && exitEvent?.causes == [
            lethalEvent!.eventID,
            resourcesEvent!.eventID,
            commitmentsEvent!.eventID,
        ].sorted()
        && finalizedEvent?.causes == [exitEvent!.eventID])
    check("mortality finalized event is terminal", finalizedEvent?.eventID == record?.deathEventID
        && lethalEvents.last?.kind == .agentDeathFinalized)
    let forbiddenCognition = Set([
        AgentCausalEventKind.perception.rawValue,
        AgentCausalEventKind.goalTransition.rawValue,
        AgentCausalEventKind.actionSelected.rawValue,
        AgentCausalEventKind.resourceFactGrounded.rawValue,
        AgentCausalEventKind.socialMessageSent.rawValue,
        AgentCausalEventKind.physicalSignalEmitted.rawValue,
        AgentCausalEventKind.sharedTaskAccepted.rawValue,
        AgentCausalEventKind.sharedTaskProgress.rawValue,
    ])
    let forbiddenMaterial = Set([
        AgentCausalEventKind.movement.rawValue,
        AgentCausalEventKind.interaction.rawValue,
        AgentCausalEventKind.delivery.rawValue,
        AgentCausalEventKind.consumption.rawValue,
        AgentCausalEventKind.constructionPlacement.rawValue,
        AgentCausalEventKind.ecologyForageResolved.rawValue,
    ])
    let postLethalEvents = session.causalLedgerSnapshot().events.filter {
        $0.sequence > lethalEvent!.sequence
            && ($0.actorID?.rawValue == "agent_0" || $0.subjectID?.rawValue == "agent_0")
    }
    check("mortality no post lethal cognition", !postLethalEvents.contains {
        forbiddenCognition.contains($0.kind.rawValue)
    })
    check("mortality no post lethal material action", !postLethalEvents.contains {
        forbiddenMaterial.contains($0.kind.rawValue)
    })
    let terminalActivity = record!.terminalActivity
    check("mortality terminal observation count frozen", terminalActivity.observationCount
        == preLethalState.observationCount
        && terminalActivity.nearbyObservationCount == preLethalState.nearbyObservationCount)
    check("mortality terminal goal counters frozen", terminalActivity.goalSelectionCount
        == preLethalState.goalSelectionCount
        && terminalActivity.goalChangeCount == preLethalState.goalChangeCount)
    check("mortality terminal action counters frozen", terminalActivity.actionCount
        == preLethalState.actionCount
        && terminalActivity.actionEffectCount == preLethalState.actionEffectCount)
    check("mortality terminal movement counters frozen", terminalActivity.movementCount
        == preLethalState.movementCount
        && terminalActivity.totalManhattanDistanceMoved
            == preLethalState.totalManhattanDistanceMoved
        && terminalActivity.returnHomeMoveCount == preLethalState.returnHomeMoveCount)
    check("mortality terminal consumption count frozen", terminalActivity.foodConsumedCount
        == (preLethalState.survivalProgress?.foodConsumedCount ?? 0))
    check("mortality terminal ticks alive advances once", terminalActivity.ticksAlive
        == preLethalState.ticksAlive + 1)
    check("mortality terminal last activity exact", terminalActivity.lastGoal
        == preLethalState.currentGoal.kind
        && terminalActivity.lastAction == preLethalState.lastAction
        && terminalActivity.lastActionEffect == preLethalState.lastActionEffect
        && terminalActivity.lastMovementOutcomeStatus == preLethalState.lastMovementOutcome?.status
        && terminalActivity.lastInteractionOutcomeStatus
            == preLethalState.lastInteractionOutcome?.status
        && terminalActivity.lastDeliveryOutcomeStatus == preLethalState.lastDeliveryOutcome?.status
        && terminalActivity.lastConsumptionOutcomeStatus
            == preLethalState.survivalProgress?.lastConsumptionOutcome?.status)
    check("mortality empty inventory remains conserved", session.conservationSnapshot().balanced
        && mortality.unrecoveredAtDeath.isEmpty)
    check("mortality active IDs equal population members", session.expectedActiveAgentIDs()
        == session.populationSnapshot().members.map(\.agentID))
    check("mortality cannot disable after death", {
        do {
            try session.setMortalityEnabled(false)
            return false
        } catch AgentSessionError.mortality(.unsafeDisable) {
            return true
        } catch { return false }
    }())

    var checkpointSource = mortalitySession("sim-mortality-checkpoint")
    let preDeathCheckpoint = try! checkpointSource.makeCheckpoint()
    check("mortality checkpoint uses v5", preDeathCheckpoint.schemaVersion == 5)
    let preDeathBytes = try! checkpointSource.durableStateBytes()
    let preDeathRestored = try! AgentSimulationSession.restoring(preDeathCheckpoint)
    check("mortality pre-death restore exact", preDeathBytes
        == (try! preDeathRestored.durableStateBytes()))
    var recorder = try! AgentReplayRecorder(
        checkpoint: preDeathCheckpoint,
        session: checkpointSource
    )
    _ = try! recorder.apply(
        .advanceTick(perceptions: [], physicalObservations: []),
        to: &checkpointSource
    )
    let postDeathBytes = try! checkpointSource.durableStateBytes()
    let postDeathCheckpoint = try! checkpointSource.makeCheckpoint()
    check("mortality post-death checkpoint uses v5", postDeathCheckpoint.schemaVersion == 5)
    let postDeathRestored = try! AgentSimulationSession.restoring(postDeathCheckpoint)
    check("mortality post-death restore exact", postDeathBytes
        == (try! postDeathRestored.durableStateBytes()))
    check("mortality restore does not resurrect", postDeathRestored.expectedActiveAgentIDs()
        .map(\.rawValue) == ["agent_1", "agent_2"])
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "mortality-lethal")!
    )
    let replay = try! AgentSessionReplayer.replay(
        checkpoint: preDeathCheckpoint,
        journal: journal
    )
    check("mortality replay schema v5", journal.manifest.schemaVersion == 5)
    check("mortality replay verifies lethal tick", replay.report.verified)
    check("mortality replay exact post-death bytes", postDeathBytes
        == (try! replay.session.durableStateBytes()))

    var resources = mortalitySession("sim-mortality-resources")
    try! resources.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "mortality-wood",
        agentId: "agent_0",
        tick: 0,
        target: AgentPosition(x: 0, y: 64, z: 1),
        resource: .wood,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .wood, quantity: 1),
        reason: "authoritative fixture harvest"
    ))
    try! resources.applyInteractionOutcome(AgentInteractionOutcome(
        interactionId: "mortality-stone",
        agentId: "agent_0",
        tick: 0,
        target: AgentPosition(x: 0, y: 64, z: -1),
        resource: .stone,
        status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .stone, quantity: 1),
        reason: "authoritative fixture harvest"
    ))
    _ = try! resources.advanceTick()
    let resourceDeath = resources.mortalitySnapshot()
    check("mortality retires multiple carried resources", resourceDeath.records.first?
        .carriedInventory == [
            AgentResourceAmount(resource: .wood, quantity: 1),
            AgentResourceAmount(resource: .stone, quantity: 1),
        ])
    check("mortality terminal custody exact", resourceDeath.unrecoveredAtDeath == [
        AgentResourceAmount(resource: .wood, quantity: 1),
        AgentResourceAmount(resource: .stone, quantity: 1),
    ])
    check("mortality resource transfer conserved", resources.conservationSnapshot().balanced
        && resources.conservationSnapshot().carriedTotal == 0
        && resources.conservationSnapshot().unrecoveredAtDeathTotal == 2)

    var resourceCleanup = mortalityPreparedSession(
        "sim-mortality-resource-cleanup",
        navigationMaxReplans: 0
    )
    resourceCleanup.setEconomyEnabled(true)
    resourceCleanup.setNaturalResourcesEnabled(true)
    let firstResourceTarget = AgentPosition(x: 3, y: 64, z: 0)
    let secondResourceTarget = AgentPosition(x: 0, y: 64, z: 4)
    let cleanupObservations = [
        mortalityResourceObservation(
            resource: .wood,
            target: firstResourceTarget,
            direction: .east,
            fingerprint: 701
        ),
        mortalityResourceObservation(
            resource: .stone,
            target: secondResourceTarget,
            direction: .south,
            fingerprint: 702
        ),
    ]
    _ = try! resourceCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        resourceObservations: cleanupObservations,
        navigationObservation: mortalityNavigation(tick: 1, target: firstResourceTarget)
    )])
    try! resourceCleanup.applyMovementOutcomes(
        AgentMovementCoordinator.resolve(snapshot: resourceCleanup.snapshot())
    )
    _ = try! resourceCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        resourceObservations: cleanupObservations,
        navigationObservation: mortalityNavigation(tick: 2, target: firstResourceTarget)
    )])
    _ = try! resourceCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        resourceObservations: cleanupObservations,
        navigationObservation: mortalityNavigation(tick: 3, target: secondResourceTarget)
    )])
    let resourceCleanupBefore = resourceCleanup.durableState()
    let resourceAgentBefore = try! resourceCleanup.state(for: "agent_0")
    let resourceHistoryBefore = resourceCleanup.causalLedgerSnapshot().events
    let resourceCleanupRecord = mortalityKillPrepared(&resourceCleanup)
    let resourceCleanupAfter = resourceCleanup.durableState()
    check("mortality resource fixture has active reservation target navigation", resourceAgentBefore
        .activeResourceTarget?.target == secondResourceTarget
        && resourceAgentBefore.navigationProgress.status == .active
        && resourceCleanupBefore.reservations.contains { $0.agentId == "agent_0" })
    check("mortality resource fixture has failed target diagnostic", resourceCleanupBefore
        .failedNaturalResourceTargets.contains {
            $0.agentID == "agent_0" && !$0.targetKeys.isEmpty
        })
    check("mortality resource active state removed", resourceCleanupAfter.reservations
        .allSatisfy { $0.agentId != "agent_0" }
        && !resourceCleanupAfter.failedNaturalResourceTargets.contains { $0.agentID == "agent_0" }
        && !resourceCleanup.expectedActiveAgentIDs().map(\.rawValue).contains("agent_0"))
    check("mortality resource material history preserved", Array(resourceCleanup
        .causalLedgerSnapshot().events.prefix(resourceHistoryBefore.count)) == resourceHistoryBefore
        && resourceCleanupRecord.cleanupCounts.reservations == 1)
    check("mortality survivor causal pointers preserved", resourceCleanupBefore
        .lastPerceptionEvents.filter { $0.agentID.rawValue != "agent_0" }.allSatisfy { pointer in
            resourceCleanupAfter.lastPerceptionEvents.contains { $0.agentID == pointer.agentID }
        }
        && resourceCleanupBefore.lastDecisionEvents
            .filter { $0.agentID.rawValue != "agent_0" }.allSatisfy { pointer in
                resourceCleanupAfter.lastDecisionEvents.contains { $0.agentID == pointer.agentID }
            }
        && resourceCleanupBefore.lastOutcomeEvents
            .filter { $0.agentID.rawValue != "agent_0" }.allSatisfy { pointer in
                resourceCleanupAfter.lastOutcomeEvents.contains { $0.agentID == pointer.agentID }
            })

    var socialCleanup = mortalityPreparedSession("sim-mortality-social-cleanup")
    try! socialCleanup.setSocialEnabled(true)
    _ = try! socialCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_1",
        socialResourceObservations: [AgentResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 0, y: 64, z: 1),
            direction: .west,
            distanceManhattan: 2,
            quantityAvailable: 1,
            source: .naturalWorld,
            expectedBlockFingerprint: 801
        )]
    )])
    for _ in 0..<4 where socialCleanup.socialSnapshot().messages.isEmpty {
        _ = try! socialCleanup.advanceTick()
    }
    if socialCleanup.socialVerificationRequest(for: "agent_0") == nil {
        _ = try! socialCleanup.advanceTick()
    }
    let socialCleanupBefore = socialCleanup.durableState()
    let socialHistoryBefore = socialCleanup.socialSnapshot()
    let socialTrustBefore = socialCleanup.trustSnapshot()
    let socialCleanupRecord = mortalityKillPrepared(&socialCleanup)
    let socialCleanupAfter = socialCleanup.durableState()
    check("mortality social fixture has active verification", socialCleanupBefore
        .activeSocialVerifications.contains(where: { $0.agentID == "agent_0" }))
    check("mortality social verification removed", !socialCleanupAfter
        .activeSocialVerifications.contains(where: { $0.agentID == "agent_0" })
        && socialCleanupRecord.cleanupCounts.socialVerifications == 1)
    check("mortality social history preserved", socialCleanup.socialSnapshot().facts
        == socialHistoryBefore.facts
        && socialCleanup.socialSnapshot().messages == socialHistoryBefore.messages
        && socialCleanup.socialSnapshot().beliefs == socialHistoryBefore.beliefs
        && socialCleanup.trustSnapshot() == socialTrustBefore)

    var physicalCleanup = mortalityPreparedSession("sim-mortality-physical-cleanup")
    try! physicalCleanup.setSocialEnabled(true)
    try! physicalCleanup.setPhysicalEnabled(true)
    _ = try! physicalCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        socialResourceObservations: [mortalityResourceObservation(
            resource: .wood,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: .east,
            fingerprint: 901
        )]
    )])
    _ = try! physicalCleanup.advanceTick()
    let physicalCleanupBefore = physicalCleanup.durableState()
    let physicalHistoryBefore = physicalCleanup.physicalChannelSnapshot().perceptions
    let physicalSignal = physicalCleanup.physicalChannelSnapshot().signals.last!
    let physicalCleanupRecord = mortalityKillPrepared(&physicalCleanup)
    let physicalCleanupAfter = physicalCleanup.durableState()
    check("mortality physical fixture has pending signal presentation", physicalSignal.senderID
        .rawValue == "agent_0" && physicalSignal.status == .pending
        && physicalCleanupBefore.physicalPresentationRequests.contains {
            $0.senderID.rawValue == "agent_0" && $0.presentedAtTick == nil
        })
    check("mortality physical pending state resolved", physicalCleanup.physicalChannelSnapshot()
        .signals.contains { $0.signalID == physicalSignal.signalID && $0.status == .cancelled }
        && !physicalCleanupAfter.physicalPresentationRequests.contains {
            $0.senderID.rawValue == "agent_0" && $0.presentedAtTick == nil
        }
        && physicalCleanupRecord.cleanupCounts.physicalSignals == 1
        && physicalCleanupRecord.cleanupCounts.physicalPresentations == 1)
    check("mortality physical cooldown removed", physicalCleanupBefore.lastSocialShareTicks
        .contains { $0.key == "agent_0" }
        && !physicalCleanupAfter.lastSocialShareTicks.contains { $0.key == "agent_0" })
    check("mortality physical perceptions preserved", physicalCleanup.physicalChannelSnapshot()
        .perceptions == physicalHistoryBefore)

    var cooperationCleanup = mortalityPreparedSession("sim-mortality-cooperation-cleanup")
    try! cooperationCleanup.setSocialEnabled(true)
    try! cooperationCleanup.setPhysicalEnabled(true)
    try! cooperationCleanup.createConstructionProject(mortalityConstructionProject(
        "mortality-cleanup-project"
    ))
    try! cooperationCleanup.setCooperationEnabled(true)
    _ = try! cooperationCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        socialResourceObservations: [mortalityResourceObservation(
            resource: .stone,
            target: AgentPosition(x: 3, y: 64, z: 0),
            direction: .east,
            fingerprint: 1_001
        )]
    )])
    _ = try! cooperationCleanup.advanceTick()
    let cooperationSignal = cooperationCleanup.physicalChannelSnapshot().signals.last!
    _ = try! cooperationCleanup.advanceTick(physicalObservations: [
        AgentPhysicalSignalObservation(
            signalID: cooperationSignal.signalID,
            observerID: AgentID(rawValue: "agent_1")!,
            distanceManhattan: 1,
            soundClarity: 95,
            gestureClarity: 95,
            opaqueOcclusionCount: 0,
            lineOfSight: true,
            chunksReady: true,
            observedAtTick: cooperationCleanup.tick + 1
        ),
    ])
    let cooperationBefore = cooperationCleanup.cooperationSnapshot()
    let constructionBefore = cooperationCleanup.snapshot().constructionProject!
    let cooperationCleanupRecord = mortalityKillPrepared(&cooperationCleanup)
    let cooperationAfter = cooperationCleanup.cooperationSnapshot()
    let constructionAfter = cooperationCleanup.snapshot().constructionProject!
    check("mortality cooperation fixture has active task offer", cooperationBefore.tasks
        .contains { !$0.status.isTerminal && $0.issuerID.rawValue == "agent_0" }
        && cooperationBefore.offers.contains { $0.issuerID.rawValue == "agent_0" })
    check("mortality cooperation task cancelled participant died", cooperationAfter.tasks
        .contains { $0.status == .cancelled && $0.reason == "participantDied" }
        && cooperationAfter.offers.isEmpty
        && cooperationCleanupRecord.cleanupCounts.cooperationTasks == 1
        && cooperationCleanupRecord.cleanupCounts.cooperationOffers == 1)
    check("mortality cooperation reliability history preserved", cooperationAfter.relations
        == cooperationBefore.relations)
    check("mortality construction builder death blocks project", constructionAfter.status
        == .blocked && constructionAfter.lastFailure == .builderDied
        && constructionAfter.materialEscrow == constructionBefore.materialEscrow
        && constructionAfter.placedCellIndices == constructionBefore.placedCellIndices
        && cooperationCleanupRecord.cleanupCounts.constructionProjects == 1)

    var ecologyCleanup = mortalityPreparedSession("sim-mortality-ecology-cleanup")
    let ecologyHabitat = mortalityEcologyHabitat()
    try! ecologyCleanup.initializeLocalEcology(observations: [ecologyHabitat])
    let ecologyObservations = try! ecologyCleanup.localEcologyResourceObservations(
        for: AgentID(rawValue: "agent_0")!,
        habitatValidations: [ecologyHabitat]
    )
    _ = try! ecologyCleanup.advanceTick(perceptions: [AgentPerceptionInput(
        agentId: "agent_0",
        resourceObservations: ecologyObservations,
        navigationObservation: mortalityNavigation(
            tick: 1,
            target: ecologyHabitat.foragePosition
        )
    )])
    let ecologyPatch = ecologyCleanup.localEcologySnapshot().patches.first!
    let blockedForage = try! ecologyCleanup.applyForageIntents([
        AgentForageIntent(
            forageID: "mortality-ecology-not-adjacent",
            patchID: ecologyPatch.patchID,
            agentID: AgentID(rawValue: "agent_0")!,
            tick: ecologyCleanup.tick,
            target: ecologyPatch.foragePosition,
            observedAtTick: ecologyCleanup.tick,
            expectedHabitatFingerprint: ecologyPatch.habitatFingerprint
        ),
    ], habitatValidations: [mortalityEcologyHabitat(tick: ecologyCleanup.tick)])
    let ecologyCleanupBefore = ecologyCleanup.durableState()
    let ecologyStateBefore = ecologyCleanup.localEcologySnapshot()
    _ = mortalityKillPrepared(&ecologyCleanup)
    let pressureAfterDeath = try! ecologyCleanup.applyLocalEcologyEndOfTick(
        habitatValidations: [mortalityEcologyHabitat(tick: ecologyCleanup.tick)]
    )
    let ecologyCleanupAfter = ecologyCleanup.durableState()
    let ecologyStateAfter = ecologyCleanup.localEcologySnapshot()
    check("mortality ecology fixture has active target reservation", ecologyCleanupBefore.agents
        .first { $0.id == "agent_0" }?.activeResourceTarget?.source == .localEcology
        && ecologyCleanupBefore.reservations.contains {
            $0.agentId == "agent_0" && $0.ecologyPatchID == ecologyPatch.patchID
        })
    check("mortality ecology fixture has real forage history", blockedForage.first?.status
        == .notAdjacent && ecologyCleanupBefore.localEcologyState?.processedForageIDs
        == ["mortality-ecology-not-adjacent"])
    check("mortality ecology active state removed", !ecologyCleanupAfter.reservations
        .contains { $0.agentId == "agent_0" }
        && !ecologyCleanupAfter.agents.contains { $0.id == "agent_0" })
    check("mortality ecology history and patch preserved", ecologyStateAfter.patches
        == ecologyStateBefore.patches
        && ecologyStateAfter.forageHistory == ecologyStateBefore.forageHistory
        && ecologyCleanupAfter.localEcologyState?.processedForageIDs
            == ecologyCleanupBefore.localEcologyState?.processedForageIDs)
    check("mortality ecology pressure uses survivors", pressureAfterDeath?.input.population == 2
        && ecologyCleanup.ecologyConservationSnapshot().balanced
        && ecologyCleanup.conservationSnapshot().balanced)

    let cleanupDurableStates = [
        resourceCleanup.durableState(),
        socialCleanup.durableState(),
        physicalCleanup.durableState(),
        cooperationCleanup.durableState(),
        ecologyCleanup.durableState(),
    ]
    check("mortality causal pointers remove dead keys", cleanupDurableStates.allSatisfy { state in
        !state.lastPerceptionEvents.contains { $0.agentID.rawValue == "agent_0" }
            && !state.lastDecisionEvents.contains { $0.agentID.rawValue == "agent_0" }
            && !state.lastOutcomeEvents.contains { $0.agentID.rawValue == "agent_0" }
    })
    check("mortality population cleanup exact across fixtures", cleanupDurableStates.allSatisfy {
        $0.populationRegistry?.members.map(\.agentID.rawValue) == ["agent_1", "agent_2"]
            && $0.populationRegistry?.settlement.residentIDs.map(\.rawValue)
                == ["agent_1", "agent_2"]
            && $0.populationRegistry?.nextPopulationOrdinal.rawValue == 3
    })

    func simultaneous(
        _ reversed: Bool,
        mortalityConfiguration: AgentMortalityConfiguration = .live
    ) -> AgentSimulationSession {
        let config = try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 64)
        )
        var agents = [
            mortalityAgent("agent_0", health: 10, lethalNextTick: true),
            mortalityAgent("agent_1", health: 10, lethalNextTick: true),
            mortalityAgent("agent_2", health: 10, lethalNextTick: true),
        ]
        if reversed { agents.reverse() }
        var value = try! AgentSimulationSession(
            configuration: config,
            agents: agents,
            simulationID: try! AgentSimulationID(validating: "sim-mortality-simultaneous"),
            causalLedgerPolicy: .bounded(maxEvents: 4096)
        )
        value.setSurvivalEnabled(true)
        try! value.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
        )
        try! value.setMortalityEnabled(true, configuration: mortalityConfiguration)
        _ = try! value.advanceTick()
        return value
    }
    var simultaneousA = simultaneous(false)
    let simultaneousB = simultaneous(true)
    check("mortality simultaneous deaths sorted", simultaneousA.mortalitySnapshot()
        .records.map(\.agentID.rawValue) == ["agent_0", "agent_1", "agent_2"])
    check("mortality simultaneous input order neutral", (try! simultaneousA.durableStateBytes())
        == (try! simultaneousB.durableStateBytes()))
    check("mortality zero active snapshot safe", simultaneousA.snapshot().agents.isEmpty
        && simultaneousA.populationSummary().memberCount == 0)
    let emptyTick = try! simultaneousA.advanceTick()
    check("mortality zero active tick safe", emptyTick.tick == 2 && emptyTick.agents.isEmpty)

    func capacityInvalidBatch(_ reversed: Bool) -> (
        rejected: Bool,
        before: Data,
        after: Data,
        session: AgentSimulationSession
    ) {
        let config = try! AgentSessionConfiguration(
            seed: 46,
            memoryPolicy: .bounded(maxEntries: 64)
        )
        var agents = [
            mortalityAgent("agent_0", health: 10, lethalNextTick: true),
            mortalityAgent("agent_1", health: 10, lethalNextTick: true),
            mortalityAgent("agent_2"),
        ]
        if reversed { agents.reverse() }
        var value = try! AgentSimulationSession(
            configuration: config,
            agents: agents,
            simulationID: try! AgentSimulationID(validating: "sim-mortality-invalid-batch"),
            causalLedgerPolicy: .bounded(maxEvents: 4096)
        )
        value.setSurvivalEnabled(true)
        try! value.initializePopulationRegistry(
            settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
            receptionPosition: AgentPosition(x: 0, y: 64, z: 0)
        )
        try! value.setMortalityEnabled(true, configuration: try! AgentMortalityConfiguration(
            maximumDeathsPerTick: 1
        ))
        let before = try! value.durableStateBytes()
        let rejected: Bool
        do {
            _ = try value.advanceTick()
            rejected = false
        } catch AgentSessionError.mortality(.deathsPerTickExceeded(2)) {
            rejected = true
        } catch {
            rejected = false
        }
        return (rejected, before, try! value.durableStateBytes(), value)
    }
    let invalidBatch = capacityInvalidBatch(false)
    let reversedInvalidBatch = capacityInvalidBatch(true)
    check("mortality batch late member invalid rollback", invalidBatch.rejected
        && invalidBatch.session.mortalitySnapshot().records.isEmpty
        && invalidBatch.session.populationSummary().memberCount == 3)
    check("mortality batch rollback durable bytes exact", invalidBatch.before
        == invalidBatch.after)
    check("mortality batch rollback input order neutral", reversedInvalidBatch.rejected
        && reversedInvalidBatch.before == invalidBatch.before
        && reversedInvalidBatch.after == invalidBatch.after)

    let boundedMortality = try! AgentMortalityConfiguration(
        maximumRetainedDeathRecords: 1,
        maximumExitFrames: 1
    )
    let evicted = simultaneous(false, mortalityConfiguration: boundedMortality)
    let evictedSnapshot = evicted.mortalitySnapshot()
    check("mortality death record eviction deterministic", evictedSnapshot.totalDeathCount == 3
        && evictedSnapshot.records.map(\.agentID.rawValue) == ["agent_2"]
        && evictedSnapshot.evictionCounts.deathRecords == 2)
    check("mortality processed IDs match retained records", evictedSnapshot.processedDeathIDs
        == evictedSnapshot.records.map(\.deathID))
    check("mortality exit frame eviction deterministic", evictedSnapshot.exitFrames
        .map(\.agentID.rawValue) == ["agent_2"]
        && evictedSnapshot.evictionCounts.exitFrames == 2)
    check("mortality bounded checkpoint restores exact", {
        guard let restored = try? AgentSimulationSession.restoring(evicted.makeCheckpoint()) else {
            return false
        }
        return (try? evicted.durableStateBytes()) == (try? restored.durableStateBytes())
    }())

    var transitioningMetrics = mortalitySession("sim-mortality-metrics-transition")
    try! transitioningMetrics.setSettlementMetricsEnabled(true)
    for _ in 0..<4 { _ = try! transitioningMetrics.advanceTick() }
    let mortalityFrame = try! transitioningMetrics.applySettlementMetricsPulseIfDue()
    check("mortality settlement transition classified", mortalityFrame?.condition
        == .transitioning && mortalityFrame?.reasonCode == "population_changed")
    check("mortality settlement death and exit delta", mortalityFrame?.mortality?.deathDelta == 1
        && mortalityFrame?.mortality?.exitDelta == 1
        && mortalityFrame?.populationEventDelta == 1)
    check("mortality settlement population reduced", mortalityFrame?.population.members == 2
        && mortalityFrame?.mortality?.totalDeathCount == 1)

    var zeroMetrics = simultaneous(false)
    try! zeroMetrics.setSettlementMetricsEnabled(true)
    for _ in 0..<4 { _ = try! zeroMetrics.advanceTick() }
    let zeroFrame = try! zeroMetrics.applySettlementMetricsPulseIfDue()
    check("mortality zero active settlement pulse safe", zeroFrame?.population.members == 0
        && zeroFrame?.condition == .stable)

    let migrationConfiguration = try! AgentSessionConfiguration(
        seed: 46,
        memoryPolicy: .bounded(maxEntries: 128)
    )
    var migration = try! AgentSimulationSession(
        configuration: migrationConfiguration,
        agents: [
            mortalityAgent("agent_0"),
            mortalityAgent("agent_1"),
            mortalityAgent("agent_2"),
        ],
        simulationID: try! AgentSimulationID(validating: "sim-mortality-migrant"),
        causalLedgerPolicy: .bounded(maxEvents: 8192)
    )
    migration.setSurvivalEnabled(true)
    try! migration.initializePopulationRegistry(
        settlementAnchor: AgentPosition(x: 0, y: 64, z: 0),
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3)
    )
    try! migration.setMortalityEnabled(true)
    for index in 0..<3 {
        try! migration.applyInteractionOutcome(AgentInteractionOutcome(
            interactionId: "founder-food-\(index)",
            agentId: "agent_\(index)",
            tick: 0,
            target: AgentPosition(x: index, y: 64, z: 1),
            resource: .foodRaw,
            status: .succeeded,
            inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
            reason: "authoritative fixture harvest"
        ))
    }
    let route = [4, 3, 2, 1, 0].map { AgentPosition(x: $0, y: 64, z: 3) }
    _ = try! migration.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: 0,
            candidateIndex: 0,
            entryPosition: route[0],
            receptionPosition: route.last!,
            route: route
        )
    )
    for step in 1...27 {
        _ = try! migration.advanceTick()
        if step == 16 {
            for index in 0..<3 {
                let id = "agent_\(index)"
                let state = try! migration.state(for: id)
                try! migration.applyConsumptionOutcome(AgentConsumptionOutcome(
                    consumptionId: "founder-consume-\(index)",
                    agentId: id,
                    tick: migration.tick,
                    resource: .foodRaw,
                    quantity: 1,
                    status: .succeeded,
                    hungerBefore: state.needs.hunger,
                    hungerAfter: 0,
                    reason: "one carried foodRaw consumed atomically"
                ))
            }
        }
    }
    let failedMigration = migration.migrationSnapshot().migrations.first
    check("mortality migrant exit typed member died", failedMigration?.status == .failed
        && failedMigration?.failure == .memberDied)
    check("mortality migrant removed without arrival", migration.expectedActiveAgentIDs()
        .map(\.rawValue) == ["agent_0", "agent_1", "agent_2"]
        && migration.populationSnapshot().settlement?.inTransitIDs.isEmpty == true)
    let replacement = try! migration.admitMigration(
        intent: AgentMigrationAdmissionIntent(),
        observation: AgentMigrationWorldObservation(
            worldTick: migration.tick,
            candidateIndex: 0,
            entryPosition: route[0],
            receptionPosition: route.last!,
            route: route
        )
    )
    check("mortality replacement is agent four", replacement.migrantID.rawValue == "agent_4")
    check("mortality replacement ordinal monotone", migration.populationSummary()
        .nextPopulationOrdinal == 5 && !migration.expectedActiveAgentIDs().map(\.rawValue)
        .contains("agent_3"))
    check("mortality population migration history preserved", migration.migrationSnapshot()
        .migrations.first == failedMigration)
}
