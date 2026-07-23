public enum AgentTeachingError: Error, Equatable, CustomStringConvertible {
    case invalidConfiguration(String)
    case causalLedgerRequired
    case populationRequired
    case lifecycleRequired
    case skillsRequired
    case alreadyEnabled
    case disabled
    case unsafeDisable
    case invalidRequest(String)
    case unknownAgent(AgentID)
    case inactiveParticipant(AgentID)
    case ineligibleTeacher(AgentID)
    case ineligibleStudent(AgentID)
    case noEligibleMentor
    case activeApprenticeshipExists(AgentID, AgentSkillDomain)
    case apprenticeshipCapacityReached
    case teacherCapacityReached(AgentID)
    case unknownApprenticeship(AgentApprenticeshipID)
    case invalidParticipant(AgentID)
    case invalidObservation(String)
    case staleDemonstration(AgentCausalEventID)
    case invalidSourceEvent(AgentCausalEventID)
    case duplicateDemonstration(AgentCausalEventID)
    case demonstrationsPerTickReached
    case exposureCapacityReached
    case invalidGuidedPractice(String)
    case duplicateGuidedPractice(AgentCausalEventID)
    case invalidCausalReference(AgentCausalEventID)
    case invalidState(String)

    public var description: String {
        switch self {
        case let .invalidConfiguration(reason): return "invalid teaching configuration: \(reason)"
        case .causalLedgerRequired: return "teaching requires the causal ledger"
        case .populationRequired: return "teaching requires population"
        case .lifecycleRequired: return "teaching requires lifecycle"
        case .skillsRequired: return "teaching requires skills"
        case .alreadyEnabled: return "teaching already enabled"
        case .disabled: return "teaching disabled"
        case .unsafeDisable: return "teaching disable refused while durable state exists"
        case let .invalidRequest(reason): return "invalid teaching request: \(reason)"
        case let .unknownAgent(id): return "unknown teaching agent \(id.rawValue)"
        case let .inactiveParticipant(id): return "inactive teaching participant \(id.rawValue)"
        case let .ineligibleTeacher(id): return "ineligible teacher \(id.rawValue)"
        case let .ineligibleStudent(id): return "ineligible student \(id.rawValue)"
        case .noEligibleMentor: return "no eligible mentor"
        case let .activeApprenticeshipExists(id, domain):
            return "active apprenticeship exists for \(id.rawValue) in \(domain.rawValue)"
        case .apprenticeshipCapacityReached: return "apprenticeship capacity reached"
        case let .teacherCapacityReached(id): return "teacher capacity reached for \(id.rawValue)"
        case let .unknownApprenticeship(id): return "unknown apprenticeship \(id.rawValue)"
        case let .invalidParticipant(id): return "invalid apprenticeship participant \(id.rawValue)"
        case let .invalidObservation(reason): return "invalid teaching observation: \(reason)"
        case let .staleDemonstration(id): return "stale demonstration source \(id.rawValue)"
        case let .invalidSourceEvent(id): return "invalid teaching source event \(id.rawValue)"
        case let .duplicateDemonstration(id): return "duplicate demonstration source \(id.rawValue)"
        case .demonstrationsPerTickReached: return "teaching demonstrations per tick reached"
        case .exposureCapacityReached: return "teaching exposure capacity reached"
        case let .invalidGuidedPractice(reason): return "invalid guided practice: \(reason)"
        case let .duplicateGuidedPractice(id): return "duplicate guided practice \(id.rawValue)"
        case let .invalidCausalReference(id): return "invalid teaching causal reference \(id.rawValue)"
        case let .invalidState(reason): return "invalid teaching state: \(reason)"
        }
    }
}

private func teachingIdentifierIsValid(_ rawValue: String) -> Bool {
    (1...160).contains(rawValue.utf8.count)
        && rawValue.utf8.allSatisfy {
            (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0)
                || $0 == 45 || $0 == 95
        }
}

public struct AgentApprenticeshipID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard teachingIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentDemonstrationID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard teachingIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct AgentLearningExposureID: RawRepresentable, Codable, Hashable, Comparable, Sendable {
    public let rawValue: String
    public init?(rawValue: String) {
        guard teachingIdentifierIsValid(rawValue) else { return nil }
        self.rawValue = rawValue
    }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum AgentTeachingAttention: String, Codable, CaseIterable, Sendable {
    case noticed
    case attended
}

public enum AgentApprenticeshipStatus: String, Codable, CaseIterable, Sendable {
    case active
    case completed
    case interrupted
    case expired

    public var isTerminal: Bool { self != .active }
}

public enum AgentApprenticeshipEndReason: String, Codable, CaseIterable, Sendable {
    case completed
    case teacherWithdrew
    case studentWithdrew
    case criticalHunger
    case carePriority
    case unsafeContext
    case participantUnavailable
    case migration
    case expired
}

public enum AgentLearningExposureStatus: String, Codable, CaseIterable, Sendable {
    case observed
    case guidedPracticeLinked
}

public struct AgentTeachingConfiguration: Codable, Equatable, Sendable {
    public let maximumMentorCandidates: Int
    public let maximumActiveApprenticeships: Int
    public let maximumRetainedApprenticeships: Int
    public let maximumApprenticesPerTeacher: Int
    public let maximumRetainedDemonstrations: Int
    public let maximumRetainedExposures: Int
    public let maximumExposuresPerStudent: Int
    public let maximumRetainedGuidedPracticeLinks: Int
    public let maximumDemonstrationsPerTick: Int
    public let maximumApprenticeshipDurationTicks: Int
    public let demonstrationFreshnessTicks: Int
    public let exposureFreshnessTicks: Int
    public let maximumObservationDistance: Int

    public init(
        maximumMentorCandidates: Int = 32,
        maximumActiveApprenticeships: Int = 128,
        maximumRetainedApprenticeships: Int = 256,
        maximumApprenticesPerTeacher: Int = 4,
        maximumRetainedDemonstrations: Int = 512,
        maximumRetainedExposures: Int = 512,
        maximumExposuresPerStudent: Int = 64,
        maximumRetainedGuidedPracticeLinks: Int = 512,
        maximumDemonstrationsPerTick: Int = 32,
        maximumApprenticeshipDurationTicks: Int = 256,
        demonstrationFreshnessTicks: Int = 2,
        exposureFreshnessTicks: Int = 512,
        maximumObservationDistance: Int = 8
    ) throws {
        guard (1...512).contains(maximumMentorCandidates) else {
            throw AgentTeachingError.invalidConfiguration("mentor candidates")
        }
        guard (1...4096).contains(maximumActiveApprenticeships),
              maximumRetainedApprenticeships >= maximumActiveApprenticeships,
              maximumRetainedApprenticeships <= 16_384 else {
            throw AgentTeachingError.invalidConfiguration("apprenticeships")
        }
        guard (1...128).contains(maximumApprenticesPerTeacher) else {
            throw AgentTeachingError.invalidConfiguration("apprentices per teacher")
        }
        guard (1...16_384).contains(maximumRetainedDemonstrations),
              (1...16_384).contains(maximumRetainedExposures),
              (1...2048).contains(maximumExposuresPerStudent),
              maximumExposuresPerStudent <= maximumRetainedExposures,
              (1...16_384).contains(maximumRetainedGuidedPracticeLinks) else {
            throw AgentTeachingError.invalidConfiguration("retained history")
        }
        guard (1...512).contains(maximumDemonstrationsPerTick) else {
            throw AgentTeachingError.invalidConfiguration("demonstrations per tick")
        }
        guard (1...65_536).contains(maximumApprenticeshipDurationTicks),
              (0...256).contains(demonstrationFreshnessTicks),
              (1...65_536).contains(exposureFreshnessTicks),
              (1...64).contains(maximumObservationDistance) else {
            throw AgentTeachingError.invalidConfiguration("time or distance")
        }
        self.maximumMentorCandidates = maximumMentorCandidates
        self.maximumActiveApprenticeships = maximumActiveApprenticeships
        self.maximumRetainedApprenticeships = maximumRetainedApprenticeships
        self.maximumApprenticesPerTeacher = maximumApprenticesPerTeacher
        self.maximumRetainedDemonstrations = maximumRetainedDemonstrations
        self.maximumRetainedExposures = maximumRetainedExposures
        self.maximumExposuresPerStudent = maximumExposuresPerStudent
        self.maximumRetainedGuidedPracticeLinks = maximumRetainedGuidedPracticeLinks
        self.maximumDemonstrationsPerTick = maximumDemonstrationsPerTick
        self.maximumApprenticeshipDurationTicks = maximumApprenticeshipDurationTicks
        self.demonstrationFreshnessTicks = demonstrationFreshnessTicks
        self.exposureFreshnessTicks = exposureFreshnessTicks
        self.maximumObservationDistance = maximumObservationDistance
    }

    public static let live = try! AgentTeachingConfiguration()
}

public struct AgentMentorCandidateConsent: Codable, Equatable, Sendable {
    public let teacherID: AgentID
    public let accepts: Bool

    public init(teacherID: AgentID, accepts: Bool) {
        self.teacherID = teacherID
        self.accepts = accepts
    }
}

public struct AgentMentorSelectionRequest: Codable, Equatable, Sendable {
    public let requestID: String
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let studentAccepts: Bool
    public let candidates: [AgentMentorCandidateConsent]
    public let requestedAtTick: Int

    public init(
        requestID: String,
        studentID: AgentID,
        domain: AgentSkillDomain,
        studentAccepts: Bool,
        candidates: [AgentMentorCandidateConsent],
        requestedAtTick: Int
    ) {
        self.requestID = requestID
        self.studentID = studentID
        self.domain = domain
        self.studentAccepts = studentAccepts
        self.candidates = candidates
        self.requestedAtTick = requestedAtTick
    }
}

public enum AgentTeachingParticipationRole: String, Codable, CaseIterable, Sendable {
    case student
    case teacher
}

public enum AgentTeachingParticipationRefusalReason:
    String, Codable, CaseIterable, Sendable
{
    case inactive
    case ineligibleLifecycleStage
    case migrating
    case criticalHunger
    case carePriority
    case unsafeContext
    case incompatibleUrgentResponsibility
    case teacherCapacityReached
}

/// Pure, testable input to the bounded V1 participation policy. The session
/// derives it from canonical lifecycle, needs, care, migration, and Teaching
/// state; no personality trait or permanent obedience flag is introduced.
public struct AgentTeachingParticipationContext: Equatable, Sendable {
    public let participantID: AgentID
    public let role: AgentTeachingParticipationRole
    public let active: Bool
    public let lifecycleStage: AgentLifeStage?
    public let migrating: Bool
    public let criticalHunger: Bool
    public let urgentCarePriority: Bool
    public let unsafe: Bool
    public let incompatibleUrgentResponsibility: Bool
    public let teacherCapacityAvailable: Bool

    public init(
        participantID: AgentID,
        role: AgentTeachingParticipationRole,
        active: Bool,
        lifecycleStage: AgentLifeStage?,
        migrating: Bool,
        criticalHunger: Bool,
        urgentCarePriority: Bool,
        unsafe: Bool,
        incompatibleUrgentResponsibility: Bool,
        teacherCapacityAvailable: Bool = true
    ) {
        self.participantID = participantID
        self.role = role
        self.active = active
        self.lifecycleStage = lifecycleStage
        self.migrating = migrating
        self.criticalHunger = criticalHunger
        self.urgentCarePriority = urgentCarePriority
        self.unsafe = unsafe
        self.incompatibleUrgentResponsibility = incompatibleUrgentResponsibility
        self.teacherCapacityAvailable = teacherCapacityAvailable
    }
}

public struct AgentTeachingParticipationDecision: Equatable, Sendable {
    public let participantID: AgentID
    public let role: AgentTeachingParticipationRole
    public let accepts: Bool
    public let refusalReason: AgentTeachingParticipationRefusalReason?

    public init(
        participantID: AgentID,
        role: AgentTeachingParticipationRole,
        accepts: Bool,
        refusalReason: AgentTeachingParticipationRefusalReason?
    ) {
        self.participantID = participantID
        self.role = role
        self.accepts = accepts
        self.refusalReason = refusalReason
    }
}

public enum AgentTeachingParticipationPolicy {
    /// The normal cognition boundary reviews contextual local opportunities,
    /// never wall-clock time or a separate scheduler.
    public static let reviewIntervalTicks = 4
    public static let reengagementCooldownTicks = 16

    public static func decide(
        _ context: AgentTeachingParticipationContext
    ) -> AgentTeachingParticipationDecision {
        let refusal: AgentTeachingParticipationRefusalReason?
        if !context.active {
            refusal = .inactive
        } else if context.lifecycleStage == nil
                    || context.lifecycleStage == .newborn
                    || (context.role == .teacher && context.lifecycleStage != .mature) {
            refusal = .ineligibleLifecycleStage
        } else if context.migrating {
            refusal = .migrating
        } else if context.criticalHunger {
            refusal = .criticalHunger
        } else if context.urgentCarePriority {
            refusal = .carePriority
        } else if context.unsafe {
            refusal = .unsafeContext
        } else if context.incompatibleUrgentResponsibility {
            refusal = .incompatibleUrgentResponsibility
        } else if context.role == .teacher && !context.teacherCapacityAvailable {
            refusal = .teacherCapacityReached
        } else {
            refusal = nil
        }
        return AgentTeachingParticipationDecision(
            participantID: context.participantID,
            role: context.role,
            accepts: refusal == nil,
            refusalReason: refusal
        )
    }
}

public enum AgentLocalApprenticeshipReason: String, Codable, CaseIterable, Sendable {
    case currentAutonomousActivity
    case nearbyLocalProductiveActivity
}

/// Bounded pure cognition input. Candidate identities come only from the
/// student's retained local peer observation, never a population-wide search.
public struct AgentLocalApprenticeshipOpportunity: Equatable, Sendable {
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let localMentorCandidateIDs: [AgentID]
    public let reason: AgentLocalApprenticeshipReason
    public let contextReference: String
    public let observedAtTick: Int

    public init(
        studentID: AgentID,
        domain: AgentSkillDomain,
        localMentorCandidateIDs: [AgentID],
        reason: AgentLocalApprenticeshipReason,
        contextReference: String,
        observedAtTick: Int
    ) {
        self.studentID = studentID
        self.domain = domain
        self.localMentorCandidateIDs = localMentorCandidateIDs
        self.reason = reason
        self.contextReference = String(contextReference.prefix(160))
        self.observedAtTick = observedAtTick
    }
}

public enum AgentLocalApprenticeshipDisposition: String, Sendable {
    case studentRefused
    case noEligibleMentor
    case activeApprenticeshipExists
    case reengagementCooldown
    case started
}

public struct AgentLocalApprenticeshipAttempt: Equatable, Sendable {
    public let opportunity: AgentLocalApprenticeshipOpportunity
    public let studentDecision: AgentTeachingParticipationDecision
    public let teacherDecisions: [AgentTeachingParticipationDecision]
    public let disposition: AgentLocalApprenticeshipDisposition
    public let apprenticeshipID: AgentApprenticeshipID?
}

/// Latest-review diagnostics only. This snapshot is intentionally not part of
/// checkpoint state; every durable result remains an existing apprenticeship
/// and causal event.
public struct AgentAutonomousTeachingReviewSnapshot: Equatable, Sendable {
    public let reviewedAtTick: Int
    public let cadenceDue: Bool
    public let opportunitiesConsidered: Int
    public let requestsAttempted: Int
    public let accepted: Int
    public let refusedStudent: Int
    public let refusedTeacher: Int
    public let noMentor: Int
    public let started: Int
    public let active: Int
    public let ended: Int
    public let attempts: [AgentLocalApprenticeshipAttempt]

    public init(
        reviewedAtTick: Int,
        cadenceDue: Bool,
        opportunitiesConsidered: Int,
        requestsAttempted: Int,
        accepted: Int,
        refusedStudent: Int,
        refusedTeacher: Int,
        noMentor: Int,
        started: Int,
        active: Int,
        ended: Int,
        attempts: [AgentLocalApprenticeshipAttempt]
    ) {
        self.reviewedAtTick = reviewedAtTick
        self.cadenceDue = cadenceDue
        self.opportunitiesConsidered = opportunitiesConsidered
        self.requestsAttempted = requestsAttempted
        self.accepted = accepted
        self.refusedStudent = refusedStudent
        self.refusedTeacher = refusedTeacher
        self.noMentor = noMentor
        self.started = started
        self.active = active
        self.ended = ended
        self.attempts = attempts
    }
}

/// Pure evidence DTO. Pebble supplies it from live embodiments and World
/// geometry; headless fixtures supply the same bounded physical contract.
public struct AgentTeachingObservation: Codable, Equatable, Sendable {
    public let apprenticeshipID: AgentApprenticeshipID
    public let teacherID: AgentID
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let sourceSuccessEventID: AgentCausalEventID
    public let teacherPosition: AgentPosition
    public let studentPosition: AgentPosition
    public let distanceManhattan: Int
    public let soundClarity: Int
    public let gestureClarity: Int
    public let opaqueOcclusionCount: Int
    public let lineOfSight: Bool
    public let chunksReady: Bool
    public let observedAtTick: Int

    public init(
        apprenticeshipID: AgentApprenticeshipID,
        teacherID: AgentID,
        studentID: AgentID,
        domain: AgentSkillDomain,
        sourceSuccessEventID: AgentCausalEventID,
        teacherPosition: AgentPosition,
        studentPosition: AgentPosition,
        distanceManhattan: Int,
        soundClarity: Int,
        gestureClarity: Int,
        opaqueOcclusionCount: Int,
        lineOfSight: Bool,
        chunksReady: Bool,
        observedAtTick: Int
    ) {
        self.apprenticeshipID = apprenticeshipID
        self.teacherID = teacherID
        self.studentID = studentID
        self.domain = domain
        self.sourceSuccessEventID = sourceSuccessEventID
        self.teacherPosition = teacherPosition
        self.studentPosition = studentPosition
        self.distanceManhattan = distanceManhattan
        self.soundClarity = soundClarity
        self.gestureClarity = gestureClarity
        self.opaqueOcclusionCount = opaqueOcclusionCount
        self.lineOfSight = lineOfSight
        self.chunksReady = chunksReady
        self.observedAtTick = observedAtTick
    }
}

public struct AgentApprenticeshipEngagement: Codable, Equatable, Sendable {
    public let apprenticeshipID: AgentApprenticeshipID
    public let requestID: String
    public let teacherID: AgentID
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let startedAtTick: Int
    public let expiresAtTick: Int
    public internal(set) var endedAtTick: Int?
    public internal(set) var status: AgentApprenticeshipStatus
    public internal(set) var endReason: AgentApprenticeshipEndReason?
    public let teacherPracticeUnitsAtSelection: Int
    public let trustAtSelection: Int
    public let distanceAtSelection: Int
    public let startedEventID: AgentCausalEventID
    public internal(set) var lastEventID: AgentCausalEventID
}

public struct AgentDemonstrationRecord: Codable, Equatable, Sendable {
    public let demonstrationID: AgentDemonstrationID
    public let apprenticeshipID: AgentApprenticeshipID
    public let teacherID: AgentID
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let sourceSuccessEventID: AgentCausalEventID
    public let observedAtTick: Int
    public let teacherPosition: AgentPosition
    public let studentPosition: AgentPosition
    public let distanceManhattan: Int
    public let attention: AgentTeachingAttention
    public let demonstrationEventID: AgentCausalEventID
    public let digest: String
}

public struct AgentLearningExposure: Codable, Equatable, Sendable {
    public let exposureID: AgentLearningExposureID
    public let demonstrationID: AgentDemonstrationID
    public let apprenticeshipID: AgentApprenticeshipID
    public let teacherID: AgentID
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let sourceSuccessEventID: AgentCausalEventID
    public let demonstrationEventID: AgentCausalEventID
    public let observedAtTick: Int
    public let expiresAtTick: Int
    public let attention: AgentTeachingAttention
    public internal(set) var status: AgentLearningExposureStatus
    public internal(set) var guidedPracticeEventID: AgentCausalEventID?
    public let digest: String

    public func isFresh(at tick: Int) -> Bool {
        observedAtTick <= tick && tick <= expiresAtTick
    }
}

public struct AgentGuidedPracticeLink: Codable, Equatable, Sendable {
    public let exposureID: AgentLearningExposureID
    public let apprenticeshipID: AgentApprenticeshipID
    public let teacherID: AgentID
    public let studentID: AgentID
    public let domain: AgentSkillDomain
    public let studentSourceSuccessEventID: AgentCausalEventID
    public let skillPracticeEventID: AgentCausalEventID
    public let linkedAtTick: Int
    public let guidedPracticeEventID: AgentCausalEventID
    public let digest: String
}

public struct AgentTeachingEvictionCounts: Codable, Equatable, Sendable {
    public internal(set) var apprenticeships: Int
    public internal(set) var demonstrations: Int
    public internal(set) var exposures: Int
    public internal(set) var guidedPracticeLinks: Int

    public init(
        apprenticeships: Int = 0,
        demonstrations: Int = 0,
        exposures: Int = 0,
        guidedPracticeLinks: Int = 0
    ) {
        self.apprenticeships = apprenticeships
        self.demonstrations = demonstrations
        self.exposures = exposures
        self.guidedPracticeLinks = guidedPracticeLinks
    }
}

public struct AgentTeachingState: Codable, Equatable, Sendable {
    public let configuration: AgentTeachingConfiguration
    public internal(set) var apprenticeships: [AgentApprenticeshipEngagement]
    public internal(set) var demonstrations: [AgentDemonstrationRecord]
    public internal(set) var exposures: [AgentLearningExposure]
    public internal(set) var guidedPracticeLinks: [AgentGuidedPracticeLink]
    public internal(set) var totalApprenticeshipCount: Int
    public internal(set) var totalDemonstrationCount: Int
    public internal(set) var totalExposureCount: Int
    public internal(set) var totalGuidedPracticeCount: Int
    public internal(set) var evictionCounts: AgentTeachingEvictionCounts
    public internal(set) var evictedHistoryDigest: String
    public internal(set) var rollingDigest: String
    public let initializedEventID: AgentCausalEventID
    public internal(set) var lastTeachingEventID: AgentCausalEventID
    public internal(set) var transitionTick: Int
    public internal(set) var demonstrationsAtTick: Int
}

public struct AgentTeachingSnapshot: Codable, Equatable, Sendable {
    public let enabled: Bool
    public let configuration: AgentTeachingConfiguration?
    public let apprenticeships: [AgentApprenticeshipEngagement]
    public let demonstrations: [AgentDemonstrationRecord]
    public let exposures: [AgentLearningExposure]
    public let guidedPracticeLinks: [AgentGuidedPracticeLink]
    public let totalApprenticeshipCount: Int
    public let totalDemonstrationCount: Int
    public let totalExposureCount: Int
    public let totalGuidedPracticeCount: Int
    public let evictionCounts: AgentTeachingEvictionCounts
    public let evictedHistoryDigest: String
    public let digest: String
}

public enum AgentTeachingDigest {
    public static func make(_ text: String) -> String {
        var value: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value &*= 1_099_511_628_211
        }
        let digits = String(value, radix: 16, uppercase: false)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}
