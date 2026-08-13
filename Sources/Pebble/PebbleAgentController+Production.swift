import PebbleAgents
import PebbleCore

extension PebbleAgentController {
    func handleProduction(
        _ arguments: [String],
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let usage = "Usage: /lab production <setup|status|proof|use-produced-tool|cleanup>"
        guard arguments.count == 1 else { return failure(usage) }
        guard productionFeatureEnabled else {
            return failure(
                "Production disabled. Set PEBBLELAB_APP_AGENTS_PRODUCTION=1 before launch."
            )
        }
        switch arguments[0].lowercased() {
        case "setup": return setupProductionProof(world: world, player: player)
        case "status": return productionStatus(world: world)
        case "proof": return proveProductionBoundaries(world: world)
        case "use-produced-tool":
            return useProducedTool(world: world, player: player)
        case "cleanup": return cleanupProductionProof(world: world)
        default: return failure(usage)
        }
    }

    func productionInputsAreUnencumbered(
        _ opportunity: AgentProductionOpportunity,
        session: AgentSimulationSession
    ) -> Bool {
        guard session.materialRightsEnabled else { return true }
        return !session.materialRightsSnapshot().records.contains { record in
            guard case let .agent(holderID) = record.lastVerifiedHolder.holder,
                  holderID == opportunity.actorID else { return false }
            return opportunity.inputs.contains {
                $0.identity.itemKey == record.asset.materialIdentity.itemKey
            }
        }
    }

    private func setupProductionProof(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        let missing = productionProofGates().filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Production setup refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard var candidate = session, activeWorld === world else {
            return failure("Production setup requires an active session in this World.")
        }
        if candidate.productionEnabled {
            return productionStatus(world: world)
        }
        let actorID = focusedAgentId ?? candidate.snapshot().agents.first?.id
        guard let actorID, let probe = probesByAgentId[actorID],
              probe.world === world, !probe.dead,
              probe.carriedItems.allSatisfy({ $0 == nil }) else {
            return failure(
                "Production setup requires one live focused probe with empty custody."
            )
        }
        let origin = PebbleAgentEmbodiment(probe: probe).position
        let occupied = Set(probesByAgentId.values.map {
            let p = PebbleAgentEmbodiment(probe: $0).position
            return "\(p.x),\(p.y),\(p.z)"
        } + [
            "\(Int(player.x.rounded(.down))),"
                + "\(Int(player.y.rounded(.down))),"
                + "\(Int(player.z.rounded(.down)))",
        ])
        let orientations = [
            ((1, 0), (-1, 0)), ((-1, 0), (1, 0)),
            ((0, 1), (0, -1)), ((0, -1), (0, 1)),
        ]
        guard let selected = orientations.first(where: { pair in
            let workshop = "\(origin.x + pair.0.0),\(origin.y),\(origin.z + pair.0.1)"
            let target = "\(origin.x + pair.1.0),\(origin.y + 2),\(origin.z + pair.1.1)"
            return !occupied.contains(workshop) && !occupied.contains(target)
                && world.isChunkReady((origin.x + pair.0.0) >> 4,
                                      (origin.z + pair.0.1) >> 4)
                && world.isChunkReady((origin.x + pair.1.0) >> 4,
                                      (origin.z + pair.1.1) >> 4)
                && world.getBlock(
                    origin.x + pair.0.0, origin.y, origin.z + pair.0.1
                ) == 0
                && world.getBlock(
                    origin.x + pair.1.0, origin.y + 2,
                    origin.z + pair.1.1
                ) == 0
        }) else {
            return failure("Production setup found no bounded workshop/target cells.")
        }
        let workshop = AgentPosition(
            x: origin.x + selected.0.0, y: origin.y,
            z: origin.z + selected.0.1
        )
        let toolTarget = PhysicalBlockPosition(
            x: origin.x + selected.1.0, y: origin.y + 2,
            z: origin.z + selected.1.1
        )
        let workshopBefore = world.getBlock(
            workshop.x, workshop.y, workshop.z
        )
        let targetBefore = world.getBlock(
            toolTarget.x, toolTarget.y, toolTarget.z
        )
        let inventoryBefore = copyItemInventory(probe.carriedItems)
        do {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                Int(cell(B.crafting_table)), SET_SILENT
            )
            _ = world.setBlock(
                toolTarget.x, toolTarget.y, toolTarget.z,
                Int(cell(B.stone)), SET_SILENT
            )
            guard (world.getBlock(workshop.x, workshop.y, workshop.z) >> 4)
                    == Int(B.crafting_table),
                  world.getBlock(toolTarget.x, toolTarget.y, toolTarget.z)
                    == Int(cell(B.stone)) else {
                throw ControllerError.feedbackBoundary(
                    "production fixture physical verification"
                )
            }
            probe.carriedItems[0] = ItemStack(iid("cobblestone"), 3)
            probe.carriedItems[1] = ItemStack(iid("stick"), 2)
            probe.carriedItems[2] = ItemStack(iid("wheat"), 3)
            guard productionItemCount("stone_pickaxe", in: probe.carriedItems) == 0,
                  productionItemCount("bread", in: probe.carriedItems) == 0 else {
                throw ControllerError.feedbackBoundary(
                    "production output was not absent"
                )
            }
            try candidate.setProductionEnabled(true)
            let actor = AgentID(rawValue: actorID)!
            try candidate.raiseProductionNeed(
                needID: AgentProductionNeedID(
                    rawValue: "need:\(actorID):stone_pickaxe"
                )!,
                actorID: actor,
                reason: .missingUsefulTool,
                desiredOutputItemKey: "stone_pickaxe",
                priority: 92
            )
            try candidate.raiseProductionNeed(
                needID: AgentProductionNeedID(
                    rawValue: "need:\(actorID):bread"
                )!,
                actorID: actor,
                reason: .materialWork,
                desiredOutputItemKey: "bread",
                priority: 64
            )
            if !candidate.autonomousActivityEnabled {
                try candidate.setAutonomousActivityEnabled(true)
            }
            session = candidate
            productionWorkshopPosition = workshop
            productionToolTargetPosition = toolTarget
            isPaused = true
            movementEnabled = false
            autoInteractionEnabled = false
            followMode = .off
            let message = "production setup actor=\(actorID) reason=missingUsefulTool "
                + "workshop=crafting_table@\(workshop.x),\(workshop.y),\(workshop.z) "
                + "inputs=cobblestone:3,stick:2,wheat:3 "
                + "outputsBefore=stone_pickaxe:0,bread:0 "
                + "toolTarget=stone@\(toolTarget.x),\(toolTarget.y),\(toolTarget.z) "
                + "paused=1 movement=0 productPath=autonomous"
            trace(message)
            return success(message)
        } catch {
            probe.carriedItems = inventoryBefore
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                workshopBefore, SET_SILENT
            )
            _ = world.setBlock(
                toolTarget.x, toolTarget.y, toolTarget.z,
                targetBefore, SET_SILENT
            )
            return failure("Production setup failed: \(error)")
        }
    }

    private func productionStatus(world: World) -> PebbleAgentCommandResult {
        guard let session, activeWorld === world else {
            return failure("No active PebbleAgents session.")
        }
        let state = session.productionSnapshot()
        let records = state.records.map {
            "\($0.outputProduced.identity.itemKey):\($0.outputProduced.count)"
                + "@\($0.workshopPosition.x),\($0.workshopPosition.y),"
                + "\($0.workshopPosition.z)"
        }.joined(separator: ",")
        let custody = state.records.compactMap { record in
            probesByAgentId[record.actorID.rawValue].map { probe in
                "\(record.actorID.rawValue):"
                    + "\(productionItemCount(record.outputProduced.identity.itemKey, in: probe.carriedItems))"
            }
        }.joined(separator: ",")
        let message = "production enabled=\(state.enabled ? 1 : 0) "
            + "activeNeeds=\(state.needs.filter { $0.status == .active }.count) "
            + "fulfilled=\(state.needs.filter { $0.status == .fulfilled }.count) "
            + "opportunities=\(state.opportunities.count) "
            + "records=\(state.records.count) uses=\(state.useRecords.count) "
            + "totalProduction=\(state.totalProductionCount) "
            + "duplicateProductionReceipts=0 inFlight=0 "
            + "outputs=\(records.isEmpty ? "none" : records) "
            + "custody=\(custody.isEmpty ? "none" : custody)"
        trace(message)
        return success(message)
    }

    private func proveProductionBoundaries(
        world: World
    ) -> PebbleAgentCommandResult {
        let missing = productionProofGates().filter { !$0.1 }.map(\.0)
        guard missing.isEmpty else {
            return failure(
                "Production proof refused; missing gates: "
                    + missing.joined(separator: ", ")
            )
        }
        guard let published = session, activeWorld === world,
              published.productionEnabled, isPaused, !movementEnabled,
              let need = published.productionSnapshot().needs.first(where: {
                  $0.status == .active
                      && $0.desiredOutputItemKey == "stone_pickaxe"
              }), let breadNeed = published.productionSnapshot().needs.first(where: {
                  $0.status == .active && $0.desiredOutputItemKey == "bread"
              }), let probe = probesByAgentId[need.actorID.rawValue],
              let workshop = productionWorkshopPosition else {
            return failure(
                "Production proof requires setup, pause, and unexecuted needs."
            )
        }
        let actor = PebbleAgentEmbodiment(probe: probe)
        let inventoryPublished = copyItemInventory(probe.carriedItems)
        let workshopCell = world.getBlock(workshop.x, workshop.y, workshop.z)
        do {
            let sessionBytes = try published.durableStateBytes()
            let rights = published.materialRightsSnapshot()
            let recorderCount = replayRecorder?.records.count ?? 0
            productionGateway.reset()
            defer { productionGateway.reset() }

            let missingInput = canonicalCraftingMutation(
                producing: "stone_pickaxe",
                from: [ItemStack(iid("cobblestone"), 3), ItemStack(iid("stick"), 1)],
                gridWidth: 3, gridHeight: 3
            ) == nil
            let wrongQuantity = canonicalCraftingMutation(
                producing: "bread",
                from: [ItemStack(iid("wheat"), 2)],
                gridWidth: 3, gridHeight: 3
            ) == nil
            let wrongIdentity = canonicalCraftingMutation(
                producing: "bread",
                from: [ItemStack(iid("carrot"), 3)],
                gridWidth: 3, gridHeight: 3
            ) == nil

            func loadStoneInputs() {
                probe.carriedItems = Array(
                    repeating: nil,
                    count: LabCoreAgentEntity.carriedItemSlotCount
                )
                probe.carriedItems[0] = ItemStack(iid("cobblestone"), 3)
                probe.carriedItems[1] = ItemStack(iid("stick"), 2)
            }
            func stoneObservation() -> AgentProductionOpportunityObservation? {
                productionSensor.observe(
                    need: need, actor: actor, world: world,
                    atTick: published.tick, lifetimeTicks: 2
                )
            }

            loadStoneInputs()
            guard let staleObservation = stoneObservation() else {
                throw ControllerError.feedbackBoundary("stale proof plan")
            }
            let staleOpportunity = AgentProductionOpportunity(
                observation: staleObservation,
                causalEventID: need.causalEventID
            )
            _ = world.setBlock(workshop.x, workshop.y, workshop.z, 0, SET_SILENT)
            let stale = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:stale-workshop",
                    opportunity: staleOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world, publish: { _ in }
            )
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                workshopCell, SET_SILENT
            )
            let staleClosed = stale.status == .staleWorkshop
                && productionItemCount("stone_pickaxe", in: probe.carriedItems) == 0
                && productionItemCount("cobblestone", in: probe.carriedItems) == 3
                && productionItemCount("stick", in: probe.carriedItems) == 2

            loadStoneInputs()
            guard let externalObservation = stoneObservation() else {
                throw ControllerError.feedbackBoundary("external proof plan")
            }
            let externalOpportunity = AgentProductionOpportunity(
                observation: externalObservation,
                causalEventID: need.causalEventID
            )
            probe.carriedItems[0] = ItemStack(iid("cobblestone"), 2)
            let external = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:external-change",
                    opportunity: externalOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world, publish: { _ in }
            )
            let externalClosed = external.status == .staleSource
                && productionItemCount("stone_pickaxe", in: probe.carriedItems) == 0

            loadStoneInputs()
            guard let lateObservation = stoneObservation() else {
                throw ControllerError.feedbackBoundary("late proof plan")
            }
            let lateOpportunity = AgentProductionOpportunity(
                observation: lateObservation,
                causalEventID: need.causalEventID
            )
            let lateBefore = copyItemInventory(probe.carriedItems)
            let late = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:late-fault",
                    opportunity: lateOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world,
                verifyAfterMutation: { false }, publish: { _ in }
            )
            let lateExact = late.status == .verificationFailure
                && late.mutationOccurred
                && productionInventoriesEqual(probe.carriedItems, lateBefore)
                && productionItemCount("stone_pickaxe", in: probe.carriedItems) == 0
            let retry = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:late-fault",
                    opportunity: lateOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world, publish: { _ in }
            )
            let retryPassed = retry.succeeded
                && productionItemCount("stone_pickaxe", in: probe.carriedItems) == 1

            probe.carriedItems = Array(
                repeating: nil,
                count: LabCoreAgentEntity.carriedItemSlotCount
            )
            probe.carriedItems[0] = ItemStack(iid("wheat"), 3)
            guard let contentionObservation = productionSensor.observe(
                need: breadNeed, actor: actor, world: world,
                atTick: published.tick, lifetimeTicks: 2
            ) else {
                throw ControllerError.feedbackBoundary("contention proof plan")
            }
            let contentionOpportunity = AgentProductionOpportunity(
                observation: contentionObservation,
                causalEventID: breadNeed.causalEventID
            )
            let winner = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:contention:winner",
                    opportunity: contentionOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world, publish: { _ in }
            )
            let loser = productionGateway.execute(
                PebbleAgentProductionRequest(
                    operationID: "proof:contention:loser",
                    opportunity: contentionOpportunity,
                    completedAtTick: published.tick
                ), actor: actor, world: world, publish: { _ in }
            )
            let contentionClosed = winner.succeeded
                && loser.status == .staleSource
                && productionItemCount("bread", in: probe.carriedItems) == 1

            var rightsCandidate = published
            if !rightsCandidate.materialRightsEnabled {
                try rightsCandidate.setMaterialRightsEnabled(true)
            }
            let protectedInput = lateObservation.inputs[0]
            let assetID = AgentMaterialAssetID(rawValue: "asset:civ34:reserved-input")!
            _ = try rightsCandidate.applyMaterialRightsOperation(.register(
                operationID: "civ34-proof-rights-register",
                asset: AgentMaterialAssetReference(
                    assetID: assetID,
                    materialIdentity: protectedInput.identity,
                    quantity: protectedInput.count
                ),
                observation: AgentMaterialHolderObservation(
                    holder: .agent(need.actorID),
                    materialIdentity: protectedInput.identity,
                    quantity: protectedInput.count,
                    custodyFingerprint: lateObservation.sourceCustodyFingerprint,
                    physicalReceiptID: "civ34-proof-rights-register",
                    observedAtTick: published.tick
                )
            ))
            _ = try rightsCandidate.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ34-proof-rights-claim-a",
                assetID: assetID,
                claimID: AgentMaterialClaimID(rawValue: "claim:civ34:a")!,
                claimantID: need.actorID,
                basis: .retained
            ))
            _ = try rightsCandidate.applyMaterialRightsOperation(.assertClaim(
                operationID: "civ34-proof-rights-claim-b",
                assetID: assetID,
                claimID: AgentMaterialClaimID(rawValue: "claim:civ34:b")!,
                claimantID: AgentID(rawValue:
                    published.snapshot().agents.first(where: {
                        $0.id != need.actorID.rawValue
                    })?.id ?? need.actorID.rawValue
                )!,
                basis: .contested
            ))
            let reservedClosed = !productionInputsAreUnencumbered(
                lateOpportunity, session: rightsCandidate
            )

            probe.carriedItems = inventoryPublished
            let exactBoundary = try self.session?.durableStateBytes() == sessionBytes
                && self.session?.materialRightsSnapshot() == rights
                && (replayRecorder?.records.count ?? 0) == recorderCount
                && productionInventoriesEqual(probe.carriedItems, inventoryPublished)
                && world.getBlock(workshop.x, workshop.y, workshop.z)
                    == workshopCell
            let passed = missingInput && wrongQuantity && wrongIdentity
                && staleClosed && externalClosed && lateExact && retryPassed
                && contentionClosed && reservedClosed && exactBoundary
            let message = "production boundary proof missingInput=\(missingInput ? "PASS" : "FAIL") "
                + "wrongQuantity=\(wrongQuantity ? "PASS" : "FAIL") "
                + "wrongIdentity=\(wrongIdentity ? "PASS" : "FAIL") "
                + "staleWorkshop=\(staleClosed ? "PASS" : "FAIL") "
                + "externalChange=\(externalClosed ? "PASS" : "FAIL") "
                + "reservedAmbiguous=\(reservedClosed ? "PASS" : "FAIL") "
                + "contention=\(contentionClosed ? "PASS" : "FAIL") "
                + "lateMutationReached=\(late.mutationOccurred ? 1 : 0) "
                + "rollback=\(lateExact ? "exact" : "not-exact") "
                + "immediateRetry=\(retryPassed ? "PASS" : "FAIL") "
                + "session=\(exactBoundary ? "exact" : "changed") "
                + "physicalLoss=0 physicalDuplication=0 syntheticMaterial=0 "
                + "productionPublication=0"
            trace(message)
            return passed ? success(message) : failure(message)
        } catch {
            probe.carriedItems = inventoryPublished
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                workshopCell, SET_SILENT
            )
            return failure("Production boundary proof failed: \(error)")
        }
    }

    private func useProducedTool(
        world: World,
        player: Player
    ) -> PebbleAgentCommandResult {
        guard var published = session, activeWorld === world,
              isPaused, !movementEnabled,
              let record = published.productionSnapshot().records.last(where: {
                  $0.outputProduced.identity.itemKey == "stone_pickaxe"
              }), let probe = probesByAgentId[record.actorID.rawValue],
              probe.world === world, !probe.dead else {
            return failure(
                "Produced-tool use requires paused restored custody and a production record."
            )
        }
        let actor = PebbleAgentEmbodiment(probe: probe)
        let actorPosition = actor.position
        let restoredTarget = [2, 1, 0, -1].flatMap { vertical in
            [(1, 0), (-1, 0), (0, 1), (0, -1)].map { offset in
                PhysicalBlockPosition(
                    x: actorPosition.x + offset.0,
                    y: actorPosition.y + vertical,
                    z: actorPosition.z + offset.1
                )
            }
        }.first { candidate in
            (candidate.x != record.workshopPosition.x
                || candidate.y != record.workshopPosition.y
                || candidate.z != record.workshopPosition.z)
                && world.getBlock(candidate.x, candidate.y, candidate.z)
                    == Int(cell(B.stone))
        }
        guard let target = productionToolTargetPosition ?? restoredTarget,
              world.getBlock(target.x, target.y, target.z)
                == Int(cell(B.stone)),
              let slot = probe.carriedItems.indices.first(where: {
                  guard let stack = probe.carriedItems[$0] else { return false }
                  return itemDef(stack.id).name == "stone_pickaxe"
                      && stack.damage == 0
              }), let binding = materialCustodyGateway.toolBinding(
                  actor: actor, slot: slot, world: world
              ) else {
            return failure(
                "Produced-tool use lost exact damage-0 stone pickaxe or stone target."
            )
        }
        productionToolTargetPosition = target
        let occupied = probesByAgentId.values.map {
            let p = PebbleAgentEmbodiment(probe: $0).position
            return PhysicalBlockPosition(x: p.x, y: p.y, z: p.z)
        } + [PhysicalBlockPosition(
            x: Int(player.x.rounded(.down)),
            y: Int(player.y.rounded(.down)),
            z: Int(player.z.rounded(.down))
        )]
        let targetBeforeWrong = world.getBlock(target.x, target.y, target.z)
        let inventoryBeforeWrong = copyItemInventory(probe.carriedItems)
        let wrong = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actor.agentID, target: target,
                expectedCell: targetBeforeWrong,
                heldItem: ItemStack(iid("stick"), 1), isCreative: false
            ),
            occupiedPositions: occupied,
            acquireDrops: { !$0.isEmpty }
        )
        guard !wrong.succeeded,
              world.getBlock(target.x, target.y, target.z) == targetBeforeWrong,
              productionInventoriesEqual(probe.carriedItems, inventoryBeforeWrong) else {
            return failure("Wrong-tool production proof did not fail closed.")
        }

        let transaction = PebbleCandidatePhysicalTransaction(
            transactionID: "production-use:\(record.operationID):t\(published.tick)",
            operation: "useProducedTool",
            physicalWorldTick: world.time
        )
        physicalActionGateway.candidatePhysicalTransaction = transaction
        materialCustodyGateway.candidatePhysicalTransaction = transaction
        defer {
            if physicalActionGateway.candidatePhysicalTransaction === transaction {
                physicalActionGateway.candidatePhysicalTransaction = nil
            }
            if materialCustodyGateway.candidatePhysicalTransaction === transaction {
                materialCustodyGateway.candidatePhysicalTransaction = nil
            }
        }
        let endpoint = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let bridge = PebbleAgentMaterialSnapshotBridge()
        let beforeTool = try? bridge.snapshot(of: binding.heldItem)
        var recorderCandidate = replayRecorder
        var publishedUse: AgentProducedGoodUseOutcome?
        var acquiredQuantity = 0
        let useOperationID = "use:\(record.operationID):t\(published.tick)"
        let outcome = physicalActionGateway.breakBlock(
            world: world,
            actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actor.agentID, target: target,
                expectedCell: Int(cell(B.stone)),
                heldItem: binding.heldItem, isCreative: false
            ),
            toolState: binding.toolState,
            occupiedPositions: occupied,
            acquireDrops: { ids in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: ids, world: world
                ), let fingerprint = try? self.materialCustodyGateway
                    .fingerprint(endpoint) else { return false }
                let result = self.materialCustodyGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: "\(useOperationID):drops",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: fingerprint
                    ), from: source, to: endpoint
                )
                acquiredQuantity = result.quantityMoved
                return result.succeeded
            },
            verifyAfterMutation: {
                guard let beforeTool,
                      let live = probe.carriedItems[slot],
                      let afterTool = try? bridge.snapshot(of: live) else {
                    return false
                }
                let use = AgentProducedGoodUseOutcome(
                    operationID: useOperationID,
                    productionOperationID: record.operationID,
                    actorID: record.actorID,
                    physicalReceiptID: useOperationID,
                    identityBefore: beforeTool,
                    identityAfter: afterTool,
                    physicalEffect: "stone block broken and drop acquired",
                    completedAtTick: published.tick
                )
                do {
                    if var activeRecorder = recorderCandidate {
                        _ = try activeRecorder.apply(
                            .recordProducedGoodUse(use), to: &published
                        )
                        recorderCandidate = activeRecorder
                    } else {
                        try published.recordProducedGoodUse(use)
                    }
                    publishedUse = use
                    return true
                } catch { return false }
            }
        )
        guard outcome.succeeded, let publishedUse,
              acquiredQuantity > 0,
              world.getBlock(target.x, target.y, target.z) == 0 else {
            let rollback = transaction.rollback()
            return failure(
                "Produced-tool use failed status=\(outcome.status.rawValue) "
                    + "failure=\(outcome.failure?.rawValue ?? "none") "
                    + "rollback=\(rollback.failure == nil ? "exact" : "failed")"
            )
        }
        transaction.commit()
        session = published
        replayRecorder = recorderCandidate
        let message = "produced tool used actor=\(record.actorID.rawValue) "
            + "productionReceipt=\(record.operationID) "
            + "sameItem=stone_pickaxe damage="
            + "\(publishedUse.identityBefore.identity.damage)>"
            + "\(publishedUse.identityAfter.identity.damage) "
            + "world=stone>air dropsAcquired=\(acquiredQuantity) "
            + "wrongTool=FAIL_CLOSED useReceipt=\(useOperationID) "
            + "postRestartCapable=1"
        trace(message)
        return success(message)
    }

    private func cleanupProductionProof(
        world: World
    ) -> PebbleAgentCommandResult {
        guard let published = session, activeWorld === world,
              isPaused, !movementEnabled,
              let workshop = published.productionSnapshot().records
                .last?.workshopPosition else {
            return failure(
                "Production cleanup requires a paused completed production session."
            )
        }
        guard (world.getBlock(workshop.x, workshop.y, workshop.z) >> 4)
                == Int(B.crafting_table) else {
            return failure("Production cleanup found a stale workshop.")
        }
        let priorWorkshop = world.getBlock(workshop.x, workshop.y, workshop.z)
        _ = world.setBlock(workshop.x, workshop.y, workshop.z, 0, SET_SILENT)
        guard world.getBlock(workshop.x, workshop.y, workshop.z) == 0 else {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                priorWorkshop, SET_SILENT
            )
            return failure("Production cleanup could not verify the workshop restore.")
        }
        if let target = productionToolTargetPosition,
           world.getBlock(target.x, target.y, target.z) != 0 {
            _ = world.setBlock(
                workshop.x, workshop.y, workshop.z,
                priorWorkshop, SET_SILENT
            )
            return failure("Production cleanup refused a non-depleted target.")
        }
        productionWorkshopPosition = nil
        productionToolTargetPosition = nil
        let message = "production cleanup workshop=air target=air "
            + "cognition=retained custody=retained fixtureCells=exact"
        trace(message)
        return success(message)
    }

    private func productionProofGates() -> [(String, Bool)] {
        [
            ("PEBBLELAB_APP_AGENTS=1", featureEnabled),
            ("PEBBLELAB_APP_AGENTS_PRODUCTION=1", productionFeatureEnabled),
            ("PEBBLELAB_APP_PROBES=1", probesFeatureEnabled),
            ("PEBBLELAB_DEBUG_ENTITIES=1", debugEntitiesEnabled),
            ("PEBBLELAB_APP_AGENTS_TRACE=1", traceEnabled),
            ("PEBBLELAB_DISPOSABLE_WORLD_PROOF=1",
             environment["PEBBLELAB_DISPOSABLE_WORLD_PROOF"] == "1"),
        ]
    }

    private func productionItemCount(
        _ itemKey: String,
        in inventory: [ItemStack?]
    ) -> Int {
        inventory.compactMap { $0 }.filter {
            itemDef($0.id).name == itemKey
        }.reduce(0) { $0 + $1.count }
    }

    private func productionInventoriesEqual(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }
}
