import Foundation

/// Experimental PebbleLab entity probe.
///
/// This entity is constructed directly by PebbleLab scenarios. It is not
/// registered in `EntityRegistry`, not persisted, and not rendered.
public final class LabCoreAgentEntity: Entity {
    public static let kind = "pebblelab:core_agent_probe"

    public let labAgentId: String
    public let physicalId: String
    public private(set) var ticksAlive = 0

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
