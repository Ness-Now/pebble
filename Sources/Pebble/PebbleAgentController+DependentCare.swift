import PebbleAgents

extension PebbleAgentController {
    func handleDependentCare(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab care <on|status>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_KINSHIP=1", kinshipFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_HOUSEHOLDS=1", householdFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_CARE=1", dependentCareFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("care gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents care refused; missing gates: \(missing.joined(separator: ", "))"
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        guard candidate.survivalEnabled else {
            return failure("PebbleAgents care refused; survival must be enabled first.")
        }
        do {
            switch command {
            case "on":
                if !candidate.dependentCareEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setDependentCareEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setDependentCareEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceDependentCareState(candidate)
                return dependentCareStatus(candidate)
            case "status":
                traceDependentCareState(candidate)
                return dependentCareStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents care command failed: \(error)")
        }
    }

    func traceDependentCareState(_ session: AgentSimulationSession) {
        let snapshot = session.dependentCareSnapshot()
        trace(
            "care tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "assignments=\(snapshot.assignments.filter { $0.status == .active }.count) "
                + "needs=\(snapshot.activeNeeds.count) "
                + "engagements=\(snapshot.activeEngagements.count) "
                + "atRisk=\(snapshot.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "digest=\(snapshot.digest) worldMutation=none"
        )
    }

    private func dependentCareStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.dependentCareSnapshot()
        let assignments = snapshot.assignments.filter { $0.status == .active }.map {
            "\($0.dependentID.rawValue)->\($0.caregiverID.rawValue)@\($0.householdID.rawValue)"
        }.joined(separator: ",")
        return success(
            "Care gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 9 : 8) "
                + "assignments=\(assignments.isEmpty ? "none" : assignments) "
                + "needs=\(snapshot.activeNeeds.count) "
                + "engagements=\(snapshot.activeEngagements.count) "
                + "atRisk=\(snapshot.atRiskDependentIDs.map(\.rawValue).joined(separator: ",")) "
                + "digest=\(snapshot.digest) worldMutation=none."
        )
    }
}
