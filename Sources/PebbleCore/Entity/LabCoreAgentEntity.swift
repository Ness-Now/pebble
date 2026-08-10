import Foundation

/// Complete physical state changed by `Entity.move` for a PebbleLab probe.
///
/// This is a bounded actor-neutral Core value. It is not a second position
/// authority and it does not capture World progression. Pebble adapters may
/// use it only to compensate a verified candidate operation before that
/// operation is published.
public struct LabCoreAgentPhysicalState: Equatable, CustomStringConvertible {
    public let x: Double
    public let y: Double
    public let z: Double
    public let prevX: Double
    public let prevY: Double
    public let prevZ: Double
    public let vx: Double
    public let vy: Double
    public let vz: Double
    public let yaw: Double
    public let pitch: Double
    public let prevYaw: Double
    public let prevPitch: Double
    public let onGround: Bool
    public let horizontalCollision: Bool
    public let fallDistance: Double

    public var description: String {
        "position=\(x),\(y),\(z) prev=\(prevX),\(prevY),\(prevZ) "
            + "velocity=\(vx),\(vy),\(vz) orientation=\(yaw),\(pitch),"
            + "\(prevYaw),\(prevPitch) onGround=\(onGround ? 1 : 0) "
            + "horizontalCollision=\(horizontalCollision ? 1 : 0) "
            + "fallDistance=\(fallDistance)"
    }
}

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

    public func capturePhysicalState() -> LabCoreAgentPhysicalState {
        LabCoreAgentPhysicalState(
            x: x, y: y, z: z,
            prevX: prevX, prevY: prevY, prevZ: prevZ,
            vx: vx, vy: vy, vz: vz,
            yaw: yaw, pitch: pitch,
            prevYaw: prevYaw, prevPitch: prevPitch,
            onGround: onGround,
            horizontalCollision: horizontalCollision,
            fallDistance: fallDistance
        )
    }

    /// Restores a previously captured probe state without running collision,
    /// pathfinding, gameplay movement, or any other World mutation.
    ///
    /// The caller must first prove that this exact probe is still the intended
    /// compensation target and must treat a failed equality check as a hard
    /// rollback failure.
    @discardableResult
    public func restorePhysicalState(
        _ state: LabCoreAgentPhysicalState
    ) -> Bool {
        x = state.x
        y = state.y
        z = state.z
        prevX = state.prevX
        prevY = state.prevY
        prevZ = state.prevZ
        vx = state.vx
        vy = state.vy
        vz = state.vz
        yaw = state.yaw
        pitch = state.pitch
        prevYaw = state.prevYaw
        prevPitch = state.prevPitch
        onGround = state.onGround
        horizontalCollision = state.horizontalCollision
        fallDistance = state.fallDistance
        return capturePhysicalState() == state
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
    from world: World,
    spillProvenance: ((Int, ItemStack) -> String?)? = nil
) -> Bool {
    guard probe.world === world,
          world.entities.contains(where: { $0 === probe }) else {
        return false
    }
    let before = copyItemInventory(probe.carriedItems)
    var spilled: [ItemEntity] = []
    for (slot, optionalStack) in before.enumerated() {
        guard let stack = optionalStack else { continue }
        let item = spawnItem(world, probe.x, probe.y + 0.5, probe.z, stack.copy())
        item.custodyProvenance = spillProvenance?(slot, stack)
        if item.custodyProvenance != nil {
            item.pickupDelay = Int.max
            item.lifeTime = Int.max
            item.noGravity = true
            item.vx = 0; item.vy = 0; item.vz = 0
            // Entity-only saves are emitted only for dirty chunks. The
            // protected escrow is itself the physical mutation that must
            // make this chunk eligible for the existing World save path.
            world.getChunkAt(ifloor(item.x), ifloor(item.z))?.modified = true
        }
        spilled.append(item)
    }
    probe.carriedItems = Array(repeating: nil, count: LabCoreAgentEntity.carriedItemSlotCount)
    let originalStacks = before.compactMap { $0 }
    let spillVerified = spilled.count == originalStacks.count
        && zip(spilled, originalStacks).allSatisfy { item, original in
            world.entities.contains(where: { $0 === item }) && item.stack == original
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
