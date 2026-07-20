import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleTeaching(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab teaching <on|status|proof>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_TEACHING=1", teachingFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("teaching gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents Teaching refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session else {
            return failure("No active PebbleAgents session.")
        }
        do {
            switch command {
            case "on":
                if !candidate.teachingEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setTeachingEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setTeachingEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceTeachingState(candidate)
                return teachingStatus(candidate)
            case "status":
                traceTeachingState(candidate)
                return teachingStatus(candidate)
            case "proof":
                return handleTeachingProof(world: world, player: player)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents Teaching command failed: \(error)")
        }
    }

    func traceTeachingState(_ session: AgentSimulationSession) {
        let snapshot = session.teachingSnapshot()
        trace(
            "teaching tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "active=\(snapshot.apprenticeships.filter { $0.status == .active }.count) "
                + "demonstrations=\(snapshot.totalDemonstrationCount) "
                + "exposures=\(snapshot.totalExposureCount) "
                + "guided=\(snapshot.totalGuidedPracticeCount) "
                + "digest=\(snapshot.digest) worldMutation=none skillMutation=none"
        )
    }

    private func teachingStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.teachingSnapshot()
        return success(
            "Teaching gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 11 : 10) "
                + "apprenticeships=\(snapshot.apprenticeships.count) "
                + "demonstrations=\(snapshot.totalDemonstrationCount) "
                + "exposures=\(snapshot.totalExposureCount) "
                + "guided=\(snapshot.totalGuidedPracticeCount) "
                + "digest=\(snapshot.digest) worldMutation=none."
        )
    }
}
