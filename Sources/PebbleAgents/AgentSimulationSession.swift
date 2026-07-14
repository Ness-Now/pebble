public struct AgentSimulationSession {
    public static let maximumConsumptionCount = AgentSurvivalProgress.maximumEventCount
    public static let maximumConstructionEventCount = 64
    public static let maximumFailedNaturalResourceTargetsPerAgent = 16
    public let configuration: AgentSessionConfiguration
    public private(set) var tick: Int
    var statesById: [String: AgentSessionAgentState]
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

    public init(
        configuration: AgentSessionConfiguration,
        agents: [AgentSessionAgentState],
        initialTick: Int = 0
    ) throws {
        guard initialTick >= 0 else {
            throw AgentSessionError.invalidInitialTick(initialTick)
        }
        var states: [String: AgentSessionAgentState] = [:]
        for var agent in agents {
            guard states[agent.id] == nil else {
                throw AgentSessionError.duplicateAgentId(agent.id)
            }
            applyMemoryPolicy(configuration.memoryPolicy, to: &agent.memory)
            states[agent.id] = agent
        }
        self.configuration = configuration
        tick = initialTick
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
        guard let state = statesById[agentId] else {
            throw AgentSessionError.unknownAgentId(agentId)
        }
        return state
    }

    public mutating func setEconomyEnabled(_ enabled: Bool) {
        economyEnabled = enabled
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
        naturalResourcesEnabled = enabled
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
        survivalEnabled = enabled
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
        var perceptionsById: [String: AgentPerceptionInput] = [:]
        var resourceObservationsById: [String: [AgentResourceObservation]] = [:]
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

        let nextTick = tick + 1
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
                    : nil
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

        tick = nextTick
        return AgentSessionTickResult(tick: tick, agents: results)
    }

}
