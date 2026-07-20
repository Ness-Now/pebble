import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleEcologicalObservation(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab ecological-observation <on|status|scan|proof>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        let dependencies = [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PERSISTENCE=1", persistenceFeatureEnabled),
            ("PEBBLELAB_APP_AGENTS_POPULATION=1", populationFeatureEnabled),
            (
                "PEBBLELAB_APP_AGENTS_ECOLOGICAL_OBSERVATION=1",
                ecologicalObservationFeatureEnabled
            ),
        ]
        let missing = dependencies.filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "PebbleAgents ecological observation refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        guard candidate.populationEnabled else {
            return failure("Ecological observation requires population.")
        }
        do {
            switch command {
            case "on":
                if !candidate.ecologicalObservationEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setEcologicalObservationEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setEcologicalObservationEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                traceEcologicalObservationState(candidate, reason: "activated")
                return ecologicalObservationStatus(candidate)
            case "status":
                traceEcologicalObservationState(candidate, reason: "status")
                return ecologicalObservationStatus(candidate)
            case "scan":
                guard candidate.ecologicalObservationEnabled else {
                    return failure("Ecological observation is not enabled.")
                }
                guard let focus = focusedAgentId,
                      let agentID = AgentID(rawValue: focus) else {
                    return failure("Ecological observation requires a focused agent.")
                }
                var recorder = replayRecorder
                let observation = try recordLiveEcologicalObservation(
                    world: world, observerID: agentID,
                    session: &candidate, recorder: &recorder
                )
                session = candidate
                replayRecorder = recorder
                traceEcologicalObservation(observation, reason: "command")
                return success(
                    "Ecological observation recorded for \(focus): "
                        + "results=\(observation.diagnostics.resultsEmitted) "
                        + "reads=\(observation.diagnostics.worldReads) "
                        + "digest=\(observation.digest)."
                )
            case "proof":
                return handleEcologicalObservationProof(world: world, player: player)
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents ecological observation command failed: \(error)")
        }
    }

    func recordLiveEcologicalObservations(
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws {
        for snapshot in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
            guard let observerID = AgentID(rawValue: snapshot.id) else {
                throw ControllerError.ecologicalObservationBoundary("invalid agent identity")
            }
            let observation = try recordLiveEcologicalObservation(
                world: world, observerID: observerID,
                session: &session, recorder: &recorder
            )
            traceEcologicalObservation(observation, reason: "cognitive-tick")
        }
    }

    @discardableResult
    func recordLiveEcologicalObservation(
        world: World,
        observerID: AgentID,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?
    ) throws -> AgentEcologicalObservation {
        guard let probe = probesByAgentId[observerID.rawValue],
              probe.world === world, !probe.dead else {
            throw ControllerError.ecologicalObservationBoundary(
                "missing, dead, or stale physical embodiment for \(observerID.rawValue)"
            )
        }
        guard let civilDate = session.civilDate(),
              let configuration = session.ecologicalObservationSnapshot().configuration else {
            throw ControllerError.ecologicalObservationBoundary("calendar unavailable")
        }
        let origin = AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
        let observation = ecologicalObservationSensor.scan(
            world: world, observerID: observerID, origin: origin,
            worldContextKey: ecologicalObservationWorldContextKey(world),
            dimensionKey: ecologicalObservationDimensionKey(world.dim),
            simulationTick: session.tick, civilDate: civilDate,
            configuration: configuration
        )
        if try applyRecordedOperationIfActive(
            .recordEcologicalObservation(observation),
            session: &session,
            recorder: &recorder
        ) == nil {
            try session.recordEcologicalObservation(observation)
        }
        return observation
    }

    func ecologicalObservationWorldContextKey(_ world: World) -> String {
        let raw = persistenceWorldID ?? "seed-\(world.seed)"
        return raw.replacingOccurrences(of: " ", with: "_")
    }

    func ecologicalObservationDimensionKey(_ dimension: Dim) -> String {
        switch dimension {
        case .overworld: return "overworld"
        case .nether: return "nether"
        case .end: return "end"
        }
    }

    func traceEcologicalObservation(
        _ observation: AgentEcologicalObservation,
        reason: String
    ) {
        let date = observation.civilDate
        let diagnostics = observation.diagnostics
        trace(
            "ecological observation tick=\(observation.observedAtSimulationTick) "
                + "observer=\(observation.observerID.rawValue) reason=\(reason) "
                + "civil=\(date.year)-\(date.season.rawValue)-\(date.day) "
                + "worldTick=\(observation.physicalWorldTick) "
                + "biome=\(observation.biome?.biomeKey ?? "unknown") "
                + "water=\(observation.water.count) soils=\(observation.soils.count) "
                + "crops=\(observation.crops.count) plants=\(observation.plants.count) "
                + "animals=\(observation.animals.count) fishing=\(observation.fishing.count) "
                + "weather=\(observation.weather.kind.rawValue) "
                + "reads=\(diagnostics.worldReads) cells=\(diagnostics.cellsConsidered) "
                + "chunks=\(diagnostics.chunksTouched) unavailable=\(diagnostics.chunksUnavailable) "
                + "cache=\(diagnostics.cacheHits):\(diagnostics.cacheMisses) "
                + "completion=\(diagnostics.completion.rawValue) digest=\(observation.digest) "
                + "worldMutation=none materialMutation=none"
        )
    }

    func traceEcologicalObservationState(
        _ session: AgentSimulationSession,
        reason: String
    ) {
        let snapshot = session.ecologicalObservationSnapshot()
        let date = snapshot.civilDate
        trace(
            "ecological observation state tick=\(session.tick) reason=\(reason) "
                + "enabled=\(snapshot.enabled ? 1 : 0) schema=\(snapshot.enabled ? 12 : 2) "
                + "civil=\(date.map { "\($0.year)-\($0.season.rawValue)-\($0.day)" } ?? "none") "
                + "retained=\(snapshot.observations.count) total=\(snapshot.totalObservationCount) "
                + "fresh=\(snapshot.freshCount) stale=\(snapshot.staleCount) "
                + "digest=\(snapshot.digest) mutation=none"
        )
    }

    private func ecologicalObservationStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.ecologicalObservationSnapshot()
        let date = snapshot.civilDate
        let sensor = ecologicalObservationSensor.snapshot
        return success(
            "Ecological observation gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 12 : 2) "
                + "civil=\(date.map { "\($0.year)-\($0.season.rawValue)-\($0.day)" } ?? "none") "
                + "retained=\(snapshot.observations.count) total=\(snapshot.totalObservationCount) "
                + "fresh=\(snapshot.freshCount) stale=\(snapshot.staleCount) "
                + "scans=\(sensor.scans) cacheHits=\(sensor.cacheHits) "
                + "cacheMisses=\(sensor.cacheMisses) reads=\(sensor.worldReads) "
                + "digest=\(snapshot.digest)."
        )
    }
}
