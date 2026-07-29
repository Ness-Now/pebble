import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleHomeostasis(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab homeostasis <on|status|proof <setup|advance 1...32|cleanup>>"
        guard homeostasisFeatureEnabled else {
            return failure(
                "Homeostasis disabled. Set PEBBLELAB_APP_AGENTS_HOMEOSTASIS=1 before launch."
            )
        }
        guard let command = arguments.first?.lowercased(), var candidate = session else {
            return failure(usage)
        }
        do {
            switch command {
            case "on":
                guard arguments.count == 1 else { return failure(usage) }
                if !candidate.homeostasisEnabled {
                    var recorder = replayRecorder
                    if try applyRecordedOperationIfActive(
                        .setHomeostasisEnabled(true, configuration: .live),
                        session: &candidate,
                        recorder: &recorder
                    ) == nil {
                        try candidate.setHomeostasisEnabled(true)
                    }
                    session = candidate
                    replayRecorder = recorder
                }
                return homeostasisStatus(candidate, world: world)
            case "status":
                guard arguments.count == 1 else { return failure(usage) }
                return homeostasisStatus(candidate, world: world)
            case "proof":
                guard environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1",
                      isPaused, !movementEnabled, activeWorld === world else {
                    return failure(
                        "Homeostasis proof requires a paused disposable World with movement off."
                    )
                }
                guard arguments.count >= 2 else { return failure(usage) }
                switch arguments[1].lowercased() {
                case "setup":
                    guard arguments.count == 2 else { return failure(usage) }
                    return try setupHomeostasisProof(session: &candidate, world: world)
                case "advance":
                    guard arguments.count == 3,
                          let count = Int(arguments[2]),
                          (1...32).contains(count) else {
                        return failure(usage)
                    }
                    session = candidate
                    return try advanceHomeostasisProof(
                        count: count, world: world, player: player
                    )
                case "cleanup":
                    guard arguments.count == 2 else { return failure(usage) }
                    return try cleanupHomeostasisProof(
                        session: &candidate, world: world
                    )
                default:
                    return failure(usage)
                }
            default:
                return failure(usage)
            }
        } catch {
            return failure("Homeostasis command failed: \(error)")
        }
    }

    private func setupHomeostasisProof(
        session candidate: inout AgentSimulationSession,
        world: World
    ) throws -> PebbleAgentCommandResult {
        guard candidate.homeostasisEnabled,
              candidate.physicalFoodSurvivalEnabled,
              candidate.materialRightsEnabled,
              candidate.persistenceReconciliationEnabled,
              candidate.expectedActiveAgentIDs().map(\.rawValue).sorted()
                == ["agent_0", "agent_1", "agent_2"] else {
            throw ControllerError.homeostasisBoundary(
                "proof dependencies or three-agent population missing"
            )
        }
        let assetID = AgentMaterialAssetID(rawValue: "asset:civ27:live-pickaxe")!
        let claimID = AgentMaterialClaimID(rawValue: "claim:civ29:agent_2")!
        guard let record = candidate.materialRightsSnapshot().records.first(where: {
            $0.asset.assetID == assetID
        }), case let .container(location) = record.lastVerifiedHolder.holder,
              let position = homeostasisContainerPosition(location),
              let container = world.getBlockEntity(position.x, position.y, position.z),
              container.items?.compactMap({ $0 }).count == 1,
              container.items?.compactMap({ $0 }).first?.id == iid("iron_pickaxe") else {
            throw ControllerError.homeostasisBoundary(
                "real persisted rights asset unavailable"
            )
        }
        if !record.claims.contains(where: { $0.claimID == claimID }) {
            _ = try candidate.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ29-live-terminal-claim",
                assetID: assetID,
                claimID: claimID,
                claimantID: AgentID(rawValue: "agent_2")!,
                basis: .contested
            ))
        }
        session = candidate
        let updated = candidate.materialRightsSnapshot().records.first {
            $0.asset.assetID == assetID
        }!
        let profile = candidate.homeostasisProfile(
            for: AgentID(rawValue: "agent_2")!
        )!
        let message = [
            "homeostasis proof setup",
            "asset=\(assetID.rawValue)",
            "physicalItem=iron_pickaxe:1",
            "holder=\(updated.lastVerifiedHolder.holder.stableText)",
            "owner=\(updated.recognizedOwnership?.ownerID.rawValue ?? "none")",
            "terminalClaim=agent_2",
            "claims=\(updated.claims.map(\.claimantID.rawValue).joined(separator: ","))",
            "vital=\(profile.vitalStatus.rawValue)",
            "condition=\(profile.condition.rawValue)",
            "foodAuthority=\(candidate.foodAuthorityMode.rawValue)",
            "worldMutation=none",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func advanceHomeostasisProof(
        count: Int,
        world: World,
        player: Player
    ) throws -> PebbleAgentCommandResult {
        guard let initial = session, initial.homeostasisEnabled else {
            throw ControllerError.homeostasisBoundary("homeostasis is not active")
        }
        let tickBefore = initial.tick
        let deathsBefore = initial.mortalitySnapshot().totalDeathCount
        var provisioned = 0
        var consumed = 0
        for _ in 0..<count {
            guard var current = session else {
                throw ControllerError.homeostasisBoundary("session disappeared")
            }
            for rawID in ["agent_0", "agent_1"] {
                guard current.expectedActiveAgentIDs().contains(
                    AgentID(rawValue: rawID)!
                ) else {
                    throw ControllerError.homeostasisBoundary(
                        "recovery actor \(rawID) disappeared"
                    )
                }
                if try consumeHomeostasisProofFood(
                    for: AgentID(rawValue: rawID)!,
                    session: &current,
                    world: world
                ) {
                    provisioned += 1
                    consumed += 1
                }
            }
            session = current
            guard advanceOneTick(world: world, player: player) else {
                throw ControllerError.homeostasisBoundary(
                    lastError ?? "live tick failed"
                )
            }
        }
        guard let final = session else {
            throw ControllerError.homeostasisBoundary("session disappeared")
        }
        let terminalID = AgentID(rawValue: "agent_2")!
        let terminalProfile = final.homeostasisProfile(for: terminalID)
        let death = final.mortalitySnapshot().records.last {
            $0.agentID == terminalID
        }
        let rights = final.materialRightsSnapshot().records.first {
            $0.asset.assetID.rawValue == "asset:civ27:live-pickaxe"
        }
        let claimPreserved = rights?.claims.contains {
            $0.claimantID == terminalID
        } == true
        let message = [
            "homeostasis proof advance",
            "ticks=\(count)",
            "tick=\(tickBefore)>\(final.tick)",
            "foodProvisioned=\(provisioned)",
            "foodConsumed=\(consumed)",
            "fedAgents=agent_0,agent_1",
            "deprivedAgent=agent_2",
            "vital=\(terminalProfile?.vitalStatus.rawValue ?? death?.finalVitalStatus?.rawValue ?? "missing")",
            "condition=\(terminalProfile?.condition.rawValue ?? death?.finalHomeostasis?.condition.rawValue ?? "missing")",
            "health=\((try? final.state(for: terminalID).health) ?? death?.finalHealth ?? -1)",
            "age=\(terminalProfile?.ageTicks ?? death?.demographicAgeTicks ?? -1)",
            "stage=\(terminalProfile?.lifeStage.rawValue ?? death?.lifeStage?.rawValue ?? "missing")",
            "deaths=\(deathsBefore)>\(final.mortalitySnapshot().totalDeathCount)",
            "claimPreserved=\(claimPreserved ? 1 : 0)",
            "activeAgents=\(final.expectedActiveAgentIDs().count)",
            "probes=\(probesByAgentId.count)",
            "runtimeErrors=\(runtimeErrorCount)",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func consumeHomeostasisProofFood(
        for agentID: AgentID,
        session candidate: inout AgentSimulationSession,
        world: World
    ) throws -> Bool {
        let actor = try candidate.state(for: agentID)
        guard actor.needs.hunger > 0 else { return false }
        guard let probe = probesByAgentId[agentID.rawValue],
              probe.world === world, !probe.dead,
              probe.carriedItems[0] == nil else {
            throw ControllerError.homeostasisBoundary(
                "exact recovery custody unavailable for \(agentID.rawValue)"
            )
        }
        probe.carriedItems[0] = ItemStack(iid("bread"), 1)
        let intent = try candidate.nextPhysicalFoodConsumptionIntent(for: agentID)
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(probe, in: world)
        guard let plan = try foodConsumptionExecutor.prepare(
            intent,
            session: candidate,
            source: source,
            gateway: materialCustodyGateway
        ), plan.validatedOutcome.canonicalMaterialName == "bread" else {
            probe.carriedItems[0] = nil
            throw ControllerError.homeostasisBoundary(
                "real bread was not observable through Pebble custody"
            )
        }
        let result = foodConsumptionExecutor.execute(
            plan,
            session: &candidate,
            source: source,
            gateway: materialCustodyGateway
        )
        guard result.succeeded, probe.carriedItems[0] == nil else {
            probe.carriedItems[0] = nil
            throw ControllerError.homeostasisBoundary(
                "verified recovery consumption failed"
            )
        }
        return true
    }

    private func cleanupHomeostasisProof(
        session candidate: inout AgentSimulationSession,
        world: World
    ) throws -> PebbleAgentCommandResult {
        let assetID = AgentMaterialAssetID(rawValue: "asset:civ27:live-pickaxe")!
        let claimID = AgentMaterialClaimID(rawValue: "claim:civ29:agent_2")!
        guard let record = candidate.materialRightsSnapshot().records.first(where: {
            $0.asset.assetID == assetID
        }), record.claims.contains(where: { $0.claimID == claimID }),
              case let .container(location) = record.lastVerifiedHolder.holder,
              let position = homeostasisContainerPosition(location),
              world.getBlockEntity(position.x, position.y, position.z)?
                .items?.compactMap({ $0 }).first?.id == iid("iron_pickaxe") else {
            throw ControllerError.homeostasisBoundary(
                "terminal claim or real physical asset missing during cleanup"
            )
        }
        _ = try candidate.applyMaterialRightsOperation(.withdrawClaim(
            operationID: "civ29-live-terminal-claim-cleanup",
            assetID: assetID,
            claimID: claimID,
            actorID: AgentID(rawValue: "agent_0")!
        ))
        guard probesByAgentId.values.allSatisfy({
            $0.carriedItems.allSatisfy { $0 == nil }
        }) else {
            throw ControllerError.homeostasisBoundary(
                "proof food custody not empty at cleanup"
            )
        }
        session = candidate
        let message = "homeostasis proof cleanup claimRemoved=1 foodCustody=empty "
            + "physicalAsset=preserved worldMutation=none"
        trace(message)
        return success(message)
    }

    private func homeostasisStatus(
        _ session: AgentSimulationSession,
        world: World
    ) -> PebbleAgentCommandResult {
        let snapshot = session.homeostasisSnapshot()
        let profiles = snapshot.profiles.map {
            "\($0.agentID.rawValue):\($0.vitalStatus.rawValue):"
                + "\($0.condition.rawValue):\($0.trend.rawValue):"
                + "h\((try? session.state(for: $0.agentID).health) ?? -1):"
                + "a\($0.ageTicks):\($0.lifeStage.rawValue)"
        }.joined(separator: ",")
        let death = session.mortalitySnapshot().records.last
        let terminalClaim = session.materialRightsSnapshot().records
            .flatMap(\.claims).contains {
                $0.claimID.rawValue == "claim:civ29:agent_2"
            }
        let causal = session.causalLedgerSnapshot().summary
        let message = [
            "homeostasis status",
            "enabled=\(snapshot.enabled ? 1 : 0)",
            "schema=\(snapshot.enabled ? AgentCheckpointSchema.homeostasisVersion : 0)",
            "tick=\(session.tick)",
            "causalSequence=\(causal.latestSequence)",
            "profiles=\(profiles.isEmpty ? "none" : profiles)",
            "deaths=\(session.mortalitySnapshot().totalDeathCount)",
            "latestDeath=\(death?.agentID.rawValue ?? "none")",
            "deathCause=\(death?.cause.rawValue ?? "none")",
            "terminalClaim=\(terminalClaim ? 1 : 0)",
            "probes=\(probesByAgentId.count)",
            "world=\(persistenceWorldID ?? "none")",
            "runtimeErrors=\(runtimeErrorCount)",
            "worldMutation=none",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func homeostasisContainerPosition(
        _ text: String
    ) -> PhysicalBlockPosition? {
        let values = text.split(separator: ",").compactMap {
            Int($0.trimmingCharacters(in: .whitespaces))
        }
        guard values.count == 3 else { return nil }
        return PhysicalBlockPosition(x: values[0], y: values[1], z: values[2])
    }
}
