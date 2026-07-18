import PebbleAgents

extension PebbleAgentController {
    func handleKinship(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab kinship <on|status>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_LIFECYCLE=1", lifecycleFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_KINSHIP=1", kinshipFeatureEnabled),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            trace("kinship gates refused missing=\(missing.joined(separator: ","))")
            return failure("PebbleAgents kinship refused; missing gates: \(missing.joined(separator: ", "))")
        }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        do {
            switch command {
            case "on":
                if !candidate.kinshipEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setKinshipEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setKinshipEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                    traceKinshipState(candidate)
                }
                return kinshipStatus(candidate)
            case "status":
                traceKinshipState(candidate)
                return kinshipStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents kinship command failed: \(error)")
        }
    }

    func traceKinshipState(_ session: AgentSimulationSession) {
        let snapshot = session.kinshipSnapshot()
        let latest = snapshot.parentageRecords.last
        trace(
            "kinship tick=\(session.tick) enabled=\(snapshot.enabled ? 1 : 0) "
                + "people=\(snapshot.historicalPersons.count) "
                + "parentages=\(snapshot.parentageRecords.count) "
                + "child=\(latest?.childID.rawValue ?? "none") "
                + "parents=\(latest?.canonicalParentIDs.map(\.rawValue).joined(separator: ",") ?? "none") "
                + "digest=\(snapshot.digest) worldMutation=none"
        )
    }

    private func kinshipStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.kinshipSnapshot()
        let records = snapshot.parentageRecords.map {
            "\($0.childID.rawValue)<-\($0.canonicalParentIDs.map(\.rawValue).joined(separator: "+"))"
        }.joined(separator: ",")
        return success(
            "Kinship gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 7 : 6) "
                + "people=\(snapshot.historicalPersons.count) "
                + "parentages=\(snapshot.parentageRecords.count) records=\(records.isEmpty ? "none" : records) "
                + "digest=\(snapshot.digest) worldMutation=none."
        )
    }
}
