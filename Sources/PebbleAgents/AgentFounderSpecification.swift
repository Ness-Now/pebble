/// Finite startup input. Population configuration supplies the safety bound. After publication, population and the ordinary
/// session domains own these people; this value is not durable authority.
public struct AgentFounderSpecification: Equatable, Sendable {
    public let count: Int

    public init(count: Int, populationConfiguration: AgentPopulationConfiguration = .live) throws {
        guard count > 0, count <= populationConfiguration.maximumActivePopulation else {
            throw AgentPopulationError.invalidConfiguration("founder count exceeds configured population capacity")
        }
        self.count = count
    }

    public var agentIDs: [String] { (0..<count).map { "agent_\($0)" } }

    public func initialStates(
        positionsByAgentID: [String: AgentPosition]
    ) throws -> [AgentSessionAgentState] {
        guard positionsByAgentID.keys.sorted() == agentIDs.sorted(),
              Set(positionsByAgentID.values).count == count else {
            throw AgentPopulationError.invalidConfiguration("founder placement identity or overlap")
        }
        return agentIDs.map { id in
            let position = positionsByAgentID[id]!
            return AgentSessionAgentState(
                id: id, state: "idle", position: position,
                needs: AgentNeeds(hunger: 0, fatigue: 0, curiosity: 0.2, safety: 1),
                health: 100, fear: 10, homePosition: position, nearbyAgents: [],
                currentGoal: AgentGoal(kind: .idle, reason: "initial goal", startedAtTick: 0, urgency: 0),
                lastAction: nil, lastActionEffect: nil, memory: [],
                tickCreated: 0, ticksAlive: 0, observationCount: 0,
                nearbyObservationCount: 0, goalSelectionCount: 0, goalChangeCount: 0,
                actionCount: 0, actionEffectCount: 0, movementCount: 0,
                totalManhattanDistanceMoved: 0, returnHomeMoveCount: 0,
                totalDistanceReducedTowardHome: 0
            )
        }
    }
}

@_spi(Testing)
public enum AgentFounderInitializationStage: String, CaseIterable, Sendable {
    case population, lifecycle, kinship, household, dependentCare, childhood
    case family, mortality, homeostasis, genetics, verification
}

extension AgentSimulationSession {
    /// Composes existing owners on a private value, before physical publication.
    /// Dependencies are checked by each domain's canonical enable operation.
    /// No roles, ancestry, possessions, reproduction plans or scale policy are seeded.
    public mutating func initializeFounderAuthorities(
        specification: AgentFounderSpecification,
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        lifecycle: Bool = true,
        kinship: Bool = true,
        households: Bool = true,
        dependentCare: Bool = true,
        childhood: Bool = true,
        family: Bool = true,
        mortality: Bool = true,
        homeostasis: Bool = true,
        genetics: Bool = true,
        populationConfiguration: AgentPopulationConfiguration = .live,
        householdConfiguration: AgentHouseholdConfiguration = .live
    ) throws {
        try initializeFounderAuthoritiesInPlace(
            specification: specification, settlementAnchor: settlementAnchor,
            receptionPosition: receptionPosition, lifecycle: lifecycle, kinship: kinship,
            households: households, dependentCare: dependentCare, childhood: childhood,
            family: family, mortality: mortality, homeostasis: homeostasis, genetics: genetics,
            populationConfiguration: populationConfiguration,
            householdConfiguration: householdConfiguration, failAfter: nil
        )
    }

    @_spi(Testing)
    public mutating func initializeFounderAuthorities(
        specification: AgentFounderSpecification,
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        populationConfiguration: AgentPopulationConfiguration,
        householdConfiguration: AgentHouseholdConfiguration,
        failAfter: AgentFounderInitializationStage
    ) throws {
        try initializeFounderAuthoritiesInPlace(
            specification: specification, settlementAnchor: settlementAnchor,
            receptionPosition: receptionPosition,
            populationConfiguration: populationConfiguration,
            householdConfiguration: householdConfiguration, failAfter: failAfter
        )
    }

    private mutating func initializeFounderAuthoritiesInPlace(
        specification: AgentFounderSpecification,
        settlementAnchor: AgentPosition,
        receptionPosition: AgentPosition,
        lifecycle: Bool = true,
        kinship: Bool = true,
        households: Bool = true,
        dependentCare: Bool = true,
        childhood: Bool = true,
        family: Bool = true,
        mortality: Bool = true,
        homeostasis: Bool = true,
        genetics: Bool = true,
        populationConfiguration: AgentPopulationConfiguration = .live,
        householdConfiguration: AgentHouseholdConfiguration = .live,
        failAfter: AgentFounderInitializationStage?
    ) throws {
        guard tick == 0, sortedIds == specification.agentIDs.sorted(),
              populationRegistry == nil, !populationScalingEnabled else {
            throw AgentPopulationError.invalidConfiguration("founders require an uninitialized matching session")
        }
        func injectedFailure(_ stage: AgentFounderInitializationStage) throws {
            if failAfter == stage {
                throw AgentPopulationError.invalidConfiguration("injected founder authority failure after \(stage.rawValue)")
            }
        }
        var candidate = self
        try candidate.initializePopulationRegistry(
            settlementAnchor: settlementAnchor, receptionPosition: receptionPosition,
            configuration: populationConfiguration
        )
        try injectedFailure(.population)
        if lifecycle {
            try candidate.setLifecycleEnabled(true)
            try injectedFailure(.lifecycle)
        }
        if kinship {
            try candidate.setKinshipEnabled(true)
            try injectedFailure(.kinship)
        }
        if households {
            try candidate.setHouseholdsEnabled(true, configuration: householdConfiguration)
            try injectedFailure(.household)
        }
        if dependentCare || mortality || homeostasis { candidate.setSurvivalEnabled(true) }
        if dependentCare {
            try candidate.setDependentCareEnabled(true)
            try injectedFailure(.dependentCare)
        }
        if childhood {
            try candidate.setChildhoodV2Enabled(true)
            try injectedFailure(.childhood)
        }
        if family {
            try candidate.setFamilyV1Enabled(true)
            try injectedFailure(.family)
        }
        if mortality {
            try candidate.setMortalityEnabled(true, configuration: .embodiedLive)
            try injectedFailure(.mortality)
        }
        if homeostasis {
            try candidate.setHomeostasisEnabled(true)
            try injectedFailure(.homeostasis)
        }
        if genetics {
            try candidate.setGeneticsEnabled(true)
            try injectedFailure(.genetics)
        }
        guard candidate.causalLedgerSnapshot().summary.droppedEventCount
                == causalLedgerSnapshot().summary.droppedEventCount else {
            throw AgentPopulationError.invalidConfiguration("founder initialization history capacity")
        }
        // The existing checkpoint validator checks the complete cross-domain
        // boundary, including identity/ordinal bijections and retained causes.
        _ = try AgentSimulationSession.restoring(candidate.makeCheckpoint())
        try injectedFailure(.verification)
        self = candidate
    }
}
