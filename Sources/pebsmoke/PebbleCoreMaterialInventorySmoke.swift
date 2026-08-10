import Foundation
import PebbleAgents
import PebbleCore

func runPebbleCoreMaterialInventorySmoke() {
    section("material identity DTO")
    var metadata = StackData()
    metadata.potion = "healing"
    metadata.lodestone = [1, 64, -2, 0]
    let metadataJSON = String(
        decoding: try! canonicalMaterialEncoder().encode(metadata),
        as: UTF8.self
    )
    let identity = AgentMaterialIdentitySnapshot(
        itemKey: "potion",
        damage: 0,
        enchantments: [AgentMaterialEnchantmentSnapshot(id: "unbreaking", level: 1)],
        label: "field kit",
        canonicalDataJSON: metadataJSON
    )
    let stackSnapshot = AgentMaterialStackSnapshot(identity: identity, count: 3)
    let encodedA = try! canonicalMaterialEncoder().encode(stackSnapshot)
    let encodedB = try! canonicalMaterialEncoder().encode(stackSnapshot)
    let decoded = try! JSONDecoder().decode(AgentMaterialStackSnapshot.self, from: encodedA)
    check("stable key preserved", decoded.identity.itemKey == "potion")
    check("count round trip", decoded.count == 3)
    check("damage round trip", decoded.identity.damage == 0)
    check("enchantment round trip", decoded.identity.enchantments == identity.enchantments)
    check("label round trip", decoded.identity.label == "field kit")
    check("metadata round trip", decoded.identity.canonicalDataJSON == metadataJSON)
    check("deterministic encoding", encodedA == encodedB)
    check("count excluded from identity", AgentMaterialStackSnapshot(identity: identity, count: 7).identity == identity)

    section("real ItemStack inventory rules")
    let cobblestone = ItemStack(iid("cobblestone"), 10)
    var source: [ItemStack?] = [cobblestone]
    var destination: [ItemStack?] = [nil, nil]
    let extractedFour = extractItemStack(matching: cobblestone, quantity: 4, from: &source)
    check("partial split extracts exact", extractedFour?.count == 4 && source[0]?.count == 6)
    let insertedFour = insertItemStack(extractedFour!, quantity: 4, into: &destination)
    check("partial split inserts exact", insertedFour == 4 && extractedFour?.count == 0 && destination[0]?.count == 4)
    check("split conserves identity quantity", (source[0]?.count ?? 0) + (destination[0]?.count ?? 0) == 10)

    let compatible = ItemStack(iid("cobblestone"), 5)
    let insertedCompatible = insertItemStack(compatible, quantity: 5, into: &destination)
    check("compatible merge", insertedCompatible == 5 && destination[0]?.count == 9 && destination[1] == nil)
    check("source reference decremented", compatible.count == 0)
    check("registry max stack authority", itemInventoryInsertionCapacity(for: cobblestone, in: destination) == 119)

    let full = ItemStack(iid("cobblestone"), maxStackOf(cobblestone))
    var fullDestination: [ItemStack?] = [full]
    let refusedSource = ItemStack(iid("cobblestone"), 1)
    check("full destination capacity zero", itemInventoryInsertionCapacity(for: refusedSource, in: fullDestination) == 0)
    check("full destination refuses mutation", insertItemStack(refusedSource, quantity: 1, into: &fullDestination) == 0 && refusedSource.count == 1)

    let dirt = ItemStack(iid("dirt"), maxStackOf(ItemStack(iid("dirt"), 1)))
    var incompatibleDestination: [ItemStack?] = [dirt]
    let incompatibleSource = ItemStack(iid("cobblestone"), 1)
    check("incompatible occupied slot has zero capacity", itemInventoryInsertionCapacity(for: incompatibleSource, in: incompatibleDestination) == 0)
    check("incompatible occupied slot unchanged", insertItemStack(incompatibleSource, quantity: 1, into: &incompatibleDestination) == 0 && incompatibleDestination[0] === dirt)

    let insufficient = ItemStack(iid("stone"), 2)
    var insufficientSlots: [ItemStack?] = [insufficient]
    let insufficientBefore = copyItemInventory(insufficientSlots)
    let insufficientResult = extractItemStack(matching: insufficient, quantity: 3, from: &insufficientSlots)
    check("insufficient exact extraction refused", insufficientResult == nil)
    check("insufficient refusal has no partial debit", materialSlotsEqual(insufficientSlots, insufficientBefore))

    var multiSource: [ItemStack?] = [ItemStack(iid("stone"), 2), ItemStack(iid("stone"), 3)]
    let extractedAll = extractItemStack(matching: multiSource[0]!, quantity: 5, from: &multiSource)
    var fullTransferDestination: [ItemStack?] = [nil]
    let movedAll = insertItemStack(extractedAll!, quantity: 5, into: &fullTransferDestination)
    check("full transfer source empty", multiSource.allSatisfy { $0 == nil })
    check("full transfer destination exact", movedAll == 5 && fullTransferDestination[0]?.count == 5)

    section("real durability rule")
    let pickaxe = ItemStack(iid("iron_pickaxe"), 1)
    let damageResult = damageItemStack(pickaxe, amount: 2, random: { 1 })
    check("tool damage uses real durability", damageResult == .damaged && pickaxe.damage == 2)
    pickaxe.damage = maxDamageOf(pickaxe) - 1
    check("tool break boundary", damageItemStack(pickaxe, amount: 1, random: { 1 }) == .broken)
    let enchanted = ItemStack(iid("iron_pickaxe"), 1, ench: [EnchInstance("unbreaking", 1)])
    check("unbreaking skip uses shared rule", damageItemStack(enchanted, amount: 1, random: { 0 }) == .unchanged && enchanted.damage == 0)

    section("probe custody lifecycle")
    let world = World(dim: .overworld, seed: 16)
    let spillChunk = Chunk(
        cx: 0, cz: 0, minY: GEN_MIN_Y, height: WORLD_H
    )
    world.setChunk(spillChunk)
    spillChunk.modified = false
    let probe = LabCoreAgentEntity(world: world, labAgentId: "agent-16", physicalId: "physical-16")
    probe.setPos(2, 64, 2)
    probe.carriedItems[0] = ItemStack(iid("cobblestone"), 4)
    world.addEntity(probe)
    let removed = removeLabCoreAgentProbe(probe, from: world)
    let spill = world.entities.compactMap { $0 as? ItemEntity }
    check("nonempty probe removed through guarded API", removed && !world.entities.contains(where: { $0 === probe }))
    check("custody spills true ItemEntity", spill.count == 1 && spill[0].stack.id == iid("cobblestone"))
    check("spill preserves exact quantity", spill[0].stack.count == 4)
    check("ordinary custody spill dirties its World chunk",
          spillChunk.modified)
    check("removed probe custody cleared", probe.carriedItems.allSatisfy { $0 == nil })
    check("probe remains unregistered and nonpersistent", !probe.shouldSaveToChunk && probe.type == LabCoreAgentEntity.kind)

    section("protected probe custody escrow")
    let escrowWorld = World(dim: .overworld, seed: 17)
    let escrowProbe = LabCoreAgentEntity(
        world: escrowWorld,
        labAgentId: "agent-17",
        physicalId: "physical-17"
    )
    escrowProbe.setPos(3.5, 64, 3.5)
    escrowProbe.carriedItems[1] = ItemStack(iid("bread"), 1)
    escrowWorld.addEntity(escrowProbe)
    let escrowRemoved = removeLabCoreAgentProbe(
        escrowProbe,
        from: escrowWorld,
        spillProvenance: { slot, _ in "checkpoint-token:\(slot)" }
    )
    let escrow = escrowWorld.entities.compactMap { $0 as? ItemEntity }.first
    check("protected removal creates one physical escrow",
          escrowRemoved && escrow?.stack == ItemStack(iid("bread"), 1)
            && escrow?.custodyProvenance == "checkpoint-token:1")
    let escrowX = escrow?.x
    let escrowY = escrow?.y
    let escrowZ = escrow?.z
    for _ in 0..<6_100 { escrow?.tick() }
    check("protected escrow cannot expire, move, or become pickable",
          escrow?.dead == false && escrow?.pickupDelay == Int.max
            && escrow?.lifeTime == Int.max
            && escrow?.x == escrowX && escrow?.y == escrowY
            && escrow?.z == escrowZ)
    check("protected escrow refuses destructive damage",
          escrow?.hurt(1, "explosion") == false && escrow?.dead == false)
    if let escrow {
        let persisted = escrow.save()
        let reloaded = ItemEntity(world: escrowWorld)
        reloaded.load(persisted)
        check("protected escrow provenance and exact stack persist",
              reloaded.custodyProvenance == escrow.custodyProvenance
                && reloaded.stack == escrow.stack
                && reloaded.pickupDelay == Int.max
                && reloaded.lifeTime == Int.max && reloaded.noGravity)
    } else {
        check("protected escrow provenance and exact stack persist", false)
    }
}

private func canonicalMaterialEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}

private func materialSlotsEqual(_ lhs: [ItemStack?], _ rhs: [ItemStack?]) -> Bool {
    lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { left, right in
        switch (left, right) {
        case (nil, nil): return true
        case let (left?, right?): return left == right
        default: return false
        }
    }
}
