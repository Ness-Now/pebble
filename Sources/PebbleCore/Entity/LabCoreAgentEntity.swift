import Foundation

/// Experimental PebbleLab entity probe.
///
/// This entity is constructed directly by PebbleLab scenarios. It is not
/// registered in `EntityRegistry`, not persisted, and not rendered.
public final class LabCoreAgentEntity: Entity {
    public static let kind = "pebblelab:core_agent_probe"
    public static let carriedItemSlotCount = 9

    public let labAgentId: String
    public let physicalId: String
    public private(set) var ticksAlive = 0
    /// Real physical custody for the experimental actor. This uses the same
    /// ItemStack representation and stack rules as every other Pebble holder.
    public var carriedItems: [ItemStack?] = Array(
        repeating: nil,
        count: carriedItemSlotCount
    )

    public override var type: String { Self.kind }
    public override var shouldSaveToChunk: Bool { false }

    public init(world: World, labAgentId: String, physicalId: String) {
        self.labAgentId = labAgentId
        self.physicalId = physicalId
        super.init(world: world)
        noGravity = true
        persistent = false
    }

    public override func tick() {
        prevX = x
        prevY = y
        prevZ = z
        prevYaw = yaw
        prevPitch = pitch
        ticksAlive += 1
    }
}

/// Removes one probe without silently destroying material in its custody.
///
/// Non-empty slots are spilled as real ItemEntity instances before the probe is
/// removed. A failed verification removes the spill and restores the exact
/// carried stacks, leaving the probe live so its custody remains observable.
@discardableResult
public func removeLabCoreAgentProbe(
    _ probe: LabCoreAgentEntity,
    from world: World
) -> Bool {
    guard probe.world === world,
          world.entities.contains(where: { $0 === probe }) else {
        return false
    }
    let before = copyItemInventory(probe.carriedItems)
    var spilled: [ItemEntity] = []
    for stack in before.compactMap({ $0 }) {
        let item = spawnItem(world, probe.x, probe.y + 0.5, probe.z, stack.copy())
        spilled.append(item)
    }
    probe.carriedItems = Array(repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount)
    let spillVerified = spilled.count == before.compactMap({ $0 }).count
        && spilled.allSatisfy { item in
            world.entities.contains(where: { $0 === item }) && item.stack.count > 0
        }
        && probe.carriedItems.allSatisfy { $0 == nil }
    guard spillVerified else {
        for item in spilled { world.removeEntity(item) }
        probe.carriedItems = copyItemInventory(before)
        return false
    }
    world.removeEntity(probe)
    guard !world.entities.contains(where: { $0 === probe }) else {
        for item in spilled { world.removeEntity(item) }
        probe.carriedItems = copyItemInventory(before)
        return false
    }
    return true
}

/// Removes every experimental Lab probe through the World's entity API.
///
/// This keeps `entities` and `entityById` consistent and is intentionally
/// independent of renderer and environment-variable state.
@discardableResult
public func clearLabCoreAgentProbes(in world: World) -> Int {
    let probes = world.entities.compactMap { $0 as? LabCoreAgentEntity }
    return probes.reduce(0) { removed, probe in
        removed + (removeLabCoreAgentProbe(probe, from: world) ? 1 : 0)
    }
}
