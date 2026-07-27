import PebbleAgents
import PebbleCore

struct PebbleAgentAgriculturePhysicalResult {
    let action: AgentAgriculturalActionRecord
    let physical: PebbleAgentPhysicalActionOutcome?
}

struct PebbleAgentAgricultureExecutor {
    enum ExecutionError: Error, CustomStringConvertible {
        case invalidIntent
        case missingActor
        case missingHoe
        case missingSeeds
        case staleWorld
        case physicalFailure(
            PebbleAgentPhysicalActionStatus,
            PebbleAgentPhysicalActionFailure?
        )
        case custodyFailure(PebbleAgentMaterialTransactionStatus)
        case observationMismatch
        case storageMismatch
        case rollbackFailure

        var description: String {
            switch self {
            case .invalidIntent: return "invalid agricultural intent"
            case .missingActor: return "missing agricultural embodiment"
            case .missingHoe: return "missing real hoe"
            case .missingSeeds: return "missing real compatible planting item"
            case .staleWorld: return "agricultural World target changed"
            case let .physicalFailure(status, failure):
                return "agricultural physical failure \(status.rawValue):"
                    + "\(failure?.rawValue ?? "none")"
            case let .custodyFailure(status): return "agricultural custody failure \(status.rawValue)"
            case .observationMismatch: return "agricultural maturity observation mismatch"
            case .storageMismatch: return "agricultural storage evidence mismatch"
            case .rollbackFailure: return "agricultural rollback verification failed"
            }
        }
    }

    func till(
        world: World,
        actor: PebbleAgentEmbodiment,
        intent: AgentAgriculturalIntent,
        civilDate: AgentCivilDate,
        occupiedPositions: [PhysicalBlockPosition],
        materialGateway: PebbleAgentMaterialCustodyGateway,
        physicalGateway: PebbleAgentPhysicalActionGateway,
        actionID: AgentAgriculturalActionID,
        publishAndVerify: (AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord
    ) throws -> PebbleAgentAgriculturePhysicalResult {
        guard intent.kind == .till, intent.cellIndex != nil,
              actor.agentID == intent.actorID.rawValue, actor.isValid(in: world) else {
            throw ExecutionError.invalidIntent
        }
        let hoeSlot = actor.carriedItems.indices.first { index in
            guard let stack = actor.carriedItems[index], stack.count > 0 else { return false }
            return itemDef(stack.id).tool?.type == "hoe"
        }
        guard let hoeSlot,
              let binding = materialGateway.toolBinding(
                actor: actor, slot: hoeSlot, world: world
              ) else { throw ExecutionError.missingHoe }
        let target = PhysicalBlockPosition(
            x: intent.position.x, y: intent.position.y, z: intent.position.z
        )
        let before = world.getBlock(target.x, target.y, target.z)
        var publication: AgentAgriculturalActionRecord?
        var publicationError: Error?
        let physical = physicalGateway.tillBlock(
            world: world, actor: actor,
            request: PebbleAgentBlockTillingRequest(
                actorID: intent.actorID.rawValue, target: target,
                expectedCell: before, heldItem: binding.heldItem
            ),
            toolState: binding.toolState,
            occupiedPositions: occupiedPositions,
            verifyAfterMutation: {
                let outcome = AgentAgriculturalActionOutcome(
                    actionID: actionID, kind: .till, actorID: intent.actorID,
                    plotID: intent.plotID, cellIndex: intent.cellIndex,
                    position: intent.position, beforeFingerprint: before,
                    afterFingerprint: world.getBlock(target.x, target.y, target.z),
                    civilDate: civilDate
                )
                do {
                    publication = try publishAndVerify(outcome)
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard physical.succeeded, let publication else {
            if physical.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
            if let publicationError { throw publicationError }
            if physical.status == .staleTarget { throw ExecutionError.staleWorld }
            throw ExecutionError.physicalFailure(physical.status, physical.failure)
        }
        return PebbleAgentAgriculturePhysicalResult(action: publication, physical: physical)
    }

    func plant(
        world: World,
        actor: PebbleAgentEmbodiment,
        intent: AgentAgriculturalIntent,
        civilDate: AgentCivilDate,
        occupiedPositions: [PhysicalBlockPosition],
        materialGateway: PebbleAgentMaterialCustodyGateway,
        physicalGateway: PebbleAgentPhysicalActionGateway,
        actionID: AgentAgriculturalActionID,
        publishAndVerify: (AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord
    ) throws -> PebbleAgentAgriculturePhysicalResult {
        guard intent.kind == .plant, intent.cellIndex != nil,
              actor.agentID == intent.actorID.rawValue, actor.isValid(in: world) else {
            throw ExecutionError.invalidIntent
        }
        guard let binding = materialGateway.placementBinding(
            actor: actor, requiredBlockID: Int(B.wheat)
        ), itemDef(binding.heldItem.id).name == AgentAgriculturalCrop.wheat.plantingItemKey else {
            throw ExecutionError.missingSeeds
        }
        let cropTarget = PhysicalBlockPosition(
            x: intent.position.x, y: intent.position.y + 1, z: intent.position.z
        )
        let before = world.getBlock(cropTarget.x, cropTarget.y, cropTarget.z)
        let hit = RaycastHit(
            x: cropTarget.x, y: cropTarget.y, z: cropTarget.z, face: 1,
            cell: before, t: 0, px: Double(cropTarget.x) + 0.5,
            py: Double(cropTarget.y) + 0.5, pz: Double(cropTarget.z) + 0.5
        )
        var publication: AgentAgriculturalActionRecord?
        var publicationError: Error?
        let physical = physicalGateway.placeBlock(
            world: world, actor: actor,
            request: PebbleAgentBlockPlacementRequest(
                actorID: intent.actorID.rawValue, hit: hit, target: cropTarget,
                expectedCell: before, blockID: Int(B.wheat), heldItem: binding.heldItem,
                orientation: BlockPlacementOrientation(yaw: actor.yaw, pitch: actor.pitch)
            ),
            custody: binding.custody, occupiedPositions: occupiedPositions,
            verifyAfterMutation: {
                do {
                    let fingerprint = try materialGateway.fingerprint(
                        .liveAgent(actor, in: world)
                    )
                    publication = try publishAndVerify(AgentAgriculturalActionOutcome(
                        actionID: actionID, kind: .plant, actorID: intent.actorID,
                        plotID: intent.plotID, cellIndex: intent.cellIndex,
                        position: intent.position, beforeFingerprint: before,
                        afterFingerprint: world.getBlock(
                            cropTarget.x, cropTarget.y, cropTarget.z
                        ),
                        materialDeltas: [AgentAgriculturalMaterialDelta(
                            itemKey: AgentAgriculturalCrop.wheat.plantingItemKey,
                            quantity: 1, direction: .consumed
                        )],
                        custodyFingerprint: fingerprint, civilDate: civilDate
                    ))
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard physical.succeeded, let publication else {
            if physical.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
            if let publicationError { throw publicationError }
            if physical.status == .staleTarget { throw ExecutionError.staleWorld }
            throw ExecutionError.physicalFailure(physical.status, physical.failure)
        }
        return PebbleAgentAgriculturePhysicalResult(action: publication, physical: physical)
    }

    func observeMaturity(
        world: World,
        intent: AgentAgriculturalIntent,
        observationEventID: AgentCausalEventID,
        observedCrop: AgentCropObservation,
        civilDate: AgentCivilDate,
        actionID: AgentAgriculturalActionID,
        publish: (AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord
    ) throws -> AgentAgriculturalActionRecord {
        guard intent.cellIndex != nil, observedCrop.cropKey == AgentAgriculturalCrop.wheat.rawValue,
              observedCrop.position == AgentPosition(
                x: intent.position.x, y: intent.position.y + 1, z: intent.position.z
              ), observedCrop.mature,
              observedCrop.growthStage == observedCrop.maximumGrowthStage else {
            throw ExecutionError.observationMismatch
        }
        let cropCell = world.getBlock(
            observedCrop.position.x, observedCrop.position.y, observedCrop.position.z
        )
        guard cropCell >> 4 == Int(B.wheat), cropCell & 15 == 7 else {
            throw ExecutionError.observationMismatch
        }
        return try publish(AgentAgriculturalActionOutcome(
            actionID: actionID, kind: .maturityObserved,
            actorID: intent.actorID, plotID: intent.plotID,
            cellIndex: intent.cellIndex, position: intent.position,
            beforeFingerprint: cropCell, afterFingerprint: cropCell,
            sourceObservationEventID: observationEventID, civilDate: civilDate
        ))
    }

    func harvest(
        world: World,
        actor: PebbleAgentEmbodiment,
        intent: AgentAgriculturalIntent,
        civilDate: AgentCivilDate,
        occupiedPositions: [PhysicalBlockPosition],
        materialGateway: PebbleAgentMaterialCustodyGateway,
        physicalGateway: PebbleAgentPhysicalActionGateway,
        actionID: AgentAgriculturalActionID,
        publishAndVerify: (AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord
    ) throws -> PebbleAgentAgriculturePhysicalResult {
        guard intent.kind == .harvest, intent.cellIndex != nil,
              actor.agentID == intent.actorID.rawValue, actor.isValid(in: world) else {
            throw ExecutionError.invalidIntent
        }
        let cropTarget = PhysicalBlockPosition(
            x: intent.position.x, y: intent.position.y + 1, z: intent.position.z
        )
        let before = world.getBlock(cropTarget.x, cropTarget.y, cropTarget.z)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        var acquisition: PebbleAgentItemEntityAcquisitionOutcome?
        var publication: AgentAgriculturalActionRecord?
        var publicationError: Error?
        let physical = physicalGateway.breakBlock(
            world: world, actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: intent.actorID.rawValue, target: cropTarget,
                expectedCell: before, heldItem: nil, isCreative: false
            ),
            occupiedPositions: occupiedPositions,
            acquireDrops: { ids in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: ids, world: world
                ), let destinationBefore = try? materialGateway.fingerprint(destination) else {
                    return false
                }
                let acquired = materialGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: actionID.rawValue + ":drops",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: destinationBefore
                    ),
                    from: source, to: destination,
                    verifyAfterMutation: { result in
                        do {
                            publication = try publishAndVerify(AgentAgriculturalActionOutcome(
                                actionID: actionID, kind: .harvest,
                                actorID: intent.actorID, plotID: intent.plotID,
                                cellIndex: intent.cellIndex, position: intent.position,
                                beforeFingerprint: before,
                                afterFingerprint: world.getBlock(
                                    cropTarget.x, cropTarget.y, cropTarget.z
                                ),
                                materialDeltas: result.acquired.map {
                                    AgentAgriculturalMaterialDelta(
                                        itemKey: $0.material.identity.itemKey,
                                        quantity: $0.material.count, direction: .acquired
                                    )
                                },
                                sourceItemEntityIDs: result.acquired.map(\.entityID),
                                custodyFingerprint: result.destinationFingerprint,
                                civilDate: civilDate
                            ))
                            return true
                        } catch {
                            publicationError = error
                            return false
                        }
                    }
                )
                acquisition = acquired
                return acquired.succeeded
            }
        )
        guard physical.succeeded, acquisition?.succeeded == true, let publication else {
            if physical.status == .rollbackFailure || acquisition?.status == .rollbackFailure {
                throw ExecutionError.rollbackFailure
            }
            if let publicationError { throw publicationError }
            if let acquisition { throw ExecutionError.custodyFailure(acquisition.status) }
            if physical.status == .staleTarget { throw ExecutionError.staleWorld }
            throw ExecutionError.physicalFailure(physical.status, physical.failure)
        }
        return PebbleAgentAgriculturePhysicalResult(action: publication, physical: physical)
    }

    func storeHarvest(
        world: World,
        actor: PebbleAgentEmbodiment,
        intent: AgentAgriculturalIntent,
        container: BlockEntityData,
        civilDate: AgentCivilDate,
        seedReserveTarget: Int,
        retainedSeedQuantity: Int = 0,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        actionID: AgentAgriculturalActionID,
        publishAndVerify: (AgentAgriculturalActionOutcome) throws -> AgentAgriculturalActionRecord
    ) throws -> PebbleAgentAgriculturePhysicalResult {
        guard intent.kind == .store, intent.cellIndex == nil,
              actor.agentID == intent.actorID.rawValue, actor.isValid(in: world) else {
            throw ExecutionError.invalidIntent
        }
        let actorPosition = actor.position
        let horizontalDistance = abs(container.x - actorPosition.x)
            + abs(container.z - actorPosition.z)
        let verticalDistance = container.y - actorPosition.y
        guard horizontalDistance == 1, (-1...2).contains(verticalDistance) else {
            throw ExecutionError.invalidIntent
        }
        let source = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let destination = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)
        let sourceSnapshot = try materialGateway.inspect(source)
        let agriculturalStacks = sourceSnapshot.slots.compactMap { stack -> AgentMaterialStackSnapshot? in
            guard let stack,
                  stack.identity.itemKey == AgentAgriculturalCrop.wheat.plantingItemKey
                    || stack.identity.itemKey == AgentAgriculturalCrop.wheat.produceItemKey else {
                return nil
            }
            return stack
        }
        let materials = Dictionary(grouping: agriculturalStacks, by: \.identity)
            .compactMap { identity, stacks -> AgentMaterialStackSnapshot? in
                var count = stacks.reduce(0) { $0 + $1.count }
                if identity.itemKey
                    == AgentAgriculturalCrop.wheat.plantingItemKey {
                    count = max(0, count - max(0, retainedSeedQuantity))
                }
                guard count > 0 else { return nil }
                return AgentMaterialStackSnapshot(
                    identity: identity,
                    count: count
                )
            }
            .sorted { $0.identity.itemKey < $1.identity.itemKey }
        guard !materials.isEmpty else { throw ExecutionError.storageMismatch }
        let sourceFingerprint = try materialGateway.fingerprint(source)
        let destinationFingerprint = try materialGateway.fingerprint(destination)
        var publication: AgentAgriculturalActionRecord?
        var publicationError: Error?
        let transfer = materialGateway.transferBatch(
            PebbleAgentMaterialBatchTransactionRequest(
                transactionID: actionID.rawValue + ":storage",
                materials: materials,
                expectedSourceFingerprint: sourceFingerprint,
                expectedDestinationFingerprint: destinationFingerprint
            ),
            from: source, to: destination,
            verifyAfterMutation: {
                do {
                    let stored = try materialGateway.inspect(destination)
                    let seeds = stored.slots.compactMap { $0 }.filter {
                        $0.identity.itemKey == AgentAgriculturalCrop.wheat.plantingItemKey
                    }.reduce(0) { $0 + $1.count }
                    let produce = stored.slots.compactMap { $0 }.filter {
                        $0.identity.itemKey == AgentAgriculturalCrop.wheat.produceItemKey
                    }.reduce(0) { $0 + $1.count }
                    let deltas = materials.map {
                        AgentAgriculturalMaterialDelta(
                            itemKey: $0.identity.itemKey, quantity: $0.count,
                            direction: .stored
                        )
                    }
                    publication = try publishAndVerify(AgentAgriculturalActionOutcome(
                        actionID: actionID, kind: .store, actorID: intent.actorID,
                        plotID: intent.plotID, cellIndex: nil,
                        position: intent.position,
                        beforeFingerprint: 0, afterFingerprint: 0,
                        materialDeltas: deltas,
                        custodyFingerprint: try materialGateway.fingerprint(destination),
                        storageLocationID: destination.locationID,
                        seedReserveQuantity: min(seeds, seedReserveTarget),
                        physicalSurplusQuantity: produce,
                        civilDate: civilDate
                    ))
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        guard transfer.succeeded, let publication else {
            if transfer.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
            if let publicationError { throw publicationError }
            throw ExecutionError.custodyFailure(transfer.status)
        }
        return PebbleAgentAgriculturePhysicalResult(action: publication, physical: nil)
    }

    func liveSurplus(
        container: BlockEntityData,
        world: World,
        materialGateway: PebbleAgentMaterialCustodyGateway
    ) throws -> (seeds: Int, wheat: Int, fingerprint: String) {
        let endpoint = PebbleAgentMaterialCustodyEndpoint.container(container, in: world)
        let snapshot = try materialGateway.inspect(endpoint)
        let stacks = snapshot.slots.compactMap { $0 }
        return (
            seeds: stacks.filter {
                $0.identity.itemKey == AgentAgriculturalCrop.wheat.plantingItemKey
            }.reduce(0) { $0 + $1.count },
            wheat: stacks.filter {
                $0.identity.itemKey == AgentAgriculturalCrop.wheat.produceItemKey
            }.reduce(0) { $0 + $1.count },
            fingerprint: try materialGateway.fingerprint(endpoint)
        )
    }
}
