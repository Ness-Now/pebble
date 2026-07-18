import PebbleAgents

extension PebbleAgentController {
    func handleHousehold(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab household <on|status>"
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
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("household gates refused missing=\(missing.joined(separator: ","))")
            return failure(
                "PebbleAgents households refused; missing gates: \(missing.joined(separator: ", "))"
            )
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        do {
            switch command {
            case "on":
                if !candidate.householdsEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setHouseholdsEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setHouseholdsEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceHouseholdState(candidate)
                return householdStatus(candidate)
            case "status":
                traceHouseholdState(candidate)
                return householdStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents household command failed: \(error)")
        }
    }

    func traceHouseholdState(_ session: AgentSimulationSession) {
        let snapshot = session.householdSnapshot()
        trace(
            "household tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "households=\(snapshot.households.count) "
                + "active=\(snapshot.households.filter { $0.status == .active }.count) "
                + "memberships=\(snapshot.currentMemberships.count) "
                + "nextOrdinal=\(snapshot.nextHouseholdOrdinal ?? -1) "
                + "digest=\(snapshot.digest) worldMutation=none"
        )
    }

    private func householdStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.householdSnapshot()
        let memberships = snapshot.currentMemberships.map {
            "\($0.agentID.rawValue)->\($0.householdID.rawValue)@"
                + "\($0.residenceAnchor.x),\($0.residenceAnchor.y),\($0.residenceAnchor.z)"
        }.joined(separator: ",")
        return success(
            "Household gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 8 : 7) "
                + "households=\(snapshot.households.count) "
                + "activeHouseholds=\(snapshot.households.filter { $0.status == .active }.count) "
                + "memberships=\(snapshot.currentMemberships.count) "
                + "records=\(memberships.isEmpty ? "none" : memberships) "
                + "digest=\(snapshot.digest) worldMutation=none."
        )
    }
}
