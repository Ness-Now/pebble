import PebbleAgents
import PebbleCore

struct PebbleAgentLivestockExecutor {
    enum ExecutionError: Error, CustomStringConvertible {
        case invalidActor
        case staleAnimal
        case wrongFeed
        case missingFeed
        case feedRefused
        case productUnavailable
        case missingTool
        case custodyFailure(PebbleAgentMaterialTransactionStatus)
        case publicationFailure
        case rollbackFailure

        var description: String {
            switch self {
            case .invalidActor: return "invalid livestock embodiment"
            case .staleAnimal: return "managed animal no longer resolves exactly"
            case .wrongFeed: return "held item is not compatible animal feed"
            case .missingFeed: return "missing real compatible feed"
            case .feedRefused: return "PebbleCore refused feeding state"
            case .productUnavailable: return "real animal product unavailable"
            case .missingTool: return "missing real livestock tool"
            case let .custodyFailure(status): return "product custody failed: \(status.rawValue)"
            case .publicationFailure: return "livestock publication failed"
            case .rollbackFailure: return "verified livestock rollback failed"
            }
        }
    }

    func feed(
        world: World,
        actor: PebbleAgentEmbodiment,
        animal: Animal,
        taskID: AgentLivestockTaskID,
        actionID: AgentLivestockActionID,
        recordID: AgentManagedAnimalRecordID,
        completedAtTick: Int,
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil,
        publish: (AgentLivestockValidatedOutcome) throws -> Void
    ) throws -> AgentLivestockValidatedOutcome {
        guard actor.isValid(in: world) else { throw ExecutionError.invalidActor }
        guard animal.world === world, world.entityById[animal.id] === animal,
              !animal.dead, animal.deathTime <= 0 else { throw ExecutionError.staleAnimal }
        let feedSlots = actor.carriedItems.indices.filter { index in
            guard let stack = actor.carriedItems[index], stack.count > 0 else { return false }
            return animal.isFood(stack)
        }
        guard let slot = feedSlots.first, let held = actor.carriedItems[slot] else {
            let hasAny = actor.carriedItems.contains { $0 != nil }
            throw hasAny ? ExecutionError.wrongFeed : ExecutionError.missingFeed
        }
        let inventoryBefore = actor.carriedItems.map { $0?.copy() }
        let loveBefore = animal.loveTicks
        let growthBefore = animal.growUpAge
        let causeBefore = animal.data.loveCause
        let reservation: PebbleCandidatePhysicalCompensationReservation?
        if let candidatePhysicalTransaction {
            reservation = try candidatePhysicalTransaction.reserve(
                compensationPrefix: "livestock-feed:\(actionID.rawValue)"
            )
        } else {
            reservation = nil
        }
        let material = try PebbleAgentMaterialSnapshotBridge().snapshot(
            of: ItemStack(held.id, 1, damage: held.damage, ench: held.ench, label: held.label, data: held.data)
        )
        let (fed, bufferedWorldEffects) = captureCandidateWorldEffects(
            world: world
        ) {
            animal.tryFeed(held, actorEntityID: actor.probe.id)
        }
        if candidatePhysicalTransaction == nil {
            publishCandidateWorldEffects(bufferedWorldEffects, world: world)
        }
        guard fed else {
            throw ExecutionError.feedRefused
        }
        held.count -= 1
        if held.count == 0 { actor.carriedItems[slot] = nil }
        let outcome = AgentLivestockValidatedOutcome(
            actionID: actionID, taskID: taskID,
            actorID: AgentID(rawValue: actor.agentID)!, kind: .feed,
            status: .succeeded, primaryAnimalRecordID: recordID,
            physicalCausalIDs: [animal.id], consumedItems: [material],
            attribution: "PebbleCore.Animal.tryFeed", completedAtTick: completedAtTick
        )
        do {
            try publish(outcome)
            if let candidatePhysicalTransaction, let reservation {
                let inventoryAfter = actor.carriedItems.map { $0?.copy() }
                let loveAfter = animal.loveTicks
                let growthAfter = animal.growUpAge
                let causeAfter = animal.data.loveCause
                let compensation = PebbleCandidatePhysicalCompensation(
                    reservation: reservation,
                    mutation: "livestock feeding",
                    agentID: actor.agentID,
                    probeID: actor.physicalID,
                    expectedBefore: "inventory/love=\(loveBefore)/growth=\(growthBefore)",
                    observedState: {
                        "love=\(animal.loveTicks) growth=\(animal.growUpAge)"
                    },
                    compensate: {
                        guard actor.isValid(in: world),
                              inventoryEqual(actor.carriedItems, inventoryAfter),
                              animal.world === world,
                              world.entityById[animal.id] === animal,
                              animal.loveTicks == loveAfter,
                              animal.growUpAge == growthAfter,
                              animal.data.loveCause == causeAfter else {
                            return false
                        }
                        actor.carriedItems = inventoryBefore.map { $0?.copy() }
                        animal.loveTicks = loveBefore
                        animal.growUpAge = growthBefore
                        animal.data.loveCause = causeBefore
                        return inventoryEqual(actor.carriedItems, inventoryBefore)
                            && animal.loveTicks == loveBefore
                            && animal.growUpAge == growthBefore
                            && animal.data.loveCause == causeBefore
                    },
                    commit: {
                        publishCandidateWorldEffects(
                            bufferedWorldEffects, world: world
                        )
                    }
                )
                do {
                    try candidatePhysicalTransaction.register(compensation)
                } catch {
                    actor.carriedItems = inventoryBefore.map { $0?.copy() }
                    animal.loveTicks = loveBefore
                    animal.growUpAge = growthBefore
                    animal.data.loveCause = causeBefore
                    throw ExecutionError.rollbackFailure
                }
            }
            return outcome
        } catch {
            actor.carriedItems = inventoryBefore
            animal.loveTicks = loveBefore
            animal.growUpAge = growthBefore
            animal.data.loveCause = causeBefore
            guard inventoryEqual(actor.carriedItems, inventoryBefore),
                  animal.loveTicks == loveBefore, animal.growUpAge == growthBefore,
                  animal.data.loveCause == causeBefore else { throw ExecutionError.rollbackFailure }
            throw error
        }
    }

    func shear(
        world: World,
        actor: PebbleAgentEmbodiment,
        sheep: Sheep,
        taskID: AgentLivestockTaskID,
        actionID: AgentLivestockActionID,
        recordID: AgentManagedAnimalRecordID,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        completedAtTick: Int,
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil,
        publish: (AgentLivestockValidatedOutcome) throws -> Void
    ) throws -> AgentLivestockValidatedOutcome {
        guard actor.isValid(in: world), sheep.world === world,
              world.entityById[sheep.id] === sheep, !sheep.dead else { throw ExecutionError.staleAnimal }
        guard let slot = actor.carriedItems.indices.first(where: {
            actor.carriedItems[$0].map { itemDef($0.id).name == "shears" && $0.count == 1 } ?? false
        }), let tool = actor.carriedItems[slot] else { throw ExecutionError.missingTool }
        let inventoryBefore = actor.carriedItems.map { $0?.copy() }
        let toolBefore = tool.copy()
        let shearedBefore = sheep.sheared
        let gameRngBefore = gameRng
        let reservation: PebbleCandidatePhysicalCompensationReservation?
        if let candidatePhysicalTransaction {
            reservation = try candidatePhysicalTransaction.reserve(
                compensationPrefix: "livestock-shear:\(actionID.rawValue)"
            )
        } else {
            reservation = nil
        }
        let (shearingPhysical, bufferedWorldEffects) =
            captureCandidateWorldEffects(world: world) {
                let shearing = sheep.shearForLivestock()
                if damageItemStack(
                    tool, amount: 1, random: { gameRng.nextFloat() }
                ) == .broken {
                    actor.carriedItems[slot] = nil
                }
                return shearing
            }
        if candidatePhysicalTransaction == nil {
            publishCandidateWorldEffects(bufferedWorldEffects, world: world)
        }
        guard let shearing = shearingPhysical else {
            throw ExecutionError.productUnavailable
        }
        let inventoryAfterToolDamage = actor.carriedItems.map { $0?.copy() }
        func rollbackPhysicalShearing() throws {
            sheep.sheared = shearedBefore
            actor.carriedItems = inventoryBefore.map { $0?.copy() }
            gameRng = gameRngBefore
            for id in shearing.spawnedItemEntityIDs {
                if let item = world.entityById[id] as? ItemEntity { world.removeEntity(item) }
            }
            guard sheep.sheared == shearedBefore,
                  shearing.spawnedItemEntityIDs.allSatisfy({ world.entityById[$0] == nil }),
                  inventoryEqual(actor.carriedItems, inventoryBefore) else {
                throw ExecutionError.rollbackFailure
            }
        }
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: shearing.spawnedItemEntityIDs, world: world
        ) else {
            try rollbackPhysicalShearing()
            throw ExecutionError.productUnavailable
        }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let destinationBefore: String
        do {
            destinationBefore = try materialGateway.fingerprint(destination)
        } catch {
            try rollbackPhysicalShearing()
            throw error
        }
        var published: AgentLivestockValidatedOutcome?
        var publicationError: Error?
        let acquisition = materialGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: actionID.rawValue + ":wool",
                spawnedItemEntityIDs: shearing.spawnedItemEntityIDs,
                expectedDestinationFingerprint: destinationBefore
            ),
            from: source, to: destination,
            verifyAfterMutation: { acquired in
                let outcome = AgentLivestockValidatedOutcome(
                    actionID: actionID, taskID: taskID,
                    actorID: AgentID(rawValue: actor.agentID)!, kind: .collectProduct,
                    status: .succeeded, primaryAnimalRecordID: recordID,
                    physicalCausalIDs: shearing.spawnedItemEntityIDs,
                    acquiredItems: acquired.acquired.map(\.material),
                    custodyFingerprint: acquired.destinationFingerprint,
                    attribution: "PebbleCore.Sheep.shearForLivestock",
                    completedAtTick: completedAtTick
                )
                do { try publish(outcome); published = outcome; return true }
                catch { publicationError = error; return false }
            }
        )
        if acquisition.succeeded, let published {
            if let candidatePhysicalTransaction, let reservation {
                let compensation = PebbleCandidatePhysicalCompensation(
                    reservation: reservation,
                    mutation: "livestock shearing",
                    agentID: actor.agentID,
                    probeID: actor.physicalID,
                    expectedBefore: "sheared=\(shearedBefore ? 1 : 0) "
                        + "tool=\(toolBefore.id):\(toolBefore.damage)",
                    observedState: {
                        "sheared=\(sheep.sheared ? 1 : 0) "
                            + "entities=\(shearing.spawnedItemEntityIDs)"
                    },
                    compensate: {
                        guard actor.isValid(in: world),
                              sheep.world === world,
                              world.entityById[sheep.id] === sheep,
                              sheep.sheared,
                              inventoryEqual(
                                  actor.carriedItems,
                                  inventoryAfterToolDamage
                              ),
                              shearing.spawnedItemEntityIDs.allSatisfy({ id in
                                  world.entityById[id] is ItemEntity
                              }) else {
                            return false
                        }
                        for id in shearing.spawnedItemEntityIDs {
                            if let item = world.entityById[id] as? ItemEntity {
                                world.removeEntity(item)
                            }
                        }
                        actor.carriedItems = inventoryBefore.map { $0?.copy() }
                        sheep.sheared = shearedBefore
                        gameRng = gameRngBefore
                        return inventoryEqual(actor.carriedItems, inventoryBefore)
                            && sheep.sheared == shearedBefore
                            && shearing.spawnedItemEntityIDs.allSatisfy {
                                world.entityById[$0] == nil
                            }
                    },
                    commit: {
                        publishCandidateWorldEffects(
                            bufferedWorldEffects, world: world
                        )
                    }
                )
                do {
                    try candidatePhysicalTransaction.register(compensation)
                } catch {
                    throw ExecutionError.rollbackFailure
                }
            }
            return published
        }
        try rollbackPhysicalShearing()
        if let publicationError { throw publicationError }
        if acquisition.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
        throw ExecutionError.custodyFailure(acquisition.status)
    }

    func resolve(
        record: AgentManagedAnimalRecord,
        transientEntityID: Int?,
        world: World,
        observedAtTick: Int
    ) -> AgentManagedAnimalResolution {
        if let transientEntityID {
            if let animal = world.entityById[transientEntityID] as? Animal,
               !animal.dead, animal.type == record.speciesKey {
                return resolution(record: record, animal: animal, tick: observedAtTick, reason: "transient runtime binding")
            }
            return AgentManagedAnimalResolution(
                recordID: record.recordID, kind: .missing,
                speciesKey: record.speciesKey,
                reason: "known transient runtime binding is absent",
                observedAtTick: observedAtTick
            )
        }
        return AgentManagedAnimalResolution(
            recordID: record.recordID,
            kind: .ambiguous,
            speciesKey: record.speciesKey,
            reason: "durable physical identity unavailable; explicit re-observation required",
            observedAtTick: observedAtTick
        )
    }

    private func resolution(
        record: AgentManagedAnimalRecord,
        animal: Animal,
        tick: Int,
        reason: String
    ) -> AgentManagedAnimalResolution {
        AgentManagedAnimalResolution(
            recordID: record.recordID, kind: .resolvedLiving,
            speciesKey: animal.type,
            position: AgentPosition(
                x: Int(animal.x.rounded(.down)), y: Int(animal.y.rounded(.down)),
                z: Int(animal.z.rounded(.down))
            ),
            lifeStage: animal.baby ? .juvenile : .adult,
            breedingReady: animal.loveTicks > 0 && animal.breedCooldown == 0,
            productReady: (animal as? Sheep).map { !$0.sheared && !$0.baby } ?? false,
            reason: reason, observedAtTick: tick
        )
    }

    private func inventoryEqual(
        _ lhs: [ItemStack?],
        _ rhs: [ItemStack?]
    ) -> Bool {
        lhs.elementsEqual(rhs, by: { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (a?, b?): return a == b
            default: return false
            }
        })
    }
}
