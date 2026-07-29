import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleHomeostasis(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab homeostasis <on|status|proof <setup|rollback|advance 1...32|cleanup>>"
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
                case "rollback":
                    guard arguments.count == 2 else { return failure(usage) }
                    return try verifyHomeostasisMortalityExitRollback(
                        published: candidate,
                        world: world
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
        try takeHomeostasisProofAsset(
            record: record,
            terminalAgentID: AgentID(rawValue: "agent_2")!,
            container: container,
            session: &candidate,
            world: world
        )
        guard let heldRecord = candidate.materialRightsSnapshot().records
            .first(where: { $0.asset.assetID == assetID }),
              heldRecord.lastVerifiedHolder.holder
                == .agent(AgentID(rawValue: "agent_2")!) else {
            throw ControllerError.homeostasisBoundary(
                "terminal actor did not receive the real proof asset"
            )
        }
        if !heldRecord.claims.contains(where: { $0.claimID == claimID }) {
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

    private func takeHomeostasisProofAsset(
        record: AgentMaterialRightsRecord,
        terminalAgentID: AgentID,
        container: BlockEntityData,
        session candidate: inout AgentSimulationSession,
        world: World
    ) throws {
        guard let probe = probesByAgentId[terminalAgentID.rawValue],
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof custody is not empty"
            )
        }
        let source = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let operationID = "civ29-terminal-agent-take"
        let decision = candidate.evaluateMaterialUse(AgentMaterialUseRequest(
            requestID: operationID + ":decision",
            assetID: record.asset.assetID,
            actorID: terminalAgentID,
            use: .transferCustody,
            verifiedHolder: record.lastVerifiedHolder
        ))
        guard decision.verdict == .denied,
              decision.reason == .requesterNotPhysicalHolder else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof take was not an explicit transgression"
            )
        }
        var staged: AgentSimulationSession?
        var publicationError: Error?
        let physical = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: operationID,
                material: AgentMaterialStackSnapshot(
                    identity: record.lastVerifiedHolder.materialIdentity,
                    count: record.lastVerifiedHolder.quantity
                ),
                expectedSourceFingerprint:
                    try materialCustodyGateway.fingerprint(source),
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination,
            verifyAfterMutation: {
                do {
                    let observation = try self.homeostasisAgentObservation(
                        agentID: terminalAgentID,
                        receiptID: operationID,
                        world: world,
                        tick: candidate.tick
                    )
                    var sessionCandidate = candidate
                    _ = try sessionCandidate.applyMaterialRightsOperation(
                        .physicalTransfer(AgentMaterialPhysicalTransferOutcome(
                            operationID: operationID,
                            decision: decision,
                            disposition: .observedTransgression,
                            status: .succeeded,
                            destinationObservation: observation,
                            physicalReceiptID: operationID
                        ))
                    )
                    staged = sessionCandidate
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard physical.succeeded, let staged else {
            throw publicationError
                ?? ControllerError.homeostasisBoundary(
                    "terminal proof take \(physical.status.rawValue)"
                )
        }
        candidate = staged
    }

    private func homeostasisAgentObservation(
        agentID: AgentID,
        receiptID: String,
        world: World,
        tick: Int
    ) throws -> AgentMaterialHolderObservation {
        guard let probe = probesByAgentId[agentID.rawValue] else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof actor missing"
            )
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let custody = try materialCustodyGateway.inspect(endpoint)
        let stacks = custody.slots.compactMap { $0 }
        guard stacks.count == 1, stacks[0].count == 1 else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof actor does not hold one exact item"
            )
        }
        return AgentMaterialHolderObservation(
            holder: .agent(agentID),
            materialIdentity: stacks[0].identity,
            quantity: stacks[0].count,
            custodyFingerprint: try materialCustodyGateway.fingerprint(endpoint),
            physicalReceiptID: receiptID,
            observedAtTick: tick
        )
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
            "holder=\(rights?.lastVerifiedHolder.holder.stableText ?? "missing")",
            "custodian=\(rights?.custodianID?.rawValue ?? "none")",
            "owner=\(rights?.recognizedOwnership?.ownerID.rawValue ?? "none")",
            "claims=\(rights?.claims.map(\.claimantID.rawValue).joined(separator: ",") ?? "none")",
            "permissions=\(rights?.permissions.map(\.userID.rawValue).joined(separator: ",") ?? "none")",
            "activeAgents=\(final.expectedActiveAgentIDs().count)",
            "probes=\(probesByAgentId.count)",
            "runtimeErrors=\(runtimeErrorCount)",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func verifyHomeostasisMortalityExitRollback(
        published: AgentSimulationSession,
        world: World
    ) throws -> PebbleAgentCommandResult {
        let terminalID = AgentID(rawValue: "agent_2")!
        guard published.tick == 22,
              published.mortalitySnapshot().totalDeathCount == 0,
              let probe = probesByAgentId[terminalID.rawValue],
              let container = mortalityMaterialExitContainers(
                  around: probe, world: world
              ).first else {
            throw ControllerError.homeostasisBoundary(
                "terminal rollback proof requires tick 22 and a real container"
            )
        }
        let sessionBefore = try published.durableStateBytes()
        let probeBefore = copyItemInventory(probe.carriedItems)
        let containerBefore = copyItemInventory(container.items ?? [])
        var staged = published
        _ = try staged.advanceTick()
        guard let pending = staged.pendingMortalityTransitions().first,
              pending.agentID == terminalID,
              pending.detectedAtTick == 23,
              staged.mortalitySnapshot().totalDeathCount == 0 else {
            throw ControllerError.homeostasisBoundary(
                "terminal rollback proof did not stage material exit"
            )
        }
        var recorder: AgentReplayRecorder?
        var rejected = false
        do {
            _ = try resolvePendingMortalityMaterialExits(
                session: &staged,
                recorder: &recorder,
                world: world,
                rejectAfterMutation: true
            )
        } catch {
            rejected = true
        }
        guard rejected,
              try published.durableStateBytes() == sessionBefore,
              session?.mortalitySnapshot().totalDeathCount == 0,
              session?.tick == 22,
              probe.carriedItems == probeBefore,
              container.items == containerBefore,
              probesByAgentId[terminalID.rawValue] === probe else {
            throw ControllerError.homeostasisBoundary(
                "terminal material rollback was not exact"
            )
        }
        let message = "homeostasis mortality-exit rollback "
            + "terminalEvent=\(pending.terminalPhysiologyEventID?.rawValue ?? "none") "
            + "pendingEvent=\(pending.pendingEventID.rawValue) "
            + "asset=\(pending.requiredMaterialAssetIDs.map(\.rawValue).joined(separator: ",")) "
            + "holder=agent:agent_2 quantity=\(probeBefore.compactMap { $0 }.reduce(0) { $0 + $1.count }) "
            + "physicalRollback=verified session=unchanged deathFinalized=0 "
            + "retryable=1 runtimeErrors=\(runtimeErrorCount)"
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
        let asset = session.materialRightsSnapshot().records.first {
            $0.asset.assetID.rawValue == "asset:civ27:live-pickaxe"
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
            "asset=\(asset?.asset.assetID.rawValue ?? "none")",
            "holder=\(asset?.lastVerifiedHolder.holder.stableText ?? "none")",
            "quantity=\(asset?.lastVerifiedHolder.quantity ?? 0)",
            "custodian=\(asset?.custodianID?.rawValue ?? "none")",
            "owner=\(asset?.recognizedOwnership?.ownerID.rawValue ?? "none")",
            "claims=\(asset?.claims.map(\.claimantID.rawValue).joined(separator: ",") ?? "none")",
            "permissions=\(asset?.permissions.map(\.userID.rawValue).joined(separator: ",") ?? "none")",
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
