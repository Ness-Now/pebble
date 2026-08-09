import Foundation
import PebbleAgents
import PebbleCore

struct PebbleAgentWildSubsistencePhysicalResult {
    let status: AgentSubsistenceOutcomeStatus
    let physicalCausalIDs: [Int]
    let acquired: [AgentMaterialStackSnapshot]
    let custodyFingerprint: String?
    let attribution: String
    let detail: String
    let waitedTicks: Int
    let rodDurability: ItemStackDurabilityResult
}

/// Thin Pebble adapter over the existing Core fishing, combat, block-action,
/// and custody authorities. It contains no loot, damage, growth, or path rules.
struct PebbleAgentWildSubsistenceExecutor {
    enum ExecutionError: Error, CustomStringConvertible {
        case invalidActor
        case invalidTarget
        case missingEquipment
        case staleWorld
        case outOfReach
        case physicalFailure(String)
        case custodyFailure(PebbleAgentMaterialTransactionStatus, [Int])
        case rollbackFailure

        var description: String {
            switch self {
            case .invalidActor: return "invalid wild-subsistence embodiment"
            case .invalidTarget: return "invalid wild-subsistence target"
            case .missingEquipment: return "missing real required equipment"
            case .staleWorld: return "observed physical target is stale"
            case .outOfReach: return "physical target is out of reach"
            case let .physicalFailure(reason): return "physical subsistence failure: \(reason)"
            case let .custodyFailure(status, ids):
                return "physical custody failure: \(status.rawValue) retained=\(ids)"
            case .rollbackFailure: return "verified physical rollback failed"
            }
        }
    }

    /// Moves only by PebbleCore path nodes and `Entity.move`. Fixture setup may
    /// seed the initial position, but productive approach never teleports.
    @discardableResult
    func approach(
        world: World,
        actor: PebbleAgentEmbodiment,
        target: AgentPosition,
        maximumSteps: Int = 24,
        reach: Int = 2,
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil
    ) throws -> Int {
        guard actor.isValid(in: world) else { throw ExecutionError.invalidActor }
        let original = actor.probe.capturePhysicalState()
        var reservation: PebbleCandidatePhysicalCompensationReservation?
        var steps = 0
        var registrationSeamHandled = false
        do {
            while steps < maximumSteps {
                let here = actor.position
                let distance = abs(here.x - target.x) + abs(here.y - target.y)
                    + abs(here.z - target.z)
                if distance <= reach {
                    if let candidatePhysicalTransaction, let reservation {
                        let expectedAfter = actor.probe.capturePhysicalState()
                        let probe = actor.probe
                        do {
                            try candidatePhysicalTransaction.registerOrCompensate(
                                PebbleCandidatePhysicalCompensation(
                                reservation: reservation,
                                mutation: "wild subsistence approach",
                                agentID: actor.agentID,
                                probeID: actor.physicalID,
                                expectedBefore: original.description,
                                observedState: {
                                    probe.capturePhysicalState().description
                                },
                                compensate: {
                                    guard actor.probe === probe,
                                          actor.isValid(in: world),
                                          probe.capturePhysicalState() == expectedAfter else {
                                        return false
                                    }
                                    return probe.restorePhysicalState(original)
                                }
                                )
                            )
                        } catch {
                            registrationSeamHandled = true
                            throw error
                        }
                    }
                    return steps
                }
                guard let path = findPath(
                    world, actor.x, actor.y, actor.z,
                    Double(target.x) + 0.5, Double(target.y),
                    Double(target.z) + 0.5, 600, true
                ), let node = path.first else { throw ExecutionError.outOfReach }
                let dx = Double(node.x) + 0.5 - actor.x
                let dy = Double(node.y) - actor.y
                let dz = Double(node.z) + 0.5 - actor.z
                guard max(abs(node.x - here.x), abs(node.z - here.z)) == 1,
                      (-3...1).contains(node.y - here.y) else {
                    throw ExecutionError.physicalFailure(
                        "Core path returned unsupported step"
                    )
                }
                if reservation == nil, let candidatePhysicalTransaction {
                    reservation = try candidatePhysicalTransaction.reserve(
                        compensationPrefix: "wild-approach:\(actor.agentID)"
                    )
                }
                actor.probe.yaw = detAtan2(-dx, dz)
                actor.probe.move(dx, dy, dz)
                guard actor.position
                        == AgentPosition(x: node.x, y: node.y, z: node.z) else {
                    throw ExecutionError.physicalFailure(
                        "Core collision refused path node"
                    )
                }
                steps += 1
            }
            throw ExecutionError.outOfReach
        } catch {
            if registrationSeamHandled {
                throw error
            }
            guard actor.probe.restorePhysicalState(original) else {
                throw ExecutionError.rollbackFailure
            }
            throw error
        }
    }

    func fish(
        world: World,
        actor: PebbleAgentEmbodiment,
        water: AgentPosition,
        rodSlot: Int,
        attemptID: String,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        maximumWaitTicks: Int = 25_000,
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil,
        publish: (
            [Int], [AgentMaterialStackSnapshot], String, String
        ) throws -> Void
    ) throws -> PebbleAgentWildSubsistencePhysicalResult {
        guard actor.isValid(in: world), actor.carriedItems.indices.contains(rodSlot) else {
            throw ExecutionError.invalidActor
        }
        guard (world.getBlock(water.x, water.y, water.z) >> 4) == Int(B.water) else {
            throw ExecutionError.staleWorld
        }
        guard let rod = actor.carriedItems[rodSlot], rod.count == 1,
              itemDef(rod.id).name == "fishing_rod" else {
            throw ExecutionError.missingEquipment
        }
        let actorStateBefore = actor.probe.capturePhysicalState()
        let inventoryBefore = copyItemInventory(actor.carriedItems)
        let entityIDsBefore = Set(world.entities.map(\.id))
        let gameRngBefore = gameRng
        let reservation: PebbleCandidatePhysicalCompensationReservation?
        if let candidatePhysicalTransaction {
            reservation = try candidatePhysicalTransaction.reserve(
                compensationPrefix: "wild-fishing:\(attemptID)"
            )
        } else {
            reservation = nil
        }
        func rollbackCandidateFishing() -> Bool {
            guard let candidatePhysicalTransaction else { return true }
            _ = candidatePhysicalTransaction
            for entity in world.entities
            where !entityIDsBefore.contains(entity.id) {
                world.removeEntity(entity)
            }
            actor.carriedItems = copyItemInventory(inventoryBefore)
            gameRng = gameRngBefore
            return actor.probe.restorePhysicalState(actorStateBefore)
                && inventoryEqual(actor.carriedItems, inventoryBefore)
                && gameRng == gameRngBefore
                && Set(world.entities.map(\.id)) == entityIDsBefore
        }
        let horizontal = abs(actor.position.x - water.x) + abs(actor.position.z - water.z)
        guard horizontal <= 3, abs(actor.position.y - water.y) <= 2 else {
            throw ExecutionError.outOfReach
        }
        let (fishingPhysical, bufferedWorldEffects) =
            captureCandidateWorldEffects(world: world) {
                actor.probe.yaw = detAtan2(
                    -(Double(water.x) + 0.5 - actor.x),
                    Double(water.z) + 0.5 - actor.z
                )
                actor.probe.pitch = degToRad(22)
                let bobber = castFishingBobber(
                    world: world, owner: actor.probe, rod: rod,
                    originX: actor.x, originY: actor.y + 0.8,
                    originZ: actor.z, pitch: actor.pitch, yaw: actor.yaw
                )
                var waited = 0
                var enteredWater = false
                while bobber.biteTime == 0 && !bobber.dead
                    && waited < maximumWaitTicks {
                    bobber.tick()
                    enteredWater = enteredWater || bobber.inWater
                        || (world.getBlock(
                            Int(floor(bobber.x)), Int(floor(bobber.y)),
                            Int(floor(bobber.z))
                        ) >> 4) == Int(B.water)
                    waited += 1
                }
                let retrieval = bobber.retrieve()
                let durability = damageItemStack(
                    rod, amount: 1, random: { gameRng.nextFloat() }
                )
                if durability == .broken { actor.carriedItems[rodSlot] = nil }
                return (retrieval, durability, waited, enteredWater)
            }
        let (retrieval, durability, waited, enteredWater) = fishingPhysical
        if candidatePhysicalTransaction == nil {
            publishCandidateWorldEffects(bufferedWorldEffects, world: world)
        }
        guard enteredWater else {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            throw ExecutionError.physicalFailure("real bobber never entered water")
        }
        guard retrieval.kind == .caughtLoot, !retrieval.spawnedItemEntityIDs.isEmpty else {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            return PebbleAgentWildSubsistencePhysicalResult(
                status: .failed, physicalCausalIDs: [], acquired: [], custodyFingerprint: nil,
                attribution: "core-fishing-\(retrieval.kind.rawValue)",
                detail: "retrieve=\(retrieval.kind.rawValue) xp=\(retrieval.experienceAmount)",
                waitedTicks: waited, rodDurability: durability
            )
        }
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: retrieval.spawnedItemEntityIDs, world: world
        ) else {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            throw ExecutionError.physicalFailure("invalid exact fishing provenance")
        }
        let inventoryAfterRetrieval = copyItemInventory(actor.carriedItems)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let before: String
        do {
            before = try materialGateway.fingerprint(destination)
        } catch {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            throw error
        }
        var publicationError: Error?
        let acquisition = materialGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: attemptID + ":fishing-loot",
                spawnedItemEntityIDs: retrieval.spawnedItemEntityIDs,
                expectedDestinationFingerprint: before
            ),
            from: source, to: destination,
            verifyAfterMutation: { acquired in
                do {
                    try publish(
                        retrieval.spawnedItemEntityIDs, acquired.acquired.map(\.material),
                        acquired.destinationFingerprint ?? "",
                        "core-fishing-retrieve:xp=\(retrieval.experienceAmount)"
                    )
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        if let publicationError {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            throw publicationError
        }
        guard acquisition.succeeded else {
            guard rollbackCandidateFishing() else {
                throw ExecutionError.rollbackFailure
            }
            if acquisition.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
            throw ExecutionError.custodyFailure(
                acquisition.status, retrieval.spawnedItemEntityIDs
            )
        }
        let result = PebbleAgentWildSubsistencePhysicalResult(
            status: .succeeded,
            physicalCausalIDs: retrieval.spawnedItemEntityIDs,
            acquired: acquisition.acquired.map(\.material),
            custodyFingerprint: acquisition.destinationFingerprint,
            attribution: "core-fishing-retrieve:xp=\(retrieval.experienceAmount)",
            detail: "waited=\(waited) retrieve=caughtLoot xp=\(retrieval.experienceAmount)",
            waitedTicks: waited, rodDurability: durability
        )
        if let candidatePhysicalTransaction, let reservation {
            let actorStateAfter = actor.probe.capturePhysicalState()
            let entityIDsAfterAcquisition = Set(world.entities.map(\.id))
            let gameRngAfter = gameRng
            let sourceIDs = Set(retrieval.spawnedItemEntityIDs)
            let compensation = PebbleCandidatePhysicalCompensation(
                reservation: reservation,
                mutation: "wild fishing cast, retrieval, and equipment wear",
                agentID: actor.agentID,
                probeID: actor.physicalID,
                expectedBefore: actorStateBefore.description,
                observedState: {
                    "actor={\(actor.probe.capturePhysicalState())} "
                        + "entities=\(world.entities.map(\.id).sorted())"
                },
                compensate: {
                    guard actor.isValid(in: world),
                          actor.probe.capturePhysicalState() == actorStateAfter,
                          inventoryEqual(
                              actor.carriedItems, inventoryAfterRetrieval
                          ),
                          gameRng == gameRngAfter,
                          Set(world.entities.map(\.id))
                            == entityIDsAfterAcquisition.union(sourceIDs),
                          retrieval.spawnedItemEntityIDs.allSatisfy({ id in
                              world.entityById[id] is ItemEntity
                          }) else {
                        return false
                    }
                    for entity in world.entities
                    where !entityIDsBefore.contains(entity.id) {
                        world.removeEntity(entity)
                    }
                    actor.carriedItems = copyItemInventory(inventoryBefore)
                    gameRng = gameRngBefore
                    return actor.probe.restorePhysicalState(actorStateBefore)
                        && inventoryEqual(actor.carriedItems, inventoryBefore)
                        && gameRng == gameRngBefore
                        && Set(world.entities.map(\.id)) == entityIDsBefore
                },
                commit: {
                    publishCandidateWorldEffects(
                        bufferedWorldEffects, world: world
                    )
                }
            )
            do {
                try candidatePhysicalTransaction.registerOrCompensate(
                    compensation
                )
            } catch {
                throw error
            }
        }
        return result
    }

    func hunt(
        world: World,
        actor: PebbleAgentEmbodiment,
        target: LivingEntity,
        expectedSpecies: String,
        weaponSlot: Int,
        attemptID: String,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        candidatePhysicalTransaction: PebbleCandidatePhysicalTransaction? = nil,
        publish: (
            [Int], [AgentMaterialStackSnapshot], String, String
        ) throws -> Void
    ) throws -> PebbleAgentWildSubsistencePhysicalResult {
        guard actor.isValid(in: world), target.world === world,
              world.entityById[target.id] === target, !target.dead, target.deathTime == 0,
              target.type == expectedSpecies else { throw ExecutionError.staleWorld }
        guard actor.carriedItems.indices.contains(weaponSlot),
              let weapon = actor.carriedItems[weaponSlot],
              itemDef(weapon.id).tool?.type == "sword" else {
            throw ExecutionError.missingEquipment
        }
        let targetBefore = target.captureCombatState()
        let inventoryBefore = copyItemInventory(actor.carriedItems)
        let entityIDsBefore = Set(world.entities.map(\.id))
        let gameRngBefore = gameRng
        let reservation: PebbleCandidatePhysicalCompensationReservation?
        if let candidatePhysicalTransaction {
            reservation = try candidatePhysicalTransaction.reserve(
                compensationPrefix: "wild-hunting:\(attemptID)"
            )
        } else {
            reservation = nil
        }
        func rollbackCandidateHunt() -> Bool {
            guard let candidatePhysicalTransaction else { return true }
            _ = candidatePhysicalTransaction
            for entity in world.entities where !entityIDsBefore.contains(entity.id) {
                world.removeEntity(entity)
            }
            actor.carriedItems = copyItemInventory(inventoryBefore)
            gameRng = gameRngBefore
            return target.restoreCombatState(targetBefore)
                && inventoryEqual(actor.carriedItems, inventoryBefore)
                && gameRng == gameRngBefore
                && Set(world.entities.map(\.id)) == entityIDsBefore
        }
        let (attack, bufferedWorldEffects) = captureCandidateWorldEffects(
            world: world
        ) {
            let attack = executeActorMeleeAttack(
                attacker: actor.probe, heldItem: weapon, target: target,
                random: { gameRng.nextFloat() }
            )
            if attack.durabilityResult == .broken {
                actor.carriedItems[weaponSlot] = nil
            }
            return attack
        }
        if candidatePhysicalTransaction == nil {
            publishCandidateWorldEffects(bufferedWorldEffects, world: world)
        }
        guard attack.status != .outOfReach else {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            throw ExecutionError.outOfReach
        }
        guard attack.succeeded else {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            throw ExecutionError.physicalFailure(attack.status.rawValue)
        }
        guard attack.killed, attack.attributedToAttacker,
              !attack.spawnedItemEntityIDs.isEmpty else {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            return PebbleAgentWildSubsistencePhysicalResult(
                status: .failed, physicalCausalIDs: [], acquired: [], custodyFingerprint: nil,
                attribution: "core-combat-hit", detail: "damage=\(attack.attemptedDamage) killed=0",
                waitedTicks: 0, rodDurability: .unchanged
            )
        }
        guard let source = PebbleAgentItemEntityCustodyEndpoint(
            spawnedItemEntityIDs: attack.spawnedItemEntityIDs, world: world
        ) else {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            throw ExecutionError.physicalFailure("invalid exact death-drop provenance")
        }
        let inventoryAfterAttack = copyItemInventory(actor.carriedItems)
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        let before: String
        do {
            before = try materialGateway.fingerprint(destination)
        } catch {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            throw error
        }
        var publicationError: Error?
        let acquisition = materialGateway.acquireItemEntities(
            PebbleAgentItemEntityAcquisitionRequest(
                transactionID: attemptID + ":death-drops",
                spawnedItemEntityIDs: attack.spawnedItemEntityIDs,
                expectedDestinationFingerprint: before
            ),
            from: source, to: destination,
            verifyAfterMutation: { acquired in
                do {
                    try publish(
                        attack.spawnedItemEntityIDs, acquired.acquired.map(\.material),
                        acquired.destinationFingerprint ?? "", "core-final-damaging-actor"
                    )
                    return true
                } catch {
                    publicationError = error
                    return false
                }
            }
        )
        if let publicationError {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            throw publicationError
        }
        guard acquisition.succeeded else {
            guard rollbackCandidateHunt() else { throw ExecutionError.rollbackFailure }
            if acquisition.status == .rollbackFailure { throw ExecutionError.rollbackFailure }
            throw ExecutionError.custodyFailure(
                acquisition.status, attack.spawnedItemEntityIDs
            )
        }
        let result = PebbleAgentWildSubsistencePhysicalResult(
            status: .succeeded, physicalCausalIDs: attack.spawnedItemEntityIDs,
            acquired: acquisition.acquired.map(\.material),
            custodyFingerprint: acquisition.destinationFingerprint,
            attribution: "core-final-damaging-actor",
            detail: "damage=\(attack.attemptedDamage) health=\(attack.healthBefore ?? 0)->\(attack.healthAfter ?? 0) killed=1",
            waitedTicks: 0, rodDurability: .unchanged
        )
        if let candidatePhysicalTransaction, let reservation {
            let targetAfter = target.captureCombatState()
            let entityIDsAfterAcquisition = Set(world.entities.map(\.id))
            let gameRngAfter = gameRng
            let sourceIDs = Set(attack.spawnedItemEntityIDs)
            let compensation = PebbleCandidatePhysicalCompensation(
                reservation: reservation,
                mutation: "wild hunting combat, death, drops, and equipment wear",
                agentID: actor.agentID,
                probeID: actor.physicalID,
                expectedBefore: targetBefore.description,
                observedState: {
                    "target={\(target.captureCombatState())} "
                        + "entities=\(world.entities.map(\.id).sorted())"
                },
                compensate: {
                    guard actor.isValid(in: world),
                          target.world === world,
                          world.entityById[target.id] === target,
                          target.combatStateMatches(targetAfter),
                          inventoryEqual(actor.carriedItems, inventoryAfterAttack),
                          gameRng == gameRngAfter,
                          Set(world.entities.map(\.id))
                            == entityIDsAfterAcquisition.union(sourceIDs),
                          attack.spawnedItemEntityIDs.allSatisfy({ id in
                              world.entityById[id] is ItemEntity
                          }) else {
                        return false
                    }
                    for entity in world.entities
                    where !entityIDsBefore.contains(entity.id) {
                        world.removeEntity(entity)
                    }
                    actor.carriedItems = copyItemInventory(inventoryBefore)
                    gameRng = gameRngBefore
                    return target.restoreCombatState(targetBefore)
                        && inventoryEqual(actor.carriedItems, inventoryBefore)
                        && gameRng == gameRngBefore
                        && Set(world.entities.map(\.id)) == entityIDsBefore
                },
                commit: {
                    publishCandidateWorldEffects(
                        bufferedWorldEffects, world: world
                    )
                }
            )
            do {
                try candidatePhysicalTransaction.registerOrCompensate(
                    compensation
                )
            } catch {
                throw error
            }
        }
        return result
    }

    func gather(
        world: World,
        actor: PebbleAgentEmbodiment,
        target: PhysicalBlockPosition,
        expectedBlockID: Int,
        attemptID: String,
        occupiedPositions: [PhysicalBlockPosition],
        physicalGateway: PebbleAgentPhysicalActionGateway,
        materialGateway: PebbleAgentMaterialCustodyGateway,
        publish: (
            [Int], [AgentMaterialStackSnapshot], String, String
        ) throws -> Void
    ) throws -> PebbleAgentWildSubsistencePhysicalResult {
        guard actor.isValid(in: world) else { throw ExecutionError.invalidActor }
        let beforeCell = world.getBlock(target.x, target.y, target.z)
        guard beforeCell >> 4 == expectedBlockID else { throw ExecutionError.staleWorld }
        let destination = PebbleAgentMaterialCustodyEndpoint.liveAgent(actor, in: world)
        var acquisition: PebbleAgentItemEntityAcquisitionOutcome?
        var publicationError: Error?
        let physical = physicalGateway.breakBlock(
            world: world, actor: actor,
            request: PebbleAgentBlockBreakRequest(
                actorID: actor.agentID, target: target, expectedCell: beforeCell,
                heldItem: nil, isCreative: false
            ),
            occupiedPositions: occupiedPositions,
            acquireDrops: { ids in
                guard let source = PebbleAgentItemEntityCustodyEndpoint(
                    spawnedItemEntityIDs: ids, world: world
                ), let destinationBefore = try? materialGateway.fingerprint(destination) else {
                    return false
                }
                let result = materialGateway.acquireItemEntities(
                    PebbleAgentItemEntityAcquisitionRequest(
                        transactionID: attemptID + ":wild-drops",
                        spawnedItemEntityIDs: ids,
                        expectedDestinationFingerprint: destinationBefore
                    ),
                    from: source, to: destination,
                    verifyAfterMutation: { acquired in
                        do {
                            try publish(
                                ids, acquired.acquired.map(\.material),
                                acquired.destinationFingerprint ?? "", "core-canonical-block-break"
                            )
                            return true
                        } catch {
                            publicationError = error
                            return false
                        }
                    }
                )
                acquisition = result
                return result.succeeded
            }
        )
        if let publicationError { throw publicationError }
        guard physical.succeeded, let acquisition, acquisition.succeeded else {
            if physical.status == .rollbackFailure || acquisition?.status == .rollbackFailure {
                throw ExecutionError.rollbackFailure
            }
            if let acquisition {
                throw ExecutionError.custodyFailure(
                    acquisition.status, physical.spawnedItemEntityIDs
                )
            }
            throw ExecutionError.physicalFailure(
                physical.status.rawValue + ":" + (physical.failure?.rawValue ?? "unknown")
            )
        }
        return PebbleAgentWildSubsistencePhysicalResult(
            status: .succeeded,
            physicalCausalIDs: physical.spawnedItemEntityIDs,
            acquired: acquisition.acquired.map(\.material),
            custodyFingerprint: acquisition.destinationFingerprint,
            attribution: "core-canonical-block-break",
            detail: "cell=\(beforeCell)->\(world.getBlock(target.x, target.y, target.z))",
            waitedTicks: 0, rodDurability: .unchanged
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
