import PebbleAgents

extension PebbleAgentController {
    func handleSettlementMetrics(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab settlement <on|off|status|clear>"
        guard let command = arguments.first?.lowercased(), arguments.count == 1 else {
            return failure(usage)
        }
        guard featureEnabled, populationFeatureEnabled, multiscaleFeatureEnabled else {
            return failure(
                "PebbleAgents settlement metrics disabled. Set PEBBLELAB_APP_AGENTS=1, "
                    + "PEBBLELAB_APP_AGENTS_POPULATION=1, and "
                    + "PEBBLELAB_APP_AGENTS_MULTISCALE=1 before launch."
            )
        }
        guard var candidate = session else {
            return failure("No active PebbleAgents session.")
        }
        do {
            switch command {
            case "on":
                guard candidate.populationEnabled else {
                    return failure(
                        "Settlement metrics enable refused: population registry is disabled."
                    )
                }
                if candidate.settlementMetricsEnabled {
                    return settlementMetricsStatus(candidate)
                }
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .setSettlementMetricsEnabled(true, configuration: .live),
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.setSettlementMetricsEnabled(true)
                }
                session = candidate
                replayRecorder = recorder
                let summary = candidate.settlementMetricsSummary()
                trace(
                    "settlement metrics initialized tick=\(summary.microTick) "
                        + "settlement=\(summary.settlementID?.rawValue ?? "none") "
                        + "macroSequence=\(summary.macroSequence) "
                        + "nextPulse=\(summary.nextPulseTick ?? -1) mutation=none"
                )
                return success(
                    "Settlement metrics enabled: settlement="
                        + "\(summary.settlementID?.rawValue ?? "none") "
                        + "interval=\(summary.macroIntervalTicks ?? 0) "
                        + "nextPulse=\(summary.nextPulseTick ?? -1)."
                )
            case "off":
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .setSettlementMetricsEnabled(false, configuration: .live),
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.setSettlementMetricsEnabled(false)
                }
                session = candidate
                replayRecorder = recorder
                trace("settlement metrics disabled tick=\(candidate.tick) mutation=none")
                return success("Settlement metrics disabled; agents and population unchanged.")
            case "status":
                return settlementMetricsStatus(candidate)
            case "clear":
                var recorder = replayRecorder
                if try applyRecordedOperationIfActive(
                    .clearSettlementMetrics,
                    session: &candidate,
                    recorder: &recorder
                ) == nil {
                    try candidate.clearSettlementMetrics()
                }
                session = candidate
                replayRecorder = recorder
                let summary = candidate.settlementMetricsSummary()
                trace(
                    "settlement metrics cleared tick=\(candidate.tick) "
                        + "macroSequence=\(summary.macroSequence) "
                        + "nextPulse=\(summary.nextPulseTick ?? -1) mutation=none"
                )
                return success(
                    "Settlement metrics history cleared; sequence="
                        + "\(summary.macroSequence) nextPulse=\(summary.nextPulseTick ?? -1)."
                )
            default:
                return failure(usage)
            }
        } catch {
            return failure("PebbleAgents settlement metrics command failed: \(error)")
        }
    }

    func handleScaleStatus(_ arguments: [String]) -> PebbleAgentCommandResult {
        guard arguments.count == 1, arguments[0].lowercased() == "status" else {
            return failure("Usage: /lab scale status")
        }
        guard let session else { return failure("No active PebbleAgents session.") }
        let interval = session.settlementMetricsSummary().macroIntervalTicks
            ?? AgentSettlementMetricsConfiguration.live.macroIntervalTicks
        return success(
            "scale microAgents=\(session.snapshot().agentCount) microTicks=every_tick "
                + "macroSettlement=every_\(interval)_ticks "
                + "coarseAgentExecution=off offScreenAgents=0"
        )
    }

    func traceSettlementMetricsState(at tick: Int) {
        guard let session, session.settlementMetricsEnabled,
              let frame = session.settlementMetricsSnapshot().frames.last,
              frame.toTickInclusive == tick else { return }
        trace(
            "settlement frame tick=\(tick) id=\(frame.frameID.rawValue) "
                + "sequence=\(frame.macroSequence.rawValue) "
                + "window=\(frame.fromTickExclusive)..\(frame.toTickInclusive) "
                + "causal=\(frame.causalSequenceStartExclusive)..\(frame.causalSequenceEndInclusive) "
                + "coverage=\(frame.causalCoverageComplete ? "complete" : "incomplete") "
                + "condition=\(frame.condition.rawValue) reason=\(frame.reasonCode) "
                + "population=\(frame.population.members)/\(frame.population.capacity) "
                + "residents=\(frame.population.residents) migrants=\(frame.population.migrants) "
                + "urgent=\(frame.activity.urgentCount) migrating=\(frame.activity.migratingCount) "
                + "engaged=\(frame.activity.engagedCount) stable=\(frame.activity.stableCount) "
                + "movementDelta=\(frame.throughput.movementDelta) "
                + "distanceDelta=\(frame.throughput.distanceDelta) "
                + "materialDelta=\(frame.throughput.materialActivityDelta) "
                + "socialDelta=\(frame.social.eventDelta) "
                + "physicalDelta=\(frame.physical.eventDelta) "
                + "cooperationDelta=\(frame.cooperation.eventDelta) "
                + "populationDelta=\(frame.populationEventDelta) digest=\(frame.digest)"
        )
        let classifications = frame.activity.classifications.map {
            "\($0.agentID.rawValue):\($0.tier.rawValue):\($0.reason)"
        }.joined(separator: ",")
        trace("settlement classifications tick=\(tick) \(classifications)")
    }

    private func settlementMetricsStatus(
        _ session: AgentSimulationSession
    ) -> PebbleAgentCommandResult {
        let summary = session.settlementMetricsSummary()
        let coverage = summary.causalCoverageComplete.map {
            $0 ? "complete" : "incomplete"
        } ?? "none"
        return success(
            "settlement gate=enabled enabled=\(summary.enabled ? 1 : 0) "
                + "settlement=\(summary.settlementID?.rawValue ?? "none") "
                + "microTick=\(summary.microTick) "
                + "macroInterval=\(summary.macroIntervalTicks ?? 0) "
                + "macroSequence=\(summary.macroSequence) "
                + "lastPulse=\(summary.lastPulseTick ?? -1) "
                + "nextPulse=\(summary.nextPulseTick ?? -1) "
                + "frames=\(summary.retainedFrameCount) "
                + "evicted=\(summary.evictedFrameCount) "
                + "condition=\(summary.condition?.rawValue ?? "none") "
                + "population=\(summary.population)/\(summary.capacity) "
                + "urgent=\(summary.urgent) migrating=\(summary.migrating) "
                + "engaged=\(summary.engaged) stable=\(summary.stable) "
                + "movementDelta=\(summary.movementDelta) "
                + "materialDelta=\(summary.materialActivityDelta) "
                + "socialDelta=\(summary.socialActivityDelta) "
                + "cooperationDelta=\(summary.cooperationActivityDelta) "
                + "coverage=\(coverage) digest=\(summary.digest)"
        )
    }
}
