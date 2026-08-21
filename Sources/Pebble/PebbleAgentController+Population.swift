import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handlePopulation(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab population <on|off|status|clear>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard populationFeatureEnabled else {
            return failure(
                "PebbleAgents population disabled. Set PEBBLELAB_APP_AGENTS_POPULATION=1 before launch."
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        do {
            switch command {
            case "on":
                guard !candidate.populationEnabled else { return populationStatus(candidate) }
                guard let anchor else { throw ControllerError.missingSession }
                let occupied = occupiedPopulationPositions(
                    session: candidate,
                    player: player
                )
                guard let reception = migrationAdmissionAdapter.selectReception(
                    world: world,
                    settlementAnchor: anchor,
                    occupiedPositions: occupied
                ) else {
                    return failure("Population enable refused: no safe local reception position.")
                }
                let populationConfiguration = populationScaleFeatureEnabled
                    ? try AgentPopulationConfiguration(
                        maximumActivePopulation: 24
                    )
                    : .live
                var recorder = replayRecorder
                let operation = AgentReplayOperation.setPopulationEnabled(
                    true,
                    settlementAnchor: anchor,
                    receptionPosition: reception,
                    configuration: populationConfiguration
                )
                if try applyRecordedOperationIfActive(
                    operation,
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.setPopulationEnabled(
                        true,
                        settlementAnchor: anchor,
                        receptionPosition: reception,
                        configuration: populationConfiguration
                    )
                }
                session = candidate
                replayRecorder = recorder
                let summary = candidate.populationSummary()
                trace(
                    "population initialized settlement=\(summary.settlementID?.rawValue ?? "none") "
                        + "capacity=\(summary.capacity) founders=\(summary.founderCount) "
                        + "members=\(summary.memberCount) nextOrdinal=\(summary.nextPopulationOrdinal ?? -1) "
                        + "reception=\(positionText(reception))"
                )
                return success(
                    "Population enabled: settlement=\(summary.settlementID?.rawValue ?? "none") "
                        + "founders=\(summary.founderCount) members=\(summary.memberCount)/\(summary.capacity) "
                        + "nextOrdinal=\(summary.nextPopulationOrdinal ?? -1) "
                        + "reception=\(positionText(reception))."
                )
            case "off":
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .setPopulationEnabled(
                        false,
                        settlementAnchor: nil,
                        receptionPosition: nil,
                        configuration: .live
                    ),
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.setPopulationEnabled(false)
                }
                session = candidate
                replayRecorder = recorder
                return success("Population disabled.")
            case "status":
                return populationStatus(candidate)
            case "clear":
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .clearPopulationDiagnostics,
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.clearPopulationDiagnostics()
                }
                session = candidate
                replayRecorder = recorder
                return success("Population terminal diagnostics cleared; members unchanged.")
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents population command failed: \(error)")
        }
    }

    func handleMigration(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab migration <admit|status>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard populationFeatureEnabled else {
            return failure(
                "PebbleAgents population disabled. Set PEBBLELAB_APP_AGENTS_POPULATION=1 before launch."
            )
        }
        guard let current = session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        switch command {
        case "status":
            return migrationStatus(current)
        case "admit":
            guard current.populationEnabled,
                  let settlement = current.populationSnapshot().settlement else {
                return failure("Migration admission refused: population registry is disabled.")
            }
            do {
                let observationResult = try migrationAdmissionAdapter.observeAdmission(
                    world: world,
                    settlement: settlement,
                    occupiedPositions: occupiedPopulationPositions(
                        session: current,
                        player: player
                    )
                )
                var candidate = current
                var candidateRecorder = replayRecorder
                let operation = AgentReplayOperation.admitMigration(
                    intent: AgentMigrationAdmissionIntent(),
                    observation: observationResult.observation
                )
                if try applyRecordedOperationIfActive(
                    operation,
                    session: &candidate,
                    recorder: &candidateRecorder
                ) == nil {
                    _ = try candidate.admitMigration(
                        intent: AgentMigrationAdmissionIntent(),
                        observation: observationResult.observation
                    )
                }
                guard let record = candidate.migrationSnapshot().migrations.last,
                      let agent = candidate.snapshot().agents.first(where: {
                          $0.id == record.migrantID.rawValue
                      }) else {
                    throw ControllerError.populationBoundary("candidate migrant missing")
                }
                let probe = try createProbe(for: agent, in: world)
                do {
                    let expected = candidate.expectedActiveAgentIDs().map(\.rawValue)
                    let worldIDs = world.entities.compactMap {
                        ($0 as? LabCoreAgentEntity)?.labAgentId
                    }.sorted()
                    guard worldIDs == expected else {
                        throw ControllerError.invalidProbeSet(worldIDs)
                    }
                    probesByAgentId[agent.id] = probe
                    session = candidate
                    replayRecorder = candidateRecorder
                } catch {
                    guard removeLabCoreAgentProbe(probe, from: world) else {
                        throw ControllerError.populationBoundary("migrant probe rollback failed")
                    }
                    throw error
                }
                let summary = candidate.populationSummary()
                let route = record.route.map(positionText).joined(separator: ">")
                trace(
                    "migration admitted id=\(record.migrationID.rawValue) migrant=\(agent.id) "
                        + "origin=\(record.origin.rawValue) destination=\(record.destinationSettlementID.rawValue) "
                        + "entry=\(positionText(record.entryPosition)) reception=\(positionText(record.receptionPosition)) "
                        + "routeLength=\(record.route.count) route=\(route) candidates=\(observationResult.candidatesConsidered) "
                        + "validCandidates=\(observationResult.validCandidateCount) probes=\(probesByAgentId.keys.sorted().joined(separator: ",")) "
                        + "members=\(summary.memberCount) nextOrdinal=\(summary.nextPopulationOrdinal ?? -1)"
                )
                return success(
                    "Migration admitted: \(record.migrationID.rawValue) migrant=\(agent.id) "
                        + "entry=\(positionText(record.entryPosition)) reception=\(positionText(record.receptionPosition)) "
                        + "routeLength=\(record.route.count) population=\(summary.memberCount)/\(summary.capacity)."
                )
            } catch {
                return failure("PebbleAgents migration admission failed: \(error)")
            }
        default:
            return failure(usage)
        }
    }

    func tracePopulationState(at tick: Int) {
        guard let session, session.populationEnabled else { return }
        let summary = session.populationSummary()
        let latest = session.migrationSnapshot().migrations.last
        trace(
            "population tick=\(tick) settlement=\(summary.settlementID?.rawValue ?? "none") "
                + "members=\(summary.memberCount)/\(summary.capacity) founders=\(summary.founderCount) "
                + "residents=\(summary.residentCount) migrating=\(summary.migratingCount) "
                + "nextOrdinal=\(summary.nextPopulationOrdinal ?? -1) "
                + "migration=\(latest?.migrationID.rawValue ?? "none") "
                + "migrant=\(latest?.migrantID.rawValue ?? "none") "
                + "status=\(latest?.status.rawValue ?? "none") "
                + "cursor=\(latest?.routeCursor ?? 0)/\(max(0, (latest?.route.count ?? 1) - 1)) "
                + "deadline=\(latest?.deadlineTick ?? 0) events=\(summary.populationCausalEventCount) "
                + "digest=\(summary.digest)"
        )
    }

    private func populationStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let summary = session.populationSummary()
        let latest = session.migrationSnapshot().migrations.last
        let message = "population gate=enabled enabled=\(summary.enabled ? 1 : 0) "
            + "settlement=\(summary.settlementID?.rawValue ?? "none") capacity=\(summary.capacity) "
            + "members=\(summary.memberCount) founders=\(summary.founderCount) "
            + "residents=\(summary.residentCount) migrating=\(summary.migratingCount) "
            + "nextOrdinal=\(summary.nextPopulationOrdinal ?? -1) "
            + "activeMigration=\(summary.activeMigrationCount) "
            + "latestMigrant=\(latest?.migrantID.rawValue ?? "none") "
            + "latestMigrationStatus=\(latest?.status.rawValue ?? "none") "
            + "populationEvents=\(summary.populationCausalEventCount) "
            + "evictions=\(summary.evictionCounts.terminalMigrations),\(summary.evictionCounts.diagnostics) "
            + "digest=\(summary.digest)"
        trace(message)
        return success(message)
    }

    private func migrationStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        guard let migration = session.migrationSnapshot().migrations.last else {
            return success("migration status none")
        }
        let causalCount = [
            migration.proposedEventID,
            migration.admittedEventID,
            migration.startedEventID,
            migration.arrivedEventID,
            migration.lastMovementEventID,
        ].compactMap { $0 }.count
        let message = "migration id=\(migration.migrationID.rawValue) "
            + "migrant=\(migration.migrantID.rawValue) origin=\(migration.origin.rawValue) "
            + "destination=\(migration.destinationSettlementID.rawValue) "
            + "entry=\(positionText(migration.entryPosition)) "
            + "reception=\(positionText(migration.receptionPosition)) "
            + "routeLength=\(migration.route.count) routeCursor=\(migration.routeCursor) "
            + "status=\(migration.status.rawValue) deadline=\(migration.deadlineTick) "
            + "lastFailure=\(migration.failure?.rawValue ?? "none") causalEvents=\(causalCount)"
        trace(message)
        return success(message)
    }

    private func occupiedPopulationPositions(
        session: AgentSimulationSession,
        player: Player
    ) -> Set<AgentPosition> {
        var positions = Set(session.snapshot().agents.map(\.position))
        positions.insert(AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        ))
        return positions
    }
}
