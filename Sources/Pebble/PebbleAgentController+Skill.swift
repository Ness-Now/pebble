import PebbleAgents

extension PebbleAgentController {
    func handleSkills(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab skills <on|status>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_SKILLS=1", skillFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("skill gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents skills refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        do {
            switch command {
            case "on":
                if !candidate.skillsEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setSkillsEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setSkillsEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceSkillState(candidate)
                return skillStatus(candidate)
            case "status":
                traceSkillState(candidate)
                return skillStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents skills command failed: \(error)")
        }
    }

    func traceSkillState(_ session: AgentSimulationSession) {
        guard session.skillsEnabled else { return }
        let snapshot = session.skillSnapshot()
        let profiles = snapshot.profiles.map { profile in
            profile.agentID.rawValue + ":" + AgentSkillDomain.allCases.map { domain in
                "\(domain.rawValue)=\(profile.practiceUnits(in: domain))/"
                    + session.skillLevel(agentID: profile.agentID, domain: domain).rawValue
            }.joined(separator: ",")
        }.joined(separator: ";")
        trace(
            "skills tick=\(session.tick) profiles=\(snapshot.profiles.count) "
                + "credits=\(snapshot.totalPracticeCreditCount) "
                + "units=\(snapshot.totalPracticeUnits) profilesState=\(profiles) "
                + "digest=\(snapshot.digest)"
        )
    }

    private func skillStatus(_ session: AgentSimulationSession) -> PebbleAgentCommandResult {
        let snapshot = session.skillSnapshot()
        return success(
            "Skills gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 10 : 9) "
                + "profiles=\(snapshot.profiles.count) "
                + "credits=\(snapshot.totalPracticeCreditCount) "
                + "units=\(snapshot.totalPracticeUnits) "
                + "digest=\(snapshot.digest)."
        )
    }
}
