import PebbleAgents
import PebbleCore

/// Read-only bridge from authoritative live embodiments and World geometry to
/// the pure Teaching observation contract.
struct PebbleAgentTeachingObservationAdapter {
    enum ObservationError: Error, Equatable {
        case invalidTeacher
        case invalidStudent
        case sameParticipant
    }

    private let physical = PebbleAgentPhysicalSignalAdapter()

    func observe(
        world: World,
        teacher: PebbleAgentEmbodiment,
        student: PebbleAgentEmbodiment,
        apprenticeshipID: AgentApprenticeshipID,
        domain: AgentSkillDomain,
        sourceSuccessEventID: AgentCausalEventID,
        atTick tick: Int,
        configuration: AgentPhysicalChannelConfiguration
    ) throws -> AgentTeachingObservation {
        guard teacher.isValid(in: world) else { throw ObservationError.invalidTeacher }
        guard student.isValid(in: world) else { throw ObservationError.invalidStudent }
        guard teacher.agentID != student.agentID else {
            throw ObservationError.sameParticipant
        }
        let evidence = physical.evidence(
            world: world, from: teacher.position, to: student.position,
            configuration: configuration
        )
        return AgentTeachingObservation(
            apprenticeshipID: apprenticeshipID,
            teacherID: AgentID(rawValue: teacher.agentID)!,
            studentID: AgentID(rawValue: student.agentID)!,
            domain: domain, sourceSuccessEventID: sourceSuccessEventID,
            teacherPosition: teacher.position, studentPosition: student.position,
            distanceManhattan: evidence.distanceManhattan,
            soundClarity: evidence.soundClarity,
            gestureClarity: evidence.gestureClarity,
            opaqueOcclusionCount: evidence.opaqueOcclusionCount,
            lineOfSight: evidence.lineOfSight,
            chunksReady: evidence.chunksReady,
            observedAtTick: tick
        )
    }
}
