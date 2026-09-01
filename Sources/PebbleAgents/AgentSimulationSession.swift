public struct AgentSimulationSession {
    public static let maximumConsumptionCount = AgentSurvivalProgress.maximumEventCount
    public static let maximumConstructionEventCount = 64
    public static let maximumFailedNaturalResourceTargetsPerAgent = 16
    public let configuration: AgentSessionConfiguration
    public internal(set) var clock: AgentSimulationClock
    public var simulationID: AgentSimulationID { clock.simulationID }
    public var simulationInstant: AgentSimulationInstant { clock.instant }
    public var tick: Int { clock.tick.rawValue }
    var statesById: AgentStateStore
    var processedInteractionIds: Set<String>
    var creditedResourceKeys: Set<String>
    var reservationsByTarget: [String: AgentResourceReservation]
    var failedNaturalResourceTargetKeysByAgentId: [String: [String]]
    public internal(set) var economyEnabled: Bool
    public internal(set) var naturalResourcesEnabled: Bool
    public internal(set) var campStock: AgentCampStock
    var harvestedResourceTotals: AgentCampStock
    var processedDeliveryIds: Set<String>
    public internal(set) var survivalEnabled: Bool
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
    public internal(set) var knowledgeGraphState: AgentKnowledgeGraphState?
    public internal(set) var physicalEnabled: Bool
    var physicalSignals: [AgentPhysicalSignal]
    var physicalPerceptions: [AgentPhysicalPerception]
    var physicalPresentationRequests: [AgentPhysicalPresentationRequest]
    var physicalEvictionCounts: AgentPhysicalEvictionCounts
    public internal(set) var cooperationEnabled: Bool
    var sharedTasks: [AgentSharedTask]
    var sharedTaskOffers: [AgentSharedTaskOffer]
    var cooperationRelations: [AgentCooperationRelation]
    var cooperationEvictionCounts: AgentCooperationEvictionCounts
    var lastCooperationOfferTickByIssuerID: [String: Int]
    public internal(set) var populationRegistry: AgentPopulationRegistry?
    public internal(set) var settlementMetricsState: AgentSettlementMetricsState?
    public internal(set) var localEcologyState: AgentLocalEcologyState?
    public internal(set) var mortalityState: AgentMortalityState?
    public internal(set) var lifecycleState: AgentLifecycleState?
    public internal(set) var kinshipState: AgentKinshipState?
    public internal(set) var householdState: AgentHouseholdState?
    public internal(set) var dependentCareState: AgentDependentCareState?
    public internal(set) var skillState: AgentSkillState?
    public internal(set) var teachingState: AgentTeachingState?
    public internal(set) var ecologicalObservationState: AgentEcologicalObservationState?
    public internal(set) var agricultureState: AgentAgricultureState?
    public internal(set) var wildSubsistenceState: AgentWildSubsistenceState?
    public internal(set) var livestockState: AgentLivestockState?
    public internal(set) var workCommitmentState: AgentWorkCommitmentState?
    public internal(set) var physicalFoodSurvivalState: AgentPhysicalFoodSurvivalState?
    public internal(set) var autonomousActivityState: AgentAutonomousActivityState?
    public internal(set) var materialRightsState: AgentMaterialRightsState?
    public internal(set) var persistenceReconciliationState:
        AgentPersistenceReconciliationState?
    public internal(set) var homeostasisState: AgentHomeostasisState?
    public internal(set) var geneticsState: AgentGeneticsState?
    public internal(set) var familyState: AgentFamilyState?
    public internal(set) var estateState: AgentEstateState?
    public internal(set) var productionState: AgentProductionState?
    public internal(set) var barterState: AgentBarterState?
    public internal(set) var contractState: AgentContractState?
    public internal(set) var marketState: AgentMarketState?
    var latestAutonomousTeachingReview: AgentAutonomousTeachingReviewSnapshot?
    // Runtime-only compatibility marker. A schema 23 childhood checkpoint
    // remains byte-identical until the first schema 24 supervision-progress
    // mutation; it is never a second durable authority.
    var durableSchemaVersionOverride: Int?

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
        knowledgeGraphState = nil
        physicalEnabled = false
        physicalSignals = []
        physicalPerceptions = []
        physicalPresentationRequests = []
        physicalEvictionCounts = AgentPhysicalEvictionCounts()
        cooperationEnabled = false
        sharedTasks = []
        sharedTaskOffers = []
        cooperationRelations = []
        cooperationEvictionCounts = AgentCooperationEvictionCounts()
        lastCooperationOfferTickByIssuerID = [:]
        populationRegistry = nil
        settlementMetricsState = nil
        localEcologyState = nil
        mortalityState = nil
        lifecycleState = nil
        kinshipState = nil
        householdState = nil
        dependentCareState = nil
        skillState = nil
        teachingState = nil
        ecologicalObservationState = nil
        agricultureState = nil
        wildSubsistenceState = nil
        livestockState = nil
        workCommitmentState = nil
        physicalFoodSurvivalState = nil
        autonomousActivityState = nil
        materialRightsState = nil
        persistenceReconciliationState = nil
        homeostasisState = nil
        geneticsState = nil
        familyState = nil
        estateState = nil
        productionState = nil
        barterState = nil
        contractState = nil
        marketState = nil
        latestAutonomousTeachingReview = nil
        durableSchemaVersionOverride = nil
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
                    survivalEnabled: survivalEnabled,
                    homeostasisProfile: AgentID(rawValue: id).flatMap {
                        homeostasisProfile(for: $0)
                    }
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
            constructionProject: constructionProject,
            population: populationRegistry == nil ? nil : populationSnapshot(),
            settlementMetrics: settlementMetricsState == nil ? nil : settlementMetricsSnapshot(),
            localEcology: localEcologyState == nil ? nil : localEcologySnapshot(),
            mortality: mortalityState == nil ? nil : mortalitySnapshot(),
            lifecycle: lifecycleState == nil ? nil : lifecycleSnapshot(),
            homeostasis: homeostasisState == nil ? nil : homeostasisSnapshot()
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
        guard enabled || (mortalityState == nil && physicalFoodSurvivalState == nil) else {
            return
        }
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
        perceptions: [AgentPerceptionInput] = [],
        physicalObservations: [AgentPhysicalSignalObservation] = []
    ) throws -> AgentSessionTickResult {
        var candidate = self
        let result = try candidate.advanceTickInPlace(
            perceptions: perceptions,
            physicalObservations: physicalObservations
        )
        self = candidate
        return result
    }

    private mutating func advanceTickInPlace(
        perceptions: [AgentPerceptionInput],
        physicalObservations: [AgentPhysicalSignalObservation]
    ) throws -> AgentSessionTickResult {
        if let pending = mortalityState?.pendingTransitions.first {
            throw AgentSessionError.mortality(
                .pendingMaterialExit(pending.agentID.rawValue)
            )
        }
        let nextSimulationTick = try clock.nextTick()
        let nextTick = nextSimulationTick.rawValue
        let execution = fidelityExecutionCounts(at: nextTick)
        let liveIDSet = Set(execution.live.map(\.rawValue))
        try prevalidateCausalAppend(
            count: execution.live.count
                * (physicalEnabled ? 30 : (socialEnabled ? 20 : 3)) + 1
                + (mortalityState?.configuration.maximumDeathsPerTick ?? 0) * 7
                + (dependentCareState?.configuration.maximumCareTransitionsPerTick ?? 0) * 3
                + (populationRegistry?.scaleState?.fidelityRecords.count ?? 0)
        )
        var perceptionsById: [String: AgentPerceptionInput] = [:]
        var resourceObservationsById: [String: [AgentResourceObservation]] = [:]
        var socialResourceObservationsById: [String: [AgentResourceObservation]] = [:]
        for perception in perceptions {
            guard statesById[perception.agentId] != nil,
                  populationRegistry?.scaleState == nil
                    || liveIDSet.contains(perception.agentId) else {
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

        let mortalityWasEnabled = mortalityState != nil
        var mortalitySurvivalMemories: [String: AgentMemoryEntry] = [:]
        if mortalityWasEnabled {
            var candidate = self
            candidate.clock.advance(to: nextSimulationTick)
            mortalitySurvivalMemories = try candidate.applyMortalitySurvivalBoundary(
                at: nextTick
            )
            self = candidate
        }
        try applyLifecycleStageBoundary(at: nextTick)
        if dependentCareState != nil, !mortalityWasEnabled, survivalEnabled {
            for id in sortedIds {
                guard var state = statesById[id] else { continue }
                if let memory = applySurvivalTick(to: &state, tick: nextTick) {
                    appendMemory(memory, to: &state.memory)
                    mortalitySurvivalMemories[id] = memory
                }
                state.ticksAlive += 1
                statesById[id] = state
            }
        }
        try applyDependentCareTickBoundary(at: nextTick)
        try applyEstateTickBoundary(at: nextTick)
        try expireActiveMigrationIfNeeded(at: nextTick)
        let ids = populationRegistry?.scaleState == nil
            ? sortedIds : execution.live.map(\.rawValue).sorted()
        refreshConstructionProjectStatus()
        reservationsByTarget = reservationsByTarget.filter { !$0.value.isExpired(at: nextTick) }
        for id in ids {
            guard var state = statesById[id] else { continue }
            let previousTarget = state.activeResourceTarget
            state.lastResourceObservations = resourceObservationsById[id] ?? []
            if isMigratingAgent(id) {
                state.activeResourceTarget = nil
            } else if shouldSatisfyHunger(state, projectedToNextTick: true) {
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
                    eligibleResources: cooperationEligibleResources(for: state)
                        ?? constructionEligibleResources(for: state)
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
        var socialPlan = prepareSocialTick(at: nextTick)
        let cooperationPlan = prepareCooperationTick(at: nextTick)
        let terminalCooperationHelperIDs = prepareAgentsForTerminalCooperationTransitions(
            cooperationPlan,
            at: nextTick
        )
        if let proposal = cooperationPlan.proposal {
            socialPlan.shareIntentsByAgentId[proposal.task.issuerID.rawValue] = proposal.shareIntent
        }
        var results: [AgentSessionAgentTickResult] = []

        for id in ids {
            guard var state = statesById[id] else { continue }
            let cooperationTransitionPending = terminalCooperationHelperIDs.contains(id)
            let perception = perceptionsById[id]
            var memoriesAdded = perception?.externalMemoryEntries ?? []

            let survivalMemory: AgentMemoryEntry?
            if mortalityWasEnabled || dependentCareState != nil {
                survivalMemory = mortalitySurvivalMemories[id]
            } else if survivalEnabled {
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
            if !mortalityWasEnabled && dependentCareState == nil { state.ticksAlive += 1 }

            appendMemories(memoriesAdded, to: &state.memory)
            if let survivalMemory {
                if !mortalityWasEnabled && dependentCareState == nil {
                    appendMemory(survivalMemory, to: &state.memory)
                }
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

            if isPhysiologicallyIncapacitated(state.agentID) {
                state.currentGoal = AgentGoal(
                    kind: .idle,
                    reason: "physiological incapacity prevents autonomous action",
                    startedAtTick: state.currentGoal.startedAtTick,
                    urgency: 100
                )
                state.lastAction = nil
                state.state = "incapacitated"
                let passiveAction = AgentAction(
                    name: "incapacitated_wait",
                    reason: "authoritative homeostasis limitation",
                    tick: nextTick
                )
                let passiveEffect = AgentActionEffect(
                    action: passiveAction.name,
                    effect: "no autonomous action while incapacitated",
                    tick: nextTick,
                    hungerBefore: state.needs.hunger,
                    hungerAfter: state.needs.hunger,
                    fatigueBefore: state.needs.fatigue,
                    fatigueAfter: state.needs.fatigue,
                    curiosityBefore: state.needs.curiosity,
                    curiosityAfter: state.needs.curiosity,
                    safetyBefore: state.needs.safety,
                    safetyAfter: state.needs.safety,
                    fearBefore: state.fear,
                    fearAfter: state.fear,
                    stateBefore: state.state,
                    stateAfter: state.state
                )
                statesById[id] = state
                results.append(AgentSessionAgentTickResult(
                    agentId: id,
                    goalChange: nil,
                    action: passiveAction,
                    actionEffect: passiveEffect,
                    memoriesAdded: memoriesAdded,
                    worldPerceptionEffect: worldPerceptionEffect,
                    snapshot: AgentSnapshot(
                        state: state,
                        recentMemoryLimit:
                            configuration.recentMemorySnapshotLimit,
                        resourceReservation: reservation(for: state),
                        survivalEnabled: survivalEnabled,
                        homeostasisProfile: homeostasisProfile(
                            for: state.agentID
                        )
                    ),
                    cognitionPerformed: false
                ))
                continue
            }

            let careStage = dependentCareState.flatMap { _ in
                lifecycleState?.members.first { $0.agentID.rawValue == id }?.currentStage
            }
            if careStage == .newborn {
                state.currentGoal = AgentGoal(
                    kind: .idle, reason: "newborn dependent; autonomous cognition disabled",
                    startedAtTick: state.currentGoal.startedAtTick, urgency: 0
                )
                state.lastAction = nil
                let passiveAction = AgentAction(
                    name: "dependent_wait", reason: "newborn dependent", tick: nextTick
                )
                let passiveEffect = AgentActionEffect(
                    action: passiveAction.name, effect: "no autonomous action", tick: nextTick,
                    hungerBefore: state.needs.hunger, hungerAfter: state.needs.hunger,
                    fatigueBefore: state.needs.fatigue, fatigueAfter: state.needs.fatigue,
                    curiosityBefore: state.needs.curiosity,
                    curiosityAfter: state.needs.curiosity,
                    safetyBefore: state.needs.safety, safetyAfter: state.needs.safety,
                    fearBefore: state.fear, fearAfter: state.fear,
                    stateBefore: state.state, stateAfter: state.state
                )
                statesById[id] = state
                results.append(AgentSessionAgentTickResult(
                    agentId: id, goalChange: nil, action: passiveAction,
                    actionEffect: passiveEffect, memoriesAdded: memoriesAdded,
                    worldPerceptionEffect: worldPerceptionEffect,
                    snapshot: AgentSnapshot(
                        state: state,
                        recentMemoryLimit: configuration.recentMemorySnapshotLimit,
                        resourceReservation: reservation(for: state),
                        survivalEnabled: survivalEnabled,
                        homeostasisProfile: homeostasisProfile(
                            for: state.agentID
                        )
                    ),
                    cognitionPerformed: false
                ))
                continue
            }

            state.goalSelectionCount += 1
            let goalChange: AgentGoalChange?
            if let forcedKind = dependentCareForcedGoal(for: state.agentID, stage: careStage) {
                if state.currentGoal.kind == forcedKind {
                    goalChange = nil
                } else {
                    goalChange = AgentGoalChange(
                        from: state.currentGoal.kind, to: forcedKind,
                        goal: AgentGoal(
                            kind: forcedKind,
                            reason: forcedKind == .provideDependentCare
                                ? "urgent dependent care engagement"
                                : "juvenile capability policy",
                            startedAtTick: nextTick,
                            urgency: forcedKind == .provideDependentCare ? 100 : 20
                        )
                    )
                }
            } else {
                let autonomousActivity = activeAutonomousActivity(for: state.agentID)
                goalChange = AgentCognitiveTransitions.selectGoal(AgentGoalSelectionInput(
                    tick: nextTick,
                    health: state.health,
                    fear: state.fear,
                    needs: state.needs,
                    hasNearbyAgents: !state.nearbyAgents.isEmpty,
                    hasCollectibleAdjacentResource: state.activeResourceTarget != nil
                        && cooperationPlan.proposal?.task.issuerID.rawValue != id,
                    hasInventoryCapacity: state.activeResourceTarget.map {
                        state.resourceInventory.canAdd($0.resource)
                    } ?? ((cooperationEligibleResources(for: state)
                        ?? constructionEligibleResources(for: state))?.contains(where: {
                        state.resourceInventory.canAdd($0)
                    }) == true),
                    hasCommittedResourceTask: (((state.currentGoal.kind == .collectResource
                        || state.currentGoal.kind == .satisfyHunger)
                        && reservation(for: state)?.agentId == id)
                        || constructionEligibleResources(for: state)?.isEmpty == false)
                        && cooperationPlan.proposal?.task.issuerID.rawValue != id,
                    shouldDeliverResources: shouldDeliverResources(state),
                    shouldBuildShelter: shouldBuildShelter(state),
                    hasConstructionTask: hasActiveConstructionTask(state)
                        || (hasActiveCooperationTask(state) && !cooperationTransitionPending),
                    canShareInformation: socialPlan.shareIntentsByAgentId[id] != nil,
                    canVerifySocialInformation: socialPlan.verificationBeliefsByAgentId[id] != nil,
                    hasActiveCooperationTask: hasActiveCooperationTask(state)
                        && !cooperationTransitionPending,
                    shouldConsiderCooperationOffer: shouldConsiderCooperationOffer(state)
                        && !cooperationTransitionPending,
                    canAcceptCooperationOffer: canAcceptCooperationOffer(state)
                        && !cooperationTransitionPending,
                    isMigrating: isMigratingAgent(id),
                    hasAutonomousActivity: autonomousActivity != nil,
                    autonomousActivityUrgency: autonomousActivity?.candidate.urgency ?? 0,
                    currentGoalKind: state.currentGoal.kind,
                    survivalEnabled: survivalEnabled,
                    hungryThreshold: configuration.survivalConfiguration.hungryThreshold,
                    criticalHungerThreshold: configuration.survivalConfiguration.criticalHungerThreshold,
                    hungerRecoveryThreshold: configuration.survivalConfiguration.hungerRecoveryThreshold,
                    fatigueThreshold: configuration.survivalConfiguration.fatigueThreshold,
                    fatigueRecoveryThreshold: configuration.survivalConfiguration.fatigueRecoveryThreshold
                ))
            }
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

            let careEngagement = activeCareEngagement(for: state.agentID)
            let careTargetPosition = careEngagement.flatMap {
                statesById[$0.dependentID.rawValue]?.position
            }
            let careActionName: String? = careEngagement.map {
                switch $0.kind {
                case .provideFood: return "provide_food"
                case .supervise: return "supervise_dependent"
                case .assistReturnHome: return "assist_return_home"
                case .approachDependent: return "supervise_dependent"
                }
            }
            let autonomousActivity = activeAutonomousActivity(for: state.agentID)
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
                hasFoodRaw: physicalFoodSurvivalState == nil
                    && state.resourceInventory.count(of: .foodRaw) > 0,
                physicalFoodAuthorityEnabled: physicalFoodSurvivalState != nil,
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
                )?.resource,
                canAcceptSharedTask: canAcceptCooperationOffer(state)
                    && !cooperationTransitionPending,
                careTarget: careTargetPosition,
                careActionName: careActionName,
                careInteractionDistance: dependentCareState?.configuration
                    .careInteractionDistance ?? 1,
                autonomousActivityTarget: autonomousActivity?.candidate.target,
                autonomousActivityActionKey: autonomousActivity?.candidate.actionKey
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
                    survivalEnabled: survivalEnabled,
                    homeostasisProfile: homeostasisProfile(
                        for: state.agentID
                    )
                )
            ))
        }

        if !mortalityWasEnabled { clock.advance(to: nextSimulationTick) }
        try applyGeneticsDevelopmentBoundary(at: nextTick)
        try reconcileTeachingBoundary(at: nextTick)
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
                if !isMigratingAgent(result.agentId) {
                    try recordGroundedSocialFacts(
                        observerID: agentID,
                        observations: (result.snapshot.lastResourceObservations
                            + (socialResourceObservationsById[result.agentId] ?? []))
                            .sorted(by: AgentResourcePerception.sortsBefore),
                        perceptionEventID: eventID,
                        at: tick
                    )
                }
            }
            guard result.cognitionPerformed else { continue }
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
        try applyCooperationTickPlan(cooperationPlan, results: results)
        let activePhysicalObservations = physicalObservations.filter {
            statesById[$0.observerID.rawValue] != nil
                && (populationRegistry?.scaleState == nil
                    || liveIDSet.contains($0.observerID.rawValue))
        }
        try applyPhysicalObservations(activePhysicalObservations)
        try applySocialTickPlan(socialPlan, results: results)
        try evaluateReproductionPlanIfDue(at: tick)
        try appendLifecycleFrame(at: tick)
        try recordCausalEvent(
            kind: .tickCompleted,
            origin: .cognitiveTransition,
            payload: .lifecycle(status: "tickCompleted", agentCount: results.count),
            summary: "tick \(tick) completed agents=\(results.count)"
        )
        recordFidelityWork(
            liveCount: execution.live.count,
            nearMaintenanceCount: execution.nearMaintenance,
            dormantMaintenanceCount: execution.dormantMaintenance
        )
        try rotateFidelityIfDue(at: tick)
        try validateHouseholdCrossDomainIfEnabled()
        try validateDependentCareCrossDomainIfEnabled()
        return AgentSessionTickResult(tick: tick, agents: results)
    }

}
