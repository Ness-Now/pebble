import PebbleAgents

/// PS01 product policy, separate from the shared population integrity contract.
struct PebbleNormalFounderProfile {
    static let allowedCounts = 20...30
    let specification: AgentFounderSpecification
    let populationConfiguration: AgentPopulationConfiguration
    let householdConfiguration: AgentHouseholdConfiguration

    init(count: Int) throws {
        guard Self.allowedCounts.contains(count) else {
            throw AgentPopulationError.invalidConfiguration("normal founders must be 20...30")
        }
        populationConfiguration = try AgentPopulationConfiguration(maximumActivePopulation: 30)
        householdConfiguration = try AgentHouseholdConfiguration(maximumHouseholdTransitionsPerTick: 30)
        specification = try AgentFounderSpecification(count: count, populationConfiguration: populationConfiguration)
    }
}

extension PebbleAgentController {
    /// Uses the ordinary Observer and durable codec on the unpublished candidate.
    /// The trace is evidence only; it is never read back as simulation authority.
    func verifyFounderProjection(
        _ candidate: AgentSimulationSession,
        specification: AgentFounderSpecification
    ) throws {
        let ids = specification.agentIDs.sorted()
        let before = try candidate.durableStateBytes()
        let checkpoint = try candidate.makeCheckpoint()
        let restored = try AgentSimulationSession.restoring(checkpoint)
        let observer = candidate.observerSnapshot(worldBinding: try AgentObserverWorldBinding(
            worldID: persistenceWorldID ?? "unbound",
            storageIdentity: persistenceWorldID ?? "unbound",
            seed: candidate.configuration.seed, dimension: persistenceDimension,
            observedWorldTick: 0
        ))
        guard candidate.populationSnapshot().members.map(\.agentID.rawValue) == ids,
              restored.expectedActiveAgentIDs().map(\.rawValue).sorted() == ids,
              try restored.durableStateBytes() == before,
              observer.individuals.map(\.agentID.rawValue) == ids,
              try candidate.durableStateBytes() == before,
              !candidate.populationScalingEnabled else {
            throw ControllerError.bootstrapPlacementBoundary("founder projection/restore mismatch")
        }
        trace("founder candidate count=\(ids.count) ids=\(ids.joined(separator: ",")) population=\(candidate.populationSummary().memberCount) nextOrdinal=\(candidate.populationSummary().nextPopulationOrdinal ?? -1) lifecycle=\(candidate.lifecycleSnapshot().members.count) kinship=\(candidate.kinshipSnapshot().historicalPersons.count) households=\(candidate.householdSnapshot().currentMemberships.count) genotypes=\(candidate.geneticsSnapshot().genotypes.count) physiology=\(candidate.homeostasisSnapshot().profiles.count) fullCognition=ALL scaling=inactive resources=0 observer=exact observerMutation=0 checkpoint=exact digest=\(checkpoint.semanticDigest.rawValue)")
    }
}
