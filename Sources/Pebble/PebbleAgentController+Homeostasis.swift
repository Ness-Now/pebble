import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleHomeostasis(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab homeostasis <on|status|proof <setup|"
            + "estate-setup|estate-co-mingled-setup|rollback|advance 1...32|"
            + "estate-advance 1...32|cleanup>>"
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
                case "estate-setup":
                    guard arguments.count == 2 else {
                        return failure(usage)
                    }
                    return try setupEstateHomeostasisProof(
                        session: &candidate, world: world
                    )
                case "estate-co-mingled-setup":
                    guard arguments.count == 2,
                          environment["PEBBLELAB_GATE_D_BLOCKER_06"] == "1"
                    else {
                        return failure(usage)
                    }
                    return try setupCoMingledEstateHomeostasisProof(
                        session: candidate, world: world
                    )
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
                case "estate-advance":
                    guard arguments.count == 3,
                          let count = Int(arguments[2]),
                          (1...32).contains(count) else {
                        return failure(usage)
                    }
                    session = candidate
                    return try advanceEstateHomeostasisProof(
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

    /// Disposable-World fixture for Gate D Blocker 06. The registered
    /// pickaxe remains in its durable container while one real, socially
    /// unregistered hoe enters the future decedent's live custody. Normal
    /// mortality then owns the complete physical exit into that same
    /// container; this helper does not open or modify an estate.
    private func setupCoMingledEstateHomeostasisProof(
        session candidate: AgentSimulationSession,
        world: World
    ) throws -> PebbleAgentCommandResult {
        let decedentID = AgentID(rawValue: "agent_0")!
        let assetID =
            AgentMaterialAssetID(rawValue: "asset:civ27:live-pickaxe")!
        guard candidate.homeostasisEnabled,
              candidate.physicalFoodSurvivalEnabled,
              candidate.materialRightsEnabled,
              candidate.persistenceReconciliationEnabled,
              candidate.estatesEnabled,
              candidate.familyV1Enabled,
              candidate.expectedActiveAgentIDs().contains(decedentID),
              let record = candidate.materialRightsSnapshot().records.first(
                where: { $0.asset.assetID == assetID }
              ),
              record.recognizedOwnership?.ownerID == decedentID,
              case let .container(location) =
                record.lastVerifiedHolder.holder,
              let position = homeostasisContainerPosition(location),
              let container = world.getBlockEntity(
                position.x, position.y, position.z
              ),
              let probe = probesByAgentId[decedentID.rawValue],
              probe.world === world, !probe.dead,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.homeostasisBoundary(
                "co-mingled estate proof dependencies unavailable"
            )
        }
        let durable = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let durableBefore = try materialCustodyGateway.inspect(durable)
        let tracked = durableBefore.slots.compactMap { $0 }.filter {
            $0.identity == record.asset.materialIdentity
        }
        guard tracked.count == 1,
              tracked[0].count == record.asset.quantity,
              try materialCustodyGateway.fingerprint(durable)
                == record.lastVerifiedHolder.custodyFingerprint else {
            throw ControllerError.homeostasisBoundary(
                "co-mingled estate tracked source is not initially exact"
            )
        }

        let item = spawnItem(
            world, probe.x, probe.y + 0.25, probe.z,
            ItemStack(iid("iron_hoe"), 1)
        )
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: [item.id], world: world
        ) else {
            world.removeEntity(item)
            throw ControllerError.homeostasisBoundary(
                "co-mingled hoe source unavailable"
            )
        }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let outcome = materialCustodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "gate-d-blocker-06-unregistered-hoe",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination
        )
        let carried = try materialCustodyGateway.inspect(destination)
        let durableAfter = try materialCustodyGateway.inspect(durable)
        guard outcome.succeeded,
              !world.entities.contains(where: { $0 === item }),
              carried.slots.compactMap({ $0 }).count == 1,
              carried.slots.compactMap({ $0 }).first?.identity.itemKey
                == "iron_hoe",
              carried.slots.compactMap({ $0 }).first?.count == 1,
              durableAfter == durableBefore,
              try candidate.durableStateBytes() == session?.durableStateBytes()
        else {
            throw ControllerError.homeostasisBoundary(
                "co-mingled hoe acquisition \(outcome.status.rawValue)"
            )
        }
        let message = [
            "estate co-mingled proof setup",
            "decedent=\(decedentID.rawValue)",
            "asset=\(assetID.rawValue)",
            "tracked=iron_pickaxe:1",
            "trackedHolder=\(record.lastVerifiedHolder.holder.stableText)",
            "unregistered=iron_hoe:1",
            "unregisteredHolder=agent:\(decedentID.rawValue)",
            "physicalItemEntityAcquired=1",
            "session=unchanged",
            "worldMutation=physicalCustodyOnly",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func setupEstateHomeostasisProof(
        session candidate: inout AgentSimulationSession,
        world: World
    ) throws -> PebbleAgentCommandResult {
        let decedentID = AgentID(rawValue: "agent_0")!
        let assetID =
            AgentMaterialAssetID(rawValue: "asset:civ27:live-pickaxe")!
        guard candidate.homeostasisEnabled,
              candidate.physicalFoodSurvivalEnabled,
              candidate.materialRightsEnabled,
              candidate.persistenceReconciliationEnabled,
              candidate.estatesEnabled,
              candidate.familyV1Enabled,
              candidate.expectedActiveAgentIDs().contains(decedentID),
              let record = candidate.materialRightsSnapshot().records.first(
                where: { $0.asset.assetID == assetID }
              ),
              record.recognizedOwnership?.ownerID == decedentID,
              case let .container(location) =
                record.lastVerifiedHolder.holder,
              let position = homeostasisContainerPosition(location),
              let container = world.getBlockEntity(
                position.x, position.y, position.z
              ),
              let probe = probesByAgentId[decedentID.rawValue],
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.homeostasisBoundary(
                "estate proof dependencies or physical asset unavailable"
            )
        }
        let source = PebbleAgentMaterialCustodyEndpoint.container(
            container, in: world
        )
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let operationID = "civ33-decedent-agent-take"
        let decision = candidate.evaluateMaterialUse(
            AgentMaterialUseRequest(
                requestID: operationID + ":decision",
                assetID: assetID,
                actorID: decedentID,
                use: .transferCustody,
                verifiedHolder: record.lastVerifiedHolder
            )
        )
        var staged: AgentSimulationSession?
        var publicationError: Error?
        let physical = materialCustodyGateway.transfer(
            PebbleAgentMaterialTransactionRequest(
                transactionID: operationID,
                material: AgentMaterialStackSnapshot(
                    identity: record.asset.materialIdentity,
                    count: record.asset.quantity
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
                    let custody = try self.materialCustodyGateway.inspect(
                        destination
                    )
                    guard custody.slots.compactMap({ $0 }).count == 1,
                          custody.slots.compactMap({ $0 }).reduce(
                            0, { $0 + $1.count }
                          ) == record.asset.quantity else {
                        return false
                    }
                    let observation = AgentMaterialHolderObservation(
                        holder: .agent(decedentID),
                        materialIdentity: record.asset.materialIdentity,
                        quantity: record.asset.quantity,
                        custodyFingerprint:
                            try self.materialCustodyGateway.fingerprint(
                                destination
                            ),
                        physicalReceiptID: operationID,
                        observedAtTick: candidate.tick
                    )
                    var social = candidate
                    _ = try social.applyMaterialRightsOperation(
                        .physicalTransfer(
                            AgentMaterialPhysicalTransferOutcome(
                                operationID: operationID,
                                decision: decision,
                                disposition:
                                    decision.verdict == .allowed
                                        ? .authorized
                                        : .observedTransgression,
                                status: .succeeded,
                                destinationObservation: observation,
                                physicalReceiptID: operationID
                            )
                        )
                    )
                    staged = social
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
                    "estate proof take \(physical.status.rawValue)"
                )
        }
        candidate = staged
        session = candidate
        let updated = candidate.materialRightsSnapshot().records.first {
            $0.asset.assetID == assetID
        }!
        let claimIDs = updated.claims.map(
            \.claimantID.rawValue
        ).joined(separator: ",")
        let permissionIDs = updated.permissions.map(
            \.userID.rawValue
        ).joined(separator: ",")
        let message = [
            "estate proof setup",
            "decedent=\(decedentID.rawValue)",
            "asset=\(assetID.rawValue)",
            "physicalItem=iron_pickaxe:\(updated.asset.quantity)",
            "holder=\(updated.lastVerifiedHolder.holder.stableText)",
            "custodian=\(updated.custodianID?.rawValue ?? "none")",
            "owner=\(updated.recognizedOwnership?.ownerID.rawValue ?? "none")",
            "claims=\(claimIDs)",
            "permissions=\(permissionIDs)",
            "worldMutation=physicalCustodyOnly",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func advanceEstateHomeostasisProof(
        count: Int,
        world: World,
        player: Player
    ) throws -> PebbleAgentCommandResult {
        guard let initial = session, initial.homeostasisEnabled,
              initial.estatesEnabled else {
            throw ControllerError.homeostasisBoundary(
                "estate homeostasis proof is not active"
            )
        }
        let terminalID = AgentID(rawValue: "agent_0")!
        let tickBefore = initial.tick
        let deathsBefore = initial.mortalitySnapshot().totalDeathCount
        var fedAgentIDs: Set<AgentID> = []
        var dependentMealsStaged = 0
        for _ in 0..<count {
            guard var current = session else {
                throw ControllerError.homeostasisBoundary(
                    "session disappeared"
                )
            }
            for rawID in ["agent_1", "agent_2"] {
                let agentID = AgentID(rawValue: rawID)!
                guard current.expectedActiveAgentIDs().contains(agentID) else {
                    continue
                }
                if try consumeHomeostasisProofFood(
                    for: agentID,
                    session: &current,
                    world: world
                ) {
                    fedAgentIDs.insert(agentID)
                }
            }
            if try stageEstateDependentCareFoodIfNeeded(
                session: current, world: world
            ) {
                dependentMealsStaged += 1
            }
            session = current
            guard advanceOneTick(world: world, player: player) else {
                throw ControllerError.homeostasisBoundary(
                    lastError ?? "live tick failed"
                )
            }
        }
        guard let final = session else {
            throw ControllerError.homeostasisBoundary(
                "session disappeared"
            )
        }
        let death = final.mortalitySnapshot().records.last {
            $0.agentID == terminalID
        }
        let profile = final.homeostasisProfile(for: terminalID)
        let rights = final.materialRightsSnapshot().records.first {
            $0.asset.assetID.rawValue == "asset:civ27:live-pickaxe"
        }
        let estate = final.estateSnapshot().estates.first {
            $0.decedentID == terminalID
        }
        let vitalStatus = profile?.vitalStatus.rawValue
            ?? death?.finalVitalStatus?.rawValue
            ?? "missing"
        let finalHealth = (try? final.state(for: terminalID).health)
            ?? death?.finalHealth
            ?? -1
        let administratorID = estate?.administrations.last?
            .administratorID.rawValue ?? "none"
        let holder = rights?.lastVerifiedHolder.holder.stableText ?? "missing"
        let ownerID = rights?.recognizedOwnership?.ownerID.rawValue ?? "none"
        let fedAgents = fedAgentIDs.sorted().map(
            \.rawValue
        ).joined(separator: ",")
        let message = [
            "estate proof advance",
            "ticks=\(count)",
            "tick=\(tickBefore)>\(final.tick)",
            "fedAgents=\(fedAgents)",
            "deprivedAgent=\(terminalID.rawValue)",
            "dependentMeals=\(dependentMealsStaged)",
            "decedent=\(terminalID.rawValue)",
            "vital=\(vitalStatus)",
            "health=\(finalHealth)",
            "deaths=\(deathsBefore)>\(final.mortalitySnapshot().totalDeathCount)",
            "estate=\(estate?.estateID.rawValue ?? "none")",
            "estateStatus=\(estate?.status.rawValue ?? "none")",
            "tier=\(estate?.beneficiaryTier.rawValue ?? "none")",
            "administrator=\(administratorID)",
            "holder=\(holder)",
            "owner=\(ownerID)",
            "physicalQuantity=\(rights?.asset.quantity ?? 0)",
            "activeAgents=\(final.expectedActiveAgentIDs().count)",
            "probes=\(probesByAgentId.count)",
            "runtimeErrors=\(runtimeErrorCount)",
        ].joined(separator: " ")
        trace(message)
        return success(message)
    }

    private func stageEstateDependentCareFoodIfNeeded(
        session: AgentSimulationSession,
        world: World
    ) throws -> Bool {
        guard let engagement = session.dependentCareSnapshot()
            .activeEngagements.filter({
                $0.kind == .provideFood
            }).sorted(by: {
                if $0.dependentID != $1.dependentID {
                    return $0.dependentID < $1.dependentID
                }
                return $0.caregiverID < $1.caregiverID
            }).first else {
            return false
        }
        guard let probe = probesByAgentId[engagement.caregiverID.rawValue],
              probe.world === world, !probe.dead else {
            throw ControllerError.homeostasisBoundary(
                "dependent food caregiver embodiment unavailable"
            )
        }
        if probe.carriedItems.compactMap({ $0 }).contains(where: {
            foodConsumptionDescriptor(for: $0) != nil
        }) {
            return false
        }
        guard let slot = probe.carriedItems.firstIndex(where: { $0 == nil }) else {
            throw ControllerError.homeostasisBoundary(
                "dependent food caregiver custody is full"
            )
        }
        probe.carriedItems[slot] = ItemStack(iid("bread"), 1)
        guard probe.carriedItems[slot].flatMap(foodConsumptionDescriptor)?
                .canonicalMaterialName == "bread" else {
            probe.carriedItems[slot] = nil
            throw ControllerError.homeostasisBoundary(
                "dependent proof food was not physically staged"
            )
        }
        return true
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
        try seedHomeostasisUntrackedInventory(
            terminalAgentID: AgentID(rawValue: "agent_2")!,
            world: world
        )
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
            "untrackedItem=cobblestone:3",
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
              probe.carriedItems.compactMap({ $0 }).count == 1,
              probe.carriedItems.compactMap({ $0 }).first?.id
                == iid("cobblestone"),
              probe.carriedItems.compactMap({ $0 }).first?.count == 3 else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof untracked custody is not exact"
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
                        materialIdentity:
                            record.lastVerifiedHolder.materialIdentity,
                        quantity: record.lastVerifiedHolder.quantity,
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
        materialIdentity: AgentMaterialIdentitySnapshot,
        quantity: Int,
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
        guard stacks.count == 2,
              stacks.filter({ $0.identity == materialIdentity })
                .reduce(0, { $0 + $1.count }) == quantity else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof actor does not hold the exact tracked item"
            )
        }
        return AgentMaterialHolderObservation(
            holder: .agent(agentID),
            materialIdentity: materialIdentity,
            quantity: quantity,
            custodyFingerprint: try materialCustodyGateway.fingerprint(endpoint),
            physicalReceiptID: receiptID,
            observedAtTick: tick
        )
    }

    private func seedHomeostasisUntrackedInventory(
        terminalAgentID: AgentID,
        world: World
    ) throws {
        guard let probe = probesByAgentId[terminalAgentID.rawValue],
              probe.world === world,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            throw ControllerError.homeostasisBoundary(
                "terminal proof probe is not empty before untracked acquisition"
            )
        }
        let item = spawnItem(
            world, probe.x, probe.y + 0.25, probe.z,
            ItemStack(iid("cobblestone"), 3)
        )
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: [item.id],
            world: world
        ) else {
            world.removeEntity(item)
            throw ControllerError.homeostasisBoundary(
                "untracked physical item source unavailable"
            )
        }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(
            probe, in: world
        )
        let outcome = materialCustodyGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: "civ29-terminal-untracked-acquisition",
                spawnedItemEntityIDs: [item.id],
                expectedDestinationFingerprint:
                    try materialCustodyGateway.fingerprint(destination)
            ),
            from: source,
            to: destination
        )
        guard outcome.succeeded,
              probe.carriedItems.compactMap({ $0 }).count == 1,
              probe.carriedItems.compactMap({ $0 }).first?.id
                == iid("cobblestone"),
              probe.carriedItems.compactMap({ $0 }).first?.count == 3,
              !world.entities.contains(where: { $0 === item }) else {
            throw ControllerError.homeostasisBoundary(
                "untracked physical item acquisition \(outcome.status.rawValue)"
            )
        }
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
        let physicalSlots = rights.flatMap {
            homeostasisPhysicalCustodySlots(for: $0, world: world)
        }
        let untrackedQuantity = physicalSlots?.compactMap { $0 }
            .filter { $0.id == iid("cobblestone") }
            .reduce(0) { $0 + $1.count } ?? 0
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
            "untrackedItem=cobblestone:\(untrackedQuantity)",
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
        let publishedBytes = try published.durableStateBytes()
        let probeBefore = copyItemInventory(probe.carriedItems)
        let containerBefore = copyItemInventory(container.items ?? [])
        var pendingCandidate = published
        _ = try pendingCandidate.advanceTick()
        guard let pending = pendingCandidate.pendingMortalityTransitions().first,
              pending.agentID == terminalID,
              pending.detectedAtTick == 23,
              pendingCandidate.mortalitySnapshot().totalDeathCount == 0 else {
            throw ControllerError.homeostasisBoundary(
                "terminal rollback proof did not stage material exit"
            )
        }
        let pendingBytes = try pendingCandidate.durableStateBytes()
        let replayBefore = try replayRecorder.map {
            try AgentReplayCodec.encodeRecords($0.records)
        }
        let probesBefore = probesByAgentId
        let worldEntityIDsBefore = Set(world.entities.map(ObjectIdentifier.init))
        let failures: [PebbleMortalityBoundaryFailurePoint] = [
            .afterPhysicalTransfers,
            .afterProbeRemoval,
            .beforePublication,
        ]
        for failure in failures {
            var staged = pendingCandidate
            var recorder = replayRecorder
            var rejected = false
            do {
                try reconcileMortalityProbes(
                    previous: published.snapshot(),
                    current: &staged,
                    recorder: &recorder,
                    world: world,
                    failurePoint: failure
                )
            } catch {
                rejected = true
            }
            let replayAfter = try recorder.map {
                try AgentReplayCodec.encodeRecords($0.records)
            }
            guard rejected,
                  try staged.durableStateBytes() == pendingBytes,
                  replayAfter == replayBefore,
                  try published.durableStateBytes() == publishedBytes,
                  session?.mortalitySnapshot().totalDeathCount == 0,
                  session?.tick == 22,
                  probe.carriedItems == probeBefore,
                  container.items == containerBefore,
                  Set(world.entities.map(ObjectIdentifier.init))
                    == worldEntityIDsBefore,
                  probesByAgentId.keys.sorted()
                    == probesBefore.keys.sorted(),
                  probesByAgentId.allSatisfy({
                      probesBefore[$0.key] === $0.value
                  }) else {
                throw ControllerError.homeostasisBoundary(
                    "terminal boundary rollback was not exact for \(failure)"
                )
            }
        }
        let containerStates = mortalityMaterialExitContainers(
            around: probe, world: world
        ).map { ($0, copyItemInventory($0.items ?? [])) }
        guard !containerStates.isEmpty else {
            throw ControllerError.homeostasisBoundary(
                "terminal no-container proof has no candidate container"
            )
        }
        for (candidateContainer, before) in containerStates {
            candidateContainer.items = Array(
                repeating: ItemStack(iid("cobblestone"), 64),
                count: before.count
            )
        }
        var noContainerCandidate = pendingCandidate
        var noContainerRecorder = replayRecorder
        var noContainerRejected = false
        do {
            try reconcileMortalityProbes(
                previous: published.snapshot(),
                current: &noContainerCandidate,
                recorder: &noContainerRecorder,
                world: world
            )
        } catch {
            noContainerRejected = true
        }
        for (candidateContainer, before) in containerStates {
            candidateContainer.items = copyItemInventory(before)
        }
        guard noContainerRejected,
              try noContainerCandidate.durableStateBytes() == pendingBytes,
              probe.carriedItems == probeBefore,
              container.items == containerBefore,
              probesByAgentId[terminalID.rawValue] === probe else {
            throw ControllerError.homeostasisBoundary(
                "terminal no-container refusal was not retryable"
            )
        }
        guard probesByAgentId[terminalID.rawValue] === probe else {
            throw ControllerError.homeostasisBoundary(
                "terminal material rollback changed the terminal probe"
            )
        }
        let message = "homeostasis mortality-boundary rollback "
            + "terminalEvent=\(pending.terminalPhysiologyEventID?.rawValue ?? "none") "
            + "pendingEvent=\(pending.pendingEventID.rawValue) "
            + "asset=\(pending.requiredMaterialAssetIDs.map(\.rawValue).joined(separator: ",")) "
            + "holder=agent:agent_2 quantity=\(probeBefore.compactMap { $0 }.reduce(0) { $0 + $1.count }) "
            + "afterTransfer=verified afterProbeRemoval=verified "
            + "beforePublication=verified session=unchanged replay=unchanged "
            + "probes=unchanged inventories=unchanged deathFinalized=0 "
            + "noContainer=verified retryable=1 "
            + "runtimeErrors=\(runtimeErrorCount) "
            + (try verifyMortalityPhysicalCustodyFixtures())
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
              let physical = world.getBlockEntity(
                  position.x, position.y, position.z
              )?.items?.compactMap({ $0 }),
              physical.filter({ $0.id == iid("iron_pickaxe") })
                .reduce(0, { $0 + $1.count }) == 1,
              physical.filter({ $0.id == iid("cobblestone") })
                .reduce(0, { $0 + $1.count }) == 3,
              physical.reduce(0, { $0 + $1.count }) == 4 else {
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
            + "trackedAsset=preserved untrackedInventory=cobblestone:3 "
            + "worldMutation=none"
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
        let physicalSlots = asset.flatMap {
            homeostasisPhysicalCustodySlots(for: $0, world: world)
        }
        let untrackedQuantity = physicalSlots?.compactMap { $0 }
            .filter { $0.id == iid("cobblestone") }
            .reduce(0) { $0 + $1.count } ?? 0
        let physicalTotal = physicalSlots?.compactMap { $0 }
            .reduce(0) { $0 + $1.count } ?? 0
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
            "untrackedItem=cobblestone:\(untrackedQuantity)",
            "physicalItemTotal=\(physicalTotal)",
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

    private func homeostasisPhysicalCustodySlots(
        for record: AgentMaterialRightsRecord,
        world: World
    ) -> [ItemStack?]? {
        switch record.lastVerifiedHolder.holder {
        case let .agent(agentID):
            return probesByAgentId[agentID.rawValue].map {
                copyItemInventory($0.carriedItems)
            }
        case let .container(location):
            guard let position = homeostasisContainerPosition(location) else {
                return nil
            }
            return world.getBlockEntity(
                position.x, position.y, position.z
            )?.items.map(copyItemInventory)
        }
    }
}
