/// A deterministic, read-only description of one domain in an agent's work
/// history. It grants no permission and changes no physical outcome.
public struct AgentProfessionDomainActivity: Codable, Equatable, Sendable {
    public let domain: AgentSkillDomain
    public let recentWorkUnits: Int
    public let lifetimeWorkUnits: Int
    public let recentShareBasisPoints: Int
    public let lifetimeShareBasisPoints: Int
    public let profileShareBasisPoints: Int
    public let skillPracticeUnits: Int
    public let apprenticeshipEvidenceCount: Int
    public let successfulOutcomeCount: Int
    public let failedOutcomeCount: Int
    public let blockedOutcomeCount: Int
    public let interruptedOutcomeCount: Int
    public let completedCommitmentCount: Int
    public let lastWorkTick: Int
}

/// A derived projection over validated work, responsibility, skill, teaching,
/// and local reliability evidence. There is deliberately no profession setter.
public struct AgentProfessionProfile: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let primaryWorkDomain: AgentSkillDomain?
    public let secondaryDomains: [AgentSkillDomain]
    public let domainActivity: [AgentProfessionDomainActivity]
    public let activeCommitmentCount: Int
    public let commitmentContinuity: Int
    public let skillEvidenceUnits: Int
    public let apprenticeshipEvidenceCount: Int
    public let reliabilityEvidenceCount: Int
    public let recentSpecializationBasisPoints: Int
    public let lifetimeSpecializationBasisPoints: Int
    public let specializationStrengthBasisPoints: Int
    public let displayDescriptor: String?
    public let lastRecomputedTick: Int
    public let digest: String
}

public struct AgentSpecializationMetric: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public let primaryDomain: AgentSkillDomain?
    public let recentConcentrationBasisPoints: Int
    public let lifetimeConcentrationBasisPoints: Int
    public let blendedConcentrationBasisPoints: Int
    public let domainCoverage: Int
}

/// Local demand coverage only. `knownCapableWorkerCount` is the number of
/// mature, living, present agents; physical tools and reachability remain with
/// Pebble and must still be checked by an adapter before matching/execution.
public struct AgentWorkDependencyMetric: Codable, Equatable, Sendable {
    public let domain: AgentSkillDomain
    public let activeDemandCount: Int
    public let committedWorkerIDs: [AgentID]
    public let knownCapableWorkerCount: Int
    public let replacementDepth: Int
    public let recentTopWorkerShareBasisPoints: Int
    public let singleWorkerDependency: Bool
}

public struct AgentWorkCoordinationMetrics: Codable, Equatable, Sendable {
    public let activeDemandCount: Int
    public let activeCommitmentCount: Int
    public let suspendedCommitmentCount: Int
    public let fulfilledCommitmentCount: Int
    public let reassignmentCount: Int
    public let coveredDemandCount: Int
    public let uncoveredDemandCount: Int
}
