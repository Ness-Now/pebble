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
                var receiptTransaction =
                    PebbleWorldEcologicalObservationReceiptTransaction()
                var receiptCommitted = false
                defer {
                    if !receiptCommitted {
                        try? rollbackWorldEcologicalObservationReceipts(
                            receiptTransaction
                        )
                    }
                }
                let observation = try recordLiveEcologicalObservation(
                    world: world, observerID: agentID,
                    session: &candidate, recorder: &recorder,
                    receiptTransaction: &receiptTransaction
                )
                try validateWorldEcologicalObservationReceipts(
                    for: candidate, dimension: world.dim.rawValue
                )
                session = candidate
                replayRecorder = recorder
                receiptTransaction.commit()
                receiptCommitted = true
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
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        for snapshot in session.snapshot().agents.sorted(by: { $0.id < $1.id }) {
            guard let observerID = AgentID(rawValue: snapshot.id) else {
                throw ControllerError.ecologicalObservationBoundary("invalid agent identity")
            }
            let observation = try recordLiveEcologicalObservation(
                world: world, observerID: observerID,
                session: &session, recorder: &recorder,
                receiptTransaction: &receiptTransaction
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
        var transaction =
            PebbleWorldEcologicalObservationReceiptTransaction()
        do {
            let observation = try recordLiveEcologicalObservation(
                world: world,
                observerID: observerID,
                session: &session,
                recorder: &recorder,
                receiptTransaction: &transaction
            )
            try validateWorldEcologicalObservationReceipts(
                for: session, dimension: world.dim.rawValue
            )
            transaction.commit()
            return observation
        } catch {
            try rollbackWorldEcologicalObservationReceipts(transaction)
            throw error
        }
    }

    @discardableResult
    func recordLiveEcologicalObservation(
        world: World,
        observerID: AgentID,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction
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
        try recordScannedEcologicalObservation(
            observation,
            world: world,
            session: &session,
            recorder: &recorder,
            receiptTransaction: &receiptTransaction
        )
        if session.productiveSourceLifecycleEnabled {
            let sourceObservations = productiveSourceObservations(
                from: observation,
                world: world,
                session: session
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

    func recordScannedEcologicalObservation(
        _ observation: AgentEcologicalObservation,
        world: World,
        session: inout AgentSimulationSession,
        recorder: inout AgentReplayRecorder?,
        receiptTransaction: inout
            PebbleWorldEcologicalObservationReceiptTransaction
    ) throws {
        try reconcileWorldEcologicalObservationReceiptRetention(
            for: session,
            transaction: &receiptTransaction
        )
        let store = try worldEcologicalObservationReceiptStore()
        let ordinal = (session.ecologicalObservationSnapshot()
            .totalObservationCount) + 1
        let receipt = store.makeReceipt(
            observation: observation,
            simulationID: session.simulationID,
            dimension: world.dim.rawValue,
            ordinal: ordinal
        )
        try store.insert(receipt)
        receiptTransaction.recordInsertion(receipt)
        trace(
            "ecological World receipt id=\(receipt.receiptID.rawValue) "
                + "observer=\(receipt.observerID.rawValue) "
                + "world=\(receipt.worldID) storage=\(receipt.storageIdentity) "
                + "dimension=\(receipt.dimension) "
                + "physicalTick=\(receipt.physicalWorldTick) "
                + "simulation=\(receipt.simulationID.rawValue) "
                + "simulationTick=\(receipt.simulationTick) "
                + "observationDigest=\(receipt.observation.digest) "
                + "receiptDigest=\(receipt.receiptDigest.rawValue) "
                + "authority=independent_world_side"
        )
        if try applyRecordedOperationIfActive(
            .recordEcologicalObservationWithPhysicalReceipt(
                observation,
                physicalReceiptID: receipt.receiptID
            ),
            session: &session,
            recorder: &recorder
        ) == nil {
            try session.recordEcologicalObservation(
                observation,
                physicalReceiptID: receipt.receiptID
            )
        }
        try reconcileWorldEcologicalObservationReceiptRetention(
            for: session,
            transaction: &receiptTransaction
        )
    }

    func productiveSourceObservations(
        from observation: AgentEcologicalObservation,
        world: World,
        session: AgentSimulationSession
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
            let executable =
                AgentWildSubsistenceMaterialPolicy.isGatherablePlant(
                    plant.plantKey
                )
            return source(
                key: "wild:\(plant.plantKey)@\(positionKey(plant.position))",
                domain: .wildGathering,
                material: "\(plant.plantKey)|\(plant.renewability.rawValue)"
                    + "|gatherable=\(executable)",
                position: plant.position,
                disposition: executable ? .viable : .temporarilyUnavailable,
                unavailableReason: executable
                    ? nil : "plant has no canonical gathering action"
            )
        }
        sources += observation.fishing.map { fishing in
            let hasPhysicalExecutor = session.snapshot().agents.contains { snapshot in
                guard let actorID = AgentID(rawValue: snapshot.id),
                      session.ecologicalObservations(for: actorID).first(where: {
                          $0.observation.isFresh(atSimulationTick: session.tick)
                              && $0.observation.fishing.contains {
                                  $0.position == fishing.position && $0.candidate
                              }
                      }) != nil,
                      let probe = probesByAgentId[snapshot.id],
                      probe.world === world, !probe.dead else {
                    return false
                }
                return probe.carriedItems.compactMap { $0 }.contains {
                    $0.count > 0 && itemDef($0.id).name == "fishing_rod"
                }
            }
            let viable = fishing.candidate && hasPhysicalExecutor
            return source(
                key: "fishing:\(fishing.waterKey)@"
                    + positionKey(fishing.position),
                domain: .fishing,
                material: "\(fishing.waterKey)|candidate=\(fishing.candidate)"
                    + "|physicalExecutor=\(hasPhysicalExecutor)",
                position: fishing.position,
                disposition: viable ? .viable : .temporarilyUnavailable,
                unavailableReason: viable ? nil
                    : fishing.candidate
                        ? "fishing rod unavailable"
                        : "fishing affordance unavailable"
            )
        }
        sources += observation.soils.map { soil in
            let compatible = soil.supportsCrop
                && (soil.tillable || soil.alreadyFarmland)
            let execution = liveAgriculturalSourceExecution(
                world: world,
                position: soil.position,
                isCrop: false,
                session: session
            )
            let viable = compatible && execution.executable
            return source(
                key: "agriculture:soil:\(soil.blockKey)@"
                    + positionKey(soil.position),
                domain: .agriculture,
                material: "\(soil.blockKey)|tillable=\(soil.tillable)"
                    + "|farmland=\(soil.alreadyFarmland)"
                    + "|hydrated=\(soil.hydrated.map(String.init) ?? "unknown")"
                    + "|supportsCrop=\(soil.supportsCrop)"
                    + "|\(execution.materialContract)",
                position: soil.position,
                disposition: viable ? .viable : .temporarilyUnavailable,
                unavailableReason: viable
                    ? nil
                    : compatible
                        ? execution.reason
                        : "soil cannot support a crop"
            )
        }
        sources += observation.crops.map { crop in
            let execution = liveAgriculturalSourceExecution(
                world: world,
                position: crop.position,
                isCrop: true,
                session: session
            )
            let viable = crop.mature && execution.executable
            return source(
                key: "agriculture:crop:\(crop.cropKey)@"
                    + positionKey(crop.position),
                domain: .agriculture,
                material: "\(crop.cropKey)|stage=\(crop.growthStage)"
                    + "/\(crop.maximumGrowthStage)|mature=\(crop.mature)"
                    + "|support=\(crop.supportBlockKey ?? "none")"
                    + "|\(execution.materialContract)",
                position: crop.position,
                disposition: viable ? .viable : .temporarilyUnavailable,
                unavailableReason: viable ? nil
                    : crop.mature
                        ? execution.reason
                        : "crop physically immature"
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
        let historical = (try? session
            .historicalEcologicalObservationValidations()) ?? []
        let activeObservers = historical.filter {
            $0.classification == .activeAtObservation
        }.count
        let deceasedObservers = historical.filter {
            $0.classification == .deceasedAfterObservationRetained
        }.count
        let date = snapshot.civilDate
        trace(
            "ecological observation state tick=\(session.tick) reason=\(reason) "
                + "enabled=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 12 : 2) receiptSchema=30 "
                + "civil=\(date.map { "\($0.year)-\($0.season.rawValue)-\($0.day)" } ?? "none") "
                + "retained=\(snapshot.observations.count) total=\(snapshot.totalObservationCount) "
                + "historicalActive=\(activeObservers) "
                + "historicalDeceased=\(deceasedObservers) "
                + "fresh=\(snapshot.freshCount) stale=\(snapshot.staleCount) "
                + "digest=\(snapshot.digest) mutation=none"
        )
    }

    private func ecologicalObservationStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let snapshot = session.ecologicalObservationSnapshot()
        let historical = (try? session
            .historicalEcologicalObservationValidations()) ?? []
        let activeObservers = historical.filter {
            $0.classification == .activeAtObservation
        }.count
        let deceasedObservers = historical.filter {
            $0.classification == .deceasedAfterObservationRetained
        }.count
        let date = snapshot.civilDate
        let sensor = ecologicalObservationSensor.snapshot
        return success(
            "Ecological observation gate=enabled active=\(snapshot.enabled ? 1 : 0) "
                + "schema=\(snapshot.enabled ? 12 : 2) "
                + "civil=\(date.map { "\($0.year)-\($0.season.rawValue)-\($0.day)" } ?? "none") "
                + "retained=\(snapshot.observations.count) total=\(snapshot.totalObservationCount) "
                + "historicalActive=\(activeObservers) "
                + "historicalDeceased=\(deceasedObservers) "
                + "fresh=\(snapshot.freshCount) stale=\(snapshot.staleCount) "
                + "scans=\(sensor.scans) cacheHits=\(sensor.cacheHits) "
                + "cacheMisses=\(sensor.cacheMisses) reads=\(sensor.worldReads) "
                + "digest=\(snapshot.digest)."
        )
    }
}
