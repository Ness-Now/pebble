import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleNatural(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab natural <on|off|status|scan>"
        guard arguments.count == 1, let subcommand = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard var session, activeWorld === world else {
            return failure("No active PebbleAgents session for this World.")
        }
        if subcommand == "on" {
            guard naturalFeatureEnabled else {
                return failure("Natural resources disabled. Set PEBBLELAB_APP_AGENTS_NATURAL=1 before launch.")
            }
            do {
                if try applyCommandMutationIfRecording(
                    .setNaturalResourcesEnabled(true), session: &session
                ) == nil {
                    session.setNaturalResourcesEnabled(true)
                }
            } catch {
                return failure("Natural resource recording failed: \(error)")
            }
            self.session = session
            lastNaturalReason = "enabled by command"
            trace("natural=on tick=\(session.tick) mutation=none")
            return success("PebbleAgents natural resources on; movement, economy, and survival unchanged.")
        }
        if subcommand == "off" {
            do {
                if try applyCommandMutationIfRecording(
                    .setNaturalResourcesEnabled(false), session: &session
                ) == nil {
                    session.setNaturalResourcesEnabled(false)
                }
            } catch {
                return failure("Natural resource recording failed: \(error)")
            }
            self.session = session
            lastNaturalReason = "disabled by command"
            trace("natural=off tick=\(session.tick) mutation=none")
            return success("PebbleAgents natural resources off; inventories and camp stock preserved.")
        }
        guard subcommand == "status" || subcommand == "scan" else { return failure(usage) }
        let snapshot = session.snapshot()
        let actor = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        if snapshot.naturalResourcesEnabled, let actor {
            do {
                let playerPosition = AgentPosition(
                    x: Int(player.x.rounded(.down)),
                    y: Int(player.y.rounded(.down)),
                    z: Int(player.z.rounded(.down))
                )
                let scan = try naturalResourceAdapter.scan(
                    world: world,
                    agent: actor,
                    occupiedAgentPositions: snapshot.agents
                        .filter { $0.id != actor.id }
                        .map(\.position),
                    playerPosition: playerPosition
                )
                naturalResourceExecutor.recordScan(scan)
            } catch {
                return failure("Natural resource scan failed: \(error)")
            }
        }
        let refreshed = session.snapshot()
        let focused = refreshed.agents.first { $0.id == focusedAgentId } ?? refreshed.agents.first
        let natural = naturalResourceExecutor.state
        let target = focused?.activeResourceTarget.flatMap {
            $0.source == .naturalWorld ? $0 : nil
        }
        let mapping = PebbleAgentNaturalResourceMapping.entries.map {
            "\($0.blockName)#\($0.fingerprint):\($0.resource.rawValue)"
        }.joined(separator: ",")
        let conservation = refreshed.conservation
        let message = "natural gate=\(naturalFeatureEnabled ? "enabled" : "disabled") active=\(refreshed.naturalResourcesEnabled ? "yes" : "no") actor=\(focused?.id ?? "none") radius=\(PebbleAgentNaturalResourceAdapter.configuration.horizontalRadius) vertical=-\(PebbleAgentNaturalResourceAdapter.configuration.verticalBelow)...+\(PebbleAgentNaturalResourceAdapter.configuration.verticalAbove) positionsConsidered=\(natural.lastScan.positionsConsidered) positionsRead=\(natural.lastScan.worldBlockReadCount) candidates=\(natural.lastScan.candidateCount) observations=\(natural.lastScan.observationsEmitted) mappedBlocks=\(natural.lastScan.mappedBlockCount) mapping=\(mapping) target=\(target.map { positionText($0.target) } ?? "none") source=\(target?.source.rawValue ?? "none") fingerprint=\(target?.expectedBlockFingerprint.map(String.init) ?? "none") distance=\(target?.distanceManhattan ?? 0) reservation=\(focused?.resourceReservation?.agentId ?? "none") route=\(focused?.navigationProgress.route?.positions.count ?? 0):\(focused?.navigationProgress.routeIndex ?? 0) lastHarvest=\(natural.lastHarvest) lastRollback=\(natural.lastRollback) harvestCount=\(natural.harvestCount) rollbackCount=\(natural.rollbackCount) fixtures=\(interactionExecutor.economyState().fixtures.count) conservation=\(conservation.harvestedTotal):\(conservation.carriedTotal)+\(conservation.campStockTotal)+\(conservation.consumedTotal)+\(conservation.constructionEscrowTotal)+\(conservation.constructedTotal):\(conservation.balanced ? "exact" : "diverged") reason=\(lastNaturalReason.replacingOccurrences(of: " ", with: "_"))"
        trace(message)
        return success(message)
    }

    func handleSurvival(_ arguments: [String]) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab survival <on|off|status>"
        guard arguments.count == 1, let subcommand = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard var session else {
            return failure("No active PebbleAgents session.")
        }
        if subcommand == "on" || subcommand == "off" {
            let enabled = subcommand == "on"
            do {
                if try applyCommandMutationIfRecording(
                    .setSurvivalEnabled(enabled), session: &session
                ) == nil {
                    session.setSurvivalEnabled(enabled)
                }
            } catch {
                return failure("Survival recording failed: \(error)")
            }
            self.session = session
            lastSurvivalReason = enabled ? "enabled by command" : "disabled by command"
            trace("survival=\(enabled ? "on" : "off") tick=\(session.tick) reason=command")
            return success("PebbleAgents survival \(enabled ? "on" : "off").")
        }
        guard subcommand == "status" else { return failure(usage) }
        let snapshot = session.snapshot()
        let agent = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let progress = agent?.survivalProgress
        let config = snapshot.survivalConfiguration
        let conservation = snapshot.conservation
        let memory = progress?.lastMemoryType?.rawValue ?? agent?.recentMemory.last { entry in
            entry.type == "food_consumed"
                || entry.type == "consumption_blocked"
                || entry.type == "starvation_damage"
        }?.type ?? "none"
        let message = "survival active=\(snapshot.survivalEnabled ? "yes" : "no") actor=\(agent?.id ?? "none") status=\(progress?.status.rawValue ?? "off") goal=\(agent?.currentGoal.kind.rawValue ?? "none") hunger=\(String(format: "%.2f", agent?.needs.hunger ?? 0)) hungerThreshold=\(config.hungryThreshold) hungerRecovery=\(config.hungerRecoveryThreshold) fatigue=\(String(format: "%.2f", agent?.needs.fatigue ?? 0)) fatigueThreshold=\(config.fatigueThreshold) fatigueRecovery=\(config.fatigueRecoveryThreshold) health=\(agent?.health ?? 0) criticalHungerTicks=\(progress?.consecutiveCriticalHungerTicks ?? 0) foodRaw=\(agent?.resourceInventory.count(of: .foodRaw) ?? 0) foodConsumed=\(progress?.foodConsumedCount ?? 0) starvationDamage=\(progress?.starvationDamageTaken ?? 0) navigationPurpose=\(agent?.navigationProgress.route?.purpose.rawValue ?? "none") consumptionOutcome=\(progress?.lastConsumptionOutcome?.status.rawValue ?? "none") memory=\(memory) conservation=\(conservation.harvestedTotal):\(conservation.carriedTotal)+\(conservation.campStockTotal)+\(conservation.consumedTotal)+\(conservation.constructionEscrowTotal)+\(conservation.constructedTotal):\(conservation.balanced ? "exact" : "diverged") reason=\(lastSurvivalReason.replacingOccurrences(of: " ", with: "_"))"
        trace(message)
        return success(message)
    }

}
