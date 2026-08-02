import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func advanceOneTick(world: World, player: Player) -> Bool {
        guard activeWorld === world, var session else { return false }
        let publishedRecorder = replayRecorder
        let skillLateFailureRunEnabled = environment[
            "PEBBLELAB_DISPOSABLE_SKILL_LATE_FAILURE_PROOF"
        ] == "1" && session.skillsEnabled && !skillLateFailureProofInjected
        let skillLateFailurePublishedBytes: Data?
        let skillLateFailurePublishedRecorderBytes: Data?
        do {
            skillLateFailurePublishedBytes = skillLateFailureRunEnabled
                ? try session.durableStateBytes() : nil
            skillLateFailurePublishedRecorderBytes = skillLateFailureRunEnabled
                ? try publishedRecorder.map { try AgentReplayCodec.encodeRecords($0.records) }
                : nil
        } catch {
            lastError = "skills late-failure boundary capture failed: \(error)"
            runtimeErrorCount += 1
            trace("error \(lastError!)")
            return false
        }
        let skillLateFailurePublishedProbeState = skillLateFailureRunEnabled
            ? probesByAgentId.values.map {
                "\($0.labAgentId):\($0.x):\($0.y):\($0.z)"
            }.sorted()
            : []
        let skillLateFailurePublishedWorldAgentIDs = skillLateFailureRunEnabled
            ? world.entities.compactMap { ($0 as? LabCoreAgentEntity)?.labAgentId }.sorted()
            : []
        let skillLateFailurePublishedWorldEntityCount = world.entities.count
        let kinshipLateFailureBoundary: PebbleKinshipLateFailureBoundarySnapshot?
        do {
            kinshipLateFailureBoundary = kinshipLateFailureProofEnabled
                ? try kinshipLateFailureBoundarySnapshot(
                    session: session, recorder: replayRecorder, world: world
                )
                : nil
        } catch {
            lastError = "kinship late-failure boundary capture failed: \(error)"
            runtimeErrorCount += 1
            trace("error \(lastError!)")
            return false
        }
        var recorder = replayRecorder
        var receiptTransaction =
            PebbleWorldEcologicalObservationReceiptTransaction()
        defer {
            if !receiptTransaction.committed {
                do {
                    try rollbackWorldEcologicalObservationReceipts(
                        receiptTransaction
                    )
                } catch {
                    lastError = "World-side receipt rollback failed: \(error)"
                    runtimeErrorCount += 1
                    trace("error \(lastError!)")
                }
            }
        }
        isAdvancingSession = true
        defer { isAdvancingSession = false }
        lastInteractionAttempted = false
        lastInteractionSucceeded = false
        lastInteractionBlocked = false
        lastDeliverySucceeded = false
        lastConsumptionSucceeded = false
        do {
            if session.mortalityEnabled,
               !session.pendingMortalityTransitions().isEmpty {
                let before = session.snapshot()
                try reconcileMortalityProbes(
                    previous: before,
                    current: &session,
                    recorder: &recorder,
                    world: world
                )
                if session.ecologicalObservationEnabled {
                    try reconcileWorldEcologicalObservationReceiptRetention(
                        for: session,
                        transaction: &receiptTransaction
                    )
                    try reconcileWorldAgriculturalActionReceiptRetention(
                        for: session,
                        transaction: &receiptTransaction
                    )
                    try validateWorldEcologicalObservationReceipts(
                        for: session,
                        dimension: world.dim.rawValue
                    )
                }
                self.session = session
                replayRecorder = recorder
                receiptTransaction.commit()
                return true
            }
            if session.livestockEnabled,
               !session.livestockSnapshot().managedAnimals.isEmpty {
                try reconcileLiveLivestock(
                    world: world, session: &session, recorder: &recorder
                )
            }
            try prepareAutonomousCivilizationDecision(
                world: world, session: &session, recorder: &recorder
            )
            let preCognitive = session.snapshot()
            let ecologyValidations: [AgentEcologyHabitatObservation]
            if session.localEcologyEnabled,
               let settlement = session.populationSnapshot().settlement {
                let validation = localEcologyAdapter.validate(
                    world: world,
                    settlement: settlement,
                    patches: session.localEcologySnapshot().patches
                )
                ecologyValidations = validation.observations
                lastEcologyScanDiagnostics = validation.diagnostics
            } else {
                ecologyValidations = []
            }
            let physicalInputs = physicalObservations(
                world: world,
                snapshot: preCognitive,
                session: session
            )
            let perceptions = try preCognitive.agents.map { agent in
                var combinedResourceObservations: [AgentResourceObservation] = []
                let socialObservations = try socialResourceObservations(
                    world: world,
                    agent: agent,
                    snapshot: preCognitive,
                    player: player
                )
                if autoInteractionEnabled || economyAutoEnabled
                    || (preCognitive.survivalEnabled && interactionFeatureEnabled) {
                    guard let anchor else { throw ControllerError.missingSession }
                    combinedResourceObservations += try interactionExecutor.resourceObservations(
                        world: world,
                        agent: agent,
                        anchor: anchor,
                        maximumDistance: session.configuration.resourceObservationRadius
                    )
                }
                let cooperationActors = Set(session.cooperationSnapshot().tasks
                    .filter { $0.status == .accepted || $0.status == .active }
                    .flatMap { [$0.issuerID.rawValue, $0.helperID.rawValue] })
                if preCognitive.naturalResourcesEnabled,
                   economyAutoEnabled,
                   (agent.id == focusedAgentId
                    || (session.cooperationEnabled && cooperationActors.contains(agent.id))) {
                    let occupied = preCognitive.agents
                        .filter { $0.id != agent.id }
                        .map(\.position)
                    let playerPosition = AgentPosition(
                        x: Int(player.x.rounded(.down)),
                        y: Int(player.y.rounded(.down)),
                        z: Int(player.z.rounded(.down))
                    )
                    let naturalScan = try naturalResourceAdapter.scan(
                        world: world,
                        agent: agent,
                        occupiedAgentPositions: occupied,
                        playerPosition: playerPosition,
                        priorityTarget: session.cooperationEnabled
                            ? agent.activeResourceTarget?.target
                            : nil
                    )
                    naturalResourceExecutor.recordScan(naturalScan)
                    combinedResourceObservations += naturalScan.observations
                }
                if session.localEcologyEnabled, let agentID = AgentID(rawValue: agent.id) {
                    combinedResourceObservations += try session.localEcologyResourceObservations(
                        for: agentID,
                        habitatValidations: ecologyValidations
                    )
                }
                var seenResourcePositions = Set<AgentPosition>()
                let resourceObservations = Array(combinedResourceObservations
                    .sorted(by: AgentResourcePerception.sortsBefore)
                    .filter { seenResourcePositions.insert($0.target).inserted }
                    .prefix(AgentResourcePerception.maximumObservationCount))
                let navigationObservation: AgentNavigationObservation?
                var preparedNavigationObservation: AgentNavigationObservation?
                var navigationTarget: AgentPosition?
                let navigationGoalMode: AgentNavigationGoalMode
                if agent.currentGoal.kind == .civilizationActivity,
                   let actorID = AgentID(rawValue: agent.id),
                   let activity = session.activeAutonomousActivity(for: actorID),
                   let target = activity.candidate.target {
                    if agent.navigationProgress.status == .active,
                       agent.navigationProgress.route?.purpose == .civilizationActivity,
                       let routeTarget = agent.navigationProgress.route?.target {
                        navigationTarget = routeTarget
                    } else if AgentBoundedTravel.requiresWaypoint(
                        from: agent.position, to: target
                    ) {
                        preparedNavigationObservation = navigationAdapter.observeBoundedTravel(
                            world: world,
                            agent: agent,
                            destination: target,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position)
                        )
                    }
                    if navigationTarget == nil {
                        navigationTarget = preparedNavigationObservation?.target ?? target
                    }
                    navigationGoalMode = navigationTarget == target
                        ? .cardinalAdjacent : .exact
                } else if agent.currentGoal.kind == .provideDependentCare,
                   let caregiverID = AgentID(rawValue: agent.id),
                   let dependentID = session.careTarget(for: caregiverID),
                   let dependent = preCognitive.agents.first(where: {
                       $0.id == dependentID.rawValue
                   }) {
                    if agent.navigationProgress.status == .active,
                       agent.navigationProgress.route?.purpose == .dependentCare,
                       let routeTarget = agent.navigationProgress.route?.target {
                        navigationTarget = routeTarget
                    } else if AgentBoundedTravel.requiresWaypoint(
                        from: agent.position, to: dependent.position
                    ) {
                        preparedNavigationObservation = navigationAdapter.observeBoundedTravel(
                            world: world,
                            agent: agent,
                            destination: dependent.position,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id && $0.id != dependentID.rawValue }
                                .map(\.position)
                        )
                    }
                    if navigationTarget == nil {
                        navigationTarget = preparedNavigationObservation?.target
                            ?? dependent.position
                    }
                    navigationGoalMode = navigationTarget == dependent.position
                        ? .cardinalAdjacent : .exact
                } else if agent.currentGoal.kind == .dependentReturnHome {
                    if agent.navigationProgress.status == .active,
                       agent.navigationProgress.route?.purpose == .dependentReturnHome,
                       let routeTarget = agent.navigationProgress.route?.target {
                        navigationTarget = routeTarget
                    } else if AgentBoundedTravel.requiresWaypoint(
                        from: agent.position, to: agent.homePosition
                    ) {
                        preparedNavigationObservation = navigationAdapter.observeBoundedTravel(
                            world: world,
                            agent: agent,
                            destination: agent.homePosition,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position)
                        )
                    }
                    if navigationTarget == nil {
                        navigationTarget = preparedNavigationObservation?.target
                            ?? agent.homePosition
                    }
                    navigationGoalMode = .exact
                } else if agent.currentGoal.kind == .migrateToSettlement,
                   let routeTarget = agent.navigationProgress.route?.target {
                    navigationTarget = routeTarget
                    navigationGoalMode = .exact
                } else if agent.currentGoal.kind == .buildShelter,
                   let project = preCognitive.constructionProject,
                   project.builderAgentId == agent.id,
                   project.status == .funded || project.status == .building,
                   let work = project.nextWorkPosition {
                    navigationTarget = work
                    navigationGoalMode = .exact
                } else if agent.currentGoal.kind == .buildShelter,
                          preCognitive.constructionProject?.status == .readyToFund,
                          agent.position != agent.homePosition {
                    if agent.navigationProgress.status == .active,
                       agent.navigationProgress.route?.purpose == .homeDelivery,
                       let routeTarget = agent.navigationProgress.route?.target {
                        navigationTarget = routeTarget
                    } else if AgentBoundedTravel.requiresWaypoint(
                        from: agent.position,
                        to: agent.homePosition
                    ) {
                        preparedNavigationObservation = navigationAdapter.observeBoundedTravel(
                            world: world,
                            agent: agent,
                            destination: agent.homePosition,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position)
                        )
                    }
                    if navigationTarget == nil {
                        navigationTarget = preparedNavigationObservation?.target ?? agent.homePosition
                    }
                    navigationGoalMode = .exact
                } else if (agent.currentGoal.kind == .deliverResources && !agent.resourceInventory.isEmpty)
                    || (preCognitive.survivalEnabled && agent.currentGoal.kind == .rest) {
                    let expectedPurpose: AgentNavigationPurpose = agent.currentGoal.kind == .rest
                        ? .homeRest
                        : .homeDelivery
                    if agent.navigationProgress.status == .active,
                       agent.navigationProgress.route?.purpose == expectedPurpose,
                       let routeTarget = agent.navigationProgress.route?.target {
                        navigationTarget = routeTarget
                    } else if AgentBoundedTravel.requiresWaypoint(
                        from: agent.position,
                        to: agent.homePosition
                    ) {
                        preparedNavigationObservation = navigationAdapter.observeBoundedTravel(
                            world: world,
                            agent: agent,
                            destination: agent.homePosition,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position)
                        )
                    }
                    if navigationTarget == nil {
                        navigationTarget = preparedNavigationObservation?.target ?? agent.homePosition
                    }
                    navigationGoalMode = .exact
                } else if let horizontalSurvey = session.constructionMaterialSurveyTarget(
                    for: agent.id,
                    observations: resourceObservations,
                    atTick: preCognitive.tick + 1
                ) {
                    preparedNavigationObservation = navigationAdapter.observeSurvey(
                        world: world,
                        agent: agent,
                        desiredTarget: horizontalSurvey,
                        occupiedAgentPositions: preCognitive.agents
                            .filter { $0.id != agent.id }
                            .map(\.position)
                    )
                    navigationTarget = preparedNavigationObservation?.target
                    navigationGoalMode = .exact
                } else {
                    let socialRequest = session.socialEnabled
                        ? session.pendingSocialVerificationRequest(for: agent.id)
                        : nil
                    if agent.activeResourceTarget == nil,
                       resourceObservations.isEmpty,
                       let socialRequest {
                        preparedNavigationObservation = socialNavigationObservation(
                            world: world,
                            agent: agent,
                            request: socialRequest,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position)
                        )
                        navigationTarget = preparedNavigationObservation?.target
                            ?? socialRequest.position
                        navigationGoalMode = navigationTarget == socialRequest.position
                            ? .cardinalAdjacent
                            : .exact
                    } else {
                        navigationTarget = agent.activeResourceTarget?.target
                            ?? resourceObservations.first?.target
                        navigationGoalMode = .cardinalAdjacent
                    }
                }
                if movementEnabled, let target = navigationTarget {
                    navigationObservation = preparedNavigationObservation
                        ?? navigationAdapter.observe(
                            world: world,
                            agent: agent,
                            target: target,
                            occupiedAgentPositions: preCognitive.agents
                                .filter { $0.id != agent.id }
                                .map(\.position),
                            goalMode: navigationGoalMode
                        )
                } else {
                    navigationObservation = nil
                }
                return AgentPerceptionInput(
                    agentId: agent.id,
                    worldObservation: try worldSensor.observe(world: world, agent: agent),
                    resourceObservations: resourceObservations,
                    socialResourceObservations: socialObservations,
                    navigationObservation: navigationObservation
                )
            }
            let result: AgentSessionTickResult
            if let recorded = try applyRecordedOperationIfActive(
                .advanceTick(
                    perceptions: perceptions,
                    physicalObservations: physicalInputs
                ),
                session: &session,
                recorder: &recorder
            ) {
                guard let tickResult = recorded.tickResult else {
                    throw ControllerError.feedbackBoundary("recorded tick result missing")
                }
                result = tickResult
            } else {
                result = try session.advanceTick(
                    perceptions: perceptions,
                    physicalObservations: physicalInputs
                )
            }
            try presentPhysicalSignals(
                world: world,
                session: &session,
                recorder: &recorder
            )
            let verificationActions = result.agents
                .filter { $0.action.name == "verify_information" }
                .sorted { $0.agentId < $1.agentId }
            for verification in verificationActions {
                guard let request = session.socialVerificationRequest(for: verification.agentId),
                      request.position == verification.action.target else {
                    throw ControllerError.socialBoundary(
                        "verification action outside active social request"
                    )
                }
                let observation = naturalResourceAdapter.observeSocialVerification(
                    world: world,
                    request: request
                )
                let outcome: AgentSocialVerificationResult
                if let recorded = try applyRecordedOperationIfActive(
                    .applySocialVerification(observation),
                    session: &session,
                    recorder: &recorder
                ) {
                    guard let verification = recorded.socialVerificationResult else {
                        throw ControllerError.socialBoundary(
                            "recorded social verification result missing"
                        )
                    }
                    outcome = verification
                } else {
                    outcome = try session.applySocialVerification(observation)
                }
                let fingerprintAfter = observation.chunkReady
                    ? world.getBlock(request.position.x, request.position.y, request.position.z)
                    : nil
                let belief = session.socialSnapshot().beliefs.first {
                    $0.beliefID == request.beliefID
                }
                trace("social verification tick=\(session.tick) verifier=\(request.verifierID.rawValue) sender=\(request.senderID.rawValue) belief=\(request.beliefID.rawValue) position=\(positionText(request.position)) expected=\(request.expectedBlockFingerprint) observed=\(observation.observedBlockFingerprint.map(String.init) ?? "none") after=\(fingerprintAfter.map(String.init) ?? "none") resourceUnchanged=\(fingerprintAfter == observation.observedBlockFingerprint ? 1 : 0) chunkReady=\(observation.chunkReady ? 1 : 0) result=\(outcome.rawValue) event=\(belief?.verificationEventID?.rawValue ?? "none") mutation=none")
            }
            let consumptionActions = result.agents
                .filter { $0.action.name == "consume_food" }
                .sorted { $0.agentId < $1.agentId }
            for consumption in consumptionActions {
                let intent = AgentConsumptionIntent(
                    consumptionId: "survival-consumption:\(consumption.agentId):\(session.tick)",
                    agentId: consumption.agentId,
                    tick: session.tick
                )
                let outcome: AgentConsumptionOutcome
                if recorder != nil {
                    var outcomeCandidate = session
                    outcome = try outcomeCandidate.consumeFood(intent)
                    _ = try applyRecordedOperationIfActive(
                        .consumptionOutcome(outcome),
                        session: &session,
                        recorder: &recorder
                    )
                } else {
                    outcome = try session.consumeFood(intent)
                }
                lastConsumptionSucceeded = outcome.status == .succeeded
                lastSurvivalReason = outcome.reason
            }
            let physicalFoodActions = result.agents
                .filter { $0.action.name == "consume_physical_food" }
                .sorted { $0.agentId < $1.agentId }
            for consumption in physicalFoodActions {
                guard let actorID = AgentID(rawValue: consumption.agentId),
                      let probe = probesByAgentId[consumption.agentId] else {
                    throw ControllerError.physicalFoodBoundary(
                        "physical food action has no exact embodiment"
                    )
                }
                let intent = try session.nextPhysicalFoodConsumptionIntent(for: actorID)
                let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(probe, in: world)
                guard let plan = try foodConsumptionExecutor.prepare(
                    intent,
                    session: session,
                    source: source,
                    gateway: materialCustodyGateway
                ) else {
                    lastConsumptionSucceeded = false
                    lastSurvivalReason = "no eligible carried physical food"
                    continue
                }
                var recorderCandidate = recorder
                let physicalResult = foodConsumptionExecutor.execute(
                    plan,
                    session: &session,
                    source: source,
                    gateway: materialCustodyGateway,
                    publish: { outcome, candidate in
                        if var activeRecorder = recorderCandidate {
                            _ = try activeRecorder.apply(
                                .validatedPhysicalFoodConsumption(outcome),
                                to: &candidate
                            )
                            recorderCandidate = activeRecorder
                        } else {
                            try candidate.applyValidatedPhysicalFoodConsumption(outcome)
                        }
                    }
                )
                if physicalResult.succeeded { recorder = recorderCandidate }
                lastConsumptionSucceeded = physicalResult.succeeded
                lastSurvivalReason = physicalResult.succeeded
                    ? "validated physical \(plan.validatedOutcome.canonicalMaterialName) consumed"
                    : "physical food \(physicalResult.status.rawValue)"
                if let outcome = physicalResult.outcome {
                    recordPassiveSocietyCompletion(
                        actorID: outcome.agentID,
                        family: "physicalSurvival",
                        action: "eat:\(outcome.canonicalMaterialName)",
                        receipt: outcome.physicalReceiptID,
                        session: session
                    )
                    trace(
                        "physical food consumption actor=\(outcome.agentID.rawValue) "
                            + "material=\(outcome.canonicalMaterialName) slot=\(outcome.sourceSlot) "
                            + "quantity=\(outcome.quantityConsumed) coreHunger=\(outcome.coreHungerPoints) "
                            + "saturation=\(outcome.coreSaturation) hunger=\(outcome.hungerBefore)>\(outcome.hungerAfter) "
                            + "receipt=\(outcome.physicalReceiptID) physicalDebit=exact abstractDelta=0"
                    )
                }
            }
            let autonomousActions = result.agents.filter {
                $0.action.name == "execute_autonomous_activity"
            }.sorted { $0.agentId < $1.agentId }
            for action in autonomousActions {
                try executeAutonomousCivilizationActivity(
                    actorIDText: action.agentId,
                    world: world,
                    session: &session,
                    recorder: &recorder
                )
            }
            let forageActions = result.agents
                .filter { $0.action.name == "forage_food" }
                .sorted { $0.agentId < $1.agentId }
            if !forageActions.isEmpty {
                guard session.localEcologyEnabled else {
                    throw ControllerError.ecologyBoundary("forage action while ecology disabled")
                }
                let snapshot = session.snapshot()
                let intents = try forageActions.map { action -> AgentForageIntent in
                    guard let actor = snapshot.agents.first(where: { $0.id == action.agentId }),
                          let target = actor.activeResourceTarget,
                          target.source == .localEcology,
                          let patchID = target.ecologyPatchID,
                          let fingerprint = target.expectedBlockFingerprint,
                          let observedAt = target.observationTick,
                          action.action.target == target.target else {
                        throw ControllerError.ecologyBoundary("forage action target mismatch")
                    }
                    return AgentForageIntent(
                        forageID: "ecology-forage:\(action.agentId):\(session.tick):\(patchID.rawValue)",
                        patchID: patchID,
                        agentID: AgentID(rawValue: action.agentId)!,
                        tick: session.tick,
                        target: target.target,
                        observedAtTick: observedAt,
                        expectedHabitatFingerprint: fingerprint
                    )
                }
                let outcomes: [AgentForageOutcome]
                if recorder != nil {
                    _ = try applyRecordedOperationIfActive(
                        .applyForageOutcomes(
                            intents: intents,
                            habitatValidations: ecologyValidations
                        ),
                        session: &session,
                        recorder: &recorder
                    )
                    let ids = Set(intents.map(\.forageID))
                    outcomes = session.localEcologySnapshot().forageHistory.filter {
                        ids.contains($0.forageID)
                    }
                } else {
                    outcomes = try session.applyForageIntents(
                        intents,
                        habitatValidations: ecologyValidations
                    )
                }
                lastForageOutcome = outcomes.last
                lastInteractionAttempted = true
                lastInteractionSucceeded = outcomes.contains { $0.status == .succeeded }
                lastInteractionBlocked = outcomes.contains { $0.status != .succeeded }
                for outcome in outcomes {
                    trace("ecology forage tick=\(session.tick) operation=\(outcome.forageID) patch=\(outcome.patchID.rawValue) actor=\(outcome.agentID.rawValue) status=\(outcome.status.rawValue) yield=\(outcome.yieldBefore)->\(outcome.yieldAfter) inventory=\(outcome.inventoryBefore)->\(outcome.inventoryAfter) mutation=none")
                }
            }
            let interactionActions = result.agents
                .filter { $0.action.name == "harvest_block" }
                .sorted { $0.agentId < $1.agentId }
            let interactionsToApply = session.cooperationEnabled
                ? interactionActions
                : Array(interactionActions.prefix(1))
            for interaction in interactionsToApply {
                guard autoInteractionEnabled || economyAutoEnabled
                        || (session.survivalEnabled && interactionFeatureEnabled) else {
                    throw ControllerError.interactionBoundary("harvest action without automatic interaction")
                }
                lastInteractionAttempted = true
                let outcome = try performHarvestTransaction(
                    world: world,
                    player: player,
                    actorId: interaction.agentId,
                    expectedAction: interaction.action,
                    interactionPrefix: "g2",
                    session: &session,
                    recorder: &recorder
                )
                if session.cooperationEnabled {
                    trace("cooperation harvest tick=\(session.tick) operation=\(outcome.interactionId) actor=\(outcome.agentId) target=\(positionText(outcome.target)) resource=\(outcome.resource.rawValue) status=\(outcome.status.rawValue)")
                }
                lastInteractionSucceeded = true
                lastAutoInteractionReason = "automatic harvest succeeded"
            }
            let deliveryActions = result.agents
                .filter { $0.action.name == "deliver_resource" }
                .sorted { $0.agentId < $1.agentId }
            let deliveriesToApply = session.cooperationEnabled
                ? deliveryActions
                : Array(deliveryActions.prefix(1))
            for delivery in deliveriesToApply {
                guard economyAutoEnabled else {
                    throw ControllerError.interactionBoundary("delivery action without automatic economy")
                }
                let actor = session.snapshot().agents.first { $0.id == delivery.agentId }!
                let deliveryId = "economy-delivery:\(delivery.agentId):\(session.tick)"
                let intent = AgentDeliveryIntent(
                    deliveryId: deliveryId,
                    agentId: delivery.agentId,
                    tick: session.tick,
                    position: actor.position
                )
                let outcome: AgentDeliveryOutcome
                if recorder != nil {
                    var outcomeCandidate = session
                    outcome = try outcomeCandidate.deliverResources(intent)
                    _ = try applyRecordedOperationIfActive(
                        .deliveryOutcome(outcome),
                        session: &session,
                        recorder: &recorder
                    )
                } else {
                    outcome = try session.deliverResources(intent)
                }
                lastDeliverySucceeded = outcome.status == .succeeded
                lastEconomyReason = outcome.reason
                if session.cooperationEnabled {
                    let transferred = outcome.transferred.map {
                        "\($0.resource.rawValue):\($0.quantity)"
                    }.joined(separator: ",")
                    trace("cooperation delivery tick=\(session.tick) operation=\(deliveryId) actor=\(delivery.agentId) transferred=\(transferred) status=\(outcome.status.rawValue)")
                }
            }
            let fundingActions = result.agents
                .filter { $0.action.name == "fund_construction" }
                .sorted { $0.agentId < $1.agentId }
            if let funding = fundingActions.first {
                guard buildFeatureEnabled, session.buildAutoEnabled else {
                    throw ControllerError.constructionBoundary(
                        "funding action without enabled construction gate and auto mode"
                    )
                }
                let fundingID = "construction-funding:\(funding.agentId):\(session.tick)"
                let funded: AgentConstructionProject
                if try applyRecordedOperationIfActive(
                    .fundConstructionProject(
                        fundingID: fundingID,
                        builderAgentID: funding.agentId,
                        tick: session.tick
                    ),
                    session: &session,
                    recorder: &recorder
                ) != nil {
                    guard let project = session.constructionProject else {
                        throw ControllerError.constructionBoundary(
                            "recorded funding project missing"
                        )
                    }
                    funded = project
                } else {
                    funded = try session.fundConstructionProject(
                        fundingId: fundingID,
                        builderAgentId: funding.agentId,
                        fundingTick: session.tick
                    )
                }
                lastConstructionReason = "funded \(funded.projectId)"
                if session.cooperationEnabled,
                   let event = session.causalLedgerSnapshot().events.last(where: {
                       $0.kind == .constructionFunding
                   }) {
                    trace("cooperation funding tick=\(session.tick) operation=construction-funding:\(funding.agentId):\(session.tick) event=\(event.eventID.rawValue) actor=\(funding.agentId) project=\(funded.projectId) status=\(funded.status.rawValue)")
                }
            }
            let placementActions = result.agents
                .filter { $0.action.name == "place_block" }
                .sorted { $0.agentId < $1.agentId }
            if let placement = placementActions.first {
                guard buildFeatureEnabled, session.buildAutoEnabled,
                      let project = session.constructionProject,
                      project.builderAgentId == placement.agentId,
                      let cell = project.nextCell,
                      let target = project.nextTarget,
                      let workPosition = project.nextWorkPosition,
                      placement.action.target == target,
                      placement.action.resource == cell.resource,
                      let actor = session.snapshot().agents.first(where: {
                          $0.id == placement.agentId
                      }),
                      let physicalActor = probesByAgentId[placement.agentId] else {
                    throw ControllerError.constructionBoundary(
                        "placement action outside active ordered project"
                    )
                }
                let intent = AgentPlacementIntent(
                    placementId: "construction-placement:\(placement.agentId):\(session.tick):\(cell.index)",
                    projectId: project.projectId,
                    builderAgentId: placement.agentId,
                    tick: session.tick,
                    cellIndex: cell.index,
                    target: target,
                    workPosition: workPosition,
                    resource: cell.resource
                )
                let outcome = AgentPlacementOutcome(
                    placementId: intent.placementId,
                    projectId: project.projectId,
                    builderAgentId: placement.agentId,
                    tick: session.tick,
                    cellIndex: cell.index,
                    target: target,
                    resource: cell.resource,
                    status: .succeeded,
                    reason: "verified PebbleCore placement with real builder custody"
                )
                var candidate = session
                var candidateRecorder = recorder
                let occupied = session.snapshot().agents
                    .filter { $0.id != placement.agentId }
                    .map(\.position)
                let playerPosition = AgentPosition(
                    x: Int(player.x.rounded(.down)),
                    y: Int(player.y.rounded(.down)),
                    z: Int(player.z.rounded(.down))
                )
                let navigationAdapter = self.navigationAdapter
                let standardPublicationFailure = environment[
                    "PEBBLELAB_APP_AGENTS_BUILD_FAIL_AFTER_WORLD"
                ] == "1"
                let skillLateFailureProof = environment[
                    "PEBBLELAB_DISPOSABLE_SKILL_LATE_FAILURE_PROOF"
                ] == "1" && session.skillsEnabled && !skillLateFailureProofInjected
                let injectPublicationFailure = standardPublicationFailure
                    || skillLateFailureProof
                let skillLateFailureBytes = skillLateFailureProof
                    ? try session.durableStateBytes() : Data()
                let skillLateFailureSnapshot = session.skillSnapshot()
                let skillLateFailureCausal = session.causalLedgerSnapshot()
                let skillLateFailureRecorderBytes = try recorder.map {
                    try AgentReplayCodec.encodeRecords($0.records)
                }
                let skillLateFailureProbeIDs = probesByAgentId.keys.sorted()
                let skillLateFailureWorldAgentIDs = world.entities.compactMap {
                    ($0 as? LabCoreAgentEntity)?.labAgentId
                }.sorted()
                let skillLateFailureBlock = world.getBlock(
                    target.x, target.y, target.z
                )
                var skillLateFailureCandidateValid = false
                do {
                    try constructionExecutor.place(
                    world: world,
                    actor: actor,
                    physicalActor: physicalActor,
                    project: project,
                    intent: intent,
                    occupiedAgentPositions: occupied,
                    playerPosition: playerPosition,
                    buildGateEnabled: buildFeatureEnabled,
                    buildAutoEnabled: session.buildAutoEnabled,
                    materialGateway: materialCustodyGateway,
                    physicalGateway: physicalActionGateway,
                    prevalidate: {
                        try session.prevalidatePlacement(intent)
                    },
                    publishAndVerify: { finalCell, actualFingerprint in
                        guard let requiredFingerprint = PebbleAgentConstructionMapping.fingerprint(
                            for: cell.resource
                        ), actualFingerprint >> 4 == requiredFingerprint >> 4 else {
                            throw ControllerError.constructionBoundary(
                                "physical placement does not match blueprint material"
                            )
                        }
                        if try applyRecordedOperationIfActive(
                            .applyPlacementOutcome(outcome),
                            session: &candidate,
                            recorder: &candidateRecorder
                        ) == nil {
                            try candidate.applyPlacementOutcome(outcome)
                        }
                        if skillLateFailureProof {
                            let candidateSkill = candidate.skillSnapshot()
                            guard candidateSkill.totalPracticeCreditCount
                                    == skillLateFailureSnapshot.totalPracticeCreditCount + 1,
                                  candidateSkill.totalPracticeUnits
                                    == skillLateFailureSnapshot.totalPracticeUnits + 1,
                                  candidate.practiceUnits(
                                    agentID: AgentID(rawValue: actor.id)!,
                                    domain: .construction
                                  ) == session.practiceUnits(
                                    agentID: AgentID(rawValue: actor.id)!,
                                    domain: .construction
                                  ) + 1 else {
                                throw ControllerError.constructionBoundary(
                                    "skill late-failure candidate missing practice credit"
                                )
                            }
                            skillLateFailureCandidateValid = true
                            trace(
                                "skills late-failure candidate valid=1 tick=\(candidate.tick) "
                                    + "actor=\(actor.id) domain=construction "
                                    + "credits=\(candidateSkill.totalPracticeCreditCount) "
                                    + "units=\(candidateSkill.totalPracticeUnits) "
                                    + "records=\(candidateSkill.retainedPracticeRecords.count) "
                                    + "causalSequence=\(candidate.causalLedgerSnapshot().summary.latestSequence) "
                                    + "worldPlaced=1 published=0"
                            )
                        }
                        if injectPublicationFailure {
                            throw ControllerError.constructionBoundary(
                                "injected construction publication failure"
                            )
                        }
                        if finalCell {
                            guard let pending = candidate.constructionProject,
                                  let builder = candidate.snapshot().agents.first(where: {
                                      $0.id == placement.agentId
                                  }) else {
                                throw ControllerError.constructionBoundary(
                                    "completion candidate unavailable"
                                )
                            }
                            let observation = navigationAdapter.observe(
                                world: world,
                                agent: builder,
                                target: pending.restPosition,
                                occupiedAgentPositions: occupied + [playerPosition],
                                goalMode: .exact
                            )
                            let entrance = AgentPosition(
                                x: pending.origin.x + pending.blueprint.entranceOffset.x,
                                y: pending.origin.y + pending.blueprint.entranceOffset.y,
                                z: pending.origin.z + pending.blueprint.entranceOffset.z
                            )
                            let entranceRoute = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                                start: builder.position,
                                target: entrance,
                                goalMode: .exact,
                                cells: observation.cells,
                                radius: observation.radius,
                                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                            ))
                            let restRoute = AgentBoundedRoutePlanner.plan(AgentNavigationRequest(
                                start: entrance,
                                target: pending.restPosition,
                                goalMode: .exact,
                                cells: observation.cells,
                                radius: observation.radius,
                                maxVisitedNodes: AgentBoundedRoutePlanner.maximumVisitedNodes,
                                maxSteps: AgentBoundedRoutePlanner.maximumRouteSteps
                            ))
                            guard entranceRoute.found, restRoute.found else {
                                throw ControllerError.constructionBoundary(
                                    "completed shelter entrance or rest cell is not safely routable"
                                )
                            }
                            if try applyRecordedOperationIfActive(
                                .completeConstructionProject(
                                    projectID: pending.projectId,
                                    tick: candidate.tick
                                ),
                                session: &candidate,
                                recorder: &candidateRecorder
                            ) == nil {
                                try candidate.completeConstructionProject(
                                    projectId: pending.projectId,
                                    completionTick: candidate.tick
                                )
                            }
                        }
                        guard candidate.conservationSnapshot().balanced,
                              candidate.constructionProject?.placedCellIndices.contains(cell.index) == true else {
                            throw ControllerError.constructionBoundary(
                                "construction publication verification failed"
                            )
                        }
                    }
                    )
                } catch {
                    if skillLateFailureProof {
                        let afterRecorderBytes = try recorder.map {
                            try AgentReplayCodec.encodeRecords($0.records)
                        }
                        let afterWorldAgentIDs = world.entities.compactMap {
                            ($0 as? LabCoreAgentEntity)?.labAgentId
                        }.sorted()
                        guard skillLateFailureCandidateValid,
                              try session.durableStateBytes() == skillLateFailureBytes,
                              session.skillSnapshot() == skillLateFailureSnapshot,
                              session.causalLedgerSnapshot() == skillLateFailureCausal,
                              afterRecorderBytes == skillLateFailureRecorderBytes,
                              probesByAgentId.keys.sorted() == skillLateFailureProbeIDs,
                              afterWorldAgentIDs == skillLateFailureWorldAgentIDs,
                              world.getBlock(target.x, target.y, target.z)
                                == skillLateFailureBlock else {
                            throw ControllerError.constructionBoundary(
                                "skill late-failure rollback diverged"
                            )
                        }
                        trace(
                            "skills late-failure rollback sessionBytes=exact "
                                + "resources=exact practiceTotals=exact records=exact "
                                + "levels=exact causal=exact recorder=exact probes=exact "
                                + "worldIndexes=exact block=restored ghostCredit=0"
                        )
                        skillLateFailureProofInjected = true
                        throw error
                    }
                    let failure = constructionFailure(for: error)
                    let failureID = "construction-failure:\(intent.placementId)"
                    if (try? applyRecordedOperationIfActive(
                        .recordConstructionFailure(
                            failureID: failureID,
                            projectID: project.projectId,
                            builderAgentID: project.builderAgentId,
                            failure: failure,
                            reason: String(describing: error)
                        ),
                        session: &session,
                        recorder: &recorder
                    )) == nil {
                        try? session.recordConstructionFailure(
                            failureId: failureID,
                            projectId: project.projectId,
                            builderAgentId: project.builderAgentId,
                            failure: failure,
                            reason: String(describing: error)
                        )
                    }
                    throw error
                }
                session = candidate
                recorder = candidateRecorder
                lastConstructionReason = "placed cell \(cell.index) \(cell.resource.rawValue)"
                if session.cooperationEnabled {
                    let ledger = session.causalLedgerSnapshot().events
                    let placementEvent = ledger.last { $0.kind == .constructionPlacement }
                    let completionEvent = ledger.last { $0.kind == .constructionCompletion }
                    trace("cooperation placement tick=\(session.tick) operation=\(intent.placementId) event=\(placementEvent?.eventID.rawValue ?? "none") actor=\(placement.agentId) cell=\(cell.index) resource=\(cell.resource.rawValue) completionEvent=\(completionEvent?.eventID.rawValue ?? "none")")
                }
            }
            let cooperationTravelAgentIDs = Set(session.cooperationSnapshot().tasks
                .filter { $0.status == .accepted || $0.status == .active }
                .map { $0.helperID.rawValue })
            if movementEnabled {
                let preMovementSnapshot = session.snapshot()
                let intents = AgentMovementCoordinator.resolve(snapshot: preMovementSnapshot)
                var movementCandidate = session
                var movementRecorder = recorder
                let verified = try movementExecutor.apply(
                    intents: intents,
                    snapshot: preMovementSnapshot,
                    world: world,
                    probesByAgentId: probesByAgentId,
                    explorationDistanceBoundary: session.configuration
                        .feedbackLoopConfiguration.maxExploreDistanceFromHome,
                    additionalOccupiedPositions: [AgentPosition(
                        x: Int(player.x.rounded(.down)),
                        y: Int(player.y.rounded(.down)),
                        z: Int(player.z.rounded(.down))
                    )],
                    postApplyValidation: { verifiedMovements in
                        if try applyRecordedOperationIfActive(
                            .verifiedPhysicalMovements(verifiedMovements),
                            session: &movementCandidate,
                            recorder: &movementRecorder
                        ) == nil {
                            try movementCandidate.applyVerifiedPhysicalMovements(
                                verifiedMovements
                            )
                        }
                        try validatePostTick(
                            snapshot: movementCandidate.snapshot(),
                            result: result,
                            dependentCareEnabled: movementCandidate.dependentCareEnabled,
                            cooperationTravelAgentIDs: cooperationTravelAgentIDs,
                            explorationDistanceBoundary: movementCandidate.configuration
                                .feedbackLoopConfiguration.maxExploreDistanceFromHome
                        )
                    }
                )
                session = movementCandidate
                recorder = movementRecorder
                lastMovementOutcomes = verified.map(\.outcome)
                let physicalMovementSummary = verified.map { movement in
                    let outcome = movement.outcome
                    return "\(outcome.agentId):\(outcome.status.rawValue):"
                        + "\(outcome.fromPosition.x),\(outcome.fromPosition.y),\(outcome.fromPosition.z)>"
                        + "\(outcome.toPosition.x),\(outcome.toPosition.y),\(outcome.toPosition.z)"
                }.joined(separator: ";")
                trace(
                    "embodiment movement tick=\(session.tick) authority=PebbleCore "
                        + "publication=verified outcomes=\(physicalMovementSummary) noNormalSetPos=1"
                )
            } else {
                lastMovementOutcomes = []
                if session.settlementMetricsEnabled,
                   session.settlementMetricsSummary().nextPulseTick == session.tick {
                    if try applyRecordedOperationIfActive(
                        .settlementPulseBoundary,
                        session: &session,
                        recorder: &recorder
                    ) == nil {
                        _ = try session.applySettlementMetricsPulseIfDue()
                    }
                }
                try validatePostTick(
                    snapshot: session.snapshot(),
                    result: result,
                    dependentCareEnabled: session.dependentCareEnabled,
                    cooperationTravelAgentIDs: cooperationTravelAgentIDs,
                    explorationDistanceBoundary: session.configuration
                        .feedbackLoopConfiguration.maxExploreDistanceFromHome
                )
            }
            if session.dependentCareEnabled {
                let supervisionEngagements = session.dependentCareSnapshot()
                    .activeEngagements.filter {
                        $0.kind == .supervise
                    }.sorted {
                        if $0.dependentID != $1.dependentID {
                            return $0.dependentID < $1.dependentID
                        }
                        return $0.caregiverID < $1.caregiverID
                    }
                for engagement in supervisionEngagements {
                    let progress: AgentCareSupervisionProgress
                    if recorder != nil {
                        var progressCandidate = session
                        progress = try progressCandidate
                            .verifyDependentCareSupervisionTick(
                                caregiverID: engagement.caregiverID,
                                dependentID: engagement.dependentID
                            )
                        _ = try applyRecordedOperationIfActive(
                            .verifyDependentCareSupervisionTick(
                                caregiverID: engagement.caregiverID,
                                dependentID: engagement.dependentID
                            ),
                            session: &session,
                            recorder: &recorder
                        )
                    } else {
                        progress = try session.verifyDependentCareSupervisionTick(
                            caregiverID: engagement.caregiverID,
                            dependentID: engagement.dependentID
                        )
                    }
                    trace(
                        "care supervision tick=\(session.tick) caregiver="
                            + "\(progress.caregiverID.rawValue) dependent="
                            + "\(progress.dependentID.rawValue) elapsedTicks="
                            + "\(progress.elapsedTicks) verifiedSupervisionTicks="
                            + "\(progress.verifiedEngagedTicks) interruptedTicks="
                            + "\(progress.interruptedTicks) counted="
                            + "\(progress.countedThisTick ? 1 : 0) interrupted="
                            + "\(progress.interruptedThisTick ? 1 : 0) duplicate="
                            + "\(progress.duplicateEvaluation ? 1 : 0)"
                    )
                }
                let careActions = result.agents.filter {
                    $0.action.name == "provide_food"
                        || $0.action.name == "supervise_dependent"
                        || $0.action.name == "assist_return_home"
                }.sorted { $0.agentId < $1.agentId }
                for action in careActions {
                    guard let caregiverID = AgentID(rawValue: action.agentId),
                          let engagement = session.careEngagement(for: caregiverID) else {
                        throw ControllerError.lifecycleBoundary(
                            "dependent care action without active engagement"
                        )
                    }
                    if action.action.name == "provide_food" {
                        if session.physicalFoodSurvivalEnabled {
                            guard let probe = probesByAgentId[action.agentId] else {
                                throw ControllerError.physicalFoodBoundary(
                                    "physical dependent care has no caregiver embodiment"
                                )
                            }
                            let intent = try session.nextPhysicalDependentFoodIntent(
                                caregiverID: caregiverID,
                                dependentID: engagement.dependentID
                            )
                            let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(
                                probe, in: world
                            )
                            guard let plan = try foodConsumptionExecutor.prepareDependent(
                                intent, session: session, source: source,
                                gateway: materialCustodyGateway
                            ) else {
                                trace(
                                    "care physical nourishment unavailable tick=\(session.tick) caregiver="
                                        + "\(caregiverID.rawValue) dependent="
                                        + "\(engagement.dependentID.rawValue) "
                                        + "foodRawShadow="
                                        + "\((try session.state(for: caregiverID)).resourceInventory.count(of: .foodRaw)) "
                                        + "physicalDebit=0 hungerDelta=0 historyDelta=0 "
                                        + "foodRawGhostDelta=0"
                                )
                                continue
                            }
                            let physicalCountBefore = source.read()?[plan.sourceSlot]?.count ?? -1
                            var recorderCandidate = recorder
                            let transaction = foodConsumptionExecutor.executeDependent(
                                plan, session: &session, source: source,
                                gateway: materialCustodyGateway
                            ) { outcome, candidate in
                                if var activeRecorder = recorderCandidate {
                                    _ = try activeRecorder.apply(
                                        .validatedPhysicalDependentFood(outcome),
                                        to: &candidate
                                    )
                                    recorderCandidate = activeRecorder
                                } else {
                                    _ = try candidate.applyValidatedPhysicalDependentFood(outcome)
                                }
                            }
                            guard transaction.succeeded else {
                                throw ControllerError.physicalFoodBoundary(
                                    "physical dependent food transaction "
                                        + transaction.status.rawValue
                                )
                            }
                            recorder = recorderCandidate
                            let physicalCountAfter = source.read()?[plan.sourceSlot]?.count ?? 0
                            trace(
                                "care physical nourishment tick=\(session.tick) caregiver="
                                    + "\(caregiverID.rawValue) dependent="
                                    + "\(engagement.dependentID.rawValue) material="
                                    + "\(plan.validatedOutcome.canonicalMaterialName) "
                                    + "slot=\(plan.sourceSlot) physicalCount="
                                    + "\(physicalCountBefore)>\(physicalCountAfter) physicalDebit=1 "
                                    + "hunger=\(plan.validatedOutcome.hungerBefore)>"
                                    + "\(plan.validatedOutcome.hungerAfter) "
                                    + "foodRawGhostDelta=0 receipt="
                                    + plan.validatedOutcome.physicalReceiptID
                            )
                            continue
                        }
                        let intent = AgentCareProvisionIntent(
                            provisionID: "dependent-care:\(action.agentId):\(engagement.dependentID.rawValue):\(session.tick)",
                            needID: engagement.needID,
                            caregiverID: caregiverID,
                            dependentID: engagement.dependentID,
                            tick: session.tick
                        )
                        let provision: AgentCareProvisionResult
                        if recorder != nil {
                            var outcomeCandidate = session
                            provision = try outcomeCandidate.provideDependentNourishment(intent)
                            _ = try applyRecordedOperationIfActive(
                                .provideDependentNourishment(intent),
                                session: &session,
                                recorder: &recorder
                            )
                        } else {
                            provision = try session.provideDependentNourishment(intent)
                        }
                        trace(
                            "care nourishment tick=\(session.tick) caregiver=\(caregiverID.rawValue) "
                                + "dependent=\(engagement.dependentID.rawValue) source=\(provision.foodSource.rawValue) "
                                + "food=\(provision.foodBefore)->\(provision.foodAfter) "
                                + "consumed=\(provision.consumedByDependent) "
                                + "hunger=\(String(format: "%.2f", provision.hungerBefore))->"
                                + "\(String(format: "%.2f", provision.hungerAfter)) "
                                + "succeeded=\(provision.succeeded ? 1 : 0) mutation=none"
                        )
                    } else {
                        if try applyRecordedOperationIfActive(
                            .completeDependentCareInteraction(
                                caregiverID: caregiverID,
                                dependentID: engagement.dependentID
                            ),
                            session: &session,
                            recorder: &recorder
                        ) == nil {
                            _ = try session.completeDependentCareInteraction(
                                caregiverID: caregiverID,
                                dependentID: engagement.dependentID
                            )
                        }
                    }
                }
                traceDependentCareState(session)
            }
            if session.localEcologyEnabled,
               let settlement = session.populationSnapshot().settlement {
                let validation = localEcologyAdapter.validate(
                    world: world,
                    settlement: settlement,
                    patches: session.localEcologySnapshot().patches
                )
                lastEcologyScanDiagnostics = validation.diagnostics
                if try applyRecordedOperationIfActive(
                    .applyHabitatValidation(validation.observations),
                    session: &session,
                    recorder: &recorder
                ) == nil {
                    _ = try session.applyLocalEcologyEndOfTick(
                        habitatValidations: validation.observations
                    )
                }
                let ecology = session.localEcologySummary()
                trace("ecology pulse tick=\(session.tick) patches=\(ecology.patchCount) yield=\(ecology.currentYield)/\(ecology.capacity) regenerated=\(ecology.regenerated) harvested=\(ecology.harvested) pressure=\(ecology.pressure?.rawValue ?? "none") hungry=\(ecology.hungry) critical=\(ecology.critical) starvationDamage=\(ecology.starvationDamage) reads=\(validation.diagnostics.worldReads) conservation=\(ecology.conservationBalanced ? "exact" : "diverged") mutation=none")
            }
            try resolvePendingBirthIfDue(
                world: world,
                player: player,
                session: &session,
                recorder: &recorder
            )
            if session.ecologicalObservationEnabled {
                ecologicalObservationSensor.invalidate(world: world)
                try recordLiveEcologicalObservations(
                    world: world, session: &session, recorder: &recorder,
                    receiptTransaction: &receiptTransaction
                )
            }
            if session.agricultureEnabled {
                try reconcileLiveAgriculturalLifecycle(
                    world: world,
                    session: &session,
                    recorder: &recorder
                )
                _ = try prepareLiveAgriculturalPlanIfEligible(
                    world: world, session: &session, recorder: &recorder
                )
            }
            if session.livestockEnabled {
                _ = try prepareLiveLivestockManagementIfEligible(
                    world: world, session: &session, recorder: &recorder
                )
            }
            if session.mortalityEnabled {
                do {
                    try reconcileMortalityProbes(
                        previous: preCognitive,
                        current: &session,
                        recorder: &recorder,
                        world: world
                    )
                } catch {
                    isPaused = true
                    throw error
                }
            }
            let finalSnapshot = session.snapshot()
            if session.ecologicalObservationEnabled {
                try reconcileWorldEcologicalObservationReceiptRetention(
                    for: session,
                    transaction: &receiptTransaction
                )
                try reconcileWorldAgriculturalActionReceiptRetention(
                    for: session,
                    transaction: &receiptTransaction
                )
                try validateWorldEcologicalObservationReceipts(
                    for: session, dimension: world.dim.rawValue
                )
            }
            receiptTransaction.commit()
            self.session = session
            replayRecorder = recorder
            tracePhysicalState(at: session.tick)
            traceCooperationState(at: session.tick)
            tracePopulationState(at: session.tick)
            traceSettlementMetricsState(at: session.tick)
            traceLifecycleState(at: session.tick)
            lastTickResult = result
            for agent in finalSnapshot.agents { observedGoalKinds.insert(agent.currentGoal.kind.rawValue) }
            for agent in finalSnapshot.agents {
                if let trace = agent.lastFeedbackDecisionTrace,
                   trace.actionChanged,
                   !trace.memoryRecordsUsed.isEmpty {
                    lastInfluencedTracesByAgentId[agent.id] = trace
                }
            }
            let focus = finalSnapshot.agents.first { $0.id == focusedAgentId } ?? finalSnapshot.agents.first
            let goals = finalSnapshot.agents.map { "\($0.id):\($0.currentGoal.kind.rawValue)" }.joined(separator: ",")
            let perception = focus?.lastWorldObservation
            let safety = focus?.lastWorldPerceptionEffect?.safetyAfter ?? 0
            let perceptionSummary = "t\(perception?.traversableNeighborCount ?? 0)/b\(perception?.blockedNeighborCount ?? 0)/d\(perception?.dangerousDropCount ?? 0)/s\(String(format: "%.2f", safety))"
            let observations = finalSnapshot.agents.map { "\($0.id):\($0.observationCount)" }.joined(separator: ",")
            let resourceSeen = focus?.lastResourceObservations.first.map {
                "\($0.resource.rawValue)@\(positionText($0.target)):\($0.source.rawValue)#\($0.expectedBlockFingerprint.map(String.init) ?? "none")"
            } ?? "none"
            let resourceDistance = focus?.lastResourceObservations.first?.distanceManhattan ?? 0
            let activeResourceTarget = focus?.activeResourceTarget.map {
                "\(positionText($0.target))@selected\($0.selectedAtTick)/seen\($0.lastSeenAtTick)"
            } ?? "none"
            let navigation = focus?.navigationProgress
            let reservationOwner = focus?.resourceReservation?.agentId ?? "none"
            let routeNext = navigation?.nextStep.map(positionText) ?? "none"
            let moved = lastMovementOutcomes.filter { $0.status == .moved }.count
            let blocked = lastMovementOutcomes.filter { $0.status == .blocked }.count
            let outcomes = lastMovementOutcomes.map { "\($0.agentId):\($0.status.rawValue)" }.joined(separator: ",")
            let positions = finalSnapshot.agents.map { "\($0.id):\($0.position.x),\($0.position.y),\($0.position.z)/m\($0.movementCount)" }.joined(separator: ";")
            let focusMovement = focus?.lastMovementOutcome.map { outcome in
                if outcome.status == .blocked { return "blocked:\(outcome.resolutionReason)" }
                let direction = outcome.requestedDirection?.rawValue ?? "none"
                return "\(outcome.status.rawValue):\(direction):from=\(positionText(outcome.fromPosition)):to=\(positionText(outcome.toPosition))"
            } ?? "none"
            let retrieved = finalSnapshot.agents.reduce(0) { $0 + $1.memoryRetrievalCount }
            let influenced = finalSnapshot.agents.reduce(0) { $0 + $1.memoryInfluencedDecisionCount }
            let deduplicated = finalSnapshot.agents.reduce(0) { $0 + $1.feedbackMemoryDeduplicatedCount }
            let currentInfluenced = finalSnapshot.agents.first {
                $0.lastFeedbackDecisionTrace?.actionChanged == true
                    && !($0.lastFeedbackDecisionTrace?.memoryRecordsUsed.isEmpty ?? true)
            }
            let decisionAgent = (
                focus?.lastFeedbackDecisionTrace?.actionChanged == true ? focus : currentInfluenced
            ) ?? focus
            let decision = decisionAgent?.lastFeedbackDecisionTrace
            let memoryUsed = decision?.memoryRecordsUsed.first.map { "\($0.type)@\($0.tick)" } ?? "none"
            let baseMove = decision?.baseDirection?.rawValue ?? decision?.baseAction.name ?? "none"
            let finalMove = decision?.finalDirection?.rawValue ?? decision?.finalAction.name ?? "none"
            let dominant = decision?.dominantFactor.kind.rawValue ?? "none"
            let decisionReason = decision?.reason.replacingOccurrences(of: " ", with: "_") ?? "none"
            let economyFixtures = interactionExecutor.economyState()
            let fixtureSummary = economyFixtures.fixtures.map {
                "\($0.fixtureId):\($0.harvested ? "harvested" : "available")"
            }.joined(separator: ",")
            let inventorySummary = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(focus?.resourceInventory.count(of: $0) ?? 0)"
            }.joined(separator: ",")
            let stockSummary = AgentResourceKind.allCases.map {
                "\($0.rawValue):\(finalSnapshot.campStock.count(of: $0))"
            }.joined(separator: ",")
            let deliveryOutcome = focus?.lastDeliveryOutcome
            let survivalProgress = focus?.survivalProgress
            let consumptionOutcome = survivalProgress?.lastConsumptionOutcome
            let survivalMemory = survivalProgress?.lastMemoryType?.rawValue ?? focus?.recentMemory.last { entry in
                entry.type == "food_consumed"
                    || entry.type == "consumption_blocked"
                    || entry.type == "starvation_damage"
            }?.type ?? "none"
            let natural = naturalResourceExecutor.state
            let construction = finalSnapshot.constructionProject
            let constructionWorld = constructionExecutor.state
            successfulCognitiveTicks += 1
            blockedMovementOutcomeCount += blocked
            maxObservedMemoryCount = max(maxObservedMemoryCount, finalSnapshot.agents.map(\.memoryCount).max() ?? 0)
            maxObservedDistanceFromHome = max(maxObservedDistanceFromHome, finalSnapshot.agents.map(\.distanceFromHome).max() ?? 0)
            let message = "tick=\(result.tick) movement=\(movementEnabled ? "on" : "off") moved=\(moved) blocked=\(blocked) outcomes=\(outcomes) positions=\(positions) goals=\(goals) focus=\(focus?.id ?? "none") action=\(focus?.lastAction?.name ?? "none") focusMove=\(focusMovement) memory=\(focus?.memoryCount ?? 0) retrieved=\(retrieved) influenced=\(influenced) dedup=\(deduplicated) decisionAgent=\(decisionAgent?.id ?? "none") memoryUsed=\(memoryUsed) decisionChanged=\(decision?.actionChanged == true ? 1 : 0) baseMove=\(baseMove) finalMove=\(finalMove) dominant=\(dominant) decisionReason=\(decisionReason) world_observed=1 perception=\(perceptionSummary) observations=\(observations) resourceSeen=\(resourceSeen) resourceDistance=\(resourceDistance) activeTarget=\(activeResourceTarget) reservationOwner=\(reservationOwner) navigationPurpose=\(navigation?.route?.purpose.rawValue ?? "none") navigation=\(navigation?.status.rawValue ?? "idle") routeLength=\(navigation?.route?.positions.count ?? 0) routeIndex=\(navigation?.routeIndex ?? 0) stepsRemaining=\(navigation?.stepsRemaining ?? 0) nextStep=\(routeNext) replans=\(navigation?.replanCount ?? 0) invalidation=\(navigation?.lastInvalidation?.rawValue ?? "none") navigationFailure=\(navigation?.lastFailure?.rawValue ?? "none") autoInteraction=\(autoInteractionEnabled ? "on" : "off") interactionAttempted=\(lastInteractionAttempted ? 1 : 0) interactionSucceeded=\(lastInteractionSucceeded ? 1 : 0) interactionBlocked=\(lastInteractionBlocked ? 1 : 0) economy=\(finalSnapshot.economyEnabled ? "on" : "off") natural=\(finalSnapshot.naturalResourcesEnabled ? "on" : "off") naturalReads=\(natural.lastScan.worldBlockReadCount) naturalCandidates=\(natural.lastScan.candidateCount) naturalObservations=\(natural.lastScan.observationsEmitted) naturalHarvests=\(natural.harvestCount) naturalRollbacks=\(natural.rollbackCount) survival=\(finalSnapshot.survivalEnabled ? "on" : "off") survivalStatus=\(survivalProgress?.status.rawValue ?? "off") hunger=\(String(format: "%.2f", focus?.needs.hunger ?? 0)) fatigue=\(String(format: "%.2f", focus?.needs.fatigue ?? 0)) health=\(focus?.health ?? 0) criticalHungerTicks=\(survivalProgress?.consecutiveCriticalHungerTicks ?? 0) foodConsumed=\(survivalProgress?.foodConsumedCount ?? 0) starvationDamage=\(survivalProgress?.starvationDamageTaken ?? 0) consumptionOutcome=\(consumptionOutcome?.status.rawValue ?? "none") consumptionSucceeded=\(lastConsumptionSucceeded ? 1 : 0) survivalMemory=\(survivalMemory) quota=\(finalSnapshot.deliveryQuota) inventoryByResource=\(inventorySummary) campStock=\(stockSummary) fixtures=\(fixtureSummary) deliveryOutcome=\(deliveryOutcome?.status.rawValue ?? "none") deliverySucceeded=\(lastDeliverySucceeded ? 1 : 0) build=\(finalSnapshot.buildAutoEnabled ? "on" : "off") buildProject=\(construction?.projectId ?? "none") buildStatus=\(construction?.status.rawValue ?? "none") buildOrigin=\(construction.map { positionText($0.origin) } ?? "none") buildPlaced=\(construction?.placedCellIndices.count ?? 0) buildNext=\(construction?.nextCellIndex ?? 0) buildWork=\(construction?.nextWorkPosition.map(positionText) ?? "none") buildLast=\(constructionWorld.lastPlacement) buildFailure=\(construction?.lastFailure?.rawValue ?? constructionWorld.lastFailure) buildRollback=\(constructionWorld.rollbackCount) home=\(focus.map { positionText($0.homePosition) } ?? "none") conservation=\(finalSnapshot.conservation.harvestedTotal):\(finalSnapshot.conservation.carriedTotal)+\(finalSnapshot.conservation.campStockTotal)+\(finalSnapshot.conservation.consumedTotal)+\(finalSnapshot.conservation.constructionEscrowTotal)+\(finalSnapshot.conservation.constructedTotal):\(finalSnapshot.conservation.balanced ? "exact" : "diverged") corridorObserved=\(economyFixtures.corridorObservedBlockCount) corridorChanged=\(economyFixtures.corridorChangedDuringNavigation) fixtureSetupMutations=\(economyFixtures.setupMutatedBlockCount)"
            traceTick(
                message,
                tick: result.tick,
                important: decision?.actionChanged == true || lastInteractionAttempted
                    || placementActions.first != nil || fundingActions.first != nil
            )
            traceSocialState(snapshot: finalSnapshot)
            return true
        } catch {
            let isKinshipLateFailure: Bool
            if case ControllerError.kinshipLateFailureProof = error {
                isKinshipLateFailure = true
            } else {
                isKinshipLateFailure = false
            }
            let isSkillLateFailure: Bool
            if case let ControllerError.constructionBoundary(reason) = error,
               reason == "injected construction publication failure",
               skillLateFailureRunEnabled,
               skillLateFailureProofInjected {
                isSkillLateFailure = true
            } else {
                isSkillLateFailure = false
            }
            let isMortalityBoundary: Bool
            if case ControllerError.mortalityBoundary = error {
                isMortalityBoundary = true
            } else {
                isMortalityBoundary = false
            }
            let isMortalityRollbackBoundary: Bool
            if case ControllerError.mortalityRollbackBoundary = error {
                isMortalityRollbackBoundary = true
            } else {
                isMortalityRollbackBoundary = false
            }
            if isMortalityRollbackBoundary {
                replayRecorder = publishedRecorder
                isPaused = true
                lastError = String(describing: error)
                runtimeErrorCount += 1
                trace(
                    "mortality boundary rollback publishedSession=unchanged "
                        + "publishedRecorder=unchanged physicalCustody=FAILED "
                        + "error=\(error)"
                )
                return false
            }
            if isMortalityBoundary {
                replayRecorder = publishedRecorder
                isPaused = true
                lastError = String(describing: error)
                runtimeErrorCount += 1
                trace(
                    "mortality boundary rollback publishedSession=unchanged "
                        + "publishedRecorder=unchanged physicalCustody=verified "
                        + "error=\(error)"
                )
                return false
            }
            if isSkillLateFailure {
                replayRecorder = publishedRecorder
                do {
                    let afterRecorderBytes = try replayRecorder.map {
                        try AgentReplayCodec.encodeRecords($0.records)
                    }
                    let afterProbeState = probesByAgentId.values.map {
                        "\($0.labAgentId):\($0.x):\($0.y):\($0.z)"
                    }.sorted()
                    let afterWorldAgentIDs = world.entities.compactMap {
                        ($0 as? LabCoreAgentEntity)?.labAgentId
                    }.sorted()
                    guard let publishedSession = self.session,
                          try publishedSession.durableStateBytes()
                            == skillLateFailurePublishedBytes,
                          afterRecorderBytes == skillLateFailurePublishedRecorderBytes,
                          afterProbeState == skillLateFailurePublishedProbeState,
                          afterWorldAgentIDs == skillLateFailurePublishedWorldAgentIDs,
                          world.entities.count == skillLateFailurePublishedWorldEntityCount else {
                        throw ControllerError.constructionBoundary(
                            "skill late-failure published boundary diverged"
                        )
                    }
                } catch {
                    lastError = String(describing: error)
                    runtimeErrorCount += 1
                    trace("error \(error)")
                    return false
                }
                lastError = String(describing: error)
                runtimeErrorCount += 1
                trace(
                    "skills late-failure controlledError=injected_construction_publication_failure "
                        + "publishedSession=unchanged publishedRecorder=unchanged "
                        + "probes=unchanged worldIndexes=unchanged"
                )
                return false
            } else if isKinshipLateFailure {
                replayRecorder = publishedRecorder
                do {
                    guard let kinshipLateFailureBoundary else {
                        throw ControllerError.kinshipBoundary(
                            "late-failure proof boundary was not captured"
                        )
                    }
                    try verifyKinshipLateFailureRollback(
                        kinshipLateFailureBoundary, world: world
                    )
                } catch {
                    lastError = String(describing: error)
                    runtimeErrorCount += 1
                    trace("error \(error)")
                    return false
                }
            } else if recorder != nil {
                recorder?.markNonReplayable("tick failed: \(error)")
                replayRecorder = recorder
            }
            if autoInteractionEnabled {
                autoInteractionEnabled = false
                lastInteractionBlocked = true
                lastAutoInteractionReason = "disabled after blocking failure: \(error)"
            }
            if economyAutoEnabled {
                economyAutoEnabled = false
                lastEconomyReason = "disabled after blocking failure: \(error)"
            }
            if session.buildAutoEnabled {
                try? session.setBuildAutoEnabled(false)
                self.session = session
                lastConstructionReason = "disabled after blocking failure: \(error)"
            }
            lastError = String(describing: error)
            runtimeErrorCount += 1
            if isKinshipLateFailure {
                trace("kinship late-failure controlledError=\(error)")
            } else {
                trace("error \(error)")
            }
            return false
        }
    }

    func validatePostTick(
        snapshot: AgentSessionSnapshot,
        result: AgentSessionTickResult,
        dependentCareEnabled: Bool = false,
        cooperationTravelAgentIDs: Set<String> = [],
        explorationDistanceBoundary: Int = AgentFeedbackLoopConfiguration.live
            .maxExploreDistanceFromHome
    ) throws {
        var positions = Set<String>()
        for agent in snapshot.agents {
            let uniquePosition = positions.insert(positionText(agent.position)).inserted
            let probe = probesByAgentId[agent.id]
            let probePosition = probe.map {
                AgentPosition(
                    x: Int($0.x.rounded(.down)), y: Int($0.y.rounded(.down)),
                    z: Int($0.z.rounded(.down))
                )
            }
            let probeMatches = probe?.labAgentId == agent.id
                && probePosition == agent.position
            guard agent.lastWorldObservation != nil,
                  agent.lastWorldPerceptionEffect != nil,
                  agent.observationCount >= agent.ticksAlive,
                  uniquePosition, probeMatches else {
                trace(
                    "movement boundary detail actor=\(agent.id) "
                        + "observation=\(agent.lastWorldObservation == nil ? 0 : 1) "
                        + "perception=\(agent.lastWorldPerceptionEffect == nil ? 0 : 1) "
                        + "counts=\(agent.observationCount)/\(agent.ticksAlive) "
                        + "unique=\(uniquePosition ? 1 : 0) session=\(positionText(agent.position)) "
                        + "probe=\(probePosition.map(positionText) ?? "none") "
                        + "probeMatches=\(probeMatches ? 1 : 0)"
                )
                throw ControllerError.movementBoundary(agent.id)
            }
            guard agent.memoryCount <= 128,
                  agent.memoryRetrievalCount >= agent.memoryInfluencedDecisionCount else {
                throw ControllerError.feedbackBoundary(agent.id)
            }
            let isPassiveNewborn = dependentCareEnabled
                && snapshot.lifecycle?.members.first(where: {
                    $0.agentID.rawValue == agent.id
                })?.currentStage == .newborn
            if isPassiveNewborn {
                guard agent.lastFeedbackDecisionTrace == nil else {
                    throw ControllerError.feedbackBoundary(agent.id)
                }
            } else {
                guard let decision = agent.lastFeedbackDecisionTrace else {
                    throw ControllerError.feedbackBoundary(agent.id)
                }
                if !decision.memoryRecordsUsed.isEmpty {
                    guard decision.actionChanged,
                          decision.dominantFactor.kind == .movementFeedback else {
                        throw ControllerError.feedbackBoundary(agent.id)
                    }
                }
            }
            let usesConstructionMaterialRange = (snapshot.buildAutoEnabled
                    && snapshot.constructionProject?.builderAgentId == agent.id
                    && (snapshot.constructionProject?.status == .planned
                        || snapshot.constructionProject?.status == .acquiringMaterials))
                || cooperationTravelAgentIDs.contains(agent.id)
            let movementBoundary: Int?
            if agent.currentGoal.kind == .migrateToSettlement {
                movementBoundary = AgentPopulationConfiguration.live.maximumMigrationDistance
            } else if usesConstructionMaterialRange {
                movementBoundary = AgentConstructionMaterialSurvey.maximumDistanceFromHome
            } else {
                movementBoundary = nil
            }
            if movementEnabled,
               let movementBoundary,
               agent.distanceFromHome > movementBoundary {
                let movement = agent.lastMovementOutcome.map {
                    "\($0.status.rawValue):from=\(positionText($0.fromPosition)):"
                        + "to=\(positionText($0.toPosition)):"
                        + "reason=\($0.resolutionReason.replacingOccurrences(of: " ", with: "_"))"
                } ?? "none"
                trace(
                    "GATE_B4_DISTANCE_FROM_HOME_FAILURE actor=\(agent.id) "
                        + "tick=\(result.tick) position=\(positionText(agent.position)) "
                        + "home=\(positionText(agent.homePosition)) "
                        + "distance=\(agent.distanceFromHome) boundary=\(movementBoundary) "
                        + "goal=\(agent.currentGoal.kind.rawValue) "
                        + "action=\(agent.lastAction?.name ?? "none") "
                        + "movement=\(movement) bypass=0"
                )
                throw ControllerError.feedbackBoundary(agent.id)
            }
            if movementEnabled,
               agent.currentGoal.kind == .explore,
               let outcome = agent.lastMovementOutcome,
               outcome.tick == result.tick,
               outcome.status == .moved {
                let respectsExplorationRange =
                    AgentFeedbackLoop.respectsExplorationHomeBoundary(
                        distanceBefore: outcome.distanceFromHomeBefore,
                        distanceAfter: outcome.distanceFromHomeAfter,
                        maximumDistance: explorationDistanceBoundary
                    )
                guard respectsExplorationRange else {
                    trace(
                        "EXPLORATION_HOME_RANGE_FAILURE actor=\(agent.id) "
                            + "tick=\(result.tick) distance="
                            + "\(outcome.distanceFromHomeBefore)>"
                            + "\(outcome.distanceFromHomeAfter) "
                            + "boundary=\(explorationDistanceBoundary) "
                            + "movement=\(positionText(outcome.fromPosition))>"
                            + "\(positionText(outcome.toPosition)) bypass=0"
                    )
                    throw ControllerError.feedbackBoundary(agent.id)
                }
            }
            if !movementWasEverEnabledSinceReset {
                guard agent.position == agent.homePosition,
                      agent.distanceFromHome == 0,
                      agent.movementCount == 0 else {
                    throw ControllerError.movementBoundary(agent.id)
                }
            }
            if let outcome = agent.lastMovementOutcome,
               outcome.tick == result.tick,
               outcome.status == .moved {
                if let route = agent.navigationProgress.route,
                   route.purpose.targetMustFitLocalObservationRadius {
                    guard AgentBoundedTravel.isLocallyBoundedSegment(
                        from: outcome.fromPosition,
                        to: route.target
                    ) else {
                        trace(
                            "LOCAL_NAVIGATION_SEGMENT_FAILURE actor=\(agent.id) "
                                + "tick=\(result.tick) origin="
                                + "\(positionText(outcome.fromPosition)) target="
                                + "\(positionText(route.target)) purpose="
                                + "\(route.purpose.rawValue) radius="
                                + "\(AgentNavigationObservation.maximumRadius) bypass=0"
                        )
                        throw ControllerError.movementBoundary(agent.id)
                    }
                }
                guard agent.movementCount > 0,
                      let observation = agent.lastWorldObservation,
                      let direction = outcome.requestedDirection,
                      let neighbor = observation.neighbors.first(where: { $0.direction == direction }),
                      neighbor.traversable,
                      !neighbor.dangerousDrop,
                      neighbor.column.chunkReady else {
                    throw ControllerError.unsafeMovement(agent.id)
                }
            }
        }
        guard probesByAgentId.count == snapshot.agentCount else {
            throw ControllerError.invalidProbeSet(probesByAgentId.keys.sorted())
        }
    }

    func positionText(_ position: AgentPosition) -> String {
        "\(position.x),\(position.y),\(position.z)"
    }

    func constructionFailure(for error: Error) -> AgentConstructionFailure {
        guard let execution = error as? PebbleAgentConstructionExecutor.ExecutionError else {
            return .publicationFailed
        }
        switch execution {
        case .gateDisabled: return .gateDisabled
        case .autoDisabled: return .autoDisabled
        case .projectAlreadyActive: return .projectAlreadyExists
        case .projectMissing: return .projectMissing
        case .projectMismatch: return .invalidBuilder
        case .invalidCell, .invalidMaterial, .invalidReach: return .invalidCell
        case .missingMaterial, .wrongMaterial: return .insufficientMaterials
        case .chunkUnavailable: return .chunkUnavailable
        case .occupied: return .occupied
        case .staleFingerprint: return .staleFingerprint
        case .previousCellChanged, .structureValidationFailed: return .structureChanged
        case .mutationVerificationFailed: return .publicationFailed
        case .rollbackVerificationFailed: return .rollbackFailed
        case .clearVerificationFailed: return .clearFailed
        }
    }

}
