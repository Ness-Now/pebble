import PebbleAgents
import PebbleCore

/// A narrow Pebble-owned view of one live Civilization actor.
///
/// This is an adapter over the existing experimental Core probe, not a new
/// entity model. PebbleCore remains authoritative for position, collision,
/// entity lifecycle, and item custody; PebbleAgents sees only pure snapshots
/// and verified outcomes.
struct PebbleAgentEmbodiment {
    enum ResolutionError: Error, Equatable {
        case emptyAgentID
        case missingMapping(String)
        case unexpectedMapping(String)
        case identityMismatch(expected: String, actual: String)
        case missingWorldEntity(String)
        case duplicateWorldEntity(String)
        case staleWorld(String)
        case unavailable(String)
        case invalidCustody(String)
    }

    let probe: LabCoreAgentEntity

    var agentID: String { probe.labAgentId }
    var physicalID: String { probe.physicalId }
    var entity: Entity { probe }
    var position: AgentPosition {
        AgentPosition(
            x: Int(probe.x.rounded(.down)),
            y: Int(probe.y.rounded(.down)),
            z: Int(probe.z.rounded(.down))
        )
    }
    var x: Double { probe.x }
    var y: Double { probe.y }
    var z: Double { probe.z }
    var yaw: Double {
        get { probe.yaw }
        nonmutating set { probe.yaw = newValue }
    }
    var pitch: Double {
        get { probe.pitch }
        nonmutating set { probe.pitch = newValue }
    }
    var carriedItems: [ItemStack?] {
        get { probe.carriedItems }
        nonmutating set { probe.carriedItems = newValue }
    }

    static func resolve(
        agentID: String,
        in world: World,
        mappedByAgentID: [String: LabCoreAgentEntity]
    ) throws -> PebbleAgentEmbodiment {
        guard !agentID.isEmpty else { throw ResolutionError.emptyAgentID }
        guard let mapped = mappedByAgentID[agentID] else {
            throw ResolutionError.missingMapping(agentID)
        }
        guard mapped.labAgentId == agentID else {
            throw ResolutionError.identityMismatch(
                expected: agentID,
                actual: mapped.labAgentId
            )
        }
        guard mapped.world === world else { throw ResolutionError.staleWorld(agentID) }
        let matches = world.entities.compactMap { $0 as? LabCoreAgentEntity }
            .filter { $0.labAgentId == agentID }
        guard !matches.isEmpty else { throw ResolutionError.missingWorldEntity(agentID) }
        guard matches.count == 1 else { throw ResolutionError.duplicateWorldEntity(agentID) }
        guard matches[0] === mapped else {
            throw ResolutionError.identityMismatch(
                expected: agentID,
                actual: matches[0].labAgentId
            )
        }
        guard !mapped.dead else { throw ResolutionError.unavailable(agentID) }
        guard mapped.carriedItems.count == LabCoreAgentEntity.carriedItemSlotCount else {
            throw ResolutionError.invalidCustody(agentID)
        }
        return PebbleAgentEmbodiment(probe: mapped)
    }

    static func resolveAll(
        agentIDs: [String],
        in world: World,
        mappedByAgentID: [String: LabCoreAgentEntity]
    ) throws -> [String: PebbleAgentEmbodiment] {
        let expected = Set(agentIDs)
        guard expected.count == agentIDs.count else {
            throw ResolutionError.duplicateWorldEntity("requested-agent-id")
        }
        if let unexpected = mappedByAgentID.keys.sorted().first(where: { !expected.contains($0) }) {
            throw ResolutionError.unexpectedMapping(unexpected)
        }
        var resolved: [String: PebbleAgentEmbodiment] = [:]
        for id in agentIDs.sorted() {
            resolved[id] = try resolve(
                agentID: id,
                in: world,
                mappedByAgentID: mappedByAgentID
            )
        }
        return resolved
    }

    func isValid(in world: World) -> Bool {
        probe.world === world && !probe.dead
            && probe.carriedItems.count == LabCoreAgentEntity.carriedItemSlotCount
            && world.entities.filter { $0 === probe }.count == 1
            && world.entities.compactMap { $0 as? LabCoreAgentEntity }
                .filter { $0.labAgentId == agentID }.count == 1
    }
}
