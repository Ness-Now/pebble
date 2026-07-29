import Foundation
import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleEcology(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab ecology <on|off|status|scan|clear>"
        guard arguments.count == 1, let command = arguments.first?.lowercased() else {
            return failure(usage)
        }
        guard var session, activeWorld === world else {
            return failure("No active PebbleAgents session for this World.")
        }
        switch command {
        case "on":
            guard ecologyFeatureEnabled else {
                return failure("Local ecology disabled. Set PEBBLELAB_APP_AGENTS_ECOLOGY=1 before launch.")
            }
            guard session.causalLedgerSnapshot().summary.latestSequence > 0 else {
                return failure("Local ecology requires the causal ledger.")
            }
            guard session.populationEnabled,
                  let settlement = session.populationSnapshot().settlement,
                  settlement.settlementID == .main else {
                return failure("Local ecology requires settlement-main population registry.")
            }
            guard !session.localEcologyEnabled else {
                return success(ecologyStatus(session: session))
            }
            do {
                let scan = try localEcologyAdapter.scanInitial(
                    world: world,
                    settlement: settlement,
                    occupiedPositions: Set(session.snapshot().agents.map(\.position)),
                    residentPositions: session.snapshot().agents
                        .sorted { $0.id < $1.id }.map(\.position),
                    playerPosition: playerAgentPosition(player),
                    configuration: .live
                )
                lastEcologyScanDiagnostics = scan.diagnostics
                guard !scan.observations.isEmpty else {
                    return failure("Local ecology activation refused: no verified World habitat.")
                }
                if try applyCommandMutationIfRecording(
                    .initializeLocalEcology(
                        observations: scan.observations,
                        configuration: .live
                    ),
                    session: &session
                ) == nil {
                    try session.initializeLocalEcology(observations: scan.observations)
                }
                self.session = session
                lastEcologyReason = "initialized from read-only World scan"
                trace("ecology=on tick=\(session.tick) patches=\(scan.observations.count) reads=\(scan.diagnostics.worldReads) duplicateHabitatsDiscarded=\(scan.diagnostics.duplicateHabitatsDiscarded) mutation=none")
                for patch in session.localEcologySnapshot().patches {
                    let distance = abs(patch.foragePosition.x - settlement.anchor.x)
                        + abs(patch.foragePosition.y - settlement.anchor.y)
                        + abs(patch.foragePosition.z - settlement.anchor.z)
                    trace("ecology patch id=\(patch.patchID.rawValue) habitat=\(positionText(patch.habitatPosition)) forage=\(positionText(patch.foragePosition)) fingerprint=\(patch.habitatFingerprint) distance=\(distance) yield=\(patch.currentYield)/\(patch.capacity) status=\(patch.status.rawValue) mutation=none")
                }
                return success(ecologyStatus(session: session))
            } catch {
                return failure("Local ecology activation failed: \(error)")
            }
        case "off":
            do {
                if try applyCommandMutationIfRecording(
                    .setLocalEcologyEnabled(false),
                    session: &session
                ) == nil {
                    try session.setLocalEcologyEnabled(false)
                }
                self.session = session
                lastEcologyReason = "disabled by command"
                trace("ecology=off tick=\(session.tick) mutation=none")
                return success("PebbleAgents local ecology off; carried and stocked material preserved.")
            } catch { return failure("Local ecology disable failed: \(error)") }
        case "scan":
            guard let settlement = session.populationSnapshot().settlement else {
                return failure("Local ecology scan requires settlement-main.")
            }
            do {
                let scan: PebbleAgentLocalEcologyScanResult
                if session.localEcologyEnabled {
                    scan = localEcologyAdapter.validate(
                        world: world,
                        settlement: settlement,
                        patches: session.localEcologySnapshot().patches
                    )
                } else {
                    scan = try localEcologyAdapter.scanInitial(
                        world: world,
                        settlement: settlement,
                        occupiedPositions: Set(session.snapshot().agents.map(\.position)),
                        residentPositions: session.snapshot().agents
                            .sorted { $0.id < $1.id }.map(\.position),
                        playerPosition: playerAgentPosition(player)
                    )
                }
                lastEcologyScanDiagnostics = scan.diagnostics
                let ids = scan.observations.map { $0.patchID.rawValue }.joined(separator: ",")
                let message = "ecology scan candidates=\(scan.diagnostics.candidatesInspected) valid=\(scan.diagnostics.habitatsValid) duplicatesDiscarded=\(scan.diagnostics.duplicateHabitatsDiscarded) reads=\(scan.diagnostics.worldReads)/256 chunksUnavailable=\(scan.diagnostics.chunksUnavailable) patches=\(ids.isEmpty ? "none" : ids) mutation=none"
                trace(message)
                return success(message)
            } catch { return failure("Local ecology scan failed: \(error)") }
        case "clear":
            do {
                if try applyCommandMutationIfRecording(
                    .clearEcologyDiagnostics,
                    session: &session
                ) == nil {
                    try session.clearLocalEcologyDiagnostics()
                }
                self.session = session
                lastEcologyScanDiagnostics = PebbleAgentLocalEcologyScanDiagnostics()
                lastForageOutcome = nil
                return success("Local ecology diagnostics cleared; patches, yields, processed IDs, conservation, and agents preserved.")
            } catch { return failure("Local ecology clear failed: \(error)") }
        case "status":
            return success(ecologyStatus(session: session))
        default:
            return failure(usage)
        }
    }

    func handleForage(_ arguments: [String]) -> PebbleAgentCommandResult {
        guard arguments == ["status"] else {
            return failure("Usage: /lab forage status")
        }
        guard let session else { return failure("No active PebbleAgents session.") }
        let snapshot = session.snapshot()
        let agent = snapshot.agents.first { $0.id == focusedAgentId } ?? snapshot.agents.first
        let target = agent?.activeResourceTarget.flatMap {
            $0.source == .localEcology ? $0 : nil
        }
        let reservation = agent?.resourceReservation.flatMap {
            $0.source == .localEcology ? $0 : nil
        }
        let message = "forage actor=\(agent?.id ?? "none") hunger=\(String(format: "%.2f", agent?.needs.hunger ?? 0)) goal=\(agent?.currentGoal.kind.rawValue ?? "none") patch=\(target?.ecologyPatchID?.rawValue ?? "none") source=\(target?.source.rawValue ?? "none") distance=\(target?.distanceManhattan ?? 0) reservation=\(reservation?.agentId ?? "none") route=\(agent?.navigationProgress.route?.positions.count ?? 0):\(agent?.navigationProgress.routeIndex ?? 0) carriedFood=\(agent?.resourceInventory.count(of: .foodRaw) ?? 0) lastForage=\(lastForageOutcome?.status.rawValue ?? "none") lastConsumption=\(agent?.survivalProgress?.lastConsumptionOutcome?.status.rawValue ?? "none")"
        trace(message)
        return success(message)
    }

    func ecologyStatus(session: AgentSimulationSession) -> String {
        let summary = session.localEcologySummary()
        let conservation = session.ecologyConservationSnapshot()
        let resource = session.conservationSnapshot()
        let nextRegeneration = session.localEcologySnapshot().patches.compactMap { patch -> Int? in
            guard patch.status != .invalidated, patch.currentYield < patch.capacity,
                  let interval = session.localEcologySnapshot().configuration?.regenerationIntervalTicks else {
                return nil
            }
            return max(0, interval - (session.tick - patch.lastRegenerationTick))
        }.min()
        let message = "ecology gate=\(ecologyFeatureEnabled ? "enabled" : "disabled") active=\(summary.enabled ? "yes" : "no") settlement=\(session.localEcologySnapshot().settlementID?.rawValue ?? "none") patches=\(summary.patchCount) available=\(summary.availablePatchCount) depleted=\(summary.depletedPatchCount) invalidated=\(summary.invalidatedPatchCount) yield=\(summary.currentYield)/\(summary.capacity) regenerated=\(summary.regenerated) harvested=\(summary.harvested) nextRegen=\(nextRegeneration.map(String.init) ?? "none") pressure=\(summary.pressure?.rawValue ?? "none") hungry=\(summary.hungry) critical=\(summary.critical) starvationDamage=\(summary.starvationDamage) events=\(summary.ecologyEventCount) evictions=\(session.localEcologySnapshot().evictionCounts.forageHistory),\(session.localEcologySnapshot().evictionCounts.pressureFrames) digest=\(summary.digest) ecologyConservation=\(conservation.initialYieldTotal)+\(conservation.regeneratedTotal):\(conservation.currentPatchYieldTotal)+\(conservation.harvestedFromEcologyTotal):\(conservation.balanced ? "exact" : "diverged") resourceConservation=\(resource.harvestedTotal):\(resource.carriedTotal)+\(resource.campStockTotal)+\(resource.consumedTotal)+\(resource.constructionEscrowTotal)+\(resource.constructedTotal):\(resource.balanced ? "exact" : "diverged") reads=\(lastEcologyScanDiagnostics.worldReads)/256 reason=\(lastEcologyReason.replacingOccurrences(of: " ", with: "_"))"
        trace(message)
        return message
    }

    func playerAgentPosition(_ player: Player) -> AgentPosition {
        AgentPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )
    }
}
