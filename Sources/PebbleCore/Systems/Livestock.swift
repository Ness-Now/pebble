/// Exact physical result from PebbleCore's existing sheep product mechanic.
public struct SheepLivestockShearingResult: Equatable, Sendable {
    public let itemName: String
    public let quantity: Int
    public let spawnedItemEntityIDs: [Int]
}

public extension Sheep {
    /// Actor-neutral extraction of the existing Player shearing behavior.
    /// Wool remains real ItemEntity output under World authority.
    func shearForLivestock() -> SheepLivestockShearingResult? {
        guard !sheared, !baby, !dead, deathTime <= 0 else { return nil }
        sheared = true
        let itemName = COLORS[color] + "_wool"
        let count = 1 + gameRng.nextInt(3)
        var entityIDs: [Int] = []
        entityIDs.reserveCapacity(count)
        for _ in 0..<count {
            entityIDs.append(
                spawnItem(world, x, y + 0.5, z, ItemStack(iid(itemName), 1)).id
            )
        }
        world.hooks.playSound("entity.sheep.shear", x, y, z, 1, 1)
        return SheepLivestockShearingResult(
            itemName: itemName, quantity: count,
            spawnedItemEntityIDs: entityIDs.sorted()
        )
    }
}

public extension Mob {
    /// Uses the existing leash physics and Navigation tick; it does not move or
    /// teleport the animal and does not introduce another pathfinder.
    @discardableResult
    func attachLivestockLeash(to holder: Entity) -> Bool {
        guard !dead, deathTime <= 0, holder.world === world,
              world.entityById[holder.id] === holder, holder !== self,
              leashedTo == nil, leashFence == nil else { return false }
        leashedTo = holder
        return true
    }

    @discardableResult
    func attachLivestockLeash(toFenceX x: Int, y: Int, z: Int) -> Bool {
        guard !dead, deathTime <= 0, leashedTo == nil, leashFence == nil else { return false }
        leashFence = (x, y, z)
        return true
    }

    @discardableResult
    func releaseLivestockLeash() -> Bool {
        guard leashedTo != nil || leashFence != nil else { return false }
        leashedTo = nil
        leashFence = nil
        return true
    }
}
