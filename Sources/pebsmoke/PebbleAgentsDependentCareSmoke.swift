import Foundation
import PebbleAgents

private let careHabitat = AgentEcologyHabitatObservation(
    worldTick: 0,
    candidateIndex: 0,
    habitatPosition: AgentPosition(x: 1, y: 63, z: 0),
    foragePosition: AgentPosition(x: 1, y: 64, z: 0),
    habitatFingerprint: 912,
    distanceFromSettlement: 1,
    directionIndex: 0,
    worldReadCount: 4
)

private let careLifecycleConfiguration = try! AgentLifecycleConfiguration(
    newbornDurationTicks: 8,
    maturityAgeTicks: 24,
    reproductionEvaluationIntervalTicks: 1,
    reproductionPlanDelayTicks: 1,
    reproductionCooldownTicks: 1,
    maximumRetainedBirthRecords: 32,
    maximumRetainedPlanRecords: 32,
    maximumParentBirthCount: 16
)

private func careAgent(
    _ ordinal: Int,
    home: AgentPosition,
    hunger: Double = 0
) -> AgentSessionAgentState {
    AgentSessionAgentState(
        id: "agent_\(ordinal)", state: "idle", position: home,
        needs: AgentNeeds(hunger: hunger, fatigue: 0, curiosity: 0.1, safety: 1),
        health: 100, fear: 0, homePosition: home, nearbyAgents: [],
        currentGoal: AgentGoal(
            kind: .idle, reason: "dependent care fixture", startedAtTick: 0, urgency: 0
        ),
        lastAction: nil, lastActionEffect: nil, memory: [], tickCreated: 0,
        ticksAlive: 0, observationCount: 0, nearbyObservationCount: 0,
        goalSelectionCount: 0, goalChangeCount: 0, actionCount: 0,
        actionEffectCount: 0, movementCount: 0,
        totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
        totalDistanceReducedTowardHome: 0
    )
}

private func careMortalityBase(_ simulationID: String) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.005,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.95,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 0.6,
        restRecoveryPerTick: 1, starvationGraceTicks: 0,
        starvationDamagePerTick: 100
    )
    let home = AgentPosition(x: 0, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: try! AgentSessionConfiguration(
            seed: 71, nearbyRadius: 8, resourceObservationRadius: 8,
            recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 64),
            survivalConfiguration: survival
        ),
        agents: [
            careAgent(0, home: home, hunger: 0.20),
            careAgent(1, home: home),
            careAgent(2, home: AgentPosition(x: 5, y: 64, z: 0)),
        ],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: 16_384)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: home, receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [careHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(habitatValidations: [careHabitat])
    try! session.setLifecycleEnabled(true, configuration: careLifecycleConfiguration)
    try! session.setKinshipEnabled(true)
    try! session.setHouseholdsEnabled(true)
    try! session.setDependentCareEnabled(true, configuration: try! .init(
        nourishmentHungerThreshold: 0.40
    ))
    try! session.setReproductionEnabled(true)
    return session
}

private func careBase(
    _ simulationID: String,
    lifecycle: Bool = true,
    kinship: Bool = true,
    households: Bool = true,
    causalMaximum: Int = 16_384
) -> AgentSimulationSession {
    let survival = try! AgentSurvivalConfiguration(
        hungerPerTick: 0.05, fatiguePerTick: 0.005,
        hungryThreshold: 0.4, criticalHungerThreshold: 0.95,
        hungerRecoveryThreshold: 0.15, fatigueThreshold: 0.65,
        fatigueRecoveryThreshold: 0.2, foodNutrition: 0.6,
        restRecoveryPerTick: 1, starvationGraceTicks: 64,
        starvationDamagePerTick: 1
    )
    let configuration = try! AgentSessionConfiguration(
        seed: 67, nearbyRadius: 8, resourceObservationRadius: 8,
        recentMemorySnapshotLimit: 8, memoryPolicy: .bounded(maxEntries: 64),
        survivalConfiguration: survival
    )
    let homeA = AgentPosition(x: 0, y: 64, z: 0)
    let homeB = AgentPosition(x: 5, y: 64, z: 0)
    var session = try! AgentSimulationSession(
        configuration: configuration,
        agents: [
            careAgent(0, home: homeA), careAgent(1, home: homeA),
            careAgent(2, home: homeB),
        ],
        simulationID: try! AgentSimulationID(validating: simulationID),
        causalLedgerPolicy: .bounded(maxEvents: causalMaximum)
    )
    session.setSurvivalEnabled(true)
    try! session.initializePopulationRegistry(
        settlementAnchor: homeA,
        receptionPosition: AgentPosition(x: 0, y: 64, z: 3),
        configuration: .live
    )
    try! session.initializeLocalEcology(observations: [careHabitat])
    _ = try! session.applyLocalEcologyEndOfTick(habitatValidations: [careHabitat])
    guard lifecycle else { return session }
    try! session.setLifecycleEnabled(true, configuration: careLifecycleConfiguration)
    guard kinship else { return session }
    try! session.setKinshipEnabled(true)
    guard households else { return session }
    try! session.setHouseholdsEnabled(true)
    return session
}

private func careAdvance(
    _ recorder: inout AgentReplayRecorder,
    _ session: inout AgentSimulationSession,
    perceptions: [AgentPerceptionInput] = []
) -> AgentSessionTickResult {
    try! recorder.apply(
        .advanceTick(perceptions: perceptions, physicalObservations: []), to: &session
    ).tickResult!
}

private func careMovementPerception(
    agentID: AgentID,
    position: AgentPosition,
    target: AgentPosition,
    worldTick: Int
) -> AgentPerceptionInput {
    let center = AgentWorldColumnObservation(
        position: position, chunkReady: true, surfaceY: position.y,
        height: position.y, blockBelow: 1, blockAtFeet: 0, blockAtHead: 0,
        groundPresent: true, feetClear: true, headClear: true
    )
    let neighbors = AgentCardinalDirection.allCases.map { direction in
        let neighbor = AgentPosition(
            x: position.x + direction.dx, y: position.y, z: position.z + direction.dz
        )
        return AgentWorldNeighborObservation(
            direction: direction,
            column: AgentWorldColumnObservation(
                position: neighbor, chunkReady: true, surfaceY: position.y,
                height: position.y, blockBelow: 1, blockAtFeet: 0, blockAtHead: 0,
                groundPresent: true, feetClear: true, headClear: true
            ),
            stepDelta: 0, traversable: true, dangerousDrop: false
        )
    }
    let world = try! AgentWorldObservation(
        worldTick: worldTick, position: position, center: center, neighbors: neighbors,
        biomeId: nil, biomeName: nil, combinedLight: nil, skyLight: nil,
        blockLight: nil, dayTime: worldTick, raining: false, thundering: false
    )
    var cells: [AgentNavigationCell] = []
    for x in (position.x - 8)...(position.x + 8) {
        for z in (position.z - 8)...(position.z + 8)
        where abs(x - position.x) + abs(z - position.z) <= 8 {
            cells.append(AgentNavigationCell(
                position: AgentPosition(x: x, y: position.y, z: z), status: .traversable
            ))
        }
    }
    return AgentPerceptionInput(
        agentId: agentID.rawValue, worldObservation: world,
        navigationObservation: AgentNavigationObservation(
            worldTick: worldTick, origin: position, target: target, radius: 8, cells: cells
        )
    )
}

private func careBirth(
    _ recorder: inout AgentReplayRecorder,
    _ session: inout AgentSimulationSession,
    position: AgentPosition,
    candidateIndex: Int
) -> AgentBirthRecord {
    for _ in 0..<32 where session.pendingBirthSitePlan() == nil {
        _ = careAdvance(&recorder, &session)
    }
    guard session.pendingBirthSitePlan() != nil else {
        fatalError("dependent care smoke reproduction plan was not created by tick \(session.tick)")
    }
    let plan = session.pendingBirthSitePlan()!
    for _ in 0..<32 where session.tick < plan.dueTick {
        _ = careAdvance(&recorder, &session)
    }
    guard session.tick >= plan.dueTick else {
        fatalError("dependent care smoke reproduction plan never became due")
    }
    _ = try! recorder.apply(
        .applyBirthSiteObservation(AgentBirthSiteObservation(
            planID: plan.planID, observedTick: session.tick,
            position: position, candidateIndex: candidateIndex,
            worldFingerprint: 16_000 + candidateIndex
        )), to: &session
    )
    return session.lifecycleSnapshot().births.last!
}

private func careAdvanceUntilFoodInteraction(
    _ recorder: inout AgentReplayRecorder,
    _ session: inout AgentSimulationSession,
    caregiverID: AgentID
) -> AgentSessionTickResult {
    for _ in 0..<16 {
        let caregiver = try! session.state(for: caregiverID)
        let perceptions: [AgentPerceptionInput]
        if let dependentID = session.careTarget(for: caregiverID),
           let dependent = try? session.state(for: dependentID) {
            perceptions = [careMovementPerception(
                agentID: caregiverID, position: caregiver.position,
                target: dependent.position, worldTick: session.tick + 1
            )]
        } else {
            perceptions = []
        }
        let result = careAdvance(&recorder, &session, perceptions: perceptions)
        if result.agents.first(where: {
            $0.agentId == caregiverID.rawValue
        })?.action.name == "provide_food" {
            return result
        }
        let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
        _ = try! recorder.apply(.movementOutcomes(outcomes), to: &session)
    }
    let state = session.snapshot()
    fatalError(
        "caregiver did not reach dependent through bounded movement caregiver=\(caregiverID.rawValue) "
            + "positions=\(state.agents.map { "\($0.id)@\($0.position.x),\($0.position.y),\($0.position.z):\($0.lastAction?.name ?? "none")" }) "
            + "engagements=\(session.dependentCareSnapshot().activeEngagements.map { "\($0.caregiverID.rawValue)>\($0.dependentID.rawValue):\($0.kind.rawValue)" })"
    )
}

private func careProvision(
    _ recorder: inout AgentReplayRecorder,
    _ session: inout AgentSimulationSession,
    caregiverID: AgentID
) -> AgentCareProvisionResult {
    guard let engagement = session.careEngagement(for: caregiverID) else {
        let snapshot = session.dependentCareSnapshot()
        fatalError(
            "care engagement missing caregiver=\(caregiverID.rawValue) "
                + "assignments=\(snapshot.assignments.map { "\($0.dependentID.rawValue)>\($0.caregiverID.rawValue):\($0.status.rawValue)" }) "
                + "needs=\(snapshot.activeNeeds.map { "\($0.dependentID.rawValue):\($0.kind.rawValue):\($0.status.rawValue)" }) "
                + "engagements=\(snapshot.activeEngagements.map { "\($0.caregiverID.rawValue):\($0.kind.rawValue)" })"
        )
    }
    let intent = AgentCareProvisionIntent(
        provisionID: "care-smoke:\(caregiverID.rawValue):\(engagement.dependentID.rawValue):\(session.tick)",
        needID: engagement.needID, caregiverID: caregiverID,
        dependentID: engagement.dependentID, tick: session.tick
    )
    var preview = session
    let result = try! preview.provideDependentNourishment(intent)
    _ = try! recorder.apply(.provideDependentNourishment(intent), to: &session)
    return result
}

private func careMutatedCheckpoint(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> AgentSessionCheckpoint {
    var root = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(checkpoint)
    ) as! [String: Any]
    var durable = root["durableState"] as! [String: Any]
    mutate(&durable)
    let mutationBytes = try! JSONSerialization.data(
        withJSONObject: durable, options: [.sortedKeys, .withoutEscapingSlashes]
    )
    let mutatedState = try! AgentCheckpointCodec.decode(
        AgentSessionDurableState.self, from: mutationBytes
    )
    let durableBytes = try! AgentCheckpointCodec.encode(mutatedState)
    let canonical = try! JSONSerialization.jsonObject(
        with: durableBytes
    ) as! [String: Any]
    let clock = canonical["clock"] as! [String: Any]
    let simulationID = clock["simulationID"] as! String
    let tick = clock["tick"] as! Int
    let digest = AgentCheckpointDigest.sha256(durableBytes)
    let simulationDigest = AgentCheckpointDigest.sha256(Data(simulationID.utf8))
    root["durableState"] = canonical
    root["schemaVersion"] = canonical["schemaVersion"]
    root["semanticDigest"] = digest.rawValue
    root["checkpointID"] = "checkpoint-\(simulationDigest.rawValue.prefix(12))-t\(tick)-\(digest.rawValue.prefix(16))"
    return try! AgentCheckpointCodec.decode(
        AgentSessionCheckpoint.self,
        from: JSONSerialization.data(
            withJSONObject: root, options: [.sortedKeys, .withoutEscapingSlashes]
        )
    )
}

private func careRestoreRefused(
    _ checkpoint: AgentSessionCheckpoint,
    mutate: (inout [String: Any]) -> Void
) -> Bool {
    do {
        _ = try AgentSimulationSession.restoring(
            careMutatedCheckpoint(checkpoint, mutate: mutate)
        )
        return false
    } catch {
        return true
    }
}

func runPebbleAgentsDependentCareSmoke() {
    section("pebble agents dependent care lifecycle")

    let live = AgentDependentCareConfiguration.live
    check("care live bounds", live.maximumDependents == 64
        && live.maximumAssignments == 256
        && live.maximumActiveNeeds == 128
        && live.maximumRetainedOutcomes == 512
        && live.maximumDependentsPerCaregiver == 4
        && live.maximumCareTransitionsPerTick == 32
        && live.careInteractionDistance == 1)
    check("care configuration Codable", (try? AgentCheckpointCodec.decode(
        AgentDependentCareConfiguration.self,
        from: AgentCheckpointCodec.encode(live)
    )) == live)
    check("care newborn capability matrix", AgentStageCapabilityPolicy.policy(for: .newborn)
        .allowed == [.perceive])
    check("care juvenile capability matrix", {
        let policy = AgentStageCapabilityPolicy.policy(for: .juvenile)
        return policy.permits(.perceive) && policy.permits(.returnHome)
            && policy.permits(.selfConsumeCarriedFood) && !policy.permits(.harvest)
            && !policy.permits(.build) && !policy.permits(.reproduce)
    }())
    check("care mature capability matrix", AgentStageCapability.allCases.allSatisfy {
        AgentStageCapabilityPolicy.policy(for: .mature).permits($0)
    })

    var missingLifecycle = careBase("sim-care-no-lifecycle", lifecycle: false)
    let missingLifecycleBytes = try! missingLifecycle.durableStateBytes()
    check("care activation without lifecycle atomic", {
        do { try missingLifecycle.setDependentCareEnabled(true); return false }
        catch AgentSessionError.dependentCare(.lifecycleRequired) {
            return (try! missingLifecycle.durableStateBytes()) == missingLifecycleBytes
        } catch { return false }
    }())
    var missingKinship = careBase("sim-care-no-kinship", kinship: false)
    check("care activation without kinship refused", {
        do { try missingKinship.setDependentCareEnabled(true); return false }
        catch AgentSessionError.dependentCare(.kinshipRequired) { return true }
        catch { return false }
    }())
    var missingHouseholds = careBase("sim-care-no-households", households: false)
    check("care activation without households refused", {
        do { try missingHouseholds.setDependentCareEnabled(true); return false }
        catch AgentSessionError.dependentCare(.householdsRequired) { return true }
        catch { return false }
    }())

    var session = careBase("sim-dependent-care-durable")
    try! session.setReproductionEnabled(true)
    let v8Checkpoint = try! session.makeCheckpoint()
    let v8Bytes = try! session.durableStateBytes()
    check("care gate off schema v8", v8Checkpoint.schemaVersion == 8)
    check("care gate off omits durable state", !String(data: v8Bytes, encoding: .utf8)!
        .contains("dependentCareState"))
    var recorder = try! AgentReplayRecorder(checkpoint: v8Checkpoint, session: session)
    let smokeCareConfiguration = try! AgentDependentCareConfiguration(
        nourishmentHungerThreshold: 0.05
    )
    _ = try! recorder.apply(
        .setDependentCareEnabled(true, configuration: smokeCareConfiguration),
        to: &session
    )
    check("care explicit activation promotes schema v9", try! session.makeCheckpoint()
        .schemaVersion == 9)
    check("care activation with mature founders has no invented assignment",
          session.dependentCareSnapshot().assignments.isEmpty)

    let patch = session.localEcologySnapshot().patches.first {
        $0.foragePosition == careHabitat.foragePosition
    }!
    let forageIntents = [0].map { ordinal in
        AgentForageIntent(
            forageID: "care-food-\(ordinal)", patchID: patch.patchID,
            agentID: AgentID(rawValue: "agent_\(ordinal)")!, tick: session.tick,
            target: patch.foragePosition, observedAtTick: session.tick,
            expectedHabitatFingerprint: patch.habitatFingerprint
        )
    }
    _ = try! recorder.apply(
        .applyForageOutcomes(
            intents: forageIntents,
            habitatValidations: [careHabitat]
        ), to: &session
    )
    check("care food harvested through ecology", session.snapshot().conservation.harvestedTotal == 1
        && session.snapshot().agents.first { $0.id == "agent_0" }?
            .resourceInventory.count(of: .foodRaw) == 1)

    let firstBirth = careBirth(
        &recorder, &session, position: AgentPosition(x: 0, y: 64, z: 2),
        candidateIndex: 0
    )
    let firstAssignment = try! session.currentCareAssignment(for: firstBirth.newbornID)
    let firstCaregiverID = firstAssignment!.caregiverID
    check("care birth assigns deterministic parent", firstAssignment?.caregiverID
        == AgentID(rawValue: "agent_0")!)
    check("care birth joins caregiver household", (try! session.currentMembership(
        of: firstBirth.newbornID
    ))?.householdID == firstAssignment?.householdID)
    let newbornBoundaryBytes = try! session.durableStateBytes()
    check("care newborn material actions are denied atomically", {
        var attempted = session
        do {
            try attempted.prevalidateInteraction(AgentInteractionIntent(
                interactionId: "care-newborn-harvest-denied",
                agentId: firstBirth.newbornID.rawValue, tick: attempted.tick,
                target: AgentPosition(x: 0, y: 64, z: 2), resource: .foodRaw
            ))
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .harvest
            )) else { return false }
        }
        do {
            _ = try attempted.deliverResources(AgentDeliveryIntent(
                deliveryId: "care-newborn-delivery-denied",
                agentId: firstBirth.newbornID.rawValue, tick: attempted.tick,
                position: (try! attempted.state(for: firstBirth.newbornID)).position
            ))
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .deliver
            )) else { return false }
        }
        do {
            _ = try attempted.fundConstructionProject(
                fundingId: "care-newborn-build-denied",
                builderAgentId: firstBirth.newbornID.rawValue,
                fundingTick: attempted.tick
            )
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .build
            )) else { return false }
        }
        do {
            _ = try attempted.consumeFood(AgentConsumptionIntent(
                consumptionId: "care-newborn-consumption-denied",
                agentId: firstBirth.newbornID.rawValue,
                tick: attempted.tick
            ))
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .selfConsumeCarriedFood
            )) else { return false }
        }
        return (try! attempted.durableStateBytes()) == newbornBoundaryBytes
    }())
    let newbornBefore = session.snapshot().agents.first { $0.id == firstBirth.newbornID.rawValue }!
    let tickResult = careAdvanceUntilFoodInteraction(
        &recorder, &session, caregiverID: firstCaregiverID
    )
    let newbornAfter = session.snapshot().agents.first { $0.id == firstBirth.newbornID.rawValue }!
    check("care newborn has no autonomous cognition action or movement",
          newbornAfter.goalSelectionCount == newbornBefore.goalSelectionCount
            && newbornAfter.actionCount == newbornBefore.actionCount
            && newbornAfter.movementCount == newbornBefore.movementCount
            && tickResult.agents.first {
                $0.agentId == firstBirth.newbornID.rawValue
            }?.cognitionPerformed == false)
    check("care caregiver activity overridden", tickResult.agents.contains {
        $0.agentId == firstCaregiverID.rawValue && $0.action.name == "provide_food"
    })
    check("care caregiver approached dependent through movement pipeline",
          session.snapshot().agents.first { $0.id == firstCaregiverID.rawValue }?
            .movementCount ?? 0 > 0)
    check("care provision too far is refused atomically", {
        var attempted = session
        let caregiver = try! attempted.state(for: firstCaregiverID)
        try! attempted.applyExternalUpdate(AgentExternalUpdate(
            agentId: firstCaregiverID.rawValue,
            position: AgentPosition(
                x: caregiver.position.x + 8,
                y: caregiver.position.y,
                z: caregiver.position.z
            )
        ))
        let before = try! attempted.durableStateBytes()
        let engagement = attempted.careEngagement(for: firstCaregiverID)!
        do {
            _ = try attempted.provideDependentNourishment(AgentCareProvisionIntent(
                provisionID: "care-too-far-denied", needID: engagement.needID,
                caregiverID: firstCaregiverID, dependentID: engagement.dependentID,
                tick: attempted.tick
            ))
            return false
        } catch {
            return error as? AgentSessionError == .dependentCare(.interactionTooFar)
                && (try! attempted.durableStateBytes()) == before
        }
    }())
    let inventoryProvision = careProvision(
        &recorder, &session, caregiverID: firstCaregiverID
    )
    check("care inventory food conservation", inventoryProvision.succeeded
        && inventoryProvision.foodSource == .caregiverInventory
        && inventoryProvision.foodBefore == inventoryProvision.foodAfter + 1
        && inventoryProvision.consumedByDependent == 1
        && inventoryProvision.hungerAfter < inventoryProvision.hungerBefore
        && session.conservationSnapshot().balanced)

    check("care missing food remains unmet without material creation", {
        var noFood = session
        var noFoodRecorder = try! AgentReplayRecorder(
            checkpoint: try! noFood.makeCheckpoint(), session: noFood
        )
        _ = careAdvanceUntilFoodInteraction(
            &noFoodRecorder, &noFood, caregiverID: firstCaregiverID
        )
        let before = noFood.conservationSnapshot()
        let hungerBefore = (try! noFood.state(for: firstBirth.newbornID)).needs.hunger
        let result = careProvision(
            &noFoodRecorder, &noFood, caregiverID: firstCaregiverID
        )
        let after = noFood.conservationSnapshot()
        return !result.succeeded && result.foodSource == .none
            && result.consumedByDependent == 0
            && result.hungerBefore == result.hungerAfter
            && (try! noFood.state(for: firstBirth.newbornID)).needs.hunger == hungerBefore
            && before == after
            && noFood.dependentCareSnapshot().activeNeeds.contains {
                $0.needID == result.needID && $0.status == .unmet
            }
    }())

    let secondFoodOutcome = AgentInteractionOutcome(
        interactionId: "care-food-agent-1", agentId: "agent_1",
        tick: session.tick, target: AgentPosition(x: -1, y: 64, z: 0),
        resource: .foodRaw, status: .succeeded,
        inventoryDelta: AgentInventoryDelta(resource: .foodRaw, quantity: 1),
        reason: "authoritative sandbox fixture harvested for care proof"
    )
    _ = try! recorder.apply(
        .interactionOutcome(secondFoodOutcome), to: &session
    )
    let deliveryIntent = AgentDeliveryIntent(
        deliveryId: "care-camp-food", agentId: "agent_1", tick: session.tick,
        position: AgentPosition(x: 0, y: 64, z: 0)
    )
    var deliveryPreview = session
    let delivery = try! deliveryPreview.deliverResources(deliveryIntent)
    _ = try! recorder.apply(.deliveryOutcome(delivery), to: &session)
    check("care camp food uses historical forage and delivery",
          session.snapshot().campStock.count(of: .foodRaw) == 1)

    let secondBirth = careBirth(
        &recorder, &session, position: AgentPosition(x: 4, y: 64, z: 0),
        candidateIndex: 1
    )
    let secondAssignment = try! session.currentCareAssignment(for: secondBirth.newbornID)
    let secondCaregiverID = secondAssignment!.caregiverID
    check("care load tie-break selects a canonical progenitor",
          secondBirth.progenitorIDs.contains(secondCaregiverID))
    _ = careAdvanceUntilFoodInteraction(
        &recorder, &session, caregiverID: secondCaregiverID
    )
    let campProvision = careProvision(
        &recorder, &session, caregiverID: secondCaregiverID
    )
    check("care campStock food conservation", campProvision.succeeded
        && campProvision.foodSource == .campStock
        && campProvision.foodBefore == campProvision.foodAfter + 1
        && campProvision.consumedByDependent == 1
        && session.conservationSnapshot().balanced)

    let assignmentCountBeforeMove = session.dependentCareSnapshot().assignments.count
    _ = try! recorder.apply(.formHousehold(
        memberIDs: [firstBirth.newbornID, AgentID(rawValue: "agent_2")!],
        residenceAnchor: AgentPosition(x: 5, y: 64, z: 0)
    ), to: &session)
    let nonParentAssignment = try! session.currentCareAssignment(for: firstBirth.newbornID)
    check("care household move reassigns to non-parent mature co-resident",
          nonParentAssignment?.caregiverID == AgentID(rawValue: "agent_2")!
            && !firstBirth.progenitorIDs.contains(nonParentAssignment!.caregiverID))
    check("care household move closes assignment history atomically",
          session.dependentCareSnapshot().assignments.count > assignmentCountBeforeMove
            && (try! session.currentMembership(of: firstBirth.newbornID))?.householdID
                == nonParentAssignment?.householdID)
    _ = try! recorder.apply(.formHousehold(
        memberIDs: [firstBirth.newbornID],
        residenceAnchor: AgentPosition(x: 9, y: 64, z: 0)
    ), to: &session)
    let crossHouseholdParent = try! session.currentCareAssignment(for: firstBirth.newbornID)
    check("care parent in another household moves dependent atomically",
          crossHouseholdParent.map { firstBirth.progenitorIDs.contains($0.caregiverID) } == true
            && (try! session.currentMembership(of: firstBirth.newbornID))?.householdID
                == crossHouseholdParent?.householdID
            && (try! session.state(for: firstBirth.newbornID)).homePosition
                == (try! session.household(for: crossHouseholdParent!.caregiverID))?
                    .residenceAnchor)

    for _ in 0..<40 where session.lifecycleSnapshot().members.first(where: {
        $0.agentID == firstBirth.newbornID
    })?.currentStage == .newborn {
        _ = careAdvance(&recorder, &session)
    }
    let juvenile = try! session.stageCapabilityPolicy(for: firstBirth.newbornID)
    check("care juvenile remains limited after real aging", juvenile.stage == .juvenile
        && juvenile.permits(.returnHome) && !juvenile.permits(.harvest)
        && !juvenile.permits(.build))
    let juvenileBoundaryBytes = try! session.durableStateBytes()
    check("care juvenile adult material actions are denied atomically", {
        var attempted = session
        do {
            try attempted.prevalidateInteraction(AgentInteractionIntent(
                interactionId: "care-juvenile-harvest-denied",
                agentId: firstBirth.newbornID.rawValue, tick: attempted.tick,
                target: AgentPosition(x: 0, y: 64, z: 2), resource: .foodRaw
            ))
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .harvest
            )) else { return false }
        }
        do {
            _ = try attempted.fundConstructionProject(
                fundingId: "care-juvenile-build-denied",
                builderAgentId: firstBirth.newbornID.rawValue,
                fundingTick: attempted.tick
            )
            return false
        } catch {
            guard error as? AgentSessionError == .dependentCare(.capabilityDenied(
                firstBirth.newbornID, .build
            )) else { return false }
        }
        return (try! attempted.durableStateBytes()) == juvenileBoundaryBytes
    }())

    let v9Checkpoint = try! session.makeCheckpoint()
    let v9Bytes = try! AgentCheckpointCodec.encode(v9Checkpoint)
    let restored = try! AgentSimulationSession.restoring(v9Checkpoint)
    check("care v9 restart exact", try! restored.durableStateBytes()
        == session.durableStateBytes())
    let journal = try! recorder.journal(
        named: AgentCheckpointName(rawValue: "dependent-care-smoke")!
    )
    let replayed = try! AgentSessionReplayer.replay(
        checkpoint: v8Checkpoint, journal: journal
    ).session
    check("care v9 replay exact", try! replayed.durableStateBytes()
        == session.durableStateBytes())
    check("care v9 checkpoint stable bytes", v9Bytes == (try! AgentCheckpointCodec.encode(
        try! session.makeCheckpoint()
    )))
    check("care restore rejects retained event with wrong semantic role", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var assignments = care["assignments"] as! [[String: Any]]
        assignments[0]["startedEventID"] = care["initializedEventID"]
        care["assignments"] = assignments
        durable["dependentCareState"] = care
    })
    check("care restore rejects foreign causal simulation", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var eventID = care["lastCareEventID"] as! [String: Any]
        eventID["simulationID"] = "sim-foreign-care"
        care["lastCareEventID"] = eventID
        durable["dependentCareState"] = care
    })
    check("care restore rejects semantically corrupt assignment", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var assignments = care["assignments"] as! [[String: Any]]
        assignments[0]["householdID"] = "household_999"
        care["assignments"] = assignments
        durable["dependentCareState"] = care
    })
    check("care restore rejects unknown caregiver assignment", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var assignments = care["assignments"] as! [[String: Any]]
        assignments[0]["caregiverID"] = "agent_999"
        care["assignments"] = assignments
        durable["dependentCareState"] = care
    })
    check("care restore rejects duplicate open assignment", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var assignments = care["assignments"] as! [[String: Any]]
        if let active = assignments.first(where: { $0["status"] as? String == "active" }) {
            assignments.append(active)
            assignments.sort {
                let lhsID = $0["dependentID"] as! String
                let rhsID = $1["dependentID"] as! String
                if lhsID != rhsID { return lhsID < rhsID }
                return ($0["startedTick"] as! Int) < ($1["startedTick"] as! Int)
            }
            care["assignments"] = assignments
            care["totalAssignmentCount"] = assignments.count
        }
        durable["dependentCareState"] = care
    })
    check("care restore rejects duplicate dependent need kind", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var needs = care["activeNeeds"] as! [[String: Any]]
        if var duplicate = needs.first {
            duplicate["needID"] = "care-need-99999999"
            needs.append(duplicate)
            needs.sort { ($0["needID"] as! String) < ($1["needID"] as! String) }
            care["activeNeeds"] = needs
            care["totalNeedCount"] = max(care["totalNeedCount"] as! Int, needs.count)
        }
        durable["dependentCareState"] = care
    })
    check("care restore rejects engagement without need", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var engagements = care["activeEngagements"] as! [[String: Any]]
        if !engagements.isEmpty {
            engagements[0]["needID"] = "care-need-99999999"
            care["activeEngagements"] = engagements
        }
        durable["dependentCareState"] = care
    })
    check("care restore rejects stale last care pointer", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        care["lastCareEventID"] = care["initializedEventID"]
        durable["dependentCareState"] = care
    })
    check("care restore rejects outcome without matching material chain", careRestoreRefused(
        v9Checkpoint
    ) { durable in
        var care = durable["dependentCareState"] as! [String: Any]
        var outcomes = care["terminalOutcomes"] as! [[String: Any]]
        let initialized = care["initializedEventID"] as! [String: Any]
        if let index = outcomes.firstIndex(where: { $0["kind"] as? String == "nourishment" }) {
            outcomes[index]["terminalEventID"] = initialized
        }
        care["terminalOutcomes"] = outcomes
        durable["dependentCareState"] = care
    })
    var evictedCare = careBase("sim-care-legitimate-eviction", causalMaximum: 8)
    try! evictedCare.setDependentCareEnabled(true)
    _ = try! evictedCare.advanceTick()
    _ = try! evictedCare.advanceTick()
    let evictedCheckpoint = try! evictedCare.makeCheckpoint()
    let evictedSummary = evictedCare.causalLedgerSnapshot().summary
    let evictedRoot = try! JSONSerialization.jsonObject(
        with: AgentCheckpointCodec.encode(evictedCheckpoint)
    ) as! [String: Any]
    let evictedDurable = evictedRoot["durableState"] as! [String: Any]
    let evictedCareJSON = evictedDurable["dependentCareState"] as! [String: Any]
    let evictedInitializedID = evictedCareJSON["initializedEventID"] as! [String: Any]
    let evictedInitializedSequence = (evictedInitializedID["sequence"] as! NSNumber)
        .uint64Value
    let evictedRestored = try! AgentSimulationSession.restoring(evictedCheckpoint)
    let evictedRestoredBytes = try! evictedRestored.durableStateBytes()
    let evictedDirectBytes = try! evictedCare.durableStateBytes()
    check("care restore accepts causally proven evicted prefix",
          evictedSummary.droppedEventCount > 0
            && evictedInitializedSequence <= evictedSummary.droppedEventCount
            && evictedCare.causalLedgerSnapshot().events.allSatisfy {
                $0.sequence.rawValue > evictedInitializedSequence
            }
            && evictedRestoredBytes == evictedDirectBytes)
    check("care causal chain retained", session.causalLedgerSnapshot().events.contains {
        $0.kind == .careNeedRaised
    } && session.causalLedgerSnapshot().events.contains {
        $0.kind == .careProvided
    } && session.causalLedgerSnapshot().events.contains {
        $0.kind == .careNeedResolved
    })

    var mortalitySession = careMortalityBase("sim-care-mortality-reassignment")
    let mortalityV9 = try! mortalitySession.makeCheckpoint()
    var mortalityRecorder = try! AgentReplayRecorder(
        checkpoint: mortalityV9, session: mortalitySession
    )
    let mortalityBirth = careBirth(
        &mortalityRecorder, &mortalitySession,
        position: AgentPosition(x: 0, y: 64, z: 1), candidateIndex: 0
    )
    let originalMortalityCaregiver = try! mortalitySession.currentCareAssignment(
        for: mortalityBirth.newbornID
    )!.caregiverID
    _ = try! mortalityRecorder.apply(
        .setMortalityEnabled(true, configuration: .live), to: &mortalitySession
    )
    for _ in 0..<24 where mortalitySession.snapshot().agents.contains(where: {
        $0.id == originalMortalityCaregiver.rawValue
    }) {
        _ = careAdvance(&mortalityRecorder, &mortalitySession)
    }
    let replacement = try! mortalitySession.currentCareAssignment(
        for: mortalityBirth.newbornID
    )
    check("caregiver real starvation death reassigns in mortality transaction",
          !mortalitySession.snapshot().agents.contains {
              $0.id == originalMortalityCaregiver.rawValue
          } && replacement != nil
            && replacement?.caregiverID != originalMortalityCaregiver)
    for _ in 0..<32 where try! mortalitySession.currentCareAssignment(
        for: mortalityBirth.newbornID
    ) != nil {
        _ = careAdvance(&mortalityRecorder, &mortalitySession)
    }
    check("dependent without surviving caregiver remains at-risk",
          mortalitySession.snapshot().agents.contains {
              $0.id == mortalityBirth.newbornID.rawValue
          } && (try! mortalitySession.currentCareAssignment(
              for: mortalityBirth.newbornID
          )) == nil
            && mortalitySession.dependentCareSnapshot().atRiskDependentIDs
                .contains(mortalityBirth.newbornID))
    check("caregiver deaths retain ended assignment history",
          mortalitySession.dependentCareSnapshot().assignments.filter {
              $0.dependentID == mortalityBirth.newbornID && $0.status == .ended
          }.count >= 2)
    for _ in 0..<32 where mortalitySession.snapshot().agents.contains(where: {
        $0.id == mortalityBirth.newbornID.rawValue
    }) {
        _ = careAdvance(&mortalityRecorder, &mortalitySession)
    }
    let postDependentDeath = mortalitySession.dependentCareSnapshot()
    check("dependent real starvation death closes care without reassignment",
          !mortalitySession.snapshot().agents.contains {
              $0.id == mortalityBirth.newbornID.rawValue
          }
            && postDependentDeath.assignments.filter {
                $0.dependentID == mortalityBirth.newbornID
            }.allSatisfy { $0.status == .ended }
            && !postDependentDeath.activeNeeds.contains {
                $0.dependentID == mortalityBirth.newbornID
            }
            && !postDependentDeath.activeEngagements.contains {
                $0.dependentID == mortalityBirth.newbornID
            })
}
