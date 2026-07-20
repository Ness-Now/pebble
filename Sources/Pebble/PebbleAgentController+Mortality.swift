import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleMortality(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab mortality <on|off|status|clear>"
        guard arguments.count == 1 else { return failure(usage) }
        guard var candidate = session else { return failure("No active PebbleAgents session.") }
        let subcommand = arguments[0].lowercased()
        do {
            switch subcommand {
            case "on":
                guard mortalityFeatureEnabled else {
                    return failure(
                        "Mortality disabled. Set PEBBLELAB_APP_AGENTS_MORTALITY=1 before launch."
                    )
                }
                guard !candidate.mortalityEnabled else {
                    return failure("Mortality is already enabled.")
                }
                if try applyCommandMutationIfRecording(
                    .setMortalityEnabled(true, configuration: .live),
                    session: &candidate
                ) == nil {
                    try candidate.setMortalityEnabled(true)
                }
                session = candidate
                let summary = candidate.mortalitySummary()
                trace(
                    "mortality enabled tick=\(candidate.tick) active=\(summary.activeAgentCount) "
                        + "deaths=0 terminal=0 mutation=none"
                )
                return success(
                    "Mortality enabled: active=\(summary.activeAgentCount) "
                        + "maximumDeathsPerTick=\(AgentMortalityConfiguration.live.maximumDeathsPerTick) "
                        + "records=\(AgentMortalityConfiguration.live.maximumRetainedDeathRecords)."
                )
            case "off":
                guard candidate.mortalityEnabled else {
                    return failure("Mortality is already disabled.")
                }
                if try applyCommandMutationIfRecording(
                    .setMortalityEnabled(false, configuration: .live),
                    session: &candidate
                ) == nil {
                    try candidate.setMortalityEnabled(false)
                }
                session = candidate
                trace("mortality disabled tick=\(candidate.tick) mutation=none")
                return success("Mortality disabled; active agents unchanged.")
            case "clear":
                guard candidate.mortalityEnabled else {
                    return failure("Mortality is disabled.")
                }
                if try applyCommandMutationIfRecording(
                    .clearMortalityDiagnostics,
                    session: &candidate
                ) == nil {
                    try candidate.clearMortalityDiagnostics()
                }
                session = candidate
                trace("mortality diagnostics cleared tick=\(candidate.tick)")
                return success("Mortality exit diagnostics cleared; death records unchanged.")
            case "status":
                return mortalityStatus(candidate)
            default:
                return failure(usage)
            }
        } catch {
            return failure("Mortality command failed: \(error)")
        }
    }

    func handlePopulationExits(_ arguments: [String]) -> PebbleAgentCommandResult {
        guard arguments == ["status"] else {
            return failure("Usage: /lab exits status")
        }
        guard let session else { return failure("No active PebbleAgents session.") }
        let exits = session.populationExitSnapshot()
        let latest = exits.last
        let message = "population exits count=\(exits.count) "
            + "latestDeath=\(latest?.deathID.rawValue ?? "none") "
            + "agent=\(latest?.agentID.rawValue ?? "none") "
            + "tick=\(latest?.tick ?? -1) "
            + "population=\(latest.map { "\($0.populationBefore)>\($0.populationAfter)" } ?? "none")"
        trace(message)
        return success(message)
    }

    func reconcileMortalityProbes(
        previous: AgentSessionSnapshot,
        current: AgentSimulationSession,
        world: World
    ) throws {
        let expected = current.expectedActiveAgentIDs().map(\.rawValue).sorted()
        let previousIDs = previous.agents.map(\.id).sorted()
        let removedIDs = previousIDs.filter { !expected.contains($0) }
        guard removedIDs.allSatisfy({ id in
            guard let probe = probesByAgentId[id] else { return false }
            return world.entities.contains { entity in entity === probe }
        }) else {
            throw ControllerError.mortalityBoundary("terminal probe missing before removal")
        }
        for id in removedIDs {
            guard let probe = probesByAgentId[id] else {
                throw ControllerError.mortalityBoundary("terminal probe missing for \(id)")
            }
            guard removeLabCoreAgentProbe(probe, from: world) else {
                throw ControllerError.mortalityBoundary("terminal probe removal failed for \(id)")
            }
            probesByAgentId.removeValue(forKey: id)
            lastInfluencedTracesByAgentId.removeValue(forKey: id)
        }
        let worldProbeIDs = world.entities.compactMap {
            ($0 as? LabCoreAgentEntity)?.labAgentId
        }.sorted()
        guard probesByAgentId.keys.sorted() == expected, worldProbeIDs == expected else {
            throw ControllerError.mortalityBoundary(
                "active probes do not match active agents expected=\(expected) actual=\(worldProbeIDs)"
            )
        }
        if let focusedAgentId, !expected.contains(focusedAgentId) {
            self.focusedAgentId = expected.first
        }
        if expected.isEmpty {
            focusedAgentId = nil
            followMode = .off
        } else if let target = followTargetId(), !expected.contains(target) {
            followMode = .off
        }
        for id in removedIDs {
            guard let record = current.mortalitySnapshot().records.last(where: {
                $0.agentID.rawValue == id
            }) else {
                throw ControllerError.mortalityBoundary("terminal record missing for \(id)")
            }
            trace(
                "mortality exit tick=\(record.deathTick) death=\(record.deathID.rawValue) "
                    + "agent=\(id) cause=\(record.cause.rawValue) "
                    + "health=\(record.healthBeforeLethalDamage)>\(record.finalHealth) "
                    + "population=\(previous.agentCount)>\(expected.count) "
                    + "terminal=\(record.carriedInventory.reduce(0) { $0 + $1.quantity }) "
                    + "probes=\(previousIDs.count)>\(expected.count) focus=\(focusedAgentId ?? "none") "
                    + "corpse=none worldMutation=none"
            )
        }
    }

    private func mortalityStatus(_ session: AgentSimulationSession) -> PebbleAgentCommandResult {
        let summary = session.mortalitySummary()
        let population = session.populationSummary()
        let message = "mortality gate=\(mortalityFeatureEnabled ? "enabled" : "disabled") "
            + "active=\(summary.enabled ? "yes" : "no") agents=\(summary.activeAgentCount) "
            + "deaths=\(summary.totalDeathCount) retained=\(summary.retainedDeathCount) "
            + "evicted=\(summary.evictedDeathCount) "
            + "latest=\(summary.latestDeathID?.rawValue ?? "none") "
            + "victim=\(summary.latestAgentID?.rawValue ?? "none") "
            + "tick=\(summary.latestDeathTick ?? -1) terminal=\(summary.unrecoveredTotal) "
            + "members=\(population.memberCount) nextOrdinal=\(population.nextPopulationOrdinal ?? -1) "
            + "probes=\(probesByAgentId.count) digest=\(summary.digest)"
        trace(message)
        return success(message)
    }
}
