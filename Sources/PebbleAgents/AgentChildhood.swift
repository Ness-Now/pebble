public enum AgentChildhoodError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case dependentCareRequired
    case alreadyEnabled
    case unknownDependent(AgentID)
    case unknownGuardian(AgentID)
    case ineligibleGuardian(AgentID)
    case invalidDelegation(AgentID)
    case duplicateGuardian(AgentID)
    case guardianCapacityReached(AgentID)
    case assignmentCapacityReached
    case exposureCapacityReached
    case interactionDurationRequired(Int)
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason):
            return "invalid childhood configuration: \(reason)"
        case .dependentCareRequired:
            return "childhood V2 requires Dependent Care"
        case .alreadyEnabled:
            return "childhood V2 already enabled"
        case let .unknownDependent(id):
            return "unknown childhood dependent \(id.rawValue)"
        case let .unknownGuardian(id):
            return "unknown guardian \(id.rawValue)"
        case let .ineligibleGuardian(id):
            return "ineligible guardian \(id.rawValue)"
        case let .invalidDelegation(id):
            return "invalid care delegation to \(id.rawValue)"
        case let .duplicateGuardian(id):
            return "duplicate active guardian for \(id.rawValue)"
        case let .guardianCapacityReached(id):
            return "guardian capacity reached for \(id.rawValue)"
        case .assignmentCapacityReached:
            return "guardianship history capacity reached"
        case .exposureCapacityReached:
            return "social-development exposure capacity reached"
        case let .interactionDurationRequired(ticks):
            return "care interaction requires \(ticks) engaged ticks"
        case let .invalidCausalReference(id):
            return "invalid childhood causal reference \(id.rawValue)"
        case let .invalidState(reason):
            return "invalid childhood state: \(reason)"
        }
    }
}

public struct AgentChildhoodConfiguration: Codable, Equatable, Sendable {
    public let maximumRetainedGuardianships: Int
    public let maximumDependentsPerGuardian: Int
    public let maximumSocialProfiles: Int
    public let maximumRetainedExposures: Int
    public let maximumExposuresPerChild: Int
    public let maximumTransitionsPerTick: Int
    public let minimumSupervisionTicks: Int
    public let maximumDimensionBasisPoints: Int

    public init(
        maximumRetainedGuardianships: Int = 256,
        maximumDependentsPerGuardian: Int = 4,
        maximumSocialProfiles: Int = 64,
        maximumRetainedExposures: Int = 512,
        maximumExposuresPerChild: Int = 64,
        maximumTransitionsPerTick: Int = 64,
        minimumSupervisionTicks: Int = 2,
        maximumDimensionBasisPoints: Int = 10_000
    ) throws {
        guard (1...4096).contains(maximumRetainedGuardianships) else {
            throw AgentChildhoodError.invalidConfiguration("guardianships")
        }
        guard (1...32).contains(maximumDependentsPerGuardian) else {
            throw AgentChildhoodError.invalidConfiguration("guardian load")
        }
        guard (1...512).contains(maximumSocialProfiles) else {
            throw AgentChildhoodError.invalidConfiguration("social profiles")
        }
        guard (1...8192).contains(maximumRetainedExposures),
              (1...2048).contains(maximumExposuresPerChild),
              maximumExposuresPerChild <= maximumRetainedExposures else {
            throw AgentChildhoodError.invalidConfiguration("social exposures")
        }
        guard (1...512).contains(maximumTransitionsPerTick),
              (2...32).contains(minimumSupervisionTicks),
              (100...100_000).contains(maximumDimensionBasisPoints) else {
            throw AgentChildhoodError.invalidConfiguration("time or dimension bounds")
        }
        self.maximumRetainedGuardianships = maximumRetainedGuardianships
        self.maximumDependentsPerGuardian = maximumDependentsPerGuardian
        self.maximumSocialProfiles = maximumSocialProfiles
        self.maximumRetainedExposures = maximumRetainedExposures
        self.maximumExposuresPerChild = maximumExposuresPerChild
        self.maximumTransitionsPerTick = maximumTransitionsPerTick
        self.minimumSupervisionTicks = minimumSupervisionTicks
        self.maximumDimensionBasisPoints = maximumDimensionBasisPoints
    }

    public static let live = try! AgentChildhoodConfiguration()
}

public enum AgentGuardianshipBasis: String, Codable, CaseIterable, Sendable {
    case canonicalParent
    case kinshipRelative
    case householdAdult
    case explicitReassignment
    case emergencyHouseholdFallback
}

public enum AgentGuardianshipStatus: String, Codable, CaseIterable, Sendable {
    case active
    case ended
}

public enum AgentGuardianshipEndReason: String, Codable, CaseIterable, Sendable {
    case guardianDied
    case guardianIncapacitated
    case dependentDied
    case householdSeparated
    case capacityExceeded
    case explicitReassignment
    case dependentMatured
}

public struct AgentGuardianshipAssignment: Codable, Equatable, Sendable {
    public let dependentID: AgentID
    public let guardianID: AgentID
    public let householdID: AgentHouseholdID
    public let basis: AgentGuardianshipBasis
    public let startedTick: Int
    public let startedEventID: AgentCausalEventID
    public internal(set) var endedTick: Int?
    public internal(set) var endedEventID: AgentCausalEventID?
    public internal(set) var endedReason: AgentGuardianshipEndReason?
    public internal(set) var status: AgentGuardianshipStatus
}

public enum AgentSocialDevelopmentDimension:
    String, Codable, CaseIterable, Comparable, Sendable
{
    case guardianContinuity
    case stableCareExposure
    case supervisedInteraction
    case teachingExposure
    case successfulPracticeExposure
    case unmetCareExposure

    public static func < (
        lhs: AgentSocialDevelopmentDimension,
        rhs: AgentSocialDevelopmentDimension
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct AgentSocialDevelopmentValue: Codable, Equatable, Sendable {
    public let dimension: AgentSocialDevelopmentDimension
    public internal(set) var basisPoints: Int
    public internal(set) var lastChangedTick: Int
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentSocialDevelopmentProfile: Codable, Equatable, Sendable {
    public let agentID: AgentID
    public internal(set) var values: [AgentSocialDevelopmentValue]
    public internal(set) var totalExposureCount: Int
    public internal(set) var lastSignificantChangeTick: Int
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentSocialDevelopmentExposure: Codable, Equatable, Sendable {
    public let ordinal: Int
    public let agentID: AgentID
    public let dimension: AgentSocialDevelopmentDimension
    public let deltaBasisPoints: Int
    public let valueAfterBasisPoints: Int
    public let tick: Int
    public let sourceEventID: AgentCausalEventID
    public let transitionEventID: AgentCausalEventID
    public let participantID: AgentID?
}

public struct AgentChildhoodEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var guardianships: Int
    public internal(set) var exposures: Int

    public init(guardianships: Int = 0, exposures: Int = 0) {
        self.guardianships = max(0, guardianships)
        self.exposures = max(0, exposures)
    }
}

public struct AgentChildhoodState: Codable, Equatable, Sendable {
    public let configuration: AgentChildhoodConfiguration
    public internal(set) var guardianships: [AgentGuardianshipAssignment]
    public internal(set) var socialProfiles: [AgentSocialDevelopmentProfile]
    public internal(set) var exposures: [AgentSocialDevelopmentExposure]
    public internal(set) var totalGuardianshipCount: Int
    public internal(set) var totalExposureCount: Int
    public internal(set) var transitionTick: Int
    public internal(set) var transitionsAtTick: Int
    public internal(set) var evictionCounts: AgentChildhoodEvictionCounts
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentChildhoodCapabilitySnapshot: Codable, Equatable, Sendable {
    public let allowed: [AgentStageCapability]
    public let refused: [AgentStageCapability]
    public let autonomyReadinessBasisPoints: Int
}

public struct AgentChildhoodSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentChildhoodConfiguration?
    public let guardianships: [AgentGuardianshipAssignment]
    public let socialProfiles: [AgentSocialDevelopmentProfile]
    public let exposures: [AgentSocialDevelopmentExposure]
    public let atRiskDependentIDs: [AgentID]
    public let totalGuardianshipCount: Int
    public let totalExposureCount: Int
    public let evictionCounts: AgentChildhoodEvictionCounts
    public let digest: String
}

enum AgentChildhoodDigest {
    static func make(_ text: String) -> String {
        AgentDependentCareDigest.make("childhood-v2|\(text)")
    }
}
