public struct AgentSimulationSession {
    public static let maximumConsumptionCount = AgentSurvivalProgress.maximumEventCount
    public static let maximumConstructionEventCount = 64
    public static let maximumFailedNaturalResourceTargetsPerAgent = 16
    public let configuration: AgentSessionConfiguration
    public private(set) var clock: AgentSimulationClock
    public var simulationID: AgentSimulationID { clock.simulationID }
    public var simulationInstant: AgentSimulationInstant { clock.instant }
    public var tick: Int { clock.tick.rawValue }
    var statesById: AgentStateStore
    var processedInteractionIds: Set<String>
    var creditedResourceKeys: Set<String>
    var reservationsByTarget: [String: AgentResourceReservation]
    var failedNaturalResourceTargetKeysByAgentId: [String: [String]]
    public private(set) var economyEnabled: Bool
    public private(set) var naturalResourcesEnabled: Bool
    public internal(set) var campStock: AgentCampStock
    var harvestedResourceTotals: AgentCampStock
    var processedDeliveryIds: Set<String>
    public private(set) var survivalEnabled: Bool
    var consumedResourceTotals: AgentCampStock
    var processedConsumptionIds: Set<String>
    public internal(set) var buildAutoEnabled: Bool
    public internal(set) var constructionProject: AgentConstructionProject?
    var processedConstructionFundingIds: Set<String>
    var processedConstructionPlacementIds: Set<String>
    var processedConstructionFailureIds: Set<String>
    var lastConstructionPlacementTick: Int?
    var causalLedger: AgentCausalLedger
    var lastPerceptionEventByAgentID: [AgentID: AgentCausalEventID]
    var lastDecisionEventByAgentID: [AgentID: AgentCausalEventID]
    var lastOutcomeEventByAgentID: [AgentID: AgentCausalEventID]
    var lastConstructionEventID: AgentCausalEventID?
    public internal(set) var socialEnabled: Bool
    var socialFacts: [AgentSocialFact]
    var socialMessages: [AgentSocialMessage]
    var socialBeliefs: [AgentSocialBelief]
    var socialTrustRelations: [AgentTrustRelation]
    var activeSocialVerificationByAgentId: [String: AgentSocialBeliefID]
    var lastSocialShareTickByAgentId: [String: Int]
    var socialEvictionCounts: AgentSocialEvictionCounts

    public init(
        configuration: AgentSessionConfiguration,
        agents: [AgentSessionAgentState],
        initialTick: Int = 0,
        simulationID: AgentSimulationID? = nil,
        causalLedgerPolicy: AgentCausalLedgerPolicy = .disabled
    ) throws {
        guard initialTick >= 0 else {
            throw AgentSessionError.invalidInitialTick(initialTick)
        }
        var states = AgentStateStore()
        for var agent in agents {
            guard states[agent.id] == nil else {
                throw AgentSessionError.duplicateAgentId(agent.id)
            }
            applyMemoryPolicy(configuration.memoryPolicy, to: &agent.memory)
            states[agent.id] = agent
        }
        self.configuration = configuration
        clock = AgentSimulationClock(
            simulationID: simulationID ?? .legacy(seed: configuration.seed),
            initialTick: AgentSimulationTick(rawValue: initialTick)!
        )
        statesById = states
        processedInteractionIds = []
        creditedResourceKeys = []
        reservationsByTarget = [:]
        failedNaturalResourceTargetKeysByAgentId = [:]
        economyEnabled = false
        naturalResourcesEnabled = false
        campStock = AgentCampStock(capacity: configuration.campStockCapacity)
        harvestedResourceTotals = AgentCampStock(capacity: 4096)
        processedDeliveryIds = []
        survivalEnabled = false
        consumedResourceTotals = AgentCampStock(capacity: 4096)
        processedConsumptionIds = []
        buildAutoEnabled = false
        constructionProject = nil
        processedConstructionFundingIds = []
        processedConstructionPlacementIds = []
        processedConstructionFailureIds = []
        lastConstructionPlacementTick = nil
        causalLedger = try AgentCausalLedger(policy: causalLedgerPolicy)
        lastPerceptionEventByAgentID = [:]
        lastDecisionEventByAgentID = [:]
        lastOutcomeEventByAgentID = [:]
        lastConstructionEventID = nil
        socialEnabled = false
        socialFacts = []
        socialMessages = []
        socialBeliefs = []
        socialTrustRelations = []
        activeSocialVerificationByAgentId = [:]
        lastSocialShareTickByAgentId = [:]
        socialEvictionCounts = AgentSocialEvictionCounts()
        try recordCausalEvent(
            kind: .sessionLifecycle,
            origin: .lifecycle,
            payload: .lifecycle(status: "created", agentCount: states.count),
            summary: "session created agents=\(states.count)"
        )
    }

    public func causalLedgerSnapshot(tail limit: Int? = nil) -> AgentCausalLedgerSnapshot {
        causalLedger.snapshot(instant: simulationInstant, tail: limit)
    }

    public func identitySnapshot() -> AgentSimulationIdentitySnapshot {
        AgentSimulationIdentitySnapshot(
            simulationID: simulationID,
            agentIDs: statesById.values.map(\.agentID)
        )
    }

    public func snapshot() -> AgentSessionSnapshot {
        let agents = sortedIds.compactMap { id in
            statesById[id].map {
                AgentSnapshot(
                    state: $0,
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit,
                    resourceReservation: reservation(for: $0),
                    survivalEnabled: survivalEnabled
                )
            }
        }
        return AgentSessionSnapshot(
            seed: configuration.seed,
            tick: tick,
            agents: agents,
            resourceReservations: reservationsByTarget.values.sorted(by: reservationSort),
            economyEnabled: economyEnabled,
            naturalResourcesEnabled: naturalResourcesEnabled,
            deliveryQuota: configuration.deliveryQuota,
            campStock: campStock,
            conservation: conservationSnapshot(),
            survivalEnabled: survivalEnabled,
            survivalConfiguration: configuration.survivalConfiguration,
            buildAutoEnabled: buildAutoEnabled,
            constructionProject: constructionProject
        )
    }

    public func state(for agentId: String) throws -> AgentSessionAgentState {
        guard let agentID = AgentID(rawValue: agentId) else {
            throw AgentSessionError.unknownAgentId(agentId)
        }
        return try state(for: agentID)
    }

    public func state(for agentID: AgentID) throws -> AgentSessionAgentState {
        guard let state = statesById[agentID.rawValue] else {
            throw AgentSessionError.unknownAgentId(agentID.rawValue)
        }
        return state
    }

    public mutating func setEconomyEnabled(_ enabled: Bool) {
        let changed = economyEnabled != enabled
        economyEnabled = enabled
        defer { if changed { recordFeatureToggle(name: "economy", enabled: enabled) } }
        guard !enabled else { return }
        reservationsByTarget.removeAll()
        for id in sortedIds {
            guard var state = statesById[id] else { continue }
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress()
            if state.currentGoal.kind == .deliverResources {
                state.currentGoal = AgentGoal(
                    kind: .idle,
                    reason: "economy disabled",
                    startedAtTick: tick,
                    urgency: 0
                )
            }
            statesById[id] = state
        }
    }

    public mutating func setNaturalResourcesEnabled(_ enabled: Bool) {
        let changed = naturalResourcesEnabled != enabled
        naturalResourcesEnabled = enabled
        defer { if changed { recordFeatureToggle(name: "naturalResources", enabled: enabled) } }
        guard !enabled else { return }
        failedNaturalResourceTargetKeysByAgentId.removeAll()
        reservationsByTarget = reservationsByTarget.filter { $0.value.source != .naturalWorld }
        for id in sortedIds {
            guard var state = statesById[id],
                  state.activeResourceTarget?.source == .naturalWorld else { continue }
            state.activeResourceTarget = nil
            state.navigationProgress = AgentNavigationProgress(
                lastInvalidation: .targetGone
            )
            statesById[id] = state
        }
    }

    public mutating func setSurvivalEnabled(_ enabled: Bool) {
        let changed = survivalEnabled != enabled
        survivalEnabled = enabled
        defer { if changed { recordFeatureToggle(name: "survival", enabled: enabled) } }
        for id in sortedIds {
            guard var state = statesById[id] else { continue }
            if enabled {
                if state.survivalProgress == nil {
                    state.survivalProgress = AgentSurvivalProgress()
                }
            } else {
                if state.currentGoal.kind == .satisfyHunger {
                    releaseReservation(for: state)
                    state.activeResourceTarget = nil
                    state.navigationProgress = AgentNavigationProgress()
                } else if state.currentGoal.kind == .rest,
                          state.navigationProgress.route?.purpose == .homeRest {
                    state.navigationProgress = AgentNavigationProgress()
                }
                if state.currentGoal.kind == .satisfyHunger || state.currentGoal.kind == .rest {
                    state.currentGoal = AgentGoal(
                        kind: .idle,
                        reason: "survival disabled",
                        startedAtTick: tick,
                        urgency: 0
                    )
                }
                state.survivalProgress = nil
            }
            statesById[id] = state
        }
    }

    public mutating func advanceTick(
        perceptions: [AgentPerceptionInput] = []
    ) throws -> AgentSessionTickResult {
        try prevalidateCausalAppend(count: sortedIds.count * (socialEnabled ? 20 : 3) + 1)
        var perceptionsById: [String: AgentPerceptionInput] = [:]
        var resourceObservationsById: [String: [AgentResourceObservation]] = [:]
        var socialResourceObservationsById: [String: [AgentResourceObservation]] = [:]
        for perception in perceptions {
            guard statesById[perception.agentId] != nil else {
                throw AgentSessionError.unknownAgentId(perception.agentId)
            }
            guard perceptionsById[perception.agentId] == nil else {
                throw AgentSessionError.duplicatePerceptionInput(perception.agentId)
            }
            if let observation = perception.worldObservation,
               observation.position != statesById[perception.agentId]?.position {
                throw AgentSessionError.worldObservationPositionMismatch(perception.agentId)
            }
            if let position = statesById[perception.agentId]?.position {
                resourceObservationsById[perception.agentId] = try AgentResourcePerception.normalize(
                    observerPosition: position,
                    observations: perception.resourceObservations,
                    maximumDistance: configuration.resourceObservationRadius
                )
                if socialEnabled {
                    socialResourceObservationsById[perception.agentId] = try AgentResourcePerception.normalize(
                        observerPosition: position,
                        observations: perception.socialResourceObservations,
                        maximumDistance: configuration.resourceObservationRadius
                    )
                }
            }
            if let navigation = perception.navigationObservation {
                guard navigation.origin == statesById[perception.agentId]?.position,
                      (1...AgentNavigationObservation.maximumRadius).contains(navigation.radius),
                      navigation.cells.count <= AgentNavigationObservation.maximumCellCount else {
                    throw AgentSessionError.invalidNavigationObservation(perception.agentId)
                }
            }
            perceptionsById[perception.agentId] = perception
        }

        let nextSimulationTick = try clock.nextTick()
        let nextTick = nextSimulationTick.rawValue
        let ids = sortedIds
        refreshConstructionProjectStatus()
        reservationsByTarget = reservationsByTarget.filter { !$0.value.isExpired(at: nextTick) }
        for id in ids {
            guard var state = statesById[id] else { continue }
            let previousTarget = state.activeResourceTarget
            state.lastResourceObservations = resourceObservationsById[id] ?? []
            if shouldSatisfyHunger(state, projectedToNextTick: true) {
                let foodObservations = state.lastResourceObservations.filter {
                    $0.resource == .foodRaw
                }
                state.activeResourceTarget = state.resourceInventory.count(of: .foodRaw) > 0
                    ? nil
                    : AgentResourceTargeting.select(
                        current: previousTarget?.resource == .foodRaw ? previousTarget : nil,
                        observations: foodObservations,
                        inventory: state.resourceInventory,
                        tick: nextTick
                    )
            } else if shouldRest(state, projectedToNextTick: true) {
                state.activeResourceTarget = nil
            } else if shouldDeliverResources(state) {
                state.activeResourceTarget = nil
            } else if isFundedConstructionBuilder(state) {
                state.activeResourceTarget = nil
            } else if survivalEnabled && !economyEnabled {
                state.activeResourceTarget = nil
            } else {
                let failedKeys = Set(
                    failedNaturalResourceTargetKeysByAgentId[id] ?? []
                )
                let selectableObservations = state.lastResourceObservations.filter {
                    !failedKeys.contains($0.identity.stableKey)
                }
                state.activeResourceTarget = AgentResourceTargeting.select(
                    current: previousTarget,
                    observations: selectableObservations,
                    inventory: state.resourceInventory,
                    tick: nextTick,
                    eligibleResources: constructionEligibleResources(for: state)
                )
            }
            if let previousTarget,
               state.activeResourceTarget?.identity != previousTarget.identity {
                state.navigationProgress = AgentNavigationProgress(
                    replanCount: 0,
                    lastInvalidation: state.activeResourceTarget == nil ? .targetGone : .targetChanged
                )
            }
            statesById[id] = state
        }
        reconcileReservations(at: nextTick)
        let peers = ids.compactMap { id in
            statesById[id].map { AgentPeerSnapshot(id: id, position: $0.position) }
        }
        let socialPlan = prepareSocialTick(at: nextTick)
        var results: [AgentSessionAgentTickResult] = []

        for id in ids {
            guard var state = statesById[id] else { continue }
            let perception = perceptionsById[id]
            var memoriesAdded = perception?.externalMemoryEntries ?? []

            let survivalMemory: AgentMemoryEntry?
            if survivalEnabled {
                survivalMemory = applySurvivalTick(to: &state, tick: nextTick)
            } else {
                let hungerBeforeConstructionTick = state.needs.hunger
                let tickTransition = AgentCognitiveTransitions.advanceTick(needs: state.needs)
                state.needs = tickTransition.needs
                if buildAutoEnabled,
                   constructionProject?.builderAgentId == state.id {
                    // Build validation deliberately keeps survival disabled while
                    // legacy fatigue accumulates. Deferring hunger prevents an
                    // off-mode counter from pre-empting the explicit post-build
                    // rest proof when survival is enabled.
                    state.needs.hunger = hungerBeforeConstructionTick
                }
                state.state = tickTransition.state
                survivalMemory = nil
            }
            state.ticksAlive += 1

            appendMemories(memoriesAdded, to: &state.memory)
            if let survivalMemory {
                appendMemory(survivalMemory, to: &state.memory)
                memoriesAdded.append(survivalMemory)
            }
            var worldPerceptionEffect: AgentWorldPerceptionEffect?
            if let observation = perception?.worldObservation {
                let effect = AgentWorldPerceptionInterpreter.interpret(
                    agentId: id,
                    tick: nextTick,
                    observation: observation,
                    needs: state.needs,
                    fear: state.fear
                )
                state.lastWorldObservation = observation
                state.lastWorldPerceptionEffect = effect
                state.needs.safety = effect.safetyAfter
                state.needs.curiosity = effect.curiosityAfter
                state.fear = effect.fearAfter
                state.observationCount += 1
                let worldMemory = AgentMemoryEntry(
                    tick: nextTick,
                    type: "world_observed",
                    summary: effect.memorySummary,
                    importance: effect.memoryImportance
                )
                appendMemory(worldMemory, to: &state.memory)
                memoriesAdded.append(worldMemory)
                worldPerceptionEffect = effect
            }
            state.observationCount += perception?.observationCountIncrement ?? 0

            state.nearbyAgents = AgentCognitiveTransitions.observeNearbyAgents(
                observerId: id,
                observerPosition: state.position,
                peers: peers,
                radius: configuration.nearbyRadius
            )
            state.nearbyObservationCount += state.nearbyAgents.count

            state.goalSelectionCount += 1
            let goalChange = AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
                tick: nextTick,
                health: state.health,
                fear: state.fear,
                needs: state.needs,
                hasNearbyAgents: !state.nearbyAgents.isEmpty,
                hasCollectibleAdjacentResource: state.activeResourceTarget != nil,
                hasInventoryCapacity: state.activeResourceTarget.map {
                    state.resourceInventory.canAdd($0.resource)
                } ?? (constructionEligibleResources(for: state)?.contains(where: {
                    state.resourceInventory.canAdd($0)
                }) == true),
                hasCommittedResourceTask: ((state.currentGoal.kind == .collectResource
                    || state.currentGoal.kind == .satisfyHunger)
                    && reservation(for: state)?.agentId == id)
                    || constructionEligibleResources(for: state)?.isEmpty == false,
                shouldDeliverResources: shouldDeliverResources(state),
                shouldBuildShelter: shouldBuildShelter(state),
                hasConstructionTask: hasActiveConstructionTask(state),
                canShareInformation: socialPlan.shareIntentsByAgentId[id] != nil,
                canVerifySocialInformation: socialPlan.verificationBeliefsByAgentId[id] != nil,
                currentGoalKind: state.currentGoal.kind,
                survivalEnabled: survivalEnabled,
                hungryThreshold: configuration.survivalConfiguration.hungryThreshold,
                criticalHungerThreshold: configuration.survivalConfiguration.criticalHungerThreshold,
                hungerRecoveryThreshold: configuration.survivalConfiguration.hungerRecoveryThreshold,
                fatigueThreshold: configuration.survivalConfiguration.fatigueThreshold,
                fatigueRecoveryThreshold: configuration.survivalConfiguration.fatigueRecoveryThreshold
            ))
            if let goalChange {
                state.currentGoal = goalChange.goal
                state.goalChangeCount += 1
            }

            activateSocialVerification(
                agentId: id,
                candidate: socialPlan.verificationBeliefsByAgentId[id],
                selectedGoal: state.currentGoal.kind
            )

            updateNavigation(
                state: &state,
                observation: perception?.navigationObservation,
                tick: nextTick
            )

            let baseAction = AgentActionDecider.decide(AgentActionDecisionInput(
                agentId: id,
                tick: nextTick,
                goalKind: state.currentGoal.kind,
                position: state.position,
                homePosition: state.homePosition,
                resourceObservations: state.lastResourceObservations,
                activeResourceTarget: state.activeResourceTarget,
                navigationProgress: state.navigationProgress,
                resourceReservation: reservation(for: state),
                survivalEnabled: survivalEnabled,
                hasFoodRaw: state.resourceInventory.count(of: .foodRaw) > 0,
                constructionProject: constructionProject?.builderAgentId == id
                    ? constructionProject
                    : nil,
                socialVerificationTarget: socialVerificationRequest(
                    candidate: socialPlan.verificationBeliefsByAgentId[id],
                    for: id
                )?.position,
                socialVerificationResource: socialVerificationRequest(
                    candidate: socialPlan.verificationBeliefsByAgentId[id],
                    for: id
                )?.resource
            ))
            let retrievedMemories = AgentFeedbackLoop.retrieveMovementMemories(
                memory: state.memory,
                currentTick: nextTick,
                lastMovementOutcome: state.lastMovementOutcome,
                configuration: configuration.feedbackLoopConfiguration
            )
            if !retrievedMemories.isEmpty {
                state.memoryRetrievalCount += 1
            }
            let decisionTrace = AgentFeedbackLoop.adjustAction(
                agentId: id,
                tick: nextTick,
                position: state.position,
                homePosition: state.homePosition,
                goal: state.currentGoal,
                baseAction: baseAction,
                worldObservation: state.lastWorldObservation,
                occupiedPositions: peers.map(\.position),
                lastMovementOutcome: state.lastMovementOutcome,
                retrievedMemories: retrievedMemories,
                configuration: configuration.feedbackLoopConfiguration
            )
            let action = decisionTrace.finalAction
            state.lastFeedbackDecisionTrace = decisionTrace
            if decisionTrace.actionChanged && !decisionTrace.memoryRecordsUsed.isEmpty {
                state.memoryInfluencedDecisionCount += 1
            }
            state.lastAction = action
            state.actionCount += 1
            let actionMemory = AgentMemoryEntry(
                tick: nextTick,
                type: "action_chosen",
                summary: "\(id) chose \(action.name) because \(action.reason)",
                importance: 0.2
            )
            appendMemory(actionMemory, to: &state.memory)
            memoriesAdded.append(actionMemory)

            let effectResult = AgentCognitiveTransitions.applyActionEffect(AgentActionEffectInput(
                action: action,
                goalKind: state.currentGoal.kind,
                distanceFromHome: distanceFromHome(state),
                needs: state.needs,
                fear: state.fear,
                state: state.state,
                tick: nextTick,
                survivalEnabled: survivalEnabled,
                restRecoveryPerTick: configuration.survivalConfiguration.restRecoveryPerTick
            ))
            state.needs = effectResult.needs
            state.fear = effectResult.fear
            state.state = effectResult.state
            state.lastActionEffect = effectResult.actionEffect
            state.actionEffectCount += 1
            if survivalEnabled {
                updateSurvivalProgress(for: &state, action: action)
            }
            let effectMemory = AgentMemoryEntry(
                tick: nextTick,
                type: "action_effect_applied",
                summary: "\(id) applied \(action.name) effect",
                importance: 0.15
            )
            appendMemory(effectMemory, to: &state.memory)
            memoriesAdded.append(effectMemory)

            statesById[id] = state
            results.append(AgentSessionAgentTickResult(
                agentId: id,
                goalChange: goalChange,
                action: action,
                actionEffect: effectResult.actionEffect,
                memoriesAdded: memoriesAdded,
                worldPerceptionEffect: worldPerceptionEffect,
                snapshot: AgentSnapshot(
                    state: state,
                    recentMemoryLimit: configuration.recentMemorySnapshotLimit,
                    resourceReservation: reservation(for: state),
                    survivalEnabled: survivalEnabled
                )
            ))
        }

        clock.advance(to: nextSimulationTick)
        for result in results {
            let agentID = AgentID(rawValue: result.agentId)!
            let perceptionEvent = try recordCausalEvent(
                kind: .perception,
                origin: .externalObservation,
                actorID: agentID,
                subjectID: agentID,
                payload: .perception(
                    worldObserved: result.worldPerceptionEffect != nil,
                    resourceObservationCount: result.snapshot.lastResourceObservations.count
                        + (socialResourceObservationsById[result.agentId]?.count ?? 0),
                    memoriesAdded: result.memoriesAdded.count
                ),
                summary: "perception accepted actor=\(result.agentId) resources=\(result.snapshot.lastResourceObservations.count + (socialResourceObservationsById[result.agentId]?.count ?? 0))"
            )
            if let eventID = perceptionEvent?.eventID {
                lastPerceptionEventByAgentID[agentID] = eventID
                try recordGroundedSocialFacts(
                    observerID: agentID,
                    observations: (result.snapshot.lastResourceObservations
                        + (socialResourceObservationsById[result.agentId] ?? []))
                        .sorted(by: AgentResourcePerception.sortsBefore),
                    perceptionEventID: eventID,
                    at: tick
                )
            }
            var actionCause = perceptionEvent?.eventID
            if let goalChange = result.goalChange {
                let goalEvent = try recordCausalEvent(
                    kind: .goalTransition,
                    origin: .cognitiveTransition,
                    actorID: agentID,
                    causes: perceptionEvent.map { [$0.eventID] } ?? [],
                    payload: .cognitive(
                        goal: goalChange.to.rawValue,
                        action: "none",
                        goalChanged: true
                    ),
                    summary: "goal actor=\(result.agentId) \(goalChange.from.rawValue)>\(goalChange.to.rawValue)"
                )
                actionCause = goalEvent?.eventID
            }
            let decisionEvent = try recordCausalEvent(
                kind: .actionSelected,
                origin: .cognitiveTransition,
                actorID: agentID,
                causes: actionCause.map { [$0] } ?? [],
                payload: .cognitive(
                    goal: result.snapshot.currentGoal.kind.rawValue,
                    action: result.action.name,
                    goalChanged: result.goalChange != nil
                ),
                summary: "action actor=\(result.agentId) goal=\(result.snapshot.currentGoal.kind.rawValue) action=\(result.action.name)"
            )
            if let eventID = decisionEvent?.eventID {
                lastDecisionEventByAgentID[agentID] = eventID
            }
        }
        try applySocialTickPlan(socialPlan, results: results)
        try recordCausalEvent(
            kind: .tickCompleted,
            origin: .cognitiveTransition,
            payload: .lifecycle(status: "tickCompleted", agentCount: results.count),
            summary: "tick \(tick) completed agents=\(results.count)"
        )
        return AgentSessionTickResult(tick: tick, agents: results)
    }

}
