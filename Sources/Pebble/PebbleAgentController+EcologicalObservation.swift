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
        if session.productiveSourceLifecycleEnabled {
            if try applyRecordedOperationIfActive(
                .reviewProductiveSources,
                session: &session,
                recorder: &recorder
            ) == nil {
                _ = try session.reviewProductiveSources()
            }
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
        if session.productiveSourceLifecycleEnabled {
            let sourceObservations = productiveSourceObservations(
                from: observation
            )
            if !sourceObservations.isEmpty {
                if try applyRecordedOperationIfActive(
                    .recordProductiveSourceObservations(sourceObservations),
                    session: &session,
                    recorder: &recorder
                ) == nil {
                    _ = try session.recordProductiveSourceObservations(
                        sourceObservations
                    )
                }
            }
        }
        return observation
    }

    func productiveSourceObservations(
        from observation: AgentEcologicalObservation
    ) -> [AgentProductiveSourceObservation] {
        func positionKey(_ position: AgentPosition) -> String {
            "\(position.x),\(position.y),\(position.z)"
        }
        func source(
            key: String,
            domain: AgentAutonomousActivityDomain,
            material: String,
            position: AgentPosition,
            disposition: AgentProductiveSourceDisposition,
            unavailableReason: String? = nil
        ) -> AgentProductiveSourceObservation {
            AgentProductiveSourceObservation(
                sourceKey: key,
                domain: domain,
                materialFingerprint: AgentAutonomousActivityDigest.make(material),
                observedAtTick: observation.observedAtSimulationTick,
                observerID: observation.observerID,
                physicalPosition: position,
                disposition: disposition,
                observationReference: "ecology:\(observation.digest)",
                temporarilyUnavailableReason: unavailableReason,
                renewalReason: disposition == .viable
                    ? "fresh local material observation" : nil
            )
        }
        var sources = observation.plants.map { plant in
            source(
                key: "wild:\(plant.plantKey)@\(positionKey(plant.position))",
                domain: .wildGathering,
                material: "\(plant.plantKey)|\(plant.renewability.rawValue)",
                position: plant.position,
                disposition: .viable
            )
        }
        sources += observation.fishing.map { fishing in
            source(
                key: "fishing:\(fishing.waterKey)@"
                    + positionKey(fishing.position),
                domain: .fishing,
                material: "\(fishing.waterKey)|candidate=\(fishing.candidate)",
                position: fishing.position,
                disposition: fishing.candidate
                    ? .viable : .temporarilyUnavailable,
                unavailableReason: fishing.candidate
                    ? nil : "fishing affordance unavailable"
            )
        }
        sources += observation.soils.map { soil in
            let viable = soil.supportsCrop
                && (soil.tillable || soil.alreadyFarmland)
            return source(
                key: "agriculture:soil:\(soil.blockKey)@"
                    + positionKey(soil.position),
                domain: .agriculture,
                material: "\(soil.blockKey)|tillable=\(soil.tillable)"
                    + "|farmland=\(soil.alreadyFarmland)"
                    + "|hydrated=\(soil.hydrated.map(String.init) ?? "unknown")"
                    + "|supportsCrop=\(soil.supportsCrop)",
                position: soil.position,
                disposition: viable ? .viable : .temporarilyUnavailable,
                unavailableReason: viable
                    ? nil : "soil cannot support a crop"
            )
        }
        sources += observation.crops.map { crop in
            source(
                key: "agriculture:crop:\(crop.cropKey)@"
                    + positionKey(crop.position),
                domain: .agriculture,
                material: "\(crop.cropKey)|stage=\(crop.growthStage)"
                    + "/\(crop.maximumGrowthStage)|mature=\(crop.mature)"
                    + "|support=\(crop.supportBlockKey ?? "none")",
                position: crop.position,
                disposition: crop.mature
                    ? .viable : .temporarilyUnavailable,
                unavailableReason: crop.mature
                    ? nil : "crop physically immature"
            )
        }
        return sources.sorted {
            if $0.domain != $1.domain {
                return $0.domain.rawValue < $1.domain.rawValue
            }
            return $0.sourceKey < $1.sourceKey
        }
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
