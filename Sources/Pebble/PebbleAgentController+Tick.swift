import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func advanceOneTick(world: World, player: Player) -> Bool {
        guard activeWorld === world, var session else { return false }
        lastInteractionAttempted = false
        lastInteractionSucceeded = false
        lastInteractionBlocked = false
        lastDeliverySucceeded = false
        lastConsumptionSucceeded = false
        do {
            let preCognitive = session.snapshot()
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
                if preCognitive.naturalResourcesEnabled,
                   economyAutoEnabled,
                   agent.id == focusedAgentId {
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
                        playerPosition: playerPosition
                    )
                    naturalResourceExecutor.recordScan(naturalScan)
                    combinedResourceObservations += naturalScan.observations
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
                if agent.currentGoal.kind == .buildShelter,
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
            let result = try session.advanceTick(perceptions: perceptions)
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
                let outcome = try session.applySocialVerification(observation)
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
                let outcome = try session.consumeFood(AgentConsumptionIntent(
                    consumptionId: "survival-consumption:\(consumption.agentId):\(session.tick)",
                    agentId: consumption.agentId,
                    tick: session.tick
                ))
                lastConsumptionSucceeded = outcome.status == .succeeded
                lastSurvivalReason = outcome.reason
            }
            let interactionActions = result.agents
                .filter { $0.action.name == "harvest_block" }
                .sorted { $0.agentId < $1.agentId }
            if let interaction = interactionActions.first {
                guard autoInteractionEnabled || economyAutoEnabled
                        || (session.survivalEnabled && interactionFeatureEnabled) else {
                    throw ControllerError.interactionBoundary("harvest action without automatic interaction")
                }
                lastInteractionAttempted = true
                _ = try performHarvestTransaction(
                    world: world,
                    player: player,
                    actorId: interaction.agentId,
                    expectedAction: interaction.action,
                    interactionPrefix: "g2",
                    session: &session
                )
                lastInteractionSucceeded = true
                lastAutoInteractionReason = "automatic harvest succeeded"
            }
            let deliveryActions = result.agents
                .filter { $0.action.name == "deliver_resource" }
                .sorted { $0.agentId < $1.agentId }
            if let delivery = deliveryActions.first {
                guard economyAutoEnabled else {
                    throw ControllerError.interactionBoundary("delivery action without automatic economy")
                }
                let actor = session.snapshot().agents.first { $0.id == delivery.agentId }!
                let deliveryId = "economy-delivery:\(delivery.agentId):\(session.tick)"
                let outcome = try session.deliverResources(AgentDeliveryIntent(
                    deliveryId: deliveryId,
                    agentId: delivery.agentId,
                    tick: session.tick,
                    position: actor.position
                ))
                lastDeliverySucceeded = outcome.status == .succeeded
                lastEconomyReason = outcome.reason
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
                let funded = try session.fundConstructionProject(
                    fundingId: "construction-funding:\(funding.agentId):\(session.tick)",
                    builderAgentId: funding.agentId,
                    fundingTick: session.tick
                )
                lastConstructionReason = "funded \(funded.projectId)"
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
                      }) else {
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
                    reason: "ordered fixed blueprint cell placed"
                )
                var candidate = session
                let occupied = session.snapshot().agents
                    .filter { $0.id != placement.agentId }
                    .map(\.position)
                let playerPosition = AgentPosition(
                    x: Int(player.x.rounded(.down)),
                    y: Int(player.y.rounded(.down)),
                    z: Int(player.z.rounded(.down))
                )
                let navigationAdapter = self.navigationAdapter
                let injectPublicationFailure = environment[
                    "PEBBLELAB_APP_AGENTS_BUILD_FAIL_AFTER_WORLD"
                ] == "1"
                do {
                    try constructionExecutor.place(
                    world: world,
                    actor: actor,
                    project: project,
                    intent: intent,
                    occupiedAgentPositions: occupied,
                    playerPosition: playerPosition,
                    buildGateEnabled: buildFeatureEnabled,
                    buildAutoEnabled: session.buildAutoEnabled,
                    prevalidate: {
                        try session.prevalidatePlacement(intent)
                    },
                    publishAndVerify: { finalCell in
                        try candidate.applyPlacementOutcome(outcome)
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
                            try candidate.completeConstructionProject(
                                projectId: pending.projectId,
                                completionTick: candidate.tick
                            )
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
                    let failure = constructionFailure(for: error)
                    try? session.recordConstructionFailure(
                        failureId: "construction-failure:\(intent.placementId)",
                        projectId: project.projectId,
                        builderAgentId: project.builderAgentId,
                        failure: failure,
                        reason: String(describing: error)
                    )
                    throw error
                }
                session = candidate
                lastConstructionReason = "placed cell \(cell.index) \(cell.resource.rawValue)"
            }
            if movementEnabled {
                let outcomes = AgentMovementCoordinator.resolve(snapshot: session.snapshot())
                try session.applyMovementOutcomes(outcomes)
                let finalSnapshot = session.snapshot()
                try movementExecutor.apply(
                    outcomes: outcomes,
                    probesByAgentId: probesByAgentId,
                    postApplyValidation: {
                        try validatePostTick(snapshot: finalSnapshot, result: result)
                    }
                )
                lastMovementOutcomes = outcomes
            } else {
                lastMovementOutcomes = []
                try validatePostTick(snapshot: session.snapshot(), result: result)
            }
            let finalSnapshot = session.snapshot()
            self.session = session
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
            trace("error \(error)")
            return false
        }
    }

    func validatePostTick(snapshot: AgentSessionSnapshot, result: AgentSessionTickResult) throws {
        var positions = Set<String>()
        for agent in snapshot.agents {
            guard agent.lastWorldObservation != nil,
                  agent.lastWorldPerceptionEffect != nil,
                  agent.observationCount >= result.tick,
                  positions.insert(positionText(agent.position)).inserted,
                  let probe = probesByAgentId[agent.id],
                  probe.labAgentId == agent.id,
                  probe.x == Double(agent.position.x) + 0.5,
                  probe.y == Double(agent.position.y),
                  probe.z == Double(agent.position.z) + 0.5 else {
                throw ControllerError.movementBoundary(agent.id)
            }
            guard agent.memoryCount <= 128,
                  agent.memoryRetrievalCount >= agent.memoryInfluencedDecisionCount,
                  let decision = agent.lastFeedbackDecisionTrace else {
                throw ControllerError.feedbackBoundary(agent.id)
            }
            if !decision.memoryRecordsUsed.isEmpty {
                guard decision.actionChanged,
                      decision.dominantFactor.kind == .movementFeedback else {
                    throw ControllerError.feedbackBoundary(agent.id)
                }
            }
            let movementBoundary = snapshot.buildAutoEnabled
                    && snapshot.constructionProject?.builderAgentId == agent.id
                    && (snapshot.constructionProject?.status == .planned
                        || snapshot.constructionProject?.status == .acquiringMaterials)
                ? AgentConstructionMaterialSurvey.maximumDistanceFromHome
                : AgentNavigationObservation.maximumRadius
            if movementEnabled, agent.distanceFromHome > movementBoundary {
                throw ControllerError.feedbackBoundary(agent.id)
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
