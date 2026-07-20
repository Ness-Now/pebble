import PebbleAgents
import PebbleCore

enum PebbleAgentMaterialTransactionStatus: String {
    case succeeded
    case invalidRequest
    case unknownMaterialIdentity
    case staleSource
    case staleDestination
    case insufficientQuantity
    case incompatibleDestination
    case destinationFull
    case physicalExecutionFailure
    case verificationFailure
    case rollbackFailure
    case duplicate
}

struct PebbleAgentMaterialTransactionRequest {
    let transactionID: String
    let material: AgentMaterialStackSnapshot
    let expectedSourceFingerprint: String
    let expectedDestinationFingerprint: String?
}

struct PebbleAgentMaterialTransactionOutcome {
    let transactionID: String
    let status: PebbleAgentMaterialTransactionStatus
    let quantityMoved: Int
    let sourceFingerprint: String?
    let destinationFingerprint: String?

    var succeeded: Bool { status == .succeeded }
}

struct PebbleAgentItemEntityAcquisitionRequest {
    let transactionID: String
    let spawnedItemEntityIDs: [Int]
    let expectedDestinationFingerprint: String
}

struct PebbleAgentItemEntityAcquisitionRecord: Equatable {
    let entityID: Int
    let material: AgentMaterialStackSnapshot
}

struct PebbleAgentItemEntityAcquisitionOutcome {
    let transactionID: String
    let status: PebbleAgentMaterialTransactionStatus
    let acquired: [PebbleAgentItemEntityAcquisitionRecord]
    let destinationFingerprint: String?

    var succeeded: Bool { status == .succeeded }
    var quantityMoved: Int { acquired.reduce(0) { $0 + $1.material.count } }
}

/// Exact, bounded source view over ItemEntity identities reported by one
/// PebbleCore action. It never performs a radius query or discovers nearby
/// items, so unrelated entities cannot enter the transfer.
struct PebbleAgentItemEntityCustodyEndpoint {
    static let maximumEntityCount = 64

    let spawnedItemEntityIDs: [Int]
    private let world: World

    init?(spawnedItemEntityIDs: [Int], world: World) {
        guard !spawnedItemEntityIDs.isEmpty,
              spawnedItemEntityIDs.count <= Self.maximumEntityCount,
              spawnedItemEntityIDs.count == Set(spawnedItemEntityIDs).count else {
            return nil
        }
        self.spawnedItemEntityIDs = spawnedItemEntityIDs
        self.world = world
    }

    func read() -> [ItemEntity]? {
        let byID = Dictionary(uniqueKeysWithValues: world.entities.compactMap { entity in
            (entity as? ItemEntity).map { ($0.id, $0) }
        })
        let items = spawnedItemEntityIDs.compactMap { byID[$0] }
        return items.count == spawnedItemEntityIDs.count ? items : nil
    }

    func containsNone() -> Bool {
        let ids = Set(spawnedItemEntityIDs)
        return world.entities.allSatisfy { !ids.contains($0.id) }
    }

    func remove(_ items: [ItemEntity]) -> Bool {
        guard items.map(\.id) == spawnedItemEntityIDs else { return false }
        for item in items { world.removeEntity(item) }
        return containsNone()
    }

    func restore(_ items: [ItemEntity]) -> Bool {
        guard items.map(\.id) == spawnedItemEntityIDs,
              containsNone() else { return false }
        for item in items { world.addEntity(item) }
        return read()?.elementsEqual(items, by: { $0 === $1 }) == true
    }
}

/// One of the two bounded V1 physical holder kinds. A location expresses
/// custody only; it conveys no social owner, claim, permission, or entitlement.
struct PebbleAgentMaterialCustodyEndpoint {
    let locationID: String
    private let isValidImpl: () -> Bool
    private let readImpl: () -> [ItemStack?]?
    private let writeImpl: ([ItemStack?]) -> Bool

    static func liveAgent(
        _ actor: LabCoreAgentEntity,
        in world: World
    ) -> PebbleAgentMaterialCustodyEndpoint {
        PebbleAgentMaterialCustodyEndpoint(
            locationID: "agent:\(actor.physicalId)",
            isValidImpl: {
                actor.world === world && !actor.dead
                    && world.entities.contains(where: { $0 === actor })
                    && actor.carriedItems.count == LabCoreAgentEntity.carriedItemSlotCount
            },
            readImpl: {
                guard actor.world === world, !actor.dead,
                      world.entities.contains(where: { $0 === actor }) else { return nil }
                return copyItemInventory(actor.carriedItems)
            },
            writeImpl: { slots in
                guard actor.world === world, !actor.dead,
                      world.entities.contains(where: { $0 === actor }),
                      slots.count == LabCoreAgentEntity.carriedItemSlotCount else { return false }
                actor.carriedItems = copyItemInventory(slots)
                return true
            }
        )
    }

    static func container(
        _ container: BlockEntityData,
        in world: World
    ) -> PebbleAgentMaterialCustodyEndpoint {
        let location = "container:\(container.x),\(container.y),\(container.z)"
        return PebbleAgentMaterialCustodyEndpoint(
            locationID: location,
            isValidImpl: {
                container.type == "container"
                    && container.items != nil
                    && world.getBlockEntity(container.x, container.y, container.z) === container
            },
            readImpl: {
                guard container.type == "container",
                      world.getBlockEntity(container.x, container.y, container.z) === container,
                      let items = container.items else { return nil }
                return copyItemInventory(items)
            },
            writeImpl: { slots in
                guard container.type == "container",
                      world.getBlockEntity(container.x, container.y, container.z) === container,
                      container.items?.count == slots.count else { return false }
                container.items = copyItemInventory(slots)
                return true
            }
        )
    }

    var isValid: Bool { isValidImpl() }
    func read() -> [ItemStack?]? { readImpl() }
    func write(_ slots: [ItemStack?]) -> Bool { writeImpl(slots) }
}

/// Bounded transaction boundary for real Pebble item custody.
///
/// It delegates stack compatibility, maxima, split/merge, and durability to
/// PebbleCore. It owns only preconditions, exact verification, rollback, and a
/// bounded local replay receipt set; it is not an inventory or economic ledger.
final class PebbleAgentMaterialCustodyGateway {
    private static let maximumReceipts = 256
    private let bridge = PebbleAgentMaterialSnapshotBridge()
    private var receiptOrder: [String] = []
    private var receipts: [String: PebbleAgentMaterialTransactionOutcome] = [:]
    private var acquisitionReceiptOrder: [String] = []
    private var acquisitionReceipts: [String: PebbleAgentItemEntityAcquisitionOutcome] = [:]

    func reset() {
        receiptOrder.removeAll(keepingCapacity: true)
        receipts.removeAll(keepingCapacity: true)
        acquisitionReceiptOrder.removeAll(keepingCapacity: true)
        acquisitionReceipts.removeAll(keepingCapacity: true)
    }

    func inspect(
        _ endpoint: PebbleAgentMaterialCustodyEndpoint
    ) throws -> AgentMaterialCustodySnapshot {
        guard endpoint.isValid, let slots = endpoint.read() else {
            throw PebbleAgentMaterialBridgeError.invalidLocationID
        }
        return try bridge.custodySnapshot(locationID: endpoint.locationID, slots: slots)
    }

    func fingerprint(
        _ endpoint: PebbleAgentMaterialCustodyEndpoint
    ) throws -> String {
        try bridge.fingerprint(of: inspect(endpoint))
    }

    func transfer(
        _ request: PebbleAgentMaterialTransactionRequest,
        from source: PebbleAgentMaterialCustodyEndpoint,
        to destination: PebbleAgentMaterialCustodyEndpoint,
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentMaterialTransactionOutcome {
        if let prior = receipts[request.transactionID] {
            return outcome(
                request.transactionID,
                .duplicate,
                0,
                prior.sourceFingerprint,
                prior.destinationFingerprint
            )
        }
        guard valid(request), source.locationID != destination.locationID else {
            return outcome(request.transactionID, .invalidRequest)
        }
        let prototype: ItemStack
        do {
            prototype = try bridge.itemStack(from: request.material)
        } catch PebbleAgentMaterialBridgeError.unknownItemKey {
            return outcome(request.transactionID, .unknownMaterialIdentity)
        } catch {
            return outcome(request.transactionID, .invalidRequest)
        }
        guard source.isValid, destination.isValid,
              let sourceBefore = source.read(),
              let destinationBefore = destination.read() else {
            return outcome(request.transactionID, .physicalExecutionFailure)
        }
        let sourceFingerprintBefore: String
        let destinationFingerprintBefore: String
        do {
            sourceFingerprintBefore = try fingerprint(source)
            destinationFingerprintBefore = try fingerprint(destination)
        } catch {
            return outcome(request.transactionID, .physicalExecutionFailure)
        }
        guard sourceFingerprintBefore == request.expectedSourceFingerprint else {
            return outcome(request.transactionID, .staleSource, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }
        guard destinationFingerprintBefore == request.expectedDestinationFingerprint else {
            return outcome(request.transactionID, .staleDestination, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }
        let quantity = request.material.count
        guard itemInventoryQuantity(matching: prototype, in: sourceBefore) >= quantity else {
            return outcome(request.transactionID, .insufficientQuantity, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }
        let capacity = itemInventoryInsertionCapacity(for: prototype, in: destinationBefore)
        guard capacity >= quantity else {
            return outcome(request.transactionID, .destinationFull, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }

        var sourceAfter = copyItemInventory(sourceBefore)
        var destinationAfter = copyItemInventory(destinationBefore)
        guard let extracted = extractItemStack(
            matching: prototype,
            quantity: quantity,
            from: &sourceAfter
        ), insertItemStack(extracted, quantity: quantity, into: &destinationAfter) == quantity,
              extracted.count == 0 else {
            return outcome(request.transactionID, .physicalExecutionFailure, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }
        guard (try? transferConservesIdentity(
            sourceBefore: sourceBefore,
            destinationBefore: destinationBefore,
            sourceAfter: sourceAfter,
            destinationAfter: destinationAfter
        )) == true else {
            return outcome(request.transactionID, .verificationFailure, 0, sourceFingerprintBefore, destinationFingerprintBefore)
        }
        guard source.write(sourceAfter), destination.write(destinationAfter) else {
            return rollback(
                request.transactionID,
                source: source,
                destination: destination,
                sourceBefore: sourceBefore,
                destinationBefore: destinationBefore,
                failure: .physicalExecutionFailure
            )
        }
        guard source.isValid, destination.isValid,
              exactSlots(source.read(), sourceAfter),
              exactSlots(destination.read(), destinationAfter),
              verifyAfterMutation() else {
            return rollback(
                request.transactionID,
                source: source,
                destination: destination,
                sourceBefore: sourceBefore,
                destinationBefore: destinationBefore,
                failure: .verificationFailure
            )
        }
        do {
            let sourceFingerprintAfter = try fingerprint(source)
            let destinationFingerprintAfter = try fingerprint(destination)
            let result = outcome(
                request.transactionID,
                .succeeded,
                quantity,
                sourceFingerprintAfter,
                destinationFingerprintAfter
            )
            retain(result)
            return result
        } catch {
            return rollback(
                request.transactionID,
                source: source,
                destination: destination,
                sourceBefore: sourceBefore,
                destinationBefore: destinationBefore,
                failure: .verificationFailure
            )
        }
    }

    /// Moves every exact Core-reported drop entity into one real custody
    /// endpoint or performs no transfer. Drop tables are never recalculated.
    func acquireItemEntities(
        _ request: PebbleAgentItemEntityAcquisitionRequest,
        from source: PebbleAgentItemEntityCustodyEndpoint,
        to destination: PebbleAgentMaterialCustodyEndpoint,
        verifyAfterMutation: (PebbleAgentItemEntityAcquisitionOutcome) -> Bool = { _ in true }
    ) -> PebbleAgentItemEntityAcquisitionOutcome {
        if let prior = acquisitionReceipts[request.transactionID] {
            return acquisitionOutcome(
                request.transactionID,
                .duplicate,
                [],
                prior.destinationFingerprint
            )
        }
        guard !request.transactionID.isEmpty,
              request.transactionID.count <= 256,
              request.spawnedItemEntityIDs == source.spawnedItemEntityIDs,
              !request.expectedDestinationFingerprint.isEmpty else {
            return acquisitionOutcome(request.transactionID, .invalidRequest)
        }
        guard destination.isValid,
              let items = source.read(),
              let destinationBefore = destination.read() else {
            return acquisitionOutcome(request.transactionID, .physicalExecutionFailure)
        }
        let destinationFingerprintBefore: String
        do { destinationFingerprintBefore = try fingerprint(destination) } catch {
            return acquisitionOutcome(request.transactionID, .physicalExecutionFailure)
        }
        guard destinationFingerprintBefore == request.expectedDestinationFingerprint else {
            return acquisitionOutcome(
                request.transactionID,
                .staleDestination,
                [],
                destinationFingerprintBefore
            )
        }
        let sourceStacks = items.map { $0.stack.copy() }
        let records: [PebbleAgentItemEntityAcquisitionRecord]
        do {
            records = try zip(items, sourceStacks).map { item, stack in
                PebbleAgentItemEntityAcquisitionRecord(
                    entityID: item.id,
                    material: try bridge.snapshot(of: stack)
                )
            }
        } catch {
            return acquisitionOutcome(request.transactionID, .unknownMaterialIdentity)
        }
        var destinationAfter = copyItemInventory(destinationBefore)
        for stack in sourceStacks {
            let candidate = stack.copy()
            let quantity = candidate.count
            guard itemInventoryInsertionCapacity(for: candidate, in: destinationAfter)
                    >= quantity,
                  insertItemStack(candidate, quantity: quantity, into: &destinationAfter)
                    == quantity,
                  candidate.count == 0 else {
                return acquisitionOutcome(
                    request.transactionID,
                    .destinationFull,
                    [],
                    destinationFingerprintBefore
                )
            }
        }
        guard (try? acquisitionConservesIdentity(
            sourceStacks: sourceStacks,
            destinationBefore: destinationBefore,
            destinationAfter: destinationAfter
        )) == true else {
            return acquisitionOutcome(request.transactionID, .verificationFailure)
        }
        guard destination.write(destinationAfter), source.remove(items) else {
            return rollbackAcquisition(
                request.transactionID,
                source: source,
                sourceItems: items,
                sourceStacks: sourceStacks,
                destination: destination,
                destinationBefore: destinationBefore,
                failure: .physicalExecutionFailure
            )
        }
        let destinationFingerprintAfter: String
        do { destinationFingerprintAfter = try fingerprint(destination) } catch {
            return rollbackAcquisition(
                request.transactionID,
                source: source,
                sourceItems: items,
                sourceStacks: sourceStacks,
                destination: destination,
                destinationBefore: destinationBefore,
                failure: .verificationFailure
            )
        }
        let candidateOutcome = acquisitionOutcome(
            request.transactionID,
            .succeeded,
            records,
            destinationFingerprintAfter
        )
        guard destination.isValid,
              exactSlots(destination.read(), destinationAfter),
              source.containsNone(),
              verifyAfterMutation(candidateOutcome) else {
            return rollbackAcquisition(
                request.transactionID,
                source: source,
                sourceItems: items,
                sourceStacks: sourceStacks,
                destination: destination,
                destinationBefore: destinationBefore,
                failure: .verificationFailure
            )
        }
        retain(candidateOutcome)
        return candidateOutcome
    }

    func consume(
        _ request: PebbleAgentMaterialTransactionRequest,
        from source: PebbleAgentMaterialCustodyEndpoint,
        verifyAfterMutation: () -> Bool = { true }
    ) -> PebbleAgentMaterialTransactionOutcome {
        if let prior = receipts[request.transactionID] {
            return outcome(request.transactionID, .duplicate, 0, prior.sourceFingerprint, nil)
        }
        guard valid(request), request.expectedDestinationFingerprint == nil else {
            return outcome(request.transactionID, .invalidRequest)
        }
        let prototype: ItemStack
        do {
            prototype = try bridge.itemStack(from: request.material)
        } catch PebbleAgentMaterialBridgeError.unknownItemKey {
            return outcome(request.transactionID, .unknownMaterialIdentity)
        } catch {
            return outcome(request.transactionID, .invalidRequest)
        }
        guard source.isValid, let sourceBefore = source.read() else {
            return outcome(request.transactionID, .physicalExecutionFailure)
        }
        let sourceFingerprintBefore: String
        do { sourceFingerprintBefore = try fingerprint(source) } catch {
            return outcome(request.transactionID, .physicalExecutionFailure)
        }
        guard sourceFingerprintBefore == request.expectedSourceFingerprint else {
            return outcome(request.transactionID, .staleSource, 0, sourceFingerprintBefore, nil)
        }
        let quantity = request.material.count
        guard itemInventoryQuantity(matching: prototype, in: sourceBefore) >= quantity else {
            return outcome(request.transactionID, .insufficientQuantity, 0, sourceFingerprintBefore, nil)
        }
        var sourceAfter = copyItemInventory(sourceBefore)
        guard extractItemStack(matching: prototype, quantity: quantity, from: &sourceAfter) != nil else {
            return outcome(request.transactionID, .physicalExecutionFailure, 0, sourceFingerprintBefore, nil)
        }
        guard source.write(sourceAfter) else {
            return rollbackConsume(request.transactionID, source: source, sourceBefore: sourceBefore, failure: .physicalExecutionFailure)
        }
        guard source.isValid, exactSlots(source.read(), sourceAfter), verifyAfterMutation() else {
            return rollbackConsume(request.transactionID, source: source, sourceBefore: sourceBefore, failure: .verificationFailure)
        }
        do {
            let result = outcome(request.transactionID, .succeeded, quantity, try fingerprint(source), nil)
            retain(result)
            return result
        } catch {
            return rollbackConsume(request.transactionID, source: source, sourceBefore: sourceBefore, failure: .verificationFailure)
        }
    }

    private func valid(_ request: PebbleAgentMaterialTransactionRequest) -> Bool {
        !request.transactionID.isEmpty && request.transactionID.count <= 256
            && request.material.count > 0
            && !request.expectedSourceFingerprint.isEmpty
    }

    private func rollback(
        _ transactionID: String,
        source: PebbleAgentMaterialCustodyEndpoint,
        destination: PebbleAgentMaterialCustodyEndpoint,
        sourceBefore: [ItemStack?],
        destinationBefore: [ItemStack?],
        failure: PebbleAgentMaterialTransactionStatus
    ) -> PebbleAgentMaterialTransactionOutcome {
        let restored = source.write(sourceBefore) && destination.write(destinationBefore)
            && exactSlots(source.read(), sourceBefore)
            && exactSlots(destination.read(), destinationBefore)
        return outcome(transactionID, restored ? failure : .rollbackFailure)
    }

    private func rollbackConsume(
        _ transactionID: String,
        source: PebbleAgentMaterialCustodyEndpoint,
        sourceBefore: [ItemStack?],
        failure: PebbleAgentMaterialTransactionStatus
    ) -> PebbleAgentMaterialTransactionOutcome {
        let restored = source.write(sourceBefore) && exactSlots(source.read(), sourceBefore)
        return outcome(transactionID, restored ? failure : .rollbackFailure)
    }

    private func exactSlots(_ lhs: [ItemStack?]?, _ rhs: [ItemStack?]) -> Bool {
        guard let lhs, lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { left, right in
            switch (left, right) {
            case (nil, nil): return true
            case let (left?, right?): return left == right
            default: return false
            }
        }
    }

    private func transferConservesIdentity(
        sourceBefore: [ItemStack?],
        destinationBefore: [ItemStack?],
        sourceAfter: [ItemStack?],
        destinationAfter: [ItemStack?]
    ) throws -> Bool {
        let before = try bridge.custodySnapshot(
            locationID: "transaction-before",
            slots: sourceBefore + destinationBefore
        )
        let after = try bridge.custodySnapshot(
            locationID: "transaction-after",
            slots: sourceAfter + destinationAfter
        )
        return bridge.normalizedTotals(in: before) == bridge.normalizedTotals(in: after)
    }

    private func acquisitionConservesIdentity(
        sourceStacks: [ItemStack],
        destinationBefore: [ItemStack?],
        destinationAfter: [ItemStack?]
    ) throws -> Bool {
        let before = try bridge.custodySnapshot(
            locationID: "acquisition-before",
            slots: sourceStacks.map(Optional.some) + destinationBefore
        )
        let after = try bridge.custodySnapshot(
            locationID: "acquisition-after",
            slots: destinationAfter
        )
        return bridge.normalizedTotals(in: before) == bridge.normalizedTotals(in: after)
    }

    private func rollbackAcquisition(
        _ transactionID: String,
        source: PebbleAgentItemEntityCustodyEndpoint,
        sourceItems: [ItemEntity],
        sourceStacks: [ItemStack],
        destination: PebbleAgentMaterialCustodyEndpoint,
        destinationBefore: [ItemStack?],
        failure: PebbleAgentMaterialTransactionStatus
    ) -> PebbleAgentItemEntityAcquisitionOutcome {
        let sourceAlreadyPresent = source.read()?.elementsEqual(
            sourceItems,
            by: { $0 === $1 }
        ) == true
        let sourceRestored = sourceAlreadyPresent || source.restore(sourceItems)
        let restored = destination.write(destinationBefore)
            && exactSlots(destination.read(), destinationBefore)
            && sourceRestored
            && source.read().map { live in
                live.count == sourceStacks.count && zip(live, sourceStacks).allSatisfy {
                    $0.stack == $1
                }
            } == true
        return acquisitionOutcome(
            transactionID,
            restored ? failure : .rollbackFailure
        )
    }

    private func retain(_ receipt: PebbleAgentMaterialTransactionOutcome) {
        receipts[receipt.transactionID] = receipt
        receiptOrder.append(receipt.transactionID)
        if receiptOrder.count > Self.maximumReceipts {
            receipts.removeValue(forKey: receiptOrder.removeFirst())
        }
    }

    private func retain(_ receipt: PebbleAgentItemEntityAcquisitionOutcome) {
        acquisitionReceipts[receipt.transactionID] = receipt
        acquisitionReceiptOrder.append(receipt.transactionID)
        if acquisitionReceiptOrder.count > Self.maximumReceipts {
            acquisitionReceipts.removeValue(
                forKey: acquisitionReceiptOrder.removeFirst()
            )
        }
    }

    private func outcome(
        _ transactionID: String,
        _ status: PebbleAgentMaterialTransactionStatus,
        _ quantityMoved: Int = 0,
        _ sourceFingerprint: String? = nil,
        _ destinationFingerprint: String? = nil
    ) -> PebbleAgentMaterialTransactionOutcome {
        PebbleAgentMaterialTransactionOutcome(
            transactionID: transactionID,
            status: status,
            quantityMoved: quantityMoved,
            sourceFingerprint: sourceFingerprint,
            destinationFingerprint: destinationFingerprint
        )
    }

    private func acquisitionOutcome(
        _ transactionID: String,
        _ status: PebbleAgentMaterialTransactionStatus,
        _ acquired: [PebbleAgentItemEntityAcquisitionRecord] = [],
        _ destinationFingerprint: String? = nil
    ) -> PebbleAgentItemEntityAcquisitionOutcome {
        PebbleAgentItemEntityAcquisitionOutcome(
            transactionID: transactionID,
            status: status,
            acquired: acquired,
            destinationFingerprint: destinationFingerprint
        )
    }
}

struct PebbleAgentMaterialPlacementBinding {
    let slot: Int
    let heldItem: ItemStack
    let custody: PebbleAgentBlockPlacementCustody
}

struct PebbleAgentMaterialToolBinding {
    let slot: Int
    let heldItem: ItemStack
    let toolState: PebbleAgentBlockBreakToolState
}

extension PebbleAgentMaterialCustodyGateway {
    func placementBinding(
        actor: LabCoreAgentEntity,
        slot: Int
    ) -> PebbleAgentMaterialPlacementBinding? {
        guard actor.carriedItems.indices.contains(slot),
              let held = actor.carriedItems[slot], held.count > 0 else { return nil }
        let before = copyItemInventory(actor.carriedItems)
        let heldCopy = held.copy()
        var expectedAfter: [ItemStack?]?
        var mutationValid = true
        return PebbleAgentMaterialPlacementBinding(
            slot: slot,
            heldItem: heldCopy,
            custody: PebbleAgentBlockPlacementCustody(
                consume: { quantity in
                    guard quantity > 0, expectedAfter == nil else {
                        mutationValid = false
                        return
                    }
                    var candidate = copyItemInventory(actor.carriedItems)
                    guard extractItemStack(
                        matching: heldCopy,
                        quantity: quantity,
                        from: &candidate,
                        slotFilter: { $0 == slot }
                    ) != nil else {
                        mutationValid = false
                        return
                    }
                    actor.carriedItems = candidate
                    expectedAfter = copyItemInventory(candidate)
                },
                verify: {
                    mutationValid && expectedAfter.map {
                        self.exactSlots(actor.carriedItems, $0)
                    } == true
                },
                rollback: {
                    actor.carriedItems = copyItemInventory(before)
                    return self.exactSlots(actor.carriedItems, before)
                }
            )
        )
    }

    /// Resolves the first real carried stack whose registry item places the
    /// exact required block. Slot order is the deterministic selection rule.
    func placementBinding(
        actor: LabCoreAgentEntity,
        requiredBlockID: Int
    ) -> PebbleAgentMaterialPlacementBinding? {
        guard requiredBlockID > 0, requiredBlockID < blockDefs.count else { return nil }
        let slot = actor.carriedItems.indices.first { index in
            guard let stack = actor.carriedItems[index], stack.count > 0 else { return false }
            return itemDef(stack.id).block.map(Int.init) == requiredBlockID
        }
        guard let slot else { return nil }
        return placementBinding(actor: actor, slot: slot)
    }

    func toolBinding(
        actor: LabCoreAgentEntity,
        slot: Int,
        world: World
    ) -> PebbleAgentMaterialToolBinding? {
        guard actor.world === world, actor.carriedItems.indices.contains(slot),
              let held = actor.carriedItems[slot] else { return nil }
        let before = copyItemInventory(actor.carriedItems)
        let heldCopy = held.copy()
        var expectedAfter: [ItemStack?]?
        var mutationValid = true
        return PebbleAgentMaterialToolBinding(
            slot: slot,
            heldItem: heldCopy,
            toolState: PebbleAgentBlockBreakToolState(
                damage: { amount in
                    guard amount > 0, expectedAfter == nil,
                          let live = actor.carriedItems[slot],
                          stacksEqual(live, heldCopy) else {
                        mutationValid = false
                        return
                    }
                    let candidate = live.copy()
                    let durability = damageItemStack(
                        candidate,
                        amount: amount,
                        random: { gameRng.nextFloat() }
                    )
                    actor.carriedItems[slot] = durability == .broken ? nil : candidate
                    if durability == .broken {
                        world.hooks.playSound("entity.item.break", actor.x, actor.y, actor.z, 0.8, 1)
                    }
                    expectedAfter = copyItemInventory(actor.carriedItems)
                },
                verify: {
                    mutationValid && expectedAfter.map {
                        self.exactSlots(actor.carriedItems, $0)
                    } == true
                },
                rollback: {
                    actor.carriedItems = copyItemInventory(before)
                    return self.exactSlots(actor.carriedItems, before)
                }
            )
        )
    }

    /// Deterministic selection from real actor custody. A matching Core tool
    /// wins by slot order; otherwise the first real tool is exposed so
    /// PebbleCore can apply its normal wrong-tool/no-drop rule.
    func harvestToolBinding(
        actor: LabCoreAgentEntity,
        targetCell: Int,
        world: World
    ) -> PebbleAgentMaterialToolBinding? {
        let block = blockDefs[targetCell >> 4]
        let toolSlots = actor.carriedItems.indices.filter { index in
            actor.carriedItems[index].flatMap { itemDef($0.id).tool } != nil
        }
        let matchingSlot = toolSlots.first { index in
            guard let stack = actor.carriedItems[index],
                  let tool = itemDef(stack.id).tool else { return false }
            return tool.type == block.tool.rawValue
                && (!block.requiresTool || canHarvest(stack, targetCell))
        }
        guard let slot = matchingSlot ?? toolSlots.first else { return nil }
        return toolBinding(actor: actor, slot: slot, world: world)
    }
}

/// Read-only compatibility view for historical Civilization resource buckets.
/// The result is derived from real custody and is never written into a session
/// or AgentCampStock by this adapter.
struct PebbleAgentCoarseMaterialProjection {
    func amounts(from custody: AgentMaterialCustodySnapshot) -> [AgentResourceAmount] {
        AgentResourceAmounts.normalize(custody.slots.compactMap { stack in
            guard let stack, let kind = historicalKind(stack.identity.itemKey) else { return nil }
            return AgentResourceAmount(resource: kind, quantity: stack.count)
        })
    }

    private func historicalKind(_ itemKey: String) -> AgentResourceKind? {
        switch itemKey {
        case "hay_block", "wheat": return .foodRaw
        case "oak_log", "birch_log": return .wood
        case "stone", "cobblestone": return .stone
        default: return nil
        }
    }
}
